local name, addonTable = ...
LootTracker = addonTable
LootTracker.Version = GetAddOnMetadata(name, "Version");
local LootTrackerDB = { }

-- window frame. Eventually, this should be moved to its own file
local window
local FRAME_WIDTH = 503
local FRAME_HEIGHT = 500
local HEADER_HEIGHT = 24
local HEADER_LEFT = 3
local HEADER_TOP = -50
local ROW_HEIGHT = 16
local ROW_TEXT_PADDING = 5
local NAME_WIDTH = 300
local KILL_WIDTH = 100
local LOOTABLE_WIDTH = 100
local SCROLL_WIDTH = 29
local TITLE_HEADER_TEXT = "LootTracker v%s"

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
	window.titleLabel:SetText(TITLE_HEADER_TEXT:format(LootTracker.Version))

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
	window.helpLabel:SetText("Left click to see a loot table. Right click to remove the creature.")

	window.nameHeader = CreateHeader(window)
	window.nameHeader:SetPoint("TOPLEFT", window, "TOPLEFT", HEADER_LEFT, HEADER_TOP)
	window.nameHeader:SetWidth(NAME_WIDTH - SCROLL_WIDTH)
	window.nameHeader:SetText("Name")

	window.totalKillHeader = CreateHeader(window)
	window.totalKillHeader:SetPoint("TOPLEFT", window.nameHeader, "TOPRIGHT", -2, 0)
	window.totalKillHeader:SetWidth(KILL_WIDTH)
	window.totalKillHeader:SetText("Kills")

	window.numberLootableHeader = CreateHeader(window)
	window.numberLootableHeader:SetPoint("TOPLEFT", window.totalKillHeader, "TOPRIGHT", -2, 0)
	window.numberLootableHeader:SetWidth(LOOTABLE_WIDTH + HEADER_LEFT)
	window.numberLootableHeader:SetText("Lootable")

	local maxRows = 0
	local function updateScrollFrame(clearAll)
		local data = LootTrackerDB.Data or {}
		local rowCount = 0
		for k,v in pairs(data) do rowCount = rowCount + 1 end
		FauxScrollFrame_Update(window.scrollFrame, rowCount, maxRows, ROW_HEIGHT, nil, nil, nil, nil, nil, nil, true)
		local offset = FauxScrollFrame_GetOffset(LootTrackerScrollFrame) or 0
		-- since we're using a non-sequential table index, we need separate counters to track the offset manually
		-- rowCounter tracks the row being updated in the frame, while mobIndex tracks the creature entry in LootTrackerDB.Data
		if clearAll then
			for i=1, maxRows do
				window.scrollFrame.rows[i].name:SetText("")
				window.scrollFrame.rows[i].totalKill:SetText("")
				window.scrollFrame.rows[i].numberLootable:SetText("")
				window.scrollFrame.rows[i]:Disable()
			end
		end
		local rowCounter, mobIndex = 1, 1
		for k,v in pairs(data) do
			-- if the current mob we're looking at sits at an index above the scrollFrame offset, we want to render it
			if mobIndex >= offset then
				window.scrollFrame.rows[rowCounter].name:SetText(v.name .. ' (' .. k .. ')')
				window.scrollFrame.rows[rowCounter].totalKill:SetText(v.total)
				window.scrollFrame.rows[rowCounter].numberLootable:SetText(v.lootable)
				window.scrollFrame.rows[rowCounter]:Enable()
				rowCounter = rowCounter + 1
			end
			-- if we've exceeded the maximum number of rows in the window, then we can stop the loop
			if rowCounter > maxRows then break end
			-- always increase the mobIndex counter
			mobIndex = mobIndex + 1
		end
		
		if offset <= 0 then
			LootTrackerScrollFrameScrollBarScrollUpButton:Disable()
		else
			LootTrackerScrollFrameScrollBarScrollUpButton:Enable()
		end
		
		if rowCount < maxRows or offset + maxRows >= rowCount then
			LootTrackerScrollFrameScrollBarScrollDownButton:Disable()
		else
			LootTrackerScrollFrameScrollBarScrollDownButton:Enable()
		end
	end
	
	window.purgeButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
	window.purgeButton:SetHeight(24)
	window.purgeButton:SetWidth(150)
	window.purgeButton:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -5)
	window.purgeButton:SetText("Purge data (temp)")
	window.purgeButton:SetScript("OnClick", function()
		table.wipe(LootTrackerDB.Data)
		updateScrollFrame(true)
	end)
	
	window.scrollFrame = CreateFrame("ScrollFrame", "LootTrackerScrollFrame", window, "FauxScrollFrameTemplateLight")
	window.scrollFrame:SetWidth(window:GetWidth())
	window.scrollFrame:SetPoint("TOPLEFT", window.nameHeader, "TOPLEFT", 0, -3)
	window.scrollFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -SCROLL_WIDTH, 4)
	window.scrollFrame:SetScript("OnVerticalScroll", function(s, val) FauxScrollFrame_OnVerticalScroll(s, val, ROW_HEIGHT, updateScrollFrame) end)
	window.scrollFrame:SetScript("OnShow", function() updateScrollFrame() end)
	window.scrollFrame.rows = { }

	local function updateMaxRows()
		maxRows = math.floor(window.scrollFrame:GetHeight() / ROW_HEIGHT)-1
		if maxRows < 0 then maxRows = 1 end
	end
	updateMaxRows()
	
	-- initialize the scrollFrame with rows. Initially they should be blank
	-- TODO: do we really need this? If the need for a new row can be calculated on demand in window.Update, this initial seeding may not be needed
	local lastKnownRow = window.nameHeader
	for i=1, maxRows do
		window.scrollFrame.rows[i] = CreateRow(window.scrollFrame, lastKnownRow)
		window.scrollFrame.rows[i].name:SetText("")
		window.scrollFrame.rows[i].totalKill:SetText("")
		window.scrollFrame.rows[i].numberLootable:SetText("")
		window.scrollFrame.rows[i]:Disable()
		lastKnownRow = window.scrollFrame.rows[i]
	end

	window.Update = updateScrollFrame
end


-- general functions
local saveCreatureData = function(creatureID, name, hasLoot)
	local creature = rawget(LootTrackerDB.Data, creatureID) or {name=name}
	creature.total = (creature.total or 0) + 1
	creature.lootable = (creature.lootable or 0) + (hasLoot and 1 or 0)
	rawset(LootTrackerDB.Data, creatureID, creature)
	-- TODO:: this is almost certainly a performance hit. Maybe better to only update window when combat ends instead of on each kill?
	window.Update()
end
local getCreatureIDForGUID = function(unitGUID)
	local tbl = { strsplit("-",unitGUID) }
	-- TODO: how to handle Vignette mobs (always 0 ID)? C_VignetteInfo exists, but it doesn't seem to expose anything useful
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

-- TODO: hook into the BOSS_KILL(ID,name) event since some bosses don't trigger PARTY_KILL. How to detect PARTY_KILL if BOSS_KILL has already triggered for the encounter?
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
eventFrame.events.COMBAT_LOG_EVENT_UNFILTERED = function()
	local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo();
	if event == "PARTY_KILL" then
		C_Timer.After(1, function() captureLootInfo(destGUID, destName, destFlags) end)
	end
end
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame.events.VARIABLES_LOADED = function()
	LootTrackerDB = _G["LootTrackerDB"] or {}
	if not _G["LootTrackerDB"] then _G["LootTrackerDB"] = LootTrackerDB end
	if not LootTrackerDB.Data then LootTrackerDB.Data = { } end
		
	CreateWindow()
	window.Update()
	window:Show()
end