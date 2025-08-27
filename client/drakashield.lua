-- DrakaShield client-side script
-- Gestisce l'apertura e la chiusura della dashboard con F9 e la comunicazione NUI

local isOpen = false

-- Mostra i dati ricevuti dal server sul pannello NUI
RegisterNetEvent('anticheat:receiveDashboardData')
AddEventHandler('anticheat:receiveDashboardData', function(data)
    if not isOpen then return end
    SendNUIMessage({ type = 'show', data = data })
end)

-- Funzione per aprire/chiudere la dashboard
local function toggleDashboard()
    isOpen = not isOpen
    if isOpen then
        SetNuiFocus(true, true)
        -- Richiedi i dati al server
        TriggerServerEvent('anticheat:requestDashboardData')
    else
        SetNuiFocus(false, false)
        SendNUIMessage({ type = 'hide' })
    end
end

-- Comando e keybind per aprire la dashboard
RegisterCommand('drakashield', function()
    toggleDashboard()
end, false)
RegisterKeyMapping('drakashield', 'Apri/chiudi DrakaShield', 'keyboard', 'F9')

-- Callback NUI per revoca singolo ban
RegisterNUICallback('unbanPlayer', function(data, cb)
    if data and data.license then
        TriggerServerEvent('anticheat:unbanPlayer', data.license)
    end
    cb(true)
end)

-- Callback NUI per revoca di tutti i ban
RegisterNUICallback('unbanAll', function(_, cb)
    TriggerServerEvent('anticheat:unbanAll')
    cb(true)
end)

-- Callback NUI per bannare un giocatore offline
RegisterNUICallback('banOffline', function(data, cb)
    if data and data.player then
        TriggerServerEvent('anticheat:banOffline', data.player, data.reason or 'Violazione')
    end
    cb(true)
end)

-- Callback NUI per aprire lo stream di un giocatore (multi-stream)
RegisterNUICallback('openPlayerStream', function(data, cb)
    if data and data.id then
        -- Puoi sostituire questo evento con la tua logica personalizzata per aprire lo stream
        TriggerEvent('anticheat:openStream', data.id, data.name)
    end
    cb(true)
end)

-- Callback NUI quando l'utente chiude la dashboard
RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hide' })
    cb(true)
end)