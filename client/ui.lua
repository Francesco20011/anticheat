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

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    SendNUIMessage({ type = 'hide' })
    SetNuiFocus(false, false)
end)

-- I comandi manuali /acshow e /achide sono stati rimossi: l'apertura avviene solo con il tasto F9.

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
RegisterKeyMapping('anticheat_toggleui', 'Apri la dashboard Anti‑Cheat', 'keyboard', 'F9')

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
    if uiData then
        cb(uiData)
    else
        pendingNuiCallbacks[#pendingNuiCallbacks + 1] = cb
        TriggerServerEvent('anticheat:requestDashboardData')
    end
end)

RegisterNetEvent('anticheat:receiveDashboardData')
AddEventHandler('anticheat:receiveDashboardData', function(data)
    uiData = data
    
    for _, callback in ipairs(pendingNuiCallbacks) do
        callback(data)
    end
    pendingNuiCallbacks = {}
    
    Citizen.SetTimeout(5000, function() cachedDashboardData = nil end)
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
