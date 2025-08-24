--[[
    client/detectors/speedhack.lua

    Flags players who appear to be running faster than the configured
    maximum. Only checks speed when the player is on foot and not
    falling or parachuting to minimise false positives. The speed
    threshold can be modified in Config.MaxRunSpeed.
]]

ACDetectors = ACDetectors or {}
ACDetectors.speedhack = {}

function ACDetectors.speedhack.check()
    local ped = ACUtils.getPlayerPed()
    if not ped or ped == 0 then return end
    -- Only flag on-foot movement; ignore when in vehicles or freefall
    if IsPedInAnyVehicle(ped, false) then return end
    if IsPedFalling(ped) or IsPedInParachuteFreeFall(ped) then return end
    local speed = ACUtils.getPlayerSpeed(ped)
    if speed > Config.MaxRunSpeed then
        ACUtils.notifyServer('reportViolation', {
            type  = 'SPEEDHACK',
            speed = speed
        })
    end
end