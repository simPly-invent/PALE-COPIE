## Colonnes de lumière qui s'allument après un avertissement (Gardien des Néons, Phare Allumé).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	var cols = [0.1, 0.5, 0.9, 0.3, 0.7, 0.2, 0.6, 0.85, 0.4]
	for i in cols.size():
		out.append({"t": 0.3 + i * 0.6, "x": cols[i]})
	return out

func spawn(ev: Dictionary) -> void:
	var b = Bullet.new()
	b.size = Vector2(26, box.size.y)
	b.color = Color(0.9, 1.0, 0.85)
	b.position = Vector2(box.position.x + 16 + ev["x"] * (box.size.x - 32) + float(ev.get("shift", 0)), box.get_center().y)
	b.warn = 0.6
	b.life = 1.0
	add_bullet(b)
