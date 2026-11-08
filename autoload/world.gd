## Gestion de l'overworld : changement de salle, caméra, portes, rencontres, Entité.
extends Node

signal room_changed(room: Node)

const PLAYER_SCRIPT := preload("res://scenes/overworld/player.gd")
const VIEW := Vector2(640, 480)

var main: Node
var world_root: Node2D
var camera: Camera2D
var ui_layer: CanvasLayer
var fade_rect: ColorRect
var current_room: Node
var player: CharacterBody2D
var follower: Node2D
var transitioning_out = false
var in_game = false
var _encounter_left = 900.0
var _entity_timer = -1.0
var _shake = 0.0
var _room_battles: Dictionary = {}

func attach(m: Node, root: Node2D, cam: Camera2D, ui: CanvasLayer, fade: ColorRect) -> void:
	main = m
	world_root = root
	camera = cam
	ui_layer = ui
	fade_rect = fade

func current_fidelity() -> int:
	if current_room:
		return current_room.fidelity
	return 100

func current_palier() -> int:
	return DegradationManager.palier_of(current_fidelity())

func current_zone() -> Dictionary:
	return current_room.zone if current_room else {}

# ---------------------------------------------------------------- Salles
func goto_room(source_id: String, depth := 0, door_id := "", spawn_id := "", fade_time := 0.25) -> void:
	if not DegradationManager.sources.has(source_id):
		push_error("goto_room : salle inconnue %s" % source_id)
		return
	transitioning_out = true
	GameState.lock("transition")
	if fade_time > 0 and current_room:
		await fade(true, fade_time)
	_load_room(source_id, depth, door_id, spawn_id)
	transitioning_out = false
	if fade_time > 0:
		await fade(false, fade_time)
	GameState.unlock("transition")
	_on_room_entered()

func _load_room(source_id: String, depth: int, door_id: String, spawn_id: String, pos := Vector2.INF) -> void:
	if current_room:
		current_room.queue_free()
		if player and player.get_parent() == current_room:
			current_room.remove_child(player)
		if follower and follower.get_parent() == current_room:
			current_room.remove_child(follower)
	var room = DegradationManager.make_copy(source_id, depth)
	if room == null:
		room = DegradationManager.make_copy("z1_arrival", 0)
	current_room = room
	world_root.add_child(room)
	if player == null:
		player = PLAYER_SCRIPT.new()
		player.name = "Player"
	room.add_child(player)
	var p = _spawn_position(room, door_id, spawn_id)
	if pos != Vector2.INF:
		p = pos
	player.global_position = p
	if door_id != "":
		var d: Door = room.find_door(door_id)
		if d:
			var o = -d.outward()
			player.face("down" if o.y > 0 else "up" if o.y < 0 else "right" if o.x > 0 else "left")
	if follower:
		room.add_child(follower)
		follower.global_position = p + Vector2(0, -4)
		follower.reset_trail()
	GameState.room_key = {"source": source_id, "depth": depth}
	GameState.still_time = 0.0
	# une interaction qui change de salle (lit, porte...) ne doit jamais laisser le joueur bloqué
	GameState.unlock("interact")
	GameState.unlock("door")
	if depth > 0 and GameState.has_item("badge"):
		GameState.badge_decay += 1
	_update_camera(true)
	FxManager.set_fidelity(room.fidelity, true)
	AudioManager.on_room(room)
	room_changed.emit(room)

func _spawn_position(room: Node, door_id: String, spawn_id: String) -> Vector2:
	if door_id != "":
		var d: Door = room.find_door(door_id)
		if d:
			return d.spawn_point()
	for id in [spawn_id, "default"]:
		if id != "" and room.spawns.has_node(NodePath(id)):
			return room.spawns.get_node(NodePath(id)).position
	return room.pixel_size() / 2.0

func _on_room_entered() -> void:
	_encounter_left = randf_range(700, 1400)
	_entity_timer = -1.0
	var src: RoomSource = current_room.source
	# l'Entité n'apparaît qu'à faible fidélité, jamais dans une salle de sauvegarde
	if current_room.palier >= 5 and src.get_list("phones").is_empty() and not src.data.get("no_entity", false):
		var rng = JsonUtil.make_rng([GameState.game_seed, "entity", DegradationManager.key(src.id, current_room.depth)])
		if rng.randf() < float(current_zone().get("entity_chance", 0.3)):
			_entity_timer = rng.randf_range(3.0, 9.0)
	if src.data.has("on_enter"):
		await Actions.run(src.data["on_enter"], current_room)

func rebuild_current() -> void:
	if current_room == null:
		return
	var pos = player.global_position
	await fade(true, 0.15)
	_load_room(current_room.source.id, current_room.depth, "", "", pos)
	await fade(false, 0.15)

## Utiliser un Souvenir dans la salle actuelle.
func restore_current(amount := 20) -> void:
	if current_room == null:
		return
	DegradationManager.restore(current_room.source.id, current_room.depth, amount)

func use_door(door: Door, body: Node) -> void:
	var d: Dictionary = door.def
	var room_src: RoomSource = current_room.source
	var depth: int = current_room.depth
	if d.has("locked_if") and GameState.check(d["locked_if"]) or d.has("requires") and not GameState.check(d["requires"]):
		GameState.lock("door")
		body.global_position = door.spawn_point()
		await DialogueManager.say(d.get("locked_text", ["* C'est fermé à clé."]))
		GameState.unlock("door")
		return
	if d.has("backwards_to") and body.has_method("is_walking_backwards") and body.is_walking_backwards():
		var b: Dictionary = d["backwards_to"]
		await goto_room(b["room"], int(b.get("depth", 0)), b.get("door", ""))
		return
	var maze_ok = d.get("to", "") == "@maze" and door == nearest_door_to_anchor()
	if d.get("to", "") == "@maze" and not maze_ok:
		GameState.inc_flag("maze_fails")
	var res = resolve_door(room_src, depth, d, maze_ok)
	if res.is_empty():
		return
	var target: String = res[0]
	var tdepth: int = res[1]
	var tdoor: String = res[2]
	await goto_room(target, tdepth, tdoor)

## Résout la destination d'une porte : [salle, profondeur, porte d'arrivée], ou [] si aucune.
func resolve_door(room_src: RoomSource, depth: int, d: Dictionary, maze_ok := false) -> Array:
	var to: String = d.get("to", "")
	var target = room_src.id
	var tdepth = 0
	var tdoor: String = d.get("to_door", "")
	match to:
		"":
			return []
		"@next":
			tdepth = depth + 1
			var chain: Dictionary = room_src.data.get("chain", {})
			if not chain.is_empty() and tdepth > int(chain.get("max_depth", 99)):
				target = chain["then"]
				tdepth = int(chain.get("then_depth", 0))
				tdoor = chain.get("then_door", tdoor)
		"@prev":
			if depth > 0:
				tdepth = depth - 1
			else:
				var back: Dictionary = room_src.data.get("back", {})
				if back.is_empty():
					return []
				target = back["room"]
				tdepth = int(back.get("depth", 0))
				tdoor = back.get("door", tdoor)
		"@self":
			tdepth = depth
			tdoor = d.get("to_door", d.get("id", ""))
		"@maze":
			var maze: Dictionary = room_src.data.get("maze", {})
			if maze_ok:
				tdepth = depth + 1
				tdoor = maze.get("entry", tdoor)
				if tdepth > int(maze.get("steps", 4)):
					target = maze["then"]
					tdepth = 0
					tdoor = maze.get("then_door", "")
			else:
				tdepth = int(maze.get("fail_depth", 1))
				tdoor = maze.get("entry", tdoor)
		_:
			target = to
			tdepth = int(d.get("depth", 0))
	return [target, tdepth, tdoor]

func nearest_door_to_anchor() -> Door:
	var a: RoomAnchor = current_room.anchor_node() if current_room else null
	if a == null:
		return null
	var best: Door = null
	var bd = 1e9
	for d in current_room.doors.get_children():
		if d is Door and d.def.get("to", "") == "@maze":
			var dist: float = d.position.distance_to(a.position)
			if dist < bd:
				bd = dist
				best = d
	return best

# ---------------------------------------------------------------- Caméra
func _process(delta: float) -> void:
	if current_room and player:
		_update_camera(false)
	if _shake > 0:
		_shake -= delta
		camera.offset = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if _shake > 0 else Vector2.ZERO
	_check_still_secret()
	if _entity_timer > 0 and not GameState.is_locked():
		_entity_timer -= delta
		if _entity_timer <= 0:
			entity_event("pass", {})

## Secret : un PNJ visible seulement si l'on reste 2 minutes immobile.
func _check_still_secret() -> void:
	if current_room == null or GameState.is_locked():
		return
	var sn: Dictionary = current_room.source.data.get("still_npc", {})
	if sn.is_empty() or current_room.has_meta("still_spawned"):
		return
	if GameState.still_time >= float(sn.get("after", 120.0)):
		current_room.set_meta("still_spawned", true)
		var npc = Npc.new()
		npc.setup(sn, current_room)
		npc.modulate.a = 0.0
		current_room.npcs.add_child(npc)
		npc.create_tween().tween_property(npc, "modulate:a", 1.0, 3.0)
		GameState.set_flag("secret.still_seen")

func shake(t: float) -> void:
	_shake = t

## Caméra fixe façon caméra de surveillance si la salle tient à l'écran, sinon suivi borné.
func _update_camera(_snap: bool) -> void:
	if camera == null:
		return
	var size: Vector2 = current_room.pixel_size()
	var target = Vector2.ZERO
	if size.x <= VIEW.x:
		target.x = size.x / 2.0
	else:
		target.x = clampf(player.global_position.x, VIEW.x / 2.0, size.x - VIEW.x / 2.0)
	if size.y <= VIEW.y:
		target.y = size.y / 2.0
	else:
		target.y = clampf(player.global_position.y - 20, VIEW.y / 2.0, size.y - VIEW.y / 2.0)
	camera.global_position = target.round()

# ---------------------------------------------------------------- Pas, rencontres
func footstep() -> void:
	if current_room == null:
		return
	var size: Vector2 = current_room.pixel_size()
	AudioManager.footstep(size.x * size.y / (640.0 * 480.0), current_room.fidelity)

func on_player_walked(dist: float) -> void:
	if current_room == null:
		return
	var enc: Dictionary = current_room.source.data.get("encounters", {})
	if enc.is_empty() or GameState.is_locked():
		return
	var k = DegradationManager.key(current_room.source.id, current_room.depth)
	if int(_room_battles.get(k, 0)) >= int(enc.get("max", 2)):
		return
	_encounter_left -= dist * float(enc.get("rate", 1.0))
	if _encounter_left <= 0:
		_encounter_left = randf_range(900, 1600)
		_room_battles[k] = int(_room_battles.get(k, 0)) + 1
		var list: Array = enc.get("enemies", [])
		if list.is_empty():
			return
		var e: String = list[randi() % list.size()]
		BattleManager.start(e, {"encounter": true})

# ---------------------------------------------------------------- Divers
func fade(out: bool, t := 0.3) -> void:
	if fade_rect == null:
		return
	var tw = fade_rect.create_tween()
	tw.tween_property(fade_rect, "color:a", 1.0 if out else 0.0, t)
	await tw.finished

func open_camcorder() -> void:
	if not GameState.has_item("camcorder"):
		await DialogueManager.say(["* (Tu n'as rien sur toi pour l'instant.)"])
		return
	var menu = preload("res://scenes/ui/camcorder_menu.gd").new()
	ui_layer.add_child(menu)
	await menu.closed

func play_tape(id: String) -> void:
	var p = preload("res://scenes/ui/vhs_player.gd").new()
	ui_layer.add_child(p)
	p.play(id)
	await p.finished

func set_follower(id: String) -> void:
	if follower:
		follower.queue_free()
		follower = null
	if id == "none" or id == "":
		return
	follower = preload("res://scenes/overworld/follower.gd").new()
	follower.setup(id)
	if current_room:
		current_room.add_child(follower)
		follower.global_position = player.global_position
		follower.reset_trail()

func entity_event(kind: String, opts: Dictionary) -> void:
	if current_room == null:
		return
	var e = preload("res://scenes/overworld/entity.gd").new()
	e.mode = kind
	e.opts = opts
	current_room.add_child(e)

func clear() -> void:
	if current_room:
		current_room.queue_free()
		current_room = null
	if player:
		player.queue_free()
		player = null
	if follower:
		follower.queue_free()
		follower = null
	in_game = false
