## Options : effets réduits, volume de la musique, plein écran.
extends Control

signal closed

var menu: ListMenu

func _ready() -> void:
	GameState.lock("options")
	menu = ListMenu.create(self, Rect2(120, 120, 400, 200), _labels(), 20)
	_loop()

func _opts() -> Dictionary:
	return GameState.meta["options"]

func _labels() -> Array:
	var o = _opts()
	return [
		"Effets réduits : %s" % ("OUI" if o.get("reduced_fx", false) else "NON"),
		"Musique : %d %%" % int(round(float(o.get("music_volume", 0.8)) * 100)),
		"Plein écran : %s" % ("OUI" if o.get("fullscreen", false) else "NON"),
		"Retour",
	]

func _loop() -> void:
	while true:
		var i: int = await menu.done
		var o = _opts()
		match i:
			0: o["reduced_fx"] = not o.get("reduced_fx", false)
			1:
				var v = float(o.get("music_volume", 0.8)) + 0.2
				o["music_volume"] = 0.0 if v > 1.01 else v
				AudioManager.set_fidelity(AudioManager.fidelity, World.current_zone())
			2:
				o["fullscreen"] = not o.get("fullscreen", false)
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if o["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
			_:
				SaveManager.write_meta()
				FxManager.set_fidelity(FxManager.target_fidelity, true)
				GameState.unlock("options")
				closed.emit()
				queue_free()
				return
		menu.set_options(_labels())
