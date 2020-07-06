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
LootTracker.testframe = eventFrame

end
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame.events.VARIABLES_LOADED = function()
	-- TODO: cache some info here like character GUID, capture sessions, etc
end