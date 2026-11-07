## Scène principale : monde, calques d'interface, post-traitement et enchaînement des écrans.
extends Node

var world_root: Node2D
var camera: Camera2D
var ui_layer: CanvasLayer
var fx_layer: CanvasLayer
var fx_rect: ColorRect
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var screen: Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	world_root = Node2D.new()
	world_root.name = "World"
	add_child(world_root)
	camera = Camera2D.new()
	camera.name = "Camera"
	world_root.add_child(camera)
	camera.make_current()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 40
	ui_layer.name = "UI"
	add_child(ui_layer)
	fx_layer = CanvasLayer.new()
	fx_layer.layer = 50
	fx_layer.name = "FX"
	add_child(fx_layer)
	fx_rect = ColorRect.new()
	fx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_rect.size = Vector2(640, 480)
	fx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(fx_rect)
	FxManager.attach(fx_rect)
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 90
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.size = Vector2(640, 480)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	World.attach(self, world_root, camera, ui_layer, fade_rect)
	_apply_options()
	var args = _dev_args()
	if args.has("room"):
		_dev_start(args)
	elif OS.get_cmdline_user_args().has("--skip-intro"):
		start_new_game("TEST")
	else:
		show_screen(preload("res://scenes/ui/fake_boot.gd").new())

func _apply_options() -> void:
	var o: Dictionary = GameState.meta.get("options", {})
	if o.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func show_screen(s: Node) -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = s
	ui_layer.add_child(s)

func clear_screen() -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = null

func show_title() -> void:
	World.clear()
	AudioManager.stop_music()
	FxManager.set_fidelity(100, true)
	show_screen(preload("res://scenes/ui/title_screen.gd").new())

func start_new_game(name: String) -> void:
	clear_screen()
	GameState.new_game(name)
	DegradationManager.bonuses.clear()
	DegradationManager.visited.clear()
	DegradationManager.invalidate()
	SaveManager.write_meta()
	World.in_game = true
	World._load_room("house_bedroom", 0, "", "default")
	World._on_room_entered()
	await World.fade(false, 1.0)

func continue_game() -> void:
	clear_screen()
	await SaveManager.load_game()
	await World.fade(false, 0.6)

func open_debug_room() -> void:
	clear_screen()
	if GameState.player_name == "":
		GameState.new_game("DEV")
	World.in_game = true
	World._load_room("debug_room", 0, "", "default")
	World._on_room_entered()
	await World.fade(false, 0.5)

func show_credits(ending_id: String) -> void:
	World.clear()
	var c = preload("res://scenes/ui/credits.gd").new()
	c.ending_id = ending_id
	show_screen(c)

# ---------------------------------------------------------------- Outils de développement
## Arguments après « -- » : --room=id --depth=n --fidelity=f --battle=id --tape=id
## --screenshot=chemin.png --frames=n --seed=n --pos=x,y
func _dev_args() -> Dictionary:
	var out = {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv = a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1]
	return out

func _dev_start(args: Dictionary) -> void:
	GameState.new_game("TEST")
	if args.has("seed"):
		GameState.game_seed = int(args["seed"])
	for it in str(args.get("give", "")).split(",", false):
		GameState.give(it)
	var depth = int(args.get("depth", 0))
	if args.has("fidelity"):
		var f = int(args["fidelity"])
		DegradationManager.set_debug_offset(args["room"], depth, f - DegradationManager.raw_fidelity(args["room"], depth))
	World.in_game = true
	World._load_room(args["room"], depth, args.get("door", ""), "default")
	if args.has("pos"):
		var p = str(args["pos"]).split(",")
		World.player.global_position = Vector2(float(p[0]), float(p[1]))
	if args.get("nofx", "") == "1":
		fx_rect.visible = false
	if args.get("overlay", "") == "1":
		DebugTools.overlay.visible = true
	if args.has("battle"):
		BattleManager.start(args["battle"])
	if args.has("tape"):
		World.play_tape(args["tape"])
	if args.has("dialogue"):
		DialogueManager.play(args["dialogue"])
	if args.has("menu"):
		World.open_camcorder()
	if args.has("screenshot"):
		var frames = int(args.get("frames", 30))
		for i in frames:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if World.current_room:
			print("DEV room ", World.current_room.pixel_size(), " cam ", camera.global_position, " player ", World.player.global_position, " rows ", World.current_room.tiles.height(), " F ", World.current_room.fidelity)
		get_viewport().get_texture().get_image().save_png(args["screenshot"])
		get_tree().quit()
