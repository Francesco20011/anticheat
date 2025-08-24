--[[
    server/ai_events.lua

    Stub for AI event hooks. When implementing advanced cheat
    detection you may choose to intercept game events (such as
    weapon fires or entity damage) and feed the data into an AI
    classifier. These functions illustrate where such logic could
    reside. They are not used by the core anti‑cheat.
]]

ACAIEvents = {}

-- Example of handling a weapon fired event. If you were collecting
-- data for an AI model you could store the weapon, the time of day
-- and other context in a database. Here we simply print a debug
-- message.
function ACAIEvents.onWeaponFired(src, weaponHash)
    local name = GetPlayerName(src) or 'unknown'
    print(('[AC AI] Player %s fired weapon %s'):format(name, weaponHash))
end

-- Registering a sample event from the client. In a real scenario
-- you might trigger this event from client detectors to inform the
-- server about user actions that the AI should observe.
RegisterNetEvent('anticheat:weaponFired')
AddEventHandler('anticheat:weaponFired', function(weaponHash)
    local src = source
    ACAIEvents.onWeaponFired(src, weaponHash)
end)