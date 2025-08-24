--[[
    server/ai_detection.lua

    Placeholder for AI‑based cheat detection. In a real deployment
    this module could interface with an external service to analyse
    player behaviour and identify sophisticated cheats such as aim
    assistance. Because external services are beyond the scope of
    this example, the functions here simply log their invocation.
]]

ACAI = ACAI or {}

-- Track violation counts per identifier for simple ML‑style analysis.
local violationCounts = {}

-- Helper to find a player's source (server ID) by their identifier
-- using the ACPlayers table maintained in events.lua. Returns nil
-- if no match is found.
local function findSourceByIdentifier(id)
    if type(ACPlayers) ~= 'table' then return nil end
    for src, info in pairs(ACPlayers) do
        if info.identifier == id then
            return tonumber(src)
        end
    end
    return nil
end

-- Evaluate whether a player should be banned based on the number of
-- violations recorded against them. This simple heuristic is not
-- true machine learning, but it demonstrates where AI logic could
-- reside. If the threshold is exceeded the player is banned via
-- ACDB.addBan and dropped from the server. Admins are exempt.
local function evaluatePlayer(identifier)
    local count = violationCounts[identifier] or 0
    local threshold = 3 -- number of violations before AI bans
    if count >= threshold then
        -- Check admin status using Config and ACE
        for _, id in ipairs(Config.AdminIdentifiers or {}) do
            if id == identifier then
                return
            end
        end
        -- Find the player's source to drop them
        local src = findSourceByIdentifier(identifier)
        if src and IsPlayerAceAllowed(src, 'anticheat.admin') then
            return
        end
        -- Add an AI violation and ban
        local reason = 'AI detection: wiederholte Verstöße'
        ACDB.addViolation(identifier, reason)
        ACDB.addBan(identifier, reason)
        if src then
            DropPlayer(src, ('You have been banned: %s'):format(reason))
        end
        print(('[AC AI] Player %s banned due to repeated violations'):format(identifier))
        -- reset count after banning
        violationCounts[identifier] = 0
    end
end

-- Process data for a particular player. In a full implementation
-- you might feed combat logs, kill/death ratios or movement
-- patterns into an ML model. For now this function only prints
-- debug information.
function ACAI.processPlayerData(identifier, data)
    print(('[AC AI] Processing data for %s'):format(identifier))
    -- Example: if data flags suspicious activity, you could call
    -- ACDB.addViolation(identifier, 'AI detection: suspicious pattern')
end

-- Listen for new violations reported by the ban manager. Each time
-- this event fires we increment the violation count for the given
-- identifier. AI evaluation runs on a timer below.
RegisterNetEvent('anticheat:violationAdded')
AddEventHandler('anticheat:violationAdded', function(identifier)
    if not identifier then return end
    violationCounts[identifier] = (violationCounts[identifier] or 0) + 1
end)

-- Periodic task to run AI analysis on all connected players. You
-- could run this in a separate thread and schedule it at regular
-- intervals. Currently it iterates over the players list and
-- invokes processPlayerData with empty data.
Citizen.CreateThread(function()
    while true do
        -- Periodically evaluate all tracked players for AI bans.
        for identifier, _ in pairs(violationCounts) do
            evaluatePlayer(identifier)
        end
        -- Optionally call processPlayerData for custom analysis
        local players = ACDB.getPlayers()
        for _, info in pairs(players) do
            ACAI.processPlayerData(info.identifier, {})
        end
        Citizen.Wait(60000) -- run every minute
    end
end)