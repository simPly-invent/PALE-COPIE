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

## Cartons de texte sur fond noir, un par un.
static func cards(lines: Array, hold := 2.6, keep_black := false) -> void:
	GameState.lock("cards")
	var layer = CanvasLayer.new()
	layer.layer = 95
	World.get_tree().root.add_child(layer)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.size = Vector2(640, 480)
	layer.add_child(bg)
	var tw = bg.create_tween()
	tw.tween_property(bg, "color:a", 1.0, 0.8)
	await tw.finished
	for line in lines:
		var l = UI.label(TextFx.process(str(line), 100, 0), 24, Color(0.92, 0.9, 0.85))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.position = Vector2(40, 140)
		l.size = Vector2(560, 200)
		l.modulate.a = 0.0
		layer.add_child(l)
		var t2 = l.create_tween()
		t2.tween_property(l, "modulate:a", 1.0, 1.0)
		t2.tween_interval(hold)
		t2.tween_property(l, "modulate:a", 0.0, 1.0)
		await t2.finished
		l.queue_free()
	if keep_black:
		# la salle suivante apparaîtra en fondu : on ne revoit jamais l'ancienne
		World.fade_rect.color.a = 1.0
	else:
		var t3 = bg.create_tween()
		t3.tween_property(bg, "color:a", 0.0, 0.8)
		await t3.finished
	layer.queue_free()
	GameState.unlock("cards")

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
