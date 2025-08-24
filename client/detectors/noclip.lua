--[[
    client/detectors/noclip.lua

    Placeholder for noclip detection. Detecting noclip reliably can be
    complex and highly dependent on server rules. Typically you would
    compare the player's position over time and look for movements
    through walls or abnormally fast vertical movement. This stub
    registers the detector but performs no checks.
]]

ACDetectors = ACDetectors or {}
ACDetectors.noclip = {}

function ACDetectors.noclip.check()
    -- TODO: implement noclip detection
end