## Palier 2 — Détail : certains petits objets disparaissent.
extends Mutation

func apply(room, rng: RandomNumberGenerator) -> void:
	var cands: Array = room.all_props().filter(func(p): return (p.has_tag("small") or p.has_tag("decor")) and not p.has_tag("keep") and not p.monitorable)
	cands.sort_custom(func(a, b): return str(a.name) < str(b.name))
	var order: Array = []
	for c in cands:
		order.append([rng.randf(), c])
	order.sort_custom(func(a, b): return a[0] < b[0])
	var n = int(floor(order.size() * (0.2 + 0.45 * intensity(room))))
	for k in n:
		var p: Node = order[k][1]
		p.get_parent().remove_child(p)
		p.free()
