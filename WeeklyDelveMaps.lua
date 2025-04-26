local addonName, ns = ...

local Progress = {
	required = 1,
	DELVE_MAP_ITEM_ID = 233071,
	DELVE_MAP_SPELL_ID = 473218,
}
Progress.__index = Progress

function Progress:Create()
	local o = { remaining = { 86371 } }

	setmetatable(o, Progress)
	return o
end

function Progress:Update()
	for i = #self.remaining, 1, -1 do
		if C_QuestLog.IsQuestFlaggedCompleted(self.remaining[i]) then
			table.remove(self.remaining, i)
		end
	end

	self.count = C_Item.GetItemCount(self.DELVE_MAP_ITEM_ID, true)
	self.pending = C_UnitAuras.GetPlayerAuraBySpellID(self.DELVE_MAP_SPELL_ID) and true
end

function Progress:Summary()
	local color = #self.remaining == 0 and "GREEN" or self.count > 0 and "RED" or "WHITE"

	local s = format("|cn%s_FONT_COLOR:%d/%d|r", color, self.required - #self.remaining, self.required)

	if self.pending then
		s = "|cnYELLOW_FONT_COLOR:*|r" .. s
	end

	if self.count > 0 then
		s = format("|cnLIGHTBLUE_FONT_COLOR:(%d) |r", self.count) .. s
	end

	return s
end

local WeeklyDelveMaps = {}

function WeeklyDelveMaps:Init()
	self.progress = Progress:Create()

	hooksecurefunc(DelveEntrancePinMixin, "OnMouseEnter", function(frame)
		self:AddProgressToTooltip(GameTooltip, frame)

		GameTooltip:Show()
	end)
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

function WeeklyDelveMaps:AddProgressToTooltip(tooltip, pin)
	if self.title == nil then
		self:UpdateProgressTitle()
	end

	local title = self.title or LFG_LIST_LOADING -- Loading...
	local progress = format("%s: %s", title, self.progress:Summary())

	if pin.description == DELVE_LABEL then
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

		line:SetText(progress .. "|n" .. " ")
	end
end

if _G["WeeklyDelveMaps"] == nil then
	_G["WeeklyDelveMaps"] = WeeklyDelveMaps

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

	WeeklyDelveMaps:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
		if isInitialLogin == false and isReloadingUi == false then
			return
		end

		WeeklyDelveMaps:Init()
	end)

	WeeklyDelveMaps:RegisterEvent("QUEST_LOG_UPDATE", function()
		WeeklyDelveMaps.progress:Update()
	end)
end
