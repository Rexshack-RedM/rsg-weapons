fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

description 'rsg-weapons'
version '3.2.0'

shared_scripts {
    '@rsg-core/shared/locale.lua',
    'config.lua',
}

client_scripts {
    'client/dataview.lua',
    'client/weaponclass.lua',
    'client/client.lua',
}

server_scripts {
    'server/server.lua',
    'server/versionchecker.lua',
}

files {
    'locales/*.json',
}

dependencies {
    'rsg-core',
    'rsg-inventory',
}
