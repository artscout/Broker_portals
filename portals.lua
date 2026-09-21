if not LibStub then return end

local dewdrop = LibStub('LibDewdrop-3.0', true)
local icon = LibStub('LibDBIcon-1.0')

local _

local CreateFrame = CreateFrame
local C_ToyBox = C_ToyBox
local GetBindLocation = GetBindLocation
local GetContainerItemCooldown = C_Container.GetContainerItemCooldown
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerItemLink = C_Container.GetContainerItemLink
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetItemCooldown = C_Container.GetItemCooldown
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemLink = GetInventoryItemLink
local GetNumGroupMembers = GetNumGroupMembers
local GetSpellBookItemName = GetSpellBookItemName or C_SpellBook.GetSpellBookItemName
local GetSpellCooldown = GetSpellCooldown or C_Spell.GetSpellCooldown
local GetSpellInfo = GetSpellInfo or C_Spell.GetSpellInfo
local GetSpellDescription = GetSpellDescription or C_Spell.GetSpellDescription
local GetItemCount = GetItemCount or C_Item.GetItemCount
local GetItemInfo = GetItemInfo or C_Item.GetItemInfo
local GetItemSpell = GetItemSpell or C_Item.GetItemSpell
local GetTime = GetTime
local IsPlayerSpell = IsPlayerSpell
local PlayerHasToy = PlayerHasToy
local SecondsToTime = SecondsToTime
local SendChatMessage = SendChatMessage
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitRace = UnitRace
local UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT

local isClassicEra       = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isTBCClassic       = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
local isWotlkClassic     = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
local isCataclysmClassic = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
local isMoPClassic       = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
-- WoW Forever ("camelot") runs on the mainline code base and therefore reports
-- WOW_PROJECT_ID == WOW_PROJECT_MAINLINE, but its world is vanilla Azeroth: no
-- housing, no retail-only services. Asking a Forever server for housing data
-- (C_Housing.GetPlayerOwnedHouses) drops the connection, so mainline must be
-- detected with camelot excluded. It is identified by TOC version - 1.60.x
-- reports 16001, which sits between Classic Era (11508) and TBC (20506).
local gameVersion, _, _, tocVersion = GetBuildInfo()
tocVersion = tocVersion or 0

-- Identify Forever positively, so the detection holds whatever WOW_PROJECT_ID
-- reports now or later: today it reports MAINLINE (which is what let the
-- housing query through again), tomorrow it may get its own constant. Two
-- independent markers, either is enough:
--   * interface version in the 1.6x band (1.60.1 -> 16001)
--   * version string "1.60.x" from GetBuildInfo
local isCamelot          = (tocVersion >= 16000 and tocVersion < 20000)
    or (type(gameVersion) == "string" and gameVersion:match("^1%.6%d") ~= nil)
local isRetail           = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE) and not isCamelot
local challengeAvailable = select(4, GetBuildInfo()) > 49999
local engineeringName    = C_TradeSkillUI.GetTradeSkillDisplayName(202)
local engineeringIcon    = C_TradeSkillUI.GetTradeSkillTexture(202)
local heartstonesIcon    = 134414 -- icon of Heartstone
local teleportsIcon      = 237509 -- Teleport to Dalaran icon used
local variousItemsIcon   = 134248 -- Key icon used

local engineringItemsCount = 0
local challengeSpellCount  = 0
local heartstoneItemsCount = 0

local challengeVanillaCount = 0
local challengeCataCount    = 0
local challengeMOPCount     = 0
local challengeWODCount     = 0
local challengeLegionCount  = 0
local challengeBFACount     = 0
local challengeSLCount      = 0
local challengeDFCount      = 0
local challengeTWWCount     = 0

local challengeCategories = {}

local databaseLoaded = false
local category = nil

local methods = {}

-- forward declaration: assigned inside CreateSettingsPanel, used by GET_ITEM_INFO_RECEIVED
local RefreshCustomList

local addonName, addonTable = ...
local L = addonTable.L

-- IDs of items usable for transportation
local items = {
    -- Dalaran rings
    40585, -- Signet of the Kirin Tor
    40586, -- Band of the Kirin Tor
    44934, -- Loop of the Kirin Tor
    44935, -- Ring of the Kirin Tor
    45688, -- Inscribed Band of the Kirin Tor
    45689, -- Inscribed Loop of the Kirin Tor
    45690, -- Inscribed Ring of the Kirin Tor
    45691, -- Inscribed Signet of the Kirin Tor
    48954, -- Etched Band of the Kirin Tor
    48955, -- Etched Loop of the Kirin Tor
    48956, -- Etched Ring of the Kirin Tor
    48957, -- Etched Signet of the Kirin Tor
    51557, -- Runed Signet of the Kirin Tor
    51558, -- Runed Loop of the Kirin Tor
    51559, -- Runed Ring of the Kirin Tor
    51560, -- Runed Band of the Kirin Tor
    139599, -- Empowered Ring of the Kirin Tor
    -- Seasonal items
    21711, -- Lunar Festival Invitation
    37863, -- Direbrew's Remote
    -- Miscellaneous
    17690, -- Frostwolf Insignia Rank 1 (Horde)
    17691, -- Stormpike Insignia Rank 1 (Alliance)
    17900, -- Stormpike Insignia Rank 2 (Alliance)
    17901, -- Stormpike Insignia Rank 3 (Alliance)
    17902, -- Stormpike Insignia Rank 4 (Alliance)
    17903, -- Stormpike Insignia Rank 5 (Alliance)
    17904, -- Stormpike Insignia Rank 6 (Alliance)
    17905, -- Frostwolf Insignia Rank 2 (Horde)
    17906, -- Frostwolf Insignia Rank 3 (Horde)
    17907, -- Frostwolf Insignia Rank 4 (Horde)
    17908, -- Frostwolf Insignia Rank 5 (Horde)
    17909, -- Frostwolf Insignia Rank 6 (Horde)
    22631, -- Atiesh, Greatstaff of the Guardian
    32757, -- Blessed Medallion of Karabor
    35230, -- Darnarian's Scroll of Teleportation
    43824, -- The Schools of Arcane Magic - Mastery
    46874, -- Argent Crusader's Tabard
    50287, -- Boots of the Bay
    52251, -- Jaina's Locket
    58487, -- Potion of Deepholm
    61379, -- Gidwin's Hearthstone
    63206, -- Wrap of Unity (Alliance)
    63207, -- Wrap of Unity (Horde)
    63352, -- Shroud of Cooperation (Alliance)
    63353, -- Shroud of Cooperation (Horde)
    63378, -- Hellscream's Reach Tabard
    63379, -- Baradin's Wardens Tabard
    64457, -- The Last Relic of Argus
    65274, -- Cloak of Coordination (Horde)
    65360, -- Cloak of Coordination (Alliance)
    95050, -- The Brassiest Knuckle (Horde)
    95051, -- The Brassiest Knuckle (Alliance)
    95567, -- Kirin Tor Beacon
    95568, -- Sunreaver Beacon
    87548, -- Lorewalker's Lodestone
    103678, -- Time-Lost Artifact
    110560, -- Garrison Hearthstone
    118662, -- Bladespire Relic
    118663, -- Relic of Karabor
    118907, -- Pit Fighter's Punching Ring
    128353, -- Admiral's Compass
    128502, -- Hunter's Seeking Crystal
    128503, -- Master Hunter's Seeking Crystal
    136849, -- Nature's Beacon
    139590, -- Scroll of Teleport: Ravenholdt
    140192, -- Dalaran Hearthstone
    140324, -- Mobile Telemancy Beacon
    142469, -- Violet Seal of the Grand Magus
    144391, -- Pugilist's Powerful Punching Ring (Alliance)
    144392, -- Pugilist's Powerful Punching Ring (Horde)
    151016, -- Fractured Necrolyte Skull
    166559, -- Commander's Signet of Battle
    202046, -- Lucky Tortollan Charm
    230850, -- Delve-O-Bot 7001
    248131, -- Key to the Arcantina
}

local heartstones = {
    -- items usable instead of hearthstone
    28585, -- Ruby Slippers
    37118, -- Scroll of Recall
    44314, -- Scroll of Recall II
    44315, -- Scroll of Recall III
    37118, -- Scroll of Recall
    44314, -- Scroll of Recall II
    44315, -- Scroll of Recall III
    54452, -- Ethereal Portal
    64488, -- The Innkeeper's Daughter
    93672, -- Dark Portal (Retail version)
    142298, -- Astonishingly Scarlet Slippers
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    180290, -- Night Fae Hearthstone
    182773, -- Necrolord Heartstone
    183716, -- Venthyr Sinstone
    184353, -- Kyrian Hearthstone
    184871, -- Dark Portal
    188952, -- Dominated Hearthstone
    190196, -- Enlightened Hearthstone
    190237, -- Broker Translocation Matrix
    193588, -- Timewalker's Hearthstone
    206195, -- Path of the Naaru
    200630, -- Ohn'ir Windsage's Hearthstone
    208704, -- Deepdweller's Earthen Hearthstone
    209035, -- Hearthstone of the Flame
    210455, -- Draenic Hologem
    212337, -- Stone of the Hearth
    228940, -- Notorious Thread's Hearthstone
    235016, -- Redeployment Module
    236687, -- Explosive Hearthstone
    243056, -- Delver's Mana-Bound Ethergate
    245970, -- P.O.S.T. Master's Express Hearthstone
    246565, -- Costmic Hearthstone
    260221  -- Naaru's Embrace (TBC Anniversary toy)
}

local engineeringItems = {
    -- Engineering Gadgets
    18984, -- Dimensional Ripper - Everlook
    18986, -- Ultrasafe Transporter: Gadgetzan
    30542, -- Dimensional Ripper - Area 52
    30544, -- Ultrasafe Transporter: Toshley's Station
    48933, -- Wormhole Generator: Northrend
    87215, -- Wormhole Generator: Pandaria
    112059, -- Wormhole Centrifuge
    151652, -- Wormhole Generator: Argus
    168807, -- Wormhole Generator: Kul Tiras
    168808, -- Wormhole Generator: Zandalar
    172924, -- Wormhole Generator: Shadowlands
    198156, -- Wormhole Generator: Dragon Isles
    221966, -- Wormhole GeneratorL Khaz Algar
    132523, -- Reaves Battery, unfortunately we can't check for Wormhole Generator module
    144341, -- Rechargeable Reaves Battery, same as with Reaves Battery
    248485, -- Wormhole Generator: Quel'Thalas
}

local scrolls = {
    6948 -- Hearthstone
}


local challengeVanillaSpells = {
    {159902, 'TRUE'}, -- Path of the Burning Mountain
    {373262, 'TRUE'}, -- Path of the Fallen Guardian
    {131232, 'TRUE'}, -- Path of the Necromancer
    {131231, 'TRUE'}, -- Path of the Scarlet Blade
    {131229, 'TRUE'}, -- Path of the Scarlet Mitre
    {393222, 'TRUE'}, -- Path of the Watcher's Legacy
}

local challengeCataSpells = {
    {424142, 'TRUE'}, -- Path of the Tidehunter
    {445424, 'TRUE'}, -- Path of the Twilight Fortress
    {410080, 'TRUE'}, -- Path of the Wind's Domain
}

local challengeMOPSpells = {
    {131228, 'TRUE'}, -- Path of the Black Ox
    {131204, 'TRUE'}, -- Path of the Jade Serpent
    {131222, 'TRUE'}, -- Path of the Mogu King
    {131225, 'TRUE'}, -- Path of the Setting Sun
    {131206, 'TRUE'}, -- Path of the Shado-Pan
    {131205, 'TRUE'}, -- Path of the Stout Brew
}

local challengeWODSpells = {
    {159895, 'TRUE'}, -- Path of the Bloodmaul
    {159899, 'TRUE'}, -- Path of the Crescent Moon
    {159900, 'TRUE'}, -- Path of the Dark Rail
    {159896, 'TRUE'}, -- Path of the Iron Prow
    {159898, 'TRUE'}, -- Path of the Skies
    {159901, 'TRUE'}, -- Path of the Verdant
    {159897, 'TRUE'}, -- Path of the Vigilant
}

local challengeLegionSpells = {
    {424153, 'TRUE'}, -- Path of the Ancient Horrors
    {410078, 'TRUE'}, -- Path of the Earth-Warder
    {393766, 'TRUE'}, -- Path of the Grand Magistrix
    {424163, 'TRUE'}, -- Path of the Nightmare Lord
    {393764, 'TRUE'}, -- Path of the Proven Worth
}

local challengeBFASpells = {
    {467553, 'TRUE'}, -- Path of the Azerite Refinery (Alliance entrance)
    {467555, 'TRUE'}, -- Path of the Azerite Refinery (Horde entrance)
    {410074, 'TRUE'}, -- Path of the Festering Rot
    {410071, 'TRUE'}, -- Path of the Freebooter
    {424187, 'TRUE'}, -- Path of the Golden Tomb
    {424167, 'TRUE'}, -- Path of the Heart's Bane
    {373274, 'TRUE'}, -- Path of the Scrappy Prince
    {445418, 'TRUE'}, -- Path of the Siege of Boralus (Alliance)
    {464256, 'TRUE'}, -- Path of the Siege of Boralus (Horde)
}

local challengeSLSpells = {
    {354466, 'TRUE'}, -- Path of the Ascendant
    {354462, 'TRUE'}, -- Path of the Courageous
    {373192, 'TRUE'}, -- Path of the First Ones
    {354464, 'TRUE'}, -- Path of the Misty Forest
    {354463, 'TRUE'}, -- Path of the Plagued
    {354468, 'TRUE'}, -- Path of the Scheming Loa
    {354465, 'TRUE'}, -- Path of the Sinful Soul
    {373190, 'TRUE'}, -- Path of the Sire
    {354469, 'TRUE'}, -- Path of the Stone Warden
    {367416, 'TRUE'}, -- Path of the Streetwise Merchant
    {373191, 'TRUE'}, -- Path of the Tormented Soul
    {354467, 'TRUE'}, -- Path of the Undefeated
}

local challengeDFSpells = {
    {393279, 'TRUE'}, -- Path of the Arcane Secrets
    {432257, 'TRUE'}, -- Path of the Bitter Lagacy
    {393256, 'TRUE'}, -- Path of the Clutch Defender
    {393273, 'TRUE'}, -- Path of the Draconic Diploma
    {393276, 'TRUE'}, -- Path of the Obsidian Hoard
    {432254, 'TRUE'}, -- Path of the Primal Prison
    {393267, 'TRUE'}, -- Path of the Rotting Woods
    {432258, 'TRUE'}, -- Path of the Scorching Dream
    {393283, 'TRUE'}, -- Path of the Titanic Reservoir
    {424197, 'TRUE'}, -- Path of the Twisted Time
    {393262, 'TRUE'}, -- Path of the Windswept Plains
}

local challengeTWWSpells = {
    {445414, 'TRUE'},  -- Path of Arathi Flagship
    {445416, 'TRUE'},  -- Path of Nerubean Ascension
    {1239155, 'TRUE'}, -- Path of the All-Devouring
    {1216786, 'TRUE'}, -- Path of the Circuit Breaker
    {445416, 'TRUE'},  -- Path of the City of Threads
    {445269, 'TRUE'},  -- Path of the Corrupted Foundry
    {445414, 'TRUE'},  -- Path of the Dawnbreaker
    {1237215, 'TRUE'}, -- Path of the Eco-Dome
    {445443, 'TRUE'},  -- Path of the Fallen Stormriders
    {445440, 'TRUE'},  -- Path of the Flaming Brewery
    {1226482, 'TRUE'}, -- Path of the Full House
    {445444, 'TRUE'},  -- Path of the Light's Reverence
    {445417, 'TRUE'},  -- Path of the Ruined City
    {445441, 'TRUE'},  -- Path of the Warding Candles
    {467546, 'TRUE'},  -- Path of the Waterworks
    {445424, 'TRUE'},  -- Path of Twilight Fortress
}

local challengeMidnightSpells = {
    {1254559, 'TRUE'}, -- Path of Cavernous Depths
    {1254551, 'TRUE'}, -- Path of Dark Dereliction
    {1254572, 'TRUE'}, -- Path of Devoted Magistry
    {1254555, 'TRUE'}, -- Path of Unyielding Blight
    {1254557, 'TRUE'}, -- Path of the Crowning Pinnacle
    {1254563, 'TRUE'}, -- Path of the Fractured Core
    {1254400, 'TRUE'}, -- Path of the Windrunners
}

-- Gold Challenge portals
local challengeSpells = {
    -- DH Classic
    {159902, 'TRUE'}, -- Path of the Burning Mountain
    {373262, 'TRUE'}, -- Path of the Fallen Guardian
    {131232, 'TRUE'}, -- Path of the Necromancer
    {131231, 'TRUE'}, -- Path of the Scarlet Blade
    {131229, 'TRUE'}, -- Path of the Scarlet Mitre
    {393222, 'TRUE'}, -- Path of the Watcher's Legacy
    -- DH BC
    -- DH Cata
    {445424, 'TRUE'}, -- Path of the Twilight Fortress
    {424142, 'TRUE'}, -- Path of the Tidehunter
    {410080, 'TRUE'}, -- Path of the Wind's Domain
    -- DH MOP
    {131228, 'TRUE'}, -- Path of the Black Ox
    {131204, 'TRUE'}, -- Path of the Jade Serpent
    {131222, 'TRUE'}, -- Path of the Mogu King
    {131225, 'TRUE'}, -- Path of the Setting Sun
    {131206, 'TRUE'}, -- Path of the Shado-Pan
    {131205, 'TRUE'}, -- Path of the Stout Brew
    -- DH WOD
    {159895, 'TRUE'}, -- Path of the Bloodmaul
    {159899, 'TRUE'}, -- Path of the Crescent Moon
    {159900, 'TRUE'}, -- Path of the Dark Rail
    {159896, 'TRUE'}, -- Path of the Iron Prow
    {159898, 'TRUE'}, -- Path of the Skies
    {159901, 'TRUE'}, -- Path of the Verdant
    {159897, 'TRUE'}, -- Path of the Vigilant
    -- DH Legion
    {424153, 'TRUE'}, -- Path of the Ancient Horrors
    {410078, 'TRUE'}, -- Path of the Earth-Warder
    {393766, 'TRUE'}, -- Path of the Grand Magistrix
    {424163, 'TRUE'}, -- Path of the Nightmare Lord
    {393764, 'TRUE'}, -- Path of the Proven Worth
    -- DH BFA
    {467553, 'TRUE'}, -- Path of the Azerite Refinery (Alliance entrance)
    {467555, 'TRUE'}, -- Path of the Azerite Refinery (Horde entrance)
    {410074, 'TRUE'}, -- Path of the Festering Rot
    {410071, 'TRUE'}, -- Path of the Freebooter
    {424187, 'TRUE'}, -- Path of the Golden Tomb
    {424167, 'TRUE'}, -- Path of the Heart's Bane
    {373274, 'TRUE'}, -- Path of the Scrappy Prince
    {445418, 'TRUE'}, -- Path of the Siege of Boralus (Alliance)
    {464256, 'TRUE'}, -- Path of the Siege of Boralus (Horde)
    -- DH SL
    {354466, 'TRUE'}, -- Path of the Ascendant
    {354462, 'TRUE'}, -- Path of the Courageous
    {373192, 'TRUE'}, -- Path of the First Ones
    {354464, 'TRUE'}, -- Path of the Misty Forest
    {354463, 'TRUE'}, -- Path of the Plagued
    {354468, 'TRUE'}, -- Path of the Scheming Loa
    {354465, 'TRUE'}, -- Path of the Sinful Soul
    {373190, 'TRUE'}, -- Path of the Sire
    {354469, 'TRUE'}, -- Path of the Stone Warden
    {367416, 'TRUE'}, -- Path of the Streetwise Merchant
    {373191, 'TRUE'}, -- Path of the Tormented Soul
    {354467, 'TRUE'}, -- Path of the Undefeated
    -- DH DF
    {393279, 'TRUE'}, -- Path of the Arcane Secrets
    {432257, 'TRUE'}, -- Path of the Bitter Lagacy
    {393256, 'TRUE'}, -- Path of the Clutch Defender
    {393273, 'TRUE'}, -- Path of the Draconic Diploma
    {393276, 'TRUE'}, -- Path of the Obsidian Hoard
    {432254, 'TRUE'}, -- Path of the Primal Prison
    {393267, 'TRUE'}, -- Path of the Rotting Woods
    {432258, 'TRUE'}, -- Path of the Scorching Dream
    {393283, 'TRUE'}, -- Path of the Titanic Reservoir
    {424197, 'TRUE'}, -- Path of the Twisted Time
    {393262, 'TRUE'}, -- Path of the Windswept Plains
    -- DH TWW
    {445414, 'TRUE'},  -- Path of Arathi Flagship
    {445416, 'TRUE'},  -- Path of Nerubean Ascension
    {445417, 'TRUE'},  -- Path of the Ruined City
    {1239155, 'TRUE'}, -- Path of the All-Devouring
    {1216786, 'TRUE'}, -- Path of the Circuit Breaker
    {445416, 'TRUE'},  -- Path of the City of Threads
    {445269, 'TRUE'},  -- Path of the Corrupted Foundry
    {445414, 'TRUE'},  -- Path of the Dawnbreaker
    {1237215, 'TRUE'}, -- Path of the Eco-Dome
    {445443, 'TRUE'},  -- Path of the Fallen Stormriders
    {445440, 'TRUE'},  -- Path of the Flaming Brewery
    {1226482, 'TRUE'}, -- Path of the Full House
    {445444, 'TRUE'},  -- Path of the Light's Reverence
    {445441, 'TRUE'},  -- Path of the Warding Candles
    {467546, 'TRUE'},  -- Path of the Waterworks
    {445424, 'TRUE'},  -- Path of Twilight Fortress
    -- DH Midnight
    {1254559, 'TRUE'}, -- Path of Cavernous Depths
    {1254551, 'TRUE'}, -- Path of Dark Dereliction
    {1254572, 'TRUE'}, -- Path of Devoted Magistry
    {1254555, 'TRUE'}, -- Path of Unyielding Blight
    {1254557, 'TRUE'}, -- Path of the Crowning Pinnacle
    {1254563, 'TRUE'}, -- Path of the Fractured Core
    {1254400, 'TRUE'}, -- Path of the Windrunners
}

-- Per-expansion challenge teleport definitions.
-- Used both for menu generation and for the per-expansion enable/disable options.
local challengeExpansions = {
    {key = "Vanilla",  spells = challengeVanillaSpells,  category = "challengesVanilla",  name = "CHALLENGE_TP_VANILLA"},
    {key = "Cata",     spells = challengeCataSpells,     category = "challengesCata",     name = "CHALLENGE_TP_CATA"},
    {key = "MOP",      spells = challengeMOPSpells,      category = "challengesMOP",      name = "CHALLENGE_TP_MOP"},
    {key = "WOD",      spells = challengeWODSpells,      category = "challengesWOD",      name = "CHALLENGE_TP_WOD"},
    {key = "Legion",   spells = challengeLegionSpells,   category = "challengesLegion",   name = "CHALLENGE_TP_LEGION"},
    {key = "BFA",      spells = challengeBFASpells,      category = "challengesBFA",      name = "CHALLENGE_TP_BFA"},
    {key = "SL",       spells = challengeSLSpells,       category = "challengesSL",       name = "CHALLENGE_TP_SL"},
    {key = "DF",       spells = challengeDFSpells,       category = "challengesDF",       name = "CHALLENGE_TP_DF"},
    {key = "TWW",      spells = challengeTWWSpells,      category = "challengesTWW",      name = "CHALLENGE_TP_TWW"},
    {key = "Midnight", spells = challengeMidnightSpells, category = "challengesMidnight", name = "CHALLENGE_TP_MIDNIGHT"},
}

local whistle = {
    141605, -- Flight Master's Whistle
    168862 -- G.E.A.R. Tracking Beacon
}

-- Housing teleport is NOT a castable spell: C_Housing.TeleportHome is protected
-- (AllowedWhenUntainted) and driven by a secure button with type="teleporthome".
-- The list of owned houses is delivered asynchronously via PLAYER_HOUSE_LIST_UPDATED
-- after calling C_Housing.GetPlayerOwnedHouses() (which itself returns nothing).
-- Each HouseInfo has: plotID, houseName, ownerName, neighborhoodName, neighborhoodGUID, houseGUID.
local housingHouses = {} -- array of {neighborhoodGUID, houseGUID, plotID, name}
local housingIcon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(1233637)) or 237509

local function RequestHousingInfo()
    -- Second line of defence: housing only exists on mainline. C_Housing is
    -- present in the shared 12.0 UI on every flavor, so its existence proves
    -- nothing - the query still has to reach a server that implements housing.
    if not isRetail then
        return
    end
    if C_Housing and C_Housing.GetPlayerOwnedHouses then
        C_Housing.GetPlayerOwnedHouses()
    end
end

-- Stale houseGUID auto-retry: a house's GUID can change server-side, so a teleport
-- may fail with a housing error. We cycle the trailing digit of the GUID so the next
-- click (after reopening the menu) uses a corrected one, and lock it briefly so an
-- async server refresh does not immediately clobber the correction.
local lastHouseAttempt = nil     -- {key = "<nGUID>:<plotID>", time = GetTime()}
local HOUSE_RETRY_WINDOW = 1.5   -- seconds to associate a UI error with the last click
local HOUSE_GUID_LOCK = 10       -- seconds a cycled GUID survives server refreshes
local staleHouseErrors = {}      -- set of localized error strings, filled at login

local function BuildStaleHouseErrorSet()
    local keys = {
        "ERR_HOUSING_RESULT_PERMISSION_DENIED",
        "ERR_HOUSING_RESULT_HOUSE_NOT_FOUND",
        "ERR_HOUSING_RESULT_INVALID_HOUSE",
    }
    for _, key in ipairs(keys) do
        if _G[key] then staleHouseErrors[_G[key]] = true end
    end
end

-- houseGUID ends in a digit; cycle it 1->2->...->9->1
local function IncrementHouseGUID(guid)
    if not guid then return nil end
    local prefix, num = tostring(guid):match("^(.+-)(%d+)$")
    if prefix and num then
        return prefix .. ((tonumber(num) % 9) + 1)
    end
    return nil
end

local obj = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {type = 'data source', text = L['P'], icon = 'Interface\\Icons\\INV_Misc_Rune_06'})
local portals
local frame = CreateFrame('frame')

local function CreateCheckbox(checkboxText, key, checkboxTooltip)
    local checkbox = CreateFrame("CheckButton", "BPCheckboxID" .. checkboxes, settingsFrame, "UICheckButtonTemplate")
    checkbox.Text:SetText(checkboxText)
    checkbox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 10, -30 + (checkboxes * -30))
end

frame:SetScript('OnEvent', function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
frame:RegisterEvent('PLAYER_LOGIN')

-- Helper function to extract item ID from item link
local function GetItemIDFromLink(itemlink)
    return tonumber(tostring(itemlink):match("item:(%d+)"))
end

local function BPToggleMinimap()
    local hide = not PortalsDB.minimap.hide
    PortalsDB.minimap.hide = hide
    if hide then
        icon:Hide('Broker_Portals')
    else
        icon:Show('Broker_Portals')
    end
end

-- File-scope so CreateSettingsPanel, the category registration and the
-- custom-list refresh all see the same frame; it used to live in _G under the
-- very collidable name "OptionsFrame".
local OptionsFrame

local function CreateSettingsPanel()
    if Settings then
        OptionsFrame = CreateFrame("Frame", "BrokerPortalsOptionsFrame", UIParent)
        OptionsFrame.name = "Broker Portals"

        -- The panel has grown beyond a single screen, so everything lives inside a
        -- scroll frame. All controls are parented to `content`.
        local scrollFrame = CreateFrame("ScrollFrame", "BPOptionsScrollFrame", OptionsFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 3, -3)
        scrollFrame:SetPoint("BOTTOMRIGHT", -27, 3)

        local content = CreateFrame("Frame", "BPOptionsScrollChild", scrollFrame)
        content:SetSize(600, 700)
        scrollFrame:SetScrollChild(content)

        local function AddCheckbox(name, x, y, label, tooltip, checked, onClick)
            local cb = CreateFrame("CheckButton", name, content, "InterfaceOptionsCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", x, y)
            cb.Text:SetText(label)
            cb.tooltipText = tooltip
            cb:SetChecked(checked)
            cb:SetScript("OnClick", onClick)
            return cb
        end

        local function AddHeader(x, y, text)
            local fs = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            fs:SetPoint("TOPLEFT", x, y)
            fs:SetText(text)
            return fs
        end

        local showItemsSubCatCheckBox, showEngineeringSubCatCheckBox, showHSItemsSubCatCheckBox

        local showItemsCheckBox = AddCheckbox("ShowItemsCheckBox", 16, -16, L["SHOW_ITEMS"], L["SHOW_ITEMS_TOOLTIP"], PortalsDB.showItems, function(self)
            PortalsDB.showItems = not PortalsDB.showItems
            showItemsSubCatCheckBox:SetEnabled(PortalsDB.showItems)
            showEngineeringSubCatCheckBox:SetEnabled(PortalsDB.showItems)
        end)

        showItemsSubCatCheckBox = AddCheckbox("showItemsSubCatCheckBox", 320, -16, L["SHOW_ITEMS_SUBCAT"], L["SHOW_ITEMS_SUBCAT_TOOLTIP"], PortalsDB.showItemsSubCat, function(self)
            PortalsDB.showItemsSubCat = not PortalsDB.showItemsSubCat
        end)

        local showHSItemsCheckBox = AddCheckbox("showHSItemsCheckBox", 16, -64, L["SHOW_HS_ITEMS"], L["SHOW_HS_ITEMS_TOOLTIP"], PortalsDB.showHSItems, function(self)
            PortalsDB.showHSItems = not PortalsDB.showHSItems
            showHSItemsSubCatCheckBox:SetEnabled(PortalsDB.showHSItems)
        end)

        showHSItemsSubCatCheckBox = AddCheckbox("showHSItemsSubCatCheckBox", 320, -64, L["SHOW_HS_ITEMS_SUBCAT"], L["SHOW_HS_ITEMS_SUBCAT_TOOLTIP"], PortalsDB.showHSItemsSubCat, function(self)
            PortalsDB.showHSItemsSubCat = not PortalsDB.showHSItemsSubCat
        end)

        showEngineeringSubCatCheckBox = AddCheckbox("showEngineeringSubCatCheckBox", 16, -110, L["SHOW_ENGINEERING_SUBCAT"], L["SHOW_ENGINEERING_SUBCAT_TOOLTIP"], PortalsDB.showEngineeringSubCat, function(self)
            PortalsDB.showEngineeringSubCat = not PortalsDB.showEngineeringSubCat
        end)

        AddCheckbox("showTeleportsSubCatCheckBox", 320, -110, L["SHOW_TELEPORTS_SUBCAT"], L["SHOW_TELEPORTS_SUBCAT_TOOLTIP"], PortalsDB.showTeleportsSubCat, function(self)
            PortalsDB.showTeleportsSubCat = not PortalsDB.showTeleportsSubCat
        end)

        AddCheckbox("showMinimapButtonCheckBox", 16, -158, L['ATT_MINIMAP'], L['ATT_MINIMAP'], not PortalsDB.minimap.hide, function(self) BPToggleMinimap() end)

        AddCheckbox("announceCheckBox", 320, -158, L["ANNOUNCE"], L["ANNOUNCE_TOOLTIP"], PortalsDB.announce, function(self)
            PortalsDB.announce = not PortalsDB.announce
        end)

        local fontSizeSlider = CreateFrame("Slider", "fontSizeSlider", content, "OptionsSliderTemplate")
        fontSizeSlider:SetPoint("TOPLEFT", 16, -206)
        fontSizeSlider.Text:SetText(L['DROPDOWN_FONT_SIZE'] .. PortalsDB.fontSize)
        fontSizeSlider.tooltipText = L['DROPDOWN_FONT_SIZE']
        fontSizeSlider:SetMinMaxValues(8, 32)
        fontSizeSlider.Low:SetText(8)
        fontSizeSlider.High:SetText(32)
        fontSizeSlider:SetValueStep(1)
        fontSizeSlider:SetScript('OnShow', function(self) self:SetValue(PortalsDB.fontSize) end)
        fontSizeSlider:SetScript('OnValueChanged', function(self, value)
            PortalsDB.fontSize = floor(tonumber(value))
            self.Text:SetText(L['DROPDOWN_FONT_SIZE'] .. PortalsDB.fontSize)
        end)

        local scrollSizeSlider = CreateFrame("Slider", "scrollSizeSlider", content, "OptionsSliderTemplate")
        scrollSizeSlider:SetPoint("TOPLEFT", 320, -206)
        scrollSizeSlider.Text:SetText(L['SCROLL_LIST_SIZE'] .. PortalsDB.scrollListSize)
        scrollSizeSlider.tooltipText = L['SCROLL_LIST_SIZE']
        scrollSizeSlider:SetMinMaxValues(30, 60)
        scrollSizeSlider.Low:SetText(30)
        scrollSizeSlider.High:SetText(60)
        scrollSizeSlider:SetValueStep(1)
        scrollSizeSlider:SetScript('OnShow', function(self) self:SetValue(PortalsDB.scrollListSize) end)
        scrollSizeSlider:SetScript('OnValueChanged', function(self, value)
            PortalsDB.scrollListSize = floor(tonumber(value))
            self.Text:SetText(L['SCROLL_LIST_SIZE'] .. PortalsDB.scrollListSize)
        end)

        AddCheckbox("showItemsCooldownCheckBox", 16, -254, L["SHOW_ITEM_COOLDOWNS"], L["SHOW_ITEM_COOLDOWNS_TOOLTIP"], PortalsDB.showItemCooldowns, function(self)
            PortalsDB.showItemCooldowns = not PortalsDB.showItemCooldowns
        end)

        AddCheckbox("sortItemsAlphabeticalyCheckBox", 320, -254, L["SORT_ITEMS"], L["SORT_ITEMS_TOOLTIP"], PortalsDB.sortItems, function(self)
            PortalsDB.sortItems = not PortalsDB.sortItems
        end)

        if challengeAvailable then
            local showChallengeSubCatCheckBox
            local expansionChecks = {}

            local function updateChallengeChildren()
                local enabled = PortalsDB.showChallengeTeleports
                showChallengeSubCatCheckBox:SetEnabled(enabled)
                for _, cb in ipairs(expansionChecks) do cb:SetEnabled(enabled) end
            end

            local showChallengeTeleportsCheckBox = AddCheckbox("showChallengeTeleportsCheckBox", 16, -302, L["SHOW_CHALLENGE_TELEPORTS"], L["SHOW_CHALLENGE_TELEPORTS_TOOLTIP"], PortalsDB.showChallengeTeleports, function(self)
                PortalsDB.showChallengeTeleports = not PortalsDB.showChallengeTeleports
                updateChallengeChildren()
            end)

            showChallengeSubCatCheckBox = AddCheckbox("showChallengeSubCatCheckBox", 320, -302, L["SHOW_CHALLENGE_TELEPORTS_SUBCAT"], L["SHOW_CHALLENGE_TELEPORTS_SUBCAT_TOOLTIP"], PortalsDB.showChallengeSubCat, function(self)
                PortalsDB.showChallengeSubCat = not PortalsDB.showChallengeSubCat
            end)

            -- Per-expansion enable/disable checkboxes
            AddHeader(16, -348, L["CHALLENGE_EXPANSIONS_HEADER"])
            for i, exp in ipairs(challengeExpansions) do
                local column = (i % 2 == 1) and 16 or 320
                local rowY = -376 - (math.floor((i - 1) / 2) * 30)
                local cb = AddCheckbox("BPChallengeExp" .. exp.key, column, rowY, L[exp.name], nil, PortalsDB.challengeExpansions[exp.key] ~= false, function(self)
                    PortalsDB.challengeExpansions[exp.key] = self:GetChecked() and true or false
                end)
                expansionChecks[#expansionChecks + 1] = cb
            end

            updateChallengeChildren()
        end

        -- ==================== Custom items / spells ====================
        AddHeader(16, -540, L["CUSTOM_HEADER"])

        local hint = content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        hint:SetPoint("TOPLEFT", 16, -562)
        hint:SetText(L["CUSTOM_HINT"])

        local newType = "item"
        local typeButton = CreateFrame("Button", "BPCustomTypeButton", content, "UIPanelButtonTemplate")
        typeButton:SetSize(80, 22)
        typeButton:SetText(L["CUSTOM_TYPE_ITEM"])
        typeButton:SetPoint("TOPLEFT", 16, -584)
        typeButton:SetScript("OnClick", function(self)
            if newType == "item" then
                newType = "spell"
                self:SetText(L["CUSTOM_TYPE_SPELL"])
            else
                newType = "item"
                self:SetText(L["CUSTOM_TYPE_ITEM"])
            end
        end)

        local idBox = CreateFrame("EditBox", "BPCustomIdBox", content, "InputBoxTemplate")
        idBox:SetSize(90, 22)
        idBox:SetAutoFocus(false)
        idBox:SetNumeric(true)
        idBox:SetPoint("TOPLEFT", 110, -584)

        local addButton = CreateFrame("Button", "BPCustomAddButton", content, "UIPanelButtonTemplate")
        addButton:SetSize(80, 22)
        addButton:SetText(L["CUSTOM_ADD"])
        addButton:SetPoint("TOPLEFT", 210, -584)

        local function DoAdd()
            local id = tonumber(idBox:GetText())
            if not id or id <= 0 then return end
            local arr = (newType == "item") and PortalsDB.customItems or PortalsDB.customSpells
            for i = 1, #arr do
                if arr[i] == id then idBox:SetText(""); return end -- already present
            end
            arr[#arr + 1] = id
            if newType == "item" and C_Item and C_Item.RequestLoadItemDataByID then
                C_Item.RequestLoadItemDataByID(id)
            end
            idBox:SetText("")
            RefreshCustomList()
        end
        addButton:SetScript("OnClick", DoAdd)
        idBox:SetScript("OnEnterPressed", function(self) DoAdd() self:ClearFocus() end)

        -- Rebuildable list of existing custom entries (assigned to the file-scope upvalue)
        local rowPool = {}
        local listStartY = -618
        RefreshCustomList = function()
            for _, r in ipairs(rowPool) do r:Hide() end

            local idx = 0
            local function buildRows(arr, entryType)
                for arrIndex = 1, #arr do
                    idx = idx + 1
                    local row = rowPool[idx]
                    if not row then
                        row = CreateFrame("Frame", nil, content)
                        row:SetSize(520, 24)
                        row.label = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                        row.label:SetPoint("LEFT", 0, 0)
                        row.label:SetWidth(46)
                        row.label:SetJustifyH("LEFT")

                        row.idBox = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                        row.idBox:SetSize(80, 20)
                        row.idBox:SetAutoFocus(false)
                        row.idBox:SetNumeric(true)
                        row.idBox:SetPoint("LEFT", 50, 0)

                        row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
                        row.name:SetPoint("LEFT", 145, 0)
                        row.name:SetWidth(320)
                        row.name:SetJustifyH("LEFT")

                        row.remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
                        row.remove:SetSize(24, 24)
                        row.remove:SetPoint("RIGHT", 0, 0)

                        row.idBox:SetScript("OnEnterPressed", function(self)
                            local newId = tonumber(self:GetText())
                            if newId and newId > 0 then
                                row.arr[row.arrIndex] = newId
                                if row.entryType == "item" and C_Item and C_Item.RequestLoadItemDataByID then
                                    C_Item.RequestLoadItemDataByID(newId)
                                end
                            end
                            self:ClearFocus()
                            RefreshCustomList()
                        end)
                        row.remove:SetScript("OnClick", function()
                            table.remove(row.arr, row.arrIndex)
                            RefreshCustomList()
                        end)
                        rowPool[idx] = row
                    end

                    row.arr = arr
                    row.arrIndex = arrIndex
                    row.entryType = entryType
                    row.label:SetText(entryType == "item" and L["CUSTOM_TYPE_ITEM"] or L["CUSTOM_TYPE_SPELL"])
                    row.idBox:SetText(tostring(arr[arrIndex]))

                    local resolvedName
                    if entryType == "item" then
                        resolvedName = GetItemInfo(arr[arrIndex])
                    else
                        resolvedName = GetSpellInfo(arr[arrIndex])
                        if type(resolvedName) == "table" then resolvedName = resolvedName.name end
                    end
                    row.name:SetText(resolvedName or "...")

                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", 16, listStartY - (idx - 1) * 26)
                    row:Show()
                end
            end

            buildRows(PortalsDB.customItems, "item")
            buildRows(PortalsDB.customSpells, "spell")

            content:SetHeight(math.max(700, -listStartY + idx * 26 + 40))
        end
        RefreshCustomList()

        category = Settings.RegisterCanvasLayoutCategory(OptionsFrame, OptionsFrame.name)
        Settings.RegisterAddOnCategory(category)
    end
end

local function pairsByKeys(t, sortTable)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    if sortTable then table.sort(a) end

    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

local function tconcat(t1, t2)
    for i = 1, #t2 do t1[#t1 + 1] = t2[i] end
    return t1
end

-- Ask the client to cache item/toy data ahead of time so that the very first
-- menu build already has names/icons available (otherwise toys and items only
-- appear on the second open, once GetItemInfo has resolved asynchronously).
local function PreloadItemData()
    if not (C_Item and C_Item.RequestLoadItemDataByID) then return end
    local function req(list)
        for i = 1, #list do
            local id = type(list[i]) == "table" and list[i][1] or list[i]
            if id then C_Item.RequestLoadItemDataByID(id) end
        end
    end
    req(items)
    req(engineeringItems)
    req(heartstones)
    req(scrolls)
    req(whistle)
    if PortalsDB and PortalsDB.customItems then req(PortalsDB.customItems) end
end

-- returns true, if player has item with given ID in inventory or bags and it's not on cooldown
local function hasItem(itemID)
    local item, found, id

    -- scan inventory
    for slotId = 1, 19 do
        item = GetInventoryItemLink('player', slotId)
        if item then
            local id = GetItemIDFromLink(item)
            if id and tonumber(id) == itemID then
                local inventoryCooldown = GetInventoryItemCooldown('player', slotId)
                -- Handle secret values in combat (WoW 12.0.0+)
                if issecretvalue and issecretvalue(inventoryCooldown) then
                    return true, "item" -- Assume ready when secret
                elseif inventoryCooldown ~= 0 then
                    return false
                else
                    return true, "item"
                end
            end
        end
    end

    -- check Toybox
    if not isTBCClassic and not isClassicEra then
        if PlayerHasToy(itemID) and C_ToyBox.IsToyUsable(itemID) then
            local startTime, duration, cooldown
            startTime, duration = GetItemCooldown(itemID)
            -- Handle secret values in combat (WoW 12.0.0+)
            if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
                return true, "toy" -- Assume ready when secret
            end
            cooldown = duration - (GetTime() - startTime)
            if cooldown > 0 then
                return false
            else
                return true, "toy"
            end
        end
    end

    -- scan bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            item = GetContainerItemLink(bag, slot)
            if item then
                local id = GetItemIDFromLink(item)
                if id and tonumber(id) == itemID then
                    local containerCooldown = GetContainerItemCooldown(bag, slot)
                    -- Handle secret values in combat (WoW 12.0.0+)
                    if issecretvalue and issecretvalue(containerCooldown) then
                        return true, "item" -- Assume ready when secret
                    elseif containerCooldown ~= 0 then
                        return false
                    else
                        return true, "item"
                    end
                end
            end
        end
    end
    return false
end

local function getReagentCount(name)
    local count = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local item = GetContainerItemLink(bag, slot)
            if item then
                if item:find(name) then
                    local itemInfo = GetContainerItemInfo(bag, slot)
                    count = count + itemInfo.stackCount
                end
            end
        end
    end
    return count
end

local function SetupSpells()
    local spells = {
        Alliance = {
            {3561, 'TP_RUNE'}, -- TP:Stormwind
            {3562, 'TP_RUNE'}, -- TP:Ironforge
            {3565, 'TP_RUNE'}, -- TP:Darnassus
            {32271, 'TP_RUNE'}, -- TP:Exodar
            {49359, 'TP_RUNE'}, -- TP:Theramore
            {33690, 'TP_RUNE'}, -- TP:Shattrath
            {53140, 'TP_RUNE'}, -- TP:Dalaran
            {88342, 'TP_RUNE'}, -- TP:Tol Barad
            {132621, 'TP_RUNE'}, -- TP:Vale of Eternal Blossoms
            {120145, 'TP_RUNE'}, -- TP:Ancient Dalaran
            {176248, 'TP_RUNE'}, -- TP:StormShield
            {224869, 'TP_RUNE'}, -- TP:Dalaran - Broken Isles
            {193759, 'TP_RUNE'}, -- TP:Hall of the Guardian
            {281403, 'TP_RUNE'}, -- TP:Boralus
            {344587, 'TP_RUNE'}, -- TP:Oribos
            {395277, 'TP_RUNE'}, -- TP:Valdrakken
            {446540, 'TP_RUNE'}, -- TP:Dornogal
            {1259190, 'TP_RUNE'}, -- P:Silvermoon City
            {10059, 'P_RUNE'}, -- P:Stormwind
            {11416, 'P_RUNE'}, -- P:Ironforge
            {11419, 'P_RUNE'}, -- P:Darnassus
            {32266, 'P_RUNE'}, -- P:Exodar
            {49360, 'P_RUNE'}, -- P:Theramore
            {33691, 'P_RUNE'}, -- P:Shattrath
            {53142, 'P_RUNE'}, -- P:Dalaran
            {88345, 'P_RUNE'}, -- P:Tol Barad
            {120146, 'P_RUNE'}, -- P:Ancient Dalaran
            {132620, 'P_RUNE'}, -- P:Vale of Eternal Blossoms
            {176246, 'P_RUNE'}, -- P:StormShield
            {224871, 'P_RUNE'}, -- P:Dalaran - Broken Isles
            {281400, 'P_RUNE'}, -- P:Boralus
            {344597, 'P_RUNE'}, -- P:Oribos
            {395289, 'P_RUNE'}, -- P:Valdrakken
            {446534, 'P_RUNE'}, -- P:Dornogal
            {1259194, 'P_RUNE'}, -- P:Silvermoon City
        },
        Horde = {
            {3563, 'TP_RUNE'}, -- TP:Undercity
            {3566, 'TP_RUNE'}, -- TP:Thunder Bluff
            {3567, 'TP_RUNE'}, -- TP:Orgrimmar
            {32272, 'TP_RUNE'}, -- TP:Silvermoon
            {49358, 'TP_RUNE'}, -- TP:Stonard
            {35715, 'TP_RUNE'}, -- TP:Shattrath
            {53140, 'TP_RUNE'}, -- TP:Dalaran
            {88344, 'TP_RUNE'}, -- TP:Tol Barad
            {132627, 'TP_RUNE'}, -- TP:Vale of Eternal Blossoms
            {120145, 'TP_RUNE'}, -- TP:Ancient Dalaran
            {176242, 'TP_RUNE'}, -- TP:Warspear
            {224869, 'TP_RUNE'}, -- TP:Dalaran - Broken Isles
            {193759, 'TP_RUNE'}, -- TP:Hall of the Guardian
            {281404, 'TP_RUNE'}, -- TP:Dazar'alor
            {344587, 'TP_RUNE'}, -- TP:Oribos
            {395277, 'TP_RUNE'}, -- TP:Valdrakken
            {446540, 'TP_RUNE'}, -- TP:Dornogal
            {1259190, 'TP_RUNE'}, -- P:Silvermoon
            {11418, 'P_RUNE'}, -- P:Undercity
            {11420, 'P_RUNE'}, -- P:Thunder Bluff
            {11417, 'P_RUNE'}, -- P:Orgrimmar
            {32267, 'P_RUNE'}, -- P:Silvermoon
            {49361, 'P_RUNE'}, -- P:Stonard
            {35717, 'P_RUNE'}, -- P:Shattrath
            {53142, 'P_RUNE'}, -- P:Dalaran
            {88346, 'P_RUNE'}, -- P:Tol Barad
            {120146, 'P_RUNE'}, -- P:Ancient Dalaran
            {132626, 'P_RUNE'}, -- P:Vale of Eternal Blossoms
            {176244, 'P_RUNE'}, -- P:Warspear
            {224871, 'P_RUNE'}, -- P:Dalaran - Broken Isles
            {281402, 'P_RUNE'}, -- P:Dazar'alor
            {344597, 'P_RUNE'}, -- P:Oribos
            {395289, 'P_RUNE'}, -- P:Valdrakken
            {446534, 'P_RUNE'}, -- P:Dornogal
            {1259194, 'P_RUNE'}, -- P:Silvermoon City
        }
    }

    local _, class = UnitClass('player')
    if class == 'MAGE' then
        portals = spells[select(1, UnitFactionGroup('player'))]
    elseif class == 'DEATHKNIGHT' then
        portals = {
            {50977, 'TRUE'} -- Death Gate
        }
    elseif class == 'DRUID' then
        portals = {
            {18960, 'TRUE'}, -- TP:Moonglade
            {147420, 'TRUE'}, -- TP:One with Nature
            {193753, 'TRUE'} -- TP:Dreamwalk
        }
    elseif class == 'SHAMAN' then
        portals = {
            {556, 'TRUE'} -- Astral Recall
        }
    elseif class == 'MONK' then
        portals = {
            {126892, 'TRUE'}, -- Zen Pilgrimage
            {126895, 'TRUE'} -- Zen Pilgrimage: Return
        }
    else
        portals = {}
    end

    local _, race = UnitRace('player')
    if race == 'DarkIronDwarf' then
        table.insert(portals, {265225, 'TRUE'}) -- Mole Machine
    end
    if race == 'Vulpera' then
        table.insert(portals, {312370, 'TRUE'}) -- Make Camp
        table.insert(portals, {312372, 'TRUE'}) -- Return To Camp
    end

    wipe(spells)
end

local function GenerateMenuEntries(itemType, itemList, menuCategory)
    local itemsGenerated = 0

    if itemType == "spell" then
    for _, unTransSpell in ipairs(itemList) do
            if IsPlayerSpell(unTransSpell[1]) then
                local spellName
                local spell, _, spellIcon, _, _, _, spellId = GetSpellInfo(unTransSpell[1])
                if type(spell) == "table" then
                    spellId = spell.spellID
                    spellIcon = spell.iconID
                    spellName = spell.name
                else
                    spellName = spell
                end

                if spellId then
                    if not methods[menuCategory] then methods[menuCategory] = {} end
                    local spellDescription = GetSpellDescription(spellId)
                    methods[menuCategory][spellName] = {
                        itemID   = spellId,
                        itemName = spellName,
                        itemIcon = spellIcon,
                        itemType = itemType,
                        itemRGB  = nil,
                        itemDesc = spellDescription,
                        isPortal = unTransSpell[2] == 'P_RUNE',
                        secure   = {type = 'spell', spell = spellId}
                    }
                    itemsGenerated = itemsGenerated + 1
                end
            end
        end
    else
        local i = 0
        for i = 1, #itemList do
            if hasItem(itemList[i]) then
                local itemHandle, itemSpellId, itemRealType, itemSecure
                _, itemRealType = hasItem(itemList[i])
                local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = GetItemInfo(itemList[i])
                if itemName and itemQuality and itemIcon then
                    itemSecure = {type = 'item', item = itemName}
                    local itemSpellDescription = nil
                    _, itemSpellId = GetItemSpell(itemList[i])
                    if itemSpellId then
                        itemSpellDescription = GetSpellDescription(itemSpellId)
                    end
                    if itemRealType == "toy" then
                        itemSecure = {type = 'toy', toy = itemList[i]}
                    end
                    if not methods[menuCategory] then methods[menuCategory] = {} end
                    methods[menuCategory][itemName] = {
                        itemID   = itemList[i],
                        itemName = itemName,
                        itemIcon = itemIcon,
                        itemType = itemType,
                        itemDesc = itemSpellDescription,
                        itemRGB  = ITEM_QUALITY_COLORS[itemQuality],
                        secure   = itemSecure --{type = 'item', item = itemName}
                    }
                    itemsGenerated = itemsGenerated + 1
                end
            end
            i = i + 1
        end
    end
    return itemsGenerated
end

local function PrepareMenuData()

    wipe(methods)
    wipe(challengeCategories)

    if not portals then SetupSpells() end

    if portals then GenerateMenuEntries("spell", portals, "mainspells") end

    -- User-defined custom spells are shown together with the main teleport/portal spells
    if PortalsDB.customSpells and #PortalsDB.customSpells > 0 then
        local customSpellList = {}
        for i = 1, #PortalsDB.customSpells do
            customSpellList[i] = {PortalsDB.customSpells[i], 'TRUE'}
        end
        GenerateMenuEntries("spell", customSpellList, "mainspells")
    end

    if challengeAvailable then
        challengeSpellCount = 0
        methods["challenges"] = {}
        -- Generate each expansion separately, skipping the ones disabled in options,
        -- and merge the enabled ones into the flat "challenges" category too.
        for _, exp in ipairs(challengeExpansions) do
            local enabled = (not PortalsDB.challengeExpansions) or (PortalsDB.challengeExpansions[exp.key] ~= false)
            if enabled then
                local count = GenerateMenuEntries("spell", exp.spells, exp.category)
                if count > 0 then
                    challengeCategories[#challengeCategories + 1] = {category = exp.category, name = L[exp.name]}
                    for entryName, entry in pairs(methods[exp.category]) do
                        methods["challenges"][entryName] = entry
                    end
                end
            end
        end
        for _ in pairs(methods["challenges"]) do challengeSpellCount = challengeSpellCount + 1 end
    end

    GenerateMenuEntries("items", items, "mainitems")

    -- User-defined custom items are shown together with the various items
    if PortalsDB.customItems and #PortalsDB.customItems > 0 then
        GenerateMenuEntries("items", PortalsDB.customItems, "mainitems")
    end

    engineringItemsCount = GenerateMenuEntries("items", engineeringItems, "engineering")

    heartstoneItemsCount = GenerateMenuEntries("items", heartstones, "heartstones")

    databaseLoaded = true
end

local function UpdateIcon(icon) obj.icon = icon end


local function ShowMenuEntries(category, sortTable)
    if methods[category] then
        for _, menuEntry in pairsByKeys(methods[category], sortTable) do
            if menuEntry.itemType == "spell" then
                local spellCooldown
                if isCataclysmClassic or isMoPClassic or isTBCClassic then
                    spellCooldown = GetSpellCooldown(menuEntry.itemName)
                else
                    spellCooldown = GetSpellCooldown(menuEntry.itemName).startTime
                end
                -- Handle secret values in combat (WoW 12.0.0+)
                local spellReady = false
                if issecretvalue and issecretvalue(spellCooldown) then
                    spellReady = true -- Assume ready when secret
                elseif spellCooldown == 0 then
                    spellReady = true
                end
                if menuEntry.secure and spellReady then
                    dewdrop:AddLine(
                        'textHeight',   PortalsDB.fontSize,
                        'text',         menuEntry.itemName,
                        'tooltipTitle', menuEntry.itemName,
                        'tooltipText',  menuEntry.itemDesc,
                        'secure',       menuEntry.secure,
                        'icon',         tostring(menuEntry.itemIcon),
                        'func',         function()
                            UpdateIcon(menuEntry.itemIcon)
                            if announce and menuyEntry.isPortal and chatType then
                                SendChatMessage(L['ANNOUNCEMENT'] .. ' ' .. menuEntry.itemName, chatType)
                            end
                        end,
                        'closeWhenClicked', true)
                end
            else
                dewdrop:AddLine(
                    'textHeight',   PortalsDB.fontSize,
                    'text',         menuEntry.itemName,
                    'tooltipTitle', menuEntry.itemName,
                    'tooltipText',  menuEntry.itemDesc,
                    'textR',        menuEntry.itemRGB.r,
                    'textG',        menuEntry.itemRGB.g,
                    'textB',        menuEntry.itemRGB.b,
                    'secure',       menuEntry.secure,
                    'icon',         tostring(menuEntry.itemIcon),
                    'func',         function() UpdateIcon(menuEntry.itemIcon) end,
                    'closeWhenClicked', true)
            end
        end
        dewdrop:AddLine()
    end
end

local function GetItemCooldowns()
    local cooldown, cooldowns, hours, mins, secs
    if cooldowns == nil then cooldowns = {} end

    for i = 1, #items do
        if GetItemCount(items[i]) > 0 or (PlayerHasToy(items[i]) and C_ToyBox.IsToyUsable(items[i])) then
            local startTime, duration = GetItemCooldown(items[i])
            -- Handle secret values in combat (WoW 12.0.0+)
            if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
                cooldown = L['READY'] -- Assume ready when secret
            else
                cooldown = duration - (GetTime() - startTime)
                local name = GetItemInfo(items[i]) or select(2, C_ToyBox.GetToyInfo(items[i]))
                if name then
                    if cooldown <= 0 then
                        cooldown = L['READY']
                    else
                        cooldown = SecondsToTime(cooldown)
                    end
                    cooldowns[name] = cooldown
                end
            end
        end
    end

    for i = 1, #engineeringItems do
        if GetItemCount(engineeringItems[i]) > 0 or (PlayerHasToy(engineeringItems[i]) and C_ToyBox.IsToyUsable(engineeringItems[i])) then
            local startTime, duration = GetItemCooldown(engineeringItems[i])
            -- Handle secret values in combat (WoW 12.0.0+)
            if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
                -- Skip showing cooldown when secret (assume ready)
            else
                cooldown = duration - (GetTime() - startTime)
                if cooldown > 0 then
                    local name = GetItemInfo(engineeringItems[i]) or select(2, C_ToyBox.GetToyInfo(engineeringItems[i]))
                    if name then
                        cooldown = SecondsToTime(cooldown)
                        cooldowns[name] = cooldown
                    end
                end
            end
        end
    end

    return cooldowns
end

local function GetScrollCooldown()
    local cooldown, startTime, duration

    for i = 1, #scrolls do
        if GetItemCount(scrolls[i]) > 0 or (PlayerHasToy(scrolls[i]) and C_ToyBox.IsToyUsable(scrolls[i])) then
            startTime, duration = GetItemCooldown(scrolls[i])
            -- Handle secret values in combat (WoW 12.0.0+)
            if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
                return L['READY'] -- Assume ready when secret
            end
            cooldown = duration - (GetTime() - startTime)
            if cooldown <= 0 then
                return L['READY']
            else
                return SecondsToTime(cooldown)
            end
        end
    end

    return L['N/A']
end

local function GetWhistleCooldown()
    local cooldown, startTime, duration
    if GetItemCount(whistle[1]) > 0 then
        startTime, duration = GetItemCooldown(whistle[1])
        -- Handle secret values in combat (WoW 12.0.0+)
        if issecretvalue and (issecretvalue(startTime) or issecretvalue(duration)) then
            return L['READY'] -- Assume ready when secret
        end
        cooldown = duration - (GetTime() - startTime)
        if cooldown <= 0 then
            return L['READY']
        else
            return SecondsToTime(cooldown)
        end
    end
    return L['N/A']
end

local function ShowHearthstone()
    local bindLoc = GetBindLocation()
    local secure, text, icon, name

    for i = 1, #scrolls do
        if hasItem(scrolls[i]) then
            name, _, _, _, _, _, _, _, _, icon = GetItemInfo(scrolls[i])
            text = L['INN'] .. ' ' .. bindLoc
            secure = {type = 'item', item = name}
            break
        end
    end

    if secure ~= nil then
        dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', text, 'secure', secure, 'icon', tostring(icon), 'func', function() UpdateIcon(icon) end, 'closeWhenClicked', true)
    end
end

local function ShowWhistle()
    local secure, icon, name
    if hasItem(whistle[1]) then
        name, _, _, _, _, _, _, _, _, icon = GetItemInfo(whistle[1])
        secure = {type = 'item', item = name}
    end
    if secure ~= nil then
        dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', name, 'secure', secure, 'icon', tostring(icon), 'func', function() UpdateIcon(icon) end, 'closeWhenClicked', true)
        dewdrop:AddLine()
    end
end

-- Shared teleport-home cooldown (applies to all houses)
local function GetHousingCooldown()
    if not (C_Housing and C_Housing.GetVisitCooldownInfo) then return L['N/A'] end
    local info = C_Housing.GetVisitCooldownInfo()
    if not info then return L['N/A'] end
    -- Handle secret values in combat (WoW 12.0.0+)
    if issecretvalue and (issecretvalue(info.startTime) or issecretvalue(info.duration)) then
        return L['READY']
    end
    if not info.isEnabled then return L['READY'] end
    local remaining = (info.startTime + info.duration) - GetTime()
    if remaining and remaining > 1 then
        return SecondsToTime(remaining)
    end
    return L['READY']
end

-- One menu entry per owned house; clicking fires the secure teleporthome action
local function ShowHousing()
    if #housingHouses == 0 then return end
    for _, house in ipairs(housingHouses) do
        -- Keep a reference to the secure table so the auto-retry can rewrite the GUID in place
        house.secure = {
            type = 'teleporthome',
            ['house-neighborhood-guid'] = house.neighborhoodGUID,
            ['house-guid']              = house.houseGUID,
            ['house-plot-id']           = house.plotID,
        }
        dewdrop:AddLine(
            'textHeight',   PortalsDB.fontSize,
            'text',         house.name,
            'tooltipTitle', house.name,
            'secure',       house.secure,
            'icon',         tostring(housingIcon),
            'func',         function()
                UpdateIcon(housingIcon)
                lastHouseAttempt = {key = house.key, time = GetTime()}
            end,
            'closeWhenClicked', true)
    end
    dewdrop:AddLine()
end

local function UpdateMenu(level, value)
    dewdrop:SetFontSize(PortalsDB.fontSize)
    dewdrop:SetScrollListSize(PortalsDB.scrollListSize)

    if level == 1 then
        dewdrop:AddLine('text', 'Broker_Portals', 'isTitle', true)
        PrepareMenuData()
        if isRetail then RequestHousingInfo() end -- refresh owned-house GUIDs for the next open (async)
        local chatType = (UnitInRaid("player") and "RAID") or (GetNumGroupMembers() > 0 and "PARTY") or nil
        local announce = PortalsDB.announce

        if not portals then SetupSpells() end

        if portals then if not PortalsDB.showTeleportsSubCat then ShowMenuEntries("mainspells", true) end end

        if PortalsDB.showItems then
            if not PortalsDB.showItemsSubCat then ShowMenuEntries("mainitems", PortalsDB.sortItems) end
            if not PortalsDB.showEngineeringSubCat and engineringItemsCount > 0 then ShowMenuEntries("engineering", PortalsDB.sortItems) end
        end

        if PortalsDB.showChallengeTeleports and challengeAvailable and challengeSpellCount > 0 then
            if not PortalsDB.showChallengeSubCat then ShowMenuEntries("challenges", PortalsDB.sortItems) end
        end

        if PortalsDB.showHSItems and heartstoneItemsCount > 0 then if not PortalsDB.showHSItemsSubCat then ShowMenuEntries("heartstones", PortalsDB.sortItems) end end

        if portals then
            if PortalsDB.showTeleportsSubCat then
                dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', L["TP_P"], 'icon', tostring(teleportsIcon), 'hasArrow', true, 'value', 'mainspells')
            end
        end

        if PortalsDB.showItems then
            if PortalsDB.showItemsSubCat then
                dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', L["MAIN_ITEMS"], 'icon', tostring(variousItemsIcon), 'hasArrow', true, 'value', 'mainitems')
            end
        end

        if PortalsDB.showItems and engineringItemsCount > 0 then
            if PortalsDB.showEngineeringSubCat then
                dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', engineeringName, 'icon', tostring(engineeringIcon), 'hasArrow', true, 'value', 'engineering')
            end
        end

        if PortalsDB.showChallengeTeleports and challengeAvailable and challengeSpellCount > 0 then
            if PortalsDB.showChallengeSubCat then
                dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', L['CHALLENGE_TELEPORTS'], 'icon', tostring(teleportsIcon), 'hasArrow', true, 'value', 'challenges')
            end
        end

        if PortalsDB.showHSItems and heartstoneItemsCount > 0 then
            if PortalsDB.showHSItemsSubCat then
                dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', L['HEARTHSTONE_ANALOGUES'], 'icon', tostring(heartstonesIcon), 'hasArrow', true, 'value', 'heartstones')
            end
        end

        ShowHearthstone()
        ShowWhistle()
        if isRetail then ShowHousing() end

        dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', L['OPTIONS'], 'hasArrow', false, 'func', function() Settings.OpenToCategory(category:GetID()); end, 'closeWhenClicked', true)

        dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', CLOSE, 'tooltipTitle', CLOSE, 'tooltipText', CLOSE_DESC, 'closeWhenClicked', true)

    elseif level == 2 and value == 'mainspells' then
        ShowMenuEntries("mainspells", true)
    elseif level == 2 and value == 'mainitems' then
        ShowMenuEntries("mainitems", PortalsDB.sortItems)
    elseif level == 2 and value == 'heartstones' then
        ShowMenuEntries("heartstones", PortalsDB.sortItems)
    elseif level == 2 and value == 'challenges' then
        for _, challengeCategory in ipairs(challengeCategories) do
            dewdrop:AddLine('textHeight', PortalsDB.fontSize, 'text', challengeCategory["name"], 'icon', tostring(teleportsIcon), 'hasArrow', true, 'value', challengeCategory["category"])
        end
    elseif level == 2 and value == 'engineering' then
        ShowMenuEntries("engineering", PortalsDB.sortItems)
    elseif level == 3 then
        ShowMenuEntries(value, PortalsDB.sortItems)
    end
end

function frame:PLAYER_LOGIN()
    -- PortalsDB.minimap is there for smooth upgrade of SVs from old version
    if (not PortalsDB) or (PortalsDB.version == nil) then
        PortalsDB                        = {}
        PortalsDB.minimap                = {}
        PortalsDB.minimap.hide           = false
        PortalsDB.showItems              = true
        PortalsDB.showItemsSubCat        = false
        PortalsDB.showHSItems            = true
        PortalsDB.showHSItemsSubCat      = false
        PortalsDB.showItemCooldowns      = true
        PortalsDB.showChallengeTeleports = true
        PortalsDB.showChallengeSubCat    = false
        PortalsDB.showEngineeringSubCat  = true
        PortalsDB.showTeleportsSubCat    = false
        PortalsDB.scrollListSize         = 33
        PortalsDB.sortItems              = false
        PortalsDB.announce               = false
        PortalsDB.fontSize               = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
        PortalsDB.version                = 10
    else -- check if all parameters exist and if not then re-add parameter with default value
        PortalsDB.minimap                = (PortalsDB.minimap ~= nil and PortalsDB.minimap) or {}
        PortalsDB.minimap.hide           = (PortalsDB.minimap.hide ~= nil and PortalsDB.minimap.hide) or false
        PortalsDB.showItems              = (PortalsDB.showItems ~= nil and PortalsDB.showItems) or true
        PortalsDB.showItemsSubCat        = (PortalsDB.showItemsSubCat ~= nil and PortalsDB.showItemsSubCat) or false
        PortalsDB.showHSItems            = (PortalsDB.showHSItems ~= nil and PortalsDB.showHSItems) or true
        PortalsDB.showHSItemsSubCat      = (PortalsDB.showHSItemsSubCat ~= nil and PortalsDB.showHSItemsSubCat) or false
        PortalsDB.showItemCooldowns      = (PortalsDB.showItemCooldowns ~= nil and PortalsDB.showItemCooldowns) or true
        PortalsDB.showChallengeTeleports = (PortalsDB.showChallengeTeleports and PortalsDB.showChallengeTeleports) or true
        PortalsDB.showChallengeSubCat    = (PortalsDB.showChallengeSubCat ~= nil and PortalsDB.showChallengeSubCat) or false
        PortalsDB.showEngineeringSubCat  = (PortalsDB.showEngineeringSubCat ~= nil and PortalsDB.showEngineeringSubCat) or true
        PortalsDB.showTeleportsSubCat    = (PortalsDB.showTeleportsSubCat ~= nil and PortalsDB.showTeleportsSubCat) or false
        PortalsDB.scrollListSize         = (PortalsDB.scrollListSize ~= nil and PortalsDB.scrollListSize) or 33
        PortalsDB.sortItems              = (PortalsDB.sortItems ~= nil and PortalsDB.sortItems) or false
        PortalsDB.announce               = (PortalsDB.announce~= nil and PortalsDB.announce) or false
        PortalsDB.fontSize               = (PortalsDB.fontSize ~= nil and PortalsDB.fontSize) or UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
        PortalsDB.version                = 10
    end

    -- Fields added in newer versions (shared by fresh install and upgrade paths)
    PortalsDB.customItems  = PortalsDB.customItems or {}
    PortalsDB.customSpells = PortalsDB.customSpells or {}
    if type(PortalsDB.challengeExpansions) ~= "table" then PortalsDB.challengeExpansions = {} end
    for _, exp in ipairs(challengeExpansions) do
        if PortalsDB.challengeExpansions[exp.key] == nil then PortalsDB.challengeExpansions[exp.key] = true end
    end

    if icon then icon:Register('Broker_Portals', obj, PortalsDB.minimap) end
    CreateSettingsPanel()
    PreloadItemData()
    PrepareMenuData()
    PrepareMenuData()
    frame:RegisterEvent('GET_ITEM_INFO_RECEIVED')
    if isRetail and C_Housing and C_Housing.GetPlayerOwnedHouses then
        BuildStaleHouseErrorSet()
        frame:RegisterEvent('PLAYER_HOUSE_LIST_UPDATED')
        frame:RegisterEvent('UI_ERROR_MESSAGE')
        RequestHousingInfo()
    end
    self:UnregisterEvent('PLAYER_LOGIN')
end

-- The owned-house list arrives asynchronously in response to GetPlayerOwnedHouses().
-- Each entry is a HouseInfo (plotID, houseName, ownerName, neighborhoodName, GUIDs).
-- We merge by a stable key (neighborhoodGUID:plotID) so a recently cycled GUID is not
-- immediately overwritten by a possibly-stale server value.
function frame:PLAYER_HOUSE_LIST_UPDATED(event, houseInfos)
    local existing = {}
    for _, h in ipairs(housingHouses) do existing[h.key] = h end

    local rebuilt = {}
    if houseInfos then
        for _, info in ipairs(houseInfos) do
            if info.neighborhoodGUID and info.houseGUID and info.plotID then
                local key = tostring(info.neighborhoodGUID) .. ":" .. tostring(info.plotID)
                local name = info.houseName
                if not name or name == "" then name = info.neighborhoodName end
                if not name or name == "" then name = L['HOUSE_TELEPORT'] .. ' ' .. tostring(info.plotID) end

                local prev = existing[key]
                local houseGUID = info.houseGUID
                local lockUntil = prev and prev.lockUntil
                -- Preserve a locally-cycled GUID while its lock is active
                if prev and lockUntil and lockUntil > GetTime() then
                    houseGUID = prev.houseGUID
                end

                rebuilt[#rebuilt + 1] = {
                    neighborhoodGUID = info.neighborhoodGUID,
                    houseGUID        = houseGUID,
                    plotID           = info.plotID,
                    name             = name,
                    key              = key,
                    lockUntil        = lockUntil,
                }
            end
        end
    end
    housingHouses = rebuilt
end

-- A teleport that fails on a stale GUID raises a housing UI error shortly after the
-- click. Cycle the trailing digit of the offending house's GUID and lock it so the
-- next attempt (after reopening the menu) uses the corrected value.
function frame:UI_ERROR_MESSAGE(event, errorType, message)
    if not lastHouseAttempt then return end
    if (GetTime() - lastHouseAttempt.time) > HOUSE_RETRY_WINDOW then
        lastHouseAttempt = nil
        return
    end
    if message and staleHouseErrors[message] then
        for _, h in ipairs(housingHouses) do
            if h.key == lastHouseAttempt.key then
                local newGUID = IncrementHouseGUID(h.houseGUID)
                if newGUID then
                    h.houseGUID = newGUID
                    h.lockUntil = GetTime() + HOUSE_GUID_LOCK
                    if h.secure then h.secure['house-guid'] = newGUID end
                end
                break
            end
        end
        lastHouseAttempt = nil
    end
end

-- Item data resolves asynchronously; refresh the custom list when it arrives so
-- freshly added entries show their real name, and mark the menu cache stale so the
-- next open rebuilds with the now-available data.
function frame:GET_ITEM_INFO_RECEIVED()
    databaseLoaded = false
    if RefreshCustomList and OptionsFrame and OptionsFrame:IsShown() then
        RefreshCustomList()
    end
end

-- All credit for this func goes to Tekkub and his picoGuild!
local function GetTipAnchor(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return 'TOPLEFT', 'BOTTOMLEFT' end
    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and 'RIGHT' or (x < UIParent:GetWidth() / 3) and 'LEFT' or ''
    local vhalf = (y > UIParent:GetHeight() / 2) and 'TOP' or 'BOTTOM'
    return vhalf .. hhalf, frame, (vhalf == 'TOP' and 'BOTTOM' or 'TOP') .. hhalf
end

function obj.OnClick(self, button)
    GameTooltip:Hide()
    if button == 'LeftButton' or button == 'RightButton' then
        if dewdrop:IsOpen(self) then
            dewdrop:Close()
        else
            dewdrop:Open(self, 'children', function(level, value) UpdateMenu(level, value) end)
        end
    end
end

function obj.OnLeave() GameTooltip:Hide() end

function obj.OnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:SetPoint(GetTipAnchor(self))
    GameTooltip:ClearLines()

    GameTooltip:AddLine('Broker Portals')
    GameTooltip:AddDoubleLine(L['RCLICK'], L['SEE_SPELLS'], 0.9, 0.6, 0.2, 0.2, 1, 0.2)
    GameTooltip:AddLine(' ')

    local scrollCooldown = GetScrollCooldown()
    if scrollCooldown == L['READY'] then
        GameTooltip:AddDoubleLine(L['HEARTHSTONE'] .. ': ' .. GetBindLocation(), scrollCooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
    else
        GameTooltip:AddDoubleLine(L['HEARTHSTONE'] .. ': ' .. GetBindLocation(), scrollCooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
    end

    if isCataclysmClassic or isClassicEra  or isCamelot then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(L["TP_P"], getReagentCount(L["TP_RUNE"]) .. "/" .. getReagentCount(L["P_RUNE"]), 0.9, 0.6, 0.2, 0.2, 1, 0.2)
    end

    if PortalsDB.showItemCooldowns then
        local cooldowns = GetItemCooldowns()
        if cooldowns ~= nil then
            GameTooltip:AddLine(' ')
            for name, cooldown in pairs(cooldowns) do
                if cooldown == L['READY'] then
                    GameTooltip:AddDoubleLine(name, cooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
                else
                    GameTooltip:AddDoubleLine(name, cooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
                end
            end
        end
    end

    if not isCataclysmClassic and not isClassicEra then
        local whistleCooldown = GetWhistleCooldown()
        if whistleCooldown == L['READY'] then
            GameTooltip:AddDoubleLine(GetItemInfo(whistle[1]), whistleCooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
        else
            GameTooltip:AddDoubleLine(GetItemInfo(whistle[1]), whistleCooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
        end
    end

    if isRetail and #housingHouses > 0 then
        local housingCooldown = GetHousingCooldown()
        if housingCooldown ~= L['N/A'] then
            if housingCooldown == L['READY'] then
                GameTooltip:AddDoubleLine(L['HOUSE_TELEPORT'], housingCooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
            else
                GameTooltip:AddDoubleLine(L['HOUSE_TELEPORT'], housingCooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
            end
        end
    end
    GameTooltip:Show()
end

-- slash command definition
SlashCmdList['BROKER_PORTALS'] = function() BPToggleMinimap() end
SLASH_BROKER_PORTALS1 = '/portals'
