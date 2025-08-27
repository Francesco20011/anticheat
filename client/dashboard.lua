-- client/dashboard.lua
-- Funzioni di supporto per gestione e aggiornamento della dashboard Anti‑Cheat lato client.

local DASH = {}
local cacheTTL = 5000 -- ms
local lastFetch = 0
local cache = nil
local fetching = false
local pending = {}

-- Richiede dati al server (con semplice debounce e cache)
local function fetchFromServer()
	if fetching then return end
	fetching = true
	TriggerServerEvent('anticheat:requestDashboardData')
end

-- API pubblica: ottenere dati (callback style)
function DASH.getData(cb)
	if type(cb) ~= 'function' then return end
	local now = GetGameTimer()
	if cache and (now - lastFetch) < cacheTTL then
		cb(cache)
		return
	end
	pending[#pending+1] = cb
	fetchFromServer()
end

-- Forza refresh ignorando la cache
function DASH.refresh(cb)
	if type(cb) == 'function' then
		pending[#pending+1] = cb
	end
	cache = nil
	fetchFromServer()
end

-- Evento risposta server (riutilizza già quello usato da ui.lua / drakashield)
AddEventHandler('anticheat:receiveDashboardData', function(data)
	cache = data
	lastFetch = GetGameTimer()
	fetching = false
	if #pending > 0 then
		for _, cb in ipairs(pending) do
			pcall(cb, data)
		end
		pending = {}
	end
end)

-- Esempio: comando per stampare info rapide in console
RegisterCommand('acstats', function()
	DASH.getData(function(data)
		if not data then
			print('[AC] Nessun dato disponibile')
			return
		end
		print(('[AC] Online: %d | Bans: %d | Minacce bloccate: %d'):format(
			data.playersOnline or 0,
			data.totalBans or 0,
			data.threatsBlocked or 0
		))
	end)
end, false)

-- Esporta per altri script client
exports('GetAntiCheatStats', function(cb)
	DASH.getData(cb)
end)

-- Periodic prefetch (facoltativo) per mantenere cache calda
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10000)
		if not fetching then
			DASH.getData(function() end)
		end
	end
end)

