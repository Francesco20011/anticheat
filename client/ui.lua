local uiOpen = false
local pendingNuiCallbacks = {}
local isAdmin = false
local cachedDashboardData = nil
local uiData = nil

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

RegisterNUICallback('close', function(data, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
    cb('ok')
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    cb('ok')
end)
