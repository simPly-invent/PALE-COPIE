## Palier 6 — Impossibilité : la salle est plus grande dedans que dehors.
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	var h: int = room.tiles.height()
	var count = 2 + int(intensity(room) * 4.0)
	room.insert_rows(h / 2 + 1, count)
	room.set_meta("bigger_inside", true)
