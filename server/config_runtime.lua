-- Runtime configuration storage and persistence for the advanced dashboard config.
-- This stores a merged copy in memory and saves to JSON so changes survive restarts.

ACRuntimeConfig = ACRuntimeConfig or { version = 1, data = {} }
local CONFIG_SAVE_PATH = ('%s/config_runtime.json'):format(GetResourcePath(GetCurrentResourceName()))

local function save()
    local ok, encoded = pcall(json.encode, ACRuntimeConfig)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), 'config_runtime.json', encoded, -1)
    else
        print('[Anti-Cheat][Config] Failed to encode runtime config: '..tostring(encoded))
    end
end

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), 'config_runtime.json')
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' and decoded.data then
            ACRuntimeConfig = decoded
            print('[Anti-Cheat] Runtime config loaded.')
        end
    end
end

load()

-- Merge incoming (client) config object into runtime store
RegisterNetEvent('anticheat:updateConfig')
AddEventHandler('anticheat:updateConfig', function(data)
    local src = source
    -- Simple ACE permission check (optional)
    if src ~= 0 and not IsPlayerAceAllowed(src, 'anticheat.admin') then
        print('[Anti-Cheat][Config] Unauthorized update attempt from '..tostring(src))
        return
    end
    if type(data) ~= 'table' then return end
    ACRuntimeConfig.data = data
    ACRuntimeConfig.savedAt = os.time()
    save()
    -- Broadcast minimal notice to connected admins (future use)
    TriggerClientEvent('anticheat:logAppend', -1, { time = os.date('!%Y-%m-%dT%H:%M:%SZ'), type='config_update', player='System', details='Configurazione aggiornata', member='-' })
end)

-- Expose helper to other server modules
function ACGetConfig()
    return ACRuntimeConfig and ACRuntimeConfig.data or {}
end
