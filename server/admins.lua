-- server/admins.lua
-- Gestione amministratori con permessi granulari
-- Persistenza semplice JSON in resource data folder
---@diagnostic disable: undefined-global

local ADMINS_FILE = 'data/admins.json'
AC_Admins = AC_Admins or {}

local function loadAdmins()
    local raw = LoadResourceFile(GetCurrentResourceName(), ADMINS_FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data)=='table' then AC_Admins = data return end
    end
    AC_Admins = {}
end

local function saveAdmins()
    SaveResourceFile(GetCurrentResourceName(), ADMINS_FILE, json.encode(AC_Admins, { indent = true }), -1)
end

loadAdmins()

local function normalizePerms(perms)
    if not perms or perms=='all' then return {'all'} end
    local out = {}
    local seen = {}
    for _,p in ipairs(perms) do
        if p=='all' then return {'all'} end
        if type(p)=='string' and p~='' and not seen[p] then
            seen[p]=true
            out[#out+1]=p
        end
    end
    return out
end

function AC_GetAdmins()
    return AC_Admins
end

function AC_GetAdminByIdentifier(identifier)
    return identifier and AC_Admins[identifier]
end

function AC_PlayerHasPerm(identifier, perm)
    local a = AC_GetAdminByIdentifier(identifier)
    if not a then return false end
    if not perm or perm=='' then return true end
    for _,p in ipairs(a.perms or {}) do
        if p=='all' or p==perm then return true end
    end
    return false
end

local function ensureAdmin(identifier, name, discord, perms)
    AC_Admins[identifier] = AC_Admins[identifier] or { addedAt = os.time() }
    local entry = AC_Admins[identifier]
    entry.name = name or entry.name or 'Sconosciuto'
    entry.discord = discord or entry.discord
    if perms then entry.perms = normalizePerms(perms) end
    if not entry.perms or #entry.perms==0 then entry.perms={'all'} end
    saveAdmins()
end

-- Esportazioni
exports('GetAdmins', AC_GetAdmins)
exports('PlayerHasPerm', AC_PlayerHasPerm)

-- Eventi NUI
RegisterNetEvent('anticheat:addAdmin')
AddEventHandler('anticheat:addAdmin', function(identifier, name, discord, perms)
    local src = source
    local callerIdent = ACDB.getIdentifier(src)
    if not AC_PlayerHasPerm(callerIdent, 'manage_admins') and not AC_PlayerHasPerm(callerIdent, 'all') then return end
    if type(identifier)~='string' or identifier=='' then return end
    ensureAdmin(identifier, name, discord, perms)
    print(('[Anti‑Cheat] Admin aggiunto %s (%s) da %s'):format(name or identifier, identifier, callerIdent))
end)

RegisterNetEvent('anticheat:updateAdminPerms')
AddEventHandler('anticheat:updateAdminPerms', function(identifier, perms)
    local src = source
    local callerIdent = ACDB.getIdentifier(src)
    if not AC_PlayerHasPerm(callerIdent, 'manage_admins') and not AC_PlayerHasPerm(callerIdent, 'all') then return end
    local a = AC_Admins[identifier]
    if not a then return end
    a.perms = normalizePerms(perms)
    saveAdmins()
    print(('[Anti‑Cheat] Permessi admin aggiornati %s da %s'):format(identifier, callerIdent))
end)

RegisterNetEvent('anticheat:removeAdmin')
AddEventHandler('anticheat:removeAdmin', function(identifier)
    local src = source
    local callerIdent = ACDB.getIdentifier(src)
    if not AC_PlayerHasPerm(callerIdent, 'manage_admins') and not AC_PlayerHasPerm(callerIdent, 'all') then return end
    if AC_Admins[identifier] then
        AC_Admins[identifier] = nil
        saveAdmins()
        print(('[Anti‑Cheat] Admin rimosso %s da %s'):format(identifier, callerIdent))
    end
end)
