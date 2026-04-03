--[[
	ClaudeCodeBridge — плагин для Roblox Studio
	Даёт Claude Code доступ к сцене через HTTP.

	Установка:
	1. Скопируй этот файл в папку плагинов Roblox Studio:
	   ~/Documents/Roblox/Plugins/ClaudeCodeBridge.server.lua
	   (macOS: ~/Documents/Roblox/Plugins/)
	2. Перезапусти Roblox Studio
	3. Разреши HttpService в Game Settings → Security → Allow HTTP Requests

	Плагин запускает локальный HTTP-сервер (через Studio Plugin API),
	к которому Claude Code обращается для получения информации о сцене.
]]

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local StudioService = game:GetService("StudioService")

-- ─── Конфигурация ───────────────────────────────────────────────────────────
local BRIDGE_PORT = 28859
local BRIDGE_FILE = os.getenv("HOME") .. "/Documents/Roblox/claude_bridge.json"

-- ─── Утилиты ────────────────────────────────────────────────────────────────

local function getFullPath(instance)
	local path = instance.Name
	local current = instance.Parent
	while current and current ~= game do
		path = current.Name .. "." .. path
		current = current.Parent
	end
	return path
end

local function serializeInstance(instance, depth)
	depth = depth or 0
	if depth > 5 then return nil end

	local data = {
		Name = instance.Name,
		ClassName = instance.ClassName,
		Path = getFullPath(instance),
	}

	-- Базовые свойства
	pcall(function()
		if instance:IsA("BasePart") then
			data.Position = {instance.Position.X, instance.Position.Y, instance.Position.Z}
			data.Size = {instance.Size.X, instance.Size.Y, instance.Size.Z}
			data.Color = {instance.Color.R, instance.Color.G, instance.Color.B}
			data.Material = instance.Material.Name
			data.Transparency = instance.Transparency
			data.Anchored = instance.Anchored
			data.CanCollide = instance.CanCollide
		end
		if instance:IsA("Model") then
			local cf = instance:GetPivot()
			data.PivotPosition = {cf.Position.X, cf.Position.Y, cf.Position.Z}
		end
		if instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript") then
			data.Source = instance.Source
			data.Disabled = instance.Disabled
		end
		if instance:IsA("Humanoid") then
			data.Health = instance.Health
			data.MaxHealth = instance.MaxHealth
			data.WalkSpeed = instance.WalkSpeed
			data.JumpPower = instance.JumpPower
		end
	end)

	-- Дочерние объекты
	local children = instance:GetChildren()
	if #children > 0 and depth < 3 then
		data.Children = {}
		for _, child in ipairs(children) do
			table.insert(data.Children, serializeInstance(child, depth + 1))
		end
	else
		data.ChildCount = #children
	end

	return data
end

-- ─── Команды ────────────────────────────────────────────────────────────────

local Commands = {}

function Commands.get_scene_tree()
	local tree = {}
	for _, service in ipairs({"Workspace", "ServerScriptService", "ServerStorage", "ReplicatedStorage", "ReplicatedFirst", "StarterGui", "StarterPack", "StarterPlayer", "Lighting", "SoundService"}) do
		local svc = game:FindFirstChild(service)
		if svc then
			table.insert(tree, serializeInstance(svc, 0))
		end
	end
	return {success = true, tree = tree}
end

function Commands.get_selection()
	local selected = Selection:Get()
	local result = {}
	for _, obj in ipairs(selected) do
		table.insert(result, serializeInstance(obj, 0))
	end
	return {success = true, selected = result, count = #result}
end

function Commands.get_object(params)
	local path = params.path
	if not path then return {success = false, error = "path required"} end

	local parts = string.split(path, ".")
	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return {success = false, error = "Object not found: " .. path}
		end
	end

	return {success = true, object = serializeInstance(current, 0)}
end

function Commands.find_objects(params)
	local className = params.className
	local name = params.name
	local parent = params.parent or "Workspace"

	local parentObj = game:FindFirstChild(parent) or game:GetService(parent)
	if not parentObj then return {success = false, error = "Parent not found"} end

	local results = {}
	local function search(obj)
		local match = true
		if className and obj.ClassName ~= className then match = false end
		if name and not string.find(obj.Name:lower(), name:lower()) then match = false end
		if match then
			table.insert(results, {
				Name = obj.Name,
				ClassName = obj.ClassName,
				Path = getFullPath(obj),
			})
		end
		if #results < 100 then
			for _, child in ipairs(obj:GetChildren()) do
				search(child)
			end
		end
	end
	search(parentObj)

	return {success = true, results = results, count = #results}
end

function Commands.execute_luau(params)
	local code = params.code
	if not code then return {success = false, error = "code required"} end

	local fn, err = loadstring(code)
	if not fn then
		return {success = false, error = "Syntax error: " .. tostring(err)}
	end

	local ok, result = pcall(fn)
	if not ok then
		return {success = false, error = "Runtime error: " .. tostring(result)}
	end

	ChangeHistoryService:SetWaypoint("ClaudeCode: execute")
	return {success = true, result = tostring(result)}
end

function Commands.create_part(params)
	local parent = game.Workspace
	if params.parent then
		parent = game:FindFirstChild(params.parent) or game.Workspace
	end

	local part = Instance.new(params.className or "Part")
	part.Name = params.name or "Part"

	if params.position then
		part.Position = Vector3.new(unpack(params.position))
	end
	if params.size then
		part.Size = Vector3.new(unpack(params.size))
	end
	if params.color then
		part.Color = Color3.new(unpack(params.color))
	end
	if params.material then
		part.Material = Enum.Material[params.material]
	end
	if params.anchored ~= nil then
		part.Anchored = params.anchored
	else
		part.Anchored = true
	end
	if params.transparency then
		part.Transparency = params.transparency
	end

	part.Parent = parent
	ChangeHistoryService:SetWaypoint("ClaudeCode: create " .. part.Name)

	return {success = true, object = serializeInstance(part, 0)}
end

function Commands.create_script(params)
	local scriptType = params.scriptType or "Script"
	local parent = game.ServerScriptService

	if params.parent then
		local p = game:FindFirstChild(params.parent)
		if p then parent = p end
	end

	local script
	if scriptType == "LocalScript" then
		script = Instance.new("LocalScript")
	elseif scriptType == "ModuleScript" then
		script = Instance.new("ModuleScript")
	else
		script = Instance.new("Script")
	end

	script.Name = params.name or "Script"
	script.Source = params.source or ""
	script.Parent = parent

	ChangeHistoryService:SetWaypoint("ClaudeCode: create script " .. script.Name)
	return {success = true, path = getFullPath(script)}
end

function Commands.set_property(params)
	local path = params.path
	if not path then return {success = false, error = "path required"} end

	local parts = string.split(path, ".")
	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return {success = false, error = "Object not found: " .. path}
		end
	end

	for prop, value in pairs(params.properties or {}) do
		pcall(function()
			if prop == "Position" and type(value) == "table" then
				current.Position = Vector3.new(unpack(value))
			elseif prop == "Size" and type(value) == "table" then
				current.Size = Vector3.new(unpack(value))
			elseif prop == "Color" and type(value) == "table" then
				current.Color = Color3.new(unpack(value))
			elseif prop == "CFrame" and type(value) == "table" then
				current.CFrame = CFrame.new(unpack(value))
			else
				current[prop] = value
			end
		end)
	end

	ChangeHistoryService:SetWaypoint("ClaudeCode: set properties")
	return {success = true}
end

function Commands.delete_object(params)
	local path = params.path
	if not path then return {success = false, error = "path required"} end

	local parts = string.split(path, ".")
	local current = game
	for _, part in ipairs(parts) do
		current = current:FindFirstChild(part)
		if not current then
			return {success = false, error = "Object not found: " .. path}
		end
	end

	local name = current.Name
	current:Destroy()
	ChangeHistoryService:SetWaypoint("ClaudeCode: delete " .. name)
	return {success = true, deleted = name}
end

function Commands.get_stats()
	local partCount = 0
	local scriptCount = 0
	local meshCount = 0

	local function count(obj)
		if obj:IsA("BasePart") then partCount += 1 end
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then scriptCount += 1 end
		if obj:IsA("MeshPart") or obj:IsA("SpecialMesh") then meshCount += 1 end
		for _, child in ipairs(obj:GetChildren()) do
			count(child)
		end
	end
	count(game.Workspace)

	return {
		success = true,
		parts = partCount,
		scripts = scriptCount,
		meshes = meshCount,
		workspaceChildren = #game.Workspace:GetChildren(),
	}
end

-- ─── Файловый мост (polling-based) ──────────────────────────────────────────
-- Studio не может слушать HTTP, поэтому используем файловый обмен:
-- Claude Code пишет команду → плагин читает → выполняет → пишет результат

local COMMAND_FILE = os.getenv("HOME") .. "/Documents/Roblox/claude_command.json"
local RESPONSE_FILE = os.getenv("HOME") .. "/Documents/Roblox/claude_response.json"

local function readFile(path)
	local ok, content = pcall(function()
		return readfile and readfile(path) or nil
	end)
	if ok and content then return content end
	return nil
end

local function writeFile(path, content)
	pcall(function()
		if writefile then
			writefile(path, content)
		end
	end)
end

local function processCommand(commandJson)
	local ok, command = pcall(function()
		return HttpService:JSONDecode(commandJson)
	end)

	if not ok or not command or not command.action then
		return HttpService:JSONEncode({success = false, error = "Invalid command"})
	end

	local handler = Commands[command.action]
	if not handler then
		return HttpService:JSONEncode({success = false, error = "Unknown action: " .. command.action})
	end

	local resultOk, result = pcall(handler, command.params or {})
	if not resultOk then
		return HttpService:JSONEncode({success = false, error = tostring(result)})
	end

	return HttpService:JSONEncode(result)
end

-- ─── Toolbar UI ─────────────────────────────────────────────────────────────

local toolbar = plugin:CreateToolbar("Claude Code Bridge")
local toggleButton = toolbar:CreateButton(
	"Toggle Bridge",
	"Enable/disable Claude Code Bridge",
	"rbxassetid://4458901886"
)

local bridgeActive = false

toggleButton.Click:Connect(function()
	bridgeActive = not bridgeActive
	toggleButton:SetActive(bridgeActive)

	if bridgeActive then
		print("[ClaudeCodeBridge] Bridge activated - polling for commands")
	else
		print("[ClaudeCodeBridge] Bridge deactivated")
	end
end)

-- ─── Polling loop ───────────────────────────────────────────────────────────
-- Поскольку Studio plugin не может слушать HTTP-порт,
-- используем подход через Plugin:GetSetting/SetSetting для обмена данными

local lastCommandId = ""

game:GetService("RunService").Heartbeat:Connect(function()
	if not bridgeActive then return end

	-- Проверяем наличие новой команды через plugin settings
	local commandData = plugin:GetSetting("ClaudeCommand")
	if commandData and commandData ~= "" and commandData ~= lastCommandId then
		lastCommandId = commandData

		local ok, command = pcall(function()
			return HttpService:JSONDecode(commandData)
		end)

		if ok and command and command.id then
			print("[ClaudeCodeBridge] Processing command: " .. (command.action or "unknown"))
			local response = processCommand(commandData)
			plugin:SetSetting("ClaudeResponse", response)
			plugin:SetSetting("ClaudeResponseId", command.id)
			plugin:SetSetting("ClaudeCommand", "") -- Clear command
		end
	end
end)

-- ─── HTTP API Alternative ──────────────────────────────────────────────────
-- Если Studio запущена в play-mode с HttpService enabled,
-- плагин может слушать через ServerScriptService

local function setupHttpBridge()
	-- Создаём BindableFunction для доступа из command bar
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "ClaudeCodeBridge"
	bridge.Parent = game:GetService("ServerStorage")

	bridge.OnInvoke = function(commandJson)
		return processCommand(commandJson)
	end

	print("[ClaudeCodeBridge] BindableFunction bridge ready in ServerStorage")
end

pcall(setupHttpBridge)

print("[ClaudeCodeBridge] Plugin loaded. Click toolbar button to activate polling bridge.")
print("[ClaudeCodeBridge] Commands available: get_scene_tree, get_selection, get_object, find_objects, execute_luau, create_part, create_script, set_property, delete_object, get_stats")
