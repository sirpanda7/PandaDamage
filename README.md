# PandaDamage

A simple, lightweight, no-fuss Roblox Luau damage calculator and applicator.

## Features
* **Built-in Lifesteal and Thorns:** Calculates lifesteal and thorns and applies them, if desired.
* **Kill Tracking:** Automatically tracks the ``LastAttacker`` attribute on players with adjustable timeouts.
* **Extensible Hooks:** Override the ``OnKill`` configuration hook to tie into your game's XP and Kill Reward systems.

---

## Installation & Setup
1. Insert ``PandaDamage.luau`` into a shared folder (such as ``ReplicatedStorage`` or ``ServerStorage``).
2. Require the module in your server-side combat scripts:

```lua
local PandaDamage = require(game:GetService("ReplicatedStorage").PandaDamage)
```

## Configuration
You can easily customize settings and hooks via the ``PandaDamage.CONFIG`` table at the top of the script or through a different server-side script:

```lua
PandaDamage.CONFIG.OVERALL_DAMAGE_MULTIPLIER = 1.5
PandaDamage.CONFIG.THORNS_MODE = "Target"
PandaDamage.CONFIG.OnKill = function(killer: Player, victim: Player)
    print(`{killer.Name} killed {victim.Name}`)
    -- Add your XP, currency, or stat logic here!
end
```

## Usage
```lua
PandaDamage.ApplyDamage(attacker, target, baseDamage, multipliers)
```
Applies calculated damage to a target player, process lifesteal/thorns (if passed in multipliers), and handles kill credit.
* ``attacker`` (``Player``): The player dealing the damage.
* ``target`` (``Player``): The player receiving the damage.
* ``baseDamage`` (``number``): The raw base damage value.
* ``multipliers`` (``DamageMultipliers?``): A table of modifiers to adjust the damage amount. (Optional)

### Example Call
```lua
local Players = game:GetService("Players")
local PandaDamage = require(game:GetService("ReplicatedStorage").PandaDamage)

local attacker = Players.LocalPlayer -- Or retrieved from a remote event
local target = game.Workspace.TargetPlayer -- Or resolved target player

local customMultipliers = {
    Combo = 2, -- Dealt damage is multiplied by the combo (adjusted by the COMBO_FACTOR)
    DamageMultiplier = 1.5, -- The attacker deals 1.5x as much damage as usual
    DamageTakenMultiplier = 1, -- The target takes 1x damage
    LifestealPercent = 0.1, -- Heals attacker for 10% of dealt damage
    ThornsPercent = 0.05,   -- Reflects 5% back onto the attacker
}

PandaDamage.ApplyDamage(attacker, target, 15, customMultipliers)
```




