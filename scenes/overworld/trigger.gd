## Zone invisible qui lance une liste d'actions quand le joueur y entre.
class_name RoomTrigger
extends Area2D

var def: Dictionary = {}
var room: Node
var running = false

func _init() -> void:
	collision_layer = 0
	collision_mask = 4

func setup(d: Dictionary, r: Node) -> void:
	def = d
	room = r
	name = str(d.get("id", "trigger")).validate_node_name()
	var rc: Array = d.get("rect", [0, 0, 1, 1])
	var T: int = TileGrid.TILE
	position = Vector2(rc[0] * T, rc[1] * T)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(rc[2] * T, rc[3] * T)
	shape.shape = rect
	shape.position = rect.size / 2.0
	add_child(shape)
	body_entered.connect(_on_enter)

func _flag() -> String:
	return "trigger.%s.%s" % [room.source.id, name]

func _on_enter(body: Node) -> void:
	if running or not body.is_in_group("player"):
		return
	if def.get("once", true) and GameState.get_flag(_flag(), false):
		return
	if def.has("if") and not GameState.check(def["if"]):
		return
	running = true
	if def.get("once", true):
		GameState.set_flag(_flag(), true)
	await Actions.run(def.get("actions", []), self)
	running = false
