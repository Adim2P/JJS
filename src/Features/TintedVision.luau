local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local TintedVision = {}
TintedVision.__index = TintedVision

function TintedVision.new(config)
    local self = setmetatable({}, TintedVision)

    self.Enabled = false
    self.Range = config.TintedVisionRange
    self.ScanInterval = config.TintedVisionScanInterval

    self.Template = nil
    self.TrackedPlayers = {}
    self.Clones = {}
    self.Elapsed = 0

    self.PlayerAddedConnection = nil
    self.PlayerRemovingConnection = nil
    self.ScanConnection = nil

    return self
end

function TintedVision:Remove(player)
    local clone = self.Clones[player]

    if clone then
        clone:Destroy()
        self.Clones[player] = nil
    end
end

function TintedVision:Scan()
    local character = LocalPlayer.Character
    local localRoot = character and character:FindFirstChild("HumanoidRootPart")

    for player in pairs(self.TrackedPlayers) do
        local targetCharacter = player.Character
        local targetRoot = targetCharacter
            and targetCharacter:FindFirstChild("HumanoidRootPart")

        if not localRoot or not targetRoot then
            self:Remove(player)
            continue
        end

        if not localRoot:IsA("BasePart")
            or not targetRoot:IsA("BasePart") then
            self:Remove(player)
            continue
        end

        local distance = (localRoot.Position - targetRoot.Position).Magnitude

        if distance > self.Range then
            self:Remove(player)
            continue
        end

        local clone = self.Clones[player]

        if clone and clone.Parent ~= targetRoot then
            self:Remove(player)
            clone = nil
        end

        if clone then
            continue
        end

        local newClone = self.Template:Clone()

        if not newClone then
            continue
        end

        newClone.Name = "ShenanigansTintedVision"
        newClone.MaxDistance = self.Range
        newClone.Enabled = true

        local handle = newClone:FindFirstChild("Handle")

        if handle and handle:IsA("LayerCollector") then
            handle.Enabled = true
        end

        newClone.Parent = targetRoot
        self.Clones[player] = newClone
    end
end

function TintedVision:SetEnabled(enabled)
    if self.Enabled == enabled then
        return true
    end

    if enabled then
        local utils = ReplicatedStorage:FindFirstChild("Utils")
        local template = utils and utils:FindFirstChild("Reveal")

        if not template or not template:IsA("BillboardGui") then
            warn("[TINTED] Native Reveal template unavailable")
            return false
        end

        self.Template = template
        self.Enabled = true
        self.Elapsed = 0

        self.PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer then
                self.TrackedPlayers[player] = true
            end
        end)

        self.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
            self.TrackedPlayers[player] = nil
            self:Remove(player)
        end)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self.TrackedPlayers[player] = true
            end
        end

        self.ScanConnection = RunService.Heartbeat:Connect(function(deltaTime)
            self.Elapsed += deltaTime

            if self.Elapsed < self.ScanInterval then
                return
            end

            self.Elapsed = 0
            self:Scan()
        end)

        self:Scan()

        print("[TINTED]: Vision enabled")
    else
        self.Enabled = false

        if self.ScanConnection then
            self.ScanConnection:Disconnect()
            self.ScanConnection = nil
        end

        if self.PlayerAddedConnection then
            self.PlayerAddedConnection:Disconnect()
            self.PlayerAddedConnection = nil
        end

        if self.PlayerRemovingConnection then
            self.PlayerRemovingConnection:Disconnect()
            self.PlayerRemovingConnection = nil
        end

        for player in pairs(self.Clones) do
            self:Remove(player)
        end

        table.clear(self.TrackedPlayers)

        self.Template = nil
        self.Elapsed = 0

        print("[TINTED] Vision disabled")
    end

    return true
end

function TintedVision:Stop()
    self:SetEnabled(false)
end

return TintedVision
