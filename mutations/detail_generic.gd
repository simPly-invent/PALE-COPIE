## Palier 2 — Détail : les petits objets deviennent des formes génériques
## (les livres de l'étagère deviennent des blocs unis).
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var cands: Array = room.all_props().filter(func(p): return p.has_tag(params.get("tag", "small")))
	_shuffle(cands, rng)
	var n = int(ceil(cands.size() * (0.4 + 0.6 * intensity(room))))
	for k in min(n, cands.size()):
		cands[k].make_generic()

static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
