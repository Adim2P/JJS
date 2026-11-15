local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local DirectionalLock = {}
DirectionalLock.__index = DirectionalLock

function DirectionalLock.new(config, appState, input)
    local self = setmetatable({}, DirectionalLock)

    self.Config = config
    self.AppState = appState
    self.Input = input

    self.TargetPlayer = nil
    self.TargetCharacter = nil
    self.Humanoid = nil
    self.PreviousAutoRotate = nil
    self.Connection = nil

    return self
end

function DirectionalLock:Update()
    if not self.Input.Holding
        or not self.AppState:IsRunning()
        or not self.Config.Features.AutoBlock
        or not self.Config.Features.DirectionalLock then
        self:Stop()
        return
    end

    local character = LocalPlayer.Character

    if not character
        or self.Humanoid.Parent ~= character
        or self.TargetPlayer.Character ~= self.TargetCharacter then
        self:Stop()
        return
    end

    if self.Humanoid.Health <= 0
        or (character:GetAttribute("Ragdoll") or 0) ~= 0 then
        self:Stop()
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local targetRoot = self.TargetCharacter:FindFirstChild("HumanoidRootPart")

    if not root or not targetRoot then
        self:Stop()
        return
    end

    local offset = targetRoot.Position - root.Position

    if offset.Magnitude > self.Config.TrackingRange then
        self:Stop()
        return
    end

    local direction = Vector3.new(offset.X, 0, offset.Z)

    if direction.Magnitude < 0.05 then
        return
    end

    root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
end

function DirectionalLock:Start(player, targetCharacter)
    if not self.Config.Features.DirectionalLock
        or not self.Input.Holding then
        return
    end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        return
    end

    if self.Humanoid ~= humanoid then
        self:Stop()

        self.Humanoid = humanoid
        self.PreviousAutoRotate = humanoid.AutoRotate
    end

    self.TargetPlayer = player
    self.TargetCharacter = targetCharacter

    humanoid.AutoRotate = false

    self:Update()

    if self.Humanoid and not self.Connection then
        self.Connection = RunService.Heartbeat:Connect(function()
            self:Update()
        end)
    end
end

function DirectionalLock:Stop()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end

    if self.Humanoid and self.Humanoid.Parent then
        self.Humanoid.AutoRotate = self.PreviousAutoRotate
    end

    self.TargetPlayer = nil
    self.TargetCharacter = nil
    self.Humanoid = nil
    self.PreviousAutoRotate = nil
end

return DirectionalLock
