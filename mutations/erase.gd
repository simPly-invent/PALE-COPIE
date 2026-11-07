## Palier 7 — Effacement : les murs restent, tout le reste disparaît ; seule l'ancre subsiste.
## Une moquette jaune à l'infini et une chaise rouge. (Les portes restent, à peine visibles.)
extends Mutation

func apply(room, _rng: RandomNumberGenerator) -> void:
	for group in [room.props, room.npcs]:
		for c in group.get_children():
			if c.is_in_group("save_phone") or (c is Node and c.get("def") is Dictionary and c.def.get("survives_erase", false)):
				continue
			group.remove_child(c)
			c.free()
	room.tiles.floor_tex = Assets.tex("tiles/carpet_yellow")
	room.tiles.wall_tex = Assets.tex("tiles/wall_yellow")
	room.tiles.alt_floor_tex = null
	room.erased = true
	for d in room.doors.get_children():
		d.modulate = Color(1, 1, 1, 0.35)
