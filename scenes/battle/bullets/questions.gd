## Le Nageur Immobile : aucune attaque. Des bulles lentes et inoffensives montent.
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 8:
		out.append({"t": 0.4 + i * 0.6, "x": fmod(i * 0.31 + 0.15, 1.0)})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.shape = "circle"
	b.radius = 4
	b.color = Color(0.7, 0.85, 1.0, 0.5)
	b.damage = 0
	b.position = Vector2(box.position.x + 10 + ev["x"] * (box.size.x - 20), box.end.y - 6)
	b.vel = Vector2(0, -40)
	add_bullet(b)
	b.damage = 0
