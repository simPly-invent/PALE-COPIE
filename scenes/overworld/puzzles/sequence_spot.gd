## Place de parking à éclairer dans l'ordre (énigme « Les phares »).
extends Interactable

var lit = false

func default_sprite() -> String:
	return "hazard"

func default_solid() -> bool:
	return false

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	if d.has("label"):
		var l = UI.label(d["label"], 16, Color(0.9, 0.9, 0.6))
		l.position = Vector2(-14, -sprite_height() - 20)
		add_child(l)
	var pid: String = d.get("puzzle", "")
	if GameState.get_flag("puzzle." + pid, false):
		_set_lit(true)

func _set_lit(v: bool) -> void:
	lit = v
	if sprite:
		sprite.modulate = Color(1.4, 1.4, 1.0) if v else Color(0.5, 0.5, 0.5)

func interact(_player: Node) -> void:
	var pid: String = def.get("puzzle", "")
	var pd = Puzzles.data(pid)
	if GameState.get_flag("puzzle." + pid, false):
		await DialogueManager.say(["* La place %s est éclairée." % def.get("label", "")])
		return
	if pd.get("needs_light", true) and not (GameState.has_item("flashlight") or GameState.has_item("lumi_lamp")):
		await DialogueManager.say(["* Il fait trop noir pour lire le numéro."])
		return
	var order: Array = pd.get("order", [])
	var progress: Array = GameState.get_flag("seq." + pid, []).duplicate()
	progress.append(int(def.get("index", 0)))
	var ok = true
	for i in progress.size():
		if i >= order.size() or int(order[i]) != progress[i]:
			ok = false
	if not ok:
		AudioManager.sfx("wrong")
		GameState.set_flag("seq." + pid, [])
		for n in room.props.get_children():
			if n.has_method("_set_lit"):
				n._set_lit(false)
		await DialogueManager.say(pd.get("fail_text", ["* Toutes les lampes s'éteignent d'un coup."]))
		return
	_set_lit(true)
	AudioManager.sfx("click")
	GameState.set_flag("seq." + pid, progress)
	if progress.size() == order.size():
		AudioManager.sfx("right")
		GameState.set_flag("puzzle." + pid, true)
		await Actions.run(pd.get("success", []), self)
	else:
		await DialogueManager.say(["* Tu éclaires la place %s." % def.get("label", "")])
