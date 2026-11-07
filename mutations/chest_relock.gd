## Palier 6 — Impossibilité : un coffre ouvert peut réapparaître fermé, au contenu dégradé
## (« Barre de céréales » -> « Barre » -> « ar e »).
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var level = 1 + int(intensity(room) * 2.0)
	room.chest_relock_level = level
	for c in room.props.get_children():
		if c is Chest:
			c.relock(level, rng)
