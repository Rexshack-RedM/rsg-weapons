local RSGCore = exports['rsg-core']:GetCoreObject()
local currentWagonCustom = {}
local currentStore, currentWagonModel, currentCustom

local function GetPlayerMoney()
    local player = RSGCore.Functions.GetPlayerData()
    if not player or not player.money then return { cash = 0, gold = 0 } end
    return { cash = player.money.cash or 0, gold = player.money.gold or 0 }
end

local function Notify(type, title, message)
    lib.notify({ title = title, description = message, type = type })
end

RegisterNetEvent("rsg-wagons:client:openStore", function(store)
    currentStore = store
    local categories = {}
    for type in pairs(Config.Wagons) do
        categories[#categories + 1] = { type = type, label = locale(type), image = type .. ".png" }
    end
    table.sort(categories, function(a, b) return a.label:lower() < b.label:lower() end)

    local money = GetPlayerMoney()

    SendNUIMessage({
        action = 'openStore',
        store = store,
        categories = categories,
        playerMoney = money,
        theme = Config.UITheme or 'color'
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('getWagonsByType', function(data, cb)
    local store = data.store
    local wagonType = data.type
    local wagonsData = {}

    if Config.Wagons[wagonType] then
        for model, v in pairs(Config.Wagons[wagonType]) do
            wagonsData[#wagonsData + 1] = {
                name = v.name,
                price = v.price,
                maxAnimals = v.maxAnimals,
                slots = v.slots,
                maxWeight = v.maxWeight,
                model = model
            }
        end
    end

    table.sort(wagonsData, function(a, b) return (a.price or math.huge) < (b.price or math.huge) end)

    SendNUIMessage({ action = 'showWagons', wagons = wagonsData })
    cb('ok')
end)

RegisterNUICallback('previewWagon', function(data, cb)
    SpawnShowroomWagon(data.model, data.store)
    cb('ok')
end)

RegisterNUICallback('previewMyWagon', function(data, cb)
    currentWagonModel = data.model
    currentCustom = data.custom or {}
    SpawnShowroomMyWagon(data.model, currentStore, data.custom or {})
    cb('ok')
end)

RegisterNUICallback('buyWagon', function(data, cb)
    local moneyType = Config.MoneyType.money
    local model = data.model
    local name = data.name

    CloseShowroom()

    local customData = {
        name = name,
        tint = 0,
        livery = -1,
        props = false,
        extra = 0,
        buyMoneyType = moneyType,
    }
    TriggerServerEvent("rsg-wagons:saveWagonToDatabase", model, customData, moneyType)

    -- Close the menu on buy (server confirms via notify). Success overlay
    -- is skipped: it would pop over the game once the panel is hidden.
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getMyWagons', function(data, cb)
    lib.callback('rsg-wagons:checkMyWagons', false, function(wagons, custom)
        if not wagons or #wagons == 0 then
            SendNUIMessage({ action = 'showMyWagons', wagons = {}, customs = {} })
        else
            SendNUIMessage({ action = 'showMyWagons', wagons = wagons, customs = custom })
        end
    end)
    cb('ok')
end)

RegisterNUICallback('activateWagon', function(data, cb)
    CloseShowroom()
    TriggerServerEvent("rsg-wagons:toggleWagonActive", data.model, data.custom)
    cb('ok')
end)

RegisterNUICallback('sellWagon', function(data, cb)
    CloseShowroom()
    TriggerServerEvent("rsg-wagons:sellWagon", data.model, data.custom)
    cb('ok')
end)

RegisterNUICallback('getCustomOptions', function(data, cb)
    local type = data.type
    local model = data.model
    local custom = data.custom or {}
    currentWagonCustom = custom

    local options = {}

    if type == "livery" then
        options[#options + 1] = { label = "Remove", value = -1 }
        if Custom.livery and Custom.livery[model] then
            for _, v in ipairs(Custom.livery[model]) do
                options[#options + 1] = { label = v[2], value = v[1] }
            end
        end
    elseif type == "extra" then
        options[#options + 1] = { label = "Remove", value = -1 }
        if Custom.extra and Custom.extra[model] then
            for _, v in ipairs(Custom.extra[model]) do
                options[#options + 1] = { label = tostring(v), value = v }
            end
        end
    elseif type == "tint" then
        options[#options + 1] = { label = "Remove", value = -1 }
        local maxTints = (Custom.tint and Custom.tint[model]) or 0
        for i = 1, maxTints do
            options[#options + 1] = { label = tostring(i), value = i }
        end
    elseif type == "props" then
        options[#options + 1] = { label = "Remove", value = -1 }
        if Custom.props and Custom.props[model] then
            local ordered = {}
            for k, v in pairs(Custom.props[model]) do
                ordered[#ordered + 1] = { key = k, value = v }
            end
            table.sort(ordered, function(a, b) return tonumber(a.key) < tonumber(b.key) end)
            for _, prop in ipairs(ordered) do
                options[#options + 1] = { label = tostring(prop.key), value = prop.value }
            end
        end
    elseif type == "lantern" then
        options[#options + 1] = { label = "Remove", value = -1 }
        if Custom.lantern and Custom.lantern[model] then
            for key, val in pairs(Custom.lantern[model]) do
                options[#options + 1] = { label = tostring(key), value = val }
            end
        end
    end

    local price = Config.CustomPrice[type] or 0

    SendNUIMessage({
        action = 'showCustomOptions',
        type = type,
        options = options,
        price = price
    })
    cb('ok')
end)

RegisterNUICallback('previewCustom', function(data, cb)
    local type = data.type
    local value = data.value
    local currentShow = {}
    for k, v in pairs(currentWagonCustom or {}) do currentShow[k] = v end
    currentShow[type] = value
    SpawnShowroomMyWagon(currentWagonModel, currentStore, currentShow)
    cb('ok')
end)

RegisterNUICallback('resetPreview', function(data, cb)
    SpawnShowroomMyWagon(data.model, currentStore, data.custom or {})
    cb('ok')
end)

RegisterNUICallback('saveCustomization', function(data, cb)
    local type = data.type
    local value = data.value
    local model = data.model

    currentWagonCustom[type] = value
    SpawnShowroomMyWagon(model, currentStore, currentWagonCustom)
    TriggerServerEvent("rsg-wagons:saveCustomization", model, currentWagonCustom, type)
    cb('ok')
end)

RegisterNUICallback('rotateWagon', function(data, cb)
    RotatePreviewWagon(data.direction)
    cb('ok')
end)

RegisterNUICallback('closeShop', function(data, cb)
    CloseShowroom()
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNetEvent("rsg-wagons:stashPermission", function(info)
    TriggerServerEvent("rsg-wagons:getOwnerPermission", info)
end)

RegisterNetEvent('rsg-wagons:client:notify', function(type, title, message)
    lib.notify({ title = title, description = message, type = type })
end)

RegisterNetEvent('rsg-wagons:client:success', function(message)
    SendNUIMessage({ action = 'success', message = message })
end)
