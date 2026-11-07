## Palier 5 — Sens : des panneaux contradictoires apparaissent.
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var t: TileGrid = room.tiles
	for attempt in 6:
		var x = rng.randi_range(2, t.width() - 3)
		var y = rng.randi_range(3, t.height() - 3)
		if t.get_cell(x, y) == "." and t.get_cell(x, y - 1) == "#":
			var lbl: String = ["SORTIE →", "← SORTIE", "SORTIE ↑", "PAS ICI", "ICI"][rng.randi_range(0, 4)]
			room.add_prop({"id": "false_sign_%d" % attempt, "sprite": "sign_sortie", "pos": [x, y - 1], "solid": false, "on_wall": true, "label": lbl, "label_size": 14, "tags": ["text", "false"]})
			return
