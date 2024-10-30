local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()
local UsedWeapons = {}
local weaponInHands = {}
local currentWeaponSerial = nil

------------------------------------------
-- weapon in hands export
------------------------------------------
exports('weaponInHands', function()
    if weaponInHands ~= nil then
        return weaponInHands
    end
end)

------------------------------------------
-- Check Weapon Serial export
------------------------------------------
exports('CheckWeaponSerial', function()
    local serial = nil
    local hash = nil
    local _, wepHash = GetCurrentPedWeapon(cache.ped, true, 0, true)

    if currentWeaponSerial then
        for k, v in pairs(weaponInHands) do
            if tonumber(wepHash) == tonumber(k) then
                hash = k
                serial = v

                break
            end
        end
    end

    if Config.Debug then
        print('^5Weapon Serial^7   : ^2'..tostring(serial)..'^7')
        print('^5Weapon Hash^7     : ^2'..tostring(hash)..'^7')
    end

    return serial, hash
end)

------------------------------------------
-- BASSICS FUNTIONS
------------------------------------------

local function getGuidFromItemId(inventoryId, itemData, category, slotId)
	local outItem = DataView.ArrayBuffer(8 * 13)

	if not itemData then
		itemData = 0
	end

	local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData, category, slotId, outItem:Buffer())
	if success then
		return outItem:Buffer() 
	else
		return nil
	end
end

local function addWardrobeInventoryItem(itemName, slotHash)
	local itemHash = GetHashKey(itemName)
	local addReason = GetHashKey("ADD_REASON_DEFAULT")
	local inventoryId = 1

	local isValid = Citizen.InvokeNative(0x6D5D51B188333FD1, itemHash, 0) 
	if not isValid then
		return false
	end

	local characterItem = getGuidFromItemId(inventoryId, nil, GetHashKey("CHARACTER"), 0xA1212100)
	if not characterItem then
		return false
	end

	local wardrobeItem = getGuidFromItemId(inventoryId, characterItem, GetHashKey("WARDROBE"), 0x3DABBFA7)
	if not wardrobeItem then
		return false
	end

	local itemData = DataView.ArrayBuffer(8 * 13)
	local isAdded = Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData:Buffer(), wardrobeItem, itemHash,
		slotHash, 1, addReason)
	if not isAdded then
		return false
	end

	local equipped = Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemData:Buffer(), true)
	return equipped;
end

------------------------------------------
-- use weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData, shootbool)
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponData.name)
    local wepSerial = tostring(weaponData.info.serie)
    local wepQuality = weaponData.info.quality
    local EquippedWeapons = exports['rsg-weapons']:EquippedWeapons() or {}

    RSGCore.Functions.TriggerCallback('rsg-weapons:server:getweaponinfo', function(results)
        local isWeaponAGun = Citizen.InvokeNative(0x705BE297EEBDB95D, hash)
        local isWeaponOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, hash)
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

            for k, v in pairs(EquippedWeapons) do
                if v.hash == hash then
                    WeaponAPI.used2 = true
                    break
                end
            end

            if not UsedWeapons[wepSerial] then

                UsedWeapons[wepSerial] = {
                    name = weaponData.name,
                    WeaponHash = hash,
                    data = weaponData,
                    serie = weaponData.info.serie,
                }

                if weaponName == 'weapon_bow' or weaponName == 'weapon_bow_improved' then

                    if ammo == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW'), Config.AmountArrowAmmo, 0xCA3454E6)
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow')
                        else
                            ammo = 0
                            lib.notify({ title = locale('cl_no_arrow'), type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW'), ammo) -- , 0xCA3454E6
                    end

                    if ammo_fire == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_fire', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_FIRE'), Config.AmountArrowAmmo) -- , 0xCA3454E6
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_fire')
                        else
                            ammo_fire = 0
                            lib.notify({ title = locale('cl_no_arrow_fire'), type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_FIRE'), ammo_fire) -- , 0xCA3454E6
                    end

                    if ammo_poison == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_poison', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_POISON'), Config.AmountArrowAmmo) -- , 0xCA3454E6
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_poison')
                        else
                            ammo_poison = 0
                            lib.notify({ title = locale('cl_no_arrow_poison'), type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_POISON'), ammo_poison) -- , 0xCA3454E6
                    end

                    if ammo_dynamite == 0 then
                        local hasItem = RSGCore.Functions.HasItem('ammo_arrow_dynamite', 1)
                        if hasItem then
                            Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_DYNAMITE'), Config.AmountArrowAmmo) -- , 0xCA3454E6
                            TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow_dynamite')
                        else
                            ammo_dynamite = 0
                            lib.notify({ title = locale('cl_no_arrow_explosive'), type = 'error', duration = 5000 })
                        end
                    else
                        Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_ARROW_DYNAMITE'), ammo_dynamite) -- , 0xCA3454E6
                    end

                    GiveWeaponToPed(cache.ped, hash, 0, false, true)
                    SetCurrentPedWeapon(cache.ped,hash,true)
                    --check throwables weapons
                elseif string.find(weaponName, 'thrown') then
                    -- GiveWeaponToPed(cache.ped, hash, 0, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
                    GiveWeaponToPed_2(cache.ped, hash, 0, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
                    TriggerServerEvent('rsg-weapons:server:removeWeaponItem', weaponName, 1)
                    SetCurrentPedWeapon(cache.ped,hash,true)
                else
                    if ammo == nil then
                        ammo = 0
                    end

	                if isWeaponAGun and isWeaponOneHanded then
                        addWardrobeInventoryItem("CLOTHING_ITEM_M_OFFHAND_000_TINT_004", 0xF20B6B4A)
		                addWardrobeInventoryItem("UPGRADE_OFFHAND_HOLSTER", 0x39E57B01)
                        if WeaponAPI.used2 then
                            WeaponAPI.EquipWeapon(weaponName, 1, wepSerial, hash)
                        else
                            WeaponAPI.EquipWeapon(weaponName, 0, wepSerial, hash)
                        end
                    else
                        GiveWeaponToPed(cache.ped, hash, 0, false, true)
                        SetCurrentPedWeapon(cache.ped,hash,true)
                    end
                end

                if  string.find(weaponName, 'thrown') then
                    local _ammoType = Config.AmmoTypes[weaponName]
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, _ammoType, Config.AmountThrowablesAmmo, 752097756) -- SetPedAmmoByType(
                else
                    if ammo == nil then
                        ammo = 0
                    end
                end

                SetAmmoInClip(cache.ped, hash, 0)

                if string.find(weaponName, 'revolver') then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REVOLVER'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REVOLVER_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REVOLVER_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REVOLVER_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REVOLVER_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'pistol') then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_PISTOL'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_PISTOL_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_PISTOL_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_PISTOL_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_PISTOL_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'repeater') then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REPEATER'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REPEATER_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REPEATER_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REPEATER_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_REPEATER_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'rifle') and weaponName ~= 'weapon_rifle_elephant' and weaponName ~= 'weapon_rifle_varmint' then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE_HIGH_VELOCITY'), ammo_high_velocity, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE_SPLIT_POINT'), ammo_split_point, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE_EXPRESS'), ammo_express, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE_EXPRESS_EXPLOSIVE'), ammo_express_explosive, 0xCA3454E6)
                end
                if string.find(weaponName, 'shotgun') then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_SHOTGUN'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_SHOTGUN_BUCKSHOT_INCENDIARY'), ammo_buckshot_incendiary, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_SHOTGUN_SLUG'), ammo_slug, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_SHOTGUN_SLUG_EXPLOSIVE'), ammo_slug_explosive, 0xCA3454E6)
                end
                if weaponName == 'weapon_rifle_elephant' then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_RIFLE_ELEPHANT'), ammo, 0xCA3454E6)
                end
                if weaponName == 'weapon_rifle_varmint' then
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_22'), ammo, 0xCA3454E6)
                    Citizen.InvokeNative(0x5FD1E1F011E76D7E, cache.ped, joaat('AMMO_22_TRANQUILIZER'), ammo_tranquilizer, 0xCA3454E6)
                end

                if Config.Debug then
                    print("Weapon Serial: "..wepSerial)
                    print("Weapon Hash: "..hash)
                end

                currentWeaponSerial = wepSerial
                weaponInHands[hash] = wepSerial

                if Config.WeaponComponents then
                    TriggerServerEvent('rsg-weaponcomp:server:check_comps')
                end
            else
                if Config.Debug then
                    print('removing weapon ')
                end
                WeaponAPI.RemoveWeaponFromPeds(weaponName, wepSerial)
            end

            -- set degradation
            local entityIndex = GetCurrentPedWeaponEntityIndex(cache.ped, 0)
            local object = GetObjectIndexFromEntityIndex(entityIndex)
            if not DoesEntityExist(object) then return end
            if wepQuality == 100 then
                Citizen.InvokeNative(0xA7A57E89E965D839, object, 0.0)-- SetWeaponDegradation(
            else
                local currentDeg = wepQuality / 100
                Citizen.InvokeNative(0xA7A57E89E965D839, object, currentDeg) -- SetWeaponDegradation(
            end

            weaponInHands[hash] = wepSerial

        else
            WeaponAPI.RemoveWeaponFromPeds(weaponName, wepSerial)

            TriggerEvent('rsg-weapons:client:brokenweapon', wepSerial)

            if Config.WeaponComponents then -- false need /loadweapon load
                TriggerServerEvent("rsg-weaponcomp:server:removeComponents", "DEFUALT", weaponName, wepSerial)
                Wait(0)
                TriggerServerEvent('rsg-weaponcomp:server:check_comps')
            end

            lib.notify({ title = Lang:t('error.weapon_degraded'), type = 'error', duration = 5000 })

        end
    end, wepSerial)
end)

------------------------------------------
-- On Player Loaded
------------------------------------------
RegisterNetEvent('RSGCore:client:OnPlayerLoaded', function()
    Wait(5000)
    if Config.WeaponComponents then
        TriggerServerEvent('rsg-weaponcomp:server:check_comps')
    end
end)

local resource = GetCurrentResourceName()
AddEventHandler('onResourceStart', function(r)
    if resource ~= r then return end
    TriggerEvent('RSGCore:client:OnPlayerLoaded')
end)

------------------------------------------
-- degrade weapon when shooting
------------------------------------------
CreateThread(function()
    while true do
        Wait(1)
        if IsPedShooting(cache.ped) then
            local heldWeapon = Citizen.InvokeNative(0x8425C5F057012DAB, cache.ped) -- GetPedCurrentHeldWeapon(
            local serialHeld = weaponInHands[heldWeapon]
            if heldWeapon ~= nil and heldWeapon ~= -1569615261 then
                TriggerServerEvent('rsg-weapons:server:degradeWeapon', serialHeld)
            end
        end
    end
end)

------------------------------------------
-- set weapon damage modifier
------------------------------------------
CreateThread(function()
    while true do
        Wait(1)
        SetPlayerWeaponDamageModifier(PlayerId(), Config.WeaponDmg)
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), Config.MeleeDmg)
        if IsPlayerFreeAiming(PlayerId()) then
            DisableControlAction(0, 0x8FFC75D6, true)
        end
    end
end)

------------------------------------------
-- repair weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:repairweapon', function()
    local heldWeapon = Citizen.InvokeNative(0x8425C5F057012DAB, cache.ped) -- GetPedCurrentHeldWeapon(
    local currentSerial = weaponInHands[heldWeapon]
    if currentSerial ~= nil and heldWeapon ~= -1569615261 then
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat= true,
                mouse= false,
                sprint = true,
            },
            label = locale('cl_repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', currentSerial)
    else
        lib.notify({ title = locale('cl_no_weapon_found'), description = locale('cl_no_weapon_found_desc'), type = 'inform', icon = 'fa-solid fa-gun', iconAnimation = 'shake', duration = 7000 })
    end
end)

------------------------------------------
-- broken repair weapon choice yes/no
------------------------------------------
RegisterNetEvent('rsg-weapons:client:brokenweapon', function(serial)
    local input = lib.inputDialog(locale('cl_weapon_repair'), {
        {
            type = 'select',
            label = locale('cl_weapon_repair_p'),
            options = {
                { value = 'yes', text = locale('cl_reapir_yes') },
                { value = 'no', text =  locale('cl_reapir_no') }
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

    local hasItem = RSGCore.Functions.HasItem('weapon_repair_kit', 1)
    if hasItem and serial ~= nil then
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat= true,
                mouse= false,
                sprint = true,
            },
            label = locale('cl_repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', serial)
    else
        lib.notify({ title = locale('cl_item_need'), description = locale('cl_item_need_desc'), type = 'inform', icon = 'fa-solid fa-gun', iconAnimation = 'shake', duration = 7000 } )
    end
end)
