## health.gd
## Módulo de salud reutilizable. Drag and drop como nodo hijo.
## No asume nada sobre el owner. Se comunica exclusivamente por señales.
##
## Árbol esperado:
##   (cualquier nodo)
##   └── HealthModule  <- este script

class_name HealthModule
extends Node

signal health_changed(current: float, maximum: float)
signal died
signal revived

@export var max_health: float = 100.0
@export var invincible: bool = false

var current_health: float
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health


## Aplica daño. Ignorado si invincible o muerto.
func take_damage(amount: float) -> void:
	if invincible or is_dead:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)

	if current_health == 0.0:
		is_dead = true
		died.emit()


## Cura. Por defecto cura al máximo si no se pasa cantidad.
func heal(amount: float = max_health) -> void:
	if is_dead:
		return

	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Revive con la cantidad de salud indicada (por defecto max_health).
func revive(amount: float = max_health) -> void:
	is_dead = false
	current_health = clampf(amount, 1.0, max_health)
	health_changed.emit(current_health, max_health)
	revived.emit()


func get_health_ratio() -> float:
	return current_health / max_health
