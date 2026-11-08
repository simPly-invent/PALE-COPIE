## Outil : découpe les planches de assets/source/ : atlas_interieur_moderne.png,
## atlas_objets_abandonnes.png, perso_medecin_clients_ages.png et perso_heroine.png. Les noms suivent l'ordre des lignes, de gauche à droite.
## Lancer : godot --headless --script res://tools/slice_atlases.gd
extends SceneTree

const CH = preload("res://tools/slice_characters.gd")

const MODERN := "res://assets/source/atlas_interieur_moderne.png"
const ABANDON := "res://assets/source/atlas_objets_abandonnes.png"
const PEOPLE := "res://assets/source/perso_medecin_clients_ages.png"

# "floor:" = tuile de sol 40x40 ; "wall:" = mur 40x80 (deux cases de hauteur) ; "" = ignoré
const MODERN_ROWS := [
	["floor:m_floor_white_tile", "floor:m_floor_dark_tile", "floor:m_floor_cream", "floor:m_floor_checker", "floor:m_floor_blue_tile", "floor:m_floor_wood", "floor:m_floor_white_grid", "floor:m_floor_blue_stripe", "floor:m_floor_speckle", "floor:m_carpet_navy", ""],
	["wall:m_wall_white", "wall:m_wall_grey_band", "wall:m_wall_blue_band", "wall:m_wall_blue_stripe", "wall:m_wall_curtain", "", "m_doorway", "m_door_window", "m_doorway_wide", "m_window"],
	["m_reception_desk", "m_desk_pc", "m_table", "m_sofa_blue", "m_armchair_blue", "m_bed_blue", "m_cabinet", "m_bookshelf", "m_drawers", "m_wardrobe"],
	["m_plant_big", "m_plant_small", "m_flowers", "m_water_cooler", "m_coffee_machine", "m_coffee_table", "m_office_chair", "m_trash", "m_cart", "m_tv_stand", "m_cork_board", "m_picture", "m_clock"],
	["m_rug_navy", "m_rug_oval", "m_rug_white", "m_rug_round", "m_rug_pattern", "m_rug_star", "m_mat_stripes", "m_curtain", "m_plant_tall", "m_hanging_plant"],
	["m_shelf_books", "m_bench_towels", "m_plant_shelf", "m_nightstand", "m_wardrobe2", "m_sideboard", "m_first_aid", "m_coat_rack", "m_vending", "m_printer", "m_heart_frame"],
	["m_monitor", "m_laptop", "m_smartphone", "m_keyboard", "m_desk_phone", "m_lanyard", "m_clipboard", "m_pen", "m_notepad", "m_plant_pot", "m_mug", "m_tissues", "m_desk_lamp", "m_lamp", "m_trash_small"],
]
const ABANDON_ROWS := [
	["wall:a_wall_white", "wall:a_wall_cracked", "wall:a_wall_stained", "wall:a_wall_dirty", "wall:a_wall_yellow", "wall:a_wall_yellow2", "wall:a_wall_yellow3", "wall:a_wall_yellow4", "wall:a_wall_grey", "wall:a_wall_grey2", "wall:a_wall_grey3", "a_vent"],
	["a_doorway", "a_doorway2", "a_door_window", "a_door_dark", "a_door_double", "a_door_double2", "a_door_double_dirty", "a_door_plain", "a_door_beige", "a_door_rusted", "a_door_hazard"],
	["a_desk_white", "a_desk_grey", "a_desk_wood", "a_desk_pc", "a_desk_plant", "a_chair_blue", "a_chair_black", "a_chair_moldy", "a_chair_green"],
	["a_file", "a_file2", "a_file3", "a_locker", "a_shelf", "a_shelf2", "a_shelf3", "a_shelf4", "a_shelf_metal", "a_shelf_metal2", "a_shelf_metal3", "a_cabinet"],
	["a_plant", "a_plant2", "a_plant_dead", "a_cooler", "a_cooler2", "a_cooler3", "a_trash", "a_trash2", "a_trash3", "a_coatrack", "a_coatrack2", "a_clock", "a_clock2"],
	["a_sofa_blue", "a_sofa_brown", "a_sofa_brown2", "a_sofa_torn", "a_bed_blue", "a_bed_blue2", "a_bed_dirty", "a_hospital_bed", "a_hospital_bed_dirty"],
	["a_kitchen", "a_kitchen2", "a_kitchen3", "a_kitchen4", "a_shelf_dishes", "a_shelf_dishes2", "a_lockers_wood", "a_lockers_dirty", "a_locker_open", "a_lockers_grey", "a_lockers_hazard"],
	["a_neon_white", "a_neon_warm", "a_lamp_ceiling", "a_lamp_hanging", "a_lamp_dark", "a_lamp_dark2", "a_lamp_warm", "a_exit_green", "a_exit_dirty", "a_exit_red"],
	["floor:a_floor_checker", "floor:a_floor_blue_dirty", "floor:a_floor_green_dirty", "floor:a_floor_dark_dirty", "floor:a_floor_white", "floor:a_floor_cream", "floor:a_floor_brown_dirty", "floor:a_floor_dark", "a_rug_blue", "a_rug_red", "a_rug_green", "a_rug_red_torn"],
	["a_extinguisher", "a_extinguisher2", "a_wet_sign", "a_wet_sign2", "a_box", "a_box_open", "a_wheelchair", "a_stretcher", "a_mop", "a_bucket", "a_debris_chair", "a_rubble", "a_debris"],
]

var ch

func _init() -> void:
	ch = CH.new()
	if OS.get_cmdline_user_args().has("--probe-main"):
		var im: Image = ch._load("res://assets/source/perso_heroine.png")
		for r in ch._rows(ch._components(im)):
			print(r.size(), " ", r)
		quit()
		return
	var n := 0
	n += _atlas(MODERN, MODERN_ROWS, 40.0)
	n += _atlas(ABANDON, ABANDON_ROWS, 40.0)
	_people()
	_child()
	print("slice_atlases : %d images" % n)
	quit()

## Regroupe les composants en lignes serrées (les petites lignes voisines ne sont pas fusionnées).
func _tight_rows(comps: Array) -> Array:
	comps.sort_custom(func(a, b): return a.get_center().y < b.get_center().y)
	var rows: Array = []
	for c in comps:
		if rows.is_empty() or abs(c.get_center().y - rows[-1][0].get_center().y) > 40:
			rows.append([c])
		else:
			rows[-1].append(c)
	for r in rows:
		r.sort_custom(func(a, b): return a.position.x < b.position.x)
	return rows

func _atlas(path: String, names: Array, _unused: float) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var img: Image = ch._load(path)
	var rows := _tight_rows(ch._components(img))
	var n := 0
	if rows.size() != names.size():
		push_warning("%s : %d lignes détectées, %d attendues" % [path, rows.size(), names.size()])
	for r in mini(rows.size(), names.size()):
		var row: Array = rows[r]
		for i in mini(row.size(), names[r].size()):
			var name: String = names[r][i]
			if name == "":
				continue
			var rect: Rect2i = row[i]
			if name.begins_with("floor:"):
				_save_tile(img, rect.grow(-6), name.substr(6), Vector2i(40, 40))
			elif name.begins_with("wall:"):
				_save_tile(img, rect.grow(-3), name.substr(5), Vector2i(40, 80))
			else:
				_save_prop(img, rect, name)
			n += 1
	return n

func _save_tile(img: Image, rect: Rect2i, name: String, size: Vector2i) -> void:
	var part := img.get_region(rect)
	part.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	for y in part.get_height():
		for x in part.get_width():
			var c := part.get_pixel(x, y)
			part.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	part.save_png(ProjectSettings.globalize_path("res://assets/tiles/%s.png" % name))

## Objet : moitié de la taille de la planche (environ l'échelle des personnages en jeu).
func _save_prop(img: Image, rect: Rect2i, name: String) -> void:
	var part := img.get_region(rect)
	var w := maxi(4, int(round(rect.size.x * 0.5)))
	var h := maxi(4, int(round(rect.size.y * 0.5)))
	part.resize(w, h, Image.INTERPOLATE_LANCZOS)
	for y in part.get_height():
		for x in part.get_width():
			var c := part.get_pixel(x, y)
			part.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if c.a > 0.45 else 0.0))
	part.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % name))

## Médecin, client âgé, cliente âgée : 4 lignes de 9 images.
func _people() -> void:
	if not FileAccess.file_exists(PEOPLE):
		return
	var img: Image = ch._load(PEOPLE)
	var rows: Array = ch._rows(ch._components(img))
	# médecin : ligne 0 = face (0-3) + dos (4-7), ligne 1 = profil gauche (0-3)
	_grid(img, [rows[0].slice(0, 4), rows[0].slice(4, 8), rows[1].slice(0, 4)], "doctor")
	for pair in [[2, "customer"], [3, "customer_woman"]]:
		var r: Array = rows[pair[0]]
		_grid(img, [r.slice(0, 4), [r[4], r[5], r[6], r[5]], [r[7], r[8], r[7], r[8]]], pair[1])

func _grid(img: Image, dirs: Array, name: String) -> void:
	# dirs : [bas, haut, gauche] ; la droite est le miroir de la gauche
	ch._scale = float(ch.FH - 1) / maxf(dirs[0][0].size.y, dirs[1][0].size.y)
	var sheet := Image.create(ch.FW * 4, ch.FH * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		var src: Array = dirs[mini(row, 2)]
		for col in 4:
			var f: Image = ch._frame(img, src[col % src.size()], row == 3)
			sheet.blit_rect(f, Rect2i(0, 0, ch.FW, ch.FH), Vector2i(col * ch.FW, row * ch.FH))
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s_walk.png" % name))
	var still: Image = ch._frame(img, dirs[0][0])
	still.resize(ch.FW * 2, ch.FH * 2, Image.INTERPOLATE_NEAREST)
	still.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % name))
	var head: Rect2i = dirs[0][0]
	ch._write_portrait(img, Rect2i(head.position, Vector2i(head.size.x, int(head.size.y * 0.7))), name)

## L'héroïne (perso_heroine.png) : 4x4 bas, haut, gauche, droite. Plus petite que les adultes.
func _child() -> void:
	if not FileAccess.file_exists("res://assets/source/perso_heroine.png"):
		return
	var img: Image = ch._load("res://assets/source/perso_heroine.png")
	var rows: Array = ch._rows(ch._components(img))
	var tallest := 0
	for r in rows:
		for f in r:
			tallest = maxi(tallest, f.size.y)
	ch._scale = 25.0 / tallest
	var sheet := Image.create(ch.FW * 4, ch.FH * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		for col in 4:
			var f: Image = ch._frame(img, rows[row][col])
			sheet.blit_rect(f, Rect2i(0, 0, ch.FW, ch.FH), Vector2i(col * ch.FW, row * ch.FH))
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/child_walk.png"))
	var head: Rect2i = rows[0][0]
	ch._write_portrait(img, Rect2i(head.position, Vector2i(head.size.x, int(head.size.y * 0.8))), "child")
