## Transition et état des combats. Les ennemis viennent de data/enemies/*.json.
extends Node

signal battle_finished(result: Dictionary)

const BATTLE_SCRIPT := "res://scenes/battle/battle_scene.gd"

var active = false
var layer: CanvasLayer

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

func load_enemy(id: String) -> Dictionary:
	var d = JsonUtil.load_json("res://data/enemies/%s.json" % id)
	if d is Dictionary:
		var e: Dictionary = d.duplicate(true)
		e["id"] = id
		return e
	push_error("Ennemi introuvable : %s" % id)
	return {}

## Lance un combat ; renvoie {"outcome": "won"|"spared"|"fled"|"dead"|"talked", ...}.
func start(enemy_id: String, opts: Dictionary = {}) -> Dictionary:
	if active:
		return {"outcome": "busy"}
	var enemy = load_enemy(enemy_id)
	if enemy.is_empty():
		return {"outcome": "error"}
	active = true
	GameState.lock("battle")
	# transition : clignotement et cœur, comme dans Undertale
	AudioManager.sfx("encounter")
	await World.fade(true, 0.2)
	if World.world_root:
		World.world_root.visible = false
	var prev_music = AudioManager.current_music
	var f = World.current_fidelity()
	var scene = load(BATTLE_SCRIPT).new()
	scene.setup(enemy, f, opts)
	layer.add_child(scene)
	await World.fade(false, 0.15)
	var result: Dictionary = await scene.finished
	await World.fade(true, 0.25)
	scene.queue_free()
	if World.world_root:
		World.world_root.visible = true
	if result.get("outcome") == "dead":
		await _game_over()
		active = false
		GameState.unlock("battle")
		return result
	AudioManager.stop_music()
	if World.current_room:
		AudioManager.on_room(World.current_room)
	await World.fade(false, 0.25)
	active = false
	GameState.unlock("battle")
	battle_finished.emit(result)
	return result

func _game_over() -> void:
	var go = preload("res://scenes/battle/game_over.gd").new()
	layer.add_child(go)
	await go.finished
	go.queue_free()
	GameState.hp = GameState.max_hp()
	if SaveManager.has_save():
		await SaveManager.load_game()
	else:
		World._load_room("house_bedroom", 0, "", "default")
	await World.fade(false, 0.5)
