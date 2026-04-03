--[[
	Feature Flags — переключатели функций.
	Позволяет включать/выключать фичи без деплоя.
	В продакшене можно подгружать из DataStore.
]]

local RunService = game:GetService("RunService")

local FeatureFlags = {
	-- Gameplay
	NEW_COMBAT_SYSTEM = false,
	DOUBLE_XP_EVENT = false,
	PETS_ENABLED = true,
	DAILY_REWARDS = true,

	-- Monetization
	REWARDED_ADS = false,
	SUBSCRIPTIONS = false,

	-- Debug (auto-enabled in Studio)
	DEBUG_MODE = RunService:IsStudio(),
	SHOW_HITBOXES = false,
	LOG_REMOTES = RunService:IsStudio(),
}

return table.freeze(FeatureFlags)
