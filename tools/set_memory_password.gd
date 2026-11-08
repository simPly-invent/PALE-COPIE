## Change le mot de passe du « Souvenir » sans l'écrire en clair dans le projet.
## Lancer : godot --headless --script res://tools/set_memory_password.gd -- MOTDEPASSE
## (majuscules et minuscules sont équivalentes ; seule l'empreinte SHA-256 est enregistrée)
## Ajouter --relock pour remettre le cadenas sur cet ordinateur.
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var pw := ""
	for a in args:
		if not a.begins_with("--"):
			pw = a
	var path := ProjectSettings.globalize_path("res://data/title.json")
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if pw != "":
		data["memory_password_sha256"] = pw.strip_edges().to_upper().sha256_text()
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(data, " ", false))
		f.close()
		print("Mot de passe du Souvenir changé.")
	if args.has("--relock"):
		var save := ProjectSettings.globalize_path("user://save.json")
		if FileAccess.file_exists(save):
			var d = JSON.parse_string(FileAccess.get_file_as_string(save))
			if d is Dictionary and d.has("meta"):
				d["meta"].erase("memory_unlocked")
				var g := FileAccess.open(save, FileAccess.WRITE)
				g.store_string(JSON.stringify(d, "\t"))
				g.close()
				print("Cadenas remis.")
	quit()
