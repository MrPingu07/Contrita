## hurtbox.gd
## Detecta hitboxes entrantes y emite señales de daño/knockback.
## Drag and drop como nodo hijo. Requiere un Area2D hermano o ser Area2D.
##
## Árbol esperado:
##   (cualquier nodo)
##   ├── HealthModule
##   └── HurtboxModule  <- este script, adjunto a un Area2D

class_name HurtboxModule
extends Area2D

## Emite la cantidad de daño recibida. Conéctalo a HealthModule.take_damage.
signal damage_received(amount: float)

## Emite dirección normalizada + fuerza. Conéctalo a KnockbackModule.apply.
signal knockback_received(direction: Vector2, force: float)

## Para efectos visuales, sonido, etc.
signal hurt

## Con qué layers colisiona esta hurtbox (debe ser distinta a la hitbox layer).
## Configúralo en el Inspector o déjalo al editor.
@export var enabled: bool = true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if not enabled:
		return

	# El área entrante debe tener estos métodos para ser una hitbox válida.
	# Así evitamos acoplar a una clase concreta.
	if not area.has_method("get_damage"):
		return

	var amount: float = area.get_damage()
	damage_received.emit(amount)
	hurt.emit()

	# Knockback es opcional: la hitbox puede o no proveerlo.
	if area.has_method("get_knockback"):
		var kb: Dictionary = area.get_knockback()
		knockback_received.emit(kb.direction, kb.force)
