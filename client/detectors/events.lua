--[[
    client/detectors/events.lua

    Stub for detecting misuse of game events. This could include
    players intercepting or emitting game events that should only
    originate from the server. A real implementation would hook
    into AddEventHandler on the client to monitor and validate.
]]

ACDetectors = ACDetectors or {}
ACDetectors.events = {}

function ACDetectors.events.check()
    -- TODO: implement game event misuse detection
end