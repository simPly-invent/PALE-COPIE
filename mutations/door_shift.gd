## Palier 4 — Géométrie : une porte est décalée sur le mur d'à côté.
## Règle 3.3.6 : toujours une règle visible — des flèches au sol mènent de l'ancienne à la nouvelle place.
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var cands: Array = []
	for d in room.doors.get_children():
		if d is Door and d.side != "top" and not d.def.get("fixed", false):
			cands.append(d)
	if cands.is_empty():
		return
	cands.sort_custom(func(a, b): return str(a.name) < str(b.name))
	var door: Door = cands[rng.randi_range(0, cands.size() - 1)]
	var w: int = room.tiles.width()
	var x = 2 if door.side == "left" else w - 3
	if door.side == "bottom":
		x = door.cell.x + (2 if door.cell.x < w / 2 else -2)
	# trouver la rangée de mur juste au-dessus du sol
	var y = 0
	while y < room.tiles.height() - 1 and room.tiles.get_cell(x, y + 1) == "#":
		y += 1
	if room.tiles.get_cell(x, y + 1) != ".":
		return
	var old_pos: Vector2 = room.cell_pos([door.cell.x, door.cell.y])
	door.side = "top"
	door.cell = Vector2i(x, y)
	door.shifted = true
	var new_pos: Vector2 = room.cell_pos([x, y + 1]) + Vector2(0, 10)
	# flèches au sol
	var steps = int(old_pos.distance_to(new_pos) / 50.0)
	for k in range(1, steps):
		var p = old_pos.lerp(new_pos, float(k) / steps)
		var arrow = room.add_prop({"id": "arrow_%s_%d" % [door.name, k], "sprite": "floor_arrow", "pos": [(p.x - 20) / 40.0, (p.y - 40) / 40.0], "solid": false, "floor": true, "tags": ["indicator"]})
		arrow.z_index = -4
		arrow.rotation = (new_pos - old_pos).angle()
		arrow.set_meta("indicates", str(door.name))
