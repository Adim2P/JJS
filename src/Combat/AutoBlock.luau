local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local AutoBlock = {}
AutoBlock.__index = AutoBlock

function AutoBlock.new(config, appState, input, trace, directionalLock)
    local self = setmetatable({}, AutoBlock)

    self.Config = config
    self.AppState = appState
    self.Input = input
    self.Trace = trace
    self.DirectionalLock = directionalLock

    return self
end

function AutoBlock:OnM1(player, targetCharacter, m1)
    local function skip(reason, distance)
        if self.Config.Debug then
            self.Trace:Log(
                "BLOCK_SKIP",
                player.Name,
                "M1=" .. tostring(m1),
                "reason=" .. reason,
                distance and string.format("dist=%.2f", distance) or ""
            )
        end
    end

    if not self.AppState:IsRunning()
        or not self.Config.Features.AutoBlock then
        skip("disabled_or_paused")
        return
    end

    if player.Character ~= targetCharacter then
        skip("stale_character")
        return
    end

    if type(m1) ~= "number" then
        skip("non_numeric_m1")
        return
    end

    if m1 == 5 then
        skip("m1_5_nonattack")
        return
    end

    local character = LocalPlayer.Character
    local root = character
        and character:FindFirstChild("HumanoidRootPart")

    local enemyRoot = targetCharacter
        and targetCharacter:FindFirstChild("HumanoidRootPart")

    if not root or not enemyRoot then
        skip("missing_root")
        return
    end

    local ragdoll = character:GetAttribute("Ragdoll")

    if (ragdoll or 0) ~= 0 then
        skip("ragdoll")
        return
    end

    local offset = enemyRoot.Position - root.Position
    local distance = offset.Magnitude

    if distance == 0 or distance > self.Config.Range then
        skip("out_of_range", distance)
        return
    end

    if self.Config.Debug then
        local facing = root.CFrame.LookVector:Dot(offset.Unit)

        self.Trace:Log(
            "M1_ELIGIBLE",
            player.Name,
            "M1=" .. tostring(m1),
            string.format("dist=%.2f", distance),
            string.format("facing=%.2f", facing),
            "stun=" .. tostring(character:GetAttribute("Stun")),
            "blocktry=" .. tostring(character:GetAttribute("BlockTry"))
        )
    end

    local requested = self.Input:PressBlock()

    if requested then
        self.DirectionalLock:Start(player, targetCharacter)
    end

    if self.Config.Debug then
        self.Trace:Log(
            requested and "BLOCK_REQUEST_OK" or "BLOCK_REQUEST_DENIED",
            player.Name,
            "M1=" .. tostring(m1)
        )
    end
end

return AutoBlock
