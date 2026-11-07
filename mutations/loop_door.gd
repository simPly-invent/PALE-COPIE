## Palier 6 — Impossibilité : une porte ramène dans la même salle, par le même côté
## (« sortir par la droite fait rentrer par la droite »). Un panneau « ↺ » l'indique.
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var cands: Array = []
	for d in room.doors.get_children():
		if d is Door and d.def.get("loopable", d.def.get("to", "") == "@prev") and not d.def.get("fixed", false):
			cands.append(d)
	if cands.is_empty():
		return
	cands.sort_custom(func(a, b): return str(a.name) < str(b.name))
	var door: Door = cands[rng.randi_range(0, cands.size() - 1)]
	door.def = door.def.duplicate(true)
	door.def["to"] = "@self"
	door.def["to_door"] = door.def.get("id", "")
	door.def["label"] = "↺"
	door.set_meta("loop", true)
