## semiauto.gd
## Arma semiauto: un disparo por press de "shoot".
## Usa BulletPool en lugar de instanciar directamente.
##
## Árbol esperado:
##   WeaponSlot
##   └── Semiauto  (Node2D + semiauto.gd)

class_name Semiauto
extends Node2D

signal shot_fired(bullet: Node)

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.1

var _cooldown: float = 0.0


func _ready() -> void:
	if bullet_scene:
		BulletPool.prewarm(bullet_scene)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func try_shoot(muzzle: Marker2D, direction: int) -> void:
	if bullet_scene == null:
		push_warning("Semiauto: bullet_scene no asignado en el Inspector.")
		return

	if _cooldown > 0.0:
		return

	_cooldown = fire_rate

	var bullet := BulletPool.request(bullet_scene, muzzle.global_position, direction)
	shot_fired.emit(bullet)
