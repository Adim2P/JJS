local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Menu = {}
Menu.__index = Menu

local function createButton(parent, text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 27)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 55)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 12
    button.Text = text
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    return button
end

function Menu.new(
    config,
    appState,
    onShutdown,
    onFastInteractChanged,
    onShowHiddenKillsChanged
)
    local self = setmetatable({}, Menu)

    local gui = Instance.new("ScreenGui")
    gui.Name = "Adim's Shenanigans"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(200, 173)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    frame.Parent = gui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "Adim's Shenanigans"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame
    title.Active = true

    local dragging = false
    local dragStart = nil
    local windowStart = nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        dragging = true
        dragStart = input.Position
        windowStart = frame.Position
    end)

    self.DragMoveConnection = UserInputService.InputChanged:Connect(function(input)
        if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            windowStart.X.Scale,
            windowStart.X.Offset + delta.X,
            windowStart.Y.Scale,
            windowStart.Y.Offset + delta.Y
        )
    end)

    self.DragEndConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local checkbox = Instance.new("TextButton")
    checkbox.Name = "AutoBlockCheckbox"
    checkbox.Size = UDim2.fromOffset(18, 18)
    checkbox.Position = UDim2.fromOffset(12, 39)
    checkbox.Text = ""
    checkbox.BorderSizePixel = 0
    checkbox.Parent = frame

    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0.5, 0)
    checkboxCorner.Parent = checkbox

    local checkmark = Instance.new("TextLabel")
    checkmark.Size = UDim2.fromScale(1, 1)
    checkmark.BackgroundTransparency = 1
    checkmark.Text = "✓"
    checkmark.TextColor3 = Color3.new(0, 0, 0)
    checkmark.Font = Enum.Font.GothamBold
    checkmark.TextSize = 14
    checkmark.Parent = checkbox

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -48, 0, 24)
    label.Position = UDim2.fromOffset(36, 36)
    label.BackgroundTransparency = 1
    label.Text = "AutoBlock"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local function updateCheckbox()
        local enabled = config.Features.AutoBlock

        checkmark.Visible = enabled

        checkbox.BackgroundColor3 = enabled
            and Color3.fromRGB(241, 242, 243)
            or Color3.fromRGB(48, 48, 55)
    end

    checkbox.Activated:Connect(function()
        local enabled = not config.Features.AutoBlock

        config.Features.AutoBlock = enabled
        appState:SetPaused(not enabled)

        updateCheckbox()
    end)

    updateCheckbox()

    local fastCheckbox = checkbox:Clone()
    fastCheckbox.Name = "FastInteractionCheckbox"
    fastCheckbox.Position = UDim2.fromOffset(12, 70)
    fastCheckbox.Parent = frame

    local fastLabel = label:Clone()
    fastLabel.Text = "Fast Interact"
    fastLabel.Position = UDim2.fromOffset(36, 67)
    fastLabel.Parent = frame

    local fastCheckmark = fastCheckbox:FindFirstChildOfClass("TextLabel")

    local function updateFastCheckbox()
        local enabled = config.Features.FastInteract

        fastCheckmark.Visible = enabled
        fastCheckbox.BackgroundColor3 = enabled
            and Color3.fromRGB(241, 242, 243)
            or Color3.fromRGB(48, 48, 55)
    end

    fastCheckbox.Activated:Connect(function()
        local enabled = not config.Features.FastInteract

        config.Features.FastInteract = enabled
        onFastInteractChanged(enabled)
        updateFastCheckbox()
    end)

    updateFastCheckbox()

    local killsCheckbox = checkbox:Clone()
    killsCheckbox.Name = "ShowHiddenKillsCheckbox"
    killsCheckbox.Position = UDim2.fromOffset(12, 101)
    killsCheckbox.Parent = frame

    local killsLabel = label:Clone()
    killsLabel.Text = "Show Hidden Kills"
    killsLabel.Position = UDim2.fromOffset(36, 98)
    killsLabel.Parent = frame

    local killsCheckmark = killsCheckbox:FindFirstChildOfClass("TextLabel")

    local function updateKillsCheckbox()
        local enabled = config.Features.ShowHiddenKills

        killsCheckmark.Visible = enabled
        killsCheckbox.BackgroundColor3 = enabled
            and Color3.fromRGB(241, 242, 243)
            or Color3.fromRGB(48, 48, 55)
    end

    killsCheckbox.Activated:Connect(function()
        local enabled = not config.Features.ShowHiddenKills

        config.Features.ShowHiddenKills = enabled
        onShowHiddenKillsChanged(enabled)
        updateKillsCheckbox()
    end)

    updateKillsCheckbox()

    local shutdownButton = createButton(frame, "Shutdown", 134)

    shutdownButton.Activated:Connect(function()
        print("[Shenanigans] Shutdown button clicked")
        onShutdown()
    end)

    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    self.Gui = gui

    return self
end

function Menu:Toggle()
    if self.Gui then
        self.Gui.Enabled = not self.Gui.Enabled
    end
end

function Menu:Destroy()
    if self.DragMoveConnection then
        self.DragMoveConnection:Disconnect()
        self.DragMoveConnection = nil
    end

    if self.DragEndConnection then
        self.DragEndConnection:Disconnect()
        self.DragEndConnection = nil
    end

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

return Menu
