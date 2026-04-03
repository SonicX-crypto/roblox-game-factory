--[[
	Object Pool — переиспользование объектов вместо Destroy/Clone.
	Критично для производительности (пули, эффекты, частицы).
]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new(template, initialSize)
	local self = setmetatable({
		_template = template,
		_available = {},
		_inUse = {},
	}, ObjectPool)

	for _ = 1, initialSize or 10 do
		local obj = template:Clone()
		obj.Parent = nil
		table.insert(self._available, obj)
	end

	return self
end

function ObjectPool:Get()
	local obj = table.remove(self._available)
	if not obj then
		obj = self._template:Clone()
	end
	self._inUse[obj] = true
	return obj
end

function ObjectPool:Return(obj)
	if not self._inUse[obj] then
		return
	end
	self._inUse[obj] = nil
	obj.Parent = nil
	table.insert(self._available, obj)
end

function ObjectPool:Destroy()
	for obj in self._inUse do
		obj:Destroy()
	end
	for _, obj in self._available do
		obj:Destroy()
	end
	table.clear(self._available)
	table.clear(self._inUse)
end

return ObjectPool
