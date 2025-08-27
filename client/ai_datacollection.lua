-- client/ai_datacollection.lua
-- Raccolta dati basilare per moduli AI (stub). Invia eventi al server
-- che potrebbero essere usati per addestrare / valutare modelli.

local lastShot = 0
local shotInterval = 500 -- ms tra un invio e l'altro

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsPedShooting(PlayerPedId()) then
			local now = GetGameTimer()
			if now - lastShot > shotInterval then
				lastShot = now
				local weapon = GetSelectedPedWeapon(PlayerPedId())
				TriggerServerEvent('anticheat:weaponFired', weapon)
			end
		end
	end
end)

-- Esempio di raccolta posizione ogni 15 secondi (potrebbe servire per pattern sospetti)
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(15000)
		local ped = PlayerPedId()
		local coords = GetEntityCoords(ped)
		-- Si potrebbe inviare a un endpoint AI; qui solo debug locale
		-- print(('[AC AI] Sample posizione: %.2f %.2f %.2f'):format(coords.x, coords.y, coords.z))
	end
end)

