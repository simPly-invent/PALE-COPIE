## Énigme « Les archives » : chaque copie montre le rapport corrompu différemment.
## mode "read" : affiche la version de cette copie. mode "input" : demande le mot reconstitué.
extends Interactable

func default_sprite() -> String:
	return "computer"

func interact(_player: Node) -> void:
	var pid: String = def.get("puzzle", "")
	var pd = Puzzles.data(pid)
	var word: String = pd.get("answer", "MIROIR")
	if def.get("mode", "read") == "read":
		var masks: Dictionary = pd.get("masks", {})
		var mask: String = masks.get(str(room.depth), "_".repeat(word.length()))
		var shown = ""
		for i in word.length():
			shown += word[i] if i < mask.length() and mask[i] != "_" else "_"
		var lines: Array = []
		for l in pd.get("report", ["RAPPORT : le mot-clé est %s."]):
			lines.append(str(l).replace("%s", " ".join(shown.split(""))))
		await DialogueManager.say(lines)
		return
	if GameState.get_flag("puzzle." + pid, false):
		await DialogueManager.say(pd.get("solved_text", ["* ACCÈS AUTORISÉ."]))
		return
	await DialogueManager.say(pd.get("prompt", ["* MOT-CLÉ DU RAPPORT ?"]))
	var code = await CodeInput.ask(pd.get("title", "MOT-CLÉ"), word.length(), true)
	if code == "":
		return
	if code == word:
		AudioManager.sfx("right")
		GameState.set_flag("puzzle." + pid, true)
		await Actions.run(pd.get("success", []), self)
	else:
		AudioManager.sfx("wrong")
		await DialogueManager.say(pd.get("fail_text", ["* ACCÈS REFUSÉ."]))
