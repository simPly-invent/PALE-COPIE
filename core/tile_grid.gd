## Nœud « Tiles » d'une salle : grille de cases dessinée à la main (sol, murs, eau...).
## Caractères : '#' mur, '.' sol, 'w' eau, ' ' vide, 'h' passage secret (mur sans collision),
## 'r' 'y' 'g' 'b' carreaux colorés, 'x' carreau délavé, 'o' sol alternatif.
class_name TileGrid
extends Node2D

const TILE := 40

var rows: Array = []          # Array[Array[String]]
var floor_tex: Texture2D
var alt_floor_tex: Texture2D
var wall_tex: Texture2D
var top_color = Color(0.04, 0.035, 0.05)
var water_color = Color(0.1, 0.24, 0.4)
var tile_colors = {"r": Color(0.75, 0.2, 0.2), "y": Color(0.85, 0.75, 0.25), "g": Color(0.3, 0.65, 0.35), "b": Color(0.25, 0.4, 0.8), "x": Color(0.55, 0.53, 0.47)}

func setup(layout: PackedStringArray) -> void:
	rows.clear()
	var w = 0
	for line in layout:
		w = max(w, line.length())
	for line in layout:
		var r: Array = []
		for i in w:
			r.append(line[i] if i < line.length() else " ")
		rows.append(r)

func width() -> int:
	return rows[0].size() if rows.size() > 0 else 0

func height() -> int:
	return rows.size()

func get_cell(x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].size():
		return " "
	return rows[y][x]

func set_cell(x: int, y: int, c: String) -> void:
	if y >= 0 and y < rows.size() and x >= 0 and x < rows[y].size():
		rows[y][x] = c
		queue_redraw()

## Un mur est une « face » visible s'il y a du sol juste en dessous, ou deux cases en dessous.
func _is_face(x: int, y: int) -> bool:
	var b1 = get_cell(x, y + 1)
	if b1 != "#" and b1 != "h" and b1 != " ":
		return true
	var b2 = get_cell(x, y + 2)
	return (b1 == "#" or b1 == "h") and b2 != "#" and b2 != "h" and b2 != " " and y + 2 < rows.size() and get_cell(x, y - 1) != " " and _floor_below(x, y + 2)

func _floor_below(x: int, y: int) -> bool:
	var c = get_cell(x, y)
	return c == "." or c == "o" or c == "w" or "rygbx".contains(c)

func is_wall(c: String) -> bool:
	return c == "#" or c == "h"

func is_walkable(x: int, y: int) -> bool:
	var c = get_cell(x, y)
	return c != "#" and c != " " and c != "w"

func insert_columns(at: int, count: int) -> void:
	for r in rows:
		var src: String = r[clampi(at, 0, r.size() - 1)]
		for i in count:
			r.insert(at, src)
	queue_redraw()

func insert_rows(at: int, count: int) -> void:
	var src: Array = rows[clampi(at, 0, rows.size() - 1)].duplicate()
	for i in count:
		rows.insert(at, src.duplicate())
	queue_redraw()

func pixel_size() -> Vector2:
	return Vector2(width() * TILE, height() * TILE)

func _draw() -> void:
	for y in rows.size():
		for x in rows[y].size():
			var c: String = rows[y][x]
			var rect = Rect2(x * TILE, y * TILE, TILE, TILE)
			match c:
				".", "o":
					var t = alt_floor_tex if c == "o" and alt_floor_tex else floor_tex
					if t:
						draw_texture_rect(t, rect, false)
					else:
						draw_rect(rect, Color(0.5, 0.45, 0.3))
				"#", "h":
					if _is_face(x, y):
						if wall_tex:
							draw_texture_rect(wall_tex, rect, false)
						else:
							draw_rect(rect, Color(0.6, 0.55, 0.4))
						draw_rect(Rect2(rect.position.x, rect.end.y - 3, TILE, 3), Color(0, 0, 0, 0.45))
					else:
						draw_rect(rect, top_color)
				"w":
					draw_rect(rect, water_color)
					var t = Time.get_ticks_msec() / 1000.0
					var off = int(sin(t * 1.3 + x * 0.7 + y) * 3.0)
					draw_rect(Rect2(rect.position.x + 6 + off, rect.position.y + 12, 14, 2), water_color.lightened(0.25))
				"r", "y", "g", "b", "x":
					if floor_tex:
						draw_texture_rect(floor_tex, rect, false)
					draw_rect(rect.grow(-4), tile_colors[c])
				_:
					draw_rect(rect, Color.BLACK)

func _process(_delta: float) -> void:
	# l'eau ondule doucement
	if _has_water:
		queue_redraw()

var _has_water = false

func refresh_flags() -> void:
	_has_water = false
	for r in rows:
		if r.has("w"):
			_has_water = true
			break
	queue_redraw()

## Collisions : un rectangle par série horizontale de murs, plus l'eau et le vide.
func build_collision(body: StaticBody2D) -> void:
	for ch in body.get_children():
		ch.free()
	for y in rows.size():
		var x = 0
		var w = width()
		while x < w:
			var c: String = rows[y][x]
			if c == "#" or c == "w" or c == " ":
				var start = x
				while x < w and (rows[y][x] == "#" or rows[y][x] == "w" or rows[y][x] == " "):
					x += 1
				var shape = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				rect.size = Vector2((x - start) * TILE, TILE)
				shape.shape = rect
				shape.position = Vector2(start * TILE + rect.size.x / 2.0, y * TILE + TILE / 2.0)
				body.add_child(shape)
			else:
				x += 1
