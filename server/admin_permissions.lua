local ESX = exports["es_extended"]:getSharedObject()

-- List of restricted commands and their required permissions
local COMMAND_PERMISSIONS = {
    -- Item/Weapon/Vehicle Commands
    ['giveitem'] = 'give_item',
    ['giveweapon'] = 'give_weapon',
    ['giveweaponcomponent'] = 'give_weapon',
    ['giveammo'] = 'give_weapon',
    ['giveweaponammo'] = 'give_weapon',
    ['giveammotocoords'] = 'give_weapon',
    ['giveweaponcomponenttoall'] = 'give_weapon',
    
    -- Vehicle Commands
    ['givecar'] = 'give_vehicle',
    ['givevehicle'] = 'give_vehicle',
    ['spawncar'] = 'give_vehicle',
    ['car'] = 'give_vehicle',
    
    -- Money/Account Commands
    ['givemoney'] = 'give_money',
    ['givemoneyto'] = 'give_money',
    ['givemoneytoall'] = 'give_money',
    ['givemoneytoallplayers'] = 'give_money',
    ['givemoneytoallonline'] = 'give_money',
    ['givemoneytoallplayersonline'] = 'give_money',
    ['addmoney'] = 'give_money',
    
    -- Job/Group Commands
    ['setjob'] = 'set_job',
    ['setjob2'] = 'set_job2',
    ['setgroup'] = 'set_group',
    
    -- Account Management
    ['setmoney'] = 'set_money',
    ['setbank'] = 'set_bank',
    ['setbankmoney'] = 'set_bank',
    ['setaccountmoney'] = 'set_money',
    
    -- Admin Tools
    ['noclip'] = 'admin_noclip',
    ['godmode'] = 'admin_godmode',
    ['invisible'] = 'admin_invisible',
    
    -- Other Restricted Commands
    ['clearinventory'] = 'admin_clear_inv',
    ['clearweapons'] = 'admin_clear_weapons'
}

-- Check if player has permission
local function HasPermission(source, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    -- Check if player is admin
    local playerGroup = xPlayer.getGroup()
    if playerGroup == 'admin' or playerGroup == 'superadmin' then
        -- Log the admin action
        print(("[ANTI-ABUSE] %s (ID: %s) used command: %s"):format(
            GetPlayerName(source), source, permission
        ))
        return true
    end
    return false
end

-- Intercept admin commands
for command, _ in pairs(COMMAND_PERMISSIONS) do
    RegisterCommand(command, function(source, args, rawCommand)
        if source == 0 then return end -- Allow console commands
        
        local requiredPerm = COMMAND_PERMISSIONS[command]
        local hasPerm = HasPermission(source, requiredPerm)
        
        if not hasPerm then
            TriggerClientEvent('esx:showNotification', source, '~r~Non hai il permesso di utilizzare questo comando.')
            print(("[ANTI-ABUSE] BLOCKED: %s (ID: %s) tried to use command: %s"):format(
                GetPlayerName(source), source, command
            ))
            return
        end
    end, false)
end

-- Event to remove items/weapons/vehicles given by unauthorized admins
RegisterNetEvent('anticheat:checkAdminAction')
AddEventHandler('anticheat:checkAdminAction', function(actionType, targetId, item)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer or not tPlayer then return end
    
    -- Check if admin has permission for this action
    local hasPermission = HasPermission(source, actionType)
    
    if not hasPermission then
        -- Remove the item/weapon/vehicle that was given
        if actionType == 'give_item' then
            tPlayer.removeInventoryItem(item.name, item.count)
        elseif actionType == 'give_weapon' then
            tPlayer.removeWeapon(item.weapon)
        elseif actionType == 'give_vehicle' then
            TriggerClientEvent('anticheat:removeVehicle', targetId, item.plate)
        end
        
        -- Notify the admin
        TriggerClientEvent('esx:showNotification', source, '~r~Non hai il permesso per questa azione!')
    end
end)

-- Add command to check admin status
ESX.RegisterCommand('acadmin', 'admin', function(xPlayer, args, showError)
    local targetId = args.id
    local targetXPlayer = ESX.GetPlayerFromId(targetId)
    
    if not targetXPlayer then
        showError('Giocatore non trovato')
        return
    end
    
    local group = targetXPlayer.getGroup()
    TriggerClientEvent('esx:showNotification', xPlayer.source, ('Gruppo di %s: %s'):format(
        GetPlayerName(targetId), group
    ))
end, true, {help = 'Controlla i permessi di un giocatore', validate = true, arguments = {
    {name = 'id', help = 'ID del giocatore', type = 'number'}
}})

print('^2[ANTICHEAT]^7 Admin Permissions System Caricato')