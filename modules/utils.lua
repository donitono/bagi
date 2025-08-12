-- ===================================================================
--                         UTILS MODULE
-- ===================================================================

local config = require(script.Parent.config)
local CONFIG = config.CONFIG
local Services = config.Services
local player = config.Variables.player

-- ===================================================================
--                       UTILITY FUNCTIONS
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
    -- Implementation for loading settings from datastore or file
    print("Settings loaded")
end

local function saveSettings()
    -- Implementation for saving settings
    print("Settings saved")
end

-- ===================================================================
--                      NOTIFICATION SYSTEM
-- ===================================================================
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
    
    -- Animate in
    notification:TweenPosition(
        UDim2.new(1, -260, 0, 50),
        "Out", "Quad", 0.3, true
    )
    
    -- Remove after 3 seconds
    task.wait(3)
    notification:TweenPosition(
        UDim2.new(1, 10, 0, 50),
        "In", "Quad", 0.3, true,
        function() notification:Destroy() end
    )
end

-- ===================================================================
--                        ANTI-AFK SYSTEM
-- ===================================================================
local function antiAFK()
    task.spawn(function()
        while true do
            task.wait(300) -- Every 5 minutes
            safeCall(function()
                -- Small movement to prevent AFK
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

return {
    randomWait = randomWait,
    safeCall = safeCall,
    loadSettings = loadSettings,
    saveSettings = saveSettings,
    createNotification = createNotification,
    antiAFK = antiAFK
}
