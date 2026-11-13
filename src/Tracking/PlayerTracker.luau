local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlayerTracker = {}
PlayerTracker.__index = PlayerTracker

function PlayerTracker.new(detector, debugEnabled, trace)
    local self = setmetatable({}, PlayerTracker)

    self.Detector = detector
    self.Debug = debugEnabled
    self.Trace = trace
    self.Connections = {}
    self.Started = false

    return self
end

function PlayerTracker:WatchSelf(character)
    if self.SelfConnection then
        self.SelfConnection:Disconnect()
    end

    self.SelfConnection = character.AttributeChanged:Connect(function(attribute)
        if attribute ~= "BlockTry"
            and attribute ~= "Stun"
            and attribute ~= "Ragdoll" then
            return
        end

        if self.Debug then
            self.Trace:Log(
                "SELF_" .. string.upper(attribute),
                "value=" .. tostring(character:GetAttribute(attribute))
            )
        end
    end)
end

function PlayerTracker:Watch(player)
    if player == LocalPlayer or self.Connections[player] then
        return
    end

    self.Connections[player] =
        player.CharacterAdded:Connect(function(character)
            self.Detector:Watch(player, character)
        end)

    if player.Character then
        self.Detector:Watch(player, player.Character)
    end
    
    if self.Debug then
        print("[TRACKING]", player.Name)
    end
end

function PlayerTracker:Unwatch(player)
    local connection = self.Connections[player]

    if not connection then
        return
    end

    connection:Disconnect()
    self.Connections[player] = nil

    self.Detector:Unwatch(player)

    if self.Debug then
        print("[UNTRACKED]", player.Name)
    end
end

function PlayerTracker:Start()
    if self.Started then
        return
    end

    self.Started = true

    self.PlayerAddedConnection =
        Players.PlayerAdded:Connect(function(player)
            self:Watch(player)
        end)
    
    self.PlayerRemovingConnection = 
        Players.PlayerRemoving:Connect(function(player)
            self:Unwatch(player)
        end)

    self.SelfCharacterConnection =
        LocalPlayer.CharacterAdded:Connect(function(character)
            self:WatchSelf(character)
        end)

    if LocalPlayer.Character then
        self:WatchSelf(LocalPlayer.Character)
    end

    for _, player in Players:GetPlayers() do
        self:Watch(player)
    end

    print("[AUTOBLOCK] Player tracking started.")
end

function PlayerTracker:Stop()
    if not self.Started then
        return
    end

    self.Started = false

    self.PlayerAddedConnection:Disconnect()
    self.PlayerRemovingConnection:Disconnect()
    self.SelfCharacterConnection:Disconnect()

    if self.SelfConnection then
        self.SelfConnection:Disconnect()
        self.SelfConnection = nil
    end

    for player in pairs(self.Connections) do
        self:Unwatch(player)
    end
end

return PlayerTracker
