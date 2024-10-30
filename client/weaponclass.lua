WeaponAPI = {}
WeaponAPI.used = false
WeaponAPI.used2 = false

local EquippedWeapons = {}

------------------------------------------
-- equiped weapons export
------------------------------------------
exports('EquippedWeapons', function()
    return EquippedWeapons
end)
--------------------------------------------------------------

local ItemdatabaseIsKeyValid = function(weaponHash, unk)
    return Citizen.InvokeNative(0x6D5D51B188333FD1, weaponHash , unk)
end

local InventoryAddItemWithGuid = function(inventoryId, itemData, parentItem, itemHash, slotHash, amount, addReason)
    return Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData, parentItem, itemHash, slotHash, amount, addReason);
end

local InventoryEquipItemWithGuid = function(inventoryId , itemData , bEquipped)
    return Citizen.InvokeNative(0x734311E2852760D0, inventoryId , itemData , bEquipped)
end

local getGuidFromItemId = function(inventoryId, itemData, category, slotId)
	local outItem = DataView.ArrayBuffer(8 * 13)
	local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData and itemData or 0, category, slotId, outItem:Buffer())
	return success and outItem or nil
end

local moveInventoryItem = function(inventoryId, old, new, slot)
    local outGUID = DataView.ArrayBuffer(8 * 13)
    if not slot then slot = 1 end
    local sHash = "SLOTID_WEAPON_" .. tostring(slot)
    local success = Citizen.InvokeNative(0xDCCAA7C3BFD88862, inventoryId, old, new, joaat(sHash), 1, outGUID:Buffer())
    return success and outGUID or nil
end

WeaponAPI.EquipWeapon = function(weaponName, slot, id, hash)
    if slot == 0 and id then
        if #EquippedWeapons > 0 then
            slot = 1
        end
    end
    local weaponHash = joaat(weaponName)
    local slotHash = joaat("SLOTID_WEAPON_" .. tostring(slot))
    local addReason = ADD_REASON_DEFAULT
    local inventoryId = 1
    local move = false
    local playerPedId = PlayerPedId()

    -- verify valid item 
    local isValid = ItemdatabaseIsKeyValid(weaponHash, 0)
    if not isValid then
        print("Arma não válida")
        return false
    end

    local characterItem = getGuidFromItemId(inventoryId, nil, joaat("CHARACTER"), 0xA1212100) --return func_1367(joaat("CHARACTER"), func_2485(), -1591664384, bParam0);
	if not characterItem then
		print("sem características")
		return false
	end

	local weaponItem = getGuidFromItemId(inventoryId, characterItem:Buffer(), 923904168, -740156546) --return func_1367(923904168, func_1889(1), -740156546, 0);
	if not weaponItem then
		print("sem armas")
		return false
	end

    -- move to other slot
    if slot == 1 then
        if #EquippedWeapons > 0 then
            local newGUID = moveInventoryItem(inventoryId, EquippedWeapons[1].guid, weaponItem:Buffer(), 1)
            if not newGUID then
                print("Não é possível mover o item")
                return false
            end
            slotHash = joaat('SLOTID_WEAPON_0')
            slot = 0
            move = true
        else
            slotHash = joaat('SLOTID_WEAPON_0')
            slot = 0
        end
    end

    -- add weapon to inventory
    local itemData = DataView.ArrayBuffer(8 * 13)
    local isAdded = InventoryAddItemWithGuid(inventoryId, itemData:Buffer(), weaponItem:Buffer(), weaponHash, slotHash, 1, addReason)
    if not isAdded then
        print("Não adicionado")
        return false
    end

    -- equip weapon to player
    local equipped = InventoryEquipItemWithGuid(inventoryId, itemData:Buffer(), true)
    if not equipped then
        print("Não é capaz de equipar")
        return false
    end

    -- equip weapon to inventory
    WeaponAPI.used = true
    Citizen.InvokeNative(0x12FB95FE3D579238, playerPedId, itemData:Buffer(), true, slot, false, false)
    if move then
        Citizen.InvokeNative(0x12FB95FE3D579238, playerPedId, EquippedWeapons[1].guid, true, 1, false, false)
    end

    -- add weapon to list equippedweapons
    if id then
        local nWeapon = {
            id = id,
            hash = hash,
            guid = itemData:Buffer(),
        }
        table.insert(EquippedWeapons, nWeapon)
    end

    return true
end

WeaponAPI.RemoveWeaponFromPeds = function(weaponName, serial)
    local isWeaponAGun = Citizen.InvokeNative(0x705BE297EEBDB95D, joaat(weaponName))
    local isWeaponOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, joaat(weaponName))
    local playerPedId = PlayerPedId()
    local inventoryId = 1
    -- Variable to check if the weapon was removed successfully
    local weaponRemoved = false
    if isWeaponAGun and isWeaponOneHanded then
        for k, v in pairs(EquippedWeapons) do
            if v.id == serial then
                Citizen.InvokeNative(0x3E4E811480B3AE79, 1, v.guid, 1, joaat("REMOVE_REASON_DEFAULT"))
                table.remove(EquippedWeapons, k)
                weaponRemoved = true
                break
            end
        end
    end

    -- If there was a removal and still reset a weapon on the table, reposition it
    if weaponRemoved and #EquippedWeapons > 0 then
        exports['rsg-weapons']:UsedWeapons(serial)
        WeaponAPI.used2 = false
        local characterItem = getGuidFromItemId(1, nil, joaat("CHARACTER"), 0xA1212100)
        if not characterItem then
            print("Erro ao obter item de personagem")
            return false
        end

        local weaponItem = getGuidFromItemId(1, characterItem:Buffer(), 923904168, -740156546)
        if not weaponItem then
            print("Erro ao obter item de arma")
            return false
        end

        -- Move the remaining weapon to the correct slot
        local moveSuccess = moveInventoryItem(inventoryId, EquippedWeapons[1].guid, weaponItem:Buffer(), 0)
        if moveSuccess then
            Citizen.InvokeNative(0x12FB95FE3D579238, playerPedId, EquippedWeapons[1].guid, true, 0, false, false)
        else
            print("Erro ao mover a arma restante")
        end
    else
        RemoveWeaponFromPed(playerPedId, joaat(weaponName), true, 0)
        exports['rsg-weapons']:UsedWeapons(serial)
        WeaponAPI.used = false
    end
end

return WeaponAPI
