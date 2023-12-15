local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-weapons/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- start of use ammo

RSGCore.Functions.CreateUseableItem('ammo_revolver', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_REVOLVER', Config.AmountRevolverAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_pistol', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_PISTOL', Config.AmountPistolAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_repeater', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_REPEATER', Config.AmountRepeaterAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_rifle', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_RIFLE', Config.AmountRifleAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_shotgun', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_SHOTGUN', Config.AmountShotgunAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_arrow', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_ARROW', Config.AmountArrowAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_varmint', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_22', Config.AmountRifleAmmo, item)
end)

RSGCore.Functions.CreateUseableItem('ammo_rifle_elephant', function(source, item)
    TriggerClientEvent('rsg-weapons:client:AddAmmo', source, 'AMMO_RIFLE_ELEPHANT', Config.AmountRifleAmmo, item)
end)

-- end of use ammo

-- callback to get weapon info
RSGCore.Functions.CreateCallback('rsg-weapons:server:getweaponinfo', function(source, cb, weaponserial)
    local weaponinfo = MySQL.query.await('SELECT * FROM player_weapons WHERE serial=@weaponserial', { ['@weaponserial'] = weaponserial })
    if weaponinfo[1] == nil then return end
    cb(weaponinfo)
end)

-- update ammo
RegisterServerEvent('rsg-weapons:server:updateammo', function(serial, ammo, ammoclip)
    MySQL.update('UPDATE player_weapons SET ammo = ? WHERE serial = ?', { ammo, serial })
    MySQL.update('UPDATE player_weapons SET ammoclip = ? WHERE serial = ?', { ammoclip, serial })
end)

-- remove ammo from player
RegisterServerEvent('rsg-weapons:server:removeWeaponAmmoItem')
AddEventHandler('rsg-weapons:server:removeWeaponAmmoItem', function(ammoitem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(ammoitem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[ammoitem], 'remove')
    RSGCore.Functions.Notify(src, Lang:t('success.weapon_reloaded'), 'success')
end)

RegisterNetEvent('rsg-weapons:server:removeWeaponItem', function(weaponName, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(weaponName, amount)
end)

-- Components Loader
RegisterNetEvent('rsg-weapons:server:LoadComponents', function(serial, hash)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local ownerName = Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname

    if Config.Debug then
        print("Weapon Serial    : "..tostring(serial))
        print("Weapon Owner     : "..tostring('('..citizenid..')'..ownerName))
    end

    local result = MySQL.Sync.fetchAll('SELECT * FROM player_weapons WHERE serial = @serial and citizenid = @citizenid',
    {
        serial = serial,
        citizenid = citizenid
    })

    if result[1] == nil or result[1] == 0 then return end

    local components = json.decode(result[1].components)

    if Config.Debug then
        print('Components       : "'..tostring(components))
    end

    TriggerClientEvent('rsg-weapon:client:LoadComponents', src, components, hash)
end)

-- repair weapon
RegisterNetEvent('rsg-weapons:server:repairweapon', function(serie)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local svslot = nil
    local itemData
    for v,k in pairs(Player.PlayerData.items) do
        if k.type == 'weapon' then
            if k.info.serie == serie then
                svslot = k.slot
                Player.PlayerData.items[svslot].info.quality = 100
            end
        end
    end
    Player.Functions.SetInventory(Player.PlayerData.items)
    RSGCore.Functions.Notify(src, Lang:t('success.weapon_repaired'), 'success')
end)

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
