--[[
	Центральная конфигурация игры.
	Все числа, балансировка, настройки — здесь.
]]

local GameConfig = {
	-- Валюта
	STARTING_COINS = 100,
	MAX_COINS = 999999999,
	DAILY_REWARD_BASE = 50,
	DAILY_REWARD_STREAK_BONUS = 10,
	MAX_DAILY_STREAK = 30,

	-- Геймплей
	MAX_WALK_SPEED = 16,
	BOOST_WALK_SPEED = 32,
	JUMP_POWER = 50,
	RESPAWN_TIME = 3,
	INTERACTION_RANGE = 15,

	-- Монетизация
	GAME_PASSES = {
		VIP = { id = 0, price = 199, speedMultiplier = 1.5, coinsMultiplier = 2 },
		SKIP_STAGE = { id = 0, price = 49 },
		DOUBLE_COINS = { id = 0, price = 99, coinsMultiplier = 2 },
	},

	DEVELOPER_PRODUCTS = {
		COINS_100 = { id = 0, amount = 100, price = 25 },
		COINS_500 = { id = 0, amount = 500, price = 99 },
		COINS_2500 = { id = 0, amount = 2500, price = 399 },
	},

	-- Rate limits (calls per second)
	RATE_LIMITS = {
		PURCHASE = { maxCalls = 3, windowSeconds = 5 },
		INTERACT = { maxCalls = 10, windowSeconds = 1 },
		CHAT_COMMAND = { maxCalls = 2, windowSeconds = 1 },
	},

	-- Performance
	MAX_PARTS_BUDGET = 10000,
	TEXTURE_MAX_SIZE = 512,
	STREAMING_MIN_RADIUS = 64,
	STREAMING_TARGET_RADIUS = 1024,
}

return table.freeze(GameConfig)
