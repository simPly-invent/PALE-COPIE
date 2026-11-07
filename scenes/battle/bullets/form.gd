## Le formulaire d'accueil : des lignes à remplir descendent, avec des cases vides où passer
## (la Réceptionniste).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	var holes = [0.15, 0.6, 0.35, 0.8, 0.5, 0.25, 0.7]
	for i in holes.size():
		out.append({"t": 0.3 + i * 0.8, "hole": holes[i]})
	return out

func spawn(ev: Dictionary) -> void:
	var hole_x: float = box.position.x + 20 + ev["hole"] * (box.size.x - 40) + float(ev.get("shift", 0))
	var x = box.position.x + 8
	while x < box.end.x - 6:
		if abs(x - hole_x) > 24:
			var b = Bullet.new()
			b.shape = "text"
			b.text = "_"
			b.size = Vector2(14, 16)
			b.position = Vector2(x, box.position.y - 6)
			b.vel = Vector2(0, 85)
			add_bullet(b)
		x += 14
