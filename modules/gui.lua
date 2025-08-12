-- ===================================================================
--                          GUI MODULE
-- ===================================================================

local config = require(script.Parent.config)
local utils = require(script.Parent.utils)
local stats = require(script.Parent.stats)
local security = require(script.Parent.security)
local player_module = require(script.Parent.player)
local fishing = require(script.Parent.fishing)

local Services = config.Services
local CONFIG = config.CONFIG
local Remotes = config.Remotes
local Workspace = config.Workspace
local player = config.Variables.player
local connections = config.Variables.connections
local isHidden = config.Variables.isHidden

local createNotification = utils.createNotification
local safeCall = utils.safeCall
local Stats = stats.Stats
local SecuritySettings = security.SecuritySettings
local SecurityStats = security.SecurityStats

-- Settings structure (this would normally be passed in or imported)
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
    SmartFishing = false,
    -- AFK2 Settings
    AFK2_DelayMode = "CUSTOM",
    AFK2_CustomDelay = 1.0,
    AFK2_FixedDelay = 0.8,
    AFK2_MinDelay = 0.5,
    AFK2_MaxDelay = 2.0,
    -- Extreme Settings
    ExtremeSpeed = "HIGH",
    ExtremeDelay = 0.05,
    ExtremeSafeMode = false,
    -- Brutal Settings
    BrutalCustomDelay = 0.02,
    BrutalSafeMode = false
}

-- ===================================================================
--                       GUI CREATION
-- ===================================================================
local function createCompleteGUI()
    -- Create main ScreenGui
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

    return {
        ZayrosFISHIT = ZayrosFISHIT,
        FrameUtama = FrameUtama,
        ExitBtn = ExitBtn,
        MAIN = MAIN,
        Player = Player,
        SpawnBoat = SpawnBoat,
        TELEPORT = TELEPORT,
        SECURITY = SECURITY,
        ADVANCED = ADVANCED,
        Tittle = Tittle,
        Settings = Settings
    }
end

return {
    createCompleteGUI = createCompleteGUI,
    Settings = Settings
}
