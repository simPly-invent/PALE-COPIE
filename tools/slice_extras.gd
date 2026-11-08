## Outil : découpe les planches de assets/source/ demandées pour remplacer les placeholders :
## perso_pnj_aventure.png (6 personnages 4x4), objets_divers.png, ennemis_phare_bouee.png, vhs_plans.png.
## Lancer : godot --headless --script res://tools/slice_extras.gd   (puis --import)
extends SceneTree

const CH = preload("res://tools/slice_characters.gd")
const SRC := "res://assets/source/"

# 6 personnages : [nom, colonne (0-2), bloc de lignes (0 haut, 1 bas), hauteur en pixels d'art]
const PEOPLE := [
	["mr_pli", 0, 0, 22], ["lumi", 1, 0, 16], ["delivery_man", 2, 0, 29],
	["lea", 0, 1, 24], ["lifeguard", 1, 1, 29], ["office_worker", 2, 1, 29],
]
# objets : nom -> largeur finale en pixels (dans l'ordre de lecture de la planche)
const OBJECTS := [["drawing_child", 34], ["save_floppy", 22], ["washing_machine", 48],
	["crib", 56], ["fridge", 40], ["car", 100],
	["pillar", 40], ["pool_ladder", 30], ["floor_arrow", 28], ["icon_lock", 16]]
const ENEMIES := [["headlight", 46], ["buoy", 56]]
const VHS := ["office", "parking", "hotel", "pool", "house", "bedroom", "children", "lab"]

var ch

func _init() -> void:
	ch = CH.new()
	_people()
	_props("objets_divers.png", OBJECTS)
	_props("ennemis_phare_bouee.png", ENEMIES)
	_vhs()
	print("slice_extras : terminé")
	quit()

func _people() -> void:
	var path := SRC + "perso_pnj_aventure.png"
	if not FileAccess.file_exists(path):
		return
	var img: Image = ch._load(path)
	var rows: Array = ch._rows(ch._components(img))
	# 8 lignes de 12 images : 3 personnages par bloc de 4 lignes
	for p in PEOPLE:
		var col: int = p[1]
		var block: int = p[2]
		var grid: Array = []
		for r in 4:
			var row: Array = rows[block * 4 + r]
			# découpe la ligne en 3 groupes de 4 selon la position horizontale
			var third := img.get_width() / 3.0
			var cells: Array = row.filter(func(c): return int(c.get_center().x / third) == col)
			cells.sort_custom(func(a, b): return a.position.x < b.position.x)
			grid.append(cells)
		_write(img, grid, p[0], p[3])

func _write(img: Image, grid: Array, name: String, art_h: int) -> void:
	var tallest := 0
	for r in grid:
		for f in r:
			tallest = maxi(tallest, f.size.y)
	ch._scale = float(art_h) / tallest
	var sheet := Image.create(ch.FW * 4, ch.FH * 4, false, Image.FORMAT_RGBA8)
	for row in 4:
		for c in 4:
			# les deux lignes de profil de la planche regardent à gauche : la droite est le miroir de la gauche
			var cells: Array = grid[mini(row, 2)]
			var f: Image = ch._frame(img, cells[mini(c, cells.size() - 1)], row == 3)
			sheet.blit_rect(f, Rect2i(0, 0, ch.FW, ch.FH), Vector2i(c * ch.FW, row * ch.FH))
	sheet.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s_walk.png" % name))
	# image fixe : première image de face, à l'échelle 2, rognée
	var still: Image = sheet.get_region(Rect2i(0, 0, ch.FW, ch.FH))
	still = still.get_region(still.get_used_rect())
	still.resize(still.get_width() * 2, still.get_height() * 2, Image.INTERPOLATE_NEAREST)
	still.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % name))
	var head: Rect2i = grid[0][0]
	ch._write_portrait(img, Rect2i(head.position, Vector2i(head.size.x, int(head.size.y * 0.75))), name)

func _props(file: String, names: Array) -> void:
	var path := SRC + file
	if not FileAccess.file_exists(path):
		return
	var img: Image = ch._load(path)
	var comps: Array = []
	for r in ch._rows(ch._components(img)):
		comps.append_array(r)
	# on ignore les petits éclats (rayons de lumière, étincelles) autour des objets
	var biggest := 0
	for c in comps:
		biggest = maxi(biggest, c.get_area())
	comps = comps.filter(func(c): return c.get_area() >= biggest * 0.1)
	for i in mini(comps.size(), names.size()):
		var rect: Rect2i = comps[i]
		var part := img.get_region(rect)
		var w: int = names[i][1]
		var h := maxi(4, int(round(rect.size.y * float(w) / rect.size.x)))
		part.resize(w, h, Image.INTERPOLATE_LANCZOS)
		for y in part.get_height():
			for x in part.get_width():
				var c := part.get_pixel(x, y)
				part.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0 if c.a > 0.45 else 0.0))
		part.save_png(ProjectSettings.globalize_path("res://assets/sprites/%s.png" % names[i][0]))

func _vhs() -> void:
	var path := SRC + "vhs_plans.png"
	if not FileAccess.file_exists(path):
		return
	var img: Image = ch._load(path)
	var comps: Array = []
	for r in ch._rows(ch._components(img)):
		comps.append_array(r)
	for i in mini(comps.size(), VHS.size()):
		var part := img.get_region(comps[i].grow(-6))
		part.resize(320, 240, Image.INTERPOLATE_LANCZOS)
		part.save_png(ProjectSettings.globalize_path("res://assets/vhs/%s.png" % VHS[i]))
