## state_machine.gd
## Módulo orquestador de estados. Drag and drop como nodo hijo.
## Los estados son nodos hijos directos de este nodo.
## Owner-agnostic: el owner se pasa al estado activo en cada transición.
##
## Uso desde el coordinador en _ready:
##   state_machine.init(self, "StateIdle")
##
## Uso desde el coordinador en _physics_process:
##   state_machine.tick(delta)
##
## Uso desde cualquier estado para transicionar:
##   state_machine.transition_to("StateChase")
##
## Árbol esperado:
##   (cualquier CharacterBody2D)
##   └── StateMachineModule  (Node + state_machine.gd)
##       ├── StateIdle       (Node + state_idle.gd)
##       └── StateChase      (Node + state_chase.gd)

class_name StateMachineModule
extends Node

## Emitida cuando el estado activo cambia.
signal state_changed(from: String, to: String)

var current_state: State = null

## Referencia al owner inyectada en init(). Se reenvía a cada estado en enter().
var _owner_node: Node = null

## Mapa nombre -> nodo estado construido en init().
var _states: Dictionary = {}


## Inicializa el módulo. Llamar desde _ready del coordinador.
## owner_node: el CharacterBody2D u otro nodo coordinador.
## initial_state: nombre exacto del nodo estado inicial (ej. "StateIdle").
func init(owner_node: Node, initial_state: String) -> void:
	_owner_node = owner_node

	for child in get_children():
		if child is State:
			child.state_machine = self
			_states[child.name] = child

	if _states.is_empty():
		push_warning("StateMachineModule: no se encontraron estados hijos.")
		return

	transition_to(initial_state)


## Delega el tick al estado activo. Llamar desde _physics_process del coordinador.
func tick(delta: float) -> void:
	if current_state:
		current_state.tick(delta)


## Transiciona al estado con el nombre dado.
## Llama exit() en el estado actual y enter(owner) en el nuevo.
func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("StateMachineModule: estado '%s' no encontrado." % state_name)
		return

	var next_state: State = _states[state_name] as State

	if next_state == current_state:
		return

	var previous_name: String = str(current_state.name) if current_state else ""

	if current_state:
		current_state.exit()

	current_state = next_state
	current_state.enter(_owner_node)

	state_changed.emit(previous_name, current_state.name)
