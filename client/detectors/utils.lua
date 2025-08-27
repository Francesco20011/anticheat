--[[
    utils.lua
    
    Funzioni di utilità condivise tra i vari detector.
    Fornisce funzioni comuni utilizzate da più moduli di rilevamento.
]]

-- Tabella per memorizzare i tempi degli ultimi avvisi
local lastWarnings = {}

--[[
    Mostra un avviso al giocatore
    @param message string - Il messaggio da mostrare
    @param duration number - Durata in millisecondi (default: 5000)
]]
function ShowWarning(message, duration)
    duration = duration or 5000
    -- Implementazione della visualizzazione dell'avviso
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('~r~[ANTI-CHEAT] ~w~' .. message)
    EndTextCommandThefeedPostTicker(false, true)
    
    -- Registra l'avviso nella console
    print(('[AC] Avviso: %s'):format(message))
end

--[[
    Verifica se un'arma è consentita
    @param weaponHash number - L'hash dell'arma da verificare
    @return boolean - true se l'arma è consentita, false altrimenti
]]
function IsWeaponAllowed(weaponHash)
    local weaponName = GetWeaponName(weaponHash)
    for _, allowedWeapon in ipairs(Config.AllowedWeapons or {}) do
        if weaponName == allowedWeapon then
            return true
        end
    end
    return false
end

--[[
    Registra una violazione per un giocatore
    @param violationType string - Il tipo di violazione (es: 'GODMODE', 'SPEEDHACK')
    @param details string - Dettagli aggiuntivi sulla violazione
]]
function RegisterViolation(violationType, details)
    local playerId = PlayerId()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Prepara i dati della violazione
    local violationData = {
        type = violationType,
        details = details,
        position = {x = coords.x, y = coords.y, z = coords.z},
        timestamp = os.time(),
        weapon = GetSelectedPedWeapon(ped)
    }
    
    -- Invia i dati al server
    TriggerServerEvent('anticheat:registerViolation', violationData)
    
    -- Log locale per debug
    print(('[AC] Violazione rilevata: %s - %s'):format(
        violationType, 
        details or 'Nessun dettaglio'
    ))
end

--[[
    Verifica se il giocatore è un amministratore
    @return boolean - true se il giocatore è un amministratore
]]
function IsPlayerAdmin()
    -- Controlla i permessi ACE
    return IsPlayerAceAllowed(PlayerId(), 'anticheat.admin')
end