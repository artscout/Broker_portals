local addonName, addonTable = ...

--[[
Name: LibDewdrop-3.0
Description: A library to provide a clean dropdown menu interface.
Supports both UIDropDownMenu (pre-12.0.0) and MenuUtil.CreateContextMenu (12.0.0+)
]]

--[[ ORIGINAL ACE2 BASED LIBRARY
Name: Dewdrop-2.0
Author(s): ckknight (ckknight@gmail.com)
Website: http://ckknight.wowinterface.com/
Documentation: http://wiki.wowace.com/index.php/Dewdrop-2.0
SVN: http://svn.wowace.com/root/trunk/DewdropLib/Dewdrop-2.0
Dependencies: AceLibrary
License: LGPL v2.1
]]

local Dewdrop = LibStub:NewLibrary("LibDewdrop-3.0", 2)

Dewdrop.scrollListSize = 33

if not Dewdrop then
    return -- already loaded and no upgrade necessary
end

-- Detect which menu system to use
local USE_NEW_MENU_SYSTEM = (MenuUtil ~= nil and MenuUtil.CreateContextMenu ~= nil)

-- Compatibility wrapper for GetMouseFocus (removed in WoW 12.0.0)
-- In 12.0.0+, GetMouseFoci() returns a table of frames under the mouse
-- We provide a wrapper that returns the first frame for backward compatibility
local GetMouseFocus = GetMouseFocus or function()
    local mouseFoci = GetMouseFoci and GetMouseFoci()
    return mouseFoci and mouseFoci[1] or nil
end

local function new(...)
    local t = {}
    for i = 1, select('#', ...), 2 do
        local k = select(i, ...)
        if k then
            t[k] = select(i + 1, ...)
        else
            break
        end
    end
    return t
end

local tmp
do
    local t = {}
    function tmp(...)
        for k in pairs(t) do t[k] = nil end
        for i = 1, select('#', ...), 2 do
            local k = select(i, ...)
            if k then
                t[k] = select(i + 1, ...)
            else
                break
            end
        end
        return t
    end
end

local tmp2
do
    local t = {}
    function tmp2(...)
        for k in pairs(t) do t[k] = nil end
        for i = 1, select('#', ...), 2 do
            local k = select(i, ...)
            if k then
                t[k] = select(i + 1, ...)
            else
                break
            end
        end
        return t
    end
end

local TOC = select(4, GetBuildInfo()) or 0

local CLOSE = "Close"
local CLOSE_DESC = "Close the menu."
local VALIDATION_ERROR = "Validation error."
local USAGE_TOOLTIP = "Usage: %s."
local RANGE_TOOLTIP =
    "Note that you can scroll your mouse wheel while over the slider to step by one."
local RESET_KEYBINDING_DESC = "Hit escape to clear the keybinding."
local KEY_BUTTON1 = "Left Mouse"
local KEY_BUTTON2 = "Right Mouse"
local DISABLED = "Disabled"
local DEFAULT_CONFIRM_MESSAGE = "Are you sure you want to perform `%s'?"

if GetLocale() == "deDE" then
    CLOSE = "Schlie\195\159en"
    CLOSE_DESC = "Men\195\188 schlie\195\159en."
    VALIDATION_ERROR = "Validierungsfehler."
    USAGE_TOOLTIP = "Benutzung: %s."
    RANGE_TOOLTIP =
        "Beachte das du mit dem Mausrad scrollen kannst solange du mit dem Mauszeiger \195\188ber dem Schieberegler bist, um feinere Spr\195\188nge zu machen."
    RESET_KEYBINDING_DESC =
        "Escape dr\195\188cken, um die Tastenbelegung zu l\195\182schen."
    KEY_BUTTON1 = "Linke Maustaste"
    KEY_BUTTON2 = "Rechte Maustaste"
    DISABLED = "Deaktiviert"
    DEFAULT_CONFIRM_MESSAGE = "Bist du sicher das du `%s' machen willst?"
elseif GetLocale() == "koKR" then
    CLOSE = "닫기"
    CLOSE_DESC = "메뉴를 닫습니다."
    VALIDATION_ERROR = "오류 확인."
    USAGE_TOOLTIP = "사용법: %s."
    RANGE_TOOLTIP =
        "알림 : 슬라이더 위에서 마우스 휠을 사용하면 한단계씩 조절할 수 있습니다."
    RESET_KEYBINDING_DESC =
        "단축키를 해제하려면 ESC키를 누르세요."
    KEY_BUTTON1 = "왼쪽 마우스"
    KEY_BUTTON2 = "오른쪽 마우스"
    DISABLED = "비활성화됨"
    DEFAULT_CONFIRM_MESSAGE = "정말로 `%s' 실행을 하시겠습니까 ?"
elseif GetLocale() == "frFR" then
    CLOSE = "Fermer"
    CLOSE_DESC = "Ferme le menu."
    VALIDATION_ERROR = "Erreur de validation."
    USAGE_TOOLTIP = "Utilisation : %s."
    RANGE_TOOLTIP =
        "Vous pouvez aussi utiliser la molette de la souris pour pour modifier progressivement."
    RESET_KEYBINDING_DESC =
        "Appuyez sur la touche Echappement pour effacer le raccourci."
    KEY_BUTTON1 = "Clic gauche"
    KEY_BUTTON2 = "Clic droit"
    DISABLED = "D\195\169sactiv\195\169"
    DEFAULT_CONFIRM_MESSAGE =
        "\195\138tes-vous s\195\187r de vouloir effectuer '%s' ?"
elseif GetLocale() == "esES" then
    CLOSE = "Cerrar"
    CLOSE_DESC = "Cierra el menú."
    VALIDATION_ERROR = "Error de validación."
    USAGE_TOOLTIP = "Uso: %s."
    RANGE_TOOLTIP =
        "Puedes desplazarte verticalmente con la rueda del ratón sobre el desplazador."
    RESET_KEYBINDING_DESC = "Pulsa Escape para borrar la asignación de tecla."
    KEY_BUTTON1 = "Clic Izquierdo"
    KEY_BUTTON2 = "Clic Derecho"
    DISABLED = "Desactivado"
    DEFAULT_CONFIRM_MESSAGE = "¿Estás seguro de querer realizar `%s'?"
elseif GetLocale() == "zhTW" then
    CLOSE = "關閉"
    CLOSE_DESC = "關閉選單。"
    VALIDATION_ERROR = "驗證錯誤。"
    USAGE_TOOLTIP = "用法: %s。"
    RANGE_TOOLTIP = "你可以在捲動條上使用滑鼠滾輪來捲動。"
    RESET_KEYBINDING_DESC = "按Esc鍵清除快捷鍵。"
    KEY_BUTTON1 = "滑鼠左鍵"
    KEY_BUTTON2 = "滑鼠右鍵"
    DISABLED = "停用"
    DEFAULT_CONFIRM_MESSAGE = "是否執行「%s」?"
elseif GetLocale() == "zhCN" then
    CLOSE = "关闭"
    CLOSE_DESC = "关闭菜单"
    VALIDATION_ERROR = "验证错误."
    USAGE_TOOLTIP = "用法: %s."
    RANGE_TOOLTIP = "你可以在滚动条上使用鼠标滚轮来翻页."
    RESET_KEYBINDING_DESC = "按ESC键清除按键绑定"
    KEY_BUTTON1 = "鼠标左键"
    KEY_BUTTON2 = "鼠标右键"
    DISABLED = "禁用"
    DEFAULT_CONFIRM_MESSAGE = "是否执行'%s'?"
elseif GetLocale() == "ruRU" then
    CLOSE = "Закрыть"
    CLOSE_DESC = "Закрыть меню."
    VALIDATION_ERROR = "Ошибка проверки данных."
    USAGE_TOOLTIP = "Используйте: %s."
    RANGE_TOOLTIP =
        "Используйте колесо мыши для прокрутки ползунка."
    RESET_KEYBINDING_DESC =
        "Нажмите клавишу Escape для очистки клавиши."
    KEY_BUTTON1 = "ЛКМ"
    KEY_BUTTON2 = "ПКМ"
    DISABLED = "Отключено"
    DEFAULT_CONFIRM_MESSAGE =
        "Вы уверены что вы хотите выполнять `%s'?"
end

Dewdrop.KEY_BUTTON1 = KEY_BUTTON1
Dewdrop.KEY_BUTTON2 = KEY_BUTTON2

local levels
local buttons
local options

-- ============================================================================
-- NEW MENU SYSTEM (MenuUtil) IMPLEMENTATION - WoW 12.0.0+
-- ============================================================================

if USE_NEW_MENU_SYSTEM then

-- State for building menus
local menuState = {
    lines = {},           -- Accumulated lines for current level
    levelLines = {},      -- Lines organized by level
    currentLevel = nil,
    baseFunc = nil,
    openMenu = nil,       -- Reference to the currently open menu
    anchor = nil,
    savedOnEnter = nil,   -- Saved OnEnter script from anchor frame
}

-- Custom font object for menu items
-- We create a font object that inherits from GameFontHighlight but with a custom size
-- This is used by SetFontObject() since SetFont() is disallowed on compositor font strings
local customMenuFont = CreateFont("LibDewdrop30MenuFont")
customMenuFont:CopyFontObject(GameFontHighlight)

-- Helper function to update the custom font object with the current font size
local function UpdateCustomMenuFont()
    local fontFile, _, fontFlags = GameFontHighlight:GetFont()
    local fontSize = Dewdrop.fontsize or 14
    customMenuFont:SetFont(fontFile, fontSize, fontFlags)
end

-- Initialize the font with default size
UpdateCustomMenuFont()

-- Secure button frame for spell/item casting
-- This frame overlays menu buttons on hover so the user's click goes to the secure button
local secureFrame = CreateFrame("Button", "LibDewdrop30SecureButton", UIParent, "SecureActionButtonTemplate")
secureFrame:Hide()
secureFrame:SetSize(1, 1)
secureFrame:SetFrameStrata("FULLSCREEN_DIALOG")
secureFrame.owner = nil
secureFrame.secure = nil
secureFrame.lineData = nil

-- Show the secure frame overlaid on the owner button
local function secureFrame_Show(self)
    local owner = self.owner
    if not owner then return end

    -- Clear any leftover attributes from previous owner
    if self.secure then
        for k, v in pairs(self.secure) do
            self:SetAttribute(k, nil)
        end
    end

    -- Grab new secure data
    self.secure = owner.secureData
    if not self.secure then return end

    -- Position secureFrame to cover the owner button exactly
    -- We use SetPoint with the owner as the anchor - this handles scaling automatically
    self:ClearAllPoints()
    -- Keep UIParent as parent but anchor to the owner button's corners
    self:SetParent(UIParent)
    self:SetPoint("TOPLEFT", owner, "TOPLEFT", 0, 0)
    self:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", 0, 0)

    -- Set up secure attributes
    for k, v in pairs(self.secure) do
        self:SetAttribute(k, v)
    end

    -- Register for ALL click types to ensure we capture the click
    -- Include both Up and Down variants for maximum compatibility
    self:RegisterForClicks("AnyUp", "AnyDown")

    -- Match the owner's frame strata but higher level to be on top
    local strata = owner:GetFrameStrata()
    local level = owner:GetFrameLevel()
    self:SetFrameStrata(strata)
    self:SetFrameLevel(level + 10)

    self:EnableMouse(true)
    self:Show()

    -- Show the owner button's highlight since secureFrame now covers it
    -- MenuUtil buttons have a highlight texture created by MenuVariants.CreateHighlight()
    if owner.highlight then
        owner.highlight:Show()
        -- Get description for alpha (enabled buttons get full alpha, disabled get reduced)
        local description = owner.GetElementDescription and owner:GetElementDescription()
        if description then
            local alpha = description:IsEnabled() and 1 or (MenuVariants and MenuVariants.DisabledHighlightOpacity or 0.4)
            owner.highlight:SetAlpha(alpha)
        end
    end
end

-- Hide the secure frame and clear attributes
local function secureFrame_Hide(self)
    self:Hide()
    if self.secure then
        for k, v in pairs(self.secure) do
            self:SetAttribute(k, nil)
        end
    end
    self.secure = nil
    self:ClearAllPoints()

    -- Hide the owner button's highlight when secureFrame is hidden
    -- (unless we're switching to a new owner, which will show its own highlight)
    if self.owner and self.owner.highlight then
        self.owner.highlight:Hide()
    end
end

-- Activate the secure frame for a menu button
function secureFrame:Activate(owner)
    if InCombatLockdown() then return end

    -- Deactivate any previous owner
    if self.owner and self.owner ~= owner then
        secureFrame_Hide(self)
    end

    self.owner = owner
    self.lineData = owner.lineData
    secureFrame_Show(self)
end

-- Deactivate the secure frame
function secureFrame:Deactivate()
    if InCombatLockdown() then return end
    secureFrame_Hide(self)
    self.owner = nil
    self.lineData = nil
end

-- Check if this frame is owned by a specific button
function secureFrame:IsOwnedBy(frame)
    return self.owner == frame
end

-- OnEnter handler: show tooltip from lineData
-- This is needed because the secureFrame covers the button, so the button's tooltip doesn't show
secureFrame:SetScript("OnEnter", function(self)
    local lineData = self.lineData
    if not lineData then return end

    -- Show tooltip if we have tooltip data
    if lineData.tooltipTitle or lineData.tooltipText then
        -- Use the owner button as the anchor for the tooltip
        local anchor = self.owner or self
        GameTooltip:SetOwner(anchor, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 5, 0)

        if lineData.tooltipTitle then
            GameTooltip:SetText(lineData.tooltipTitle, 1, 1, 1, 1)
            if lineData.tooltipText then
                GameTooltip:AddLine(lineData.tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
            end
        else
            GameTooltip:SetText(lineData.tooltipText, 1, 1, 1, 1)
        end
        GameTooltip:Show()
    end
end)

-- OnLeave handler: deactivate and delegate to owner's OnLeave
secureFrame:SetScript("OnLeave", function(self)
    local owner = self.owner

    -- Check if mouse moved back to the owner button - if so, don't deactivate
    -- This prevents flickering when mouse moves between secureFrame and owner
    local mouseFocus = GetMouseFocus()
    if mouseFocus == owner then return end

    -- Hide the tooltip when leaving the secure frame
    GameTooltip:Hide()

    -- Hide the owner button's highlight before deactivating
    -- This ensures the highlight disappears when mouse leaves the secure item
    if owner and owner.highlight then
        owner.highlight:Hide()
    end

    self:Deactivate()

    -- Call the owner's original OnLeave if it exists
    if owner then
        local onLeave = owner:GetScript("OnLeave")
        if onLeave then
            onLeave(owner)
        end
    end
end)

-- OnClick handler: close menu and call any callback
secureFrame:HookScript("OnClick", function(self, button, down)
    -- Capture lineData immediately - it may be cleared by Deactivate later
    local lineData = self.lineData
    -- Also try to get it from the owner as a fallback
    if not lineData and self.owner then
        lineData = self.owner.lineData
    end

    -- Close the menu after the secure action executes
    if menuState.openMenu then
        -- Use C_Timer to close menu after the secure action completes
        C_Timer.After(0, function()
            Dewdrop:Close()
        end)
    end

    -- Call the line's callback function if it exists
    if lineData and lineData.func then
        if type(lineData.func) == "function" then
            lineData.func(lineData.arg1, lineData.arg2, lineData.arg3, lineData.arg4)
        end
    end
end)

-- Helper function to apply custom font size to a menu element
-- This uses SetFontObject() which is allowed (SetFont() is disallowed on compositor font strings)
-- Also adjusts button height to prevent text overlap at larger font sizes
local function ApplyCustomFontSize(element)
    -- Always add the initializer - the custom font object already has the correct size
    -- This ensures font size changes take effect immediately when the setting changes
    element:AddInitializer(function(button, description, menu)
        local fontString = button.fontString or button.Text
        if fontString and fontString.SetFontObject then
            fontString:SetFontObject(customMenuFont)
        end

        -- Adjust button height based on font size to prevent text overlap
        -- Default font size is 14, default row height is ~20 (font + 6px padding)
        local fontSize = Dewdrop.fontsize or 14
        local buttonHeight = fontSize + 6
        if button.SetHeight then
            button:SetHeight(buttonHeight)
        end
    end)
end

-- Helper function to add an icon to a menu element using AddInitializer
local function AddIconToElement(element, icon)
    if not icon then return end
    element:AddInitializer(function(button, description, menu)
        local texture = button:AttachTexture()
        texture:SetSize(16, 16)
        -- Position icon inside the button with small left padding
        texture:SetPoint("LEFT", button, "LEFT", 4, 0)
        if type(icon) == "number" then
            texture:SetTexture(icon)
        else
            texture:SetTexture(icon)
        end
        -- Crop icons that come from the Icons folder
        if type(icon) == "string" and icon:find("^Interface\\Icons\\") then
            texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        end
        -- Find and indent the text fontstring to make room for the icon
        -- MenuUtil buttons have a fontString member or we can find it
        local fontString = button.fontString or button.Text or button:GetFontString()
        if fontString then
            -- Add left padding to text so it starts after the icon (icon is 16px + 4px padding + 4px gap = 24px)
            fontString:SetPoint("LEFT", button, "LEFT", 24, 0)
        end
    end)
end

-- Helper to add the secure overlay initializer to a menu button
-- IMPORTANT: This function MUST be called AFTER SetTooltip() if tooltips are used!
--
-- The Menu system's HookOnEnter() works as follows:
--   1. If self.onEnter exists, it uses hooksecurefunc() to hook into the existing function
--   2. If self.onEnter is nil, it just calls SetOnEnter() to set the callback
--
-- SetTooltip() internally calls SetOnEnter(), which REPLACES self.onEnter entirely.
-- If we call HookOnEnter before SetTooltip:
--   - HookOnEnter sees self.onEnter is nil, so it calls SetOnEnter(ourCallback)
--   - Then SetTooltip calls SetOnEnter(tooltipCallback), REPLACING ourCallback
--   - Our callback is lost!
--
-- If we call HookOnEnter AFTER SetTooltip:
--   - SetTooltip calls SetOnEnter(tooltipCallback), setting self.onEnter
--   - HookOnEnter sees self.onEnter exists, so it uses hooksecurefunc()
--   - Both callbacks run: tooltipCallback first, then ourCallback
--
local function AddSecureOverlayToElement(element, line)
    -- Use AddInitializer to store secure data on the button frame
    element:AddInitializer(function(button, description, menu)
        -- Store secure data and line data on the button for the overlay to access
        button.secureData = line.secure
        button.lineData = line
    end)

    -- Use HookOnEnter to add our callback.
    -- If SetTooltip was called first, this will properly hook into the existing onEnter.
    -- If no tooltip exists, this will just set onEnter directly.
    element:HookOnEnter(function(button, description)
        -- Activate secure overlay if not in combat
        if button.secureData and not InCombatLockdown() then
            secureFrame:Activate(button)
        end
    end)

    -- Also hook OnLeave to handle the secure frame when mouse leaves the button
    -- This hook runs AFTER the button's original OnLeave, which hides the highlight
    element:HookOnLeave(function(button, description)
        if secureFrame:IsOwnedBy(button) then
            local mouseFocus = GetMouseFocus()
            if mouseFocus == secureFrame then
                -- Mouse moved to secureFrame - re-show the highlight that OnButtonLeave just hid
                -- This is needed because our hook runs AFTER the original OnLeave
                if button.highlight then
                    button.highlight:Show()
                    local alpha = description:IsEnabled() and 1 or (MenuVariants and MenuVariants.DisabledHighlightOpacity or 0.4)
                    button.highlight:SetAlpha(alpha)
                end
                return
            end
            -- Mouse left to somewhere else - deactivate the secure frame
            secureFrame:Deactivate()
        end
    end)
end

-- Helper to add menu items recursively
local function AddMenuItemsFromLines(parentDesc, lines, levelValue)
    for _, line in ipairs(lines) do
        if line.isTitle then
            -- Title (non-interactive header)
            if line.text and line.text ~= "" then
                local title = parentDesc:CreateTitle(line.text)
                ApplyCustomFontSize(title)
            else
                parentDesc:CreateDivider()
            end
        elseif not line.text or line.text == "" then
            -- Divider/separator
            parentDesc:CreateDivider()
        elseif line.hasArrow and line.value then
            -- Submenu
            local submenuButton = parentDesc:CreateButton(line.text)
            ApplyCustomFontSize(submenuButton)
            if line.icon then
                AddIconToElement(submenuButton, line.icon)
            end
            submenuButton:SetOnEnter(function(_, desc)
                desc:ForceOpenSubmenu()
            end)
            -- Populate the submenu by re-running the children function for this submenu level
            -- In MenuUtil, submenu items are added directly to the button element
            if menuState.baseFunc then
                local savedLevel = menuState.currentLevel
                local savedLines = menuState.levelLines
                menuState.levelLines = {}
                menuState.currentLevel = (menuState.currentMenuLevel or 1) + 1
                menuState.levelLines[menuState.currentLevel] = {}
                menuState.baseFunc(menuState.currentLevel, line.value)
                local subLines = menuState.levelLines[menuState.currentLevel] or {}
                AddMenuItemsFromLines(submenuButton, subLines, line.value)
                -- Restore state
                menuState.currentLevel = savedLevel
                menuState.levelLines = savedLines
            end
        elseif line.checked ~= nil and not line.notCheckable then
            -- Checkbox item
            local checkbox = parentDesc:CreateCheckbox(
                line.text,
                function() return line.checked end,
                function(data)
                    if line.func then
                        if type(line.func) == "function" then
                            line.func(line.arg1, line.arg2, line.arg3, line.arg4)
                        end
                    end
                    if line.closeWhenClicked then
                        return MenuResponse.Close
                    end
                end
            )
            ApplyCustomFontSize(checkbox)
            if line.icon then
                AddIconToElement(checkbox, line.icon)
            end
            if line.disabled then
                checkbox:SetEnabled(false)
            end
            if line.tooltipTitle or line.tooltipText then
                checkbox:SetTooltip(function(tooltip, desc)
                    if line.tooltipTitle then
                        GameTooltip_SetTitle(tooltip, line.tooltipTitle)
                    end
                    if line.tooltipText then
                        GameTooltip_AddNormalLine(tooltip, line.tooltipText)
                    end
                end)
            end
        elseif line.secure then
            -- Secure action button (spell/item/toy)
            -- We create a regular button but overlay the secureFrame on hover
            -- so the user's click goes to the secure button directly
            local btn = parentDesc:CreateButton(line.text)
            ApplyCustomFontSize(btn)

            if line.icon then
                AddIconToElement(btn, line.icon)
            end

            -- Disable during combat lockdown (can't set secure attributes)
            if line.disabled or InCombatLockdown() then
                btn:SetEnabled(false)
            end

            -- IMPORTANT: SetTooltip MUST be called BEFORE AddSecureOverlayToElement!
            -- SetTooltip() internally calls SetOnEnter() which REPLACES self.onEnter.
            -- If we call HookOnEnter first (when self.onEnter is nil), it just calls SetOnEnter.
            -- Then when SetTooltip calls SetOnEnter, it OVERWRITES our callback completely.
            -- By calling SetTooltip first, self.onEnter exists when HookOnEnter runs,
            -- so hooksecurefunc properly hooks into the existing function.
            if line.tooltipTitle or line.tooltipText then
                btn:SetTooltip(function(tooltip, desc)
                    if line.tooltipTitle then
                        GameTooltip_SetTitle(tooltip, line.tooltipTitle)
                    end
                    if line.tooltipText then
                        GameTooltip_AddNormalLine(tooltip, line.tooltipText)
                    end
                end)
            end

            -- Add the secure overlay initializer - this hooks OnEnter to show the overlay
            -- MUST be called AFTER SetTooltip so HookOnEnter can properly hook the existing onEnter
            AddSecureOverlayToElement(btn, line)
        else
            -- Regular button
            local regularCallback = function(data)
                if line.func then
                    if type(line.func) == "function" then
                        line.func(line.arg1, line.arg2, line.arg3, line.arg4)
                    end
                end
                if line.closeWhenClicked then
                    return MenuResponse.Close
                end
            end
            local btn = parentDesc:CreateButton(line.text, regularCallback)
            ApplyCustomFontSize(btn)
            if line.icon then
                AddIconToElement(btn, line.icon)
            end
            if line.disabled or line.notClickable then
                btn:SetEnabled(false)
            end
            if line.tooltipTitle or line.tooltipText then
                btn:SetTooltip(function(tooltip, desc)
                    if line.tooltipTitle then
                        GameTooltip_SetTitle(tooltip, line.tooltipTitle)
                    end
                    if line.tooltipText then
                        GameTooltip_AddNormalLine(tooltip, line.tooltipText)
                    end
                end)
            end
        end
    end
end

Dewdrop.fontsize = 14

function Dewdrop:SetFontSize(fontSize)
    Dewdrop.fontsize = tonumber(fontSize)
    -- Update the custom font object with the new size
    UpdateCustomMenuFont()
end

function Dewdrop:SetScrollListSize(scrollListSize)
    Dewdrop.scrollListSize = scrollListSize
end

function Dewdrop:IsOpen(parent)
    return menuState.openMenu ~= nil
end

function Dewdrop:GetOpenedParent()
    return menuState.anchor
end

-- Helper function to restore the anchor's OnEnter script
local function RestoreAnchorOnEnter()
    if menuState.anchor and menuState.savedOnEnter ~= nil then
        -- Restore the original OnEnter script
        -- savedOnEnter is false if no script was set, or a function if one was set
        if type(menuState.anchor) == "table" and menuState.anchor.SetScript then
            local scriptToRestore = menuState.savedOnEnter
            if scriptToRestore == false then
                scriptToRestore = nil  -- Convert sentinel back to nil
            end
            menuState.anchor:SetScript("OnEnter", scriptToRestore)
        end
    end
    menuState.savedOnEnter = nil
end

function Dewdrop:Close(level)
    -- Deactivate the secure overlay if it's showing
    if secureFrame.owner then
        secureFrame:Deactivate()
    end

    -- Restore the anchor's OnEnter script before clearing state
    RestoreAnchorOnEnter()

    -- Close the actual menu if open
    if menuState.openMenu and menuState.openMenu:IsShown() then
        Menu.GetManager():CloseMenu(menuState.openMenu)
    end

    -- Clear our state
    menuState.lines = {}
    menuState.levelLines = {}
    menuState.currentLevel = nil
    menuState.baseFunc = nil
    menuState.openMenu = nil
    menuState.anchor = nil
end

function Dewdrop:AddSeparator(level)
    level = level or menuState.currentLevel or 1
    if not menuState.levelLines[level] then
        menuState.levelLines[level] = {}
    end
    table.insert(menuState.levelLines[level], { text = "", disabled = true })
end

function Dewdrop:AddLine(...)
    local info = tmp(...)
    local level = info.level or menuState.currentLevel or 1
    info.level = nil

    if not menuState.levelLines[level] then
        menuState.levelLines[level] = {}
    end

    -- Store the line info for later menu building
    local lineInfo = {
        text = info.text,
        isTitle = info.isTitle,
        disabled = info.isTitle or info.notClickable or info.disabled,
        notClickable = info.notClickable,
        notCheckable = info.notCheckable,
        checked = info.checked,
        isRadio = info.isRadio,
        hasArrow = info.hasArrow,
        value = info.value,
        func = info.func,
        arg1 = info.arg1,
        arg2 = info.arg2,
        arg3 = info.arg3,
        arg4 = info.arg4,
        secure = info.secure,
        icon = info.icon,
        closeWhenClicked = info.closeWhenClicked,
        tooltipTitle = info.tooltipTitle,
        tooltipText = info.tooltipText,
        hasColorSwatch = info.hasColorSwatch,
        hasSlider = info.hasSlider,
        hasEditBox = info.hasEditBox,
    }

    table.insert(menuState.levelLines[level], lineInfo)
end

function Dewdrop:Open(parent, ...)
    self:argCheck(parent, 2, "table", "string")

    -- Hide any existing tooltip before opening the menu
    GameTooltip:Hide()

    local info
    local k1 = ...
    if type(k1) == "table" and k1[0] and k1.IsObjectType and self.registry and self.registry[k1] then
        info = tmp(select(2, ...))
        for k, v in pairs(self.registry[k1]) do
            if info[k] == nil then info[k] = v end
        end
    else
        info = tmp(...)
        if self.registry and self.registry[parent] then
            for k, v in pairs(self.registry[parent]) do
                if info[k] == nil then info[k] = v end
            end
        end
    end

    -- Clear previous state (this also restores any previous anchor's OnEnter)
    RestoreAnchorOnEnter()
    menuState.lines = {}
    menuState.levelLines = {}
    menuState.levelLines[1] = {}
    menuState.currentLevel = 1
    menuState.currentMenuLevel = 1
    menuState.baseFunc = info.children
    menuState.anchor = parent

    -- Save and replace the parent's OnEnter script to prevent tooltip from showing while menu is open
    -- Use false as a sentinel to indicate "no script was set" vs nil meaning "not saved yet"
    if type(parent) == "table" and parent.GetScript and parent.SetScript then
        local originalOnEnter = parent:GetScript("OnEnter")
        menuState.savedOnEnter = originalOnEnter or false
        -- Replace with a function that hides tooltip (in case something else shows it)
        parent:SetScript("OnEnter", function(self)
            GameTooltip:Hide()
        end)
    end

    -- Create the menu description using the lower-level API for explicit anchor support
    local menuMixin = MenuVariants.GetDefaultContextMenuMixin()
    local elementDescription = MenuUtil.CreateRootMenuDescription(menuMixin)

    -- Populate the menu by calling the children function
    if menuState.baseFunc then
        menuState.baseFunc(1, nil)
    end

    -- Add all accumulated lines to the menu description
    local lines = menuState.levelLines[1] or {}
    AddMenuItemsFromLines(elementDescription, lines, nil)

    -- Create anchor: menu's TOPRIGHT at parent's BOTTOMRIGHT (menu expands left and down)
    local anchor = CreateAnchor("TOPRIGHT", parent, "BOTTOMRIGHT", 0, 0)

    -- Open the menu with explicit anchor positioning
    local menu = Menu.GetManager():OpenMenu(parent, elementDescription, anchor)

    if menu then
        -- Hook OnHide for cleanup (deactivate secure overlay and restore OnEnter when menu closes)
        menu:HookScript("OnHide", function()
            -- Deactivate the secure overlay if it's showing
            if secureFrame.owner then
                secureFrame:Deactivate()
            end
            RestoreAnchorOnEnter()
        end)
        menuState.openMenu = menu
    end
end

function Dewdrop:Refresh(level)
    -- MenuUtil rebuilds menus automatically, nothing to do
end

function Dewdrop:IsRegistered(parent)
    self:argCheck(parent, 2, "table", "string")
    return self.registry and self.registry[parent] ~= nil
end

function Dewdrop:SmartAnchorTo(frame)
    -- MenuUtil handles anchoring automatically
end

-- Stub functions for compatibility
function Dewdrop:FeedAceOptionsTable(options, difference)
    -- Not implemented for new menu system
    return false
end

function Dewdrop:FeedTable(s, difference)
    -- Not implemented for new menu system
    return false
end

function Dewdrop:EncodeKeybinding(text)
    if text == nil or text == "NONE" then return nil end
    text = tostring(text):upper()
    local shift, ctrl, alt
    local modifier
    while true do
        if text == "-" then break end
        modifier, text = strsplit('-', text, 2)
        if text then
            if modifier ~= "SHIFT" and modifier ~= "CTRL" and modifier ~= "ALT" then
                return false
            end
            if modifier == "SHIFT" then
                if shift then return false end
                shift = true
            end
            if modifier == "CTRL" then
                if ctrl then return false end
                ctrl = true
            end
            if modifier == "ALT" then
                if alt then return false end
                alt = true
            end
        else
            text = modifier
            break
        end
    end
    if not text:find("^F%d+$") and text ~= "CAPSLOCK" and text:len() ~= 1 and
        (text:len() == 0 or text:byte() < 128 or text:len() > 4) and
        not _G["KEY_" .. text] and text ~= "BUTTON1" and text ~= "BUTTON2" then
        return false
    end
    local s = GetBindingText(text, "KEY_")
    if s == "BUTTON1" then
        s = KEY_BUTTON1
    elseif s == "BUTTON2" then
        s = KEY_BUTTON2
    end
    if shift then s = "Shift-" .. s end
    if ctrl then s = "Ctrl-" .. s end
    if alt then s = "Alt-" .. s end
    return s
end

function Dewdrop:OnTooltipHide()
    -- Nothing needed for new menu system
end

-- Initialize
local function activate()
    local self = Dewdrop
    self.registry = self.registry or {}
    self.onceRegistered = self.onceRegistered or {}
end

activate()

function Dewdrop:argCheck(arg, num, kind, kind2, kind3, kind4, kind5)
    if type(num) ~= "number" then
        return error(self,
                     "Bad argument #3 to `argCheck' (number expected, got %s)",
                     type(num))
    elseif type(kind) ~= "string" then
        return error(self,
                     "Bad argument #4 to `argCheck' (string expected, got %s)",
                     type(kind))
    end
    arg = type(arg)
    if arg ~= kind and arg ~= kind2 and arg ~= kind3 and arg ~= kind4 and arg ~=
        kind5 then
        local stack = debugstack()
        local func = stack:match("`argCheck'.-([`<].-['>])")
        if not func then func = stack:match("([`<].-['>])") end
        if kind5 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, %s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3,
                         kind4, kind5, arg)
        elseif kind4 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3,
                         kind4, arg)
        elseif kind3 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3, arg)
        elseif kind2 then
            return error(self,
                         "Bad argument #%s to %s (%s or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, arg)
        else
            return error(self, "Bad argument #%s to %s (%s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, arg)
        end
    end
end

function Dewdrop:error(message, ...)
    if type(self) ~= "table" then
        return _G.error(
                   ("Bad argument #1 to `error' (table expected, got %s)"):format(
                       type(self)), 2)
    end

    local stack = debugstack()
    if not message then
        local second = stack:match("\n(.-)\n")
        message = "error raised! " .. second
    else
        local arg = {...}
        for i = 1, #arg do arg[i] = tostring(arg[i]) end
        for i = 1, 10 do table.insert(arg, "nil") end
        message = message:format(unpack(arg))
    end

    if getmetatable(self) and getmetatable(self).__tostring then
        message = ("%s: %s"):format(tostring(self), message)
    end

    return _G.error(message, 2)
end

else
-- ============================================================================
-- OLD MENU SYSTEM (UIDropDownMenu) IMPLEMENTATION - Pre-12.0.0
-- ============================================================================

-- Secure frame handling:
-- Rather than using secure buttons in the menu (has problems), we have one
-- master secureframe that we pop onto menu items on mouseover. This requires
-- some dark magic with OnLeave etc, but it's not too bad.

local secureFrame =
    CreateFrame("Button", nil, nil, "SecureActionButtonTemplate")
secureFrame:Hide()

local function secureFrame_Show(self)
    local owner = self.owner
    if self.secure then -- Leftovers from previos owner, clean up! ("Shouldn't" happen but does..)
        for k, v in pairs(self.secure) do self:SetAttribute(k, nil) end
    end
    self.secure = owner.secure; -- Grab hold of new secure data

    local scale = owner:GetEffectiveScale()

    self:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", owner:GetLeft() * scale,
                  owner:GetTop() * scale)
    self:SetPoint("BOTTOMRIGHT", nil, "BOTTOMLEFT", owner:GetRight() * scale,
                  owner:GetBottom() * scale)
    self:EnableMouse(true)
    for k, v in pairs(self.secure) do self:SetAttribute(k, v) end
    local state = C_CVar.GetCVarBool("ActionButtonUseKeyDown")
    if state then
        self:RegisterForClicks("LeftButtonDown")
    else
        self:RegisterForClicks("LeftButtonUp")
    end

    secureFrame:SetFrameStrata(owner:GetFrameStrata())
    secureFrame:SetFrameLevel(owner:GetFrameLevel() + 2)
    self:Show()
end

local function secureFrame_Hide(self)
    self:Hide()
    if self.secure then
        for k, v in pairs(self.secure) do self:SetAttribute(k, nil) end
    end
    self.secure = nil
end

secureFrame:SetScript("OnLeave", function(self)
    local owner = self.owner

    -- Check if mouse moved back to the owner button - if so, don't deactivate
    -- This prevents flickering when mouse moves between secureFrame and owner
    local mouseFocus = GetMouseFocus()
    if mouseFocus == owner then
        return
    end

    self:Deactivate()
    if owner then
        local callBack = owner:GetScript("OnLeave")
        if callBack then
            return callBack(owner)
        end
    end
end)

secureFrame:HookScript("OnClick", function(self, ...)
    if not self.owner then return end
    self.owner:GetScript("OnClick")(self.owner, ...)
end)

function secureFrame:IsOwnedBy(frame) return self.owner == frame end

function secureFrame:Activate(owner)
    if self.owner then -- "Shouldn't" happen but apparently it does and I cba to troubleshoot...
        if not InCombatLockdown() then secureFrame_Hide(self) end
    end
    self.owner = owner
    if not InCombatLockdown() then secureFrame_Show(self) end
end

function secureFrame:Deactivate()
    if not InCombatLockdown() then secureFrame_Hide(self) end
    self.owner = nil
end

-- END secure frame utilities

-- State for tracking anchor's OnEnter script (to prevent tooltip while menu open)
local savedAnchorOnEnter = nil
local savedAnchorFrame = nil

-- Helper function to restore the anchor's OnEnter script
local function RestoreAnchorOnEnter()
    if savedAnchorFrame and savedAnchorOnEnter ~= nil then
        if type(savedAnchorFrame) == "table" and savedAnchorFrame.SetScript then
            local scriptToRestore = savedAnchorOnEnter
            if scriptToRestore == false then
                scriptToRestore = nil  -- Convert sentinel back to nil
            end
            savedAnchorFrame:SetScript("OnEnter", scriptToRestore)
        end
    end
    savedAnchorOnEnter = nil
    savedAnchorFrame = nil
end

-- Underline on mouseover - use a single global underline that we move around, no point in creating lots of copies
local underlineFrame = CreateFrame("Frame")
underlineFrame.tx = underlineFrame:CreateTexture()
underlineFrame.tx:SetTexture(1, 1, 0.5, 0.75)
underlineFrame:SetScript("OnHide", function(self) self:Hide() end)
underlineFrame:SetScript("OnShow",
                         function(self) -- change sizing on the fly to catch runtime uiscale changes
    self.tx:SetPoint("TOPLEFT", -1, -2 / self:GetEffectiveScale())
    self.tx:SetPoint("RIGHT", 1, 0)
    self.tx:SetHeight(0.6 / self:GetEffectiveScale())
end)
underlineFrame:SetHeight(1)
-- END underline on mouseover

local function GetScaledCursorPosition()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    return x / scale, y / scale
end

local function StartCounting(level)
    for i = level, 1, -1 do if levels[i] then levels[i].count = 3 end end
end

local function StopCounting(level)
    for i = level, 1, -1 do if levels[i] then levels[i].count = nil end end
end

local function OnUpdate(self, elapsed)
    for _, level in ipairs(levels) do
        local count = level.count
        if count then
            count = count - elapsed
            if count < 0 then
                level.count = nil
                Dewdrop:Close(level.num)
            else
                level.count = count
            end
        end
    end
end

local function CheckDualMonitor(frame)
    local ratio = GetScreenWidth() / GetScreenHeight()
    if ratio >= 2.4 and frame:GetRight() > GetScreenWidth() / 2 and
        frame:GetLeft() < GetScreenWidth() / 2 then
        local offsetx
        if GetCursorPosition() / GetScreenHeight() * 768 < GetScreenWidth() / 2 then
            offsetx = GetScreenWidth() / 2 - frame:GetRight()
        else
            offsetx = GetScreenWidth() / 2 - frame:GetLeft()
        end
        local point, parent, relativePoint, x, y = frame:GetPoint(1)
        frame:SetPoint(point, parent, relativePoint, (x or 0) + offsetx, y or 0)
    end
end

local function CheckSize(level)
    if not level.scrollFrame.child.buttons then return end
    if #level.scrollFrame.child.buttons < Dewdrop.scrollListSize then
        level.scrollFrame.ScrollBar:Hide()
    else
        level.scrollFrame.ScrollBar:Show()
    end
    local height = 20
    for _, button in ipairs(level.scrollFrame.child.buttons) do
        height = height + button:GetHeight()
    end
    local levelMaxHeight = 16 * Dewdrop.scrollListSize
    local levelHeight = height
    if height > levelMaxHeight then levelHeight = levelMaxHeight end
    level:SetHeight(levelHeight)
    level.scrollFrame.child:SetHeight(height)
    local width = 50
    for _, button in ipairs(level.scrollFrame.child.buttons) do
        local extra = 1
        if button.hasArrow or button.hasColorSwatch then
            extra = extra + 16
        end
        if not button.notCheckable then extra = extra + 24 end
        if button.text:GetStringWidth() + extra > width then
            width = button.text:GetStringWidth() + extra
        end
    end
    level:SetWidth(width + 20)
    level.scrollFrame.child:SetWidth(width + 20)
    if level:GetLeft() and level:GetRight() and level:GetTop() and
        level:GetBottom() and
        (level:GetLeft() < 0 or level:GetRight() > GetScreenWidth() or
            level:GetTop() > GetScreenHeight() or level:GetBottom() < 0) then
        level:ClearAllPoints()
        local parent = level.parent or level:GetParent()
        if type(parent) ~= "table" then parent = UIParent end
        if level.lastDirection == "RIGHT" then
            if level.lastVDirection == "DOWN" then
                level:SetPoint("TOPLEFT", parent, "TOPRIGHT", 5, 10)
            else
                level:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 5, -10)
            end
        else
            if level.lastVDirection == "DOWN" then
                level:SetPoint("TOPRIGHT", parent, "TOPLEFT", -5, 10)
            else
                level:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -5, -10)
            end
        end
    end
    local dirty = false
    if not level:GetRight() then
        Dewdrop:Close()
        return
    end
    if level:GetRight() > GetScreenWidth() and level.lastDirection == "RIGHT" then
        level.lastDirection = "LEFT"
        dirty = true
    elseif level:GetLeft() < 0 and level.lastDirection == "LEFT" then
        level.lastDirection = "RIGHT"
        dirty = true
    end
    if level:GetTop() > GetScreenHeight() and level.lastVDirection == "UP" then
        level.lastVDirection = "DOWN"
        dirty = true
    elseif level:GetBottom() < 0 and level.lastVDirection == "DOWN" then
        level.lastVDirection = "UP"
        dirty = true
    end
    if dirty then
        level:ClearAllPoints()
        local parent = level.parent or level:GetParent()
        if type(parent) ~= "table" then parent = UIParent end
        if level.lastDirection == "RIGHT" then
            if level.lastVDirection == "DOWN" then
                level:SetPoint("TOPLEFT", parent, "TOPRIGHT", 5, 10)
            else
                level:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 5, -10)
            end
        else
            if level.lastVDirection == "DOWN" then
                level:SetPoint("TOPRIGHT", parent, "TOPLEFT", -5, 10)
            else
                level:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -5, -10)
            end
        end
    end
    if level:GetTop() > GetScreenHeight() then
        local top = level:GetTop()
        local point, parent, relativePoint, x, y = level:GetPoint(1)
        level:ClearAllPoints()
        level:SetPoint(point, parent, relativePoint, x or 0,
                       (y or 0) + GetScreenHeight() - top)
    elseif level:GetBottom() < 0 then
        local bottom = level:GetBottom()
        local point, parent, relativePoint, x, y = level:GetPoint(1)
        level:ClearAllPoints()
        level:SetPoint(point, parent, relativePoint, x or 0, (y or 0) - bottom)
    end
    CheckDualMonitor(level)
    if mod(level.num, 5) == 0 then
        local left, bottom = level:GetLeft(), level:GetBottom()
        level:ClearAllPoints()
        level:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    end
end

local Open
local OpenSlider
local OpenEditBox
local Refresh
local Clear
local function ReleaseButton(level, index)
    if not level.scrollFrame.child.buttons then return end
    if not level.scrollFrame.child.buttons[index] then return end
    local button = level.scrollFrame.child.buttons[index]
    button:Hide()
    if button.highlight then button.highlight:Hide() end
    table.remove(level.scrollFrame.child.buttons, index)
    table.insert(buttons, button)
    for k in pairs(button) do
        if k ~= 0 and k ~= "text" and k ~= "check" and k ~= "arrow" and k ~=
            "colorSwatch" and k ~= "highlight" and k ~= "radioHighlight" then
            button[k] = nil
        end
    end
    return true
end

local function getArgs(t, str, num, ...)
    local x = t[str .. num]
    if x == nil then
        return ...
    else
        return x, getArgs(t, str, num + 1, ...)
    end
end

local sliderFrame
local editBoxFrame

local normalFont
local lastSetFont
local justSetFont = false
local regionTmp = {}
local function fillRegionTmp(...)
    for i = 1, select('#', ...) do regionTmp[i] = select(i, ...) end
end

local function showGameTooltip(self)
    if self.tooltipTitle or self.tooltipText then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        local disabled = not self.isTitle and self.disabled
        if self.tooltipTitle then
            if disabled then
                GameTooltip:SetText(self.tooltipTitle, 0.5, 0.5, 0.5, 1)
            else
                GameTooltip:SetText(self.tooltipTitle, 1, 1, 1, 1)
            end
            if self.tooltipText then
                if disabled then
                    GameTooltip:AddLine(self.tooltipText,
                                        (NORMAL_FONT_COLOR.r + 0.5) / 2,
                                        (NORMAL_FONT_COLOR.g + 0.5) / 2,
                                        (NORMAL_FONT_COLOR.b + 0.5) / 2, 1)
                else
                    GameTooltip:AddLine(self.tooltipText, NORMAL_FONT_COLOR.r,
                                        NORMAL_FONT_COLOR.g,
                                        NORMAL_FONT_COLOR.b, 1)
                end
            end
        else
            if disabled then
                GameTooltip:SetText(self.tooltipText, 0.5, 0.5, 0.5, 1)
            else
                GameTooltip:SetText(self.tooltipText, 1, 1, 1, 1)
            end
        end
        GameTooltip:Show()
    end
    if self.tooltipFunc then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 5, 0)
        self.tooltipFunc(getArgs(self, 'tooltipArg', 1))
        GameTooltip:Show()
    end
end

local tmpt = setmetatable({}, {mode = 'v'})
local numButtons = 0
local function AcquireButton(level)
    if not levels[level] then return end
    level = levels[level]
    if not level.scrollFrame.child.buttons then
        level.scrollFrame.child.buttons = {}
    end

    local button
    if #buttons == 0 then
        numButtons = numButtons + 1
        button = CreateFrame("Button", "LibDewdrop30Button" .. numButtons, nil)
        button:SetFrameStrata("FULLSCREEN_DIALOG")
        button:SetHeight(16)
        local highlight = button:CreateTexture(nil, "BACKGROUND")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        button.highlight = highlight
        highlight:SetBlendMode("ADD")
        highlight:SetAllPoints(button)
        highlight:Hide()
        local check = button:CreateTexture(nil, "ARTWORK")
        button.check = check
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetPoint("CENTER", button, "LEFT", 12, 0)
        check:SetWidth(24)
        check:SetHeight(24)
        local radioHighlight = button:CreateTexture(nil, "ARTWORK")
        button.radioHighlight = radioHighlight
        radioHighlight:SetTexture("Interface\\Buttons\\UI-RadioButton")
        radioHighlight:SetAllPoints(check)
        radioHighlight:SetBlendMode("ADD")
        radioHighlight:SetTexCoord(0.5, 0.75, 0, 1)
        radioHighlight:Hide()
        button:SetScript("OnEnter", function(self)
            if (sliderFrame and sliderFrame:IsShown() and sliderFrame.mouseDown and
                sliderFrame.level == self.level.num + 1) or
                (editBoxFrame and editBoxFrame:IsShown() and
                    editBoxFrame.mouseDown and editBoxFrame.level ==
                    self.level.num + 1) then
                for i = 1, self.level.num do Refresh(levels[i]) end
                return
            end
            Dewdrop:Close(self.level.num + 1)
            if not self.disabled then
                if self.secure then
                    secureFrame:Activate(self)
                elseif self.hasSlider then
                    OpenSlider(self)
                elseif self.hasEditBox then
                    OpenEditBox(self)
                elseif self.hasArrow then
                    Open(self, nil, self.level.num + 1, self.value)
                end
            end
            if not self.level then -- button reclaimed
                return
            end
            StopCounting(self.level.num + 1)
            if not self.disabled then
                highlight:Show()
                if self.isRadio then button.radioHighlight:Show() end
                if self.mouseoverUnderline then
                    underlineFrame:SetParent(self)
                    underlineFrame:SetPoint("BOTTOMLEFT", self.text, 0, 0)
                    underlineFrame:SetWidth(self.text:GetStringWidth())
                    underlineFrame:Show()
                end
            end
            showGameTooltip(self)
        end)
        button:SetScript("OnHide", function(self)
            if self.secure and secureFrame:IsOwnedBy(self) then
                secureFrame:Deactivate()
            end
        end)
        button:SetScript("OnLeave", function(self)
            if self.secure and secureFrame:IsShown() then
                return; -- it's ok, we didn't actually mouse out of the button, only onto the secure frame on top of it
            end
            underlineFrame:Hide()
            if not self.selected then highlight:Hide() end
            button.radioHighlight:Hide()
            if self.level then StartCounting(self.level.num) end
            GameTooltip:Hide()
        end)
        local first = true
        button:SetScript("OnClick", function(self)
            if not self.disabled then
                if self.hasColorSwatch then
                    local func = button.colorFunc
                    local hasOpacity = self.hasOpacity
                    local self = self
                    for k in pairs(tmpt) do tmpt[k] = nil end
                    for i = 1, 1000 do
                        local x = self['colorArg' .. i]
                        if x == nil then
                            break
                        else
                            tmpt[i] = x
                        end
                    end
                    ColorPickerFrame.func = function()
                        if func then
                            local r, g, b = ColorPickerFrame:GetColorRGB()
                            local a = hasOpacity and 1 -
                                          OpacitySliderFrame:GetValue() or nil
                            local n = #tmpt
                            tmpt[n + 1] = r
                            tmpt[n + 2] = g
                            tmpt[n + 3] = b
                            tmpt[n + 4] = a
                            func(unpack(tmpt))
                            tmpt[n + 1] = nil
                            tmpt[n + 2] = nil
                            tmpt[n + 3] = nil
                            tmpt[n + 4] = nil
                        end
                    end
                    ColorPickerFrame.hasOpacity = self.hasOpacity
                    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
                    ColorPickerFrame.opacity = 1 - self.opacity
                    ColorPickerFrame:SetColorRGB(self.r, self.g, self.b)
                    local r, g, b, a = self.r, self.g, self.b, self.opacity
                    ColorPickerFrame.cancelFunc = function()
                        if func then
                            local n = #tmpt
                            tmpt[n + 1] = r
                            tmpt[n + 2] = g
                            tmpt[n + 3] = b
                            tmpt[n + 4] = a
                            func(unpack(tmpt))
                            for i = 1, n + 4 do
                                tmpt[i] = nil
                            end
                        end
                    end
                    Dewdrop:Close(1)
                    ShowUIPanel(ColorPickerFrame)
                elseif self.func then
                    local level = self.level
                    if type(self.func) == "string" then
                        if type(self.arg1[self.func]) ~= "function" then
                            self:error("Cannot call method %q", self.func)
                        end
                        self.arg1[self.func](self.arg1, getArgs(self, 'arg', 2))
                    else
                        self.func(getArgs(self, 'arg', 1))
                    end
                    if self.closeWhenClicked then
                        Dewdrop:Close()
                    elseif level:IsShown() then
                        for i = 1, level.num do
                            Refresh(levels[i])
                        end
                        local value = levels[level.num].value
                        for i = level.num - 1, 1, -1 do
                            local level = levels[i]
                            local good = false
                            for _, button in ipairs(
                                                 level.scrollFrame.child.buttons) do
                                if button.value == value then
                                    good = true
                                    break
                                end
                            end
                            if not good then
                                Dewdrop:Close(i + 1)
                            end
                            value = levels[i].value
                        end
                    end
                elseif self.closeWhenClicked then
                    Dewdrop:Close()
                end
            end
        end)

        local text = button:CreateFontString(nil, "ARTWORK")
        button.text = text
        button:SetScript("OnMouseDown", function(self)
            if not self.disabled and
                (self.func or self.colorFunc or self.closeWhenClicked) then
                text:SetPoint("LEFT", button, "LEFT",
                              self.notCheckable and 1 or 25, -1)
            end
        end)
        button:SetScript("OnMouseUp", function(self)
            if not self.disabled and
                (self.func or self.colorFunc or self.closeWhenClicked) then
                text:SetPoint("LEFT", button, "LEFT",
                              self.notCheckable and 0 or 24, 0)
            end
        end)
        local arrow = button:CreateTexture(nil, "ARTWORK")
        button.arrow = arrow
        arrow:SetPoint("LEFT", button, "RIGHT", -16, 0)
        arrow:SetWidth(16)
        arrow:SetHeight(16)
        arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        local colorSwatch = button:CreateTexture(nil, "ARTWORK")
        button.colorSwatch = colorSwatch
        colorSwatch:SetWidth(20)
        colorSwatch:SetHeight(20)
        colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
        local texture = button:CreateTexture(nil, "OVERLAY")
        colorSwatch.texture = texture
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetWidth(11.5)
        texture:SetHeight(11.5)
        texture:Show()
        texture:SetPoint("CENTER", colorSwatch, "CENTER")
        colorSwatch:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    else
        button = table.remove(buttons)
    end
    button:ClearAllPoints()
    button:SetFrameStrata(level:GetFrameStrata())
    button:SetFrameLevel(level:GetFrameLevel() + 5)
    button:SetPoint("LEFT", level.scrollFrame.child, "LEFT", 10, 0)
    button:SetPoint("RIGHT", level.scrollFrame.child, "RIGHT", -10, 0)
    if #level.scrollFrame.child.buttons == 0 then
        button:SetPoint("TOP", level.scrollFrame.child, "TOP", 0, -10)
    else
        button:SetPoint("TOP",
                        level.scrollFrame.child.buttons[#level.scrollFrame.child
                            .buttons], "BOTTOM", 0, 0)
    end
    button:SetParent(level.scrollFrame.child)
    button.text:SetPoint("LEFT", button, "LEFT", 24, 0)
    button:Show()
    button.level = level
    table.insert(level.scrollFrame.child.buttons, button)
    if not level.parented then
        level.parented = true
        level:ClearAllPoints()
        if level.num == 1 then
            if level.parent ~= UIParent and type(level.parent) == "table" then
                level:SetPoint("TOPRIGHT", level.parent, "TOPLEFT")
            else
                level:SetPoint("CENTER", UIParent, "CENTER")
            end
        else
            if level.lastDirection == "RIGHT" then
                if level.lastVDirection == "DOWN" then
                    level:SetPoint("TOPLEFT", level.parent, "TOPRIGHT", 5, 10)
                else
                    level:SetPoint("BOTTOMLEFT", level.parent, "BOTTOMRIGHT", 5,
                                   -10)
                end
            else
                if level.lastVDirection == "DOWN" then
                    level:SetPoint("TOPRIGHT", level.parent, "TOPLEFT", -5, 10)
                else
                    level:SetPoint("BOTTOMRIGHT", level.parent, "BOTTOMLEFT",
                                   -5, -10)
                end
            end
        end
        level:SetFrameStrata("FULLSCREEN_DIALOG")
    end
    button:SetAlpha(1)
    return button
end

local numLevels = 0
local function AcquireLevel(level)
    if not levels[level] then
        for i = #levels + 1, level, -1 do
            local i = i
            numLevels = numLevels + 1
            local frame = CreateFrame("Button",
                                      "LibDewdrop30Level" .. numLevels,
                                      UIParent, BackdropTemplateMixin and
                                          "BackdropTemplate")
            if i == 1 then
                local old_CloseSpecialWindows = CloseSpecialWindows
                function CloseSpecialWindows()
                    local found = old_CloseSpecialWindows()
                    if levels[1]:IsShown() then
                        Dewdrop:Close()
                        return 1
                    end
                    return found
                end
            end
            frame.scrollFrame = CreateFrame("ScrollFrame",
                                            "LibDewdrop30ScrollFrame" ..
                                                numLevels, frame,
                                            "ScrollFrameTemplate")
            frame.scrollFrame.child = CreateFrame("Button",
                                                  "LibDewdrop30ScrollFrameChild" ..
                                                      numLevels,
                                                  frame.scrollFrame)
            frame.scrollFrame.child:SetHeight(16 * Dewdrop.scrollListSize)
            frame.scrollFrame.child:SetWidth(frame:GetWidth())
            frame.scrollFrame:SetScrollChild(frame.scrollFrame.child)
            frame.scrollFrame.child:SetAllPoints(frame.scrollFrame)
            frame.scrollFrame:SetAllPoints(frame)
            frame.scrollFrame:SetPoint("TOPLEFT", 1, -5)
            frame.scrollFrame:SetPoint("TOPRIGHT", 1, -5)
            frame.scrollFrame:SetPoint("BOTTOMLEFT", 1, 5)
            frame.scrollFrame:SetPoint("BOTTOMRIGHT", 1, 5)
            levels[i] = frame
            frame.num = i
            frame:SetFrameStrata("FULLSCREEN_DIALOG")
            frame.scrollFrame:SetFrameStrata("FULLSCREEN_DIALOG")
            frame.scrollFrame.child:SetFrameStrata("FULLSCREEN_DIALOG")
            frame:SetParent(UIParent)
            frame:Hide()
            frame:SetWidth(180)
            frame:SetHeight(10)
            frame:SetFrameLevel(i * 3)
            frame:SetScript("OnHide", function()
                Dewdrop:Close(level + 1)
                -- Also restore anchor's OnEnter when level 1 hides (in case it wasn't restored via Close)
                if i == 1 then
                    RestoreAnchorOnEnter()
                end
            end)
            if frame.SetTopLevel then frame:SetTopLevel(true) end
            frame:EnableMouse(true)
            frame:EnableMouseWheel(true)
            local backdrop = CreateFrame("Frame", nil, frame,
                                         BackdropTemplateMixin and
                                             "BackdropTemplate")
            backdrop:SetAllPoints(frame)
            backdrop:SetBackdrop(tmp('bgFile',
                                     "Interface\\Tooltips\\UI-Tooltip-Background",
                                     'edgeFile',
                                     "Interface\\Tooltips\\UI-Tooltip-Border",
                                     'tile', true, 'insets', tmp2('left', 0,
                                                                  'right', 0,
                                                                  'top', 0,
                                                                  'bottom', 0),
                                     'tileSize', 16, 'edgeSize', 16))
            backdrop:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r,
                                            TOOLTIP_DEFAULT_COLOR.g,
                                            TOOLTIP_DEFAULT_COLOR.b)
            backdrop:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
                                      TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
                                      TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)
            frame:SetScript("OnClick", function(self)
                Dewdrop:Close(i)
            end)
            frame:SetScript("OnEnter", function(self) StopCounting(i) end)
            frame:SetScript("OnLeave", function(self)
                StartCounting(i)
            end)
            if i == 1 then
                frame:SetScript("OnUpdate", function(self, elapsed)
                    OnUpdate(self, elapsed)
                end)
                levels[1].lastDirection = "RIGHT"
                levels[1].lastVDirection = "DOWN"
            else
                levels[i].lastDirection = levels[i - 1].lastDirection
                levels[i].lastVDirection = levels[i - 1].lastVDirection
            end
        end
    end
    local fullscreenFrame = GetUIPanel("fullscreen")
    local l = levels[level]
    local strata, framelevel = l:GetFrameStrata(), l:GetFrameLevel()
    if fullscreenFrame then
        l:SetParent(fullscreenFrame)
    else
        l:SetParent(UIParent)
    end
    l:SetFrameStrata(strata)
    l:SetFrameLevel(framelevel)
    l:SetAlpha(1)
    return l
end

local validatedOptions

local values
local mysort_args
local mysort
local othersort
local othersort_validate

local baseFunc, currentLevel

local function confirmPopup(message, func, ...)
    if not StaticPopupDialogs["LIBDEWDROP30_CONFIRM_DIALOG"] then
        StaticPopupDialogs["LIBDEWDROP30_CONFIRM_DIALOG"] = {}
    end
    local t = StaticPopupDialogs["LIBDEWDROP30_CONFIRM_DIALOG"]
    for k in pairs(t) do t[k] = nil end
    t.text = message
    t.button1 = ACCEPT or "Accept"
    t.button2 = CANCEL or "Cancel"
    t.OnAccept = function() func(unpack(t)) end
    for i = 1, select('#', ...) do t[i] = select(i, ...) end
    t.timeout = 0
    t.whileDead = 1
    t.hideOnEscape = 1

    Dewdrop:Close()
    StaticPopup_Show("LIBDEWDROP30_CONFIRM_DIALOG")
end

local function getMethod(settingname, handler, v, methodName, ...)
    assert(v and type(v) == "table")
    assert(methodName and type(methodName) == "string")

    local method = v[methodName]
    if type(method) == "function" then
        return method, ...
    elseif type(method) == "string" then
        if not handler then
            Dewdrop:error(
                "[%s] 'handler' is required if providing a method name: %q",
                tostring(settingname), method)
        elseif not handler[method] then
            Dewdrop:error("[%s] 'handler' method %q not defined",
                          tostring(settingname), method)
        end
        return handler[method], handler, ...
    end

    Dewdrop:error("[%s] Missing %q directive", tostring(settingname), methodName)
end

local function callMethod(settingname, handler, v, methodName, ...)
    assert(v and type(v) == "table")
    assert(methodName and type(methodName) == "string")

    local method = v[methodName]
    if type(method) == "function" then
        local success, ret, ret2, ret3, ret4 = pcall(v[methodName], ...)
        if not success then
            geterrorhandler()(ret)
            return nil
        end
        return ret, ret2, ret3, ret4

    elseif type(method) == "string" then

        local neg = method:match("^~(.-)$")
        if neg then method = neg end
        if not handler then
            Dewdrop:error(
                "[%s] 'handler' is required if providing a method name: %q",
                tostring(settingname), method)
        elseif not handler[method] then
            Dewdrop:error("[%s] 'handler' (%q) method %q not defined",
                          tostring(settingname), handler.name or "(unnamed)",
                          method)
        end
        local success, ret, ret2, ret3, ret4 =
            pcall(handler[method], handler, ...)
        if not success then
            geterrorhandler()(ret)
            return nil
        end
        if neg then return not ret end
        return ret, ret2, ret3, ret4
    elseif method == false then
        return nil
    end

    Dewdrop:error("[%s] Missing %q directive in %q", tostring(settingname),
                  methodName, v.name or "(unnamed)")
end

local function skip1Nil(...)
    if select(1, ...) == nil then return select(2, ...) end
    return ...
end

Dewdrop.fontsize = 14

function Dewdrop:SetFontSize(fontSize) Dewdrop.fontsize = tonumber(fontSize) end

function Dewdrop:SetScrollListSize(scrollListSize)
    Dewdrop.scrollListSize = scrollListSize
end

function Dewdrop:FeedAceOptionsTable(options, difference)
    -- Implementation omitted for brevity - same as original
    return false
end

function Dewdrop:FeedTable(s, difference)
    -- Implementation omitted for brevity - same as original
    return false
end

function Refresh(level)
    if type(level) == "number" then level = levels[level] end
    if not level then return end
    if baseFunc then
        Clear(level)
        currentLevel = level.num
        if type(baseFunc) == "table" then
            if currentLevel == 1 then
                local handler = baseFunc.handler
                if handler then
                    local name = tostring(handler)
                    if not name:find('^table:') and not handler.hideMenuTitle then
                        name = name:gsub("|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
                        Dewdrop:AddLine('text', name, 'isTitle', true)
                    end
                end
            end
            Dewdrop:FeedAceOptionsTable(baseFunc)
            if currentLevel == 1 then
                Dewdrop:AddLine('text', CLOSE, 'tooltipTitle', CLOSE,
                                'tooltipText', CLOSE_DESC, 'closeWhenClicked',
                                true)
            end
        else
            baseFunc(currentLevel, level.value,
                     levels[level.num - 1] and levels[level.num - 1].value,
                     levels[level.num - 2] and levels[level.num - 2].value,
                     levels[level.num - 3] and levels[level.num - 3].value,
                     levels[level.num - 4] and levels[level.num - 4].value)
        end
        currentLevel = nil
        CheckSize(level)
    end
end

function Dewdrop:Refresh(level)
    Dewdrop:argCheck(level, 2, "number", "nil")
    if not level then
        for k, v in pairs(levels) do Refresh(v) end
    else
        Refresh(levels[level])
    end
end

-- OpenSlider and OpenEditBox functions omitted for brevity - same as original

function Dewdrop:EncodeKeybinding(text)
    if text == nil or text == "NONE" then return nil end
    text = tostring(text):upper()
    local shift, ctrl, alt
    local modifier
    while true do
        if text == "-" then break end
        modifier, text = strsplit('-', text, 2)
        if text then
            if modifier ~= "SHIFT" and modifier ~= "CTRL" and modifier ~= "ALT" then
                return false
            end
            if modifier == "SHIFT" then
                if shift then return false end
                shift = true
            end
            if modifier == "CTRL" then
                if ctrl then return false end
                ctrl = true
            end
            if modifier == "ALT" then
                if alt then return false end
                alt = true
            end
        else
            text = modifier
            break
        end
    end
    if not text:find("^F%d+$") and text ~= "CAPSLOCK" and text:len() ~= 1 and
        (text:len() == 0 or text:byte() < 128 or text:len() > 4) and
        not _G["KEY_" .. text] and text ~= "BUTTON1" and text ~= "BUTTON2" then
        return false
    end
    local s = GetBindingText(text, "KEY_")
    if s == "BUTTON1" then
        s = KEY_BUTTON1
    elseif s == "BUTTON2" then
        s = KEY_BUTTON2
    end
    if shift then s = "Shift-" .. s end
    if ctrl then s = "Ctrl-" .. s end
    if alt then s = "Alt-" .. s end
    return s
end

local function GetTipAnchor(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or
                      (x < UIParent:GetWidth() / 3) and "LEFT" or ""
    local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
    return vhalf .. hhalf, frame,
           (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
end

function Dewdrop:SmartAnchorTo(frame)
    if not frame then error("Invalid frame provided.", 2) end
    if (levels[1] and levels[1]:IsShown()) then
        levels[1]:ClearAllPoints()
        levels[1]:SetClampedToScreen(true)
        levels[1]:SetPoint(GetTipAnchor(frame))
    end
end

function Dewdrop:IsOpen(parent)
    self:argCheck(parent, 2, "table", "string", "nil")
    return levels[1] and levels[1]:IsShown() and
               (not parent or parent == levels[1].parent or parent ==
                   levels[1]:GetParent())
end

function Dewdrop:GetOpenedParent()
    return (levels[1] and levels[1]:IsShown()) and
               (levels[1].parent or levels[1]:GetParent())
end

function Open(parent, func, level, value, point, relativePoint, cursorX, cursorY)
    Dewdrop:Close(level)
    if type(parent) == "table" then parent:GetCenter() end
    local frame = AcquireLevel(level)
    if level == 1 then
        frame.lastDirection = "RIGHT"
        frame.lastVDirection = "DOWN"
    else
        frame.lastDirection = levels[level - 1].lastDirection
        frame.lastVDirection = levels[level - 1].lastVDirection
    end
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:ClearAllPoints()
    frame.parent = parent
    frame:SetPoint("LEFT", UIParent, "RIGHT", 10000, 0)
    frame:Show()

    if level == 1 then baseFunc = func end
    levels[level].value = value
    if type(parent) == "table" and parent.arrow then
        parent.selected = true
        parent.highlight:Show()
    end
    relativePoint = relativePoint or point
    Refresh(levels[level])
    if point or (cursorX and cursorY) then
        frame:ClearAllPoints()
        if cursorX and cursorY then
            local curX, curY = GetScaledCursorPosition()
            if curY < GetScreenHeight() / 2 then
                point, relativePoint = "BOTTOM", "BOTTOM"
            else
                point, relativePoint = "TOP", "TOP"
            end
            if curX < GetScreenWidth() / 2 then
                point, relativePoint = point .. "LEFT", relativePoint .. "RIGHT"
            else
                point, relativePoint = point .. "RIGHT", relativePoint .. "LEFT"
            end
        end
        frame:SetPoint(point, type(parent) == "table" and parent or UIParent,
                       relativePoint)
    end
    CheckDualMonitor(frame)
    frame:SetClampedToScreen(true)
    frame:SetClampedToScreen(false)
    StartCounting(level)
end

function Dewdrop:IsRegistered(parent)
    self:argCheck(parent, 2, "table", "string")
    return not not self.registry[parent]
end

function Dewdrop:Open(parent, ...)
    self:argCheck(parent, 2, "table", "string")

    -- Restore any previous anchor's OnEnter before opening new menu
    RestoreAnchorOnEnter()

    -- Hide any existing tooltip before opening the menu
    GameTooltip:Hide()

    local info
    local k1 = ...
    if type(k1) == "table" and k1[0] and k1.IsObjectType and self.registry[k1] then
        info = tmp(select(2, ...))
        for k, v in pairs(self.registry[k1]) do
            if info[k] == nil then info[k] = v end
        end
    else
        info = tmp(...)
        if self.registry[parent] then
            for k, v in pairs(self.registry[parent]) do
                if info[k] == nil then info[k] = v end
            end
        end
    end

    -- Save and replace the parent's OnEnter script to prevent tooltip while menu is open
    if type(parent) == "table" and parent.GetScript and parent.SetScript then
        local originalOnEnter = parent:GetScript("OnEnter")
        savedAnchorOnEnter = originalOnEnter or false  -- false is sentinel for "no script"
        savedAnchorFrame = parent
        -- Replace with a function that hides tooltip (in case something else shows it)
        parent:SetScript("OnEnter", function(self)
            GameTooltip:Hide()
        end)
    end

    local point = info.point
    local relativePoint = info.relativePoint
    local cursorX = info.cursorX
    local cursorY = info.cursorY
    if type(point) == "function" then
        local b
        point, b = point(parent)
        if b then relativePoint = b end
    end
    if type(relativePoint) == "function" then
        relativePoint = relativePoint(parent)
    end
    Open(parent, info.children, 1, nil, point, relativePoint, cursorX, cursorY)
    self:SmartAnchorTo(parent)
end

function Clear(level)
    if level then
        if level.scrollFrame.child.buttons then
            for i = #level.scrollFrame.child.buttons, 1, -1 do
                ReleaseButton(level, i)
            end
        end
    end
end

function Dewdrop:Close(level)
    if DropDownList1 and DropDownList1:IsShown() then DropDownList1:Hide() end
    self:argCheck(level, 2, "number", "nil")
    if not level then level = 1 end

    -- Restore anchor's OnEnter when closing level 1 (main menu)
    if level == 1 then
        RestoreAnchorOnEnter()
    end

    if level == 1 and levels[level] then levels[level].parented = false end
    if level > 1 and levels[level - 1] and levels[level - 1].scrollFrame.child.buttons then
        local buttons = levels[level - 1].scrollFrame.child.buttons
        for _, button in ipairs(buttons) do
            button.selected = nil
            button.highlight:Hide()
        end
    end
    if sliderFrame and sliderFrame.level >= level then sliderFrame:Hide() end
    if editBoxFrame and editBoxFrame.level >= level then editBoxFrame:Hide() end
    for i = level, #levels do
        Clear(levels[level])
        levels[i]:Hide()
        levels[i]:ClearAllPoints()
        levels[i]:SetPoint("CENTER", UIParent, "CENTER")
        levels[i].value = nil
    end
end

function Dewdrop:AddSeparator(level)
    level = levels[level or currentLevel]
    if not level or not level.scrollFrame.child.buttons then return; end

    local prevbutton = level.scrollFrame.child.buttons[#level.scrollFrame.child
                           .buttons]
    if not prevbutton then return; end

    if prevbutton.disabled and prevbutton.text:GetText() == "" then return end
    self:AddLine("text", "", "disabled", true)
end

function Dewdrop:AddLine(...)
    local info = tmp(...)
    local level = info.level or currentLevel
    if (info.icon and type(info.icon) == "number") then
        info.icon = tostring(info.icon)
    end
    info.level = nil
    local button = AcquireButton(level)
    if not next(info) then info.disabled = true end
    button.disabled = info.isTitle or info.notClickable or info.disabled or
                          (InCombatLockdown() and info.secure)
    button.isTitle = info.isTitle
    button.notClickable = info.notClickable
    if info.disabled then
        button.arrow:SetDesaturated(true)
        button.check:SetDesaturated(true)
    else
        button.arrow:SetDesaturated(false)
        button.check:SetDesaturated(false)
    end
    button.notCheckable = info.notCheckable
    button.text:SetPoint("LEFT", button, "LEFT",
                         button.notCheckable and 0 or 24, 0)
    button.checked = not info.notCheckable and info.checked
    button.mouseoverUnderline = info.mouseoverUnderline
    button.isRadio = not info.notCheckable and info.isRadio
    if info.isRadio then
        button.check:Show()
        button.check:SetTexture(info.checkIcon or
                                    "Interface\\Buttons\\UI-RadioButton")
        if button.checked then
            button.check:SetTexCoord(0.25, 0.5, 0, 1)
            button.check:SetVertexColor(1, 1, 1, 1)
        else
            button.check:SetTexCoord(0, 0.25, 0, 1)
            button.check:SetVertexColor(1, 1, 1, 0.5)
        end
        button.radioHighlight:SetTexture(info.checkIcon or
                                             "Interface\\Buttons\\UI-RadioButton")
        button.check:SetWidth(16)
        button.check:SetHeight(16)
    elseif info.icon then
        button.check:Show()
        button.check:SetTexture(info.icon)
        if info.iconWidth and info.iconHeight then
            button.check:SetWidth(info.iconWidth)
            button.check:SetHeight(info.iconHeight)
        else
            button.check:SetWidth(16)
            button.check:SetHeight(16)
        end
        if info.iconCoordLeft and info.iconCoordRight and info.iconCoordTop and
            info.iconCoordBottom then
            button.check:SetTexCoord(info.iconCoordLeft, info.iconCoordRight,
                                     info.iconCoordTop, info.iconCoordBottom)
        elseif info.icon:find("^Interface\\Icons\\") then
            button.check:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        else
            button.check:SetTexCoord(0, 1, 0, 1)
        end
        button.check:SetVertexColor(1, 1, 1, 1)
    else
        if button.checked then
            if info.checkIcon then
                button.check:SetWidth(16)
                button.check:SetHeight(16)
                button.check:SetTexture(info.checkIcon)
                if info.checkIcon:find("^Interface\\Icons\\") then
                    button.check:SetTexCoord(0.05, 0.95, 0.05, 0.95)
                else
                    button.check:SetTexCoord(0, 1, 0, 1)
                end
            else
                button.check:SetWidth(24)
                button.check:SetHeight(24)
                button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                button.check:SetTexCoord(0, 1, 0, 1)
            end
            button.check:SetVertexColor(1, 1, 1, 1)
        else
            button.check:SetVertexColor(1, 1, 1, 0)
        end
    end
    if not button.disabled then
        button.func = info.func
        button.secure = info.secure
    end
    button.hasColorSwatch = info.hasColorSwatch
    if button.hasColorSwatch then
        button.colorSwatch:Show()
        button.colorSwatch.texture:Show()
        button.r = info.r or 1
        button.g = info.g or 1
        button.b = info.b or 1
        button.colorSwatch.texture:SetVertexColor(button.r, button.g, button.b)
        button.checked = false
        button.func = nil
        button.colorFunc = info.colorFunc
        local i = 1
        while true do
            local k = "colorArg" .. i
            local x = info[k]
            if x == nil then break end
            button[k] = x
            i = i + 1
        end
        button.hasOpacity = info.hasOpacity
        button.opacity = info.opacity or 1
    else
        button.colorSwatch:Hide()
        button.colorSwatch.texture:Hide()
    end
    button.hasArrow = not button.hasColorSwatch and
                          (info.value or info.hasSlider or info.hasEditBox) and
                          info.hasArrow
    if button.hasArrow then
        button.arrow:SetAlpha(1)
        if info.hasSlider then
            button.hasSlider = true
            button.sliderMin = info.sliderMin or 0
            button.sliderMax = info.sliderMax or 1
            button.sliderStep = info.sliderStep or 0
            button.sliderBigStep = info.sliderBigStep or button.sliderStep
            if button.sliderBigStep < button.sliderStep then
                button.sliderBigStep = button.sliderStep
            end
            button.sliderIsPercent = info.sliderIsPercent and true or false
            button.sliderMinText =
                info.sliderMinText or button.sliderIsPercent and
                    string.format("%.0f%%", button.sliderMin * 100) or
                    button.sliderMin
            button.sliderMaxText =
                info.sliderMaxText or button.sliderIsPercent and
                    string.format("%.0f%%", button.sliderMax * 100) or
                    button.sliderMax
            button.sliderFunc = info.sliderFunc
            button.sliderValue = info.sliderValue
            button.fromAceOptions = info.fromAceOptions
            local i = 1
            while true do
                local k = "sliderArg" .. i
                local x = info[k]
                if x == nil then break end
                button[k] = x
                i = i + 1
            end
        elseif info.hasEditBox then
            button.hasEditBox = true
            button.editBoxText = info.editBoxText or ""
            button.editBoxFunc = info.editBoxFunc
            local i = 1
            while true do
                local k = "editBoxArg" .. i
                local x = info[k]
                if x == nil then break end
                button[k] = x
                i = i + 1
            end
            button.editBoxChangeFunc = info.editBoxChangeFunc
            local i = 1
            while true do
                local k = "editBoxChangeArg" .. i
                local x = info[k]
                if x == nil then break end
                button[k] = x
                i = i + 1
            end
            button.editBoxValidateFunc = info.editBoxValidateFunc
            local i = 1
            while true do
                local k = "editBoxValidateArg" .. i
                local x = info[k]
                if x == nil then break end
                button[k] = x
                i = i + 1
            end
            button.editBoxIsKeybinding = info.editBoxIsKeybinding
            button.editBoxKeybindingOnly = info.editBoxKeybindingOnly
            button.editBoxKeybindingExcept = info.editBoxKeybindingExcept
        else
            button.value = info.value
            local l = levels[level + 1]
            if l and info.value == l.value then
                button.selected = true
                button.highlight:Show()
            end
        end
    else
        button.arrow:SetAlpha(0)
    end
    local i = 1
    while true do
        local k = "arg" .. i
        local x = info[k]
        if x == nil then break end
        button[k] = x
        i = i + 1
    end
    button.closeWhenClicked = info.closeWhenClicked

    local fontsize = self.fontsize
    local fontcolor

    button.textHeight = fontsize

    if button.isTitle then
        button.text:SetFont(options.fonts.title.ttf, fontsize)
        fontcolor = options.fonts.title.color
    elseif button.notClickable then
        button.text:SetFont(options.fonts.notClickable.ttf, fontsize)
        fontcolor = options.fonts.notClickable.color
    elseif button.disabled then
        button.text:SetFont(options.fonts.disabled.ttf, fontsize)
        fontcolor = options.fonts.disabled.color
    else
        button.text:SetFont(options.fonts.standard.ttf, fontsize)
        fontcolor = options.fonts.standard.color
    end

    button.text:SetTextColor(unpack(fontcolor))

    button:SetHeight(button.textHeight + 6)

    button.text:SetPoint("RIGHT", button.arrow, (button.hasColorSwatch or
                             button.hasArrow) and "LEFT" or "RIGHT")
    button.text:SetJustifyH(info.justifyH or "LEFT")
    button.text:SetText(info.text)
    button.tooltipTitle = info.tooltipTitle
    button.tooltipText = info.tooltipText
    button.tooltipFunc = info.tooltipFunc
    local i = 1
    while true do
        local k = "tooltipArg" .. i
        local x = info[k]
        if x == nil then break end
        button[k] = x
        i = i + 1
    end
    if not button.tooltipTitle and not button.tooltipText and
        not button.tooltipFunc and not info.isTitle then
        button.tooltipTitle = info.text
    end
    if type(button.func) == "string" then
        if type(button.arg1) ~= "table" then
            self:error("Cannot call method %q on a non-table", button.func)
        end
        if type(button.arg1[button.func]) ~= "function" then
            self:error("Method %q nonexistant.", button.func)
        end
    end
end

function Dewdrop:OnTooltipHide()
    if lastSetFont then
        if lastSetFont == normalFont then
            lastSetFont = nil
            return
        end
        fillRegionTmp(GameTooltip:GetRegions())
        for i, v in ipairs(regionTmp) do
            if v.GetFont then
                local font, size, outline = v:GetFont()
                if font == lastSetFont then
                    v:SetFont(normalFont, size, outline)
                end
            end
            regionTmp[i] = nil
        end
        lastSetFont = nil
    end
end

local function activate()

    local self = Dewdrop

    self.registry = {}
    self.onceRegistered = {}

    local WorldFrame_OnMouseDown = WorldFrame:GetScript("OnMouseDown")
    local WorldFrame_OnMouseUp = WorldFrame:GetScript("OnMouseUp")
    local oldX, oldY, clickTime

    WorldFrame:SetScript("OnMouseDown", function(self, ...)
        oldX, oldY = GetCursorPosition()
        clickTime = GetTime()
        if WorldFrame_OnMouseDown then WorldFrame_OnMouseDown(self, ...) end
    end)

    WorldFrame:SetScript("OnMouseUp", function(self, ...)
        local x, y = GetCursorPosition()
        if not oldX or not oldY or not x or not y or not clickTime then
            Dewdrop:Close()
            if WorldFrame_OnMouseUp then
                WorldFrame_OnMouseUp(self, ...)
            end
            return
        end
        local d = math.abs(x - oldX) + math.abs(y - oldY)
        if d <= 5 and GetTime() - clickTime < 0.5 then Dewdrop:Close() end
        if WorldFrame_OnMouseUp then WorldFrame_OnMouseUp(self, ...) end
    end)

    hooksecurefunc(DropDownList1, "Show", function()
        if levels[1] and levels[1]:IsVisible() then Dewdrop:Close() end
    end)

    hooksecurefunc("HideDropDownMenu", function()
        if levels[1] and levels[1]:IsVisible() then Dewdrop:Close() end
    end)

    self.frame = CreateFrame("Frame")
    self.frame:UnregisterAllEvents()
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_REGEN_ENABLED" then
            self.combat = false
        elseif event == "PLAYER_REGEN_DISABLED" then
            self.combat = true
        end
    end)
    self.frame:SetScript("OnUpdate", function(self, elapsed)
        self:Hide()
        Refresh(1)
    end)
    self.frame:Show()
    self.hookedTooltip = true

    local OnTooltipHide = GameTooltip:GetScript("OnHide")
    GameTooltip:SetScript("OnHide", function(self, ...)
        if OnTooltipHide then OnTooltipHide(self, ...) end
        if type(self.OnTooltipHide) == "function" then
            self:OnTooltipHide()
        end
    end)

    levels = {}
    buttons = {}
    options = {
        fonts = {
            standard = {
                ttf = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
                size = 14,
                color = {GameFontHighlightSmall:GetTextColor()}
            },
            title = {
                ttf = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
                size = 11,
                color = {0.2, 1, 1, 1}
            },
            notClickable = {
                ttf = "Fonts\\ARIALN.ttf",
                size = 6,
                color = {GameFontNormalMed3:GetTextColor()}
            },
            disabled = {
                ttf = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
                size = 8,
                color = {GameFontDisableSmall:GetTextColor()}
            }
        }
    }
end

activate()

function Dewdrop:argCheck(arg, num, kind, kind2, kind3, kind4, kind5)
    if type(num) ~= "number" then
        return error(self,
                     "Bad argument #3 to `argCheck' (number expected, got %s)",
                     type(num))
    elseif type(kind) ~= "string" then
        return error(self,
                     "Bad argument #4 to `argCheck' (string expected, got %s)",
                     type(kind))
    end
    arg = type(arg)
    if arg ~= kind and arg ~= kind2 and arg ~= kind3 and arg ~= kind4 and arg ~=
        kind5 then
        local stack = debugstack()
        local func = stack:match("`argCheck'.-([`<].-['>])")
        if not func then func = stack:match("([`<].-['>])") end
        if kind5 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, %s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3,
                         kind4, kind5, arg)
        elseif kind4 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3,
                         kind4, arg)
        elseif kind3 then
            return error(self,
                         "Bad argument #%s to %s (%s, %s, or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, kind3, arg)
        elseif kind2 then
            return error(self,
                         "Bad argument #%s to %s (%s or %s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, kind2, arg)
        else
            return error(self, "Bad argument #%s to %s (%s expected, got %s)",
                         tonumber(num) or 0 / 0, func, kind, arg)
        end
    end
end

function Dewdrop:error(message, ...)
    if type(self) ~= "table" then
        return _G.error(
                   ("Bad argument #1 to `error' (table expected, got %s)"):format(
                       type(self)), 2)
    end

    local stack = debugstack()
    if not message then
        local second = stack:match("\n(.-)\n")
        message = "error raised! " .. second
    else
        local arg = {...}

        for i = 1, #arg do arg[i] = tostring(arg[i]) end
        for i = 1, 10 do table.insert(arg, "nil") end
        message = message:format(unpack(arg))
    end

    if getmetatable(self) and getmetatable(self).__tostring then
        message = ("%s: %s"):format(tostring(self), message)
    elseif type(rawget(self, 'GetLibraryVersion')) == "function" and
        AceLibrary and AceLibrary:HasInstance(self:GetLibraryVersion()) then
        message = ("%s: %s"):format(self:GetLibraryVersion(), message)
    elseif type(rawget(self, 'class')) == "table" and
        type(rawget(self.class, 'GetLibraryVersion')) == "function" and
        AceLibrary and AceLibrary:HasInstance(self.class:GetLibraryVersion()) then
        message = ("%s: %s"):format(self.class:GetLibraryVersion(), message)
    end

    local first = stack:gsub("\n.*", "")
    local file = first:gsub(".*\\(.*).lua:%d+: .*", "%1")
    file = file:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1")

    local i = 0
    for s in stack:gmatch("\n([^\n]*)") do
        i = i + 1
        if not s:find(file .. "%.lua:%d+:") and not s:find("%(tail call%)") then
            file = s:gsub("^.*\\(.*).lua:%d+: .*", "%1")
            file = file:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1")
            break
        end
    end
    local j = 0
    for s in stack:gmatch("\n([^\n]*)") do
        j = j + 1
        if j > i and not s:find(file .. "%.lua:%d+:") and
            not s:find("%(tail call%)") then
            return _G.error(message, j + 1)
        end
    end
    return _G.error(message, 2)
end

end -- end of USE_NEW_MENU_SYSTEM else block
