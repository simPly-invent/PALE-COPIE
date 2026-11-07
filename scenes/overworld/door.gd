## Porte entre deux salles. "to" : id de salle source, "@next" (copie suivante),
## "@prev" (copie précédente), "@self" (boucle), "@maze" (énigme de l'ancre).
class_name Door
extends Area2D

var def: Dictionary = {}
var room: Node
var side = "top"
var cell = Vector2i.ZERO
var sprite: Sprite2D
var label: Label
var shifted = false
var original_cell = Vector2i.ZERO
var enabled = true
var _cooldown = 0.5
var _protected: CanvasLayer

func _init() -> void:
	collision_layer = 0
	collision_mask = 4

func setup(d: Dictionary, r: Node) -> void:
	def = d
	room = r
	name = str(d.get("id", "door")).validate_node_name()
	side = d.get("side", "top")
	var p: Array = d.get("pos", [1, 1])
	cell = Vector2i(int(p[0]), int(p[1]))
	original_cell = cell
	add_to_group("door")
	body_entered.connect(_on_body_entered)

## Place la porte sur sa case de mur (appelé à la finalisation, après les mutations).
func place() -> void:
	for ch in get_children():
		ch.free()
	sprite = null
	label = null
	_protected = null
	var T: int = TileGrid.TILE
	var tiles: TileGrid = room.tiles
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	match side:
		"top":
			position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T)
			rect.size = Vector2(28, 14)
			shape.position = Vector2(0, 4)
			var spr: String = def.get("sprite", room.zone.get("door_sprite", "door_beige"))
			if spr == "opening":
				var c = ColorRect.new()
				c.color = Color.BLACK
				c.size = Vector2(36, 70)
				c.position = Vector2(-18, -70)
				add_child(c)
			elif spr != "none":
				sprite = Sprite2D.new()
				sprite.texture = Assets.tex(spr)
				sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
				if def.has("tint"):
					sprite.modulate = Color.from_string(def["tint"], Color.WHITE)
				add_child(sprite)
				if def.has("protect_if") and GameState.check(def["protect_if"]):
					# couleur gardée en mémoire : rendue au-dessus des effets d'écran
					var layer = CanvasLayer.new()
					layer.layer = 51
					layer.follow_viewport_enabled = true
					var copy = Sprite2D.new()
					copy.texture = sprite.texture
					copy.offset = sprite.offset
					copy.modulate = sprite.modulate
					copy.position = position
					layer.add_child(copy)
					add_child(layer)
					_protected = layer
		"bottom":
			tiles.set_cell(cell.x, cell.y, ".")
			position = Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T)
			rect.size = Vector2(36, 12)
			shape.position = Vector2(0, -6)
			_add_dark(Rect2(-20, -16, 40, 16))
		"left":
			tiles.set_cell(cell.x, cell.y, ".")
			position = Vector2(cell.x * T, (cell.y + 1) * T)
			rect.size = Vector2(12, 36)
			shape.position = Vector2(6, -20)
			_add_dark(Rect2(0, -40, 16, 40))
		"right":
			tiles.set_cell(cell.x, cell.y, ".")
			position = Vector2((cell.x + 1) * T, (cell.y + 1) * T)
			rect.size = Vector2(12, 36)
			shape.position = Vector2(-6, -20)
			_add_dark(Rect2(-16, -40, 16, 40))
	shape.shape = rect
	add_child(shape)
	if def.has("label_seq"):
		var seq = Puzzles.room_sequence(def["label_seq"]["puzzle"])
		def["label"] = str(seq[int(def["label_seq"]["index"])])
	if def.has("label") and str(def["label"]) != "":
		label = UI.label(str(def["label"]), 16, Color(0.95, 0.9, 0.7))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(80, 20)
		label.position = Vector2(-40, -110 if side == "top" else -64)
		label.set_meta("original", str(def["label"]))
		label.add_to_group("room_text")
		add_child(label)

func _add_dark(r: Rect2) -> void:
	var c = ColorRect.new()
	c.color = Color(0, 0, 0, 0.85)
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)

## Point d'apparition du joueur quand il arrive par cette porte.
func spawn_point() -> Vector2:
	var T: int = TileGrid.TILE
	match side:
		"top": return Vector2(cell.x * T + T / 2.0, (cell.y + 2) * T + 6)
		"bottom": return Vector2(cell.x * T + T / 2.0, (cell.y) * T - 2)
		"left": return Vector2((cell.x + 1) * T + T / 2.0, (cell.y + 1) * T - 4)
		"right": return Vector2((cell.x - 1) * T + T / 2.0, (cell.y + 1) * T - 4)
	return position

## Direction « vers l'extérieur » de la porte.
func outward() -> Vector2:
	match side:
		"top": return Vector2.UP
		"bottom": return Vector2.DOWN
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
	return Vector2.UP

func _process(delta: float) -> void:
	if _protected:
		_protected.visible = is_visible_in_tree()
	if _cooldown > 0:
		_cooldown -= delta

func _on_body_entered(body: Node) -> void:
	if not enabled or _cooldown > 0 or not body.is_in_group("player"):
		return
	if GameState.is_locked():
		return
	World.use_door(self, body)
