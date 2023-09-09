local Translations = {
error = {
    no_arrows_your_inventory_load = 'nenhuma flecha em seu inventário para carregar',
    max_mmo_capacity = 'Capacidade Máxima de Munição',
    wrong_ammo_for_weapon = 'munição errada para a arma!',
    you_are_not_holding_weapon = 'você não está segurando uma arma!',
},
success = {
    weapon_reloaded = 'Arma Recarregada',
},
primary = {
    var = 'o texto vai aqui',
},
menu = {
    var = 'o texto vai aqui',
},
commands = {
    var = 'o texto vai aqui',
},
progressbar = {
    var = 'o texto vai aqui',
},
}

if GetConvar('rsg_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
