## Boîte de dialogue façon Undertale : cadre blanc, portrait, effet machine à écrire, voix.
extends Control

signal advanced
signal chosen(index: int)

var frame: Panel
var portrait: TextureRect
var text_label: Label
var choice_box: VBoxContainer
var heart: TextureRect
var _full = ""
var _shown = 0.0
var _speed = 30.0
var _voice = "default"
var _typing = false
var _waiting = false
var _choices: Array = []
var _choice_idx = 0
var _accept_after = 0
var _blip_count = 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame = UI.panel(Rect2(30, 316, 580, 148), 4)
	add_child(frame)
	portrait = TextureRect.new()
	portrait.position = Vector2(16, 30)
	portrait.size = Vector2(88, 88)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(portrait)
	text_label = UI.label("", 22)
	text_label.position = Vector2(24, 14)
	text_label.size = Vector2(530, 120)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(text_label)
	choice_box = VBoxContainer.new()
	choice_box.position = Vector2(330, 20)
	choice_box.add_theme_constant_override("separation", 4)
	frame.add_child(choice_box)
	heart = UI.sprite_rect("soul_red", 0.55)
	heart.visible = false
	frame.add_child(heart)
	visible = false

func place_top(top: bool) -> void:
	frame.position.y = 16 if top else 316

func show_line(text: String, portrait_name := "", voice := "default", speed := 1.0) -> void:
	visible = true
	_choices = []
	choice_box.visible = false
	heart.visible = false
	for c in choice_box.get_children():
		c.queue_free()
	if portrait_name != "":
		portrait.texture = Assets.tex("portraits/" + portrait_name)
		portrait.visible = true
		text_label.position.x = 120
		text_label.size.x = 440
	else:
		portrait.visible = false
		text_label.position.x = 24
		text_label.size.x = 530
	_full = text
	text_label.text = text
	text_label.visible_characters = 0
	_shown = 0.0
	_speed = 32.0 * speed
	_voice = voice
	_typing = true
	_waiting = true
	_blip_count = 0
	_accept_after = Time.get_ticks_msec() + 120
	await advanced

func show_choices(prompt: String, options: Array, portrait_name := "", voice := "default") -> int:
	visible = true
	show_line_no_wait(prompt, portrait_name, voice)
	while _typing:
		await get_tree().process_frame
	for c in choice_box.get_children():
		c.free()
	_choices = options
	_choice_idx = 0
	var x0: float = text_label.position.x + 34
	var prompt_lines = ceili(prompt.length() / 40.0)
	if prompt == "" or options.size() + prompt_lines > 4:
		text_label.text = ""
		choice_box.position = Vector2(x0, 14)
	else:
		choice_box.position = Vector2(x0, 14 + prompt_lines * 27)
	for o in options:
		choice_box.add_child(UI.label(str(o), 22))
	choice_box.visible = true
	heart.visible = true
	_waiting = true
	_accept_after = Time.get_ticks_msec() + 150
	await get_tree().process_frame
	_update_heart()
	var idx: int = await chosen
	heart.visible = false
	choice_box.visible = false
	_choices = []
	return idx

func show_line_no_wait(text: String, portrait_name := "", voice := "default") -> void:
	if portrait_name != "":
		portrait.texture = Assets.tex("portraits/" + portrait_name)
		portrait.visible = true
		text_label.position.x = 120
		text_label.size.x = 440
	else:
		portrait.visible = false
		text_label.position.x = 24
		text_label.size.x = 530
	_full = text
	text_label.text = text
	text_label.visible_characters = 0
	_shown = 0.0
	_speed = 32.0
	_voice = voice
	_typing = true

func _update_heart() -> void:
	if _choices.is_empty() or choice_box.get_child_count() == 0:
		return
	var l: Control = choice_box.get_child(_choice_idx)
	heart.position = choice_box.position + l.position + Vector2(-26, 6)

func _process(delta: float) -> void:
	if not _typing:
		return
	var before = int(_shown)
	_shown += _speed * delta
	# petite pause sur la ponctuation
	var n = mini(int(_shown), _full.length())
	if n > before and n > 0 and ".?!,".contains(_full[n - 1]):
		_shown -= _speed * delta * 0.6
	text_label.visible_characters = n
	for i in range(before, n):
		if i < _full.length() and _full[i] != " " and _full[i] != "*":
			_blip_count += 1
			if _blip_count % 2 == 1:
				AudioManager.voice(_voice)
	if n >= _full.length():
		_typing = false

func hide_box() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if not visible or not _waiting:
		return
	if Time.get_ticks_msec() < _accept_after:
		if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
			get_viewport().set_input_as_handled()
		return
	if not _choices.is_empty() and not _typing:
		if event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
			_choice_idx = (_choice_idx + 1) % _choices.size()
			AudioManager.sfx("select")
			_update_heart()
		elif event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
			_choice_idx = (_choice_idx - 1 + _choices.size()) % _choices.size()
			AudioManager.sfx("select")
			_update_heart()
		elif event.is_action_pressed("confirm"):
			AudioManager.sfx("confirm")
			_waiting = false
			get_viewport().set_input_as_handled()
			chosen.emit(_choice_idx)
			return
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
			text_label.visible_characters = -1
		elif _choices.is_empty():
			_waiting = false
			advanced.emit()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
			text_label.visible_characters = -1
