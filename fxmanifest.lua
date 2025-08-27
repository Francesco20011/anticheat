fx_version 'cerulean'
game 'gta5'

name 'DrakaShield Anti-Cheat'
description 'Pannello anti-cheat completo in italiano'
author 'ChatGPT'
version '1.0.0'

ui_page 'client/ui/index.html'

files {
  'client/ui/index.html',
  'client/ui/*.html',
  'client/ui/*.js',
  'client/ui/*.css'
}

shared_script 'config.lua'

client_scripts {
  'client/utils.lua',
  'client/main.lua',
  'client/ui.lua',
  'client/dashboard.lua',
  'client/drakashield.lua',
  'client/ai_datacollection.lua',
  'client/detectors/utils.lua',
  'client/detectors/godmode.lua',
  'client/detectors/speedhack.lua',
  'client/detectors/noclip.lua',
  'client/detectors/weapons.lua',
  'client/detectors/vehicles.lua',
  'client/detectors/visuals.lua',
  'client/detectors/resources.lua',
  'client/detectors/events.lua',
  'client/detectors/triggers.lua',
  'client/detectors/aimbot.lua'
}

server_scripts {
  'server/database.lua',
  'server/validation.lua',
  'server/events.lua',
  'server/banmanager.lua',
  'server/admins.lua',
  'server/samples.lua',
  'server/commands.lua',
  'server/discord.lua',
  'server/config_runtime.lua',
  'server/admin_utils.lua',
  'server/admin_events.lua',
  'server/dashboard.lua',
  'server/main.lua',
  'server/ai_events.lua',
  'server/ai_reporting.lua',
  'server/ai_detection.lua'
}

lua54 'yes'