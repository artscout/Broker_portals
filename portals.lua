if not LibStub then return end

local dewdrop = LibStub('LibDewdrop-3.0', true)
local icon = LibStub('LibDBIcon-1.0')

local _

local CreateFrame = CreateFrame
local C_ToyBox = C_ToyBox
local GetBindLocation = GetBindLocation
local GetContainerItemCooldown = GetContainerItemCooldown
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetContainerNumSlots = GetContainerNumSlots
local GetItemCooldown = GetItemCooldown
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemLink = GetInventoryItemLink
local GetNumGroupMembers = GetNumGroupMembers
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local IsPlayerSpell = IsPlayerSpell
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
    -- Engineering Gadgets
    18984,  -- Dimensional Ripper - Everlook
    18986,  -- Ultrasafe Transporter: Gadgetzan
    30542,  -- Dimensional Ripper - Area 52
    30544,  -- Ultrasafe Transporter: Toshley's Station
    48933,  -- Wormhole Generator: Northrend
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

}

local heartstones = {
    -- items usable instead of hearthstone
    28585,  -- Ruby Slippers
    37118,  -- Scroll of Recall
    44314,  -- Scroll of Recall II
    44315,  -- Scroll of Recall III
    184871  -- Dark Portal
}

local scrolls = {
    6948    -- Hearthstone
}

-- Gold Challenge portals
local challengeSpells = {
}

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
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            item = C_Container.GetContainerItemLink(bag, slot)
            if item then
                found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
                if found and tonumber(id) == itemID then
                    if C_Container.GetContainerItemCooldown(bag, slot) ~= 0 then
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
        startTime, duration = C_Container.GetItemCooldown(itemID)
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
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemLink(bag, slot)
            if item then
                if item:find(name) then
                    itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                    if itemInfo then
                        count = count + itemInfo['stackCount']
                    end
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
            { 10059, 'P_RUNE' },   -- P:Stormwind
            { 11416, 'P_RUNE' },   -- P:Ironforge
            { 11419, 'P_RUNE' },   -- P:Darnassus
            { 32266, 'P_RUNE' },   -- P:Exodar
            { 49360, 'P_RUNE' },   -- P:Theramore
            { 33691, 'P_RUNE' },    -- P:Shattrath
            { 53142, 'P_RUNE' }   -- P:Dalaran
        },
        Horde = {
            { 3563, 'TP_RUNE' },   -- TP:Undercity
            { 3566, 'TP_RUNE' },   -- TP:Thunder Bluff
            { 3567, 'TP_RUNE' },   -- TP:Orgrimmar
            { 32272, 'TP_RUNE' },  -- TP:Silvermoon
            { 49358, 'TP_RUNE' },  -- TP:Stonard
            { 35715, 'TP_RUNE' },  -- TP:Shattrath
            { 53140, 'TP_RUNE' },  -- TP:Dalaran
            { 11418, 'P_RUNE' },   -- P:Undercity
            { 11420, 'P_RUNE' },   -- P:Thunder Bluff
            { 11417, 'P_RUNE' },   -- P:Orgrimmar
            { 32267, 'P_RUNE' },   -- P:Silvermoon
            { 49361, 'P_RUNE' },   -- P:Stonard
            { 35717, 'P_RUNE' },    -- P:Shattrath
            { 53142, 'P_RUNE' }   -- P:Dalaran
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
            { 18960,  'TRUE' } -- TP:Moonglade
        }
    else
        portals = {}
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
        if GetItemCount(scrolls[i]) > 0 then
            startTime, duration = C_Container.GetItemCooldown(scrolls[i])
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

local function GetItemCooldowns()
    local cooldown, cooldowns, hours, mins, secs

    for i = 1, #items do
        if GetItemCount(items[i]) > 0 then
            startTime, duration = C_Container.GetItemCooldown(items[i])
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
    dewdrop:AddLine()
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

    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L["TP_P"], getReagentCount(L["TP_RUNE"]).."/"..getReagentCount(L["P_RUNE"]), 0.9, 0.6, 0.2, 0.2, 1, 0.2)

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

    GameTooltip:Show()
end

-- slash command definition
SlashCmdList['BROKER_PORTALS'] = function() ToggleMinimap() end
SLASH_BROKER_PORTALS1 = '/portals'
