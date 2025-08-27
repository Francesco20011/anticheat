-- FiveM runtime provides many globals not known to static analyzers.
---@diagnostic disable: undefined-global, param-type-mismatch
-- Helper to resolve server name dynamically (auto if Config.ServerName is blank)
local function AC_GetServerName()
    if Config.ServerName and Config.ServerName ~= '' then return Config.ServerName end
    return GetConvar('sv_hostname', 'EmpireRP')
end

-- Prova a determinare un IP/endpoint pubblico sensato. In molti ambienti endpoint_add_tcp può essere 0.0.0.0.
local function AC_GetServerIP()
    local ip = GetConvar('endpoint_add_tcp', '')
    if ip == '' or ip == '0.0.0.0' then
        -- Alcuni artefatti usano sv_endpoints (lista separata da ;) oppure sv_listingIP
        local endpoints = GetConvar('sv_endpoints', '')
        if endpoints ~= '' then
            ip = endpoints:match('([^;]+)') or endpoints
        end
    end
    if ip == '' or ip == '0.0.0.0' then
        ip = GetConvar('sv_listingIP', '')
    end
    if ip == '' or ip == '0.0.0.0' then
        -- Come fallback estremo mostriamo hostname
        ip = GetConvar('sv_hostname', 'N/D')
    end
    return ip ~= '' and ip or 'N/D'
end

RegisterNetEvent('anticheat:requestDashboardData')
AddEventHandler('anticheat:requestDashboardData', function()
    local src = source
    local playersData = {}
    local totalPing = 0
    local callerIdentifier = ACDB.getIdentifier(src)
    
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
            local rawHealth = ped and GetEntityHealth(ped) or 0
            local maxHealth = 200
            local healthPct = 0
            if rawHealth and rawHealth > 0 then
                healthPct = math.floor(math.min(100, (rawHealth / maxHealth) * 100))
            end
            
            local isProtected = false
            if Config.AdminIdentifiers then
                for _, adminId in ipairs(Config.AdminIdentifiers) do
                    if adminId == license then isProtected = true break end
                end
            end
            local pdata = {
                id = playerSrc,
                name = GetPlayerName(playerSrc),
                license = license,
                ping = GetPlayerPing(playerSrc),
                steam = steam,
                discord = discord,
                ip = isProtected and nil or ip,
                ipHidden = isProtected,
                health = healthPct,
                joinedAt = playerData.joinedAt or os.time(),
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
            ---@diagnostic disable-next-line: param-type-mismatch
            local target = os.time({year=assert(tonumber(y)), month=assert(tonumber(m)), day=assert(tonumber(d)), hour=0})
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
        name = AC_GetServerName(),
        maxPlayers = tonumber(GetConvar('sv_maxclients', '0')) or 0,
        ip = AC_GetServerIP()
    },
    samples = AC_GetSamples and AC_GetSamples() or {},
    admins = AC_GetAdmins and AC_GetAdmins() or {},
    you = {
        identifier = callerIdentifier,
        perms = (function()
            local a = AC_GetAdminByIdentifier and AC_GetAdminByIdentifier(callerIdentifier)
            return (a and a.perms) or (AC_GetAdmins and AC_GetAdmins()[callerIdentifier] and AC_GetAdmins()[callerIdentifier].perms) or {}
        end)()
    }
    }
    
    TriggerClientEvent('anticheat:receiveDashboardData', src, responseData)
end)

-- Broadcast periodico (ridotto a ~2s) ai client admin
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local violations = ACDB.getViolations() or {}
        local bans = ACDB.getBans() or {}
        local players = ACDB.getPlayers() or {}
        local playersData = {}
        for playerId, playerData in pairs(ACPlayers or {}) do
            local playerSrc = tonumber(playerId)
            if playerSrc and GetPlayerName(playerSrc) then
                local ped = GetPlayerPed(playerSrc)
                local rawHealth = ped and GetEntityHealth(ped) or 0
                local maxHealth = 200
                local healthPct = 0
                if rawHealth and rawHealth > 0 then
                    healthPct = math.floor(math.min(100, (rawHealth / maxHealth) * 100))
                end
                local license = playerData.identifier
                local isProtected = false
                if Config.AdminIdentifiers then
                    for _, adminId in ipairs(Config.AdminIdentifiers) do
                        if adminId == license then isProtected = true break end
                    end
                end
                table.insert(playersData, {
                    id = playerSrc,
                    name = GetPlayerName(playerSrc),
                    license = license,
                    ping = GetPlayerPing(playerSrc),
                    isAdmin = playerData.isAdmin or false,
                    health = healthPct,
                    joinedAt = playerData.joinedAt or os.time(),
                    ip = (not isProtected) and playerData.ip or nil,
                    ipHidden = isProtected
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
                ---@diagnostic disable-next-line: param-type-mismatch
                local target = os.time({year=assert(tonumber(y)), month=assert(tonumber(m)), day=assert(tonumber(d)), hour=0})
                daysLeft = math.max(0, math.floor((target - os.time()) / 86400))
            end
        end
        -- Campionamento (ogni 60s) per analisi storica semplice in memoria
    -- Usa persistenza centralizzata
    local currentSamples = AC_GetSamples and AC_GetSamples() or {}
        local now = os.time()
    if (not _AC_LAST_SAMPLE_TIME) or now - _AC_LAST_SAMPLE_TIME >= 60 then
            if AC_AddSample then
                AC_AddSample({
                    time = os.date('!%Y-%m-%dT%H:%M:%SZ', now),
                    players = #playersData,
                    bans = #bans,
                    peak = _AC_PEAK,
                    avg = avgPlayers
                })
            end
            _AC_LAST_SAMPLE_TIME = now
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
                    name = AC_GetServerName(),
                    maxPlayers = tonumber(GetConvar('sv_maxclients', '0')) or 0,
                    ip = AC_GetServerIP()
                },
                samples = AC_GetSamples and AC_GetSamples() or {},
                admins = AC_GetAdmins and AC_GetAdmins() or {}
                -- the `you` field will be populated per-admin in the send loop
            }
        }
        -- Invia solo a chi ha il permesso admin (per ridurre traffico)
        for playerId, info in pairs(ACPlayers or {}) do
            if info.isAdmin then
                local pid = tonumber(playerId)
                if pid then
                    -- Populate the `you` field for this admin: identifier and permissions
                    local identifier = ACDB.getIdentifier(pid)
                    local perms = {}
                    if AC_GetAdminByIdentifier then
                        local adminInfo = AC_GetAdminByIdentifier(identifier)
                        if adminInfo and adminInfo.perms then perms = adminInfo.perms end
                    end
                    payload.data.you = { identifier = identifier, perms = perms }
                    TriggerClientEvent('anticheat:pushDashboardUpdate', pid, payload)
                end
            end
        end
    end
end)

-- Funzione di utilità per costruire e inviare snapshot immediato
local function AC_PushInstantSnapshot(reason)
    local violations = ACDB.getViolations() or {}
    local bans = ACDB.getBans() or {}
    local playersData = {}
    for playerId, playerData in pairs(ACPlayers or {}) do
        local playerSrc = tonumber(playerId)
        if playerSrc and GetPlayerName(playerSrc) then
            local ped = GetPlayerPed(playerSrc)
            local rawHealth = ped and GetEntityHealth(ped) or 0
            local maxHealth = 200
            local healthPct = 0
            if rawHealth and rawHealth > 0 then
                healthPct = math.floor(math.min(100, (rawHealth / maxHealth) * 100))
            end
            local license = playerData.identifier
            local isProtected = false
            if Config.AdminIdentifiers then
                for _, adminId in ipairs(Config.AdminIdentifiers) do
                    if adminId == license then isProtected = true break end
                end
            end
            table.insert(playersData, {
                id = playerSrc,
                name = GetPlayerName(playerSrc),
                license = license,
                ping = GetPlayerPing(playerSrc),
                isAdmin = playerData.isAdmin or false,
                health = healthPct,
                joinedAt = playerData.joinedAt or os.time(),
                ip = (not isProtected) and playerData.ip or nil,
                ipHidden = isProtected
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
            ---@diagnostic disable-next-line: param-type-mismatch
            local target = os.time({year=assert(tonumber(y)), month=assert(tonumber(m)), day=assert(tonumber(d)), hour=0})
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
                name = AC_GetServerName(),
                maxPlayers = tonumber(GetConvar('sv_maxclients', '0')) or 0,
                ip = AC_GetServerIP()
            },
            samples = AC_GetSamples and AC_GetSamples() or {}
        }
    }
    for playerId, info in pairs(ACPlayers or {}) do
        if info.isAdmin then
            local pid = tonumber(playerId)
            if pid then
                -- Populate per-admin `you` field on the payload. This ensures each admin
                -- sees their own identifier and permission set.
                local identifier = ACDB.getIdentifier(pid)
                local perms = {}
                if AC_GetAdminByIdentifier then
                    local adminInfo = AC_GetAdminByIdentifier(identifier)
                    if adminInfo and adminInfo.perms then perms = adminInfo.perms end
                end
                payload.data.you = { identifier = identifier, perms = perms }
                TriggerClientEvent('anticheat:pushDashboardUpdate', pid, payload)
            end
        end
    end
end

-- Campionamento immediato su cambio numero giocatori (throttle 5s)
local function AC_TryInstantSample()
    local now = os.time()
    if (not _AC_LAST_INSTANT_SAMPLE) or (now - _AC_LAST_INSTANT_SAMPLE) >= 5 then
        _AC_LAST_INSTANT_SAMPLE = now
        if AC_AddSample then
            local bans = ACDB.getBans() or {}
            local count = 0
            for pid,_ in pairs(ACPlayers or {}) do
                local ps = tonumber(pid)
                if ps and GetPlayerName(ps) then count = count + 1 end
            end
            AC_AddSample({
                time = os.date('!%Y-%m-%dT%H:%M:%SZ', now),
                players = count,
                bans = (#bans),
                peak = math.max(_AC_PEAK or count, count),
                avg = math.floor(((_AC_AVG_ACC or count) + count) / math.max((_AC_AVG_COUNT or 0) + 1,1))
            })
        end
    end
end

-- Hook eventi join/leave per push immediato e sample
AddEventHandler('playerConnecting', function()
    -- Delay piccolo per assicurare che ACPlayers sia popolato
    Citizen.SetTimeout(500, function()
        AC_PushInstantSnapshot('join')
        AC_TryInstantSample()
    end)
end)

AddEventHandler('playerDropped', function()
    Citizen.SetTimeout(500, function()
        AC_PushInstantSnapshot('leave')
        AC_TryInstantSample()
    end)
end)