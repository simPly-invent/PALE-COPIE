## Pluie de barres qui tombent (Néon Clignotant, Moquette Humide...).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 18:
		out.append({"t": 0.3 + i * 0.3, "x": fmod(i * 0.37 + 0.1, 1.0)})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.size = Vector2(6, 18)
	b.position = Vector2(box.position.x + 10 + ev["x"] * (box.size.x - 20) + float(ev.get("shift", 0)), box.position.y - 10)
	b.vel = Vector2(0, 150)
	add_bullet(b)
