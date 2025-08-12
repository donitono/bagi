-- ===================================================================
--                        SECURITY MODULE
-- ===================================================================

local config = require(script.Parent.config)
local utils = require(script.Parent.utils)
local Services = config.Services
local player = config.Variables.player
local connections = config.Variables.connections
local CONFIG = config.CONFIG
local createNotification = utils.createNotification

-- ===================================================================
--                        SECURITY FEATURES
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

-- ===================================================================
--                       SECURITY FUNCTIONS
-- ===================================================================
local function isPlayerAdmin(targetPlayer)
    -- Check if player is admin/moderator
    if targetPlayer:GetRankInGroup(0) >= 100 then return true end
    if targetPlayer.Name:lower():find("admin") or targetPlayer.Name:lower():find("mod") then return true end
    if targetPlayer.DisplayName:lower():find("admin") or targetPlayer.DisplayName:lower():find("mod") then return true end
    
    -- Check for admin gamepass or badges (customize these IDs based on the game)
    local adminGamepasses = {123456, 789012} -- Replace with actual admin gamepass IDs
    for _, gamepassId in ipairs(adminGamepasses) do
        if game:GetService("MarketplaceService"):UserOwnsGamePassAsync(targetPlayer.UserId, gamepassId) then
            return true
        end
    end
    
    return false
end

local function logSuspiciousActivity(activity, playerName)
    SecurityStats.SuspiciousActivities = SecurityStats.SuspiciousActivities + 1
    local timestamp = os.date("%H:%M:%S")
    warn(string.format("🔒 [%s] Suspicious Activity: %s | Player: %s", timestamp, activity, playerName or "Unknown"))
end

local function getPlayerDistance(targetPlayer)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return math.huge end
    
    local distance = (player.Character.HumanoidRootPart.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
    return distance
end

local function checkPlayerProximity(isHidden)
    if not SecuritySettings.PlayerProximityAlert then return end
    
    for _, targetPlayer in pairs(Services.Players:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character then
            local distance = getPlayerDistance(targetPlayer)
            
            if distance <= SecuritySettings.ProximityDistance then
                -- Check if player is blacklisted
                for _, blacklisted in ipairs(SecuritySettings.BlacklistedPlayers) do
                    if targetPlayer.Name == blacklisted then
                        SecurityStats.ProximityAlerts = SecurityStats.ProximityAlerts + 1
                        createNotification("⚠️ Blacklisted player nearby: " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
                        logSuspiciousActivity("Blacklisted player proximity", targetPlayer.Name)
                        
                        if SecuritySettings.AutoHideOnAdmin then
                            isHidden = true
                            local gui = player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME)
                            if gui then gui.Enabled = false end
                            SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                        end
                        break
                    end
                end
                
                -- Check if admin is nearby
                if isPlayerAdmin(targetPlayer) then
                    SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
                    SecurityStats.ProximityAlerts = SecurityStats.ProximityAlerts + 1
                    createNotification("🚨 ADMIN NEARBY: " .. targetPlayer.Name, Color3.fromRGB(255, 0, 0))
                    logSuspiciousActivity("Admin proximity detected", targetPlayer.Name)
                    
                    if SecuritySettings.AutoHideOnAdmin then
                        isHidden = true
                        local gui = player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME)
                        if gui then gui.Enabled = false end
                        SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                    end
                end
            end
        end
    end
    return isHidden
end

local function monitorChatForAdmins()
    connections[#connections + 1] = Services.Players.PlayerAdded:Connect(function(newPlayer)
        if isPlayerAdmin(newPlayer) then
            SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
            createNotification("🚨 Admin joined server: " .. newPlayer.Name, Color3.fromRGB(255, 0, 0))
            logSuspiciousActivity("Admin joined server", newPlayer.Name)
        end
    end)
    
    -- Monitor chat messages for admin commands
    connections[#connections + 1] = Services.Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.Chatted:Connect(function(message)
            local adminCommands = {":ban", ":kick", ":warn", "/ban", "/kick", "/warn", ":tp", "/tp"}
            for _, command in ipairs(adminCommands) do
                if message:lower():find(command) then
                    if isPlayerAdmin(newPlayer) then
                        createNotification("🔴 Admin command detected!", Color3.fromRGB(255, 0, 0))
                        logSuspiciousActivity("Admin command used: " .. command, newPlayer.Name)
                        
                        if SecuritySettings.AutoHideOnAdmin then
                            local isHidden = true
                            local gui = player.PlayerGui:FindFirstChild(CONFIG.GUI_NAME)
                            if gui then gui.Enabled = false end
                            SecurityStats.AutoHides = SecurityStats.AutoHides + 1
                        end
                    end
                    break
                end
            end
        end)
    end)
end

local function initializeSecurity()
    -- Start proximity monitoring
    task.spawn(function()
        while true do
            local isHidden = config.Variables.isHidden
            isHidden = checkPlayerProximity(isHidden)
            config.Variables.isHidden = isHidden
            task.wait(2) -- Check every 2 seconds
        end
    end)
    
    -- Monitor for admin activity
    monitorChatForAdmins()
    
    -- Check existing players
    for _, existingPlayer in pairs(Services.Players:GetPlayers()) do
        if existingPlayer ~= player and isPlayerAdmin(existingPlayer) then
            SecurityStats.AdminsDetected = SecurityStats.AdminsDetected + 1
            createNotification("🚨 Admin in server: " .. existingPlayer.Name, Color3.fromRGB(255, 0, 0))
        end
    end
end

return {
    SecuritySettings = SecuritySettings,
    SecurityStats = SecurityStats,
    isPlayerAdmin = isPlayerAdmin,
    logSuspiciousActivity = logSuspiciousActivity,
    getPlayerDistance = getPlayerDistance,
    checkPlayerProximity = checkPlayerProximity,
    monitorChatForAdmins = monitorChatForAdmins,
    initializeSecurity = initializeSecurity
}
