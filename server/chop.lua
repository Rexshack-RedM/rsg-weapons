-- rsg-wagons chop shop (server): rewards, cooldown, owner-aware delete.
-- Registry access goes through globals exposed by server/server.lua
-- (RSGWagons_GetWagon / RSGWagons_DeactivateWagon) so this file stays
-- decoupled from its locals.

local RSGCore = exports['rsg-core']:GetCoreObject()

local ChopCooldowns = {}
local PendingChops = {}

local function ChopDebug(...)
    if Config.Chop and Config.Chop.Debug then
        print('[rsg-wagons:chop]', ...)
    end
end

local function GetWagonDisplayName(modelName)
    if not modelName then return 'Unknown Wagon' end
    local name = modelName:gsub('^p_', ''):gsub('(%d+x?)$', ''):gsub('(%d+)$', ''):gsub('_', ' ')
    name = name:gsub('(%a)([%w]*)', function(first, rest) return first:upper() .. rest end)
    if name == '' then name = modelName end
    return name
end

-- Multiplier derived from the wagon's shop price so no second model
-- list is needed. Unknown wagons use DefaultMultiplier.
local function GetChopMultiplier(modelName)
    if Config.Wagons then
        for _, set in pairs(Config.Wagons) do
            local cfg = set[modelName]
            if cfg and cfg.price then
                local m = cfg.price / 100.0
                m = math.max(Config.Chop.MinMultiplier or 0.5, math.min(Config.Chop.MaxMultiplier or 2.5, m))
                return m
            end
        end
    end
    return Config.Chop.DefaultMultiplier or 1.0
end

local function CalculateChopRewards(multiplier)
    local rewards = {}
    if Config.Chop.RewardItems then
        for item, range in pairs(Config.Chop.RewardItems) do
            local amount = math.random(range.min, range.max)
            rewards[item] = math.floor(amount * multiplier + 0.5)
        end
    end
    if Config.Chop.CashPayout then
        local cash = math.random(Config.Chop.CashPayout.min, Config.Chop.CashPayout.max)
        rewards.cash = math.floor(cash * multiplier + 0.5)
    end
    return rewards
end

local function IsChopOnCooldown(src)
    local now = os.time()
    if ChopCooldowns[src] and (now - ChopCooldowns[src]) < (Config.Chop.ChopCooldown or 300) then
        return true, (Config.Chop.ChopCooldown or 300) - (now - ChopCooldowns[src])
    end
    return false, 0
end

local function GetRegisteredWagon(netId)
    local getter = rawget(_G, 'RSGWagons_GetWagon')
    if type(getter) ~= 'function' then return nil end
    return getter(netId)
end

lib.callback.register('rsg-wagons:server:getChopInfo', function(source, netId, modelName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return nil end

    local onCooldown, remaining = IsChopOnCooldown(src)
    if onCooldown then
        return { error = true, message = locale('cl_chop_cooldown') .. ' ' .. remaining .. 's' }
    end

    netId = tonumber(netId) or 0
    local reg = netId ~= 0 and GetRegisteredWagon(netId) or nil
    if reg then
        -- Registered (owned) wagons can only be scrapped by their owner.
        -- This prevents griefing other players' wagons for materials.
        if src ~= reg.owner then
            return { error = true, message = locale('no_permission') }
        end
    end

    local displayName = GetWagonDisplayName(modelName)
    local multiplier = GetChopMultiplier(modelName)
    local rewards = CalculateChopRewards(multiplier)

    -- Labelled list for the NUI offer screen (map stays for payout).
    local rewardList = {}
    if rewards.cash and rewards.cash > 0 then
        rewardList[#rewardList + 1] = { item = 'cash', label = 'Cash', amount = '$' .. rewards.cash }
    end
    for item, amount in pairs(rewards) do
        if item ~= 'cash' and amount > 0 then
            local itemData = RSGCore.Shared.Items[item]
            rewardList[#rewardList + 1] = { item = item, label = (itemData and itemData.label) or item, amount = 'x' .. amount }
        end
    end

    PendingChops[src] = PendingChops[src] or {}
    PendingChops[src][netId] = {
        modelName = modelName,
        rewards = rewards,
        multiplier = multiplier,
        wagonID = reg and reg.wagonID or nil,
        createdAt = os.time(),
    }

    return {
        error = false,
        netId = netId,
        modelName = modelName,
        displayName = displayName,
        rewards = rewards,
        rewardList = rewardList,
        multiplier = multiplier,
        isRegistered = reg ~= nil,
    }
end)

RegisterNetEvent('rsg-wagons:server:processChop', function(netId, modelName)
    local src = source
    netId = tonumber(netId) or 0
    ChopDebug(('processChop src=%s netId=%s model=%s'):format(tostring(src), tostring(netId), tostring(modelName)))

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local onCooldown, remaining = IsChopOnCooldown(src)
    if onCooldown then
        TriggerClientEvent('rsg-wagons:client:chopNotify', src, 'error', locale('cl_chop_title'), locale('cl_chop_cooldown') .. ' ' .. remaining .. 's')
        return
    end

    local pending = PendingChops[src] and PendingChops[src][netId]
    if not pending or pending.modelName ~= modelName then
        TriggerClientEvent('rsg-wagons:client:chopNotify', src, 'error', locale('cl_chop_title'), locale('cl_chop_expired'))
        return
    end
    if (os.time() - pending.createdAt) > 120 then
        PendingChops[src][netId] = nil
        TriggerClientEvent('rsg-wagons:client:chopNotify', src, 'error', locale('cl_chop_title'), locale('cl_chop_expired'))
        return
    end
    PendingChops[src][netId] = nil

    local reg = netId ~= 0 and GetRegisteredWagon(netId) or nil
    if reg and src ~= reg.owner then
        TriggerClientEvent('rsg-wagons:client:chopNotify', src, 'error', locale('cl_chop_title'), locale('no_permission'))
        return
    end

    local rewards = pending.rewards
    local displayName = GetWagonDisplayName(modelName)
    local rewardMsg = {}

    if rewards.cash and rewards.cash > 0 then
        Player.Functions.AddMoney('cash', rewards.cash)
        rewardMsg[#rewardMsg + 1] = '$' .. rewards.cash
    end
    if Config.Chop.RewardItems then
        for item, amount in pairs(rewards) do
            if item ~= 'cash' and amount > 0 then
                Player.Functions.AddItem(item, amount)
                TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
                rewardMsg[#rewardMsg + 1] = amount .. 'x ' .. item
            end
        end
    end

    ChopCooldowns[src] = os.time()

    if reg then
        -- Owned wagon, chopper IS the owner: owner-side cleanup has
        -- control, so it deletes reliably (fixes shop-wagon survival).
        local deactivator = rawget(_G, 'RSGWagons_DeactivateWagon')
        if type(deactivator) == 'function' then
            deactivator(reg.wagonID)
        end
        TriggerClientEvent('rsg-wagons:client:chopDeleteOwnedWagon', reg.owner, netId)
    else
        -- World / third-party wagon (e.g. shop wagons): chopper deletes
        -- locally, server fallback below clears it for everyone.
        TriggerClientEvent('rsg-wagons:client:chopForceDelete', src, netId)
    end

    TriggerClientEvent('rsg-wagons:client:chopNotify', src, 'success', locale('cl_chop_done_title'),
        locale('cl_chop_done') .. ' ' .. displayName .. ' (' .. table.concat(rewardMsg, ', ') .. ')')

    local ci = Player.PlayerData.charinfo or {}
    print(('[rsg-wagons:chop] %s %s (ID %s) scrapped %s for %s'):format(
        ci.firstname or '?', ci.lastname or '?', tostring(src), tostring(modelName), table.concat(rewardMsg, ', ')))
end)

-- Server-side network deletion fallback for world/third-party wagons.
RegisterNetEvent('rsg-wagons:server:chopDeleteFallback', function(netId)
    local src = source
    local id = tonumber(netId)
    if not id or id == 0 then return end
    local playerPed = GetPlayerPed(src)
    if playerPed == 0 then return end

    local wagon = NetworkGetEntityFromNetworkId(id)
    if wagon == 0 or not DoesEntityExist(wagon) then return end

    local playerCoords = GetEntityCoords(playerPed)
    local wagonCoords = GetEntityCoords(wagon)
    if #(playerCoords - wagonCoords) > 60.0 then return end
    if GetEntityType(wagon) ~= 2 then return end

    SetEntityAsMissionEntity(wagon, true, true)
    DeleteEntity(wagon)
    Wait(200)
    if DoesEntityExist(wagon) then
        DeleteEntity(wagon)
    end
    ChopDebug('fallback delete netId=' .. tostring(id) .. ' exists=' .. tostring(DoesEntityExist(wagon)))
end)

AddEventHandler('playerDropped', function()
    local src = source
    ChopCooldowns[src] = nil
    PendingChops[src] = nil
end)
