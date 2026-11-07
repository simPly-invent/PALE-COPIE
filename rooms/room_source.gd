## Salle source dessinée « à la main » (dans un fichier JSON de rooms/<zone>/).
## Les copies sont générées par DegradationManager.make_copy(source_id, depth).
class_name RoomSource
extends Resource

@export var id = ""
@export var zone = 0
@export var title = ""
@export var base_fidelity = 100
@export var size = Vector2i(16, 12)
@export var layout: PackedStringArray = []
@export var anchor: Dictionary = {}
@export var props: Array = []
@export var doors: Array = []
@export var data: Dictionary = {}     # tout le reste (npcs, chests, phones, triggers, puzzles, chain...)

static func from_json(d: Dictionary) -> RoomSource:
	var r = RoomSource.new()
	r.id = d.get("id", "")
	r.zone = int(d.get("zone", 0))
	r.title = d.get("name", r.id)
	r.base_fidelity = int(d.get("fidelity", 100))
	var s: Array = d.get("size", [16, 12])
	r.size = Vector2i(int(s[0]), int(s[1]))
	r.layout = PackedStringArray(d.get("layout", []))
	r.anchor = d.get("anchor", {})
	r.props = d.get("props", [])
	r.doors = d.get("doors", [])
	r.data = d
	return r

func get_list(key: String) -> Array:
	return data.get(key, [])
