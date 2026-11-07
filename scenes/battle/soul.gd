## L'âme (cœur) du joueur dans la boîte de combat.
## Modes : normal, heavy (gravité, zone 3), reflect (contrôles inversés en bas, zone 5),
## erased (invisible si immobile, zone 6).
class_name Soul
extends Node2D

const SPEED := 150.0
const RADIUS := 6.0

var mode = "normal"
var box: Rect2
var sprite: Sprite2D
var invuln = 0.0
var moving = false
var vel_y = 0.0
var grounded = false
var frozen = false

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Assets.tex("soul_blue" if mode == "heavy" else "soul_red")
	sprite.scale = Vector2(0.55, 0.55)
	add_child(sprite)

func _process(delta: float) -> void:
	if frozen:
		return
	var dir = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if mode == "reflect" and position.y > box.get_center().y:
		dir = -dir
	moving = dir != Vector2.ZERO
	if mode == "heavy":
		position.x += dir.x * SPEED * delta
		vel_y += 520.0 * delta
		if grounded and Input.is_action_pressed("move_up"):
			vel_y = -260.0
		if not Input.is_action_pressed("move_up") and vel_y < -60.0:
			vel_y = -60.0
		position.y += vel_y * delta
	else:
		position += dir.normalized() * SPEED * delta
	var inner = box.grow(-RADIUS - 2)
	position.x = clampf(position.x, inner.position.x, inner.end.x)
	grounded = position.y >= inner.end.y - 0.5
	if grounded:
		vel_y = min(vel_y, 0.0)
	position.y = clampf(position.y, inner.position.y, inner.end.y)
	if invuln > 0:
		invuln -= delta
		sprite.visible = fmod(invuln, 0.2) > 0.1
	else:
		sprite.visible = true
	if mode == "erased" and not moving:
		sprite.modulate.a = move_toward(sprite.modulate.a, 0.0, delta * 3.0)
	else:
		sprite.modulate.a = 1.0

func is_hidden() -> bool:
	return mode == "erased" and sprite.modulate.a < 0.2
