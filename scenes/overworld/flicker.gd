## Clignotement irrégulier d'un néon.
extends Node

var light: PointLight2D
var target: CanvasItem
var _t = 0.0
var _rng = RandomNumberGenerator.new()
var _base = 1.0

func _ready() -> void:
	_rng.randomize()
	if light:
		_base = light.energy
	_t = _rng.randf_range(0.5, 3.0)

func _process(delta: float) -> void:
	_t -= delta
	if _t > 0:
		return
	var off = _rng.randf() < 0.5
	if light:
		light.energy = _base * (0.15 if off else 1.0)
	if target:
		target.modulate.a = 0.6 if off else 1.0
	_t = _rng.randf_range(0.03, 0.12) if off else _rng.randf_range(0.4, 4.0)
