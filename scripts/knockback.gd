## knockback.gd
## Aplica un impulso de knockback que decae con fricción cada frame.
## Drag and drop como nodo hijo. Owner-agnostic.
##
## Uso desde el coordinador en _ready:
##   hurtbox_module.knockback_received.connect(knockback_module.apply)
##
## Uso desde el coordinador en _physics_process:
##   velocity += knockback_module.consume()
##
## Árbol esperado:
##   (cualquier CharacterBody2D)
##   ├── HurtboxModule  (Area2D + hurtbox.gd)
##   └── KnockbackModule  (Node + knockback.gd)

class_name KnockbackModule
extends Node

## Emitida cada frame mientras el impulso está activo.
## El coordinador suma este vector a su velocity.
signal knockback_applied(impulse: Vector2)

## Emitida cuando el impulso decae por debajo del umbral y se cancela.
signal knockback_finished

## Qué fracción de la velocidad se conserva cada frame (0 = para inmediato, 1 = no decae).
@export var friction: float = 0.2

## Por debajo de esta magnitud el impulso se cancela.
@export var stop_threshold: float = 5.0

var _impulse: Vector2 = Vector2.ZERO


## Inicia o reemplaza el impulso actual.
## Conectar a HurtboxModule.knockback_received.
func apply(direction: Vector2, force: float) -> void:
	_impulse = direction.normalized() * force


## Llama esto desde _physics_process del coordinador y suma el resultado a velocity.
## Retorna Vector2.ZERO cuando no hay impulso activo.
## friction usa pow(friction, delta) para ser frame-rate independent.
## Un friction de 0.2 significa que queda el 20% del impulso después de 1 segundo.
func consume(delta: float) -> Vector2:
	if _impulse.is_zero_approx():
		return Vector2.ZERO

	var current := _impulse
	_impulse *= pow(friction, delta)

	if _impulse.length() < stop_threshold:
		_impulse = Vector2.ZERO
		knockback_finished.emit()

	knockback_applied.emit(current)
	return current
