## player.gd
## Coordinador del player. Movimiento, salto, flip visual y disparo delegado.
##
## Árbol esperado:
##   Player  (CharacterBody2D)
##   ├── CollisionShape2D
##   ├── HealthModule       (Node        + health.gd)
##   ├── HurtboxModule      (Area2D      + hurtbox.gd)
##   │   └── CollisionShape2D
##   ├── WeaponSlot         (Node2D      + weapon_slot.gd)
##   │   └── Semiauto       (Node2D      + semiauto.gd)
##   └── Visuals            (Node2D)
##       ├── Sprite2D
##       └── Muzzle         (Marker2D)

extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var health_module: HealthModule  = $HealthModule
@onready var hurtbox_module: HurtboxModule = $HurtboxModule
@onready var weapon_slot: WeaponSlot      = $WeaponSlot
@onready var visuals: Node2D              = $Visuals
@onready var muzzle: Marker2D             = $Visuals/Muzzle

var facing_direction: int = 1


func _ready() -> void:
	_connect_modules()


func _physics_process(delta: float) -> void:
	if health_module.is_dead:
		return

	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_handle_shooting()
	move_and_slide()


# --- Módulos ---

func _connect_modules() -> void:
	hurtbox_module.damage_received.connect(health_module.take_damage)
	health_module.died.connect(_on_died)


# --- Movimiento ---

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _handle_movement() -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		_set_facing(int(sign(direction)))
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func _handle_shooting() -> void:
	if Input.is_action_just_pressed("shoot"):
		weapon_slot.try_shoot(muzzle, facing_direction)

	if Input.is_action_just_pressed("weapon_next"):
		weapon_slot.equip_next()

	if Input.is_action_just_pressed("weapon_prev"):
		weapon_slot.equip_previous()


func _set_facing(direction: int) -> void:
	if facing_direction == direction:
		return
	facing_direction = direction
	visuals.scale.x = facing_direction


# --- Callbacks ---

func _on_died() -> void:
	set_physics_process(false)
