local addonName, ns = ...

local WeeklyDelveMaps = {}

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

	local DELVE_MAP_ITEM_ID = 233071

	local Progress = {
		required = 1,
		remaining = { 86371 },
	}

	function Progress:Update()
		for i = #self.remaining, 1, -1 do
			if C_QuestLog.IsQuestFlaggedCompleted(self.remaining[i]) then
				table.remove(self.remaining, i)
			end
		end
	end

	function Progress:Summary()
		local color = #self.remaining == 0 and GREEN_FONT_COLOR or WHITE_FONT_COLOR

		return color:WrapTextInColorCode(format("%d/%d", self.required - #self.remaining, self.required))
	end

	function Progress:Init()
		local item = Item:CreateFromItemID(DELVE_MAP_ITEM_ID)

		item:ContinueOnItemLoad(function()
			local name = item:GetItemName()
			local icon = item:GetItemIcon()
			local quality = item:GetItemQuality()
			print(icon)

			hooksecurefunc(DelveEntrancePinMixin, "OnMouseEnter", function(frame)
				local progress = format(
					"%s: %s",
					CURRENCY_THIS_WEEK:format(CreateSimpleTextureMarkup(icon, 15, 15) .. " " .. ITEM_QUALITY_COLORS[quality].color:WrapTextInColorCode(name)),
					self:Summary()
				)

				if frame.description == DELVE_LABEL then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(progress)
				else
					local numLines = GameTooltip:NumLines()
					local line = _G["GameTooltipTextLeft" .. numLines]
					for i = 3, numLines do
						if _G["GameTooltipTextLeft" .. i]:GetText() ~= " " then
							line = _G["GameTooltipTextLeft" .. i - 1]
							break
						end
					end

					line:SetText(progress .. "|n" .. " ")
				end

				GameTooltip:Show()
			end)
		end)
	end

	WeeklyDelveMaps:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
		if isInitialLogin == false and isReloadingUi == false then
			return
		end

		C_Timer.After(1, function()
			Progress:Init()
		end)
	end)

	WeeklyDelveMaps:RegisterEvent("QUEST_LOG_UPDATE", function()
		Progress:Update()
	end)
end
