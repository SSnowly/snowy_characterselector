---@class AppearanceBridge
---@field getDefaultClothes fun(gender: string, modelHash: number, cb: fun(data: table?))

Bridge = {}

local adapters = {
    ['illenium-appearance'] = function(gender, modelHash, cb)
        local success, data = pcall(function()
            return lib.callback.await('illenium-appearance:server:GetDefaultAppearance', false, gender, modelHash)
        end)
        if success and data then
            cb({ clothes = data, underwears = data })
        else
            cb(nil)
        end
    end,
}

---@param gender string
---@param modelHash number
---@param cb fun(data: table?)
function Bridge.getDefaultClothes(gender, modelHash, cb)
    local key = Config.appearance
    local adapter = adapters[key]
    if not adapter then
        lib.notify({ type = 'error', description = ('Appearance "%s" is not supported.'):format(tostring(key)) })
        cb(nil)
        return
    end
    adapter(gender, modelHash, cb)
end
