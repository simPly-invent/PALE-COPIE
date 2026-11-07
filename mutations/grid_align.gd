## Palier 3 — Répétition : les objets se rangent en grille.
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	var step = 2 * TileGrid.TILE
	for p in room.all_props():
		if p.monitorable or p.def.get("on_wall", false):
			continue
		var c: Vector2i = room.pos_cell(p.position)
		var nx = int(round(c.x / 2.0)) * 2 + 0.5
		var target = Vector2(nx * TileGrid.TILE, p.position.y)
		var tc: Vector2i = room.pos_cell(target)
		if room.tiles.get_cell(tc.x, tc.y) == ".":
			p.position = target
