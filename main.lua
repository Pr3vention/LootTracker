local name, addonTable = ...
LootTracker = addonTable
LootTracker.Version = GetAddOnMetadata(name, "Version");

LootTracker.Constants = {
	ROW_HEIGHT = 16,
}

local Window = LootTracker.Window
local LootTrackerDB = { }

-- general functions
local GetCreatureIDFromGUID = function(unitGUID)
	local tbl = { strsplit("-",unitGUID) }
	if tbl[1] == "Creature" then
		return tbl[6]
	end
end
local GetItemInfoFromLink = function(itemLink)
	if not itemLink then return end
	local _, _, Color, LinkType, ID = string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+)")
	local Name
	if LinkType == "item" then
		Name = C_Item.GetItemNameByID(ID)
	elseif LinkType == "currency" then
		Name = C_CurrencyInfo.GetCurrencyInfo(ID)
	else
		return LinkType, ID, "UNKNOWN"
	end
	
	local CleanLink = '|cff' .. Color .. '|H' .. LinkType .. ':' .. ID .. ':::::::::|h[' .. Name .. ']|h|r'
	return LinkType, ID, Name, CleanLink
end

local SaveCreatureData = function(creatureID, name, hasLoot)
	local creature = rawget(LootTrackerDB.Data, creatureID) or {name=name}
	creature.total = (creature.total or 0) + 1
	creature.lootable = (creature.lootable or 0) + (hasLoot and 1 or 0)
	-- This doesn't happen often, but sometimes mob names can change... if they do, update the cached name
	if creature.name ~= name then
		creature.name = name
	end
	
	rawset(LootTrackerDB.Data, creatureID, creature)
	-- TODO:: this is almost certainly a performance hit. Maybe better to only update window when combat ends instead of on each kill?
	LootTracker.Window:Update()
end
local CaptureLootInfo = function(unitGUID, name, flags)
	local creatureID = GetCreatureIDFromGUID(unitGUID)
	--print(unitGUID, name, creatureID)
	if creatureID then
		local hasLoot, inRange = CanLootUnit(unitGUID)
		SaveCreatureData(creatureID, name, hasLoot)
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

-- TODO: hook into the BOSS_KILL(ID,name) event since some bosses don't trigger PARTY_KILL. How to detect PARTY_KILL if BOSS_KILL has already triggered for the encounter?
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
eventFrame.events.COMBAT_LOG_EVENT_UNFILTERED = function()
	local _, event, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags = CombatLogGetCurrentEventInfo();
	if event == "PARTY_KILL" then
		C_Timer.After(1, function() CaptureLootInfo(destGUID, destName, destFlags) end)
	end
end
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame.events.VARIABLES_LOADED = function()
	LootTrackerDB = _G["LootTrackerDB"] or {}
	if not _G["LootTrackerDB"] then _G["LootTrackerDB"] = LootTrackerDB end
	if not LootTrackerDB.Data then LootTrackerDB.Data = { } end
	LootTracker.Window:Update()
end
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame.events.LOOT_OPENED = function(autoloot, isFromItem)
	local numItemsLooted = GetNumLootItems()
	for slot=1,numItemsLooted do
		local itemLink = GetLootSlotLink(slot)
		local LinkType, ID, Name, CleanLink = GetItemInfoFromLink(itemLink)
		-- TODO: make this work for non-teim loot as well (currency, gold, etc)
		if ID then
			local lootSourceInfo = {GetLootSourceInfo(slot)}
			for i=1,#lootSourceInfo,2 do
				local sourceID = GetCreatureIDFromGUID(lootSourceInfo[i])
				if(LootTrackerDB.Data[sourceID]) then
					if not LootTrackerDB.Data[sourceID].loot then
						LootTrackerDB.Data[sourceID].loot = {}
					end
					LootTrackerDB.Data[sourceID].loot[ID] = (LootTrackerDB.Data[sourceID].loot[ID] or 0) + lootSourceInfo[i+1]
				end
			end
		end
	end
	-- TODO: add support for loot from fishing?
	-- TODO: add support for item-granted loot windows (bags)?
end
