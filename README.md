# Godot Contra-like prototype

A Godot 4 prototype built around reusable, drop-in modules.

The guiding principle: every module works as a drag-and-drop child node with no assumptions about its owner. A `HealthModule` on a player, an enemy, or a barrel behaves identically. Modules communicate exclusively through signals, which keeps them replaceable without touching unrelated code.

The coordinator (the owner scene) is responsible for connecting modules together. That is by design: the modules are agnostic, the coordinator is not.

---

## Design Philosophy

- **Drag and drop** - add a module as a child node and it works.
- **Drop-in replaceable** - swap `Semiauto` for `Shotgun` by changing one child node.
- **Signal-only communication** - modules never reach outside their own subtree.
- **Owner-agnostic** - no module assumes it lives inside a player, an enemy, or any specific scene.
- **Duck-typed contracts** - hitboxes and weapons are not coupled to a base class. Any node that implements the expected methods qualifies.

---

## Project Setup

Before running any scene, configure the following in the Godot editor.

### 1. Autoload

| Script | Name |
|---|---|
| `bullet_pool.gd` | `BulletPool` |

`Project > Autoload > Add`

The name must be `BulletPool` exactly. Scripts that call `BulletPool.request()` will fail at runtime otherwise.

### 2. Physics Layer Names

`Project > Project Settings > Layer Names > 2D Physics`

```
Layer 1: world
Layer 2: player
Layer 3: enemy
Layer 4: player_bullet
Layer 5: enemy_bullet
```

### 3. Input Map

`Project > Project Settings > Input Map`

| Action | Suggested key |
|---|---|
| `shoot` | Z |
| `weapon_next` | E |
| `weapon_prev` | Q |

`ui_left`, `ui_right`, `ui_accept` are Godot defaults and require no setup.

---

## Modules

### `health.gd` - HealthModule
Tracks current and max health. Emits `died`, `health_changed`, `revived`.
No assumptions about owner type. Works on players, enemies, and props.

### `hurtbox.gd` - HurtboxModule
Detects incoming hitboxes via `Area2D`. Emits `damage_received`, `knockback_received`, and `hurt`.
The owner's coordinator connects `damage_received` to `HealthModule.take_damage` in `_ready`.
Knockback is optional: the hitbox only needs to implement `get_knockback()` if knockback is intended.

### `weapon_slot.gd` - WeaponSlot
Manages the active weapon. Supports cyclic swap via `equip_next()` / `equip_previous()`.
All child weapon nodes are disabled at startup except `default_weapon_index`.
Delegates shooting to the active weapon via `try_shoot(muzzle, direction)`.

### `semiauto.gd` - Semiauto
One shot per input press. Enforces a configurable fire rate (default 100ms).
Requires `bullet_scene` assigned in the Inspector. Calls `BulletPool.prewarm()` on `_ready`.

### `bullet_pool.gd` - BulletPool *(Autoload)*
Generic object pool keyed by `PackedScene`. Supports any number of projectile types simultaneously.
Initial pool size is 20 per scene. Grows automatically if the pool is exhausted.
Call `prewarm(scene)` during `_ready` of any weapon to avoid the first-frame instantiation spike.

### `bullet.gd` - Bullet
Base projectile. Releases itself back to the pool on collision or on `screen_exited`.
Implements `launch(direction)` and `get_damage()` as required contracts.

---

## Scene Structure

### Player.tscn
```
Player  (CharacterBody2D + player.gd)
├── CollisionShape2D          # Layer: player        Mask: world
├── HealthModule  (Node       + health.gd)
├── HurtboxModule (Area2D     + hurtbox.gd)
│   └── CollisionShape2D      # Layer: player        Mask: enemy | enemy_bullet
├── WeaponSlot    (Node2D     + weapon_slot.gd)
│   └── Semiauto  (Node2D     + semiauto.gd)
└── Visuals       (Node2D)
    ├── Sprite2D
    └── Muzzle    (Marker2D)
```

`player.gd` connects `HurtboxModule.damage_received` → `HealthModule.take_damage` and `HealthModule.died` → `_on_died` in `_ready`. This is the only place where modules are coupled; the modules themselves have no knowledge of each other.

### Bullet.tscn
```
Bullet  (Area2D + bullet.gd)
├── CollisionShape2D          # Layer: player_bullet  Mask: world | enemy
└── VisibleOnScreenNotifier2D
```

For enemy projectiles, duplicate the scene and change the collision layer to `enemy_bullet` and the mask to `world | player`.

### Enemy.tscn (minimal example)
```
Enemy  (CharacterBody2D + enemy.gd)
├── CollisionShape2D          # Layer: enemy          Mask: world
├── HealthModule  (Node       + health.gd)
└── HurtboxModule (Area2D     + hurtbox.gd)
    └── CollisionShape2D      # Layer: enemy          Mask: player_bullet
```

`HealthModule` and `HurtboxModule` drop in without modification. The enemy coordinator connects them the same way `player.gd` does.

---

## Weapon Contract

Any node can act as a weapon inside `WeaponSlot` by implementing:

```gdscript
func try_shoot(muzzle: Marker2D, direction: int) -> void:
    pass
```

No base class required. `WeaponSlot` checks for the method with `has_method()` before calling.

---

## Hitbox Contract

Any `Area2D` can deal damage to a `HurtboxModule` by implementing:

```gdscript
func get_damage() -> float:
    return 10.0

# Optional. Triggers knockback_received on the hurtbox.
func get_knockback() -> Dictionary:
    return { "direction": Vector2.RIGHT, "force": 300.0 }
```

No base class required. `HurtboxModule` checks for these methods with `has_method()` before calling them. Collision filtering (which layers actually reach the hurtbox) is handled entirely via Godot's physics layer masks.
