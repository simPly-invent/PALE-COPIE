## Liste verticale avec curseur-cœur. `await menu.done` renvoie l'index choisi, ou -1 (annuler).
class_name ListMenu
extends Control

signal done(index: int)

var options: Array = []
var idx = 0
var labels: Array = []
var heart: TextureRect
var font_size = 22
var line_h = 30
var cancellable = true
var disabled: Array = []
var icons: Dictionary = {}      # index -> Texture2D affichée à gauche du texte
var _accept_after = 0
var on_move: Callable

static func create(parent: Node, rect: Rect2, opts: Array, size := 22, frame := true) -> ListMenu:
	var m = ListMenu.new()
	m.position = rect.position
	m.size = rect.size
	m.options = opts
	m.font_size = size
	m.line_h = int(size * 1.35)
	if frame:
		var p = UI.panel(Rect2(Vector2.ZERO, rect.size), 3)
		m.add_child(p)
	parent.add_child(m)
	return m

func _ready() -> void:
	_build()

func _build() -> void:
	for l in labels:
		l.queue_free()
	labels.clear()
	for i in options.size():
		var l = UI.label(str(options[i]), font_size, Color(0.5, 0.5, 0.5) if disabled.has(i) else Color.WHITE)
		l.position = Vector2(44, 12 + i * line_h)
		if icons.has(i):
			var ic = TextureRect.new()
			ic.texture = icons[i]
			ic.size = icons[i].get_size()
			ic.position = Vector2(42, 12 + i * line_h + (line_h - ic.size.y) / 2.0 - 2)
			add_child(ic)
			labels.append(ic)
			l.position.x = 44 + ic.size.x + 8
		l.size = Vector2(size.x - 52, line_h)
		l.clip_text = true
		add_child(l)
		labels.append(l)
	if heart == null:
		heart = UI.sprite_rect("soul_red", 0.55)
		add_child(heart)
	_accept_after = Time.get_ticks_msec() + 120
	_update()

func set_options(opts: Array) -> void:
	options = opts
	idx = clampi(idx, 0, max(0, opts.size() - 1))
	_build()

func _update() -> void:
	if options.is_empty():
		heart.visible = false
		return
	heart.visible = true
	heart.position = Vector2(14, 12 + idx * line_h + (line_h - heart.size.y) / 2.0 - 3)
	if on_move.is_valid():
		on_move.call(idx)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey):
		return
	if Time.get_ticks_msec() < _accept_after or (DialogueManager.active and not get_meta("in_dialogue", false)):
		return
	if event.is_action_pressed("move_down") and not options.is_empty():
		idx = (idx + 1) % options.size()
		AudioManager.sfx("select")
		_update()
	elif event.is_action_pressed("move_up") and not options.is_empty():
		idx = (idx - 1 + options.size()) % options.size()
		AudioManager.sfx("select")
		_update()
	elif event.is_action_pressed("confirm") and not options.is_empty():
		if disabled.has(idx):
			return
		AudioManager.sfx("confirm")
		get_viewport().set_input_as_handled()
		done.emit(idx)
		return
	elif (event.is_action_pressed("cancel") or event.is_action_pressed("menu")) and cancellable:
		get_viewport().set_input_as_handled()
		done.emit(-1)
		return
	else:
		return
	get_viewport().set_input_as_handled()
