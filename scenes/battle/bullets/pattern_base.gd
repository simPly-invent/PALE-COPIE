## Pattern d'attaque. Chaque pattern a un « pattern original » (liste d'événements) qui est
## rejoué avec des erreurs de copie : décalage, doublon, trou (section 6.2).
## Les scripts concrets surchargent original_events() et spawn(ev).
class_name BulletPattern
extends Node2D

signal done

var box: Rect2
var soul: Node2D
var enemy: Dictionary = {}
var duration = 6.0
var damage = 3
var turn = 0
var rng = RandomNumberGenerator.new()
var _events: Array = []
var _t = 0.0
var _running = false
var bullets: Array = []

## Le joueur qui a mémorisé l'original peut anticiper : l'original est fixe pour un ennemi donné.
func original_events() -> Array:
	return []

func spawn(_ev: Dictionary) -> void:
	pass

func play(error_level: float) -> void:
	rng.seed = JsonUtil.hash_seed([enemy.get("id", ""), get_script().resource_path, turn, GameState.game_seed])
	var orig = original_events()
	_events = []
	for ev in orig:
		var e: Dictionary = ev.duplicate(true)
		var r = rng.randf()
		if r < error_level * 0.25:
			continue                              # trou
		if r < error_level * 0.6:
			e["t"] = float(e["t"]) + rng.randf_range(-0.25, 0.35) * (1.0 + error_level)   # décalage
			e["shift"] = rng.randf_range(-30, 30) * error_level
		_events.append(e)
		if rng.randf() < error_level * 0.35:
			var dup: Dictionary = e.duplicate(true)  # doublon
			dup["t"] = float(e["t"]) + rng.randf_range(0.1, 0.4)
			dup["shift"] = float(e.get("shift", 0.0)) + rng.randf_range(-50, 50)
			_events.append(dup)
	_events.sort_custom(func(a, b): return a["t"] < b["t"])
	_running = true

func _process(delta: float) -> void:
	if not _running:
		return
	_t += delta
	while not _events.is_empty() and float(_events[0]["t"]) <= _t:
		spawn(_events.pop_front())
	if _t >= duration:
		_running = false
		done.emit()

func add_bullet(b: Bullet) -> Bullet:
	b.soul = soul
	b.damage = damage
	add_child(b)
	bullets.append(b)
	return b

func check_hit(p: Vector2, r: float) -> int:
	for b in bullets:
		if is_instance_valid(b) and b.hits(p, r):
			return b.damage
	return 0

func cleanup() -> void:
	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()
