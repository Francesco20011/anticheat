--[[
    server/banmanager.lua

    Receives violation reports from clients and takes action based on
    the type of violation. By default this module bans the player
    immediately on any report. To avoid false positives you can
    integrate further validation (see validation.lua) or accumulate
    strikes before banning.
]]

local violationCount = {}

-- Determine whether a player is an admin. Admins are exempt from
-- automatic bans but violations will still be recorded. A player is
-- considered an admin if their identifier appears in
-- Config.AdminIdentifiers or if they have the ACE permission
-- "anticheat.admin".
local function isAdmin(src, identifier)
    -- check explicit identifiers
    for _, id in ipairs(Config.AdminIdentifiers or {}) do
        if id == identifier then
            return true
        end
    end
    -- check ACE permission
    if src ~= 0 and IsPlayerAceAllowed(src, 'anticheat.admin') then
        return true
    end
    return false
end

-- Helper to disconnect a player with a message and optionally log
-- the ban. Triggers a Discord notification if a webhook is configured.
local function dropAndBan(src, identifier, reason)
    ACDB.addBan(identifier, reason)
    local name = GetPlayerName(src)
    if Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
        ACDiscord.sendBanNotification(name, identifier, reason)
    end
    -- Drop the player with an Italian message
    DropPlayer(src, ('Sei stato bannato: %s'):format(reason))
end

-- Handle reports from the client. `data` should contain at least
-- a `type` field corresponding to a key in Config.BanReasons. If
-- unknown types are received they are ignored.
RegisterNetEvent('anticheat:reportViolation')
AddEventHandler('anticheat:reportViolation', function(data)
    local src = source
    if type(data) ~= 'table' or not data.type then return end
    local reason = Config.BanReasons[data.type] or ('Violazione sconosciuta: ' .. tostring(data.type))
    local identifier = ACDB.getIdentifier(src)
    -- Increment violation count for this player
    violationCount[identifier] = (violationCount[identifier] or 0) + 1
    -- Record the violation for auditing. Even if the player is
    -- banned immediately, keeping track of violations helps with
    -- analytics and appeals.
    ACDB.addViolation(identifier, reason)
    -- Notify AI subsystem about the new violation for the player.
    TriggerEvent('anticheat:violationAdded', identifier)
    -- Skip banning admins; log and return
    if isAdmin(src, identifier) then
        print(('[AC] Admin violation ignored for %s (%s): %s'):format(GetPlayerName(src) or 'unknown', identifier, reason))
        return
    end
    -- For a more forgiving system you could wait until several
    -- violations have been recorded before banning. Here we ban
    -- immediately on the first violation.
    dropAndBan(src, identifier, reason)
end)