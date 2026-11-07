## Palier 3 — Répétition : un élément est dupliqué et aligné (trois lampes au lieu d'une).
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var tag: String = room.source.data.get("mutation_params", {}).get(id, {}).get("tag", params.get("tag", "repeatable"))
	var cands: Array = room.all_props().filter(func(p): return p.has_tag(tag) and not p.has_tag("dup"))
	if cands.is_empty():
		return
	cands.sort_custom(func(a, b): return str(a.name) < str(b.name))
	var count = int(room.source.data.get("mutation_params", {}).get(id, {}).get("all", 0))
	var targets: Array = cands if count == 1 else [cands[rng.randi_range(0, cands.size() - 1)]]
	var extra_rng = rng.randi_range(0, 1)
	for src in targets:
		var n = 1 + int(floor(intensity(room) * 3.0)) + extra_rng
		if room.source.data.get("mutation_params", {}).get(id, {}).get("per_depth", false):
			n = room.depth + extra_rng
		var w: int = room.tiles.width()
		var step = 2 * TileGrid.TILE
		var placed = 0
		for k in range(1, 12):
			if placed >= n:
				break
			for sgn in [1, -1]:
				if placed >= n:
					break
				var pos: Vector2 = src.position + Vector2(step * k * sgn, 0)
				var c: Vector2i = room.pos_cell(pos)
				if c.x < 1 or c.x >= w - 1:
					continue
				var under: String = room.tiles.get_cell(c.x, c.y)
				if not src.def.get("on_wall", false) and under != ".":
					continue
				var d: Prop = src.duplicate_prop(room, Vector2(step * k * sgn, 0))
				d.name = "%s_dup%d" % [src.name, placed]
				room.props.add_child(d)
				placed += 1
