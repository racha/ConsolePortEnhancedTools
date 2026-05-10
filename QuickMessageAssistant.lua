local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsQuickMessageRing", UIParent)
ns.QuickMessageAssistant = Assistant
CPE:RegisterModule("QuickMessageAssistant", Assistant)

local MESSAGES = {
	{ name = "Invite", text = "Invite please.", icon = "Interface\\Icons\\Achievement_GuildPerk_EveryonesAFriend", description = "Ask for an invite in your last chat channel." },
	{ name = "Thanks", text = "Thank you!", icon = "Interface\\Icons\\INV_Misc_Note_01", description = "Send a quick thank you." },
	{ name = "Hello", text = "Hello!", icon = "Interface\\Icons\\INV_Letter_15", description = "Greet nearby players or your group." },
	{ name = "On My Way", text = "On my way.", icon = "Interface\\Icons\\Ability_Mount_RidingHorse", description = "Let others know you are coming." },
	{ name = "Need Help", text = "Need help, please.", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing", description = "Ask for help in the last chat channel." },
	{ name = "Ready", text = "Ready.", icon = "Interface\\Icons\\Ability_Warrior_RallyingCry", description = "Confirm that you are ready." },
	{ name = "One Moment", text = "One moment, please.", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", description = "Ask people to wait briefly." },
	{ name = "Sorry", text = "Sorry!", icon = "Interface\\Icons\\Spell_Holy_Renew", description = "Send a quick apology." },
}

local function ScanMessages()
	return MESSAGES
end

local function SetMessageButtonAction(self, button, message)
	if not button then return end
	if InCombatLockdown() then return end
	button:SetAttribute("type", nil)
	button:SetAttribute("macrotext", nil)
end

local function OnSelect(self, button, message)
	if message then
		local destination = CPE:GetChatDestinationText(CPE:GetLastChatType(), CPE:GetLastChatTarget())
		local state = InCombatLockdown() and "|cffff4040Disabled in combat|r" or ("|cff40ff60" .. destination .. "|r")
		self.Detail:SetText(CPE:AppendDescription(message.name .. "\n" .. state .. "\n" .. message.text, message.description))
	else
		self.Detail:SetText("|cff888888No message|r")
	end
end

local function OnClick(self, button, message)
	if message then
		if InCombatLockdown() then
			self.Detail:SetText("|cffff4040Quick messages are disabled in combat.|r")
			return
		end
		CPE:SendQuickMessage(message.text)
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Quick Message Ring")
	if InCombatLockdown() then
		self.Subtitle:SetText("Disabled in combat")
	else
		self.Subtitle:SetText("Last channel: " .. CPE:GetChatDestinationText(CPE:GetLastChatType(), CPE:GetLastChatTarget()))
	end
end

local function UpdateMessageButton(self, button, message)
	button.quickMessage = message
	ns.RingHelper:SetIcon(button.Icon, message.icon)
	self:SetButtonName(button, message.name, 12)
	if InCombatLockdown() then
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	else
		self:SetButtonStateColor(button, 0.35, 0.85, 1.00)
	end
end

local function ClearMessageButton(self, button)
	button.quickMessage = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	self:ClearButtonState(button)
end

local function ShowMessageTooltip(self, button, message)
	if not message then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(message.name, 1, 0.82, 0.2)
	GameTooltip:AddLine(message.text, 0.25, 1, 0.35)
	GameTooltip:AddLine("Sends to: " .. CPE:GetChatDestinationText(CPE:GetLastChatType(), CPE:GetLastChatTarget()), 0.75, 0.75, 0.75)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Quick Message Ring",
	launcherName = "ConsolePortEnhancedToolsQuickMessageAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsQuickMessageKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsQuickMessageSelect",
	selectorX = -126,
	selectorY = 126,
	launcherX = -116,
	launcherY = 116,
	buttonName = "QuickMessage",
	itemKey = "quickMessage",
	itemsKey = "quickMessages",
	idleText = "|cff888888Move to select message|r",
	emptyMessage = "No quick messages available.",
	disableClickInCombat = true,
	scan = ScanMessages,
	setButtonAction = SetMessageButtonAction,
	onSelect = OnSelect,
	onClick = OnClick,
	refreshHeader = RefreshHeader,
	updateButton = UpdateMessageButton,
	clearButton = ClearMessageButton,
	onEnter = ShowMessageTooltip,
})
