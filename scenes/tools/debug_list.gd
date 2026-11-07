## Petite liste de sélection pour les outils de debug (F5, F6).
extends Control

var title = ""
var items: Array = []
var cb: Callable
var idx = 0
var depth = 0
var label: Label

func setup(t: String, it: Array, c: Callable) -> void:
	title = t
	items = it.duplicate()
	items.sort()
	cb = c

func _ready() -> void:
	GameState.lock("debug")
	var p = UI.panel(Rect2(120, 20, 400, 440), 2)
	add_child(p)
	label = UI.label("", 14)
	label.position = Vector2(12, 8)
	label.size = Vector2(376, 420)
	p.add_child(label)
	_refresh()

func _refresh() -> void:
	var lines = PackedStringArray([title + ("   profondeur : %d" % depth), ""])
	var start = clampi(idx - 10, 0, max(0, items.size() - 22))
	for i in range(start, min(items.size(), start + 22)):
		lines.append(("> " if i == idx else "  ") + str(items[i]))
	label.text = "\n".join(lines)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("move_down"):
		idx = (idx + 1) % items.size()
	elif event.is_action_pressed("move_up"):
		idx = (idx - 1 + items.size()) % items.size()
	elif event.is_action_pressed("move_right"):
		depth += 1
	elif event.is_action_pressed("move_left"):
		depth = max(0, depth - 1)
	elif event.is_action_pressed("confirm"):
		GameState.unlock("debug")
		queue_free()
		cb.call(items[idx], depth)
		return
	elif event.is_action_pressed("cancel") or event.keycode == KEY_ESCAPE:
		GameState.unlock("debug")
		queue_free()
		return
	_refresh()
