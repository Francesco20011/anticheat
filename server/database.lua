--[[
    server/database.lua

    Provides persistence for bans and violation logs. In a
    production environment this module would interface with a
    relational database such as MySQL or MariaDB. To keep this
    example self contained and easy to deploy, bans are stored in a
    JSON file within the resource. The file will be created
    automatically on first use.
]]

ACDB = ACDB or {}
---@diagnostic disable: undefined-global

local bans = {}
local usedBanIds = {}
local dataPath = 'data/bans.json'

-- Table of recorded violations. Each entry is a table with keys
-- identifier, reason and timestamp. This allows the dashboard to
-- display a history of suspicious activity separate from the ban
-- list. Violations are persisted to a separate JSON file to avoid
-- mixing different kinds of data.
local violations = {}
local violationsPath = 'data/violations.json'

-- Table of current players. When a player connects or disconnects
-- the events module updates this table and writes it to disk so
-- external scripts (like the web dashboard) can see who is online.
local players = {}
local playersPath = 'data/players.json'

-- Load bans from the JSON file. If the file does not exist an empty
-- table is returned. Errors during decode are silently ignored.
local function loadBans()
    local raw = LoadResourceFile(GetCurrentResourceName(), dataPath)
    if raw then
        local ok, result = pcall(function()
            return json.decode(raw)
        end)
        if ok and type(result) == 'table' then
            bans = result
        else
            bans = {}
        end
    else
        bans = {}
    end
    -- Normalizza vecchi record (retro‑compatibilità) e costruisce indice banId
    local changed = false
    usedBanIds = {}
    for identifier, ban in pairs(bans) do
        if type(ban) == 'table' then
            if not ban.banId then
                -- genera ID univoco a 6 cifre
                local id
                repeat
                    id = tostring(math.random(100000, 999999))
                until not usedBanIds[id]
                ban.banId = id
                changed = true
            end
            usedBanIds[ban.banId] = true
            -- campi aggiuntivi opzionali
            ban.reason = ban.reason or 'Violazione'
            ban.bannedAt = ban.bannedAt or os.time()
            ban.permanent = (ban.expiresAt == nil)
        end
    end
    if changed then
        local ok2, raw2 = pcall(function() return json.encode(bans) end)
        if ok2 and raw2 then
            SaveResourceFile(GetCurrentResourceName(), dataPath, raw2, #raw2)
        end
    end
end

-- Load violations from disk into the violations table. If the file
-- does not exist or cannot be parsed an empty table is used.
local function loadViolations()
    local raw = LoadResourceFile(GetCurrentResourceName(), violationsPath)
    if raw then
        local ok, result = pcall(function()
            return json.decode(raw)
        end)
        if ok and type(result) == 'table' then
            violations = result
        else
            violations = {}
        end
    else
        violations = {}
    end
end

-- Save the violations table to disk. On error the function fails
-- silently; this should not interrupt gameplay.
local function saveViolations()
    local ok, raw = pcall(function()
        return json.encode(violations)
    end)
    if ok and raw then
        SaveResourceFile(GetCurrentResourceName(), violationsPath, raw, #raw)
    end
end

-- Load the current players table from disk. Used during resource
-- startup to populate the in-memory list when restarting the
-- resource mid-game. If the file does not exist an empty table is
-- returned.
local function loadPlayers()
    local raw = LoadResourceFile(GetCurrentResourceName(), playersPath)
    if raw then
        local ok, result = pcall(function()
            return json.decode(raw)
        end)
        if ok and type(result) == 'table' then
            players = result
        else
            players = {}
        end
    else
        players = {}
    end
end

-- Save the players table to disk. This is called whenever a player
-- connects or disconnects so that external tools (like the web
-- dashboard) can display who is currently online.
local function savePlayers()
    local ok, raw = pcall(function()
        return json.encode(players)
    end)
    if ok and raw then
        SaveResourceFile(GetCurrentResourceName(), playersPath, raw, #raw)
    end
end

-- Save bans to the JSON file. The file is stored relative to the
-- resource folder; passing -1 as the length writes the entire
-- buffer. Errors during encode or write are silently ignored.
local function saveBans()
    local ok, raw = pcall(function()
        return json.encode(bans)
    end)
    if ok and raw then
        -- Ensure the data directory exists before writing
        SaveResourceFile(GetCurrentResourceName(), dataPath, raw, #raw)
    end
end

-- Add or update a ban. Uses the player's unique identifier as key.
-- Aggiunge / aggiorna un ban. Param info opzionale:
-- info.name, info.bannedBy, info.durationSeconds (nil = permanente), info.evidence
local function generateUniqueBanId()
    local id
    repeat
        id = tostring(math.random(100000, 999999))
    until not usedBanIds[id]
    usedBanIds[id] = true
    return id
end
function ACDB.addBan(identifier, reason, info)
    info = info or {}
    local duration = tonumber(info.durationSeconds)
    local expiresAt = nil
    if duration and duration > 0 then
        expiresAt = os.time() + duration
    end
    local existing = bans[identifier]
    local banId = existing and existing.banId or generateUniqueBanId()
    bans[identifier] = {
        banId = banId,
        identifier = identifier,
        playerName = info.name or (existing and existing.playerName) or 'Sconosciuto',
        reason = reason or (existing and existing.reason) or 'Violazione',
        bannedAt = os.time(),
        bannedBy = info.bannedBy or 'Sistema',
        evidence = info.evidence, -- stringa / url / nil
        expiresAt = expiresAt, -- nil = permanente
        permanent = expiresAt == nil
    }
    saveBans()
    return banId
end

-- Remove a ban. Returns true if a ban existed and was removed.
function ACDB.removeBan(identifier)
    if bans[identifier] then
        bans[identifier] = nil
        saveBans()
        return true
    end
    return false
end

-- Check if an identifier is banned. Returns true/false and reason.
function ACDB.isBanned(identifier)
    local ban = bans[identifier]
    if not ban then return false, nil end
    -- Auto-expire temporary bans
    if ban.expiresAt and os.time() >= ban.expiresAt then
        bans[identifier] = nil
        saveBans()
        return false, nil
    end
    return true, ban.reason
end

-- Return the full ban list table. Useful for administrative tools.
function ACDB.getBans()
    return bans
end

-- Attempt to find a unique identifier for a player. Prioritises
-- license identifiers (FiveM, Steam) but falls back to other
-- identifiers if necessary.
function ACDB.getIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 7) == 'license' then
            return id
        end
    end
    -- fallback: return the first identifier
    return identifiers[1]
end

-- Record a violation. Adds a new entry to the violations table and
-- persists the file. Each record contains the player's identifier,
-- the reason (human readable) and the timestamp. This function is
-- called by the ban manager when a violation is reported, even if
-- the player is banned immediately.
function ACDB.addViolation(identifier, reason)
    table.insert(violations, {
        identifier = identifier,
        reason = reason,
        time = os.time()
    })
    saveViolations()
end

-- Return all recorded violations. Returns a table where each entry
-- represents a single violation record. Useful for the web
-- dashboard. The returned table should not be mutated directly.
function ACDB.getViolations()
    return violations
end

-- Update the in-memory players table and persist it to disk. The
-- argument should be a table mapping source IDs to player info
-- tables. This function is called by the events module when
-- players connect or disconnect.
function ACDB.updatePlayers(list)
    players = list or {}
    savePlayers()
end

-- Return the current in‑memory players table. Keys are source IDs
-- (strings) and values are objects with at least name, identifier
-- and joinedAt fields. Useful for the web dashboard API.
function ACDB.getPlayers()
    return players
end

-- Initialise persistence on resource start
Citizen.CreateThread(function()
    -- Small delay to ensure json library is ready
    Citizen.Wait(200)
    loadBans()
    loadViolations()
    loadPlayers()
    local function count(t) local c=0 for _ in pairs(t) do c=c+1 end return c end
    print(('[Anti-Cheat] Persistence loaded: %d ban(s), %d violation(s).'):format(count(bans), #violations))
    -- Periodic purge of expired bans every 5 minutes
    while true do
        local now = os.time()
        local changed = false
        for id, ban in pairs(bans) do
            if ban.expiresAt and now >= ban.expiresAt then
                bans[id] = nil
                changed = true
            end
        end
        if changed then
            saveBans()
            print('[Anti-Cheat] Expired bans purged automatically')
        end
        Citizen.Wait(300000) -- 5 minutes
    end
end)
