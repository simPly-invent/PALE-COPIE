## Palier 4 — Géométrie : un mur en trop au milieu de la pièce (sans jamais bloquer un passage).
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var t: TileGrid = room.tiles
	for attempt in 8:
		var x = rng.randi_range(3, t.width() - 4)
		var y0 = rng.randi_range(4, max(4, t.height() - 4))
		var len = rng.randi_range(2, 3)
		var cells: Array = []
		for k in len:
			if t.get_cell(x, y0 + k) == ".":
				cells.append(Vector2i(x, y0 + k))
		if cells.size() < 2 or _near_something(room, cells):
			continue
		for c in cells:
			t.set_cell(c.x, c.y, "#")
		if _connected(room):
			return
		for c in cells:
			t.set_cell(c.x, c.y, ".")

func _near_something(room, cells: Array) -> bool:
	var pts: Array = []
	for d in room.doors.get_children():
		pts.append(room.pos_cell(d.spawn_point()))
	for g in [room.props, room.npcs, room.anchor_root, room.spawns]:
		for n in g.get_children():
			if n is Node2D:
				pts.append(room.pos_cell(n.position))
	for c in cells:
		for p in pts:
			if abs(c.x - p.x) <= 1 and abs(c.y - p.y) <= 1:
				return true
	return false

## Toutes les portes restent accessibles entre elles.
func _connected(room) -> bool:
	var t: TileGrid = room.tiles
	var targets: Array = []
	for d in room.doors.get_children():
		targets.append(room.pos_cell(d.spawn_point()))
	if targets.size() < 2:
		return true
	var start: Vector2i = targets[0]
	var seen = {start: true}
	var q: Array = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for dlt in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dlt
			if not seen.has(n) and t.is_walkable(n.x, n.y):
				seen[n] = true
				q.append(n)
	for c in targets:
		if not seen.has(c):
			return false
	return true
