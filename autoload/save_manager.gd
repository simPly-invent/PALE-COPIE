## Sauvegarde : un seul fichier JSON dans user://, avec l'état du monde, les lignées visitées,
## la graine, les drapeaux et le compteur de parties (section 9.2).
extends Node

const PATH := "user://save.json"

var data: Dictionary = {}

func _ready() -> void:
	load_file()
	GameState.meta["boots"] = int(GameState.meta.get("boots", 0)) + 1
	write_meta()

func load_file() -> void:
	data = {}
	if FileAccess.file_exists(PATH):
		var f = FileAccess.open(PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			data = JsonUtil.normalize(parsed)
	var meta: Dictionary = data.get("meta", {})
	for k in meta:
		GameState.meta[k] = meta[k]
	if not GameState.meta.has("options"):
		GameState.meta["options"] = {"reduced_fx": false, "music_volume": 0.8, "fullscreen": false}

func has_save() -> bool:
	return data.has("game") and data["game"] is Dictionary

func _write() -> void:
	data["meta"] = GameState.meta.duplicate(true)
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))

func write_meta() -> void:
	_write()

## Capture complète de l'état.
func snapshot() -> Dictionary:
	var g = GameState.to_dict()
	g["degradation"] = DegradationManager.to_dict()
	if World.player:
		g["position"] = [World.player.global_position.x, World.player.global_position.y]
		g["facing"] = World.player.facing
	if World.current_room:
		g["room_key"] = {"source": World.current_room.source.id, "depth": World.current_room.depth}
	g["follower"] = World.follower.id if World.follower else ""
	g["saved_at"] = Time.get_datetime_string_from_system()
	return g

func save_game() -> void:
	data["game"] = snapshot()
	_write()
	AudioManager.sfx("save")

func summary() -> Dictionary:
	if not has_save():
		return {}
	var g: Dictionary = data["game"]
	var src: RoomSource = DegradationManager.sources.get(g.get("room_key", {}).get("source", ""))
	return {"name": g.get("player_name", ""), "lv": g.get("lv", 1), "time": g.get("playtime", 0.0), "room": src.title if src else "?"}

## Restaure l'état et recharge la salle à la position sauvegardée.
func load_game() -> void:
	if not has_save():
		return
	await apply_snapshot(data["game"])

func apply_snapshot(g: Dictionary) -> void:
	g = JsonUtil.normalize(g)
	GameState.from_dict(g)
	DegradationManager.from_dict(g.get("degradation", {}))
	var rk: Dictionary = GameState.room_key
	var p: Array = g.get("position", [0, 0])
	if World.current_room == null or true:
		World.set_follower(g.get("follower", ""))
		World._load_room(rk["source"], int(rk["depth"]), "", "", Vector2(p[0], p[1]))
		if g.has("facing") and World.player:
			World.player.face(g["facing"])
		World.in_game = true
		World._on_room_entered()
