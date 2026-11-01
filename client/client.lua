local RSGCore = exports['rsg-core']:GetCoreObject()

local UNARMED = `WEAPON_UNARMED`
local SPRINT = 0x8FFC75D6

local UsedWeapons = {}      -- [serial] = { name, WeaponHash, data, serie }
local weaponInHands = {}    -- [weaponHash] = serial (read by other resources)
local degradeQueue = {}     -- [serial] = shots
local damageByHash = {}     -- [weaponHash] = { damage, name }
local nextHandLeft = false
local offhandHolsterAdded = false
local repairing = false
local infinityOn = false

for _, v in ipairs(Config.WeaponDamage) do
    damageByHash[joaat(v.Name)] = { damage = v.Damage, name = v.Name }
end

------------------------------------------
-- exports
------------------------------------------
exports('weaponInHands', function()
    return weaponInHands
end)

-- kept for compatibility: clears a serial from the used list
exports('UsedWeapons', function(serial)
    UsedWeapons[serial] = nil
end)

WeaponAPI.OnRemoved = function(serial)
    UsedWeapons[serial] = nil
end

exports('GetUsedWeapons', function()
    return UsedWeapons
end)

exports('CheckWeaponSerial', function()
    local _, hash = GetCurrentPedWeapon(PlayerPedId(), true, 0, true)
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
    RSGCore.Functions.Notify({ title = title, description = description, type = nType or 'inform', duration = 5000 })
end

local function ensureOffhandHolster()
    if offhandHolsterAdded then return end
    local prefix = IsPedMale(PlayerPedId()) and 'M' or 'F'
    WeaponAPI.AddWardrobeItem('CLOTHING_ITEM_' .. prefix .. '_OFFHAND_000_TINT_004', 0xF20B6B4A)
    WeaponAPI.AddWardrobeItem('UPGRADE_OFFHAND_HOLSTER', 0x39E57B01)
    offhandHolsterAdded = true
end

-- keep weaponInHands pointing at a gun that is still equipped
local function clearWeaponTracking(hash, serial)
    if weaponInHands[hash] ~= serial then return end
    weaponInHands[hash] = nil
    for _, v in ipairs(WeaponAPI.GetEquipped()) do
        if v.hash == hash then
            weaponInHands[hash] = v.id
            break
        end
    end
end

local function unequipWeapon(weaponName, serial, hash, keepSaved)
    WeaponAPI.RemoveWeaponFromPeds(weaponName, serial)
    UsedWeapons[serial] = nil
    clearWeaponTracking(hash, serial)
    if Config.SaveEquippedWeapons and not keepSaved then
        TriggerServerEvent('rsg-weapons:server:saveEquippedWeapon', serial, false)
    end
end

local function setDegradation(attachPoint, quality)
    local object = GetObjectIndexFromEntityIndex(GetCurrentPedWeaponEntityIndex(PlayerPedId(), attachPoint))
    if not DoesEntityExist(object) then return end
    local degradation = quality >= 100 and 0.0 or (1.0 - (quality / 100))
    Citizen.InvokeNative(0xA7A57E89E965D839, object, degradation) -- SetWeaponDegradation
end

local function resetState()
    WeaponAPI.Reset()
    UsedWeapons, weaponInHands, degradeQueue = {}, {}, {}
    offhandHolsterAdded = false
end

-- serial of the gun in the right hand
local function getHeldSerial()
    local held = Citizen.InvokeNative(0x8425C5F057012DAB, PlayerPedId()) -- GetPedCurrentHeldWeapon
    if not held or held == UNARMED then return nil end
    return WeaponAPI.GetSerialInSlot(0, held) or weaponInHands[held]
end

------------------------------------------
-- use weapon (sent by rsg-inventory)
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData)
    if type(weaponData) ~= 'table' or not weaponData.name then return end
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)
    local ped = PlayerPedId()

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
        if UsedWeapons[serial] then
            unequipWeapon(weaponName, serial, hash)
            if Config.WeaponComponents then
                TriggerServerEvent('rsg-weaponcomp:server:removeComponents', 'DEFAULT', weaponName, serial)
                TriggerServerEvent('rsg-weaponcomp:server:check_comps')
            end
        end
        notify(locale('cl_weapon_degraded'), locale('cl_weapon_broken_hint'), 'error')
        return
    end

    -- toggle off
    if UsedWeapons[serial] then
        unequipWeapon(weaponName, serial, hash)
        return
    end

    -- equip
    local attachPoint = 0
    local isGun = Citizen.InvokeNative(0x705BE297EEBDB95D, hash)       -- IsWeaponAGun
    local isOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, hash) -- IsWeaponOneHanded

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
        GiveWeaponToPed(ped, hash, 0, false, true)
        SetCurrentPedWeapon(ped, hash, true)
    end

    UsedWeapons[serial] = { name = weaponName, WeaponHash = hash, data = weaponData, serie = serial }
    weaponInHands[hash] = serial

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
    if type(weaponData) ~= 'table' or not weaponData.name then return end
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)
    local ped = PlayerPedId()
    local ammoType = Config.ThrowableWeaponAmmoTypes[weaponName]
    local ammo = ammoType and GetResourceState('rsg-ammo') == 'started' and exports['rsg-ammo']:GetAmmoTypes()[ammoType]
    if not ammo then
        if Config.Debug then print(('^1[rsg-weapons]^7 no ammo definition for %s (%s)'):format(weaponName, tostring(ammoType))) end
        return
    end

    if GetPedAmmoByType(ped, ammo.hash) + ammo.refill > ammo.maxAmmo then
        notify(locale('cl_ammo_max'), nil, 'error')
        return
    end

    if not RSGCore.Functions.AwaitCallback('rsg-weapons:server:consumeItem', 5000, weaponName) then return end

    if not HasPedGotWeapon(ped, hash) then
        GiveWeaponToPed(ped, hash, 0)
    end
    AddAmmoToPedByType(ped, ammo.hash, ammo.refill)
    SetCurrentPedWeapon(ped, hash, true)
end)

------------------------------------------
-- knives / torch
------------------------------------------
RegisterNetEvent('rsg-weapons:client:UseEquipment', function(weaponData)
    if type(weaponData) ~= 'table' or not weaponData.name then return end
    local weaponName = tostring(weaponData.name)
    local hash = joaat(weaponName)
    local ped = PlayerPedId()

    if weaponName == 'weapon_melee_torch' then
        if HasPedGotWeapon(ped, hash) then return end
        if not RSGCore.Functions.AwaitCallback('rsg-weapons:server:consumeItem', 5000, weaponName) then return end
        GiveWeaponToPed(ped, hash, 0, false, true)
        SetCurrentPedWeapon(ped, hash, true)
        return
    end

    local equip = not HasPedGotWeapon(ped, hash)
    if equip then
        GiveWeaponToPed(ped, hash, 0, false, true)
        SetCurrentPedWeapon(ped, hash, true)
    else
        RemoveWeaponFromPed(ped, hash)
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
        if not next(UsedWeapons) then
            Wait(500) -- nothing tracked, nothing to wear
        else
            Wait(100)
            local ped = PlayerPedId()
            if IsPedShooting(ped) then
                local held = Citizen.InvokeNative(0x8425C5F057012DAB, ped) -- GetPedCurrentHeldWeapon
                if held and held ~= UNARMED then
                    local right = WeaponAPI.GetSerialInSlot(0, held) or weaponInHands[held]
                    local _, leftHash = GetCurrentPedWeapon(ped, true, 1, true)
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
        local _, weapon = GetCurrentPedWeapon(PlayerPedId())
        if weapon ~= lastWeapon then
            local data = damageByHash[weapon]
            Citizen.InvokeNative(0xD04AD186CE8BB129, PlayerId(), weapon, data and data.damage or 1.0) -- SetPlayerWeaponDamageModifier
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
            if IsPlayerFreeAiming(PlayerId()) then
                DisableControlAction(0, SPRINT, true)
                Wait(0)
            else
                Wait(50)
            end
        end
    end)
end

------------------------------------------
-- repair: held gun first, otherwise the server picks the most worn gun you carry
------------------------------------------
RegisterNetEvent('rsg-weapons:client:repairweapon', function()
    if repairing then return end
    local serial = RSGCore.Functions.AwaitCallback('rsg-weapons:server:startRepair', 5000, getHeldSerial())
    if not serial then return end

    repairing = true
    LocalPlayer.state:set('inv_busy', true, true)
    local done = RSGCore.Functions.ProgressBar({
        duration = Config.RepairTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, mouse = true },
        label = locale('cl_repairing_weapon'),
    })
    LocalPlayer.state:set('inv_busy', false, true)
    repairing = false

    if done then
        TriggerServerEvent('rsg-weapons:server:finishRepair')
    else
        TriggerServerEvent('rsg-weapons:server:cancelRepair')
        notify(locale('sv_weapon_repair'), locale('cl_repair_cancelled'), 'inform')
    end
end)

-- server confirmed a repair: clear the wear on the model if that gun is equipped
RegisterNetEvent('rsg-weapons:client:weaponRepaired', function(serial)
    local used = UsedWeapons[serial]
    if not used then return end
    if used.data and type(used.data.info) == 'table' then used.data.info.quality = 100 end
    setDegradation(WeaponAPI.GetSlotForSerial(serial) or 0, 100)
end)

------------------------------------------
-- infinite ammo (admin, server checks permission)
------------------------------------------
RegisterCommand('infinityammo', function()
    TriggerServerEvent('rsg-weapons:requestToggle')
end, false)

local function setInfiniteAmmo(state, weaponHash)
    local ped = PlayerPedId()
    SetPedInfiniteAmmoClip(ped, state)
    SetPedInfiniteAmmo(ped, state, weaponHash or UNARMED)
end

RegisterNetEvent('rsg-weapons:toggle', function()
    if GetInvokingResource() then return end -- only the server may toggle
    local hasWeapon, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
    if not hasWeapon or weaponHash == UNARMED then
        notify(locale('cl_infinite_ammo_title'), locale('cl_no_weapon_in_hand'), 'error')
        return
    end
    infinityOn = not infinityOn
    setInfiniteAmmo(infinityOn, weaponHash)
    notify(locale('cl_infinite_ammo_title'), infinityOn and locale('cl_infinite_ammo_on') or locale('cl_infinite_ammo_off'), infinityOn and 'success' or 'inform')
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
-- restore saved loadout
------------------------------------------
local function restoreLoadout()
    resetState()
    WeaponAPI.EnableDualWield()
    if not Config.SaveEquippedWeapons then return end

    CreateThread(function()
        Wait(5000)
        local data = RSGCore.Functions.AwaitCallback('rsg-weapons:server:getEquipped', 10000)
        if type(data) ~= 'table' then return end
        for _, item in ipairs(data.weapons or {}) do
            TriggerEvent('rsg-weapons:client:UseWeapon', item)
            Wait(500)
        end
        for _, name in ipairs(data.knives or {}) do
            if not HasPedGotWeapon(PlayerPedId(), joaat(name)) then
                TriggerEvent('rsg-weapons:client:UseEquipment', { name = name, info = {} })
                Wait(500)
            end
        end
        Wait(1000)
        Citizen.InvokeNative(0x94A3C1B804D291EC, PlayerPedId(), false, false, false, true) -- holster everything after restore
    end)
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', restoreLoadout)
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', resetState)

-- resource restarted while in game: put the saved loadout back
AddEventHandler('onResourceStart', function(name)
    if name ~= GetCurrentResourceName() then return end
    if LocalPlayer.state.isLoggedIn then restoreLoadout() end
end)

------------------------------------------
-- cleanup on resource stop (saved loadout is kept so it comes back on start)
------------------------------------------
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    local playerId = PlayerId()
    for hash in pairs(damageByHash) do
        Citizen.InvokeNative(0xD04AD186CE8BB129, playerId, hash, 1.0)
    end
    if Config.DisableCriticalHits then
        for _, ped in ipairs(GetGamePool('CPed')) do
            setCriticalFlags(ped, false)
        end
    end
    if infinityOn then setInfiniteAmmo(false) end
    for serial, v in pairs(UsedWeapons) do
        unequipWeapon(v.name, serial, v.WeaponHash, true)
    end
    if repairing then LocalPlayer.state:set('inv_busy', false, true) end
end)
