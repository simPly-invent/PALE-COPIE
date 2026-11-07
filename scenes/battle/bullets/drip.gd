## Gouttes qui rebondissent (Moquette Humide, Bouée, Maître-Nageur).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 12:
		out.append({"t": 0.3 + i * 0.45, "x": fmod(i * 0.53 + 0.2, 1.0), "vx": [-40, 40, 0, -20, 20][i % 5]})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.shape = "circle"
	b.radius = 5
	b.color = Color(0.6, 0.8, 1.0)
	b.position = Vector2(box.position.x + 12 + ev["x"] * (box.size.x - 24) + float(ev.get("shift", 0)), box.position.y + 4)
	b.vel = Vector2(ev["vx"], 20)
	b.accel = Vector2(0, 240)
	add_bullet(b)

func _process(delta: float) -> void:
	super._process(delta)
	for b in bullets:
		if is_instance_valid(b) and b.position.y > box.end.y - 6 and b.vel.y > 0:
			b.vel.y = -b.vel.y * 0.7
