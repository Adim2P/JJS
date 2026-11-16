local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local WINDOW = 0.65
local MIN_REACTION_AGE = 0.08

local M1OutcomeTracker = {}
M1OutcomeTracker.__index = M1OutcomeTracker

function M1OutcomeTracker.new(config)
    local self = setmetatable({}, M1OutcomeTracker)

    self.Config = config
    self.Running = false
    self.Generation = 0
    self.Pending = {}
    self.DeflectIds = {}
    self.Connections = {}
    self.CharacterConnections = {}

    return self
end

function M1OutcomeTracker:GetPending()
    local now = os.clock()
    local candidate = nil
    local attacker = nil

    for _, event in ipairs(self.Pending) do
        local age = now - event.Started

        if event.Done
            or age < MIN_REACTION_AGE
            or age > WINDOW
            or event.Player.Character ~= event.Character then
            continue
        end

        if attacker and attacker ~= event.Player then
            return nil
        end

        attacker = event.Player

        if not candidate or event.Started > candidate.Started then
            candidate = event
        end
    end

    return candidate
end

function M1OutcomeTracker:Resolve(outcome, detail)
    local event = self:GetPending()

    if not event then
        return
    end

    event.Done = true

    print(
        "[M1 OUTCOME]",
        outcome,
        event.Player.Name,
        "M1=" .. tostring(event.M1),
        "delay=" .. string.format("%.3f", os.clock() - event.Started),
        detail or ""
    )
end

function M1OutcomeTracker:WatchCharacter(character)
    for _, connection in ipairs(self.CharacterConnections) do
        connection:Disconnect()
    end

    table.clear(self.CharacterConnections)
    table.clear(self.Pending)

    local humanoid = character:WaitForChild("Humanoid", 5)
    local animator = humanoid and humanoid:WaitForChild("Animator", 5)

    if not self.Running
        or LocalPlayer.Character ~= character
        or not humanoid
        or not animator then
        return
    end

    local previousHealth = humanoid.Health

    local healthConnection = humanoid.HealthChanged:Connect(function(health)
        if health < previousHealth then
            self:Resolve(
                "HIT_CANDIDATE",
                string.format("damage=%.2f", previousHealth - health)
            )
        end

        previousHealth = health
    end)

    table.insert(self.CharacterConnections, healthConnection)

    local animationConnection = animator.AnimationPlayed:Connect(function(track)
        local animation = track.Animation

        if not animation then
            return
        end

        local id = animation.AnimationId:match("(%d+)$")
        local deflectName = id and self.DeflectIds[id]

        if deflectName then
            self:Resolve("BLOCK_CANDIDATE", deflectName)
        end
    end)

    table.insert(self.CharacterConnections, animationConnection)
end

function M1OutcomeTracker:OnM1(player, character, m1)
    if not self.Running
        or type(m1) ~= "number"
        or m1 == 5
        or player.Character ~= character then
        return
    end

    local localCharacter = LocalPlayer.Character
    local root = localCharacter
        and localCharacter:FindFirstChild("HumanoidRootPart")

    local targetRoot = character:FindFirstChild("HumanoidRootPart")

    if not root or not targetRoot then
        return
    end

    if(root.Position - targetRoot.Position).Magnitude > self.Config.Range then
        return
    end

    local event = {
        Player = player,
        Character = character,
        M1 = m1,
        Started = os.clock(),
        Done = false
    }

    table.insert(self.Pending, event)

    local generation = self.Generation

    task.delay(WINDOW, function()
        if self.Running
            and self.Generation == generation
            and not event.Done then

            print(
                "[M1 OUTCOME]",
                "UNCONFIRMED",
                player.Name,
                "M1=" .. tostring(m1)
            )
        end

        event.Done = true

        for index = #self.Pending, 1, -1 do
            if self.Pending[index] == event then
                table.remove(self.Pending, index)
                break
            end
        end
    end)
end

function M1OutcomeTracker:Start()
    if self.Running or not self.Config.M1OutcomeDebug then
        return
    end

    local animations = ReplicatedStorage:FindFirstChild("Animations")
    local misc = animations and animations:FindFirstChild("Misc")
    local hits = misc and misc:FindFirstChild("Hits")
    local deflect = hits and hits:FindFirstChild("Deflect")

    if not deflect then
        warn("[M1 OUTCOME] Deflect registry unavailable")
        return
    end

    for _, instance in ipairs(deflect:GetDescendants()) do
        if instance:IsA("Animation") then
            local id = instance.AnimationId:match("(%d+)$")

            if id then
                self.DeflectIds[id] = instance.Name
            end
        end
    end

    self.Running = true
    self.Generation += 1

    local connection = LocalPlayer.CharacterAdded:Connect(function(character)
        task.spawn(function()
            self:WatchCharacter(character)
        end)
    end)

    table.insert(self.Connections, connection)

    if LocalPlayer.Character then
        task.spawn(function()
            self:WatchCharacter(LocalPlayer.Character)
        end)
    end

    print("[M1 OUTCOME] Passive tracking started")
end

function M1OutcomeTracker:Stop()
    self.Running = false
    self.Generation += 1

    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end

    for _, connection in ipairs(self.CharacterConnections) do
        connection:Disconnect()
    end

    table.clear(self.Connections)
    table.clear(self.CharacterConnections)
    table.clear(self.Pending)
    table.clear(self.DeflectIds)
end

return M1OutcomeTracker
