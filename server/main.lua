--[[
    server/main.lua

    Root entry point for the server side of the anti‑cheat. This
    module contains initialisation logic that runs when the resource
    starts and stops. It is intentionally minimal because most
    functionality resides in the dedicated modules loaded via
    fxmanifest.lua. When the resource stops we ensure that the
    current players list is persisted.
]]

-- Notify that the anti‑cheat has loaded. This helps during
-- development to confirm that server scripts are executing.
print('[Anti‑Cheat] Server scripts initialised.')

-- Ricostruisce la tabella ACPlayers se la risorsa viene riavviata mentre
-- ci sono giocatori già connessi (altrimenti la dashboard mostra 0).
local function RebuildOnlinePlayers()
    ACPlayers = ACPlayers or {}
    local changed = false
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and GetPlayerName(src) then
            if not ACPlayers[id] then
                local identifier = ACDB.getIdentifier(src)
                local isAdminPlayer = false
                for _, adm in ipairs(Config.AdminIdentifiers or {}) do
                    if adm == identifier then isAdminPlayer = true break end
                end
                if not isAdminPlayer and src ~= 0 and IsPlayerAceAllowed(src, 'anticheat.admin') then
                    isAdminPlayer = true
                end
                ACPlayers[id] = {
                    name = GetPlayerName(src),
                    identifier = identifier,
                    joinedAt = os.time(),
                    isAdmin = isAdminPlayer
                }
                TriggerClientEvent('anticheat:setAdmin', src, isAdminPlayer)
                changed = true
            end
        end
    end
    if changed then
        ACDB.updatePlayers(ACPlayers)
        print('[Anti‑Cheat] ACPlayers ricostruito dopo restart (giocatori attivi: '..tostring(#GetPlayers())..')')
    end
end

-- Esegue la ricostruzione con un piccolo delay per essere sicuri che tutte
-- le dipendenze siano caricate.
Citizen.CreateThread(function()
    Citizen.Wait(1500)
    if not next(ACPlayers or {}) then
        RebuildOnlinePlayers()
    end
end)

-- Ricostruzione immediata anche sull'evento di start della risorsa
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Delay minimo per assicurare caricamento DB helper
        Citizen.SetTimeout(500, function()
            if not next(ACPlayers or {}) then
                RebuildOnlinePlayers()
            end
        end)
    end
end)

-- Save the players list when the resource stops. This ensures
-- connected players are persisted across restarts (useful if the
-- resource is restarted while players are online). Without this
-- handler the players file would only be updated on connect and
-- disconnect events.
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if ACPlayers then
            ACDB.updatePlayers(ACPlayers)
        end
    end
end)