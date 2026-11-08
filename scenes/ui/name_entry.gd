## Saisie du nom de l'enfant, comme dans Undertale.
extends Control

signal named(name: String)

var title_text = "Nomme l'enfant tombé."
var return_mode = false     # true : renvoie le nom au lieu de lancer une partie
var allow_skip = false

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var cols = 7
var idx = 0
var name_text = ""
var name_label: Label
var cells: Array = []
var heart: TextureRect
var options = ["Effacer", "Terminé", "Ne rien dire"]
var busy = false

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
	if not allow_skip:
		options = ["Effacer", "Terminé"]
	for j in options.size():
		var l = UI.label(options[j], 22)
		l.position = Vector2(110 + j * 170, 380)
		add_child(l)
		cells.append(l)
	_refresh()

func _refresh() -> void:
	name_label.text = name_text + "_"
	for i in cells.size():
		cells[i].add_theme_color_override("font_color", Color.YELLOW if i == idx else Color.WHITE)

func _input(event: InputEvent) -> void:
	if busy or not (event is InputEventKey) or not event.pressed:
		return
	var n = LETTERS.length()
	if event.is_action_pressed("move_right"):
		idx = (idx + 1) % cells.size()
	elif event.is_action_pressed("move_left"):
		idx = (idx - 1 + cells.size()) % cells.size()
	elif event.is_action_pressed("move_down"):
		idx = n if idx + cols >= n and idx < n else min(cells.size() - 1, idx + cols)
	elif event.is_action_pressed("move_up"):
		idx = max(0, idx - cols) if idx < n else n - 3
	elif event.is_action_pressed("cancel"):
		name_text = name_text.left(name_text.length() - 1)
	elif event.is_action_pressed("confirm"):
		if idx < n:
			if name_text.length() < 8:
				name_text += LETTERS[idx]
		elif idx == n:
			name_text = name_text.left(name_text.length() - 1)
		elif idx == n + 2:
			if allow_skip:
				get_viewport().set_input_as_handled()
				busy = true
				named.emit("")
				queue_free()
			return
		elif name_text.length() > 0:
			get_viewport().set_input_as_handled()
			_confirm()
			return
	else:
		return
	AudioManager.sfx("select")
	get_viewport().set_input_as_handled()
	_refresh()

func _confirm() -> void:
	busy = true
	var d = JsonUtil.load_json("res://data/title.json")
	var special: Dictionary = d.get("names", {}) if d is Dictionary else {}
	var reply: String = special.get(name_text, "")
	if reply.begins_with("!"):
		await DialogueManager.say([reply.substr(1)])
		busy = false
		return
	var lines: Array = []
	if reply != "":
		lines.append(reply)
	var i: int = await DialogueManager.choose(("%s\n" % reply if reply != "" else "") + "Est-ce bien ton nom ? « %s »" % name_text, ["Non", "Oui"])
	if i == 1 and return_mode:
		named.emit(name_text.capitalize())
		queue_free()
	elif i == 1:
		await World.fade(true, 1.2)
		World.main.start_new_game(name_text)
	else:
		busy = false
