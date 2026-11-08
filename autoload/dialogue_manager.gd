## Dialogues en JSON (data/dialogues/*.json), avec variantes par palier (p1, p4, p6...),
## choix, drapeaux, objets et actions.
extends Node

signal dialogue_finished(id: String)

var layer: CanvasLayer
var box: Control
var active = false
var _depth = 0
var last_choice = -1

func _ready() -> void:
	layer = CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	box = preload("res://scenes/ui/dialogue_box.gd").new()
	layer.add_child(box)

func load_dialogue(id: String) -> Dictionary:
	var d = JsonUtil.load_json("res://data/dialogues/%s.json" % id)
	if d is Dictionary:
		return d
	push_warning("Dialogue introuvable : %s" % id)
	return {"nodes": {"start": ["* ..."]}}

func _begin() -> void:
	_depth += 1
	if _depth > 1:
		return
	active = true
	GameState.lock("dialogue")
	var p = World.player
	if p and World.camera:
		var screen_y: float = p.global_position.y - World.camera.global_position.y + 240
		box.place_top(screen_y > 300)
	else:
		box.place_top(false)

func _end() -> void:
	_depth = max(0, _depth - 1)
	if _depth > 0:
		return
	box.hide_box()
	active = false
	GameState.unlock("dialogue")

## Affiche une liste de répliques simples (texte ou dictionnaires).
func say(lines: Array, portrait := "", voice := "default") -> void:
	_begin()
	for l in lines:
		if l is Dictionary:
			await _run_line(l, {"portrait": portrait, "voice": voice})
		else:
			await box.show_line(_txt(str(l)), portrait, voice)
	_end()

## Pose une question ; renvoie l'index choisi.
func choose(prompt: String, options: Array, portrait := "") -> int:
	_begin()
	var idx: int = await box.show_choices(_txt(prompt), options.map(func(o): return _txt(str(o))), portrait)
	_end()
	return idx

## Joue un dialogue complet par son id.
func play(id: String, _ctx := {}) -> void:
	var d = load_dialogue(id)
	_begin()
	var defaults = {"portrait": d.get("portrait", ""), "voice": d.get("voice", "default"), "speed": d.get("speed", 1.0)}
	var node = "start"
	for s in d.get("start", []):
		if s is Dictionary and (not s.has("if") or GameState.check(s["if"])):
			node = s.get("goto", "start")
			break
	var guard = 0
	while node != "" and guard < 64:
		guard += 1
		var lines: Array = d.get("nodes", {}).get(node, [])
		node = ""
		for l in lines:
			var res: String = await _run_line(l, defaults)
			if res != "":
				node = res
				break
	_end()
	dialogue_finished.emit(id)

## Exécute une réplique ; renvoie le nœud suivant ("" = continuer, "@end" = fin).
func _run_line(l: Variant, defaults: Dictionary) -> String:
	if l is String:
		await box.show_line(_txt(l), defaults.get("portrait", ""), defaults.get("voice", "default"), defaults.get("speed", 1.0))
		return ""
	var line: Dictionary = l
	if line.has("if") and not GameState.check(line["if"]):
		return ""
	if line.has("set"):
		for k in line["set"]:
			GameState.set_flag(k, line["set"][k])
	if line.has("inc"):
		GameState.inc_flag(line["inc"])
	var text = pick_variant(line)
	var portrait: String = line.get("portrait", defaults.get("portrait", ""))
	var voice: String = line.get("voice", defaults.get("voice", "default"))
	var speed: float = line.get("speed", defaults.get("speed", 1.0))
	if line.has("choices"):
		var opts: Array = []
		var targets: Array = []
		for c in line["choices"]:
			if c.has("if") and not GameState.check(c["if"]):
				continue
			opts.append(_txt(c["text"]))
			targets.append(c)
		var idx: int = await box.show_choices(_txt(text), opts, portrait, voice)
		last_choice = idx
		var c: Dictionary = targets[idx]
		if c.has("set"):
			for k in c["set"]:
				GameState.set_flag(k, c["set"][k])
		if c.has("actions"):
			await _run_actions(c["actions"])
		return c.get("goto", "@end" if c.get("end", false) else "")
	if text != "":
		await box.show_line(_txt(text), portrait, voice, speed)
	if line.has("give") or line.has("take") or line.has("actions"):
		var acts: Array = []
		if line.has("give"):
			acts.append({"give": line["give"]})
		if line.has("take"):
			acts.append({"take": line["take"]})
		acts.append_array(line.get("actions", []))
		await _run_actions(acts)
	if line.get("end", false):
		return "@end"
	return line.get("goto", "")

func _run_actions(acts: Array) -> void:
	# les actions peuvent ouvrir d'autres boîtes : on garde la main
	await Actions.run(acts, null)

## Choisit la variante selon le palier de la salle : la clé pN la plus haute avec N <= palier.
func pick_variant(line: Dictionary) -> String:
	var palier = World.current_palier()
	var best = -1
	var text: String = line.get("text", "")
	for k in line.keys():
		var ks = str(k)
		if ks.length() == 2 and ks[0] == "p" and ks[1].is_valid_int():
			var n = int(ks[1])
			if n <= palier and n > best:
				best = n
				text = line[k]
	return text

func _txt(t: String) -> String:
	return TextFx.process(t, World.current_fidelity(), World.current_palier())
