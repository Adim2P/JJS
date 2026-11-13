local Trace = {}
Trace.__index = Trace

function Trace.new(enabled)
    local self = setmetatable({}, Trace)

    self.Enabled = enabled
    self.Started = os.clock()

    return self
end

function Trace:Log(event, ...)
    if not self.Enabled then
        return
    end

    local elapsed = (os.clock() - self.Started) * 1000

    print(
        string.format("[TRACE +%.1fms] %s", elapsed, event),
        ...
    )
end

return Trace
