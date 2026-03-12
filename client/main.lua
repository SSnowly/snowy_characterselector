Data = {}

lib.locale()

if Config.Debug then
    RegisterCommand('getcampos', function()
        local coords = GetFinalRenderedCamCoord()
        local rot = GetFinalRenderedCamRot(2)
        local s = ('vec3(%.4f, %.4f, %.4f)'):format(coords.x, coords.y, coords.z)
        local r = ('vec3(%.4f, %.4f, %.4f)'):format(rot.x, rot.y, rot.z)
        lib.notify({ title = 'Camera position', description = ('Coords: %s  |  Rotation: %s'):format(s, r), duration = 8000 })
        print(('[getcampos] coords = %s'):format(s))
        print(('[getcampos] rotation = %s'):format(r))
    end, false)

    RegisterCommand('getcharpos', function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local s = ('vec3(%.4f, %.4f, %.4f)'):format(coords.x, coords.y, coords.z)
        lib.notify({ title = 'Character position', description = ('Coords: %s  |  Heading: %.2f'):format(s, heading), duration = 8000 })
        print(('[getcharpos] coords = %s'):format(s))
        print(('[getcharpos] heading = %.4f'):format(heading))
    end, false)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        Selector.Remove()
        Creator.Remove()
    end
end)
