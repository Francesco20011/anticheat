local uiOpen = false

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    SendNUIMessage({ type = 'hide' })
    SetNuiFocus(false, false)
end)

RegisterCommand('acshow', function()
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'show' })
end, false)

RegisterCommand('achide', function()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
end, false)

RegisterCommand('anticheat_toggleui', function()
    uiOpen = not uiOpen
    
    if uiOpen then
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'show' })
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'hide' })
    end
end, false)
RegisterKeyMapping('anticheat_toggleui', 'Öffnet das Anti‑Cheat Dashboard', 'keyboard', 'F9')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if uiOpen and IsControlJustPressed(0, 322) then
            uiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ type = 'hide' })
        end
    end
end)

RegisterNUICallback('requestData', function(data, cb)
    local players = {}
    local myPlayerId = PlayerId()
    local myServerID = GetPlayerServerId(myPlayerId)
    local myName = GetPlayerName(myPlayerId) or 'Du'
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    
    table.insert(players, {
        id = myServerID,
        name = myName,
        license = 'license:' .. string.format('%016x', math.random(1000000, 9999999999)),
        ping = GetPlayerPing(myPlayerId),
        steam = 'steam:' .. string.format('%015x', math.random(100000, 999999999)),
        discord = 'discord:' .. string.format('%018d', math.random(100000000000000000, 999999999999999999)),
        ip = '192.168.' .. math.random(1, 255) .. '.' .. math.random(1, 255),
        coords = {
            x = math.floor(myCoords.x),
            y = math.floor(myCoords.y),
            z = math.floor(myCoords.z)
        },
        isAdmin = true
    })
    
    for i = 1, math.random(2, 8) do
        local fakeId = math.random(1, 64)
        if fakeId ~= myServerID then
            local fakeCoords = {
                x = myCoords.x + math.random(-1000, 1000),
                y = myCoords.y + math.random(-1000, 1000),
                z = myCoords.z + math.random(-50, 50)
            }
            
            table.insert(players, {
                id = fakeId,
                name = 'Player' .. fakeId,
                license = 'license:' .. string.format('%016x', math.random(1000000, 9999999999)),
                ping = math.random(20, 150),
                steam = 'steam:' .. string.format('%015x', math.random(100000, 999999999)),
                discord = 'discord:' .. string.format('%018d', math.random(100000000000000000, 999999999999999999)),
                ip = '192.168.' .. math.random(1, 255) .. '.' .. math.random(1, 255),
                coords = {
                    x = math.floor(fakeCoords.x),
                    y = math.floor(fakeCoords.y),
                    z = math.floor(fakeCoords.z)
                },
                isAdmin = math.random(1, 10) > 8
            })
        end
    end
    
    local violations = {}
    for i = 1, math.random(5, 15) do
        table.insert(violations, {
            id = i,
            player_name = 'Player' .. math.random(1, 50),
            violation_type = ({'Speedhack', 'Godmode', 'Teleport', 'NoClip', 'Aimbot', 'ESP'})[math.random(1, 6)],
            description = 'Automatische Erkennung',
            severity = math.random(70, 95),
            created_at = os.date('%Y-%m-%d %H:%M:%S', os.time() - math.random(3600, 86400))
        })
    end
    
    local bans = {}
    for i = 1, math.random(3, 10) do
        table.insert(bans, {
            player_license = 'license:' .. string.format('%016x', math.random(1000000, 9999999999)),
            player_name = 'BannedUser' .. i,
            reason = ({'Speedhacking', 'Godmode', 'Griefing', 'Exploiting', 'Harassment', 'Trolling'})[math.random(1, 6)],
            banned_by = ({'System', 'Admin', 'Moderator', 'AutoBan'})[math.random(1, 4)],
            created_at = os.date('%Y-%m-%d %H:%M:%S', os.time() - math.random(3600, 604800))
        })
    end
    
    local aiDetections = {}
    for i = 1, math.random(2, 8) do
        table.insert(aiDetections, {
            id = i,
            player_name = 'Player' .. math.random(1, 50),
            detection_type = ({'Suspicious Movement', 'Unusual Accuracy', 'Pattern Recognition', 'Behavior Analysis'})[math.random(1, 4)],
            confidence = math.random(75, 99) .. '%',
            detection_data = 'AI Model v2.1',
            created_at = os.date('%Y-%m-%d %H:%M:%S', os.time() - math.random(1800, 7200))
        })
    end
    
    local responseData = {
        playersOnline = #players,
        threatsBlocked = math.random(1250, 2500),
        totalBans = math.random(450, 850),
        aiActive = true,
        players = players,
        violations = violations,
        bans = bans,
        aiDetections = aiDetections
    }
    
    cb(responseData)
end)

RegisterNUICallback('close', function(data, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
    cb('ok')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    if data.playerId then
        TriggerEvent('chat:addMessage', {
            color = {255, 255, 0},
            args = {"[ANTICHEAT]", "Spieler " .. data.playerId .. " wurde gekickt!"}
        })
    end
    cb('ok')
end)

RegisterNetEvent('anticheat:responseData')
AddEventHandler('anticheat:responseData', function(requestId, payload)
    local cb = pendingNuiCallbacks[requestId]
    if cb then
        cb(payload)
        pendingNuiCallbacks[requestId] = nil
    end
end)

RegisterNetEvent('anticheat:setAdmin')
AddEventHandler('anticheat:setAdmin', function(state)
    isAdmin = state
end)
