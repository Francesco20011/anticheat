--[[
    config.lua

    This file contains values used by the anti‑cheat on both the client
    and server. Adjust these values to customise detection thresholds
    and behaviour. All values are exposed globally via the `Config`
    table.
]]

Config = {}

-- Maximum allowed health for a player. If a player's health exceeds
-- this value the anti‑cheat will flag them for godmode.
Config.MaxHealth = 200

-- Maximum allowed running speed (in m/s). Anything higher will be
-- considered a speed hack when the player is on foot and not falling.
Config.MaxRunSpeed = 10.0

-- List of allowed weapons. Any weapon outside of this list will be
-- considered illegal and flagged. Use weapon names from
-- https://docs.fivem.net/docs/game-references/weapon-names/
Config.AllowedWeapons = {
    'WEAPON_UNARMED',
    'WEAPON_KNIFE',
    'WEAPON_NIGHTSTICK',
    'WEAPON_HAMMER',
    'WEAPON_BAT',
    'WEAPON_GOLFCLUB',
    'WEAPON_CROWBAR',
    'WEAPON_PISTOL',
    'WEAPON_COMBATPISTOL',
    'WEAPON_APPISTOL'
}

-- Reasons used when banning players. Localised to Italian.
-- Keys are matched against violation types sent from the client detectors.
Config.BanReasons = {
    GODMODE   = 'Godmode rilevato',
    SPEEDHACK = 'Speedhack rilevato',
    NOCLIP    = 'Noclip rilevato',
    AIMBOT    = 'Aimbot rilevato',
    WEAPON    = 'Arma illegale rilevata',
    RESOURCE  = 'Iniezione di risorsa non autorizzata',
    TRIGGER   = 'Trigger non autorizzato rilevato',
    EVENT     = 'Evento non autorizzato rilevato',
    VISUAL    = 'Modifica visiva rilevata',
    VEHICLE   = 'Modifica del veicolo rilevata'
}

-- Discord webhook used to send ban notifications. Leave empty if you
-- don't want to send messages to Discord. See server/discord.lua
-- for implementation details.
Config.DiscordWebhook = ''

-- Database connection details. In a production setup you would
-- configure these to point at your MySQL or MariaDB server. The
-- example implementation in server/database.lua falls back to a
-- simple JSON file store when a database driver is unavailable.
Config.Database = {
    host     = 'localhost',
    user     = 'fivem',
    password = 'password',
    database = 'anticheat'
}

-- List of identifiers (e.g. license strings) that should be treated
-- as administrators. Players with these identifiers will not be
-- banned by the anti‑cheat. Populate this list with the license
-- identifiers of your trusted staff members.
Config.AdminIdentifiers = {
    -- Example: 'license:1234567890abcdef'
}

-- Informazioni licenza (personalizza con i tuoi dati reali)
Config.LicenseKey = 'DRKS-XXXX-XXXX-XXXX'
-- Data di scadenza licenza (YYYY-MM-DD)
Config.LicenseExpiry = '2025-09-26'
-- Stato server mostrato in dashboard (puoi sovrascriverlo dinamicamente)
Config.ServerStatus = 'Online'
-- Nome server personalizzato. Lascia vuoto ("") per usare automaticamente sv_hostname.
Config.ServerName = ''