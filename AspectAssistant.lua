local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsAspectRing", UIParent)
ns.AspectAssistant = Assistant
CPE:RegisterModule("AspectAssistant", Assistant)

local ASPECTS = {
	{ id = 13165, fallback = "Aspect of the Hawk" },
	{ id = 61846, fallback = "Aspect of the Dragonhawk" },
	{ id = 34074, fallback = "Aspect of the Viper" },
	{ id = 5118, fallback = "Aspect of the Cheetah" },
	{ id = 13159, fallback = "Aspect of the Pack" },
	{ id = 13163, fallback = "Aspect of the Monkey" },
	{ id = 13161, fallback = "Aspect of the Beast" },
	{ id = 20043, fallback = "Aspect of the Wild" },
}

local function GetAspectName(info)
	return GetSpellInfo(info.id) or info.fallback
end

local function GetAspectIcon(info)
	local _, _, icon = GetSpellInfo(info.id)
	return icon or "Interface\\Icons\\Ability_Hunter_EagleEye"
end

local function GetCasterName(unit)
	if not unit or unit == "" then
		return nil
	end
	if unit == "player" then
		return UnitName("player") or "You"
	end
	return UnitName(unit)
end

local function IsAspectKnown(name)
	local i = 1
	while true do
		local spellName = GetSpellName(i, BOOKTYPE_SPELL)
		if not spellName then
			return false
		end
		if spellName == name then
			return true
		end
		i = i + 1
	end
end

local function GetAspectAura(name)
	for i = 1, 40 do
		local auraName, _, _, _, _, _, _, caster = UnitBuff("player", i)
		if not auraName then break end
		if auraName == name then
			return true, caster, GetCasterName(caster)
		end
	end
end

local function ValidateAspectAssistant()
	if not CPE:IsHunter() then
		CPE:Print("Aspect Assistant is only available to hunters.")
		return false
	end
	return true
end

local function ScanAspects()
	local aspects = {}

	for _, info in ipairs(ASPECTS) do
		local name = GetAspectName(info)
		if name and IsAspectKnown(name) then
			local active, caster, casterName = GetAspectAura(name)
			tinsert(aspects, {
				id = info.id,
				name = name,
				icon = GetAspectIcon(info),
				active = active,
				other = active and caster ~= "player",
				caster = caster,
				casterName = casterName,
			})
		end
	end

	return aspects
end

local function SetAspectButtonAction(self, button, aspect)
	if not button then return end
	if InCombatLockdown() then return end
	if aspect then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", aspect.name)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("spell", nil)
	end
end

local function OnSelect(self, button, aspect)
	if aspect then
		local status = ""
		if aspect.other then
			status = "\n|cffff4040Active from " .. (aspect.casterName or "another hunter") .. "|r"
		elseif aspect.active then
			status = "\n|cff40ff60Active|r"
		end
		self.Detail:SetText(aspect.name .. status)
	else
		self.Detail:SetText("|cff888888No aspect|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Aspect Assistant")
	self.Subtitle:SetText("Available hunter aspects")
end

local function UpdateAspectButton(self, button, aspect)
	button.aspect = aspect
	ns.RingHelper:SetIcon(button.Icon, aspect.icon)
	self:SetButtonName(button, aspect.name:gsub("^Aspect of the ", ""), 12)
	button.State:SetText(aspect.other and "|cffff4040Other|r" or (aspect.active and "|cff40ff60Active|r" or ""))
	if aspect.other then
		self:SetButtonStateColor(button, 1.00, 0.10, 0.10)
	elseif aspect.active then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	else
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	end
end

local function ClearAspectButton(self, button)
	button.aspect = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateAspectRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowAspectTooltip(self, button, aspect)
	if not aspect then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(aspect.name, 1, 0.82, 0.2)
	if aspect.other then
		GameTooltip:AddLine("Provided by: " .. (aspect.casterName or "another hunter"), 1, 0.2, 0.2)
	elseif aspect.active then
		GameTooltip:AddLine("Currently active.", 0.25, 1, 0.35)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Aspect Assistant",
	launcherName = "ConsolePortEnhancedToolsAspectAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsAspectKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsAspectSelect",
	selectorX = -34,
	selectorY = 34,
	launcherX = -24,
	launcherY = 24,
	buttonName = "Aspect",
	itemKey = "aspect",
	itemsKey = "aspects",
	idleText = "|cff888888Move to select aspect|r",
	emptyMessage = "No trained hunter aspects found.",
	validate = ValidateAspectAssistant,
	scan = ScanAspects,
	setButtonAction = SetAspectButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateAspectButton,
	clearButton = ClearAspectButton,
	createButtonRegions = CreateAspectRegions,
	onEnter = ShowAspectTooltip,
})
