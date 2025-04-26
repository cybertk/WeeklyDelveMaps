local _, ns = ...

local Util = ns.Util

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

ns.Progress = Progress

local Character = {}
Character.__index = Character

function Character:New(o)
	o = o or {}
	setmetatable(o, self)

	if next(o) == nil then
		Character._Init(o)
	else
		setmetatable(o.progress, Progress)
	end

	return o
end

function Character:_Init()
	local _localizedClassName, classFile, _classID = UnitClass("player")
	local _englishFactionName, localizedFactionName = UnitFactionGroup("player")

	self.name = UnitName("player")
	self.GUID = UnitGUID("player")
	self.realmName = GetRealmName()
	self.level = UnitLevel("player")
	self.factionName = localizedFactionName
	self.class = classFile
	self.progress = Progress:Create()
	self.updatedAt = GetServerTime()

	Util:Debug("Initialized new character:", self.name)
end

function Character:Update()
	self.progress:Update()
	self.updatedAt = GetServerTime()
end

ns.Character = Character
