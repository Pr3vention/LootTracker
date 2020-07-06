local name, addonTable = ...
LootTracker = addonTable
local LootTrackerDB = { }

-- general functions
local saveCreatureData = function(creatureID, name, hasLoot)
   local creature = rawget(LootTrackerDB.Data, creatureID) or {name=name}
   creature.total = (creature.total or 0) + 1
   creature.lootable = (creature.lootable or 0) + (hasLoot and 1 or 0)
   rawset(LootTrackerDB.Data, creatureID, creature)
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
		print(name .. ' (' .. creatureID .. ') lootable: ' .. tostring(hasLoot))
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
end