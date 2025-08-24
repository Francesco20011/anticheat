--[[
    client/detectors/weapons.lua

    Verifies that the player is not carrying a weapon that isn't
    whitelisted in Config.AllowedWeapons. On every check the current
    selected weapon is compared against the whitelist. If an
    unauthorized weapon is detected a violation report is sent. Note
    that this will only check the currently equipped weapon; it does
    not scan the entire inventory.
]]

ACDetectors = ACDetectors or {}
ACDetectors.weapons = {}

function ACDetectors.weapons.check()
    local ped = ACUtils.getPlayerPed()
    if not ped or ped == 0 then return end
    local weaponHash = GetSelectedPedWeapon(ped)
    -- Convert whitelist names to hashes for comparison
    local allowed = false
    for _, weaponName in ipairs(Config.AllowedWeapons) do
        if weaponHash == GetHashKey(weaponName) then
            allowed = true
            break
        end
    end
    if not allowed then
        ACUtils.notifyServer('reportViolation', {
            type   = 'WEAPON',
            weapon = tostring(weaponHash)
        })
    end
end