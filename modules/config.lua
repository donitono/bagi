-- ===================================================================
--                         CONFIG MODULE
-- ===================================================================

local CONFIG = {
    GUI_NAME = "GamerXsan", -- Ganti nama GUI disini
    GUI_TITLE = "Mod GamerXsan", -- Ganti judul yang ditampilkan
    LOGO_IMAGE = "rbxassetid://10776847027", -- Ganti dengan ID gambar kamu
    HOTKEY = Enum.KeyCode.F9, -- Hide/Show GUI
    AUTO_SAVE_SETTINGS = true,
    FISHING_DELAYS = {
        MIN = 0.1,
        MAX = 0.3
    },
    -- AFK2 AutoFish Settings
    AFK2_DELAYS = {
        MIN = 0.5,    -- Minimum delay untuk AFK2
        MAX = 2.0,    -- Maximum delay untuk AFK2
        CUSTOM = 1.0  -- Custom delay yang bisa diatur user
    }
}

-- ===================================================================
--                           SERVICES
-- ===================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

-- ===================================================================
--                        REMOTE REFERENCES
-- ===================================================================
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

-- ===================================================================
--                           VARIABLES
-- ===================================================================
local player = Players.LocalPlayer
local connections = {}
local isHidden = false

return {
    CONFIG = CONFIG,
    Services = {
        Players = Players,
        UserInputService = UserInputService,
        TweenService = TweenService,
        RunService = RunService,
        Rs = Rs
    },
    Remotes = {
        EquipRod = EquipRod,
        UnEquipRod = UnEquipRod,
        RequestFishing = RequestFishing,
        ChargeRod = ChargeRod,
        FishingComplete = FishingComplete,
        CancelFishing = CancelFishing,
        spawnBoat = spawnBoat,
        despawnBoat = despawnBoat,
        sellAll = sellAll
    },
    External = {
        noOxygen = noOxygen
    },
    Workspace = {
        tpFolder = tpFolder,
        charFolder = charFolder
    },
    Variables = {
        player = player,
        connections = connections,
        isHidden = isHidden
    }
}
