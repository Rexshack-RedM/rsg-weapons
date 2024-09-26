local RSGCore = exports['rsg-core']:GetCoreObject()

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
-- remove ammo from player
-----------------------------------
RegisterServerEvent('rsg-weapons:server:removeWeaponAmmoItem')
AddEventHandler('rsg-weapons:server:removeWeaponAmmoItem', function(ammoitem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(ammoitem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[ammoitem], 'remove')
    TriggerClientEvent('ox_lib:notify', src, {title = Lang:t('success.weapon_reloaded'), type = 'success', duration = 5000 })
end)

RegisterNetEvent('rsg-weapons:server:removeWeaponItem', function(weaponName, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(weaponName, amount)
end)

-----------------------------------
-- Degrade Weapon
-----------------------------------
RegisterNetEvent('rsg-weapons:server:degradeWeapon', function(serie)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local svslot = nil
    for _, v in pairs(Player.PlayerData.items) do
        if v.type == 'weapon' then
            if v.info.serie == serie then
                svslot = v.slot

                -- weapon quality update
                local newquality = (Player.PlayerData.items[svslot].info.quality - Config.DegradeRate)
                Player.PlayerData.items[svslot].info.quality = newquality

                if Player.PlayerData.items[svslot].info.quality <= 0 then
                    print(Player.PlayerData.items[svslot])
                    TriggerClientEvent("rsg-weapons:client:UseWeapon", src, Player.PlayerData.items[svslot])
                end
            end
        end
    end
    Player.Functions.SetInventory(Player.PlayerData.items)
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
    TriggerClientEvent('ox_lib:notify', src, {title = Lang:t('success.weapon_repaired'), type = 'success', duration = 5000 })
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('rsg-weapons:server:removeitem')
AddEventHandler('rsg-weapons:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
end)
