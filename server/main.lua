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