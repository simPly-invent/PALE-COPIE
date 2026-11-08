## Saisie d'un prénom. On peut taper directement au clavier, ou choisir les lettres
## dans la grille (flèches + Espace). Entrée termine. Retour arrière efface.
## La confirmation « Oui / Non » est affichée sur ce même écran.
extends Control

signal named(name: String)

var title_text = "Nomme l'enfant tombé."
var return_mode = false     # true : renvoie le nom au lieu de lancer une partie
var allow_skip = false
var password_mode = false   # texte masqué, Entrée valide directement

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const MAX_LEN := 12
var cols = 7
var idx = 0
var name_text = ""
var name_label: Label
var info: Label
var cells: Array = []
var options: Array = []
var busy = false
var confirming = false
var confirm_idx = 1
var confirm_label: Label
var _accept_after = 0

func _ready() -> void:
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	var t = UI.label(title_text, 24)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 40)
	t.size = Vector2(640, 30)
	add_child(t)
	name_label = UI.label("", 30)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 100)
	name_label.size = Vector2(640, 40)
	add_child(name_label)
	for i in LETTERS.length():
		var l = UI.label(LETTERS[i], 26)
		l.position = Vector2(150 + (i % cols) * 50, 170 + (i / cols) * 44)
		add_child(l)
		cells.append(l)
	options = ["Effacer", "Terminé"]
	if allow_skip:
		options.append("Ne rien dire")
	for j in options.size():
		var l = UI.label(options[j], 22)
		l.position = Vector2(110 + j * 170, 370)
		add_child(l)
		cells.append(l)
	info = UI.label("Tape au clavier, ou flèches + Espace.  Entrée : terminer.  Retour arrière : effacer.", 12, Color(0.55, 0.55, 0.55))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.position = Vector2(0, 440)
	info.size = Vector2(640, 20)
	add_child(info)
	confirm_label = UI.label("", 22, Color.WHITE)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_label.position = Vector2(0, 400)
	confirm_label.size = Vector2(640, 30)
	confirm_label.visible = false
	add_child(confirm_label)
	_accept_after = Time.get_ticks_msec() + 250
	_refresh()

func _refresh() -> void:
	var shown = "*".repeat(name_text.length()) if password_mode else name_text
	name_label.text = shown + ("_" if name_text.length() < MAX_LEN else "")
	for i in cells.size():
		cells[i].add_theme_color_override("font_color", Color.YELLOW if i == idx and not confirming else Color.WHITE)
	if confirming:
		confirm_label.text = "C'est bien « %s » ?     %sNon     %sOui" % [name_text, "> " if confirm_idx == 0 else "  ", "> " if confirm_idx == 1 else "  "]

func _input(event: InputEvent) -> void:
	if busy or not (event is InputEventKey) or not event.pressed or Time.get_ticks_msec() < _accept_after:
		return
	get_viewport().set_input_as_handled()
	if confirming:
		_confirm_input(event)
		return
	var n = LETTERS.length()
	var k: int = event.keycode
	# touches directes
	if k == KEY_ENTER or k == KEY_KP_ENTER:
		_finish()
		return
	if k == KEY_BACKSPACE or k == KEY_DELETE:
		name_text = name_text.left(name_text.length() - 1)
		_click()
		return
	if k == KEY_ESCAPE:
		if allow_skip or password_mode:
			_emit("")
		return
	var ch = String.chr(event.unicode) if event.unicode > 0 else ""
	if ch != "" and (ch.to_upper() != ch.to_lower() or ch == "-" or ch == "'"):
		if name_text.length() < MAX_LEN:
			name_text += ch.to_upper() if name_text.is_empty() else ch.to_lower()
		_click()
		return
	# navigation dans la grille
	if event.is_action_pressed("move_right"):
		idx = (idx + 1) % cells.size()
	elif event.is_action_pressed("move_left"):
		idx = (idx - 1 + cells.size()) % cells.size()
	elif event.is_action_pressed("move_down"):
		idx = n if idx + cols >= n and idx < n else mini(cells.size() - 1, idx + cols)
	elif event.is_action_pressed("move_up"):
		idx = maxi(0, idx - cols) if idx < n else n - 3
	elif event.is_action_pressed("cancel"):
		name_text = name_text.left(name_text.length() - 1)
	elif event.is_action_pressed("confirm"):
		if idx < n:
			if name_text.length() < MAX_LEN:
				name_text += LETTERS[idx] if name_text.is_empty() else LETTERS[idx].to_lower()
		elif idx == n:
			name_text = name_text.left(name_text.length() - 1)
		elif idx == n + 1:
			_finish()
			return
		elif idx == n + 2:
			_emit("")
			return
	else:
		return
	_click()

func _click() -> void:
	AudioManager.sfx("select")
	_refresh()

func _finish() -> void:
	if name_text.strip_edges() == "":
		AudioManager.sfx("wrong")
		return
	if password_mode:
		_emit(name_text.strip_edges())
		return
	var d = JsonUtil.load_json("res://data/title.json")
	var special: Dictionary = d.get("names", {}) if d is Dictionary else {}
	var reply: String = special.get(name_text.to_upper(), "")
	if reply.begins_with("!"):
		info.text = reply.substr(1)
		AudioManager.sfx("wrong")
		return
	if reply != "":
		info.text = reply
	confirming = true
	confirm_idx = 1
	confirm_label.visible = true
	AudioManager.sfx("confirm")
	_refresh()

func _confirm_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		confirm_idx = 1 - confirm_idx
		_click()
	elif event.is_action_pressed("cancel") or event.keycode == KEY_ESCAPE:
		confirming = false
		confirm_label.visible = false
		_click()
	elif event.is_action_pressed("confirm"):
		if confirm_idx == 1:
			_emit(name_text.strip_edges())
		else:
			confirming = false
			confirm_label.visible = false
			_click()

func _emit(value: String) -> void:
	busy = true
	AudioManager.sfx("confirm")
	if return_mode:
		named.emit(value)
		queue_free()
	else:
		await World.fade(true, 1.2)
		World.main.start_new_game(value if value != "" else "Enfant")
