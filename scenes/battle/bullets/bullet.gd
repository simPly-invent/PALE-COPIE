## Projectile simple : forme dessinée, vitesse, collision par distance avec l'âme.
class_name Bullet
extends Node2D

var vel = Vector2.ZERO
var accel = Vector2.ZERO
var radius = 6.0
var size = Vector2(12, 12)
var shape = "rect"          # rect, circle, text
var color = Color.WHITE
var text = ""
var life = 8.0
var damage = 3
var homing = 0.0
var soul: Node2D
var warn = 0.0              # durée d'avertissement avant d'être dangereux

func _process(delta: float) -> void:
	life -= delta
	if life <= 0:
		queue_free()
		return
	if warn > 0:
		warn -= delta
		queue_redraw()
		return
	if homing > 0 and soul and not soul.is_hidden():
		vel = vel.lerp((soul.position - position).normalized() * vel.length(), homing * delta)
	vel += accel * delta
	position += vel * delta
	queue_redraw()

func hits(p: Vector2, r: float) -> bool:
	if warn > 0:
		return false
	if shape == "circle":
		return position.distance_to(p) < radius + r
	var rect = Rect2(position - size / 2.0, size)
	return rect.grow(r * 0.7).has_point(p)

func _draw() -> void:
	var c = color
	if warn > 0:
		c = Color(color.r, color.g, color.b, 0.3 if fmod(warn, 0.2) > 0.1 else 0.1)
	match shape:
		"circle":
			draw_circle(Vector2.ZERO, radius, c)
		"text":
			draw_string(UI.font(), Vector2(-size.x / 2.0, size.y / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y), c)
		_:
			draw_rect(Rect2(-size / 2.0, size), c)
