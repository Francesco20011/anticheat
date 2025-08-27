-- server/admin_events.lua
-- Gestione eventi provenienti dalla UI NUI per ban / unban

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
    end
end)

RegisterNetEvent('anticheat:banOffline')
AddEventHandler('anticheat:banOffline', function(identifier, reason)
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
    ACDB.addBan(identifier, reason)
    print('[Anti‑Cheat] Ban offline aggiunto per '..identifier..' motivo: '..reason..' da '..(src==0 and 'console' or ('player '..src)))
end)
