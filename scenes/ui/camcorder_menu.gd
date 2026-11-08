## Le caméscope sert de menu : inventaire, statistiques, carte (qui devient fausse),
## lecteur de cassettes, Souvenirs, options.
extends Control

signal closed

const TABS := ["OBJETS", "STATS", "CARTE", "CASSETTES", "SOUVENIRS", "OPTIONS", "QUITTER"]
var tabs: ListMenu
var content: Control
var header: Label

func _ready() -> void:
	GameState.lock("camcorder")
	size = Vector2(640, 480)
	var cam = UI.sprite_rect("icon_camcorder", 1.0)
	cam.position = Vector2(30, 24)
	add_child(cam)
	header = UI.label("● REC  %s   LV %d   PV %d/%d   %d T" % [GameState.player_name, GameState.lv, GameState.hp, GameState.max_hp(), GameState.gold], 16, Color(1, 0.4, 0.4))
	header.position = Vector2(90, 34)
	add_child(header)
	tabs = ListMenu.create(self, Rect2(24, 70, 170, 250), TABS, 18)
	content = Control.new()
	content.position = Vector2(206, 70)
	content.size = Vector2(410, 390)
	add_child(content)
	tabs.on_move = func(i): _preview(i)
	_preview(0)
	_loop()

func _close() -> void:
	GameState.unlock("camcorder")
	closed.emit()
	queue_free()

func _clear_content() -> void:
	for c in content.get_children():
		c.queue_free()

func _text_panel(text: String) -> Label:
	_clear_content()
	content.add_child(UI.panel(Rect2(Vector2.ZERO, content.size), 3))
	var l = UI.label(text, 18)
	l.position = Vector2(16, 12)
	l.size = content.size - Vector2(32, 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)
	return l

func _preview(i: int) -> void:
	match i:
		0: _text_panel(_items_text())
		1: _text_panel(_stats_text())
		2: _show_map()
		3: _text_panel(_tapes_text())
		4: _text_panel(_souvenirs_text())
		5: _text_panel("Effets réduits, volume, plein écran.")
		6: _text_panel("Revenir à l'écran-titre, ou quitter le jeu.\n\nPense à sauvegarder avant : un téléphone, ou une disquette dans un refuge.")

func _items_text() -> String:
	var s = ""
	for id in GameState.inventory:
		s += "* %s\n" % GameState.item_name(id)
	if GameState.inventory.is_empty():
		s += "(rien)\n"
	if not GameState.key_items.is_empty():
		s += "\nObjets clés :\n"
		for id in GameState.key_items:
			var n = GameState.item_name(id)
			if id == "badge":
				n = TextFx.corrupt_label(n.to_upper(), GameState.badge_decay * 0.2, "badge")
			s += "- %s\n" % n
	return s

func _stats_text() -> String:
	var w = GameState.item_def(GameState.weapon)
	var a = GameState.item_def(GameState.armor)
	return "« %s »\n\nLV %d\nPV %d / %d\n\nATT %d (%d)\nDEF %d (%d)\n\nEXP : %d\nArme : %s\nProtection : %s\nTickets : %d\n\nSouvenirs gardés : %d\nCassettes : %d / 20" % [
		GameState.player_name, GameState.lv, GameState.hp, GameState.max_hp(),
		GameState.atk(), int(w.get("atk", 0)), GameState.def(), int(a.get("def", 0)),
		GameState.xp, w.get("name", "?"), a.get("name", "?"), GameState.gold,
		GameState.souvenirs.size(), GameState.tapes_found.size()]

func _tapes_text() -> String:
	if GameState.tapes_found.is_empty():
		return "Aucune cassette.\n\nLe caméscope peut lire les cassettes VHS que tu trouves."
	var s = ""
	for id in GameState.tapes_found:
		s += "%s %s\n" % ["✓" if GameState.tapes_seen.has(id) else "•", VhsLibrary.title(id)]
	return s

func _souvenirs_text() -> String:
	if GameState.souvenirs.is_empty():
		return "Aucun Souvenir.\n\nUn Souvenir rend +20 de fidélité à une salle et à ses copies.\nMais on n'en garde qu'un nombre limité..."
	var s = "Souvenirs gardés : %d\n\n" % GameState.souvenirs.size()
	for id in GameState.souvenirs:
		s += "* %s\n" % GameState.item_name(id)
	return s

func _show_map() -> void:
	_clear_content()
	content.add_child(UI.panel(Rect2(Vector2.ZERO, content.size), 3))
	var m = preload("res://scenes/ui/map_view.gd").new()
	m.position = Vector2(8, 8)
	m.size = content.size - Vector2(16, 16)
	content.add_child(m)

func _loop() -> void:
	while true:
		var i: int = await tabs.done
		if i < 0:
			_close()
			return
		tabs.visible = true
		match i:
			0: await _items_menu()
			3: await _tapes_menu()
			4: await _souvenirs_menu()
			5:
				var o = preload("res://scenes/ui/options_menu.gd").new()
				add_child(o)
				tabs.set_process_input(false)
				await o.closed
				tabs.set_process_input(true)
			6:
				tabs.set_process_input(false)
				var quit: bool = await QuitMenu.ask(self)
				tabs.set_process_input(true)
				if quit:
					GameState.unlock("camcorder")
					closed.emit()
					queue_free()
					return
		_preview(tabs.idx)
		tabs._accept_after = Time.get_ticks_msec() + 150

func _submenu(opts: Array) -> int:
	_clear_content()
	var m = ListMenu.create(content, Rect2(Vector2.ZERO, Vector2(content.size.x, max(80, 24 + opts.size() * 28))), opts, 18)
	tabs.set_process_input(false)
	var i: int = await m.done
	tabs.set_process_input(true)
	m.queue_free()
	return i

func _items_menu() -> void:
	if GameState.inventory.is_empty():
		return
	var names: Array = GameState.inventory.map(func(id): return GameState.item_name(id))
	var i = await _submenu(names)
	if i < 0:
		return
	var id: String = GameState.inventory[i]
	var a = await _submenu(["Utiliser", "Infos", "Jeter"])
	match a:
		0:
			var msg = GameState.use_item(i)
			AudioManager.sfx("heal")
			_close_temporarily()
			await DialogueManager.say([msg])
		1:
			_close_temporarily()
			await DialogueManager.say(["* « %s » - %s" % [GameState.item_name(id), GameState.item_def(id).get("desc", "")]])
		2:
			GameState.inventory.remove_at(i)
			_close_temporarily()
			await DialogueManager.say(["* Tu poses %s par terre. Il disparaît sans bruit." % GameState.item_name(id)])
	visible = true

func _close_temporarily() -> void:
	visible = false

func _tapes_menu() -> void:
	if GameState.tapes_found.is_empty():
		return
	var names: Array = GameState.tapes_found.map(func(id): return VhsLibrary.title(id))
	var i = await _submenu(names)
	if i < 0:
		return
	visible = false
	await World.play_tape(GameState.tapes_found[i])
	visible = true

func _souvenirs_menu() -> void:
	if GameState.souvenirs.is_empty():
		return
	var names: Array = GameState.souvenirs.map(func(id): return GameState.item_name(id))
	var i = await _submenu(names)
	if i < 0:
		return
	var id: String = GameState.souvenirs[i]
	var a = await _submenu(["Se souvenir (utiliser ici)", "Regarder", "Garder"])
	if a == 1:
		visible = false
		await DialogueManager.say(["* " + GameState.item_def(id).get("desc", "")])
		visible = true
	elif a == 0:
		visible = false
		var r: Room = World.current_room
		var yes: int = await DialogueManager.choose("* Utiliser « %s » ici ? Tu ne pourras plus le garder." % GameState.item_name(id), ["Non", "Oui"])
		if yes == 1 and r:
			GameState.souvenirs.remove_at(i)
			GameState.souvenirs_used.append({"id": id, "room": DegradationManager.key(r.source.id, r.depth)})
			AudioManager.sfx("souvenir")
			await DialogueManager.say(["* " + GameState.item_def(id).get("memory", "Tu te souviens."), "* La pièce se souvient un peu mieux d'elle-même."])
			World.restore_current(DegradationManager.SOUVENIR_BONUS)
			GameState.unlock("camcorder")
			closed.emit()
			queue_free()
			await World.rebuild_current()
			return
		visible = true
