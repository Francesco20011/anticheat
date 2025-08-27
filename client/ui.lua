---@diagnostic disable: undefined-global
local uiOpen = false
local pendingNuiCallbacks = {}
local isAdmin = false
local cachedDashboardData = nil
local uiData = nil
local isSpectating = false
local spectateTarget = nil
local spectateLastCoords = nil
local spectateDisableHud = true
local isNuiFocused = false

-- Vehicle removal handler for unauthorized admin actions
RegisterNetEvent('anticheat:removeVehicle')
AddEventHandler('anticheat:removeVehicle', function(plate)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if DoesEntityExist(vehicle) then
        local vehiclePlate = GetVehicleNumberPlateText(vehicle)
        if vehiclePlate == plate then
            -- Save player's last position before removing the vehicle
            local lastCoords = GetEntityCoords(playerPed)
            
            -- Delete the vehicle
            ESX.Game.DeleteVehicle(vehicle)
            
            -- Teleport player to the ground to prevent falling through the map
            local groundFound, groundZ = GetGroundZFor_3dCoord(lastCoords.x, lastCoords.y, lastCoords.z + 10.0, true)
            if groundFound then
                SetEntityCoords(playerPed, lastCoords.x, lastCoords.y, groundZ, false, false, false, false)
            else
                SetEntityCoords(playerPed, lastCoords.x, lastCoords.y, lastCoords.z, false, false, false, false)
            end
            
            -- Notify the player
            ESX.ShowNotification('~r~Veicolo rimosso: accesso non autorizzato')
            
            -- Log the action
            print(('[ANTI-ABUSE] Removed unauthorized vehicle with plate: %s'):format(plate))
        end
    end
end)

-- Initialize UI in hidden state
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    -- Invia lo stato iniziale all'UI
    SendNUIMessage({ 
        type = 'SET_VISIBILITY',
        visible = false
    })
    SetNuiFocus(false, false)
    isNuiFocused = false
    uiOpen = false
end)

-- I comandi manuali /acshow e /achide sono stati rimossi: l'apertura avviene solo con il tasto F9.

-- Toggle UI with F9
RegisterCommand('anticheat_toggleui', function()
    if not isAdmin then 
        ESX.ShowNotification('~r~Accesso negato: non hai i permessi necessari')
        return 
    end
    
    uiOpen = not uiOpen
    
    if uiOpen then
        -- Mostra l'UI prima di richiedere i dati per evitare ritardi
        SendNUIMessage({
            type = 'SET_VISIBILITY',
            visible = true
        })
        
        -- Mostra il cursore e imposta il focus NUI
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        isNuiFocused = true
        uiOpen = true
        
        -- Disabilita i controlli del giocatore
        Citizen.CreateThread(function()
            while uiOpen do
                DisableControlAction(0, 24, true)  -- Disable attack
                DisableControlAction(0, 25, true)  -- Disable aim
                DisableControlAction(0, 1, true)   -- Disable pan
                DisableControlAction(0, 2, true)   -- Disable tilt
                DisableControlAction(0, 263, true) -- Disable melee
                DisableControlAction(0, 264, true) -- Disable melee
                DisableControlAction(0, 257, true) -- Disable melee
                Citizen.Wait(0)
            end
        end)
        
        -- Richiedi i dati al server dopo aver mostrato l'UI
        TriggerServerEvent('anticheat:requestDashboardData')
        
        -- Log action
        print('[ANTICHEAT] UI opened by admin')
    else
        -- Nascondi l'UI
        SendNUIMessage({ type = 'hide' })
        
        -- Ripristina i controlli del giocatore
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        isNuiFocused = false
        uiOpen = false
        
        -- Forza il rilascio di tutti i controlli
        Citizen.Wait(0)
        EnableAllControlActions(0)
        
        -- Add debug print
        print('^2[ANTICHEAT]^7 UI closed')
    end
end, false)
RegisterKeyMapping('anticheat_toggleui', 'Apri la dashboard Anti‑Cheat', 'keyboard', 'F9')

-- Handle ESC key to close UI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Close UI when ESC is pressed and UI is open
        if IsControlJustReleased(0, 322) and uiOpen then -- 322 is ESC key
            uiOpen = false
            isNuiFocused = false
            SetNuiFocus(false, false)
            SendNUIMessage({ type = 'hide' })
            EnableAllControlActions(0)
            print('^2[ANTICHEAT]^7 UI closed by ESC key')
            Citizen.Wait(200) -- Aumentato il delay per prevenire riaperture accidentali
        end
    end
end)

-- Close UI when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if uiOpen then
            SetNuiFocus(false, false)
            SendNUIMessage({ type = 'hide' })
        end
    end
end)

-- Handle close request from NUI
RegisterNUICallback('closeUI', function(data, cb)
    uiOpen = false
    isNuiFocused = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
    if cb then cb('ok') end
end)

-- Handle data requests from NUI
RegisterNUICallback('requestData', function(data, cb)
    -- If we have cached data and it's recent (less than 5 seconds old), use it
    if uiData and (GetGameTimer() - (uiData.timestamp or 0) < 5000) then
        cb(uiData)
    else
        -- Otherwise, request fresh data
        pendingNuiCallbacks[#pendingNuiCallbacks + 1] = cb
        TriggerServerEvent('anticheat:requestDashboardData')
    end
end)

-- Handle updated dashboard data from server
RegisterNetEvent('anticheat:updateDashboardData')
AddEventHandler('anticheat:updateDashboardData', function(data)
    -- Aggiungi timestamp e informazioni aggiuntive
    data.timestamp = GetGameTimer()
    
    -- Assicurati che i dati del server siano sempre disponibili
    if not data.serverInfo then data.serverInfo = {} end
    data.serverInfo.status = 'Online'
    data.serverInfo.ip = GetConvar('sv_hostname', '127.0.0.1')
    data.serverInfo.license = GetConvar('sv_licenseKey', 'N/A')
    
    -- Aggiorna i dati
    uiData = data
    
    -- Invia l'aggiornamento all'NUI se l'UI è aperta
    if uiOpen then
        SendNUIMessage({
            type = 'updateData',
            data = uiData
        })
    end
    
    -- Chiama le callback in attesa
    for _, cb in ipairs(pendingNuiCallbacks) do
        cb(uiData)
    end
    pendingNuiCallbacks = {}
    
    -- Log di debug
    print('[ANTICHEAT] Dati dashboard aggiornati')
end)

-- Aggiornamenti push periodici
RegisterNetEvent('anticheat:pushDashboardUpdate')
AddEventHandler('anticheat:pushDashboardUpdate', function(payload)
    if not uiOpen then return end
    if payload and payload.data then
        uiData = payload.data
        SendNUIMessage({ type = 'show', data = uiData })
    end
end)

-- Append singolo log dinamico
RegisterNetEvent('anticheat:logAppend')
AddEventHandler('anticheat:logAppend', function(log)
    if not uiOpen then return end
    if type(log) ~= 'table' then return end
    SendNUIMessage({ type = 'logAppend', log = log })
end)

RegisterNUICallback('close', function(data, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
    cb('ok')
end)

-- FiveM global API declarations for linter
---@diagnostic disable: undefined-global

-- Azioni dettagli giocatore
RegisterNUICallback('banPlayer', function(data, cb)
    if data and data.id then
    TriggerServerEvent('anticheat:adminBanPlayer', tonumber(data.id), data.reason or 'Ban manuale', data.duration or nil)
    end
    cb('ok')
end)
RegisterNUICallback('kickPlayer', function(data, cb)
    if data and data.id then
        TriggerServerEvent('anticheat:adminKickPlayer', tonumber(data.id), data.reason or 'Kick manuale')
    end
    cb('ok')
end)
RegisterNUICallback('screenshotPlayer', function(data, cb)
    if data and data.id then
        TriggerServerEvent('anticheat:adminScreenshotPlayer', tonumber(data.id))
    end
    cb('ok')
end)
RegisterNUICallback('spectatePlayer', function(data, cb)
    if not isAdmin then cb('noadmin'); return end
    if data and data.id then
        local targetId = tonumber(data.id)
        spectateDisableHud = data.disableHud and true or false
        startSpectate(targetId)
        cb('ok')
    else
        cb('invalid')
    end
end)
RegisterNUICallback('spectateStop', function(_, cb)
    stopSpectate()
    cb('ok')
end)

-- Gestione ban sezione "bans"
RegisterNUICallback('unbanAll', function(_, cb)
    TriggerServerEvent('anticheat:unbanAll')
    cb('ok')
end)
RegisterNUICallback('unbanPlayer', function(data, cb)
    if data and data.identifier then
        TriggerServerEvent('anticheat:unbanPlayer', data.identifier)
    end
    cb('ok')
end)
RegisterNUICallback('banOffline', function(data, cb)
    if data and (data.identifier or data.player) and data.reason then
        local ident = data.identifier or data.player
        TriggerServerEvent('anticheat:banOffline', ident, data.reason, data.duration or nil, data.evidence or nil)
    end
    cb('ok')
end)

-- Aggiornamento configurazione avanzata dalla dashboard
RegisterNUICallback('updateConfig', function(data, cb)
    -- data conterrà l'intero oggetto configData dal frontend
    if data then
        TriggerServerEvent('anticheat:updateConfig', data)
    end
    cb('ok')
end)

-- Admin management
RegisterNUICallback('addAdmin', function(data, cb)
    if data and data.identifier then
        TriggerServerEvent('anticheat:addAdmin', data.identifier, data.name or '', data.discord or '', data.perms or {})
    end
    cb('ok')
end)

-- Admin flag event
RegisterNetEvent('anticheat:setAdmin')
AddEventHandler('anticheat:setAdmin', function(flag)
    isAdmin = flag and true or false
end)

-- Spectate implementation
function startSpectate(serverId)
    if isSpectating then stopSpectate() end
    local playerPed = PlayerPedId()
    local playerServerId = GetPlayerServerId(PlayerId())
    if serverId == playerServerId then return end
    local targetPlayer = GetPlayerFromServerId(serverId)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)
    if targetPed == 0 then return end
    spectateLastCoords = GetEntityCoords(playerPed)
    NetworkSetInSpectatorMode(true, targetPed)
    SetEntityCollision(playerPed, false, false)
    SetEntityVisible(playerPed, false, false)
    if spectateDisableHud then DisplayRadar(false) end
    isSpectating = true
    spectateTarget = serverId
    -- Local log append for console UI
    SendNUIMessage({ type='logAppend', log = { time = os.date('!%Y-%m-%dT%H:%M:%SZ'), type='spectate_start', player=('Admin'), details=('Osserva '..tostring(serverId)), member=tostring(serverId) } })
    Citizen.CreateThread(function()
        while isSpectating do
            Citizen.Wait(1000)
            local tPlayer = GetPlayerFromServerId(spectateTarget or -1)
            if tPlayer == -1 then
                stopSpectate()
                break
            end
        end
    end)
end

function stopSpectate()
    if not isSpectating then return end
    local playerPed = PlayerPedId()
    NetworkSetInSpectatorMode(false, 0)
    SetEntityCollision(playerPed, true, true)
    SetEntityVisible(playerPed, true, false)
    DisplayRadar(true)
    if spectateLastCoords then
        SetEntityCoords(playerPed, spectateLastCoords.x or spectateLastCoords[1], spectateLastCoords.y or spectateLastCoords[2], spectateLastCoords.z or spectateLastCoords[3])
    end
    isSpectating = false
    spectateTarget = nil
    SendNUIMessage({ type='logAppend', log = { time = os.date('!%Y-%m-%dT%H:%M:%SZ'), type='spectate_stop', player='Admin', details='Fine osservazione', member='' } })
end

-- Allow ESC to stop spectate even if UI closed
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isSpectating and IsControlJustPressed(0, 322) then -- ESC
            stopSpectate()
        end
    end
end)
