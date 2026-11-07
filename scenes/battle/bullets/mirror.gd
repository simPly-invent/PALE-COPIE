## La Copie : les projectiles reprennent les mouvements du joueur avec un temps de retard.
extends BulletPattern

var _trail: Array = []
var _ghost: Bullet

func original_events() -> Array:
	var out: Array = [{"t": 0.0, "kind": "ghost"}]
	for i in 8:
		out.append({"t": 0.8 + i * 0.6, "kind": "drop", "x": fmod(i * 0.41, 1.0)})
	return out

func spawn(ev: Dictionary) -> void:
	if ev.get("kind") == "ghost":
		_ghost = Bullet.new()
		_ghost.shape = "circle"
		_ghost.radius = 7
		_ghost.color = Color(0.75, 0.75, 0.8)
		_ghost.position = box.get_center()
		_ghost.life = duration + 1
		add_bullet(_ghost)
	else:
		var b = Bullet.new()
		b.size = Vector2(8, 8)
		b.position = Vector2(box.position.x + 10 + ev["x"] * (box.size.x - 20) + float(ev.get("shift", 0)), box.position.y)
		b.vel = Vector2(0, 110)
		add_bullet(b)

func _process(delta: float) -> void:
	super._process(delta)
	if soul:
		_trail.append(soul.position)
	if _ghost and is_instance_valid(_ghost) and _trail.size() > 40:
		_ghost.position = _trail.pop_front()
