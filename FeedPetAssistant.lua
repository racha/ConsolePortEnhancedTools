local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsFeedPetRing", UIParent)
ns.FeedPetAssistant = Assistant
CPE:RegisterModule("FeedPetAssistant", Assistant)

local FEED_PET_SPELL_ID = 6991

local QUALITY = {
	good = { text = "Best", happiness = 35, r = 0.25, g = 1.00, b = 0.35, rank = 4 },
	ok = { text = "Good", happiness = 17, r = 1.00, g = 0.82, b = 0.20, rank = 3 },
	poor = { text = "Weak", happiness = 8, r = 1.00, g = 0.45, b = 0.20, rank = 2 },
	low = { text = "Too low", happiness = 0, r = 0.65, g = 0.65, b = 0.65, rank = 1 },
	unknown = { text = "Unknown", happiness = 0, r = 0.70, g = 0.70, b = 1.00, rank = 0 },
}

local function ColorText(text, q)
	return ("|cff%02x%02x%02x%s|r"):format(
		math.floor(q.r * 255 + 0.5),
		math.floor(q.g * 255 + 0.5),
		math.floor(q.b * 255 + 0.5),
		text
	)
end

local function GetFeedPetSpellName()
	return GetSpellInfo(FEED_PET_SPELL_ID) or "Feed Pet"
end

local function GetFeedMacro(food)
	return ("/cast %s\n/use %d %d"):format(GetFeedPetSpellName(), food.bag, food.slot)
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

local function ValidateFeedAssistant()
	if not CPE:IsHunter() then
		CPE:Print("Feed Pet Assistant is only available to hunters.")
		return false
	end
	if not UnitExists("pet") then
		CPE:Print("No active pet.")
		return false
	end
	return true
end

local function ScanFood(self)
	local diet, dietText = GetDietSet()
	local petLevel = UnitLevel("pet")
	local foods = {}

	self.dietText = dietText

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
						description = CPE:GetBagItemDescription(bag, slot),
					})
				end
			end
		end
	end

	table.sort(foods, SortFoods)
	return foods
end

local function SetFoodButtonAction(self, button, food)
	if not button then return end
	if InCombatLockdown() then return end
	if food then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", GetFeedMacro(food))
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
	end
end

local function OnSelect(self, button, food)
	if food then
		local detail = food.name .. "\n" .. ColorText(food.quality.text, food.quality)
			.. "\n|cffbbbbbb" .. food.foodType .. "  |  +" .. food.quality.happiness .. " happiness/tick|r"
		self.Detail:SetText(CPE:AppendDescription(detail, food.description))
	else
		self.Detail:SetText("|cff888888No food|r")
	end
end

local function RefreshHeader(self)
	local petLevel = UnitLevel("pet") or "?"
	self.Title:SetText("Feed Pet Assistant")
	self.Subtitle:SetText(("Pet level %s  |  %s"):format(petLevel, GetPetHappinessText()))
	self.Diet:SetText("Eats: " .. (self.dietText ~= "" and self.dietText or "unknown"))
end

local function UpdateFoodButton(self, button, food)
	button.food = food
	ns.RingHelper:SetIcon(button.Icon, food.texture)
	button.Count:SetText(food.count > 1 and food.count or "")
	self:SetButtonName(button, food.name, 13)
	button.Level:SetText(("iLvl %s"):format(food.itemLevel > 0 and food.itemLevel or "?"))
	button.Quality:SetText(ColorText(food.quality.text, food.quality))
	self:SetButtonStateColor(button, food.quality.r, food.quality.g, food.quality.b)
end

local function ClearFoodButton(self, button)
	button.food = nil
	button.Icon:SetTexture(nil)
	button.Count:SetText("")
	self:SetButtonName(button, "")
	button.Level:SetText("")
	button.Quality:SetText("")
	self:ClearButtonState(button)
end

local function AfterRefresh(self, foods)
	if #foods > self.maxButtons then
		self.More:SetText(("Showing best %d of %d foods."):format(self.maxButtons, #foods))
	else
		self.More:SetText("")
	end
end

local function CreateFoodRegions(self, button)
	button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

	button.Level = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.Level:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)

	button.Quality = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.Quality:SetPoint("TOP", button.Level, "BOTTOM", 0, -1)
end

local function CreateFeedFrameRegions(self)
	self.Diet = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.Diet:SetPoint("TOP", self.Subtitle, "BOTTOM", 0, -6)

	self.Detail = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.Detail:SetPoint("TOP", self.Diet, "BOTTOM", 0, -20)
	self.Detail:SetWidth(210)
	self.Detail:SetJustifyH("CENTER")

	self.More = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	self.More:SetPoint("BOTTOM", self, "BOTTOM", 0, 42)
end

local function ShowFoodTooltip(self, button, food)
	if not food then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(food.bag, food.slot)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Pet food: " .. food.foodType, 0.6, 0.8, 1)
	GameTooltip:AddLine(("Happiness: %s per tick"):format(food.quality.happiness), food.quality.r, food.quality.g, food.quality.b)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Feed Pet Assistant",
	launcherName = "ConsolePortEnhancedToolsFeedPetAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsFeedPetKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsFeedPetSelect",
	buttonName = "Food",
	itemKey = "food",
	itemsKey = "foods",
	idleText = "|cff888888Move to select food|r",
	emptyMessage = "No known compatible pet food found in your bags.",
	validate = ValidateFeedAssistant,
	scan = ScanFood,
	setButtonAction = SetFoodButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateFoodButton,
	clearButton = ClearFoodButton,
	afterRefresh = AfterRefresh,
	createButtonRegions = CreateFoodRegions,
	createFrameRegions = CreateFeedFrameRegions,
	onEnter = ShowFoodTooltip,
})
