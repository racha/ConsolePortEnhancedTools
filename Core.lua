local ADDON, ns = ...

local CPE = CreateFrame("Frame", "ConsolePortEnhancedToolsFrame")
_G.ConsolePortEnhancedTools = CPE

ns.CPE = CPE
ns.ADDON = ADDON

local CP_BINDING = "CLICK ConsolePortEnhancedToolsFeedPetAssistant:LeftButton"

_G.BINDING_HEADER_CPE_PETMANAGEMENT = "Pet Management"
_G.BINDING_NAME_CPE_FEEDPETASSISTANT = "Feed Pet Assistant"
_G["BINDING_NAME_" .. CP_BINDING] = "Feed Pet Assistant"

CPE.modules = {}
CPE.binding = CP_BINDING

function CPE:Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff739bd0ConsolePortEnhancedTools:|r " .. tostring(message))
end

function CPE:RegisterModule(name, module)
	self.modules[name] = module
	module.name = name
	module.core = self
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

function CPE:RegisterConsolePortBinding()
	if self.consolePortBindingRegistered or not ConsolePort or not ConsolePort.GetCustomBindings then
		return
	end

	local original = ConsolePort.GetCustomBindings
	ConsolePort.GetCustomBindings = function(consolePort)
		local bindings = original(consolePort)
		tinsert(bindings, { name = "Pet Management" })
		tinsert(bindings, {
			name = "Feed Pet Assistant",
			binding = CP_BINDING,
		})
		return bindings
	end

	self.consolePortBindingRegistered = true
end

function CPE:Initialize()
	ConsolePortEnhancedToolsDB = ConsolePortEnhancedToolsDB or {}
	self.db = ConsolePortEnhancedToolsDB

	self:RegisterConsolePortBinding()

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
	message = (message or ""):lower()
	if message == "" or message == "feed" then
		if ns.FeedPetAssistant then
			ns.FeedPetAssistant:ToggleFromBinding()
		end
	else
		CPE:Print("/cpet feed - open Feed Pet Assistant")
	end
end
