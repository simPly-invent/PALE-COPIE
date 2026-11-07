## Clavier à code. La réponse est calculée par Puzzles.answer(puzzle) (souvent dérivée de la graine).
extends Interactable

func default_sprite() -> String:
	return "computer"

func interact(_player: Node) -> void:
	var pid: String = def.get("puzzle", "")
	var pd = Puzzles.data(pid)
	var flag: String = "puzzle." + pid
	if GameState.get_flag(flag, false):
		await DialogueManager.say(pd.get("solved_text", ["* Le voyant est vert."]))
		return
	await DialogueManager.say(pd.get("prompt", ["* Un clavier à code."]))
	var answer = Puzzles.answer(pid)
	var code = await CodeInput.ask(pd.get("title", "CODE"), answer.length(), pd.get("letters", false))
	if code == "":
		return
	if code == answer:
		AudioManager.sfx("right")
		GameState.set_flag(flag, true)
		await Actions.run(pd.get("success", [{"say": ["* Clic. Quelque chose s'est ouvert."]}]), self)
	else:
		AudioManager.sfx("wrong")
		GameState.inc_flag(flag + ".tries")
		await DialogueManager.say(pd.get("fail_text", ["* Bzzt. Mauvais code."]))
