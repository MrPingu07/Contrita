## weapon_slot.gd
## Contenedor del arma activa. Gestiona equip, unequip y swap.
## Las armas son nodos hijos directos de este nodo.
## Solo un arma está activa a la vez.
##
## Árbol esperado:
##   Player
##   └── WeaponSlot     (Node2D + weapon_slot.gd)
##       ├── Semiauto   (Node2D + semiauto.gd)
##       └── Shotgun    (Node2D + shotgun.gd)  <- desactivado al inicio

class_name WeaponSlot
extends Node2D

## Emitida cuando el arma activa cambia.
signal weapon_changed(new_weapon: Node)

## Índice del arma equipada al iniciar la escena.
@export var default_weapon_index: int = 0

var current_weapon: Node = null
var _weapons: Array[Node] = []


func _ready() -> void:
	# Registra todos los hijos como armas disponibles.
	for child in get_children():
		_weapons.append(child)
		child.process_mode = Node.PROCESS_MODE_DISABLED
		child.visible = false

	if _weapons.is_empty():
		return

	equip(default_weapon_index)


## Equipa el arma en el índice dado.
func equip(index: int) -> void:
	if index < 0 or index >= _weapons.size():
		push_warning("WeaponSlot: índice %d fuera de rango." % index)
		return

	if current_weapon:
		current_weapon.process_mode = Node.PROCESS_MODE_DISABLED
		current_weapon.visible = false

	current_weapon = _weapons[index]
	current_weapon.process_mode = Node.PROCESS_MODE_INHERIT
	current_weapon.visible = true

	weapon_changed.emit(current_weapon)


## Swap al siguiente arma en la lista (cíclico).
func equip_next() -> void:
	if _weapons.is_empty():
		return
	var next_index := (_weapons.find(current_weapon) + 1) % _weapons.size()
	equip(next_index)


## Swap al arma anterior (cíclico).
func equip_previous() -> void:
	if _weapons.is_empty():
		return
	var prev_index := (_weapons.find(current_weapon) - 1 + _weapons.size()) % _weapons.size()
	equip(prev_index)


## Delega el disparo al arma activa.
## El arma debe implementar try_shoot(muzzle: Marker2D, direction: int).
func try_shoot(muzzle: Marker2D, direction: int) -> void:
	if current_weapon and current_weapon.has_method("try_shoot"):
		current_weapon.try_shoot(muzzle, direction)
