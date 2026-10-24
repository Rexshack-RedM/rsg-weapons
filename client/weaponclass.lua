WeaponAPI = {}
WeaponAPI.used = false

-- list of one-handed guns equipped through the inventory system
-- { id = serial, name = weaponName, hash = weaponHash, guid = buffer, slot = 0 (right) | 1 (left) }
local EquippedWeapons = {}

local ADD_REASON_DEFAULT = joaat('ADD_REASON_DEFAULT')
local REMOVE_REASON_DEFAULT = joaat('REMOVE_REASON_DEFAULT')
local INVENTORY_ID = 1

------------------------------------------
-- exports
------------------------------------------
exports('EquippedWeapons', function()
    return EquippedWeapons
end)

------------------------------------------
-- native wrappers
------------------------------------------
local function ItemdatabaseIsKeyValid(weaponHash, unk)
    return Citizen.InvokeNative(0x6D5D51B188333FD1, weaponHash, unk)
end

local function InventoryAddItemWithGuid(inventoryId, itemData, parentItem, itemHash, slotHash, amount, addReason)
    return Citizen.InvokeNative(0xCB5D11F9508A928D, inventoryId, itemData, parentItem, itemHash, slotHash, amount, addReason)
end

local function InventoryEquipItemWithGuid(inventoryId, itemData, bEquipped)
    return Citizen.InvokeNative(0x734311E2852760D0, inventoryId, itemData, bEquipped)
end

local function getGuidFromItemId(inventoryId, itemData, category, slotId)
    local outItem = DataView.ArrayBuffer(8 * 13)
    local success = Citizen.InvokeNative(0x886DFD3E185C8A89, inventoryId, itemData and itemData or 0, category, slotId, outItem:Buffer())
    return success and outItem or nil
end

-- returns the NEW guid buffer (the old guid is no longer valid after a move)
local function moveInventoryItem(inventoryId, old, new, slot)
    local outGUID = DataView.ArrayBuffer(8 * 13)
    local slotHash = joaat('SLOTID_WEAPON_' .. tostring(slot or 0))
    local success = Citizen.InvokeNative(0xDCCAA7C3BFD88862, inventoryId, old, new, slotHash, 1, outGUID:Buffer())
    return success and outGUID:Buffer() or nil
end

local function attachToPed(ped, guid, attachPoint)
    Citizen.InvokeNative(0x12FB95FE3D579238, ped, guid, true, attachPoint, false, false)
end

local function getWeaponParentItem()
    local characterItem = getGuidFromItemId(INVENTORY_ID, nil, joaat('CHARACTER'), 0xA1212100)
    if not characterItem then return nil end
    local weaponItem = getGuidFromItemId(INVENTORY_ID, characterItem:Buffer(), 923904168, -740156546)
    if not weaponItem then return nil end
    return weaponItem:Buffer()
end

local function isSlotUsed(slot)
    for _, v in ipairs(EquippedWeapons) do
        if v.slot == slot then return true end
    end
    return false
end

------------------------------------------
-- add + equip a wardrobe item (used for the off-hand holster)
------------------------------------------
WeaponAPI.AddWardrobeItem = function(itemName, slotHash)
    local itemHash = joaat(itemName)
    if not ItemdatabaseIsKeyValid(itemHash, 0) then return false end
    local characterItem = getGuidFromItemId(INVENTORY_ID, nil, joaat('CHARACTER'), 0xA1212100)
    if not characterItem then return false end
    local wardrobeItem = getGuidFromItemId(INVENTORY_ID, characterItem:Buffer(), joaat('WARDROBE'), 0x3DABBFA7)
    if not wardrobeItem then return false end
    local itemData = DataView.ArrayBuffer(8 * 13)
    if not InventoryAddItemWithGuid(INVENTORY_ID, itemData:Buffer(), wardrobeItem:Buffer(), itemHash, slotHash, 1, ADD_REASON_DEFAULT) then
        return false
    end
    return InventoryEquipItemWithGuid(INVENTORY_ID, itemData:Buffer(), true)
end

------------------------------------------
-- dual wield toggle (game scripts call this before allowing an off-hand gun)
------------------------------------------
WeaponAPI.EnableDualWield = function()
    Citizen.InvokeNative(0x83B8D50EB9446BBA, PlayerPedId(), true) -- _SET_ALLOW_DUAL_WIELD
end

WeaponAPI.CanEquipAnother = function()
    return #EquippedWeapons < 2
end

------------------------------------------
-- equip a one-handed gun
-- same order as the game (train_summon func_25): right hand first, then left hand
-- returns true, slot (attach point) on success
------------------------------------------
WeaponAPI.EquipWeapon = function(weaponName, id, hash)
    local weaponHash = joaat(weaponName)
    local playerPedId = PlayerPedId()

    if not ItemdatabaseIsKeyValid(weaponHash, 0) then
        if Config.Debug then print('^1[rsg-weapons]^7 weapon not valid: ' .. tostring(weaponName)) end
        return false
    end

    local slot
    if not isSlotUsed(0) then
        slot = 0
    elseif not isSlotUsed(1) then
        slot = 1
    else
        return false -- both hands full
    end

    local weaponItem = getWeaponParentItem()
    if not weaponItem then
        if Config.Debug then print('^1[rsg-weapons]^7 could not get weapon inventory parent') end
        return false
    end

    WeaponAPI.EnableDualWield()

    local itemData = DataView.ArrayBuffer(8 * 13)
    local slotHash = joaat('SLOTID_WEAPON_' .. slot)
    if not InventoryAddItemWithGuid(INVENTORY_ID, itemData:Buffer(), weaponItem, weaponHash, slotHash, 1, ADD_REASON_DEFAULT) then
        if Config.Debug then print('^1[rsg-weapons]^7 weapon not added to inventory') end
        return false
    end

    if not InventoryEquipItemWithGuid(INVENTORY_ID, itemData:Buffer(), true) then
        if Config.Debug then print('^1[rsg-weapons]^7 unable to equip weapon') end
        Citizen.InvokeNative(0x3E4E811480B3AE79, INVENTORY_ID, itemData:Buffer(), 1, REMOVE_REASON_DEFAULT)
        return false
    end

    attachToPed(playerPedId, itemData:Buffer(), slot)
    WeaponAPI.used = true

    EquippedWeapons[#EquippedWeapons + 1] = {
        id = id,
        name = weaponName,
        hash = hash or weaponHash,
        guid = itemData:Buffer(),
        slot = slot,
    }

    return true, slot
end

------------------------------------------
-- remove a weapon (one-handed guns are removed by serial so two of the same model work)
------------------------------------------
WeaponAPI.RemoveWeaponFromPeds = function(weaponName, serial)
    local weaponHash = joaat(weaponName)
    local isWeaponAGun = Citizen.InvokeNative(0x705BE297EEBDB95D, weaponHash)
    local isWeaponOneHanded = Citizen.InvokeNative(0xD955FEE4B87AFA07, weaponHash)
    local playerPedId = PlayerPedId()

    local removed = false
    if isWeaponAGun and isWeaponOneHanded then
        for k, v in ipairs(EquippedWeapons) do
            if v.id == serial then
                Citizen.InvokeNative(0x3E4E811480B3AE79, INVENTORY_ID, v.guid, 1, REMOVE_REASON_DEFAULT)
                table.remove(EquippedWeapons, k)
                removed = true
                break
            end
        end
    end

    exports['rsg-weapons']:UsedWeapons(serial)

    if removed and #EquippedWeapons > 0 then
        -- one gun left: if it is in the left hand, move it to the right hand
        local remaining = EquippedWeapons[1]
        if remaining.slot == 1 then
            local weaponItem = getWeaponParentItem()
            local newGuid = weaponItem and moveInventoryItem(INVENTORY_ID, remaining.guid, weaponItem, 0)
            if newGuid then
                remaining.guid = newGuid
                remaining.slot = 0
                attachToPed(playerPedId, newGuid, 0)
            elseif Config.Debug then
                print('^1[rsg-weapons]^7 could not move remaining weapon to right hand')
            end
        end
    else
        RemoveWeaponFromPed(playerPedId, weaponHash, true, 0)
        if #EquippedWeapons == 0 then
            WeaponAPI.used = false
        end
    end
end
exports('RemoveWeaponFromPeds', WeaponAPI.RemoveWeaponFromPeds)

-- serial of the equipped one-handed gun in an attach point (0 right, 1 left)
WeaponAPI.GetSerialInSlot = function(slot, hash)
    for _, v in ipairs(EquippedWeapons) do
        if v.slot == slot and (not hash or v.hash == hash) then
            return v.id
        end
    end
    return nil
end

-- clear tracking (resource restart / character change)
WeaponAPI.Reset = function()
    EquippedWeapons = {}
    WeaponAPI.used = false
end

