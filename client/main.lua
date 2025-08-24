--[[
    client/main.lua

    Entry point for the client side of the anti‑cheat. This script
    periodically iterates over all detectors registered in the global
    `ACDetectors` table and invokes their `check` function. Each
    detector is responsible for reporting suspicious activity to the
    server via the helper in ACUtils.
]]

-- Ensure the detectors table exists. Individual detector scripts
-- extend this table in their respective files.
ACDetectors = ACDetectors or {}

-- Main detection loop. Runs forever and catches errors from
-- individual detectors so that one faulty script does not disable
-- the entire anti‑cheat. The delay between iterations can be
-- increased or decreased depending on performance requirements.
Citizen.CreateThread(function()
    while true do
        for name, detector in pairs(ACDetectors) do
            if type(detector.check) == 'function' then
                local ok, err = pcall(detector.check)
                if not ok then
                    print(('[AC] Detector "%s" error: %s'):format(name, err))
                end
            end
        end
        Citizen.Wait(3000)
    end
end)