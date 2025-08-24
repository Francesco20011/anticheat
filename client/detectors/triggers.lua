--[[
    client/detectors/triggers.lua

    Stub for detecting unauthorized trigger usage. Attackers may
    attempt to fire server events that they normally shouldn't have
    access to. You can detect this by patching TriggerServerEvent
    and monitoring which events are invoked from the client. For now
    this stub does nothing.
]]

ACDetectors = ACDetectors or {}
ACDetectors.triggers = {}

function ACDetectors.triggers.check()
    -- TODO: implement trigger misuse detection
end