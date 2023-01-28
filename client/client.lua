local RSGCore = exports['rsg-core']:GetCoreObject()
local currentSerial = nil
local alreadyUsed = false
local UsedWeapons = {}
local EquippedWeapons = {}

exports('EquippedWeapons', function()
    if EquippedWeapons ~= nil then
        return EquippedWeapons
    end
end)

-- Models Loader
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

local GiveWeaponComponentToEntity = function(entity, componentHash, weaponHash, p3)
    return Citizen.InvokeNative(0x74C9090FDD1BB48E, entity, componentHash, weaponHash, p3)
end

RegisterNetEvent('rsg-weapons:client:UseWeapon', function(weaponData, shootbool)
    local ped = PlayerPedId()
    local weaponName = tostring(weaponData.name)
    local hash = GetHashKey(weaponData.name)
    local wepSerial = tostring(weaponData.info.serie)

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
            if weaponData.info.ammo == nil then
                local hasItem = RSGCore.Functions.HasItem('ammo_arrow', 1)
                if hasItem then
                    weaponData.info.ammo = Config.AmountArrowAmmo
                    weaponData.info.ammoclip = Config.AmountArrowAmmo
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow')
                else
                    weaponData.info.ammo = 0
                    weaponData.info.ammoclip = 0
                    RSGCore.Functions.Notify(Lang:t('error.no_arrows_your_inventory_load'), 'error')
                end
            elseif weaponData.info.ammo == 0 then
                local hasItem = RSGCore.Functions.HasItem('ammo_arrow', 1)
                if hasItem then
                    weaponData.info.ammo = Config.AmountArrowAmmo
                    weaponData.info.ammoclip = Config.AmountArrowAmmo
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow')
                else
                    weaponData.info.ammo = 0
                    weaponData.info.ammoclip = 0
                    RSGCore.Functions.Notify(Lang:t('error.no_arrows_your_inventory_load'), 'error')
                end
            end
            Citizen.InvokeNative(0x5E3BDDBCB83F3D84, ped, hash, 0, false, true)

        --check throwables weapons
        elseif string.find(weaponName, 'thrown') then
            GiveWeaponToPed_2(ped, hash, 0, false, true, 0, false, 0.5, 1.0, 752097756, false, 0.0, false)
            TriggerServerEvent('rsg-weapons:server:removeWeaponItem', weaponName, 1)
        else
            if weaponData.info.ammo == nil then
                weaponData.info.ammo = 0
                weaponData.info.ammoclip = 0
            end
            Citizen.InvokeNative(0x5E3BDDBCB83F3D84, ped, hash, 0, false, true)
        end
        if weaponName == 'weapon_bow' or weaponName == 'weapon_bow_improved' then
            SetPedAmmo(ped, hash, weaponData.info.ammo)

        elseif  string.find(weaponName, 'thrown') then
            local _ammoType = Config.AmmoTypes[weaponName]
            Citizen.InvokeNative(0x106A811C6D3035F3, ped, _ammoType, Config.AmountThrowablesAmmo, 752097756)
        else
            if weaponData.info.ammo == nil or weaponData.info.ammoclip == nil then
                weaponData.info.ammo = 0
                weaponData.info.ammoclip = 0
            end
            SetPedAmmo(ped, hash, weaponData.info.ammo - weaponData.info.ammoclip)
            SetAmmoInClip(ped, hash, weaponData.info.ammoclip)
        end

        if Config.Debug then
            print("Weapon Serial    : "..wepSerial)
            print("Weapon Hash      : "..hash)
        end

        TriggerServerEvent('rsg-weapons:server:LoadComponents', wepSerial, hash)

        SetCurrentPedWeapon(ped,hash,true)

    else
        local ammo = GetAmmoInPedWeapon(PlayerPedId(), hash)
        local ammobool, ammoclip = GetAmmoInClip(PlayerPedId(),hash)
        TriggerServerEvent('rsg-weapons:server:SaveAmmo', weaponData.info.serie, ammo, ammoclip)
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
    currentSerial = weaponData.info.serie
end)

-- Components Loader
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

-- load ammo
RegisterNetEvent('rsg-weapons:client:AddAmmo', function(ammotype, amount, ammo)
    local ped = PlayerPedId()
    local weapon = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
    local weapongroup = GetWeapontypeGroup(weapon)
    local currentSerial = currentSerial
    if Config.Debug == true then
        print(weapon)
        print(weapongroup)
        print(currentSerial)
    end
    if currentSerial ~= nil then
        if weapongroup == -1101297303 then -- revolver weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxRevolverAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_revolver')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == 416676503 then -- pistol weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxPistolAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_pistol')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == -594562071 then -- repeater weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxRepeaterAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_repeater')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == 970310034 then -- rifle weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxRifleAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_rifle')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == -1212426201 then -- sniper rifle weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxRifleAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_rifle')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == 860033945 then -- shotgun weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxShotgunAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_shotgun')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        elseif weapongroup == -1241684019 then -- bow weapon group
            local total = Citizen.InvokeNative(0x015A522136D7F951, PlayerPedId(), weapon, Citizen.ResultAsInteger()) -- GetAmmoInPedWeapon
            if total + (amount/2) < Config.MaxArrowAmmo then
                if RSGCore.Shared.Weapons[weapon] then
                    Citizen.InvokeNative(0x106A811C6D3035F3, ped, GetHashKey(ammotype), amount, 0xCA3454E6) -- AddAmmoToPedByType
                    TriggerServerEvent('rsg-weapons:server:removeWeaponAmmoItem', 'ammo_arrow')
                end
            else
                RSGCore.Functions.Notify(Lang:t('error.max_mmo_capacity'), 'error')
            end
        else
            RSGCore.Functions.Notify(Lang:t('error.wrong_ammo_for_weapon'), 'error')
        end
    else
        RSGCore.Functions.Notify(Lang:t('error.you_are_not_holding_weapon'), 'error')
    end
end)

-- update ammo loop
CreateThread(function()
    while true do
        Wait(60000)
        local ped = PlayerPedId()
        local heldWeapon = Citizen.InvokeNative(0x8425C5F057012DAB, ped)
        local getammo = GetAmmoInPedWeapon(ped, heldWeapon)
        local getammoclip = GetAmmoInClip(ped, heldWeapon)
        if currentSerial ~= nil and heldWeapon ~= -1569615261 then
            TriggerServerEvent('rsg-weapons:server:SaveAmmo', currentSerial, tonumber(getammo), tonumber(getammoclip))
        end        
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(1)
        SetPlayerWeaponDamageModifier(PlayerId(),Config.WeaponDmg)
        SetPlayerMeleeWeaponDamageModifier(PlayerId(),Config.MeleeDmg)
        if IsPlayerFreeAiming(PlayerId()) then
            DisableControlAction(0  ,0x8FFC75D6 ,true)
        end
    end
end)
