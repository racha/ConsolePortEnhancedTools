local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsEmoteRing", UIParent)
ns.EmoteAssistant = Assistant
CPE:RegisterModule("EmoteAssistant", Assistant)

local EMOTES = {
	{ name = "Wave", command = "/wave", icon = "Interface\\Icons\\INV_Misc_GroupLooking", description = "Wave at your target or nearby players." },
	{ name = "Thanks", command = "/thank", icon = "Interface\\Icons\\INV_Misc_Note_01", description = "Thank your target or nearby players." },
	{ name = "Cheer", command = "/cheer", icon = "Interface\\Icons\\Achievement_BG_winWSG", description = "Cheer for your target or group." },
	{ name = "Laugh", command = "/laugh", icon = "Interface\\Icons\\Spell_Holy_Silence", description = "Laugh." },
	{ name = "Point", command = "/point", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath", description = "Point at your target." },
	{ name = "Follow Me", command = "/followme", icon = "Interface\\Icons\\Ability_Hunter_AspectOfThePack", description = "Signal others to follow you." },
	{ name = "Ready", command = "/ready", icon = "Interface\\Icons\\Ability_Warrior_RallyingCry", description = "Tell others you are ready." },
	{ name = "Sorry", command = "/sorry", icon = "Interface\\Icons\\Spell_Holy_Renew", description = "Apologize quickly." },
}

local function ScanEmotes()
	return EMOTES
end

local function SetEmoteButtonAction(self, button, emote)
	if not button then return end
	if InCombatLockdown() then return end
	if emote then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", emote.command)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
	end
end

local function OnSelect(self, button, emote)
	if emote then
		self.Detail:SetText(CPE:AppendDescription(emote.name .. "\n|cff40ff60" .. emote.command .. "|r", emote.description))
	else
		self.Detail:SetText("|cff888888No emote|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Emote Ring")
	self.Subtitle:SetText("Common social emotes")
end

local function UpdateEmoteButton(self, button, emote)
	button.emote = emote
	ns.RingHelper:SetIcon(button.Icon, emote.icon)
	self:SetButtonName(button, emote.name, 12)
	self:SetButtonStateColor(button, 0.70, 0.70, 1.00)
end

local function ClearEmoteButton(self, button)
	button.emote = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	self:ClearButtonState(button)
end

local function ShowEmoteTooltip(self, button, emote)
	if not emote then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(emote.name, 1, 0.82, 0.2)
	GameTooltip:AddLine(emote.command, 0.25, 1, 0.35)
	GameTooltip:AddLine(emote.description, 0.75, 0.75, 0.75, true)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Emote Ring",
	launcherName = "ConsolePortEnhancedToolsEmoteAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsEmoteKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsEmoteSelect",
	selectorX = -118,
	selectorY = 118,
	launcherX = -108,
	launcherY = 108,
	buttonName = "Emote",
	itemKey = "emote",
	itemsKey = "emotes",
	idleText = "|cff888888Move to select emote|r",
	emptyMessage = "No emotes available.",
	scan = ScanEmotes,
	setButtonAction = SetEmoteButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateEmoteButton,
	clearButton = ClearEmoteButton,
	onEnter = ShowEmoteTooltip,
})
