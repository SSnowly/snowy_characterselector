--- Handles player spawn sequence with GTA-style character switch effect
---@param coords vector3 Spawn coordinates
---@param heading number Spawn heading
---@param newPlayer boolean Whether this is a new character
---@return boolean success
local function startSpawnSequence(coords, heading, newPlayer, ped)
    SetPlayerModel(PlayerId(), ped)
    local ped = PlayerPedId()
    DoScreenFadeIn(0)
    SwitchOutPlayer(ped, 0, 1)

    local switchOutStart = GetGameTimer()
    while GetPlayerSwitchState() ~= 5 do
        if GetGameTimer() - switchOutStart > 10000 then break end
        Wait(0)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    Creator.Remove()
    Selector.Remove()

    local collisionStart = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) do
        if GetGameTimer() - collisionStart > 10000 then break end
        Wait(0)
    end

    SetEntityVisible(ped, true, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 1.0, false, false, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityHeading(ped, heading)
    SetEntityMaxHealth(ped, 200)
    if newPlayer then
        SetEntityHealth(ped, 200)
    end
    SwitchInPlayer(ped)

    local switchInStart = GetGameTimer()
    while GetPlayerSwitchState() ~= 12 do
        if GetGameTimer() - switchInStart > 10000 then break end
        Wait(0)
    end

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    if newPlayer then
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    end
    TriggerEvent('qb-weathersync:client:EnableSync')

    FreezeEntityPosition(ped, false)
    SetPlayerControl(PlayerId(), true, 0)

    return true
end

Spawn = {
    SpawnPlayer = startSpawnSequence
}


lib.callback.register("snowy_characterselector:client:spawnNormal", function(lastPos, lastHeading, ped)
    return startSpawnSequence(lastPos, lastHeading, false, ped)
end)
