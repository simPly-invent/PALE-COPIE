## Point de sauvegarde : un téléphone fixe qui sonne dans le vide.
class_name SavePhone
extends Interactable

var _ring_t = 0.0
var _shake = 0.0

func default_sprite() -> String:
	return "phone"

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	add_to_group("save_phone")
	_ring_t = randf_range(2.0, 6.0)

func _process(delta: float) -> void:
	if not def.get("ring", true):
		return
	_ring_t -= delta
	if _ring_t <= 0:
		_ring_t = randf_range(7.0, 14.0)
		_shake = 1.2
		var p = get_tree().get_first_node_in_group("player") as Node2D
		if p and p.global_position.distance_to(global_position) < 360:
			AudioManager.sfx("phone_ring", -10.0 - p.global_position.distance_to(global_position) / 30.0)
	if _shake > 0 and sprite:
		_shake -= delta
		sprite.position.x = (randf() - 0.5) * 2.0 if _shake > 0 else 0.0

func interact(_player: Node) -> void:
	await DialogueManager.play(def.get("dialogue", "save_phone"))
