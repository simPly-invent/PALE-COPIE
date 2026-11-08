## Fabrique « La Copie » à partir de l'héroïne : même silhouette, mais pâle, froide, trop nette.
## Lancer après tools/slice_atlases.gd : godot --headless --script res://tools/make_copy_sprite.gd
extends SceneTree

func _init() -> void:
	var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/child_walk.png"))
	src.convert(Image.FORMAT_RGBA8)
	var sheet := _pale(src)
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/copy_walk.png"))
	# image fixe (face, première image) à l'échelle 2, pour les PNJ
	var fw := sheet.get_width() / 4
	var fh := sheet.get_height() / 4
	var still := sheet.get_region(Rect2i(0, 0, fw, fh))
	still.resize(fw * 2, fh * 2, Image.INTERPOLATE_NEAREST)
	still.save_png(ProjectSettings.globalize_path("res://assets/sprites/copy.png"))
	# image de combat, plus grande
	var big := sheet.get_region(Rect2i(0, 0, fw, fh))
	big.resize(fw * 4, fh * 4, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://assets/sprites/copy_battle.png"))
	var por := Image.load_from_file(ProjectSettings.globalize_path("res://assets/portraits/child.png"))
	if por:
		por.convert(Image.FORMAT_RGBA8)
		_pale(por).save_png(ProjectSettings.globalize_path("res://assets/portraits/copy.png"))
	print("make_copy_sprite : terminé")
	quit()

func _pale(img: Image) -> Image:
	var out: Image = img.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var l := c.get_luminance()
			if l < 0.12:
				# le contour reste net, mais tire vers un gris bleuté
				out.set_pixel(x, y, Color(0.16, 0.17, 0.24, 1.0))
				continue
			var grey := Color(l, l, l)
			var pale := c.lerp(grey, 0.7).lerp(Color(0.86, 0.9, 1.0), 0.35)
			pale = pale.lightened(0.18)
			out.set_pixel(x, y, Color(pale.r, pale.g, pale.b, 1.0))
	return out
