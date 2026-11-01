local RSGCore = exports['rsg-core']:GetCoreObject()

local REPAIR_KIT = 'weapon_repair_kit'
local degradeCooldown = {}
local toggleCooldown = {}
local pendingRepairs = {} -- [src] = { serial = string, started = ms }

-- items the client is allowed to ask us to consume (throwables + torch)
local consumable = { weapon_melee_torch = true }
for name in pairs(Config.ThrowableWeaponAmmoTypes) do
    consumable[name] = true
end

------------------------------------------
-- helpers
------------------------------------------
local function notify(src, title, description, nType)
    TriggerClientEvent('RSGCore:Client:Notify', src, { title = title, description = description, type = nType or 'inform', duration = 5000 })
end

local function isSerial(serial)
    return type(serial) == 'string' and #serial > 0 and #serial <= 32
end

local function getQuality(item)
    return tonumber(item.info.quality) or 100
end

-- returns the live item table for a weapon serial the player owns
local function findWeapon(Player, serial)
    for _, v in pairs(Player.PlayerData.items) do
        if v and v.type == 'weapon' and type(v.info) == 'table' and tostring(v.info.serie) == serial then
            return v
        end
    end
end

-- the most worn weapon the player carries (used when no gun is held)
local function findMostWorn(Player)
    local worst
    for _, v in pairs(Player.PlayerData.items) do
        if v and v.type == 'weapon' and type(v.info) == 'table' and v.info.serie and getQuality(v) < 100 then
            if not worst or getQuality(v) < getQuality(worst) then worst = v end
        end
    end
    return worst
end

local function saveItems(src, Player)
    exports['rsg-inventory']:SetInventory(src, Player.PlayerData.items)
end

------------------------------------------
-- degrade weapons (client batches shots every Config.UpdateDegrade ms)
------------------------------------------
local maxShotsPerBatch = math.ceil(Config.UpdateDegrade / 100) -- client samples every 100ms

RegisterNetEvent('rsg-weapons:server:degradeWeapon', function(queue)
    local src = source
    local now = GetGameTimer()
    if degradeCooldown[src] and now - degradeCooldown[src] < Config.UpdateDegrade * 0.5 then return end
    degradeCooldown[src] = now

    if type(queue) ~= 'table' then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local changed, broken = false, {}
    for serial, shots in pairs(queue) do
        shots = math.tointeger(tonumber(shots))
        if isSerial(serial) and shots and shots > 0 then
            local item = findWeapon(Player, serial)
            if item and getQuality(item) > 0 then
                item.info.quality = math.max(getQuality(item) - Config.DegradeRate * math.min(shots, maxShotsPerBatch), 0)
                changed = true
                if item.info.quality <= 1 then broken[#broken + 1] = item end
            end
        end
    end

    if not changed then return end
    saveItems(src, Player)
    for _, item in ipairs(broken) do
        TriggerClientEvent('rsg-weapons:client:UseWeapon', src, item) -- client unequips + tells the player
    end
end)

------------------------------------------
-- repair (start validates, finish checks the progress bar really ran)
------------------------------------------
RSGCore.Functions.CreateUseableItem(REPAIR_KIT, function(source)
    TriggerClientEvent('rsg-weapons:client:repairweapon', source)
end)

-- heldSerial is optional; returns the serial being repaired or false
RSGCore.Functions.CreateCallback('rsg-weapons:server:startRepair', function(src, cb, heldSerial)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or pendingRepairs[src] then return cb(false) end

    if not exports['rsg-inventory']:HasItem(src, REPAIR_KIT, 1) then
        notify(src, locale('cl_item_need'), locale('cl_item_need_desc'), 'error')
        return cb(false)
    end

    local item = isSerial(heldSerial) and findWeapon(Player, heldSerial)
    if item and getQuality(item) >= 100 then
        notify(src, locale('sv_weapon_repair'), locale('sv_weapon_not_damaged'), 'inform')
        return cb(false)
    end
    item = item or findMostWorn(Player)
    if not item then
        notify(src, locale('cl_no_weapon_found'), locale('cl_no_weapon_found_desc'), 'error')
        return cb(false)
    end

    local serial = tostring(item.info.serie)
    pendingRepairs[src] = { serial = serial, started = GetGameTimer() }
    cb(serial)
end)

RegisterNetEvent('rsg-weapons:server:finishRepair', function()
    local src = source
    local pending = pendingRepairs[src]
    pendingRepairs[src] = nil
    if not pending then return end
    -- reject if the progress bar was skipped (small allowance for latency)
    if GetGameTimer() - pending.started < Config.RepairTime - 1000 then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local item = findWeapon(Player, pending.serial)
    if not item then return end

    if not exports['rsg-inventory']:RemoveItem(src, REPAIR_KIT, 1, nil, 'rsg-weapons:repair') then
        notify(src, locale('cl_item_need'), locale('cl_item_need_desc'), 'error')
        return
    end
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[REPAIR_KIT], 'remove', 1)

    item.info.quality = 100
    saveItems(src, Player)
    TriggerClientEvent('rsg-weapons:client:weaponRepaired', src, pending.serial)
    notify(src, locale('sv_weapon_repair'), locale('sv_weapon_repaired', item.label or item.name), 'success')
end)

RegisterNetEvent('rsg-weapons:server:cancelRepair', function()
    pendingRepairs[source] = nil
end)

------------------------------------------
-- consume a throwable / torch (only whitelisted items, always 1)
------------------------------------------
RSGCore.Functions.CreateCallback('rsg-weapons:server:consumeItem', function(src, cb, item)
    if type(item) ~= 'string' or not consumable[item] then return cb(false) end
    if not RSGCore.Functions.GetPlayer(src) then return cb(false) end
    if not exports['rsg-inventory']:RemoveItem(src, item, 1, nil, 'rsg-weapons:use') then return cb(false) end
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', 1)
    cb(true)
end)

------------------------------------------
-- saved equipped weapons / knives (metadata)
------------------------------------------
RegisterNetEvent('rsg-weapons:server:saveEquippedWeapon', function(serial, isEquipped)
    local src = source
    if not isSerial(serial) then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local equipped = Player.PlayerData.metadata.equippedweapons or {}
    if isEquipped then
        local item = findWeapon(Player, serial)
        if not item or equipped[serial] then return end
        equipped[serial] = { name = item.name, serie = serial }
    else
        if not equipped[serial] then return end
        equipped[serial] = nil
    end
    Player.Functions.SetMetaData('equippedweapons', equipped)
end)

RegisterNetEvent('rsg-weapons:server:saveEquippedKnife', function(knifeName, isEquipped)
    local src = source
    if type(knifeName) ~= 'string' then return end
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local equipped = Player.PlayerData.metadata.equippedknives or {}
    if isEquipped then
        local shared = RSGCore.Shared.Items[knifeName]
        if not shared or shared.type ~= 'equipment' or equipped[knifeName] then return end
        if not exports['rsg-inventory']:HasItem(src, knifeName, 1) then return end
        equipped[knifeName] = true
    else
        if not equipped[knifeName] then return end
        equipped[knifeName] = nil
    end
    Player.Functions.SetMetaData('equippedknives', equipped)
end)

-- weapons to re-equip on login (owned and not broken) and knife names
RSGCore.Functions.CreateCallback('rsg-weapons:server:getEquipped', function(src, cb)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return cb({ weapons = {}, knives = {} }) end

    local saved = Player.PlayerData.metadata.equippedweapons or {}
    local weapons, cleaned, dirty = {}, {}, false
    for serial, data in pairs(saved) do
        local item = isSerial(serial) and findWeapon(Player, serial)
        if item and getQuality(item) > 1 then
            weapons[#weapons + 1] = item
            cleaned[serial] = data
        else
            dirty = true
        end
    end
    if dirty then Player.Functions.SetMetaData('equippedweapons', cleaned) end

    local knives = {}
    for name in pairs(Player.PlayerData.metadata.equippedknives or {}) do
        if exports['rsg-inventory']:HasItem(src, name, 1) then
            knives[#knives + 1] = name
        end
    end
    cb({ weapons = weapons, knives = knives })
end)

------------------------------------------
-- infinite ammo (admin)
------------------------------------------
RegisterNetEvent('rsg-weapons:requestToggle', function()
    local src = source
    local now = GetGameTimer()
    if toggleCooldown[src] and now - toggleCooldown[src] < 1000 then return end
    toggleCooldown[src] = now

    if RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('rsg-weapons:toggle', src)
    else
        notify(src, locale('cl_infinite_ammo_title'), locale('sv_no_permission'), 'error')
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    degradeCooldown[src] = nil
    toggleCooldown[src] = nil
    pendingRepairs[src] = nil
end)
