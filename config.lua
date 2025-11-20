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

---------------------------------------------------------------------
-- Weapon Limit System
---------------------------------------------------------------------
-- Weapon category limits: Controls how many weapons of each type a player can carry
Config.WeaponLimits = {
    longgun = 1,    -- Rifles, Repeaters, Shotguns, Bows (1 on back)
    pistol = 2,     -- Pistols, Revolvers (2 holsters)
    melee = 1,      -- Melee weapons (Knives, Machetes, Hatchets)
    tools = 2,      -- Tools (Lasso, Lantern, Torch, etc.)
    throwable = 5,  -- Throwables (Dynamite, Throwing Knives, Tomahawks)
    other = 1       -- Other weapons
}

-- German names for weapon categories (for notifications)
Config.WeaponCategoryNames = {
    longgun = "Langwaffe", -- Rifles, Repeaters, Shotguns, Bows
    pistol = "Pistole/Revolver", -- Pistols and Revolvers
    melee = "Nahkampfwaffe", -- Melee weapons
    tools = "Werkzeug", -- Tools
    throwable = "Wurfwaffe", -- Throwables
    other = "andere Waffe" -- Other weapons
}

-- Manual weapon category assignments (for special cases)
-- Most weapons are auto-categorized by their name patterns
Config.WeaponCategories = {
    -- Special cases that don't follow standard naming patterns
    ['improved_bow'] = 'longgun',
    ['tomahawk'] = 'throwable',
}

---------------------------------------------------------------------
-- Automatic weapon categorization based on weapon name patterns
---------------------------------------------------------------------
Config.AutoCategorizeWeapon = function(weaponName)
    -- Check if weapon is already manually categorized
    if Config.WeaponCategories[weaponName] then
        return Config.WeaponCategories[weaponName]
    end
    
    -- Pistols and Revolvers (sidearms)
    if string.find(weaponName, "pistol") or string.find(weaponName, "revolver") then
        return "pistol"
    end
    
    -- Long guns (Rifles, Repeaters, Shotguns, Bows)
    if string.find(weaponName, "rifle") or 
       string.find(weaponName, "repeater") or 
       string.find(weaponName, "shotgun") or 
       string.find(weaponName, "sniperrifle") or
       string.find(weaponName, "bow") then
        return "longgun"
    end
    
    -- Melee weapons
    if string.find(weaponName, "knife") or 
       string.find(weaponName, "hatchet") or 
       string.find(weaponName, "machete") or
       string.find(weaponName, "cleaver") or
       string.find(weaponName, "tomahawk") or
       string.find(weaponName, "hammer") then
        return "melee"
    end
    
    -- Tools
    if string.find(weaponName, "lasso") or 
       string.find(weaponName, "fishingrod") or 
       string.find(weaponName, "lantern") or 
       string.find(weaponName, "torch") or 
       string.find(weaponName, "camera") or
       string.find(weaponName, "binoculars") then
        return "tools"
    end
    
    -- Throwables and explosives
    if string.find(weaponName, "thrown") or 
       string.find(weaponName, "dynamite") or
       string.find(weaponName, "molotov") or
       string.find(weaponName, "bolas") then
        return "throwable"
    end
    
    -- Default fallback
    return "other"
end

---------------------------------------------------------------------
-- Get weapon category (with automatic categorization fallback)
---------------------------------------------------------------------
Config.GetWeaponCategory = function(weaponName)
    return Config.WeaponCategories[weaponName] or Config.AutoCategorizeWeapon(weaponName)
end

---------------------------------------------------------------------
-- Weapon Damage Configuration
---------------------------------------------------------------------
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

---------------------------------------------------------------------
-- Initialize weapon categories at runtime from RSGCore items
---------------------------------------------------------------------
CreateThread(function()
    -- Wait for RSGCore to load
    Wait(1000)
    
    if RSGCore and RSGCore.Shared and RSGCore.Shared.Items then
        if Config.Debug then
            print("🔫 Loading weapon categories from RSGCore...")
        end
        
        for itemName, itemData in pairs(RSGCore.Shared.Items) do
            -- Check if it's a weapon
            if itemData.type == 'weapon' or itemData.type == 'equipment' or itemData.type == 'weapon_thrown' then
                if string.find(itemName, "weapon_") then
                    Config.WeaponCategories[itemName] = Config.AutoCategorizeWeapon(itemName)
                    if Config.Debug then
                        print("Categorized: " .. itemName .. " -> " .. Config.WeaponCategories[itemName])
                    end
                end
            end
        end
        
        if Config.Debug then
            print("✅ Weapon categories successfully loaded!")
        end
    else
        if Config.Debug then
            print("⚠️ RSGCore not available, using automatic categorization")
        end
    end
end)

---------------------------------------------------------------------
-- Weapon Ammo Type Mappings
---------------------------------------------------------------------
Config.WeaponAmmoTypes = {
    ['weapon_revolver_cattleman'] = 'AMMO_REVOLVER',
    ['weapon_revolver_cattleman_mexican'] = 'AMMO_REVOLVER',
    ['weapon_revolver_doubleaction'] = 'AMMO_REVOLVER',
    ['weapon_revolver_doubleaction_gambler'] = 'AMMO_REVOLVER',
    ['weapon_revolver_schofield'] = 'AMMO_REVOLVER',
    ['weapon_revolver_lemat'] = 'AMMO_REVOLVER',
    ['weapon_revolver_navy'] = 'AMMO_REVOLVER',
    ['weapon_pistol_volcanic'] = 'AMMO_PISTOL',
    ['weapon_pistol_m1899'] = 'AMMO_PISTOL',
    ['weapon_pistol_mauser'] = 'AMMO_PISTOL',
    ['weapon_pistol_semiauto'] = 'AMMO_PISTOL',
    ['weapon_rifle_boltaction'] = 'AMMO_RIFLE',
    ['weapon_rifle_springfield'] = 'AMMO_RIFLE',
    ['weapon_rifle_varmint'] = 'AMMO_RIFLE_VARMINT',
    ['weapon_rifle_carcano'] = 'AMMO_RIFLE',
    ['weapon_rifle_elephant'] = 'AMMO_RIFLE_ELEPHANT',
    ['weapon_sniperrifle_carcano'] = 'AMMO_RIFLE',
    ['weapon_sniperrifle_rollingblock'] = 'AMMO_RIFLE',
    ['weapon_repeater_carbine'] = 'AMMO_REPEATER',
    ['weapon_repeater_henry'] = 'AMMO_REPEATER',
    ['weapon_repeater_evans'] = 'AMMO_REPEATER',
    ['weapon_repeater_winchester'] = 'AMMO_REPEATER',
    ['weapon_shotgun_doublebarrel'] = 'AMMO_SHOTGUN',
    ['weapon_shotgun_pump'] = 'AMMO_SHOTGUN',
    ['weapon_shotgun_repeating'] = 'AMMO_SHOTGUN',
    ['weapon_shotgun_sawed'] = 'AMMO_SHOTGUN',
    ['weapon_shotgun_semiauto'] = 'AMMO_SHOTGUN',
    ['weapon_bow'] = 'AMMO_ARROW',
    ['weapon_bow_improved'] = 'AMMO_ARROW_IMPROVED',
    ['weapon_thrown_throwing_knives'] = 'AMMO_THROWING_KNIVES',
    ['weapon_thrown_tomahawk'] = 'AMMO_TOMAHAWK',
    ['weapon_thrown_tomahawk_ancient'] = 'AMMO_TOMAHAWK_ANCIENT',
    ['weapon_thrown_bolas'] = 'AMMO_BOLAS',
    ['weapon_thrown_bolas_hawkmoth'] = 'AMMO_BOLAS_HAWKMOTH',
    ['weapon_thrown_bolas_ironspiked'] = 'AMMO_BOLAS_IRONSPIKED',
    ['weapon_thrown_bolas_intertwined'] = 'AMMO_BOLAS_INTERTWINED',
    ['weapon_thrown_dynamite'] = 'AMMO_DYNAMITE',
    ['weapon_thrown_molotov'] = 'AMMO_MOLOTOV',
    ['weapon_thrown_poisonbottle'] = 'AMMO_POISONBOTTLE',
}