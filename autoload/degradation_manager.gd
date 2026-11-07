## Système central : fidélité, mutations, lignées, graine (section 3).
extends Node

const ROOM_BASE := preload("res://scenes/overworld/room_base.tscn")
const PALIERS := [[1, 90], [2, 75], [3, 60], [4, 45], [5, 30], [6, 15], [7, 5]]
const MAX_NEW_PER_COPY := 2
const SOUVENIR_BONUS := 20

var sources: Dictionary = {}          # id -> RoomSource
var zones: Dictionary = {}            # numéro -> données de zone
var mutations: Array = []             # Array[Mutation]
var mutation_by_id: Dictionary = {}
var bonuses: Dictionary = {}          # source_id -> [[profondeur, montant], ...]
var visited: Dictionary = {}          # "source#profondeur" -> true
var debug_offset: Dictionary = {}     # "source#profondeur" -> int (touche F4)
var _desc_cache: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all() -> void:
	sources.clear()
	for path in JsonUtil.list_files("res://rooms", ".json"):
		var d = JsonUtil.load_json(path)
		if d is Dictionary and d.has("id"):
			sources[d["id"]] = RoomSource.from_json(d)
	var z = JsonUtil.load_json("res://data/zones.json")
	if z is Dictionary:
		for entry in z.get("zones", []):
			zones[int(entry["id"])] = entry
	mutations.clear()
	for path in JsonUtil.list_files("res://mutations", ".tres"):
		var m = load(path)
		if m is Mutation:
			mutations.append(m)
			mutation_by_id[m.id] = m
	mutations.sort_custom(func(a, b): return a.palier < b.palier or (a.palier == b.palier and a.id < b.id))

# ---------------------------------------------------------------- Fidélité
static func palier_of(f: float) -> int:
	var p = 0
	for pr in PALIERS:
		if f <= pr[1]:
			p = pr[0]
	return p

static func key(source_id: String, depth: int) -> String:
	return "%s#%d" % [source_id, depth]

func zone_of(source_id: String) -> Dictionary:
	var src: RoomSource = sources.get(source_id)
	if src == null:
		return {}
	return zones.get(src.zone, {})

## Perte de fidélité au passage de la copie k (3 à 8 points selon la zone).
func drop_for(source_id: String, k: int) -> int:
	var z = zone_of(source_id)
	var lo = int(z.get("drop_min", 3))
	var hi = int(z.get("drop_max", 8))
	var src: RoomSource = sources.get(source_id)
	if src and src.data.has("drop"):
		lo = int(src.data["drop"][0]); hi = int(src.data["drop"][1])
	var rng = JsonUtil.make_rng([GameState.game_seed, source_id, "drop", k])
	return rng.randi_range(lo, hi)

func raw_fidelity(source_id: String, depth: int) -> int:
	var src: RoomSource = sources.get(source_id)
	if src == null:
		return 100
	var f = src.base_fidelity
	if src.data.get("fidelity_from_souvenirs", false):
		# la maison finale : dégradée selon les Souvenirs gardés
		f = clampi(16 + GameState.souvenirs.size() * 8, 5, 100)
	if source_id.begins_with("house_") and GameState.get_flag("prologue_wrong", false):
		f = min(f, 84)
	for k in range(1, depth + 1):
		f -= drop_for(source_id, k)
	var floor_f = int(zone_of(source_id).get("min_fidelity", 0))
	return clampi(f, min(floor_f, src.base_fidelity), 100)

func bonus_for(source_id: String, depth: int) -> int:
	var total = 0
	for b in bonuses.get(source_id, []):
		if depth >= int(b[0]):
			total += int(b[1])
	return total

func fidelity(source_id: String, depth: int) -> int:
	var f = raw_fidelity(source_id, depth) + bonus_for(source_id, depth)
	f += int(debug_offset.get(key(source_id, depth), 0))
	return clampi(f, 0, 100)

## Utiliser un Souvenir : +20 F pour cette salle et ses futures copies (3.4).
func restore(source_id: String, depth: int, amount := SOUVENIR_BONUS) -> void:
	if not bonuses.has(source_id):
		bonuses[source_id] = []
	bonuses[source_id].append([depth, amount])
	invalidate(source_id)

func set_debug_offset(source_id: String, depth: int, offset: int) -> void:
	debug_offset[key(source_id, depth)] = offset
	invalidate(source_id)

func invalidate(source_id := "") -> void:
	if source_id == "":
		_desc_cache.clear()
		return
	for k in _desc_cache.keys():
		if k.begins_with(source_id + "#"):
			_desc_cache.erase(k)

# ---------------------------------------------------------------- Lignée et mutations
## Descripteur déterministe d'une copie : fidélité, palier, mutations (héritées puis nouvelles).
func descriptor(source_id: String, depth: int) -> Dictionary:
	var k = key(source_id, depth)
	if _desc_cache.has(k):
		return _desc_cache[k]
	var src: RoomSource = sources.get(source_id)
	var f = fidelity(source_id, depth)
	var list: Array = []
	var parent = ""
	if depth > 0:
		var pd = descriptor(source_id, depth - 1)
		list = pd["mutations"].duplicate(true)
		parent = key(source_id, depth - 1)
	var present = {}
	for m in list:
		present[m["id"]] = true
	var new_ids: Array = []
	# mutations imposées par la salle (énigmes) : {"depth": n, "id": "..."}
	if src:
		for forced in src.data.get("forced_mutations", []):
			if int(forced.get("depth", -1)) == depth and not present.has(forced["id"]):
				var fm: Mutation = mutation_by_id.get(forced["id"])
				if fm and f <= fm.seuil:
					new_ids.append(forced["id"])
					present[forced["id"]] = true
	var limit = MAX_NEW_PER_COPY if depth > 0 else 7
	var rng = JsonUtil.make_rng([GameState.game_seed, source_id, "pick", depth])
	# candidates par palier croissant : le palier le plus ancien non représenté d'abord
	var by_palier = {}
	for m in mutations:
		if present.has(m.id) or f > m.seuil or (src and not m.is_allowed(src)):
			continue
		if not by_palier.has(m.palier):
			by_palier[m.palier] = []
		by_palier[m.palier].append(m.id)
	var paliers = by_palier.keys()
	paliers.sort()
	# 1) une mutation par palier non encore représenté
	var represented = {}
	for m in list:
		represented[int(mutation_by_id[m["id"]].palier) if mutation_by_id.has(m["id"]) else 0] = true
	for nid in new_ids:
		represented[mutation_by_id[nid].palier] = true
	for p in paliers:
		if new_ids.size() >= limit:
			break
		if represented.has(p):
			continue
		var ids: Array = by_palier[p]
		var pick: String = ids[rng.randi_range(0, ids.size() - 1)]
		new_ids.append(pick)
		ids.erase(pick)
		represented[p] = true
	# 2) compléter (copies uniquement) avec le palier le plus bas disponible
	if depth > 0:
		for p in paliers:
			var ids: Array = by_palier[p]
			while new_ids.size() < limit and not ids.is_empty():
				# une copie n'ajoute pas toujours 2 mutations : 50 % de chance pour la seconde
				if new_ids.size() >= 1 and rng.randf() < 0.5:
					break
				var pick: String = ids[rng.randi_range(0, ids.size() - 1)]
				new_ids.append(pick)
				ids.erase(pick)
			if new_ids.size() >= 1:
				break
	for nid in new_ids:
		list.append({"id": nid, "depth": depth})
	var active: Array = []
	for m in list:
		var mut: Mutation = mutation_by_id.get(m["id"])
		if mut and f <= mut.seuil:
			active.append(m)
	var desc = {
		"key": k, "source": source_id, "depth": depth, "parent": parent,
		"fidelity": f, "palier": palier_of(f), "mutations": list, "active": active, "new": new_ids,
	}
	_desc_cache[k] = desc
	return desc

func lineage(source_id: String, depth: int) -> Array:
	var out: Array = []
	for d in range(0, depth + 1):
		out.append(key(source_id, d))
	return out

## Instancie la salle source, applique les mutations héritées puis les nouvelles (9.2).
func make_copy(source_id: String, depth: int) -> Node:
	var src: RoomSource = sources.get(source_id)
	if src == null:
		push_error("Salle inconnue : %s" % source_id)
		return null
	var desc = descriptor(source_id, depth)
	var room = ROOM_BASE.instantiate()
	if src.data.has("scene") and ResourceLoader.exists(src.data["scene"]):
		room.free()
		room = load(src.data["scene"]).instantiate()
	room.build(src, depth, desc["fidelity"])
	for m in desc["active"]:
		var mut: Mutation = mutation_by_id[m["id"]]
		var rng = JsonUtil.make_rng([GameState.game_seed, source_id, int(m["depth"]), m["id"]])
		mut.apply(room, rng)
		room.active_mutations.append({"id": m["id"], "depth": m["depth"], "intensity": mut.intensity(room)})
	room.finalize()
	visited[key(source_id, depth)] = true
	return room

## Nombre de nœuds portant un tag dans une copie (énigme « Compter les néons »).
func count_tag(source_id: String, depth: int, tag: String) -> int:
	var room = make_copy(source_id, depth)
	if room == null:
		return 0
	var n: int = room.count_tag(tag)
	room.free()
	return n

## Volume relatif du bourdonnement des néons (règle 3.3.7 : le son suit la fidélité).
static func hum_level(f: float) -> float:
	return lerpf(0.12, 1.0, clampf((100.0 - f) / 95.0, 0.0, 1.0))

func to_dict() -> Dictionary:
	return {"bonuses": bonuses.duplicate(true), "visited": visited.keys()}

func from_dict(d: Dictionary) -> void:
	bonuses = d.get("bonuses", {}).duplicate(true)
	visited.clear()
	for k in d.get("visited", []):
		visited[k] = true
	debug_offset.clear()
	invalidate()
