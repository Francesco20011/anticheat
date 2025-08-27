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

local bans = {}
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
function ACDB.addBan(identifier, reason)
    bans[identifier] = {
        reason = reason,
        bannedAt = os.time()
    }
    saveBans()
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
    if ban then
        return true, ban.reason
    end
    return false, nil
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
