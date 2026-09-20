Config = {}

Config.Debug = false
Config.WeaponComponents = true -- true or false with script custom weapon (note with false can use /loadweapon for equiped) 

Config.SaveEquippedWeapons = true

-- settings
--Config.UpdateAmmo = 10000 -- amount of time before saving player ammo in miliseconds
Config.RepairTime = 30000

-- weapon degradation
Config.DegradeRate = 0.01
Config.UpdateDegrade = 5000

Config.DisableSprintWhileAiming = true

--- Damage Weapon
Config.DisableCriticalHits = false 
Config.WeaponDamage = {
    -- Melee
    {Name = 'WEAPON_UNARMED', Damage = 1.0},
    {Name = 'WEAPON_MELEE_CLEAVER', Damage = 1.0},
    {Name = 'WEAPON_MELEE_HAMMER', Damage = 1.0},
    {Name = 'WEAPON_MELEE_HATCHET', Damage = 1.0},
    {Name = 'WEAPON_MELEE_HATCHET_HUNTER', Damage = 1.0},
    {Name = 'WEAPON_MELEE_KNIFE', Damage = 1.0},
    {Name = 'WEAPON_MELEE_KNIFE_HORROR', Damage = 1.0},
    {Name = 'WEAPON_MELEE_KNIFE_JAWBONE', Damage = 1.0},
    {Name = 'WEAPON_MELEE_KNIFE_RUSTIC', Damage = 1.0},
    {Name = 'WEAPON_MELEE_KNIFE_TRADER', Damage = 1.0},
    {Name = 'WEAPON_MELEE_MACHETE', Damage = 1.0},
    {Name = 'WEAPON_MELEE_MACHETE_COLLECTOR', Damage = 1.0},
    {Name = 'WEAPON_MELEE_MACHETE_HORROR', Damage = 1.0},

    -- Revolver
    {Name = 'WEAPON_REVOLVER_CATTLEMAN', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_CATTLEMAN_MEXICAN', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_DOUBLEACTION', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_DOUBLEACTION_GAMBLER', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_LEMAT', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_NAVY', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_NAVY_CROSSOVER', Damage = 1.0},
    {Name = 'WEAPON_REVOLVER_SCHOFIELD', Damage = 1.0},

    -- Pistols
    {Name = 'WEAPON_PISTOL_M1899', Damage = 1.0},
    {Name = 'WEAPON_PISTOL_MAUSER', Damage = 1.0},
    {Name = 'WEAPON_PISTOL_SEMIAUTO', Damage = 1.0},
    {Name = 'WEAPON_PISTOL_VOLCANIC', Damage = 1.0},

    -- Snipers
    {Name = 'WEAPON_SNIPERRIFLE_CARCANO', Damage = 1.0},
    {Name = 'WEAPON_SNIPERRIFLE_ROLLINGBLOCK', Damage = 1.0},

    -- Rifle
    {Name = 'WEAPON_RIFLE_BOLTACTION', Damage = 1.0},
    {Name = 'WEAPON_RIFLE_ELEPHANT', Damage = 1.0},
    {Name = 'WEAPON_RIFLE_SPRINGFIELD', Damage = 1.0},
    {Name = 'WEAPON_RIFLE_VARMINT', Damage = 1.0},

    -- Repeater
    {Name = 'WEAPON_REPEATER_CARBINE', Damage = 1.0},
    {Name = 'WEAPON_REPEATER_EVANS', Damage = 1.0},
    {Name = 'WEAPON_REPEATER_HENRY', Damage = 1.0},
    {Name = 'WEAPON_REPEATER_WINCHESTER', Damage = 1.0},

    -- Thrown
    {Name = 'WEAPON_THROWN_DYNAMITE', Damage = 1.0},
    {Name = 'WEAPON_THROWN_POISONBOTTLE', Damage = 1.0},
    {Name = 'WEAPON_THROWN_THROWING_KNIVES', Damage = 1.0},
    {Name = 'WEAPON_THROWN_TOMAHAWK', Damage = 1.0},
    {Name = 'WEAPON_THROWN_TOMAHAWK_ANCIENT', Damage = 1.0},
    --[[ {Name = 'WEAPON_THROWN_MOLOTOV', Damage = 1.0}, ]] -- Has no effect

    -- Shotgun
    {Name = 'WEAPON_SHOTGUN_DOUBLEBARREL', Damage = 1.0},
    {Name = 'WEAPON_SHOTGUN_PUMP', Damage = 1.0},
    {Name = 'WEAPON_SHOTGUN_REPEATING', Damage = 1.0},
    {Name = 'WEAPON_SHOTGUN_SAWEDOFF', Damage = 1.0},
    {Name = 'WEAPON_SHOTGUN_SEMIAUTO', Damage = 1.0},

    -- Bows
    {Name = 'WEAPON_BOW', Damage = 1.0},
    {Name = 'WEAPON_BOW_IMPROVED', Damage = 1.0},
}

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