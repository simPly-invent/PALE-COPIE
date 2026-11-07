## Palier 1 — Couleur : contrastes aplatis.
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	room.tint["flatten"] = max(room.tint["flatten"], 0.25 + 0.7 * intensity(room))
