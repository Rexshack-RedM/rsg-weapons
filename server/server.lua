if not Config then Config = {} end
local RSGCore = exports['rsg-core']:GetCoreObject()
local wagons = {}
local wagonAnimalsData = {}

local function resolveCashType(moneyType)
    if moneyType == 'gold' then
        return Config.MoneyType.gold
    end
    return Config.MoneyType.money
end


local function getPlayer(src)
    return RSGCore.Functions.GetPlayer(src)
end

local function getCitizenId(src)
    local Player = getPlayer(src)
    return Player and Player.PlayerData.citizenid or nil
end

local function getName(src)
    local Player = getPlayer(src)
    if not Player then return nil, nil end
    local ci = Player.PlayerData.charinfo or {}
    return ci.firstname, ci.lastname
end

local function removeMoney(src, amount, moneyType)
    local Player = getPlayer(src)
    if not Player then return nil, false end
    local citizenid = Player.PlayerData.citizenid
    local cashType = resolveCashType(moneyType)
    if (Player.PlayerData.money[cashType] or 0) < amount then
        return citizenid, false
    end
    local ok = Player.Functions.RemoveMoney(cashType, amount)
    return citizenid, ok and true or false
end

local function addMoney(src, amount, moneyType)
    local Player = getPlayer(src)
    if not Player then return nil, false end
    local citizenid = Player.PlayerData.citizenid
    local ok = Player.Functions.AddMoney(resolveCashType(moneyType), amount)
    return citizenid, ok and true or false
end

local function openStash(src, weight, slots, stash)
    local data = { label = "Baú", maxweight = (weight or 0) * 1000, slots = slots or 0 }
    exports['rsg-inventory']:OpenInventory(src, stash, data)
end

RegisterNetEvent("rsg-wagons:saveWagonToDatabase", function(wagon, custom, moneyType)
    local src = source
    if not wagon or type(custom) ~= "table" then
        return
    end

    local maxWagons = Config.maxWagonsPerPlayer
    local wagonName, wagonPrice

    for _, info in pairs(Config.Wagons) do
        for k, v in pairs(info) do
            if wagon == k then
                wagonName = v.name
                wagonPrice = (moneyType == "gold") and v.priceGold or v.price
                break
            end
        end
        if wagonName then break end
    end

    if not wagonName then return end

    local citizenid, success = removeMoney(src, wagonPrice, moneyType)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, { title = locale("error"), description = locale("cl_dont_have_money"), type = 'error', duration = 5000 })
        return
    end

    local totalCount = MySQL.scalar.await("SELECT COUNT(*) FROM rsg_wagons WHERE citizenid = ?", { citizenid }) or 0
    if totalCount >= maxWagons then
        TriggerClientEvent('ox_lib:notify', src, { title = locale("error"), description = locale("cl_max_wagons_reached"), type = 'error', duration = 5000 })
        addMoney(src, wagonPrice, moneyType)
        return
    end

    local nameExists = MySQL.scalar.await(
        "SELECT COUNT(*) FROM rsg_wagons WHERE citizenid = ? AND JSON_EXTRACT(custom, '$.name') = ?",
        { citizenid, custom.name }
    ) or 0
    if nameExists > 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = locale("error"), description = locale("cl_wagon_name_exists"), type = 'error', duration = 5000 })
        addMoney(src, wagonPrice, moneyType)
        return
    end

    local inserted = MySQL.insert.await(
        "INSERT INTO rsg_wagons (citizenid, wagon, custom, animals) VALUES (?, ?, ?, ?)",
        { citizenid, wagon, json.encode(custom), json.encode({}) }
    )
    if inserted and inserted > 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = locale("success"), description = locale("cl_you_buy"), type = 'success', duration = 5000 })
    end
end)

RegisterNetEvent("rsg-wagons:getWagonDataByCitizenID", function(serverSource)
    local src = serverSource or source
    local citizenid = getCitizenId(src)
    if not citizenid then return end

    local rows = MySQL.query.await("SELECT * FROM rsg_wagons WHERE citizenid = ? AND active = 1 LIMIT 1", { citizenid })
    if rows and rows[1] then
        local d = rows[1]
        TriggerClientEvent("rsg-wagons:receiveWagonData", src, d.wagon, json.decode(d.custom), json.decode(d.animals), d.id)
    end
end)

RegisterNetEvent("rsg-wagons:registerWagon", function(netId, wagonID, model)
    wagons[netId] = { owner = source, wagonID = wagonID, wagonModel = model, authorized = wagons[netId] and wagons[netId].authorized or {} }
end)

RegisterNetEvent("rsg-wagons:updateWagonAuth", function(netId, citizenID, action)
    local w = wagons[netId]
    if not w or not citizenID then return end
    w.authorized = w.authorized or {}
    if action == "add" then
        w.authorized[citizenID] = true
    elseif action == "remove" then
        w.authorized[citizenID] = nil
    end
end)

lib.callback.register('rsg-wagons:isWagonRegistered', function(src, netId)
    local w = wagons[netId]
    if not w then return false end
    local isOwner = (src == w.owner)
    return true, isOwner, w.wagonID, w.wagonModel, netId
end)

-- server deel 2

RegisterNetEvent("rsg-wagons:openWagonStash", function(stash, wagonModel, wagonID, netId)
    local src = source
    local citizenId = getCitizenId(src)
    if not citizenId then return end

    local w = wagons[netId]
    if not w then return end

    local isAuthorized = (src == w.owner) or (w.authorized and w.authorized[citizenId])

    for _, infos in pairs(Config.Wagons) do
        local cfg = infos[wagonModel]
        if cfg then
            if isAuthorized then
                openStash(src, cfg.maxWeight, cfg.slots, stash)
            else
                local firstname, lastname = getName(src)
                TriggerClientEvent("rsg-wagons:stashPermission", src, {
                    citizenId = citizenId,
                    netId = netId,
                    firstname = firstname,
                    lastname = lastname,
                    owner = w.owner,
                    targetID = src,
                    stash = stash,
                    weight = cfg.maxWeight,
                    slots = cfg.slots
                })
            end
            return
        end
    end
end)

RegisterNetEvent("rsg-wagons:getOwnerPermission", function(data)
    TriggerClientEvent("btc-wagon:askOwnerPermission", data.owner, data)
end)

RegisterNetEvent("rsg-wagons:giveOwnerPermission", function(permission, data)
    local targetID, citizenId, netId = data.targetID, data.citizenId, data.netId
    if permission ~= "confirm" then
        return lib.notify(targetID, { title = locale("error"), description = locale("no_permission"), type = 'error', duration = 5000 })
    end

    local w = wagons[netId]
    if not w then return end

    w.authorized = w.authorized or {}
    if w.authorized[citizenId] then return end

    w.authorized[citizenId] = true
    lib.notify(targetID, { title = locale("success"), description = locale("have_permission"), type = 'success', duration = 5000 })
end)

lib.callback.register('rsg-wagons:checkMyWagons', function(src)
    local citizenid = getCitizenId(src)
    if not citizenid then return {}, {} end

    local result = MySQL.query.await("SELECT wagon, custom FROM rsg_wagons WHERE citizenid = ?", { citizenid })
    if not result or #result == 0 then return {}, {} end

    local models, customs = {}, {}
    for _, data in ipairs(result) do
        models[#models + 1] = data.wagon
        customs[#customs + 1] = json.decode(data.custom) or {}
    end
    return models, customs
end)

RegisterNetEvent("rsg-wagons:saveCustomization", function(wagonModel, custom, customType)
    local src = source
    local price = Config.CustomPrice and Config.CustomPrice[customType] or 0
    if price <= 0 or not wagonModel or type(custom) ~= "table" then
        return lib.notify(src, { title = locale("error"), description = locale("error"), type = 'error', duration = 5000 })
    end

    local citizenid, success = removeMoney(src, price)
    if not success then
        return lib.notify(src, { title = locale("error"), description = locale("cl_dont_have_money"), type = 'error', duration = 5000 })
    end

    local ok = MySQL.update.await(
        "UPDATE rsg_wagons SET custom = ? WHERE citizenid = ? AND wagon = ? AND JSON_EXTRACT(custom, '$.name') = ?",
        { json.encode(custom), citizenid, wagonModel, custom.name }
    )
    if ok and ok > 0 then
        lib.notify(src, { title = locale("success"), description = locale("cl_custom_success"), type = 'success', duration = 5000 })
    end
end)

RegisterNetEvent("rsg-wagons:toggleWagonActive", function(wagon, currentWagonCustom)
    local src = source
    local citizenID = getCitizenId(src)
    local customName = currentWagonCustom and currentWagonCustom.name
    if not citizenID or not wagon or not customName or customName == "" then
        return lib.notify(src, { title = locale("error"), description = locale("error"), type = 'error', duration = 5000 })
    end

    local active = MySQL.query.await("SELECT id FROM rsg_wagons WHERE citizenid = ? AND active = 1 LIMIT 1", { citizenID })
    if active and active[1] then
        MySQL.update.await("UPDATE rsg_wagons SET active = 0 WHERE id = ?", { active[1].id })
    end

    local updated = MySQL.update.await([[
        UPDATE rsg_wagons
        SET active = 1
        WHERE wagon = ?
          AND JSON_UNQUOTE(JSON_EXTRACT(custom, "$.name")) = ?
          AND citizenid = ?
    ]], { wagon, customName, citizenID })

    if updated and updated > 0 then
        --lib.notify(src, { title = locale("success"), description = locale("ative_wagon"), type = 'success', duration = 5000 })
        Wait(500)
        TriggerEvent("rsg-wagons:getWagonDataByCitizenID", src)
    else
        lib.notify(src, { title = locale("error"), description = locale("no_custom_wagon"), type = 'error', duration = 5000 })
    end
end)

-- server deel 3

RegisterNetEvent("rsg-wagons:sellWagon", function(wagonModel, custom)
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid or type(custom) ~= "table" or not custom.name then
        return lib.notify(src, { title = locale("error"), description = locale("no_wagon_found"), type = 'error', duration = 5000 })
    end

    local rows = MySQL.query.await(
        "SELECT * FROM rsg_wagons WHERE citizenid = ? AND JSON_EXTRACT(custom, '$.name') = ?",
        { citizenid, custom.name }
    )
    if not rows or not rows[1] then
        return lib.notify(src, { title = locale("error"), description = locale("no_wagon_found"), type = 'error', duration = 5000 })
    end

    local customDB = json.decode(rows[1].custom or "{}") or {}
    local buyMoneyType = customDB.buyMoneyType or "cash"

    local originalPrice, altPrice
    for _, set in pairs(Config.Wagons) do
        local cfg = set[wagonModel]
        if cfg then
            originalPrice = (buyMoneyType == "gold" and cfg.priceGold) or cfg.price
            altPrice = (buyMoneyType == "gold" and cfg.price) or cfg.priceGold
            break
        end
    end

    if not originalPrice then
        originalPrice = altPrice
        buyMoneyType = (buyMoneyType == "gold") and "cash" or "gold"
    end
    if not originalPrice then
        return lib.notify(src, { title = locale("error"), description = locale("no_price"), type = 'error', duration = 5000 })
    end

    local sellPrice = originalPrice * (Config.Sell or 1.0)

    MySQL.update.await(
        "DELETE FROM rsg_wagons WHERE citizenid = ? AND JSON_EXTRACT(custom, '$.name') = ?",
        { citizenid, custom.name }
    )
    addMoney(src, sellPrice, buyMoneyType)

    lib.notify(src, {
        title = locale("success"),
        description = locale("you_sell_wagon") .. ((buyMoneyType == "gold") and "🪙 " or "💰 ") .. tostring(sellPrice) .. "!",
        type = 'success',
        duration = 5000
    })
end)

local function GetLabelFromModel(item)
    if item.type == "animal" then
        local entry = Config.AnimalsStorage[item.model]
        return entry and entry.label
    elseif item.type == "pelt" then
        local entry = Config.AnimalsStorage[item.peltquality]
        return entry and entry.label
    end
end

local function buildMenuDataFromCache(wagonId)
    local menuData, list = {}, wagonAnimalsData[wagonId] or {}
    for _, item in ipairs(list) do
        menuData[#menuData + 1] = {
            label = GetLabelFromModel(item) or "Unknown Item",
            infos = item
        }
    end
    return menuData
end

local function getWagonMenuData(wagonId)
    if not wagonId then return {} end
    if wagonAnimalsData[wagonId] then
        return buildMenuDataFromCache(wagonId)
    end
    local rows = MySQL.query.await("SELECT animals FROM rsg_wagons WHERE id = ? LIMIT 1", { wagonId })
    local decoded = {}
    if rows and rows[1] and rows[1].animals then
        decoded = json.decode(rows[1].animals) or {}
    end
    wagonAnimalsData[wagonId] = decoded
    return buildMenuDataFromCache(wagonId)
end

local function updateAndSave(wagonId, newAnimal, remove)
    if not wagonId or type(newAnimal) ~= "table" then return end
    wagonAnimalsData[wagonId] = wagonAnimalsData[wagonId] or {}
    local animals = wagonAnimalsData[wagonId]

    local foundIndex
    for i, a in ipairs(animals) do
        local same = a.model == newAnimal.model and a.type == newAnimal.type and (
            (newAnimal.type == "animal" and a.outfit == newAnimal.outfit and a.skinned == newAnimal.skinned and a.quality == newAnimal.quality) or
            (newAnimal.type == "pelt" and a.peltquality == newAnimal.peltquality)
        )
        if same then
            foundIndex = i
            break
        end
    end

    if remove then
        if not foundIndex then return end
        local qty = animals[foundIndex].quantity or 1
        if qty > 1 then
            animals[foundIndex].quantity = qty - 1
        else
            table.remove(animals, foundIndex)
        end
    else
        if foundIndex then
            animals[foundIndex].quantity = (animals[foundIndex].quantity or 1) + 1
        else
            local entry = newAnimal
            entry.quantity = 1
            animals[#animals + 1] = entry
        end
    end

    wagonAnimalsData[wagonId] = animals
    MySQL.update.await("UPDATE rsg_wagons SET animals = ? WHERE id = ?", { json.encode(animals), wagonId })
end

RegisterNetEvent("rsg-wagons:storeAnimalInWagon", function(wagonId, newAnimal)
    if not wagonId or type(newAnimal) ~= "table" then return end
    if not wagonAnimalsData[wagonId] then
        local rows = MySQL.query.await("SELECT animals FROM rsg_wagons WHERE id = ? LIMIT 1", { wagonId })
        local loaded = {}
        if rows and rows[1] and rows[1].animals then
            loaded = json.decode(rows[1].animals) or {}
        end
        wagonAnimalsData[wagonId] = loaded
    end
    updateAndSave(wagonId, newAnimal, false)
end)

lib.callback.register('rsg-wagons:getAnimalStorage', function(_, wagonId)
    return getWagonMenuData(wagonId)
end)

RegisterNetEvent("rsg-wagons:removeAnimalFromWagon", function(wagonID, infos, label)
    local src = source
    if not wagonID or type(infos) ~= "table" then return end
    TriggerClientEvent("rsg-wagons:spawnAnimal", src, infos)
    updateAndSave(wagonID, infos, true)
end)

RegisterNetEvent("rsg-wagons:removeWagon", function(netId, wagon)
    local w = wagons[netId]
    local entity = NetworkGetEntityFromNetworkId(netId)

    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    wagons[netId] = nil
end)

-- Chop shop integration: registry accessors for server/chop.lua.
-- (server/*.lua share globals but not locals, so chop.lua reaches the
-- wagons table through these.)
function RSGWagons_GetWagon(netId)
    return wagons[tonumber(netId)]
end

-- Permanent delete: scrapping destroys the wagon, row included
-- (matches sellWagon semantics, no re-activation exploit).
function RSGWagons_DeactivateWagon(wagonID)
    if not wagonID then return end
    wagonAnimalsData[wagonID] = nil
    MySQL.update.await("DELETE FROM rsg_wagons WHERE id = ?", { wagonID })
    for netId, w in pairs(wagons) do
        if w.wagonID == wagonID then
            local entity = NetworkGetEntityFromNetworkId(tonumber(netId))
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
            wagons[netId] = nil
        end
    end
end
