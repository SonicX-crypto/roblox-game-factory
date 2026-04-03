--[[
	Dev Server — запускается через: lune run lune/dev
	Устанавливает пакеты и запускает rojo serve для разработки
]]

local process = require("@lune/process")
local stdio = require("@lune/stdio")

stdio.write(
	"╔══════════════════════════════════════╗\n"
)
stdio.write("║       DEV SERVER                     ║\n")
stdio.write(
	"╚══════════════════════════════════════╝\n\n"
)

stdio.write("[1/2] Installing Wally packages...\n")
local wallyResult = process.spawn("wally", { "install" })
if not wallyResult.ok then
	stdio.ewrite("  ✗ Wally install failed\n")
	process.exit(1)
end

stdio.write("[2/2] Starting Rojo serve...\n")
stdio.write("  → Connect in Roblox Studio via Rojo plugin\n")
stdio.write("  → Press Ctrl+C to stop\n\n")

process.spawn("rojo", { "serve", "dev.project.json" }, {
	stdio = "inherit",
})
