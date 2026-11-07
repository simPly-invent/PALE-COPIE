## Projectiles qui cherchent l'âme ; ils la perdent si elle est invisible (zone 6).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 8:
		out.append({"t": 0.4 + i * 0.65, "side": i % 4})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.size = Vector2(10, 10)
	b.color = Color(0.85, 0.85, 0.95)
	var corners = [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	b.position = corners[ev["side"]] + Vector2(float(ev.get("shift", 0)), 0)
	b.vel = (box.get_center() - b.position).normalized() * 90
	b.homing = 2.5
	b.life = 4.0
	add_bullet(b)
