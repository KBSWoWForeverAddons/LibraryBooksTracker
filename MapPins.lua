local _, ns = ...

local function ShouldShowBookPin(entry)
    local db = LibraryBooksTrackerDB
    if not db or not db.showMapPins then return false end
    if entry.status == "turned_in" and not db.showCompletedPins then
        return false
    end
    return true
end

local function ShouldShowSleepingBagPin(stepState)
    local db = LibraryBooksTrackerDB
    if not db or not db.showMapPins or not db.showSleepingBagPins then return false end
    if not ns.state or not ns.state.sleepingBag then return false end
    if (ns.state.sleepingBag.allCompleted or stepState.completed) and not db.showCompletedPins then
        return false
    end
    return true
end

-- Build list of pins for a given mapID
function ns.GetPinsForMap(mapID)
    local pins = {}
    local db = LibraryBooksTrackerDB
    if not db or not db.showMapPins then return pins end
    if not ns.state or not ns.state.booksById then return pins end

    -- Book pins
    for _, entry in pairs(ns.state.booksById) do
        local book = entry.book
        if book.mapID == mapID and ShouldShowBookPin(entry) then
            local tex = ns.TEXTURES.bookMissing
            if entry.status == "turned_in" then
                tex = ns.TEXTURES.bookTurnedIn
            elseif entry.status == "collected" then
                tex = ns.TEXTURES.bookCollected
            elseif book.category == "level60" then
                tex = ns.TEXTURES.book60
            end

            table.insert(pins, {
                kind = "book",
                x = book.x,
                y = book.y,
                texture = tex,
                size = 18,
                entry = entry,
                tipOverride = nil,
            })

            if book.extraPins then
                for _, ep in ipairs(book.extraPins) do
                    table.insert(pins, {
                        kind = "book",
                        x = ep.x,
                        y = ep.y,
                        texture = tex,
                        size = 14,
                        entry = entry,
                        tipOverride = ep.tip,
                    })
                end
            end
        end
    end

    -- Turn-in NPCs
    for _, npc in ipairs(ns.NPCS) do
        if npc.mapID == mapID and npc.faction == ns.FACTION then
            table.insert(pins, {
                kind = "npc",
                x = npc.x,
                y = npc.y,
                texture = ns.TEXTURES.npc,
                size = 20,
                npc = npc,
            })
        end
    end

    -- Cozy Sleeping Bag quest chain pins
    for _, stepState in ipairs(ns.state.sleepingBag.steps) do
        local def = stepState.def
        if def.mapID == mapID and ShouldShowSleepingBagPin(stepState) then
            table.insert(pins, {
                kind = "sleepingbag",
                x = def.x,
                y = def.y,
                texture = ns.TEXTURES.sleepingBag,
                size = 18,
                stepState = stepState,
                tipOverride = nil,
            })

            if def.extraPins then
                for _, ep in ipairs(def.extraPins) do
                    table.insert(pins, {
                        kind = "sleepingbag",
                        x = ep.x,
                        y = ep.y,
                        texture = ns.TEXTURES.sleepingBag,
                        size = 15,
                        stepState = stepState,
                        tipOverride = ep.tip,
                    })
                end
            end
        end
    end

    return pins
end

local function PopulatePinTooltip(pinData)
    GameTooltip:ClearLines()
    if pinData.kind == "book" then
        local entry = pinData.entry
        local book = entry.book
        local diff = entry.difficulty

        GameTooltip:AddLine(book.name, 1, 0.82, 0)
        if book.category == "level60" then
            GameTooltip:AddLine("Level 60 Library Book", 0.75, 0.55, 1.0)
        else
            GameTooltip:AddLine("Standard Library Book", 0.65, 0.85, 1.0)
        end

        if entry.status == "turned_in" then
            GameTooltip:AddLine("Status: Turned In", 0.3, 1.0, 0.3)
        elseif entry.status == "collected" then
            local where = entry.inBags and "In Bags (Ready to Turn In)" or "In Bank (Ready to Turn In)"
            GameTooltip:AddLine("Status: " .. where, 0.2, 0.9, 1.0)
        else
            GameTooltip:AddLine("Status: Missing", 1.0, 0.4, 0.4)
        end

        GameTooltip:AddLine(
            string.format("Recommended Level: %d-%d (%s%s|r)", book.minLevel, book.maxLevel, diff.hex, diff.label),
            0.9, 0.9, 0.9
        )
        if book.dangerNote then
            GameTooltip:AddLine("Note: " .. book.dangerNote, 0.8, 0.8, 0.8)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(pinData.tipOverride or book.tip, 1, 1, 1, true)
    elseif pinData.kind == "npc" then
        local npc = pinData.npc
        GameTooltip:AddLine(npc.name, 1, 0.82, 0)
        if npc.category == "standard" then
            local s = ns.state.standard
            GameTooltip:AddLine(string.format("Turned In: %d / %d  (In Bags/Bank: %d)", s.turnedIn, s.total, s.collected), 0.3, 1.0, 0.5)
            for _, t in ipairs(ns.state.tiers) do
                if t.completed then
                    GameTooltip:AddLine(string.format("Tier %d (%d books): Completed", t.tier, t.count), 0.4, 1.0, 0.4)
                elseif t.readyToTurnIn then
                    GameTooltip:AddLine(string.format("Tier %d (%d books): Ready to Turn In!", t.tier, t.count), 0.2, 0.9, 1.0)
                else
                    GameTooltip:AddLine(string.format("Tier %d (%d books): Need %d more", t.tier, t.count, t.needAcquire), 1.0, 0.8, 0.2)
                end
            end
        else
            local l60 = ns.state.level60
            GameTooltip:AddLine(string.format("Level 60 Books Turned In: %d / %d  (In Bags/Bank: %d)", l60.turnedIn, l60.total, l60.collected), 0.75, 0.55, 1.0)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(npc.tip, 1, 1, 1, true)
    elseif pinData.kind == "sleepingbag" then
        local stepState = pinData.stepState
        local def = stepState.def
        GameTooltip:AddLine("Cozy Sleeping Bag - Step " .. def.step, 0.8, 0.5, 1.0)
        GameTooltip:AddLine(def.name, 1, 0.82, 0)
        GameTooltip:AddLine(stepState.completed and "Status: Completed" or "Status: Incomplete", stepState.completed and 0.3 or 1.0, stepState.completed and 1.0 or 0.5, 0.3)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(pinData.tipOverride or def.tip, 1, 1, 1, true)
    end
end

-- ============================================================================
-- WORLD MAP DATA PROVIDER (Pure Lua pin pool on WorldMapFrame:GetCanvas())
-- ============================================================================

local WorldMapProvider = CreateFromMixins(MapCanvasDataProviderMixin)
local activeWorldPins = {}
local worldPinPool = {}

local function AcquireWorldPin(canvas)
    local pin = table.remove(worldPinPool)
    if not pin then
        pin = CreateFrame("Button", nil, canvas)
        pin:SetFrameStrata("HIGH")
        pin:SetFrameLevel(2000)
        pin.tex = pin:CreateTexture(nil, "ARTWORK")
        pin.tex:SetAllPoints()

        pin:SetScript("OnEnter", function(self)
            if not self.pinData then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            PopulatePinTooltip(self.pinData)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    else
        pin:SetParent(canvas)
    end
    pin:Show()
    return pin
end

local function ReleaseAllWorldPins()
    for _, pin in ipairs(activeWorldPins) do
        pin:Hide()
        pin.pinData = nil
        table.insert(worldPinPool, pin)
    end
    wipe(activeWorldPins)
end

function WorldMapProvider:RemoveAllData()
    ReleaseAllWorldPins()
end

function WorldMapProvider:RefreshAllData()
    ReleaseAllWorldPins()
    local map = self:GetMap()
    if not map then return end
    local mapID = map:GetMapID()
    if not mapID then return end

    local canvas = map:GetCanvas()
    if not canvas then return end

    local width = canvas:GetWidth()
    local height = canvas:GetHeight()
    local scale = map:GetCanvasScale() or 1
    if scale <= 0 then scale = 1 end

    local pins = ns.GetPinsForMap(mapID)
    for _, pinData in ipairs(pins) do
        local pin = AcquireWorldPin(canvas)
        pin.pinData = pinData
        pin:SetSize(pinData.size, pinData.size)
        pin.tex:SetTexture(pinData.texture)
        pin:SetScale(1 / scale)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT", pinData.x * width * scale / scale, -pinData.y * height)
        table.insert(activeWorldPins, pin)
    end
end

function WorldMapProvider:OnCanvasScaleChanged()
    local map = self:GetMap()
    if not map then return end
    local scale = map:GetCanvasScale() or 1
    if scale <= 0 then scale = 1 end
    for _, pin in ipairs(activeWorldPins) do
        pin:SetScale(1 / scale)
    end
end

-- ============================================================================
-- MINIMAP PINS
-- ============================================================================

local MINIMAP_RADIUS_YARDS = {
    [0] = 233.33,
    [1] = 200.00,
    [2] = 166.67,
    [3] = 133.33,
    [4] = 100.00,
    [5] = 66.67,
}

local activeMinimapPins = {}
local minimapPinPool = {}
local minimapUpdater = CreateFrame("Frame")
local minimapTimer = 0

local function AcquireMinimapPin()
    local pin = table.remove(minimapPinPool)
    if not pin then
        pin = CreateFrame("Button", nil, Minimap)
        pin:SetFrameStrata("MEDIUM")
        pin:SetFrameLevel(8)
        pin.tex = pin:CreateTexture(nil, "ARTWORK")
        pin.tex:SetAllPoints()
        pin:SetScript("OnEnter", function(self)
            if not self.pinData then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            PopulatePinTooltip(self.pinData)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    pin:Show()
    return pin
end

local function ReleaseMinimapPins()
    for _, pin in ipairs(activeMinimapPins) do
        pin:Hide()
        pin.pinData = nil
        table.insert(minimapPinPool, pin)
    end
    wipe(activeMinimapPins)
end

local function UpdateMinimapPins()
    ReleaseMinimapPins()
    local db = LibraryBooksTrackerDB
    if not db or not db.showMapPins then return end
    if IsInInstance() then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    local playerPos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not playerPos then return end

    local okP, _, playerWorld = pcall(C_Map.GetWorldPosFromMapPos, mapID, playerPos)
    if not okP or not playerWorld then return end

    local pins = ns.GetPinsForMap(mapID)
    if #pins == 0 then return end

    local zoom = Minimap:GetZoom() or 0
    local radiusYards = MINIMAP_RADIUS_YARDS[zoom] or 133.33
    local minimapRadiusPx = (Minimap:GetWidth() or 140) * 0.48
    local rotate = GetCVarBool("rotateMinimap")
    local facing = rotate and (GetPlayerFacing() or 0) or 0
    local cosF, sinF = math.cos(facing), math.sin(facing)

    for _, pinData in ipairs(pins) do
        local okT, _, targetWorld = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(pinData.x, pinData.y))
        if okT and targetWorld then
            -- In WoW world coords: X is North-South (positive = North), Y is West-East (positive = West)
            local dy = targetWorld.x - playerWorld.x -- North (+) / South (-)
            local dx = playerWorld.y - targetWorld.y -- East (+) / West (-)

            if rotate then
                local rdx = dx * cosF - dy * sinF
                local rdy = dx * sinF + dy * cosF
                dx, dy = rdx, rdy
            end

            local px = (dx / radiusYards) * minimapRadiusPx
            local py = (dy / radiusYards) * minimapRadiusPx
            local dist = math.sqrt(px * px + py * py)

            if dist <= minimapRadiusPx then
                local pin = AcquireMinimapPin()
                pin.pinData = pinData
                pin:SetSize(14, 14)
                pin.tex:SetTexture(pinData.texture)
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", Minimap, "CENTER", px, py)
                table.insert(activeMinimapPins, pin)
            end
        end
    end
end

function ns.InitMapPins()
    minimapUpdater:SetScript("OnUpdate", function(_, elapsed)
        minimapTimer = minimapTimer + elapsed
        if minimapTimer >= 0.2 then
            minimapTimer = 0
            UpdateMinimapPins()
        end
    end)
    if WorldMapFrame and WorldMapFrame.AddDataProvider then
        WorldMapFrame:AddDataProvider(WorldMapProvider)
    end
    ns.RefreshMapPins()
end

function ns.RefreshMapPins()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        WorldMapProvider:RefreshAllData()
    end
    UpdateMinimapPins()
end
