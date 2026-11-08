## Écran-titre : logo, menu, sous-titre qui change à chaque lancement, mot de passe secret.
extends Control

var menu: ListMenu
var data: Dictionary = {}
var typed = ""
var busy = false

func _ready() -> void:
	size = Vector2(640, 480)
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.size = size
	add_child(bg)
	var d = JsonUtil.load_json("res://data/title.json")
	data = d if d is Dictionary else {}
	var logo = TextureRect.new()
	logo.texture = Assets.tex("title_logo")
	logo.position = Vector2((640 - logo.texture.get_width()) / 2.0, 50)
	add_child(logo)
	var subs: Array = data.get("subtitles", ["Un jeu de 1997."])
	var boots = int(GameState.meta.get("boots", 1))
	var sub = UI.label(subs[(boots - 1) % subs.size()], 16, Color(0.7, 0.7, 0.6))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 245)
	sub.size = Vector2(640, 24)
	add_child(sub)
	var opts: Array = []
	if SaveManager.has_save():
		opts.append("Continuer")
	opts.append_array(["Nouvelle partie", "Options", "Quitter"])
	menu = ListMenu.create(self, Rect2(200, 290, 240, 24 + opts.size() * 30), opts, 22)
	menu.cancellable = false
	if SaveManager.has_save():
		var s = SaveManager.summary()
		var info = UI.label("%s   LV %d   %s" % [s["name"], s["lv"], s["room"]], 14, Color(0.6, 0.6, 0.6))
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.position = Vector2(0, 430)
		info.size = Vector2(640, 20)
		add_child(info)
	var foot = UI.label(data.get("footer", "© 1997 HALDEN INTERACTIVE"), 12, Color(0.4, 0.4, 0.4))
	foot.position = Vector2(8, 458)
	add_child(foot)
	FxManager.set_fidelity(90, true)
	AudioManager.play_music("lullaby", 90)
	_loop()

func _loop() -> void:
	while true:
		var i: int = await menu.done
		if busy or not is_inside_tree():
			return
		var choice: String = menu.options[i]
		match choice:
			"Continuer":
				busy = true
				World.main.continue_game()
				return
			"Nouvelle partie":
				menu.visible = false
				var c: int = await DialogueManager.choose("* Par où commencer ?", ["Le souvenir", "L'aventure", "Retour"])
				if c == 2 or c < 0:
					menu.visible = true
					menu._accept_after = Time.get_ticks_msec() + 150
					continue
				busy = true
				await World.fade(true, 1.2)
				if c == 0:
					World.main.start_memory()
				else:
					var ne = preload("res://scenes/ui/name_entry.gd").new()
					World.main.show_screen(ne)
					World.fade(false, 0.5)
				return
			"Options":
				menu.visible = false
				var o = preload("res://scenes/ui/options_menu.gd").new()
				add_child(o)
				await o.closed
				menu.visible = true
				menu._accept_after = Time.get_ticks_msec() + 150
			"Quitter":
				get_tree().quit()
				return

## Mot de passe secret tapé au clavier sur l'écran-titre.
func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var ch = String.chr(event.unicode).to_upper() if event.unicode > 0 else ""
	if ch == "" or not ch.is_valid_identifier() and not ch.is_valid_int():
		return
	typed = (typed + ch).right(16)
	var pw: String = data.get("password", "NOCLIP")
	if typed.ends_with(pw) and not busy:
		busy = true
		AudioManager.sfx("static")
		World.main.open_debug_room()
