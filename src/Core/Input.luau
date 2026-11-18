local Input = {}
Input.__index = Input

local BLOCK_KEY = 0x46
local MANUAL_M1_GRACE = 0.2
local STOP_RELEASE_TIMEOUT = 10

function Input.new(config, appState, trace)
    local self = setmetatable({}, Input)

    self.Config = config
    self.AppState = appState
    self.Trace = trace
    self.Holding = false
    self.ReleaseAt = 0
    self.RearmAt = 0
    self.Stopped = false
    self.ManualAttackHeld = false
    self.ManualOverrideUntil = 0
    self.StopReleaseDeadline = nil

    task.spawn(function()
        while not self.Stopped or self.Holding do
            if self.Stopped and self.StopReleaseDeadline
                and os.clock() >= self.StopReleaseDeadline then
                warn("[AUTOBLOCK] Release timed out; return to Roblox and release the block key manually.")
                break
            end
            if self.Holding then
                local shouldRelease =
                    self.Stopped
                    or self.ManualAttackHeld
                    or not self.AppState:IsRunning()
                    or not self.Config.Features.AutoBlock
                    or os.clock() >= self.ReleaseAt
                if shouldRelease then
                    self:Release()
                end
            end

            task.wait(0.03)
        end
    end)

    return self
end

function Input:ManualM1Started()
    if self.Stopped then
        return
    end

    self.ManualAttackHeld = true

    self.Trace:Log("MANUAL_M1_DOWN")

    self:Release()
end

function Input:ManualM1Ended()
    if self.Stopped or not self.ManualAttackHeld then
        return
    end

    self.ManualAttackHeld = false
    self.ManualOverrideUntil = math.max(
        self.ManualOverrideUntil,
        os.clock() + MANUAL_M1_GRACE
    )
    self.Trace:Log("MANUAL_M1_UP")
end

function Input:ManualAbilityUsed()
    if self.Stopped then
        return
    end

    self.ManualOverrideUntil = math.max(
        self.ManualOverrideUntil,
        os.clock() + self.Config.AbilityOverrideDuration
    )

    self.Trace:Log("MANUAL_ABILITY_OVERRIDE")
    self:Release()
end

function Input:PressBlock()
    if self.Stopped
        or not self.AppState:IsRunning()
        or not self.Config.Features.AutoBlock then

        self.Trace:Log("INPUT_SKIP", "inactive")
        return false
    end

    if self.ManualAttackHeld
        or os.clock() < self.ManualOverrideUntil then

        self.Trace:Log("INPUT_SKIP", "manual_m1_override")
        return false
    end

    if not self.Holding and os.clock() < self.RearmAt then
        self.Trace:Log("INPUT_SKIP", "block_rearming")
        return false
    end

    if not isrbxactive() then
        self.Trace:Log("INPUT_SKIP", "Roblox unfocused")
        return false
    end

    if not self.Holding then
        self.Trace:Log("F_DOWN_CALL")

        local success, err = pcall(keypress, BLOCK_KEY)

        if not success then
            self.Trace:Log("F_DOWN_ERROR", tostring(err))
            return false
        end

        self.Holding = true
        self.Trace:Log("F_DOWN_RETURN")
    else
        self.Trace:Log("F_HOLD_EXTENDED")
    end

    self.ReleaseAt = os.clock() + self.Config.BlockDuration

    return true
end

function Input:Release()
    if not self.Holding then
        return true
    end

    if not isrbxactive() then
        return false
    end

    self.Trace:Log(
        "F_UP_CALL",
        string.format("deadline_offset=%.1fms",
            (os.clock() - self.ReleaseAt) * 1000)
    )

    local success, err = pcall(keyrelease, BLOCK_KEY)
    if not success then
        warn("[AUTOBLOCK] Key release failed:", err)
        return false
    end

    self.Trace:Log("F_UP_RETURN")

    self.Holding = false
    self.ReleaseAt = 0
    self.RearmAt = os.clock() + self.Config.BlockRearmDelay

    if self.Config.Debug then
        print("[AUTOBLOCK] Block released.")
    end

    return true
end

function Input:Stop()
    if self.Stopped then
        return
    end

    self.Stopped = true
    self.StopReleaseDeadline = os.clock() + STOP_RELEASE_TIMEOUT

    if self.Holding and not isrbxactive() then
        warn("[AUTOBLOCK] Release pending: Roblox is unfocused")
    end

    self:Release()
end

return Input
