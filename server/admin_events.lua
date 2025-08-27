-- server/admin_events.lua
-- Gestione eventi provenienti dalla UI NUI per ban / unban
---@diagnostic disable: undefined-global

RegisterNetEvent('anticheat:unbanAll')
AddEventHandler('anticheat:unbanAll', function()
    local src = source
    -- Controllo permesso base: deve essere admin registrato oppure avere ACE
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.unban') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    local bans = ACDB.getBans() or {}
    for identifier, _ in pairs(bans) do
        ACDB.removeBan(identifier)
    end
    print('[Anti‑Cheat] Tutti i ban sono stati revocati da '..(src==0 and 'console' or ('player '..src)))
    -- Log append broadcast
    TriggerClientEvent('anticheat:logAppend', -1, {
        time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        type = 'unban',
        player = 'Tutti',
        details = 'Revoca di massa dei ban',
        member = (src==0 and 'console' or tostring(src))
    })
end)

RegisterNetEvent('anticheat:unbanPlayer')
AddEventHandler('anticheat:unbanPlayer', function(identifier)
    local src = source
    if type(identifier) ~= 'string' then return end
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.unban') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    if ACDB.removeBan(identifier) then
        print('[Anti‑Cheat] Ban revocato per '..identifier..' da '..(src==0 and 'console' or ('player '..src)))
        TriggerClientEvent('anticheat:logAppend', -1, {
            time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            type = 'unban',
            player = identifier,
            details = 'Ban revocato',
            member = (src==0 and 'console' or tostring(src))
        })
    end
end)

RegisterNetEvent('anticheat:banOffline')
AddEventHandler('anticheat:banOffline', function(identifier, reason, durationSeconds, evidence)
    local src = source
    if type(identifier) ~= 'string' then return end
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.ban') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    reason = (type(reason) == 'string' and reason ~= '' and reason) or 'Violazione'
    local banId = ACDB.addBan(identifier, reason, { bannedBy = (src==0 and 'console' or ('player '..src)), durationSeconds = durationSeconds, evidence = evidence })
    print('[Anti‑Cheat] Ban offline aggiunto #"'..banId..'" per '..identifier..' motivo: '..reason..' da '..(src==0 and 'console' or ('player '..src)))
    TriggerClientEvent('anticheat:logAppend', -1, {
        time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        type = 'ban',
        player = identifier,
        details = reason,
        member = (src==0 and 'console' or tostring(src))
    })
end)

-- Kick online player
RegisterNetEvent('anticheat:adminKickPlayer')
AddEventHandler('anticheat:adminKickPlayer', function(targetId, reason)
    local src = source
    if type(targetId) ~= 'number' then return end
    reason = (type(reason)=='string' and reason~='' and reason) or 'Kick amministrativo'
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.kick') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    if GetPlayerName(targetId) then
        local identifier = ACDB.getIdentifier(targetId)
        DropPlayer(targetId, ('Sei stato espulso: %s'):format(reason))
        print(('[Anti‑Cheat] Kick player %s (%s) da %s motivo: %s'):format(GetPlayerName(targetId), identifier, (src==0 and 'console' or ('player '..src)), reason))
        TriggerClientEvent('anticheat:logAppend', -1, {
            time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            type = 'kick',
            player = GetPlayerName(targetId),
            details = reason,
            member = identifier
        })
    end
end)

-- Ban online player
RegisterNetEvent('anticheat:adminBanPlayer')
AddEventHandler('anticheat:adminBanPlayer', function(targetId, reason, durationSeconds)
    local src = source
    if type(targetId) ~= 'number' then return end
    reason = (type(reason)=='string' and reason~='' and reason) or 'Ban amministrativo'
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.ban') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    if GetPlayerName(targetId) then
        local identifier = ACDB.getIdentifier(targetId)
        local banId = ACDB.addBan(identifier, reason, { name = GetPlayerName(targetId), bannedBy = (src==0 and 'console' or ('player '..src)), durationSeconds = durationSeconds })
        DropPlayer(targetId, ('Sei stato bannato: %s'):format(reason))
        print(('[Anti‑Cheat] Ban player #%s %s (%s) da %s motivo: %s'):format(banId, GetPlayerName(targetId), identifier, (src==0 and 'console' or ('player '..src)), reason))
        TriggerClientEvent('anticheat:logAppend', -1, {
            time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            type = 'ban',
            player = GetPlayerName(targetId),
            details = reason .. ' (#'..banId..')',
            member = identifier
        })
    end
end)

-- Screenshot player (requires screenshot-basic if installed)
RegisterNetEvent('anticheat:adminScreenshotPlayer')
AddEventHandler('anticheat:adminScreenshotPlayer', function(targetId)
    local src = source
    if type(targetId) ~= 'number' then return end
    local isAllowed = false
    if src == 0 then
        isAllowed = true
    else
        if ACPlayers and ACPlayers[tostring(src)] and ACPlayers[tostring(src)].isAdmin then
            isAllowed = true
        elseif IsPlayerAceAllowed(src, 'anticheat.screenshot') then
            isAllowed = true
        end
    end
    if not isAllowed then return end
    if GetPlayerName(targetId) then
        local took = false
        if GetResourceState('screenshot-basic') == 'started' then
            exports['screenshot-basic']:requestClientScreenshot(targetId, { encoding = 'jpg', quality = 50 }, function(data)
                took = true
                print(('[Anti‑Cheat] Screenshot %s (%d bytes) richiesto da %s'):format(GetPlayerName(targetId), data and #data or 0, (src==0 and 'console' or ('player '..src))))
                -- Could be saved to disk or uploaded to discord here.
            end)
        end
        if not took then
            print(('[Anti‑Cheat] Screenshot fallback: risorsa screenshot-basic non disponibile (richiedente %s)'):format(src==0 and 'console' or ('player '..src)))
        end
        TriggerClientEvent('anticheat:logAppend', -1, {
            time = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            type = 'screenshot',
            player = GetPlayerName(targetId),
            details = 'Screenshot richiesto',
            member = ACDB.getIdentifier(targetId)
        })
    end
end)
