## Compagnon qui suit le joueur (Lumi, le petit néon de la zone 3).
## Dans le noir, sa lumière baisse ; près d'un néon allumé, elle remonte. À 0, il s'éteint.
extends Node2D

var id = ""
var sprite: Sprite2D
var light: PointLight2D
var charge = 100.0
var _trail: Array = []
var _warned = false

func setup(fid: String) -> void:
	id = fid
	name = "Follower"
	sprite = Sprite2D.new()
	sprite.texture = Assets.tex(fid)
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	add_child(sprite)
	light = PointLight2D.new()
	light.texture = FxManager.light_texture()
	light.texture_scale = 2.2
	light.color = Color(0.85, 1.0, 0.8)
	light.position = Vector2(0, -16)
	add_child(light)

func reset_trail() -> void:
	_trail.clear()

func _process(delta: float) -> void:
	var p = World.player
	if p == null:
		return
	_trail.append(p.global_position)
	if _trail.size() > 14:
		global_position = global_position.lerp(_trail.pop_front() + Vector2(0, -2), 0.5)
	sprite.position.y = sin(Time.get_ticks_msec() / 300.0) * 2.0 - 4.0
	if id != "lumi" or World.current_room == null:
		return
	# quête « Lumière » : garder Lumi allumé à travers le parking
	if World.current_room.dark and not GameState.is_locked():
		var near_light = false
		for prop in World.current_room.all_props():
			if prop.light and prop.global_position.distance_to(global_position) < 110:
				near_light = true
				break
		charge = clampf(charge + (25.0 if near_light else -3.2) * delta, 0.0, 100.0)
		if charge < 30 and not _warned:
			_warned = true
			DialogueManager.say(["* Lumi grésille. « J'ai froid... il faut une lumière... »"])
		if charge > 50:
			_warned = false
		if charge <= 0:
			_go_out()
	light.energy = 0.2 + charge / 100.0
	light.texture_scale = 1.0 + 1.6 * charge / 100.0

func _go_out() -> void:
	charge = 100.0
	GameState.set_flag("lumi.failures", int(GameState.get_flag("lumi.failures", 0)) + 1)
	await DialogueManager.say(["* Lumi s'est éteint.", "* ...", "* Il se rallume tout doucement, très loin derrière toi.", "* « On recommence ? Pas trop vite, cette fois. »"])
	World.goto_room("z3_ramp", 0, "", "lumi")
