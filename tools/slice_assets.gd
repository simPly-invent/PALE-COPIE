## Outil : découpe asset_tuile.png et principalcharacter_deplacement.png en sprites individuels.
## Lancer : godot --headless --script res://tools/slice_assets.gd
extends SceneTree

const ATLAS := "res://assets/source/atlas_decors_ennemis_ui.png"
const PLAYER_SHEET := "res://assets/source/heros_marche_ancien.png"

# nom -> [x, y, w, h, tolérance_fond]  (coordonnées dans asset_tuile.png, 1536x1024)
const SPRITES := {
	# Décors et objets
	"chair_red": [382, 54, 38, 51], "chair_blue": [436, 55, 37, 49], "chair_grey": [492, 55, 42, 49],
	"desk": [557, 46, 67, 59], "filing_cabinet": [645, 45, 37, 59], "filing_cabinet_tall": [708, 38, 35, 66],
	"vending_machine": [768, 41, 53, 73], "trash_can": [846, 44, 41, 61], "plant": [906, 44, 32, 60],
	"clock": [953, 39, 36, 37],
	"sofa_purple": [379, 121, 84, 48], "sofa_red": [477, 122, 75, 47], "table": [565, 127, 55, 42],
	"tv": [640, 123, 65, 45], "safe": [722, 127, 45, 43], "wet_floor_sign": [794, 130, 47, 43],
	"bookshelf": [864, 116, 56, 57], "drawers": [942, 126, 46, 46],
	"lamp": [382, 184, 33, 50], "neon_ceiling": [434, 182, 50, 44], "hanging_lamp": [500, 182, 33, 43],
	"extinguisher": [550, 186, 32, 48], "phone": [599, 192, 43, 42], "computer": [664, 192, 43, 40],
	"copier": [732, 183, 46, 51], "cabinet_small": [802, 184, 41, 50], "bed": [859, 188, 54, 46],
	"stretcher": [934, 191, 57, 43],
	# Portes et éléments
	"door_beige": [1027, 42, 49, 85], "door_wood": [1096, 42, 44, 85], "door_grey_double": [1161, 42, 72, 85],
	"door_white_double": [1257, 42, 79, 85], "door_elevator": [1362, 41, 70, 86], "door_red_window": [1452, 41, 56, 86],
	"sign_sortie": [1029, 147, 86, 45], "sign_exit_arrow": [1149, 147, 39, 50], "bars": [1217, 147, 66, 80],
	"hazard": [1309, 148, 45, 78], "door_small_window": [1387, 145, 59, 84],
	# PNJ
	"npc_kid": [34, 310, 33, 51], "npc_girl": [100, 292, 41, 69], "npc_scientist": [169, 287, 39, 74],
	"npc_worker": [232, 286, 39, 75], "npc_redhead": [295, 286, 44, 75], "npc_guard": [371, 282, 39, 79],
	"npc_granny": [27, 378, 47, 67], "npc_oldman": [99, 376, 40, 69], "npc_scientist_bald": [161, 376, 39, 69],
	"npc_shadow": [214, 372, 46, 76, 0.035], "npc_girl_purple": [270, 376, 41, 69], "npc_hat_man": [332, 378, 36, 66],
	"npc_ghost": [387, 379, 49, 64],
	# Ennemis
	"enemy_chair": [474, 331, 56, 74], "enemy_monitor": [555, 335, 43, 73], "enemy_cone": [624, 317, 50, 91],
	"enemy_ghost": [697, 320, 51, 83], "enemy_blob": [768, 350, 61, 54], "enemy_shadow": [840, 272, 72, 140, 0.035],
	# Boss
	"boss_receptionist": [953, 303, 107, 125], "boss_concierge": [1091, 285, 63, 142], "boss_swimmer": [1187, 290, 60, 138],
	"boss_entity": [1255, 262, 135, 172, 0.035], "boss_copy_a": [1397, 307, 49, 120], "boss_copy_b": [1446, 307, 48, 120],
	# Objets interactifs
	"item_key": [26, 506, 33, 45], "item_badge": [69, 502, 47, 44], "item_vhs": [126, 506, 56, 38],
	"item_photo": [194, 502, 43, 49], "item_pizza": [257, 499, 37, 52], "item_candy": [303, 509, 37, 38],
	"item_apple": [349, 513, 29, 34], "item_milk": [388, 504, 30, 44], "item_book": [430, 505, 37, 46],
	"item_cassette": [478, 513, 45, 30],
	# Coffres et conteneurs
	"chest_box": [554, 508, 53, 44], "chest_crate": [623, 501, 49, 51], "chest_locker": [690, 493, 36, 65],
	"chest_box_open": [742, 508, 51, 45], "chest_vending": [808, 488, 40, 65], "chest_crate_blue": [865, 504, 47, 48],
	"chest_briefcase": [928, 499, 53, 48],
	# Icônes
	"icon_heart": [447, 623, 36, 35], "icon_star": [502, 623, 35, 35], "icon_cassette": [551, 626, 52, 31],
	"icon_key": [618, 622, 31, 38], "icon_phone": [668, 621, 29, 39], "icon_bag": [716, 620, 35, 40],
	"icon_camcorder": [444, 685, 51, 39], "icon_note": [523, 685, 32, 40], "icon_map": [590, 684, 55, 41],
	"icon_question": [679, 685, 26, 40], "icon_exclaim": [748, 685, 14, 40],
	"soul_red": [493, 753, 32, 30], "soul_yellow": [547, 753, 31, 29], "soul_blue": [600, 753, 31, 29],
	"soul_purple": [653, 753, 31, 30], "soul_grey": [706, 754, 31, 28],
	# Animations exemples
	"ghost_anim_0": [24, 914, 36, 38], "ghost_anim_1": [71, 914, 38, 38], "ghost_anim_2": [120, 914, 37, 38],
	"ghost_anim_3": [168, 914, 39, 38],
	"chair_anim_0": [29, 963, 36, 42], "chair_anim_1": [77, 963, 32, 42], "chair_anim_2": [127, 963, 28, 41],
	"chair_anim_3": [173, 963, 32, 42],
	# Logo
	"title_logo": [1215, 818, 296, 182],
}

# Images rectangulaires copiées sans détourage (tuiles, portraits, vhs, effets)
const RAW := {
	"tiles/carpet_yellow": [33, 47, 40, 40], "tiles/carpet_brown": [101, 47, 40, 40], "tiles/floor_diamond": [168, 47, 40, 40],
	"tiles/tile_green": [233, 47, 40, 40], "tiles/tile_dark_green": [298, 47, 40, 40],
	"tiles/wall_beige": [33, 108, 40, 40], "tiles/tile_yellow": [101, 108, 40, 40], "tiles/tile_purple": [168, 108, 40, 40],
	"tiles/wall_grey": [233, 108, 40, 40], "tiles/wall_panel": [298, 108, 40, 40],
	"tiles/wall_cream": [33, 176, 40, 40], "tiles/wall_yellow": [101, 176, 40, 40], "tiles/floor_concrete": [168, 176, 40, 40],
	"portraits/girl": [24, 615, 66, 70], "portraits/woman": [102, 615, 65, 70], "portraits/scientist": [180, 615, 65, 70],
	"portraits/cat": [257, 615, 66, 70], "portraits/ghost": [335, 615, 66, 70],
	"portraits/guard": [24, 695, 66, 70], "portraits/girl_b": [102, 695, 65, 70], "portraits/shadow": [180, 695, 65, 70],
	"portraits/monitor": [257, 695, 66, 70], "portraits/scared": [335, 695, 66, 70],
	"vhs/static": [832, 619, 66, 66], "vhs/scanlines": [904, 619, 66, 66], "vhs/rgb": [975, 619, 66, 66],
	"vhs/grain_dark": [1045, 619, 64, 66], "vhs/grain_yellow": [1113, 619, 64, 66], "vhs/noise": [1181, 619, 58, 66],
	"vhs/eye": [832, 694, 72, 96], "vhs/glitch_lines": [912, 694, 90, 96], "vhs/weave": [1010, 694, 98, 96],
	"vhs/streak": [1116, 708, 116, 69],
	"vhs/timestamp": [1371, 628, 140, 70], "vhs/hallway": [1263, 714, 107, 78], "vhs/entity": [1380, 714, 132, 78],
	"vhs/tape_big": [1264, 639, 84, 55],
}

func _init() -> void:
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(ATLAS))
	atlas.convert(Image.FORMAT_RGBA8)
	var n := 0
	for key in SPRITES:
		var r: Array = SPRITES[key]
		var tol: float = r[4] if r.size() > 4 else 0.05
		var img := atlas.get_region(Rect2i(r[0], r[1], r[2], r[3]))
		_key_out_background(img, tol)
		img = _trim(img)
		img.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % key))
		n += 1
	for key in RAW:
		var r: Array = RAW[key]
		var img := atlas.get_region(Rect2i(r[0], r[1], r[2], r[3]))
		img.save_png(ProjectSettings.globalize_path("res://assets/%s.png" % key))
		n += 1
	n += _slice_player()
	print("slice_assets: %d images écrites" % n)
	quit()

## Détourage : remplissage depuis les bords sur les pixels proches de la couleur de fond.
func _key_out_background(img: Image, tol: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var corners := [img.get_pixel(0, 0), img.get_pixel(w - 1, 0), img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1)]
	var bg := Color(0, 0, 0)
	for c in corners:
		bg.r += c.r / 4.0; bg.g += c.g / 4.0; bg.b += c.b / 4.0
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
		if max(abs(c.r - bg.r), abs(c.g - bg.g), abs(c.b - bg.b)) > tol + 0.03:
			continue
		seen[p] = 1
		img.set_pixel(px, py, Color(0, 0, 0, 0))
		if px > 0: stack.append(p - 1)
		if px < w - 1: stack.append(p + 1)
		if py > 0: stack.append(p - w)
		if py < h - 1: stack.append(p + w)

func _trim(img: Image) -> Image:
	var used := img.get_used_rect()
	if used.size.x <= 0:
		return img
	return img.get_region(used)

## Planche du héros : 4 lignes (bas, haut, gauche, droite) x 4 images, 1 pixel d'art = 11 px.
func _slice_player() -> int:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(PLAYER_SHEET))
	sheet.convert(Image.FORMAT_RGBA8)
	const PX := 11
	const FW := 20
	const FH := 26
	var cw := sheet.get_width() / 4.0
	var ch := sheet.get_height() / 4.0
	var out := Image.create(FW * 4, FH * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		for col in 4:
			var x0 := int(col * cw)
			var y0 := int(row * ch)
			var x1 := int((col + 1) * cw)
			var y1 := int((row + 1) * ch)
			# boîte englobante en ignorant les pixels parasites gris clair
			var minx := 99999; var miny := 99999; var maxx := -1; var maxy := -1
			for y in range(y0, y1):
				for x in range(x0, x1):
					var c := sheet.get_pixel(x, y)
					if c.a > 0.5 and not _is_stray(c):
						minx = min(minx, x); maxx = max(maxx, x); miny = min(miny, y); maxy = max(maxy, y)
			var aw := int(round((maxx - minx + 1) / float(PX)))
			var ah := int(round((maxy - miny + 1) / float(PX)))
			var ox := col * FW + (FW - aw) / 2
			var oy := row * FH + (FH - ah)
			for ay in ah:
				for ax in aw:
					var c := sheet.get_pixel(minx + ax * PX + PX / 2, miny + ay * PX + PX / 2)
					if c.a > 0.5 and not _is_stray(c):
						out.set_pixel(ox + ax, oy + ay, Color(c.r, c.g, c.b, 1.0))
	out.save_png(ProjectSettings.globalize_path("res://assets/sprites/heros_ancien_walk.png"))
	return 1

func _is_stray(c: Color) -> bool:
	return c.r > 0.8 and c.g > 0.8 and c.b > 0.8
