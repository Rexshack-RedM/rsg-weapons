local Translations = {
    error = {
        no_arrows_your_inventory_load = 'no hay flechas en su inventario para cargar',
        max_mmo_capacity = 'Capacidad máxima de munición',
        wrong_ammo_for_weapon = '¡munición incorrecta para el arma!',
        you_are_not_holding_weapon = '¡No estás sosteniendo un arma!',
        weapon_degraded = '¡El arma está degradada!',
        no_weapon_found = 'No se encontró ningún arma',
        no_weapon_found_desc = 'debes estar sosteniendo el arma',
    },
    success = {
        weapon_reloaded = 'Arma Recargada',
        weapon_repaired = 'Arma Reparada',
        reapir_yes = 'Yes',
        item_need = 'Artículo necesario',
        item_need_desc = '¡Se necesita un kit de reparación de armas!',
    },
    primary = {
        var = 'text goes here',
    },
    menu = {
        var = 'text goes here',
    },
    commands = {
        var = 'text goes here',
    },
    progressbar = {
        repairing_weapon = 'Reparador de armas '
    },
}

if GetConvar('rsg_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
