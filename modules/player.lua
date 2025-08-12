-- ===================================================================
--                        PLAYER MODULE
-- ===================================================================

local config = require(script.Parent.config)
local utils = require(script.Parent.utils)
local Services = config.Services
local player = config.Variables.player
local safeCall = utils.safeCall

-- ===================================================================
--                        WALKSPEED SYSTEM
-- ===================================================================
local function setWalkSpeed(speed)
    safeCall(function()
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end)
end

local function setJumpPower(power)
    safeCall(function()
        local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.JumpPower = power
        end
    end)
end

-- ===================================================================
--                        TELEPORT FUNCTIONS
-- ===================================================================
local function teleportToPlayer(targetPlayer)
    safeCall(function()
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end)
end

local function teleportToIsland(island)
    safeCall(function()
        if island and island:IsA("BasePart") then
            player.Character.HumanoidRootPart.CFrame = island.CFrame
        end
    end)
end

-- ===================================================================
--                         ESP SYSTEM
-- ===================================================================
local function enableESP()
    for _, targetPlayer in pairs(Services.Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            safeCall(function()
                local highlight = Instance.new("Highlight")
                highlight.Parent = targetPlayer.Character
                highlight.Name = "ZayrosESP"
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
            end)
        end
    end
end

local function disableESP()
    for _, targetPlayer in pairs(Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            local esp = targetPlayer.Character:FindFirstChild("ZayrosESP")
            if esp then esp:Destroy() end
        end
    end
end

-- ===================================================================
--                        PLAYER LIST UPDATE
-- ===================================================================
local function updatePlayerList(ListOfTpPlayer, connections)
    safeCall(function()
        -- Clear existing buttons
        for _, child in pairs(ListOfTpPlayer:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        -- Add current players
        local index = 0
        for _, targetPlayer in pairs(Services.Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                local btn = Instance.new("TextButton")
                btn.Name = targetPlayer.Name
                btn.Parent = ListOfTpPlayer
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                btn.Text = targetPlayer.Name
                btn.Size = UDim2.new(1, 0, 0.1, 0)
                btn.Position = UDim2.new(0, 0, (0.1 + 0.02) * index, 0)
                btn.TextScaled = true
                btn.Font = Enum.Font.GothamBold
                
                connections[#connections + 1] = btn.MouseButton1Click:Connect(function()
                    teleportToPlayer(targetPlayer)
                end)
                
                index = index + 1
            end
        end
    end)
end

-- ===================================================================
--                        CHARACTER RESPAWN
-- ===================================================================
local function setupCharacterRespawn(Settings)
    config.Variables.connections[#config.Variables.connections + 1] = player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to load
        setWalkSpeed(Settings.WalkSpeed)
        setJumpPower(Settings.JumpPower)
    end)
end

return {
    setWalkSpeed = setWalkSpeed,
    setJumpPower = setJumpPower,
    teleportToPlayer = teleportToPlayer,
    teleportToIsland = teleportToIsland,
    enableESP = enableESP,
    disableESP = disableESP,
    updatePlayerList = updatePlayerList,
    setupCharacterRespawn = setupCharacterRespawn
}
