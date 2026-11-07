## Le héros. Déplacement 4 directions, interaction, traînée fantôme (smear) à faible fidélité.
## Maintenir Annuler (X/Maj) bloque l'orientation : on peut marcher à reculons.
class_name Player
extends CharacterBody2D

const SPEED := 130.0
const FRAME_W := 20
const FRAME_H := 26
const ROWS := {"down": 0, "up": 1, "left": 2, "right": 3}

var facing = "down"
var anim: AnimatedSprite2D
var reach: Area2D
var reach_shape: CollisionShape2D
var flashlight: PointLight2D
var moving = false
var last_move_dir = Vector2.ZERO
var _step_t = 0.0
var _smear_t = 0.0
var _walked = 0.0

func _ready() -> void:
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(18, 10)
	shape.shape = rect
	shape.position = Vector2(0, -5)
	add_child(shape)
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = _build_frames()
	anim.scale = Vector2(2, 2)
	anim.offset = Vector2(0, -FRAME_H / 2.0)
	anim.animation = "down"
	add_child(anim)
	reach = Area2D.new()
	reach.collision_layer = 0
	reach.collision_mask = 2
	reach.monitorable = false
	reach_shape = CollisionShape2D.new()
	var rr = RectangleShape2D.new()
	rr.size = Vector2(22, 22)
	reach_shape.shape = rr
	reach.add_child(reach_shape)
	add_child(reach)
	flashlight = PointLight2D.new()
	flashlight.texture = FxManager.light_texture()
	flashlight.texture_scale = 3.0
	flashlight.energy = 1.2
	flashlight.color = Color(1.0, 0.95, 0.8)
	flashlight.position = Vector2(0, -20)
	flashlight.enabled = false
	add_child(flashlight)
	_update_reach()

func _build_frames() -> SpriteFrames:
	var sf = SpriteFrames.new()
	sf.remove_animation("default")
	var tex = Assets.tex("player_walk")
	for dir in ROWS:
		sf.add_animation(dir)
		sf.set_animation_speed(dir, 6.0)
		sf.set_animation_loop(dir, true)
		for i in 4:
			var at = AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * FRAME_W, ROWS[dir] * FRAME_H, FRAME_W, FRAME_H)
			sf.add_frame(dir, at)
	return sf

func face(dir: String) -> void:
	facing = dir
	anim.animation = dir
	anim.frame = 0
	_update_reach()

func _update_reach() -> void:
	var off = Vector2.ZERO
	match facing:
		"down": off = Vector2(0, 14)
		"up": off = Vector2(0, -26)
		"left": off = Vector2(-20, -8)
		"right": off = Vector2(20, -8)
	reach_shape.position = off

func _physics_process(delta: float) -> void:
	if GameState.is_locked():
		moving = false
		anim.stop()
		anim.frame = 0
		return
	var dir = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	moving = dir != Vector2.ZERO
	if moving:
		dir = dir.normalized()
		last_move_dir = dir
		if not Input.is_action_pressed("cancel"):
			var nf = facing
			if abs(dir.x) > abs(dir.y) + 0.01:
				nf = "right" if dir.x > 0 else "left"
			elif abs(dir.y) > 0:
				nf = "down" if dir.y > 0 else "up"
			if nf != facing:
				facing = nf
				anim.animation = nf
				_update_reach()
		velocity = dir * SPEED
		var before = global_position
		move_and_slide()
		var dist = global_position.distance_to(before)
		_walked += dist
		World.on_player_walked(dist)
		if not anim.is_playing():
			anim.play(facing)
		_step_t -= delta
		if _step_t <= 0 and dist > 0.1:
			_step_t = 0.32
			World.footstep()
		_smear(delta)
		GameState.still_time = 0.0
	else:
		velocity = Vector2.ZERO
		anim.stop()
		anim.frame = 0
		GameState.still_time += delta
	flashlight.enabled = World.current_room != null and World.current_room.dark and (GameState.has_item("flashlight") or GameState.has_item("lumi_lamp"))
	if flashlight.enabled:
		var infinite = GameState.has_item("lumi_lamp")
		if not infinite and moving:
			GameState.battery = max(0.0, GameState.battery - delta * 1.2)
		var b = 1.0 if infinite else GameState.battery / 100.0
		flashlight.texture_scale = 1.0 + 2.6 * b
		flashlight.energy = 0.4 + 0.9 * b

func _smear(delta: float) -> void:
	var frames = FxManager.smear_frames()
	if frames <= 0:
		return
	_smear_t -= delta
	if _smear_t > 0:
		return
	_smear_t = 1.0 / 20.0
	var ghost = Sprite2D.new()
	ghost.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	ghost.scale = anim.scale
	ghost.offset = anim.offset
	ghost.global_position = global_position
	ghost.modulate = Color(1, 1, 0.85, 0.45)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tw = ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, frames / 30.0)
	tw.tween_callback(ghost.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if GameState.is_locked():
		return
	if event.is_action_pressed("confirm"):
		get_viewport().set_input_as_handled()
		_try_interact()
	elif event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		World.open_camcorder()

func _try_interact() -> void:
	var best: Node = null
	var best_d = 99999.0
	for a in reach.get_overlapping_areas():
		if a.has_method("interact") and a.monitorable and a.has_method("can_interact") and a.can_interact():
			var d = a.global_position.distance_to(reach.global_position + reach_shape.position)
			if d < best_d:
				best_d = d
				best = a
	if best:
		GameState.lock("interact")
		await best.interact(self)
		GameState.unlock("interact")

## Marche à reculons : orientation opposée au dernier déplacement.
func is_walking_backwards() -> bool:
	var f = Vector2.ZERO
	match facing:
		"down": f = Vector2.DOWN
		"up": f = Vector2.UP
		"left": f = Vector2.LEFT
		"right": f = Vector2.RIGHT
	return last_move_dir != Vector2.ZERO and f.dot(last_move_dir) < -0.5
