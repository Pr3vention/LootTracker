local name, addonTable = ...
LootTracker = addonTable

local data = {
	
}

--------------------
-- Event Handling --
--------------------
-- Events must be registered to a frame. Since we only want these to fire once, we'll create an invisible
-- dummy frame to intercept and handle collection events
local eventFrame = CreateFrame("FRAME", nil, UIParent)
eventFrame.events = {}
eventFrame:SetScript("OnEvent", function(self, event, ...) (eventFrame.events[event] or print)(...) end)
eventFrame:RegisterEvent("VARIABLES_LOADED")
LootTracker.testframe = eventFrame

eventFrame.events.TRANSMOG_COLLECTION_UPDATED = function(collectionIndex, modID, itemAppearanceID, reason)
	print('TRANSMOG_COLLECTION_UPDATED: ', collectionIndex, modID, itemAppearanceID, reason)
end
eventFrame.events.TRANSMOG_COLLECTION_SOURCE_ADDED = function(sourceID)
	print('TRANSMOG_COLLECTION_SOURCE_ADDED: ', sourceID)
end
eventFrame.events.VARIABLES_LOADED = function()
	print('if you see this message, the event was correctly registered!')
end