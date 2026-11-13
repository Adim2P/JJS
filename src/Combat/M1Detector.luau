local M1Detector = {}
M1Detector.__index = M1Detector

function M1Detector.new(onM1, debugEnabled, trace)
    local self = setmetatable({}, M1Detector)

    self.OnM1 = onM1
    self.Debug = debugEnabled
    self.Trace = trace
    self.Connections = {}

    return self
end

function M1Detector:Watch(player, character)
    self:Unwatch(player)

    local connection =
        character:GetAttributeChangedSignal("CurrentM1"):Connect(function()
            if player.Character ~= character then
                return
            end

            local m1 = character:GetAttribute("CurrentM1")

            if self.Debug then
                self.Trace:Log(
                    "M1_CHANGED",
                    player.Name,
                    "M1=" .. tostring(m1),
                    "LastM1=" .. tostring(character:GetAttribute("LastM1"))
                )
            end

            if type(m1) == "number" then
                self.OnM1(player, character, m1)
            end
        end)

    self.Connections[player] = connection

    if self.Debug then
        print("[WATCHING]", player.Name)
    end
end

function M1Detector:Unwatch(player)
    local connection = self.Connections[player]

    if connection then
        connection:Disconnect()
        self.Connections[player] = nil
    end
end

function M1Detector:Stop()
    for player in pairs(self.Connections) do
        self:Unwatch(player)
    end
end

return M1Detector
