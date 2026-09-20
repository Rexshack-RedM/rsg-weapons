fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-wagons'
version '2.0.3'
author 'rex and phil'
ox_lib 'locale'
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependencies {
    'ox_lib',
}

ui_page 'html/index.html'

files {
    'locales/*.json',
    'images/*.png',
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'
