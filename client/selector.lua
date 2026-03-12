Selector = {}
Selector.Ped = {}
local mousePos = { x = 0, y = 0 }
local mouseClick = false

RegisterNUICallback('main:mouse_event', function(data, cb)
    mousePos.x = data.x
    mousePos.y = data.y
    if data.type == 'click' then
        mouseClick = true
    end
    cb('ok')
end)

local function requestModel(model, timeout)
    local hash = type(model) == 'string' and joaat(model) or model
    return lib.requestModel(hash, timeout or 10000)
end

local function createLocalPed(model, coords, heading)
    local hash = type(model) == 'string' and joaat(model) or model
    local x, y, z = coords.x, coords.y, coords.z
    local ped = CreatePed(4, hash, x, y, z, heading or 0.0, false, false)
    SetEntityAsNoLongerNeeded(ped)
    return ped
end

local function selectorSetupPlayer()
    local cfg = Config.Selector.player
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetEntityCoords(ped, cfg.coords.x, cfg.coords.y, cfg.coords.z, false, false, false, false)
    FreezeEntityPosition(ped, true)
end

local function selectorSetupCamera()
    local cfg = Config.Selector.camera
    local camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(camera, cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetCamRot(camera, cfg.rotation.x, cfg.rotation.y, cfg.rotation.z, 2)
    RenderScriptCams(true, false, false, true, false)
    Data.selector.camera = camera
end

local function selectorDestroyPed(id)
    if not Data.selector.characters or not Data.selector.characters[id] then return end
    if DoesEntityExist(Data.selector.characters[id].ped) then
        DeleteEntity(Data.selector.characters[id].ped)
    end
    Data.selector.characters[id].ped = nil
end

---@param id number Character slot ID
---@param data table Character data
local function selectorCreatePed(id, data)
    local cfg = Config.Selector.positions[id]
    local empty = not data.firstname or not data.lastname
    if not data.ped then
        data.ped = empty and Config.Selector.empty.ped or
            (Config.Gender and Config.Gender[data.gender or 'man'] or 'mp_m_freemode_01')
    end
    local convertPed = data.ped
    if not requestModel(convertPed, 60000) then return end

    local ped = createLocalPed(convertPed, cfg.coords, cfg.heading)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, cfg.coords.x, cfg.coords.y, cfg.coords.z, false, false, false, false)
    SetEntityHeading(ped, cfg.heading)
    SetEntityInvincible(ped, false)

    if not empty then
        if Config.framework == 'qbx_core' then
            if data.skin and next(data.skin) then
                if GetResourceState('illenium-appearance') == 'started' then
                    pcall(function()
                        exports['illenium-appearance']:setPedAppearance(ped, data.skin)
                    end)
                end
            else
                local defaultSkin = Config.Selector.skin
                if defaultSkin and GetResourceState('illenium-appearance') == 'started' then
                    pcall(function()
                        exports['illenium-appearance']:setPedAppearance(ped, defaultSkin)
                    end)
                end
            end

            lib.requestAnimDict(cfg.animation.dict)
            TaskPlayAnimAdvanced(ped, cfg.animation.dict, cfg.animation.name, cfg.coords.x, cfg.coords.y, cfg.coords.z, 0.0, 0.0, cfg.heading, 8.0, 1.0, -1, 2, 0)
        end
    else
        lib.requestAnimDict(cfg.animation.dict)
        TaskPlayAnimAdvanced(ped, cfg.animation.dict, cfg.animation.name, cfg.coords.x, cfg.coords.y, cfg.coords.z, 0.0, 0.0, cfg.heading, 8.0, 1.0, -1, 2, 0)
    end

    Data.selector.characters[id].ped = ped
end

local function isSelected(id)
    return Data.selector.selected and Data.selector.selected == Data.selector.characters[id].id
end

local function selectorRunHover()
    CreateThread(function()
        while Data.selector and Data.selector.characters do
            DisableAllControlActions(0)
            for k, v in pairs(Data.selector.characters) do
                if v.ped and DoesEntityExist(v.ped) and GetEntityModel(v.ped) ~= 0 then
                    local coords = GetEntityCoords(v.ped)
                    local boneCoords = GetWorldPositionOfEntityBone(v.ped, 0)
                    if boneCoords and (boneCoords.x ~= 0.0 or boneCoords.y ~= 0.0) then
                        coords = boneCoords
                    end
                    if coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0 then
                        local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

                        SetEntityAlpha(v.ped, ((v.firstname and v.lastname) or isSelected(k)) and 250 or 120, false)
                        if onScreen and math.abs(mousePos.x - x) < 0.05 and math.abs(mousePos.y - y) < 0.15 then
                            SetEntityAlpha(v.ped, 255, false)
                            if mouseClick then
                                Selector.Select(k)
                            end
                        end
                    end
                end
            end
            mouseClick = false
            Wait(0)
        end
    end)
end

function Selector.StartHover()
    selectorRunHover()
end

---@param isSecondary? boolean Skip framework unload if true
---@param existingCamera? number Reuse existing camera instead of creating new one
function Selector.Load(isSecondary, existingCamera)
    local secondary = isSecondary or false
    if not secondary then Framework.onOpenSelector() end
    Framework.getCharacters(function(args)
        if args then Selector.Setup(args, existingCamera) end
    end)
end

---@param characters table List of character data
---@param existingCamera? number Reuse existing camera instead of creating new one
function Selector.Setup(characters, existingCamera)
    if not Data.selector then
        Data.selector = {
            characters = characters,
            selected = nil,
            block = false
        }
    end

    selectorSetupPlayer()
    for k, v in pairs(characters) do
        selectorCreatePed(k, v)
    end

    if existingCamera then
        Data.selector.camera = existingCamera
    else
        selectorSetupCamera()
    end

    local coords = Config.Selector.interior.coords
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId and interiorId ~= 0 then
        LoadInterior(interiorId)
        PinInteriorInMemory(interiorId)
    end
    local timeout = GetGameTimer() + 10000
    while (not interiorId or interiorId == 0 or not IsInteriorReady(interiorId)) and timeout > GetGameTimer() do
        Wait(0)
    end

    DisplayRadar(false)
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(1000)
    SetNuiFocus(true, true)
    selectorRunHover()
end

---@param id number Character slot ID
function Selector.Select(id)
    if Data.selector.block or Data.selector.selected == id then return end
    Data.selector.block = true

    if Data.selector.selected then
        local cfg = Config.Selector.positions[Data.selector.selected]
        TaskPlayAnimAdvanced(Data.selector.characters[Data.selector.selected].ped, cfg.animation.dict, cfg.animation.name, cfg.coords.x, cfg.coords.y, cfg.coords.z, 0.0, 0.0, cfg.heading, 1.0, 1.0, -1, 2, 0)
    end

    Data.selector.selected = id

    if Data.selector.zoomCamera and DoesCamExist(Data.selector.zoomCamera) then
        DestroyCam(Data.selector.zoomCamera, false)
        Data.selector.zoomCamera = nil
    end

    if Data.selector.originalCamera and DoesCamExist(Data.selector.originalCamera) then
        Data.selector.camera = Data.selector.originalCamera
        Data.selector.originalCamera = nil
    end

    local char = Data.selector.characters[id]
    if char and char.ped and DoesEntityExist(char.ped) then
        local camOffset = GetOffsetFromEntityInWorldCoords(char.ped, 0.0, 1.5, 0.2)

        local zoomCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(zoomCam, camOffset.x, camOffset.y, camOffset.z)
        PointCamAtEntity(zoomCam, char.ped, 0.0, 0.0, 0.3, true)
        SetCamActiveWithInterp(zoomCam, Data.selector.camera, 1000, 1, 1)

        Data.selector.originalCamera = Data.selector.camera
        Data.selector.zoomCamera = zoomCam
        Data.selector.camera = zoomCam
    end

    local hasCharacter = char and char.firstname and char.lastname

    local function showCharacterMenu()
        local options = {}
        if hasCharacter then
            local fullName = char.firstname .. " " .. char.lastname
            local cashFormatted = string.format("$%s", string.format("%d", char.cash or 0):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
            local bankFormatted = string.format("$%s", string.format("%d", char.bank or 0):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))

            options = {
                {
                    title = fullName,
                    description = char.nationality or 'Unknown',
                    icon = 'user',
                    readOnly = true,
                },
                {
                    title = locale('selector.citizen_id'),
                    description = char.citizenid or 'Unknown',
                    icon = 'id-card',
                    readOnly = true,
                },
                {
                    title = locale('selector.total_money'),
                    description = locale('selector.cash') .. " " .. cashFormatted .. "\n" .. locale('selector.bank') .. " " .. bankFormatted,
                    icon = 'wallet',
                    readOnly = true,
                },
                {
                    title = locale('selector.load_character'),
                    icon = 'right-from-bracket',
                    onSelect = function()
                        Selector.Method('load')
                    end,
                },
            }
            if Config.CharacterDeletion.allowDeletion then
                options[#options+1] = {
                    title = locale('selector.delete_character'),
                    icon = 'trash',
                    onSelect = function()
                        Selector.Method('remove')
                    end,
                }
            end
        elseif char.isLocked then
            options = {
                {
                    title = locale('selector.slot_locked'),
                    description = locale('selector.slot_locked_desc'),
                    icon = 'lock',
                    readOnly = true,
                },
            }
        else
            options = {
                {
                    title = locale('selector.create_new'),
                    icon = 'user-plus',
                    onSelect = function()
                        Selector.Method('create')
                    end,
                },
            }
        end

        lib.registerContext({
            id = 'character_selector_menu',
            title = locale('selector.menu_title'),
            options = options,
            onExit = function()
                CreateThread(function()
                    if Data.selector and Data.selector.originalCamera and Data.selector.zoomCamera then
                        if DoesCamExist(Data.selector.originalCamera) and DoesCamExist(Data.selector.zoomCamera) then
                            SetCamActiveWithInterp(Data.selector.originalCamera, Data.selector.zoomCamera, 1000, 1, 1)
                            Wait(1000)
                            DestroyCam(Data.selector.zoomCamera, false)
                        end
                        Data.selector.camera = Data.selector.originalCamera
                        Data.selector.zoomCamera = nil
                        Data.selector.originalCamera = nil
                    end

                    if Data.selector and Data.selector.selected then
                        local cfg = Config.Selector.positions[Data.selector.selected]
                        local ped = Data.selector.characters[Data.selector.selected].ped
                        if DoesEntityExist(ped) then
                            TaskPlayAnimAdvanced(ped, cfg.animation.dict, cfg.animation.name, cfg.coords.x, cfg.coords.y, cfg.coords.z, 0.0, 0.0, cfg.heading, 8.0, 1.0, -1, 2, 0)
                        end
                    end

                    if Data.selector then
                        Data.selector.selected = nil
                        Data.selector.block = false
                    end
                end)
            end,
        })
        lib.showContext('character_selector_menu')
    end

    Data.selector.showMenu = showCharacterMenu
    showCharacterMenu()
end

function Selector.Ped.Create(id, data)
    selectorCreatePed(id, data)
end

function Selector.Ped.Destroy(id)
    selectorDestroyPed(id)
end

function Selector.Ped.DestroyAll()
    if not Data.selector.characters then return end
    for k in pairs(Data.selector.characters) do
        selectorDestroyPed(k)
    end
end

function Selector.Remove()
    if not Data.selector then return end
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    SetNuiFocus(false, false)
    Selector.Ped.DestroyAll()
    if Data.selector.camera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(Data.selector.camera, true)
    end
    Data.selector = nil
end

---@param methodType string Method type: 'load', 'create', 'remove'
function Selector.Method(methodType)
    if not Data.selector.selected then return end

    if methodType == 'load' then
        Data.selector.block = true
        local characterId = Data.selector.characters[Data.selector.selected].id
        DoScreenFadeOut(500)
        Wait(500)
        Framework.selectCharacter(characterId, function()
            Selector.Remove()
            Framework.triggerSpawnAfterLoad(characterId)
        end)
        return
    end

    if methodType == 'create' then
        Data.selector.block = true

        local creatorCfg = Config.Creator.camera
        local targetCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(targetCam, creatorCfg.coords.x, creatorCfg.coords.y, creatorCfg.coords.z)
        SetCamRot(targetCam, creatorCfg.rotation.x, creatorCfg.rotation.y, creatorCfg.rotation.z, 2)
        SetCamActiveWithInterp(targetCam, Data.selector.camera, 2000, 1, 1)

        Wait(2000)

        DestroyCam(Data.selector.camera, false)
        local camera = targetCam

        local selectorData = Data.selector
        Data.selector = nil

        SetNuiFocus(false, false)

        Creator.Load(camera, selectorData)
        return
    end

    if methodType == 'remove' then
        if Data.selector.characters[Data.selector.selected].removeDate then
            lib.notify({
                type = 'error',
                title = locale('selector.delete_error_title'),
                description = locale('selector.delete_error_date', Data.selector.characters[Data.selector.selected].removeDate),
                duration = 5000
            })
            Data.selector.block = false
            return
        end

        local selected = Data.selector.selected
        local alert = lib.alertDialog({
            header = locale('selector.delete_confirm_header'),
            content = locale('selector.delete_confirm_content', Data.selector.characters[selected].firstname .. " " .. Data.selector.characters[selected].lastname),
            centered = true,
            cancel = true,
            labels = { confirm = locale('selector.delete_confirm_btn'), cancel = locale('selector.cancel') }
        })

        if alert == 'confirm' then
            local targetPed = Data.selector.characters[selected].ped
            if DoesEntityExist(targetPed) then
                local headBone = GetPedBoneIndex(targetPed, 31086)
                local headCoords = GetWorldPositionOfEntityBone(targetPed, headBone)

                ApplyDamageToPed(targetPed, 500, false, 1)
                SetPedToRagdoll(targetPed, 5000, 5000, 0, false, false, false)
                SetEntityHealth(targetPed, 0)

                if Config.CharacterDeletion.useBulletShootAsDeletion then
                    local weaponHash = `WEAPON_PISTOL`
                    ShootSingleBulletBetweenCoords(
                        headCoords.x + 2.0, headCoords.y, headCoords.z,
                        headCoords.x, headCoords.y, headCoords.z,
                        1, true, weaponHash, 0, true, false, 1000.0
                    )
                end
            end

            Wait(1500)

            if Data.selector.originalCamera and Data.selector.zoomCamera then
                if DoesCamExist(Data.selector.originalCamera) and DoesCamExist(Data.selector.zoomCamera) then
                    SetCamActiveWithInterp(Data.selector.originalCamera, Data.selector.zoomCamera, 1500, 1, 1)
                end
            end

            CreateThread(function()
                if DoesEntityExist(targetPed) then
                    for i = 255, 0, -15 do
                        SetEntityAlpha(targetPed, i, false)
                        Wait(50)
                    end
                end
            end)

            Wait(1500)

            if Data.selector.zoomCamera and DoesCamExist(Data.selector.zoomCamera) then
                DestroyCam(Data.selector.zoomCamera, false)
            end
            Data.selector.camera = Data.selector.originalCamera
            Data.selector.zoomCamera = nil
            Data.selector.originalCamera = nil

            Framework.deleteCharacter(Data.selector.characters[selected].id, function(success)
                if success then
                    selectorDestroyPed(selected)

                    Framework.getCharacters(function(args)
                        if args then
                            Data.selector.characters = args
                            Data.selector.selected = nil
                            Data.selector.block = false

                            for k, v in pairs(args) do
                                if not v.ped or not DoesEntityExist(v.ped) then
                                    selectorCreatePed(k, v)
                                end
                            end
                        end
                    end)
                end
            end)
        else
            Data.selector.block = false
            if Data.selector.showMenu then
                Data.selector.showMenu()
            end
        end
    end
end


exports('characterSelector', function()
    Selector.Load()
end)

---@description Handles player logout with GTA-style camera transition
RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end

    local ped = PlayerPedId()

    DoScreenFadeIn(0)
    SwitchOutPlayer(ped, 0, 1)

    local switchOutStart = GetGameTimer()
    while GetPlayerSwitchState() ~= 5 do
        if GetGameTimer() - switchOutStart > 10000 then break end
        Wait(0)
    end

    local cfg = Config.Selector.player
    RequestCollisionAtCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)

    local collisionStart = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(ped) do
        if GetGameTimer() - collisionStart > 10000 then break end
        Wait(0)
    end

    SetEntityCoords(ped, cfg.coords.x, cfg.coords.y, cfg.coords.z, false, false, false, false)
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)

    Selector.Load(true)

    local waitStart = GetGameTimer()
    while not Data.selector or not Data.selector.camera do
        if GetGameTimer() - waitStart > 10000 then break end
        Wait(100)
    end

    SwitchInPlayer(ped)

    local switchInStart = GetGameTimer()
    while GetPlayerSwitchState() ~= 12 do
        if GetGameTimer() - switchInStart > 10000 then break end
        Wait(0)
    end

end)

CreateThread(function()
    local model = `a_m_y_bevhills_01`
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            Wait(250)
            lib.requestModel(model, 5000)
            SetPlayerModel(cache.playerId, model)
            Selector.Load()
            break
        end
    end
end)
