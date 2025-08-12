-- ===================================================================
--                         STATS MODULE
-- ===================================================================

local utils = require(script.Parent.utils)
local createNotification = utils.createNotification

-- ===================================================================
--                         STATISTICS
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

-- ===================================================================
--                         LUCK SYSTEM
-- ===================================================================
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

-- ===================================================================
--                       WEATHER SYSTEM
-- ===================================================================
local WeatherTypes = {
    "Sunny", "Rainy", "Cloudy", "Stormy", "Foggy", "Windy"
}

local WeatherEffects = {
    Sunny = {luck = 1.2, fish_rate = 1.1, description = "☀️ Perfect fishing weather!"},
    Rainy = {luck = 1.5, fish_rate = 1.3, description = "🌧️ Fish are more active!"},
    Cloudy = {luck = 1.0, fish_rate = 1.0, description = "☁️ Normal conditions"},
    Stormy = {luck = 2.0, fish_rate = 0.8, description = "⛈️ Dangerous but lucky!"},
    Foggy = {luck = 1.8, fish_rate = 0.9, description = "🌫️ Mysterious waters"},
    Windy = {luck = 1.1, fish_rate = 1.2, description = "💨 Good for surface fish"}
}

local currentWeather = "Sunny"

-- ===================================================================
--                        TIME SYSTEM
-- ===================================================================
local TimeEffects = {
    Dawn = {luck = 1.4, fish_rate = 1.2, description = "🌅 Golden hour fishing!"},
    Morning = {luck = 1.1, fish_rate = 1.1, description = "🌞 Good morning catch"},
    Noon = {luck = 0.9, fish_rate = 1.0, description = "☀️ Fish are hiding"},
    Evening = {luck = 1.3, fish_rate = 1.3, description = "🌆 Prime fishing time"},
    Night = {luck = 1.6, fish_rate = 0.8, description = "🌙 Rare night fish"},
    Midnight = {luck = 2.2, fish_rate = 0.6, description = "🌌 Legendary hour"}
}

-- ===================================================================
--                      FISHING SPOTS
-- ===================================================================
local FishingSpots = {
    {name = "Shallow Waters", luck = 1.0, rarity = "Common", bonus = "Fast catch rate"},
    {name = "Deep Ocean", luck = 1.8, rarity = "Rare", bonus = "Big fish chance"},
    {name = "Coral Reef", luck = 1.5, rarity = "Exotic", bonus = "Colorful fish"},
    {name = "Mysterious Cave", luck = 2.5, rarity = "Legendary", bonus = "Ancient fish"},
    {name = "Volcanic Waters", luck = 3.0, rarity = "Mythical", bonus = "Fire fish"},
    {name = "Frozen Lake", luck = 2.2, rarity = "Ice", bonus = "Ice fish"}
}

local currentSpot = FishingSpots[1]

-- ===================================================================
--                        LUCK FUNCTIONS
-- ===================================================================
local function calculateCurrentLuck(Settings)
    local baseLuck = LuckSystem.baseChance
    local totalMultiplier = LuckSystem.boostMultiplier
    
    if Settings.WeatherBoost then
        totalMultiplier = totalMultiplier * (WeatherEffects[currentWeather].luck or 1.0)
    end
    
    if Settings.TimeBoost then
        local hour = tonumber(os.date("%H"))
        local timeKey = "Morning"
        if hour >= 5 and hour < 8 then timeKey = "Dawn"
        elseif hour >= 8 and hour < 12 then timeKey = "Morning"  
        elseif hour >= 12 and hour < 17 then timeKey = "Noon"
        elseif hour >= 17 and hour < 20 then timeKey = "Evening"
        elseif hour >= 20 and hour < 24 then timeKey = "Night"
        else timeKey = "Midnight" end
        
        totalMultiplier = totalMultiplier * (TimeEffects[timeKey].luck or 1.0)
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
        
        -- Bonus reward for leveling up
        if Stats.currentLuckLevel % 5 == 0 then
            createNotification("🎁 Milestone Bonus! Special luck boost!", Color3.fromRGB(255, 215, 0))
        end
    end
end

local function generateRandomWeather()
    local oldWeather = currentWeather
    currentWeather = WeatherTypes[math.random(1, #WeatherTypes)]
    
    if currentWeather ~= oldWeather then
        local effect = WeatherEffects[currentWeather]
        createNotification(effect.description, Color3.fromRGB(100, 200, 255))
        Stats.weatherBonuses = Stats.weatherBonuses + 1
    end
end

local function getFishRarity(Settings)
    local luck = calculateCurrentLuck(Settings)
    local roll = math.random()
    
    if roll <= luck * 0.001 then -- 0.1% base for mythical
        return "Mythical", Color3.fromRGB(255, 0, 255)
    elseif roll <= luck * 0.01 then -- 1% base for legendary  
        Stats.legendaryFishCaught = Stats.legendaryFishCaught + 1
        return "Legendary", Color3.fromRGB(255, 215, 0)
    elseif roll <= luck * 0.05 then -- 5% base for rare
        Stats.rareFishCaught = Stats.rareFishCaught + 1
        return "Rare", Color3.fromRGB(128, 0, 255)
    elseif roll <= luck * 0.15 then -- 15% base for uncommon
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
--                      WEATHER CYCLE
-- ===================================================================
local function startWeatherCycle()
    task.spawn(function()
        while true do
            task.wait(math.random(300, 600)) -- Weather changes every 5-10 minutes
            generateRandomWeather()
        end
    end)
end

return {
    Stats = Stats,
    LuckSystem = LuckSystem,
    WeatherTypes = WeatherTypes,
    WeatherEffects = WeatherEffects,
    TimeEffects = TimeEffects,
    FishingSpots = FishingSpots,
    currentWeather = currentWeather,
    currentSpot = currentSpot,
    calculateCurrentLuck = calculateCurrentLuck,
    updateLuckLevel = updateLuckLevel,
    generateRandomWeather = generateRandomWeather,
    getFishRarity = getFishRarity,
    simulateFishValue = simulateFishValue,
    startWeatherCycle = startWeatherCycle
}
