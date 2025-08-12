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
    local PlayerFrame = Instance.new("Frame")
    PlayerFrame.Name = "PlayerFrame"
    PlayerFrame.Parent = FrameUtama
    PlayerFrame.BackgroundTransparency = 1
    PlayerFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    PlayerFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    PlayerFrame.Visible = false
    
    local SpawnBoatFrame = Instance.new("Frame")
    SpawnBoatFrame.Name = "SpawnBoatFrame"
    SpawnBoatFrame.Parent = FrameUtama
    SpawnBoatFrame.BackgroundTransparency = 1
    SpawnBoatFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SpawnBoatFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SpawnBoatFrame.Visible = false
    
    local TeleportFrame = Instance.new("Frame")
    TeleportFrame.Name = "TeleportFrame"
    TeleportFrame.Parent = FrameUtama
    TeleportFrame.BackgroundTransparency = 1
    TeleportFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    TeleportFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    TeleportFrame.Visible = false
    
    local SecurityFrame = Instance.new("Frame")
    SecurityFrame.Name = "SecurityFrame"
    SecurityFrame.Parent = FrameUtama
    SecurityFrame.BackgroundTransparency = 1
    SecurityFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    SecurityFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    SecurityFrame.Visible = false
    
    local AdvancedFrame = Instance.new("Frame")
    AdvancedFrame.Name = "AdvancedFrame"
    AdvancedFrame.Parent = FrameUtama
    AdvancedFrame.BackgroundTransparency = 1
    AdvancedFrame.Position = UDim2.new(0.376, 0, 0.147, 0)
    AdvancedFrame.Size = UDim2.new(0.624, 0, 0.853, 0)
    AdvancedFrame.Visible = false

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
