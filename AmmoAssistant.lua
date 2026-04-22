local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsAmmoRing", UIParent)
ns.AmmoAssistant = Assistant
CPE:RegisterModule("AmmoAssistant", Assistant)

local AMMO_SLOT = GetInventorySlotInfo("AmmoSlot")

local function ValidateAmmoAssistant()
	if not CPE:IsHunter() then
		CPE:Print("Ammo Assistant is only available to hunters.")
		return false
	end
	return true
end

local function IsAmmo(itemEquipLoc, itemType)
	return itemEquipLoc == "INVTYPE_AMMO" or itemType == "Projectile"
end

local function SortAmmo(a, b)
	if a.current ~= b.current then
		return a.current
	end
	if a.itemLevel ~= b.itemLevel then
		return a.itemLevel > b.itemLevel
	end
	if a.count ~= b.count then
		return a.count > b.count
	end
	return a.name < b.name
end

local function AddAmmo(ammoByID, ammo)
	local existing = ammoByID[ammo.itemID]
	if existing then
		existing.count = existing.count + ammo.count
		if ammo.itemLevel > existing.itemLevel then
			existing.itemLevel = ammo.itemLevel
		end
	else
		ammoByID[ammo.itemID] = ammo
	end
end

local function ScanAmmo()
	local ammoByID = {}
	local equippedLink = GetInventoryItemLink("player", AMMO_SLOT)
	local equippedID = CPE:GetItemID(equippedLink)

	if equippedID then
		local name, _, _, itemLevel, _, itemType, _, _, itemEquipLoc, icon = GetItemInfo(equippedLink or equippedID)
		if name then
			AddAmmo(ammoByID, {
				itemID = equippedID,
				link = equippedLink,
				name = name,
				icon = icon,
				itemLevel = itemLevel or 0,
				count = GetInventoryItemCount("player", AMMO_SLOT) or 0,
				current = true,
				equippable = false,
				itemType = itemType,
				itemEquipLoc = itemEquipLoc,
			})
		end
	end

	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local itemID = CPE:GetItemID(link)
			if itemID then
				local texture, count = GetContainerItemInfo(bag, slot)
				local name, _, _, itemLevel, _, itemType, _, _, itemEquipLoc, icon = GetItemInfo(link or itemID)
				if name and IsAmmo(itemEquipLoc, itemType) then
					AddAmmo(ammoByID, {
						bag = bag,
						slot = slot,
						itemID = itemID,
						link = link,
						name = name,
						icon = icon or texture,
						itemLevel = itemLevel or 0,
						count = count or 1,
						current = itemID == equippedID,
						equippable = itemID ~= equippedID,
						itemType = itemType,
						itemEquipLoc = itemEquipLoc,
					})
				end
			end
		end
	end

	local ammo = {}
	for _, item in pairs(ammoByID) do
		tinsert(ammo, item)
	end
	table.sort(ammo, SortAmmo)
	return ammo
end

local function SetAmmoButtonAction(self, button, ammo)
	if not button then return end
	if InCombatLockdown() then return end
	if ammo and ammo.equippable then
		button:SetAttribute("type", "item")
		button:SetAttribute("item", ammo.name)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("item", nil)
	end
	button:SetAttribute("macrotext", nil)
end

local function OnSelect(self, button, ammo)
	if ammo then
		local status = ammo.current and "|cff40ff60Equipped|r" or "|cffffff40Release to equip|r"
		self.Detail:SetText(ammo.name .. "\n" .. status)
	else
		self.Detail:SetText("|cff888888No ammo|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Ammo Assistant")
	self.Subtitle:SetText("Equipped ammo and bag ammo")
end

local function UpdateAmmoButton(self, button, ammo)
	button.ammo = ammo
	ns.RingHelper:SetIcon(button.Icon, ammo.icon or "Interface\\Icons\\INV_Ammo_Arrow_02")
	button.Count:SetText(ammo.count > 0 and ammo.count or "")
	self:SetButtonName(button, ammo.name, 13)
	button.Level:SetText(("iLvl %s"):format(ammo.itemLevel > 0 and ammo.itemLevel or "?"))
	button.State:SetText(ammo.current and "|cff40ff60Now|r" or "")

	if ammo.current then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	elseif ammo.equippable then
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	else
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	end
end

local function ClearAmmoButton(self, button)
	button.ammo = nil
	button.Icon:SetTexture(nil)
	button.Count:SetText("")
	self:SetButtonName(button, "")
	button.Level:SetText("")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateAmmoRegions(self, button)
	button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count:SetPoint("BOTTOMRIGHT", -2, 2)

	button.Level = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.Level:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)

	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Level, "BOTTOM", 0, -1)
end

local function ShowAmmoTooltip(self, button, ammo)
	if not ammo then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	if ammo.bag and ammo.slot then
		GameTooltip:SetBagItem(ammo.bag, ammo.slot)
	elseif ammo.link then
		GameTooltip:SetHyperlink(ammo.link)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Ammo Assistant",
	launcherName = "ConsolePortEnhancedToolsAmmoAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsAmmoKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsAmmoSelect",
	selectorX = -86,
	selectorY = 86,
	launcherX = -76,
	launcherY = 76,
	buttonName = "Ammo",
	itemKey = "ammo",
	itemsKey = "ammoItems",
	idleText = "|cff888888Move to select ammo|r",
	emptyMessage = "No ammo found equipped or in bags.",
	validate = ValidateAmmoAssistant,
	scan = ScanAmmo,
	setButtonAction = SetAmmoButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateAmmoButton,
	clearButton = ClearAmmoButton,
	createButtonRegions = CreateAmmoRegions,
	onEnter = ShowAmmoTooltip,
})
