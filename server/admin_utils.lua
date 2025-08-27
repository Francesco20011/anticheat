--[[
    admin_utils.lua
    
    Funzioni di utilità per gli amministratori del server.
    Gestisce i comandi e i permessi degli amministratori.
]]

-- Tabella per memorizzare i permessi degli amministratori
local adminCache = {}

--[[
    Verifica se un giocatore è un amministratore
    @param source number - L'ID sorgente del giocatore
    @return boolean - true se è un amministratore
]]
function IsAdmin(source)
    -- Controlla se il giocatore è nella cache
    if adminCache[source] ~= nil then
        return adminCache[source]
    end
    
    -- Controlla i permessi ACE
    local isAdmin = IsPlayerAceAllowed(source, 'anticheat.admin')
    adminCache[source] = isAdmin
    
    return isAdmin
end

--[[
    Aggiunge un amministratore
    @param source number - L'ID sorgente dell'amministratore che esegue il comando
    @param targetId number|string - L'ID o l'identificatore del giocatore da rendere amministratore
    @return boolean, string - Stato dell'operazione e messaggio
]]
function AddAdmin(source, targetId)
    -- Verifica i permessi
    if not IsAdmin(source) then
        return false, 'Permessi insufficienti.'
    end
    
    -- Ottieni l'identificatore del giocatore di destinazione
    local targetIdentifier = GetPlayerIdentifier(targetId, 0) -- steam:
    if not targetIdentifier then
        return false, 'Giocatore non trovato.'
    end
    
    -- Aggiungi il permesso ACE (esempio con esx)
    ExecuteCommand(('add_principal identifier.%s group.admin'):format(targetIdentifier))
    
    -- Aggiorna la cache
    local targetSource = tonumber(targetId)
    if targetSource and GetPlayerName(targetSource) then
        adminCache[targetSource] = true
    end
    
    return true, 'Amministratore aggiunto con successo.'
end

--[[
    Rimuove un amministratore
    @param source number - L'ID sorgente dell'amministratore che esegue il comando
    @param targetId number|string - L'ID o l'identificatore del giocatore da rimuovere dagli amministratori
    @return boolean, string - Stato dell'operazione e messaggio
]]
function RemoveAdmin(source, targetId)
    -- Verifica i permessi
    if not IsAdmin(source) then
        return false, 'Permessi insufficienti.'
    end
    
    -- Ottieni l'identificatore del giocatore di destinazione
    local targetIdentifier = GetPlayerIdentifier(targetId, 0) -- steam:
    if not targetIdentifier then
        return false, 'Giocatore non trovato.'
    end
    
    -- Rimuovi il permesso ACE (esempio con esx)
    ExecuteCommand(('remove_principal identifier.%s group.admin'):format(targetIdentifier))
    
    -- Aggiorna la cache
    local targetSource = tonumber(targetId)
    if targetSource and GetPlayerName(targetSource) then
        adminCache[targetSource] = false
    end
    
    return true, 'Amministratore rimosso con successo.'
end

--[[
    Registra un comando di amministrazione
    @param command string - Nome del comando (senza /)
    @param callback function - Funzione da eseguire quando il comando viene chiamato
    @param helpText string - Testo di aiuto per il comando
]]
function RegisterAdminCommand(command, callback, helpText)
    RegisterCommand(command, function(source, args, rawCommand)
        if not IsAdmin(source) then
            TriggerClientEvent('chat:addMessage', source, {
                color = {255, 0, 0},
                args = {'[ANTI-CHEAT]', 'Non hai i permessi per eseguire questo comando.'}
            })
            return
        end
        
        callback(source, args, rawCommand)
    end, false)
    
    -- Aggiungi il messaggio di aiuto
    if helpText then
        TriggerEvent('chat:addSuggestion', '/'..command, helpText)
    end
end

-- Gestisci la disconnessione dei giocatori per pulire la cache
AddEventHandler('playerDropped', function()
    local source = source
    if adminCache[source] then
        adminCache[source] = nil
    end
end)

-- Esporta le funzioni per l'uso in altri script
return {
    IsAdmin = IsAdmin,
    AddAdmin = AddAdmin,
    RemoveAdmin = RemoveAdmin,
    RegisterAdminCommand = RegisterAdminCommand
}