local ADDON, ns = ...

local CPE = CreateFrame("Frame", "ConsolePortEnhancedToolsFrame")
_G.ConsolePortEnhancedTools = CPE

ns.CPE = CPE
ns.ADDON = ADDON

local FEED_PET_SPELL_ID = 6991

local CLASS_COLOR_FALLBACKS = {
	HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
}

local TOOL_GROUPS = {
	general = {
		order = 1,
		name = "ConsolePort Enhanced General",
		color = { r = 0.95, g = 0.95, b = 0.95 },
	},
	hunter = {
		order = 2,
		name = "ConsolePort Enhanced Hunter",
		class = "HUNTER",
	},
}

local TOOL_DEFS = {
	{
		key = "feed",
		group = "hunter",
		module = "FeedPetAssistant",
		name = "Feed Pet Assistant",
		launcher = "ConsolePortEnhancedToolsFeedPetAssistant",
		luaBinding = "CPE_FEEDPETASSISTANT",
		spellID = FEED_PET_SPELL_ID,
		fallbackIcon = "Interface\\Icons\\Ability_Hunter_BeastTraining",
		aliases = { "feed", "foodpet", "petfood" },
	},
	{
		key = "aspect",
		group = "hunter",
		module = "AspectAssistant",
		name = "Aspect Assistant",
		launcher = "ConsolePortEnhancedToolsAspectAssistant",
		luaBinding = "CPE_ASPECTASSISTANT",
		spellID = 13165,
		fallbackIcon = "Interface\\Icons\\Ability_Hunter_AspectoftheHawk",
		aliases = { "aspect", "aspects" },
	},
	{
		key = "trap",
		group = "hunter",
		module = "TrapAssistant",
		name = "Trap Ring",
		launcher = "ConsolePortEnhancedToolsTrapAssistant",
		luaBinding = "CPE_TRAPASSISTANT",
		spellID = 1499,
		fallbackIcon = "Interface\\Icons\\Spell_Frost_ChainsOfIce",
		aliases = { "trap", "traps" },
	},
	{
		key = "quest",
		group = "general",
		module = "QuestItemAssistant",
		name = "Quest Item Ring",
		launcher = "ConsolePortEnhancedToolsQuestItemAssistant",
		luaBinding = "CPE_QUESTITEMASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_Note_02",
		aliases = { "quest", "questitem", "questitems" },
	},
	{
		key = "marker",
		group = "general",
		module = "MarkerAssistant",
		name = "Marker Ring",
		launcher = "ConsolePortEnhancedToolsMarkerAssistant",
		luaBinding = "CPE_MARKERASSISTANT",
		fallbackIcon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
		aliases = { "mark", "marker", "markers", "raidtarget" },
	},
	{
		key = "mount",
		group = "general",
		module = "MountAssistant",
		name = "Mount Ring",
		launcher = "ConsolePortEnhancedToolsMountAssistant",
		luaBinding = "CPE_MOUNTASSISTANT",
		fallbackIcon = "Interface\\Icons\\Ability_Mount_RidingHorse",
		aliases = { "mount", "mounts" },
	},
	{
		key = "emote",
		group = "general",
		module = "EmoteAssistant",
		name = "Emote Ring",
		launcher = "ConsolePortEnhancedToolsEmoteAssistant",
		luaBinding = "CPE_EMOTEASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_GroupLooking",
		aliases = { "emote", "emotes" },
	},
	{
		key = "quickmessage",
		group = "general",
		module = "QuickMessageAssistant",
		name = "Quick Message Ring",
		launcher = "ConsolePortEnhancedToolsQuickMessageAssistant",
		luaBinding = "CPE_QUICKMESSAGEASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Letter_15",
		aliases = { "message", "messages", "quick", "quickmessage" },
	},
	{
		key = "chat",
		group = "general",
		module = "ChatAssistant",
		name = "Chat Ring",
		launcher = "ConsolePortEnhancedToolsChatAssistant",
		luaBinding = "CPE_CHATASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Letter_17",
		aliases = { "chat", "talk" },
	},
	{
		key = "track",
		group = "general",
		module = "TrackAssistant",
		name = "Track Ring",
		launcher = "ConsolePortEnhancedToolsTrackAssistant",
		luaBinding = "CPE_TRACKASSISTANT",
		spellID = 1494,
		fallbackIcon = "Interface\\Icons\\Ability_Tracking",
		aliases = { "track", "tracking" },
	},
	{
		key = "consumables",
		group = "general",
		module = "ConsumablesAssistant",
		name = "Consumables Ring",
		launcher = "ConsolePortEnhancedToolsConsumablesAssistant",
		luaBinding = "CPE_CONSUMABLESASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_Food_65",
		aliases = { "consume", "consumable", "consumables", "food", "drink" },
	},
	{
		key = "profession",
		group = "general",
		module = "ProfessionAssistant",
		name = "Profession Assistant",
		launcher = "ConsolePortEnhancedToolsProfessionAssistant",
		luaBinding = "CPE_PROFESSIONASSISTANT",
		fallbackIcon = "Interface\\Icons\\Trade_Engineering",
		aliases = { "profession", "professions", "prof" },
	},
	{
		key = "party",
		group = "general",
		module = "PartyAssistant",
		name = "Party Assistant",
		launcher = "ConsolePortEnhancedToolsPartyAssistant",
		luaBinding = "CPE_PARTYASSISTANT",
		fallbackIcon = "Interface\\Icons\\Achievement_GuildPerk_EveryonesAFriend",
		aliases = { "party", "group" },
	},
	{
		key = "vehicle",
		group = "general",
		module = "VehicleAssistant",
		name = "Vehicle Control Ring",
		launcher = "ConsolePortEnhancedToolsVehicleAssistant",
		luaBinding = "CPE_VEHICLEASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_EngGizmos_30",
		aliases = { "vehicle", "seat", "seats" },
	},
	{
		key = "ammo",
		group = "hunter",
		module = "AmmoAssistant",
		name = "Ammo Assistant",
		launcher = "ConsolePortEnhancedToolsAmmoAssistant",
		luaBinding = "CPE_AMMOASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Ammo_Arrow_02",
		aliases = { "ammo", "arrows", "bullets" },
	},
}

for _, tool in ipairs(TOOL_DEFS) do
	tool.cpBinding = "CLICK " .. tool.launcher .. ":LeftButton"
end

local function ColorToHex(color)
	color = color or {}
	return ("|cff%02x%02x%02x"):format(
		math.floor((color.r or 1) * 255 + 0.5),
		math.floor((color.g or 1) * 255 + 0.5),
		math.floor((color.b or 1) * 255 + 0.5)
	)
end

local function GetGroupColor(group)
	if not group then return end
	if group.color then
		return group.color
	end
	if group.class then
		return (RAID_CLASS_COLORS and RAID_CLASS_COLORS[group.class]) or CLASS_COLOR_FALLBACKS[group.class]
	end
end

local function ColorLastWord(text, color)
	if not color then return text end
	local prefix, word = text:match("^(.*%s)(%S+)$")
	if not word then
		return ColorToHex(color) .. text .. "|r"
	end
	return prefix .. ColorToHex(color) .. word .. "|r"
end

local function GetGroupName(groupKey)
	local group = TOOL_GROUPS[groupKey or "general"] or TOOL_GROUPS.general
	return ColorLastWord(group.name, GetGroupColor(group))
end

local function GetToolGroupOrder(groupKey)
	local group = TOOL_GROUPS[groupKey or "general"] or TOOL_GROUPS.general
	return group.order or 99
end

_G.BINDING_HEADER_CPE_ENHANCEMENT = "ConsolePort Enhancement"
_G.BINDING_HEADER_CPE_ENHANCEMENT_GENERAL = GetGroupName("general")
_G.BINDING_HEADER_CPE_ENHANCEMENT_HUNTER = GetGroupName("hunter")
for _, tool in ipairs(TOOL_DEFS) do
	_G["BINDING_NAME_" .. tool.luaBinding] = tool.name
	_G["BINDING_NAME_" .. tool.cpBinding] = tool.name
end

CPE.modules = {}
CPE.toolDefs = TOOL_DEFS
CPE.toolGroups = TOOL_GROUPS
CPE.feedBinding = TOOL_DEFS[1].cpBinding
CPE.aspectBinding = TOOL_DEFS[2].cpBinding

function CPE:Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff739bd0ConsolePortEnhancedTools:|r " .. tostring(message))
end

function CPE:RegisterModule(name, module)
	self.modules[name] = module
	module.name = name
	module.core = self
end

function CPE:GetToolDef(keyOrBinding)
	for _, tool in ipairs(TOOL_DEFS) do
		if keyOrBinding == tool.key or keyOrBinding == tool.cpBinding or keyOrBinding == tool.luaBinding then
			return tool
		end
		for _, alias in ipairs(tool.aliases or {}) do
			if keyOrBinding == alias then
				return tool
			end
		end
	end
end

function CPE:IsHunter()
	local _, class = UnitClass("player")
	return class == "HUNTER"
end

function CPE:GetFoodInfo(itemID)
	local data = ns.FoodDB and ns.FoodDB[tonumber(itemID)]
	if type(data) == "table" then
		return data.type, data.level
	end
	return data
end

function CPE:GetItemID(link)
	if not link then return end
	return tonumber(link:match("item:(%-?%d+)"))
end

function CPE:GetToolGroupName(groupKey)
	return GetGroupName(groupKey)
end

function CPE:GetToolGroupOrder(groupKey)
	return GetToolGroupOrder(groupKey)
end

local DESCRIPTION_SCANNER = CreateFrame("GameTooltip", "ConsolePortEnhancedToolsDescriptionScanner", UIParent, "GameTooltipTemplate")
DESCRIPTION_SCANNER:SetOwner(UIParent, "ANCHOR_NONE")

local DESCRIPTION_SKIP = {
	["^item level"] = true,
	["^requires "] = true,
	["^classes:"] = true,
	["^races:"] = true,
	["^unique"] = true,
	["^soulbound"] = true,
	["^binds when"] = true,
	["^sell price"] = true,
}

local function IsDescriptionLine(text, index)
	if not text or text == "" or index == 1 then
		return false
	end

	local lower = text:lower()
	for pattern in pairs(DESCRIPTION_SKIP) do
		if lower:match(pattern) then
			return false
		end
	end

	return lower:match("^use:") or lower:match("^equip:") or lower:match("^chance on hit:")
		or lower:find("restores") or lower:find("increases") or lower:find("tracks")
		or lower:find("opens") or lower:find("summons") or lower:find("teaches")
		or text:find("%.")
end

function CPE:TrimDescription(text, limit)
	text = tostring(text or ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
	limit = limit or 130
	if text:len() > limit then
		return text:sub(1, limit - 1) .. "."
	end
	return text
end

function CPE:GetTooltipDescription(setter)
	if not setter then return end

	DESCRIPTION_SCANNER:ClearLines()
	local ok = pcall(setter, DESCRIPTION_SCANNER)
	if not ok then
		return
	end

	for i = 1, DESCRIPTION_SCANNER:NumLines() do
		local left = _G["ConsolePortEnhancedToolsDescriptionScannerTextLeft" .. i]
		local text = left and left:GetText()
		if IsDescriptionLine(text, i) then
			return self:TrimDescription(text)
		end
	end
end

function CPE:GetBagItemDescription(bag, slot)
	if not bag or not slot then return end
	return self:GetTooltipDescription(function(scanner)
		scanner:SetBagItem(bag, slot)
	end)
end

function CPE:GetItemDescription(link)
	if not link then return end
	return self:GetTooltipDescription(function(scanner)
		scanner:SetHyperlink(link)
	end)
end

function CPE:GetSpellDescriptionText(spellID, spellName)
	if GetSpellDescription and spellID then
		local ok, description = pcall(GetSpellDescription, spellID)
		if description and description ~= "" then
			return self:TrimDescription(description)
		end
	end

	if spellID then
		local description = self:GetTooltipDescription(function(scanner)
			if scanner.SetSpellByID then
				scanner:SetSpellByID(spellID)
			else
				scanner:SetHyperlink("spell:" .. spellID)
			end
		end)
		if description then
			return description
		end
	end

	if spellName then
		return self:GetTooltipDescription(function(scanner)
			scanner:SetText(spellName)
		end)
	end
end

function CPE:AppendDescription(text, description)
	if description and description ~= "" then
		return text .. "\n|cffbbbbbb" .. description .. "|r"
	end
	return text
end

local CHAT_TYPES = {
	SAY = true,
	PARTY = true,
	RAID = true,
	GUILD = true,
	OFFICER = true,
	BATTLEGROUND = true,
	INSTANCE_CHAT = true,
	WHISPER = true,
	CHANNEL = true,
}

local CHAT_PREFIX = {
	SAY = "/s ",
	PARTY = "/p ",
	RAID = "/raid ",
	GUILD = "/g ",
	OFFICER = "/o ",
	BATTLEGROUND = "/bg ",
	INSTANCE_CHAT = "/i ",
}

function CPE:GetDefaultChatType()
	if GetNumRaidMembers and GetNumRaidMembers() > 0 then
		return "RAID"
	end
	if GetNumPartyMembers and GetNumPartyMembers() > 0 then
		return "PARTY"
	end
	return "SAY"
end

function CPE:RememberChatType(chatType, target)
	if chatType and CHAT_TYPES[chatType] then
		self.lastChatType = chatType
		self.lastChatTarget = target
	end
end

function CPE:GetLastChatType()
	return self.lastChatType or self:GetDefaultChatType()
end

function CPE:GetLastChatTarget()
	return self.lastChatTarget
end

function CPE:GetChatDestinationText(chatType, target)
	chatType = chatType or self:GetLastChatType()
	if chatType == "WHISPER" then
		return target and ("Whisper: " .. target) or "Whisper"
	elseif chatType == "BATTLEGROUND" then
		return "Battleground"
	elseif chatType == "INSTANCE_CHAT" then
		return "Instance"
	elseif chatType == "CHANNEL" then
		return target and ("Channel " .. target) or "Channel"
	end
	return chatType:sub(1, 1) .. chatType:sub(2):lower()
end

function CPE:SendQuickMessage(message)
	if not message or message == "" then return end
	if InCombatLockdown and InCombatLockdown() then
		self:Print("Quick messages are disabled in combat to avoid protected chat taint.")
		return false
	end

	local chatType = self:GetLastChatType()
	local target = self:GetLastChatTarget()

	if chatType == "WHISPER" and (not target or target == "") then
		local targetName = UnitExists("target") and UnitIsPlayer("target") and UnitName("target")
		if targetName then
			target = targetName
		else
			chatType = self:GetDefaultChatType()
		end
	end

	if chatType == "CHANNEL" and not target then
		chatType = self:GetDefaultChatType()
	end

	self:RememberChatType(chatType, target)
	SendChatMessage(message, chatType, nil, target)
	return true
end

function CPE:GetChatEditBox()
	local chatFrame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME or ChatFrame1
	return (chatFrame and chatFrame.editBox) or ChatFrame1EditBox or DEFAULT_CHAT_FRAME_EDIT_BOX
end

function CPE:OpenChatText(text)
	text = text or ""
	local chatFrame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME or ChatFrame1

	if ChatFrame_OpenChat then
		local ok = pcall(ChatFrame_OpenChat, text, chatFrame)
		if ok then
			return true
		end
	end

	local editBox = self:GetChatEditBox()
	if not editBox then
		return false
	end

	if editBox.SetText then
		editBox:SetText(text)
	end
	if ChatEdit_ActivateChat then
		ChatEdit_ActivateChat(editBox)
	else
		editBox:Show()
		editBox:SetFocus()
	end
	if editBox.SetCursorPosition then
		editBox:SetCursorPosition(text:len())
	end
	return true
end

function CPE:OpenChat(mode)
	if InCombatLockdown and InCombatLockdown() then
		self:Print("Chat ring actions are disabled in combat to avoid protected chat taint.")
		return false
	end

	local prefix = CHAT_PREFIX[mode]
	local rememberType = mode
	local rememberTarget

	if mode == "WHISPER_TARGET" then
		local name, server
		if UnitExists("target") and UnitIsPlayer("target") then
			name, server = UnitName("target")
		end
		if name and name ~= "" then
			if server and server ~= "" then
				name = name .. "-" .. server
			end
			prefix = "/w " .. name .. " "
			rememberType = "WHISPER"
			rememberTarget = name
		else
			prefix = "/w "
			rememberType = nil
		end
	elseif mode == "REPLY" then
		prefix = "/r "
		rememberType = nil
	end

	if rememberType and CHAT_TYPES[rememberType] then
		self:RememberChatType(rememberType, rememberTarget)
	end

	if not self:OpenChatText(prefix or "") then
		self:Print("Unable to open the chat edit box.")
		return false
	end
	return true
end

function CPE:RegisterChatTracking()
	if self.chatTrackingRegistered then
		return
	end

	if hooksecurefunc and pcall(hooksecurefunc, "SendChatMessage", function(message, chatType, language, target)
			CPE:RememberChatType(chatType, target)
		end) then
		-- Hook registered.
	elseif SendChatMessage then
		local originalSendChatMessage = SendChatMessage
		SendChatMessage = function(message, chatType, language, target, ...)
			CPE:RememberChatType(chatType, target)
			return originalSendChatMessage(message, chatType, language, target, ...)
		end
	end

	self.chatTrackingRegistered = true
end

function CPE:GetToolIcon(tool)
	if type(tool) ~= "table" then
		tool = self:GetToolDef(tool)
	end
	if not tool then return end
	if tool.spellID then
		local _, _, icon = GetSpellInfo(tool.spellID)
		if icon then
			return icon
		end
	end
	return tool.fallbackIcon
end

function CPE:IsSpellKnown(name)
	if not name then return false end
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

function CPE:GetKnownSpellByID(spellID, fallback)
	local name, _, icon = GetSpellInfo(spellID)
	name = name or fallback
	if name and self:IsSpellKnown(name) then
		return name, icon
	end
end

function CPE:OpenRingBinding(moduleName, keystate)
	local module = ns[moduleName]
	if not module then return end
	if keystate == "down" then
		module:Open()
	else
		module:Hide()
	end
end

function CPE:CloseAllRings()
	for _, module in pairs(self.modules) do
		if module.Hide and module:IsShown() then
			module:Hide()
		end
	end
end

function CPE:RegisterGameMenuClose()
	if self.gameMenuCloseRegistered then
		return
	end

	if GameMenuFrame and GameMenuFrame.HookScript then
		GameMenuFrame:HookScript("OnShow", function()
			CPE:CloseAllRings()
		end)
	end

	if hooksecurefunc then
		if ToggleGameMenu then
			pcall(hooksecurefunc, "ToggleGameMenu", function()
				CPE:CloseAllRings()
			end)
		end
		if ToggleFrame then
			pcall(hooksecurefunc, "ToggleFrame", function(frame)
				if frame == GameMenuFrame then
					CPE:CloseAllRings()
				end
			end)
		end
	else
		if ToggleGameMenu then
			local originalToggleGameMenu = ToggleGameMenu
			ToggleGameMenu = function(...)
				CPE:CloseAllRings()
				return originalToggleGameMenu(...)
			end
		end
		if ToggleFrame then
			local originalToggleFrame = ToggleFrame
			ToggleFrame = function(frame, ...)
				if frame == GameMenuFrame then
					CPE:CloseAllRings()
				end
				return originalToggleFrame(frame, ...)
			end
		end
	end

	self.gameMenuCloseRegistered = true
end

function CPE:RegisterConsolePortBinding()
	if self.consolePortBindingRegistered or not ConsolePort or not ConsolePort.GetCustomBindings then
		return
	end

	local original = ConsolePort.GetCustomBindings
	ConsolePort.GetCustomBindings = function(consolePort)
		local bindings = original(consolePort) or {}
		local groupKeys = {}

		for groupKey in pairs(TOOL_GROUPS) do
			tinsert(groupKeys, groupKey)
		end
		table.sort(groupKeys, function(a, b)
			return CPE:GetToolGroupOrder(a) < CPE:GetToolGroupOrder(b)
		end)

		for _, groupKey in ipairs(groupKeys) do
			tinsert(bindings, { name = CPE:GetToolGroupName(groupKey) })
			for _, tool in ipairs(TOOL_DEFS) do
				if (tool.group or "general") == groupKey then
					tinsert(bindings, { name = tool.name, binding = tool.cpBinding })
				end
			end
		end
		return bindings
	end

	self.consolePortBindingRegistered = true
end

function CPE:RegisterConsolePortIcon()
	if self.consolePortIconRegistered or not ConsolePort then
		return
	end

	local originalIcon = ConsolePort.GetUtilityRingIcon
	ConsolePort.GetUtilityRingIcon = function(consolePort, binding)
		local tool = CPE:GetToolDef(binding)
		if tool then
			return CPE:GetToolIcon(tool)
		end
		return originalIcon and originalIcon(consolePort, binding)
	end

	local originalName = ConsolePort.GetUtilityRingName
	ConsolePort.GetUtilityRingName = function(consolePort, binding)
		local tool = CPE:GetToolDef(binding)
		if tool then
			return tool.name
		end
		return originalName and originalName(consolePort, binding)
	end

	self.consolePortIconRegistered = true
end

function CPE:NormalizeConsolePortBindings(bindingSet)
	if type(bindingSet) ~= "table" then
		return
	end

	local changed

	for _, bindings in pairs(bindingSet) do
		if type(bindings) == "table" then
			for modifier, binding in pairs(bindings) do
				local tool = self:GetToolDef(binding)
				if tool and binding == tool.luaBinding then
					bindings[modifier] = tool.cpBinding
					changed = true
				end
			end
		end
	end

	return changed
end

function CPE:RegisterConsolePortBindingMigration()
	if self.consolePortBindingMigrationRegistered or not ConsolePort then
		return
	end

	local originalLoadBindingSet = ConsolePort.LoadBindingSet
	if originalLoadBindingSet then
		ConsolePort.LoadBindingSet = function(consolePort, bindingSet, ...)
			self:NormalizeConsolePortBindings(bindingSet)
			return originalLoadBindingSet(consolePort, bindingSet, ...)
		end
	end

	self.consolePortBindingMigrationRegistered = true
end

function CPE:MigrateConsolePortBinding()
	if not ConsolePort or not ConsolePort.GetBindingSet then
		return
	end

	local bindingSet = ConsolePort:GetBindingSet()
	local changed = self:NormalizeConsolePortBindings(bindingSet)

	if changed and ConsolePort.LoadBindingSet then
		ConsolePort:LoadBindingSet(bindingSet, true)
	end
end

function CPE:Initialize()
	ConsolePortEnhancedToolsDB = ConsolePortEnhancedToolsDB or {}
	self.db = ConsolePortEnhancedToolsDB

	self:RegisterConsolePortBinding()
	self:RegisterConsolePortIcon()
	self:RegisterConsolePortBindingMigration()
	self:RegisterChatTracking()
	self:RegisterGameMenuClose()
	self:MigrateConsolePortBinding()

	for _, module in pairs(self.modules) do
		if module.OnInitialize then
			module:OnInitialize()
		end
	end
end

CPE:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" and (...) == ADDON then
		self:UnregisterEvent("ADDON_LOADED")
		self:Initialize()
	end
end)
CPE:RegisterEvent("ADDON_LOADED")

SLASH_CONSOLEPORTENHANCEDTOOLS1 = "/cpe"
SLASH_CONSOLEPORTENHANCEDTOOLS2 = "/cpet"
SlashCmdList.CONSOLEPORTENHANCEDTOOLS = function(message)
	message = (message or ""):lower():match("^%s*(.-)%s*$")
	if message == "" then
		message = "feed"
	end

	local tool = CPE:GetToolDef(message)
	if tool then
		local module = ns[tool.module]
		if module then
			module:ToggleFromBinding()
		end
	else
		for _, knownTool in ipairs(TOOL_DEFS) do
			CPE:Print("/cpet " .. knownTool.key .. " - open " .. knownTool.name)
		end
	end
end
