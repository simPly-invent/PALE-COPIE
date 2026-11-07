## Écran de fin de partie.
extends Control

signal finished

func _ready() -> void:
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	var t = UI.label("ÉCRAN NOIR", 40, Color(0.9, 0.9, 0.85))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 120)
	t.size = Vector2(640, 60)
	add_child(t)
	World.fade(false, 0.3)
	_run()

func _run() -> void:
	AudioManager.sfx("hurt")
	await get_tree().create_timer(1.2).timeout
	await DialogueManager.say(["* Ne t'endors pas maintenant...", "* %s ! Reste éveillé." % GameState.player_name], "", "mom")
	finished.emit()
