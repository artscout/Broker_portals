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

local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local isCataclysmClassic = (WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC)
local isMoPClassic = (WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC)
local engineeringName = C_TradeSkillUI.GetTradeSkillDisplayName(202)
local engineeringIcon = C_TradeSkillUI.GetTradeSkillTexture(202)
local heartstonesIcon = 134414 -- icon of Heartstone
local teleportsIcon = 237509 -- Teleport to Dalaran icon used
local variousItemsIcon = 134248 -- Key icon used

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
    93672, -- Dark Portal
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
    230850, -- Delve-O-Bot 7001
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
    212337 -- Stone of the Hearth
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
    144341 -- Rechargeable Reaves Battery, same as with Reaves Battery
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
    {445424, 'TRUE'}, -- Path of the Twilight Fortress
    {424142, 'TRUE'}, -- Path of the Tidehunter
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
    {445414, 'TRUE'}, -- Path of Arathi Flagship
    {445416, 'TRUE'}, -- Path of Nerubean Ascension
    {445417, 'TRUE'}, -- Path of the Ruined City
    {445424, 'TRUE'}, -- Path of Twilight Fortress
    {445440, 'TRUE'}, -- Path of the Flaming Brewery
    {445416, 'TRUE'}, -- Path of the City of Threads
    {445441, 'TRUE'}, -- Path of the Warding Candles
    {445414, 'TRUE'}, -- Path of the Dawnbreaker
    {445444, 'TRUE'}, -- Path of the Light's Reverence
    {445443, 'TRUE'}, -- Path of the Fallen Stormriders
    {445269, 'TRUE'}, -- Path of the Corrupted Foundry
    {467546, 'TRUE'}, -- Path of the Waterworks
    {1216786, 'TRUE'}, -- Path of the Circuit Breaker
    {1226482, 'TRUE'}, -- Path of the Full House
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
    {445414, 'TRUE'}, -- Path of Arathi Flagship
    {445416, 'TRUE'}, -- Path of Nerubean Ascension
    {445417, 'TRUE'}, -- Path of the Ruined City
    {445424, 'TRUE'}, -- Path of Twilight Fortress
    {445440, 'TRUE'}, -- Path of the Flaming Brewery
    {445416, 'TRUE'}, -- Path of the City of Threads
    {445441, 'TRUE'}, -- Path of the Warding Candles
    {445414, 'TRUE'}, -- Path of the Dawnbreaker
    {445444, 'TRUE'}, -- Path of the Light's Reverence
    {445443, 'TRUE'}, -- Path of the Fallen Stormriders
    {445269, 'TRUE'}, -- Path of the Corrupted Foundry
    {467546, 'TRUE'}, -- Path of the Waterworks
    {1216786, 'TRUE'}, -- Path of the Circuit Breaker
    {1226482, 'TRUE'}, -- Path of the Full House
}

local whistle = {
    141605, -- Flight Master's Whistle
    168862 -- G.E.A.R. Tracking Beacon
}

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

local function BPToggleMinimap()
    local hide = not PortalsDB.minimap.hide
    PortalsDB.minimap.hide = hide
    if hide then
        icon:Hide('Broker_Portals')
    else
        icon:Show('Broker_Portals')
    end
end

local function CreateSettingsPanel()
    if Settings then
        OptionsFrame = CreateFrame("Frame", "OptionsFrame", UIParent)
        OptionsFrame.name = "Broker Portals"

        local showItemsCheckBox = CreateFrame("CheckButton", "ShowItemsCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showItemsCheckBox:SetPoint("TOPLEFT", 16, -16)
        showItemsCheckBox.Text:SetText(L["SHOW_ITEMS"])
        showItemsCheckBox.tooltipText = L["SHOW_ITEMS_TOOLTIP"]
        showItemsCheckBox:SetChecked(PortalsDB.showItems)

        showItemsCheckBox:SetScript("OnClick", function(self)
            PortalsDB.showItems = not PortalsDB.showItems
            parentFrame = self:GetParent()
            children = {parentFrame:GetChildren()}
            for _, child in ipairs(children) do
                if child:GetDebugName() == "showItemsSubCatCheckBox" or child:GetDebugName() == "showEngineeringSubCatCheckBox" then child:SetEnabled(PortalsDB.showItems) end
            end
        end)

        local showItemsSubCatCheckBox = CreateFrame("CheckButton", "showItemsSubCatCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showItemsSubCatCheckBox:SetPoint("TOPLEFT", 320, -16)
        showItemsSubCatCheckBox.Text:SetText(L["SHOW_ITEMS_SUBCAT"])
        showItemsSubCatCheckBox.tooltipText = L["SHOW_ITEMS_SUBCAT_TOOLTIP"]
        showItemsSubCatCheckBox:SetChecked(PortalsDB.showItemsSubCat)

        showItemsSubCatCheckBox:SetScript("OnClick", function(self) PortalsDB.showItemsSubCat = not PortalsDB.showItemsSubCat end)

        local showHSItemsCheckBox = CreateFrame("CheckButton", "showHSItemsCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showHSItemsCheckBox:SetPoint("TOPLEFT", 16, -64)
        showHSItemsCheckBox.Text:SetText(L["SHOW_HS_ITEMS"])
        showHSItemsCheckBox.tooltipText = L["SHOW_HS_ITEMS_TOOLTIP"]
        showHSItemsCheckBox:SetChecked(PortalsDB.showHSItems)

        showHSItemsCheckBox:SetScript("OnClick", function(self)
            PortalsDB.showHSItems = not PortalsDB.showHSItems
            parentFrame = self:GetParent()
            children = {parentFrame:GetChildren()}
            for _, child in ipairs(children) do if child:GetDebugName() == "showHSItemsSubCatCheckBox" then child:SetEnabled(PortalsDB.showHSItems) end end
        end)

        local showHSItemsSubCatCheckBox = CreateFrame("CheckButton", "showHSItemsSubCatCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showHSItemsSubCatCheckBox:SetPoint("TOPLEFT", 320, -64)
        showHSItemsSubCatCheckBox.Text:SetText(L["SHOW_HS_ITEMS_SUBCAT"])
        showHSItemsSubCatCheckBox.tooltipText = L["SHOW_HS_ITEMS_SUBCAT_TOOLTIP"]
        showHSItemsSubCatCheckBox:SetChecked(PortalsDB.showHSItemsSubCat)

        showHSItemsSubCatCheckBox:SetScript("OnClick", function(self) PortalsDB.showHSItemsSubCat = not PortalsDB.showHSItemsSubCat end)

        local showEngineeringSubCatCheckBox = CreateFrame("CheckButton", "showEngineeringSubCatCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showEngineeringSubCatCheckBox:SetPoint("TOPLEFT", 16, -110)
        showEngineeringSubCatCheckBox.Text:SetText(L["SHOW_ENGINEERING_SUBCAT"])
        showEngineeringSubCatCheckBox.tooltipText = L["SHOW_ENGINEERING_SUBCAT_TOOLTIP"]
        showEngineeringSubCatCheckBox:SetChecked(PortalsDB.showEngineeringSubCat)

        showEngineeringSubCatCheckBox:SetScript("OnClick", function(self) PortalsDB.showEngineeringSubCat = not PortalsDB.showEngineeringSubCat end)

        local showTeleportsSubCatCheckBox = CreateFrame("CheckButton", "showTeleportsSubCatCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showTeleportsSubCatCheckBox:SetPoint("TOPLEFT", 320, -110)
        showTeleportsSubCatCheckBox.Text:SetText(L["SHOW_TELEPORTS_SUBCAT"])
        showTeleportsSubCatCheckBox.tooltipText = L["SHOW_TELEPORTS_SUBCAT_TOOLTIP"]
        showTeleportsSubCatCheckBox:SetChecked(PortalsDB.showTeleportsSubCat)

        showTeleportsSubCatCheckBox:SetScript("OnClick", function(self) PortalsDB.showTeleportsSubCat = not PortalsDB.showTeleportsSubCat end)

        local minimapButtonBox = CreateFrame("CheckButton", "showMinimapButtonCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        minimapButtonBox:SetPoint("TOPLEFT", 16, -158)
        minimapButtonBox.Text:SetText(L['ATT_MINIMAP'])
        minimapButtonBox.tooltipText = L['ATT_MINIMAP']
        minimapButtonBox:SetChecked(not PortalsDB.minimap.hide)

        minimapButtonBox:SetScript("OnClick", function(self) BPToggleMinimap() end)

        local announceCheckBox = CreateFrame("CheckButton", "announceCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        announceCheckBox:SetPoint("TOPLEFT", 320, -158)
        announceCheckBox.Text:SetText(L["ANNOUNCE"])
        announceCheckBox.tooltipText = L["ANNOUNCE_TOOLTIP"]
        announceCheckBox:SetChecked(PortalsDB.announce)

        announceCheckBox:SetScript("OnClick", function(self) PortalsDB.announce = not PortalsDB.announce end)

        local fontSizeSlider = CreateFrame("Slider", "fontSizeSlider", OptionsFrame, "OptionsSliderTemplate")
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

        local scrollSizeSlider = CreateFrame("Slider", "scrollSizeSlider", OptionsFrame, "OptionsSliderTemplate")
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

        local showItemsCooldownCheckBox = CreateFrame("CheckButton", "showItemsCooldownCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        showItemsCooldownCheckBox:SetPoint("TOPLEFT", 16, -254)
        showItemsCooldownCheckBox.Text:SetText(L["SHOW_ITEM_COOLDOWNS"])
        showItemsCooldownCheckBox.tooltipText = L["SHOW_ITEM_COOLDOWNS_TOOLTIP"]
        showItemsCooldownCheckBox:SetChecked(PortalsDB.showItemCooldowns)

        showItemsCooldownCheckBox:SetScript("OnClick", function(self) PortalsDB.showItemCooldowns = not PortalsDB.showItemCooldowns end)

        local sortItemsAlphabeticalyCheckBox = CreateFrame("CheckButton", "sortItemsAlphabeticalyCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
        sortItemsAlphabeticalyCheckBox:SetPoint("TOPLEFT", 320, -254)
        sortItemsAlphabeticalyCheckBox.Text:SetText(L["SORT_ITEMS"])
        sortItemsAlphabeticalyCheckBox.tooltipText = L["SORT_ITEMS_TOOLTIP"]
        sortItemsAlphabeticalyCheckBox:SetChecked(PortalsDB.sortItems)

        sortItemsAlphabeticalyCheckBox:SetScript("OnClick", function(self) PortalsDB.sortItems = not PortalsDB.sortItems end)

        if not isCataclysmClassic and not isClassic then
            local showChallengeTeleportsCheckBox = CreateFrame("CheckButton", "showChallengeTeleportsCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
            showChallengeTeleportsCheckBox:SetPoint("TOPLEFT", 16, -302)
            showChallengeTeleportsCheckBox.Text:SetText(L["SHOW_CHALLENGE_TELEPORTS"])
            showChallengeTeleportsCheckBox.tooltipText = L["SHOW_CHALLENGE_TELEPORTS_TOOLTIP"]
            showChallengeTeleportsCheckBox:SetChecked(PortalsDB.showChallengeTeleports)

            showChallengeTeleportsCheckBox:SetScript("OnClick", function(self)
                PortalsDB.showChallengeTeleports = not PortalsDB.showChallengeTeleports
                for _, child in ipairs(children) do if child:GetDebugName() == "showChallengeSubCatCheckBox" then child:SetEnabled(PortalsDB.showChallengeTeleports) end end
            end)

            local showChallengeSubCatCheckBox = CreateFrame("CheckButton", "showChallengeSubCatCheckBox", OptionsFrame, "InterfaceOptionsCheckButtonTemplate")
            showChallengeSubCatCheckBox:SetPoint("TOPLEFT", 320, -302)
            showChallengeSubCatCheckBox.Text:SetText(L["SHOW_CHALLENGE_TELEPORTS_SUBCAT"])
            showChallengeSubCatCheckBox.tooltipText = L["SHOW_CHALLENGE_TELEPORTS_SUBCAT_TOOLTIP"]
            showChallengeSubCatCheckBox:SetChecked(PortalsDB.showChallengeSubCat)

            showChallengeSubCatCheckBox:SetScript("OnClick", function(self) PortalsDB.showChallengeSubCat = not PortalsDB.showChallengeSubCat end)
        end

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

local function GetItemIDFromLink(itemlink)
    return tonumber(tostring(itemlink):match("item:(%d+)"))
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
                if GetInventoryItemCooldown('player', slotId) ~= 0 then
                    return false
                else
                    return true, "item"
                end
            end
        end
    end

    -- check Toybox
    if PlayerHasToy(itemID) and C_ToyBox.IsToyUsable(itemID) then
        local startTime, duration, cooldown
        startTime, duration = GetItemCooldown(itemID)
        cooldown = duration - (GetTime() - startTime)

        if cooldown > 0 then
            return false
        else
            return true, "toy"
        end
    end

    -- scan bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            item = GetContainerItemLink(bag, slot)
            if item then
                local id = GetItemIDFromLink(item)
                if id and tonumber(id) == itemID then
                    if GetContainerItemCooldown(bag, slot) ~= 0 then
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
            {446534, 'P_RUNE'} -- P:Dornogal
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
            {446534, 'P_RUNE'} -- P:Dornogal
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
                    spellDescription = GetSpellDescription(spellId)
                    methods[menuCategory][spellName] = {
                        itemID   = spellId,
                        itemName = spellName,
                        itemIcon = spellIcon,
                        itemType = itemType,
                        itemRGB  = nil,
                        itemDesc = spellDescription,
                        isPortal = unTransSpell[2] == 'P_RUNE',
                        secure   = {type = 'spell', spell = spellName}
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

    if not isCataclysmClassic and not isClassic then
        challengeVanillaCount = GenerateMenuEntries("spell", challengeVanillaSpells, "challengesVanilla")
        if challengeVanillaCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesVanilla", name = L["CHALLENGE_TP_VANILLA"]}
        end

        challengeCataCount    = GenerateMenuEntries("spell", challengeCataSpells, "challengesCata")
        if challengeCataCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesCata", name = L["CHALLENGE_TP_CATA"]}
        end

        challengeMOPCount     = GenerateMenuEntries("spell", challengeMOPSpells, "challengesMOP")
        if challengeMOPCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesMOP", name = L["CHALLENGE_TP_MOP"]}
        end

        challengeWODCount     = GenerateMenuEntries("spell", challengeWODSpells, "challengesWOD")
        if challengeWODCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesWOD", name = L["CHALLENGE_TP_WOD"]}
        end

        challengeLegionCount  = GenerateMenuEntries("spell", challengeLegionSpells, "challengesLegion")
        if challengeLegionCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesLegion", name = L["CHALLENGE_TP_LEGION"]}
        end

        challengeBFACount     = GenerateMenuEntries("spell", challengeBFASpells, "challengesBFA")
        if challengeBFACount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesBFA", name = L["CHALLENGE_TP_BFA"]}
        end

        challengeSLCount      = GenerateMenuEntries("spell", challengeSLSpells, "challengesSL")
        if challengeSLCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesSL", name = L["CHALLENGE_TP_SL"]}
        end

        challengeDFCount      = GenerateMenuEntries("spell", challengeDFSpells, "challengesDF")
        if challengeDFCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesDF", name = L["CHALLENGE_TP_DF"]}
        end

        challengeTWWCount     = GenerateMenuEntries("spell", challengeTWWSpells, "challengesTWW")
        if challengeTWWCount > 0 then
            challengeCategories[#challengeCategories + 1] = {category = "challengesTWW", name = L["CHALLENGE_TP_TWW"]}
        end

        challengeSpellCount = GenerateMenuEntries("spell", challengeSpells, "challenges")
    end

    GenerateMenuEntries("items", items, "mainitems")

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
                if isCataclysmClassic or isMoPClassic then
                    spellCooldown = GetSpellCooldown(menuEntry.itemName)
                else
                    spellCooldown = GetSpellCooldown(menuEntry.itemName).startTime
                end
                if menuEntry.secure and spellCooldown == 0 then
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
                    'func',         function()
                        UpdateIcon(menuEntry.itemIcon)
                    end,
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
            startTime, duration = GetItemCooldown(items[i])
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

    for i = 1, #engineeringItems do
        if GetItemCount(engineeringItems[i]) > 0 or (PlayerHasToy(engineeringItems[i]) and C_ToyBox.IsToyUsable(engineeringItems[i])) then
            startTime, duration = GetItemCooldown(engineeringItems[i])
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

    return cooldowns
end

local function GetScrollCooldown()
    local cooldown, startTime, duration

    for i = 1, #scrolls do
        if GetItemCount(scrolls[i]) > 0 or (PlayerHasToy(scrolls[i]) and C_ToyBox.IsToyUsable(scrolls[i])) then
            startTime, duration = GetItemCooldown(scrolls[i])
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

local function UpdateMenu(level, value)
    dewdrop:SetFontSize(PortalsDB.fontSize)
    dewdrop:SetScrollListSize(PortalsDB.scrollListSize)

    if level == 1 then
        dewdrop:AddLine('text', 'Broker_Portals', 'isTitle', true)
        PrepareMenuData()
        local chatType = (UnitInRaid("player") and "RAID") or (GetNumGroupMembers() > 0 and "PARTY") or nil
        local announce = PortalsDB.announce

        if not portals then SetupSpells() end

        if portals then if not PortalsDB.showTeleportsSubCat then ShowMenuEntries("mainspells", true) end end

        if PortalsDB.showItems then
            if not PortalsDB.showItemsSubCat then ShowMenuEntries("mainitems", PortalsDB.sortItems) end
            if not PortalsDB.showEngineeringSubCat and engineringItemsCount > 0 then ShowMenuEntries("engineering", PortalsDB.sortItems) end
        end

        if PortalsDB.showChallengeTeleports and not isCataclysmClassic and not isClassic and challengeSpellCount > 0 then
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

        if PortalsDB.showChallengeTeleports and not isCataclysmClassic and not isClassic and challengeSpellCount > 0 then
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
        PortalsDB = {}
        PortalsDB.minimap = {}
        PortalsDB.minimap.hide = false
        PortalsDB.showItems = true
        PortalsDB.showHSItems = true
        PortalsDB.showItemCooldowns = true
        PortalsDB.showChallengeTeleports = true
        PortalsDB.showChallengeSubCat = false
        PortalsDB.showEngineeringSubCat = true
        PortalsDB.showChallengeSubCat = false
        PortalsDB.showTeleportsSubCat = false
        PortalsDB.scrollListSize = 33
        PortalsDB.sortItems = false
        PortalsDB.announce = false
        PortalsDB.announce = false
        PortalsDB.fontSize = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
        PortalsDB.version = 9
    end
    -- upgrade from versions
    if PortalsDB.version == 8 then
        PortalsDB.sortItems = false
        PortalsDB.version = 9
    elseif PortalsDB.version == 7 then
        PortalsDB.showEngineeringSubCat = true
        PortalsDB.showChallengeSubCat = false
        PortalsDB.showTeleportsSubCat = false
        PortalsDB.scrollListSize = 33
        PortalsDB.version = 8
    elseif PortalsDB.version == 6 then
        PortalsDB.showEngineeringSubCat = true
        PortalsDB.version = 7
    elseif PortalsDB.version == 5 then
        PortalsDB.showChallengeTeleports = true
        PortalsDB.version = 6
    elseif PortalsDB.version == 4 then
        PortalsDB.fontSize = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
        PortalsDB.version = 5
    elseif PortalsDB.version == 3 then
        PortalsDB.announce = false
        PortalsDB.version = 4
    elseif PortalsDB.version == 2 then
        PortalsDB.showItemCooldowns = true
        PortalsDB.announce = false
        PortalsDB.version = 4
    elseif PortalsDB.version < 2 then
        PortalsDB.showItems = true
        PortalsDB.showItemCooldowns = true
        PortalsDB.announce = false
        PortalsDB.version = 4
    end

    if icon then icon:Register('Broker_Portals', obj, PortalsDB.minimap) end
    CreateSettingsPanel()
    PrepareMenuData()
    PrepareMenuData()
    self:UnregisterEvent('PLAYER_LOGIN')
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
    if button == 'RightButton' then dewdrop:Open(self, 'children', function(level, value) UpdateMenu(level, value) end) end
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

    if isCataclysmClassic or isClassic then
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

    if not isCataclysmClassic and not isClassic then
        local whistleCooldown = GetWhistleCooldown()
        if whistleCooldown == L['READY'] then
            GameTooltip:AddDoubleLine(GetItemInfo(whistle[1]), whistleCooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
        else
            GameTooltip:AddDoubleLine(GetItemInfo(whistle[1]), whistleCooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
        end
    end
    GameTooltip:Show()
end

-- slash command definition
SlashCmdList['BROKER_PORTALS'] = function() BPToggleMinimap() end
SLASH_BROKER_PORTALS1 = '/portals'
