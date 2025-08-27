-- server/samples.lua
-- Gestione persistenza dei campioni storici (players / bans / peak / avg)
-- Salva su file JSON ciclicamente e carica all'avvio.

ACSAMPLES = ACSAMPLES or {}

local dataFile = 'data/samples.json'

local function loadSamples()
    local path = dataFile
    local f = io.open(path, 'r')
    if f then
        local content = f:read('*a')
        f:close()
        local ok, decoded = pcall(json.decode, content or '')
        if ok and type(decoded) == 'table' then
            ACSAMPLES = decoded
            return
        end
    end
    ACSAMPLES = {}
end

local function saveSamples()
    local path = dataFile
    local dir = 'data'
    os.execute('mkdir "'..dir..'" >NUL 2>&1') -- Windows compat, silently
    local f = io.open(path, 'w+')
    if f then
        f:write(json.encode(ACSAMPLES))
        f:close()
    end
end

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        loadSamples()
    end
end)

-- Salvataggio periodico
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- ogni minuto
        saveSamples()
    end
end)

function AC_AddSample(entry)
    ACSAMPLES[#ACSAMPLES+1] = entry
    -- Limita a 43200 campioni (~30 giorni a 1 campione/minuto)
    local limit = 43200
    if #ACSAMPLES > limit then
        local excess = #ACSAMPLES - limit
        for i=1, excess do table.remove(ACSAMPLES, 1) end
    end
end

function AC_GetSamples()
    return ACSAMPLES
end
