local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()
local UsedWeapons = {}
local UsedEquipment = {} -- Track equipped knives, tools, etc.
local weaponInHands = {}
local degradeQueue = {}
local weaponDataLookup = {}
local currentWeaponSerial = nil

---------------------------------------------------------------------
-- Check if weapon limit is reached for a category
---------------------------------------------------------------------
local function IsWeaponLimitReached(weaponName)
    local category = Config.GetWeaponCategory(weaponName)
    local limit = Config.WeaponLimits[category] or 999
    
    -- Count currently equipped weapons in this category
    local count = 0
    
    -- Count from UsedWeapons (guns)
    for serial, weaponData in pairs(UsedWeapons) do
        local wepCategory = Config.GetWeaponCategory(weaponData.name)
        if wepCategory == category then
            count = count + 1
        end
    end
    
    -- Count from UsedEquipment (melee, tools)
    for equipName, _ in pairs(UsedEquipment) do
        local equipCategory = Config.GetWeaponCategory(equipName)
        if equipCategory == category then
            count = count + 1
        end
    end
    
    if Config.Debug then
        print(string.format("Category: %s | Count: %d | Limit: %d", category, count, limit))
    end
    
    return count >= limit, category, count, limit
end

for _, v in ipairs(Config.WeaponDamage) do
    local hash = GetHashKey(v.Name)
    weaponDataLookup[hash] = {
        Damage = v.Damage,
        Name = v.Name
    }
end

------------------------------------------
-- weapon in hands export
------------------------------------------
exports('weaponInHands', function()
    if weaponInHands ~= nil then
        return weaponInHands
    end
end)

exports('UsedWeapons', function(serial)
    UsedWeapons[serial] = nil
end)

exports('GetUsedWeapons', function()
    return UsedWeapons
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

local function AddToDegradationQueue(serial)
    if not serial then return end
    
    if degradeQueue[serial] then
        degradeQueue[serial] = degradeQueue[serial] + 1
    else
        degradeQueue[serial] = 1
    end
end

------------------------------------------
-- use weapon
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData)
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponData.name)
    local wepSerial = tostring(weaponData.info.serie)
    local wepQuality = weaponData.info.quality
    local EquippedWeapons = exports['rsg-weapons']:EquippedWeapons() or {}
    local isWeaponAGun = Citizen.InvokeNative(0x705BE297EEBDB95D, hash)
    local isWeaponOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, hash)

    if wepQuality > 1 then

        for k, v in pairs(EquippedWeapons) do
            if v.hash == hash then
                WeaponAPI.used2 = true
                break
            end
        end

        if not UsedWeapons[wepSerial] then
            -- Check weapon limit before equipping
            local limitReached, category, count, limit = IsWeaponLimitReached(weaponName)
            if limitReached then
                local categoryName = Config.WeaponCategoryNames[category] or category
                lib.notify({
                    title = 'Waffenlimit erreicht',
                    description = string.format('Du kannst nur %d %s tragen! (%d/%d)', limit, categoryName, count, limit),
                    type = 'error',
                    duration = 5000
                })
                return
            end
            UsedWeapons[wepSerial] = {
                name = weaponData.name,
                WeaponHash = hash,
                data = weaponData,
                serie = weaponData.info.serie,
            }

            if weaponName == 'weapon_bow' or weaponName == 'weapon_bow_improved' then
                GiveWeaponToPed(cache.ped, hash, 0, false, true)
                SetCurrentPedWeapon(cache.ped,hash,true)
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

            SetAmmoInClip(cache.ped, hash, 0)

            if Config.Debug then
                print("Weapon Serial: "..wepSerial)
                print("Weapon Hash: "..hash)
            end

            currentWeaponSerial = wepSerial
            weaponInHands[hash] = wepSerial
            if Config.SaveEquippedWeapons then
                TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', weaponData, true)
            end

            if Config.WeaponComponents then
                TriggerServerEvent('rsg-weaponcomp:server:check_comps')
            end
        else
            if Config.Debug then
                print('removing weapon ')
            end
            WeaponAPI.RemoveWeaponFromPeds(weaponName, wepSerial)
            UsedWeapons[wepSerial] = nil
            if Config.SaveEquippedWeapons then
                TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', weaponData, false)
            end
        end

        -- set degradation
        local entityIndex = GetCurrentPedWeaponEntityIndex(cache.ped, 0)
        local object = GetObjectIndexFromEntityIndex(entityIndex)
        if not DoesEntityExist(object) then return end
        if wepQuality == 100 then
            Citizen.InvokeNative(0xA7A57E89E965D839, object, 0.0)-- SetWeaponDegradation(
        else
            local currentDeg = (1.0 - (wepQuality / 100))
            Citizen.InvokeNative(0xA7A57E89E965D839, object, currentDeg) -- SetWeaponDegradation(
        end

        weaponInHands[hash] = wepSerial

    else
        WeaponAPI.RemoveWeaponFromPeds(weaponName, wepSerial)
        UsedWeapons[wepSerial] = nil
        TriggerEvent('rsg-weapons:client:brokenweapon', wepSerial)

        if Config.WeaponComponents then -- false need /loadweapon load
            TriggerServerEvent("rsg-weaponcomp:server:removeComponents", "DEFUALT", weaponName, wepSerial)
            Wait(0)
            TriggerServerEvent('rsg-weaponcomp:server:check_comps')
        end

        lib.notify({ title = locale('cl_weapon_degraded'), type = 'error', duration = 5000 })
        
    end
end)

RegisterNetEvent('rsg-weapons:client:UseThrownWeapon', function(weaponData) 
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponData.name)
    local ammoType = Config.ThrowableWeaponAmmoTypes[weaponName]
    local ammoDefinition = exports['rsg-ammo']:GetAmmoTypes()[ammoType]
    if not ammoDefinition then 
        --notify
        lib.print.info('neni defi', ammoType, weaponName)
        return
    end

    local originalAmount = GetPedAmmoByType(cache.ped, ammoDefinition.hash)
    local desiredAmount = originalAmount + ammoDefinition.refill
    if ammoDefinition.maxAmmo < desiredAmount then
        lib.notify({ title = locale('cl_ammo_max'), type = 'error', duration = 5000 })
        return
    end
    
    if not HasPedGotWeapon(cache.ped, hash) then
        GiveWeaponToPed(cache.ped, hash, 0)
    end

    AddAmmoToPedByType(cache.ped, ammoDefinition.hash, ammoDefinition.refill)
    SetCurrentPedWeapon(cache.ped, hash, true)
    TriggerServerEvent('rsg-weapons:server:removeitem', weaponName, 1)
end)

RegisterNetEvent('rsg-weapons:client:UseEquipment', function(weaponData) 
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponData.name)

    if weaponName == 'weapon_melee_torch' then
        if not HasPedGotWeapon(cache.ped, hash) then
            GiveWeaponToPed(cache.ped, hash, 0, false, true)
            SetCurrentPedWeapon(cache.ped, hash, true)
            TriggerServerEvent('rsg-weapons:server:removeitem', weaponName, 1)
        end

        return
    end

    if not HasPedGotWeapon(cache.ped, hash) then
        -- Check weapon limit before equipping
        local limitReached, category, count, limit = IsWeaponLimitReached(weaponName)
        if limitReached then
            local categoryName = Config.WeaponCategoryNames[category] or category
            lib.notify({
                title = 'Waffenlimit erreicht',
                description = string.format('Du kannst nur %d %s tragen! (%d/%d)', limit, categoryName, count, limit),
                type = 'error',
                duration = 5000
            })
            return
        end
        
        GiveWeaponToPed(cache.ped, hash, 0, false, true)
        SetCurrentPedWeapon(cache.ped, hash, true)
        UsedEquipment[weaponName] = true -- Track equipped equipment
        if Config.SaveEquippedWeapons then
            TriggerServerEvent('rsg-weapons:server:saveEquippedKnife', weaponName, true)
        end
    else
        RemoveWeaponFromPed(cache.ped, hash)
        UsedEquipment[weaponName] = nil -- Remove from tracking
        if Config.SaveEquippedWeapons then
            TriggerServerEvent('rsg-weapons:server:saveEquippedKnife', weaponName, false)
        end
    end
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
                AddToDegradationQueue(serialHeld)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.UpdateDegrade) 
        if next(degradeQueue) ~= nil then
            TriggerServerEvent('rsg-weapons:server:degradeWeapon', degradeQueue)
            degradeQueue = {}
        end
    end
end)

------------------------------------------
-- set weapon damage modifier
------------------------------------------
CreateThread(function()
    while true do
        Wait(250) 
        local ped = PlayerPedId()
        local _, wep = GetCurrentPedWeapon(ped)
        if wep ~= lastWeapon then
            local weaponData = weaponDataLookup[wep] 
            local currentModifier = 1.0
            local weaponLabel = "Unknown Weapon"
            if weaponData then
                currentModifier = weaponData.Damage
                weaponLabel = weaponData.Name
            end
            Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wep, currentModifier) 
            if Config.Debug and weaponData then
                local message = string.format("Weapon: %s | Damage Modifier: %.2fx", weaponLabel, currentModifier)
                print(message)
            end
            lastWeapon = wep
        end
    end
end)

CreateThread(function()

    if not Config.DisableSprintWhileAiming then 
        return 
    end

    while true do
        Wait(1)
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
    local hasItem = RSGCore.Functions.HasItem('weapon_repair_kit', 1)
    if hasItem and currentSerial ~= nil and heldWeapon ~= -1569615261 then
        LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                mouse = true,
            },
            label = locale('cl_repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', currentSerial)
        LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
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
        LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
        lib.progressBar({
            duration = Config.RepairTime,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                mouse = true,
            },
            label = locale('cl_repairing_weapon'),
        })
        TriggerServerEvent('rsg-weapons:server:removeitem', 'weapon_repair_kit', 1)
        TriggerServerEvent('rsg-weapons:server:repairweapon', serial)
        LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
    else
        lib.notify({ title = locale('cl_item_need'), description = locale('cl_item_need_desc'), type = 'inform', icon = 'fa-solid fa-gun', iconAnimation = 'shake', duration = 7000 } )
    end
end)

------------------------------------------
-- infinityammo for admins
------------------------------------------
local infinityOn = false

RegisterCommand('infinityammo', function()
    TriggerServerEvent('rsg-weapons:requestToggle')
end, false)

RegisterNetEvent('rsg-weapons:toggle', function()
    local ped = PlayerPedId()
    local hasWeapon, weaponHash = GetCurrentPedWeapon(ped, true)
    if hasWeapon and weaponHash ~= `WEAPON_UNARMED` then
        infinityOn = not infinityOn
        SetPedInfiniteAmmoClip(ped, infinityOn)
        SetPedInfiniteAmmo(ped, infinityOn, weaponHash)
        lib.notify({
            title = 'Infinity Ammo',
            description = infinityOn and locale('cl_lang_1') or locale('cl_lang_2'),
            type = infinityOn and 'success' or 'inform'
        })
    else
        lib.notify({
            title = locale('cl_lang_3'),
            description = locale('cl_lang_4'),
            type = 'error'
        })
    end
end)

------------------------------------------
-- disable critical hits
------------------------------------------
CreateThread(function()
    while true do
        Wait(1000) 
        local pool = GetGamePool('CPed')
        for _, ped in ipairs(pool) do
            if DoesEntityExist(ped) then
                SetPedConfigFlag(ped, 263, Config.DisableCriticalHits) 
                SetPedConfigFlag(ped, 340, Config.DisableCriticalHits)
                SetPedConfigFlag(ped, 388, Config.DisableCriticalHits) 
            end
        end
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    if not Config.SaveEquippedWeapons then return end
    CreateThread(function()
        while not RSGCore.Functions.GetPlayerData().citizenid or not RSGCore.Functions.GetPlayerData().items do
            Wait(100)
        end
        Wait(5000)
        RSGCore.Functions.TriggerCallback('rsg-weapons:server:getEquippedWeapons', function(equippedWeapons)
            if equippedWeapons and next(equippedWeapons) ~= nil then
                for serial, _ in pairs(equippedWeapons) do
                    RSGCore.Functions.TriggerCallback('rsg-weapons:server:getWeaponBySerial', function(weaponData)
                        if weaponData and weaponData.info and weaponData.info.quality > 1 then
                            Wait(500)
                            TriggerEvent('rsg-weapons:client:UseWeapon', weaponData)
                        end
                    end, serial)
                    Wait(1000)
                end
            end
        end)
        RSGCore.Functions.TriggerCallback('rsg-weapons:server:getEquippedKnives', function(equippedKnives)
            if equippedKnives and next(equippedKnives) ~= nil then
                for knifeName, _ in pairs(equippedKnives) do
                    Wait(500)
                    UsedEquipment[knifeName] = true -- Track on login
                    local fakeWeaponData = { name = knifeName, info = {} }
                    TriggerEvent('rsg-weapons:client:UseEquipment', fakeWeaponData)
                    Wait(1000)
                end
            end
        end)
        Wait(3000)
        Citizen.InvokeNative(0x94A3C1B804D291EC, cache.ped, false, false, false, true)
    end)
end)

------------------------------------------
-- cleanup on resource stop
------------------------------------------
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then 
        return 
    end
    for wepHash in pairs(weaponDataLookup) do
        Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), wepHash, 1.0)
    end
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) then
            SetPedConfigFlag(ped, 263, false)
            SetPedConfigFlag(ped, 340, false)
            SetPedConfigFlag(ped, 388, false)
        end
    end
    if Config.SaveEquippedWeapons then
        for serial, data in pairs(UsedWeapons) do
            TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', data.data, false)
        end
        for equipName, _ in pairs(UsedEquipment) do
            TriggerServerEvent('rsg-weapons:server:saveEquippedKnife', equipName, false)
        end
    end
end)