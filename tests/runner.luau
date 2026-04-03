-- Test runner for Lune
-- Run with: lune run tests/runner

local MathUtils = require("../src/shared/utils/MathUtils")

local totalTests = 0
local passedTests = 0
local failedTests = 0

local function expect(testName: string, actual: any, expected: any)
	totalTests += 1
	if actual == expected then
		passedTests += 1
		print(`  ✅ {testName}`)
	else
		failedTests += 1
		print(`  ❌ {testName}: expected {expected}, got {actual}`)
	end
end

local function describe(suiteName: string, fn: () -> ())
	print(`\n📦 {suiteName}`)
	fn()
end

-- MathUtils tests
describe("MathUtils.lerp", function()
	expect("lerp(0, 10, 0) = 0", MathUtils.lerp(0, 10, 0), 0)
	expect("lerp(0, 10, 1) = 10", MathUtils.lerp(0, 10, 1), 10)
	expect("lerp(0, 10, 0.5) = 5", MathUtils.lerp(0, 10, 0.5), 5)
	expect("lerp clamps t > 1", MathUtils.lerp(0, 10, 2), 10)
	expect("lerp clamps t < 0", MathUtils.lerp(0, 10, -1), 0)
end)

describe("MathUtils.distance2D", function()
	expect("distance (0,0)→(3,4) = 5", MathUtils.distance2D(0, 0, 3, 4), 5)
	expect("distance (0,0)→(0,0) = 0", MathUtils.distance2D(0, 0, 0, 0), 0)
end)

describe("MathUtils.round", function()
	expect("round(3.14159, 2) = 3.14", MathUtils.round(3.14159, 2), 3.14)
	expect("round(3.5) = 4", MathUtils.round(3.5), 4)
	expect("round(3.4) = 3", MathUtils.round(3.4), 3)
end)

describe("MathUtils.isInRange", function()
	expect("(0,0)→(3,4) in range 5 = true", MathUtils.isInRange(0, 0, 3, 4, 5), true)
	expect("(0,0)→(3,4) in range 4 = false", MathUtils.isInRange(0, 0, 3, 4, 4), false)
end)

describe("MathUtils.calculateStreakReward", function()
	expect("base=50, day=5, bonus=10, max=30 → 100", MathUtils.calculateStreakReward(50, 5, 10, 30), 100)
	expect("streak capped at max", MathUtils.calculateStreakReward(50, 50, 10, 30), 350)
end)

describe("MathUtils.percentage", function()
	expect("50/100 = 50%", MathUtils.percentage(50, 100), 50)
	expect("0/0 = 0%", MathUtils.percentage(0, 0), 0)
	expect("clamps at 100%", MathUtils.percentage(200, 100), 100)
end)

-- Summary
local separator = string.rep("=", 40)
print(`\n{separator}`)
print(`📊 Results: {passedTests}/{totalTests} passed, {failedTests} failed`)

if failedTests > 0 then
	print("💥 SOME TESTS FAILED!")
	process.exit(1)
else
	print("🎉 ALL TESTS PASSED!")
end
