## Objet de décor (chaise, néon, panneau...). Les mutations agissent sur les Props.
class_name Prop
extends Interactable

var tags: Array = []
var label: Label
var original_text = ""
var light: PointLight2D
var generic = false

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	tags = d.get("tags", []).duplicate()
	if d.has("label"):
		original_text = d["label"]
		label = UI.label(original_text, int(d.get("label_size", 16)), Color.from_string(d.get("label_color", "#ffffff"), Color.WHITE))
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(120, 24)
		label.position = Vector2(-60, -sprite_height() - 24 + float(d.get("label_dy", 0)))
		add_child(label)
		add_to_group("room_text")
	if tags.has("light") or d.has("light"):
		_add_light(d.get("light", {}))
	if not (d.has("text") or d.has("dialogue") or d.has("actions")):
		monitorable = false
	z_index = int(d.get("z", 0))

func default_solid() -> bool:
	return not def.get("floor", false)

func _add_light(ld: Dictionary) -> void:
	light = PointLight2D.new()
	light.texture = FxManager.light_texture()
	light.texture_scale = float(ld.get("scale", 2.5))
	light.energy = float(ld.get("energy", 0.9))
	light.color = Color.from_string(ld.get("color", "#e8ffd8"), Color(0.9, 1, 0.85))
	light.position = Vector2(0, -sprite_height() * 0.6)
	add_child(light)
	if ld.get("flicker", tags.has("flicker")):
		var f = preload("res://scenes/overworld/flicker.gd").new()
		f.light = light
		f.target = sprite
		add_child(f)

func has_tag(t: String) -> bool:
	return tags.has(t)

## Mutation Détail : devient une forme générique.
func make_generic() -> void:
	if sprite and not generic:
		sprite.texture = Assets.generic_block(tex_name)
		generic = true

func set_text(t: String) -> void:
	if label:
		label.text = t

func interact(player: Node) -> void:
	await super.interact(player)

## Copie conforme (mutation Répétition).
func duplicate_prop(r: Node, offset: Vector2) -> Prop:
	var d = def.duplicate(true)
	d["id"] = str(def.get("id", "prop")) + "_dup"
	var p = Prop.new()
	p.setup(d, r)
	p.position = position + offset
	p.tags.append("dup")
	if generic:
		p.make_generic()
	return p
