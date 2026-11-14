local globals = getgenv()

local branch = globals.ShenanigansBranch or "stable"

assert(
    type(branch) == "string" and branch ~="",
    "[SHENANIGANS] Invalid branch name"
)

local ROOT = "https://raw.githubusercontent.com/Adim2P/JJS/refs/heads/"
    .. branch .. "/"

local previousRoot = globals.ShenanigansRemoteRoot

globals.ShenanigansRemoteRoot = ROOT

local success, result = pcall(function()
    local source = (game :: any):HttpGet(ROOT .. "main.luau", true)

    assert(source ~= "", "Failed to download main.luau")

    local chunk, err = loadstring(source, "main.luau")
    assert(chunk, err)

    return chunk()
end)

globals.ShenanigansRemoteRoot = previousRoot

assert(success, "[Shenanigans] Branch '" .. branch .. "': " .. tostring(result))

print("[Shenanigans] Loaded branch:", branch)
