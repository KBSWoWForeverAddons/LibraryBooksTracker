local _, ns = ...

local button

local function UpdateButtonPosition()
    if not button then return end
    local angle = math.rad((LibraryBooksTrackerDB and LibraryBooksTrackerDB.minimapAngle) or 220)
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ns.InitMinimapButton()
    if button then
        UpdateButtonPosition()
        return
    end

    button = CreateFrame("Button", "LibraryBooksTrackerMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture(ns.TEXTURES.minimapIcon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER")

    button:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local angle = math.deg(math.atan2(cy - my, cx - mx))
            if LibraryBooksTrackerDB then
                LibraryBooksTrackerDB.minimapAngle = angle
            end
            UpdateButtonPosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ns.ToggleTrackerUI()
        elseif mouseButton == "RightButton" then
            ns.ToggleTrackerUI()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cFFFF007FLibrary Books Tracker|r")

        local s = ns.state.standard
        local l60 = ns.state.level60
        GameTooltip:AddDoubleLine("Standard Books:", string.format("%d / %d turned in (%d in bags)", s.turnedIn, s.total, s.collected), 0.9, 0.9, 0.9, 0.4, 1.0, 0.5)
        GameTooltip:AddDoubleLine("Level 60 Books:", string.format("%d / %d turned in (%d in bags)", l60.turnedIn, l60.total, l60.collected), 0.9, 0.9, 0.9, 0.75, 0.55, 1.0)

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Tier Rewards:", 1, 0.82, 0)
        for _, t in ipairs(ns.state.tiers) do
            local rightText, r, g, b
            if t.completed then
                rightText, r, g, b = "Completed", 0.3, 1.0, 0.3
            elseif t.readyToTurnIn then
                rightText, r, g, b = "Ready to Turn In!", 0.2, 0.9, 1.0
            else
                rightText = string.format("Need %d more", t.needAcquire)
                r, g, b = 1.0, 0.8, 0.2
            end
            GameTooltip:AddDoubleLine(string.format("  Tier %d (%d books)", t.tier, t.count), rightText, 0.85, 0.85, 0.85, r, g, b)
        end

        if #s.missingSorted > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format("Easiest Next (Lvl %d):", ns.state.playerLevel), 1, 0.82, 0)
            for i = 1, math.min(3, #s.missingSorted) do
                local e = s.missingSorted[i]
                GameTooltip:AddDoubleLine(
                    "  " .. e.book.name,
                    string.format("%s (%s%s|r)", e.book.zone, e.difficulty.hex, e.difficulty.label),
                    1, 1, 1, 0.85, 0.85, 0.85
                )
            end
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFAAAAAALeft-Click: Open/Close Tracker   Drag: Move Button|r")
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdateButtonPosition()
end
