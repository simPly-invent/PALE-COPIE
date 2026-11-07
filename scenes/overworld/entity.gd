## L'Entité : silhouette trop grande, saccadée. Elle s'annonce toujours par le même son.
## "pass" : elle traverse la salle au loin ; si le joueur bouge pendant qu'elle est visible, combat (fuite).
## "chase" : elle poursuit le joueur (zone 3).
extends Node2D

var mode = "pass"
var opts: Dictionary = {}
var sprite: Sprite2D
var _t = 0.0
var _phase = 0
var _from = Vector2.ZERO
var _to = Vector2.ZERO
var _jerk = 0.0
var _triggered = false

func _ready() -> void:
	name = "Entity"
	sprite = Sprite2D.new()
	sprite.texture = Assets.tex("boss_entity")
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	sprite.modulate.a = 0.0
	add_child(sprite)
	AudioManager.sfx("entity")
	var room: Room = get_parent()
	var size: Vector2 = room.pixel_size()
	var top = 4 * TileGrid.TILE + 10
	if mode == "pass":
		_from = Vector2(-80, top)
		_to = Vector2(size.x + 80, top)
		if randf() < 0.5:
			var tmp = _from
			_from = _to
			_to = tmp
		sprite.scale = Vector2(0.7, 0.7)
	else:
		var door_name: String = opts.get("from_door", "")
		var d: Door = room.find_door(door_name) if door_name != "" else null
		_from = d.spawn_point() if d else Vector2(40, size.y / 2)
		sprite.scale = Vector2(0.8, 0.8)
	position = _from

func _process(delta: float) -> void:
	_t += delta
	var room: Room = get_parent()
	if mode == "pass":
		if _t < 2.5:
			return   # le son d'abord, la silhouette ensuite
		var k = clampf((_t - 2.5) / 9.0, 0.0, 1.0)
		_jerk -= delta
		if _jerk <= 0:
			_jerk = randf_range(0.08, 0.35)
			position = _from.lerp(_to, k) + Vector2(0, randf_range(-3, 3))
		sprite.modulate.a = 0.85 if k < 1.0 else 0.0
		var p = World.player
		if p and p.moving and sprite.modulate.a > 0 and _t > 3.2 and not _triggered and not GameState.is_locked():
			_triggered = true
			_start_battle()
		if k >= 1.0:
			if not _triggered:
				GameState.inc_flag("entity_watched")
			queue_free()
	else:
		var delay = float(opts.get("delay", 2.0))
		if _t < delay:
			return
		sprite.modulate.a = 0.9
		var p = World.player
		if p == null or GameState.is_locked():
			return
		_jerk -= delta
		if _jerk <= 0:
			_jerk = randf_range(0.12, 0.3)
			var dir = (p.global_position - position)
			var step: float = float(opts.get("speed", 95.0)) * _jerk * randf_range(0.6, 1.5)
			if dir.length() > step:
				position += dir.normalized() * step
			else:
				position = p.global_position
		if position.distance_to(p.global_position) < 22 and not _triggered:
			_triggered = true
			_start_battle()

func _start_battle() -> void:
	var res: Dictionary = await BattleManager.start("entity", {"entity": true})
	if res.get("outcome", "") == "fled" and mode == "chase":
		# on a réussi à fuir : elle reprend un peu plus loin
		_triggered = false
		_t = 0.0
		position = _from
	elif mode == "pass" and is_instance_valid(self):
		queue_free()
