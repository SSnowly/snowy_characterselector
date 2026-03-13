Creator = {}
Creator.Ped = {}

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

local function creatorSetupCamera()
    local cfg = Config.Creator.camera
    local camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(camera, cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetCamRot(camera, cfg.rotation.x, cfg.rotation.y, cfg.rotation.z, 2)
    RenderScriptCams(true, false, false, true, false)
    Data.creator.camera = camera
end

local function creatorDestroyPed()
    if not Data.creator or not Data.creator.ped then return end
    if DoesEntityExist(Data.creator.ped) then
        DeleteEntity(Data.creator.ped)
    end
    Data.creator.ped = nil
end

local function creatorCreatePed(gender)
    local cfg = Config.Creator.ped
    if not requestModel(cfg.gender[gender].model) then return end
    local ped = createLocalPed(cfg.gender[gender].model, vector3(cfg.position.coords.x, cfg.position.coords.y, cfg.position.coords.z - 1.0), cfg.position.heading)
    while not DoesEntityExist(ped) do Wait(0) end
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, cfg.position.coords.x, cfg.position.coords.y, cfg.position.coords.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, cfg.position.heading)
    SetEntityInvincible(ped, false)
    SetEntityAlpha(ped, 255, false)
    TaskStandStill(ped, -1)
    Data.creator.ped = ped
end

local function creatorFlow()
    local genderPicked = false
    local cancelled = false
    lib.registerContext({
        id = 'creator_gender',
        title = locale('creator.gender_title'),
        options = {
            { title = locale('creator.male'), icon = 'mars', onSelect = function()
                Creator.Method('gender', 'man')
                Data.creator.gender = 'man'
                genderPicked = true
            end },
            { title = locale('creator.female'), icon = 'venus', onSelect = function()
                Creator.Method('gender', 'woman')
                Data.creator.gender = 'woman'
                genderPicked = true
            end },
            { title = locale('creator.cancel'), icon = 'xmark', onSelect = function()
                cancelled = true
                Creator.Method('selector')
            end },
        },
        onExit = function()
            if not genderPicked then
                cancelled = true
                Creator.Method('selector')
            end
        end,
    })
    lib.showContext('creator_gender')
    local timeout = GetGameTimer() + 60000
    while not genderPicked and not cancelled and Data.creator do
        if GetGameTimer() > timeout then
            Creator.Method('selector')
            return
        end
        Wait(100)
    end
    SetEntityVisible(ped, true)

    if not Data.creator or not genderPicked or cancelled then return end

    local nameInput = lib.inputDialog(locale('creator.name_title'), {
        { type = 'input', label = locale('creator.firstname_label'), required = true, min = 1, max = 50, placeholder = locale('creator.firstname_placeholder') },
        { type = 'input', label = locale('creator.lastname_label'), required = true, min = 1, max = 50, placeholder = locale('creator.lastname_placeholder') },
    })
    if not nameInput or not nameInput[1] or nameInput[1]:len() == 0 or not nameInput[2] or nameInput[2]:len() == 0 then
        Creator.Method('selector')
        return
    end
    Data.creator.firstname = nameInput[1]
    Data.creator.lastname = nameInput[2]

    local dateInput = lib.inputDialog(locale('creator.birthday_title'), {
        { type = 'date', label = locale('creator.birthday_label'), default = "01/01/2006", format = 'DD/MM/YYYY', max = "01/01/2006" },
    })
    if not dateInput or not dateInput[1] then
        Creator.Method('selector')
        return
    end
    local birthdayTs = dateInput[1]
    if type(birthdayTs) == 'number' and birthdayTs > 10000000000 then
        birthdayTs = math.floor(birthdayTs / 1000)
    end

    local nationalityInput = lib.inputDialog(locale('creator.nationality_title'), {
        {
            type = 'select',
            label = locale('creator.nationality_label'),
            required = true,
            options = {
                { value = 'Afghan', label = 'Afghan' },
                { value = 'Albanian', label = 'Albanian' },
                { value = 'Algerian', label = 'Algerian' },
                { value = 'American', label = 'American' },
                { value = 'Andorran', label = 'Andorran' },
                { value = 'Angolan', label = 'Angolan' },
                { value = 'Argentine', label = 'Argentine' },
                { value = 'Armenian', label = 'Armenian' },
                { value = 'Australian', label = 'Australian' },
                { value = 'Austrian', label = 'Austrian' },
                { value = 'Azerbaijani', label = 'Azerbaijani' },
                { value = 'Bahamian', label = 'Bahamian' },
                { value = 'Bahraini', label = 'Bahraini' },
                { value = 'Bangladeshi', label = 'Bangladeshi' },
                { value = 'Barbadian', label = 'Barbadian' },
                { value = 'Belarusian', label = 'Belarusian' },
                { value = 'Belgian', label = 'Belgian' },
                { value = 'Belizean', label = 'Belizean' },
                { value = 'Beninese', label = 'Beninese' },
                { value = 'Bhutanese', label = 'Bhutanese' },
                { value = 'Bolivian', label = 'Bolivian' },
                { value = 'Bosnian', label = 'Bosnian' },
                { value = 'Brazilian', label = 'Brazilian' },
                { value = 'British', label = 'British' },
                { value = 'Bruneian', label = 'Bruneian' },
                { value = 'Bulgarian', label = 'Bulgarian' },
                { value = 'Burkinabe', label = 'Burkinabe' },
                { value = 'Burmese', label = 'Burmese' },
                { value = 'Burundian', label = 'Burundian' },
                { value = 'Cambodian', label = 'Cambodian' },
                { value = 'Cameroonian', label = 'Cameroonian' },
                { value = 'Canadian', label = 'Canadian' },
                { value = 'Cape Verdean', label = 'Cape Verdean' },
                { value = 'Central African', label = 'Central African' },
                { value = 'Chadian', label = 'Chadian' },
                { value = 'Chilean', label = 'Chilean' },
                { value = 'Chinese', label = 'Chinese' },
                { value = 'Colombian', label = 'Colombian' },
                { value = 'Comoran', label = 'Comoran' },
                { value = 'Congolese', label = 'Congolese' },
                { value = 'Costa Rican', label = 'Costa Rican' },
                { value = 'Croatian', label = 'Croatian' },
                { value = 'Cuban', label = 'Cuban' },
                { value = 'Cypriot', label = 'Cypriot' },
                { value = 'Czech', label = 'Czech' },
                { value = 'Danish', label = 'Danish' },
                { value = 'Djiboutian', label = 'Djiboutian' },
                { value = 'Dominican', label = 'Dominican' },
                { value = 'Dutch', label = 'Dutch' },
                { value = 'Ecuadorian', label = 'Ecuadorian' },
                { value = 'Egyptian', label = 'Egyptian' },
                { value = 'Emirati', label = 'Emirati' },
                { value = 'English', label = 'English' },
                { value = 'Eritrean', label = 'Eritrean' },
                { value = 'Estonian', label = 'Estonian' },
                { value = 'Ethiopian', label = 'Ethiopian' },
                { value = 'Fijian', label = 'Fijian' },
                { value = 'Filipino', label = 'Filipino' },
                { value = 'Finnish', label = 'Finnish' },
                { value = 'French', label = 'French' },
                { value = 'Gabonese', label = 'Gabonese' },
                { value = 'Gambian', label = 'Gambian' },
                { value = 'Georgian', label = 'Georgian' },
                { value = 'German', label = 'German' },
                { value = 'Ghanaian', label = 'Ghanaian' },
                { value = 'Greek', label = 'Greek' },
                { value = 'Grenadian', label = 'Grenadian' },
                { value = 'Guatemalan', label = 'Guatemalan' },
                { value = 'Guinean', label = 'Guinean' },
                { value = 'Guyanese', label = 'Guyanese' },
                { value = 'Haitian', label = 'Haitian' },
                { value = 'Honduran', label = 'Honduran' },
                { value = 'Hungarian', label = 'Hungarian' },
                { value = 'Icelandic', label = 'Icelandic' },
                { value = 'Indian', label = 'Indian' },
                { value = 'Indonesian', label = 'Indonesian' },
                { value = 'Iranian', label = 'Iranian' },
                { value = 'Iraqi', label = 'Iraqi' },
                { value = 'Irish', label = 'Irish' },
                { value = 'Israeli', label = 'Israeli' },
                { value = 'Italian', label = 'Italian' },
                { value = 'Ivorian', label = 'Ivorian' },
                { value = 'Jamaican', label = 'Jamaican' },
                { value = 'Japanese', label = 'Japanese' },
                { value = 'Jordanian', label = 'Jordanian' },
                { value = 'Kazakh', label = 'Kazakh' },
                { value = 'Kenyan', label = 'Kenyan' },
                { value = 'Korean', label = 'Korean' },
                { value = 'Kuwaiti', label = 'Kuwaiti' },
                { value = 'Kyrgyz', label = 'Kyrgyz' },
                { value = 'Laotian', label = 'Laotian' },
                { value = 'Latvian', label = 'Latvian' },
                { value = 'Lebanese', label = 'Lebanese' },
                { value = 'Liberian', label = 'Liberian' },
                { value = 'Libyan', label = 'Libyan' },
                { value = 'Lithuanian', label = 'Lithuanian' },
                { value = 'Luxembourgish', label = 'Luxembourgish' },
                { value = 'Macedonian', label = 'Macedonian' },
                { value = 'Malagasy', label = 'Malagasy' },
                { value = 'Malawian', label = 'Malawian' },
                { value = 'Malaysian', label = 'Malaysian' },
                { value = 'Maldivian', label = 'Maldivian' },
                { value = 'Malian', label = 'Malian' },
                { value = 'Maltese', label = 'Maltese' },
                { value = 'Mauritanian', label = 'Mauritanian' },
                { value = 'Mauritian', label = 'Mauritian' },
                { value = 'Mexican', label = 'Mexican' },
                { value = 'Moldovan', label = 'Moldovan' },
                { value = 'Mongolian', label = 'Mongolian' },
                { value = 'Montenegrin', label = 'Montenegrin' },
                { value = 'Moroccan', label = 'Moroccan' },
                { value = 'Mozambican', label = 'Mozambican' },
                { value = 'Namibian', label = 'Namibian' },
                { value = 'Nepalese', label = 'Nepalese' },
                { value = 'New Zealander', label = 'New Zealander' },
                { value = 'Nicaraguan', label = 'Nicaraguan' },
                { value = 'Nigerian', label = 'Nigerian' },
                { value = 'Norwegian', label = 'Norwegian' },
                { value = 'Omani', label = 'Omani' },
                { value = 'Pakistani', label = 'Pakistani' },
                { value = 'Panamanian', label = 'Panamanian' },
                { value = 'Paraguayan', label = 'Paraguayan' },
                { value = 'Peruvian', label = 'Peruvian' },
                { value = 'Polish', label = 'Polish' },
                { value = 'Portuguese', label = 'Portuguese' },
                { value = 'Qatari', label = 'Qatari' },
                { value = 'Romanian', label = 'Romanian' },
                { value = 'Russian', label = 'Russian' },
                { value = 'Rwandan', label = 'Rwandan' },
                { value = 'Saudi', label = 'Saudi' },
                { value = 'Scottish', label = 'Scottish' },
                { value = 'Senegalese', label = 'Senegalese' },
                { value = 'Serbian', label = 'Serbian' },
                { value = 'Singaporean', label = 'Singaporean' },
                { value = 'Slovak', label = 'Slovak' },
                { value = 'Slovenian', label = 'Slovenian' },
                { value = 'Somali', label = 'Somali' },
                { value = 'South African', label = 'South African' },
                { value = 'Spanish', label = 'Spanish' },
                { value = 'Sri Lankan', label = 'Sri Lankan' },
                { value = 'Sudanese', label = 'Sudanese' },
                { value = 'Swedish', label = 'Swedish' },
                { value = 'Swiss', label = 'Swiss' },
                { value = 'Syrian', label = 'Syrian' },
                { value = 'Taiwanese', label = 'Taiwanese' },
                { value = 'Tajik', label = 'Tajik' },
                { value = 'Tanzanian', label = 'Tanzanian' },
                { value = 'Thai', label = 'Thai' },
                { value = 'Togolese', label = 'Togolese' },
                { value = 'Trinidadian', label = 'Trinidadian' },
                { value = 'Tunisian', label = 'Tunisian' },
                { value = 'Turkish', label = 'Turkish' },
                { value = 'Turkmen', label = 'Turkmen' },
                { value = 'Ugandan', label = 'Ugandan' },
                { value = 'Ukrainian', label = 'Ukrainian' },
                { value = 'Uruguayan', label = 'Uruguayan' },
                { value = 'Uzbek', label = 'Uzbek' },
                { value = 'Venezuelan', label = 'Venezuelan' },
                { value = 'Vietnamese', label = 'Vietnamese' },
                { value = 'Welsh', label = 'Welsh' },
                { value = 'Yemeni', label = 'Yemeni' },
                { value = 'Zambian', label = 'Zambian' },
                { value = 'Zimbabwean', label = 'Zimbabwean' },
            },
            default = 'American'
        },
    })
    if not nationalityInput or not nationalityInput[1] then
        Creator.Method('selector')
        return
    end
    Data.creator.nationality = nationalityInput[1]
    -- did you know we never actually show the character anywhere else? yes so this is what makes ur char show up
    -- i spent around 5 minutes thinkin about why this happens, so this comment is here to prove that i am stupid
    SetEntityVisible(PlayerPedId(), true, false)
    Creator.Method('create', {
        firstname = Data.creator.firstname,
        lastname = Data.creator.lastname,
        gender = Data.creator.gender,
        birthday = birthdayTs,
        nationality = Data.creator.nationality,
    })
end

---@param existingCamera? number Reuse existing camera
---@param selectorData? table Selector data to restore on cancel
---@param slot? number Slot ID for character creation
function Creator.Load(existingCamera, selectorData, slot)
    Data.creator = {
        selectorData = selectorData,
        slot = slot
    }

    local coords = Config.Creator.interior.coords
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId and interiorId ~= 0 then
        LoadInterior(interiorId)
        PinInteriorInMemory(interiorId)
    end
    local timer = GetGameTimer() + 10000
    while (not interiorId or interiorId == 0 or not IsInteriorReady(interiorId)) and timer > GetGameTimer() do
        Wait(0)
    end

    if existingCamera then
        Data.creator.camera = existingCamera
    else
        creatorSetupCamera()
    end

    DoScreenFadeIn(1000)

    CreateThread(function()
        while Data.creator do
            DisableAllControlActions(0)
            EnableControlAction(0, 24, true)
            Wait(0)
        end
    end)
    CreateThread(creatorFlow)
end

function Creator.Remove()
    if not Data.creator then return end
    if Data.creator.camera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(Data.creator.camera, true)
    end
    creatorDestroyPed()
    Data.creator = nil
end

function Creator.Ped.Create(gender)
    creatorCreatePed(gender)
end

function Creator.Ped.Destroy()
    creatorDestroyPed()
end

---@param methodType string Method type: 'selector', 'gender', 'create', 'finish'
---@param data? any Method-specific data
function Creator.Method(methodType, data)
    if methodType == 'selector' then
        local selectorCfg = Config.Selector.camera
        local targetCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(targetCam, selectorCfg.coords.x, selectorCfg.coords.y, selectorCfg.coords.z)
        SetCamRot(targetCam, selectorCfg.rotation.x, selectorCfg.rotation.y, selectorCfg.rotation.z, 2)
        SetCamActiveWithInterp(targetCam, Data.creator.camera, 2000, 1, 1)

        Wait(2000)

        DestroyCam(Data.creator.camera, false)
        local camera = targetCam

        local selectorData = Data.creator.selectorData
        Data.creator.camera = nil

        Creator.Remove()

        if selectorData then
            Data.selector = selectorData
            Data.selector.camera = camera
            Data.selector.selected = nil
            Data.selector.block = false
            SetNuiFocus(true, true)
            Selector.StartHover()
        else
            Selector.Load(false, camera)
        end
        return
    end

    if methodType == 'gender' then
        local modelHash = type(Config.Creator.ped.gender[data].model) == 'string'
            and joaat(Config.Creator.ped.gender[data].model)
            or Config.Creator.ped.gender[data].model
        if Data.creator.ped and DoesEntityExist(Data.creator.ped) and GetEntityModel(Data.creator.ped) == modelHash then return end
        creatorDestroyPed()
        creatorCreatePed(data)
        return
    end

    if methodType == 'create' then
        Data.creator.data = data
        DoScreenFadeOut(1000)
        Wait(1000)
        creatorDestroyPed()
        local ped = PlayerPedId()
        local model = Config.Gender[data.gender]
        SetEntityCoords(ped, Config.Creator.customizer.coords.x, Config.Creator.customizer.coords.y, Config.Creator.customizer.coords.z - 1.0, true, false, false, false)
        SetEntityHeading(ped, Config.Creator.customizer.heading)
        FreezeEntityPosition(ped, true)

        if not requestModel(model) then return end

        local modelHash = type(model) == 'string' and joaat(model) or model
        SetPlayerModel(PlayerId(), modelHash)
        SetModelAsNoLongerNeeded(modelHash)

        local function capString(str)
            if not str then return '' end
            return str:sub(1, 1):upper() .. str:sub(2):lower()
        end

        local key = Config.appearance
        local returned = lib.callback.await("snowy_characterselector:server:createCharacter", false, {
            firstname = capString(data.firstname),
            lastname = capString(data.lastname),
            nationality = capString(data.nationality),
            gender = data.gender == 'man' and 0 or 1,
            birthdate = data.birthday,
            slot = Data.creator.slot
        })
        if not returned then
            DoScreenFadeIn(1000)
            Creator.Method('selector')
            return
        end
        local spawned = Spawn.SpawnPlayer(Config.Spawn.defaultSpawn.coords, Config.Spawn.defaultSpawn.heading, true)
        while not spawned do Wait(100) end
        if key == 'illenium-appearance' then
            DoScreenFadeIn(1000)
            if returned then TriggerEvent("qb-clothes:client:CreateFirstCharacter") end
        else
            lib.notify({ type = 'error', title = 'Appearance Error', description = 'Configured appearance system is not supported in creator.', duration = 4000 })
            Creator.Method('selector')
        end
        return
    end

    if methodType == 'finish' then
        lib.notify({ type = 'success', title = locale('creator.success_title'), description = locale('creator.success_description'), duration = 2000 })

        CreateThread(function()
            DoScreenFadeOut(1000)
            Wait(1000)
            for k, v in pairs(Data.creator.data.current.clothes) do
                for key, value in pairs(v) do
                    if value.clothesId then
                        Data.creator.data.current.clothes[k][key].clothesId = nil
                    end
                end
            end
            Creator.Remove()
            Wait(500)
            Selector.Load(true)
        end)
    end
end
