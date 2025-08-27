RegisterNetEvent('anticheat:requestDashboardData')
AddEventHandler('anticheat:requestDashboardData', function()
    local src = source
    local playersData = {}
    local totalPing = 0
    
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
            
            local pdata = {
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
            }
            totalPing = totalPing + (pdata.ping or 0)
            table.insert(playersData, pdata)
        end
    end
    
    local violations = ACDB.getViolations() or {}
    local bans = ACDB.getBans() or {}
    
    -- Calcolo picco/media semplificato (in memoria runtime)
    _AC_PEAK = math.max(_AC_PEAK or 0, #playersData)
    _AC_AVG_ACC = (_AC_AVG_ACC or 0) + #playersData
    _AC_AVG_COUNT = (_AC_AVG_COUNT or 0) + 1
    local avgPlayers = math.floor((_AC_AVG_ACC or 0) / (_AC_AVG_COUNT or 1))
    local avgPing = (#playersData > 0) and math.floor(totalPing / #playersData) or 0

    local expiry = Config.LicenseExpiry or ''
    local daysLeft = 0
    if expiry ~= '' then
        local y,m,d = expiry:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
        if y then
            local target = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=0})
            local diff = target - os.time()
            daysLeft = math.max(0, math.floor(diff / 86400))
        end
    end

    local responseData = {
        playersOnline = #playersData,
        threatsBlocked = #violations,
        totalBans = #bans,
        aiActive = true,
        players = playersData,
        violations = violations,
        bans = bans,
        aiDetections = {},
        peakPlayers = _AC_PEAK,
        averagePlayers = avgPlayers,
        averagePing = avgPing,
        license = {
            keyMasked = (Config.LicenseKey and Config.LicenseKey:gsub('%w', '•')) or '••••',
            expiry = expiry,
            daysLeft = daysLeft,
            status = daysLeft > 0 and 'Valida' or 'Scaduta'
        },
        server = {
            status = Config.ServerStatus or 'Online',
            name = (Config.ServerName and Config.ServerName ~= '') and Config.ServerName or GetConvar('sv_hostname', 'EmpireRP'),
            maxPlayers = tonumber(GetConvar('sv_maxclients', '0')) or 0,
            ip = GetConvar('endpoint_add_tcp', '0.0.0.0')
        }
    }
    
    TriggerClientEvent('anticheat:receiveDashboardData', src, responseData)
end)

-- Broadcast periodico (ogni 10s) ai client admin con UI aperta (lato client userà evento per aggiornare)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        local violations = ACDB.getViolations() or {}
        local bans = ACDB.getBans() or {}
        local players = ACDB.getPlayers() or {}
        local playersData = {}
        for playerId, playerData in pairs(ACPlayers or {}) do
            local playerSrc = tonumber(playerId)
            if playerSrc and GetPlayerName(playerSrc) then
                table.insert(playersData, {
                    id = playerSrc,
                    name = GetPlayerName(playerSrc),
                    license = playerData.identifier,
                    ping = GetPlayerPing(playerSrc),
                    isAdmin = playerData.isAdmin or false
                })
            end
        end
        _AC_PEAK = math.max(_AC_PEAK or 0, #playersData)
        _AC_AVG_ACC = (_AC_AVG_ACC or 0) + #playersData
        _AC_AVG_COUNT = (_AC_AVG_COUNT or 0) + 1
        local avgPlayers = math.floor((_AC_AVG_ACC or 0) / (_AC_AVG_COUNT or 1))
        local expiry = Config.LicenseExpiry or ''
        local daysLeft = 0
        if expiry ~= '' then
            local y,m,d = expiry:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
            if y then
                local target = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=0})
                daysLeft = math.max(0, math.floor((target - os.time()) / 86400))
            end
        end
        local payload = {
            type = 'show',
            data = {
                playersOnline = #playersData,
                threatsBlocked = #violations,
                totalBans = #bans,
                aiActive = true,
                players = playersData,
                violations = violations,
                bans = bans,
                aiDetections = {},
                peakPlayers = _AC_PEAK,
                averagePlayers = avgPlayers,
                license = {
                    keyMasked = (Config.LicenseKey and Config.LicenseKey:gsub('%w', '•')) or '••••',
                    expiry = expiry,
                    daysLeft = daysLeft,
                    status = daysLeft > 0 and 'Valida' or 'Scaduta'
                },
                server = {
                    status = Config.ServerStatus or 'Online',
                    name = (Config.ServerName and Config.ServerName ~= '') and Config.ServerName or GetConvar('sv_hostname', 'EmpireRP'),
                    maxPlayers = tonumber(GetConvar('sv_maxclients', '0')) or 0,
                    ip = GetConvar('endpoint_add_tcp', '0.0.0.0')
                }
            }
        }
        -- Invia solo a chi ha il permesso admin (per ridurre traffico)
        for playerId, info in pairs(ACPlayers or {}) do
            if info.isAdmin then
                TriggerClientEvent('anticheat:pushDashboardUpdate', tonumber(playerId), payload)
            end
        end
    end
end)