local _, ns = ...

local RingHelper = {}
ns.RingHelper = RingHelper

local DEFAULT_MAX_BUTTONS = 8
local DEFAULT_RADIUS = 155
local DEFAULT_BUTTON_SIZE = 64
local DEFAULT_BORDER_SIZE = 74

local ADDON_TEXTURE_PATH = "Interface\\AddOns\\ConsolePortEnhancedTools\\Textures\\"
local TEXTURE_CLIP = ADDON_TEXTURE_PATH .. "IconClip"
local TEXTURE_CONNECTOR = ADDON_TEXTURE_PATH .. "RingConnector"
local TEXTURE_RIM = ADDON_TEXTURE_PATH .. "ThinRim"
local TEXTURE_SOCKET = ADDON_TEXTURE_PATH .. "RoundSocket"
local TEXTURE_HILITE_YELLOW = "Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite-Yellow"
local TEXTURE_PUSHED = "Interface\\AddOns\\ConsolePort\\Textures\\Button\\Pushed"

local DIRECTION_INDEX = {
	UP = 1,
	RIGHT = 3,
	DOWN = 5,
	LEFT = 7,
}

local KEY_TO_DIRECTION = {
	W = "UP",
	UP = "UP",
	A = "LEFT",
	LEFT = "LEFT",
	S = "DOWN",
	DOWN = "DOWN",
	D = "RIGHT",
	RIGHT = "RIGHT",
}

local BINDING_MAP = {
	UP = { "W", "UP", "MOVEFORWARD", "CP_L_UP" },
	LEFT = { "A", "LEFT", "STRAFELEFT", "TURNLEFT", "CP_L_LEFT" },
	DOWN = { "S", "DOWN", "MOVEBACKWARD", "CP_L_DOWN" },
	RIGHT = { "D", "RIGHT", "STRAFERIGHT", "TURNRIGHT", "CP_L_RIGHT" },
}

local REFRESH_EVENTS = {
	"PLAYER_ENTERING_WORLD",
	"BAG_UPDATE",
	"BAG_UPDATE_COOLDOWN",
	"SPELLS_CHANGED",
	"LEARNED_SPELL_IN_TAB",
	"ACTIONBAR_UPDATE_COOLDOWN",
	"UNIT_AURA",
	"UNIT_PET",
	"UNIT_INVENTORY_CHANGED",
	"PARTY_MEMBERS_CHANGED",
	"UNIT_ENTERED_VEHICLE",
	"UNIT_EXITED_VEHICLE",
	"VEHICLE_UPDATE",
	"PLAYER_CONTROL_LOST",
	"PLAYER_CONTROL_GAINED",
	"COMPANION_LEARNED",
	"COMPANION_UPDATE",
	"PLAYER_MOUNT_DISPLAY_CHANGED",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED",
}

local function ShortText(text, limit)
	text = tostring(text or "")
	limit = limit or 14
	if text:len() <= limit then
		return text
	end
	return text:sub(1, limit - 1) .. "."
end

function RingHelper:SetIcon(texture, icon)
	if SetPortraitToTexture then
		SetPortraitToTexture(texture, icon)
	else
		texture:SetTexture(icon)
		texture:SetTexCoord(0.04, 0.96, 0.04, 0.96)
	end
end

local Methods = {}

function Methods:GetRingItems()
	return self[self.ring.itemsKey or "items"] or {}
end

function Methods:GetButtonItem(button)
	return button and button[self.ring.itemKey]
end

function Methods:SetButtonAction(button, item)
	if self.ring.setButtonAction then
		self.ring.setButtonAction(self, button, item)
	end
end

function Methods:SetButtonName(button, text, limit)
	if button and button.Name then
		button.Name:SetText(ShortText(text, limit or self.ring.nameLimit))
	end
end

function Methods:SetButtonStateColor(button, r, g, b)
	if not button then return end
	r, g, b = r or 1, g or 1, b or 1
	button.ColorBorder:SetVertexColor(r, g, b)
	button.ColorBorder:SetAlpha(1)
	button.ColorBorder:Show()
end

function Methods:ClearButtonState(button)
	if not button then return end
	button.ColorBorder:SetVertexColor(0.55, 0.56, 0.52)
	button.ColorBorder:SetAlpha(0.9)
end

function Methods:SetButtonFilled(button)
	if not button then return end
	button:SetAlpha(1)
	button.Icon:SetVertexColor(1, 1, 1)
	button.Backdrop:SetVertexColor(0.28, 0.29, 0.26)
	button.Backdrop:SetAlpha(0.22)
	button.Inner:SetAlpha(0.10)
	button.Clip:SetAlpha(0)
end

function Methods:SetButtonEmpty(button)
	if not button then return end
	button:SetAlpha(0.88)
	button.Icon:SetTexture(nil)
	button.Icon:SetVertexColor(1, 1, 1)
	button.Icon:SetTexCoord(0, 1, 0, 1)
	button.Backdrop:SetVertexColor(0.55, 0.57, 0.51)
	button.Backdrop:SetAlpha(0.58)
	button.Inner:SetAlpha(0.18)
	button.Clip:SetAlpha(0)
end

function Methods:SetLauncherAction(button)
	if not self.launcher then return end
	if InCombatLockdown() then return end
	if button and self:GetButtonItem(button) then
		self.launcher:SetAttribute("type", "click")
		self.launcher:SetAttribute("clickbutton", button)
	else
		self.launcher:SetAttribute("type", nil)
		self.launcher:SetAttribute("clickbutton", nil)
	end
end

function Methods:ClearSelection()
	if self.selected and self.selected.Selected then
		self.selected.Selected:Hide()
		self.selected.Hover:Hide()
	end
	self.selected = nil
	self.selectedIndex = nil
	if self.Detail then
		if self.isEmpty then
			self.Detail:SetText("|cff888888" .. (self.ring.emptyMessage or "No available items.") .. "|r")
		else
			self.Detail:SetText(self.ring.idleText or "")
		end
	end
	self:SetLauncherAction()
end

function Methods:Select(index)
	local button = self.buttons and self.buttons[index]
	if not button then return end

	self:ClearSelection()

	self.selected = button
	self.selectedIndex = index
	button.Selected:Show()
	button.Hover:Show()

	local item = self:GetButtonItem(button)
	if self.ring.onSelect then
		self.ring.onSelect(self, button, item, index)
	end
	self:SetLauncherAction(item and button)
end

function Methods:SelectDirection(direction)
	self:Select(DIRECTION_INDEX[direction] or 1)
end

function Methods:ClearSelectionKeys()
	if InCombatLockdown() then return end
	if self.keyOwner then
		ClearOverrideBindings(self.keyOwner)
	end
end

function Methods:BindSelectionKey(key, selector, direction)
	if key and key ~= "" and selector then
		SetOverrideBindingClick(self.keyOwner, true, key, selector:GetName(), direction)
	end
end

function Methods:BindSelectionKeys()
	if InCombatLockdown() then return end
	if not self.keyOwner then return end

	self:ClearSelectionKeys()

	for direction, bindings in pairs(BINDING_MAP) do
		local selector = self.selectors and self.selectors[direction]
		for _, binding in ipairs(bindings) do
			if binding:len() == 1 or binding == "UP" or binding == "DOWN" or binding == "LEFT" or binding == "RIGHT" then
				self:BindSelectionKey(binding, selector, direction)
			else
				for i = 1, select("#", GetBindingKey(binding)) do
					self:BindSelectionKey(select(i, GetBindingKey(binding)), selector, direction)
				end
			end
		end
	end
end

function Methods:UpdateSelectionFromKeys()
	local keys = self.keys
	local up, down, left, right = keys.UP, keys.DOWN, keys.LEFT, keys.RIGHT
	local index =
		(up and right and 2) or
		(down and right and 4) or
		(down and left and 6) or
		(up and left and 8) or
		(up and 1) or
		(right and 3) or
		(down and 5) or
		(left and 7)

	if index then
		self:Select(index)
	else
		self:ClearSelection()
	end
end

function Methods:ToggleFromBinding()
	if self:IsShown() then
		self:Close()
	else
		self:Open()
	end
end

function Methods:OnLauncherPostClick(button, down)
	if down then
		self:Open()
	elseif down == false then
		if self:IsShown() then
			self:Close()
		end
	else
		self:ToggleFromBinding()
	end
end

function Methods:Close()
	if self:IsShown() then
		pcall(self.Hide, self)
	end
end

function Methods:CloseForCombat()
	if not InCombatLockdown() then
		self:ClearSelectionKeys()
	end
	wipe(self.keys)
	self:Close()
end

function Methods:ScanItems()
	local items = self.ring.scan(self) or {}
	self[self.ring.itemsKey or "items"] = items
	self.isEmpty = #items == 0
	return items
end

function Methods:RefreshSecureActions()
	if InCombatLockdown() or not self.ring.scan then
		return
	end

	self:ScanItems()
	self:Refresh()
	if not self:IsShown() then
		self:ClearSelection()
	end
end

function Methods:Open()
	if self.ring.validate and not self.ring.validate(self) then
		return
	end

	local items = self:GetRingItems()
	if InCombatLockdown() then
		self.isEmpty = not items or #items == 0
	else
		items = self:ScanItems()
	end

	self:Refresh()
	self:Show()
	self:ClearSelection()
	self:BindSelectionKeys()
end

function Methods:Refresh()
	local items = self:GetRingItems()
	local count = math.min(#items, self.maxButtons)

	if self.ring.refreshHeader then
		self.ring.refreshHeader(self, items)
	end

	for i = 1, self.maxButtons do
		local button = self.buttons[i]
		local item = items[i]
		button[self.ring.itemKey] = item
		self:SetButtonAction(button, item)
		if i <= count and item then
			self:SetButtonFilled(button)
			if self.ring.updateButton then
				self.ring.updateButton(self, button, item, i)
			end
		else
			if self.ring.clearButton then
				self.ring.clearButton(self, button, i)
			end
			self:SetButtonEmpty(button)
		end
		button:Show()
	end

	if self.ring.afterRefresh then
		self.ring.afterRefresh(self, items)
	end
end

function Methods:CreateButton(index)
	local button = CreateFrame("Button", "$parent" .. (self.ring.buttonName or "RingButton") .. index, self, "SecureActionButtonTemplate")
	button:SetSize(self.buttonSize, self.buttonSize)
	button:RegisterForClicks("AnyUp")
	button:SetAlpha(1)

	local angle = math.rad(90 - ((index - 1) * 45))
	button:SetPoint("CENTER", self, "CENTER", math.cos(angle) * self.radius, math.sin(angle) * self.radius)

	button.Backdrop = button:CreateTexture(nil, "BORDER")
	button.Backdrop:SetTexture(TEXTURE_SOCKET)
	button.Backdrop:SetSize(self.buttonSize + 10, self.buttonSize + 10)
	button.Backdrop:SetPoint("CENTER")
	button.Backdrop:SetVertexColor(0.55, 0.57, 0.51)
	button.Backdrop:SetAlpha(0.58)

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetSize(self.buttonSize - 6, self.buttonSize - 6)
	button.Icon:SetPoint("CENTER")
	button.Icon:SetTexCoord(0.04, 0.96, 0.04, 0.96)

	button.Inner = button:CreateTexture(nil, "OVERLAY")
	button.Inner:SetTexture(TEXTURE_PUSHED)
	button.Inner:SetSize(self.buttonSize, self.buttonSize)
	button.Inner:SetPoint("CENTER")
	button.Inner:SetVertexColor(0.05, 0.05, 0.05)
	button.Inner:SetAlpha(0.18)

	button.Clip = button:CreateTexture(nil, "OVERLAY")
	button.Clip:SetTexture(TEXTURE_CLIP)
	button.Clip:SetSize(self.buttonSize + 14, self.buttonSize + 14)
	button.Clip:SetPoint("CENTER")
	button.Clip:SetAlpha(0)

	button.ColorBorder = button:CreateTexture(nil, "OVERLAY")
	button.ColorBorder:SetTexture(TEXTURE_RIM)
	button.ColorBorder:SetSize(self.borderSize, self.borderSize)
	button.ColorBorder:SetPoint("CENTER")
	button.ColorBorder:SetBlendMode("ADD")
	button.ColorBorder:SetVertexColor(0.55, 0.56, 0.52)
	button.ColorBorder:SetAlpha(0.9)

	button.Selected = button:CreateTexture(nil, "OVERLAY")
	button.Selected:SetTexture(TEXTURE_RIM)
	button.Selected:SetBlendMode("ADD")
	button.Selected:SetSize(self.borderSize + 8, self.borderSize + 8)
	button.Selected:SetPoint("CENTER")
	button.Selected:SetVertexColor(1, 0.86, 0.18)
	button.Selected:SetAlpha(0.90)
	button.Selected:Hide()

	button.Hover = button:CreateTexture(nil, "OVERLAY")
	button.Hover:SetTexture(TEXTURE_HILITE_YELLOW)
	button.Hover:SetBlendMode("ADD")
	button.Hover:SetSize(self.buttonSize, self.buttonSize)
	button.Hover:SetPoint("CENTER")
	button.Hover:SetAlpha(0.34)
	button.Hover:Hide()

	button.Name = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Name:SetWidth(90)
	button.Name:SetPoint("TOP", button, "BOTTOM", 0, -4)
	button.Name:SetJustifyH("CENTER")
	if button.Name.SetMaxLines then
		button.Name:SetMaxLines(1)
	end

	if self.ring.createButtonRegions then
		self.ring.createButtonRegions(self, button, index)
	end

	button:SetScript("PostClick", function(buttonSelf, clickedButton, down)
		if self.ring.disableClickInCombat and InCombatLockdown() then
			return
		end
		local item = self:GetButtonItem(buttonSelf)
		self:Close()
		if self.ring.onClick then
			self.ring.onClick(self, buttonSelf, item, index, clickedButton, down)
		end
	end)
	button:SetScript("OnEnter", function(buttonSelf)
		self:Select(index)
		if self.ring.onEnter then
			self.ring.onEnter(self, buttonSelf, self:GetButtonItem(buttonSelf), index)
		end
	end)
	button:SetScript("OnLeave", function(buttonSelf)
		if self.ring.onLeave then
			self.ring.onLeave(self, buttonSelf, self:GetButtonItem(buttonSelf), index)
		else
			GameTooltip:Hide()
		end
	end)

	return button
end

function Methods:CreateLauncher()
	self.launcher = CreateFrame("Button", self.ring.launcherName, UIParent, "SecureActionButtonTemplate")
	self.launcher:SetSize(1, 1)
	self.launcher:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.ring.launcherX or -20, self.ring.launcherY or 20)
	self.launcher:SetAlpha(0)
	self.launcher:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "AnyDown", "AnyUp")
	self.launcher:SetScript("PostClick", function(_, button, down)
		self:OnLauncherPostClick(button, down)
	end)
	self.launcher:Show()
end

function Methods:CreateSelectors()
	self.keyOwner = CreateFrame("Frame", self.ring.keyOwnerName, UIParent, "SecureHandlerStateTemplate")
	self.selectors = {}

	if RegisterStateDriver then
		self.keyOwner:SetAttribute("_onstate-combat", [[
			if newstate then
				self:ClearBindings()
			end
		]])
		RegisterStateDriver(self.keyOwner, "combat", "[combat] true; nil")
	end

	for direction in pairs(DIRECTION_INDEX) do
		local dir = direction
		local selector = CreateFrame("Button", self.ring.selectorPrefix .. direction, UIParent, "SecureActionButtonTemplate")
		selector:SetSize(1, 1)
		selector:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self.ring.selectorX or -30, self.ring.selectorY or 30)
		selector:SetAlpha(0)
		selector:RegisterForClicks("AnyDown", "AnyUp")
		selector:SetScript("OnClick", function(_, button, down)
			local pressedDirection = DIRECTION_INDEX[button] and button or dir
			if down == false then
				self.keys[pressedDirection] = nil
				self:UpdateSelectionFromKeys()
			else
				self.keys[pressedDirection] = true
				self:UpdateSelectionFromKeys()
			end
		end)
		selector:Show()
		self.selectors[dir] = selector
	end
end

function Methods:CreateFrame()
	self:SetSize(420, 420)
	self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	self:SetFrameStrata("DIALOG")
	self:EnableKeyboard(true)
	self:Hide()

	self.BG = self:CreateTexture(nil, "BACKGROUND")
	self.BG:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Window\\Circle")
	self.BG:SetSize(390, 390)
	self.BG:SetPoint("CENTER")
	self.BG:SetAlpha(0.18)

	self.Connector = self:CreateTexture(nil, "BORDER")
	self.Connector:SetTexture(TEXTURE_CONNECTOR)
	self.Connector:SetSize(420, 420)
	self.Connector:SetPoint("CENTER")
	self.Connector:SetVertexColor(0.82, 0.84, 0.76)
	self.Connector:SetAlpha(0.85)

	self.Glow = self:CreateTexture(nil, "BORDER")
	self.Glow:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Utility\\UtilityCircle")
	self.Glow:SetSize(450, 450)
	self.Glow:SetPoint("CENTER")
	self.Glow:SetAlpha(0.10)
	self.Glow:SetBlendMode("ADD")

	self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.Title:SetPoint("CENTER", self, "CENTER", 0, 44)

	self.Subtitle = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, -8)

	if self.ring.createFrameRegions then
		self.ring.createFrameRegions(self)
	end

	if not self.Detail then
		self.Detail = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.Detail:SetPoint("TOP", self.Subtitle, "BOTTOM", 0, -24)
		self.Detail:SetWidth(230)
		self.Detail:SetJustifyH("CENTER")
	end

	self.buttons = {}
	for i = 1, self.maxButtons do
		self.buttons[i] = self:CreateButton(i)
	end

	self.keys = {}
	self:SetScript("OnKeyDown", function(frame, key)
		if key == "ESCAPE" then
			frame:Close()
			return
		end

		local direction = KEY_TO_DIRECTION[key]
		if direction then
			frame.keys[direction] = true
			frame:UpdateSelectionFromKeys()
		end
	end)
	self:SetScript("OnKeyUp", function(frame, key)
		local direction = KEY_TO_DIRECTION[key]
		if direction then
			frame.keys[direction] = nil
			frame:UpdateSelectionFromKeys()
		end
	end)
	self:SetScript("OnHide", function(frame)
		frame:ClearSelection()
		frame:ClearSelectionKeys()
		wipe(frame.keys)
	end)
end

function Methods:OnInitialize()
	self:CreateLauncher()
	self:CreateSelectors()
	self:CreateFrame()
	for _, event in ipairs(REFRESH_EVENTS) do
		pcall(self.RegisterEvent, self, event)
	end
	self:SetScript("OnEvent", function(frame, event)
		if event == "PLAYER_REGEN_DISABLED" then
			frame:CloseForCombat()
		else
			frame:RefreshSecureActions()
		end
	end)
	self:RefreshSecureActions()
end

function RingHelper:Mixin(frame, config)
	frame.ring = config
	frame.maxButtons = config.maxButtons or DEFAULT_MAX_BUTTONS
	frame.radius = config.radius or DEFAULT_RADIUS
	frame.buttonSize = config.buttonSize or DEFAULT_BUTTON_SIZE
	frame.borderSize = config.borderSize or DEFAULT_BORDER_SIZE

	for name, method in pairs(Methods) do
		frame[name] = method
	end

	return frame
end
