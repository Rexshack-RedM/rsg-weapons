local RSGCore = exports['rsg-core']:GetCoreObject()
local alreadyUsed = false
local UsedWeapons = {}
local EquippedWeapons = {}
local weaponInHands = {}

------------------------------------------
-- equiped weapons export
------------------------------------------
exports('EquippedWeapons', function()
    if EquippedWeapons ~= nil then
        return EquippedWeapons
    end
end)

------------------------------------------
-- weapon in hands export
------------------------------------------
exports('weaponInHands', function()
    if weaponInHands ~= nil then
        return weaponInHands
    end
end)

------------------------------------------
-- models loader
------------------------------------------
local LoadModel = function(model)
    if not IsModelInCdimage(model) then
        return false
    end

    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(0)
    end

    return true
end

local getGuidFromItemId = function(inventoryId, itemData, category, slotId)
    local outItem = DataView.ArrayBuffer(8 * 13)

    if not itemData then
        itemData = 0
    end

    local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData, category, slotId, outItem:Buffer())

    if success then
        return outItem:Buffer()
    end

    return nil
end

local addWardrobeInventoryItem = function(itemName, slotHash)
    local itemHash = GetHashKey(itemName)
    local addReason = `ADD_REASON_DEFAULT`
    local inventoryId = 1
    local isValid = Citizen.InvokeNative(0x6D5D51B188333FD1, itemHash, 0)

    if not isValid then
        return false
    end

    local characterItem = getGuidFromItemId(inventoryId, nil, `CHARACTER`, 0xA1212100)

    if not characterItem then
        return false
    end

    local wardrobeItem = getGuidFromItemId(inventoryId, characterItem, `WARDROBE`, 0x3DABBFA7)

    if not wardrobeItem then
        return false
    end

    local itemData = DataView.ArrayBuffer(8 * 13)
    local isAdded = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData:Buffer(), wardrobeItem, itemHash, slotHash, 1, addReason)

    if not isAdded then
        return false
    end

    local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemData:Buffer(), true)

    return equipped
end

local GiveWeaponComponentToEntity = function(entity, componentHash, weaponHash, p3)
    return Citizen.InvokeNative(0x74C9090FDD1BB48E, entity, componentHash, weaponHash, p3)
end

------------------------------------------
-- auto dual-wield
------------------------------------------
RegisterNetEvent('rsg-weapons:client:AutoDualWield', function()
    local ped = PlayerPedId()

    addWardrobeInventoryItem("CLOTHING_ITEM_M_OFFHAND_000_TINT_004", 0xF20B6B4A)
    addWardrobeInventoryItem("UPGRADE_OFFHAND_HOLSTER", 0x39E57B01)

    Citizen.InvokeNative(0x1B7C5ADA8A6910A0, `SP_WEAPON_DUALWIELD`, true)
    Citizen.InvokeNative(0x46B901A8ECDB5A61, `SP_WEAPON_DUALWIELD`, true)
    Citizen.InvokeNative(0x83B8D50EB9446BBA, ped, true)
end)

------------------------------------------
-- use weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    local hash = GetHashKey(weaponData.name)
    local wepSerial = tostring(weaponData.info.serie)
    local wepQuality = weaponData.info.quality
    
    RSGCore.Functions.TriggerCallback('rsg-weapons:server:getweaponinfo', function(results)

        local ammo = results[1].ammo
        local ammo_high_velocity = results[1].ammo_high_velocity
        local ammo_split_point = results[1].ammo_split_point
        local ammo_express = results[1].ammo_express
        local ammo_express_explosive = results[1].ammo_express_explosive
        local ammo_buckshot_incendiary = results[1].ammo_buckshot_incendiary
        local ammo_slug = results[1].ammo_slug
        local ammo_slug_explosive = results[1].ammo_slug_explosive
        local ammo_tranquilizer = results[1].ammo_tranquilizer
        local ammo_fire = results[1].ammo_fire
        local ammo_poison = results[1].ammo_poison
        local ammo_dynamite = results[1].ammo_dynamite

        if wepQuality > 1 then
            
            for i = 1, #EquippedWeapons do
                local usedHash = EquippedWeapons[i]

                if hash == usedHash then
                    alreadyUsed = true
                end
            end

            EquippedWeapons[#EquippedWeapons + 1] = hash

            if not alreadyUsed and not UsedWeapons[tonumber(hash)] then

                if string.find(weaponName, 'thrown') == false then
                    UsedWeapons[tonumber(hash)] = {
                        name = weaponData.name,
                        WeaponHash = hash,
                        data = weaponData,
                        serie = weaponData.info.serie,
                    }
                end

                if weaponName == 'weapon_bow' or weaponName == 'weapon_bow_improved' then

                    if ammo == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW'), Config.AmountArrowAmmo, 0xCA3454E6)
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow')
                        else
                            ammo = 0
                            lib.notify({ title = 'No Arrows', type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW'), ammo, 0xCA3454E6)
                    end

                    if ammo_fire == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_fire', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_FIRE'), Config.AmountArrowAmmo, 0xCA3454E6)
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_fire')
                        else
                            ammo_fire = 0
                            lib.notify({ title = 'No Fire Arrows', type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_FIRE'), ammo_fire, 0xCA3454E6)
                    end

                    if ammo_poison == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_poison', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_POISON'), Config.AmountArrowAmmo, 0xCA3454E6)
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_poison')
                        else
                            ammo_poison = 0
                            lib.notify({ title = 'No Poison Arrows', type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_POISON'), ammo_poison, 0xCA3454E6)
                    end

                    if ammo_dynamite == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_dynamite', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_DYNAMITE'), Config.AmountArrowAmmo, 0xCA3454E6)
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_dynamite')
                        else
                            ammo_dynamite = 0
                            lib.notify({ title = 'No Dynamite Arrows', type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_ARROW_DYNAMITE'), ammo_dynamite, 0xCA3454E6)
                    end

                    Citizen.InvokeNative(0x5E3BDDBCB83F3D84, ped, hash, 0, false, true)

                --check throwables weapons
                elseif string.find(weaponName, 'thrown') then
                    GiveWeaponToPed_2(ped, hash, 0, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
                    TriggerServerEvent('rsg-weapons:server:removeWeaponItem', weaponName, 1)
                else
                     if ammo == nil then
                        ammo = 0
                    end 
                    --local _currentAmmo = loadedAmmo[wepSerial]
                    Citizen.InvokeNative(0x5E3BDDBCB83F3D84, ped, hash, 0, false, true)
                end
                if  string.find(weaponName, 'thrown') then
                    local _ammoType = Config.AmmoTypes[weaponName]
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, _ammoType, Config.AmountThrowablesAmmo, 752097756)
                else
                    if ammo == nil then
                        ammo = 0
                    end
                    Citizen.InvokeNative(0x14E56BC5B5DB6A19, ped, hash, ammo)
                end

                if string.find(weaponName, 'revolver') then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REVOLVER'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REVOLVER_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REVOLVER_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REVOLVER_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REVOLVER_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'pistol') then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_PISTOL'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_PISTOL_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_PISTOL_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_PISTOL_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_PISTOL_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'repeater') then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REPEATER'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REPEATER_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REPEATER_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REPEATER_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_REPEATER_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'rifle') and not weaponName == 'weapon_rifle_elephant' and not weaponName == 'weapon_rifle_varmint' then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'shotgun') then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_SHOTGUN'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_SHOTGUN_BUCKSHOT_INCENDIARY'), ammo_buckshot_incendiary, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_SHOTGUN_SLUG'), ammo_slug, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_SHOTGUN_SLUG_EXPLOSIVE'), ammo_slug_explosive, 0xCA3454E6)
                end
                if weaponName == 'weapon_rifle_elephant' then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_RIFLE_ELEPHANT'), ammo, 0xCA3454E6)
                end
                if weaponName == 'weapon_rifle_varmint' then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_22'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, joaat('AMMO_22_TRANQUILIZER'), ammo, 0xCA3454E6)
                end

                if Config.Debug then
                    print("Weapon Serial    : "..wepSerial)
                    print("Weapon Hash      : "..hash)
                end

                weaponInHands[hash] = wepSerial

                TriggerServerEvent('rsg-weapons:server:LoadComponents', wepSerial, hash)

                SetCurrentPedWeapon(ped,hash,true)

            else
                print('removing weapon ')
                RemoveWeaponFromPed(ped,hash)
                UsedWeapons[tonumber(hash)] = nil

                for i = 1, #EquippedWeapons do
                    local usedHash = EquippedWeapons[i]

                    if hash == usedHash then
                        EquippedWeapons[i] = nil
                        alreadyUsed = false
                    end
                end
            end

            -- set degradation
            local object = GetObjectIndexFromEntityIndex(GetCurrentPedWeaponEntityIndex(PlayerPedId(), 0))
            if not DoesEntityExist(object) then return end
            if wepQuality == 100 then
                Citizen.InvokeNative(0xA7A57E89E965D839, object, 0.0)
            else
                local currentDeg = wepQuality / 100
                Citizen.InvokeNative(0xA7A57E89E965D839, object, currentDeg)
            end

            weaponInHands[hash] = wepSerial

        else
            RemoveWeaponFromPed(ped,hash)
            UsedWeapons[tonumber(hash)] = nil

            for i = 1, #EquippedWeapons do
                local usedHash = EquippedWeapons[i]

                if hash == usedHash then
                    EquippedWeapons[i] = nil
                    alreadyUsed = false
                end
            end

            TriggerEvent('rsg-weapons:client:brokenweapon', wepSerial)
            lib.notify({ title = Lang:t('error.weapon_degraded'), type = 'error', duration = 5000 })

        end
    end, wepSerial)
end)

------------------------------------------
-- weapon components loader
------------------------------------------
RegisterNetEvent("rsg-weapon:client:LoadComponents")
AddEventHandler("rsg-weapon:client:LoadComponents", function(components, hash)
    Wait(500)

    for i = 1, #components do
        if components[i].model ~= 0 then
            LoadModel(components[i].model)
        end

        GiveWeaponComponentToEntity(PlayerPedId(), components[i].name, hash, true)

        if components[i].model ~= 0 then
            SetModelAsNoLongerNeeded(components[i].model)
        end
    end
end)

------------------------------------------
-- reload weapon function
------------------------------------------
function HandleReload()
    if not Config.EasyReload then
        return
    end

    local ped = PlayerPedId()
    local weaponHash = Citizen.InvokeNative(0x8425C5F057012DAB, ped) -- GetHashKey for the weapon the player is holding
    if weaponHash and weaponHash ~= -1569615261 then 
        local weaponData = RSGCore.Shared.Weapons[weaponHash]
        if weaponData then
            local ammoType = weaponData.ammotype
            local hasAmmoItem = RSGCore.Functions.HasItem(string.lower(ammoType), 1)
            if hasAmmoItem then
                TriggerEvent('rsg-weapons:client:AddAmmo', ammoType, 1, ammoType)
            else
                lib.notify({ title = 'No Ammo For Weapon', type = 'error', duration = 5000 })
            end
        else
            lib.notify({ title = Lang:t('error.weapon_not_recognized'), type = 'error', duration = 5000 })
        end
    else
        lib.notify({ title = Lang:t('error.you_are_not_holding_weapon'), type = 'error', duration = 5000 })
    end
end

------------------------------------------
-- reload weapon by keybind
------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, RSGCore.Shared.Keybinds[Config.AmmoReloadKeybind]) then
            HandleReload()
        end
    end
end)

------------------------------------------
-- degrade weapon when shooting
------------------------------------------
CreateThread(function()
    while true do
        Wait(1)
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local heldWeapon = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
            local currentSerial = weaponInHands[heldWeapon]

            if heldWeapon ~= nil and heldWeapon ~= -1569615261 then
                TriggerServerEvent('rsg-weapons:server:degradeWeapon', currentSerial)
            end
        end
    end
end)

------------------------------------------
-- set weapon damage modifier
------------------------------------------
Citizen.CreateThread(function()
    while true do
        Wait(1)
        SetPlayerWeaponDamageModifier(PlayerId(),Config.WeaponDmg)
        SetPlayerMeleeWeaponDamageModifier(PlayerId(),Config.MeleeDmg)
        if IsPlayerFreeAiming(PlayerId()) then
            DisableControlAction(0, 0x8FFC75D6, true)
        end
    end
end)

------------------------------------------
-- repair weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:repairweapon', function()
    local ped = PlayerPedId()
    local heldWeapon = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
    local currentSerial = weaponInHands[heldWeapon]
    if currentSerial ~= nil and heldWeapon ~= -1569615261 then
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            label = Lang:t('progressbar.repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', currentSerial)
    else
        lib.notify(
            { 
                title = Lang:t('error.no_weapon_found'),
                description = Lang:t('error.no_weapon_found_desc'),
                type = 'inform',
                icon = 'fa-solid fa-gun',
                iconAnimation = 'shake',
                duration = 7000
            }
        )
    end
end)

------------------------------------------
-- broken repair weapon choice yes/no
------------------------------------------
RegisterNetEvent('rsg-weapons:client:brokenweapon', function(serial)
    local input = lib.inputDialog('Repair Weapon', {
        { 
            type = 'select',
            label = 'Repair Weapon',
            options = { 
                { value = 'yes', text = 'Yes' }, 
                { value = 'no', text = 'No' }  
            },
            required = true
        },
    })

    if not input then return end

    if input[1] == 'yes' then
        TriggerEvent('rsg-weapons:client:repairbrokenweapon', serial)
    end
end)

------------------------------------------
-- repair broken weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:repairbrokenweapon', function(serial)
    local ped = PlayerPedId()
    local hasItem = RSGCore.Functions.HasItem('weapon_repair_kit', 1)
    if hasItem and serial ~= nil then
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disableControl = true,
            label = Lang:t('progressbar.repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', serial)
    else
        lib.notify(
            { 
                title = 'Item Needed',
                description = 'weapon repair kit needed!',
                type = 'inform',
                icon = 'fa-solid fa-gun',
                iconAnimation = 'shake',
                duration = 7000
            }
        )
    end
end)
