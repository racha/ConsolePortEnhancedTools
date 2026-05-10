local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsMarkerRing", UIParent)
ns.MarkerAssistant = Assistant
CPE:RegisterModule("MarkerAssistant", Assistant)

local MARKERS = {
	{ id = 8, name = "Skull", color = { r = 1.00, g = 0.10, b = 0.10 }, description = "Mark your target as kill target." },
	{ id = 7, name = "Cross", color = { r = 1.00, g = 0.45, b = 0.20 }, description = "Mark your target as secondary kill target." },
	{ id = 6, name = "Square", color = { r = 0.15, g = 0.55, b = 1.00 }, description = "Mark your target with square." },
	{ id = 5, name = "Moon", color = { r = 0.70, g = 0.70, b = 1.00 }, description = "Mark your target for crowd control." },
	{ id = 4, name = "Triangle", color = { r = 0.25, g = 1.00, b = 0.25 }, description = "Mark your target with triangle." },
	{ id = 3, name = "Diamond", color = { r = 0.80, g = 0.35, b = 1.00 }, description = "Mark your target with diamond." },
	{ id = 2, name = "Circle", color = { r = 1.00, g = 0.75, b = 0.15 }, description = "Mark your target with circle." },
	{ id = 1, name = "Star", color = { r = 1.00, g = 0.95, b = 0.25 }, description = "Mark your target with star." },
}

local function MarkerIcon(id)
	return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. id
end

local function ScanMarkers()
	return MARKERS
end

local function SetMarkerButtonAction(self, button, marker)
	if not button then return end
	if InCombatLockdown() then return end
	if marker then
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", ("/run SetRaidTarget(\"target\", %d)"):format(marker.id))
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
	end
end

local function OnSelect(self, button, marker)
	if marker then
		self.Detail:SetText(CPE:AppendDescription(marker.name .. "\n|cff40ff60Set target marker|r", marker.description))
	else
		self.Detail:SetText("|cff888888No marker|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Marker Ring")
	self.Subtitle:SetText(UnitExists("target") and "Set raid target icon" or "No target selected")
end

local function UpdateMarkerButton(self, button, marker)
	button.marker = marker
	ns.RingHelper:SetIcon(button.Icon, MarkerIcon(marker.id))
	self:SetButtonName(button, marker.name, 12)
	self:SetButtonStateColor(button, marker.color.r, marker.color.g, marker.color.b)
end

local function ClearMarkerButton(self, button)
	button.marker = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	self:ClearButtonState(button)
end

local function ShowMarkerTooltip(self, button, marker)
	if not marker then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(marker.name, 1, 0.82, 0.2)
	GameTooltip:AddLine(marker.description, 0.75, 0.75, 0.75, true)
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Marker Ring",
	launcherName = "ConsolePortEnhancedToolsMarkerAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsMarkerKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsMarkerSelect",
	selectorX = -102,
	selectorY = 102,
	launcherX = -92,
	launcherY = 92,
	buttonName = "Marker",
	itemKey = "marker",
	itemsKey = "markers",
	idleText = "|cff888888Move to select marker|r",
	emptyMessage = "No markers available.",
	scan = ScanMarkers,
	setButtonAction = SetMarkerButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateMarkerButton,
	clearButton = ClearMarkerButton,
	onEnter = ShowMarkerTooltip,
})
