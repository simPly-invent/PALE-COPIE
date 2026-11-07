## PNJ : dialogue en JSON (versions par palier), mémoire de dialogue via les drapeaux.
class_name Npc
extends Interactable

var _t = 0.0
var _base_y = 0.0

func default_sprite() -> String:
	return "npc_kid"

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	add_to_group("npc")
	if sprite:
		_base_y = sprite.position.y
	_t = randf() * 6.0

func _process(delta: float) -> void:
	_t += delta
	if sprite and not def.get("still", false):
		# légère respiration
		sprite.position.y = _base_y + (1.0 if fmod(_t, 2.0) > 1.0 else 0.0)

func interact(player: Node) -> void:
	if sprite and player and not def.get("no_turn", false):
		sprite.flip_h = (player.global_position.x < global_position.x) != def.get("flip", false)
	GameState.set_flag("met." + str(def.get("id", "")))
	await super.interact(player)
