RegisterNetEvent('anticheat:requestDashboardData')
AddEventHandler('anticheat:requestDashboardData', function()
    local src = source
    local playersData = {}
    
    for playerId, playerData in pairs(ACPlayers or {}) do
        local playerSrc = tonumber(playerId)
        if playerSrc and GetPlayerName(playerSrc) then
            local identifiers = GetPlayerIdentifiers(playerSrc)
            local license, steam, discord, ip = '', '', '', ''
            
            for _, id in ipairs(identifiers) do
                if string.match(id, 'license:') then
                    license = id
                elseif string.match(id, 'steam:') then
                    steam = id
                elseif string.match(id, 'discord:') then
                    discord = id
                elseif string.match(id, 'ip:') then
                    ip = string.gsub(id, 'ip:', '')
                end
            end
            
            local ped = GetPlayerPed(playerSrc)
            local coords = GetEntityCoords(ped)
            
            table.insert(playersData, {
                id = playerSrc,
                name = GetPlayerName(playerSrc),
                license = license,
                ping = GetPlayerPing(playerSrc),
                steam = steam,
                discord = discord,
                ip = ip,
                coords = {
                    x = math.floor(coords.x),
                    y = math.floor(coords.y),
                    z = math.floor(coords.z)
                },
                isAdmin = playerData.isAdmin or false
            })
        end
    end
    
    local violations = ACDB.getViolations() or {}
    local bans = ACDB.getBans() or {}
    
    local responseData = {
        playersOnline = #playersData,
        threatsBlocked = #violations,
        totalBans = #bans,
        aiActive = true,
        players = playersData,
        violations = violations,
        bans = bans,
        aiDetections = {}
    }
    
    TriggerClientEvent('anticheat:receiveDashboardData', src, responseData)
end)