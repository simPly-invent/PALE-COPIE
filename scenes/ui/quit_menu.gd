## Quitter la partie : retour à l'écran-titre ou fermeture du jeu, avec confirmation.
class_name QuitMenu
extends RefCounted

## Renvoie true si le joueur a quitté (le menu appelant doit alors se fermer).
static func ask(parent: Node) -> bool:
	var m = ListMenu.create(parent, Rect2(150, 150, 340, 120), ["Retour à l'écran-titre", "Quitter le jeu", "Annuler"], 20)
	m.set_meta("in_dialogue", true)
	var i: int = await m.done
	m.queue_free()
	if i < 0 or i == 2:
		return false
	var warn = "* Ce qui n'a pas été sauvegardé sera perdu."
	if SaveManager.has_save():
		warn += "\n* (Dernière sauvegarde : %s.)" % SaveManager.summary().get("room", "?")
	var c: int = await DialogueManager.choose(warn, ["Non", "Oui"])
	if c != 1:
		return false
	if i == 1:
		SaveManager.write_meta()
		parent.get_tree().quit()
		return true
	await World.fade(true, 0.6)
	GameState.clear_locks()
	DialogueManager.box.hide_box()
	DialogueManager.active = false
	World.main.show_title()
	await World.fade(false, 0.6)
	return true
