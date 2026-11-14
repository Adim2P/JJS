local Players = game:GetService("Players")

local ShowHiddenKills = {}
ShowHiddenKills.__index = ShowHiddenKills

function ShowHiddenKills.new()
    local self = setmetatable({}, ShowHiddenKills)

    self.Enabled = false
    self.Connections = {}
    self.Moved = {}
    self.WatchedPlayers = {}
    self.WatchedStats = {}
    self.WatchedHidden = {}

    return self
end

function ShowHiddenKills:Reveal(hidden)
    if not self.Enabled then
        return
    end

    local leaderstats = hidden.Parent
    local player = leaderstats and leaderstats.Parent

    if not player or player == Players.LocalPlayer then
        return
    end

    local kills = hidden:FindFirstChild("Kills")

    if not kills then
        return
    end

    if not kills:IsA("NumberValue") and not kills:IsA("IntValue") then
        return
    end

    self.Moved[kills] = {
        Hidden = hidden,
        Leaderstats = leaderstats
    }

    kills.Parent = leaderstats
end

function ShowHiddenKills:WatchHidden(hidden)
    if self.WatchedHidden[hidden] then
        return
    end

    self.WatchedHidden[hidden] = true

    local connection = hidden.ChildAdded:Connect(function(child)
        if child.Name == "Kills" then
            self:Reveal(hidden)
        end
    end)

    table.insert(self.Connections, connection)
    self:Reveal(hidden)
end

function ShowHiddenKills:WatchStats(leaderstats)
    if self.WatchedStats[leaderstats] then
        return
    end

    self.WatchedStats[leaderstats] = true

    local connection = leaderstats.ChildAdded:Connect(function(child)
        if child.Name == "Hidden" and child:IsA("Folder") then
            self:WatchHidden(child)
        end
    end)

    table.insert(self.Connections, connection)

    local hidden = leaderstats:FindFirstChild("Hidden")

    if hidden and hidden:IsA("Folder") then
        self:WatchHidden(hidden)
    end
end

function ShowHiddenKills:WatchPlayer(player)
    if player == Players.LocalPlayer or self.WatchedPlayers[player] then
        return
    end

    self.WatchedPlayers[player] = true

    local connection = player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            self:WatchStats(child)
        end
    end)

    table.insert(self.Connections, connection)

    local leaderstats = player:FindFirstChild("leaderstats")

    if leaderstats then
        self:WatchStats(leaderstats)
    end
end

function ShowHiddenKills:SetEnabled(enabled)
    if self.Enabled == enabled then
        return
    end

    self.Enabled = enabled

    if enabled then
        local connection = Players.PlayerAdded:Connect(function(player)
            self:WatchPlayer(player)

            task.delay(1, function()
                if not self.Enabled or player.Parent ~= Players then
                    return
                end

                local leaderstats = player:FindFirstChild("leaderstats")

                if not leaderstats then
                    return
                end

                self:WatchStats(leaderstats)

                local hidden = leaderstats:FindFirstChild("Hidden")

                if hidden and hidden:IsA("Folder") then
                    self:WatchHidden(hidden)
                    self:Reveal(hidden)
                end
            end)
        end)

        table.insert(self.Connections, connection)

        for _, player in ipairs(Players:GetPlayers()) do
            self:WatchPlayer(player)
        end
    else
        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end

        for kills, original in pairs(self.Moved) do
            if kills.Parent == original.Leaderstats
                and original.Hidden.Parent == original.Leaderstats then

                kills.Parent = original.Hidden
            end
        end

        table.clear(self.Connections)
        table.clear(self.Moved)
        table.clear(self.WatchedPlayers)
        table.clear(self.WatchedStats)
        table.clear(self.WatchedHidden)
    end
end

function ShowHiddenKills:Stop()
    self:SetEnabled(false)
end

return ShowHiddenKills
