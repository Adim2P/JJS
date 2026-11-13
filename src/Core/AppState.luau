local AppState = {}
AppState.__index = AppState

function AppState.new()
    local self =  setmetatable({}, AppState)

    self.Status = "running"

    return self
end

function AppState:IsRunning()
    return self.Status == "running"
end

function AppState:IsStopped()
    return self.Status == "stopped"
end

function AppState:SetPaused(paused)
    if self:IsStopped() then
        return
    end

    self.Status = paused and "paused" or "running"

    print("[Shenanigans] Application State:", self.Status)
end

function AppState:Stop()
    if self:IsStopped() then
        return false
    end

    self.Status = "stopped"
    return true
end

return AppState
