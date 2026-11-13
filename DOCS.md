# rsg-weapons – Docs (v3.2.0)

## Contents
1. Files
2. How it works
3. Configuration
4. Exports and events
5. Commands
6. Security
7. Server owner how-tos
8. Troubleshooting

## 1. Files
| File | Purpose |
|---|---|
| `fxmanifest.lua` | Manifest; depends on `rsg-core`, `rsg-inventory` |
| `config.lua` | Repair time, wear, damage multipliers, throwable ammo types |
| `client/client.lua` | Equipping, dual wield, shot tracking, repair, loadout restore |
| `client/weaponclass.lua` | Weapon helper class, `EquippedWeapons`, `RemoveWeaponFromPeds` |
| `client/dataview.lua` | Buffer helper for natives |
| `server/server.lua` | Wear, repair kit, saved loadout, validation |
| `server/versionchecker.lua` | GitHub version check |
| `locales/*.json` | en, cs, de, el, es, fr, it, ja, nl, pl, pt-br, ro |

## 2. How it works
- Every gun is tracked by **serial number**, so two of the same model keep separate wear and repair state.
- **Dual wield:** right hand fills first, then left. Removing the right gun moves the left across. A third one-handed gun is refused. The off-hand holster is added automatically for male and female peds.
- **Wear:** each shot lowers the gun's quality by `DegradeRate`. Shots are batched and sent every `UpdateDegrade` ms. Dual wielding shares wear. At quality 1 or less the gun breaks and is unequipped.
- **Repair:** use a `weapon_repair_kit` on the held gun, or the most worn gun you carry. The kit is used only when the progress bar completes.
- **Saved loadout:** with `SaveEquippedWeapons`, equipped guns and knives are re-equipped on login and after a resource restart. Broken or missing weapons are dropped from the list.
- **Throwables** (tomahawks, knives, dynamite, bolas, hatchets) refill ammo through rsg-ammo after the server removes the item.
- With `Config.WeaponComponents`, components are synced with rsg-weaponcomp when equipping or breaking.

## 3. Configuration
`config.lua`:
| Option | Default | Meaning |
|---|---|---|
| `Debug` | `false` | Debug prints |
| `WeaponComponents` | `true` | Sync components with rsg-weaponcomp |
| `SaveEquippedWeapons` | `true` | Re-equip weapons and knives on login |
| `RepairTime` | `30000` | Repair progress bar ms (also enforced server-side) |
| `DegradeRate` | `0.01` | Quality lost per shot |
| `UpdateDegrade` | `5000` | ms between shot batches sent to the server |
| `DisableSprintWhileAiming` | `true` | Block sprint while aiming |
| `DisableCriticalHits` | `false` | Disable critical hits |
| `WeaponDamage` | list | `{ Name = 'WEAPON_…', Damage = 1.0 }` multiplier per weapon |
| `ThrowableWeaponAmmoTypes` | table | throwable item → ammo type |

Example, make the Cattleman 20% weaker:
```lua
{Name = 'WEAPON_REVOLVER_CATTLEMAN', Damage = 0.8},
```

## 4. Exports and events
### Client exports
| Export | Notes |
|---|---|
| `weaponInHands()` | Current weapon in hands |
| `UsedWeapons(serial)` | Equipped-state lookup by serial |
| `GetUsedWeapons()` | All equipped weapons |
| `CheckWeaponSerial()` | Serial of the held weapon |
| `EquippedWeapons()` | Equipped weapon list |
| `RemoveWeaponFromPeds` | Remove a weapon from the ped |

### Events and callbacks
| Name | Side | Notes |
|---|---|---|
| `rsg-weapons:client:UseWeapon` | client net event | Equip/unequip a weapon item |
| `rsg-weapons:client:UseThrownWeapon` | client net event | Throwable use |
| `rsg-weapons:client:UseEquipment` | client net event | Equipment (e.g. torch) |
| `rsg-weapons:client:repairweapon` | client net event | Start a repair |
| `rsg-weapons:client:weaponRepaired` | client net event | `(serial)` repair done |
| `rsg-weapons:toggle` | client net event | Infinite ammo toggle, server only |
| `rsg-weapons:server:degradeWeapon` | server net event | `(queue)` shot batch |
| `rsg-weapons:server:startRepair` | callback | Checks kit, ownership, damage |
| `rsg-weapons:server:finishRepair` | server net event | Checks elapsed time, removes the kit |
| `rsg-weapons:server:cancelRepair` | server net event | Cancel repair |
| `rsg-weapons:server:consumeItem` | callback | Throwables and torch only |
| `rsg-weapons:server:saveEquippedWeapon` / `saveEquippedKnife` | server net events | Saved loadout |
| `rsg-weapons:server:getEquipped` | callback | Loadout on login |
| `rsg-weapons:requestToggle` | server net event | Infinite ammo, admin only |

## 5. Commands
| Command | Who | What |
|---|---|---|
| `/infinityammo` | admin (server checks) | Toggle infinite ammo for the held weapon |

## 6. Security
All item and quality changes happen on the server. The client only reports shots and repair completion. The server checks the kit, weapon ownership, that the weapon is damaged and that the full repair time passed. Only whitelisted items (throwables, torch) can be consumed through the client request. The admin command is permission-checked and rate-limited.

## 7. How-tos
- Repair item: `weapon_repair_kit` must exist in `items.lua`.
- Language: `setr rsg:locale "de"` in server.cfg.
- Turn off wear: set `DegradeRate = 0`.

## 8. Troubleshooting
| Problem | Fix |
|---|---|
| Weapon broke | Use a `weapon_repair_kit` |
| Third pistol refused | Dual wield holds two one-handed guns |
| Throwable has no ammo | Start rsg-ammo and check `ThrowableWeaponAmmoTypes` |
| Loadout not restored | `SaveEquippedWeapons = true`; the item must still be in the inventory |

Support the Project : https://rexshack.tebex.store/
