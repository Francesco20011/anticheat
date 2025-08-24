--[[
    server/commands.lua

    Provides a handful of administrative commands for managing the
    anti‑cheat. These commands are intentionally simple and rely on
    ACE permissions for access control. See
    https://docs.fivem.net/docs/scripting-reference/commands/add_ace/ for
    details on configuring permissions. All commands can also be run
    from the server console.
]]

-- Helper function to send a chat message to a player. If the source
-- is 0 (server console) the message is printed to the server log
-- instead.
local function sendMessage(src, msg)
    if src == 0 then
        print(msg)
    else
        TriggerClientEvent('chat:addMessage', src, {
            color = {255, 0, 0},
            args = {'Anti‑Cheat', msg}
        })
    end
end

-- Command: ac_unban <identifier>
-- Removes a ban entry by identifier. Only players with the
-- "anticheat.unban" ACE permission or the server console can run this.
RegisterCommand('ac_unban', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'anticheat.unban') then
        sendMessage(src, 'Du hast keine Berechtigung, diesen Befehl zu verwenden.')
        return
    end
    local identifier = args[1]
    if not identifier then
        sendMessage(src, 'Verwendung: /ac_unban <identifier>')
        return
    end
    if ACDB.removeBan(identifier) then
        sendMessage(src, ('Spieler %s wurde entbannt.'):format(identifier))
    else
        sendMessage(src, ('Es existiert kein Bann für %s.'):format(identifier))
    end
end, true)

-- Command: ac_bans
-- Lists all current bans. Only players with the "anticheat.view" ACE
-- permission or the server console can run this. Output is JSON
-- encoded for easy reading.
RegisterCommand('ac_bans', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'anticheat.view') then
        sendMessage(src, 'Du hast keine Berechtigung, diesen Befehl zu verwenden.')
        return
    end
    local bans = ACDB.getBans()
    local encoded = json.encode(bans)
    sendMessage(src, encoded)
end, true)

-- Command: ac_players
-- Lists all currently connected players from the perspective of the
-- anti‑cheat. Useful for debugging.
RegisterCommand('ac_players', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'anticheat.view') then
        sendMessage(src, 'Du hast keine Berechtigung, diesen Befehl zu verwenden.')
        return
    end
    local players = ACDB.getPlayers()
    local encoded = json.encode(players)
    sendMessage(src, encoded)
end, true)