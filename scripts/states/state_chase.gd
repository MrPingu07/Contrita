## state_chase.gd
## El enemigo persigue al jugador mientras tenga línea de visión.
## Sin línea de visión, camina hacia last_known_position hasta que
## DetectionModule emita target_lost (5 segundos por defecto).
##
## Transiciones:
##   -> StateIdle: cuando detection_module emite target_lost (gestionado en enemy.gd)

extends State

## Velocidad de desplazamiento horizontal.
@export var chase_speed: float = 80.0

## Distancia mínima al target antes de detenerse.
@export var stop_distance: float = 8.0

var _actor: CharacterBody2D = null
var _detection: DetectionModule = null


func enter(actor: Node) -> void:
	_actor = actor as CharacterBody2D
	_detection = _actor.get_node("DetectionModule") as DetectionModule


func exit() -> void:
	_actor.velocity.x = 0.0
	_actor = null
	_detection = null


func tick(_delta: float) -> void:
	var target_position := _detection.last_known_position
	var distance := _actor.global_position.distance_to(target_position)

	if distance <= stop_distance:
		_actor.velocity.x = 0.0
		return

	var direction: float = sign(target_position.x - _actor.global_position.x)
	_actor.velocity.x = direction * chase_speed
	_actor.set_facing(int(direction))
