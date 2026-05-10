local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsConsumablesRing", UIParent)
ns.ConsumablesAssistant = Assistant
CPE:RegisterModule("ConsumablesAssistant", Assistant)

local SCANNER = CreateFrame("GameTooltip", "ConsolePortEnhancedToolsConsumableScanner", UIParent, "GameTooltipTemplate")
SCANNER:SetOwner(UIParent, "ANCHOR_NONE")

local function GetTooltipText(bag, slot)
	SCANNER:ClearLines()
	SCANNER:SetBagItem(bag, slot)
	local lines = {}
	for i = 1, SCANNER:NumLines() do
		local left = _G["ConsolePortEnhancedToolsConsumableScannerTextLeft" .. i]
		local text = left and left:GetText()
		if text then
			tinsert(lines, text:lower())
		end
	end
	return table.concat(lines, "\n")
end

local function GetCooldownText(start, duration)
	if start and duration and duration > 1.5 then
		local left = math.max(0, start + duration - GetTime())
		return ("%ds"):format(left + 0.5)
	end
	return ""
end

local function AnalyzeConsumable(bag, slot, itemType, itemSubType)
	local text = GetTooltipText(bag, slot)
	local health = text:find("restores? [%d,]+ health over") or text:find("health over")
	local mana = text:find("restores? [%d,]+ mana over") or text:find("mana over")
	local seated = text:find("must remain seated")
	local foodDrink = itemSubType == "Food & Drink" or seated
	local otherConsumable = itemType == "Consumable" and not foodDrink

	return foodDrink, health, mana, otherConsumable
end

local function ConsumableScore(item)
	local score = item.itemLevel or 0
	if item.count and item.count > 1 then
		score = score + 0.01
	end
	return score
end

local function BetterConsumable(a, b)
	if not a then return b end
	if not b then return a end
	if ConsumableScore(b) > ConsumableScore(a) then
		return b
	end
	return a
end

local function SortOther(a, b)
	if a.usable ~= b.usable then
		return a.usable
	end
	if a.cooldown ~= b.cooldown then
		return not a.cooldown
	end
	if a.itemLevel ~= b.itemLevel then
		return a.itemLevel > b.itemLevel
	end
	return a.name < b.name
end

local function ScanConsumables()
	local bestFood
	local bestDrink
	local others = {}

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemID = CPE:GetItemID(link)
			if itemID then
				local texture, count = GetContainerItemInfo(bag, slot)
				local name, _, _, itemLevel, _, itemType, itemSubType, _, _, icon = GetItemInfo(link or itemID)
				if name then
					local usable = IsUsableItem(link or itemID)
					local start, duration = GetContainerItemCooldown(bag, slot)
					local cooldown = duration and duration > 1.5
					local foodDrink, health, mana, otherConsumable = AnalyzeConsumable(bag, slot, itemType, itemSubType)
					local item = {
						bag = bag,
						slot = slot,
						itemID = itemID,
						link = link,
						name = name,
						icon = icon or texture,
						count = count or 1,
						itemLevel = itemLevel or 0,
						usable = usable,
						cooldown = cooldown,
						cooldownText = GetCooldownText(start, duration),
						description = CPE:GetBagItemDescription(bag, slot),
					}

					if foodDrink and usable then
						if health then
							item.category = "Food"
							bestFood = BetterConsumable(bestFood, item)
						end
						if mana then
							local drink = {}
							for k, v in pairs(item) do
								drink[k] = v
							end
							drink.category = "Drink"
							bestDrink = BetterConsumable(bestDrink, drink)
						end
					elseif otherConsumable and (usable or cooldown) then
						item.category = itemSubType or "Consumable"
						tinsert(others, item)
					end
				end
			end
		end
	end

	table.sort(others, SortOther)

	local items = {}
	if bestFood then
		tinsert(items, bestFood)
	end
	if bestDrink and not (bestFood and bestDrink.bag == bestFood.bag and bestDrink.slot == bestFood.slot) then
		tinsert(items, bestDrink)
	end
	for _, item in ipairs(others) do
		if #items >= 8 then break end
		tinsert(items, item)
	end

	return items
end

local function SetConsumableButtonAction(self, button, item)
	if not button then return end
	if InCombatLockdown() then return end
	if item then
		button:SetAttribute("type", "item")
		button:SetAttribute("item", item.name)
		button:SetAttribute("macrotext", nil)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("item", nil)
		button:SetAttribute("macrotext", nil)
	end
end

local function OnSelect(self, button, item)
	if item then
		local state = item.cooldown and ("|cffffff40Cooldown " .. item.cooldownText .. "|r") or (item.usable and "|cff40ff60Usable|r" or "|cffaaaaaaConsumable|r")
		self.Detail:SetText(CPE:AppendDescription(item.category .. "\n" .. item.name .. "\n" .. state, item.description))
	else
		self.Detail:SetText("|cff888888No consumable|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Consumables Ring")
	self.Subtitle:SetText("Best food, best drink, usable consumables")
end

local function UpdateConsumableButton(self, button, item)
	button.consumable = item
	ns.RingHelper:SetIcon(button.Icon, item.icon or "Interface\\Icons\\INV_Misc_Food_65")
	button.Count:SetText(item.count > 1 and item.count or "")
	self:SetButtonName(button, item.category, 12)
	button.ItemName:SetText(item.name:len() > 13 and (item.name:sub(1, 12) .. ".") or item.name)
	if item.cooldown then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	elseif item.category == "Food" then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	elseif item.category == "Drink" then
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	else
		self:SetButtonStateColor(button, 0.70, 0.70, 1.00)
	end
end

local function ClearConsumableButton(self, button)
	button.consumable = nil
	button.Icon:SetTexture(nil)
	button.Count:SetText("")
	self:SetButtonName(button, "")
	button.ItemName:SetText("")
	self:ClearButtonState(button)
end

local function CreateConsumableRegions(self, button)
	button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

	button.ItemName = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.ItemName:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
	button.ItemName:SetWidth(112)
	button.ItemName:SetJustifyH("CENTER")
	if button.ItemName.SetMaxLines then
		button.ItemName:SetMaxLines(1)
	end
end

local function ShowConsumableTooltip(self, button, item)
	if not item then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(item.bag, item.slot)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Consumables Ring",
	launcherName = "ConsolePortEnhancedToolsConsumablesAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsConsumablesKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsConsumablesSelect",
	selectorX = -62,
	selectorY = 62,
	launcherX = -52,
	launcherY = 52,
	buttonName = "Consumable",
	itemKey = "consumable",
	itemsKey = "consumables",
	idleText = "|cff888888Move to select consumable|r",
	emptyMessage = "No usable consumables found in your bags.",
	scan = ScanConsumables,
	setButtonAction = SetConsumableButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateConsumableButton,
	clearButton = ClearConsumableButton,
	createButtonRegions = CreateConsumableRegions,
	onEnter = ShowConsumableTooltip,
})
