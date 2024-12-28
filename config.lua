Config = {}

Config.Debug = false
Config.WeaponComponents = true -- true or false with script custom weapon (note with false can use /loadweapon for equiped) 

-- settings
--Config.UpdateAmmo = 10000 -- amount of time before saving player ammo in miliseconds
Config.RepairTime = 30000

-- weapon degradation
Config.DegradeRate = 0.01

--- Damage Weapon
Config.WeaponDmg = 0.65
Config.MeleeDmg = 1.0

Config.ThrowableWeaponAmmoTypes = {
    ['weapon_thrown_throwing_knives'] = 'AMMO_THROWING_KNIVES',
    ['weapon_thrown_tomahawk'] = 'AMMO_TOMAHAWK',
    ['weapon_thrown_tomahawk_ancient'] = 'AMMO_TOMAHAWK_ANCIENT',
    ['weapon_thrown_bolas'] = 'AMMO_BOLAS',
    ['weapon_thrown_bolas_hawkmoth'] = 'AMMO_BOLAS_HAWKMOTH',
    ['weapon_thrown_bolas_ironspiked'] = 'AMMO_BOLAS_IRONSPIKED',
    ['weapon_thrown_bolas_intertwined']  = 'AMMO_BOLAS_INTERTWINED',
    ['weapon_thrown_dynamite'] = 'AMMO_DYNAMITE',
    ['weapon_thrown_molotov'] = 'AMMO_MOLOTOV',
    ['weapon_thrown_poisonbottle'] = 'AMMO_POISONBOTTLE',
    ['weapon_melee_hatchet'] = 'AMMO_HATCHET',
    ['weapon_melee_hatchet_hunter'] = 'AMMO_HATCHET_HUNTER',
    ['weapon_melee_cleaver'] = 'AMMO_HATCHET_CLEAVER',
}
