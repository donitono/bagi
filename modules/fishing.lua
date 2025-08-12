-- ===================================================================
--                        FISHING MODULE
-- ===================================================================

local config = require(script.Parent.config)
local utils = require(script.Parent.utils)
local stats = require(script.Parent.stats)
local Services = config.Services
local Remotes = config.Remotes
local player = config.Variables.player
local randomWait = utils.randomWait
local safeCall = utils.safeCall
local createNotification = utils.createNotification
local Stats = stats.Stats
local getFishRarity = stats.getFishRarity
local simulateFishValue = stats.simulateFishValue
local updateLuckLevel = stats.updateLuckLevel

-- ===================================================================
--                    SMART FISHING SYSTEM
-- ===================================================================
local function smartFishingLogic(Settings, LuckSystem)
    if not Settings.SmartFishing then return true end
    
    -- Skip fishing during low-luck periods
    local currentLuck = stats.calculateCurrentLuck(Settings)
    if currentLuck < LuckSystem.baseChance * 0.8 then
        return false
    end
    
    -- Check fish value filter
    if Settings.FishValueFilter then
        local estimatedValue = math.random(10, 100) -- Simulate fish detection
        if estimatedValue < Settings.MinFishValue then
            return false
        end
    end
    
    return true
end

-- ===================================================================
--                      AUTO FISHING SYSTEM
-- ===================================================================
local function enhancedAutoFishing(Settings)
    task.spawn(function()
        while Settings.AutoFishing do
            safeCall(function()
                -- Safety check - stop if player is in danger
                if Settings.SafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 20 then
                        warn("⚠️ Low health detected! Stopping auto fishing for safety.")
                        task.wait(5)
                        return
                    end
                end
                
                -- Smart fishing check
                if not smartFishingLogic(Settings, stats.LuckSystem) then
                    task.wait(randomWait() * 2) -- Wait longer during bad conditions
                    return
                end
                
                -- Add random delays to avoid detection
                task.wait(randomWait())
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    Remotes.CancelFishing:InvokeServer()
                    task.wait(randomWait())
                    Remotes.EquipRod:FireServer(1)
                end

                task.wait(randomWait())
                Remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(randomWait())
                Remotes.RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + randomWait())
                Remotes.FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Simulate fish catch with luck system
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🎣 Caught " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                -- Update luck XP
                updateLuckLevel()
                
                -- Auto sell when inventory might be full
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(1)
                    safeCall(function()
                        Remotes.sellAll:InvokeServer()
                        createNotification("🛒 Auto-sold items! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 215, 0))
                    end)
                end
            end)
        end
    end)
end

-- ===================================================================
--                      AFK2 AUTOFISHING SYSTEM  
-- ===================================================================
local function getAFK2Delay(Settings)
    if Settings.AFK2_DelayMode == "RANDOM" then
        return math.random(Settings.AFK2_MinDelay * 1000, Settings.AFK2_MaxDelay * 1000) / 1000
    elseif Settings.AFK2_DelayMode == "CUSTOM" then
        return Settings.AFK2_CustomDelay
    elseif Settings.AFK2_DelayMode == "FIXED" then
        return Settings.AFK2_FixedDelay
    else
        return 1.0 -- Default fallback
    end
end

local function autoFishingAFK2(Settings)
    task.spawn(function()
        while Settings.AutoFishingAFK2 do
            safeCall(function()
                -- Safety check
                if Settings.SafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 20 then
                        warn("⚠️ [AFK2] Low health detected! Stopping auto fishing.")
                        task.wait(5)
                        return
                    end
                end
                
                -- Smart fishing check
                if not smartFishingLogic(Settings, stats.LuckSystem) then
                    task.wait(getAFK2Delay(Settings))
                    return
                end
                
                -- Custom delay before starting
                task.wait(getAFK2Delay(Settings))
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    Remotes.CancelFishing:InvokeServer()
                    task.wait(getAFK2Delay(Settings))
                    Remotes.EquipRod:FireServer(1)
                end

                task.wait(getAFK2Delay(Settings))
                Remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(getAFK2Delay(Settings))
                Remotes.RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + getAFK2Delay(Settings))
                Remotes.FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Simulate fish catch with luck system
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🎣 [AFK2] Caught " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                -- Update luck XP
                updateLuckLevel()
                
                -- Auto sell when inventory might be full
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(getAFK2Delay(Settings))
                    safeCall(function()
                        Remotes.sellAll:InvokeServer()
                        createNotification("🛒 [AFK2] Auto-sold items! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 215, 0))
                    end)
                end
                
                -- Additional delay at the end of cycle
                task.wait(getAFK2Delay(Settings))
            end)
        end
    end)
end

-- ===================================================================
--                    EXTREME AUTOFISHING SYSTEM  
-- ===================================================================
local function getExtremeDelay(Settings)
    if Settings.ExtremeSpeed == "LOW" then
        return 0.15
    elseif Settings.ExtremeSpeed == "MEDIUM" then
        return 0.1
    elseif Settings.ExtremeSpeed == "HIGH" then
        return 0.05
    elseif Settings.ExtremeSpeed == "INSANE" then
        return 0.01
    else
        return Settings.ExtremeDelay
    end
end

local function autoFishingExtreme(Settings)
    task.spawn(function()
        while Settings.AutoFishingExtreme do
            safeCall(function()
                -- Minimal safety check (only if ExtremeSafeMode is enabled)
                if Settings.ExtremeSafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 10 then
                        warn("⚠️ [EXTREME] Critical health! Pausing...")
                        task.wait(2)
                        return
                    end
                end
                
                -- Ultra fast delay
                local extremeDelay = getExtremeDelay(Settings)
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    Remotes.EquipRod:FireServer(1)
                    task.wait(extremeDelay)
                end

                -- Rapid fire fishing sequence
                Remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                task.wait(extremeDelay)
                
                Remotes.RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                task.wait(extremeDelay)
                
                Remotes.FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Quick fish value calculation
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                -- Only show notifications for rare fish to avoid spam
                if rarity == "Legendary" or rarity == "Mythical" then
                    createNotification("⚡ [EXTREME] " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    Stats.bestFish = rarity .. " Fish"
                end
                
                -- Quick luck update
                updateLuckLevel()
                
                -- Auto sell more frequently for extreme mode
                if Settings.AutoSell and Stats.fishCaught % 25 == 0 then
                    safeCall(function()
                        Remotes.sellAll:InvokeServer()
                        createNotification("⚡ [EXTREME] Auto-sold! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 215, 0))
                    end)
                    task.wait(extremeDelay * 2) -- Slightly longer wait after selling
                end
                
                -- Minimal delay between cycles
                task.wait(extremeDelay)
            end)
        end
    end)
end

-- ===================================================================
--                       BRUTAL AUTO FISHING
-- ===================================================================
local function autoFishingBrutal(Settings)
    task.spawn(function()
        while Settings.AutoFishingBrutal do
            safeCall(function()
                -- Optional safety check (only if BrutalSafeMode is enabled)
                if Settings.BrutalSafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 10 then
                        warn("⚠️ [BRUTAL] Critical health! Pausing...")
                        task.wait(2)
                        return
                    end
                end
                
                -- Use custom user-defined delay
                local brutalDelay = Settings.BrutalCustomDelay
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    Remotes.EquipRod:FireServer(1)
                    task.wait(brutalDelay)
                end

                -- Ultra custom speed fishing sequence
                Remotes.ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                task.wait(brutalDelay)
                
                Remotes.RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                task.wait(brutalDelay)
                
                Remotes.FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                -- Quick fish value calculation
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🔥 [BRUTAL] " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                        Stats.legendaryFishCaught = Stats.legendaryFishCaught + 1
                    elseif rarity ~= "Common" then
                        Stats.rareFishCaught = Stats.rareFishCaught + 1
                    end
                end
                
                -- Quick luck update
                updateLuckLevel()
                
                -- Auto sell very frequently for brutal mode
                if Settings.AutoSell and Stats.fishCaught % 30 == 0 then
                    safeCall(function()
                        Remotes.sellAll:InvokeServer()
                        createNotification("🔥 [BRUTAL] Auto-sold! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 69, 0))
                    end)
                    task.wait(brutalDelay * 3) -- Brief wait after selling
                end
                
                -- Custom user delay between cycles
                task.wait(brutalDelay)
            end)
        end
    end)
end

return {
    smartFishingLogic = smartFishingLogic,
    enhancedAutoFishing = enhancedAutoFishing,
    getAFK2Delay = getAFK2Delay,
    autoFishingAFK2 = autoFishingAFK2,
    getExtremeDelay = getExtremeDelay,
    autoFishingExtreme = autoFishingExtreme,
    autoFishingBrutal = autoFishingBrutal
}
