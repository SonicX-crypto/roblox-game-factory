--[[
	Player data schema — определяет структуру сохраняемых данных игрока.
	Используется ProfileStore для сохранения.

	Тип PlayerData:
	- level, xp, stage — прогресс
	- coins, totalCoinsEarned — экономика
	- dailyStreak, lastDailyReward — daily rewards
	- inventory, equippedItems — предметы
	- settings — настройки игрока
	- firstJoinTimestamp, totalPlayTime, sessionCount — метаданные
]]

local PlayerData = {}

function PlayerData.getDefault()
	return {
		level = 1,
		xp = 0,
		stage = 1,

		coins = 100,
		totalCoinsEarned = 0,

		dailyStreak = 0,
		lastDailyReward = 0,

		inventory = {},
		equippedItems = {},

		settings = {
			musicVolume = 0.5,
			sfxVolume = 0.8,
			showParticles = true,
		},

		firstJoinTimestamp = os.time(),
		totalPlayTime = 0,
		sessionCount = 0,
	}
end

return PlayerData
