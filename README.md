<img width="2948" height="497" alt="rsg_framework" src="https://github.com/user-attachments/assets/638791d8-296d-4817-a596-785325c1b83a" />

# 🔫 rsg-weapons

**Weapon handling for RSG Framework: dual wield, serial-based equipping, weapon wear, repairs, saved loadouts and damage tuning.**

![Platform](https://img.shields.io/badge/platform-RedM-darkred)
![Framework](https://img.shields.io/badge/framework-RSG%20Core-black)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

---

## 📖 Overview

rsg-weapons controls what happens when a player uses a weapon from their inventory. Every gun is tracked by its **serial number**, so two of the same model behave as two separate weapons with their own wear and repair state.

All item and quality changes happen **on the server**. The client only reports what happened (shots fired, repair finished) and the server checks it before saving anything.

---

## ✨ Features

### 🔫 Dual wield
- Equip two one-handed guns (revolvers and pistols) at once.
- Hands fill the same way as the base game: **right hand first, then left hand**.
- Taking off the right-hand gun moves the left-hand gun across to the right.
- A third one-handed gun is refused with a message instead of breaking the loadout.
- The off-hand holster is added automatically, with the correct version for male and female characters.

### 📉 Weapon wear
- Each shot lowers the quality of the gun that fired it.
- When dual wielding, wear is shared between both hands.
- The gun's look matches its quality (dirt and wear on the model).
- At **quality 1 or less** the gun breaks: it is unequipped and the player is asked if they want to repair it.

### 🧰 Repairs
- Use a `weapon_repair_kit` while holding a gun to repair it back to 100%.
- The progress bar can be cancelled, and the kit is only used when the repair finishes.
- The server checks that the player has a kit, owns the weapon, the weapon is actually damaged, and the full repair time has passed.

### 💾 Saved loadout
- Equipped guns and knives are re-equipped automatically when the player logs in.
- Weapons that are broken or no longer in the inventory are skipped and removed from the saved list.

### 🎯 Other
- Damage multiplier per weapon (`Config.WeaponDamage`).
- Throwables (tomahawks, knives, dynamite, bolas, etc.) refill ammo through **rsg-ammo**; the server removes the item first.
- Torch support.
- `/infinityammo` for admins.
- Optional: block sprinting while aiming, disable critical hits.
- Fully localised with ox_lib JSON locales.

---

## 🛠️ Requirements

| Resource | Required | Notes |
|---|---|---|
| [rsg-core](https://github.com/Rexshack-RedM/rsg-core) | ✅ | Framework |
| [rsg-inventory](https://github.com/Rexshack-RedM/rsg-inventory) | ✅ | Sends weapon use events, stores weapon quality |
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ | Callbacks, notifications, dialogs, progress bars, locales |
| [oxmysql](https://github.com/overextended/oxmysql) | ✅ | Database |
| [rsg-ammo](https://github.com/Rexshack-RedM/rsg-ammo) | ✅ | Ammo definitions for throwable weapons |
| [rsg-weaponcomp](https://github.com/Rexshack-RedM/rsg-weaponcomp) | Optional | Weapon components (`Config.WeaponComponents = true`) |

---

## 📂 Installation

### 1. Add the resource
Place the `rsg-weapons` folder in your server's resources folder, for example `resources/[rsg]/rsg-weapons`.

### 2. Add the repair kit item
Add this line to `rsg-core/shared/items.lua`:

```lua
weapon_repair_kit = { name = 'weapon_repair_kit', label = 'Weapon Repair Kit', weight = 200, type = 'item', image = 'weapon_repair_kit.png', unique = false, useable = true, decay = 0, delete = true, shouldClose = true, description = 'Tools and oil to repair a worn weapon.' },
```

Put a `weapon_repair_kit.png` image in your inventory's image folder (`rsg-inventory/html/images/`).

### 3. Check your weapon items
rsg-weapons relies on the item `type` set in `rsg-core/shared/items.lua`:

| Item type | Used for | Example |
|---|---|---|
| `weapon` | Guns and bows (tracked by serial, wear, repair) | `weapon_revolver_cattleman` |
| `weapon_thrown` | Throwables (refill ammo, item is used up) | `weapon_thrown_tomahawk` |
| `equipment` | Knives and the torch | `weapon_melee_knife` |

Weapons get their serial (`info.serie`) and quality (`info.quality`) from rsg-inventory automatically.

### 4. Start order
In `server.cfg`, start rsg-weapons **after** its dependencies:

```cfg
ensure oxmysql
ensure ox_lib
ensure rsg-core
ensure rsg-inventory
ensure rsg-ammo
ensure rsg-weaponcomp   # optional
ensure rsg-weapons
```

### 5. Admin permission
`/infinityammo` uses the RSG `admin` permission. Make sure your admins have it, for example:

```cfg
add_principal identifier.license:YOUR_LICENSE group.admin
```

### 6. Restart
Restart the server (or `refresh` then `ensure rsg-weapons`).

---

## ⚙️ Configuration

All settings are in `config.lua`.

### General

```lua
Config.Debug = false                 -- print debug info to the F8 console
Config.WeaponComponents = true       -- sync components with rsg-weaponcomp on equip / break
Config.SaveEquippedWeapons = true    -- re-equip guns and knives on login
```

### Repair

```lua
Config.RepairTime = 30000            -- repair time in ms (also checked on the server)
```

### Wear

```lua
Config.DegradeRate = 0.01            -- quality lost per shot
Config.UpdateDegrade = 5000          -- ms between sending shot counts to the server
```

Roughly how many shots a gun lasts from 100% to broken:

| `DegradeRate` | Shots to break |
|---|---|
| `0.005` | ~19,800 |
| `0.01` | ~9,900 |
| `0.05` | ~1,980 |
| `0.1` | ~990 |

### Gameplay

```lua
Config.DisableSprintWhileAiming = true   -- players can't sprint while aiming
Config.DisableCriticalHits = false       -- true = no critical hits on any ped
```

### Damage per weapon
Each weapon has its own damage multiplier. `1.0` is normal, `0.5` is half damage, `2.0` is double.

```lua
Config.WeaponDamage = {
    {Name = 'WEAPON_REVOLVER_CATTLEMAN', Damage = 1.0},
    {Name = 'WEAPON_RIFLE_SPRINGFIELD',  Damage = 0.8},
    {Name = 'WEAPON_SHOTGUN_PUMP',       Damage = 1.2},
    -- ...
}
```

Weapons not in the list use `1.0`.

### Throwable ammo
Maps each throwable item to its ammo type in **rsg-ammo**. Using the item adds that ammo type's refill amount, up to its max.

```lua
Config.ThrowableWeaponAmmoTypes = {
    ['weapon_thrown_throwing_knives'] = 'AMMO_THROWING_KNIVES',
    ['weapon_thrown_tomahawk']        = 'AMMO_TOMAHAWK',
    ['weapon_thrown_dynamite']        = 'AMMO_DYNAMITE',
    -- ...
}
```

Only items in this list (plus `weapon_melee_torch`) can be used up by the server, so add any new throwable here.

---

## 🎮 How players use it

| Action | Result |
|---|---|
| Use a gun from the inventory | Equips it (one-handed guns go to the right hand, then the left) |
| Use the same gun again | Unequips it |
| Use a third one-handed gun | Refused: "You already have a weapon in both hands" |
| Use a repair kit while holding a gun | Starts the repair progress bar |
| Gun breaks while shooting | Unequipped, with a prompt to repair it now |
| Drop / give away an equipped gun | Automatically unequipped |
| Use a throwable | Item is used up and ammo is added |
| Use a knife | Toggles it on / off the belt |

---

## 🧑‍💼 Commands

| Command | Access | Description |
|---|---|---|
| `/infinityammo` | Admin | Toggles infinite ammo for the weapon in hand |

---

## 🌍 Locales

Text lives in `locales/*.json`. Included languages:

`en`, `cs`, `el`, `es`, `fr`, `it`, `pl`, `pt-br`, `ro`

The server language follows ox_lib's locale setting:

```cfg
setr ox:locale en
```

To add a language, copy `locales/en.json` to a new file (for example `de.json`) and translate the values. Keep the keys the same.

---

## 🧩 For developers

### Client exports

```lua
-- { [weaponHash] = serial } for every equipped weapon
local inHands = exports['rsg-weapons']:weaponInHands()

-- serial and hash of the gun in the right hand (nil if none)
local serial, hash = exports['rsg-weapons']:CheckWeaponSerial()

-- { [serial] = { name, WeaponHash, data, serie } }
local used = exports['rsg-weapons']:GetUsedWeapons()

-- one-handed guns: { { id = serial, name, hash, guid, slot = 0 (right) / 1 (left) }, ... }
local guns = exports['rsg-weapons']:EquippedWeapons()

-- unequip a weapon by name + serial
exports['rsg-weapons']:RemoveWeaponFromPeds('weapon_revolver_cattleman', serial)
```

### Client events (triggered by rsg-inventory)

| Event | Data |
|---|---|
| `rsg-weapons:client:UseWeapon` | Full weapon item (`{ name, info = { serie, quality } }`), or `{ name }` when the weapon left the inventory |
| `rsg-weapons:client:UseThrownWeapon` | Throwable item |
| `rsg-weapons:client:UseEquipment` | Knife / torch item |

### Saved data
Saved loadouts are stored in player metadata:
- `equippedweapons`: `{ [serial] = { name, serie } }`
- `equippedknives`: `{ [itemName] = true }`

---

## ❓ Troubleshooting

| Problem | Check |
|---|---|
| Second pistol won't equip | Make sure it's a one-handed gun (revolver/pistol) and you don't already have two equipped |
| Throwables do nothing | The item must be in `Config.ThrowableWeaponAmmoTypes` and rsg-ammo must be started |
| Repair does nothing | You need a `weapon_repair_kit`, must be holding the gun, and it must be below 100% |
| Weapons don't come back after relog | `Config.SaveEquippedWeapons = true`, and the weapon must still be in the inventory and not broken |
| `/infinityammo` says no permission | Give the player the `admin` permission |
| Need more info | Set `Config.Debug = true` and check the F8 console |

---

## 💎 Credits

- [qbr-weapons](https://github.com/qbcore-redm-framework/qbr-weapons)
- [qr-weapons](https://github.com/QRCore-RedM-Re/qr-weapons)
- RSG / Rexshack-RedM and the community translators

☕ Support development: [buymeacoffee.com/rexshack](https://buymeacoffee.com/rexshack)

---

## 📜 License

GPL-3.0. See [LICENSE](LICENSE).
