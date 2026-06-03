# Godot Contra-like prototype

A proof of concept game utilizing reusable, drop-in systems in Godot 4.

The guiding principle is simple: every module should work as a drag-and-drop node with zero assumptions about its owner.
A `HealthModule` on a player, an enemy, or a barrel behaves identically.
Modules communicate exclusively through signals, which keeps them replaceable without touching unrelated code.

---

## Design Philosophy

- **Drag and drop** - add a module as a child node and it works.
- **Drop-in replaceable** - swap `Semiauto` for `Shotgun` by changing one child node.
- **Signal-only communication** - modules never reach outside their own subtree.
- **Owner-agnostic** - no module assumes it lives inside a player, an enemy, or any specific scene.

---

## Project Setup

Before running any scene, configure the following in the Godot editor.

### 1. Autoload

| Script | Name |
|---|---|
| `bullet_pool.gd` | `BulletPool` |

`Project > Autoload > Add`

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
Detects incoming hitboxes via `Area2D`. Emits `damage_received` and `knockback_received`.
Connect `damage_received` to `HealthModule.take_damage` in the owner's `_ready`.

### `weapon_slot.gd` - WeaponSlot
Manages the active weapon. Supports cyclic swap via `equip_next()` / `equip_previous()`.
All child weapon nodes are disabled at startup except `default_weapon_index`.

### `semiauto.gd` - Semiauto
One shot per button press. Enforces a minimum fire rate (default 100ms).
Requires `bullet_scene` assigned in the Inspector.

### `bullet_pool.gd` - BulletPool *(Autoload)*
Generic object pool keyed by `PackedScene`. Handles player and enemy projectiles.
Grows automatically if the pool is exhausted.

### `bullet.gd` - Bullet
Base projectile. Releases itself on `hit` or on `screen_exited`.
Implements `launch(direction)` and `get_damage()` as required contracts.

---

## Scene Structure

### Player.tscn
```
Player  (CharacterBody2D + player.gd)
├── CollisionShape2D          # Layer: player      Mask: world
├── HealthModule  (Node + health.gd)
├── HurtboxModule (Area2D + hurtbox.gd)
│   └── CollisionShape2D      # Layer: player      Mask: enemy | enemy_bullet
├── WeaponSlot    (Node2D + weapon_slot.gd)
│   └── Semiauto  (Node2D + semiauto.gd)
└── Visuals       (Node2D)
    ├── Sprite2D
    └── Muzzle    (Marker2D)
```

### Bullet.tscn
```
Bullet  (Area2D + bullet.gd)
├── CollisionShape2D          # Layer: player_bullet   Mask: world | enemy
└── VisibleOnScreenNotifier2D
```

---

## Weapon Contract

Any script can act as a weapon inside `WeaponSlot` by implementing:

```gdscript
func try_shoot(muzzle: Marker2D, direction: int) -> void:
    pass
```

## Hitbox Contract

Any `Area2D` can deal damage to a `HurtboxModule` by implementing:

```gdscript
func get_damage() -> float:
    return 10.0

# Optional — triggers knockback_received on the hurtbox.
func get_knockback() -> Dictionary:
    return { "direction": Vector2.RIGHT, "force": 300.0 }
```
