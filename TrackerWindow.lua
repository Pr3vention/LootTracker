local addon = select(2,...)
local Window = {}
Window.__index = Window
addon.Window = Window

-- This file is a work in progress. There's a lot of cleanup and optimization that can occur but it currently works

local LootTrackerWindow
local ROW_HEIGHT = addon.Constants.ROW_HEIGHT

function Column_SetWidth(frame, width)
	frame:SetWidth(width);
	_G[frame:GetName().."Middle"]:SetWidth(width - 9);
end

local function SetMaxVisibleRows(scrollFrame)
	local rows = math.floor(scrollFrame:GetHeight() / ROW_HEIGHT)
	scrollFrame.maxRows = rows
end

function Window:Update()
	local data = LootTrackerDB.Data or {}
	local sf = LootTrackerWindow.ScrollFrame
	local offset = FauxScrollFrame_GetOffset(sf)
	local numRows = #sf.rows
	local count, index = 0, 1
	for creatureID,info in pairs(data) do
		if count >= offset and index <= sf.maxRows then
			sf.rows[index].Name:SetText(info.name)
			sf.rows[index].Killed:SetText(info.total)
			sf.rows[index].Lootable:SetText(info.lootable)
			sf.rows[index]:Show()
			index = index + 1
		end
		count = count + 1
	end

	if count < sf.maxRows then
		for i=count, sf.maxRows do
			sf.rows[i]:Hide()
		end
	end
	
	FauxScrollFrame_Update(sf, count, sf.maxRows, ROW_HEIGHT, nil, nil, nil, nil, nil, nil, true);
end

function OnLoad(frame)
	LootTrackerWindow = frame
	_G[LootTrackerWindow:GetName()].Title:SetText(string.format("LootTracker v%s",addon.Version))
	SetMaxVisibleRows(LootTrackerWindow.ScrollFrame)
	
	LootTrackerWindow.ScrollFrame.rows = {}
	for i=1, LootTrackerWindow.ScrollFrame.maxRows do
		local row = CreateFrame("Button", "LootTrackerRow"..i, LootTrackerWindow.ScrollFrame, "LootTrackerRowTemplate")
		if i == 1 then
			row:SetPoint("TOPLEFT", LootTrackerWindow.ScrollFrame, "TOPLEFT")
		else
			row:SetPoint("TOPLEFT", LootTrackerWindow.ScrollFrame.rows[i-1], "BOTTOMLEFT")
		end
		LootTrackerWindow.ScrollFrame.rows[i] = row
	end
end
