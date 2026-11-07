## Cercle de projectiles qui se referme sur l'âme (Fax Fantôme, Écho...).
extends BulletPattern

func original_events() -> Array:
	var out: Array = []
	for i in 5:
		out.append({"t": 0.4 + i * 1.1, "n": 10, "rot": i * 0.3})
	return out

func spawn(ev: Dictionary) -> void:
	var c = soul.position
	var n: int = ev["n"]
	for i in n:
		if i == int(abs(float(ev.get("shift", 0)))) % n:
			continue
		var a: float = TAU * i / n + ev["rot"]
		var b = Bullet.new()
		b.shape = "circle"
		b.radius = 5
		b.position = c + Vector2(cos(a), sin(a)) * 120
		b.vel = -Vector2(cos(a), sin(a)) * 70
		b.life = 3.0
		add_bullet(b)
