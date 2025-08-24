fx_version 'cerulean'
game 'gta5'

description 'Simple Anti‑Cheat for FiveM'

--
-- Shared configuration file. This file exposes values to both the
-- client and server runtime. Adjust the values in `config.lua` to
-- fine‑tune how the anti‑cheat operates.
--
shared_scripts {
    'config.lua'
}

--
-- Client scripts. The order here matters: utilities are loaded
-- first, then each detector registers itself into the global
-- `ACDetectors` table, and finally the main client loop iterates
-- over all registered detectors.
--
client_scripts {
    'client/utils.lua',
    'client/detectors/*.lua',
    'client/main.lua',
    'client/ui.lua'
}

--
-- Server scripts. These files implement the back‑end of the anti‑cheat:
-- storing bans, validating reports, dispatching notifications and
-- exposing administrative commands. They are executed in the order
-- listed below.
--
server_scripts {
    'server/database.lua',
    'server/banmanager.lua',
    'server/validation.lua',
    'server/discord.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/ai_detection.lua',
    'server/ai_events.lua',
    'server/ai_reporting.lua',
    'server/dashboard.lua',
    'server/main.lua'
}

-- NUI page used for the in‑game dashboard. When ui_page is set,
-- FiveM will serve this HTML file and its referenced assets to the
-- client. The HTML loads data via NUI callbacks defined in
-- client/ui.lua.
ui_page 'client/ui/index.html'

-- Files required by the NUI. Although our UI page is self
-- contained, we include it here so that FiveM knows to send it to
-- the client.
files {
    'client/ui/index.html'
}