## Lignes horizontales avec un trou à traverser (Chaise de Bureau Vide, Carrelage...).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 6:
		out.append({"t": 0.4 + i * 0.9, "gap": [0.2, 0.7, 0.45, 0.1, 0.8, 0.5][i], "left": i % 2 == 0})
	return out

func spawn(ev: Dictionary) -> void:
	var gap_y: float = box.position.y + 16 + ev["gap"] * (box.size.y - 32) + float(ev.get("shift", 0)) * 0.5
	var step = 14.0
	var y = box.position.y + 6
	while y < box.end.y - 4:
		if abs(y - gap_y) > 22:
			var b = Bullet.new()
			b.size = Vector2(10, 10)
			var left: bool = ev["left"]
			b.position = Vector2(box.position.x - 10 if left else box.end.x + 10, y)
			b.vel = Vector2(130 if left else -130, 0)
			add_bullet(b)
		y += step
