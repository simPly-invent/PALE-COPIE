## Palier 5 — Sens : les textes deviennent illisibles ou faux (« SORTIE » -> « SORTE » -> « S RT »).
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	room.text_decay = max(room.text_decay, 0.3 + 0.7 * intensity(room))
