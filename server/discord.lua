--[[
    server/discord.lua

    Provides helper functions for sending notifications to Discord
    via webhooks. You can configure the webhook URL in Config.DiscordWebhook.
    All messages are sent as rich embeds to improve readability.
]]

ACDiscord = {}

-- Send a ban notification to the configured Discord webhook. If no
-- webhook is configured this function does nothing. Arguments:
--  - playerName: the display name of the banned player
--  - identifier: the unique identifier used for the ban
--  - reason: the human‑readable reason for the ban
function ACDiscord.sendBanNotification(playerName, identifier, reason)
    local url = Config.DiscordWebhook
    if not url or url == '' then return end
    local embed = {
        {
            -- Title translated to Italian
            title = 'Giocatore bannato',
            color = 15158332, -- red
            fields = {
                {name = 'Giocatore', value = playerName or 'Sconosciuto', inline = true},
                {name = 'Identificatore', value = identifier or 'Sconosciuto', inline = false},
                {name = 'Motivo', value = reason or 'Nessun motivo fornito', inline = false},
                {name = 'Data', value = os.date('%Y-%m-%d %H:%M:%S'), inline = false}
            }
        }
    }
    local payload = {
        username = 'Anti‑Cheat',
        embeds = embed
    }
    PerformHttpRequest(url, function(statusCode, responseText, headers)
        -- callback intentionally left empty
    end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end