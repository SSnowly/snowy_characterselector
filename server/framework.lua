Framework = {}

---@param source number Player source
function GiveStarterItems(source)
    if GetResourceState('ox_inventory') == 'missing' then return end
    while not exports.ox_inventory:GetInventory(source) do
        Wait(100)
    end
    local starterItems = Config.StarterItems
    for i = 1, #starterItems do
        local item = starterItems[i]
        if item.metadata and type(item.metadata) == 'function' then
            exports.ox_inventory:AddItem(source, item.name, item.amount, item.metadata(source))
        else
            exports.ox_inventory:AddItem(source, item.name, item.amount, item.metadata)
        end
    end
end

MySQL.ready(function()
    MySQL.query.await([[
        ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `char_slot` INT(11) DEFAULT NULL;
    ]])
end)

---@param license2 string
---@param license? string
local function getAllowedAmountOfCharacters(license2, license)
    return Config.Characters.playersNumberOfCharacters[license2] or license and Config.Characters.playersNumberOfCharacters[license] or Config.Characters.defaultNumberOfCharacters
end

local adapters = {
    ['qbx_core'] = {
        ---@param source number Player source
        ---@param gender number Gender (0 = male, 1 = female)
        ---@param data table Character data
        ---@return boolean success, table? characterData
        createCharacter = function(source, gender, data)
            local license, license2
            for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                local identifier = GetPlayerIdentifier(source, i)
                if string.find(identifier, 'license2:') then
                    license2 = identifier
                elseif string.find(identifier, 'license:') then
                    license = identifier
                end
            end

            local licenses = {}
            if license then licenses[#licenses+1] = license end
            if license2 then licenses[#licenses+1] = license2 end

            if #licenses == 0 then
                lib.print.error(('No license found for player %s'):format(source))
                return false, nil
            end

            local maxCharacters = getAllowedAmountOfCharacters(license2, license)
            local charactersCount = MySQL.query.await('SELECT COUNT(*) as count FROM players WHERE license IN (?)', { licenses })
            local count = charactersCount and charactersCount[1] and charactersCount[1].count or 0

            if count >= maxCharacters then
                lib.print.error(('Player %s has already reached the maximum amount of characters (%s)'):format(source, maxCharacters))
                return false, nil
            end

            local citizenid
            repeat
                citizenid = exports.qbx_core:GenerateUniqueIdentifier('citizenid')
                local existing = MySQL.query.await('SELECT citizenid FROM players WHERE citizenid = ?', {citizenid})
            until not existing or #existing == 0

            local requestedSlot = data and tonumber(data.slot) or nil
            local taken = {}
            local existingSlots = MySQL.query.await('SELECT char_slot FROM players WHERE license IN (?)', { licenses }) or {}
            for _, row in ipairs(existingSlots) do
                local s = tonumber(row.char_slot)
                if s then taken[s] = true end
            end

            local slotToUse = requestedSlot
            if not slotToUse or slotToUse < 1 or slotToUse > maxCharacters or taken[slotToUse] then
                slotToUse = nil
                for i = 1, maxCharacters do
                    if not taken[i] then
                        slotToUse = i
                        break
                    end
                end
            end

            local charinfo = {
                firstname = data and data.firstname or 'John',
                lastname = data and data.lastname or 'Doe',
                birthdate = data and data.birthdate or '01/01/1990',
                gender = gender,
                nationality = data and data.nationality or 'American',
                phone = exports.qbx_core:GenerateUniqueIdentifier('PhoneNumber'),
                account = exports.qbx_core:GenerateUniqueIdentifier('AccountNumber')
            }

            local playerLicense = license2 or license
            local success = MySQL.insert.await('INSERT INTO players (citizenid, name, license, charinfo, money, job, gang, position, metadata, char_slot) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                citizenid,
                GetPlayerName(source) or "Not Found",
                playerLicense,
                json.encode(charinfo),
                json.encode({cash = 500, bank = 5000, crypto = 0}),
                json.encode({name = 'unemployed', label = 'Unemployed', payment = 10, onduty = false, isboss = false, grade = {name = 'Freelancer', level = 0}}),
                json.encode({name = 'none', label = 'No Gang', isboss = false, grade = {name = 'none', level = 0}}),
                json.encode({x = -269.4, y = -955.3, z = 31.2, w = 205.8}),
                json.encode({hunger = 100, thirst = 100, stress = 0, armor = 0, isdead = false, inlaststand = false, ishandcuffed = false, tracker = false, injail = 0, jailitems = {}, status = {}, phone = {}, fitbit = {}, commandbinds = {}, inside = {house = nil, apartment = {}}, phonedata = {SerialNumber = tostring(math.random(11111111, 99999999)), InstalledApps = {}}}),
                slotToUse
            })

            if success then
                local loginSuccess = exports.qbx_core:Login(source, citizenid)
                if loginSuccess then
                    exports.qbx_core:SetPlayerBucket(source, 0)
                    return true, {citizenid = citizenid, charinfo = charinfo}
                else
                    lib.print.error(('Failed to login with new character %s for player %s'):format(citizenid, source))
                    return false, nil
                end
            else
                lib.print.error(('Failed to create character in database for player %s'):format(source))
                return false, nil
            end
        end,

        ---@param source number Player source
        ---@return table characters, number maxSlots
        getCharacters = function(source)
            local license, license2
            for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                local identifier = GetPlayerIdentifier(source, i)
                if string.find(identifier, 'license2:') then
                    license2 = identifier
                elseif string.find(identifier, 'license:') then
                    license = identifier
                end
            end

            local licenses = {}
            if license then licenses[#licenses+1] = license end
            if license2 then licenses[#licenses+1] = license2 end

            if #licenses == 0 then
                lib.print.error(('No license found for player %s'):format(source))
                return {}, 0
            end

            local characters = MySQL.query.await('SELECT * FROM players WHERE license IN (?) ORDER BY char_slot ASC, last_updated DESC', { licenses }) or {}

            for _, char in ipairs(characters) do
                if char.citizenid then
                    local appearance = MySQL.query.await('SELECT skin FROM playerskins WHERE citizenid = ? AND active = 1', {char.citizenid})
                    if appearance and appearance[1] then
                        char.skin = appearance[1].skin
                    end
                end
            end

            local maxCharacters = getAllowedAmountOfCharacters(license2, license)

            -- Backfill missing char_slot values automatically (so old NULL rows self-heal)
            local usedSlots = {}
            for _, char in ipairs(characters) do
                local s = tonumber(char.char_slot)
                if s and s >= 1 and s <= maxCharacters then
                    usedSlots[s] = true
                end
            end

            for _, char in ipairs(characters) do
                if char.citizenid and (char.char_slot == nil or char.char_slot == false or char.char_slot == '') then
                    local assigned
                    for i = 1, maxCharacters do
                        if not usedSlots[i] then
                            assigned = i
                            usedSlots[i] = true
                            break
                        end
                    end

                    if assigned then
                        char.char_slot = assigned
                        MySQL.update.await('UPDATE players SET char_slot = ? WHERE citizenid = ?', { assigned, char.citizenid })
                    end
                end
            end

            return characters, maxCharacters
        end,

        ---@param source number Player source
        ---@param characterId string Character ID
        ---@return boolean success
        loadCharacter = function(source, characterId)
            return exports.qbx_core:Login(source, characterId)
        end,

        ---@param source number Player source
        ---@param characterId string Character ID
        ---@return boolean success
        deleteCharacter = function(source, characterId)
            local license, license2
            for i = 0, GetNumPlayerIdentifiers(source) - 1 do
                local identifier = GetPlayerIdentifier(source, i)
                if string.find(identifier, 'license2:') then
                    license2 = identifier
                elseif string.find(identifier, 'license:') then
                    license = identifier
                end
            end

            if not license and not license2 then
                lib.print.error(('No license found for player %s'):format(source))
                return false
            end

            local character = MySQL.query.await('SELECT license FROM players WHERE citizenid = ?', { characterId })
            if not character or not character[1] then
                lib.print.error(('Character %s not found'):format(characterId))
                return false
            end

            local charLicense = character[1].license
            if charLicense ~= license and charLicense ~= license2 then
                lib.print.error(('Player %s tried to delete character %s that doesn\'t belong to them'):format(source, characterId))
                return false
            end

            local success = MySQL.query.await('DELETE FROM players WHERE citizenid = ?', { characterId })

            if success and success.affectedRows > 0 then
                return true
            else
                lib.print.error(('Failed to delete character %s'):format(characterId))
                return false
            end
        end,

        getPlayerData = function(source)
            return exports.qbx_core:GetPlayer(source)
        end,

        setPlayerBucket = function(source, bucket)
            exports.qbx_core:SetPlayerBucket(source, bucket or 0)
        end
    },
}

---@param source number Player source
---@param gender number Gender
---@param data table Character data
---@return boolean success, table? characterData
function Framework.createCharacter(source, gender, data)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.createCharacter then
        lib.print.error(('Framework "%s" is not supported for character creation'):format(tostring(key)))
        return false, nil
    end

    return adapter.createCharacter(source, gender, data)
end

---@param source number Player source
---@return table? characters
function Framework.getCharacters(source)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.getCharacters then
        lib.print.error(('Framework "%s" is not supported for getting characters'):format(tostring(key)))
        return nil
    end

    return adapter.getCharacters(source)
end

---@param source number Player source
---@param characterId number|string
---@return boolean success
function Framework.loadCharacter(source, characterId)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.loadCharacter then
        lib.print.error(('Framework "%s" is not supported for loading characters'):format(tostring(key)))
        return false
    end

    return adapter.loadCharacter(source, characterId)
end

---@param source number Player source
---@param characterId number|string
---@return boolean success
function Framework.deleteCharacter(source, characterId)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.deleteCharacter then
        lib.print.error(('Framework "%s" is not supported for deleting characters'):format(tostring(key)))
        return false
    end

    return adapter.deleteCharacter(source, characterId)
end

---@param source number Player source
---@return table? playerData
function Framework.getPlayerData(source)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.getPlayerData then
        lib.print.error(('Framework "%s" is not supported for getting player data'):format(tostring(key)))
        return nil
    end

    return adapter.getPlayerData(source)
end

---@param source number Player source
---@param bucket? number Routing bucket
function Framework.setPlayerBucket(source, bucket)
    local key = Config.framework
    local adapter = adapters[key]

    if not adapter or not adapter.setPlayerBucket then
        lib.print.error(('Framework "%s" is not supported for setting player bucket'):format(tostring(key)))
        return
    end

    adapter.setPlayerBucket(source, bucket)
end
