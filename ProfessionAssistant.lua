local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsProfessionRing", UIParent)
ns.ProfessionAssistant = Assistant
CPE:RegisterModule("ProfessionAssistant", Assistant)

local PROFESSIONS = {
	{ id = 2259, fallback = "Alchemy" },
	{ id = 2018, fallback = "Blacksmithing" },
	{ id = 7411, fallback = "Enchanting" },
	{ id = 4036, fallback = "Engineering" },
	{ id = 45357, fallback = "Inscription" },
	{ id = 25229, fallback = "Jewelcrafting" },
	{ id = 2108, fallback = "Leatherworking" },
	{ id = 3908, fallback = "Tailoring" },
	{ id = 2656, fallback = "Smelting" },
	{ id = 2550, fallback = "Cooking" },
	{ id = 3273, fallback = "First Aid" },
	{ id = 7620, fallback = "Fishing" },
}

local function ScanProfessions()
	local professions = {}

	for _, info in ipairs(PROFESSIONS) do
		local name, icon = CPE:GetKnownSpellByID(info.id, info.fallback)
		if name then
			local start, duration = GetSpellCooldown(name)
			local cooldown = duration and duration > 1.5
			tinsert(professions, {
				id = info.id,
				name = name,
				icon = icon or "Interface\\Icons\\Trade_Engineering",
				cooldown = cooldown,
			})
		end
	end

	return professions
end

local function SetProfessionButtonAction(self, button, profession)
	if not button then return end
	if InCombatLockdown() then return end
	if profession then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", profession.name)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("spell", nil)
	end
end

local function OnSelect(self, button, profession)
	if profession then
		self.Detail:SetText(profession.name)
	else
		self.Detail:SetText("|cff888888No profession|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Profession Assistant")
	self.Subtitle:SetText("Known profession tools")
end

local function UpdateProfessionButton(self, button, profession)
	button.profession = profession
	ns.RingHelper:SetIcon(button.Icon, profession.icon)
	self:SetButtonName(button, profession.name, 13)
	if profession.cooldown then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	else
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	end
end

local function ClearProfessionButton(self, button)
	button.profession = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	self:ClearButtonState(button)
end

local function ShowProfessionTooltip(self, button, profession)
	if not profession then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(profession.name, 1, 0.82, 0.2)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Profession Assistant",
	launcherName = "ConsolePortEnhancedToolsProfessionAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsProfessionKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsProfessionSelect",
	selectorX = -70,
	selectorY = 70,
	launcherX = -60,
	launcherY = 60,
	buttonName = "Profession",
	itemKey = "profession",
	itemsKey = "professions",
	idleText = "|cff888888Move to select profession|r",
	emptyMessage = "No known profession spells found.",
	scan = ScanProfessions,
	setButtonAction = SetProfessionButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateProfessionButton,
	clearButton = ClearProfessionButton,
	onEnter = ShowProfessionTooltip,
})
