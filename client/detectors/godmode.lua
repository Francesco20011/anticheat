--[[
    client/detectors/godmode.lua

    Detects if a player is using godmode by checking whether their
    health exceeds the maximum configured in Config.MaxHealth. When
    triggered a report is sent to the server specifying the detected
    health. False positives can occur if Config.MaxHealth is set
    lower than the maximum health granted by certain game effects.
]]

ACDetectors = ACDetectors or {}
ACDetectors.godmode = {}

function ACDetectors.godmode.check()
    local ped = ACUtils.getPlayerPed()
    if not ped or ped == 0 then return end
    local health = GetEntityHealth(ped)
    if health > Config.MaxHealth then
        ACUtils.notifyServer('reportViolation', {
            type   = 'GODMODE',
            health = health
        })
    end
end