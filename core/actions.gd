## Mini-langage d'actions utilisé par les données (déclencheurs, dialogues, énigmes).
## Chaque action est un dictionnaire à une clé principale :
##  {"say": ["texte", ...]}            {"dialogue": "id"}            {"battle": "enemy_id"}
##  {"set": {"flag": valeur}}         {"inc": "flag"}               {"give": "item"} {"take": "item"}
##  {"goto": {"room": "id", "door": "id", "depth": 0, "spawn": "id"}}
##  {"wait": 1.0}                     {"sfx": "nom"}                {"music": "nom"} {"stop_music": true}
##  {"shake": 0.5}                    {"heal": true}                {"save": true}
##  {"tape": "t01"}                   {"restore": 20}               {"fade": "out"/"in"}
##  {"if": "cond", "then": [...], "else": [...]}
##  {"cutscene": "fall"}              {"ending": true}              {"entity": "pass"/"chase"}
##  {"follower": "lumi"/"none"}       {"rebuild": true}             {"gold": 10}
##  {"name_entry": true}              {"title": true}
class_name Actions
extends RefCounted

static func run(list: Array, source: Node = null) -> void:
	for i in list.size():
		var a = list[i]
		if not (a is Dictionary):
			continue
		# un carton suivi d'un changement de salle reste au noir jusqu'à la nouvelle salle
		if a.has("card") and i + 1 < list.size() and list[i + 1] is Dictionary and (list[i + 1].has("goto") or list[i + 1].has("start_adventure")):
			a = a.duplicate()
			a["keep_black"] = true
		await run_one(a, source)
		if World.transitioning_out:
			# un changement de salle interrompt la suite
			pass

static func run_one(a: Dictionary, source: Node) -> void:
	if a.has("if"):
		if GameState.check(a["if"]):
			await run(a.get("then", []), source)
		else:
			await run(a.get("else", []), source)
		return
	if a.has("say"):
		var t = a["say"]
		await DialogueManager.say(t if t is Array else [t], a.get("portrait", ""), a.get("voice", "default"))
	if a.has("dialogue"):
		await DialogueManager.play(a["dialogue"])
	if a.has("set"):
		for k in a["set"]:
			GameState.set_flag(k, a["set"][k])
	if a.has("inc"):
		GameState.inc_flag(a["inc"])
	if a.has("give"):
		var id: String = a["give"]
		if GameState.give(id):
			var d = GameState.item_def(id)
			AudioManager.sfx("souvenir" if d.get("type") == "souvenir" else "item")
			if not a.get("silent", false):
				var msg = "* Vous avez trouvé un souvenir." if d.get("type") == "souvenir" else "* Tu obtiens : %s." % GameState.item_name(id)
				await DialogueManager.say([msg])
		else:
			await DialogueManager.say(["* Tes poches sont pleines."])
	if a.has("take"):
		GameState.take(a["take"])
	if a.has("gold"):
		GameState.gold += int(a["gold"])
	if a.has("heal"):
		GameState.heal(999)
	if a.has("save"):
		SaveManager.save_game()
	if a.has("sfx"):
		AudioManager.sfx(a["sfx"])
	if a.has("music"):
		AudioManager.play_music(a["music"], World.current_fidelity())
	if a.has("stop_music"):
		AudioManager.stop_music()
	if a.has("shake"):
		FxManager.shake(float(a["shake"]))
	if a.has("wait"):
		await World.get_tree().create_timer(float(a["wait"])).timeout
	if a.has("fade"):
		await World.fade(a["fade"] == "out", float(a.get("time", 0.5)))
	if a.has("tape"):
		await World.play_tape(a["tape"])
	if a.has("restore"):
		World.restore_current(int(a["restore"]))
	if a.has("rebuild"):
		await World.rebuild_current()
	if a.has("battle"):
		var res: Dictionary = await BattleManager.start(a["battle"], a.get("battle_opts", {}))
		if a.has("on_" + str(res.get("outcome", ""))):
			await run(a["on_" + str(res["outcome"])], source)
	if a.has("follower"):
		World.set_follower(a["follower"])
	if a.has("entity"):
		World.entity_event(a["entity"], a)
	if a.has("cutscene"):
		await Cutscenes.play(a["cutscene"], a)
	if a.has("ending"):
		await Cutscenes.play("ending", a)
	if a.has("ask_code"):
		# {"ask_code": {"puzzle": "z2_clocks", "title": "...", "letters": false, "right": [...], "wrong": [...]}}
		var q: Dictionary = a["ask_code"]
		var ans = Puzzles.answer(q.get("puzzle", ""))
		var code: String = await CodeInput.ask(q.get("title", "?"), ans.length(), q.get("letters", false))
		if code == ans:
			AudioManager.sfx("right")
			await run(q.get("right", []), source)
		else:
			AudioManager.sfx("wrong")
			await run(q.get("wrong", []), source)
	if a.has("name_entry"):
		# {"name_entry": {"title": "...", "skip": true}} : le nom choisi devient {name}
		var cfg: Dictionary = a["name_entry"] if a["name_entry"] is Dictionary else {}
		var ne = load("res://scenes/ui/name_entry.gd").new()
		ne.title_text = cfg.get("title", "Nomme l'enfant tombé.")
		ne.return_mode = true
		ne.allow_skip = cfg.get("skip", false)
		GameState.lock("name")
		World.main.add_overlay(ne)
		var chosen: String = await ne.named
		GameState.unlock("name")
		if chosen != "":
			GameState.player_name = chosen
			GameState.set_flag("named_in_memory", true)
	if a.has("card"):
		# cartons plein écran (ellipses, passages du temps) : {"card": ["Un mois."], "hold": 2.5}
		await Cutscenes.cards(a["card"] if a["card"] is Array else [a["card"]], float(a.get("hold", 2.6)), a.get("keep_black", false))
	if a.has("skin"):
		GameState.player_skin = a["skin"]
	if a.has("player_name"):
		GameState.player_name = a["player_name"]
	if a.has("start_adventure"):
		await World.main.start_adventure()
		return
	if a.has("goto"):
		var g: Dictionary = a["goto"]
		await World.goto_room(g.get("room", ""), int(g.get("depth", 0)), g.get("door", ""), g.get("spawn", ""))
