local RSGCore = exports['rsg-core']:GetCoreObject()

lib.locale()
------------------------------------
-- callback to get weapon info
-----------------------------------
RSGCore.Functions.CreateCallback('rsg-weapons:server:getweaponinfo', function(source, cb, weaponserial)
-- lib.callback.register('rsg-weapons:server:getweaponinfo', function(source, cb, weaponserial)
    local weaponinfo = MySQL.query.await('SELECT * FROM player_weapons WHERE serial=@weaponserial', { ['@weaponserial'] = weaponserial })
    if weaponinfo[1] == nil then return end
    cb(weaponinfo)
end)

-----------------------------------
-- Degrade Weapon
-----------------------------------
RegisterNetEvent('rsg-weapons:server:degradeWeapon', function(degradationQueue) 
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then 
        return 
    end
    local items = Player.PlayerData.items
    local hasChanged = false
    for serial, shotCount in pairs(degradationQueue) do
        local svslot = nil
        for _, v in pairs(items) do
            if v.type == 'weapon' and v.info.serie == serial then
                svslot = v.slot
                break 
            end
        end
        if svslot and items[svslot] then
            local totalDegradation = (Config.DegradeRate * shotCount)
            local currentQuality = items[svslot].info.quality
            local newQuality = currentQuality - totalDegradation

            if newQuality <= 0 then
                newQuality = 0
                items[svslot].info.quality = newQuality
                TriggerClientEvent('rsg-weapons:client:UseWeapon', src, items[svslot])
            else
                items[svslot].info.quality = newQuality
            end
            
            hasChanged = true
        end
    end
    if hasChanged then
        Player.Functions.SetInventory(items)
    end
end)
------------------------------------------
-- use weapon repair kit
------------------------------------------
RSGCore.Functions.CreateUseableItem('weapon_repair_kit', function(source, item)
    TriggerClientEvent('rsg-weapons:client:repairweapon', source)
end)

-----------------------------------
-- repair weapon
-----------------------------------
RegisterNetEvent('rsg-weapons:server:repairweapon', function(serie)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local svslot = nil
    for _, v in pairs(Player.PlayerData.items) do
        if v.type == 'weapon' then
            if v.info.serie == serie then
                svslot = v.slot
                Player.PlayerData.items[svslot].info.quality = 100
            end
        end
    end
    Player.Functions.SetInventory(Player.PlayerData.items)
    TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_weapon_repaired'), type = 'success', duration = 5000 })
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('rsg-weapons:server:removeitem')
AddEventHandler('rsg-weapons:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)

RegisterNetEvent('rsg-weapons:server:saveEquippedWeapon', function(weaponData, isEquipped)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local equippedWeapons = Player.PlayerData.metadata.equippedweapons or {}
    if isEquipped then
        equippedWeapons[weaponData.info.serie] = {
            name = weaponData.name,
            serie = weaponData.info.serie,
            slot = weaponData.slot
        }
    else
        equippedWeapons[weaponData.info.serie] = nil
    end
    Player.Functions.SetMetaData('equippedweapons', equippedWeapons)
end)

RegisterNetEvent('rsg-weapons:server:saveEquippedKnife', function(knifeName, equipped)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local equippedKnives = Player.PlayerData.metadata.equippedknives or {}
    if equipped then
        equippedKnives[knifeName] = true
    else
        equippedKnives[knifeName] = nil
    end
    Player.Functions.SetMetaData('equippedknives', equippedKnives)
end)

RSGCore.Functions.CreateCallback('rsg-weapons:server:getEquippedWeapons', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end
    cb(Player.PlayerData.metadata.equippedweapons or {})
end)

RSGCore.Functions.CreateCallback('rsg-weapons:server:getEquippedKnives', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    cb(Player.PlayerData.metadata.equippedknives or {})
end)

RSGCore.Functions.CreateCallback('rsg-weapons:server:getWeaponBySerial', function(source, cb, serial)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(nil) return end
    for _, item in pairs(Player.PlayerData.items) do
        if item and item.name and item.info and item.info.serie == serial then
            cb(item)
            return
        end
    end
    cb(nil)
end)

---------------------------------------------
-- Infinityammo for admin
---------------------------------------------
RegisterNetEvent('rsg-weapons:requestToggle', function()
    local src = source
    if RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('rsg-weapons:toggle', src)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Infinity Ammo',
            description = 'You do not have permission to use this command.',
            type = 'error'
        })
    end
end)