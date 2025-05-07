local addonName, ns = ...

local Util = ns.Util
local CharacterStore = ns.CharacterStore
local Progress = ns.Progress

local WeeklyDelveMaps = {}

function WeeklyDelveMaps:Init()
	hooksecurefunc(DelveEntrancePinMixin, "OnMouseEnter", function(frame)
		self:UpdateTooltip(GameTooltip, frame.description ~= DELVE_LABEL)
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if not self:IsValidMap(tooltip:GetPrimaryTooltipData().id) then
			return
		end

		self:UpdateTooltip(tooltip, false)
	end)

	CharacterStore:SetCharacterTemplate(ns.Character)
	CharacterStore:SetFlatField("progress")
	CharacterStore.Load(self.db.characters)

	self.characterStore = CharacterStore.Get()
	self.characterStore:SetSortOrder("name")

	self.character = self.characterStore:CurrentPlayer()
end

function WeeklyDelveMaps:ResetProgress()
	local resetTime = C_DateAndTime.GetWeeklyResetStartTime()
	if resetTime == self.db.resetTime then
		return
	end

	local filter = function(character)
		return character.updatedAt and character.updatedAt < resetTime
	end

	-- TODO: Temp Migration
	if self.db.resetTime == nil then
		filter = function()
			return true
		end
	end

	self.characterStore:ForEach(function(character)
		character.progress:Reset()
	end, filter)

	self.db.resetTime = resetTime

	print(addonName .. ": Progress were reset")
end

function WeeklyDelveMaps:UpdateTooltip(tooltip, appendEndLine)
	if IsControlKeyDown() then
		self:AddWarbandProgressToTooltip(tooltip, appendEndLine)
	elseif not IsModifierKeyDown() then
		self:AddProgressToTooltip(tooltip, appendEndLine)
	end

	tooltip:Show()
end

function WeeklyDelveMaps:IsValidMap(itemID)
	local mapItems = {
		[233071] = true, -- Delver's Bounty in bag
		[235628] = true, -- Delver's Bounty with upgrade data
	}

	return mapItems[itemID] == true
end

function WeeklyDelveMaps:UpdateProgressTitle()
	local item = Item:CreateFromItemID(Progress.DELVE_MAP_ITEM_ID)

	local updateTitle = function()
		local name = item:GetItemName()
		local icon = item:GetItemIcon()
		local quality = item:GetItemQuality()

		self.title = CURRENCY_THIS_WEEK:format(CreateSimpleTextureMarkup(icon, 15, 15) .. " " .. ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(name))
	end

	if item:IsItemDataCached() then
		updateTitle()
	else
		item:ContinueOnItemLoad(updateTitle)
	end
end

function WeeklyDelveMaps:AddProgressToTooltip(tooltip, appendEndLine)
	if self.title == nil then
		self:UpdateProgressTitle()
	end

	local title = self.title or LFG_LIST_LOADING -- Loading...
	local progress = format("|cnNORMAL_FONT_COLOR:%s:|r %s", title, self.character.progress:Summary())

	if not appendEndLine then
		tooltip:AddLine(" ")
		tooltip:AddLine(progress)
	else
		local numLines = tooltip:NumLines()
		local line = _G["GameTooltipTextLeft" .. numLines]
		for i = 3, numLines do
			if _G["GameTooltipTextLeft" .. i]:GetText() ~= " " then
				line = _G["GameTooltipTextLeft" .. i - 1]
				break
			end
		end

		line:SetText(progress)
	end

	tooltip:AddLine("|n|cnGREEN_FONT_COLOR:<Press CTRL to show all characters>|r")
	if appendEndLine then
		tooltip:AddLine(" ")
	end
end

function WeeklyDelveMaps:AddWarbandProgressToTooltip(tooltip, appendEndLine)
	if self.title == nil then
		tooltip:AddLine(LFG_LIST_LOADING)
		return
	end

	tooltip:AddLine(self.title)

	local indent = CreateSimpleTextureMarkup(0, 15, 15) .. " "
	self.characterStore:ForEach(function(character)
		tooltip:AddDoubleLine(
			Util.WrapTextInClassColor(character.class, format("%s%s - %s", indent, character.name, character.realmName)),
			character.progress:Summary()
		)
	end, function(character)
		return character.level == 80
	end)

	if appendEndLine then
		tooltip:AddLine(" ")
	end
end

if _G["WeeklyDelveMaps"] == nil then
	_G["WeeklyDelveMaps"] = WeeklyDelveMaps

	local DefaultWeeklyDelveMapsDB = { characters = {} }

	WeeklyDelveMaps.frame = CreateFrame("Frame")

	WeeklyDelveMaps.frame:SetScript("OnEvent", function(self, event, ...)
		WeeklyDelveMaps.eventsHandler[event](event, ...)
	end)

	function WeeklyDelveMaps:RegisterEvent(name, handler)
		if self.eventsHandler == nil then
			self.eventsHandler = {}
		end
		self.eventsHandler[name] = handler
		self.frame:RegisterEvent(name)
	end

	WeeklyDelveMaps:RegisterEvent("ADDON_LOADED", function(event, name)
		if name ~= addonName then
			return
		end

		WeeklyDelveMapsDB = WeeklyDelveMapsDB or DefaultWeeklyDelveMapsDB

		WeeklyDelveMaps.db = WeeklyDelveMapsDB
		Util.debug = WeeklyDelveMapsDB.debug
	end)

	WeeklyDelveMaps:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
		if isInitialLogin == false and isReloadingUi == false then
			return
		end

		WeeklyDelveMaps:Init()
		WeeklyDelveMaps:ResetProgress()
	end)

	WeeklyDelveMaps:RegisterEvent("QUEST_LOG_UPDATE", function()
		WeeklyDelveMaps.character:Update()
	end)
end
