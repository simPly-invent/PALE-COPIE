## Carte dessinée à la main de la zone actuelle. Elle devient fausse avec la dégradation :
## salles décalées, salles en trop. La « carte fiable » corrige la zone 4.
extends Control

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var r: Room = World.current_room
	if r == null:
		return
	var zone: Dictionary = r.zone
	var map: Dictionary = zone.get("map", {})
	var font = UI.font()
	draw_string(font, Vector2(8, 20), zone.get("name", "?"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.85, 0.7))
	var rooms: Dictionary = map.get("rooms", {})
	if rooms.is_empty():
		draw_string(font, Vector2(8, 60), "La page est blanche.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		return
	var reliable = r.source.zone == 4 and GameState.has_item("reliable_map")
	var k = 0.0 if reliable else clampf((100.0 - r.fidelity) / 80.0, 0.0, 1.0)
	var rng = JsonUtil.make_rng([GameState.game_seed, "map", r.source.zone, r.palier])
	var paper = Color(0.92, 0.88, 0.75)
	var pos = {}
	for id in rooms:
		var b: Array = rooms[id]
		var off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 30.0 * k
		pos[id] = Rect2(Vector2(b[0], b[1]) * 1.0 + Vector2(10, 34) + off, Vector2(b[2], b[3]))
	for l in map.get("links", []):
		if pos.has(l[0]) and pos.has(l[1]):
			draw_line(pos[l[0]].get_center(), pos[l[1]].get_center(), paper * Color(1, 1, 1, 0.6), 2.0)
	for id in pos:
		var visited = false
		for v in DegradationManager.visited:
			if v.begins_with(id + "#"):
				visited = true
		var rect: Rect2 = pos[id]
		draw_rect(rect, Color(0.15, 0.13, 0.1) if visited else Color(0, 0, 0), true)
		draw_rect(rect, paper if visited else paper * Color(1, 1, 1, 0.35), false, 2.0)
		if id == r.source.id:
			var heart = Assets.tex("soul_red")
			draw_texture_rect(heart, Rect2(rect.get_center() - Vector2(8, 8), Vector2(16, 15)), false)
	# salles qui n'existent pas
	for i in int(k * 4.0):
		var fake = Rect2(Vector2(rng.randf_range(20, 340), rng.randf_range(50, 330)), Vector2(rng.randf_range(20, 60), rng.randf_range(16, 40)))
		draw_rect(fake, paper * Color(1, 1, 1, 0.5), false, 2.0)
	if r.depth > 0:
		draw_string(font, Vector2(8, size.y - 10), "Copie n°%d — la carte ne sait pas où tu es." % r.depth if k > 0.3 else "Copie n°%d" % r.depth, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 0.7, 0.6))
