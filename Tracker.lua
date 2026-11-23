local _, ns = ...

local IsQuestFlaggedCompleted = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo

local function NormalizeName(str)
    if not str then return "" end
    local res = str:lower():gsub("[%p%c]", " "):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    return res
end

-- Precompute normalized matchers for each book
if ns.BOOKS then
    for _, book in ipairs(ns.BOOKS) do
        book._matchers = { NormalizeName(book.name) }
        if book.aliases then
            for _, alias in ipairs(book.aliases) do
                table.insert(book._matchers, NormalizeName(alias))
            end
        end
    end
end

function ns.GetCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Realm"
    return name .. "-" .. realm
end

local function ScanContainerRange(bagIDs)
    local found = {}
    for _, bag in ipairs(bagIDs) do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName = link:match("%[(.-)%]")
                if itemName then
                    local norm = NormalizeName(itemName)
                    for _, book in ipairs(ns.BOOKS) do
                        if not found[book.id] then
                            for _, matcher in ipairs(book._matchers) do
                                if norm == matcher or norm:find(matcher, 1, true) then
                                    found[book.id] = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

function ns.ScanBags()
    return ScanContainerRange({ 0, 1, 2, 3, 4 })
end

function ns.ScanBank()
    local bankBags = { -1 }
    for b = 5, 11 do
        table.insert(bankBags, b)
    end
    local found = ScanContainerRange(bankBags)
    if LibraryBooksTrackerDB then
        LibraryBooksTrackerDB.banked = LibraryBooksTrackerDB.banked or {}
        LibraryBooksTrackerDB.banked[ns.GetCharacterKey()] = found
    end
    return found
end

function ns.GetBookDifficulty(book, playerLevel)
    playerLevel = playerLevel or UnitLevel("player") or 1

    if book.enemyCity == ns.FACTION then
        return {
            rank = 4,
            label = "Enemy Capital",
            color = { 1.0, 0.25, 0.25 },
            hex = "|cFFFF4040",
            effectiveMin = 60,
            effectiveScore = book.dangerScore + 100,
        }
    end

    local diff = book.minLevel - playerLevel
    if diff <= 0 then
        return {
            rank = 1,
            label = "Safe",
            color = { 0.25, 0.90, 0.35 },
            hex = "|cFF40E659",
            effectiveMin = book.minLevel,
            effectiveScore = book.dangerScore,
        }
    elseif diff <= 3 then
        return {
            rank = 2,
            label = "Manageable",
            color = { 1.0, 0.85, 0.20 },
            hex = "|cFFFFD933",
            effectiveMin = book.minLevel,
            effectiveScore = book.dangerScore,
        }
    elseif diff <= 7 then
        return {
            rank = 3,
            label = "Risky",
            color = { 1.0, 0.50, 0.15 },
            hex = "|cFFFF8026",
            effectiveMin = book.minLevel,
            effectiveScore = book.dangerScore,
        }
    else
        return {
            rank = 4,
            label = "Dangerous",
            color = { 1.0, 0.25, 0.25 },
            hex = "|cFFFF4040",
            effectiveMin = book.minLevel,
            effectiveScore = book.dangerScore,
        }
    end
end

-- Cached snapshot refreshed by events
ns.state = {
    playerLevel = 1,
    booksById = {},
    standard = {
        total = 0,
        turnedIn = 0,
        collected = 0,
        missing = 0,
        list = {},
        missingSorted = {},
    },
    level60 = {
        total = 0,
        turnedIn = 0,
        collected = 0,
        missing = 0,
        list = {},
        missingSorted = {},
    },
    tiers = {},
    sleepingBag = {
        completedSteps = 0,
        totalSteps = ns.SLEEPING_BAG_STEPS and #ns.SLEEPING_BAG_STEPS or 0,
        allCompleted = false,
        steps = {},
    },
}

function ns.RefreshTracker()
    local playerLevel = UnitLevel("player") or 1
    local inBags = ns.ScanBags()
    local inBank = (LibraryBooksTrackerDB and LibraryBooksTrackerDB.banked and LibraryBooksTrackerDB.banked[ns.GetCharacterKey()]) or {}

    local state = {
        playerLevel = playerLevel,
        booksById = {},
        standard = { total = 0, turnedIn = 0, collected = 0, missing = 0, list = {}, missingSorted = {} },
        level60 = { total = 0, turnedIn = 0, collected = 0, missing = 0, list = {}, missingSorted = {} },
        tiers = {},
        sleepingBag = { completedSteps = 0, totalSteps = #ns.SLEEPING_BAG_STEPS, allCompleted = false, steps = {} },
    }

    for _, book in ipairs(ns.BOOKS) do
        if not book.faction or book.faction == ns.FACTION then
        local isTurnedIn = IsQuestFlaggedCompleted(book.id) == true
        local isInBags = (not isTurnedIn) and (inBags[book.id] == true)
        local isInBank = (not isTurnedIn) and (not isInBags) and (inBank[book.id] == true)
        local status = isTurnedIn and "turned_in" or ((isInBags or isInBank) and "collected" or "missing")
        local diffInfo = ns.GetBookDifficulty(book, playerLevel)

        local entry = {
            book = book,
            status = status,
            inBags = isInBags,
            inBank = isInBank,
            difficulty = diffInfo,
            tierMilestone = nil, -- populated below for missing standard books
        }

        state.booksById[book.id] = entry
        local bucket = (book.category == "level60") and state.level60 or state.standard
        bucket.total = bucket.total + 1
        table.insert(bucket.list, entry)

        if status == "turned_in" then
            bucket.turnedIn = bucket.turnedIn + 1
        elseif status == "collected" then
            bucket.collected = bucket.collected + 1
        else
            bucket.missing = bucket.missing + 1
            table.insert(bucket.missingSorted, entry)
        end
        end
    end

    local function SortByDifficulty(a, b)
        if a.difficulty.effectiveMin ~= b.difficulty.effectiveMin then
            return a.difficulty.effectiveMin < b.difficulty.effectiveMin
        end
        if a.difficulty.effectiveScore ~= b.difficulty.effectiveScore then
            return a.difficulty.effectiveScore < b.difficulty.effectiveScore
        end
        return a.book.name < b.book.name
    end

    table.sort(state.standard.missingSorted, SortByDifficulty)
    table.sort(state.level60.missingSorted, SortByDifficulty)

    -- Compute Tier 1 (10), Tier 2 (20), Tier 3 (25) progress
    local turnedIn = state.standard.turnedIn
    local effective = turnedIn + state.standard.collected

    for _, tierDef in ipairs(ns.TIERS) do
        local questDone = IsQuestFlaggedCompleted(tierDef.questID) == true
        local completed = questDone or (turnedIn >= tierDef.count)
        local readyToTurnIn = (not completed) and (effective >= tierDef.count)
        local needTurnIn = math.max(0, tierDef.count - turnedIn)
        local needAcquire = math.max(0, tierDef.count - effective)

        table.insert(state.tiers, {
            tier = tierDef.tier,
            count = tierDef.count,
            name = tierDef.name,
            questID = tierDef.questID,
            completed = completed,
            readyToTurnIn = readyToTurnIn,
            needTurnIn = needTurnIn,
            needAcquire = needAcquire,
        })
    end

    -- Tag each missing standard book with the earliest tier milestone it helps reach
    local t1Need = state.tiers[1].needAcquire
    local t2Need = state.tiers[2].needAcquire
    local t3Need = state.tiers[3].needAcquire

    for idx, entry in ipairs(state.standard.missingSorted) do
        if idx <= t1Need then
            entry.tierMilestone = 1
        elseif idx <= t2Need then
            entry.tierMilestone = 2
        elseif idx <= t3Need then
            entry.tierMilestone = 3
        end
    end

    -- Cozy Sleeping Bag chain status
    local lastStepDone = IsQuestFlaggedCompleted(79976) == true
    for _, stepDef in ipairs(ns.SLEEPING_BAG_STEPS) do
        local done = lastStepDone or (IsQuestFlaggedCompleted(stepDef.questID) == true)
        if done then
            state.sleepingBag.completedSteps = state.sleepingBag.completedSteps + 1
        end
        table.insert(state.sleepingBag.steps, {
            def = stepDef,
            completed = done,
        })
    end
    state.sleepingBag.allCompleted = lastStepDone or (state.sleepingBag.completedSteps >= #ns.SLEEPING_BAG_STEPS)

    ns.state = state
    return state
end
