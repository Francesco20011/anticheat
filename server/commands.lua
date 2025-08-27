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

-- Tutti i comandi chat legacy (/ac_unban, /ac_bans, /ac_players) sono stati rimossi
-- su richiesta. La gestione avviene ora esclusivamente tramite la dashboard UI / eventi.
-- Manteniamo il file per futura estensione se necessario.