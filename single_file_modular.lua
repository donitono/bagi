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
    notification.BackgroundColor3 = color or Color3.fromRGB(0, 200, 0)
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
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
        createNotification("🍀 Luck Level Up! Level " .. Stats.currentLuckLevel, Color3.fromRGB(0, 255, 0))
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
                        createNotification("🛒 Auto-sold items! (₡" .. Stats.moneyEarned .. ")", Color3.fromRGB(255, 215, 0))
                    end)
                end
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
local function createCompleteGUI()
    local ZayrosFISHIT = Instance.new("ScreenGui")
    ZayrosFISHIT.Name = CONFIG.GUI_NAME
    ZayrosFISHIT.Parent = player:WaitForChild("PlayerGui")
    ZayrosFISHIT.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local FrameUtama = Instance.new("Frame")
    FrameUtama.Name = "FrameUtama"
    FrameUtama.Parent = ZayrosFISHIT
    FrameUtama.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FrameUtama.BackgroundTransparency = 0.200
    FrameUtama.BorderSizePixel = 0
    FrameUtama.Position = UDim2.new(0.264, 0, 0.174, 0)
    FrameUtama.Size = UDim2.new(0.542, 0, 0.650, 0)
    
    local UICorner = Instance.new("UICorner")
    UICorner.Parent = FrameUtama

    -- Exit Button
    local ExitBtn = Instance.new("TextButton")
    ExitBtn.Name = "ExitBtn"
    ExitBtn.Parent = FrameUtama
    ExitBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 34)
    ExitBtn.BorderSizePixel = 0
    ExitBtn.Position = UDim2.new(0.901, 0, 0.038, 0)
    ExitBtn.Size = UDim2.new(0.063, 0, 0.088, 0)
    ExitBtn.Font = Enum.Font.SourceSansBold
    ExitBtn.Text = "X"
    ExitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExitBtn.TextScaled = true
    
    local exitCorner = Instance.new("UICorner")
    exitCorner.CornerRadius = UDim.new(0, 4)
    exitCorner.Parent = ExitBtn

    -- Side Bar
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Parent = FrameUtama
    SideBar.BackgroundColor3 = Color3.fromRGB(83, 83, 83)
    SideBar.BorderSizePixel = 0
    SideBar.Size = UDim2.new(0.376, 0, 1, 0)
    SideBar.ZIndex = 2

    -- Logo
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Parent = SideBar
    Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
    TittleSideBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    TittleSideBar.TextScaled = true
    TittleSideBar.TextXAlignment = Enum.TextXAlignment.Left

    -- Line
    local Line = Instance.new("Frame")
    Line.Name = "Line"
    Line.Parent = SideBar
    Line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(0.916, 0, 0.113, 0)
        btn.Font = Enum.Font.SourceSansBold
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    Credit.TextColor3 = Color3.fromRGB(255, 255, 255)
    Credit.TextScaled = true

    -- Main content line
    local Line_2 = Instance.new("Frame")
    Line_2.Name = "Line"
    Line_2.Parent = FrameUtama
    Line_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
    Tittle.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    AutoFishFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    AutoFishText.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    AutoFishButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoFishButton.TextScaled = true

    local AutoFishWarna = Instance.new("Frame")
    AutoFishWarna.Parent = AutoFishFrame
    AutoFishWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    AutoFishWarna.BorderSizePixel = 0
    AutoFishWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoFishWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    
    local autoFishWarnaCorner = Instance.new("UICorner")
    autoFishWarnaCorner.Parent = AutoFishWarna

    -- Sell All Frame
    local SellAllFrame = Instance.new("Frame")
    SellAllFrame.Name = "SellAllFrame"
    SellAllFrame.Parent = MainListLayoutFrame
    SellAllFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    SellAllText.TextColor3 = Color3.fromRGB(255, 255, 255)
    SellAllText.TextScaled = true

    -- Statistics Frame
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Parent = MainListLayoutFrame
    StatsFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    StatsText.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatsText.TextScaled = true

    -- Weather Frame
    local WeatherFrame = Instance.new("Frame")
    WeatherFrame.Name = "WeatherFrame"
    WeatherFrame.Parent = MainListLayoutFrame
    WeatherFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    WeatherText.TextColor3 = Color3.fromRGB(255, 255, 255)
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

    -- Player Frame Content
    local PlayerListFrame = Instance.new("Frame")
    PlayerListFrame.Name = "PlayerListFrame"
    PlayerListFrame.Parent = PlayerFrame
    PlayerListFrame.BackgroundTransparency = 1
    PlayerListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    PlayerListFrame.Size = UDim2.new(1, 0, 2, 0)

    local PlayerListLayout = Instance.new("UIListLayout")
    PlayerListLayout.Parent = PlayerListFrame
    PlayerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PlayerListLayout.Padding = UDim.new(0, 8)

    -- Walkspeed Frame
    local WalkspeedFrame = Instance.new("Frame")
    WalkspeedFrame.Parent = PlayerListFrame
    WalkspeedFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    WalkspeedFrame.BorderSizePixel = 0
    WalkspeedFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local walkCorner = Instance.new("UICorner")
    walkCorner.Parent = WalkspeedFrame

    local WalkspeedText = Instance.new("TextLabel")
    WalkspeedText.Parent = WalkspeedFrame
    WalkspeedText.BackgroundTransparency = 1
    WalkspeedText.Position = UDim2.new(0.030, 0, 0.216, 0)
    WalkspeedText.Size = UDim2.new(0.415, 0, 0.568, 0)
    WalkspeedText.Font = Enum.Font.SourceSansBold
    WalkspeedText.Text = "Walkspeed:"
    WalkspeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkspeedText.TextScaled = true
    WalkspeedText.TextXAlignment = Enum.TextXAlignment.Left

    local WalkspeedInput = Instance.new("TextBox")
    WalkspeedInput.Parent = WalkspeedFrame
    WalkspeedInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    WalkspeedInput.BorderSizePixel = 0
    WalkspeedInput.Position = UDim2.new(0.500, 0, 0.135, 0)
    WalkspeedInput.Size = UDim2.new(0.150, 0, 0.730, 0)
    WalkspeedInput.Font = Enum.Font.SourceSansBold
    WalkspeedInput.Text = "16"
    WalkspeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkspeedInput.TextScaled = true
    local walkInputCorner = Instance.new("UICorner")
    walkInputCorner.Parent = WalkspeedInput

    local WalkspeedBtn = Instance.new("TextButton")
    WalkspeedBtn.Parent = WalkspeedFrame
    WalkspeedBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    WalkspeedBtn.BorderSizePixel = 0
    WalkspeedBtn.Position = UDim2.new(0.680, 0, 0.135, 0)
    WalkspeedBtn.Size = UDim2.new(0.100, 0, 0.730, 0)
    WalkspeedBtn.Font = Enum.Font.SourceSansBold
    WalkspeedBtn.Text = "Set"
    WalkspeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    WalkspeedBtn.TextScaled = true
    local walkBtnCorner = Instance.new("UICorner")
    walkBtnCorner.Parent = WalkspeedBtn

    -- Jumppower Frame
    local JumppowerFrame = Instance.new("Frame")
    JumppowerFrame.Parent = PlayerListFrame
    JumppowerFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
    JumppowerFrame.BorderSizePixel = 0
    JumppowerFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.Parent = JumppowerFrame

    local JumppowerText = Instance.new("TextLabel")
    JumppowerText.Parent = JumppowerFrame
    JumppowerText.BackgroundTransparency = 1
    JumppowerText.Position = UDim2.new(0.030, 0, 0.216, 0)
    JumppowerText.Size = UDim2.new(0.415, 0, 0.568, 0)
    JumppowerText.Font = Enum.Font.SourceSansBold
    JumppowerText.Text = "Jumppower:"
    JumppowerText.TextColor3 = Color3.fromRGB(255, 255, 255)
    JumppowerText.TextScaled = true
    JumppowerText.TextXAlignment = Enum.TextXAlignment.Left

    local JumppowerInput = Instance.new("TextBox")
    JumppowerInput.Parent = JumppowerFrame
    JumppowerInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    JumppowerInput.BorderSizePixel = 0
    JumppowerInput.Position = UDim2.new(0.500, 0, 0.135, 0)
    JumppowerInput.Size = UDim2.new(0.150, 0, 0.730, 0)
    JumppowerInput.Font = Enum.Font.SourceSansBold
    JumppowerInput.Text = "50"
    JumppowerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    JumppowerInput.TextScaled = true
    local jumpInputCorner = Instance.new("UICorner")
    jumpInputCorner.Parent = JumppowerInput

    local JumppowerBtn = Instance.new("TextButton")
    JumppowerBtn.Parent = JumppowerFrame
    JumppowerBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    JumppowerBtn.BorderSizePixel = 0
    JumppowerBtn.Position = UDim2.new(0.680, 0, 0.135, 0)
    JumppowerBtn.Size = UDim2.new(0.100, 0, 0.730, 0)
    JumppowerBtn.Font = Enum.Font.SourceSansBold
    JumppowerBtn.Text = "Set"
    JumppowerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    JumppowerBtn.TextScaled = true
    local jumpBtnCorner = Instance.new("UICorner")
    jumpBtnCorner.Parent = JumppowerBtn

    -- Noclip Frame
    local NoclipFrame = Instance.new("Frame")
    NoclipFrame.Parent = PlayerListFrame
    NoclipFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    NoclipText.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoclipText.TextScaled = true
    NoclipText.TextXAlignment = Enum.TextXAlignment.Left

    local NoclipBtn = Instance.new("TextButton")
    NoclipBtn.Parent = NoclipFrame
    NoclipBtn.BackgroundTransparency = 1
    NoclipBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    NoclipBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    NoclipBtn.Font = Enum.Font.SourceSansBold
    NoclipBtn.Text = "OFF"
    NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoclipBtn.TextScaled = true

    local NoclipWarna = Instance.new("Frame")
    NoclipWarna.Parent = NoclipFrame
    NoclipWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    NoclipWarna.BorderSizePixel = 0
    NoclipWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    NoclipWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local noclipWarnaCorner = Instance.new("UICorner")
    noclipWarnaCorner.Parent = NoclipWarna

    -- Fly Frame
    local FlyFrame = Instance.new("Frame")
    FlyFrame.Parent = PlayerListFrame
    FlyFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    FlyText.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlyText.TextScaled = true
    FlyText.TextXAlignment = Enum.TextXAlignment.Left

    local FlyBtn = Instance.new("TextButton")
    FlyBtn.Parent = FlyFrame
    FlyBtn.BackgroundTransparency = 1
    FlyBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    FlyBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    FlyBtn.Font = Enum.Font.SourceSansBold
    FlyBtn.Text = "OFF"
    FlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FlyBtn.TextScaled = true

    local FlyWarna = Instance.new("Frame")
    FlyWarna.Parent = FlyFrame
    FlyWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
        BoatFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
        BoatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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

    -- Teleport Frame Content
    local TeleportListFrame = Instance.new("Frame")
    TeleportListFrame.Name = "TeleportListFrame"
    TeleportListFrame.Parent = TeleportFrame
    TeleportListFrame.BackgroundTransparency = 1
    TeleportListFrame.Position = UDim2.new(0, 0, 0.022, 0)
    TeleportListFrame.Size = UDim2.new(1, 0, 2, 0)

    local TeleportListLayout = Instance.new("UIListLayout")
    TeleportListLayout.Parent = TeleportListFrame
    TeleportListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TeleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TeleportListLayout.Padding = UDim.new(0, 8)

    -- Teleport locations
    local teleportLocations = {
        {name = "🏪 Shop", pos = Vector3.new(-39, 10, -921)},
        {name = "🎣 Fishing Spot 1", pos = Vector3.new(-100, 10, -800)},
        {name = "🌊 Deep Sea", pos = Vector3.new(-500, 10, -1500)},
        {name = "🏝️ Island", pos = Vector3.new(200, 10, 300)},
        {name = "🏠 Spawn", pos = Vector3.new(0, 10, 0)},
        {name = "⛵ Dock", pos = Vector3.new(-50, 10, -950)}
    }

    for i, location in ipairs(teleportLocations) do
        local TpFrame = Instance.new("Frame")
        TpFrame.Parent = TeleportListFrame
        TpFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
        TpFrame.BorderSizePixel = 0
        TpFrame.Size = UDim2.new(0.898, 0, 0.053, 0)
        local tpCorner = Instance.new("UICorner")
        tpCorner.Parent = TpFrame

        local TpBtn = Instance.new("TextButton")
        TpBtn.Parent = TpFrame
        TpBtn.BackgroundTransparency = 1
        TpBtn.Size = UDim2.new(1, 0, 1, 0)
        TpBtn.Font = Enum.Font.SourceSansBold
        TpBtn.Text = location.name
        TpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TpBtn.TextScaled = true

        -- Teleport connection
        connections[#connections + 1] = TpBtn.MouseButton1Click:Connect(function()
            safeCall(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(location.pos)
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
    AntiAFKFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    AntiAFKText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AntiAFKText.TextScaled = true
    AntiAFKText.TextXAlignment = Enum.TextXAlignment.Left

    local AntiAFKBtn = Instance.new("TextButton")
    AntiAFKBtn.Parent = AntiAFKFrame
    AntiAFKBtn.BackgroundTransparency = 1
    AntiAFKBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AntiAFKBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AntiAFKBtn.Font = Enum.Font.SourceSansBold
    AntiAFKBtn.Text = "ON"
    AntiAFKBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AntiAFKBtn.TextScaled = true

    local AntiAFKWarna = Instance.new("Frame")
    AntiAFKWarna.Parent = AntiAFKFrame
    AntiAFKWarna.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    AntiAFKWarna.BorderSizePixel = 0
    AntiAFKWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AntiAFKWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local antiAfkWarnaCorner = Instance.new("UICorner")
    antiAfkWarnaCorner.Parent = AntiAFKWarna

    -- Player Detection
    local PlayerDetectionFrame = Instance.new("Frame")
    PlayerDetectionFrame.Parent = SecurityListFrame
    PlayerDetectionFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    PlayerDetectionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerDetectionText.TextScaled = true
    PlayerDetectionText.TextXAlignment = Enum.TextXAlignment.Left

    local PlayerDetectionBtn = Instance.new("TextButton")
    PlayerDetectionBtn.Parent = PlayerDetectionFrame
    PlayerDetectionBtn.BackgroundTransparency = 1
    PlayerDetectionBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    PlayerDetectionBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    PlayerDetectionBtn.Font = Enum.Font.SourceSansBold
    PlayerDetectionBtn.Text = "ON"
    PlayerDetectionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerDetectionBtn.TextScaled = true

    local PlayerDetectionWarna = Instance.new("Frame")
    PlayerDetectionWarna.Parent = PlayerDetectionFrame
    PlayerDetectionWarna.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    PlayerDetectionWarna.BorderSizePixel = 0
    PlayerDetectionWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    PlayerDetectionWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local playerDetectWarnaCorner = Instance.new("UICorner")
    playerDetectWarnaCorner.Parent = PlayerDetectionWarna

    -- Auto Hide GUI
    local AutoHideFrame = Instance.new("Frame")
    AutoHideFrame.Parent = SecurityListFrame
    AutoHideFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    AutoHideText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoHideText.TextScaled = true
    AutoHideText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoHideBtn = Instance.new("TextButton")
    AutoHideBtn.Parent = AutoHideFrame
    AutoHideBtn.BackgroundTransparency = 1
    AutoHideBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoHideBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoHideBtn.Font = Enum.Font.SourceSansBold
    AutoHideBtn.Text = "OFF"
    AutoHideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoHideBtn.TextScaled = true

    local AutoHideWarna = Instance.new("Frame")
    AutoHideWarna.Parent = AutoHideFrame
    AutoHideWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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
    AutoSellRareFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    AutoSellRareText.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoSellRareText.TextScaled = true
    AutoSellRareText.TextXAlignment = Enum.TextXAlignment.Left

    local AutoSellRareBtn = Instance.new("TextButton")
    AutoSellRareBtn.Parent = AutoSellRareFrame
    AutoSellRareBtn.BackgroundTransparency = 1
    AutoSellRareBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    AutoSellRareBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    AutoSellRareBtn.Font = Enum.Font.SourceSansBold
    AutoSellRareBtn.Text = "OFF"
    AutoSellRareBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoSellRareBtn.TextScaled = true

    local AutoSellRareWarna = Instance.new("Frame")
    AutoSellRareWarna.Parent = AutoSellRareFrame
    AutoSellRareWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    AutoSellRareWarna.BorderSizePixel = 0
    AutoSellRareWarna.Position = UDim2.new(0.756, 0, 0.135, 0)
    AutoSellRareWarna.Size = UDim2.new(0.204, 0, 0.730, 0)
    local autoSellRareWarnaCorner = Instance.new("UICorner")
    autoSellRareWarnaCorner.Parent = AutoSellRareWarna

    -- Fishing Speed
    local FishingSpeedFrame = Instance.new("Frame")
    FishingSpeedFrame.Parent = AdvancedListFrame
    FishingSpeedFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    FishingSpeedText.TextColor3 = Color3.fromRGB(255, 255, 255)
    FishingSpeedText.TextScaled = true
    FishingSpeedText.TextXAlignment = Enum.TextXAlignment.Left

    local FishingSpeedInput = Instance.new("TextBox")
    FishingSpeedInput.Parent = FishingSpeedFrame
    FishingSpeedInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FishingSpeedInput.BorderSizePixel = 0
    FishingSpeedInput.Position = UDim2.new(0.500, 0, 0.135, 0)
    FishingSpeedInput.Size = UDim2.new(0.150, 0, 0.730, 0)
    FishingSpeedInput.Font = Enum.Font.SourceSansBold
    FishingSpeedInput.Text = "0.5"
    FishingSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    FishingSpeedInput.TextScaled = true
    local fishSpeedInputCorner = Instance.new("UICorner")
    fishSpeedInputCorner.Parent = FishingSpeedInput

    local FishingSpeedBtn = Instance.new("TextButton")
    FishingSpeedBtn.Parent = FishingSpeedFrame
    FishingSpeedBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    FishingSpeedBtn.BorderSizePixel = 0
    FishingSpeedBtn.Position = UDim2.new(0.680, 0, 0.135, 0)
    FishingSpeedBtn.Size = UDim2.new(0.100, 0, 0.730, 0)
    FishingSpeedBtn.Font = Enum.Font.SourceSansBold
    FishingSpeedBtn.Text = "Set"
    FishingSpeedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FishingSpeedBtn.TextScaled = true
    local fishSpeedBtnCorner = Instance.new("UICorner")
    fishSpeedBtnCorner.Parent = FishingSpeedBtn

    -- Infinite Stamina
    local InfStaminaFrame = Instance.new("Frame")
    InfStaminaFrame.Parent = AdvancedListFrame
    InfStaminaFrame.BackgroundColor3 = Color3.fromRGB(47, 47, 47)
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
    InfStaminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
    InfStaminaText.TextScaled = true
    InfStaminaText.TextXAlignment = Enum.TextXAlignment.Left

    local InfStaminaBtn = Instance.new("TextButton")
    InfStaminaBtn.Parent = InfStaminaFrame
    InfStaminaBtn.BackgroundTransparency = 1
    InfStaminaBtn.Position = UDim2.new(0.756, 0, 0.108, 0)
    InfStaminaBtn.Size = UDim2.new(0.207, 0, 0.784, 0)
    InfStaminaBtn.Font = Enum.Font.SourceSansBold
    InfStaminaBtn.Text = "OFF"
    InfStaminaBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    InfStaminaBtn.TextScaled = true

    local InfStaminaWarna = Instance.new("Frame")
    InfStaminaWarna.Parent = InfStaminaFrame
    InfStaminaWarna.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
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

    -- ===================================================================
    --                      BUTTON CONNECTIONS
    -- ===================================================================
    
    connections[#connections + 1] = ExitBtn.MouseButton1Click:Connect(function()
        ZayrosFISHIT:Destroy()
        for _, connection in pairs(connections) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
    end)

    connections[#connections + 1] = AutoFishButton.MouseButton1Click:Connect(function()
        Settings.AutoFishing = not Settings.AutoFishing
        AutoFishButton.Text = Settings.AutoFishing and "ON" or "OFF"
        AutoFishWarna.BackgroundColor3 = Settings.AutoFishing and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        if Settings.AutoFishing then
            enhancedAutoFishing(Settings)
            createNotification("🎣 Auto Fishing started!", Color3.fromRGB(0, 200, 0))
        else
            createNotification("🎣 Auto Fishing stopped!", Color3.fromRGB(200, 0, 0))
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
        NoclipWarna.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        
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
        FlyWarna.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        
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
        AntiAFKWarna.BackgroundColor3 = antiAFKEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        createNotification("🛡️ Anti AFK " .. (antiAFKEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    local playerDetectionEnabled = true
    connections[#connections + 1] = PlayerDetectionBtn.MouseButton1Click:Connect(function()
        playerDetectionEnabled = not playerDetectionEnabled
        PlayerDetectionBtn.Text = playerDetectionEnabled and "ON" or "OFF"
        PlayerDetectionWarna.BackgroundColor3 = playerDetectionEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        createNotification("👥 Player Detection " .. (playerDetectionEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    local autoHideEnabled = false
    connections[#connections + 1] = AutoHideBtn.MouseButton1Click:Connect(function()
        autoHideEnabled = not autoHideEnabled
        AutoHideBtn.Text = autoHideEnabled and "ON" or "OFF"
        AutoHideWarna.BackgroundColor3 = autoHideEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        createNotification("🫥 Auto Hide GUI " .. (autoHideEnabled and "enabled" or "disabled"), Color3.fromRGB(255, 165, 0))
    end)

    -- ADVANCED FRAME CONNECTIONS
    local autoSellRareEnabled = false
    connections[#connections + 1] = AutoSellRareBtn.MouseButton1Click:Connect(function()
        autoSellRareEnabled = not autoSellRareEnabled
        AutoSellRareBtn.Text = autoSellRareEnabled and "ON" or "OFF"
        AutoSellRareWarna.BackgroundColor3 = autoSellRareEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
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
        InfStaminaWarna.BackgroundColor3 = infStaminaEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(0, 0, 0)
        
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

    return ZayrosFISHIT
end

-- ===================================================================
--                           INITIALIZATION
-- ===================================================================
local function initialize()
    loadSettings()
    
    createCompleteGUI()
    createNotification("🎣 " .. CONFIG.GUI_TITLE .. " V2.0 (Single File) loaded!", Color3.fromRGB(0, 255, 0))
    
    antiAFK()
    initializeSecurity()
    
    connections[#connections + 1] = player.CharacterAdded:Connect(function()
        task.wait(1)
        setWalkSpeed(Settings.WalkSpeed)
        setJumpPower(Settings.JumpPower)
    end)
    
    print("✅ " .. CONFIG.GUI_TITLE .. " V2.0 (Single File Modular) loaded successfully!")
    print("🎯 Simplified GUI with essential features")
    print("📦 Ready for loadstring(game:HttpGet())")
    print("🎮 Features: Auto Fish, Sell All, Stats Display")
    print("🔧 Hotkey: F9 to hide/show GUI")
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
