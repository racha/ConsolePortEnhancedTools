local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsFeedPetRing", UIParent)
ns.FeedPetAssistant = Assistant
CPE:RegisterModule("FeedPetAssistant", Assistant)

local MAX_BUTTONS = 8
local RADIUS = 142
local FEED_PET_SPELL_ID = 6991
local launcher

local QUALITY = {
	good = { text = "Best", happiness = 35, r = 0.25, g = 1.00, b = 0.35, rank = 4 },
	ok = { text = "Good", happiness = 17, r = 1.00, g = 0.82, b = 0.20, rank = 3 },
	poor = { text = "Weak", happiness = 8, r = 1.00, g = 0.45, b = 0.20, rank = 2 },
	low = { text = "Too low", happiness = 0, r = 0.65, g = 0.65, b = 0.65, rank = 1 },
	unknown = { text = "Unknown", happiness = 0, r = 0.70, g = 0.70, b = 1.00, rank = 0 },
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

local function ColorText(text, q)
	return ("|cff%02x%02x%02x%s|r"):format(
		math.floor(q.r * 255 + 0.5),
		math.floor(q.g * 255 + 0.5),
		math.floor(q.b * 255 + 0.5),
		text
	)
end

local function SetIcon(texture, icon)
	if SetPortraitToTexture then
		SetPortraitToTexture(texture, icon)
	else
		texture:SetTexture(icon)
	end
end

local function GetFeedPetSpellName()
	return GetSpellInfo(FEED_PET_SPELL_ID) or "Feed Pet"
end

local function GetFoodQuality(itemLevel, petLevel)
	if not itemLevel or itemLevel <= 0 or not petLevel then
		return QUALITY.unknown
	end

	local delta = petLevel - itemLevel
	if delta <= 15 then
		return QUALITY.good
	elseif delta <= 25 then
		return QUALITY.ok
	elseif delta <= 35 then
		return QUALITY.poor
	end
	return QUALITY.low
end

local function GetPetHappinessText()
	local happiness = GetPetHappiness and GetPetHappiness()
	if happiness == 3 then
		return "|cff40ff60Happy|r"
	elseif happiness == 2 then
		return "|cffffff40Content|r"
	elseif happiness == 1 then
		return "|cffff4040Unhappy|r"
	end
	return "|cffaaaaaaUnknown|r"
end

local function GetDietSet()
	local diet = {}
	local labels = {}
	local foods = { GetPetFoodTypes() }

	for _, foodType in ipairs(foods) do
		diet[foodType] = true
		tinsert(labels, foodType)
	end

	return diet, table.concat(labels, ", ")
end

local function SortFoods(a, b)
	if a.quality.rank ~= b.quality.rank then
		return a.quality.rank > b.quality.rank
	end
	if a.itemLevel ~= b.itemLevel then
		return a.itemLevel > b.itemLevel
	end
	if a.count ~= b.count then
		return a.count < b.count
	end
	return a.name < b.name
end

function Assistant:ScanFood()
	local diet, dietText = GetDietSet()
	local petLevel = UnitLevel("pet")
	local foods = {}

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemID = CPE:GetItemID(link)
			local foodType, fallbackLevel = CPE:GetFoodInfo(itemID)

			if foodType and diet[foodType] then
				local texture, count = GetContainerItemInfo(bag, slot)
				local name, _, _, itemLevel, _, _, _, _, _, icon = GetItemInfo(link or itemID)

				itemLevel = fallbackLevel or itemLevel or 0
				texture = icon or texture

				if name and texture then
					local quality = GetFoodQuality(itemLevel, petLevel)
					tinsert(foods, {
						bag = bag,
						slot = slot,
						itemID = itemID,
						link = link,
						name = name,
						texture = texture,
						count = count or 1,
						foodType = foodType,
						itemLevel = itemLevel,
						quality = quality,
					})
				end
			end
		end
	end

	table.sort(foods, SortFoods)
	return foods, dietText
end

function Assistant:Feed(food)
	if not food then return end
	if InCombatLockdown() then
		CPE:Print("You cannot feed your pet in combat.")
		return
	end
	if not UnitExists("pet") then
		CPE:Print("No active pet.")
		return
	end
	if UnitIsDead("pet") then
		CPE:Print("Your pet is dead.")
		return
	end

	CastSpellByName(GetFeedPetSpellName())
	UseContainerItem(food.bag, food.slot)
	self:Hide()
end

function Assistant:Select(index)
	local button = self.buttons and self.buttons[index]
	if not button or not button:IsShown() or not button.food then return end

	if self.selected and self.selected.Selected then
		self.selected.Selected:Hide()
	end

	self.selected = button
	self.selectedIndex = index
	button.Selected:Show()
	self.Detail:SetText(button.food.name .. "\n" .. ColorText(button.food.quality.text, button.food.quality))
end

function Assistant:UpdateSelectionFromKeys()
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
	end
end

function Assistant:ToggleFromBinding()
	if self:IsShown() then
		if self.selected and self.selected.food then
			self:Feed(self.selected.food)
		else
			self:Hide()
		end
	else
		self:Open()
	end
end

function Assistant:Open()
	if InCombatLockdown() then
		CPE:Print("Feed Pet Assistant is unavailable in combat.")
		return
	end
	if not CPE:IsHunter() then
		CPE:Print("Feed Pet Assistant is only available to hunters.")
		return
	end
	if not UnitExists("pet") then
		CPE:Print("No active pet.")
		return
	end

	local foods, dietText = self:ScanFood()
	self.foods = foods
	self.dietText = dietText

	if #foods == 0 then
		CPE:Print("No known compatible pet food found in your bags.")
		return
	end

	self:Refresh()
	self:Show()
	self:Select(1)
end

function Assistant:Refresh()
	local count = math.min(#self.foods, MAX_BUTTONS)
	local petLevel = UnitLevel("pet") or "?"

	self.Title:SetText("Feed Pet Assistant")
	self.Subtitle:SetText(("Pet level %s  |  %s"):format(petLevel, GetPetHappinessText()))
	self.Diet:SetText("Eats: " .. (self.dietText ~= "" and self.dietText or "unknown"))

	for i = 1, MAX_BUTTONS do
		local button = self.buttons[i]
		local food = self.foods[i]
		if i <= count and food then
			button.food = food
			SetIcon(button.Icon, food.texture)
			button.Count:SetText(food.count > 1 and food.count or "")
			button.Name:SetText(food.name)
			button.Level:SetText(("iLvl %s"):format(food.itemLevel > 0 and food.itemLevel or "?"))
			button.Quality:SetText(ColorText(food.quality.text, food.quality))
			button.Border:SetVertexColor(food.quality.r, food.quality.g, food.quality.b)
			button:Show()
		else
			button.food = nil
			button:Hide()
		end
	end

	if #self.foods > MAX_BUTTONS then
		self.More:SetText(("Showing best %d of %d foods."):format(MAX_BUTTONS, #self.foods))
	else
		self.More:SetText("")
	end
end

function Assistant:CreateButton(index)
	local button = CreateFrame("Button", "$parentFood" .. index, self)
	button:SetSize(64, 64)
	button:RegisterForClicks("AnyUp")

	local angle = math.rad(90 - ((index - 1) * 45))
	button:SetPoint("CENTER", self, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)

	button.Icon = button:CreateTexture(nil, "ARTWORK")
	button.Icon:SetAllPoints(button)

	button.Border = button:CreateTexture(nil, "OVERLAY")
	button.Border:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\UtilityBorder")
	button.Border:SetSize(82, 82)
	button.Border:SetPoint("CENTER")

	button.Selected = button:CreateTexture(nil, "OVERLAY")
	button.Selected:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Button\\Hilite")
	button.Selected:SetBlendMode("ADD")
	button.Selected:SetAllPoints(button)
	button.Selected:Hide()

	button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

	button.Name = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	button.Name:SetWidth(104)
	button.Name:SetPoint("TOP", button, "BOTTOM", 0, -4)
	button.Name:SetJustifyH("CENTER")
	if button.Name.SetMaxLines then
		button.Name:SetMaxLines(2)
	end

	button.Level = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.Level:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)

	button.Quality = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.Quality:SetPoint("TOP", button.Level, "BOTTOM", 0, -1)

	button:SetScript("OnClick", function(self)
		Assistant:Feed(self.food)
	end)
	button:SetScript("OnEnter", function(self)
		Assistant:Select(index)
		if self.food then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetBagItem(self.food.bag, self.food.slot)
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Pet food: " .. self.food.foodType, 0.6, 0.8, 1)
			GameTooltip:AddLine(("Happiness: %s per tick"):format(self.food.quality.happiness), self.food.quality.r, self.food.quality.g, self.food.quality.b)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return button
end

function Assistant:CreateLauncher()
	launcher = CreateFrame("Button", "ConsolePortEnhancedToolsFeedPetAssistant", UIParent)
	launcher:SetSize(1, 1)
	launcher:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -20, 20)
	launcher:SetAlpha(0)
	launcher:RegisterForClicks("AnyUp")
	launcher:SetScript("OnClick", function()
		Assistant:ToggleFromBinding()
	end)
	launcher:Show()
end

function Assistant:CreateFrame()
	self:SetSize(420, 420)
	self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	self:SetFrameStrata("DIALOG")
	self:EnableKeyboard(true)
	self:Hide()

	self.BG = self:CreateTexture(nil, "BACKGROUND")
	self.BG:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Window\\Circle")
	self.BG:SetSize(330, 330)
	self.BG:SetPoint("CENTER")
	self.BG:SetAlpha(0.78)

	self.Glow = self:CreateTexture(nil, "BORDER")
	self.Glow:SetTexture("Interface\\AddOns\\ConsolePort\\Textures\\Utility\\UtilityGlow8")
	self.Glow:SetSize(430, 430)
	self.Glow:SetPoint("CENTER")
	self.Glow:SetAlpha(0.38)
	self.Glow:SetBlendMode("ADD")

	self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	self.Title:SetPoint("CENTER", self, "CENTER", 0, 44)

	self.Subtitle = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.Subtitle:SetPoint("TOP", self.Title, "BOTTOM", 0, -8)

	self.Diet = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.Diet:SetPoint("TOP", self.Subtitle, "BOTTOM", 0, -6)

	self.Detail = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.Detail:SetPoint("TOP", self.Diet, "BOTTOM", 0, -20)
	self.Detail:SetWidth(210)
	self.Detail:SetJustifyH("CENTER")

	self.More = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	self.More:SetPoint("BOTTOM", self, "BOTTOM", 0, 42)

	self.buttons = {}
	for i = 1, MAX_BUTTONS do
		self.buttons[i] = self:CreateButton(i)
	end

	self.keys = {}
	self:SetScript("OnKeyDown", function(frame, key)
		if key == "ESCAPE" then
			frame:Hide()
			return
		elseif key == "SPACE" or key == "ENTER" then
			if frame.selected and frame.selected.food then
				frame:Feed(frame.selected.food)
			end
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
		if frame.selected and frame.selected.Selected then
			frame.selected.Selected:Hide()
		end
		frame.selected = nil
		frame.selectedIndex = nil
		wipe(frame.keys)
	end)
end

function Assistant:OnInitialize()
	self:CreateLauncher()
	self:CreateFrame()
end
