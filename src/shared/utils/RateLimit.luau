--[[
	Rate Limiter — защита от спама RemoteEvent.
	Используется на сервере для каждого remote-вызова.
]]

local Players = game:GetService("Players")

local RateLimit = {}

local playerLimits = {}

Players.PlayerAdded:Connect(function(player)
	playerLimits[player] = {}
end)

Players.PlayerRemoving:Connect(function(player)
	playerLimits[player] = nil
end)

function RateLimit.check(player, actionName, maxCalls, windowSeconds)
	local limits = playerLimits[player]
	if not limits then
		return false
	end

	local now = os.clock()
	local data = limits[actionName]

	if not data or (now - data.windowStart) >= windowSeconds then
		limits[actionName] = { callCount = 1, windowStart = now }
		return true
	end

	data.callCount += 1
	if data.callCount > maxCalls then
		return false
	end

	return true
end

return RateLimit
