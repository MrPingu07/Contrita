## bullet.gd
## Proyectil base. Compatible con BulletPool.
## Se libera al salir de pantalla o al golpear algo.
##
## Árbol esperado:
##   Bullet  (Area2D + bullet.gd)
##   ├── CollisionShape2D          <- dibujar shape manualmente en el editor
##   └── VisibleOnScreenNotifier2D <- nodo requerido, añadir manualmente
##
## Editor - Collision (Inspector del nodo Bullet):
##   Player bullet:  Layer = player_bullet   Mask = world | enemy
##   Enemy bullet:   Layer = enemy_bullet    Mask = world | player
##
## Inspector - Semiauto:
##   bullet_scene <- asignar la escena Bullet.tscn aquí

class_name Bullet
extends Area2D

@export var speed: float = 600.0
@export var damage: float = 10.0

var _direction: int = 1
var _active: bool = false

@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	screen_notifier.screen_exited.connect(_release)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	position.x += _direction * speed * delta


## Contrato requerido por BulletPool.
func launch(direction: int) -> void:
	_direction = direction
	_active = true


## Contrato requerido por hurtbox.gd.
func get_damage() -> float:
	return damage


func _release() -> void:
	_active = false
	BulletPool.release(self)


func _on_body_entered(_body: Node) -> void:
	_release()


func _on_area_entered(area: Area2D) -> void:
	if area is Bullet:
		return
	_release()
