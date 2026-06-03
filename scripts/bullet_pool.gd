## bullet_pool.gd
## Autoload. Object pool genérico para proyectiles.
## Soporta múltiples tipos de proyectil (player, enemigos, etc).
##
## Editor - Registro obligatorio:
##   Project > Autoload > añadir bullet_pool.gd con nombre exacto "BulletPool"
##   Sin este paso los scripts que llamen BulletPool.request() fallan en runtime.
##
## Uso desde cualquier arma:
##   var bullet = BulletPool.request(bullet_scene, position, direction)
##
## Uso desde bullet.gd en lugar de queue_free():
##   BulletPool.release(self)

extends Node

## Tamaño inicial del pool por tipo de proyectil.
const POOL_SIZE = 20

## { PackedScene: Array[Node] }
var _pools: Dictionary = {}


## Solicita una bala del pool. Si no hay disponibles, instancia una nueva.
func request(scene: PackedScene, spawn_position: Vector2, direction: int) -> Node:
	_ensure_pool(scene)

	var pool: Array = _pools[scene]
	var bullet: Node = null

	for candidate in pool:
		if not candidate.is_inside_tree() or not candidate.visible:
			bullet = candidate
			break

	if bullet == null:
		bullet = _grow_pool(scene)

	bullet.global_position = spawn_position
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT

	if bullet.has_method("launch"):
		bullet.launch(direction)
	else:
		push_warning("BulletPool: %s no implementa launch(direction)." % scene.resource_path)

	return bullet


## Devuelve una bala al pool desactivándola.
## set_deferred evita deshabilitar un CollisionObject durante un callback de física.
func release(bullet: Node) -> void:
	bullet.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	bullet.set_deferred("visible", false)


## Precalienta el pool para una escena dada. Opcional pero recomendado en _ready del arma.
func prewarm(scene: PackedScene) -> void:
	_ensure_pool(scene)


# --- Interno ---

func _ensure_pool(scene: PackedScene) -> void:
	if _pools.has(scene):
		return

	_pools[scene] = []
	for i in POOL_SIZE:
		_grow_pool(scene)


func _grow_pool(scene: PackedScene) -> Node:
	var bullet: Node = scene.instantiate()
	add_child(bullet)
	bullet.visible = false
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	_pools[scene].append(bullet)
	return bullet
