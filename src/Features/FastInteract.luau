local ProximityPromptService = game:GetService("ProximityPromptService")

local FastInteract = {}
FastInteract.__index = FastInteract

function FastInteract.new()
    local self = setmetatable({}, FastInteract)

    self.Enabled = false
    self.OriginalDurations = {}

    self.Connection = ProximityPromptService.PromptShown:Connect(function(prompt)
        if self.Enabled then
            self:Apply(prompt)
        end
    end)

    return self
end

function FastInteract:Apply(prompt)
    if not prompt:IsA("ProximityPrompt") then
        return
    end

    if self.OriginalDurations[prompt] == nil then
        self.OriginalDurations[prompt] = prompt.HoldDuration
    end

    prompt.HoldDuration = 0
end

function FastInteract:SetEnabled(enabled)
    if self.Enabled == enabled then
        return
    end

    self.Enabled = enabled

    if enabled then
        for _, instance in ipairs(game:GetDescendants()) do
            if instance:IsA("ProximityPrompt") then
                self:Apply(instance)
            end
        end
    else
        for prompt, duration in pairs(self.OriginalDurations) do
            if prompt.Parent then
                prompt.HoldDuration = duration
            end
            self.OriginalDurations[prompt] = nil
        end
    end
end

function FastInteract:Stop()
    self:SetEnabled(false)

    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

return FastInteract
