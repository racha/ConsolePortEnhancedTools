local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsTrapRing", UIParent)
ns.TrapAssistant = Assistant
CPE:RegisterModule("TrapAssistant", Assistant)

local TRAPS = {
	{ id = 1499, fallback = "Freezing Trap" },
	{ id = 13809, fallback = "Frost Trap" },
	{ id = 13795, fallback = "Immolation Trap" },
	{ id = 13813, fallback = "Explosive Trap" },
	{ id = 34600, fallback = "Snake Trap" },
	{ id = 60192, fallback = "Freezing Arrow" },
}

local function ValidateTrapAssistant()
	if not CPE:IsHunter() then
		CPE:Print("Trap Ring is only available to hunters.")
		return false
	end
	return true
end

local function GetCooldownText(start, duration)
	if start and duration and duration > 1.5 then
		local left = math.max(0, start + duration - GetTime())
		return ("%ds"):format(left + 0.5)
	end
	return ""
end

local function ScanTraps()
	local traps = {}

	for _, info in ipairs(TRAPS) do
		local name, icon = CPE:GetKnownSpellByID(info.id, info.fallback)
		if name then
			local usable, noMana = IsUsableSpell(name)
			local start, duration = GetSpellCooldown(name)
			local cooldown = duration and duration > 1.5
			tinsert(traps, {
				id = info.id,
				name = name,
				icon = icon or "Interface\\Icons\\Spell_Frost_ChainsOfIce",
				usable = usable,
				noMana = noMana,
				cooldown = cooldown,
				cooldownText = GetCooldownText(start, duration),
				description = CPE:GetSpellDescriptionText(info.id, name),
			})
		end
	end

	return traps
end

local function SetTrapButtonAction(self, button, trap)
	if not button then return end
	if InCombatLockdown() then return end
	if trap then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", trap.name)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("spell", nil)
	end
end

local function OnSelect(self, button, trap)
	if trap then
		local state = trap.cooldown and ("|cffffff40Cooldown " .. trap.cooldownText .. "|r") or (trap.usable and "|cff40ff60Ready|r" or "|cffff4040Unavailable|r")
		self.Detail:SetText(CPE:AppendDescription(trap.name .. "\n" .. state, trap.description))
	else
		self.Detail:SetText("|cff888888No trap|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Trap Ring")
	self.Subtitle:SetText("Available hunter traps")
end

local function UpdateTrapButton(self, button, trap)
	button.trap = trap
	ns.RingHelper:SetIcon(button.Icon, trap.icon)
	self:SetButtonName(button, trap.name:gsub(" Trap$", ""), 12)
	button.State:SetText(trap.cooldown and trap.cooldownText or (trap.usable and "" or "|cffff4040No|r"))
	if trap.cooldown then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	elseif trap.usable then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	else
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	end
end

local function ClearTrapButton(self, button)
	button.trap = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateTrapRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowTrapTooltip(self, button, trap)
	if not trap then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	if GameTooltip.SetSpellByID then
		GameTooltip:SetSpellByID(trap.id)
	else
		GameTooltip:AddLine(trap.name, 1, 0.82, 0.2)
	end
	if trap.cooldown then
		GameTooltip:AddLine("Cooldown: " .. trap.cooldownText, 1, 0.82, 0.2)
	elseif trap.usable then
		GameTooltip:AddLine("Ready", 0.25, 1, 0.35)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Trap Ring",
	launcherName = "ConsolePortEnhancedToolsTrapAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsTrapKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsTrapSelect",
	selectorX = -38,
	selectorY = 38,
	launcherX = -28,
	launcherY = 28,
	buttonName = "Trap",
	itemKey = "trap",
	itemsKey = "traps",
	idleText = "|cff888888Move to select trap|r",
	emptyMessage = "No trained hunter traps found.",
	validate = ValidateTrapAssistant,
	scan = ScanTraps,
	setButtonAction = SetTrapButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateTrapButton,
	clearButton = ClearTrapButton,
	createButtonRegions = CreateTrapRegions,
	onEnter = ShowTrapTooltip,
})
