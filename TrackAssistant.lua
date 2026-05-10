local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsTrackRing", UIParent)
ns.TrackAssistant = Assistant
CPE:RegisterModule("TrackAssistant", Assistant)

local TRACKS = {
	{ id = 1494, fallback = "Track Beasts" },
	{ id = 19883, fallback = "Track Humanoids" },
	{ id = 19885, fallback = "Track Hidden" },
	{ id = 19880, fallback = "Track Elementals" },
	{ id = 19878, fallback = "Track Demons" },
	{ id = 19884, fallback = "Track Undead" },
	{ id = 19882, fallback = "Track Giants" },
	{ id = 19879, fallback = "Track Dragonkin" },
	{ id = 2580, fallback = "Find Minerals" },
	{ id = 2383, fallback = "Find Herbs" },
	{ id = 43308, fallback = "Find Fish" },
}

local function IsTrackingActive(name)
	for i = 1, 40 do
		local auraName = UnitBuff("player", i)
		if not auraName then break end
		if auraName == name then
			return true
		end
	end
	return false
end

local function ScanTracks()
	local tracks = {}

	for _, info in ipairs(TRACKS) do
		local name, icon = CPE:GetKnownSpellByID(info.id, info.fallback)
		if name then
			tinsert(tracks, {
				id = info.id,
				name = name,
				icon = icon or "Interface\\Icons\\Ability_Tracking",
				active = IsTrackingActive(name),
				description = CPE:GetSpellDescriptionText(info.id, name),
			})
		end
	end

	return tracks
end

local function SetTrackButtonAction(self, button, track)
	if not button then return end
	if InCombatLockdown() then return end
	if track then
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", track.name)
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("spell", nil)
	end
end

local function OnSelect(self, button, track)
	if track then
		self.Detail:SetText(CPE:AppendDescription(track.name .. (track.active and "\n|cff40ff60Active|r" or ""), track.description))
	else
		self.Detail:SetText("|cff888888No tracking|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Track Ring")
	self.Subtitle:SetText("Known tracking spells")
end

local function UpdateTrackButton(self, button, track)
	button.track = track
	ns.RingHelper:SetIcon(button.Icon, track.icon)
	self:SetButtonName(button, track.name:gsub("^Track ", ""):gsub("^Find ", ""), 12)
	button.State:SetText(track.active and "|cff40ff60Active|r" or "")
	if track.active then
		self:SetButtonStateColor(button, 0.25, 1.00, 0.35)
	else
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	end
end

local function ClearTrackButton(self, button)
	button.track = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateTrackRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowTrackTooltip(self, button, track)
	if not track then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(track.name, 1, 0.82, 0.2)
	if track.active then
		GameTooltip:AddLine("Currently active.", 0.25, 1, 0.35)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Track Ring",
	launcherName = "ConsolePortEnhancedToolsTrackAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsTrackKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsTrackSelect",
	selectorX = -46,
	selectorY = 46,
	launcherX = -36,
	launcherY = 36,
	buttonName = "Track",
	itemKey = "track",
	itemsKey = "tracks",
	idleText = "|cff888888Move to select tracking|r",
	emptyMessage = "No known tracking spells found.",
	scan = ScanTracks,
	setButtonAction = SetTrackButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateTrackButton,
	clearButton = ClearTrackButton,
	createButtonRegions = CreateTrackRegions,
	onEnter = ShowTrackTooltip,
})
