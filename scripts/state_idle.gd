## state_idle.gd
## Estado de ejemplo: el enemigo está quieto esperando detectar al jugador.
## Sustituye la lógica de tick() con la tuya.
##
## Para transicionar a otro estado:
##   state_machine.transition_to("StateChase")

extends State

var _owner: CharacterBody2D = null


func enter(actor: Node) -> void:
	_owner = actor as CharacterBody2D
	# Detener movimiento al entrar en idle.
	_owner.velocity.x = 0.0


func exit() -> void:
	_owner = null


func tick(_delta: float) -> void:
	# Sustituir con condición real: detección de jugador, timer, etc.
	# Ejemplo: transicionar a Chase cuando DetectionModule emita target_acquired.
	pass
