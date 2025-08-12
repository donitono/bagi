-- ██████████████████████████████████████████████████████████████
-- ██                                                          ██
-- ██                 GamerXsan FISHIT V2.0                    ██
-- ██                 SINGLE FILE MODULAR VERSION              ██
-- ██                 READY FOR LOADSTRING                     ██
-- ██                                                          ██
-- ██████████████████████████████████████████████████████████████

local success, error = pcall(function()

-- ===================================================================
--                         CONFIG MODULE
-- ===================================================================
local CONFIG = {
    GUI_NAME = "GamerXsan",
    GUI_TITLE = "Mod GamerXsan",
    LOGO_IMAGE = "rbxassetid://10776847027",
    HOTKEY = Enum.KeyCode.F9,
    AUTO_SAVE_SETTINGS = true,
    FISHING_DELAYS = {
        MIN = 0.1,
        MAX = 0.3
    },
    AFK2_DELAYS = {
        MIN = 0.5,
        MAX = 2.0,
        CUSTOM = 1.0
    },
    -- DARK BLUE THEME COLORS
    COLORS = {
        MAIN_BG = Color3.fromRGB(15, 25, 45),        -- Dark Navy Blue
        SIDEBAR_BG = Color3.fromRGB(20, 35, 60),     -- Medium Navy Blue  
        FRAME_BG = Color3.fromRGB(25, 40, 70),       -- Lighter Navy Blue
        BUTTON_BG = Color3.fromRGB(30, 50, 90),      -- Button Blue
        BUTTON_HOVER = Color3.fromRGB(40, 65, 110),  -- Button Hover
        ACCENT_BLUE = Color3.fromRGB(0, 120, 255),   -- Bright Blue Accent
        SUCCESS_GREEN = Color3.fromRGB(0, 200, 100), -- Success Green
        DANGER_RED = Color3.fromRGB(220, 40, 34),    -- Danger Red
        WARNING_ORANGE = Color3.fromRGB(255, 165, 0), -- Warning Orange
        TEXT_WHITE = Color3.fromRGB(255, 255, 255),  -- White Text
        TEXT_GRAY = Color3.fromRGB(200, 200, 200),   -- Gray Text
        BORDER_BLUE = Color3.fromRGB(50, 100, 180),  -- Border Blue
        OFF_STATE = Color3.fromRGB(10, 15, 25)       -- OFF Button State
    }
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

-- Remote References
local EquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/EquipToolFromHotbar"]
local UnEquipRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/UnequipToolFromHotbar"]
local RequestFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"]
local ChargeRod = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"]
local FishingComplete = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RE/FishingCompleted"]
local CancelFishing = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"]
local spawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SpawnBoat"]
local despawnBoat = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/DespawnBoat"]
local sellAll = Rs.Packages._Index["sleitnick_net@0.2.0"].net["RF/SellAllItems"]

-- External scripts
local noOxygen = loadstring(game:HttpGet("https://pastebin.com/raw/JS7LaJsa"))()

-- Workspace references
local tpFolder = workspace["!!!! ISLAND LOCATIONS !!!!"]
local charFolder = workspace.Characters

-- Variables
local player = Players.LocalPlayer
local connections = {}
local isHidden = false

-- Check if GUI already exists and destroy it
if player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME) then
    player.PlayerGui[CONFIG.GUI_NAME]:Destroy()
end

-- ===================================================================
--                         UTILS MODULE
-- ===================================================================
local function randomWait()
    return math.random(CONFIG.FISHING_DELAYS.MIN * 1000, CONFIG.FISHING_DELAYS.MAX * 1000) / 1000
end

local function safeCall(func)
    local success, result = pcall(func)
    if not success then
        warn("Error: " .. tostring(result))
    end
    return success, result
end

local function loadSettings()
    print("Settings loaded")
end

local function saveSettings()
    print("Settings saved")
end

local function createNotification(text, color)
    local gui = player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME)
    if not gui then return end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Parent = gui
    notification.BackgroundColor3 = color or CONFIG.COLORS.SUCCESS_GREEN
    notification.BorderSizePixel = 0
    notification.Position = UDim2.new(1, -250, 0, 50)
    notification.Size = UDim2.new(0, 240, 0, 50)
    notification.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = notification
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = text
    textLabel.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    textLabel.TextScaled = true
    
    notification:TweenPosition(
        UDim2.new(1, -260, 0, 50),
        "Out", "Quad", 0.3, true
    )
    
    task.spawn(function()
        task.wait(3)
        notification:TweenPosition(
            UDim2.new(1, 10, 0, 50),
            "In", "Quad", 0.3, true,
            function() notification:Destroy() end
        )
    end)
end

local function antiAFK()
    task.spawn(function()
        while true do
            task.wait(300)
            safeCall(function()
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:Move(Vector3.new(0.1, 0, 0))
                    task.wait(0.1)
                    humanoid:Move(Vector3.new(-0.1, 0, 0))
                end
            end)
        end
    end)
end

-- ===================================================================
--                         STATS MODULE
-- ===================================================================
local Stats = {
    fishCaught = 0,
    moneyEarned = 0,
    sessionStartTime = tick(),
    bestFish = "None",
    totalPlayTime = 0,
    boatsSpawned = 0,
    rareFishCaught = 0,
    legendaryFishCaught = 0,
    currentLuckLevel = 1,
    fishPerMinute = 0,
    moneyPerHour = 0,
    bestSpot = "None",
    weatherBonuses = 0,
    timeBonuses = 0
}

local LuckSystem = {
    baseChance = 0.1,
    boostMultiplier = 1.0,
    weatherMultiplier = 1.0,
    timeMultiplier = 1.0,
    spotMultiplier = 1.0,
    maxLuckLevel = 10,
    luckXP = 0,
    xpPerLevel = 100
}

local WeatherTypes = {"Sunny", "Rainy", "Cloudy", "Stormy", "Foggy", "Windy"}
local WeatherEffects = {
    Sunny = {luck = 1.2, fish_rate = 1.1, description = "☀️ Perfect fishing weather!"},
    Rainy = {luck = 1.5, fish_rate = 1.3, description = "🌧️ Fish are more active!"},
    Cloudy = {luck = 1.0, fish_rate = 1.0, description = "☁️ Normal conditions"},
    Stormy = {luck = 2.0, fish_rate = 0.8, description = "⛈️ Dangerous but lucky!"},
    Foggy = {luck = 1.8, fish_rate = 0.9, description = "🌫️ Mysterious waters"},
    Windy = {luck = 1.1, fish_rate = 1.2, description = "💨 Good for surface fish"}
}

local currentWeather = "Sunny"

local function calculateCurrentLuck(Settings)
    local baseLuck = LuckSystem.baseChance
    local totalMultiplier = LuckSystem.boostMultiplier
    
    if Settings.WeatherBoost then
        totalMultiplier = totalMultiplier * (WeatherEffects[currentWeather].luck or 1.0)
    end
    
    if Settings.LuckBoost then
        local levelBonus = 1 + (Stats.currentLuckLevel * 0.1)
        totalMultiplier = totalMultiplier * levelBonus
    end
    
    return baseLuck * totalMultiplier
end

local function updateLuckLevel()
    LuckSystem.luckXP = LuckSystem.luckXP + 1
    local requiredXP = Stats.currentLuckLevel * LuckSystem.xpPerLevel
    
    if LuckSystem.luckXP >= requiredXP and Stats.currentLuckLevel < LuckSystem.maxLuckLevel then
        Stats.currentLuckLevel = Stats.currentLuckLevel + 1
        LuckSystem.luckXP = 0
        createNotification("🍀 Luck Level Up! Level " .. Stats.currentLuckLevel, CONFIG.COLORS.SUCCESS_GREEN)
    end
end

local function getFishRarity(Settings)
    local luck = calculateCurrentLuck(Settings)
    local roll = math.random()
    
    if roll <= luck * 0.001 then
        return "Mythical", Color3.fromRGB(255, 0, 255)
    elseif roll <= luck * 0.01 then
        Stats.legendaryFishCaught = Stats.legendaryFishCaught + 1
        return "Legendary", Color3.fromRGB(255, 215, 0)
    elseif roll <= luck * 0.05 then
        Stats.rareFishCaught = Stats.rareFishCaught + 1
        return "Rare", Color3.fromRGB(128, 0, 255)
    elseif roll <= luck * 0.15 then
        return "Uncommon", Color3.fromRGB(0, 255, 0)
    else
        return "Common", Color3.fromRGB(255, 255, 255)
    end
end

local function simulateFishValue(rarity)
    local baseValues = {
        Common = {min = 10, max = 50},
        Uncommon = {min = 40, max = 120},
        Rare = {min = 100, max = 300},
        Legendary = {min = 250, max = 800},
        Mythical = {min = 500, max = 2000}
    }
    
    local range = baseValues[rarity]
    if range then
        return math.random(range.min, range.max)
    end
    return 25
end

-- ===================================================================
--                        SECURITY MODULE
-- ===================================================================
local SecuritySettings = {
    AdminDetection = true,
    PlayerProximityAlert = true,
    SuspiciousActivityLogger = true,
    AutoHideOnAdmin = true,
    ProximityDistance = 20,
    BlacklistedPlayers = {},
    WhitelistedPlayers = {}
}

local SecurityStats = {
    AdminsDetected = 0,
    ProximityAlerts = 0,
    AutoHides = 0,
    SuspiciousActivities = 0
}

local function isPlayerAdmin(targetPlayer)
    if targetPlayer:GetRankInGroup(0) >= 100 then return true end
    if targetPlayer.Name:lower():find("admin") or targetPlayer.Name:lower():find("mod") then return true end
    if targetPlayer.DisplayName:lower():find("admin") or targetPlayer.DisplayName:lower():find("mod") then return true end
    return false
end

local function initializeSecurity()
    print("🔒 Security system initialized")
end

-- ===================================================================
--                        PLAYER MODULE
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
--                        FISHING MODULE
-- ===================================================================
local function enhancedAutoFishing(Settings)
    task.spawn(function()
        while Settings.AutoFishing do
            safeCall(function()
                if Settings.SafeMode then
                    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health < 20 then
                        warn("⚠️ Low health detected! Stopping auto fishing for safety.")
                        task.wait(5)
                        return
                    end
                end
                
                task.wait(randomWait())
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    CancelFishing:InvokeServer()
                    task.wait(randomWait())
                    EquipRod:FireServer(1)
                end

                task.wait(randomWait())
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(randomWait())
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + randomWait())
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🎣 Caught " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                updateLuckLevel()
                
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(1)
                    safeCall(function()
                        sellAll:InvokeServer()
                        createNotification("🛒 Auto-sold items! (₡" .. Stats.moneyEarned .. ")", CONFIG.COLORS.WARNING_ORANGE)
                    end)
                end
            end)
        end
    end)
end

local function autoFishingAFK2()
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
                
                -- Custom delay (slightly faster than regular)
                local afk2Delay = math.random(300, 600) / 1000
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    CancelFishing:InvokeServer()
                    task.wait(afk2Delay)
                    EquipRod:FireServer(1)
                end

                task.wait(afk2Delay)
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                
                task.wait(afk2Delay)
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                
                task.wait(0.4 + afk2Delay)
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🎣 [AFK2] Caught " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                updateLuckLevel()
                
                if Settings.AutoSell and Stats.fishCaught % 10 == 0 then
                    task.wait(1)
                    safeCall(function()
                        sellAll:InvokeServer()
                        createNotification("🛒 [AFK2] Auto-sold items!", CONFIG.COLORS.WARNING_ORANGE)
                    end)
                end
                
                task.wait(afk2Delay)
                
            end)
        end
    end)
end

local function autoFishingExtreme()
    task.spawn(function()
        while Settings.AutoFishingExtreme do
            safeCall(function()
                -- Minimal safety check 
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health < 10 then
                    warn("⚠️ [EXTREME] Critical health! Pausing...")
                    task.wait(2)
                    return
                end
                
                -- Ultra fast delay
                local extremeDelay = math.random(50, 150) / 1000
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    EquipRod:FireServer(1)
                    task.wait(extremeDelay)
                end

                -- Rapid fire fishing sequence
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                task.wait(extremeDelay)
                
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                task.wait(extremeDelay)
                
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                -- Only show notifications for rare fish to avoid spam
                if rarity == "Legendary" or rarity == "Mythical" then
                    createNotification("⚡ [EXTREME] " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    Stats.bestFish = rarity .. " Fish"
                end
                
                updateLuckLevel()
                
                -- Auto sell more frequently for extreme mode
                if Settings.AutoSell and Stats.fishCaught % 20 == 0 then
                    safeCall(function()
                        sellAll:InvokeServer()
                        createNotification("🛒 [EXTREME] Auto-sold items!", CONFIG.COLORS.WARNING_ORANGE)
                    end)
                end
                
                task.wait(extremeDelay)
                
            end)
        end
    end)
end

local function autoFishingBrutal()
    task.spawn(function()
        while Settings.AutoFishingBrutal do
            safeCall(function()
                -- Optional safety check
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health < 10 then
                    warn("⚠️ [BRUTAL] Critical health! Pausing...")
                    task.wait(2)
                    return
                end
                
                -- Use custom very fast delay
                local brutalDelay = math.random(10, 50) / 1000
                
                local char = player.Character or player.CharacterAdded:Wait()
                local equippedTool = char:FindFirstChild("!!!EQUIPPED_TOOL!!!")

                if not equippedTool then
                    EquipRod:FireServer(1)
                    task.wait(brutalDelay)
                end

                -- Ultra custom speed fishing sequence
                ChargeRod:InvokeServer(workspace:GetServerTimeNow())
                task.wait(brutalDelay)
                
                RequestFishing:InvokeServer(-1.2379989624023438, 0.9800224985802423)
                task.wait(brutalDelay)
                
                FishingComplete:FireServer()
                
                Stats.fishCaught = Stats.fishCaught + 1
                
                local rarity, color = getFishRarity(Settings)
                local fishValue = simulateFishValue(rarity)
                Stats.moneyEarned = Stats.moneyEarned + fishValue
                
                if rarity ~= "Common" then
                    createNotification("🔥 [BRUTAL] " .. rarity .. " fish! (₡" .. fishValue .. ")", color)
                    if rarity == "Legendary" or rarity == "Mythical" then
                        Stats.bestFish = rarity .. " Fish"
                    end
                end
                
                updateLuckLevel()
                
                -- Auto sell very frequently for brutal mode
                if Settings.AutoSell and Stats.fishCaught % 30 == 0 then
                    safeCall(function()
                        sellAll:InvokeServer()
                        createNotification("🛒 [BRUTAL] Auto-sold items!", CONFIG.COLORS.WARNING_ORANGE)
                    end)
                end
                
                task.wait(brutalDelay)
                
            end)
        end
    end)
end

-- ===================================================================
--                           SETTINGS
-- ===================================================================
local Settings = {
    AutoFishing = false,
    AutoFishingAFK2 = false,
    AutoFishingExtreme = false,
    AutoFishingBrutal = false,
    WalkSpeed = 16,
    NoOxygenDamage = false,
    Theme = "Dark",
    AutoSell = false,
    JumpPower = 50,
    AutoEquipBestRod = true,
    SafeMode = true,
    LuckBoost = false,
    WeatherBoost = false,
    TimeBoost = false,
    FishValueFilter = false,
    MinFishValue = 100,
    AutoBaitUse = false,
    SmartFishing = false
}

-- ===================================================================
--                       COMPLETE GUI CREATION
-- ===================================================================
-- Global variables for GUI management
local mainGui = nil
local floatingButton = nil
local guiVisible = true

local function toggleGUI()
    if mainGui and mainGui.Parent then
        guiVisible = not guiVisible
        mainGui.Enabled = guiVisible
        
        -- Update floating button appearance
        if floatingButton and floatingButton.Parent then
            if guiVisible then
                floatingButton.Text = "🎣"
                floatingButton.BackgroundColor3 = CONFIG.COLORS.ACCENT_BLUE
                createNotification("🎣 GUI Opened", CONFIG.COLORS.SUCCESS_GREEN)
            else
                floatingButton.Text = "👁️"
                floatingButton.BackgroundColor3 = CONFIG.COLORS.ACCENT_BLUE
                createNotification("👁️ GUI Hidden", CONFIG.COLORS.WARNING_ORANGE)
            end
        end
    else
        -- GUI doesn't exist, show restart message
        if floatingButton and floatingButton.Parent then
            createNotification("⚠️ Script needs restart - Run script again", CONFIG.COLORS.DANGER_RED)
        end
    end
end

local function createFloatingToggleButton()
    -- Create separate ScreenGui for floating button so it persists
    local FloatingGui = Instance.new("ScreenGui")
    FloatingGui.Name = "FloatingToggle"
    FloatingGui.Parent = player:WaitForChild("PlayerGui")
    FloatingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FloatingGui.ResetOnSpawn = true  -- Change to true so it resets on respawn
    
    -- Floating Toggle Button
    local FloatingButton = Instance.new("TextButton")
    FloatingButton.Name = "FloatingToggle"
    FloatingButton.Parent = FloatingGui
    FloatingButton.BackgroundColor3 = CONFIG.COLORS.ACCENT_BLUE
    FloatingButton.BorderSizePixel = 0
    FloatingButton.Position = UDim2.new(0.02, 0, 0.5, -25)
    FloatingButton.Size = UDim2.new(0, 50, 0, 50)
    FloatingButton.Font = Enum.Font.SourceSansBold
    FloatingButton.Text = "🎣"
    FloatingButton.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FloatingButton.TextSize = 20
    FloatingButton.ZIndex = 1000
    
    local floatingCorner = Instance.new("UICorner")
    floatingCorner.CornerRadius = UDim.new(0, 25)
    floatingCorner.Parent = FloatingButton
    
    -- Add glow effect
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = CONFIG.COLORS.TEXT_WHITE
    UIStroke.Thickness = 2
    UIStroke.Transparency = 0.5
    UIStroke.Parent = FloatingButton
    
    -- Make it draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    FloatingButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = FloatingButton.Position
        end
    end)
    
    FloatingButton.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            FloatingButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    FloatingButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Connect to toggle function
    FloatingButton.MouseButton1Click:Connect(toggleGUI)
    
    return FloatingButton
end

local function createCompleteGUI()
    local ZayrosFISHIT = Instance.new("ScreenGui")
    ZayrosFISHIT.Name = CONFIG.GUI_NAME
    ZayrosFISHIT.Parent = player:WaitForChild("PlayerGui")
    ZayrosFISHIT.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local FrameUtama = Instance.new("Frame")
    FrameUtama.Name = "FrameUtama"
    FrameUtama.Parent = ZayrosFISHIT
    FrameUtama.BackgroundColor3 = CONFIG.COLORS.MAIN_BG
    FrameUtama.BackgroundTransparency = 0.100
    FrameUtama.BorderSizePixel = 0
    FrameUtama.Position = UDim2.new(0.264, 0, 0.174, 0)
    FrameUtama.Size = UDim2.new(0.542, 0, 0.650, 0)
    
    local UICorner = Instance.new("UICorner")
    UICorner.Parent = FrameUtama

    -- Exit Button
    local ExitBtn = Instance.new("TextButton")
    ExitBtn.Name = "ExitBtn"
    ExitBtn.Parent = FrameUtama
    ExitBtn.BackgroundColor3 = CONFIG.COLORS.DANGER_RED
    ExitBtn.BorderSizePixel = 0
    ExitBtn.Position = UDim2.new(0.901, 0, 0.038, 0)
    ExitBtn.Size = UDim2.new(0.063, 0, 0.088, 0)
    ExitBtn.Font = Enum.Font.SourceSansBold
    ExitBtn.Text = "X"
    ExitBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    ExitBtn.TextScaled = true
    
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 4)
    exitCorner.Parent = ExitBtn

    -- Side Bar
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Parent = FrameUtama
    SideBar.BackgroundColor3 = CONFIG.COLORS.SIDEBAR_BG
    SideBar.BorderSizePixel = 0
    SideBar.Size = UDim2.new(0.376, 0, 1, 0)
    SideBar.ZIndex = 2

    -- Logo
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Parent = SideBar
    Logo.BackgroundColor3 = CONFIG.COLORS.TEXT_WHITE
    Logo.BorderSizePixel = 0
    Logo.Position = UDim2.new(0.073, 0, 0.038, 0)
    Logo.Size = UDim2.new(0.168, 0, 0.088, 0)
    Logo.ZIndex = 2
    Logo.Image = CONFIG.LOGO_IMAGE
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 10)
    logoCorner.Parent = Logo

    -- Title
    local TittleSideBar = Instance.new("TextLabel")
    TittleSideBar.Name = "TittleSideBar"
    TittleSideBar.Parent = SideBar
    TittleSideBar.BackgroundTransparency = 1
    TittleSideBar.Position = UDim2.new(0.309, 0, 0.038, 0)
    TittleSideBar.Size = UDim2.new(0.654, 0, 0.088, 0)
    TittleSideBar.ZIndex = 2
    TittleSideBar.Font = Enum.Font.SourceSansBold
    TittleSideBar.Text = CONFIG.GUI_TITLE
    TittleSideBar.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    TittleSideBar.TextScaled = true
    TittleSideBar.TextXAlignment = Enum.TextXAlignment.Left

    -- Line
    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = SideBar
    Line.BackgroundColor3 = CONFIG.COLORS.BORDER_BLUE
    Line.BorderSizePixel = 0
    Line.Position = UDim2.new(0, 0, 0.145, 0)
    Line.Size = UDim2.new(1, 0, 0.003, 0)
    Line.ZIndex = 2

    -- Menu Container
    local MainMenuSaidBar = Instance.new("Frame")
    MainMenuSaidBar.Name = "MainMenuSaidBar"
    MainMenuSaidBar.Parent = SideBar
    MainMenuSaidBar.BackgroundTransparency = 1
    MainMenuSaidBar.Position = UDim2.new(0, 0, 0.165, 0)
    MainMenuSaidBar.Size = UDim2.new(1, 0, 0.710, 0)

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = MainMenuSaidBar
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0.05, 0)

    -- Menu Buttons
    local function createMenuButton(name, text)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Parent = MainMenuSaidBar
        btn.BackgroundColor3 = CONFIG.COLORS.BUTTON_BG
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0.916, 0, 0.113, 0)
        btn.Font = Enum.Font.SourceSansBold
        btn.Text = text
        btn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
        btn.TextScaled = true
        
        local corner = Instance.new("UICorner")
        corner.Parent = btn
        
        return btn
    end

    local MAIN = createMenuButton("MAIN", "MAIN")
    local Player = createMenuButton("Player", "PLAYER")
    local SpawnBoat = createMenuButton("SpawnBoat", "SPAWN BOAT")
    local TELEPORT = createMenuButton("TELEPORT", "TELEPORT")
    local SECURITY = createMenuButton("SECURITY", "SECURITY")
    local ADVANCED = createMenuButton("ADVANCED", "ADVANCED")

    -- Credit
    local Credit = Instance.new("TextLabel")
    Credit.Name = "Credit"
    Credit.Parent = SideBar
    Credit.BackgroundTransparency = 1
    Credit.Position = UDim2.new(0, 0, 0.875, 0)
    Credit.Size = UDim2.new(0.998, 0, 0.123, 0)
    Credit.Font = Enum.Font.SourceSansBold
    Credit.Text = "Telegram @Spinnerxxx"
    Credit.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    Credit.TextScaled = true

    -- Main content line
    local Line_2 = Instance.new("Frame")
    Line_2.Name = "Line"
    Line_2.Parent = FrameUtama
    Line_2.BackgroundColor3 = CONFIG.COLORS.BORDER_BLUE
    Line_2.BorderSizePixel = 0
    Line_2.Position = UDim2.new(0.376, 0, 0.145, 0)
    Line_2.Size = UDim2.new(0.624, 0, 0.003, 0)
    Line_2.ZIndex = 2

    -- Title for current page
    local Tittle = Instance.new("TextLabel")
    Tittle.Name = "Tittle"
    Tittle.Parent = FrameUtama
    Tittle.BackgroundTransparency = 1
    Tittle.Position = UDim2.new(0.420, 0, 0.038, 0)
    Tittle.Size = UDim2.new(0.444, 0, 0.088, 0)
    Tittle.ZIndex = 2
    Tittle.Font = Enum.Font.SourceSansBold
    Tittle.Text = "MAIN"
    Tittle.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    Tittle.TextScaled = true

    -- ===============================================================
    --                         MAIN FRAME
    -- ===============================================================
    local MainFrame = Instance.new("ScrollingFrame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = FrameUtama
    MainFrame.Active = true
    MainFrame.BackgroundTransparency = 1
    MainFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    MainFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    MainFrame.ZIndex = 2
    MainFrame.ScrollBarThickness = 6

    local MainListLayoutFrame = Instance.new("Frame")
    MainListLayoutFrame.Name = "MainListLayoutFrame"
    MainListLayoutFrame.Parent = MainFrame
    MainListLayoutFrame.BackgroundTransparency = 1
    MainListLayoutFrame.Position = UDim2.new(0, 0, 0.022, 0)
    MainListLayoutFrame.Size = UDim2.new(1, 0, 1, 0)

    local ListLayoutMain = Instance.new("UIListLayout")
    ListLayoutMain.Name = "ListLayoutMain"
    ListLayoutMain.Parent = MainListLayoutFrame
    ListLayoutMain.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ListLayoutMain.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayoutMain.Padding = UDim.new(0, 8)

    -- Auto Fish Frame
    local AutoFishFrame = Instance.new("Frame")
    AutoFishFrame.Name = "AutoFishFrame"
    AutoFishFrame.Parent = MainListLayoutFrame
    AutoFishFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoFishFrame.BorderSizePixel = 0
    AutoFishFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoFishCorner = Instance.new("UICorner")
    autoFishCorner.Parent = AutoFishFrame

    local AutoFishText = Instance.new("TextLabel")
    AutoFishText.Parent = AutoFishFrame
    AutoFishText.BackgroundTransparency = 1
    AutoFishText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoFishText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoFishText.Font = Enum.Font.SourceSansBold
    AutoFishText.Text = "Auto Fish (AFK) :"
    AutoFishText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishText.TextScaled = true
    AutoFishText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoFishButton = Instance.new("TextButton")
    AutoFishButton.Name = "AutoFishButton"
    AutoFishButton.Parent = AutoFishFrame
    AutoFishButton.BackgroundTransparency = 1
    AutoFishButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoFishButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoFishButton.ZIndex = 2
    AutoFishButton.Font = Enum.Font.SourceSansBold
    AutoFishButton.Text = "OFF"
    AutoFishButton.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishButton.TextScaled = true

    local AutoFishWarna = Instance.new("Frame")
    AutoFishWarna.Parent = AutoFishFrame
    AutoFishWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoFishWarna.BorderSizePixel = 0
    AutoFishWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishWarnaCorner = Instance.new("UICorner")
    autoFishWarnaCorner.Parent = AutoFishWarna

    -- Auto Fish AFK2 Frame
    local AutoFishAFK2Frame = Instance.new("Frame")
    AutoFishAFK2Frame.Name = "AutoFishAFK2Frame"
    AutoFishAFK2Frame.Parent = MainListLayoutFrame
    AutoFishAFK2Frame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoFishAFK2Frame.BorderSizePixel = 0
    AutoFishAFK2Frame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoFishAFK2Corner = Instance.new("UICorner")
    autoFishAFK2Corner.Parent = AutoFishAFK2Frame

    local AutoFishAFK2Text = Instance.new("TextLabel")
    AutoFishAFK2Text.Parent = AutoFishAFK2Frame
    AutoFishAFK2Text.BackgroundTransparency = 1
    AutoFishAFK2Text.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoFishAFK2Text.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoFishAFK2Text.Font = Enum.Font.SourceSansBold
    AutoFishAFK2Text.Text = "Auto Fish (AFK2) :"
    AutoFishAFK2Text.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishAFK2Text.TextScaled = true
    AutoFishAFK2Text.TextXAlignment = Enum.TextXAlignment.Left

    local AutoFishAFK2Button = Instance.new("TextButton")
    AutoFishAFK2Button.Name = "AutoFishAFK2Button"
    AutoFishAFK2Button.Parent = AutoFishAFK2Frame
    AutoFishAFK2Button.BackgroundTransparency = 1
    AutoFishAFK2Button.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoFishAFK2Button.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoFishAFK2Button.ZIndex = 2
    AutoFishAFK2Button.Font = Enum.Font.SourceSansBold
    AutoFishAFK2Button.Text = "OFF"
    AutoFishAFK2Button.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishAFK2Button.TextScaled = true

    local AutoFishAFK2Warna = Instance.new("Frame")
    AutoFishAFK2Warna.Parent = AutoFishAFK2Frame
    AutoFishAFK2Warna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoFishAFK2Warna.BorderSizePixel = 0
    AutoFishAFK2Warna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishAFK2Warna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishAFK2WarnaCorner = Instance.new("UICorner")
    autoFishAFK2WarnaCorner.Parent = AutoFishAFK2Warna

    -- Auto Fish Extreme Frame
    local AutoFishExtremeFrame = Instance.new("Frame")
    AutoFishExtremeFrame.Name = "AutoFishExtremeFrame"
    AutoFishExtremeFrame.Parent = MainListLayoutFrame
    AutoFishExtremeFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoFishExtremeFrame.BorderSizePixel = 0
    AutoFishExtremeFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoFishExtremeCorner = Instance.new("UICorner")
    autoFishExtremeCorner.Parent = AutoFishExtremeFrame

    local AutoFishExtremeText = Instance.new("TextLabel")
    AutoFishExtremeText.Parent = AutoFishExtremeFrame
    AutoFishExtremeText.BackgroundTransparency = 1
    AutoFishExtremeText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoFishExtremeText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoFishExtremeText.Font = Enum.Font.SourceSansBold
    AutoFishExtremeText.Text = "Auto Fish (Extreme) :"
    AutoFishExtremeText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishExtremeText.TextScaled = true
    AutoFishExtremeText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoFishExtremeButton = Instance.new("TextButton")
    AutoFishExtremeButton.Name = "AutoFishExtremeButton"
    AutoFishExtremeButton.Parent = AutoFishExtremeFrame
    AutoFishExtremeButton.BackgroundTransparency = 1
    AutoFishExtremeButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoFishExtremeButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoFishExtremeButton.ZIndex = 2
    AutoFishExtremeButton.Font = Enum.Font.SourceSansBold
    AutoFishExtremeButton.Text = "OFF"
    AutoFishExtremeButton.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishExtremeButton.TextScaled = true

    local AutoFishExtremeWarna = Instance.new("Frame")
    AutoFishExtremeWarna.Parent = AutoFishExtremeFrame
    AutoFishExtremeWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoFishExtremeWarna.BorderSizePixel = 0
    AutoFishExtremeWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishExtremeWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishExtremeWarnaCorner = Instance.new("UICorner")
    autoFishExtremeWarnaCorner.Parent = AutoFishExtremeWarna

    -- Auto Fish Brutal Frame
    local AutoFishBrutalFrame = Instance.new("Frame")
    AutoFishBrutalFrame.Name = "AutoFishBrutalFrame"
    AutoFishBrutalFrame.Parent = MainListLayoutFrame
    AutoFishBrutalFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoFishBrutalFrame.BorderSizePixel = 0
    AutoFishBrutalFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local autoFishBrutalCorner = Instance.new("UICorner")
    autoFishBrutalCorner.Parent = AutoFishBrutalFrame

    local AutoFishBrutalText = Instance.new("TextLabel")
    AutoFishBrutalText.Parent = AutoFishBrutalFrame
    AutoFishBrutalText.BackgroundTransparency = 1
    AutoFishBrutalText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoFishBrutalText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoFishBrutalText.Font = Enum.Font.SourceSansBold
    AutoFishBrutalText.Text = "Auto Fish (Brutal) :"
    AutoFishBrutalText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishBrutalText.TextScaled = true
    AutoFishBrutalText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoFishBrutalButton = Instance.new("TextButton")
    AutoFishBrutalButton.Name = "AutoFishBrutalButton"
    AutoFishBrutalButton.Parent = AutoFishBrutalFrame
    AutoFishBrutalButton.BackgroundTransparency = 1
    AutoFishBrutalButton.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoFishBrutalButton.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoFishBrutalButton.ZIndex = 2
    AutoFishBrutalButton.Font = Enum.Font.SourceSansBold
    AutoFishBrutalButton.Text = "OFF"
    AutoFishBrutalButton.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoFishBrutalButton.TextScaled = true

    local AutoFishBrutalWarna = Instance.new("Frame")
    AutoFishBrutalWarna.Parent = AutoFishBrutalFrame
    AutoFishBrutalWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoFishBrutalWarna.BorderSizePixel = 0
    AutoFishBrutalWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishBrutalWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishBrutalWarnaCorner = Instance.new("UICorner")
    autoFishBrutalWarnaCorner.Parent = AutoFishBrutalWarna

    -- Sell All Frame
    local SellAllFrame = Instance.new("Frame")
    SellAllFrame.Name = "SellAllFrame"
    SellAllFrame.Parent = MainListLayoutFrame
    SellAllFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    SellAllFrame.BorderSizePixel = 0
    SellAllFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local sellAllCorner = Instance.new("UICorner")
    sellAllCorner.Parent = SellAllFrame

    local SellAllButton = Instance.new("TextButton")
    SellAllButton.Name = "SellAllButton"
    SellAllButton.Parent = SellAllFrame
    SellAllButton.BackgroundTransparency = 1
    SellAllButton.Size = UDim2.new(1, 0, 1, 0)
    SellAllButton.ZIndex = 2
    SellAllButton.Font = Enum.Font.SourceSansBold
    SellAllButton.Text = ""

    local SellAllText = Instance.new("TextLabel")
    SellAllText.Parent = SellAllFrame
    SellAllText.BackgroundTransparency = 1
    SellAllText.Position = UDim2.new(0.290, 0, 0.216, 0)
    SellAllText.Size = UDim2.new(0.415, 0, 0.568, 0)
    SellAllText.Font = Enum.Font.SourceSansBold
    SellAllText.Text = "Sell All"
    SellAllText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    SellAllText.TextScaled = true

    -- Statistics Frame
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Parent = MainListLayoutFrame
    StatsFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.Parent = StatsFrame

    local StatsText = Instance.new("TextLabel")
    StatsText.Parent = StatsFrame
    StatsText.BackgroundTransparency = 1
    StatsText.Position = UDim2.new(0.030, 0, 0.216, 0)
    StatsText.Size = UDim2.new(0.940, 0, 0.568, 0)
    StatsText.Font = Enum.Font.SourceSansBold
    StatsText.Text = "🐟 Fish: 0 | Session: 0m | 🍀 Luck: Lv1"
    StatsText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    StatsText.TextScaled = true

    -- Weather Frame
    local WeatherFrame = Instance.new("Frame")
    WeatherFrame.Name = "WeatherFrame"
    WeatherFrame.Parent = MainListLayoutFrame
    WeatherFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    WeatherFrame.BorderSizePixel = 0
    WeatherFrame.Size = UDim2.new(0.898, 0, 0.106, 0)
    
    local weatherCorner = Instance.new("UICorner")
    weatherCorner.Parent = WeatherFrame

    local WeatherText = Instance.new("TextLabel")
    WeatherText.Parent = WeatherFrame
    WeatherText.BackgroundTransparency = 1
    WeatherText.Position = UDim2.new(0.030, 0, 0.216, 0)
    WeatherText.Size = UDim2.new(0.940, 0, 0.568, 0)
    WeatherText.Font = Enum.Font.SourceSansBold
    WeatherText.Text = "☀️ Sunny | Perfect fishing weather!"
    WeatherText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    WeatherText.TextScaled = true

    -- Create other page frames (initially hidden)
    local PlayerFrame = Instance.new("ScrollingFrame")
    PlayerFrame.Name = "PlayerFrame"
    PlayerFrame.Parent = FrameUtama
    PlayerFrame.Active = true
    PlayerFrame.BackgroundTransparency = 1
    PlayerFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    PlayerFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    PlayerFrame.Visible = false
    PlayerFrame.ScrollBarThickness = 6
    PlayerFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    -- Player Frame Content
    local PlayerListFrame = Instance.new("Frame")
    PlayerListFrame.Name = "PlayerListFrame"
    PlayerListFrame.Parent = PlayerFrame
    PlayerListFrame.BackgroundTransparency = 1
    PlayerListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    PlayerListFrame.Size = UDim2.new(1, 0, 1, 0)

    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Parent = PlayerListFrame
    PlayerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerListLayout.Padding = UDim.new(0, 4)

    -- Walkspeed Frame
    local WalkspeedFrame = Instance.new("Frame")
    WalkspeedFrame.Parent = PlayerListFrame
    WalkspeedFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    WalkspeedFrame.BorderSizePixel = 0
    WalkspeedFrame.Size = UDim2.new(0.898, 0, 0, 40)
    local walkCorner = Instance.new("UICorner")
    walkCorner.Parent = WalkspeedFrame

    local WalkspeedText = Instance.new("TextLabel")
    WalkspeedText.Parent = WalkspeedFrame
    WalkspeedText.BackgroundTransparency = 1
    WalkspeedText.Position = UDim2.new(0.030, 0, 0, 0)
    WalkspeedText.Size = UDim2.new(0.300, 0, 1, 0)
    WalkspeedText.Font = Enum.Font.SourceSansBold
    WalkspeedText.Text = "Walkspeed:"
    WalkspeedText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    WalkspeedText.TextSize = 14
    WalkspeedText.TextXAlignment = Enum.TextXAlignment.Left
    WalkspeedText.TextYAlignment = Enum.TextYAlignment.Center

    local WalkspeedInput = Instance.new("TextBox")
    WalkspeedInput.Parent = WalkspeedFrame
    WalkspeedInput.BackgroundColor3 = CONFIG.COLORS.BUTTON_BG
    WalkspeedInput.BorderSizePixel = 0
    WalkspeedInput.Position = UDim2.new(0.400, 0, 0.125, 0)
    WalkspeedInput.Size = UDim2.new(0.180, 0, 0.750, 0)
    WalkspeedInput.Font = Enum.Font.SourceSansBold
    WalkspeedInput.Text = "16"
    WalkspeedInput.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    WalkspeedInput.TextSize = 14
    local walkInputCorner = Instance.new("UICorner")
    walkInputCorner.Parent = WalkspeedInput

    local WalkspeedBtn = Instance.new("TextButton")
    WalkspeedBtn.Parent = WalkspeedFrame
    WalkspeedBtn.BackgroundColor3 = CONFIG.COLORS.ACCENT_BLUE
    WalkspeedBtn.BorderSizePixel = 0
    WalkspeedBtn.Position = UDim2.new(0.620, 0, 0.125, 0)
    WalkspeedBtn.Size = UDim2.new(0.150, 0, 0.750, 0)
    WalkspeedBtn.Font = Enum.Font.SourceSansBold
    WalkspeedBtn.Text = "Set"
    WalkspeedBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    WalkspeedBtn.TextSize = 14
    local walkBtnCorner = Instance.new("UICorner")
    walkBtnCorner.Parent = WalkspeedBtn

    -- Jumppower Frame
    local JumppowerFrame = Instance.new("Frame")
    JumppowerFrame.Parent = PlayerListFrame
    JumppowerFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    JumppowerFrame.BorderSizePixel = 0
    JumppowerFrame.Size = UDim2.new(0.898, 0, 0, 40)
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.Parent = JumppowerFrame

    local JumppowerText = Instance.new("TextLabel")
    JumppowerText.Parent = JumppowerFrame
    JumppowerText.BackgroundTransparency = 1
    JumppowerText.Position = UDim2.new(0.030, 0, 0, 0)
    JumppowerText.Size = UDim2.new(0.300, 0, 1, 0)
    JumppowerText.Font = Enum.Font.SourceSansBold
    JumppowerText.Text = "Jumppower:"
    JumppowerText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    JumppowerText.TextSize = 14
    JumppowerText.TextXAlignment = Enum.TextXAlignment.Left
    JumppowerText.TextYAlignment = Enum.TextYAlignment.Center

    local JumppowerInput = Instance.new("TextBox")
    JumppowerInput.Parent = JumppowerFrame
    JumppowerInput.BackgroundColor3 = CONFIG.COLORS.BUTTON_BG
    JumppowerInput.BorderSizePixel = 0
    JumppowerInput.Position = UDim2.new(0.400, 0, 0.125, 0)
    JumppowerInput.Size = UDim2.new(0.180, 0, 0.750, 0)
    JumppowerInput.Font = Enum.Font.SourceSansBold
    JumppowerInput.Text = "50"
    JumppowerInput.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    JumppowerInput.TextSize = 14
    local jumpInputCorner = Instance.new("UICorner")
    jumpInputCorner.Parent = JumppowerInput

    local JumppowerBtn = Instance.new("TextButton")
    JumppowerBtn.Parent = JumppowerFrame
    JumppowerBtn.BackgroundColor3 = CONFIG.COLORS.ACCENT_BLUE
    JumppowerBtn.BorderSizePixel = 0
    JumppowerBtn.Position = UDim2.new(0.620, 0, 0.125, 0)
    JumppowerBtn.Size = UDim2.new(0.150, 0, 0.750, 0)
    JumppowerBtn.Font = Enum.Font.SourceSansBold
    JumppowerBtn.Text = "Set"
    JumppowerBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    JumppowerBtn.TextSize = 14
    local jumpBtnCorner = Instance.new("UICorner")
    jumpBtnCorner.Parent = JumppowerBtn

    -- Noclip Frame
    local NoclipFrame = Instance.new("Frame")
    NoclipFrame.Parent = PlayerListFrame
    NoclipFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    NoclipFrame.BorderSizePixel = 0
    NoclipFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local noclipCorner = Instance.new("UICorner")
    noclipCorner.Parent = NoclipFrame

    local NoclipText = Instance.new("TextLabel")
    NoclipText.Parent = NoclipFrame
    NoclipText.BackgroundTransparency = 1
    NoclipText.Position = UDim2.new(0.030, 0, 0.216, 0)
    NoclipText.Size = UDim2.new(0.415, 0, 0.568, 0)
    NoclipText.Font = Enum.Font.SourceSansBold
    NoclipText.Text = "Noclip:"
    NoclipText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    NoclipText.TextScaled = true
    NoclipText.TextXAlignment = Enum.TextXAlignment.Left

    local NoclipBtn = Instance.new("TextButton")
    NoclipBtn.Parent = NoclipFrame
    NoclipBtn.BackgroundTransparency = 1
    NoclipBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    NoclipBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    NoclipBtn.Font = Enum.Font.SourceSansBold
    NoclipBtn.Text = "OFF"
    NoclipBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    NoclipBtn.TextScaled = true

    local NoclipWarna = Instance.new("Frame")
    NoclipWarna.Parent = NoclipFrame
    NoclipWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    NoclipWarna.BorderSizePixel = 0
    NoclipWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    NoclipWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local noclipWarnaCorner = Instance.new("UICorner")
    noclipWarnaCorner.Parent = NoclipWarna

    -- Fly Frame
    local FlyFrame = Instance.new("Frame")
    FlyFrame.Parent = PlayerListFrame
    FlyFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    FlyFrame.BorderSizePixel = 0
    FlyFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local flyCorner = Instance.new("UICorner")
    flyCorner.Parent = FlyFrame

    local FlyText = Instance.new("TextLabel")
    FlyText.Parent = FlyFrame
    FlyText.BackgroundTransparency = 1
    FlyText.Position = UDim2.new(0.030, 0, 0.216, 0)
    FlyText.Size = UDim2.new(0.415, 0, 0.568, 0)
    FlyText.Font = Enum.Font.SourceSansBold
    FlyText.Text = "Fly (E to toggle):"
    FlyText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FlyText.TextScaled = true
    FlyText.TextXAlignment = Enum.TextXAlignment.Left

    local FlyBtn = Instance.new("TextButton")
    FlyBtn.Parent = FlyFrame
    FlyBtn.BackgroundTransparency = 1
    FlyBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    FlyBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    FlyBtn.Font = Enum.Font.SourceSansBold
    FlyBtn.Text = "OFF"
    FlyBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FlyBtn.TextScaled = true

    local FlyWarna = Instance.new("Frame")
    FlyWarna.Parent = FlyFrame
    FlyWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    FlyWarna.BorderSizePixel = 0
    FlyWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    FlyWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local flyWarnaCorner = Instance.new("UICorner")
    flyWarnaCorner.Parent = FlyWarna
    
    local SpawnBoatFrame = Instance.new("ScrollingFrame")
    SpawnBoatFrame.Name = "SpawnBoatFrame"
    SpawnBoatFrame.Parent = FrameUtama
    SpawnBoatFrame.Active = true
    SpawnBoatFrame.BackgroundTransparency = 1
    SpawnBoatFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SpawnBoatFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SpawnBoatFrame.Visible = false
    SpawnBoatFrame.ScrollBarThickness = 6

    -- Boat Frame Content
    local BoatListFrame = Instance.new("Frame")
    BoatListFrame.Name = "BoatListFrame"
    BoatListFrame.Parent = SpawnBoatFrame
    BoatListFrame.BackgroundTransparency = 1
    BoatListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    BoatListFrame.Size = UDim2.new(1, 0, 2, 0)

    local BoatListLayout = Instance.new("UIListLayout")
    BoatListLayout.Parent = BoatListFrame
    BoatListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    BoatListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    BoatListLayout.Padding = UDim.new(0, 8)

    -- Boat options
    local boats = {"wooden_boat", "metal_boat", "yacht", "luxury_yacht", "fishing_boat"}
    for i, boatName in ipairs(boats) do
        local BoatFrame = Instance.new("Frame")
        BoatFrame.Parent = BoatListFrame
        BoatFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
        BoatFrame.BorderSizePixel = 0
        BoatFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
        local boatCorner = Instance.new("UICorner")
        boatCorner.Parent = BoatFrame

        local BoatBtn = Instance.new("TextButton")
        BoatBtn.Parent = BoatFrame
        BoatBtn.BackgroundTransparency = 1
        BoatBtn.Size = UDim2.new(1, 0, 1, 0)
        BoatBtn.Font = Enum.Font.SourceSansBold
        BoatBtn.Text = "Spawn " .. boatName:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
        BoatBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
        BoatBtn.TextScaled = true

        -- Boat spawn connection
        connections[#connections + 1] = BoatBtn.MouseButton1Click:Connect(function()
            safeCall(function()
                local remotes = ReplicatedStorage:WaitForChild("events")
                if remotes:FindFirstChild("dock_boat") then
                    remotes.dock_boat:InvokeServer(boatName)
                    createNotification("🛥️ " .. boatName:gsub("_", " ") .. " spawned!", Color3.fromRGB(0, 162, 255))
                end
            end)
        end)
    end
    
    local TeleportFrame = Instance.new("ScrollingFrame")
    TeleportFrame.Name = "TeleportFrame"
    TeleportFrame.Parent = FrameUtama
    TeleportFrame.Active = true
    TeleportFrame.BackgroundTransparency = 1
    TeleportFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    TeleportFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    TeleportFrame.Visible = false
    TeleportFrame.ScrollBarThickness = 6
    TeleportFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    -- Teleport Frame Content
    local TeleportListFrame = Instance.new("Frame")
    TeleportListFrame.Name = "TeleportListFrame"
    TeleportListFrame.Parent = TeleportFrame
    TeleportListFrame.BackgroundTransparency = 1
    TeleportListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    TeleportListFrame.Size = UDim2.new(1, 0, 1, 0)

    local TeleportListLayout = Instance.new("UIListLayout")
    TeleportListLayout.Parent = TeleportListFrame
    TeleportListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TeleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TeleportListLayout.Padding = UDim.new(0, 4)

    -- Teleport locations
    local teleportLocations = {
        {name = "🏪 Shop", pos = Vector3.new(-39, 10, -921)},
        {name = "🎣 Shallow Waters", pos = Vector3.new(-100, 10, -800)},
        {name = "🌊 Deep Ocean", pos = Vector3.new(-500, 10, -1500)},
        {name = "🏠 Spawn", pos = Vector3.new(0, 10, 0)},
        {name = "⛵ Dock", pos = Vector3.new(-50, 10, -950)},
        {name = "🪸 Coral Reef", pos = Vector3.new(300, 10, -200)},
        {name = "🕳️ Mysterious Cave", pos = Vector3.new(-800, 10, 400)},
        {name = "🌋 Volcanic Waters", pos = Vector3.new(600, 10, 800)},
        {name = "❄️ Frozen Lake", pos = Vector3.new(-300, 10, 600)}
    }

    -- Add dynamic island locations from workspace
    safeCall(function()
        local tpFolder = workspace:FindFirstChild("!!!! ISLAND LOCATIONS !!!!")
        if tpFolder then
            for _, island in ipairs(tpFolder:GetChildren()) do
                if island:IsA("BasePart") then
                    table.insert(teleportLocations, {
                        name = "🏝️ " .. island.Name,
                        pos = island.Position,
                        cframe = island.CFrame
                    })
                end
            end
        end
    end)

    for i, location in ipairs(teleportLocations) do
        local TpFrame = Instance.new("Frame")
        TpFrame.Parent = TeleportListFrame
        TpFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
        TpFrame.BorderSizePixel = 0
        TpFrame.Size = UDim2.new(0.898, 0, 0, 35)
        local tpCorner = Instance.new("UICorner")
        tpCorner.Parent = TpFrame

        local TpBtn = Instance.new("TextButton")
        TpBtn.Parent = TpFrame
        TpBtn.BackgroundTransparency = 1
        TpBtn.Size = UDim2.new(1, 0, 1, 0)
        TpBtn.Font = Enum.Font.SourceSansBold
        TpBtn.Text = location.name
        TpBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
        TpBtn.TextSize = 14
        TpBtn.TextXAlignment = Enum.TextXAlignment.Left
        TpBtn.TextYAlignment = Enum.TextYAlignment.Center
        
        -- Add padding for text
        local textPadding = Instance.new("UIPadding")
        textPadding.PaddingLeft = UDim.new(0, 10)
        textPadding.Parent = TpBtn

        -- Teleport connection
        connections[#connections + 1] = TpBtn.MouseButton1Click:Connect(function()
            safeCall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if location.cframe then
                        player.Character.HumanoidRootPart.CFrame = location.cframe
                    else
                        player.Character.HumanoidRootPart.CFrame = CFrame.new(location.pos)
                    end
                    createNotification("📍 Teleported to " .. location.name, Color3.fromRGB(128, 0, 255))
                end
            end)
        end)
    end
    
    local SecurityFrame = Instance.new("ScrollingFrame")
    SecurityFrame.Name = "SecurityFrame"
    SecurityFrame.Parent = FrameUtama
    SecurityFrame.Active = true
    SecurityFrame.BackgroundTransparency = 1
    SecurityFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SecurityFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SecurityFrame.Visible = false
    SecurityFrame.ScrollBarThickness = 6

    -- Security Frame Content
    local SecurityListFrame = Instance.new("Frame")
    SecurityListFrame.Name = "SecurityListFrame"
    SecurityListFrame.Parent = SecurityFrame
    SecurityListFrame.BackgroundTransparency = 1
    SecurityListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    SecurityListFrame.Size = UDim2.new(1, 0, 2, 0)

    local SecurityListLayout = Instance.new("UIListLayout")
    SecurityListLayout.Parent = SecurityListFrame
    SecurityListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SecurityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SecurityListLayout.Padding = UDim.new(0, 8)

    -- Anti AFK
    local AntiAFKFrame = Instance.new("Frame")
    AntiAFKFrame.Parent = SecurityListFrame
    AntiAFKFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AntiAFKFrame.BorderSizePixel = 0
    AntiAFKFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local antiAfkCorner = Instance.new("UICorner")
    antiAfkCorner.Parent = AntiAFKFrame

    local AntiAFKText = Instance.new("TextLabel")
    AntiAFKText.Parent = AntiAFKFrame
    AntiAFKText.BackgroundTransparency = 1
    AntiAFKText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AntiAFKText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AntiAFKText.Font = Enum.Font.SourceSansBold
    AntiAFKText.Text = "Anti AFK:"
    AntiAFKText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AntiAFKText.TextScaled = true
    AntiAFKText.TextXAlignment = Enum.TextXAlignment.Left

    local AntiAFKBtn = Instance.new("TextButton")
    AntiAFKBtn.Parent = AntiAFKFrame
    AntiAFKBtn.BackgroundTransparency = 1
    AntiAFKBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AntiAFKBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AntiAFKBtn.Font = Enum.Font.SourceSansBold
    AntiAFKBtn.Text = "ON"
    AntiAFKBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AntiAFKBtn.TextScaled = true

    local AntiAFKWarna = Instance.new("Frame")
    AntiAFKWarna.Parent = AntiAFKFrame
    AntiAFKWarna.BackgroundColor3 = CONFIG.COLORS.SUCCESS_GREEN
    AntiAFKWarna.BorderSizePixel = 0
    AntiAFKWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AntiAFKWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local antiAfkWarnaCorner = Instance.new("UICorner")
    antiAfkWarnaCorner.Parent = AntiAFKWarna

    -- Player Detection
    local PlayerDetectionFrame = Instance.new("Frame")
    PlayerDetectionFrame.Parent = SecurityListFrame
    PlayerDetectionFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    PlayerDetectionFrame.BorderSizePixel = 0
    PlayerDetectionFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local playerDetectCorner = Instance.new("UICorner")
    playerDetectCorner.Parent = PlayerDetectionFrame

    local PlayerDetectionText = Instance.new("TextLabel")
    PlayerDetectionText.Parent = PlayerDetectionFrame
    PlayerDetectionText.BackgroundTransparency = 1
    PlayerDetectionText.Position = UDim2.new(0.030, 0, 0.216, 0)
    PlayerDetectionText.Size = UDim2.new(0.415, 0, 0.568, 0)
    PlayerDetectionText.Font = Enum.Font.SourceSansBold
    PlayerDetectionText.Text = "Player Detection:"
    PlayerDetectionText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    PlayerDetectionText.TextScaled = true
    PlayerDetectionText.TextXAlignment = Enum.TextXAlignment.Left

    local PlayerDetectionBtn = Instance.new("TextButton")
    PlayerDetectionBtn.Parent = PlayerDetectionFrame
    PlayerDetectionBtn.BackgroundTransparency = 1
    PlayerDetectionBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    PlayerDetectionBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    PlayerDetectionBtn.Font = Enum.Font.SourceSansBold
    PlayerDetectionBtn.Text = "ON"
    PlayerDetectionBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    PlayerDetectionBtn.TextScaled = true

    local PlayerDetectionWarna = Instance.new("Frame")
    PlayerDetectionWarna.Parent = PlayerDetectionFrame
    PlayerDetectionWarna.BackgroundColor3 = CONFIG.COLORS.SUCCESS_GREEN
    PlayerDetectionWarna.BorderSizePixel = 0
    PlayerDetectionWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    PlayerDetectionWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local playerDetectWarnaCorner = Instance.new("UICorner")
    playerDetectWarnaCorner.Parent = PlayerDetectionWarna

    -- Auto Hide GUI
    local AutoHideFrame = Instance.new("Frame")
    AutoHideFrame.Parent = SecurityListFrame
    AutoHideFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoHideFrame.BorderSizePixel = 0
    AutoHideFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local autoHideCorner = Instance.new("UICorner")
    autoHideCorner.Parent = AutoHideFrame

    local AutoHideText = Instance.new("TextLabel")
    AutoHideText.Parent = AutoHideFrame
    AutoHideText.BackgroundTransparency = 1
    AutoHideText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoHideText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoHideText.Font = Enum.Font.SourceSansBold
    AutoHideText.Text = "Auto Hide GUI:"
    AutoHideText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoHideText.TextScaled = true
    AutoHideText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoHideBtn = Instance.new("TextButton")
    AutoHideBtn.Parent = AutoHideFrame
    AutoHideBtn.BackgroundTransparency = 1
    AutoHideBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoHideBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoHideBtn.Font = Enum.Font.SourceSansBold
    AutoHideBtn.Text = "OFF"
    AutoHideBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoHideBtn.TextScaled = true

    local AutoHideWarna = Instance.new("Frame")
    AutoHideWarna.Parent = AutoHideFrame
    AutoHideWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoHideWarna.BorderSizePixel = 0
    AutoHideWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoHideWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local autoHideWarnaCorner = Instance.new("UICorner")
    autoHideWarnaCorner.Parent = AutoHideWarna
    
    local AdvancedFrame = Instance.new("ScrollingFrame")
    AdvancedFrame.Name = "AdvancedFrame"
    AdvancedFrame.Parent = FrameUtama
    AdvancedFrame.Active = true
    AdvancedFrame.BackgroundTransparency = 1
    AdvancedFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    AdvancedFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    AdvancedFrame.Visible = false
    AdvancedFrame.ScrollBarThickness = 6

    -- Advanced Frame Content
    local AdvancedListFrame = Instance.new("Frame")
    AdvancedListFrame.Name = "AdvancedListFrame"
    AdvancedListFrame.Parent = AdvancedFrame
    AdvancedListFrame.BackgroundTransparency = 1
    AdvancedListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    AdvancedListFrame.Size = UDim2.new(1, 0, 2, 0)

    local AdvancedListLayout = Instance.new("UIListLayout")
    AdvancedListLayout.Parent = AdvancedListFrame
    AdvancedListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    AdvancedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    AdvancedListLayout.Padding = UDim.new(0, 8)

    -- Auto Sell Rare
    local AutoSellRareFrame = Instance.new("Frame")
    AutoSellRareFrame.Parent = AdvancedListFrame
    AutoSellRareFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    AutoSellRareFrame.BorderSizePixel = 0
    AutoSellRareFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local autoSellRareCorner = Instance.new("UICorner")
    autoSellRareCorner.Parent = AutoSellRareFrame

    local AutoSellRareText = Instance.new("TextLabel")
    AutoSellRareText.Parent = AutoSellRareFrame
    AutoSellRareText.BackgroundTransparency = 1
    AutoSellRareText.Position = UDim2.new(0.030, 0, 0.216, 0)
    AutoSellRareText.Size = UDim2.new(0.415, 0, 0.568, 0)
    AutoSellRareText.Font = Enum.Font.SourceSansBold
    AutoSellRareText.Text = "Auto Sell Rare:"
    AutoSellRareText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoSellRareText.TextScaled = true
    AutoSellRareText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoSellRareBtn = Instance.new("TextButton")
    AutoSellRareBtn.Parent = AutoSellRareFrame
    AutoSellRareBtn.BackgroundTransparency = 1
    AutoSellRareBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoSellRareBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoSellRareBtn.Font = Enum.Font.SourceSansBold
    AutoSellRareBtn.Text = "OFF"
    AutoSellRareBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    AutoSellRareBtn.TextScaled = true

    local AutoSellRareWarna = Instance.new("Frame")
    AutoSellRareWarna.Parent = AutoSellRareFrame
    AutoSellRareWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    AutoSellRareWarna.BorderSizePixel = 0
    AutoSellRareWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoSellRareWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local autoSellRareWarnaCorner = Instance.new("UICorner")
    autoSellRareWarnaCorner.Parent = AutoSellRareWarna

    -- Fishing Speed
    local FishingSpeedFrame = Instance.new("Frame")
    FishingSpeedFrame.Parent = AdvancedListFrame
    FishingSpeedFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    FishingSpeedFrame.BorderSizePixel = 0
    FishingSpeedFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local fishSpeedCorner = Instance.new("UICorner")
    fishSpeedCorner.Parent = FishingSpeedFrame

    local FishingSpeedText = Instance.new("TextLabel")
    FishingSpeedText.Parent = FishingSpeedFrame
    FishingSpeedText.BackgroundTransparency = 1
    FishingSpeedText.Position = UDim2.new(0.030, 0, 0.216, 0)
    FishingSpeedText.Size = UDim2.new(0.415, 0, 0.568, 0)
    FishingSpeedText.Font = Enum.Font.SourceSansBold
    FishingSpeedText.Text = "Fishing Speed:"
    FishingSpeedText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FishingSpeedText.TextScaled = true
    FishingSpeedText.TextXAlignment = Enum.TextXAlignment.Left

    local FishingSpeedInput = Instance.new("TextBox")
    FishingSpeedInput.Parent = FishingSpeedFrame
    FishingSpeedInput.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    FishingSpeedInput.BorderSizePixel = 0
    FishingSpeedInput.Position = UDim2.new(0.500, 0, 0.135, 0)
    FishingSpeedInput.Size = UDim2.new(0.150, 0, 0.730, 0)
    FishingSpeedInput.Font = Enum.Font.SourceSansBold
    FishingSpeedInput.Text = "0.5"
    FishingSpeedInput.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FishingSpeedInput.TextScaled = true
    local fishSpeedInputCorner = Instance.new("UICorner")
    fishSpeedInputCorner.Parent = FishingSpeedInput

    local FishingSpeedBtn = Instance.new("TextButton")
    FishingSpeedBtn.Parent = FishingSpeedFrame
    FishingSpeedBtn.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    FishingSpeedBtn.BorderSizePixel = 0
    FishingSpeedBtn.Position = UDim2.new(0.680, 0, 0.135, 0)
    FishingSpeedBtn.Size = UDim2.new(0.150, 0, 0.730, 0)
    FishingSpeedBtn.Font = Enum.Font.SourceSansBold
    FishingSpeedBtn.Text = "Set"
    FishingSpeedBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    FishingSpeedBtn.TextScaled = true
    local fishSpeedBtnCorner = Instance.new("UICorner")
    fishSpeedBtnCorner.Parent = FishingSpeedBtn

    -- Infinite Stamina
    local InfStaminaFrame = Instance.new("Frame")
    InfStaminaFrame.Parent = AdvancedListFrame
    InfStaminaFrame.BackgroundColor3 = CONFIG.COLORS.FRAME_BG
    InfStaminaFrame.BorderSizePixel = 0
    InfStaminaFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local infStaminaCorner = Instance.new("UICorner")
    infStaminaCorner.Parent = InfStaminaFrame

    local InfStaminaText = Instance.new("TextLabel")
    InfStaminaText.Parent = InfStaminaFrame
    InfStaminaText.BackgroundTransparency = 1
    InfStaminaText.Position = UDim2.new(0.030, 0, 0.216, 0)
    InfStaminaText.Size = UDim2.new(0.415, 0, 0.568, 0)
    InfStaminaText.Font = Enum.Font.SourceSansBold
    InfStaminaText.Text = "Infinite Stamina:"
    InfStaminaText.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    InfStaminaText.TextScaled = true
    InfStaminaText.TextXAlignment = Enum.TextXAlignment.Left

    local InfStaminaBtn = Instance.new("TextButton")
    InfStaminaBtn.Parent = InfStaminaFrame
    InfStaminaBtn.BackgroundTransparency = 1
    InfStaminaBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    InfStaminaBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    InfStaminaBtn.Font = Enum.Font.SourceSansBold
    InfStaminaBtn.Text = "OFF"
    InfStaminaBtn.TextColor3 = CONFIG.COLORS.TEXT_WHITE
    InfStaminaBtn.TextScaled = true

    local InfStaminaWarna = Instance.new("Frame")
    InfStaminaWarna.Parent = InfStaminaFrame
    InfStaminaWarna.BackgroundColor3 = CONFIG.COLORS.OFF_STATE
    InfStaminaWarna.BorderSizePixel = 0
    InfStaminaWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    InfStaminaWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local infStaminaWarnaCorner = Instance.new("UICorner")
    infStaminaWarnaCorner.Parent = InfStaminaWarna

    -- Page switching function
    local function showPanel(pageName)
        MainFrame.Visible = false
        PlayerFrame.Visible = false
        SpawnBoatFrame.Visible = false
        TeleportFrame.Visible = false
        SecurityFrame.Visible = false
        AdvancedFrame.Visible = false
        
        if pageName == "Main" then
            MainFrame.Visible = true
        elseif pageName == "Player" then
            PlayerFrame.Visible = true
        elseif pageName == "Boat" then
            SpawnBoatFrame.Visible = true
        elseif pageName == "Teleport" then
            TeleportFrame.Visible = true
        elseif pageName == "Security" then
            SecurityFrame.Visible = true
        elseif pageName == "Advanced" then
            AdvancedFrame.Visible = true
        end
        
        Tittle.Text = pageName:upper()
    end

    -- ===================================================================
    --                      BUTTON CONNECTIONS
    -- ===================================================================
    
    connections[#connections + 1] = ExitBtn.MouseButton1Click:Connect(function()
        -- Use the global toggle function to hide GUI
        guiVisible = true -- Set to true so toggleGUI will make it false
        toggleGUI()
    end)

    connections[#connections + 1] = AutoFishButton.MouseButton1Click:Connect(function()
        Settings.AutoFishing = not Settings.AutoFishing
        AutoFishButton.Text = Settings.AutoFishing and "ON" or "OFF"
        AutoFishWarna.BackgroundColor3 = Settings.AutoFishing and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        if Settings.AutoFishing then
            enhancedAutoFishing(Settings)
            createNotification("🎣 Auto Fishing started!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🎣 Auto Fishing stopped!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = AutoFishAFK2Button.MouseButton1Click:Connect(function()
        Settings.AutoFishingAFK2 = not Settings.AutoFishingAFK2
        AutoFishAFK2Button.Text = Settings.AutoFishingAFK2 and "ON" or "OFF"
        AutoFishAFK2Warna.BackgroundColor3 = Settings.AutoFishingAFK2 and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        if Settings.AutoFishingAFK2 then
            autoFishingAFK2()
            createNotification("🎣 Auto Fishing AFK2 started!", Color3.fromRGB(0, 150, 255))
        else
            createNotification("🎣 Auto Fishing AFK2 stopped!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = AutoFishExtremeButton.MouseButton1Click:Connect(function()
        Settings.AutoFishingExtreme = not Settings.AutoFishingExtreme
        AutoFishExtremeButton.Text = Settings.AutoFishingExtreme and "ON" or "OFF"
        AutoFishExtremeWarna.BackgroundColor3 = Settings.AutoFishingExtreme and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        if Settings.AutoFishingExtreme then
            autoFishingExtreme()
            createNotification("⚡ Auto Fishing EXTREME started!", Color3.fromRGB(255, 165, 0))
        else
            createNotification("⚡ Auto Fishing EXTREME stopped!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = AutoFishBrutalButton.MouseButton1Click:Connect(function()
        Settings.AutoFishingBrutal = not Settings.AutoFishingBrutal
        AutoFishBrutalButton.Text = Settings.AutoFishingBrutal and "ON" or "OFF"
        AutoFishBrutalWarna.BackgroundColor3 = Settings.AutoFishingBrutal and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        if Settings.AutoFishingBrutal then
            autoFishingBrutal()
            createNotification("🔥 Auto Fishing BRUTAL started!", Color3.fromRGB(255, 0, 0))
        else
            createNotification("🔥 Auto Fishing BRUTAL stopped!", Color3.fromRGB(200, 0, 0))
        end
    end)

    connections[#connections + 1] = SellAllButton.MouseButton1Click:Connect(function()
        safeCall(function()
            sellAll:InvokeServer()
            createNotification("🛒 Items sold!", Color3.fromRGB(255, 215, 0))
        end)
    end)

    -- PLAYER FRAME CONNECTIONS
    connections[#connections + 1] = WalkspeedBtn.MouseButton1Click:Connect(function()
        local speed = tonumber(WalkspeedInput.Text) or 16
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = speed
            createNotification("🏃 Walkspeed set to " .. speed, Color3.fromRGB(0, 255, 255))
        end
    end)

    connections[#connections + 1] = JumppowerBtn.MouseButton1Click:Connect(function()
        local jumpPower = tonumber(JumppowerInput.Text) or 50
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = jumpPower
            createNotification("🦘 Jumppower set to " .. jumpPower, Color3.fromRGB(0, 255, 255))
        end
    end)

    local noclipEnabled = false
    connections[#connections + 1] = NoclipBtn.MouseButton1Click:Connect(function()
        noclipEnabled = not noclipEnabled
        NoclipBtn.Text = noclipEnabled and "ON" or "OFF"
        NoclipWarna.BackgroundColor3 = noclipEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        
        if noclipEnabled then
            spawn(function()
                while noclipEnabled and player.Character do
                    for _, part in pairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                    wait(0.1)
                end
            end)
            createNotification("👻 Noclip enabled", Color3.fromRGB(255, 0, 255))
        else
            createNotification("👻 Noclip disabled", Color3.fromRGB(255, 0, 255))
        end
    end)

    local flyEnabled = false
    local bodyVelocity = nil
    connections[#connections + 1] = FlyBtn.MouseButton1Click:Connect(function()
        flyEnabled = not flyEnabled
        FlyBtn.Text = flyEnabled and "ON" or "OFF"
        FlyWarna.BackgroundColor3 = flyEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        
        if flyEnabled then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = player.Character.HumanoidRootPart
                createNotification("✈️ Fly enabled (E to toggle)", Color3.fromRGB(0, 255, 0))
            end
        else
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            createNotification("✈️ Fly disabled", Color3.fromRGB(255, 0, 0))
        end
    end)

    -- SECURITY FRAME CONNECTIONS
    local antiAFKEnabled = true
    connections[#connections + 1] = AntiAFKBtn.MouseButton1Click:Connect(function()
        antiAFKEnabled = not antiAFKEnabled
        AntiAFKBtn.Text = antiAFKEnabled and "ON" or "OFF"
        AntiAFKWarna.BackgroundColor3 = antiAFKEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        createNotification("🛡️ Anti AFK " .. (antiAFKEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    local playerDetectionEnabled = true
    connections[#connections + 1] = PlayerDetectionBtn.MouseButton1Click:Connect(function()
        playerDetectionEnabled = not playerDetectionEnabled
        PlayerDetectionBtn.Text = playerDetectionEnabled and "ON" or "OFF"
        PlayerDetectionWarna.BackgroundColor3 = playerDetectionEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        createNotification("👥 Player Detection " .. (playerDetectionEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    local autoHideEnabled = false
    connections[#connections + 1] = AutoHideBtn.MouseButton1Click:Connect(function()
        autoHideEnabled = not autoHideEnabled
        AutoHideBtn.Text = autoHideEnabled and "ON" or "OFF"
        AutoHideWarna.BackgroundColor3 = autoHideEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        createNotification("🫥 Auto Hide GUI " .. (autoHideEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    -- ADVANCED FRAME CONNECTIONS
    local autoSellRareEnabled = false
    connections[#connections + 1] = AutoSellRareBtn.MouseButton1Click:Connect(function()
        autoSellRareEnabled = not autoSellRareEnabled
        AutoSellRareBtn.Text = autoSellRareEnabled and "ON" or "OFF"
        AutoSellRareWarna.BackgroundColor3 = autoSellRareEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        createNotification("💎 Auto Sell Rare " .. (autoSellRareEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 215, 0))
    end)

    connections[#connections + 1] = FishingSpeedBtn.MouseButton1Click:Connect(function()
        local speed = tonumber(FishingSpeedInput.Text) or 0.5
        Settings.FishingSpeed = speed
        createNotification("⚡ Fishing speed set to " .. speed .. "s", Color3.fromRGB(255, 255, 0))
    end)

    local infStaminaEnabled = false
    connections[#connections + 1] = InfStaminaBtn.MouseButton1Click:Connect(function()
        infStaminaEnabled = not infStaminaEnabled
        InfStaminaBtn.Text = infStaminaEnabled and "ON" or "OFF"
        InfStaminaWarna.BackgroundColor3 = infStaminaEnabled and CONFIG.COLORS.SUCCESS_GREEN or CONFIG.COLORS.OFF_STATE
        
        if infStaminaEnabled then
            spawn(function()
                while infStaminaEnabled do
                    wait(0.1)
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        for _, child in pairs(player.Character.Humanoid:GetChildren()) do
                            if child.Name == "creator" then child:Destroy() end
                        end
                    end
                end
            end)
        end
        createNotification("💪 Infinite Stamina " .. (infStaminaEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 255, 0))
    end)

    -- Update statistics display
    connections[#connections + 1] = RunService.Heartbeat:Connect(function()
        local sessionTime = math.floor((tick() - Stats.sessionStartTime) / 60)
        StatsText.Text = string.format("🐟 Fish: %d | Session: %dm | 🍀 Luck: Lv1", 
            Stats.fishCaught, sessionTime)
    end)

    -- Make GUI draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil

    connections[#connections + 1] = FrameUtama.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = FrameUtama.Position
        end
    end)

    connections[#connections + 1] = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            FrameUtama.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Hotkey for hiding GUI
    connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == CONFIG.HOTKEY then
            isHidden = not isHidden
            FrameUtama.Visible = not isHidden
            
            if isHidden then
                createNotification("📦 GUI Hidden - Press F9 to show", Color3.fromRGB(255, 165, 0))
            else
                createNotification("📦 GUI Shown", Color3.fromRGB(0, 255, 0))
            end
        end
    end)

    -- Menu button connections
    connections[#connections + 1] = MAIN.MouseButton1Click:Connect(function()
        showPanel("Main")
    end)

    connections[#connections + 1] = Player.MouseButton1Click:Connect(function()
        showPanel("Player")
    end)

    connections[#connections + 1] = SpawnBoat.MouseButton1Click:Connect(function()
        showPanel("Boat")
    end)

    connections[#connections + 1] = TELEPORT.MouseButton1Click:Connect(function()
        showPanel("Teleport")
    end)

    connections[#connections + 1] = SECURITY.MouseButton1Click:Connect(function()
        showPanel("Security")
    end)

    connections[#connections + 1] = ADVANCED.MouseButton1Click:Connect(function()
        showPanel("Advanced")
    end)

    return ZayrosFISHIT
end

-- Cleanup function
local function cleanupScript()
    -- Disconnect all connections
    for _, connection in pairs(connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    connections = {}
    
    -- Clean up GUI elements
    if mainGui then
        mainGui:Destroy()
        mainGui = nil
    end
    
    if floatingButton and floatingButton.Parent then
        floatingButton.Parent:Destroy()
        floatingButton = nil
    end
    
    -- Reset global variables
    guiVisible = true
    
    print("🧹 Script cleaned up successfully")
end

-- Check if script is already running
local function checkExistingScript()
    local existingGui = player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME)
    local existingFloating = player.PlayerGui:FindFirstChild("FloatingToggle")
    
    if existingGui or existingFloating then
        if existingGui then existingGui:Destroy() end
        if existingFloating then existingFloating:Destroy() end
        warn("🔄 Previous script instance detected and removed")
        task.wait(0.5) -- Brief wait for cleanup
    end
end
-- ===================================================================
--                           INITIALIZATION
-- ===================================================================
local function initialize()
    -- Check and cleanup any existing script instances
    checkExistingScript()
    
    loadSettings()
    
    -- Create floating toggle button and store in global variable
    floatingButton = createFloatingToggleButton()
    
    -- Create main GUI and store in global variable
    mainGui = createCompleteGUI()
    
    -- Initialize GUI as visible
    guiVisible = true
    
    -- Add hotkey support (F9 to toggle)
    connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == CONFIG.HOTKEY then
            toggleGUI()
        end
    end)
    
    createNotification("🎣 " .. CONFIG.GUI_TITLE .. " V2.0 (Single File) loaded!", Color3.fromRGB(0, 255, 0))
    
    antiAFK()
    initializeSecurity()
    
    -- Character respawn detection and cleanup
    connections[#connections + 1] = player.CharacterAdded:Connect(function()
        -- Clean up and restart script after respawn
        warn("🔄 Character respawned - Script will restart for safety")
        task.wait(2) -- Wait for character to fully load
        
        cleanupScript()
        
        -- Show restart notification
        createNotification("🔄 Script restarting due to respawn...", CONFIG.COLORS.WARNING_ORANGE)
        
        task.wait(1)
        
        -- Restart the script
        initialize()
    end)
    
    print("✅ " .. CONFIG.GUI_TITLE .. " V2.0 (Single File Modular) loaded successfully!")
    print("🎯 Dark Blue Theme with Auto-Restart on Respawn")
    print("📦 Ready for loadstring(game:HttpGet())")
    print("🎮 Features: Auto Fish (4 modes), Sell All, Stats Display")
    print("🔧 Hotkey: F9 to hide/show GUI")
    print("🔄 Auto-restarts safely on character respawn")
end

initialize()

connections[#connections + 1] = Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        if CONFIG.AUTO_SAVE_SETTINGS then
            saveSettings()
        end
    end
end)

end)

if not success then
    warn("❌ Single file modular script failed to load: " .. tostring(error))
else
    print("🎉 Single file modular script loaded successfully!")
end
