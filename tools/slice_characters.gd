## Outil : découpe les planches de personnages (papa_infirmiere_maman.png,
## agarderseuelementlafemmeadroite.png) en planches de marche au format du joueur.
## Lancer : godot --headless --script res://tools/slice_characters.gd
extends SceneTree

const FW := 24          # taille d'une image (pixels d'art), rendue x2 en jeu
const FH := 30

func _init() -> void:
	var mode := "slice"
	for a in OS.get_cmdline_user_args():
		if a == "--probe":
			mode = "probe"
	var s1 := _load("res://papa_infirmiere_maman.png")
	var s2 := _load("res://agarderseuelementlafemmeadroite.png")
	var c1 := _components(s1)
	var c2 := _components(s2)
	if mode == "probe":
		_print_rows("planche 1", c1)
		_print_rows("planche 2", c2)
		quit()
		return
	var r1 := _rows(c1)
	var r2 := _rows(c2)
	# planche 1 : 4 lignes (bas, haut, gauche, gauche bis) x 6 colonnes (papa x2, infirmière x2, maman x2), puis portraits
	var names := ["papa", "nurse", "maman"]
	var faces_right := [false, false, true]
	for k in 3:
		var frames := {"down": [r1[0][k * 2], r1[0][k * 2 + 1]], "up": [r1[1][k * 2], r1[1][k * 2 + 1]], "side": [r1[2][k * 2], r1[3][k * 2]]}
		_write_sheet(s1, frames, names[k], faces_right[k])
		_write_portrait(s1, r1[4][k], names[k])
	# planche 2 : seulement la femme à droite (tenue de patiente) ; ligne 1 = face puis dos, ligne 3 = profil
	var pf := {"down": [r2[0][4], r2[0][4]], "up": [r2[1][4], r2[1][5]], "side": [r2[2][4], r2[2][5]]}
	_write_sheet(s2, pf, "maman_patient", true)
	_write_portrait(s2, r2[3][r2[3].size() - 1], "maman_patient")
	# planche du manager : 4 lignes (bas, haut, gauche, droite) x 4 images
	if FileAccess.file_exists("res://managertelephonie.png"):
		var s3 := _load("res://managertelephonie.png")
		var r3 := _rows(_components(s3))
		_write_grid(s3, r3, "manager")
		# portrait : le haut de la première image de face
		var f: Rect2i = r3[0][0]
		_write_portrait(s3, Rect2i(f.position, Vector2i(f.size.x, int(f.size.y * 0.75))), "manager")
	# planche du bébé emmailloté : 4x4 également
	var baby_path := "res://Planche de sprites bébé emmailloté pixel art.png"
	if FileAccess.file_exists(baby_path):
		var s4 := _load(baby_path)
		_write_grid(s4, _rows(_components(s4)), "baby")
	print("slice_characters : terminé")
	quit()

func _load(p: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(p))
	img.convert(Image.FORMAT_RGBA8)
	_key_checker(img)
	return img

## Le fond est un damier blanc/gris : on l'efface depuis les bords.
func _key_checker(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var seen := PackedByteArray()
	seen.resize(w * h)
	var stack: Array[int] = []
	for x in w:
		stack.append(x); stack.append((h - 1) * w + x)
	for y in h:
		stack.append(y * w); stack.append(y * w + w - 1)
	while not stack.is_empty():
		var p: int = stack.pop_back()
		if seen[p]:
			continue
		var px := p % w
		var py := p / w
		var c := img.get_pixel(px, py)
		if c.v < 0.78 or c.s > 0.12:
			continue
		seen[p] = 1
		img.set_pixel(px, py, Color(0, 0, 0, 0))
		if px > 0: stack.append(p - 1)
		if px < w - 1: stack.append(p + 1)
		if py > 0: stack.append(p - w)
		if py < h - 1: stack.append(p + w)

func _components(img: Image) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var lab := PackedInt32Array()
	lab.resize(w * h)
	var out: Array = []
	var n := 0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a < 0.5 or lab[y * w + x] != 0:
				continue
			n += 1
			var minx := x; var maxx := x; var miny := y; var maxy := y; var cnt := 0
			var st: Array[int] = [y * w + x]
			lab[y * w + x] = n
			while not st.is_empty():
				var p: int = st.pop_back()
				var px := p % w
				var py := p / w
				cnt += 1
				minx = mini(minx, px); maxx = maxi(maxx, px); miny = mini(miny, py); maxy = maxi(maxy, py)
				for d in [-1, 1, -w, w, -2, 2, -2 * w, 2 * w]:
					var q: int = p + d
					if q < 0 or q >= w * h:
						continue
					var qx := q % w
					if abs(qx - px) > 2:
						continue
					if lab[q] == 0 and img.get_pixel(qx, q / w).a >= 0.5:
						lab[q] = n
						st.append(q)
			if cnt > 800:
				out.append(Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1))
	return out

func _rows(comps: Array) -> Array:
	comps.sort_custom(func(a, b): return a.get_center().y < b.get_center().y)
	var rows: Array = []
	for c in comps:
		if rows.is_empty() or abs(c.get_center().y - rows[-1][0].get_center().y) > 90:
			rows.append([c])
		else:
			rows[-1].append(c)
	for r in rows:
		r.sort_custom(func(a, b): return a.position.x < b.position.x)
	return rows

func _print_rows(title: String, comps: Array) -> void:
	print(title)
	for r in _rows(comps):
		print("  ", r.size(), " : ", r)

var _scale := 0.1

func _frame(img: Image, rect: Rect2i, flip := false) -> Image:
	var part := img.get_region(rect)
	var scale := minf(_scale, float(FH - 1) / rect.size.y)
	var nw := maxi(1, int(round(rect.size.x * scale)))
	var nh := maxi(1, int(round(rect.size.y * scale)))
	part.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	for y in part.get_height():
		for x in part.get_width():
			var c := part.get_pixel(x, y)
			part.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if c.a > 0.45 else 0.0))
	if flip:
		part.flip_x()
	var out := Image.create(FW, FH, false, Image.FORMAT_RGBA8)
	out.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i((FW - part.get_width()) / 2, FH - part.get_height()))
	return out

## Planche 4x4 identique à celle du joueur : lignes bas, haut, gauche, droite.
func _write_sheet(img: Image, frames: Dictionary, name: String, side_faces_right := false) -> void:
	_scale = float(FH - 1) / maxf(frames["down"][0].size.y, frames["up"][0].size.y)
	var sheet := Image.create(FW * 4, FH * 4, false, Image.FORMAT_RGBA8)
	var order := [["down", false], ["up", false], ["side", side_faces_right], ["side", not side_faces_right]]
	for row in 4:
		var key: String = order[row][0]
		var fl: bool = order[row][1]
		var fr: Array = frames[key]
		for col in 4:
			var f := _frame(img, fr[col % 2], fl)
			sheet.blit_rect(f, Rect2i(0, 0, FW, FH), Vector2i(col * FW, row * FH))
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s_walk.png" % name))
	# sprite fixe (face) pour les PNJ, déjà à l'échelle 2
	var still := _frame(img, frames["down"][0])
	still.resize(FW * 2, FH * 2, Image.INTERPOLATE_NEAREST)
	still.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % name))

func _write_portrait(img: Image, rect: Rect2i, name: String) -> void:
	var part := img.get_region(rect)
	var side := maxi(rect.size.x, rect.size.y)
	var sq := Image.create(side, side, false, Image.FORMAT_RGBA8)
	sq.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i((side - rect.size.x) / 2, side - rect.size.y))
	sq.resize(44, 44, Image.INTERPOLATE_LANCZOS)
	sq.resize(88, 88, Image.INTERPOLATE_NEAREST)
	sq.save_png(ProjectSettings.globalize_path("res://assets/portraits/%s.png" % name))

## Planche déjà organisée en 4x4 (bas, haut, gauche, droite).
func _write_grid(img: Image, rows: Array, name: String) -> void:
	_scale = float(FH - 1) / maxf(rows[0][0].size.y, rows[1][0].size.y)
	var sheet := Image.create(FW * 4, FH * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		for col in 4:
			var f := _frame(img, rows[row][mini(col, rows[row].size() - 1)])
			sheet.blit_rect(f, Rect2i(0, 0, FW, FH), Vector2i(col * FW, row * FH))
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s_walk.png" % name))
	var still := _frame(img, rows[0][0])
	still.resize(FW * 2, FH * 2, Image.INTERPOLATE_NEAREST)
	still.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % name))
