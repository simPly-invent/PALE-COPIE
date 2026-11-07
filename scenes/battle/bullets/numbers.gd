## Numéros de chambres qui volent (Concierge, Clé 404).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	var nums = ["101", "103", "107", "115", "131", "404", "163"]
	for i in 14:
		out.append({"t": 0.3 + i * 0.4, "n": nums[i % nums.size()], "y": fmod(i * 0.29, 1.0), "left": i % 3 != 0})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.shape = "text"
	b.text = ev["n"]
	b.size = Vector2(36, 18)
	var left: bool = ev["left"]
	b.position = Vector2(box.position.x - 20 if left else box.end.x + 20, box.position.y + 12 + ev["y"] * (box.size.y - 24) + float(ev.get("shift", 0)) * 0.4)
	b.vel = Vector2(150 if left else -150, 0)
	add_bullet(b)
