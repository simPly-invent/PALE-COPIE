## Fabrique des objets d'énigme décrits dans les salles ("puzzles": [...]).
## Chaque type correspond à un script de ce dossier. Les paramètres viennent de data/puzzles/*.json.
class_name Puzzles
extends RefCounted

const TYPES := {
	"keypad": "res://scenes/overworld/puzzles/keypad.gd",
	"clock": "res://scenes/overworld/puzzles/clock.gd",
	"sequence": "res://scenes/overworld/puzzles/sequence_spot.gd",
	"tile_path": "res://scenes/overworld/puzzles/tile_path.gd",
	"terminal": "res://scenes/overworld/puzzles/terminal.gd",
	"reflection": "res://scenes/overworld/puzzles/reflection.gd",
	"badge_reader": "res://scenes/overworld/puzzles/badge_reader.gd",
}

static func create(d: Dictionary, room: Node) -> Node:
	var path: String = TYPES.get(d.get("type", ""), "")
	if path == "":
		push_warning("Type d'énigme inconnu : %s" % d.get("type", ""))
		return null
	var node = load(path).new()
	node.setup(d, room)
	return node

static func data(id: String) -> Dictionary:
	var d = JsonUtil.load_json("res://data/puzzles/%s.json" % id)
	return d if d is Dictionary else {}

## Valeur dérivée de la graine (codes qui changent à chaque partie).
static func seeded(id: String, key: String, lo: int, hi: int) -> int:
	var rng = JsonUtil.make_rng([GameState.game_seed, "puzzle", id, key])
	return rng.randi_range(lo, hi)

## Calcule la réponse attendue d'une énigme.
static func answer(id: String) -> String:
	var d = data(id)
	match d.get("kind", ""):
		"count_tag":
			# code = nombre d'objets portant le tag dans chaque copie listée
			var s = ""
			for depth in d.get("depths", [1, 2, 3]):
				s += str(DegradationManager.count_tag(d["room"], int(depth), d.get("tag", "neon")) % 10)
			return s
		"clock_source":
			var t = clock_minutes(id, 0)
			return "%02d%02d" % [int(t / 60) % 12 if int(t / 60) % 12 != 0 else 12, t % 60]
		"sequence":
			var seq = room_sequence(id)
			return str(seq[int(d.get("missing_index", 4))])
		"fixed":
			return str(d.get("answer", ""))
	return str(d.get("answer", ""))

## Énigme des horloges : heure (en minutes) affichée dans la copie `depth`.
static func clock_minutes(id: String, depth: int) -> int:
	var d = data(id)
	var base = seeded(id, "base", 60, 719)
	base = base - base % 5
	var step = seeded(id, "step", int(d.get("step_min", 7)), int(d.get("step_max", 23)))
	return (base + step * depth) % 720

## Énigme des numéros de chambres : suite à écarts doublés.
static func room_sequence(id: String) -> Array:
	var d = data(id)
	var start = seeded(id, "start", 101, 119)
	var gap = seeded(id, "gap", 1, 3)
	var out: Array = []
	var v = start
	for i in int(d.get("length", 7)):
		out.append(v)
		v += gap
		gap *= 2
	return out
