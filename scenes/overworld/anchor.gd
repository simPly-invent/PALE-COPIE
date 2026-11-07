## L'ancre : objet unique par lignée, qui ne mute jamais (règle 3.3.5).
## Elle est affichée sur un calque au-dessus des effets d'écran pour garder sa vraie couleur.
class_name RoomAnchor
extends Interactable

var overlay: CanvasLayer
var overlay_sprite: Sprite2D

func default_sprite() -> String:
	return "chair_red"

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	add_to_group("anchor")
	if sprite:
		sprite.visible = false   # le vrai rendu est sur le calque protégé
	overlay = CanvasLayer.new()
	overlay.name = "AnchorOverlay"
	overlay.layer = 51
	overlay.follow_viewport_enabled = true
	overlay_sprite = Sprite2D.new()
	overlay_sprite.texture = Assets.tex(tex_name)
	overlay_sprite.offset = Vector2(0, -overlay_sprite.texture.get_height() / 2.0)
	overlay.add_child(overlay_sprite)
	add_child(overlay)

func _process(_delta: float) -> void:
	if overlay:
		overlay.visible = is_visible_in_tree()
	if overlay_sprite:
		overlay_sprite.global_transform = get_global_transform()
		# le joueur passe devant l'ancre : on la masque pendant le recouvrement
		var p = get_tree().get_first_node_in_group("player") as Node2D
		var hidden = false
		if p and p.global_position.y > global_position.y and abs(p.global_position.x - global_position.x) < 26 and p.global_position.y - global_position.y < 44:
			hidden = true
		overlay_sprite.modulate.a = 0.0 if hidden else 1.0
		if sprite:
			sprite.visible = hidden

## Signature utilisée par les tests de cohérence.
func signature() -> String:
	return "%s@%s|%s" % [tex_name, str(position), str(overlay_sprite.modulate if overlay_sprite else Color.WHITE)]

func interact(player: Node) -> void:
	if not def.has("text") and not def.has("dialogue"):
		await DialogueManager.say(["* %s." % def.get("name", "Une chaise rouge"), "* Elle n'a pas changé. Elle ne change jamais."])
	else:
		await super.interact(player)
