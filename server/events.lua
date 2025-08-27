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
        -- Deny connection with the ban reason (translated to Italian)
        deferrals.done(('Sei stato bannato: %s'):format(reason))
        CancelEvent()
        return
    end
    -- Add the player to the list of current players
    local isAdminPlayer = false
    local adminEntry = AC_GetAdminByIdentifier and AC_GetAdminByIdentifier(identifier)
    if adminEntry then
        isAdminPlayer = true
    else
        for _, id in ipairs(Config.AdminIdentifiers or {}) do
            if id == identifier then isAdminPlayer = true break end
        end
        if (not isAdminPlayer) and src ~= 0 and IsPlayerAceAllowed(src, 'anticheat.admin') then
            isAdminPlayer = true
        end
    end
    ACPlayers[tostring(src)] = {
        name = playerName,
        identifier = identifier,
        joinedAt = os.time(),
    isAdmin = isAdminPlayer,
    perms = adminEntry and adminEntry.perms or (isAdminPlayer and {'all'} or nil),
        ip = (function()
            local addr = ''
            for _, id in ipairs(GetPlayerIdentifiers(src)) do
                if id:sub(1,3) == 'ip:' then
                    addr = id:gsub('ip:','')
                    break
                end
            end
            -- Se l'identifier è protetto (admin) non memorizziamo IP
            if isAdminPlayer then return nil end
            return addr ~= '' and addr or nil
        end)()
    }
    -- Persist the current players list so external tools can see who is online
    ACDB.updatePlayers(ACPlayers)
    -- Inform the client of their admin status. The UI uses this to
    -- determine whether the in‑game dashboard may be opened.
    TriggerClientEvent('anticheat:setAdmin', src, isAdminPlayer)
    deferrals.done()
    -- Broadcast log append: ingresso giocatore
    TriggerClientEvent('anticheat:logAppend', -1, {
        time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        type = 'player_join',
        player = playerName,
        details = 'Connessione',
        member = identifier
    })
end)

-- When a player disconnects remove them from the ACPlayers table
-- and persist the updated list. The `reason` argument is unused
-- but included to match the event signature.
AddEventHandler('playerDropped', function(reason)
    local src = source
    ACPlayers[tostring(src)] = nil
    ACDB.updatePlayers(ACPlayers)
    local name = GetPlayerName(src) or 'Sconosciuto'
    local identifier = ACDB.getIdentifier(src)
    TriggerClientEvent('anticheat:logAppend', -1, {
        time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        type = 'player_leave',
        player = name,
        details = reason or 'Disconnessione',
        member = identifier
    })
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