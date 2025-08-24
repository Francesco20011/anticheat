--[[
    server/events.lua

    Handles server‑side events related to player connection
    management. This module intercepts player connections to check
    against the ban list and maintains a list of currently online
    players for use by the web dashboard. When a player connects or
    disconnects the players table is updated and persisted via
    ACDB.updatePlayers().
]]

-- Table tracking currently connected players. Keys are player
-- source IDs (numbers) and values are tables with name,
-- identifier and joinedAt timestamp.
ACPlayers = {}

-- When a player attempts to connect to the server this handler
-- checks whether they are banned. If the player is banned their
-- connection is refused with the ban reason. Otherwise the player
-- is added to the ACPlayers table and the current list is saved.
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    -- Identify the player via the database helper
    local identifier = ACDB.getIdentifier(src)
    local banned, reason = ACDB.isBanned(identifier)
    if banned then
        -- Deny connection with the ban reason
        deferrals.done(('Du bist gebannt: %s'):format(reason))
        CancelEvent()
        return
    end
    -- Add the player to the list of current players
    local isAdminPlayer = false
    -- Determine admin status using the same helper as the ban manager
    for _, id in ipairs(Config.AdminIdentifiers or {}) do
        if id == identifier then
            isAdminPlayer = true
            break
        end
    end
    if not isAdminPlayer then
        if src ~= 0 and IsPlayerAceAllowed(src, 'anticheat.admin') then
            isAdminPlayer = true
        end
    end
    ACPlayers[tostring(src)] = {
        name = playerName,
        identifier = identifier,
        joinedAt = os.time(),
        isAdmin = isAdminPlayer
    }
    -- Persist the current players list so external tools can see who is online
    ACDB.updatePlayers(ACPlayers)
    -- Inform the client of their admin status. The UI uses this to
    -- determine whether the in‑game dashboard may be opened.
    TriggerClientEvent('anticheat:setAdmin', src, isAdminPlayer)
    deferrals.done()
end)

-- When a player disconnects remove them from the ACPlayers table
-- and persist the updated list. The `reason` argument is unused
-- but included to match the event signature.
AddEventHandler('playerDropped', function(reason)
    local src = source
    ACPlayers[tostring(src)] = nil
    ACDB.updatePlayers(ACPlayers)
end)

-- Respond to NUI data requests from the client. The client sends a
-- request ID so we can match the response to the original callback.
RegisterNetEvent('anticheat:requestData')
AddEventHandler('anticheat:requestData', function(requestId)
    local src = source
    local bans = ACDB.getBans() or {}
    local players = ACDB.getPlayers() or {}
    local totalBans = 0
    for _ in pairs(bans) do totalBans = totalBans + 1 end
    local totalPlayers = 0
    for _ in pairs(players) do totalPlayers = totalPlayers + 1 end
    local payload = {
        totalBans = totalBans,
        totalPlayers = totalPlayers,
        bans = bans,
        players = players
    }
    TriggerClientEvent('anticheat:responseData', src, requestId, payload)
end)