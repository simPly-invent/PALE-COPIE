## État global : drapeaux, inventaire, statistiques, Souvenirs, fins.
extends Node

signal stats_changed
signal inventory_changed
signal flag_changed(key: String, value: Variant)

const MAX_INVENTORY := 8
const LV_EXP := [0, 10, 30, 70, 120, 200, 300, 500, 800, 1200, 1700, 2500, 3500, 5000, 7000, 10000, 15000, 25000, 50000, 99999]

var player_name = ""
var game_seed = 0
var lv = 1
var xp = 0
var hp = 20
var gold = 0                     # « tickets »
var inventory: Array = []         # objets ordinaires (id ou id~niveau_de_dégradation)
var key_items: Array = []         # objets clés
var souvenirs: Array = []         # Souvenirs conservés
var souvenirs_used: Array = []    # [{id, room}]
var tapes_found: Array = []
var tapes_seen: Array = []
var weapon = "stick_ruler"
var armor = "pyjama"
var flags: Dictionary = {}
var kills: Array = []             # ids des ennemis tués
var spared: Array = []
var named: Array = []             # ennemis épargnés dont le nom a été rendu
var room_key = {"source": "house_bedroom", "depth": 0}
var position = Vector2.ZERO
var playtime = 0.0
var still_time = 0.0             # temps immobile (secrets)
var badge_decay = 0
var battery = 100.0
var meta: Dictionary = {"boots": 0, "games_started": 0, "options": {"reduced_fx": false, "music_volume": 0.8, "fullscreen": false}}

var items_db: Dictionary = {}
var _locks: Dictionary = {}

func _enter_tree() -> void:
	_setup_input()
	_load_items()

func _process(delta: float) -> void:
	if not is_locked():
		playtime += delta

# ---------------------------------------------------------------- Contrôles
func _setup_input() -> void:
	# Déplacement : flèches + ZQSD (touches physiques W A S D = Z Q S D en AZERTY).
	# Valider : Entrée + touche physique Z (position Undertale ; « W » en AZERTY) + Espace.
	_bind("move_up", [KEY_UP], [KEY_W])
	_bind("move_down", [KEY_DOWN], [KEY_S])
	_bind("move_left", [KEY_LEFT], [KEY_A])
	_bind("move_right", [KEY_RIGHT], [KEY_D])
	_bind("confirm", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [KEY_Z])
	_bind("cancel", [KEY_SHIFT], [KEY_X])
	_bind("menu", [KEY_CTRL], [KEY_C])
	_bind("debug_overlay", [KEY_F3], [])
	_bind("debug_fidelity", [KEY_F4], [])
	_bind("debug_teleport", [KEY_F5], [])
	_bind("debug_battle", [KEY_F6], [])

func _bind(action: String, keys: Array, physical: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.2)
	for k in keys:
		var e = InputEventKey.new()
		e.keycode = k
		InputMap.action_add_event(action, e)
	for k in physical:
		var e = InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

# ---------------------------------------------------------------- Verrous (dialogues, menus, combats)
func lock(who: String) -> void:
	_locks[who] = true

func unlock(who: String) -> void:
	_locks.erase(who)

func is_locked() -> bool:
	return not _locks.is_empty()

# ---------------------------------------------------------------- Nouvelle partie
func new_game(name: String) -> void:
	player_name = name
	game_seed = randi() & 0x7fffffff
	lv = 1; xp = 0; gold = 0
	hp = max_hp()
	inventory = []; key_items = []; souvenirs = []; souvenirs_used = []
	tapes_found = []; tapes_seen = []
	weapon = "stick_ruler"; armor = "pyjama"
	flags = {}; kills = []; spared = []; named = []
	badge_decay = 0; battery = 100.0; playtime = 0.0
	room_key = {"source": "house_bedroom", "depth": 0}
	position = Vector2.ZERO
	meta["games_started"] = int(meta.get("games_started", 0)) + 1
	if meta.get("prologue_wrong", false):
		flags["prologue_wrong"] = true

# ---------------------------------------------------------------- Drapeaux et conditions
func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flag_changed.emit(key, value)

func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)

func inc_flag(key: String, by := 1) -> int:
	var v = int(flags.get(key, 0)) + by
	set_flag(key, v)
	return v

## Évalue une condition texte : "flag", "!flag", "flag>=3", "has:item", "souvenirs>=10",
## "palier>=4", "fidelity<50", "kills==0", "named>=6", "tapes_seen>=20", "games>=2".
## Plusieurs conditions séparées par " && ".
func check(cond: String) -> bool:
	cond = cond.strip_edges()
	if cond == "":
		return true
	if cond.contains("&&"):
		for part in cond.split("&&"):
			if not check(part):
				return false
		return true
	if cond.contains("||"):
		for part in cond.split("||"):
			if check(part):
				return true
		return false
	if cond.begins_with("!"):
		return not check(cond.substr(1))
	if cond.begins_with("has:"):
		return has_item(cond.substr(4))
	for op in [">=", "<=", "==", "!=", ">", "<"]:
		var i = cond.find(op)
		if i > 0:
			var lhs = _value_of(cond.substr(0, i).strip_edges())
			var rhs = float(cond.substr(i + op.length()).strip_edges())
			match op:
				">=": return lhs >= rhs
				"<=": return lhs <= rhs
				"==": return lhs == rhs
				"!=": return lhs != rhs
				">": return lhs > rhs
				"<": return lhs < rhs
	return bool(flags.get(cond, false))

func _value_of(key: String) -> float:
	match key:
		"souvenirs": return souvenirs.size()
		"kills": return kills.size()
		"spared": return spared.size()
		"named": return named.size()
		"tapes_seen": return tapes_seen.size()
		"tapes_found": return tapes_found.size()
		"lv": return lv
		"gold": return gold
		"games": return int(meta.get("games_started", 0))
		"boots": return int(meta.get("boots", 0))
		"fidelity": return World.current_fidelity()
		"palier": return DegradationManager.palier_of(World.current_fidelity())
		"depth": return int(room_key.get("depth", 0))
	var v = flags.get(key, 0)
	if v is bool:
		return 1.0 if v else 0.0
	return float(v)

# ---------------------------------------------------------------- Objets
func _load_items() -> void:
	var data = JsonUtil.load_json("res://data/items/items.json")
	if data is Dictionary:
		for it in data.get("items", []):
			items_db[it["id"]] = it

## Les objets dégradés sont notés "id~niveau".
func item_base(id: String) -> String:
	return id.split("~")[0]

func item_level(id: String) -> int:
	var p = id.split("~")
	return int(p[1]) if p.size() > 1 else 0

func item_def(id: String) -> Dictionary:
	return items_db.get(item_base(id), {"id": id, "name": id, "type": "junk"})

func item_name(id: String) -> String:
	var d = item_def(id)
	return TextFx.degrade_name(d.get("name", id), d.get("degraded", []), item_level(id))

func has_item(id: String) -> bool:
	for list in [inventory, key_items, souvenirs]:
		for it in list:
			if item_base(it) == id:
				return true
	return tapes_found.has(id)

## Donne un objet ; retourne false si l'inventaire est plein.
func give(id: String) -> bool:
	var d = item_def(id)
	match d.get("type", "junk"):
		"key":
			if not key_items.has(id):
				key_items.append(id)
		"souvenir":
			if not souvenirs.has(id):
				souvenirs.append(id)
		"tape":
			if not tapes_found.has(id):
				tapes_found.append(id)
		_:
			if inventory.size() >= MAX_INVENTORY:
				return false
			inventory.append(id)
	inventory_changed.emit()
	return true

func take(id: String) -> void:
	for list in [inventory, key_items, souvenirs]:
		for i in list.size():
			if item_base(list[i]) == id:
				list.remove_at(i)
				inventory_changed.emit()
				return

## Utilise un objet de l'inventaire ; renvoie le texte affiché.
func use_item(index: int) -> String:
	if index < 0 or index >= inventory.size():
		return ""
	var id: String = inventory[index]
	var d = item_def(id)
	var lvl = item_level(id)
	match d.get("type", ""):
		"heal":
			var amount = int(d.get("hp", 5) * pow(0.5, lvl))
			amount = max(1, amount)
			inventory.remove_at(index)
			heal(amount)
			inventory_changed.emit()
			var msg = "* Tu manges : %s." % item_name(id)
			if hp >= max_hp():
				return msg + "\n* Tes PV sont au maximum."
			return msg + "\n* Tu récupères %d PV." % amount
		"weapon":
			inventory[index] = weapon
			weapon = id
			inventory_changed.emit(); stats_changed.emit()
			return "* Tu t'équipes : %s." % item_name(id)
		"armor":
			inventory[index] = armor
			armor = id
			inventory_changed.emit(); stats_changed.emit()
			return "* Tu enfiles : %s." % item_name(id)
		"battery":
			inventory.remove_at(index)
			battery = 100.0
			inventory_changed.emit()
			return "* Tu changes les piles de la lampe."
	return "* Rien ne se passe."

# ---------------------------------------------------------------- Statistiques
func max_hp() -> int:
	return 16 + lv * 4

func atk() -> int:
	return 10 + (lv - 1) * 2 + int(item_def(weapon).get("atk", 0))

func def() -> int:
	return 10 + int((lv - 1) / 4) + int(item_def(armor).get("def", 0))

func heal(amount: int) -> void:
	hp = min(max_hp(), hp + amount)
	stats_changed.emit()

func damage(amount: int) -> void:
	hp = max(0, hp - amount)
	stats_changed.emit()

func add_exp(amount: int) -> bool:
	xp += amount
	var leveled = false
	while lv < LV_EXP.size() and xp >= LV_EXP[lv]:
		lv += 1
		hp += 4
		leveled = true
	stats_changed.emit()
	return leveled

# ---------------------------------------------------------------- Fins
## Calcule la fin selon la section 5.3 du cahier des charges.
func compute_ending() -> String:
	if tapes_seen.size() >= 20 and get_flag("copy_talked", false):
		return "secret"
	if souvenirs.size() >= 10 and kills.is_empty():
		return "retour"
	if souvenirs.size() <= 3:
		return "effacement"
	return "copie"

# ---------------------------------------------------------------- Sérialisation
func to_dict() -> Dictionary:
	return {
		"player_name": player_name, "seed": game_seed, "lv": lv, "exp": xp, "hp": hp, "gold": gold,
		"inventory": inventory.duplicate(), "key_items": key_items.duplicate(),
		"souvenirs": souvenirs.duplicate(), "souvenirs_used": souvenirs_used.duplicate(true),
		"tapes_found": tapes_found.duplicate(), "tapes_seen": tapes_seen.duplicate(),
		"weapon": weapon, "armor": armor, "flags": flags.duplicate(true),
		"kills": kills.duplicate(), "spared": spared.duplicate(), "named": named.duplicate(),
		"room_key": room_key.duplicate(), "position": [position.x, position.y],
		"playtime": playtime, "badge_decay": badge_decay, "battery": battery,
	}

func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", "")
	game_seed = int(d.get("seed", 0))
	lv = int(d.get("lv", 1)); xp = int(d.get("exp", 0)); hp = int(d.get("hp", 20)); gold = int(d.get("gold", 0))
	inventory = d.get("inventory", []).duplicate()
	key_items = d.get("key_items", []).duplicate()
	souvenirs = d.get("souvenirs", []).duplicate()
	souvenirs_used = d.get("souvenirs_used", []).duplicate(true)
	tapes_found = d.get("tapes_found", []).duplicate()
	tapes_seen = d.get("tapes_seen", []).duplicate()
	weapon = d.get("weapon", "stick_ruler"); armor = d.get("armor", "pyjama")
	flags = d.get("flags", {}).duplicate(true)
	kills = d.get("kills", []).duplicate(); spared = d.get("spared", []).duplicate(); named = d.get("named", []).duplicate()
	var rk: Dictionary = d.get("room_key", {"source": "house_bedroom", "depth": 0})
	room_key = {"source": rk.get("source", "house_bedroom"), "depth": int(rk.get("depth", 0))}
	var p: Array = d.get("position", [0, 0])
	position = Vector2(p[0], p[1])
	playtime = float(d.get("playtime", 0.0))
	badge_decay = int(d.get("badge_decay", 0))
	battery = float(d.get("battery", 100.0))
	stats_changed.emit()
	inventory_changed.emit()
