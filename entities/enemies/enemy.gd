## enemy.gd
## Coordinador base del enemigo. Movimiento delegado a StateMachineModule.
##
## Árbol esperado:
##   Enemy  (CharacterBody2D + enemy.gd)
##   ├── CollisionShape2D
##   ├── HealthModule        (Node    + health.gd)
##   ├── HurtboxModule       (Area2D  + hurtbox.gd)
##   │   └── CollisionShape2D
##   ├── KnockbackModule     (Node    + knockback.gd)
##   ├── StateMachineModule  (Node    + state_machine.gd)
##   │   └── StateIdle       (Node    + state_idle.gd)
##   └── Visuals             (Node2D)
##       └── Sprite2D

extends CharacterBody2D

@onready var health_module: HealthModule       = $HealthModule
@onready var hurtbox_module: HurtboxModule     = $HurtboxModule
@onready var knockback_module: KnockbackModule = $KnockbackModule
@onready var state_machine: StateMachineModule = $StateMachineModule
@onready var visuals: Node2D                   = $Visuals

var facing_direction: int = -1


func _ready() -> void:
	_connect_modules()
	state_machine.init(self, "StateIdle")


func _physics_process(delta: float) -> void:
	if health_module.is_dead:
		return

	_apply_gravity(delta)
	state_machine.tick(delta)
	velocity += knockback_module.consume(delta)
	move_and_slide()


# --- Módulos ---

func _connect_modules() -> void:
	hurtbox_module.damage_received.connect(health_module.take_damage)
	hurtbox_module.knockback_received.connect(knockback_module.apply)
	health_module.died.connect(_on_died)


# --- Movimiento ---

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func set_facing(direction: int) -> void:
	if facing_direction == direction:
		return
	facing_direction = direction
	visuals.scale.x = facing_direction


# --- Callbacks ---

func _on_died() -> void:
	set_physics_process(false)
