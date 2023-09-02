if not LibStub then return end

local dewdrop = LibStub('LibDewdrop-3.0', true)
local icon = LibStub('LibDBIcon-1.0')

local _

local CreateFrame = CreateFrame
local C_ToyBox = C_ToyBox
local GetBindLocation = GetBindLocation
local GetContainerItemCooldown =  C_Container.GetContainerItemCooldown
local GetContainerItemInfo =  C_Container.GetContainerItemInfo
local GetContainerItemLink =  C_Container.GetContainerItemLink
local GetContainerNumSlots =  C_Container.GetContainerNumSlots
local GetItemCooldown = C_Container.GetItemCooldown
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemLink = GetInventoryItemLink
local GetNumGroupMembers = GetNumGroupMembers
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local IsPlayerSpell = IsPlayerSpell
local PlayerHasToy = PlayerHasToy
local SecondsToTime = SecondsToTime
local SendChatMessage = SendChatMessage
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitRace = UnitRace
local UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT

local addonName, addonTable = ...
local L = addonTable.L

-- IDs of items usable for transportation
local items = {
    -- Dalaran rings
    40585,  -- Signet of the Kirin Tor
    40586,  -- Band of the Kirin Tor
    44934,  -- Loop of the Kirin Tor
    44935,  -- Ring of the Kirin Tor
    45688,  -- Inscribed Band of the Kirin Tor
    45689,  -- Inscribed Loop of the Kirin Tor
    45690,  -- Inscribed Ring of the Kirin Tor
    45691,  -- Inscribed Signet of the Kirin Tor
    48954,  -- Etched Band of the Kirin Tor
    48955,  -- Etched Loop of the Kirin Tor
    48956,  -- Etched Ring of the Kirin Tor
    48957,  -- Etched Signet of the Kirin Tor
    51557,  -- Runed Signet of the Kirin Tor
    51558,  -- Runed Loop of the Kirin Tor
    51559,  -- Runed Ring of the Kirin Tor
    51560,  -- Runed Band of the Kirin Tor
    139599, -- Empowered Ring of the Kirin Tor
    -- Engineering Gadgets
    18984,  -- Dimensional Ripper - Everlook
    18986,  -- Ultrasafe Transporter: Gadgetzan
    30542,  -- Dimensional Ripper - Area 52
    30544,  -- Ultrasafe Transporter: Toshley's Station
    48933,  -- Wormhole Generator: Northrend
    87215,  -- Wormhole Generator: Pandaria
    112059, -- Wormhole Centrifuge
    151652, -- Wormhole Generator: Argus
    168807, -- Wormhole Generator: Kul Tiras
    168808, -- Wormhole Generator: Zandalar
    198156, -- Wormhole Genrator: Dragon Isles
    -- Seasonal items
    21711,  -- Lunar Festival Invitation
    37863,  -- Direbrew's Remote
    -- Miscellaneous
    17690,  -- Frostwolf Insignia Rank 1 (Horde)
    17691,  -- Stormpike Insignia Rank 1 (Alliance)
    17900,  -- Stormpike Insignia Rank 2 (Alliance)
    17901,  -- Stormpike Insignia Rank 3 (Alliance)
    17902,  -- Stormpike Insignia Rank 4 (Alliance)
    17903,  -- Stormpike Insignia Rank 5 (Alliance)
    17904,  -- Stormpike Insignia Rank 6 (Alliance)
    17905,  -- Frostwolf Insignia Rank 2 (Horde)
    17906,  -- Frostwolf Insignia Rank 3 (Horde)
    17907,  -- Frostwolf Insignia Rank 4 (Horde)
    17908,  -- Frostwolf Insignia Rank 5 (Horde)
    17909,  -- Frostwolf Insignia Rank 6 (Horde)
    22631,  -- Atiesh, Greatstaff of the Guardian
    32757,  -- Blessed Medallion of Karabor
    35230,  -- Darnarian's Scroll of Teleportation
    43824,  -- The Schools of Arcane Magic - Mastery
    46874,  -- Argent Crusader's Tabard
    50287,  -- Boots of the Bay
    52251,  -- Jaina's Locket
    58487,  -- Potion of Deepholm
    61379,  -- Gidwin's Hearthstone
    63206,  -- Wrap of Unity (Alliance)
    63207,  -- Wrap of Unity (Horde)
    63352,  -- Shroud of Cooperation (Alliance)
    63353,  -- Shroud of Cooperation (Horde)
    63378,  -- Hellscream's Reach Tabard
    63379,  -- Baradin's Wardens Tabard
    64457,  -- The Last Relic of Argus
    65274,  -- Cloak of Coordination (Horde)
    65360,  -- Cloak of Coordination (Alliance)
    95050,  -- The Brassiest Knuckle (Horde)
    95051,  -- The Brassiest Knuckle (Alliance)
    95567,  -- Kirin Tor Beacon
    95568,  -- Sunreaver Beacon
    87548,  -- Lorewalker's Lodestone
    93672,  -- Dark Portal
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
    168862, -- G.E.A.R. Tracking Beacon
    -- items usable instead of hearthstone
    28585  -- Ruby Slippers
}

local heartstones = {
    -- items usable instead of hearthstone
    28585,  -- Ruby Slippers
    37118,  -- Scroll of Recall
    44314,  -- Scroll of Recall II
    44315,  -- Scroll of Recall III
    37118,  -- Scroll of Recall
    44314,  -- Scroll of Recall II
    44315,  -- Scroll of Recall III
    54452,  -- Ethereal Portal
    64488,  -- The Innkeeper's Daughter
    142298, -- Astonishingly Scarlet Slippers
    142542, -- Tome of Town Portal
    162973, -- Greatfather Winter's Hearthstone
    163045, -- Headless Horseman's Hearthstone
    165669, -- Lunar Elder's Hearthstone
    165670, -- Peddlefeet's Lovely Hearthstone
    165802, -- Noble Gardener's Hearthstone
    166746, -- Fire Eater's Hearthstone
    166747, -- Brewfest Reveler's Hearthstone
    168862, -- G.E.A.R. Tracking Beacon
    168907, -- Holographic Digitalization Hearthstone
    172179, -- Eternal Traveler's Hearthstone
    180290, -- Night Fae Hearthstone
    182773, -- Necrolord Heartstone
    184353, -- Kyrian Hearthstone
    184871, -- Dark Portal
    188952, -- Dominated Hearthstone
    193588, -- Timewalker's Hearthstone
    200630  -- Ohn'ir Windsage's Hearthstone
}

local scrolls = {
    6948    -- Hearthstone
}

-- Gold Challenge portals
local challengeSpells = {
    { 131204, 'TRUE' }, -- Path of the Jade Serpent
    { 131205, 'TRUE' }, -- Path of the Stout Brew
    { 131206, 'TRUE' }, -- Path of the Shado-Pan
    { 131222, 'TRUE' }, -- Path of the Mogu King
    { 131225, 'TRUE' }, -- Path of the Setting Sun
    { 131231, 'TRUE' }, -- Path of the Scarlet Blade
    { 131229, 'TRUE' }, -- Path of the Scarlet Mitre
    { 131232, 'TRUE' }, -- Path of the Necromancer
    { 131228, 'TRUE' }, -- Path of the Black Ox
    { 159895, 'TRUE' }, -- Path of the Bloodmaul
    { 159896, 'TRUE' }, -- Path of the Iron Prow
    { 159897, 'TRUE' }, -- Path of the Vigilant
    { 159898, 'TRUE' }, -- Path of the Skies
    { 159899, 'TRUE' }, -- Path of the Crescent Moon
    { 159900, 'TRUE' }, -- Path of the Dark Rail
    { 159901, 'TRUE' }, -- Path of the Verdant
    { 159902, 'TRUE' }  -- Path of the Burning Mountain
}

local whistle = 141605 -- Flight Master's Whistle

local obj = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {
    type = 'data source',
    text = L['P'],
    icon = 'Interface\\Icons\\INV_Misc_Rune_06',
})
local methods = {}
local portals
local frame = CreateFrame('frame')

frame:SetScript('OnEvent', function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
frame:RegisterEvent('PLAYER_LOGIN')
frame:RegisterEvent('SKILL_LINES_CHANGED')

local function pairsByKeys(t)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a)

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
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function findSpell(spellName)
    local i = 1
    while true do
        local s = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        if not s then
            break
        end

        if s == spellName then
            return i
        end

        i = i + 1
    end
end

-- returns true, if player has item with given ID in inventory or bags and it's not on cooldown
local function hasItem(itemID)
    local item, found, id
    -- scan inventory
    for slotId = 1, 19 do
        item = GetInventoryItemLink('player', slotId)
        if item then
            found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
            if found and tonumber(id) == itemID then
                if GetInventoryItemCooldown('player', slotId) ~= 0 then
                    return false
                else
                    return true
                end
            end
        end
    end
    -- scan bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            item = GetContainerItemLink(bag, slot)
            if item then
                found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
                if found and tonumber(id) == itemID then
                    if GetContainerItemCooldown(bag, slot) ~= 0 then
                        return false
                    else
                        return true
                    end
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
            return true
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
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    count = count + itemCount
                end
            end
        end
    end

    return count
end

local function SetupSpells()
    local spells = {
        Alliance = {
            { 3561, 'TP_RUNE' },   -- TP:Stormwind
            { 3562, 'TP_RUNE' },   -- TP:Ironforge
            { 3565, 'TP_RUNE' },   -- TP:Darnassus
            { 32271, 'TP_RUNE' },  -- TP:Exodar
            { 49359, 'TP_RUNE' },  -- TP:Theramore
            { 33690, 'TP_RUNE' },  -- TP:Shattrath
            { 53140, 'TP_RUNE' },  -- TP:Dalaran
            { 88342, 'TP_RUNE' },  -- TP:Tol Barad
            { 132621, 'TP_RUNE' }, -- TP:Vale of Eternal Blossoms
            { 120145, 'TP_RUNE' }, -- TP:Ancient Dalaran
            { 176248, 'TP_RUNE' }, -- TP:StormShield
            { 224869, 'TP_RUNE' }, -- TP:Dalaran - Broken Isles
            { 193759, 'TP_RUNE' }, -- TP:Hall of the Guardian
            { 281403, 'TP_RUNE' }, -- TP:Boralus
            { 344587, 'TP_RUNE' }, -- TP:Oribos
            { 395277, 'TP_RUNE' }, -- TP:Valdrakken
            { 10059, 'P_RUNE' },   -- P:Stormwind
            { 11416, 'P_RUNE' },   -- P:Ironforge
            { 11419, 'P_RUNE' },   -- P:Darnassus
            { 32266, 'P_RUNE' },   -- P:Exodar
            { 49360, 'P_RUNE' },   -- P:Theramore
            { 33691, 'P_RUNE' },   -- P:Shattrath
            { 53142, 'P_RUNE' },   -- P:Dalaran
            { 88345, 'P_RUNE' },   -- P:Tol Barad
            { 120146, 'P_RUNE' },  -- P:Ancient Dalaran
            { 132620, 'P_RUNE' },  -- P:Vale of Eternal Blossoms
            { 176246, 'P_RUNE' },  -- P:StormShield
            { 224871, 'P_RUNE' },  -- P:Dalaran - Broken Isles
            { 281400, 'P_RUNE' },  -- P:Boralus
            { 344597, 'P_RUNE' },  -- P:Oribos
            { 395289, 'P_RUNE' }   -- P:Valdrakken
        },
        Horde = {
            { 3563, 'TP_RUNE' },   -- TP:Undercity
            { 3566, 'TP_RUNE' },   -- TP:Thunder Bluff
            { 3567, 'TP_RUNE' },   -- TP:Orgrimmar
            { 32272, 'TP_RUNE' },  -- TP:Silvermoon
            { 49358, 'TP_RUNE' },  -- TP:Stonard
            { 35715, 'TP_RUNE' },  -- TP:Shattrath
            { 53140, 'TP_RUNE' },  -- TP:Dalaran
            { 88344, 'TP_RUNE' },  -- TP:Tol Barad
            { 132627, 'TP_RUNE' }, -- TP:Vale of Eternal Blossoms
            { 120145, 'TP_RUNE' }, -- TP:Ancient Dalaran
            { 176242, 'TP_RUNE' }, -- TP:Warspear
            { 224869, 'TP_RUNE' }, -- TP:Dalaran - Broken Isles
            { 193759, 'TP_RUNE' }, -- TP:Hall of the Guardian
            { 281404, 'TP_RUNE' }, -- TP:Dazar'alor
            { 344587, 'TP_RUNE' }, -- TP:Oribos
            { 395277, 'TP_RUNE' }, -- TP:Valdrakken
            { 11418, 'P_RUNE' },   -- P:Undercity
            { 11420, 'P_RUNE' },   -- P:Thunder Bluff
            { 11417, 'P_RUNE' },   -- P:Orgrimmar
            { 32267, 'P_RUNE' },   -- P:Silvermoon
            { 49361, 'P_RUNE' },   -- P:Stonard
            { 35717, 'P_RUNE' },   -- P:Shattrath
            { 53142, 'P_RUNE' },   -- P:Dalaran
            { 88346, 'P_RUNE' },   -- P:Tol Barad
            { 120146, 'P_RUNE' },  -- P:Ancient Dalaran
            { 132626, 'P_RUNE' },  -- P:Vale of Eternal Blossoms
            { 176244, 'P_RUNE' },  -- P:Warspear
            { 224871, 'P_RUNE' },  -- P:Dalaran - Broken Isles
            { 281402, 'P_RUNE' },  -- P:Dazar'alor
            { 344597, 'P_RUNE' },  -- P:Oribos
            { 395289, 'P_RUNE' }   -- P:Valdrakken
        }
    }

    local _, class = UnitClass('player')
    if class == 'MAGE' then
        portals = spells[select(1, UnitFactionGroup('player'))]
    elseif class == 'DEATHKNIGHT' then
        portals = {
            { 50977, 'TRUE' } -- Death Gate
        }
    elseif class == 'DRUID' then
        portals = {
            { 18960,  'TRUE' }, -- TP:Moonglade
            { 147420, 'TRUE' }, -- TP:One with Nature
            { 193753, 'TRUE' }  -- TP:Dreamwalk
        }
    elseif class == 'SHAMAN' then
        portals = {
            { 556, 'TRUE' } -- Astral Recall
        }
    elseif class == 'MONK' then
        portals = {
            { 126892, 'TRUE' }, -- Zen Pilgrimage
            { 126895, 'TRUE' }  -- Zen Pilgrimage: Return
        }
    else
        portals = {}
    end

    local _, race = UnitRace('player')
    if race == 'DarkIronDwarf' then
        table.insert(portals, { 265225, 'TRUE' }) -- Mole Machine
    end

    wipe(spells)
end

local function GenerateLinks(spells)
    local itemsGenerated = 0

    for _, unTransSpell in ipairs(spells) do
        if IsPlayerSpell(unTransSpell[1]) then
            local spell, _, spellIcon = GetSpellInfo(unTransSpell[1])
            local spellid = findSpell(spell)

            if spellid then
                methods[spell] = {
                    spellid = spellid,
                    text = spell,
                    spellIcon = spellIcon,
                    isPortal = unTransSpell[2] == 'P_RUNE',
                    secure = {
                        type = 'spell',
                        spell = spell
                    }
                }
                itemsGenerated = itemsGenerated + 1
            end
        end
    end

    return itemsGenerated
end

local function UpdateClassSpells()
    if not portals then
        SetupSpells()
    end

    if portals then
        return GenerateLinks(portals)
    end
end

local function UpdateChallengeSpells()
    return GenerateLinks(challengeSpells)
end

local function UpdateIcon(icon)
    obj.icon = icon
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
    if GetItemCount(whistle) > 0 then
        startTime, duration = GetItemCooldown(whistle)
        cooldown = duration - (GetTime() - startTime)
        if cooldown <= 0 then
            return L['READY']
        else
            return SecondsToTime(cooldown)
        end
    end
    return L['N/A']
end

local function GetItemCooldowns()
    local cooldown, cooldowns, hours, mins, secs

    for i = 1, #items do
        if GetItemCount(items[i]) > 0 or (PlayerHasToy(items[i]) and C_ToyBox.IsToyUsable(items[i])) then
            startTime, duration = GetItemCooldown(items[i])
            cooldown = duration - (GetTime() - startTime)
            if cooldown <= 0 then
                cooldown = L['READY']
            else
                cooldown = SecondsToTime(cooldown)
            end

            if cooldowns == nil then
                cooldowns = {}
            end

            local name = GetItemInfo(items[i]) or select(2, C_ToyBox.GetToyInfo(items[i]))

            if name then
                cooldowns[name] = cooldown
            end
        end
    end

    return cooldowns
end

local function ShowHearthstone()
    local bindLoc = GetBindLocation()
    local secure, text, icon, name

    for i = 1, #scrolls do
        if hasItem(scrolls[i]) then
            name, _, _, _, _, _, _, _, _, icon = GetItemInfo(scrolls[i])
            text = L['INN'] .. ' ' .. bindLoc
            secure = {
                type = 'item',
                item = name
            }
            break
        end
    end

    if secure ~= nil then
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', text,
            'secure', secure,
            'icon', tostring(icon),
            'func', function() UpdateIcon(icon) end,
            'closeWhenClicked', true)
    end

    local j = 0
    if PortalsDB.showHSItems then
        for i = 1, #heartstones do
            if hasItem(heartstones[i]) then
                name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(heartstones[i])
                secure = {
                    type = 'item',
                    item = name
                }
                dewdrop:AddLine(
                    'textHeight', PortalsDB.fontSize,
                    'text', name,
                    'textR', ITEM_QUALITY_COLORS[quality].r,
                    'textG', ITEM_QUALITY_COLORS[quality].g,
                    'textB', ITEM_QUALITY_COLORS[quality].b,
                    'secure', secure,
                    'icon', tostring(icon),
                    'func', function() UpdateIcon(icon) end,
                    'closeWhenClicked', true)
                j = i
            end
        end
        dewdrop:AddLine()
    end
    if j < 1 then
        dewdrop:AddLine()
    end
end

local function ShowWhistle()
    local secure, icon, name
    if hasItem(whistle) then
        name, _, _, _, _, _, _, _, _, icon = GetItemInfo(whistle)
        secure = {
            type = 'item',
            item = name
        }
    end
    if secure ~= nil then
        dewdrop:AddLine()
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', name,
            'secure', secure,
            'icon', tostring(icon),
            'func', function() UpdateIcon(icon) end,
            'closeWhenClicked', true)
        dewdrop:AddLine()
    end
end

local function ShowOtherItems()
    local secure, icon, quality, name
    local i = 0

    for i = 1, #items do
        if hasItem(items[i]) then
            name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(items[i])
            secure = {
                type = 'item',
                item = name
            }

            dewdrop:AddLine(
                'textHeight', PortalsDB.fontSize,
                'text', name,
                'textR', ITEM_QUALITY_COLORS[quality].r,
                'textG', ITEM_QUALITY_COLORS[quality].g,
                'textB', ITEM_QUALITY_COLORS[quality].b,
                'secure', secure,
                'icon', tostring(icon),
                'func', function() UpdateIcon(icon) end,
                'closeWhenClicked', true)
            i = i + 1
        end
    end
    if i > 0 then
        dewdrop:AddLine()
    end
end

local function ToggleMinimap()
    local hide = not PortalsDB.minimap.hide
    PortalsDB.minimap.hide = hide
    if hide then
        icon:Hide('Broker_Portals')
    else
        icon:Show('Broker_Portals')
    end
end

local function UpdateMenu(level, value)
    dewdrop:SetFontSize(PortalsDB.fontSize)

    if level == 1 then
        dewdrop:AddLine('text', 'Broker_Portals', 'isTitle', true)

        methods = {}
        local spells = UpdateClassSpells()
        if spells > 0 then
          dewdrop:AddLine()
        end
        local challengeSpells = UpdateChallengeSpells()
        if challengeSpells > 0 then
          dewdrop:AddLine()
        end

        local chatType = (UnitInRaid("player") and "RAID") or (GetNumGroupMembers() > 0 and "PARTY") or nil
        local announce = PortalsDB.announce
        for k, v in pairsByKeys(methods) do
            if v.secure and GetSpellCooldown(v.text) == 0 then
                dewdrop:AddLine(
                    'textHeight', PortalsDB.fontSize,
                    'text', v.text,
                    'secure', v.secure,
                    'icon', tostring(v.spellIcon),
                    'func', function()
                        UpdateIcon(v.spellIcon)
                        if announce and v.isPortal and chatType then
                            SendChatMessage(L['ANNOUNCEMENT'] .. ' ' .. v.text, chatType)
                        end
                    end,
                    'closeWhenClicked', true)
            end
        end

        dewdrop:AddLine()

        ShowHearthstone()

        if PortalsDB.showItems then
            ShowOtherItems()
            ShowWhistle()
        end

        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['OPTIONS'],
            'hasArrow', true,
            'value', 'options')

        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', CLOSE,
            'tooltipTitle', CLOSE,
            'tooltipText', CLOSE_DESC,
            'closeWhenClicked', true)
    elseif level == 2 and value == 'options' then
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['SHOW_ITEMS'],
            'checked', PortalsDB.showItems,
            'func', function() PortalsDB.showItems = not PortalsDB.showItems end,
            'closeWhenClicked', true)
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['SHOW_HS_ITEMS'],
            'checked', PortalsDB.showHSItems,
            'func', function() PortalsDB.showHSItems = not PortalsDB.showHSItems end,
            'closeWhenClicked', true)
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['SHOW_ITEM_COOLDOWNS'],
            'checked', PortalsDB.showItemCooldowns,
            'func', function() PortalsDB.showItemCooldowns = not PortalsDB.showItemCooldowns end,
            'closeWhenClicked', true)
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['ATT_MINIMAP'],
            'checked', not PortalsDB.minimap.hide,
            'func', function() ToggleMinimap() end,
            'closeWhenClicked', true)
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['ANNOUNCE'],
            'checked', PortalsDB.announce,
            'func', function() PortalsDB.announce = not PortalsDB.announce end,
            'closeWhenClicked', true)
        dewdrop:AddLine(
            'textHeight', PortalsDB.fontSize,
            'text', L['DROPDOWN_FONT_SIZE'],
            'hasArrow', true,
            'hasEditBox', true,
            'editBoxText', PortalsDB.fontSize,
						'editBoxFunc', function(value)
                       if value ~= '' and tonumber(value) ~= nil then
                           PortalsDB.fontSize = tonumber(value)
                       else
                           PortalsDB.fontSize = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
                       end
                   end)
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
        PortalsDB.announce = false
        PortalsDB.fontSize = UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT
        PortalsDB.version = 5
    end

    -- upgrade from versions
    if PortalsDB.version == 4 then
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

    if icon then
        icon:Register('Broker_Portals', obj, PortalsDB.minimap)
    end

    self:UnregisterEvent('PLAYER_LOGIN')
end

function frame:SKILL_LINES_CHANGED()
    UpdateClassSpells()
    UpdateChallengeSpells()
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
    if button == 'RightButton' then
        dewdrop:Open(self, 'children', function(level, value) UpdateMenu(level, value) end)
    end
end

function obj.OnLeave()
    GameTooltip:Hide()
end

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

    local whistleCooldown = GetWhistleCooldown()
    if whistleCooldown == L['READY'] then
        GameTooltip:AddDoubleLine(GetItemInfo(whistle), whistleCooldown, 0.9, 0.6, 0.2, 0.2, 1, 0.2)
    else
       GameTooltip:AddDoubleLine(GetItemInfo(whistle), whistleCooldown, 0.9, 0.6, 0.2, 1, 1, 0.2)
    end

    GameTooltip:Show()
end

-- slash command definition
SlashCmdList['BROKER_PORTALS'] = function() ToggleMinimap() end
SLASH_BROKER_PORTALS1 = '/portals'
