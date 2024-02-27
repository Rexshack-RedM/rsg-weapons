Config = {}

Config.Debug = false

-- settings
--Config.UpdateAmmo = 10000 -- amount of time before saving player ammo in miliseconds
Config.RepairTime = 30000
Config.EasyReload = true        -- Set to false if you want to disable easy reload
Config.AmmoReloadKeybind = 'R'
-- weapon degradation
Config.DegradeRate = 0.01

-- limit the amount of ammo players can load
Config.MaxArrowAmmo = 12
Config.MaxRevolverAmmo = 12
Config.MaxPistolAmmo = 12
Config.MaxRepeaterAmmo = 12
Config.MaxRifleAmmo = 12
Config.MaxVarmintAmmo = 28
Config.MaxShotgunAmmo = 12

-- amount of ammo per load
Config.AmountArrowAmmo = 8
Config.AmountRevolverAmmo = 12
Config.AmountPistolAmmo = 12
Config.AmountRepeaterAmmo = 12
Config.AmountRifleAmmo = 12
Config.AmountVarmintAmmo = 28
Config.AmountShotgunAmmo = 12
Config.AmountThrowablesAmmo = 1

--- Damage Weapon
Config.WeaponDmg = 0.65
Config.MeleeDmg = 1.0

Config.AmmoTypes = {
    ['weapon_thrown_throwing_knives'] = `AMMO_THROWING_KNIVES`,
    ['weapon_thrown_tomahawk'] = `AMMO_TOMAHAWK`,
    ['weapon_thrown_tomahawk_ancient'] = `AMMO_TOMAHAWK_ANCIENT`,
    ['weapon_thrown_bolas'] = `AMMO_BOLAS`,
    ['weapon_thrown_bolas_hawkmoth'] = `AMMO_BOLAS_HAWKMOTH`,
    ['weapon_thrown_bolas_ironspiked'] = `AMMO_BOLAS_IRONSPIKED`,
    ['weapon_thrown_bolas_intertwined']  = `AMMO_BOLAS_INTERTWINED`,
    ['weapon_thrown_dynamite'] = `AMMO_DYNAMITE`,
    ['weapon_thrown_molotov'] = `AMMO_MOLOTOV`,
    ['weapon_thrown_poisonbottle'] = `AMMO_POISONBOTTLE`
}

