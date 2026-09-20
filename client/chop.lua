

local ChopGroup = GetRandomIntInRange(0, 0xffffff)
local chopPrompt = nil
local chopBlips = {}

RSGWagonsChopBusy = false

local function ChopDebug(...)
    if Config.Chop and Config.Chop.Debug then
        print('[rsg-wagons:chop]', ...)
    end
end

local function GetChopLocations()
    local out = {}
    if not Config.Chop or not Config.Chop.Locations then return out end
    for _, loc in ipairs(Config.Chop.Locations) do
        if loc and loc.coords then
            out[#out + 1] = loc
        end
    end
    return out
end

local function CreateChopBlips()
    for _, blip in pairs(chopBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    chopBlips = {}
    if not Config.Chop or not Config.Chop.ChopBlip or not Config.Chop.ChopBlip.show then return end
    for _, loc in ipairs(GetChopLocations()) do
        if loc.blip ~= false then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, loc.coords.x, loc.coords.y, loc.coords.z)
            if blip and blip ~= 0 then
                SetBlipSprite(blip, Config.Chop.ChopBlip.sprite, true)
                local name = CreateVarString(10, 'LITERAL_STRING', loc.blipName or Config.Chop.ChopBlip.name or locale('cl_chop_blip'))
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, name)
                SetBlipScale(blip, Config.Chop.ChopBlip.scale or 0.8)
                chopBlips[#chopBlips + 1] = blip
            end
        end
    end
end

local function CreateChopPrompt()
    if chopPrompt then return end
    chopPrompt = Citizen.InvokeNative(0x04F97DE45A519419)
    PromptSetControlAction(chopPrompt, Config.Chop.PromptKey)
    PromptSetText(chopPrompt, CreateVarString(10, 'LITERAL_STRING', Config.Chop.PromptText or locale('cl_chop_prompt')))
    PromptSetEnabled(chopPrompt, true)
    PromptSetVisible(chopPrompt, true)
    PromptSetHoldMode(chopPrompt, true)
    PromptSetGroup(chopPrompt, ChopGroup)
    PromptRegisterEnd(chopPrompt)
end


local function IsWagonModel(modelHash)
    for _, wagonType in pairs(Config.Wagons) do
        for wagonModel in pairs(wagonType) do
            if GetHashKey(wagonModel) == modelHash then
                return wagonModel
            end
        end
    end
    return nil
end

local function GetNearbyChopWagon(coords, radius)
    local closest, closestDist, closestModel = nil, radius, nil
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            local modelName = IsWagonModel(GetEntityModel(vehicle))
            if modelName or Config.Chop.AllowUnknownWagons then
                local dist = #(coords - GetEntityCoords(vehicle))
                if dist < closestDist then
                    closest, closestDist, closestModel = vehicle, dist, (modelName or 'unknown_wagon')
                end
            end
        end
    end
    return closest, closestModel
end

local function GetDrivenChopWagon()
    local ped = cache.ped or PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle and vehicle ~= 0 and IsEntityAVehicle(vehicle) then
        local modelName = IsWagonModel(GetEntityModel(vehicle))
        if modelName or Config.Chop.AllowUnknownWagons then
            return vehicle, (modelName or 'unknown_wagon')
        end
    end
    return nil, nil
end

local function GetClosestChopLocation(playerCoords)
    local bestIndex, bestDist = nil, math.huge
    for i, loc in ipairs(GetChopLocations()) do
        local dist = #(playerCoords - loc.coords)
        if dist < bestDist then
            bestIndex, bestDist = i, dist
        end
    end
    return bestIndex, bestDist
end


local function DeleteChopDraftAnimals(wagon)
    if not wagon or wagon == 0 or not DoesEntityExist(wagon) then return end
    local count = Citizen.InvokeNative(0x635423D55CA84FC8, wagon)
    count = tonumber(count) or 0
    for i = count, 1, -1 do
        local animal = Citizen.InvokeNative(0x0A794A2989F18F3C, wagon, i)
        if animal and animal ~= 0 and DoesEntityExist(animal) then
            SetEntityAsMissionEntity(animal, true, true)
            DetachEntity(animal, true, true)
            ClearPedTasksImmediately(animal)
            DeletePed(animal)
            DeleteEntity(animal)
        end
    end
end

local function TryGetChopControl(entity, timeoutMs)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end
    if NetworkHasControlOfEntity(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local timeout = GetGameTimer() + (timeoutMs or 1500)
    while DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    end
    return NetworkHasControlOfEntity(entity)
end

local function ForceDeleteChopVehicle(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return true end
    TryGetChopControl(entity, 1500)
    SetEntityAsMissionEntity(entity, true, true)
    DeleteVehicle(entity)
    local attempts = 0
    while DoesEntityExist(entity) and attempts < 5 do
        Wait(150)
        TryGetChopControl(entity, 300)
        SetEntityAsMissionEntity(entity, true, true)
        DeleteVehicle(entity)
        attempts = attempts + 1
    end
    if DoesEntityExist(entity) then
        SetEntityVisible(entity, false, false)
        SetEntityCollision(entity, false, false, false)
        FreezeEntityPosition(entity, true)
        SetEntityCoords(entity, 0.0, 0.0, -1000.0, false, false, false, false)
        return false
    end
    return true
end


RegisterNetEvent('rsg-wagons:client:chopForceDelete', function(netId)
    local entity = nil
    local numericNetId = tonumber(netId)
    if numericNetId and numericNetId ~= 0 then
        entity = NetworkGetEntityFromNetworkId(numericNetId)
    end
    if not entity or entity == 0 or not DoesEntityExist(entity) then
       
        local ped = cache.ped or PlayerPedId()
        entity = GetNearbyChopWagon(GetEntityCoords(ped), Config.Chop.WagonSearchDistance)
    end
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteChopDraftAnimals(entity)
        ForceDeleteChopVehicle(entity)
    end
    if numericNetId and numericNetId ~= 0 then
        TriggerServerEvent('rsg-wagons:server:chopDeleteFallback', numericNetId)
    end
    RSGWagonsChopBusy = false
end)


local function OpenChopUI(netId, modelName, info)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openChop',
        netId = netId,
        modelName = modelName,
        displayName = info.displayName or modelName,
        rewards = info.rewardList or {},
        isRegistered = info.isRegistered or false,
    })
end

RegisterNUICallback('confirmChop', function(data, cb)
    cb('ok')
    if data and data.modelName then
        RSGWagonsChopBusy = true
        TriggerServerEvent('rsg-wagons:server:processChop', tonumber(data.netId) or 0, data.modelName)
    end
end)

local function TryOpenChopUI(wagon, modelName)
    if not wagon or wagon == 0 or not DoesEntityExist(wagon) then return end
    local netId = NetworkGetNetworkIdFromEntity(wagon)
    if not netId or netId == 0 then
        
        netId = 0
    end
    lib.callback('rsg-wagons:server:getChopInfo', false, function(result)
        if not result then return end
        if result.error then
            lib.notify({ title = locale('error'), description = result.message, type = 'error', duration = Config.Chop.NotifyDuration })
            return
        end
        OpenChopUI(netId, modelName, result)
    end, netId, modelName)
end

RegisterNetEvent('rsg-wagons:client:chopNotify', function(ntype, title, message)
    
    if ntype == 'error' then
        RSGWagonsChopBusy = false
    end
    lib.notify({ title = title, description = message, type = ntype, duration = Config.Chop.NotifyDuration })
end)

if Config.Chop and Config.Chop.Debug then
    RegisterCommand('chopdebug', function()
        local ped = cache.ped or PlayerPedId()
        local coords = GetEntityCoords(ped)
        print(('[chop] coords: vector3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z))
        local idx, dist = GetClosestChopLocation(coords)
        if idx then
            print(('[chop] nearest location distance %.2f (need <= %.2f)'):format(dist, Config.Chop.InteractDistance))
        else
            print('[chop] no chop locations configured - check Config.Chop.Locations.')
        end
        local wagon, model = GetNearbyChopWagon(coords, Config.Chop.WagonSearchDistance)
        print('[chop] nearby wagon: ' .. tostring(wagon) .. ' model: ' .. tostring(model))
        for i, loc in ipairs(GetChopLocations()) do
            print(('[chop] location %d "%s": vector3(%.2f, %.2f, %.2f)'):format(i, loc.name or '?', loc.coords.x, loc.coords.y, loc.coords.z))
        end
    end, false)
end

CreateThread(function()
    CreateChopBlips()
    CreateChopPrompt()
    ChopDebug('chop.lua started - ' .. GetCurrentResourceName())

    while true do
        local sleep = 1000
        local ped = cache.ped or PlayerPedId()

        if not RSGWagonsChopBusy and not IsNuiFocused() then
            local playerCoords = GetEntityCoords(ped)
            local _, locDist = GetClosestChopLocation(playerCoords)

            if locDist and locDist <= Config.Chop.InteractDistance then
                sleep = 0
                local groupLabel = CreateVarString(10, 'LITERAL_STRING', Config.Chop.PromptText or locale('cl_chop_prompt'))
                PromptSetActiveGroupThisFrame(ChopGroup, groupLabel)

                if PromptHasHoldModeCompleted(chopPrompt) then
                    PromptSetEnabled(chopPrompt, false)
                    local wagon, modelName = GetNearbyChopWagon(playerCoords, Config.Chop.WagonSearchDistance)
                    if not wagon then wagon, modelName = GetDrivenChopWagon() end
                    if wagon and modelName then
                        ChopDebug('prompt complete, wagon=' .. tostring(wagon) .. ' model=' .. tostring(modelName))
                        TryOpenChopUI(wagon, modelName)
                    else
                        ChopDebug('prompt complete, no wagon nearby')
                        lib.notify({ title = locale('cl_chop_title'), description = locale('cl_chop_no_wagon'), type = 'error', duration = Config.Chop.NotifyDuration })
                    end
                    Wait(1000)
                    PromptSetEnabled(chopPrompt, true)
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, blip in pairs(chopBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    chopBlips = {}
end)
