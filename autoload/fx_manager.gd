## Paramètres des shaders selon la fidélité de la salle (section 8.1).
extends Node

## Palette jaune-beige à 8 couleurs, du sombre au clair.
const MEMORY_PALETTE := [
	Color("#1b1912"), Color("#4a4128"), Color("#7a6a3a"), Color("#a8955a"),
	Color("#c9b77a"), Color("#dccb92"), Color("#ebe0b4"), Color("#f7f0d6"),
]

var material: ShaderMaterial
var fidelity = 100.0
var target_fidelity = 100.0
var override_strength = -1.0     # le lecteur VHS force un effet fort
var _glitch_t = 3.0
var _glitch_left = 0.0
var _light_tex: Texture2D
var _rng = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func attach(rect: ColorRect) -> void:
	material = ShaderMaterial.new()
	material.shader = preload("res://shaders/post_process.gdshader")
	var pal = PackedVector3Array()
	for c in MEMORY_PALETTE:
		pal.append(Vector3(c.r, c.g, c.b))
	material.set_shader_parameter("mem_palette", pal)
	rect.material = material
	_apply()

func reduced() -> bool:
	return GameState.meta.get("options", {}).get("reduced_fx", false)

func set_fidelity(f: float, instant := false) -> void:
	target_fidelity = f
	if instant:
		fidelity = f
	_apply()

func _process(delta: float) -> void:
	if abs(fidelity - target_fidelity) > 0.01:
		fidelity = move_toward(fidelity, target_fidelity, delta * 40.0)
		_apply()
	_update_glitch(delta)

## Courbes : tout est progressif de F = 100 à F = 5.
func _apply() -> void:
	if material == null:
		return
	var k = clampf((100.0 - fidelity) / 95.0, 0.0, 1.0)   # 0 à F=100, 1 à F=5
	var p = DegradationManager.palier_of(fidelity)
	var vhs = lerpf(0.18, 1.0, k)
	if override_strength >= 0:
		vhs = override_strength
	material.set_shader_parameter("vhs_strength", vhs)
	material.set_shader_parameter("chroma", lerpf(0.6, 2.2, k))
	material.set_shader_parameter("scanlines", 1.0)
	material.set_shader_parameter("tracking", 0.0 if reduced() else 1.0)
	material.set_shader_parameter("saturation", lerpf(1.0, 0.35, k))
	material.set_shader_parameter("palette_amount", clampf((90.0 - fidelity) / 85.0, 0.0, 1.0) * 0.85)
	material.set_shader_parameter("palette_count", int(round(lerpf(8.0, 3.0, clampf((90.0 - fidelity) / 85.0, 0.0, 1.0)))))
	material.set_shader_parameter("dither_strength", clampf((80.0 - fidelity) / 75.0, 0.0, 1.0) * 0.8)
	material.set_shader_parameter("blur_strength", clampf((30.0 - fidelity) / 25.0, 0.0, 1.0) if p >= 5 else 0.0)
	material.set_shader_parameter("vignette_strength", lerpf(0.15, 0.6, k))

func _update_glitch(delta: float) -> void:
	if material == null:
		return
	var p = DegradationManager.palier_of(fidelity)
	if p < 6 or reduced():
		material.set_shader_parameter("band_h", 0.0)
		return
	if _glitch_left > 0:
		_glitch_left -= delta
		if _glitch_left <= 0:
			material.set_shader_parameter("band_h", 0.0)
		return
	_glitch_t -= delta
	if _glitch_t <= 0:
		_glitch_t = _rng.randf_range(1.5, 5.0)
		_glitch_left = _rng.randf_range(0.08, 0.22)
		material.set_shader_parameter("band_y", _rng.randf_range(0.0, 0.9))
		material.set_shader_parameter("band_h", _rng.randf_range(0.03, 0.12))
		material.set_shader_parameter("band_offset", _rng.randf_range(-8.0, 8.0))

## Smear : nombre d'images de traînée fantôme (0 à haute fidélité, 1 à 2 en bas).
func smear_frames() -> int:
	if fidelity > 45:
		return 0
	return 1 if fidelity > 20 else 2

func shake(t: float) -> void:
	if reduced():
		t *= 0.3
	World.shake(t)

func light_texture() -> Texture2D:
	if _light_tex:
		return _light_tex
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	_light_tex = gt
	return gt
