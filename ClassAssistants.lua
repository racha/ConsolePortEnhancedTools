local _, ns = ...
local CPE = ns.CPE
local RingHelper = ns.RingHelper

local CLASS_COLOR_FALLBACKS = {
	DRUID = { r = 1.00, g = 0.49, b = 0.04 },
	MAGE = { r = 0.41, g = 0.80, b = 0.94 },
	PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
	PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
	ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
	SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
	WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
	WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}

local CLASS_PLURAL = {
	DRUID = "druids",
	MAGE = "mages",
	PALADIN = "paladins",
	PRIEST = "priests",
	ROGUE = "rogues",
	SHAMAN = "shamans",
	WARLOCK = "warlocks",
	WARRIOR = "warriors",
}

local ICON_SPELL = "Interface\\Icons\\INV_Misc_QuestionMark"
local ICON_POISON = "Interface\\Icons\\Ability_Rogue_DualWeild"
local ICON_STONE = "Interface\\Icons\\INV_Stone_04"

local registerIndex = 0

local function GetClassColor(class)
	return (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or CLASS_COLOR_FALLBACKS[class] or { r = 0.35, g = 0.55, b = 1.00 }
end

local function IsPlayerClass(class)
	local _, playerClass = UnitClass("player")
	return playerClass == class
end

local function ShortName(name, fallback)
	name = fallback or name or ""
	name = name:gsub("^Teleport:%s*", "")
	name = name:gsub("^Portal:%s*", "")
	name = name:gsub("^Summon%s+", "")
	name = name:gsub("^Conjure%s+", "")
	name = name:gsub("^Create%s+", "")
	name = name:gsub("^Blessing of%s+", "")
	name = name:gsub("^Greater Blessing of%s+", "Greater ")
	name = name:gsub("^Seal of%s+", "")
	name = name:gsub("%s+Form$", "")
	name = name:gsub("%s+Totem$", "")
	name = name:gsub("%s+Weapon$", "")
	name = name:gsub("%s+Shield$", "")
	name = name:gsub("%s+Shout$", "")
	return name
end

local function GetCooldownText(start, duration)
	if start and duration and duration > 1.5 then
		local left = math.max(0, start + duration - GetTime())
		return ("%ds"):format(left + 0.5)
	end
	return ""
end

local function AddSpell(items, info, fallbackIcon, seen)
	local name, icon = CPE:GetKnownSpellByID(info.id, info.fallback)
	if not name then return end
	if seen and seen[name] then return end
	if seen then
		seen[name] = true
	end

	local usable, noMana = IsUsableSpell(name)
	local start, duration = GetSpellCooldown(name)
	local cooldown = duration and duration > 1.5

	tinsert(items, {
		kind = "spell",
		id = info.id,
		name = name,
		label = info.label or ShortName(name),
		icon = icon or info.icon or fallbackIcon or ICON_SPELL,
		usable = usable,
		noMana = noMana,
		cooldown = cooldown,
		cooldownText = GetCooldownText(start, duration),
		description = info.description or CPE:GetSpellDescriptionText(info.id, name),
	})
end

local function ScanSpells(self)
	local items = {}
	local config = self.classRing
	local seen = {}

	for _, info in ipairs(config.spells or {}) do
		AddSpell(items, info, config.fallbackIcon, seen)
	end

	return items
end

local function NameMatchesAny(name, patterns)
	if not name then return false end
	for _, pattern in ipairs(patterns) do
		if name:find(pattern) then
			return true
		end
	end
	return false
end

local function AddBagItems(items, patterns, fallbackIcon)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local texture, count = GetContainerItemInfo(bag, slot)
				local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(link)
				if NameMatchesAny(name, patterns) then
					tinsert(items, {
						kind = "item",
						name = name,
						label = ShortName(name),
						link = link,
						bag = bag,
						slot = slot,
						count = count,
						icon = icon or texture or fallbackIcon or ICON_SPELL,
						usable = true,
						description = CPE:GetBagItemDescription(bag, slot),
					})
				end
			end
		end
	end
end

local function ScanPoisons()
	local items = {}
	AddBagItems(items, {
		"Instant Poison",
		"Deadly Poison",
		"Wound Poison",
		"Crippling Poison",
		"Mind%-numbing Poison",
		"Anesthetic Poison",
	}, ICON_POISON)
	return items
end

local function ScanWarlockStones(self)
	local items = ScanSpells(self)
	AddBagItems(items, {
		"Healthstone",
		"Soulstone",
		"Firestone",
		"Spellstone",
	}, ICON_STONE)
	return items
end

local function SetClassButtonAction(self, button, item)
	if not button then return end
	if InCombatLockdown() then return end

	button:SetAttribute("spell", nil)
	button:SetAttribute("item", nil)
	button:SetAttribute("macrotext", nil)

	if not item then
		button:SetAttribute("type", nil)
	elseif item.kind == "item" then
		button:SetAttribute("type", "item")
		button:SetAttribute("item", item.name)
	else
		button:SetAttribute("type", "spell")
		button:SetAttribute("spell", item.name)
	end
end

local function ValidateClassAssistant(self)
	local config = self.classRing
	if not IsPlayerClass(config.class) then
		CPE:Print(config.title .. " is only available to " .. (CLASS_PLURAL[config.class] or config.class) .. ".")
		return false
	end
	return true
end

local function OnSelect(self, button, item)
	if item then
		local state = "|cff40ff60Ready|r"
		if item.cooldown then
			state = "|cffffff40Cooldown " .. item.cooldownText .. "|r"
		elseif not item.usable then
			state = item.noMana and "|cffff4040No resources|r" or "|cffff4040Unavailable|r"
		end
		if item.count and item.count > 1 then
			state = state .. "  |cffbbbbbbx" .. item.count .. "|r"
		end
		self.Detail:SetText(CPE:AppendDescription(item.name .. "\n" .. state, item.description))
	else
		self.Detail:SetText("|cff888888No ability|r")
	end
end

local function RefreshHeader(self, items)
	local config = self.classRing
	self.Title:SetText(config.title)
	self.Subtitle:SetText((items and #items > 0) and config.subtitle or config.emptySubtitle)
end

local function UpdateClassButton(self, button, item)
	local color = GetClassColor(self.classRing.class)
	button.classItem = item
	RingHelper:SetIcon(button.Icon, item.icon or self.classRing.fallbackIcon or ICON_SPELL)
	self:SetButtonName(button, item.label or ShortName(item.name), 13)
	button.State:SetText(item.cooldown and item.cooldownText or ((item.count and item.count > 1) and ("x" .. item.count) or ""))

	if item.cooldown then
		self:SetButtonStateColor(button, 1.00, 0.82, 0.20)
	elseif not item.usable then
		self:SetButtonStateColor(button, 0.85, 0.25, 0.25)
	else
		self:SetButtonStateColor(button, color.r, color.g, color.b)
	end
end

local function ClearClassButton(self, button)
	button.classItem = nil
	button.Icon:SetTexture(nil)
	self:SetButtonName(button, "")
	button.State:SetText("")
	self:ClearButtonState(button)
end

local function CreateClassRegions(self, button)
	button.State = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.State:SetPoint("TOP", button.Name, "BOTTOM", 0, -1)
end

local function ShowClassTooltip(self, button, item)
	if not item then return end
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:ClearLines()
	if item.kind == "spell" and item.id and GameTooltip.SetSpellByID then
		GameTooltip:SetSpellByID(item.id)
	elseif item.link then
		GameTooltip:SetHyperlink(item.link)
	else
		GameTooltip:AddLine(item.name, 1, 0.82, 0.2)
		if item.description then
			GameTooltip:AddLine(item.description, 0.75, 0.75, 0.75, true)
		end
	end
	GameTooltip:Show()
end

local function RegisterClassRing(config)
	registerIndex = registerIndex + 1
	local frame = CreateFrame("Frame", "ConsolePortEnhancedTools" .. config.module .. "Ring", UIParent)
	frame.classRing = config
	ns[config.module] = frame
	CPE:RegisterModule(config.module, frame)

	local offset = 150 + (registerIndex * 4)
	RingHelper:Mixin(frame, {
		title = config.title,
		launcherName = "ConsolePortEnhancedTools" .. config.module,
		keyOwnerName = "ConsolePortEnhancedTools" .. config.module .. "KeyOwner",
		selectorPrefix = "ConsolePortEnhancedTools" .. config.module .. "Select",
		selectorX = -offset,
		selectorY = offset,
		launcherX = -offset + 10,
		launcherY = offset - 10,
		buttonName = config.module:gsub("Assistant$", ""),
		itemKey = "classItem",
		itemsKey = config.module .. "Items",
		idleText = "|cff888888Move to select|r",
		emptyMessage = config.emptyMessage,
		validate = ValidateClassAssistant,
		scan = config.scan or ScanSpells,
		setButtonAction = SetClassButtonAction,
		onSelect = OnSelect,
		refreshHeader = RefreshHeader,
		updateButton = UpdateClassButton,
		clearButton = ClearClassButton,
		createButtonRegions = CreateClassRegions,
		onEnter = ShowClassTooltip,
	})
end

local RINGS = {
	{
		module = "DruidFormAssistant",
		class = "DRUID",
		title = "Form Ring",
		subtitle = "Known druid forms",
		emptySubtitle = "No forms trained",
		emptyMessage = "No trained druid forms found.",
		fallbackIcon = "Interface\\Icons\\Ability_Druid_CatForm",
		spells = {
			{ id = 9634, fallback = "Dire Bear Form" },
			{ id = 5487, fallback = "Bear Form" },
			{ id = 768, fallback = "Cat Form" },
			{ id = 783, fallback = "Travel Form" },
			{ id = 1066, fallback = "Aquatic Form" },
			{ id = 24858, fallback = "Moonkin Form" },
			{ id = 33891, fallback = "Tree of Life" },
			{ id = 33943, fallback = "Flight Form" },
			{ id = 40120, fallback = "Swift Flight Form", label = "Swift Flight" },
		},
	},
	{
		module = "DruidBuffAssistant",
		class = "DRUID",
		title = "Buff Ring",
		subtitle = "Known druid buffs",
		emptySubtitle = "No buffs trained",
		emptyMessage = "No trained druid buffs found.",
		fallbackIcon = "Interface\\Icons\\Spell_Nature_Regeneration",
		spells = {
			{ id = 1126, fallback = "Mark of the Wild", label = "Mark" },
			{ id = 21849, fallback = "Gift of the Wild", label = "Gift" },
			{ id = 467, fallback = "Thorns" },
			{ id = 16864, fallback = "Omen of Clarity", label = "Omen" },
			{ id = 22812, fallback = "Barkskin" },
			{ id = 16689, fallback = "Nature's Grasp", label = "Grasp" },
			{ id = 2893, fallback = "Abolish Poison", label = "Abolish" },
		},
	},
	{
		module = "MagePortalAssistant",
		class = "MAGE",
		title = "Portal Ring",
		subtitle = "Known mage portals",
		emptySubtitle = "No portals trained",
		emptyMessage = "No trained portal spells found.",
		fallbackIcon = "Interface\\Icons\\Spell_Arcane_PortalStormWind",
		spells = {
			{ id = 10059, fallback = "Portal: Stormwind", label = "Stormwind" },
			{ id = 11416, fallback = "Portal: Ironforge", label = "Ironforge" },
			{ id = 11419, fallback = "Portal: Darnassus", label = "Darnassus" },
			{ id = 32266, fallback = "Portal: Exodar", label = "Exodar" },
			{ id = 49360, fallback = "Portal: Theramore", label = "Theramore" },
			{ id = 11417, fallback = "Portal: Orgrimmar", label = "Orgrimmar" },
			{ id = 11418, fallback = "Portal: Undercity", label = "Undercity" },
			{ id = 11420, fallback = "Portal: Thunder Bluff", label = "Thunder Bluff" },
			{ id = 32267, fallback = "Portal: Silvermoon", label = "Silvermoon" },
			{ id = 49361, fallback = "Portal: Stonard", label = "Stonard" },
			{ id = 33691, fallback = "Portal: Shattrath", label = "Shattrath" },
			{ id = 35717, fallback = "Portal: Shattrath", label = "Shattrath" },
			{ id = 53142, fallback = "Portal: Dalaran", label = "Dalaran" },
		},
	},
	{
		module = "MageTeleportAssistant",
		class = "MAGE",
		title = "Teleport Ring",
		subtitle = "Known mage teleports",
		emptySubtitle = "No teleports trained",
		emptyMessage = "No trained teleport spells found.",
		fallbackIcon = "Interface\\Icons\\Spell_Arcane_TeleportStormWind",
		spells = {
			{ id = 3561, fallback = "Teleport: Stormwind", label = "Stormwind" },
			{ id = 3562, fallback = "Teleport: Ironforge", label = "Ironforge" },
			{ id = 3565, fallback = "Teleport: Darnassus", label = "Darnassus" },
			{ id = 32271, fallback = "Teleport: Exodar", label = "Exodar" },
			{ id = 49359, fallback = "Teleport: Theramore", label = "Theramore" },
			{ id = 3567, fallback = "Teleport: Orgrimmar", label = "Orgrimmar" },
			{ id = 3563, fallback = "Teleport: Undercity", label = "Undercity" },
			{ id = 3566, fallback = "Teleport: Thunder Bluff", label = "Thunder Bluff" },
			{ id = 32272, fallback = "Teleport: Silvermoon", label = "Silvermoon" },
			{ id = 49358, fallback = "Teleport: Stonard", label = "Stonard" },
			{ id = 33690, fallback = "Teleport: Shattrath", label = "Shattrath" },
			{ id = 35715, fallback = "Teleport: Shattrath", label = "Shattrath" },
			{ id = 53140, fallback = "Teleport: Dalaran", label = "Dalaran" },
		},
	},
	{
		module = "MageFoodDrinkAssistant",
		class = "MAGE",
		title = "Food/Drink Ring",
		subtitle = "Known mage conjures",
		emptySubtitle = "No conjures trained",
		emptyMessage = "No trained mage food or drink spells found.",
		fallbackIcon = "Interface\\Icons\\INV_Misc_Food_73CinnamonRoll",
		spells = {
			{ id = 587, fallback = "Conjure Food", label = "Food" },
			{ id = 5504, fallback = "Conjure Water", label = "Water" },
			{ id = 42955, fallback = "Conjure Refreshment", label = "Refresh" },
			{ id = 43987, fallback = "Ritual of Refreshment", label = "Table" },
			{ id = 759, fallback = "Conjure Mana Gem", label = "Mana Gem" },
		},
	},
	{
		module = "PaladinAuraAssistant",
		class = "PALADIN",
		title = "Aura Assistant",
		subtitle = "Known paladin auras",
		emptySubtitle = "No auras trained",
		emptyMessage = "No trained paladin auras found.",
		fallbackIcon = "Interface\\Icons\\Spell_Holy_DevotionAura",
		spells = {
			{ id = 465, fallback = "Devotion Aura", label = "Devotion" },
			{ id = 7294, fallback = "Retribution Aura", label = "Ret" },
			{ id = 19746, fallback = "Concentration Aura", label = "Concent." },
			{ id = 19891, fallback = "Fire Resistance Aura", label = "Fire" },
			{ id = 19888, fallback = "Frost Resistance Aura", label = "Frost" },
			{ id = 19876, fallback = "Shadow Resistance Aura", label = "Shadow" },
			{ id = 32223, fallback = "Crusader Aura", label = "Crusader" },
		},
	},
	{
		module = "PaladinSealAssistant",
		class = "PALADIN",
		title = "Seal Assistant",
		subtitle = "Known paladin seals",
		emptySubtitle = "No seals trained",
		emptyMessage = "No trained paladin seals found.",
		fallbackIcon = "Interface\\Icons\\Ability_ThunderBolt",
		spells = {
			{ id = 21084, fallback = "Seal of Righteousness", label = "Righteous" },
			{ id = 20165, fallback = "Seal of Light", label = "Light" },
			{ id = 20166, fallback = "Seal of Wisdom", label = "Wisdom" },
			{ id = 20164, fallback = "Seal of Justice", label = "Justice" },
			{ id = 20375, fallback = "Seal of Command", label = "Command" },
			{ id = 31801, fallback = "Seal of Vengeance", label = "Vengeance" },
			{ id = 53736, fallback = "Seal of Corruption", label = "Corrupt." },
		},
	},
	{
		module = "PaladinBlessingAssistant",
		class = "PALADIN",
		title = "Blessing Assistant",
		subtitle = "Known paladin blessings",
		emptySubtitle = "No blessings trained",
		emptyMessage = "No trained paladin blessings found.",
		fallbackIcon = "Interface\\Icons\\Spell_Holy_FistOfJustice",
		spells = {
			{ id = 19740, fallback = "Blessing of Might", label = "Might" },
			{ id = 19742, fallback = "Blessing of Wisdom", label = "Wisdom" },
			{ id = 20217, fallback = "Blessing of Kings", label = "Kings" },
			{ id = 20911, fallback = "Blessing of Sanctuary", label = "Sanctuary" },
			{ id = 25782, fallback = "Greater Blessing of Might", label = "G. Might" },
			{ id = 25894, fallback = "Greater Blessing of Wisdom", label = "G. Wisdom" },
			{ id = 25898, fallback = "Greater Blessing of Kings", label = "G. Kings" },
			{ id = 25899, fallback = "Greater Blessing of Sanctuary", label = "G. Sanc." },
		},
	},
	{
		module = "PriestBuffAssistant",
		class = "PRIEST",
		title = "Buff Assistant",
		subtitle = "Known priest buffs",
		emptySubtitle = "No buffs trained",
		emptyMessage = "No trained priest buffs found.",
		fallbackIcon = "Interface\\Icons\\Spell_Holy_WordFortitude",
		spells = {
			{ id = 1243, fallback = "Power Word: Fortitude", label = "Fortitude" },
			{ id = 21562, fallback = "Prayer of Fortitude", label = "P. Fort" },
			{ id = 14752, fallback = "Divine Spirit", label = "Spirit" },
			{ id = 27681, fallback = "Prayer of Spirit", label = "P. Spirit" },
			{ id = 976, fallback = "Shadow Protection", label = "Shadow" },
			{ id = 27683, fallback = "Prayer of Shadow Protection", label = "P. Shadow" },
			{ id = 588, fallback = "Inner Fire", label = "Inner Fire" },
			{ id = 6346, fallback = "Fear Ward", label = "Fear Ward" },
		},
	},
	{
		module = "RoguePoisonAssistant",
		class = "ROGUE",
		title = "Poison Assistant",
		subtitle = "Poisons in your bags",
		emptySubtitle = "No poisons found",
		emptyMessage = "No rogue poisons found in your bags.",
		fallbackIcon = ICON_POISON,
		scan = ScanPoisons,
	},
	{
		module = "ShamanTotemAssistant",
		class = "SHAMAN",
		title = "Totem Assistant",
		subtitle = "Known shaman totems",
		emptySubtitle = "No totems trained",
		emptyMessage = "No trained shaman totems found.",
		fallbackIcon = "Interface\\Icons\\Spell_Nature_EarthBindTotem",
		spells = {
			{ id = 8075, fallback = "Strength of Earth Totem", label = "Str Earth" },
			{ id = 8071, fallback = "Stoneskin Totem", label = "Stoneskin" },
			{ id = 8143, fallback = "Tremor Totem", label = "Tremor" },
			{ id = 2484, fallback = "Earthbind Totem", label = "Earthbind" },
			{ id = 3599, fallback = "Searing Totem", label = "Searing" },
			{ id = 8190, fallback = "Magma Totem", label = "Magma" },
			{ id = 8227, fallback = "Flametongue Totem", label = "Flame" },
			{ id = 1535, fallback = "Fire Nova Totem", label = "Fire Nova" },
			{ id = 5394, fallback = "Healing Stream Totem", label = "Healing" },
			{ id = 5675, fallback = "Mana Spring Totem", label = "Mana" },
			{ id = 8512, fallback = "Windfury Totem", label = "Windfury" },
			{ id = 3738, fallback = "Wrath of Air Totem", label = "Wrath Air" },
			{ id = 8177, fallback = "Grounding Totem", label = "Grounding" },
			{ id = 8170, fallback = "Cleansing Totem", label = "Cleansing" },
		},
	},
	{
		module = "ShamanWeaponAssistant",
		class = "SHAMAN",
		title = "Weapon Imbue Ring",
		subtitle = "Known weapon imbues",
		emptySubtitle = "No imbues trained",
		emptyMessage = "No trained shaman weapon imbues found.",
		fallbackIcon = "Interface\\Icons\\Spell_Nature_Cyclone",
		spells = {
			{ id = 8017, fallback = "Rockbiter Weapon", label = "Rockbiter" },
			{ id = 8024, fallback = "Flametongue Weapon", label = "Flame" },
			{ id = 8033, fallback = "Frostbrand Weapon", label = "Frost" },
			{ id = 8232, fallback = "Windfury Weapon", label = "Windfury" },
			{ id = 51730, fallback = "Earthliving Weapon", label = "Earthliving" },
		},
	},
	{
		module = "ShamanShieldAssistant",
		class = "SHAMAN",
		title = "Shield Assistant",
		subtitle = "Known shaman shields",
		emptySubtitle = "No shields trained",
		emptyMessage = "No trained shaman shield spells found.",
		fallbackIcon = "Interface\\Icons\\Spell_Nature_LightningShield",
		spells = {
			{ id = 324, fallback = "Lightning Shield", label = "Lightning" },
			{ id = 52127, fallback = "Water Shield", label = "Water" },
			{ id = 974, fallback = "Earth Shield", label = "Earth" },
		},
	},
	{
		module = "ShamanUtilityAssistant",
		class = "SHAMAN",
		title = "Utility Ring",
		subtitle = "Known shaman utility",
		emptySubtitle = "No utility trained",
		emptyMessage = "No trained shaman utility spells found.",
		fallbackIcon = "Interface\\Icons\\Spell_Nature_SpiritWolf",
		spells = {
			{ id = 2645, fallback = "Ghost Wolf", label = "Ghost Wolf" },
			{ id = 556, fallback = "Astral Recall", label = "Recall" },
			{ id = 2825, fallback = "Bloodlust" },
			{ id = 32182, fallback = "Heroism" },
			{ id = 51514, fallback = "Hex" },
			{ id = 370, fallback = "Purge" },
			{ id = 51886, fallback = "Cleanse Spirit", label = "Cleanse" },
			{ id = 526, fallback = "Cure Toxins", label = "Cure" },
			{ id = 546, fallback = "Water Walking", label = "Walking" },
			{ id = 131, fallback = "Water Breathing", label = "Breathing" },
			{ id = 6196, fallback = "Far Sight" },
		},
	},
	{
		module = "WarlockDaemonAssistant",
		class = "WARLOCK",
		title = "Daemon Assistant",
		subtitle = "Known warlock summons",
		emptySubtitle = "No daemon summons trained",
		emptyMessage = "No trained warlock daemon summons found.",
		fallbackIcon = "Interface\\Icons\\Spell_Shadow_SummonImp",
		spells = {
			{ id = 688, fallback = "Summon Imp", label = "Imp" },
			{ id = 697, fallback = "Summon Voidwalker", label = "Voidwalker" },
			{ id = 712, fallback = "Summon Succubus", label = "Succubus" },
			{ id = 691, fallback = "Summon Felhunter", label = "Felhunter" },
			{ id = 30146, fallback = "Summon Felguard", label = "Felguard" },
			{ id = 1122, fallback = "Inferno" },
			{ id = 18540, fallback = "Ritual of Doom", label = "Doomguard" },
		},
	},
	{
		module = "WarlockStoneAssistant",
		class = "WARLOCK",
		title = "Stone Assistant",
		subtitle = "Create and use stones",
		emptySubtitle = "No stones available",
		emptyMessage = "No trained stone spells or stone items found.",
		fallbackIcon = ICON_STONE,
		scan = ScanWarlockStones,
		spells = {
			{ id = 6201, fallback = "Create Healthstone", label = "Healthstone" },
			{ id = 693, fallback = "Create Soulstone", label = "Soulstone" },
			{ id = 6366, fallback = "Create Firestone", label = "Firestone" },
			{ id = 2362, fallback = "Create Spellstone", label = "Spellstone" },
			{ id = 29893, fallback = "Create Soulwell", label = "Soulwell" },
		},
	},
	{
		module = "WarlockSummonAssistant",
		class = "WARLOCK",
		title = "Summon Assistant",
		subtitle = "Known warlock utility summons",
		emptySubtitle = "No summon utility trained",
		emptyMessage = "No trained warlock summon utility found.",
		fallbackIcon = "Interface\\Icons\\Spell_Shadow_Twilight",
		spells = {
			{ id = 698, fallback = "Ritual of Summoning", label = "Ritual" },
			{ id = 126, fallback = "Eye of Kilrogg", label = "Eye" },
			{ id = 5697, fallback = "Unending Breath", label = "Breath" },
			{ id = 132, fallback = "Detect Invisibility", label = "Detect" },
			{ id = 1098, fallback = "Enslave Demon", label = "Enslave" },
		},
	},
	{
		module = "WarriorStanceAssistant",
		class = "WARRIOR",
		title = "Stance Assistant",
		subtitle = "Known warrior stances",
		emptySubtitle = "No stances trained",
		emptyMessage = "No trained warrior stances found.",
		fallbackIcon = "Interface\\Icons\\Ability_Warrior_OffensiveStance",
		spells = {
			{ id = 2457, fallback = "Battle Stance", label = "Battle" },
			{ id = 71, fallback = "Defensive Stance", label = "Defensive" },
			{ id = 2458, fallback = "Berserker Stance", label = "Berserker" },
		},
	},
	{
		module = "WarriorShoutAssistant",
		class = "WARRIOR",
		title = "Shout Assistant",
		subtitle = "Known warrior shouts",
		emptySubtitle = "No shouts trained",
		emptyMessage = "No trained warrior shouts found.",
		fallbackIcon = "Interface\\Icons\\Ability_Warrior_BattleShout",
		spells = {
			{ id = 6673, fallback = "Battle Shout", label = "Battle" },
			{ id = 469, fallback = "Commanding Shout", label = "Command" },
			{ id = 1160, fallback = "Demoralizing Shout", label = "Demo" },
			{ id = 1161, fallback = "Challenging Shout", label = "Challenge" },
			{ id = 5246, fallback = "Intimidating Shout", label = "Fear" },
			{ id = 12323, fallback = "Piercing Howl", label = "Piercing" },
		},
	},
}

for _, config in ipairs(RINGS) do
	RegisterClassRing(config)
end
