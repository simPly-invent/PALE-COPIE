## Base des objets avec lesquels le joueur interagit (touche Valider).
## Origine du nœud = pieds de l'objet (tri en Y).
class_name Interactable
extends Area2D

var def: Dictionary = {}
var room: Node
var sprite: Sprite2D
var body: StaticBody2D
var tex_name = ""

func _init() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true

func setup(d: Dictionary, r: Node) -> void:
	def = d
	room = r
	name = str(d.get("id", name)).validate_node_name()
	position = r.cell_pos(d.get("pos", [0, 0]))
	tex_name = d.get("sprite", default_sprite())
	if tex_name != "":
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = Assets.tex(tex_name)
		sprite.centered = true
		var sc: float = d.get("scale", 1.0)
		sprite.scale = Vector2(sc, sc)
		sprite.flip_h = d.get("flip", false)
		if sprite.texture:
			sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		add_child(sprite)
	var fp = footprint()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = fp + Vector2(12, 16)
	shape.shape = rect
	shape.position = Vector2(0, -fp.y / 2.0)
	add_child(shape)
	if d.get("solid", default_solid()):
		body = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var bs = CollisionShape2D.new()
		var br = RectangleShape2D.new()
		br.size = fp
		bs.shape = br
		bs.position = Vector2(0, -fp.y / 2.0)
		body.add_child(bs)
		add_child(body)

func default_sprite() -> String:
	return ""

func default_solid() -> bool:
	return true

## Emprise au sol (collision) : largeur du sprite, faible hauteur.
func footprint() -> Vector2:
	if def.has("footprint"):
		return Vector2(def["footprint"][0], def["footprint"][1])
	var w = 24.0
	if sprite and sprite.texture:
		w = sprite.texture.get_width() * sprite.scale.x * 0.8
	return Vector2(max(12.0, w), 14.0)

func sprite_height() -> float:
	if sprite and sprite.texture:
		return sprite.texture.get_height() * sprite.scale.y
	return 32.0

func can_interact() -> bool:
	return true

## Surchargé par les sous-classes. Coroutine.
func interact(_player: Node) -> void:
	if def.has("dialogue"):
		await DialogueManager.play(def["dialogue"], {"speaker_node": self})
	elif def.has("text"):
		var t = def["text"]
		await DialogueManager.say(t if t is Array else [t])
	if def.has("actions"):
		await Actions.run(def["actions"], self)
