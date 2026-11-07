## Outil de prévisualisation : génère côte à côte les 10 premières copies d'une salle source.
## Lancer la scène degradation_preview.tscn (ou : $GODOT res://scenes/tools/degradation_preview.tscn -- --room=z1_halls).
## ←/→ : salle source précédente/suivante. ↑/↓ : décaler la première profondeur affichée.
extends Node2D

const COLS := 5
const ROWS := 2
const CELL := Vector2(256, 250)

var source_ids: Array = []
var idx = 0
var first_depth = 0
var labels: Array = []
var layer: CanvasLayer

func _ready() -> void:
	if GameState.game_seed == 0:
		GameState.game_seed = 1997
	source_ids = DegradationManager.sources.keys()
	source_ids.sort()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--room="):
			idx = max(0, source_ids.find(a.substr(7)))
		if a.begins_with("--seed="):
			GameState.game_seed = int(a.substr(7))
	get_window().content_scale_size = Vector2i(int(COLS * CELL.x), int(ROWS * CELL.y + 40))
	get_window().size = get_window().content_scale_size
	var cam = Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(cam)
	cam.make_current()
	layer = CanvasLayer.new()
	add_child(layer)
	_build()

func _build() -> void:
	for c in get_children():
		if c is Room or c is Label:
			c.queue_free()
	for l in labels:
		l.queue_free()
	labels.clear()
	var sid: String = source_ids[idx]
	var head = UI.label("%s  —  graine %d  —  ←/→ salle, ↑/↓ profondeur" % [sid, GameState.game_seed], 16, Color(0.7, 1, 0.7))
	head.position = Vector2(8, ROWS * CELL.y + 10)
	layer.add_child(head)
	labels.append(head)
	for k in COLS * ROWS:
		var depth = first_depth + k
		var room = DegradationManager.make_copy(sid, depth)
		var size: Vector2 = room.pixel_size()
		var s = minf((CELL.x - 8) / size.x, (CELL.y - 76) / size.y)
		room.scale = Vector2(s, s)
		room.position = Vector2((k % COLS) * CELL.x + 4, (k / COLS) * CELL.y + 4)
		add_child(room)
		var desc = DegradationManager.descriptor(sid, depth)
		var muts: Array = room.active_mutations.map(func(m): return m["id"])
		var l = UI.label("#%d  F=%d  p%d\n%s" % [depth, desc["fidelity"], desc["palier"], "\n".join(muts)], 11)
		l.position = Vector2((k % COLS) * CELL.x + 4, (k / COLS) * CELL.y + CELL.y - 70)
		l.size = Vector2(CELL.x - 8, 66)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layer.add_child(l)
		labels.append(l)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	if event.is_action_pressed("move_right"):
		idx = (idx + 1) % source_ids.size()
	elif event.is_action_pressed("move_left"):
		idx = (idx - 1 + source_ids.size()) % source_ids.size()
	elif event.is_action_pressed("move_down"):
		first_depth += COLS * ROWS
	elif event.is_action_pressed("move_up"):
		first_depth = max(0, first_depth - COLS * ROWS)
	else:
		return
	_build()

func _process(_d: float) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screenshot=") and Engine.get_process_frames() > 20:
			set_process(false)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(a.substr(13))
			get_tree().quit()
