local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsPartyRing", UIParent)
ns.PartyAssistant = Assistant
CPE:RegisterModule("PartyAssistant", Assistant)

local function GetUnitHealthText(unit)
	if UnitIsDeadOrGhost(unit) then
		return "Dead"
	end
	if not UnitIsConnected(unit) then
		return "Offline"
	end
	local maxHealth = UnitHealthMax(unit)
	if maxHealth and maxHealth > 0 then
		return ("%d%%"):format((UnitHealth(unit) / maxHealth) * 100 + 0.5)
	end
	return ""
end

local function ScanParty()
	local members = {}

	for i = 1, 4 do
		local unit = "party" .. i
		if UnitExists(unit) then
			local name = UnitName(unit)
			local _, class = UnitClass(unit)
			local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
			tinsert(members, {
				unit = unit,
				name = name or unit,
				class = class,
				r = color and color.r or 0.7,
				g = color and color.g or 0.7,
				b = color and color.b or 0.7,
				health = GetUnitHealthText(unit),
				dead = UnitIsDeadOrGhost(unit),
				offline = not UnitIsConnected(unit),
				description = class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class],
			})
		end
	end

	return members
end

local function SetPartyButtonAction(self, button, member)
	if not button then return end
	if InCombatLockdown() then return end
	if member then
		button:SetAttribute("type", "target")
		button:SetAttribute("unit", member.unit)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("unit", nil)
	end
end

local function OnSelect(self, button, member)
	if member then
		self.Detail:SetText(CPE:AppendDescription(member.name .. "\n" .. member.health, member.description))
	else
		self.Detail:SetText("|cff888888No party member|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Party Assistant")
	self.Subtitle:SetText("Select party member")
end

local function UpdatePartyButton(self, button, member)
	button.member = member
	SetPortraitTexture(button.Icon, member.unit)
	self:SetButtonName(button, member.name, 13)
	button.State:SetText(member.health)
	if member.dead or member.offline then
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	else
		self:SetButtonStateColor(button, member.r, member.g, member.b)
	end
end

local function ClearPartyButton(self, button)
	button.member = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreatePartyRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowPartyTooltip(self, button, member)
	if not member then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:SetUnit(member.unit)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Party Assistant",
	launcherName = "ConsolePortEnhancedToolsPartyAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsPartyKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsPartySelect",
	selectorX = -78,
	selectorY = 78,
	launcherX = -68,
	launcherY = 68,
	buttonName = "Party",
	itemKey = "member",
	itemsKey = "members",
	idleText = "|cff888888Move to select party member|r",
	emptyMessage = "No party members found.",
	scan = ScanParty,
	setButtonAction = SetPartyButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdatePartyButton,
	clearButton = ClearPartyButton,
	createButtonRegions = CreatePartyRegions,
	onEnter = ShowPartyTooltip,
})
