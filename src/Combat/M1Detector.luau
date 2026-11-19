local KNOWN_ITADORI_M1  = {
    ["95295463826732"] = true,
    ["105077924973072"] = true,
    ["98783064085844"] = true
}
local M1Detector = {}
M1Detector.__index = M1Detector

function M1Detector.new(onM1, debugEnabled, trace)
    local self = setmetatable({}, M1Detector)

    self.OnM1 = onM1
    self.Debug = debugEnabled
    self.Trace = trace
    self.Connections = {}
    self.AnimationConnections = {}

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
        task.spawn(function()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
                or character:WaitForChild("Humanoid", 5)

            local animator = humanoid and (
                humanoid:FindFirstChildOfClass("Animator")
                or humanoid:WaitForChild("Animator", 5)
            )

            if not animator
                or player.Character ~= character
                or self.Connections[player] ~= connection then
                return
            end

            self.AnimationConnections[player] =
                animator.AnimationPlayed:Connect(function(track)
                    local animation = track.Animation

                    if not animation
                        or track.Priority.Value < Enum.AnimationPriority.Action.Value then
                        return
                    end

                    local id = animation.AnimationId:match("(%d+)$")
                    local moveset = character:GetAttribute("Moveset")

                    local knownM1 =
                        moveset == "Itadori"
                        and KNOWN_ITADORI_M1[id] == true

                    self.Trace:Log(
                        "ACTION_ANIM",
                        player.Name,
                        "moveset=" .. tostring(moveset),
                        "id=" .. tostring(id),
                        "knownM1=" .. tostring(knownM1),
                        "CurrentM1=" .. tostring(character:GetAttribute("CurrentM1")),
                        "LastM1=" .. tostring(character:GetAttribute("LastM1"))
                    )
                end)
        end)
    end

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

    local animationConnection = self.AnimationConnections[player]

    if animationConnection then
        animationConnection:Disconnect()
        self.AnimationConnections[player] = nil
    end
end

function M1Detector:Stop()
    for player in pairs(self.Connections) do
        self:Unwatch(player)
    end
end

return M1Detector
