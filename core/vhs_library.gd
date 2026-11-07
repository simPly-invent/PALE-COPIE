## Accès aux cassettes VHS décrites dans data/tapes/*.json.
class_name VhsLibrary
extends RefCounted

static func load_tape(id: String) -> Dictionary:
	var d = JsonUtil.load_json("res://data/tapes/%s.json" % id)
	return d if d is Dictionary else {}

static func title(id: String) -> String:
	return load_tape(id).get("title", id)

static func all_ids() -> Array:
	var out: Array = []
	for p in JsonUtil.list_files("res://data/tapes", ".json"):
		out.append(p.get_file().get_basename())
	return out
