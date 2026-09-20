local RSGCore = exports['rsg-core']:GetCoreObject()

local wagonBlip, mywagon, wagonID, wagonNetId, wagonModel
local isNearWagon, isOwner, openMenu, cargo = false, false, false, false
local wagonVerificationCache, animalStorageCache = {}, {}
local StashPrompt, DeletePrompt, CarcassPrompt, StockCarcassPrompt
local WagonGroup = GetRandomIntInRange(0, 0xffffff)


local function CallWagon()
    if mywagon and DoesEntityExist(mywagon) then
        return lib.notify({
            title = locale("error"),
            description = locale("cl_have_wagon"),
            type = "error",
            duration = 7000
        })
    end

    if wagonBlip and DoesBlipExist(wagonBlip) then
        RemoveBlip(wagonBlip)
        wagonBlip = nil
    end

    TriggerServerEvent("rsg-wagons:getWagonDataByCitizenID")
end


RegisterNetEvent("rsg-wagons:client:dellwagon", function()
    DeleteWagon()
end)

RegisterNetEvent("rsg-wagons:client:callwagon", function()
    CallWagon()
end)

local function FindSafeSpawnCoords(baseCoords, attempts, radius, minDistance)
    attempts = attempts or 10
    radius = radius or Config.SpawnRadius or 10.0
    minDistance = minDistance or 5.0
    local players = GetActivePlayers()
    for i = 1, attempts do
        local angle = math.rad((360 / attempts) * i)
        local offsetX, offsetY = math.cos(angle) * radius, math.sin(angle) * radius
        local tryCoords = vec3(baseCoords.x + offsetX, baseCoords.y + offsetY, baseCoords.z)

        local isFar = true
        for _, playerId in ipairs(players) do
            if #(GetEntityCoords(GetPlayerPed(playerId)) - tryCoords) < minDistance then
                isFar = false
                break
            end
        end

        if isFar then
            local x, y, z = table.unpack(GetEntityCoords(cache.ped))
            local found, roadCoords = GetClosestVehicleNode(x - 15, y, z, 0, 3.0, 0.0)
            local _, _, nodeHeading = GetNthClosestVehicleNodeWithHeading(x - 15, y, z, 1, 1, 0, 0)
            if found then
                return found, roadCoords, nodeHeading
            end
        end
    end

    
    local pedCoords = GetEntityCoords(cache.ped)
    local fallbackDistance = Config.FallbackSpawnDistance or 10.0
    for i = 1, 8 do
        local angle = math.rad((360 / 8) * i)
        local offsetX, offsetY = math.cos(angle) * fallbackDistance, math.sin(angle) * fallbackDistance
        local tryCoords = vec3(pedCoords.x + offsetX, pedCoords.y + offsetY, pedCoords.z)

        local isFar = true
        for _, playerId in ipairs(players) do
            if #(GetEntityCoords(GetPlayerPed(playerId)) - tryCoords) < minDistance then
                isFar = false
                break
            end
        end

        if isFar then
            return true, tryCoords, GetEntityHeading(cache.ped)
        end
    end
    return nil
end

local function SpawnWagon(model, tint, livery, props, extra, lantern, myWagonID)
    local hash = joaat(model)
    if not lib.requestModel(hash, 10000) then
        return lib.notify({ title = locale("error"), description = locale("cl_no_road"), type = "error", duration = 7000 })
    end

    if IsPedInAnyVehicle(cache.ped, false) then
        DeleteVehicle(cache.vehicle)
    end

    local found, safeCoords, nodeHeading = FindSafeSpawnCoords(GetEntityCoords(cache.ped))
    if not safeCoords or not found then
        return lib.notify({ title = locale("error"), description = locale("cl_no_road"), type = "error", duration = 7000 })
    end

    mywagon = CreateVehicle(hash, safeCoords.x, safeCoords.y, safeCoords.z, nodeHeading, true, false)
    SetVehicleDirtLevel(mywagon, 0.0)

    Wait(100)
    Citizen.InvokeNative(0x75F90E4051CC084C, mywagon, 0)
    Citizen.InvokeNative(0xE31C0CB1C3186D40, mywagon)

    if props then
        Citizen.InvokeNative(0x75F90E4051CC084C, mywagon, GetHashKey(props))
        Citizen.InvokeNative(0x31F343383F19C987, mywagon, 0.5, 1)
    end
    if lantern then
        Citizen.InvokeNative(0xC0F0417A90402742, mywagon, GetHashKey(lantern))
    end

    Citizen.InvokeNative(0x8268B098F6FCA4E2, mywagon, tint)
    Citizen.InvokeNative(0xF89D82A0582E46ED, mywagon, livery or 0)

    Citizen.InvokeNative(0xAD738C3085FE7E11, mywagon, true, true)
    Citizen.InvokeNative(0x9617B6E5F65329A5, mywagon)

    for i = 0, 10 do
        if DoesExtraExist(mywagon, i) then
            Citizen.InvokeNative(0xBB6F89150BC9D16B, mywagon, i, true)
        end
    end
    if extra then
        Citizen.InvokeNative(0xBB6F89150BC9D16B, mywagon, extra, false)
    end

    if model == "huntercart01" then
        Citizen.InvokeNative(0x75F90E4051CC084C, mywagon, joaat('pg_mp005_huntingWagonTarp01'))
        Citizen.InvokeNative(0xC0F0417A90402742, mywagon, joaat('pg_teamster_cart06_lightupgrade3'))
        Citizen.InvokeNative(0x31F343383F19C987, mywagon, 0.5, 1)
    end

    NetworkRegisterEntityAsNetworked(mywagon)
    SetVehicleIsConsideredByPlayer(mywagon, true)
    Citizen.InvokeNative(0xBB5A3FA8ED3979C5, mywagon, true)

    local networkId = NetworkGetNetworkIdFromEntity(mywagon)
    while not NetworkDoesEntityExistWithNetworkId(networkId) do
        Wait(50)
    end

    getControlOfEntity(mywagon)

    TriggerServerEvent("rsg-wagons:registerWagon", networkId, myWagonID, model)

    local targetOptions = {
        {
            name = "wagonStash",
            icon = "fa-solid fa-box-open",
            label = locale("cl_wagon_stash"),
            onSelect = function(data)
                local wagon = data.entity
                local netId = NetworkGetNetworkIdFromEntity(wagon)
                local cached = wagonVerificationCache[netId]
                if cached then
                    TriggerServerEvent("rsg-wagons:openWagonStash", "Wagon_Stash_" .. cached.id, cached.model, cached.id, netId)
                else
                    lib.callback('rsg-wagons:isWagonRegistered', false, function(isRegistered, owner, id, model)
                        if isRegistered then
                            wagonVerificationCache[netId] = { owner = owner, id = id, model = model }
                            TriggerServerEvent("rsg-wagons:openWagonStash", "Wagon_Stash_" .. id, model, id, netId)
                        else
                            lib.notify({ title = "Error", description = "Wagon not registered", type = "error", duration = 5000 })
                        end
                    end, netId)
                end
            end,
            distance = 1.5,
        },
        {
            name = "wagonDelete",
            icon = "fa-solid fa-warehouse",
            label = locale("cl_flee_wagon"),
            onSelect = function(data)
                local wagon = data.entity
                local netId = NetworkGetNetworkIdFromEntity(wagon)
                local cached = wagonVerificationCache[netId]
                if not cached then
                    lib.callback('rsg-wagons:isWagonRegistered', false, function(isRegistered, owner, id, model)
                        if isRegistered then wagonVerificationCache[netId] = { owner = owner, id = id, model = model } end
                    end, netId)
                    return
                end
                if not cached.owner then
                    lib.notify({ title = locale("error"), description = locale("no_permission"), type = "error", duration = 7000 })
                    return
                end
                mywagon = wagon
                wagonID = cached.id
                wagonNetId = netId
                wagonModel = cached.model
                DeleteWagon()
            end,
            distance = 1.5,
        },
    }
    if model == "huntercart01" then
        targetOptions[#targetOptions + 1] = {
            name = "wagonShowCarcass",
            icon = "fa-solid fa-boxes-stacked",
            label = locale("cl_see_carcass"),
            onSelect = function(data)
                local wagon = data.entity
                local netId = NetworkGetNetworkIdFromEntity(wagon)
                local cached = wagonVerificationCache[netId]
                if not cached then
                    lib.callback('rsg-wagons:isWagonRegistered', false, function(isRegistered, owner, id, model)
                        if isRegistered then wagonVerificationCache[netId] = { owner = owner, id = id, model = model } end
                    end, netId)
                    return
                end
                if not cached.owner then
                    lib.notify({ title = locale("error"), description = locale("no_permission"), type = "error", duration = 7000 })
                    return
                end
                ensureAnimalCapacityCached(netId, cached.model)
                local maxAnimal = animalStorageCache[netId] or 0
                if maxAnimal > 0 then
                    wagonID = cached.id
                    wagonModel = cached.model
                    CarcassInWagon(cached.id)
                else
                    lib.notify({ title = locale("error"), description = locale("no_animals_in_wagon"), type = "error", duration = 7000 })
                end
            end,
            distance = 1.5,
        }
        targetOptions[#targetOptions + 1] = {
            name = "wagonStockCarcass",
            icon = "fa-solid fa-paw",
            label = locale("cl_stock_carcass"),
            onSelect = function(data)
                local wagon = data.entity
                local netId = NetworkGetNetworkIdFromEntity(wagon)
                local cached = wagonVerificationCache[netId]
                if not cached then
                    lib.callback('rsg-wagons:isWagonRegistered', false, function(isRegistered, owner, id, model)
                        if isRegistered then wagonVerificationCache[netId] = { owner = owner, id = id, model = model } end
                    end, netId)
                    return
                end
                ensureAnimalCapacityCached(netId, cached.model)
                local maxAnimal = animalStorageCache[netId] or 0
                if maxAnimal > 0 then
                    wagonID = cached.id
                    wagonNetId = netId
                    wagonModel = cached.model
                    StoreCarriedEntityInWagon()
                else
                    lib.notify({ title = locale("error"), description = locale("no_animals_in_wagon"), type = "error", duration = 7000 })
                end
            end,
            distance = 1.5,
        }
    end
    if Config.Target then
        exports.ox_target:addLocalEntity(mywagon, targetOptions)
    end

    local blipModel = GetHashKey("blip_player_coach")
    wagonBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, mywagon)
    SetBlipSprite(wagonBlip, blipModel, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, wagonBlip, locale("cl_your_wagon"))

    if model == "huntercart01" then
        UpdateHuntingTarp()
    end
end

function UpdateHuntingTarp()
    if not mywagon then return end
    lib.callback('rsg-wagons:getAnimalStorage', false, function(menuData)
        local count = 0
        for _, v in pairs(menuData or {}) do
            count += (v.infos.quantity or 1)
        end
        local maxAnimal = animalStorageCache[wagonNetId] or 20
        local percentage = count / maxAnimal
        Citizen.InvokeNative(0x31F343383F19C987, mywagon, percentage, 1)
    end, wagonID)
end



function getControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000
    while timeout > 0 and not NetworkHasControlOfEntity(entity) do
        Wait(100)
        timeout -= 100
    end
    return NetworkHasControlOfEntity(entity)
end

local function EnumerateVehicles(callback)
    local handle, vehicle = FindFirstVehicle()
    local success
    repeat
        if DoesEntityExist(vehicle) then
            callback(vehicle)
        end
        success, vehicle = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
end

local function IsThisModelAWagon(model)
    for _, wagonType in pairs(Config.Wagons) do
        for wagonModel in pairs(wagonType) do
            if GetHashKey(wagonModel) == model then
                return true
            end
        end
    end
    return false
end


local function GetClosestWagon(callback)
    local pedCoords = GetEntityCoords(cache.ped)
    local closestWagon, closestDist, networkId
    local maxDist = 2.0

    EnumerateVehicles(function(vehicle)
        if IsThisModelAWagon(GetEntityModel(vehicle)) then
            local dist = #(pedCoords - GetEntityCoords(vehicle))
            if dist <= maxDist then
                closestWagon = vehicle
                closestDist = dist
                networkId = NetworkGetNetworkIdFromEntity(vehicle)
                maxDist = dist
            end
        end
    end)

    if not closestWagon or not networkId then
        return callback(nil, nil, nil, nil, nil, nil)
    end

    local cached = wagonVerificationCache[networkId]
    if cached then
        return callback(closestWagon, closestDist, cached.owner, cached.id, cached.model, networkId)
    end

    lib.callback('rsg-wagons:isWagonRegistered', false, function(isRegistered, owner, id, model, netId)
        if isRegistered then
            wagonVerificationCache[netId] = { owner = owner, id = id, model = model }
            callback(closestWagon, closestDist, owner, id, model, netId)
        else
            callback(closestWagon, closestDist, nil, nil, nil, networkId)
        end
    end, networkId)
end


function ensureAnimalCapacityCached(netId, model)
    if animalStorageCache[netId] ~= nil then return end
    for _, modelos in pairs(Config.Wagons) do
        if modelos[model] then
            animalStorageCache[netId] = modelos[model].maxAnimals or 0
            return
        end
    end
    animalStorageCache[netId] = 0
end

function StashWagon()
    GetClosestWagon(function(wagon, _, owner, id, model, netId)
        if not wagon or not id then return end
        isOwner, wagonID, wagonModel, wagonNetId = owner, id, model, netId
        ensureAnimalCapacityCached(netId, wagonModel)
        TriggerServerEvent("rsg-wagons:openWagonStash", "Wagon_Stash_" .. wagonID, wagonModel, wagonID, wagonNetId)
    end)
end

function ShowCarcass()
    GetClosestWagon(function(wagon, _, owner, id, model, netId)
        if not wagon or not id then return end
        isOwner, wagonID, wagonModel, wagonNetId = owner, id, model, netId
        ensureAnimalCapacityCached(netId, wagonModel)

        if isOwner then
            local maxAnimal = animalStorageCache[wagonNetId] or 0
            if maxAnimal > 0 then
                CarcassInWagon(wagonID)
            else
                lib.notify({ title = locale("error"), description = locale("no_animals_in_wagon"), type = "error", duration = 7000 })
            end
        else
            lib.notify({ title = locale("error"), description = locale("no_permission"), type = "error", duration = 7000 })
        end
    end)
end

function StockCarcass()
    GetClosestWagon(function(wagon, _, owner, id, model, netId)
        if not wagon or not id then return end
        isOwner, wagonID, wagonModel, wagonNetId = owner, id, model, netId
        ensureAnimalCapacityCached(netId, wagonModel)

        local maxAnimal = animalStorageCache[wagonNetId] or 0
        if maxAnimal > 0 then
            StoreCarriedEntityInWagon()
        else
            lib.notify({ title = locale("error"), description = locale("no_animals_in_wagon"), type = "error", duration = 7000 })
        end
    end)
end

function DeleteThisWagon()
    GetClosestWagon(function(wagon, _, owner, id, model, netId)
        if not wagon or not id then return end
        isOwner, wagonID, wagonModel, wagonNetId = owner, id, model, netId
        ensureAnimalCapacityCached(netId, wagonModel)

        if isOwner then
            DeleteWagon()
        else
            lib.notify({ title = locale("error"), description = locale("no_permission"), type = "error", duration = 7000 })
        end
    end)
end

if not Config.Target then
    CreateThread(function()
        while true do
            GetClosestWagon(function(wagon, _, owner, id, model, netId)
                if wagon and id then
                    isNearWagon, isOwner, wagonID, wagonModel, wagonNetId = true, owner, id, model, netId
                    ensureAnimalCapacityCached(netId, model)
                else
                    isNearWagon = false
                end
            end)
            Wait(500)
        end
    end)
end

local stashPromptHandle
local deletePromptHandle
local carcassPromptHandle
local stockCarcassPromptHandle

local function createPrompt(labelKey, control, group)
    local prompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(prompt, GetHashKey(control))
    PromptSetText(prompt, CreateVarString(10, "LITERAL_STRING", locale(labelKey)))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    PromptSetHoldMode(prompt, true)
    PromptSetGroup(prompt, group)
    PromptRegisterEnd(prompt)
    return prompt
end

function StashPrompt()
    stashPromptHandle = createPrompt("cl_wagon_stash", "INPUT_JUMP", WagonGroup)          -- Spacebar
end

function DeletePrompt()
    deletePromptHandle = createPrompt("cl_flee_wagon", "INPUT_FRONTEND_CANCEL", WagonGroup) -- Escape
end

function CarcassPrompt()
    carcassPromptHandle = createPrompt("cl_see_carcass", "INPUT_DOCUMENT_PAGE_PREV", WagonGroup) -- Q
end

function StockCarcassPrompt()
    stockCarcassPromptHandle = createPrompt("cl_stock_carcass", "INPUT_DOCUMENT_PAGE_NEXT", WagonGroup) -- E (scroll context)
end

if not Config.Target then
    CreateThread(function()
        StashPrompt()
        DeletePrompt()
        CarcassPrompt()
        StockCarcassPrompt()

        while true do
            local waitTime = 2000
            local pedInVehicle = IsPedInAnyVehicle(cache.ped, false)
            local maxAnimal = wagonNetId and animalStorageCache[wagonNetId] or 0

            if isNearWagon and not pedInVehicle and not openMenu then
                waitTime = 2
                local groupLabel = CreateVarString(10, "LITERAL_STRING", locale("cl_your_wagon"))
                PromptSetActiveGroupThisFrame(WagonGroup, groupLabel)

                if isOwner then
                    PromptSetEnabled(carcassPromptHandle, false)
                    PromptSetVisible(carcassPromptHandle, false)
                    PromptSetEnabled(stockCarcassPromptHandle, false)
                    PromptSetVisible(stockCarcassPromptHandle, false)

                    if PromptHasHoldModeCompleted(stashPromptHandle) then
                        PromptSetEnabled(stashPromptHandle, false)
                        PromptSetVisible(stashPromptHandle, false)
                        TriggerServerEvent("rsg-wagons:openWagonStash", "Wagon_Stash_" .. wagonID, wagonModel, wagonID,
                            wagonNetId)
                        Wait(500)
                        PromptSetEnabled(stashPromptHandle, true)
                        PromptSetVisible(stashPromptHandle, true)
                    elseif PromptHasHoldModeCompleted(deletePromptHandle) then
                        PromptSetEnabled(deletePromptHandle, false)
                        PromptSetVisible(deletePromptHandle, false)
                        DeleteWagon()
                        Wait(500)
                        PromptSetEnabled(deletePromptHandle, true)
                        PromptSetVisible(deletePromptHandle, true)
                    elseif maxAnimal > 0 then
                        PromptSetEnabled(carcassPromptHandle, true)
                        PromptSetVisible(carcassPromptHandle, true)
                        PromptSetEnabled(stockCarcassPromptHandle, true)
                        PromptSetVisible(stockCarcassPromptHandle, true)

                        if PromptHasHoldModeCompleted(carcassPromptHandle) then
                            PromptSetEnabled(carcassPromptHandle, false)
                            PromptSetVisible(carcassPromptHandle, false)
                            CarcassInWagon(wagonID)
                            openMenu = true
                            Wait(1000)
                            PromptSetEnabled(carcassPromptHandle, true)
                            PromptSetVisible(carcassPromptHandle, true)
                        elseif PromptHasHoldModeCompleted(stockCarcassPromptHandle) then
                            PromptSetEnabled(stockCarcassPromptHandle, false)
                            PromptSetVisible(stockCarcassPromptHandle, false)
                            StoreCarriedEntityInWagon()
                            Wait(1000)
                            PromptSetEnabled(stockCarcassPromptHandle, true)
                            PromptSetVisible(stockCarcassPromptHandle, true)
                        end
                    end
                else
                    PromptSetEnabled(deletePromptHandle, false)
                    PromptSetVisible(deletePromptHandle, false)

                    if PromptHasHoldModeCompleted(stashPromptHandle) then
                        PromptSetEnabled(stashPromptHandle, false)
                        PromptSetVisible(stashPromptHandle, false)
                        TriggerServerEvent("rsg-wagons:openWagonStash", "Wagon_Stash_" .. wagonID, wagonModel, wagonID,
                            wagonNetId)
                        Wait(500)
                        PromptSetEnabled(stashPromptHandle, true)
                        PromptSetVisible(stashPromptHandle, true)
                    end

                    if maxAnimal > 0 then
                        PromptSetEnabled(stockCarcassPromptHandle, true)
                        PromptSetVisible(stockCarcassPromptHandle, true)
                        if PromptHasHoldModeCompleted(stockCarcassPromptHandle) then
                            PromptSetEnabled(stockCarcassPromptHandle, false)
                            PromptSetVisible(stockCarcassPromptHandle, false)
                            StoreCarriedEntityInWagon()
                            Wait(1000)
                            PromptSetEnabled(stockCarcassPromptHandle, true)
                            PromptSetVisible(stockCarcassPromptHandle, true)
                        end
                    else
                        PromptSetEnabled(stockCarcassPromptHandle, false)
                        PromptSetVisible(stockCarcassPromptHandle, false)
                    end
                end
            end
            Wait(waitTime)
        end
    end)
end



RegisterNetEvent("btc-wagon:askOwnerPermission", function(data)
    local alert = lib.alertDialog({
        header = locale("alert"),
        content = locale("player_stash") .. data.firstname .. " " .. data.lastname .. locale("player_stash_02"),
        centered = true,
        cancel = true
    })
    TriggerServerEvent("rsg-wagons:giveOwnerPermission", alert, data)
end)


RegisterNetEvent("rsg-wagons:receiveWagonData", function(wModel, customData, animalsData, myWagonID)
    if mywagon and DoesEntityExist(mywagon) then
        DeleteWagon()
        Wait(500)
    end

    if wagonBlip and DoesBlipExist(wagonBlip) then
        RemoveBlip(wagonBlip)
        wagonBlip = nil
    end

    if not wModel then
        return lib.notify({
            title = locale("error"),
            description = locale("cl_no_wagon"),
            type = "error",
            duration = 7000
        })
    end

    SpawnWagon(
        wModel,
        customData.tint,
        customData.livery,
        customData.props,
        customData.extra,
        customData.lantern,
        myWagonID
    )
end)


RegisterNetEvent("rsg-wagons:saveWagonToDatabase", function(wagonModel, name, moneyType)
    local customData = {
        name = name,
        tint = 0,
        livery = -1,
        props = false,
        extra = 0,
        buyMoneyType = moneyType,
    }
    TriggerServerEvent("rsg-wagons:saveWagonToDatabase", wagonModel, customData, moneyType)
end)


-- Verified delete: requests control, retries, and ALWAYS clears local
-- state (even when the entity is already gone) so a "deleted" wagon
-- can never linger in the world and duplicate the next spawn.
function DeleteWagon(netId)
    -- Resolve the entity: live handle first, netId lookup as fallback.
    local entity = nil
    if mywagon and DoesEntityExist(mywagon) then
        entity = mywagon
    elseif netId and tonumber(netId) and tonumber(netId) ~= 0 then
        local resolved = NetworkGetEntityFromNetworkId(tonumber(netId))
        if resolved and resolved ~= 0 and DoesEntityExist(resolved) then
            entity = resolved
        end
    end

    local resolvedNetId = nil
    if entity then
        resolvedNetId = NetworkGetNetworkIdFromEntity(entity)
        if Config.Target then exports.ox_target:removeEntity(entity) end
        TriggerServerEvent("rsg-wagons:removeWagon", resolvedNetId, entity)
        getControlOfEntity(entity)
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
        local attempts = 0
        while DoesEntityExist(entity) and attempts < 5 do
            Wait(150)
            getControlOfEntity(entity)
            SetEntityAsMissionEntity(entity, true, true)
            DeleteVehicle(entity)
            attempts = attempts + 1
        end
        if DoesEntityExist(entity) then
            -- Could not free it: hide/relocate so it never duplicates.
            SetEntityVisible(entity, false, false)
            SetEntityCollision(entity, false, false, false)
            FreezeEntityPosition(entity, true)
            SetEntityCoords(entity, 0.0, 0.0, -1000.0, false, false, false, false)
        end
    elseif netId and tonumber(netId) and tonumber(netId) ~= 0 then
        -- Entity already gone locally: still tell the server so the
        -- registry can't linger.
        TriggerServerEvent("rsg-wagons:removeWagon", tonumber(netId), 0)
    end

    -- Always clear local state, even when there was nothing to delete.
    mywagon = nil
    wagonID = nil
    wagonNetId = nil
    wagonModel = nil
    if wagonBlip and DoesBlipExist(wagonBlip) then
        RemoveBlip(wagonBlip)
        wagonBlip = nil
    end
    for cacheNetId in pairs(animalStorageCache) do
        animalStorageCache[cacheNetId] = nil
    end
    if resolvedNetId then wagonVerificationCache[resolvedNetId] = nil end
    if netId and tonumber(netId) then wagonVerificationCache[tonumber(netId)] = nil end
end

-- Chop shop integration: owner-side delete. The owner has network
-- control of its wagon, so deleting here removes reliably where a
-- chopper-side delete would silently fail. Not ox_target related.
RegisterNetEvent("rsg-wagons:client:chopDeleteOwnedWagon", function(netId)
    if RSGWagonsChopBusy ~= nil then RSGWagonsChopBusy = false end
    DeleteWagon(netId)
end)

if Config.SpawnKey then
    CreateThread(function()
        while true do
            local sleep = 250
            if IsControlJustReleased(0, GetHashKey(Config.SpawnKey)) then
                CallWagon()
            end
            if mywagon and DoesEntityExist(mywagon) then
                sleep = 1000
            end
            Wait(sleep)
        end
    end)
end

if Config.usecommand then
    RegisterCommand("callwagon", function()
        CallWagon()
    end, false)
end



local function GetFirstEntityPedIsCarrying(ped)
    return Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
end
local function GetMetaPedAssetTint(ped, index)
    return Citizen.InvokeNative(0xE7998FEC53A33BBE, ped, index, Citizen.PointerValueInt(), Citizen.PointerValueInt(),
        Citizen.PointerValueInt(), Citizen.PointerValueInt())
end
local function GetMetaPedAssetGuids(ped, index)
    return Citizen.InvokeNative(0xA9C28516A6DC9D56, ped, index, Citizen.PointerValueInt(), Citizen.PointerValueInt(),
        Citizen.PointerValueInt(), Citizen.PointerValueInt())
end
local function GetNumComponentsInPed(ped)
    return Citizen.InvokeNative(0x90403E8107B60E81, ped, Citizen.ResultAsInteger())
end
local function GetIsCarriablePelt(entity)
    return Citizen.InvokeNative(0x255B6DB4E3AD3C3E, entity)
end
local function GetCarriableFromEntity(entity)
    return Citizen.InvokeNative(0x31FEF6A20F00B963, entity)
end
local function GetCarcassMetaTag(entity)
    local metatag, numComponents = {}, GetNumComponentsInPed(entity)
    for i = 0, numComponents - 1 do
        local drawable, albedo, normal, material = GetMetaPedAssetGuids(entity, i)
        local palette, tint0, tint1, tint2 = GetMetaPedAssetTint(entity, i)
        metatag[i] = {
            drawable = drawable,
            albedo = albedo,
            normal = normal,
            material = material,
            palette = palette,
            tint0 = tint0,
            tint1 = tint1,
            tint2 = tint2
        }
    end
    return metatag
end
local function UpdatePedVariation(ped)
    Citizen.InvokeNative(0xAAB86462966168CE, ped, true)
    Citizen.InvokeNative(0xCC8CA3E88256E58F, ped, false, true, true, true, false)
end
local function SetMetaPedTag(ped, drawable, albedo, normal, material, palette, tint0, tint1, tint2)
    return Citizen.InvokeNative(0xBC6DF00D7A4A6819, ped, drawable, albedo, normal, material, palette, tint0, tint1, tint2)
end
local function GetPedMetaOutfitHash(ped)
    return Citizen.InvokeNative(0x30569F348D126A5A, ped, Citizen.ResultAsInteger())
end
local function IsEntityFullyLooted(entity)
    return Citizen.InvokeNative(0x8DE41E9902E85756, entity)
end
local function GetPedDamageCleanliness(ped)
    return Citizen.InvokeNative(0x88EFFED5FE8B0B4A, ped, Citizen.ResultAsInteger())
end
local function EquipMetaPedOutfit(ped, hash)
    return Citizen.InvokeNative(0x1902C4CFCC5BE57C, ped, hash)
end
local function ApplyCarcasMetaTag(entity, metatag)
    if type(metatag) ~= "table" then return end
    for _, data in pairs(metatag) do
        if data then
            SetMetaPedTag(entity, data.drawable, data.albedo, data.normal, data.material, data.palette,
                data.tint0, data.tint1, data.tint2)
        end
    end
    UpdatePedVariation(entity)
end
local function SetPedDamageCleanliness(ped, damageCleanliness)
    return Citizen.InvokeNative(0x7528720101A807A5, ped, damageCleanliness)
end
local function GetPedQuality(ped)
    return Citizen.InvokeNative(0x7BCC6087D130312A, ped)
end
local function SetPedQuality(ped, quality)
    return Citizen.InvokeNative(0xCE6B874286D640BB, ped, quality)
end
local function TaskStatus(task)
    local count = 0
    repeat
        count += 1
        Wait(0)
    until (GetScriptTaskStatus(cache.ped, task, true) == 8) or count > 100
end


function StoreCarriedEntityInWagon()
    lib.callback('rsg-wagons:getAnimalStorage', false, function(menuData)
        local carriedEntity = GetFirstEntityPedIsCarrying(cache.ped)
        if not carriedEntity or not DoesEntityExist(carriedEntity) then
            return lib.notify({
                title = locale("error"),
                description = locale("carry_nothing"),
                type = "error",
                duration = 7000
            })
        end

        local totalStored = 0
        for _, v in pairs(menuData) do
            totalStored += (v.infos.quantity or 1)
        end

        local maxAnimal = animalStorageCache[wagonNetId] or 0
        if totalStored >= maxAnimal then
            return lib.notify({
                title = locale("error"),
                description = locale("wagon_full"),
                type = "error",
                duration = 7000
            })
        end

        local data = { model = GetEntityModel(carriedEntity) }

        if GetIsCarriablePelt(carriedEntity) then
            data.type = "pelt"
            data.peltquality = GetCarriableFromEntity(carriedEntity)
        else
            if not Config.AnimalsStorage[data.model] then
                return lib.notify({
                    title = locale("error"),
                    description = locale("carry_nothing"),
                    type = "error",
                    duration = 7000
                })
            end
            data.type = "animal"
            data.metatag = GetCarcassMetaTag(carriedEntity)
            data.outfit = GetPedMetaOutfitHash(carriedEntity)
            data.skinned = IsEntityFullyLooted(carriedEntity) or false
            data.damage = GetPedDamageCleanliness(carriedEntity) or 0
            data.quality = GetPedQuality(carriedEntity) or 0
        end

        TriggerServerEvent("rsg-wagons:storeAnimalInWagon", wagonID, data)
        DeleteEntity(carriedEntity)

        if wagonModel == "huntercart01" then
            UpdateHuntingTarp()
        end
    end, wagonID)
end

function CarcassInWagon(wagonID)
    local carcassInWagon = {}
    lib.callback('rsg-wagons:getAnimalStorage', false, function(menuData)
        if not menuData or #menuData == 0 then
            openMenu = false
            return lib.notify({
                title = locale("error"),
                description = locale("wagon_no_animals"),
                type = "error",
                duration = 7000
            })
        end

        for _, v in pairs(menuData) do
            carcassInWagon[#carcassInWagon + 1] = {
                label       = v.label,
                value       = v.infos.type,
                infos       = v.infos,
                description = locale("animal_desc") .. v.infos.quantity .. " " .. v.label .. locale("animal_desc2"),
                onSelect    = function()
                    TriggerServerEvent("rsg-wagons:removeAnimalFromWagon", wagonID, v.infos, v.label)
                    openMenu = false
                    if wagonModel == "huntercart01" then
                        UpdateHuntingTarp()
                    end
                end
            }
        end

        lib.registerContext({
            id = 'mycarcass_menu',
            title = locale("animals_in_wagon"),
            options = carcassInWagon,
            onExit = function()
                openMenu = false
            end,
        })
        lib.showContext('mycarcass_menu')
    end, wagonID)
end

RegisterNetEvent("rsg-wagons:spawnAnimal", function(data)
    local coords = GetEntityCoords(cache.ped)
    if not lib.requestModel(data.model, 10000) then return end

    local cargo
    if IsModelAPed(data.model) then
        cargo = CreatePed(data.model, coords.x, coords.y, coords.z, 0.0, true, true)
        SetEntityHealth(cargo, 0, cache.ped)
        SetPedQuality(cargo, data.quality or 0)
        SetPedDamageCleanliness(cargo, data.damage or 0)

        if data.skinned then
            Wait(1000)
            Citizen.InvokeNative(0x6BCF5F3D8FFE988D, cargo, true)
            ApplyCarcasMetaTag(cargo, data.metatag)
        else
            EquipMetaPedOutfit(cargo, data.outfit)
            UpdatePedVariation(cargo)
        end
    else
        cargo = CreateObject(data.model, coords.x, coords.y, coords.z, true, true, true)
        Citizen.InvokeNative(0x78B4567E18B54480, cargo)
        Citizen.InvokeNative(0xF0B4F759F35CC7F5, cargo, Citizen.InvokeNative(0x34F008A7E48C496B, cargo, 0), cache.ped, 7,
            512)
        Citizen.InvokeNative(0x399657ED871B3A6C, cargo, data.peltquality or 0)
    end

    Citizen.InvokeNative(0x18FF3110CF47115D, cargo, 21, true)
    SetEntityVisible(cargo, false)
    FreezeEntityPosition(cargo, true)

    TaskPickupCarriableEntity(cache.ped, cargo)
    TaskStatus(`SCRIPT_TASK_PICKUP_CARRIABLE_ENTITY`)
    Wait(500)

    FreezeEntityPosition(cargo, false)
    SetEntityVisible(cargo, true)
    Citizen.InvokeNative(0x18FF3110CF47115D, cargo, 21, false)

    SetModelAsNoLongerNeeded(data.model)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if mywagon and DoesEntityExist(mywagon) then
        local netId = NetworkGetNetworkIdFromEntity(mywagon)
        if Config.Target then exports.ox_target:removeEntity(mywagon) end
        TriggerServerEvent("rsg-wagons:removeWagon", netId, mywagon)
        mywagon = nil
        if wagonBlip and DoesBlipExist(wagonBlip) then
            RemoveBlip(wagonBlip)
            wagonBlip = nil
        end
        if wagonNetId and animalStorageCache[wagonNetId] then
            animalStorageCache[wagonNetId] = nil
        end
        if netId then
            wagonVerificationCache[netId] = nil
        end
    end
end)
