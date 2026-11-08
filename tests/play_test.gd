## Test de jeu piloté au clavier (touches simulées). Lancer :
##   $GODOT --headless res://tests/play_test.tscn
## Vérifie : un combat fini en épargnant, un combat fini en tuant, un dialogue avec choix,
## l'ouverture du caméscope, une cassette, une porte, et une sauvegarde rechargée.
extends Node

var failures: Array = []
var main: Node

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.set_script(null)
	var root = Node2D.new()
	add_child(root)
	var cam = Camera2D.new()
	root.add_child(cam)
	var ui = CanvasLayer.new()
	ui.layer = 40
	add_child(ui)
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	ui.add_child(fade)
	World.attach(self, root, cam, ui, fade)
	GameState.new_game("TEST")
	GameState.game_seed = 99
	World.in_game = true
	World._load_room("z1_arrival", 0, "", "default")
	await _wait(0.5)
	await test_spare()
	await test_kill()
	await test_dialogue()
	await test_menu_and_tape()
	await test_door()
	await test_name_entry()
	await test_memory_lock()
	print("")
	if failures.is_empty():
		print("PLAY TEST PASSED")
	else:
		for f in failures:
			print("ÉCHEC : ", f)
	get_tree().quit(0 if failures.is_empty() else 1)

func check(c: bool, msg: String) -> void:
	if not c:
		failures.append(msg)
	print(("ok   " if c else "FAIL ") + msg)

func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func press(key: Key, hold := 0.05) -> void:
	var e = InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	e.pressed = true
	Input.parse_input_event(e)
	await _wait(hold)
	var r = InputEventKey.new()
	r.keycode = key
	r.physical_keycode = key
	r.pressed = false
	Input.parse_input_event(r)
	await _wait(0.12)

## Appuie sur Entrée jusqu'à ce que la condition soit vraie (ou délai dépassé).
func mash_until(cond: Callable, timeout := 30.0, key := KEY_ENTER) -> bool:
	var t = 0.0
	while not bool(cond.call()) and t < timeout:
		await press(key)
		await _wait(0.25)
		t += 0.42
	return bool(cond.call())

func battle_scene() -> Node:
	for c in BattleManager.layer.get_children():
		if c.has_signal("_picked"):
			return c
	return null

func test_spare() -> void:
	var result = {}
	var run = func(): result.merge(await BattleManager.start("drying_sheet"))
	run.call()
	await _wait(1.0)
	var b = battle_scene()
	check(b != null, "le combat s'ouvre")
	if b == null:
		return
	for turn in 2:
		print("  tour ", turn, " mode=", b._input_mode, " mercy=", b.mercy, " pv=", GameState.hp)
		await mash_until(func(): return not is_instance_valid(b) or b._input_mode == "menu", 15.0)
		if not is_instance_valid(b):
			print("  combat terminé trop tôt : ", result)
			return
		await _wait(0.25)
		b._menu_idx = 0
		await press(KEY_RIGHT)          # ACT
		await press(KEY_ENTER)
		await _wait(0.3)
		print("    list=", b._list, " idx=", b._list_idx)
		await press(KEY_RIGHT)          # « Plier »
		print("    list idx after=", b._list_idx)
		await press(KEY_ENTER)
		await mash_until(func(): return b._input_mode == "" and b.soul != null or b._input_mode == "menu", 15.0)
		# esquive : on attend la fin du tour ennemi
		var t = 0.0
		while b.soul != null and t < 10.0:
			await _wait(0.2)
			t += 0.2
	check(b.mercy >= 100, "ACT « Plier » remplit la jauge de pitié (%d)" % b.mercy)
	await mash_until(func(): return b._input_mode == "menu", 15.0)
	await _wait(0.25)
	b._menu_idx = 0
	for i in 3:
		await press(KEY_RIGHT)          # MERCY
	await press(KEY_ENTER)
	await _wait(0.3)
	await press(KEY_ENTER)              # Épargner
	await mash_until(func(): return not result.is_empty(), 20.0)
	check(result.get("outcome", "") == "spared", "combat terminé en épargnant (%s)" % result.get("outcome", "?"))
	check(GameState.spared.has("drying_sheet"), "l'ennemi est noté comme épargné")
	await _wait(0.8)

func test_kill() -> void:
	var result = {}
	var xp_before = GameState.xp
	var run = func(): result.merge(await BattleManager.start("drying_sheet"))
	run.call()
	await _wait(1.0)
	var b = battle_scene()
	var guard = 0
	while result.is_empty() and guard < 6:
		guard += 1
		await mash_until(func(): return b == null or not is_instance_valid(b) or b._input_mode == "menu" or not result.is_empty(), 20.0)
		if not result.is_empty() or not is_instance_valid(b):
			break
		await _wait(0.25)
		b._menu_idx = 0
		b._update_buttons()
		await press(KEY_ENTER)          # FIGHT
		await _wait(0.62)               # la barre arrive au centre
		await press(KEY_ENTER)
		await mash_until(func(): return not result.is_empty() or (is_instance_valid(b) and b.soul != null), 15.0)
		var t = 0.0
		while is_instance_valid(b) and b.soul != null and t < 10.0:
			await _wait(0.2)
			t += 0.2
	await mash_until(func(): return not result.is_empty(), 20.0)
	check(result.get("outcome", "") == "won", "combat terminé en tuant (%s)" % result.get("outcome", "?"))
	check(GameState.kills.has("drying_sheet") and GameState.xp > xp_before, "tuer donne de l'EXP")
	await _wait(0.8)

func test_dialogue() -> void:
	var done = [false]
	var run = func():
		await DialogueManager.play("dana")
		done[0] = true
	run.call()
	await mash_until(func(): return done[0], 30.0)
	check(done[0], "le dialogue de Dana se termine")
	check(GameState.get_flag("met.dana", false), "le dialogue pose ses drapeaux")
	# choix : téléphone de sauvegarde -> Oui
	if FileAccess.file_exists(SaveManager.PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.PATH))
	SaveManager.load_file()
	done[0] = false
	var run2 = func():
		await DialogueManager.play("save_phone")
		done[0] = true
	run2.call()
	await mash_until(func(): return done[0], 30.0)
	check(SaveManager.has_save(), "le téléphone sauvegarde la partie (choix « Oui »)")

func test_menu_and_tape() -> void:
	GameState.give("camcorder")
	GameState.give("t01")
	var done = [false]
	var run = func():
		await World.open_camcorder()
		done[0] = true
	run.call()
	await _wait(0.4)
	await press(KEY_X)
	await _wait(0.3)
	check(done[0], "le caméscope s'ouvre et se ferme")
	done[0] = false
	var run2 = func():
		await World.play_tape("t01")
		done[0] = true
	run2.call()
	await mash_until(func(): return done[0], 40.0)
	check(GameState.tapes_seen.has("t01"), "la cassette t01 est vue")

func test_door() -> void:
	World._load_room("z1_halls", 0, "", "default")
	await _wait(0.3)
	var d: Door = World.current_room.find_door("east")
	World.player.global_position = d.global_position + Vector2(-60, -10)
	await _wait(0.2)
	var e = InputEventKey.new()
	e.keycode = KEY_RIGHT
	e.physical_keycode = KEY_RIGHT
	e.pressed = true
	Input.parse_input_event(e)
	var t = 0.0
	while World.current_room.depth == 0 and t < 5.0:
		await _wait(0.1)
		t += 0.1
	var r = InputEventKey.new()
	r.keycode = KEY_RIGHT
	r.physical_keycode = KEY_RIGHT
	r.pressed = false
	Input.parse_input_event(r)
	await _wait(0.6)
	check(World.current_room.source.id == "z1_halls" and World.current_room.depth == 1, "marcher dans la porte mène à la copie suivante (#%d)" % World.current_room.depth)

func type_key(key: Key, uni: int) -> void:
	var e = InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	e.unicode = uni
	e.pressed = true
	Input.parse_input_event(e)
	await _wait(0.05)
	var r = InputEventKey.new()
	r.keycode = key
	r.physical_keycode = key
	r.pressed = false
	Input.parse_input_event(r)
	await _wait(0.1)

func test_name_entry() -> void:
	var ne = load("res://scenes/ui/name_entry.gd").new()
	ne.return_mode = true
	ne.allow_skip = true
	var got = [null]
	ne.named.connect(func(n): got[0] = n)
	add_child(ne)
	await _wait(0.4)
	await type_key(KEY_L, "l".unicode_at(0))
	await type_key(KEY_E, "e".unicode_at(0))
	await type_key(KEY_A, "a".unicode_at(0))
	await press(KEY_ENTER)      # terminer
	await _wait(0.2)
	await press(KEY_ENTER)      # confirmer « Oui »
	await _wait(0.3)
	check(got[0] == "Lea", "saisie du prénom au clavier puis Entrée (%s)" % str(got[0]))

func _type_word(w: String) -> void:
	for c in w:
		await type_key(OS.find_keycode_from_string(c), c.unicode_at(0))

func test_memory_lock() -> void:
	check(SaveManager.PATH == SaveManager.TEST_PATH, "les tests n'écrivent pas dans la vraie sauvegarde")
	GameState.meta.erase("memory_unlocked")
	var title = load("res://scenes/ui/title_screen.gd").new()
	add_child(title)
	await _wait(0.3)
	check(title.menu.icons.size() == 1, "le souvenir est verrouillé (cadenas)")
	title.menu.visible = false     # comme dans le jeu pendant la saisie
	var r = [null]
	var run = func(): r[0] = await title._ask_memory_password()
	run.call()
	await _wait(0.4)
	await _type_word("FAUX")
	await press(KEY_ENTER)
	await _wait(0.3)
	check(r[0] == false and not title.memory_unlocked(), "mauvais mot de passe : reste verrouillé")
	r[0] = null
	run.call()
	await _wait(0.4)
	await _type_word("souvenir")
	await press(KEY_ENTER)
	await _wait(0.3)
	check(r[0] == true and title.memory_unlocked() and title.menu.icons.is_empty(), "bon mot de passe : le cadenas disparaît")
	GameState.meta.erase("memory_unlocked")
	SaveManager.write_meta()
	title.set_process_input(false)
	title.menu.set_process_input(false)
	title.queue_free()

## Même rôle que Main.add_overlay dans le jeu.
func add_overlay(node: Node) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 92
	add_child(layer)
	layer.add_child(node)
	node.tree_exited.connect(layer.queue_free)
