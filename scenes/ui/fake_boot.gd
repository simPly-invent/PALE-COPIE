## Faux démarrage daté de 1997 : logo d'éditeur, carte mémoire, copyright légèrement faux.
extends Control

var lines: Array = []
var _skip = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	FxManager.set_fidelity(85, true)
	_run()

func _wait(t: float) -> bool:
	var end = Time.get_ticks_msec() + int(t * 1000)
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame
		if _skip:
			return true
	return false

func _clear() -> void:
	for c in get_children():
		if c is Label or c is TextureRect:
			c.queue_free()

func _center(text: String, y: float, size_px := 22, col := Color.WHITE) -> Label:
	var l = UI.label(text, size_px, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(640, 40)
	add_child(l)
	return l

func _run() -> void:
	var d = JsonUtil.load_json("res://data/title.json")
	var boot: Dictionary = d.get("boot", {}) if d is Dictionary else {}
	if await _wait(0.6): return _done()
	AudioManager.sfx("static")
	var logo = _center(boot.get("publisher", "HALDEN INTERACTIVE"), 200, 34, Color(0.85, 0.85, 0.9))
	_center(boot.get("presents", "présente"), 250, 18, Color(0.6, 0.6, 0.6))
	if await _wait(2.6): return _done()
	_clear()
	_center(boot.get("memory_title", "CARTE MÉMOIRE"), 150, 24)
	var status = _center(boot.get("memory_check", "Vérification de la carte mémoire (fente 1)..."), 210, 18)
	if await _wait(1.8): return _done()
	var games = int(GameState.meta.get("games_started", 0))
	if SaveManager.has_save():
		status.text = boot.get("memory_found", "1 bloc utilisé : PÂLE COPIE")
	else:
		status.text = boot.get("memory_empty", "Aucune donnée. (Il y en avait pourtant.)") if games > 0 else boot.get("memory_new", "Aucune donnée.")
	if await _wait(1.6): return _done()
	_clear()
	_center(boot.get("copyright", "© 1997 1996 HALDEN INTERACTIVE"), 210, 18, Color(0.7, 0.7, 0.7))
	_center(boot.get("copyright2", "TOUS DROITS RÉSERVÉS. LICENCE ACCORDÉE PAR PERSONNE."), 240, 14, Color(0.5, 0.5, 0.5))
	if await _wait(2.4): return _done()
	_done()

func _done() -> void:
	if is_queued_for_deletion():
		return
	World.main.show_title()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		_skip = true
		get_viewport().set_input_as_handled()
