local _, ns = ...
local CPE = ns.CPE

local Assistant = CreateFrame("Frame", "ConsolePortEnhancedToolsVehicleRing", UIParent)
ns.VehicleAssistant = Assistant
CPE:RegisterModule("VehicleAssistant", Assistant)

local MAX_SEAT_BUTTONS = 7

local ICON_EXIT = "Interface\\Icons\\Ability_Druid_Dash"
local ICON_SEAT = "Interface\\Icons\\INV_Misc_EngGizmos_30"

local function HasVehicleControls()
	if UnitHasVehicleUI and UnitHasVehicleUI("player") then
		return true
	end
	if UnitInVehicle and UnitInVehicle("player") then
		return true
	end
	if CanExitVehicle and CanExitVehicle() then
		return true
	end
	return false
end

local function GetSeatInfo(index)
	if UnitVehicleSeatInfo then
		local controlType, occupantName, serverName, ejectable, canSwitchSeats = UnitVehicleSeatInfo("player", index)
		return controlType, occupantName, serverName, ejectable, canSwitchSeats
	end
end

local function ScanVehicleControls()
	local controls = {}
	if not HasVehicleControls() then
		return controls
	end

	tinsert(controls, {
		kind = "exit",
		name = "Exit Vehicle",
		icon = ICON_EXIT,
		state = CanExitVehicle and not CanExitVehicle() and "|cffff4040Unavailable|r" or "|cff40ff60Available|r",
		description = "Leave the current vehicle, possession, or override bar.",
	})

	for seat = 1, MAX_SEAT_BUTTONS do
		local controlType, occupantName, serverName, _, canSwitchSeats = GetSeatInfo(seat)
		if controlType or occupantName or canSwitchSeats then
			local name = ("Seat %d"):format(seat)
			local state = "|cffaaaaaaEmpty|r"
			local description = "Switch to this vehicle seat."

			if occupantName and occupantName ~= "" then
				name = name .. ": " .. occupantName
				state = "|cffffff40Occupied|r"
				description = "Switch to the seat occupied by " .. occupantName .. "."
				if serverName and serverName ~= "" then
					description = description .. "-" .. serverName
				end
			end
			if canSwitchSeats == false then
				state = "|cffff4040Locked|r"
				description = "This vehicle seat cannot be selected right now."
			end

			tinsert(controls, {
				kind = "seat",
				seat = seat,
				name = name,
				shortName = ("Seat %d"):format(seat),
				icon = ICON_SEAT,
				state = state,
				canSwitch = canSwitchSeats ~= false,
				description = description,
			})
		end
	end

	return controls
end

local function SetMacroAction(button, macrotext)
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", macrotext)
	button:SetAttribute("clickbutton", nil)
end

local function SetVehicleButtonAction(self, button)
	if not button then return end
	if InCombatLockdown() then return end

	local index = button.vehicleIndex
	if index == 1 then
		if VehicleMenuBarLeaveButton then
			button:SetAttribute("type", "click")
			button:SetAttribute("clickbutton", VehicleMenuBarLeaveButton)
			button:SetAttribute("macrotext", nil)
		else
			SetMacroAction(button, "/click VehicleMenuBarLeaveButton\n/leavevehicle\n/vehicleexit")
		end
	elseif index and index > 1 then
		local seat = index - 1
		local seatButton = _G["VehicleSeatIndicatorButton" .. seat]
		if seatButton then
			button:SetAttribute("type", "click")
			button:SetAttribute("clickbutton", seatButton)
			button:SetAttribute("macrotext", nil)
		else
			SetMacroAction(button, ("/click VehicleSeatIndicatorButton%d\n/run UnitSwitchToVehicleSeat(\"player\", %d)"):format(seat, seat))
		end
	else
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
		button:SetAttribute("clickbutton", nil)
	end
end

local function OnSelect(self, button, control)
	if control then
		self.Detail:SetText(CPE:AppendDescription(control.name .. "\n" .. (control.state or ""), control.description))
	else
		self.Detail:SetText("|cff888888No vehicle control|r")
	end
end

local function RefreshHeader(self)
	self.Title:SetText("Vehicle Control Ring")
	self.Subtitle:SetText(HasVehicleControls() and "Exit and switch vehicle seats" or "No vehicle controls active")
end

local function UpdateVehicleButton(self, button, control)
	button.vehicleControl = control
	ns.RingHelper:SetIcon(button.Icon, control.icon)
	self:SetButtonName(button, control.shortName or control.name, 13)
	button.State:SetText(control.state or "")

	if control.kind == "exit" then
		self:SetButtonStateColor(button, 1.00, 0.35, 0.25)
	elseif control.canSwitch then
		self:SetButtonStateColor(button, 0.35, 0.55, 1.00)
	else
		self:SetButtonStateColor(button, 0.65, 0.65, 0.65)
	end
end

local function ClearVehicleButton(self, button)
	button.vehicleControl = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateVehicleRegions(self, button, index)
	button.vehicleIndex = index
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
	button.State:SetWidth(112)
	button.State:SetJustifyH("CENTER")
	if button.State.SetMaxLines then
		button.State:SetMaxLines(1)
	end
end

local function ShowVehicleTooltip(self, button, control)
	if not control then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(control.name, 1, 0.82, 0.2)
	if control.state and control.state ~= "" then
		GameTooltip:AddLine(control.state, 1, 1, 1)
	end
	if control.description then
		GameTooltip:AddLine(control.description, 0.75, 0.75, 0.75, true)
	end
	GameTooltip:Show()
end

ns.RingHelper:Mixin(Assistant, {
	title = "Vehicle Control Ring",
	launcherName = "ConsolePortEnhancedToolsVehicleAssistant",
	keyOwnerName = "ConsolePortEnhancedToolsVehicleKeyOwner",
	selectorPrefix = "ConsolePortEnhancedToolsVehicleSelect",
	selectorX = -94,
	selectorY = 94,
	launcherX = -84,
	launcherY = 84,
	buttonName = "Vehicle",
	itemKey = "vehicleControl",
	itemsKey = "vehicleControls",
	idleText = "|cff888888Move to select vehicle control|r",
	emptyMessage = "No vehicle controls available.",
	scan = ScanVehicleControls,
	setButtonAction = SetVehicleButtonAction,
	onSelect = OnSelect,
	refreshHeader = RefreshHeader,
	updateButton = UpdateVehicleButton,
	clearButton = ClearVehicleButton,
	createButtonRegions = CreateVehicleRegions,
	onEnter = ShowVehicleTooltip,
})
