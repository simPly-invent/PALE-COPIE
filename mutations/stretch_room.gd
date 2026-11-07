## Palier 4 — Géométrie : la pièce s'étire (le couloir fait 2 fois sa longueur).
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var w: int = room.tiles.width()
	var count = int(round((w - 2) * (0.4 + 0.6 * intensity(room))))
	if count <= 0:
		return
	var at = w / 2 + rng.randi_range(-1, 1)
	room.insert_columns(at, count)
