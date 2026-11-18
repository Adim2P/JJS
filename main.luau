local UserInputService = game:GetService("UserInputService")

local ROOT = "Roblox_Bullshit/"

local function import(path)
    local remoteRoot = getgenv().ShenanigansRemoteRoot
    local chunk, err

    if remoteRoot then
        local source = (game :: any):HttpGet(remoteRoot .. path, true)
        assert(source ~= "", "Failed to fetch: " .. path)

        chunk, err = loadstring(source, path)
    else
        chunk, err = loadfile(ROOT .. path)
    end

    assert(chunk, err or ("Failed to load: " .. path))

    return chunk()
end

-- Local Imports
local Config = import("src/Config.luau")
local AppState = import("src/Core/AppState.luau")
local Menu = import("src/UI/Menu.luau")
local Input = import("src/Core/Input.luau")
local AutoBlock = import("src/Combat/AutoBlock.luau")
local DirectionalLock = import("src/Combat/DirectionalLock.luau")
local M1Detector = import("src/Combat/M1Detector.luau")
local M1OutcomeTracker = import("src/Combat/M1OutcomeTracker.luau")
local PlayerTracker = import("src/Tracking/PlayerTracker.luau")
local Trace = import("src/Core/Trace.luau")
local FastInteract = import("src/Features/FastInteract.luau")
local ShowHiddenKills = import("src/Features/ShowHiddenKills.luau")
local TintedVision = import("src/Features/TintedVision.luau")


-- Import Initiator
local State = AppState.new()
local fastInteract = FastInteract.new()
local showHiddenKills = ShowHiddenKills.new()
local tintedVision = TintedVision.new(Config)
local trace = Trace.new(Config.Debug)
local blockInput = Input.new(Config, State, trace)
local directionalLock = DirectionalLock.new(Config, State, blockInput)
local defender = AutoBlock.new(Config, State, blockInput, trace, directionalLock)

local outcomeTracker = M1OutcomeTracker.new(Config)
outcomeTracker:Start()

local detector = M1Detector.new(function(player, character, m1)
    outcomeTracker:OnM1(player, character, m1)
    defender:OnM1(player, character, m1)
end, Config.Debug, trace)

local tracker = PlayerTracker.new(detector, Config.Debug, trace)

local menu
local keyConnection
local mouseReleasedConnection

local function shutdown()
    if not State:Stop() then
        return
    end

    tracker:Stop()
    detector:Stop()
    outcomeTracker:Stop()
    blockInput:Stop()
    directionalLock:Stop()
    fastInteract:Stop()
    showHiddenKills:Stop()
    tintedVision:Stop()

    if keyConnection then
        keyConnection:Disconnect()
        keyConnection = nil
    end

    if mouseReleasedConnection then
        mouseReleasedConnection:Disconnect()
        mouseReleasedConnection = nil
    end

    if menu then
        menu:Destroy()
        menu = nil
    end

    print("[Shenanigans] Application terminated.")
end

menu = Menu.new(Config, State, shutdown,
    function(enabled)
        fastInteract:SetEnabled(enabled)
    end,
    function(enabled)
        showHiddenKills:SetEnabled(enabled)
    end,
    function(enabled)
        return tintedVision:SetEnabled(enabled)
    end
)

keyConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        and not processed then

        blockInput:ManualM1Started()

    elseif not processed and (
        input.KeyCode == Enum.KeyCode.One
        or input.KeyCode == Enum.KeyCode.Two
        or input.KeyCode == Enum.KeyCode.Three
        or input.KeyCode == Enum.KeyCode.Four
    ) then
    blockInput:ManualAbilityUsed()

    elseif input.KeyCode == Enum.KeyCode.F6 then
        print("[Shenanigans] Toggling Overlay")
        menu:Toggle()

    elseif input.KeyCode == Enum.KeyCode.F7 then
        print("[Shenanigans] Emergency shutdown")
        shutdown()
    end
end)

mouseReleasedConnection = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        blockInput:ManualM1Ended()
    end
end)

tracker:Start()

print("[Shenanigans] Application initialized.")
print("[Shenanigans] Press F6 to toggle overlay.")
print("[Shenanigans] Press F7 to terminate.")
