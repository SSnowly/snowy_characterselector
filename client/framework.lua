Framework = {}

---@param char table Raw character data from database
---@param i number Character index
---@return table Mapped character data
local function mapQbxCharacter(char, i)
    local charinfo = char.charinfo
    if type(charinfo) == 'string' then
        charinfo = json.decode(charinfo) or {}
    elseif type(charinfo) ~= 'table' then
        charinfo = {}
    end

    local firstname = charinfo.firstname
    local lastname = charinfo.lastname
    local nationality = charinfo.nationality or 'Unknown'

    local pos = char.position
    if type(pos) == 'string' then
        pos = json.decode(pos) or {}
    end
    local lastCoords = (type(pos) == 'table' and pos.x) and vector3(pos.x, pos.y, pos.z) or vector3(0, 0, 0)

    local gender = (charinfo and charinfo.gender == 1) and 'woman' or 'man'

    local skin = {}
    if char.skin then
        if type(char.skin) == 'string' then
            skin = json.decode(char.skin) or {}
        else
            skin = char.skin
        end
    end
    local money = char.money
    if type(money) == 'string' then
        money = json.decode(money) or {}
    elseif type(money) ~= 'table' then
        money = {}
    end
    local cash = money.cash or 0
    local bank = money.bank or 0

    local ret = {
        id = char.citizenid or char.id or i,
        citizenid = char.citizenid or tostring(i),
        firstname = firstname,
        lastname = lastname,
        nationality = nationality,
        cash = cash,
        bank = bank,
        lastCoords = lastCoords,
        ped = Config.Gender and Config.Gender[gender] or (gender == 'woman' and 'mp_f_freemode_01' or 'mp_m_freemode_01'),
        skin = skin,
        cloth = char.cloth or {},
        tattoo = char.tattoo or {},
        gender = gender,
        removeDate = char.removeDate or char.deleteDate,
        isLocked = false,
    }
    return ret
end

---@param raw table Raw characters from database
---@param maxSlots number Maximum character slots
---@return table Mapped characters with empty slots
local function mapQbxCharacters(raw, maxSlots)
    if type(raw) ~= 'table' then raw = {} end

    local out = {}
    local configSlots = #Config.Selector.positions

    local characterCount = #raw
    local allowedSlots = maxSlots or configSlots

    if type(allowedSlots) ~= 'number' or allowedSlots < 1 then
        allowedSlots = configSlots
    end

    local totalSlots = characterCount

    if characterCount < allowedSlots then
        totalSlots = characterCount + 1
    end

    totalSlots = math.min(totalSlots, allowedSlots, configSlots)
    if totalSlots < characterCount then
        totalSlots = characterCount
    end

    for i = 1, totalSlots do
        out[i] = {
            id = i,
            firstname = nil,
            lastname = nil,
            lastCoords = vector3(0, 0, 0),
            ped = nil,
            skin = {},
            cloth = {},
            tattoo = {},
            gender = math.random(0, 1) == 0 and 'woman' or 'man',
            removeDate = nil,
            isLocked = i > allowedSlots
        }

    end

    for _, char in ipairs(raw) do
        local slot = tonumber(char.char_slot)

        if slot and out[slot] then
            out[slot] = mapQbxCharacter(char, slot)
        else
            for i = 1, totalSlots do
                if not out[i].firstname and not out[i].isLocked then
                    out[i] = mapQbxCharacter(char, i)

                    break
                end
            end
        end
    end

    return out
end

local adapters = {
    ['qbx_core'] = {
        onOpenSelector = function()
            TriggerEvent('QBCore:Client:OnPlayerUnload')
            Wait(2000)
        end,
        getCharacters = function(cb)
            CreateThread(function()
                local data = lib.callback.await('snowy_characterselector:server:getCharacters', false)
                if not data or not data.characters then
                    cb({})
                    return
                end
                local mapped = mapQbxCharacters(data.characters, data.maxSlots)
                cb(mapped)
            end)
        end,
        selectCharacter = function(characterId, onLoaded)
            local ok = lib.callback.await('snowy_characterselector:server:loadCharacter', false, characterId)
            if onLoaded then onLoaded(ok, characterId) end
        end,
        deleteCharacter = function(characterId, cb)
            CreateThread(function()
                local success = lib.callback.await('snowy_characterselector:server:deleteCharacter', false, characterId)
                cb(success == true)
            end)
        end,
        triggerSpawnAfterLoad = function(citizenId)
            if GetResourceState('qbx_apartments'):find('start') then
                TriggerEvent('apartments:client:setupSpawnUI', citizenId)
            elseif GetResourceState('qbx_spawn'):find('start') and not Config.Spawn.defaultSpawn then
                TriggerEvent('qb-spawn:client:setupSpawns', citizenId)
                TriggerEvent('qb-spawn:client:openUI', true)
            end
        end,
    },
}

---@param cb fun(characters: table?)
function Framework.getCharacters(cb)
    local key = Config.framework
    local adapter = adapters[key]
    if not adapter or not adapter.getCharacters then
        lib.notify({ type = 'error', description = ('Framework "%s" is not supported.'):format(tostring(key)) })
        cb(nil)
        return
    end
    adapter.getCharacters(cb)
end

function Framework.onOpenSelector()
    local key = Config.framework
    local adapter = adapters[key]
    if adapter and adapter.onOpenSelector then
        adapter.onOpenSelector()
    end
end

---@param characterId number|string
---@param onLoaded? fun(success?: boolean, characterId?: string)
function Framework.selectCharacter(characterId, onLoaded)
    local key = Config.framework
    local adapter = adapters[key]
    if not adapter or not adapter.selectCharacter then return end
    adapter.selectCharacter(characterId, onLoaded)
end

---@param characterId string
function Framework.triggerSpawnAfterLoad(characterId)
    local adapter = adapters[Config.framework]
    if adapter and adapter.triggerSpawnAfterLoad then
        adapter.triggerSpawnAfterLoad(characterId)
    end
end

---@param characterId number|string
---@param cb fun(success: boolean)
function Framework.deleteCharacter(characterId, cb)
    local key = Config.framework
    local adapter = adapters[key]
    if not adapter or not adapter.deleteCharacter then
        if cb then cb(false) end
        return
    end
    adapter.deleteCharacter(characterId, cb or function() end)
end
