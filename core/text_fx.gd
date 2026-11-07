## Dégradation du texte selon la fidélité.
## Balises : [lose]texte[/lose] perd des lettres, [swap=autre]texte[/swap] est remplacé à palier 5+,
## {name} = nom du joueur.
class_name TextFx
extends RefCounted

static var _swap_re: RegEx
static var _lose_re: RegEx

static func process(text: String, fidelity: int, palier: int) -> String:
	if _swap_re == null:
		_swap_re = RegEx.create_from_string("\\[swap=([^\\]]*)\\](.*?)\\[/swap\\]")
		_lose_re = RegEx.create_from_string("\\[lose\\](.*?)\\[/lose\\]")
	text = text.replace("{name}", GameState.player_name if GameState.player_name != "" else "???")
	text = text.replace("{games}", str(GameState.meta.get("games_started", 1)))
	for m in _swap_re.search_all(text):
		var rep: String = m.get_string(1) if palier >= 5 else m.get_string(2)
		text = text.replace(m.get_string(0), rep)
	for m in _lose_re.search_all(text):
		text = text.replace(m.get_string(0), lose_letters(m.get_string(1), fidelity))
	return text

## Retire des lettres de façon déterministe : plus F est bas, plus il en manque.
static func lose_letters(s: String, fidelity: int) -> String:
	var ratio = clampf((100.0 - fidelity) / 110.0, 0.0, 0.85)
	var out = ""
	for i in s.length():
		var c = s[i]
		if c == " ":
			out += c
			continue
		var h = float((str(i) + s).hash() % 1000) / 1000.0
		out += " " if h < ratio else c
	return out

## « SORTIE » -> « SORTE » -> « S RT » : dégradation progressive d'un libellé.
static func corrupt_label(s: String, level: float, seed_key: String) -> String:
	if level <= 0.0:
		return s
	var out = ""
	for i in s.length():
		var h = float((seed_key + str(i)).hash() % 1000) / 1000.0
		if s[i] != " " and h < level * 0.7:
			out += " " if h < level * 0.35 else ""
		else:
			out += s[i]
	return out

## Nom d'objet dégradé : utilise la liste fournie sinon perd des lettres.
static func degrade_name(name: String, degraded: Array, level: int) -> String:
	if level <= 0:
		return name
	if level - 1 < degraded.size():
		return degraded[level - 1]
	return lose_letters(name, 100 - level * 35)
