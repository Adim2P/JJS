local ROOT = "https://raw.githubusercontent.com/Adim2P/JJS/stable/"

local globals = getgenv()
local previousRoot = globals.ShenanigansRemoteRoot

globals.ShenanigansRemoteRoot = ROOT

local source = (game :: any):HttpGet(ROOT .. "main.luau", true)
assert(source ~= "", "Failed to download main.luau")

local chunk, err = loadstring(source, "main.luau")
assert(chunk, err)

local success, result = pcall(chunk)

globals.ShenanigansRemoteRoot = previousRoot

assert(success, result)