## Scène de combat façon Undertale : FIGHT, ACT, ITEM, MERCY ; âme dans une boîte ;
## patterns rejoués avec des erreurs ; boîte qui se dégrade avec la fidélité.
extends Control

signal finished(result: Dictionary)
signal _picked(index: int)

const BTN := ["FIGHT", "ACT", "ITEM", "MERCY"]
const BOX_WIDE := Rect2(32, 250, 576, 140)
const ZONE_SOUL := {3: "heavy", 5: "reflect", 6: "erased"}

var enemy: Dictionary = {}
var fidelity = 100
var palier = 0
var opts: Dictionary = {}
var hp = 0
var max_hp = 0
var mercy = 0
var turn = 0
var name_restored = false
var waits_in_row = 0
var last_player_action = ""
var pending_copy_action = ""

var enemy_sprite: TextureRect
var box: Panel
var box_ghost: Panel
var box_dark: Control
var box_rect = BOX_WIDE
var text: Label
var stats: Label
var hp_bar: ColorRect
var hp_bar_bg: ColorRect
var buttons: Array = []
var heart: TextureRect
var bubble: Panel
var bubble_label: Label
var enemy_hp_bar: ColorRect
var soul: Soul
var arena: Node2D
var pattern: BulletPattern
var _input_mode = ""         # "menu", "list", "wait", "bar"
var _list: Array = []
var _list_idx = 0
var _menu_idx = 0
var _list_labels: Array = []
var _bar_x = 0.0
var _bar_node: ColorRect
var _rng = RandomNumberGenerator.new()
var _accept_after = 0
var _box_flicker = 0.0

func setup(e: Dictionary, f: int, o: Dictionary) -> void:
	enemy = e
	fidelity = f
	palier = DegradationManager.palier_of(f)
	opts = o
	max_hp = int(e.get("hp", 20))
	hp = max_hp
	_rng.randomize()

func _ready() -> void:
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	enemy_sprite = TextureRect.new()
	enemy_sprite.texture = Assets.tex(enemy.get("sprite", "enemy_ghost"))
	enemy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sc = float(enemy.get("scale", 2.0))
	enemy_sprite.size = enemy_sprite.texture.get_size() * sc
	enemy_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_sprite.position = Vector2(320 - enemy_sprite.size.x / 2.0, 235 - enemy_sprite.size.y)
	add_child(enemy_sprite)
	enemy_hp_bar = ColorRect.new()
	enemy_hp_bar.visible = false
	add_child(enemy_hp_bar)
	box_ghost = Panel.new()
	box_ghost.add_theme_stylebox_override("panel", UI.frame_style(3, Color(0, 0, 0, 0), Color(1, 1, 1, 0.25)))
	box_ghost.visible = palier >= 5
	add_child(box_ghost)
	box = Panel.new()
	box.add_theme_stylebox_override("panel", UI.frame_style(4))
	box.clip_contents = true
	add_child(box)
	text = UI.label("", 22)
	text.position = Vector2(24, 16)
	text.size = Vector2(530, 110)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	arena = Node2D.new()
	add_child(arena)
	box_dark = Control.new()
	box_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box_dark.visible = false
	box_dark.draw.connect(_draw_dark)
	add_child(box_dark)
	stats = UI.label("", 20)
	stats.position = Vector2(32, 398)
	add_child(stats)
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.color = Color(0.75, 0.1, 0.1)
	hp_bar_bg.position = Vector2(290, 402)
	add_child(hp_bar_bg)
	hp_bar = ColorRect.new()
	hp_bar.color = Color(1, 0.95, 0.2)
	hp_bar.position = Vector2(290, 402)
	add_child(hp_bar)
	var labels: Array = BTN
	if enemy.get("special", "") == "entity":
		labels = ["…", "", "", ""]
	for i in 4:
		var b = Panel.new()
		b.position = Vector2(32 + i * 153, 430)
		b.size = Vector2(120, 42)
		b.add_theme_stylebox_override("panel", UI.frame_style(3, Color.BLACK, Color(1, 0.55, 0.1)))
		b.visible = labels[i] != ""
		var l = UI.label(labels[i], 22, Color(1, 0.55, 0.1))
		l.position = Vector2(34, 6)
		b.add_child(l)
		add_child(b)
		buttons.append(b)
	heart = UI.sprite_rect("soul_red", 0.55)
	heart.visible = false
	add_child(heart)
	bubble = Panel.new()
	bubble.add_theme_stylebox_override("panel", UI.frame_style(2, Color.WHITE, Color.BLACK))
	bubble.visible = false
	add_child(bubble)
	bubble_label = UI.label("", 16, Color.BLACK)
	bubble_label.position = Vector2(8, 6)
	bubble_label.size = Vector2(164, 90)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(bubble_label)
	_set_box(_degraded_box(BOX_WIDE), true)
	_update_stats()
	var music: String = enemy.get("music", "battle")
	AudioManager.play_music(music, fidelity)
	_run()

# ---------------------------------------------------------------- Boîte
## La boîte se dégrade : étirée (palier 4), dupliquée (palier 5), bords invisibles (palier 6).
func _degraded_box(r: Rect2) -> Rect2:
	if palier >= 4:
		var w: float = min(600.0, r.size.x * 1.25)
		r = Rect2(Vector2(320 - w / 2.0, r.position.y), Vector2(w, r.size.y))
	return r

func _set_box(r: Rect2, instant := false) -> void:
	box_rect = r
	if instant:
		box.position = r.position
		box.size = r.size
	else:
		var tw = create_tween()
		tw.tween_property(box, "position", r.position, 0.2)
		tw.parallel().tween_property(box, "size", r.size, 0.2)
	box_ghost.position = r.position + Vector2(10, -8)
	box_ghost.size = r.size
	box_dark.position = Vector2.ZERO
	box_dark.size = size

func _process(delta: float) -> void:
	_update_stats()
	if palier >= 6:
		_box_flicker -= delta
		if _box_flicker <= 0:
			_box_flicker = _rng.randf_range(0.3, 1.5)
			box.self_modulate.a = 0.0 if _rng.randf() < 0.35 else 1.0
	if _input_mode == "bar" and _bar_node:
		_bar_x += delta * 380.0
		_bar_node.position.x = 40 + _bar_x
		if _bar_x > 500:
			_input_mode = ""
			_picked.emit(-1)
	if soul and pattern:
		if box_dark.visible:
			box_dark.queue_redraw()
		if soul.invuln <= 0:
			var dmg = pattern.check_hit(soul.position, Soul.RADIUS)
			if dmg > 0:
				_hurt(dmg)

func _draw_dark() -> void:
	# le Gardien des Néons coupe la lumière : seul un halo autour de l'âme reste visible
	var r = box_rect.grow(-4)
	var c = soul.position if soul else r.get_center()
	var hole = Rect2(c - Vector2(36, 36), Vector2(72, 72)).intersection(r)
	box_dark.draw_rect(Rect2(r.position, Vector2(r.size.x, hole.position.y - r.position.y)), Color.BLACK)
	box_dark.draw_rect(Rect2(Vector2(r.position.x, hole.end.y), Vector2(r.size.x, r.end.y - hole.end.y)), Color.BLACK)
	box_dark.draw_rect(Rect2(Vector2(r.position.x, hole.position.y), Vector2(hole.position.x - r.position.x, hole.size.y)), Color.BLACK)
	box_dark.draw_rect(Rect2(Vector2(hole.end.x, hole.position.y), Vector2(r.end.x - hole.end.x, hole.size.y)), Color.BLACK)

func _update_stats() -> void:
	stats.text = "%s   LV %d       PV        %d / %d" % [GameState.player_name, GameState.lv, GameState.hp, GameState.max_hp()]
	var w = GameState.max_hp() * 1.2
	hp_bar_bg.size = Vector2(w, 20)
	hp_bar.size = Vector2(w * GameState.hp / float(GameState.max_hp()), 20)

# ---------------------------------------------------------------- Boucle principale
func _run() -> void:
	await get_tree().process_frame
	var intro: String = enemy.get("intro", "* %s apparaît." % enemy.get("name", "?"))
	if enemy.get("special", "") == "entity":
		intro = "* ..."
	await _show_text(intro, true)
	while true:
		var r = await _player_turn()
		if not r.is_empty():
			_end(r)
			return
		await _enemy_talk()
		await _dodge()
		if GameState.hp <= 0:
			_end({"outcome": "dead"})
			return
		turn += 1

func _end(r: Dictionary) -> void:
	_set_box(_degraded_box(BOX_WIDE))
	heart.visible = false
	for l in r.get("lines", []):
		await _show_text(str(l), true)
	AudioManager.stop_music()
	r["enemy"] = enemy.get("id", "")
	finished.emit(r)

func _show_text(t: String, wait := false) -> void:
	text.text = TextFx.process(t, fidelity, palier)
	text.visible_characters = 0
	var shown = 0.0
	while text.visible_characters < text.text.length() and text.visible_characters != -1:
		await get_tree().process_frame
		shown += get_process_delta_time() * 40.0
		text.visible_characters = int(shown)
		if int(shown) % 3 == 0:
			AudioManager.voice("none")
		if Input.is_action_just_pressed("cancel"):
			break
	text.visible_characters = -1
	if wait:
		await _wait_confirm()

func _wait_confirm() -> void:
	_input_mode = "wait"
	_accept_after = Time.get_ticks_msec() + 150
	await _picked
	_input_mode = ""

func _say_lines(lines: Array) -> void:
	for l in lines:
		await _show_text(str(l), true)

func _flavor() -> String:
	if mercy >= 100:
		return enemy.get("spare_flavor", "* %s ne veut plus se battre." % enemy.get("name", "?"))
	var fl: Array = enemy.get("flavor", ["* %s te regarde." % enemy.get("name", "?")])
	if palier >= 5 and enemy.has("flavor_low"):
		fl = enemy["flavor_low"]
	return fl[turn % fl.size()]

# ---------------------------------------------------------------- Tour du joueur
func _player_turn() -> Dictionary:
	_set_box(_degraded_box(BOX_WIDE))
	_show_text(_flavor())
	while true:
		var b = await _pick_button()
		match b:
			0:
				if enemy.get("special", "") == "entity":
					return await _entity_flee()
				var r = await _fight()
				if r is Dictionary and not r.is_empty():
					return r
				return {}
			1:
				var r = await _act_menu()
				if r is Dictionary:
					return r
				if r == true:
					return {}
			2:
				var r = await _item_menu()
				if r == true:
					return {}
			3:
				var r = await _mercy_menu()
				if r is Dictionary:
					return r
				if r == true:
					return {}
		_show_text(_flavor())
	return {}

func _pick_button() -> int:
	_input_mode = "menu"
	_accept_after = Time.get_ticks_msec() + 120
	heart.visible = true
	_update_buttons()
	var i: int = await _picked
	_input_mode = ""
	return i

func _update_buttons() -> void:
	for i in 4:
		var col = Color(1, 1, 0.2) if i == _menu_idx else Color(1, 0.55, 0.1)
		buttons[i].add_theme_stylebox_override("panel", UI.frame_style(3, Color.BLACK, col))
		buttons[i].get_child(0).add_theme_color_override("font_color", col)
	heart.position = buttons[_menu_idx].position + Vector2(8, 13)

func _pick_list(items: Array) -> int:
	text.text = ""
	for l in _list_labels:
		l.queue_free()
	_list_labels.clear()
	_list = items
	_list_idx = 0
	for i in items.size():
		var l = UI.label("* " + str(items[i]), 22)
		l.position = Vector2(56 + (i % 2) * 260, 16 + (i / 2) * 32)
		box.add_child(l)
		_list_labels.append(l)
	_input_mode = "list"
	_accept_after = Time.get_ticks_msec() + 120
	_update_list_heart()
	var i: int = await _picked
	_input_mode = ""
	for l in _list_labels:
		l.queue_free()
	_list_labels.clear()
	return i

func _update_list_heart() -> void:
	if _list_labels.is_empty():
		return
	var l: Label = _list_labels[_list_idx]
	heart.position = box.position + l.position + Vector2(-30, 6)

func _input(event: InputEvent) -> void:
	if _input_mode == "" or not (event is InputEventKey) or not event.pressed:
		return
	if Time.get_ticks_msec() < _accept_after:
		return
	match _input_mode:
		"wait":
			if event.is_action_pressed("confirm"):
				_picked.emit(0)
		"menu":
			var n = 1 if enemy.get("special", "") == "entity" else 4
			if event.is_action_pressed("move_right"):
				_menu_idx = (_menu_idx + 1) % n
				AudioManager.sfx("select")
				_update_buttons()
			elif event.is_action_pressed("move_left"):
				_menu_idx = (_menu_idx - 1 + n) % n
				AudioManager.sfx("select")
				_update_buttons()
			elif event.is_action_pressed("confirm"):
				AudioManager.sfx("confirm")
				_picked.emit(_menu_idx)
		"list":
			var n = _list.size()
			if event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
				_list_idx = (_list_idx + (1 if event.is_action_pressed("move_right") else 2)) % n
				AudioManager.sfx("select")
				_update_list_heart()
			elif event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
				_list_idx = (_list_idx - (1 if event.is_action_pressed("move_left") else 2) + n * 2) % n
				AudioManager.sfx("select")
				_update_list_heart()
			elif event.is_action_pressed("confirm"):
				AudioManager.sfx("confirm")
				_picked.emit(_list_idx)
			elif event.is_action_pressed("cancel"):
				_picked.emit(-1)
		"bar":
			if event.is_action_pressed("confirm"):
				_input_mode = ""
				_picked.emit(int(_bar_x))
	get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- FIGHT
func _fight() -> Variant:
	last_player_action = "FIGHT"
	waits_in_row = 0
	if enemy.get("special", "") == "wait_only":
		await _show_text(enemy.get("fight_text", "* Tu lèves la main. Tu n'oses pas."), true)
		return {}
	heart.visible = false
	text.text = ""
	var target = ColorRect.new()
	target.color = Color(0.1, 0.1, 0.1)
	target.position = Vector2(40, 20)
	target.size = Vector2(box.size.x - 80, 100)
	box.add_child(target)
	for i in 5:
		var line = ColorRect.new()
		line.color = Color(0.3, 0.8, 0.3) if i == 2 else Color(0.5, 0.5, 0.5)
		line.size = Vector2(4 if i == 2 else 2, 100)
		line.position = Vector2(target.size.x * (i + 1) / 6.0, 0)
		target.add_child(line)
	_bar_node = ColorRect.new()
	_bar_node.color = Color.WHITE
	_bar_node.size = Vector2(8, 110)
	_bar_node.position = Vector2(40, 15)
	box.add_child(_bar_node)
	_bar_x = 0.0
	_input_mode = "bar"
	_accept_after = Time.get_ticks_msec() + 100
	var stop: int = await _picked
	var center = (box.size.x - 80) / 2.0
	target.queue_free()
	var bn = _bar_node
	_bar_node = null
	if stop < 0:
		bn.queue_free()
		await _show_text("* RATÉ", true)
		return {}
	await get_tree().create_timer(0.2).timeout
	bn.queue_free()
	var acc = 1.0 - clampf(abs(stop - center) / center, 0.0, 1.0)
	var dmg = int(round((GameState.atk() - int(enemy.get("def", 0)) + _rng.randi_range(0, 2)) * (0.3 + acc * 1.9)))
	dmg = max(1, dmg)
	if enemy.get("special", "") == "copy":
		pending_copy_action = "FIGHT"
	AudioManager.sfx("slash")
	await get_tree().create_timer(0.25).timeout
	AudioManager.sfx("hit")
	hp -= dmg
	_shake_enemy()
	_show_damage(dmg)
	await get_tree().create_timer(0.9).timeout
	if hp <= 0:
		return _kill()
	if enemy.has("hurt_text"):
		await _show_text(enemy["hurt_text"][turn % enemy["hurt_text"].size()], true)
	return {}

func _shake_enemy() -> void:
	var base = enemy_sprite.position
	var tw = create_tween()
	for i in 6:
		tw.tween_property(enemy_sprite, "position", base + Vector2(8 if i % 2 == 0 else -8, 0), 0.04)
	tw.tween_property(enemy_sprite, "position", base, 0.04)

func _show_damage(dmg: int) -> void:
	var l = UI.label(str(dmg), 28, Color(1, 0.2, 0.2))
	l.position = Vector2(300, enemy_sprite.position.y - 10)
	add_child(l)
	var barbg = ColorRect.new()
	barbg.color = Color(0.3, 0.3, 0.3)
	barbg.position = Vector2(220, enemy_sprite.position.y + 20)
	barbg.size = Vector2(200, 14)
	add_child(barbg)
	var bar = ColorRect.new()
	bar.color = Color(0.2, 0.9, 0.2)
	bar.position = barbg.position
	bar.size = Vector2(200 * max(0, hp) / float(max_hp), 14)
	add_child(bar)
	var tw = create_tween()
	tw.tween_property(l, "position:y", l.position.y - 20, 0.3)
	tw.tween_interval(0.5)
	tw.tween_callback(l.queue_free)
	tw.tween_callback(barbg.queue_free)
	tw.tween_callback(bar.queue_free)

func _kill() -> Dictionary:
	var id: String = enemy.get("id", "")
	GameState.kills.append(id)
	var xp = int(enemy.get("exp", 5))
	var gold = int(enemy.get("gold", 3))
	GameState.gold += gold
	var tw = create_tween()
	tw.tween_property(enemy_sprite, "modulate:a", 0.0, 0.8)
	var lines: Array = enemy.get("kill_text", [])
	var up = GameState.add_exp(xp)
	lines = lines.duplicate()
	lines.append("* VICTOIRE. Tu gagnes %d EXP et %d tickets." % [xp, gold])
	if up:
		AudioManager.sfx("levelup")
		lines.append("* Ton LV a augmenté.")
	return {"outcome": "won", "lines": lines}

# ---------------------------------------------------------------- ACT
func _act_menu() -> Variant:
	var acts: Array = [{"label": "Vérifier", "check": true}]
	for a in enemy.get("acts", []):
		if a.has("if") and not GameState.check(a["if"]):
			continue
		acts.append(a)
	var names: Array = acts.map(func(a): return a["label"])
	var i = await _pick_list(names)
	if i < 0:
		return false
	var a: Dictionary = acts[i]
	last_player_action = "ACT"
	heart.visible = false
	if a.get("check", false):
		var c: String = enemy.get("check", "* %s - ATT %d DÉF %d" % [enemy.get("name", "?").to_upper(), enemy.get("atk", 1), enemy.get("def", 0)])
		await _show_text(c, true)
		return true
	if a.get("remember", false):
		return await _remember(a)
	if a.get("wait", false):
		waits_in_row += 1
		if enemy.get("special", "") == "copy":
			pending_copy_action = "WAIT"
	else:
		waits_in_row = 0
	if a.has("question"):
		var q: Dictionary = a["question"][turn % a["question"].size()]
		await _show_text(q["text"], true)
		var k = await _pick_list(q["choices"])
		heart.visible = false
		if k == int(q.get("answer", -1)) or q.get("any", false):
			mercy += int(a.get("mercy", 25))
			await _say_lines(q.get("reply_right", ["* Il hoche la tête, très lentement."]))
		else:
			await _say_lines(q.get("reply_wrong", ["* Il ne répond pas."]))
		return true
	var lines: Array = a.get("text", ["* Tu fais quelque chose."])
	if palier >= 5 and a.has("text_low"):
		lines = a["text_low"]
	mercy += int(a.get("mercy", 0))
	if a.has("set"):
		for k in a["set"]:
			GameState.set_flag(k, a["set"][k])
	await _say_lines(lines)
	if enemy.get("special", "") == "copy" and waits_in_row >= 3:
		mercy = 100
		await _show_text("* La Copie ne fait rien, elle non plus.\n* Vous ne faites rien ensemble.", true)
	return true

## ACT « Se souvenir » : retrouver ce que l'ennemi était (métier, objet, nom).
func _remember(a: Dictionary) -> Variant:
	if name_restored:
		await _show_text("* Tu t'en souviens déjà : %s." % a.get("name", "?"), true)
		return true
	await _show_text(a.get("prompt", "* Qu'est-ce que c'était, avant ?"), true)
	var choices: Array = a.get("choices", [])
	var k = await _pick_list(choices)
	heart.visible = false
	if k < 0:
		return false
	if k == int(a.get("answer", 0)):
		name_restored = true
		mercy += int(a.get("mercy", 60))
		AudioManager.sfx("souvenir")
		await _say_lines(a.get("text_right", ["* C'est ça. Il s'en souvient aussi."]))
	else:
		await _say_lines(a.get("text_wrong", ["* Ce n'est pas ça. Il a l'air un peu plus perdu."]))
	return true

# ---------------------------------------------------------------- ITEM
func _item_menu() -> Variant:
	if GameState.inventory.is_empty():
		return false
	var names: Array = GameState.inventory.map(func(id): return GameState.item_name(id))
	var i = await _pick_list(names)
	if i < 0:
		return false
	heart.visible = false
	last_player_action = "ITEM"
	waits_in_row = 0
	var msg = GameState.use_item(i)
	AudioManager.sfx("heal")
	if enemy.get("special", "") == "copy":
		pending_copy_action = "ITEM"
	await _show_text(msg, true)
	return true

# ---------------------------------------------------------------- MERCY
func _mercy_menu() -> Variant:
	var spare_label = "Épargner"
	var items: Array = [spare_label]
	var can_flee: bool = enemy.get("flee", not enemy.get("boss", false))
	if can_flee:
		items.append("Fuir")
	var i = await _pick_list(items)
	if i < 0:
		return false
	heart.visible = false
	last_player_action = "MERCY"
	if i == 0:
		if mercy >= 100:
			var id: String = enemy.get("id", "")
			GameState.spared.append(id)
			if name_restored and not GameState.named.has(id):
				GameState.named.append(id)
			AudioManager.sfx("spare")
			var tw = create_tween()
			tw.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 0.3), 0.6)
			var lines: Array = enemy.get("spare_text", []).duplicate()
			lines.append("* VICTOIRE. Tu gagnes 0 EXP et %d tickets." % int(enemy.get("spare_gold", 0)))
			GameState.gold += int(enemy.get("spare_gold", 0))
			if name_restored:
				lines.insert(0, "* Il se souvient de son nom : %s." % _remember_name())
			return {"outcome": "spared", "lines": lines}
		await _show_text("* %s ne veut pas encore partir." % enemy.get("name", "?"), true)
		return true
	AudioManager.sfx("flee")
	if _rng.randf() < 0.6 + turn * 0.1:
		return {"outcome": "fled", "lines": ["* Tu t'enfuis en courant."]}
	await _show_text("* Tu n'arrives pas à fuir.", true)
	return true

func _remember_name() -> String:
	for a in enemy.get("acts", []):
		if a.get("remember", false):
			return a.get("name", "?")
	return "?"

# ---------------------------------------------------------------- L'Entité
## On ne la combat jamais : le seul choix est « … », et il faut fuir à temps.
func _entity_flee() -> Dictionary:
	heart.visible = false
	text.text = ""
	var target = ColorRect.new()
	target.color = Color(0.1, 0.1, 0.1)
	target.position = Vector2(40, 20)
	target.size = Vector2(box.size.x - 80, 100)
	box.add_child(target)
	var zone = ColorRect.new()
	zone.color = Color(0.25, 0.25, 0.3)
	var zw = max(40.0, 140.0 - turn * 20.0)
	zone.size = Vector2(zw, 100)
	zone.position = Vector2(_rng.randf_range(60, target.size.x - zw - 20), 0)
	target.add_child(zone)
	_bar_node = ColorRect.new()
	_bar_node.color = Color.WHITE
	_bar_node.size = Vector2(8, 110)
	_bar_node.position = Vector2(40, 15)
	box.add_child(_bar_node)
	_bar_x = 0.0
	_input_mode = "bar"
	_accept_after = Time.get_ticks_msec() + 100
	var stop: int = await _picked
	target.queue_free()
	if _bar_node:
		_bar_node.queue_free()
		_bar_node = null
	if stop >= zone.position.x and stop <= zone.position.x + zw:
		AudioManager.sfx("flee")
		return {"outcome": "fled", "lines": ["* Tu cours. Tu ne te retournes pas."]}
	await _show_text("* Trop tard. Elle est plus près.", true)
	return {}

# ---------------------------------------------------------------- Tour ennemi
func _enemy_talk() -> void:
	var lines: Array = enemy.get("dialogue", [])
	if palier >= 5 and enemy.has("dialogue_low"):
		lines = enemy["dialogue_low"]
	var special: String = enemy.get("special", "")
	var line = ""
	if special == "copy" and turn > 0:
		var act = pending_copy_action if pending_copy_action != "" else "WAIT"
		line = {"FIGHT": "(La Copie lève la main, comme toi tout à l'heure.)", "ITEM": "(La Copie mange quelque chose qui n'existe pas.)", "WAIT": "(La Copie attend. Comme toi.)"}.get(act, "...")
		if act == "FIGHT":
			GameState.damage(max(1, GameState.atk() / 4))
			AudioManager.sfx("hurt")
		elif act == "ITEM":
			hp = min(max_hp, hp + 10)
		pending_copy_action = ""
	elif special == "receptionist":
		line = "Bienvenue ! Avez-vous rendez-vous ?" if turn % 2 == 0 else (lines[turn % lines.size()] if not lines.is_empty() else "...")
	elif not lines.is_empty():
		line = lines[turn % lines.size()]
	if line == "":
		return
	bubble.position = Vector2(min(enemy_sprite.position.x + enemy_sprite.size.x + 10, 450), max(10, enemy_sprite.position.y))
	bubble.size = Vector2(180, 80)
	bubble_label.text = TextFx.process(line, fidelity, palier)
	bubble.visible = true
	_accept_after = Time.get_ticks_msec() + 150
	_input_mode = "wait"
	var t = get_tree().create_timer(2.6)
	t.timeout.connect(func():
		if _input_mode == "wait" and bubble.visible:
			_picked.emit(0))
	await _picked
	_input_mode = ""
	bubble.visible = false

func _dodge() -> void:
	heart.visible = false
	text.text = ""
	var w = float(enemy.get("box_w", 170))
	var h = float(enemy.get("box_h", 140))
	var r = _degraded_box(Rect2(320 - w / 2.0, 250, w, h))
	_set_box(r)
	await get_tree().create_timer(0.25).timeout
	soul = Soul.new()
	var mode: String = enemy.get("soul_mode", ZONE_SOUL.get(int(World.current_room.source.zone) if World.current_room else 0, "normal"))
	soul.mode = mode
	soul.box = r
	soul.position = r.get_center()
	arena.add_child(soul)
	var plist: Array = enemy.get("patterns", ["rain"])
	var pid: String = plist[turn % plist.size()]
	var script_path = "res://scenes/battle/bullets/%s.gd" % pid
	pattern = load(script_path).new() if ResourceLoader.exists(script_path) else load("res://scenes/battle/bullets/rain.gd").new()
	pattern.box = r
	pattern.soul = soul
	pattern.enemy = enemy
	pattern.turn = turn
	pattern.damage = int(enemy.get("atk", 3))
	pattern.duration = float(enemy.get("turn_time", 6.0))
	arena.add_child(pattern)
	box_dark.visible = enemy.get("special", "") == "lights_out" and turn % 2 == 1
	var err = clampf(turn * 0.12 + (100.0 - fidelity) / 220.0, 0.0, 0.9)
	pattern.play(err)
	await pattern.done
	box_dark.visible = false
	pattern.cleanup()
	pattern.queue_free()
	pattern = null
	soul.queue_free()
	soul = null

func _hurt(dmg: int) -> void:
	var real = max(1, dmg - int((GameState.def() - 10) / 2))
	GameState.damage(real)
	soul.invuln = 1.0
	AudioManager.sfx("hurt")
	if GameState.hp <= 0 and pattern:
		pattern.duration = 0.0
