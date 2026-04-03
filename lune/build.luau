--[[
	Build Pipeline — запускается через: lune run lune/build
	Полный цикл: packages → sourcemap → darklua → rojo build
]]

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local function run(cmd: string, args: { string })
	stdio.write(`  → {cmd} {table.concat(args, " ")}\n`)
	local result = process.spawn(cmd, args)
	if not result.ok then
		stdio.ewrite(`  ✗ FAILED: {result.stderr}\n`)
		process.exit(1)
	end
	return result
end

stdio.write(
	"╔══════════════════════════════════════╗\n"
)
stdio.write("║       BUILD PIPELINE                 ║\n")
stdio.write(
	"╚══════════════════════════════════════╝\n\n"
)

-- 1. Install packages
stdio.write("[1/5] Installing Wally packages...\n")
run("wally", { "install" })

-- 2. Generate sourcemap
stdio.write("[2/5] Generating sourcemap...\n")
run("rojo", { "sourcemap", "default.project.json", "-o", "sourcemap.json" })

-- 3. Lint
stdio.write("[3/5] Linting with Selene...\n")
run("selene", { "src/" })

-- 4. Format check
stdio.write("[4/5] Checking format with StyLua...\n")
run("stylua", { "--check", "src/" })

-- 5. Build
stdio.write("[5/5] Building place file...\n")
if not fs.isDir("build") then
	fs.writeDir("build")
end
run("rojo", { "build", "default.project.json", "-o", "build/game.rbxl" })

stdio.write("\n✓ Build complete: build/game.rbxl\n")
