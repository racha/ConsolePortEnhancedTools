local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsMountRing", UIParent)
ns.MountAssistant = Assistant
CPE:RegisterModule("MountAssistant", Assistant)

local ICON_MOUNT = "Interface\\Icons\\Ability_Mount_RidingHorse"
local ICON_DISMOUNT = "Interface\\Icons\\Ability_Mount_Dreadsteed"

local function ScanMounts()
	local mounts = {}

	if IsMounted and IsMounted() then
		tinsert(mounts, {
			kind = "dismount",
			name = "Dismount",
			icon = ICON_DISMOUNT,
			state = "|cffffff40Mounted|r",
			description = "Dismount from your current mount.",
		})
	end

	local count = GetNumCompanions and GetNumCompanions("MOUNT") or 0
	for index = 1, count do
		if #mounts >= 8 then break end
		local _, name, spellID, icon, active = GetCompanionInfo("MOUNT", index)
		if name then
			tinsert(mounts, {
				kind = "mount",
				index = index,
				name = name,
				spellID = spellID,
				icon = icon or ICON_MOUNT,
				state = active and "|cff40ff60Active|r" or "",
				description = active and "This mount is currently active." or "Summon this mount.",
			})
		end
	end

	return mounts
end

local function SetMountButtonAction(self, button, mount)
	if not button then return end
	if InCombatLockdown() then return end
	if mount and mount.kind == "dismount" then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", "/dismount")
	elseif mount and mount.index then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", ("/run CallCompanion(\"MOUNT\", %d)"):format(mount.index))
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
	end
end

local function OnSelect(self, button, mount)
	if mount then
		self.Detail:SetText(CPE:AppendDescription(mount.name .. "\n" .. (mount.state ~= "" and mount.state or "|cff40ff60Ready|r"), mount.description))
	else
		self.Detail:SetText("|cff888888No mount|r")
	end
end

local function RefreshHeader(self, mounts)
	self.Title:SetText("Mount Ring")
	self.Subtitle:SetText((mounts and #mounts > 0) and "Known companion mounts" or "No mounts learned")
end

local function UpdateMountButton(self, button, mount)
	button.mount = mount
	ns.RingHelper:SetIcon(button.Icon, mount.icon or ICON_MOUNT)
	self:SetButtonName(button, mount.name, 13)
	button.State:SetText(mount.state or "")

	if mount.kind == "dismount" then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	elseif mount.state ~= "" then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	else
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	end
end

local function ClearMountButton(self, button)
	button.mount = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateMountRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowMountTooltip(self, button, mount)
	if not mount then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	if mount.spellID and GameTooltip.SetSpellByID then
		GameTooltip:SetSpellByID(mount.spellID)
	else
		GameTooltip:AddLine(mount.name, 1, 0.82, 0.2)
		GameTooltip:AddLine(mount.description, 0.75, 0.75, 0.75, true)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Mount Ring",
	launcherName = "ConsolePortEnhancedToolsMountAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsMountKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsMountSelect",
	selectorX = -110,
	selectorY = 110,
	launcherX = -100,
	launcherY = 100,
	buttonName = "Mount",
	itemKey = "mount",
	itemsKey = "mounts",
	idleText = "|cff888888Move to select mount|r",
	emptyMessage = "No mounts learned.",
	scan = ScanMounts,
	setButtonAction = SetMountButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateMountButton,
	clearButton = ClearMountButton,
	createButtonRegions = CreateMountRegions,
	onEnter = ShowMountTooltip,
})
