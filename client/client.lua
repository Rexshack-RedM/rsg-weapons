local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

local UNARMED = `WEAPON_UNARMED`
local SPRINT = 0x8FFC75D6

local UsedWeapons = {}      -- [serial] = { name, WeaponHash, data, serie }
local weaponInHands = {}    -- [weaponHash] = serial (read by rsg-weaponcomp / rsg-essentials)
local degradeQueue = {}     -- [serial] = shots
local damageByHash = {}     -- [weaponHash] = { damage, name }
local currentWeaponSerial = nil
local nextHandLeft = false
local offhandHolsterAdded = false
local repairing = false

for _, v in ipairs(Config.WeaponDamage) do
    damageByHash[joaat(v.Name)] = { damage = v.Damage, name = v.Name }
end

------------------------------------------
-- exports
------------------------------------------
exports('weaponInHands', function()
    return weaponInHands
end)

exports('UsedWeapons', function(serial)
    UsedWeapons[serial] = nil
end)

exports('GetUsedWeapons', function()
    return UsedWeapons
end)

exports('CheckWeaponSerial', function()
    local _, hash = GetCurrentPedWeapon(cache.ped, true, 0, true)
    local serial = weaponInHands[hash]
    if Config.Debug then
        print(('^5Weapon Serial^7: ^2%s^7 | ^5Hash^7: ^2%s^7'):format(tostring(serial), tostring(hash)))
    end
    if serial then return serial, hash end
    return nil, nil
end)

------------------------------------------
-- helpers
------------------------------------------
local function notify(title, description, nType)
    lib.notify({ title = title, description = description, type = nType or 'inform', duration = 5000 })
end

local function ensureOffhandHolster()
    if offhandHolsterAdded then return end
    local prefix = IsPedMale(cache.ped) and 'M' or 'F'
    WeaponAPI.AddWardrobeItem('CLOTHING_ITEM_' .. prefix .. '_OFFHAND_000_TINT_004', 0xF20B6B4A)
    WeaponAPI.AddWardrobeItem('UPGRADE_OFFHAND_HOLSTER', 0x39E57B01)
    offhandHolsterAdded = true
end

-- keep weaponInHands pointing at a gun that is still equipped
local function clearWeaponTracking(hash, serial)
    if weaponInHands[hash] == serial then
        weaponInHands[hash] = nil
        for _, v in ipairs(exports['rsg-weapons']:EquippedWeapons() or {}) do
            if v.hash == hash then
                weaponInHands[hash] = v.id
                break
            end
        end
    end
    if currentWeaponSerial == serial then
        currentWeaponSerial = nil
    end
end

local function unequipWeapon(weaponName, serial, hash)
    WeaponAPI.RemoveWeaponFromPeds(weaponName, serial)
    UsedWeapons[serial] = nil
    clearWeaponTracking(hash, serial)
    if Config.SaveEquippedWeapons then
        TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', serial, false)
    end
end

local function setDegradation(attachPoint, quality)
    local object = GetObjectIndexFromEntityIndex(GetCurrentPedWeaponEntityIndex(cache.ped, attachPoint))
    if not DoesEntityExist(object) then return end
    local degradation = quality >= 100 and 0.0 or (1.0 - (quality / 100))
    Citizen.InvokeNative(0xA7A57E89E965D839, object, degradation) -- SetWeaponDegradation
end

local function resetState()
    WeaponAPI.Reset()
    UsedWeapons, weaponInHands, degradeQueue = {}, {}, {}
    currentWeaponSerial = nil
    offhandHolsterAdded = false
end

------------------------------------------
-- use weapon (sent by rsg-inventory)
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData)
    if type(weaponData) ~= 'table' or not weaponData.name then return end
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)

    -- weapon left the inventory (rsg-inventory only sends the name): unequip every copy of that model
    if type(weaponData.info) ~= 'table' or not weaponData.info.serie then
        for serial, v in pairs(UsedWeapons) do
            if v.WeaponHash == hash then
                unequipWeapon(weaponName, serial, hash)
            end
        end
        return
    end

    local serial = tostring(weaponData.info.serie)
    local quality = tonumber(weaponData.info.quality) or 100

    -- broken
    if quality <= 1 then
        unequipWeapon(weaponName, serial, hash)
        if Config.WeaponComponents then
            TriggerServerEvent('rsg-weaponcomp:server:removeComponents', 'DEFAULT', weaponName, serial)
            TriggerServerEvent('rsg-weaponcomp:server:check_comps')
        end
        notify(locale('cl_weapon_degraded'), nil, 'error')
        TriggerEvent('rsg-weapons:client:brokenweapon', serial)
        return
    end

    -- toggle off
    if UsedWeapons[serial] then
        unequipWeapon(weaponName, serial, hash)
        return
    end

    -- equip
    local attachPoint = 0
    local isGun = Citizen.InvokeNative(0x705BE297EEBDB95D, hash)
    local isOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, hash)

    if isGun and isOneHanded then
        if not WeaponAPI.CanEquipAnother() then
            notify(locale('cl_dual_wield_full'), nil, 'error')
            return
        end
        ensureOffhandHolster()
        local ok, slot = WeaponAPI.EquipWeapon(weaponName, serial, hash)
        if not ok then
            notify(locale('cl_dual_wield_failed'), nil, 'error')
            return
        end
        attachPoint = slot
    else
        GiveWeaponToPed(cache.ped, hash, 0, false, true)
        SetCurrentPedWeapon(cache.ped, hash, true)
    end

    UsedWeapons[serial] = { name = weaponName, WeaponHash = hash, data = weaponData, serie = serial }
    weaponInHands[hash] = serial
    currentWeaponSerial = serial

    if Config.Debug then
        print(('^5[rsg-weapons]^7 equipped %s serial %s hand %d'):format(weaponName, serial, attachPoint))
    end
    if Config.SaveEquippedWeapons then
        TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', serial, true)
    end
    if Config.WeaponComponents then
        TriggerServerEvent('rsg-weaponcomp:server:check_comps')
    end

    Wait(100) -- let the weapon object spawn before applying wear
    setDegradation(attachPoint, quality)
end)

------------------------------------------
-- throwables (server removes the item before we refill ammo)
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseThrownWeapon', function(weaponData)
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)
    local ammoType = Config.ThrowableWeaponAmmoTypes[weaponName]
    local ammo = ammoType and exports['rsg-ammo']:GetAmmoTypes()[ammoType]
    if not ammo then
        if Config.Debug then print(('^1[rsg-weapons]^7 no ammo definition for %s (%s)'):format(weaponName, tostring(ammoType))) end
        return
    end

    if GetPedAmmoByType(cache.ped, ammo.hash) + ammo.refill > ammo.maxAmmo then
        notify(locale('cl_ammo_max'), nil, 'error')
        return
    end

    if not lib.callback.await('rsg-weapons:server:consumeItem', false, weaponName) then return end

    if not HasPedGotWeapon(cache.ped, hash) then
        GiveWeaponToPed(cache.ped, hash, 0)
    end
    AddAmmoToPedByType(cache.ped, ammo.hash, ammo.refill)
    SetCurrentPedWeapon(cache.ped, hash, true)
end)

------------------------------------------
-- knives / torch
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseEquipment', function(weaponData)
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)

    if weaponName == 'weapon_melee_torch' then
        if HasPedGotWeapon(cache.ped, hash) then return end
        if not lib.callback.await('rsg-weapons:server:consumeItem', false, weaponName) then return end
        GiveWeaponToPed(cache.ped, hash, 0, false, true)
        SetCurrentPedWeapon(cache.ped, hash, true)
        return
    end

    local equip = not HasPedGotWeapon(cache.ped, hash)
    if equip then
        GiveWeaponToPed(cache.ped, hash, 0, false, true)
        SetCurrentPedWeapon(cache.ped, hash, true)
    else
        RemoveWeaponFromPed(cache.ped, hash)
    end
    if Config.SaveEquippedWeapons then
        TriggerServerEvent('rsg-weapons:server:saveEquippedKnife', weaponName, equip)
    end
end)

------------------------------------------
-- degradation: count shots, send in batches
------------------------------------------
CreateThread(function()
    while true do
        Wait(100)
        if IsPedShooting(cache.ped) then
            local held = Citizen.InvokeNative(0x8425C5F057012DAB, cache.ped) -- GetPedCurrentHeldWeapon
            if held and held ~= UNARMED then
                local right = WeaponAPI.GetSerialInSlot(0, held) or weaponInHands[held]
                local _, leftHash = GetCurrentPedWeapon(cache.ped, true, 1, true)
                local left = leftHash and leftHash ~= UNARMED and WeaponAPI.GetSerialInSlot(1, leftHash)
                local serial = right
                if left then
                    -- dual wielding: the game fires each hand in turn
                    nextHandLeft = not nextHandLeft
                    serial = nextHandLeft and left or right
                end
                if serial then
                    degradeQueue[serial] = (degradeQueue[serial] or 0) + 1
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.UpdateDegrade)
        if next(degradeQueue) then
            TriggerServerEvent('rsg-weapons:server:degradeWeapon', degradeQueue)
            degradeQueue = {}
        end
    end
end)

------------------------------------------
-- damage modifier per weapon
------------------------------------------
CreateThread(function()
    local lastWeapon
    while true do
        Wait(250)
        local _, weapon = GetCurrentPedWeapon(cache.ped)
        if weapon ~= lastWeapon then
            local data = damageByHash[weapon]
            Citizen.InvokeNative(0xD04AD186CE8BB129, cache.playerId, weapon, data and data.damage or 1.0) -- SetPlayerWeaponDamageModifier
            if Config.Debug and data then
                print(('Weapon: %s | Damage Modifier: %.2fx'):format(data.name, data.damage))
            end
            lastWeapon = weapon
        end
    end
end)

------------------------------------------
-- no sprinting while aiming
------------------------------------------
if Config.DisableSprintWhileAiming then
    CreateThread(function()
        while true do
            if IsPlayerFreeAiming(cache.playerId) then
                DisableControlAction(0, SPRINT, true)
                Wait(0)
            else
                Wait(50)
            end
        end
    end)
end

------------------------------------------
-- repair
------------------------------------------
local function repairWeapon(serial)
    if repairing then return end
    if not serial then
        notify(locale('cl_no_weapon_found'), locale('cl_no_weapon_found_desc'), 'error')
        return
    end
    if not RSGCore.Functions.HasItem('weapon_repair_kit', 1) then
        notify(locale('cl_item_need'), locale('cl_item_need_desc'), 'error')
        return
    end
    if not lib.callback.await('rsg-weapons:server:startRepair', false, serial) then return end

    repairing = true
    LocalPlayer.state:set('inv_busy', true, true)
    local done = lib.progressBar({
        duration = Config.RepairTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, mouse = true },
        label = locale('cl_repairing_weapon'),
    })
    LocalPlayer.state:set('inv_busy', false, true)
    repairing = false

    TriggerServerEvent(done and 'rsg-weapons:server:finishRepair' or 'rsg-weapons:server:cancelRepair')
end

-- repair kit used: repair the weapon in the right hand
RegisterNetEvent('rsg-weapons:client:repairweapon', function()
    local held = Citizen.InvokeNative(0x8425C5F057012DAB, cache.ped)
    local serial = held and held ~= UNARMED and (WeaponAPI.GetSerialInSlot(0, held) or weaponInHands[held])
    repairWeapon(serial or nil)
end)

-- weapon broke: offer to repair it now
RegisterNetEvent('rsg-weapons:client:brokenweapon', function(serial)
    local answer = lib.alertDialog({
        header = locale('cl_weapon_repair'),
        content = locale('cl_weapon_repair_p'),
        centered = true,
        cancel = true,
        labels = { confirm = locale('cl_reapir_yes'), cancel = locale('cl_reapir_no') },
    })
    if answer == 'confirm' then
        repairWeapon(serial)
    end
end)

------------------------------------------
-- infinite ammo (admin, server checks permission)
------------------------------------------
local infinityOn = false

RegisterCommand('infinityammo', function()
    TriggerServerEvent('rsg-weapons:requestToggle')
end, false)

RegisterNetEvent('rsg-weapons:toggle', function()
    local hasWeapon, weaponHash = GetCurrentPedWeapon(cache.ped, true)
    if not hasWeapon or weaponHash == UNARMED then
        notify(locale('cl_lang_3'), locale('cl_lang_4'), 'error')
        return
    end
    infinityOn = not infinityOn
    SetPedInfiniteAmmoClip(cache.ped, infinityOn)
    SetPedInfiniteAmmo(cache.ped, infinityOn, weaponHash)
    notify(locale('cl_lang_3'), infinityOn and locale('cl_lang_1') or locale('cl_lang_2'), infinityOn and 'success' or 'inform')
end)

------------------------------------------
-- critical hits
------------------------------------------
local function setCriticalFlags(ped, value)
    SetPedConfigFlag(ped, 263, value)
    SetPedConfigFlag(ped, 340, value)
    SetPedConfigFlag(ped, 388, value)
end

if Config.DisableCriticalHits then
    CreateThread(function()
        while true do
            Wait(1000)
            for _, ped in ipairs(GetGamePool('CPed')) do
                setCriticalFlags(ped, true)
            end
        end
    end)
end

------------------------------------------
-- player load / unload
------------------------------------------
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    resetState()
    WeaponAPI.EnableDualWield()
    if not Config.SaveEquippedWeapons then return end

    CreateThread(function()
        Wait(5000)
        local weapons, knives = lib.callback.await('rsg-weapons:server:getEquipped', false)
        for _, item in ipairs(weapons or {}) do
            TriggerEvent('rsg-weapons:client:UseWeapon', item)
            Wait(500)
        end
        for _, name in ipairs(knives or {}) do
            TriggerEvent('rsg-weapons:client:UseEquipment', { name = name, info = {} })
            Wait(500)
        end
        Wait(1000)
        Citizen.InvokeNative(0x94A3C1B804D291EC, cache.ped, false, false, false, true) -- holster everything after restore
    end)
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', resetState)

------------------------------------------
-- cleanup on resource stop
------------------------------------------
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for hash in pairs(damageByHash) do
        Citizen.InvokeNative(0xD04AD186CE8BB129, cache.playerId, hash, 1.0)
    end
    if Config.DisableCriticalHits then
        for _, ped in ipairs(GetGamePool('CPed')) do
            setCriticalFlags(ped, false)
        end
    end
    if Config.SaveEquippedWeapons then
        for serial in pairs(UsedWeapons) do
            TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', serial, false)
        end
    end
end)
