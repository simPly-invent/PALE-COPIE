## Fabrique l'icône du jeu : le logo « PÂLE COPIE » sur fond noir.
## Lancer : godot --headless --script res://tools/make_icon.gd
## Produit icon.png (1024x1024) et icon_256.png (pour l'icône Windows).
extends SceneTree

func _init() -> void:
	var logo := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/title_logo.png"))
	logo.convert(Image.FORMAT_RGBA8)
	logo = logo.get_region(logo.get_used_rect())
	var size := 1024
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	# agrandissement entier, sans lissage, pour garder les pixels nets
	var scale := (size * 0.9) / logo.get_width()
	var big := logo.duplicate()
	big.resize(int(logo.get_width() * scale), int(logo.get_height() * scale), Image.INTERPOLATE_NEAREST)
	img.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i((size - big.get_width()) / 2, (size - big.get_height()) / 2))
	img.save_png(ProjectSettings.globalize_path("res://icon.png"))
	var small := img.duplicate()
	small.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	small.save_png(ProjectSettings.globalize_path("res://assets/source/icon_256.png"))
	print("make_icon : terminé (échelle x%.2f)" % scale)
	quit()
