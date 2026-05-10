local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsChatRing", UIParent)
ns.ChatAssistant = Assistant
CPE:RegisterModule("ChatAssistant", Assistant)

local CHANNELS = {
	{ name = "Say", mode = "SAY", icon = "Interface\\Icons\\INV_Letter_17", description = "Open chat in say." },
	{ name = "Party", mode = "PARTY", icon = "Interface\\Icons\\Achievement_GuildPerk_EveryonesAFriend", description = "Open party chat." },
	{ name = "Whisper", mode = "WHISPER_TARGET", icon = "Interface\\Icons\\INV_Letter_15", description = "Whisper your current player target." },
	{ name = "Reply", mode = "REPLY", icon = "Interface\\Icons\\INV_Letter_06", description = "Reply to the last whisper." },
	{ name = "Raid", mode = "RAID", icon = "Interface\\Icons\\INV_BannerPVP_02", description = "Open raid chat." },
	{ name = "BG", mode = "BATTLEGROUND", icon = "Interface\\Icons\\INV_BannerPVP_01", description = "Open battleground chat." },
	{ name = "Guild", mode = "GUILD", icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01", description = "Open guild chat." },
	{ name = "Officer", mode = "OFFICER", icon = "Interface\\Icons\\INV_Misc_Note_02", description = "Open officer chat." },
}

local function ScanChannels()
	return CHANNELS
end

local function SetChatButtonAction(self, button, channel)
	if not button then return end
	if InCombatLockdown() then return end
	button:SetAttribute("type", nil)
	button:SetAttribute("macrotext", nil)
end

local function OnSelect(self, button, channel)
	if channel then
		local state = InCombatLockdown() and "|cffff4040Disabled in combat|r" or "|cff40ff60Open chat|r"
		self.Detail:SetText(CPE:AppendDescription(channel.name .. "\n" .. state, channel.description))
	else
		self.Detail:SetText("|cff888888No chat channel|r")
	end
end

local function OnClick(self, button, channel)
	if channel then
		if InCombatLockdown() then
			self.Detail:SetText("|cffff4040Chat actions are disabled in combat.|r")
			return
		end
		CPE:OpenChat(channel.mode)
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Chat Ring")
	self.Subtitle:SetText(InCombatLockdown() and "Disabled in combat" or "Open chat channels")
end

local function UpdateChatButton(self, button, channel)
	button.chatChannel = channel
	ns.RingHelper:SetIcon(button.Icon, channel.icon)
	self:SetButtonName(button, channel.name, 12)
	if InCombatLockdown() then
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	else
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	end
end

local function ClearChatButton(self, button)
	button.chatChannel = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	self:ClearButtonState(button)
end

local function ShowChatTooltip(self, button, channel)
	if not channel then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(channel.name, 1, 0.82, 0.2)
	GameTooltip:AddLine(channel.description, 0.75, 0.75, 0.75, true)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Chat Ring",
	launcherName = "ConsolePortEnhancedToolsChatAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsChatKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsChatSelect",
	selectorX = -134,
	selectorY = 134,
	launcherX = -124,
	launcherY = 124,
	buttonName = "Chat",
	itemKey = "chatChannel",
	itemsKey = "chatChannels",
	idleText = "|cff888888Move to select chat channel|r",
	emptyMessage = "No chat channels available.",
	disableClickInCombat = true,
	scan = ScanChannels,
	setButtonAction = SetChatButtonAction,
	onSelect = OnSelect,
	onClick = OnClick,
	refreshHeader = RefreshHeader,
	updateButton = UpdateChatButton,
	clearButton = ClearChatButton,
	onEnter = ShowChatTooltip,
})
