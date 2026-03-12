

---@param source number Player source
---@param data table Character creation data
---@return table? Character data if successful
lib.callback.register("snowy_characterselector:server:createCharacter", function(source, data)
    local success, characterData = Framework.createCharacter(source, data.gender, data)

    if not success then
        lib.print.error(('Character creation failed for player %s'):format(source))
        return nil
    end
    GiveStarterItems(source)
    return characterData
end)

---@param source number Player source
---@return table { characters: table, maxSlots: number }
lib.callback.register("snowy_characterselector:server:getCharacters", function(source)
    local characters, maxSlots = Framework.getCharacters(source)
    print(#characters, maxSlots)
    return { characters = characters, maxSlots = maxSlots }
end)

---@param source number Player source
---@param characterId string Character ID to load
---@return boolean success
lib.callback.register("snowy_characterselector:server:loadCharacter", function(source, characterId)
    local success = Framework.loadCharacter(source, characterId)
    local Player = Framework.getPlayerData(source)
    if Player and Config.Spawn.useCustomSpawn then
        local pos = vec3(Player.PlayerData.position.x, Player.PlayerData.position.y, Player.PlayerData.position.z) or Config.Spawn.defaultSpawn.coords
        local heading = Player.PlayerData.position.w or Config.Spawn.defaultSpawn.heading
        lib.callback.await("snowy_characterselector:client:spawnNormal", source, pos, heading, Player.PlayerData.charinfo.gender == 0 and 'mp_m_freemode_01' or 'mp_f_freemode_01')
    end
    return success
end)

---@param source number Player source
---@param characterId string Character ID to delete
---@return boolean success
lib.callback.register("snowy_characterselector:server:deleteCharacter", function(source, characterId)
    if not Config.CharacterDeletion.allowDeletion then
        return false
    end
    return Framework.deleteCharacter(source, characterId)
end)
