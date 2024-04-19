Config = {}

Config.Debug = false
Config.WeaponComponents = true -- true or false with script custom weapon (note with false can use /loadweapon for equiped) 

-- settings
-- Config.UpdateAmmo = 10000 -- amount of time before saving player ammo in miliseconds
Config.RepairTime = 30000

-- weapon degradation
Config.DegradeRate = 0.02

-- limit the amount of ammo players can load
Config.MaxArrowAmmo = 16
Config.MaxRevolverAmmo = 12
Config.MaxPistolAmmo = 20
Config.MaxRepeaterAmmo = 30
Config.MaxRifleAmmo = 20
Config.MaxElephantAmmo = 18
Config.MaxVarmintAmmo = 16
Config.MaxShotgunAmmo = 10

-- amount of ammo per load
Config.AmountArrowAmmo = 8
Config.AmountRevolverAmmo = 6
Config.AmountPistolAmmo = 10
Config.AmountRepeaterAmmo = 15
Config.AmountRifleAmmo = 10
Config.MaxElephantAmmo = 8
Config.AmountVarmintAmmo = 8
Config.AmountShotgunAmmo = 5
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

    ['weapon_thrown_dynamite'] = `AMMO_DYNAMITE` or `ammo_voldynamite`,
    ['weapon_thrown_molotov'] = `AMMO_MOLOTOV` or `ammo_volmolotov`,

    ['weapon_thrown_poisonbottle'] = `AMMO_POISONBOTTLE`
}

RSGCore = exports['rsg-core']:GetCoreObject()