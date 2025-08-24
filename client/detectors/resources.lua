--[[
    client/detectors/resources.lua

    Stub for detecting unauthorized client resource injections. A
    robust implementation would periodically check the list of loaded
    resources via GetNumResources() and compare against a whitelist.
]]

ACDetectors = ACDetectors or {}
ACDetectors.resources = {}

function ACDetectors.resources.check()
    -- TODO: implement resource injection detection
end