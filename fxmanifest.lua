fx_version "cerulean"
game "gta5"

author "Snowy"
version "2.0"
license "GPL-3.0"
description "Snowy Multicharacter for Qbox framework"

client_scripts {
    "client/main.lua",
    "client/framework.lua",
    "client/bridge.lua",
    "client/selector.lua",
    "client/creator.lua",
    "client/spawn.lua"
}

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/framework.lua",
    "server/main.lua",
}

dependencies  {
    "ox_lib",
    "oxmysql"
}

ox_lib 'locale'

ui_page "html/index.html"

files {
    "locales/*.json",
    "html/index.html",
    "data/peds.meta"
}
data_file 'PED_METADATA_FILE' 'data/peds.meta'
