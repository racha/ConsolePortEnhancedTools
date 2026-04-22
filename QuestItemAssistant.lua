local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsQuestItemRing", UIParent)
ns.QuestItemAssistant = Assistant
CPE:RegisterModule("QuestItemAssistant", Assistant)

local function IsQuestItem(bag, slot, itemType)
	if GetContainerItemQuestInfo then
		local isQuestItem = GetContainerItemQuestInfo(bag, slot)
		if isQuestItem then
			return true
		end
	end
	return itemType == "Quest"
end

local function GetCooldownText(start, duration)
	if start and duration and duration > 1.5 then
		local left = math.max(0, start + duration - GetTime())
		return ("%ds"):format(left + 0.5)
	end
	return ""
end

local function SortQuestItems(a, b)
	if a.usable ~= b.usable then
		return a.usable
	end
	if a.cooldown ~= b.cooldown then
		return not a.cooldown
	end
	return a.name < b.name
end

local function ScanQuestItems()
	local items = {}

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemID = CPE:GetItemID(link)
			if itemID then
				local name, _, _, itemLevel, _, itemType, _, _, _, icon = GetItemInfo(link or itemID)
				if name and IsQuestItem(bag, slot, itemType) then
					local usable = IsUsableItem(link or itemID)
					local start, duration = GetContainerItemCooldown(bag, slot)
					local cooldown = duration and duration > 1.5
					if usable or cooldown then
						tinsert(items, {
							bag = bag,
							slot = slot,
							itemID = itemID,
							link = link,
							name = name,
							icon = icon,
							itemLevel = itemLevel or 0,
							usable = usable,
							cooldown = cooldown,
							cooldownText = GetCooldownText(start, duration),
						})
					end
				end
			end
		end
	end

	table.sort(items, SortQuestItems)
	return items
end

local function SetQuestItemButtonAction(self, button, item)
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
		local state = item.cooldown and ("|cffffff40Cooldown " .. item.cooldownText .. "|r") or (item.usable and "|cff40ff60Usable|r" or "|cffaaaaaaQuest item|r")
		self.Detail:SetText(item.name .. "\n" .. state)
	else
		self.Detail:SetText("|cff888888No quest item|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Quest Item Ring")
	self.Subtitle:SetText("Usable quest items in bags")
end

local function UpdateQuestItemButton(self, button, item)
	button.questItem = item
	ns.RingHelper:SetIcon(button.Icon, item.icon or "Interface\\Icons\\INV_Misc_Note_02")
	self:SetButtonName(button, item.name, 13)
	button.State:SetText(item.cooldown and item.cooldownText or "")
	if item.cooldown then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	elseif item.usable then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	else
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	end
end

local function ClearQuestItemButton(self, button)
	button.questItem = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateQuestItemRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowQuestItemTooltip(self, button, item)
	if not item then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetBagItem(item.bag, item.slot)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Quest Item Ring",
	launcherName = "ConsolePortEnhancedToolsQuestItemAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsQuestItemKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsQuestItemSelect",
	selectorX = -54,
	selectorY = 54,
	launcherX = -44,
	launcherY = 44,
	buttonName = "QuestItem",
	itemKey = "questItem",
	itemsKey = "questItems",
	idleText = "|cff888888Move to select quest item|r",
	emptyMessage = "No usable quest items found in your bags.",
	scan = ScanQuestItems,
	setButtonAction = SetQuestItemButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateQuestItemButton,
	clearButton = ClearQuestItemButton,
	createButtonRegions = CreateQuestItemRegions,
	onEnter = ShowQuestItemTooltip,
})
