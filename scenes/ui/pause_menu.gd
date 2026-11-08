## Petit menu pause, quand on n'a pas encore le caméscope (début du prologue, « Le souvenir »).
extends Control

signal closed

var menu: ListMenu

func _ready() -> void:
	GameState.lock("pause")
	size = Vector2(640, 480)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = size
	add_child(dim)
	var t = UI.label("PAUSE", 26)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 110)
	t.size = Vector2(640, 30)
	add_child(t)
	menu = ListMenu.create(self, Rect2(160, 160, 320, 150), ["Reprendre", "Options", "Retour à l'écran-titre", "Quitter le jeu"], 20)
	_loop()

func _close() -> void:
	GameState.unlock("pause")
	closed.emit()
	queue_free()

func _loop() -> void:
	while true:
		var i: int = await menu.done
		match i:
			1:
				var o = preload("res://scenes/ui/options_menu.gd").new()
				add_child(o)
				menu.set_process_input(false)
				await o.closed
				menu.set_process_input(true)
			2, 3:
				menu.set_process_input(false)
				var quit: bool = false
				if i == 2:
					quit = await _confirm_title()
				else:
					var c: int = await DialogueManager.choose("* Quitter le jeu ? Ce qui n'a pas été sauvegardé sera perdu.", ["Non", "Oui"])
					if c == 1:
						SaveManager.write_meta()
						get_tree().quit()
						return
				menu.set_process_input(true)
				if quit:
					GameState.unlock("pause")
					closed.emit()
					queue_free()
					return
			_:
				_close()
				return
		menu._accept_after = Time.get_ticks_msec() + 150

func _confirm_title() -> bool:
	var c: int = await DialogueManager.choose("* Revenir à l'écran-titre ? Ce qui n'a pas été sauvegardé sera perdu.", ["Non", "Oui"])
	if c != 1:
		return false
	await World.fade(true, 0.6)
	GameState.clear_locks()
	DialogueManager.box.hide_box()
	DialogueManager.active = false
	World.main.show_title()
	await World.fade(false, 0.6)
	return true
