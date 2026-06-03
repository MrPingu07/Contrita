## state.gd
## Clase base para todos los estados. Extiende con un script por estado.
##
## Contrato:
##   enter(actor)  -> llamado al activar el estado. Recibe referencia al coordinador.
##   exit()        -> llamado al desactivar el estado.
##   tick(delta)   -> llamado cada _physics_process mientras el estado está activo.
##
## Para transicionar desde dentro de un estado:
##   state_machine.transition_to("NombreDelEstado")
##
## Árbol esperado:
##   StateMachineModule  (Node + state_machine.gd)
##   ├── StateIdle       (Node + state_idle.gd)
##   ├── StateChase      (Node + state_chase.gd)
##   └── StateAttack     (Node + state_attack.gd)

class_name State
extends Node

## Referencia al StateMachineModule padre. Asignada automáticamente por el módulo.
var state_machine: Node = null


## Llamado al entrar al estado. actor es el nodo coordinador.
func enter(_actor: Node) -> void:
	pass


## Llamado al salir del estado.
func exit() -> void:
	pass


## Llamado cada physics frame mientras el estado está activo.
func tick(_delta: float) -> void:
	pass
