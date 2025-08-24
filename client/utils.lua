--[[
    client/utils.lua

    A collection of helper functions used by client detectors and
    main loop. The ACUtils table is global so that other scripts
    can access it without requiring modules (FiveM Lua does not
    support `require` by default).
]]

ACUtils = ACUtils or {}

-- Send a detection report to the server. The event name passed in
-- will be prefixed with `anticheat:` on the server side.
function ACUtils.notifyServer(eventName, data)
    TriggerServerEvent('anticheat:' .. eventName, data)
end

-- Calculate the current speed of a ped in metres per second. The
-- returned value is the magnitude of the velocity vector.
function ACUtils.getPlayerSpeed(ped)
    local vx, vy, vz = table.unpack(GetEntityVelocity(ped))
    return math.sqrt((vx * vx) + (vy * vy) + (vz * vz))
end

-- Returns the current player's ped. Provided as a helper to avoid
-- repeating calls to PlayerPedId() across detectors.
function ACUtils.getPlayerPed()
    return PlayerPedId()
end