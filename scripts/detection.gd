## detection.gd
## Detecta targets dentro de un rango y confirma línea de visión con RayCast2D.
## Drag and drop como nodo hijo. Owner-agnostic.
##
## Emite target_acquired cuando un target entra al rango con línea de visión libre.
## Emite target_lost cuando se pierde línea de visión por más de memory_duration segundos.
##
## Uso desde un estado:
##   detection_module.target_acquired.connect(_on_target_acquired)
##   detection_module.target_lost.connect(_on_target_lost)
##
## Para obtener la posición del target en tick():
##   detection_module.last_known_position
##
## Árbol esperado:
##   Enemy  (CharacterBody2D + enemy.gd)
##   └── DetectionModule  (Node2D + detection.gd)
##       ├── Area2D           <- rango de detección, CollisionShape2D configurable en editor
##       │   └── CollisionShape2D
##       └── RayCast2D        <- confirma línea de visión

class_name DetectionModule
extends Node2D

## Emitida cuando se detecta un target con línea de visión libre.
signal target_acquired(target: Node)

## Emitida cuando se pierde el target tras agotar memory_duration.
signal target_lost

## Segundos que el módulo recuerda al target sin línea de visión antes de emitir target_lost.
@export var memory_duration: float = 5.0

## Layer que el RayCast2D considera como obstáculo (normalmente "world").
@export_flags_2d_physics var obstruction_mask: int = 1

## Posición del target en el último frame con línea de visión confirmada.
## Disponible para los estados incluso durante el periodo de memoria.
var last_known_position: Vector2 = Vector2.ZERO

## Nodo target activo. Null si no hay ninguno en rango.
var current_target: Node = null

var _has_target: bool = false
var _memory_timer: float = 0.0
var _candidates: Array[Node] = []

@onready var _raycast: RayCast2D = $RayCast2D
@onready var _area: Area2D = $Area2D


func _ready() -> void:
	_raycast.collision_mask = obstruction_mask
	_raycast.enabled = true
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_update_raycast()

	if _has_target:
		_memory_timer = 0.0
		return

	# Sin línea de visión: contar memoria.
	if current_target != null:
		_memory_timer += delta
		if _memory_timer >= memory_duration:
			_lose_target()


# --- Interno ---

func _update_raycast() -> void:
	# Revisar candidatos en rango en orden de proximidad.
	for candidate in _candidates:
		if not is_instance_valid(candidate):
			continue

		_raycast.target_position = to_local(candidate.global_position)
		_raycast.force_raycast_update()

		var line_of_sight_clear := not _raycast.is_colliding()

		if line_of_sight_clear:
			last_known_position = candidate.global_position
			if not _has_target:
				_acquire_target(candidate)
			return

	# Ningún candidato tiene línea de visión libre.
	_has_target = false


func _acquire_target(target: Node) -> void:
	current_target = target
	_has_target = true
	_memory_timer = 0.0
	target_acquired.emit(target)


func _lose_target() -> void:
	current_target = null
	_has_target = false
	_memory_timer = 0.0
	target_lost.emit()


func _on_body_entered(body: Node) -> void:
	if not _candidates.has(body):
		_candidates.append(body)


func _on_body_exited(body: Node) -> void:
	_candidates.erase(body)

	# Si el target que se va era el actual y no hay más candidatos, iniciar memoria.
	if body == current_target:
		_has_target = false
