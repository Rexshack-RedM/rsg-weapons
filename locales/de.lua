local Translations = {
    error = {
        no_arrows_your_inventory_load = 'Keine Pfeile in deinem Inventar zum Laden',
        max_mmo_capacity = 'Maximale Munitionskapazität',
        wrong_ammo_for_weapon = 'Falsche Munition für die Waffe!',
        you_are_not_holding_weapon = 'Du hältst keine Waffe!',
    },
    success = {
        weapon_reloaded = 'Waffe nachgeladen',
    },
    primary = {
        var = 'Hier steht der Text',
    },
    menu = {
        var = 'Hier steht der Text',
    },
    commands = {
        var = 'Hier steht der Text',
    },
    progressbar = {
        var = 'Hier steht der Text',
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
