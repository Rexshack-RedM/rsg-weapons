local showroomWagon, showroomCam
local rotationSpeed = 1.0
local isSpawningWagon = false
local showroomRenderActive = false
local rotatePromptGroup, rotateLeftPrompt, rotateRightPrompt
local inputLeft = GetHashKey("INPUT_DIVE")
local inputRight = GetHashKey("INPUT_LOOT_VEHICLE")


CreateThread(function()
    for k, v in pairs(Config.Stores) do
        if not Config.Target then
            exports['rsg-core']:createPrompt(
                "wagonStore" .. k,
                v.coords,
                GetHashKey(Config.Keys.OpenStore),
                Config.Blip.blipName,
                { type = "client", event = "rsg-wagons:client:openStore", args = { k } }
            )
        end

        if Config.Blip.showBlip then
            local blip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(blip, -1747775003, true)
            SetBlipScale(blip, 0.2)
            SetBlipName(blip, Config.Blip.blipName)
        end
    end
end)


-- Verified showroom delete: plain DeleteEntity on a non-mission entity
-- can silently fail, leaking a second preview wagon on every switch.
local function DeleteShowroomWagon()
    if not showroomWagon then return end
    local wagon = showroomWagon
    showroomWagon = nil
    if not DoesEntityExist(wagon) then return end
    SetEntityAsMissionEntity(wagon, true, true)
    DeleteEntity(wagon)
    local t = 0
    while DoesEntityExist(wagon) and t < 2000 do
        Wait(10)
        t += 10
    end
    if DoesEntityExist(wagon) then
        DeleteEntity(wagon)
        Wait(100)
    end
    if DoesEntityExist(wagon) then
        -- Last resort: hide it so it never haunts the showroom
        SetEntityVisible(wagon, false, false)
        SetEntityCollision(wagon, false, false, false)
        SetEntityCoords(wagon, 0.0, 0.0, -1000.0, false, false, false, false)
    end
end

function SpawnShowroomWagon(model, store)
    if isSpawningWagon then return end
    isSpawningWagon = true

    local coords = Config.Stores[store].previewWagon
    local camCoords = Config.Stores[store].cameraPreviewWagon

    DeleteShowroomWagon()

    if not lib.requestModel(model, 5000) then
        isSpawningWagon = false
        return
    end

    showroomWagon = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetEntityAsMissionEntity(showroomWagon, true, true)
    Citizen.InvokeNative(0x75F90E4051CC084C, showroomWagon, 0)
    Citizen.InvokeNative(0x8268B098F6FCA4E2, showroomWagon, 0)
    Citizen.InvokeNative(0xF89D82A0582E46ED, showroomWagon, -1)

    for i = 0, 10 do
        if DoesExtraExist(showroomWagon, i) then
            Citizen.InvokeNative(0xBB6F89150BC9D16B, showroomWagon, i, true)
        end
    end

    SetEntityInvincible(showroomWagon, true)
    FreezeEntityPosition(showroomWagon, true)

    SetUpShowroomCamera(camCoords, showroomWagon)
    SetModelAsNoLongerNeeded(model)

    Wait(250)
    isSpawningWagon = false
end


function SpawnShowroomMyWagon(model, store, custom)
    if isSpawningWagon then return end
    isSpawningWagon = true

    local coords = Config.Stores[store].previewWagon
    local camCoords = Config.Stores[store].cameraPreviewWagon

    if showroomWagon and DoesEntityExist(showroomWagon) then
        local currentModel = GetEntityModel(showroomWagon)
        if currentModel == GetHashKey(model) then
            UpdateShowroomWagonVisuals(showroomWagon, custom)
            isSpawningWagon = false
            return
        end
    end
    DeleteShowroomWagon()

    if not lib.requestModel(model, 5000) then
        isSpawningWagon = false
        return
    end

    showroomWagon = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetEntityAsMissionEntity(showroomWagon, true, true)
    UpdateShowroomWagonVisuals(showroomWagon, custom)

    SetEntityInvincible(showroomWagon, true)
    FreezeEntityPosition(showroomWagon, true)

    SetUpShowroomCamera(camCoords, showroomWagon)
    SetModelAsNoLongerNeeded(model)
    isSpawningWagon = false
end


function UpdateShowroomWagonVisuals(wagon, custom)
    if not DoesEntityExist(wagon) then return end

    Citizen.InvokeNative(0x75F90E4051CC084C, wagon, 0)
    if custom.props then
        Citizen.InvokeNative(0x75F90E4051CC084C, wagon, GetHashKey(custom.props))
        Citizen.InvokeNative(0x31F343383F19C987, wagon, 0.5, 1)
    end

    Citizen.InvokeNative(0xE31C0CB1C3186D40, wagon)
    Wait(50)

    if custom.lantern then
        Citizen.InvokeNative(0xC0F0417A90402742, wagon, GetHashKey(custom.lantern))
    end

    Wait(50)
    Citizen.InvokeNative(0xAD738C3085FE7E11, wagon, true, true)
    Citizen.InvokeNative(0x9617B6E5F65329A5, wagon)

    Citizen.InvokeNative(0x8268B098F6FCA4E2, wagon, custom.tint or 0)
    Citizen.InvokeNative(0xF89D82A0582E46ED, wagon, custom.livery or 0)

    for i = 0, 10 do
        if DoesExtraExist(wagon, i) then
            Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, i, true)
        end
    end
    if custom.extra then
        Citizen.InvokeNative(0xBB6F89150BC9D16B, wagon, custom.extra, false)
    end
end


-- Same preview light rig as rsg-horses showroom: a per-frame
-- DrawLightWithRange over the preview wagon plus cam keep-alive.
local function StartShowroomRenderThread()
    if showroomRenderActive then return end
    showroomRenderActive = true
    CreateThread(function()
        while showroomRenderActive and (showroomCam or showroomWagon) do
            Wait(0)
            if showroomCam then
                SetCamActive(showroomCam, true)
                RenderScriptCams(true, false, 0, true, true)
            end
            if showroomWagon and DoesEntityExist(showroomWagon) then
                local crds = GetEntityCoords(showroomWagon)
                DrawLightWithRange(crds.x, crds.y, crds.z + 2.0, 255, 255, 255, 15.0, 50.0)
            end
        end
        showroomRenderActive = false
    end)
end

function SetUpShowroomCamera(cameraPosition, targetEntity)
    FreezeEntityPosition(cache.ped, true)
    SetEntityInvincible(cache.ped, true)

    if showroomCam then
        -- Re-point the existing camera instead of leaking cam handles
        SetCamCoord(showroomCam, cameraPosition.x, cameraPosition.y, cameraPosition.z)
        PointCamAtEntity(showroomCam, targetEntity, 0, 0, 0, true)
    else
        showroomCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(showroomCam, cameraPosition.x, cameraPosition.y, cameraPosition.z)
        PointCamAtEntity(showroomCam, targetEntity, 0, 0, 0, true)
    end

    SetCamActive(showroomCam, true)
    RenderScriptCams(true, false, 0, true, true)
    SetCamFov(showroomCam, 50.0)

    StartShowroomRenderThread()
end


function ShowRotatePrompt()
    rotatePromptGroup = PromptGetGroupIdForTargetEntity(cache.ped)

    rotateLeftPrompt = PromptRegisterBegin()
    PromptSetControlAction(rotateLeftPrompt, inputLeft)
    PromptSetText(rotateLeftPrompt, CreateVarString(10, "LITERAL_STRING", locale("left")))
    PromptSetEnabled(rotateLeftPrompt, true)
    PromptSetVisible(rotateLeftPrompt, true)
    PromptSetStandardMode(rotateLeftPrompt, true)
    PromptSetGroup(rotateLeftPrompt, rotatePromptGroup)
    PromptRegisterEnd(rotateLeftPrompt)

    rotateRightPrompt = PromptRegisterBegin()
    PromptSetControlAction(rotateRightPrompt, inputRight)
    PromptSetText(rotateRightPrompt, CreateVarString(10, "LITERAL_STRING", locale("right")))
    PromptSetEnabled(rotateRightPrompt, true)
    PromptSetVisible(rotateRightPrompt, true)
    PromptSetStandardMode(rotateRightPrompt, true)
    PromptSetGroup(rotateRightPrompt, rotatePromptGroup)
    PromptRegisterEnd(rotateRightPrompt)

    CreateThread(function()
        while rotatePromptGroup do
            Wait(0)
            PromptSetActiveGroupThisFrame(rotatePromptGroup, CreateVarString(10, "LITERAL_STRING", "Rotate Wagon"))
            RotateShowroomWagon()
        end
    end)
end

function HideRotatePrompt()
    if rotateLeftPrompt then PromptDelete(rotateLeftPrompt) end
    if rotateRightPrompt then PromptDelete(rotateRightPrompt) end
    rotateLeftPrompt, rotateRightPrompt, rotatePromptGroup = nil, nil, nil
end

function RotateShowroomWagon()
    if not showroomWagon then return end
    local heading = GetEntityHeading(showroomWagon)
    if IsDisabledControlPressed(0, inputLeft) then
        SetEntityHeading(showroomWagon, heading - rotationSpeed)
    elseif IsDisabledControlPressed(0, inputRight) then
        SetEntityHeading(showroomWagon, heading + rotationSpeed)
    end
end

function RotatePreviewWagon(direction)
    if not showroomWagon then return end
    local heading = GetEntityHeading(showroomWagon)
    SetEntityHeading(showroomWagon, heading + (direction == 'left' and -5 or 5))
end

function CloseShowroom()
    showroomRenderActive = false
    DeleteShowroomWagon()
    if showroomCam then
        DestroyCam(showroomCam, false)
        RenderScriptCams(false, false, 0, true, true)
        showroomCam = nil
    end
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)
end
