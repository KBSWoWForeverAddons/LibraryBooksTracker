local _, ns = ...

local mainFrame
local activeTab = "recommended"
local rowPool = {}
local activeRows = {}
local tabButtons = {}
local tierCards = {}
local summaryText
local npcText
local scrollChild
local scrollFrame
local checkboxes = {}

local function CreateBackdrop(frame, bgAlpha)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.11, bgAlpha or 0.94)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.55, 0.9)
end

local function OpenMapToZone(mapID)
    if not mapID then return end
    if WorldMapFrame then
        if not WorldMapFrame:IsShown() then
            ShowUIPanel(WorldMapFrame)
        end
        WorldMapFrame:SetMapID(mapID)
    end
end

local function AcquireRow(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Button", nil, parent, "BackdropTemplate")
        row:SetHeight(38)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.14, 0.14, 0.18, 0.85)
        row:SetBackdropBorderColor(0.25, 0.25, 0.32, 0.8)

        row.badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.badge:SetPoint("LEFT", 8, 0)
        row.badge:SetWidth(68)
        row.badge:SetJustifyH("LEFT")

        row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.title:SetPoint("TOPLEFT", 80, -5)
        row.title:SetWidth(270)
        row.title:SetJustifyH("LEFT")

        row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.sub:SetPoint("BOTTOMLEFT", 80, 5)
        row.sub:SetWidth(350)
        row.sub:SetJustifyH("LEFT")

        row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.levelText:SetPoint("RIGHT", -68, 0)
        row.levelText:SetWidth(135)
        row.levelText:SetJustifyH("RIGHT")

        row.mapBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.mapBtn:SetSize(48, 22)
        row.mapBtn:SetPoint("RIGHT", -8, 0)
        row.mapBtn:SetText("Map")

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.20, 0.20, 0.28, 0.95)
            if not self.tooltipBuilder then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            self.tooltipBuilder(GameTooltip)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.14, 0.14, 0.18, 0.85)
            GameTooltip:Hide()
        end)
    else
        row:SetParent(parent)
    end
    row:Show()
    return row
end

local function ReleaseRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row.tooltipBuilder = nil
        row.mapBtn:SetScript("OnClick", nil)
        row:SetScript("OnClick", nil)
        table.insert(rowPool, row)
    end
    wipe(activeRows)
end

local function FormatBookRow(row, entry, showTierTag)
    local book = entry.book
    local diff = entry.difficulty

    -- Left status / tier badge
    if showTierTag and book.category == "level60" then
        row.badge:SetText("|cFFC080FF[Lv60]|r")
    elseif showTierTag and entry.tierMilestone then
        local tColors = { "|cFF40E659[Tier 1]|r", "|cFF33CCFF[Tier 2]|r", "|cFFFFD933[Tier 3]|r" }
        row.badge:SetText(tColors[entry.tierMilestone] or "|cFFAAAAAA[Extra]|r")
    elseif entry.status == "turned_in" then
        row.badge:SetText("|cFF40E659Turned In|r")
    elseif entry.status == "collected" then
        row.badge:SetText(entry.inBags and "|cFF33CCFFIn Bags|r" or "|cFF33CCFFIn Bank|r")
    else
        row.badge:SetText("|cFFFF6666Missing|r")
    end

    row.title:SetText(book.name)
    row.sub:SetText(string.format("%s (%s) - %.1f, %.1f", book.zone, book.continent, book.x * 100, book.y * 100))

    if entry.status == "turned_in" then
        row.levelText:SetText("|cFF66CC66Completed|r")
    else
        row.levelText:SetText(string.format("%sLvl %d-%d (%s)|r", diff.hex, book.minLevel, book.maxLevel, diff.label))
    end

    row.mapBtn:SetScript("OnClick", function()
        OpenMapToZone(book.mapID)
    end)
    row:SetScript("OnClick", function()
        OpenMapToZone(book.mapID)
    end)

    row.tooltipBuilder = function(tt)
        tt:AddLine(book.name, 1, 0.82, 0)
        tt:AddLine(string.format("%s (%s)  [%.1f, %.1f]", book.zone, book.continent, book.x * 100, book.y * 100), 0.7, 0.85, 1)
        tt:AddLine(string.format("Recommended Level: %d-%d  |  %s%s|r", book.minLevel, book.maxLevel, diff.hex, diff.label), 0.9, 0.9, 0.9)
        if book.dangerNote then
            tt:AddLine("Danger Note: " .. book.dangerNote, 0.8, 0.8, 0.8)
        end
        if entry.tierMilestone then
            tt:AddLine(string.format("Helps reach Tier %d (%d books)", entry.tierMilestone, ns.TIERS[entry.tierMilestone].count), 0.3, 0.9, 1.0)
        end
        tt:AddLine(" ")
        tt:AddLine(book.tip, 1, 1, 1, true)
        tt:AddLine(" ")
        tt:AddLine("|cFFAAAAAAClick to open World Map to this zone|r")
    end
end

local function FormatSleepingBagRow(row, stepState)
    local def = stepState.def
    row.badge:SetText(stepState.completed and "|cFF40E659Done|r" or "|cFFFFD933Step " .. def.step .. "|r")
    row.title:SetText(def.name)
    row.sub:SetText(string.format("%s - %.1f, %.1f", def.zone, def.x * 100, def.y * 100))
    row.levelText:SetText(stepState.completed and "|cFF66CC66Completed|r" or "|cFFFFAA33Incomplete|r")

    row.mapBtn:SetScript("OnClick", function()
        OpenMapToZone(def.mapID)
    end)
    row:SetScript("OnClick", function()
        OpenMapToZone(def.mapID)
    end)

    row.tooltipBuilder = function(tt)
        tt:AddLine("Cozy Sleeping Bag - Step " .. def.step, 0.8, 0.5, 1.0)
        tt:AddLine(def.name, 1, 0.82, 0)
        tt:AddLine(string.format("%s  [%.1f, %.1f]", def.zone, def.x * 100, def.y * 100), 0.7, 0.85, 1)
        tt:AddLine(" ")
        tt:AddLine(def.tip, 1, 1, 1, true)
        tt:AddLine(" ")
        tt:AddLine("|cFFAAAAAAClick to open World Map to this zone|r")
    end
end

function ns.RefreshTrackerUI()
    if not mainFrame or not mainFrame:IsShown() then return end

    local state = ns.state
    local s = state.standard
    local l60 = state.level60
    local db = LibraryBooksTrackerDB or {}

    summaryText:SetText(string.format(
        "Player Level: |cFFFFD933%d|r   |   Standard Turned In: |cFF40E659%d/%d|r   |   In Bags/Bank: |cFF33CCFF%d|r   |   Missing: |cFFFF6666%d|r",
        state.playerLevel, s.turnedIn, s.total, s.collected, s.missing
    ))

    local stdNpc = (ns.FACTION == "Alliance") and "Garion Wendell (Stormwind)" or "Owen Thadd (Undercity)"
    local l60Npc = (ns.FACTION == "Alliance") and "Jennea Cannon (Stormwind)" or "Oran Snakewrithe (Undercity)"
    npcText:SetText(string.format("Turn-In NPCs: |cFFFFFFFF%s|r  |  Lv60: |cFFFFFFFF%s|r", stdNpc, l60Npc))

    -- Update Tier Cards
    for i, t in ipairs(state.tiers) do
        local card = tierCards[i]
        if card then
            card.title:SetText(string.format("Tier %d (%d Books)", t.tier, t.count))
            if t.completed then
                card.status:SetText("|cFF40E659Completed|r")
                card:SetBackdropBorderColor(0.25, 0.8, 0.35, 0.9)
            elseif t.readyToTurnIn then
                card.status:SetText("|cFF33CCFFReady to Turn In!|r")
                card:SetBackdropBorderColor(0.2, 0.75, 0.95, 0.9)
            else
                card.status:SetText(string.format("|cFFFFD933Need %d more|r", t.needAcquire))
                card:SetBackdropBorderColor(0.55, 0.45, 0.2, 0.9)
            end
        end
    end

    -- 4th card: Level 60 Books
    if tierCards[4] then
        local card = tierCards[4]
        card.title:SetText("Level 60 Books")
        card.status:SetText(string.format("|cFFC080FF%d / %d Turned In|r", l60.turnedIn, l60.total))
        card:SetBackdropBorderColor(0.55, 0.35, 0.8, 0.9)
    end

    -- Update Tab Highlights
    if tabButtons.all then
        tabButtons.all:SetText(string.format("All Standard (%d)", s.total))
    end
    if tabButtons.level60 then
        tabButtons.level60:SetText(string.format("Level 60 (%d)", l60.total))
    end
    for id, btn in pairs(tabButtons) do
        if id == activeTab then
            btn:LockHighlight()
        else
            btn:UnlockHighlight()
        end
    end

    -- Sync Checkboxes
    if checkboxes.showMapPins then checkboxes.showMapPins:SetChecked(db.showMapPins) end
    if checkboxes.showSleepingBagPins then checkboxes.showSleepingBagPins:SetChecked(db.showSleepingBagPins) end
    if checkboxes.showCompletedPins then checkboxes.showCompletedPins:SetChecked(db.showCompletedPins) end
    if checkboxes.hideCompletedInList then checkboxes.hideCompletedInList:SetChecked(db.hideCompletedInList) end

    -- Populate Scroll List
    ReleaseRows()
    local items = {}

    if activeTab == "recommended" then
        local combined = {}
        for _, entry in ipairs(s.missingSorted) do
            table.insert(combined, entry)
        end
        for _, entry in ipairs(l60.missingSorted) do
            table.insert(combined, entry)
        end
        table.sort(combined, function(a, b)
            if a.difficulty.effectiveMin ~= b.difficulty.effectiveMin then
                return a.difficulty.effectiveMin < b.difficulty.effectiveMin
            end
            if a.difficulty.effectiveScore ~= b.difficulty.effectiveScore then
                return a.difficulty.effectiveScore < b.difficulty.effectiveScore
            end
            return a.book.name < b.book.name
        end)
        for _, entry in ipairs(combined) do
            table.insert(items, { kind = "book", entry = entry, showTier = true })
        end
    elseif activeTab == "all" then
        for _, entry in ipairs(s.list) do
            if not (db.hideCompletedInList and entry.status == "turned_in") then
                table.insert(items, { kind = "book", entry = entry, showTier = false })
            end
        end
        table.sort(items, function(a, b)
            local order = { collected = 1, missing = 2, turned_in = 3 }
            if order[a.entry.status] ~= order[b.entry.status] then
                return order[a.entry.status] < order[b.entry.status]
            end
            if a.entry.difficulty.effectiveMin ~= b.entry.difficulty.effectiveMin then
                return a.entry.difficulty.effectiveMin < b.entry.difficulty.effectiveMin
            end
            return a.entry.book.name < b.entry.book.name
        end)
    elseif activeTab == "level60" then
        for _, entry in ipairs(l60.list) do
            if not (db.hideCompletedInList and entry.status == "turned_in") then
                table.insert(items, { kind = "book", entry = entry, showTier = false })
            end
        end
        table.sort(items, function(a, b)
            local order = { collected = 1, missing = 2, turned_in = 3 }
            if order[a.entry.status] ~= order[b.entry.status] then
                return order[a.entry.status] < order[b.entry.status]
            end
            return a.entry.difficulty.effectiveScore < b.entry.difficulty.effectiveScore
        end)
    elseif activeTab == "sleepingbag" then
        for _, stepState in ipairs(state.sleepingBag.steps) do
            table.insert(items, { kind = "sleepingbag", stepState = stepState })
        end
    end

    local yOffset = 0
    for _, item in ipairs(items) do
        local row = AcquireRow(scrollChild)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", -4, 0)

        if item.kind == "book" then
            FormatBookRow(row, item.entry, item.showTier)
        else
            FormatSleepingBagRow(row, item.stepState)
        end

        table.insert(activeRows, row)
        yOffset = yOffset + 41
    end

    scrollChild:SetHeight(math.max(1, yOffset))
end

local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", "LibraryBooksTrackerFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(670, 540)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    CreateBackdrop(mainFrame, 0.95)
    table.insert(UISpecialFrames, "LibraryBooksTrackerFrame")

    -- Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -12)
    title:SetText("|cFFFF007FLibrary Books Tracker|r")

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    summaryText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    summaryText:SetPoint("TOPLEFT", 16, -34)

    npcText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    npcText:SetPoint("TOPLEFT", 16, -50)
    npcText:SetTextColor(0.75, 0.75, 0.85)

    -- Tier Cards (4 across)
    local cardWidth = 152
    for i = 1, 4 do
        local card = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
        card:SetSize(cardWidth, 44)
        card:SetPoint("TOPLEFT", 16 + (i - 1) * (cardWidth + 8), -68)
        CreateBackdrop(card, 0.75)

        card.title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        card.title:SetPoint("TOP", 0, -6)

        card.status = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        card.status:SetPoint("BOTTOM", 0, 7)

        tierCards[i] = card
    end

    -- Tabs
    local tabs = {
        { id = "recommended", label = "Recommended Next", width = 140 },
        { id = "all",         label = "All Standard (30)", width = 130 },
        { id = "level60",     label = "Level 60 (8)",      width = 105 },
        { id = "sleepingbag", label = "Sleeping Bag",      width = 110 },
    }
    local xPos = 16
    for _, t in ipairs(tabs) do
        local btn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
        btn:SetSize(t.width, 24)
        btn:SetPoint("TOPLEFT", xPos, -120)
        btn:SetText(t.label)
        btn:SetScript("OnClick", function()
            activeTab = t.id
            ns.RefreshTrackerUI()
        end)
        tabButtons[t.id] = btn
        xPos = xPos + t.width + 6
    end

    -- Scroll Frame
    local listBg = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    listBg:SetPoint("TOPLEFT", 16, -150)
    listBg:SetPoint("BOTTOMRIGHT", -16, 42)
    CreateBackdrop(listBg, 0.65)

    scrollFrame = CreateFrame("ScrollFrame", "LibraryBooksTrackerScrollFrame", listBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 6)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth() or 600, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Bottom Option Checkboxes
    local function MakeCheckbox(key, label, xOffset, onClick)
        local cb = CreateFrame("CheckButton", nil, mainFrame, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("BOTTOMLEFT", xOffset, 12)
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb.text:SetText(label)
        cb:SetScript("OnClick", function(self)
            if LibraryBooksTrackerDB then
                LibraryBooksTrackerDB[key] = self:GetChecked() and true or false
            end
            onClick()
        end)
        checkboxes[key] = cb
    end

    MakeCheckbox("showMapPins", "Map Pins", 16, function()
        ns.RefreshMapPins()
    end)
    MakeCheckbox("showSleepingBagPins", "Sleeping Bag Pins", 120, function()
        ns.RefreshMapPins()
    end)
    MakeCheckbox("showCompletedPins", "Completed Pins", 265, function()
        ns.RefreshMapPins()
    end)
    MakeCheckbox("hideCompletedInList", "Hide Turned-In in List", 405, function()
        ns.RefreshTrackerUI()
    end)

    mainFrame:Hide()
end

function ns.ToggleTrackerUI()
    if not mainFrame then
        CreateMainFrame()
    end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        ns.RefreshTracker()
        mainFrame:Show()
        ns.RefreshTrackerUI()
    end
end
