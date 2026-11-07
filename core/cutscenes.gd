## Petites cinématiques scriptées (chute « noclip », fins). Le texte vient des données.
class_name Cutscenes
extends RefCounted

static func play(id: String, opts: Dictionary = {}) -> void:
	match id:
		"fall":
			await _fall(opts)
		"ending":
			await _ending()
		"tape_sequence":
			await World.play_tape(opts.get("tape", ""))

## Le sol cède sous le lit.
static func _fall(opts: Dictionary) -> void:
	GameState.lock("cutscene")
	FxManager.shake(1.2)
	AudioManager.stop_music()
	AudioManager.sfx("fall")
	var p = World.player
	if p:
		var tw = p.create_tween()
		tw.tween_property(p, "scale", Vector2(0.2, 0.2), 1.4)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 1.4)
		await tw.finished
	await World.fade(true, 0.6)
	await World.get_tree().create_timer(1.2).timeout
	if p:
		p.scale = Vector2.ONE
		p.modulate.a = 1.0
	GameState.unlock("cutscene")
	await DialogueManager.say(opts.get("lines", ["* ..."]))
	var g: Dictionary = opts.get("to", {"room": "z1_arrival"})
	World._load_room(g["room"], int(g.get("depth", 0)), g.get("door", ""), g.get("spawn", ""))
	await World.fade(false, 1.5)
	World._on_room_entered()

## Fin du jeu : calculée par GameState.compute_ending() puis jouée depuis data/endings/<id>.json.
static func _ending() -> void:
	var id = GameState.compute_ending()
	GameState.meta["endings_seen"] = GameState.meta.get("endings_seen", [])
	if not GameState.meta["endings_seen"].has(id):
		GameState.meta["endings_seen"].append(id)
	var d = JsonUtil.load_json("res://data/endings/%s.json" % id)
	if not (d is Dictionary):
		return
	GameState.lock("ending")
	await World.fade(true, 1.5)
	var player = preload("res://scenes/ui/vhs_player.gd").new()
	World.ui_layer.add_child(player)
	player.play_data(d)
	await player.finished
	GameState.unlock("ending")
	if id == "effacement":
		# le jeu relance le prologue, mais tout y est légèrement faux
		GameState.meta["prologue_wrong"] = true
	SaveManager.write_meta()
	World.main.show_credits(id)
