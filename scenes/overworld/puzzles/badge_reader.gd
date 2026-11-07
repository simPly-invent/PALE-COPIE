## Lecteur de badge (énigme « Le badge ») : le texte du badge se dégrade à chaque copie traversée.
## Il faut l'utiliser avant qu'il devienne illisible, ou faire remonter la salle (Souvenir).
extends Interactable

func default_sprite() -> String:
	return "icon_note"

func interact(_player: Node) -> void:
	var pid: String = def.get("puzzle", "z2_badge")
	var pd = Puzzles.data(pid)
	if GameState.get_flag("puzzle." + pid, false):
		await DialogueManager.say(["* Le lecteur clignote en vert."])
		return
	if not GameState.has_item("badge"):
		await DialogueManager.say(["* Un lecteur de badge. « PRÉSENTEZ VOTRE BADGE »"])
		return
	var legible = badge_legible(room.fidelity)
	var shown = TextFx.corrupt_label("DANA K. - TECHNICIENNE NIV.2", GameState.badge_decay * 0.18, "badge")
	await DialogueManager.say(["* Tu passes le badge : « %s »." % shown])
	if legible:
		AudioManager.sfx("right")
		GameState.set_flag("puzzle." + pid, true)
		await Actions.run(pd.get("success", [{"say": ["* Bip. La porte se déverrouille."]}]), self)
	else:
		AudioManager.sfx("wrong")
		await DialogueManager.say(pd.get("fail_text", ["* BADGE ILLISIBLE.", "* (Le badge s'efface un peu plus à chaque copie. Il faudrait que cette pièce se souvienne mieux d'elle-même.)"]))

static func badge_legible(room_fidelity: int) -> bool:
	return GameState.badge_decay * 6 <= room_fidelity - 40
