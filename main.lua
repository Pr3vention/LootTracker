local name, addonTable = ...
LootTracker = addonTable
local LootTrackerDB = { }

-- window frame. Eventually, this should be moved to its own file
local window
local FRAME_WIDTH = 503
local FRAME_HEIGHT = 500
local HEADER_HEIGHT = 24
local HEADER_LEFT = 3
local HEADER_TOP = -50
local ROW_HEIGHT = 15
local ROW_TEXT_PADDING = 5
local ROWS_HEIGHT = 450
local NAME_WIDTH = 300
local KILL_WIDTH = 100
local LOOTABLE_WIDTH = 100
local SCROLL_WIDTH = 27 -- Scrollbar width
local STATUS_TEXT = "Total number of creatures: %d"

local CreateHeader = function(parent)
	local h = CreateFrame("Button", nil, parent)
	h:SetHeight(HEADER_HEIGHT)
	h:SetNormalFontObject("GameFontHighlightSmall")

	local bgl = h:CreateTexture(nil, "BACKGROUND")
	bgl:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
	bgl:SetWidth(5)
	bgl:SetHeight(HEADER_HEIGHT)
	bgl:SetPoint("TOPLEFT")
	bgl:SetTexCoord(0, 0.07815, 0, 0.75)

	local bgr = h:CreateTexture(nil, "BACKGROUND")
	bgr:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
	bgr:SetWidth(5)
	bgr:SetHeight(HEADER_HEIGHT)
	bgr:SetPoint("TOPRIGHT")
	bgr:SetTexCoord(0.90625, 0.96875, 0, 0.75)

	local bgm = h:CreateTexture(nil, "BACKGROUND")
	bgm:SetTexture("Interface\\FriendsFrame\\WhoFrame-ColumnTabs")
	bgm:SetHeight(HEADER_HEIGHT)
	bgm:SetPoint("LEFT", bgl, "RIGHT")
	bgm:SetPoint("RIGHT", bgr, "LEFT")
	bgm:SetTexCoord(0.07815, 0.90625, 0, 0.75)

	local hl = h:CreateTexture()
	h:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight", "ADD")
	hl:SetPoint("TOPLEFT", bgl, "TOPLEFT", -2, 5)
	hl:SetPoint("BOTTOMRIGHT", bgr, "BOTTOMRIGHT", 2, -7)

	return h
end

local CreateRow = function(container, previous)
	local row = CreateFrame("Button", nil, container)
	row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("LEFT")
	row:SetPoint("RIGHT")
	row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)

	row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.name:SetHeight(ROW_HEIGHT)
	row.name:SetWidth(NAME_WIDTH - SCROLL_WIDTH - ROW_TEXT_PADDING * 3)
	row.name:SetPoint("LEFT", row, "LEFT", ROW_TEXT_PADDING, 0)
	row.name:SetJustifyH("LEFT")

	row.totalKill = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.totalKill:SetHeight(ROW_HEIGHT)
	row.totalKill:SetWidth(KILL_WIDTH - ROW_TEXT_PADDING * 2)
	row.totalKill:SetPoint("LEFT", row.name, "RIGHT", 2 * ROW_TEXT_PADDING, 0)
	row.totalKill:SetJustifyH("RIGHT")

	row.numberLootable = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.numberLootable:SetHeight(ROW_HEIGHT)
	row.numberLootable:SetWidth(LOOTABLE_WIDTH - ROW_TEXT_PADDING * 2)
	row.numberLootable:SetPoint("LEFT", row.totalKill, "RIGHT", 2 * ROW_TEXT_PADDING, 0)
	row.numberLootable:SetJustifyH("RIGHT")
	return row
end
local CreateWindow = function()
	if window then return end
	window = CreateFrame("FRAME", 'LootTrackerWindow', UIParent)
	window:SetToplevel(true)
	window:EnableMouse(true)
	window:SetMovable(true)
	window:SetPoint("CENTER")
	window:SetWidth(FRAME_WIDTH)
	window:SetHeight(FRAME_HEIGHT)

	local bd = {
	  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	  tile = true,
	  edgeSize = 16,
	  tileSize = 32,
	  insets = {
		 left = 2.5,
		 right = 2.5,
		 top = 2.5,
		 bottom = 2.5
	  }
	}
	window:SetBackdrop(bd)

	window.titleLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	window.titleLabel:SetWidth(250)
	window.titleLabel:SetHeight(16)
	window.titleLabel:SetPoint("TOP", window, "TOP", 0, -5)
	window.titleLabel:SetText("LootTracker")

	window:SetScript("OnMouseDown", function(s) s:StartMoving() end)
	window:SetScript("OnMouseUp", function(s) s:StopMovingOrSizing() end)

	window.closeButton = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	window.closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -1, -1)

	window.helpLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	window.helpLabel:SetWidth(380)
	window.helpLabel:SetHeight(16)
	window.helpLabel:SetPoint("TOP", window, "TOP", 0, -28)
	window.helpLabel:SetWordWrap(true)
	window.helpLabel:SetMaxLines(2)
	window.helpLabel:SetText("Click an entry to see its loot table.")

	window.nameHeader = CreateHeader(window)
	window.nameHeader:SetPoint("TOPLEFT", window, "TOPLEFT", HEADER_LEFT, HEADER_TOP)
	window.nameHeader:SetWidth(NAME_WIDTH - SCROLL_WIDTH)
	window.nameHeader:SetText("Name")

	window.totalKillHeader = CreateHeader(window)
	window.totalKillHeader:SetPoint("TOPLEFT", window.nameHeader, "TOPRIGHT", -2, 0)
	window.totalKillHeader:SetWidth(KILL_WIDTH)
	window.totalKillHeader:SetText("Total Kills")

	window.numberLootableHeader = CreateHeader(window)
	window.numberLootableHeader:SetPoint("TOPLEFT", window.totalKillHeader, "TOPRIGHT", -2, 0)
	window.numberLootableHeader:SetWidth(LOOTABLE_WIDTH + HEADER_LEFT)
	window.numberLootableHeader:SetText("# Lootable")

	window.rows = CreateFrame("FRAME", nil, window)
	window.rows:SetPoint("LEFT")
	window.rows:SetPoint("RIGHT", window, "RIGHT", -SCROLL_WIDTH, 0)
	window.rows:SetPoint("TOP", window.nameHeader, "BOTTOM", 0, 0)
	window.rows:SetPoint("BOTTOM", window, "BOTTOM", 0, 0)
	window.rows:SetPoint("TOPLEFT", window.nameHeader, "BOTTOMLEFT", 0, 30)

	local lastKnownRow = window.nameHeader
	for k,v in pairs(LootTrackerDB.Data) do
		window.rows[k] = CreateRow(window.rows, lastKnownRow)
		window.rows[k].name:SetText(v.name .. ' (' .. k .. ')')
		window.rows[k].totalKill:SetText(v.total)
		window.rows[k].numberLootable:SetText(v.lootable)
		lastKnownRow = window.rows[k]
	end
	
	window.rows.scroller = CreateFrame("ScrollFrame", "LootTrackerScrollFrame", window.rows, "FauxScrollFrameTemplateLight")
	window.rows.scroller:SetWidth(window.rows:GetWidth())
	window.rows.scroller:SetPoint("TOPRIGHT", window.rows, "TOPRIGHT", -2, -9)
	window.rows.scroller:SetPoint("BOTTOMRIGHT", 0, 4)
	window.rows.scroller:SetScript("OnVerticalScroll",
		function(s, val)
			FauxScrollFrame_OnVerticalScroll(
				s, val, ROW_HEIGHT,
				function()
					local offset = FauxScrollFrame_GetOffset(LootTrackerScrollFrame)
					-- TODO: have this actually scroll the window by modifying what data is visible
				end
			)
		end
	)
	window.statusLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	window.statusLabel:SetWidth(420)
	window.statusLabel:SetHeight(16)
	window.statusLabel:SetPoint("BOTTOM", window, "BOTTOM", 0, 8)
	window.statusLabel:SetText(STATUS_TEXT:format(ROW_COUNT))
	
	window.insertNewCreatureData = function(creatureID, creatureData)
		if creatureID and creatureData then
			window.rows[creatureID] = CreateRow(window.rows, lastKnownRow)
			window.rows[creatureID].name:SetText(creatureData.name .. ' (' .. creatureID .. ')')
			window.rows[creatureID].totalKill:SetText(creatureData.total)
			window.rows[creatureID].numberLootable:SetText(creatureData.lootable)
			lastKnownRow = window.rows[creatureID]
		end
	end
	window.updateWindowData = function(creatureID)
		local creatureData = LootTrackerDB.Data[creatureID]
		if creatureData then
			if window.rows[creatureID] then
				window.rows[creatureID].totalKill:SetText(creatureData.total)
				window.rows[creatureID].numberLootable:SetText(creatureData.lootable)
			else
				window.insertNewCreatureData(creatureID, creatureData)
			end
		end
	end
end

-- general functions
local saveCreatureData = function(creatureID, name, hasLoot)
	local creature = rawget(LootTrackerDB.Data, creatureID) or {name=name}
	creature.total = (creature.total or 0) + 1
	creature.lootable = (creature.lootable or 0) + (hasLoot and 1 or 0)
	rawset(LootTrackerDB.Data, creatureID, creature)
	 -- TODO:: this is almost certainly a major performance hit. Maybe better to only update window when combat ends?
	window.updateWindowData(creatureID)
end
local getCreatureIDForGUID = function(unitGUID)
	local tbl = { strsplit("-",unitGUID) }
	if tbl[1] == "Creature" then
		return tbl[6]
	end
end
local captureLootInfo = function(unitGUID, name, flags)
	local creatureID = getCreatureIDForGUID(unitGUID)
	if creatureID then
		local hasLoot, inRange = CanLootUnit(unitGUID)
		saveCreatureData(creatureID, name, hasLoot)
	end
end

----------------
-- Public API --
----------------
LootTracker.Print = function()
	for k,v in pairs(LootTrackerDB.Data) do
		print(v.name .. ' (' .. k .. ') has been killed ' .. v.total .. ' time(s), of which ' .. v.lootable .. ' had loot.')
	end
end

--------------------
-- Event Handling --
--------------------
-- Events must be registered to a frame. Since we only want these to fire once, we'll create an invisible
-- dummy frame to intercept and handle collection events
local eventFrame = CreateFrame("FRAME", nil, UIParent)
eventFrame.events = {}
eventFrame:SetScript("OnEvent", function(self, event, ...) (eventFrame.events[event] or print)(...) end)
LootTracker.testframe = eventFrame

eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
eventFrame.events.COMBAT_LOG_EVENT_UNFILTERED = function()
	local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo();
	if event == "PARTY_KILL" then
		C_Timer.After(0.25, function() captureLootInfo(destGUID, destName, destFlags) end)
	end
end
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame.events.VARIABLES_LOADED = function()
	-- TODO: cache some info here like character GUID, capture sessions, etc
	LootTrackerDB = _G["LootTrackerDB"] or {}
	if not _G["LootTrackerDB"] then _G["LootTrackerDB"] = LootTrackerDB end
	if not LootTrackerDB.Data then LootTrackerDB.Data = { } end
		
	CreateWindow()
	window:Show()
end