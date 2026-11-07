## Coffre (carton d'archives, casier, distributeur...). Ouvert = drapeau "chest.<id>".
## Palier 6 (mutation chest_relock) : peut réapparaître fermé avec un contenu dégradé.
class_name Chest
extends Interactable

var opened = false
var degrade_level = 0
var state_key = ""

func default_sprite() -> String:
	return "chest_box"

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	add_to_group("chest")
	state_key = "chest." + str(d.get("id", "?"))
	opened = GameState.get_flag(state_key, false)
	_refresh()

## Appelé par la mutation chest_relock.
func relock(level: int, rng: RandomNumberGenerator) -> void:
	if not opened or rng.randf() > 0.6:
		return
	var contents: String = def.get("contents", "")
	if contents.begins_with("tape:") or contents.begins_with("souvenir:"):
		return
	state_key = "chest.%s@%d" % [def.get("id", "?"), room.depth]
	opened = GameState.get_flag(state_key, false)
	degrade_level = level
	_refresh()

func _refresh() -> void:
	if sprite == null:
		return
	if opened and tex_name == "chest_box":
		sprite.texture = Assets.tex("chest_box_open")
	elif opened:
		sprite.modulate = Color(0.65, 0.65, 0.65)
	else:
		sprite.texture = Assets.tex(tex_name)
		sprite.modulate = Color.WHITE

func interact(_player: Node) -> void:
	if opened:
		await DialogueManager.say(["* C'est vide."])
		return
	var contents: String = def.get("contents", "")
	var lines: Array = []
	if def.has("text"):
		lines.append(def["text"])
	var got = true
	if contents.begins_with("gold:"):
		var n = int(contents.substr(5))
		GameState.gold += n
		lines.append("* Tu trouves %d tickets." % n)
	elif contents.begins_with("tape:"):
		var id = contents.substr(5)
		GameState.give(id)
		AudioManager.sfx("item")
		lines.append("* Tu trouves une cassette VHS : « %s »." % VhsLibrary.title(id))
	elif contents.begins_with("souvenir:"):
		var id = contents.substr(9)
		GameState.give(id)
		AudioManager.sfx("souvenir")
		lines.append("* Vous avez trouvé un souvenir.")
		lines.append("* " + GameState.item_def(id).get("desc", ""))
	elif contents != "":
		var id = contents if degrade_level == 0 else "%s~%d" % [contents, degrade_level]
		got = GameState.give(id)
		if got:
			AudioManager.sfx("item")
			lines.append("* Tu trouves : %s." % GameState.item_name(id))
		else:
			lines.append("* Il y a %s dedans, mais tes poches sont pleines." % GameState.item_name(id))
	else:
		lines.append("* Il n'y a rien dedans. Juste de la poussière.")
	if got:
		opened = true
		GameState.set_flag(state_key, true)
		_refresh()
	await DialogueManager.say(lines)
