## Écran après une fin. Retourne au titre.
extends Control

var ending_id = ""

func _ready() -> void:
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	var d = JsonUtil.load_json("res://data/endings/%s.json" % ending_id)
	var title: String = d.get("name", ending_id) if d is Dictionary else ending_id
	var l = UI.label("FIN : %s" % title.to_upper(), 28)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 180)
	l.size = Vector2(640, 40)
	add_child(l)
	var seen: Array = GameState.meta.get("endings_seen", [])
	var s = UI.label("Fins vues : %d / 4     Temps : %s" % [seen.size(), _fmt(GameState.playtime)], 16, Color(0.6, 0.6, 0.6))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.position = Vector2(0, 240)
	s.size = Vector2(640, 30)
	add_child(s)
	var hint = UI.label("Appuie sur Valider.", 14, Color(0.4, 0.4, 0.4))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 420)
	hint.size = Vector2(640, 20)
	add_child(hint)
	World.fade(false, 1.0)

static func _fmt(t: float) -> String:
	return "%d:%02d" % [int(t / 3600), int(t / 60) % 60]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		World.main.show_title()
