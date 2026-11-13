local Players = game:GetService("Players")

local Menu = {}
Menu.__index = Menu

local function createButton(parent, text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 32)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(48, 48, 55)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Text = text
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    return button
end

function Menu.new(config, appState, onShutdown)
    local self = setmetatable({}, Menu)

    local gui = Instance.new("ScreenGui")
    gui.Name = "Adim's Shenanigans"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(230, 130)
    frame.Position = UDim2.new(1, -250, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    frame.Parent = gui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "Adim's Shenanigans"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = frame

    local checkbox = Instance.new("TextButton")
    checkbox.Name = "AutoBlockCheckbox"
    checkbox.Size = UDim2.fromOffset(22, 22)
    checkbox.Position = UDim2.fromOffset(12, 46)
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
    checkmark.TextSize = 17
    checkmark.Parent = checkbox

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 0, 28)
    label.Position = UDim2.fromOffset(43, 43)
    label.BackgroundTransparency = 1
    label.Text = "AutoBlock"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
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

    local shutdownButton = createButton(frame, "Shutdown", 85)

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
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

return Menu
