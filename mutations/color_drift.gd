## Palier 1 — Couleur : désaturation, teinte qui tire vers le jaune.
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	var i = intensity(room)
	room.tint["desaturate"] = max(room.tint["desaturate"], 0.2 + 0.6 * i)
	room.tint["yellow_shift"] = max(room.tint["yellow_shift"], 0.15 + 0.75 * i)
