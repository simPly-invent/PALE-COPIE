## Lecteur de cassettes : joue des séquences décrites en JSON (images, texte, durée, sons),
## en vue fixe, avec bande noire, horodatage et grain (section 5.2).
## Format : {"title", "date", "time", "frames": [{"image": "vhs/hallway", "text": "...", "duration": 3,
##           "sound": "static"|"hum"|"entity"|"silence"|"music:id", "tint": "#hex", "shake": true}]}
extends Control

signal finished

var frames: Array = []
var tape_id = ""
var data: Dictionary = {}
var img: TextureRect
var text: Label
var stamp: Label
var rec: Label
var _skip = false
var _next = false
var _prev_override = -1.0

func _ready() -> void:
	GameState.lock("vhs")
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	img = TextureRect.new()
	img.position = Vector2(40, 50)
	img.size = Vector2(560, 330)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(img)
	stamp = UI.label("", 20, Color(0.95, 0.95, 0.95))
	stamp.position = Vector2(56, 330)
	add_child(stamp)
	rec = UI.label("▶ LECTURE", 18)
	rec.position = Vector2(56, 60)
	add_child(rec)
	text = UI.label("", 20)
	text.position = Vector2(40, 392)
	text.size = Vector2(560, 80)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(text)
	_prev_override = FxManager.override_strength
	FxManager.override_strength = 1.0
	FxManager._apply()

func play(id: String) -> void:
	tape_id = id
	play_data(VhsLibrary.load_tape(id))

func play_data(d: Dictionary) -> void:
	data = d
	frames = d.get("frames", [])
	_run()

func _run() -> void:
	await get_tree().process_frame
	AudioManager.sfx("static")
	for f in frames:
		if _skip:
			break
		_show(f)
		var dur = float(f.get("duration", 3.0))
		var t = 0.0
		var full: String = TextFx.process(f.get("text", ""), 100, 0)
		text.text = full
		text.visible_characters = 0
		_next = false
		while t < dur or (f.get("wait", false) and not _next):
			await get_tree().process_frame
			var dt = get_process_delta_time()
			t += dt
			text.visible_characters = int(t * 35.0)
			_update_stamp(t)
			if f.get("shake", false):
				img.position = Vector2(40, 50) + Vector2(randf_range(-2, 2), randf_range(-1, 1))
			if _skip or _next and t > 0.3:
				break
	if tape_id != "" and not GameState.tapes_seen.has(tape_id):
		GameState.tapes_seen.append(tape_id)
	_finish()

func _show(f: Dictionary) -> void:
	var im: String = f.get("image", "")
	img.texture = Assets.tex(im) if im != "" else null
	img.modulate = Color.from_string(f.get("tint", "#ffffff"), Color.WHITE)
	var s: String = f.get("sound", "")
	if s == "static" or s == "entity" or s == "phone_ring" or s == "click":
		AudioManager.sfx(s)
	elif s.begins_with("music:"):
		AudioManager.play_music(s.substr(6), float(f.get("fidelity", 60)))
	elif s == "silence":
		AudioManager.stop_music()

func _update_stamp(t: float) -> void:
	var base: String = data.get("time", "PM 10:24")
	var secs = int(t) % 60
	stamp.text = "%s:%02d\n%s" % [base, secs, data.get("date", "JUL. 14 1997")]
	rec.visible = fmod(t, 1.0) < 0.6

func _finish() -> void:
	FxManager.override_strength = _prev_override
	FxManager._apply()
	GameState.unlock("vhs")
	finished.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		_skip = true
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("confirm"):
		_next = true
		get_viewport().set_input_as_handled()
