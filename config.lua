Config = {}
Config.Debug = true
Config.appearance = 'illenium-appearance' -- supports: "illenium-appearance"
Config.framework = 'qbx_core' -- supports: "qbx_core"
Config.Selector = {
    camera = {
        coords = vec3(-782.0007, 341.9744, 213.1713),
        rotation = vec3(-27.2875, -0.0000, -176.9356)
    },
    interior = {
        coords = vec3(-773.407, 341.766, 211.397)
    },
    player = {
        coords = vec3(-769.5869, 335.1765, 211.3971)
    },
    positions = {
        {
            coords = vec3(-782.0049, 336.6557, 211.2327),
            heading = 13.9067,
            animation = {
                dict = "anim@heists@heist_safehouse_intro@variations@male@tv",
                name = "tv_part_one_loop"
            }
        },
        {
            coords = vec3(-783.3555, 337.7827, 211.2329),
            heading = 278.0073,
            animation = {
                dict = "timetable@ron@ig_3_couch",
                name = "base"
            }
        },
        {
            coords = vec3(-780.2003, 338.7839, 211.1970),
            heading = 114.6381,
            animation = {
                dict = "timetable@reunited@ig_10",
                name = "base_amanda"
            }
        },
        {
            coords = vec3(-780.1037, 337.0664, 211.1970),
            heading = 99.6381,
            animation = {
                dict = "timetable@ron@ig_5_p3",
                name = "ig_5_p3_base"
            }
        }
    },
    skin = {
        cloth = {
            mask = 0, maskcolor = 0, torso1 = 0, torso1color = 0,
            shirt = 0, shirtcolor = 0, accessory = 0, accessorycolor = 0,
            accessory2 = 0, accessory2color = 0, earrings = 0, earringscolor = 0,
            hat = 0, hatcolor = 0, torso2 = 0, torso2color = 0,
            pants = 0, pantscolor = 0, shoes = 0, shoecolor = 0,
            bags = 0, bagscolor = 0, badges = 0, badgescolor = 0,
            glasses = 0, glassescolor = 0, watch = 0, watchcolor = 0
        },
        wears = {
            mask = false, cap = false,
            glasses = false, shirt = true,
            cloack = true, pants = true,
            shoes = true, necklace = false,
            armor = false, hairBand = false,
            vest = false, badge = false, bag = false,
        }
    },
    empty = {
        ped = "char_selector_male"
    }
}

Config.Creator = {
    interior = {
        coords = vec3(-773.407, 341.766, 211.397)
    },
    ped = {
        gender = {
            man = {
                model = "char_selector_male"
            },
            woman = {
                model = "char_selector_female"
            }
        },
        position = {
            coords = vec3(-772.9800, 342.8023, 211.3971),
            heading = 178.9256
        }
    },
    camera = {
        coords = vec3(-772.9119, 340.2855, 211.9378),
        rotation = vec3(-1.5001, -0.0000, -1.1483)
    },
    customizer = {
        coords = vec3(-772.9800, 342.8023, 211.3971),
        heading = 178.9256
    }
}

Config.Gender = {
    man = "mp_m_freemode_01",
    woman = "mp_f_freemode_01"
}


Config.Spawn = {
    useCustomSpawn = true, -- if false it will not spawn the player, instead initiate the event itself for any spawn selectors etc to spawn the player
    defaultSpawn = {
        coords = vec3(-542.3136, -208.9639, 37.6498),
        heading = 209.9319
    }
}


Config.CharacterDeletion = {
    allowDeletion = true, -- allows deleting a character
    useBulletShootAsDeletion = true, -- shoots the ped in the face, can be disabled for anticheats
}


Config.StarterItems = { -- straight up taken from qbx_core lmao
        { name = 'phone', amount = 1 },
        { name = 'id_card', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'id_card'})
            end
        },
        { name = 'driver_license', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'driver_license'})
            end
        },
}

Config.Characters = {
    defaultNumberOfCharacters = 3,
    playersNumberOfCharacters = {
        ["license"] = 4,
        ["license2"] = 7,
    }
}