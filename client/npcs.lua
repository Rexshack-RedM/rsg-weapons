local spawnedPeds = {}

local function fadeOutAndDeletePed(ped)
    if not DoesEntityExist(ped) then return end
    CreateThread(function()
        for i = 255, 0, -51 do
            Wait(50)
            SetEntityAlpha(ped, i, false)
        end
        SetEntityAsMissionEntity(ped, true, true)
        DeletePed(ped)
    end)
end

local function spawnStorePed(npcModel, coords, storeId)
    if not lib.requestModel(npcModel, 5000) then return nil end
    local ped = CreatePed(npcModel, coords.x, coords.y, coords.z - 1.0, coords.w, false, false, 0, 0)
    SetEntityAlpha(ped, 0, false)
    SetRandomOutfitVariation(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)

    -- Fade in
    CreateThread(function()
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(ped, i, false)
        end
    end)

    if Config.Target then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = "npc_wagonStore",
                icon = "far fa-eye",
                label = locale("cl_wagon_store"),
                onSelect = function()
                    TriggerEvent("rsg-wagons:client:openStore", storeId)
                end,
                distance = 2.0
            }
        })
    end

    SetModelAsNoLongerNeeded(npcModel)
    return ped
end


for storeId, store in pairs(Config.Stores) do
    local point = lib.points.new({
        coords = store.npccoords.xyz,
        distance = 50.0,
        onEnter = function()
            spawnedPeds[storeId] = { spawnedPed = spawnStorePed(store.npcmodel, store.npccoords, storeId) }
        end,
        onExit = function()
            if spawnedPeds[storeId] then
                fadeOutAndDeletePed(spawnedPeds[storeId].spawnedPed)
                if Config.Target then
                    exports.ox_target:removeEntity(spawnedPeds[storeId].spawnedPed, "npc_wagonStore")
                end
                spawnedPeds[storeId] = nil
            end
        end
    })
end


AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(spawnedPeds) do
        if DoesEntityExist(v.spawnedPed) then
            DeletePed(v.spawnedPed)
            if Config.Target then
                exports.ox_target:removeEntity(v.spawnedPed, "npc_wagonStore")
            end
        end
    end
end)
