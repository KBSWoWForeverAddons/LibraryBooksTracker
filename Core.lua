local addOnName, ns = ...

local DEFAULTS = {
    minimapAngle = 220,
    showMapPins = true,
    showSleepingBagPins = true,
    showCompletedPins = false,
    hideCompletedInList = false,
    banked = {},
}

local function ApplyDefaults(db, defaults)
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            if type(db[k]) ~= "table" then
                db[k] = {}
            end
            ApplyDefaults(db[k], v)
        elseif db[k] == nil then
            db[k] = v
        end
    end
end

local function FullRefresh()
    ns.RefreshTracker()
    ns.RefreshMapPins()
    ns.RefreshTrackerUI()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("BANKFRAME_OPENED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addOnName then
        LibraryBooksTrackerDB = LibraryBooksTrackerDB or {}
        ApplyDefaults(LibraryBooksTrackerDB, DEFAULTS)
        ns.RefreshTracker()
        ns.InitMinimapButton()
        ns.InitMapPins()
    elseif event == "BANKFRAME_OPENED" then
        ns.ScanBank()
        FullRefresh()
    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "BAG_UPDATE_DELAYED"
        or event == "QUEST_TURNED_IN"
        or event == "PLAYER_LEVEL_UP" then
        FullRefresh()
    end
end)

SLASH_LIBRARYBOOKSTRACKER1 = "/lbt"
SLASH_LIBRARYBOOKSTRACKER2 = "/books"
SLASH_LIBRARYBOOKSTRACKER3 = "/lb"
SlashCmdList["LIBRARYBOOKSTRACKER"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s*(.-)%s*$", "%1")
    if msg == "reset" then
        if LibraryBooksTrackerDB then
            LibraryBooksTrackerDB.minimapAngle = 220
        end
        ns.InitMinimapButton()
        print("|cFFFF007FLibrary Books Tracker:|r Minimap button position reset.")
    else
        ns.ToggleTrackerUI()
    end
end
