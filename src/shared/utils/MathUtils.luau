--[[
	Утилиты для математических вычислений.
	Используется для расчёта урона, дистанций, прогрессии.
]]

local MathUtils = {}

-- Линейная интерполяция
function MathUtils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Расстояние между двумя точками (2D)
function MathUtils.distance2D(x1: number, y1: number, x2: number, y2: number): number
	local dx = x2 - x1
	local dy = y2 - y1
	return math.sqrt(dx * dx + dy * dy)
end

-- Зажать значение в пределах min..max
function MathUtils.clamp(value: number, min: number, max: number): number
	return math.clamp(value, min, max)
end

-- Округление до N знаков после запятой
function MathUtils.round(value: number, decimals: number?): number
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

-- Проверить, находится ли точка в радиусе
function MathUtils.isInRange(x1: number, y1: number, x2: number, y2: number, range: number): boolean
	return MathUtils.distance2D(x1, y1, x2, y2) <= range
end

-- Рассчитать награду с учётом стрика (формула прогрессии)
function MathUtils.calculateStreakReward(
	baseReward: number,
	streakDay: number,
	bonusPerDay: number,
	maxStreak: number
): number
	local effectiveStreak = math.min(streakDay, maxStreak)
	return baseReward + (effectiveStreak * bonusPerDay)
end

-- Процент от максимума (для UI progress bars)
function MathUtils.percentage(current: number, max: number): number
	if max == 0 then
		return 0
	end
	return MathUtils.clamp(current / max * 100, 0, 100)
end

return table.freeze(MathUtils)
