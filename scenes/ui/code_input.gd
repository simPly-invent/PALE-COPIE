## Saisie d'un code (chiffres ou lettres) : ←/→ pour choisir la case, ↑/↓ pour changer.
## `await input.done` renvoie le code, ou "" si annulé.
class_name CodeInput
extends Control

signal done(code: String)

var length = 3
var charset = "0123456789"
var title = ""
var values: Array = []
var idx = 0
var labels: Array = []
var _accept_after = 0

func _ready() -> void:
	GameState.lock("code")
	values.resize(length)
	values.fill(0)
	var w = 80 + length * 44
	var p = UI.panel(Rect2(320 - w / 2.0, 150, w, 160), 4)
	add_child(p)
	var t = UI.label(title, 18)
	t.position = Vector2(16, 12)
	t.size = Vector2(w - 32, 24)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(t)
	for i in length:
		var l = UI.label("", 34)
		l.position = Vector2(40 + i * 44, 60)
		p.add_child(l)
		labels.append(l)
	var hint = UI.label("↑↓ changer  ←→ case  Z valider  X annuler", 12, Color(0.6, 0.6, 0.6))
	hint.position = Vector2(12, 128)
	hint.size = Vector2(w - 24, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(hint)
	_accept_after = Time.get_ticks_msec() + 150
	_refresh()

func _refresh() -> void:
	for i in length:
		labels[i].text = charset[values[i]]
		labels[i].add_theme_color_override("font_color", Color.YELLOW if i == idx else Color.WHITE)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or Time.get_ticks_msec() < _accept_after:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("move_up"):
		values[idx] = (values[idx] + 1) % charset.length()
	elif event.is_action_pressed("move_down"):
		values[idx] = (values[idx] - 1 + charset.length()) % charset.length()
	elif event.is_action_pressed("move_right"):
		idx = (idx + 1) % length
	elif event.is_action_pressed("move_left"):
		idx = (idx - 1 + length) % length
	elif event.is_action_pressed("confirm"):
		_finish("".join(values.map(func(v): return charset[v])))
		return
	elif event.is_action_pressed("cancel"):
		_finish("")
		return
	else:
		return
	AudioManager.sfx("click")
	_refresh()

func _finish(code: String) -> void:
	GameState.unlock("code")
	done.emit(code)
	queue_free()

static func ask(t: String, len: int, letters := false) -> String:
	var c = CodeInput.new()
	c.title = t
	c.length = len
	c.charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" if letters else "0123456789"
	World.ui_layer.add_child(c)
	return await c.done
