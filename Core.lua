local ADDON, ns = ...

local CPE = CreateFrame("Frame", "ConsolePortEnhancedToolsFrame")
_G.ConsolePortEnhancedTools = CPE

ns.CPE = CPE
ns.ADDON = ADDON

local FEED_PET_SPELL_ID = 6991

local TOOL_DEFS = {
	{
		key = "feed",
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
		module = "QuestItemAssistant",
		name = "Quest Item Ring",
		launcher = "ConsolePortEnhancedToolsQuestItemAssistant",
		luaBinding = "CPE_QUESTITEMASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_Note_02",
		aliases = { "quest", "questitem", "questitems" },
	},
	{
		key = "track",
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
		module = "ConsumablesAssistant",
		name = "Consumables Ring",
		launcher = "ConsolePortEnhancedToolsConsumablesAssistant",
		luaBinding = "CPE_CONSUMABLESASSISTANT",
		fallbackIcon = "Interface\\Icons\\INV_Misc_Food_65",
		aliases = { "consume", "consumable", "consumables", "food", "drink" },
	},
	{
		key = "profession",
		module = "ProfessionAssistant",
		name = "Profession Assistant",
		launcher = "ConsolePortEnhancedToolsProfessionAssistant",
		luaBinding = "CPE_PROFESSIONASSISTANT",
		fallbackIcon = "Interface\\Icons\\Trade_Engineering",
		aliases = { "profession", "professions", "prof" },
	},
	{
		key = "party",
		module = "PartyAssistant",
		name = "Party Assistant",
		launcher = "ConsolePortEnhancedToolsPartyAssistant",
		luaBinding = "CPE_PARTYASSISTANT",
		fallbackIcon = "Interface\\Icons\\Achievement_GuildPerk_EveryonesAFriend",
		aliases = { "party", "group" },
	},
	{
		key = "ammo",
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

_G.BINDING_HEADER_CPE_ENHANCEMENT = "ConsolePort Enhancement"
for _, tool in ipairs(TOOL_DEFS) do
	_G["BINDING_NAME_" .. tool.luaBinding] = tool.name
	_G["BINDING_NAME_" .. tool.cpBinding] = tool.name
end

CPE.modules = {}
CPE.toolDefs = TOOL_DEFS
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

function CPE:RegisterConsolePortBinding()
	if self.consolePortBindingRegistered or not ConsolePort or not ConsolePort.GetCustomBindings then
		return
	end

	local original = ConsolePort.GetCustomBindings
	ConsolePort.GetCustomBindings = function(consolePort)
		local bindings = original(consolePort) or {}
		tinsert(bindings, { name = "ConsolePort Enhancement" })
		for _, tool in ipairs(TOOL_DEFS) do
			tinsert(bindings, {
				name = tool.name,
				binding = tool.cpBinding,
			})
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
