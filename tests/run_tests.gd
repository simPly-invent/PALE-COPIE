## Tests de cohérence (jalons 3, 4 et 7). Lancer :
##   $GODOT --headless res://tests/run_tests.tscn
## Vérifie les 7 règles de la section 3.3 sur une lignée de 20 copies, toutes les salles
## sources (construction sans erreur, portes accessibles), et l'aller-retour de sauvegarde.
extends Node

var failures: Array = []
var checks = 0

func _ready() -> void:
	await get_tree().process_frame
	GameState.new_game("TEST")
	GameState.game_seed = 1997
	test_lineage_rules("test_lineage", 20)
	for seed in [1, 42, 123456]:
		GameState.game_seed = seed
		DegradationManager.invalidate()
		test_lineage_rules("test_lineage", 20)
	GameState.game_seed = 1997
	DegradationManager.invalidate()
	test_all_sources()
	test_reachability()
	test_souvenir_restore()
	await test_save_roundtrip()
	test_data_files()
	print("")
	if failures.is_empty():
		print("ALL TESTS PASSED (%d vérifications)" % checks)
	else:
		for f in failures:
			print("ÉCHEC : ", f)
		print("%d ÉCHEC(S) sur %d vérifications" % [failures.size(), checks])
	get_tree().quit(0 if failures.is_empty() else 1)

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)

# ---------------------------------------------------------------- Règles 3.3
func test_lineage_rules(sid: String, n: int) -> void:
	var src: RoomSource = DegradationManager.sources[sid]
	var prev_desc: Dictionary = {}
	var prev_f = 101
	var prev_int: Dictionary = {}
	var prev_hum = -1.0
	var max_palier = 0
	for d in range(0, n + 1):
		DegradationManager.invalidate(sid)
		var r1 = DegradationManager.make_copy(sid, d)
		var sig1: String = r1.signature()
		DegradationManager.invalidate(sid)
		var r2 = DegradationManager.make_copy(sid, d)
		var sig2: String = r2.signature()
		var desc = DegradationManager.descriptor(sid, d)
		var tag = "[seed %d] %s#%d" % [GameState.game_seed, sid, d]
		# 1. Déterminisme
		check(sig1 == sig2, tag + " : la copie n'est pas identique à la reconstruction")
		# 2. Héritage : les mutations du parent sont un préfixe
		if d > 0:
			var pm: Array = prev_desc["mutations"]
			var cm: Array = desc["mutations"]
			var ok = cm.size() >= pm.size()
			for i in pm.size():
				if not ok or cm[i]["id"] != pm[i]["id"]:
					ok = false
			check(ok, tag + " : n'hérite pas des mutations du parent")
			# 4. Lisibilité : au plus 2 nouvelles mutations
			check(cm.size() - pm.size() <= 2, tag + " : plus de 2 nouvelles mutations")
		# 3. Monotonie : F ne remonte pas, l'intensité ne baisse pas
		var f: int = desc["fidelity"]
		check(f <= prev_f, tag + " : la fidélité remonte sans Souvenir (%d > %d)" % [f, prev_f])
		for m in r1.active_mutations:
			if prev_int.has(m["id"]):
				check(m["intensity"] >= prev_int[m["id"]] - 0.0001, tag + " : %s recule" % m["id"])
			prev_int[m["id"]] = m["intensity"]
		# une mutation n'apparaît jamais avant son seuil
		for m in r1.active_mutations:
			var mut: Mutation = DegradationManager.mutation_by_id[m["id"]]
			check(f <= mut.seuil, tag + " : %s active au-dessus de son seuil" % m["id"])
		# 5. L'ancre est sacrée
		var anchors: Array = r1.anchor_root.get_children().filter(func(a): return a is RoomAnchor)
		check(anchors.size() == (1 if not src.anchor.is_empty() else 0), tag + " : %d ancre(s)" % anchors.size())
		if anchors.size() == 1:
			var a: RoomAnchor = anchors[0]
			check(a.position == r1.cell_pos(src.anchor["pos"]), tag + " : l'ancre a bougé")
			check(a.tex_name == src.anchor.get("sprite", "chair_red"), tag + " : l'ancre a changé d'apparence")
			check(a.modulate == Color.WHITE and a.overlay_sprite.modulate == Color.WHITE, tag + " : l'ancre a changé de couleur")
			check(a.material == null and not a.use_parent_material, tag + " : l'ancre reçoit la teinte de salle")
		# 6. Les portes mentent de façon logique
		for door in r1.doors.get_children():
			if door is Door and door.shifted:
				var ind = 0
				for p in r1.all_props():
					if p.get_meta("indicates", "") == str(door.name):
						ind += 1
				check(ind > 0, tag + " : porte %s décalée sans indication visible" % door.name)
			if door is Door and door.get_meta("loop", false):
				check(str(door.def.get("label", "")) != "", tag + " : boucle sans panneau")
		# accessibilité des portes
		check(_doors_connected(r1), tag + " : une porte est inaccessible")
		# 7. Le son suit la fidélité
		var hum = DegradationManager.hum_level(f)
		check(hum >= prev_hum - 0.0001, tag + " : le bourdonnement baisse alors que F baisse")
		prev_hum = hum
		max_palier = max(max_palier, desc["palier"])
		prev_desc = desc
		prev_f = f
		r1.free()
		r2.free()
	check(max_palier == 7, "[seed %d] la lignée de %d copies n'atteint pas le palier 7 (max %d)" % [GameState.game_seed, n, max_palier])
	print("Lignée %s (graine %d) : %d copies vérifiées, palier max %d" % [sid, GameState.game_seed, n, max_palier])

func _doors_connected(room) -> bool:
	var t: TileGrid = room.tiles
	var targets: Array = []
	for d in room.doors.get_children():
		if d is Door:
			d.place()
			targets.append(room.pos_cell(d.spawn_point()))
	if targets.size() < 2:
		return true
	var seen = {targets[0]: true}
	var q: Array = [targets[0]]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for dl in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nn: Vector2i = c + dl
			if not seen.has(nn) and (t.is_walkable(nn.x, nn.y) or t.get_cell(nn.x, nn.y) == "h"):
				seen[nn] = true
				q.append(nn)
	for c in targets:
		if not seen.has(c):
			return false
	return true

# ---------------------------------------------------------------- Toutes les salles
func test_all_sources() -> void:
	var n = 0
	for sid in DegradationManager.sources:
		var src: RoomSource = DegradationManager.sources[sid]
		var max_d = 0
		if src.data.has("chain"):
			max_d = int(src.data["chain"].get("max_depth", 0))
		if src.data.has("maze"):
			max_d = int(src.data["maze"].get("steps", 0))
		for d in range(0, max_d + 1):
			var r = DegradationManager.make_copy(sid, d)
			check(r != null, "%s#%d : construction impossible" % [sid, d])
			if r:
				check(_doors_connected(r), "%s#%d : portes non reliées" % [sid, d])
				for door in r.doors.get_children():
					var to: String = door.def.get("to", "")
					if to != "" and not to.begins_with("@"):
						check(DegradationManager.sources.has(to), "%s : porte vers salle inconnue %s" % [sid, to])
				r.free()
				n += 1
	print("Salles sources : %d, copies construites : %d" % [DegradationManager.sources.size(), n])

# ---------------------------------------------------------------- Parcours
## Toutes les salles sources sont atteignables depuis la chambre, et la fin aussi.
func test_reachability() -> void:
	var seen = {}
	var q: Array = [["house_bedroom", 0], ["n_shop", 0]]
	while not q.is_empty():
		var cur: Array = q.pop_front()
		var k = "%s#%d" % [cur[0], cur[1]]
		if seen.has(k) or not DegradationManager.sources.has(cur[0]):
			continue
		seen[k] = true
		var src: RoomSource = DegradationManager.sources[cur[0]]
		var depth: int = cur[1]
		var nexts: Array = []
		for d in src.doors:
			var w: Dictionary = d.get("when", {})
			if w.has("depth") and (depth < int(w["depth"][0]) or depth > int(w["depth"][1])):
				continue
			for ok in [true, false]:
				var r = World.resolve_door(src, depth, d, ok)
				if not r.is_empty():
					nexts.append([r[0], r[1]])
			if d.has("backwards_to"):
				nexts.append([d["backwards_to"]["room"], int(d["backwards_to"].get("depth", 0))])
		_collect_gotos(src.data, nexts)
		for n in nexts:
			q.append(n)
	var reached = {}
	for k in seen:
		reached[k.split("#")[0]] = true
	for sid in DegradationManager.sources:
		# le chapitre du souvenir s'enchaîne par les dialogues, pas par les portes
		if sid.begins_with("test_") or sid == "debug_room":
			continue
		check(reached.has(sid), "Parcours : salle %s inatteignable depuis la chambre" % sid)
	check(reached.has("z7_bedroom"), "Parcours : la fin est inatteignable")
	print("Parcours : %d salles sources atteintes, %d copies" % [reached.size(), seen.size()])

var _seen_dialogues = {}

func _collect_gotos(v: Variant, out: Array) -> void:
	if v is Dictionary:
		if v.has("goto") and v["goto"] is Dictionary and v["goto"].has("room"):
			out.append([v["goto"]["room"], int(v["goto"].get("depth", 0))])
		if v.has("dialogue") and v["dialogue"] is String:
			var dd = JsonUtil.load_json("res://data/dialogues/%s.json" % v["dialogue"])
			if dd is Dictionary and not _seen_dialogues.has(v["dialogue"]):
				_seen_dialogues[v["dialogue"]] = true
				_collect_gotos(dd, out)
		if v.has("cutscene") and v.has("to"):
			out.append([v["to"]["room"], int(v["to"].get("depth", 0))])
		for k in v:
			_collect_gotos(v[k], out)
	elif v is Array:
		for x in v:
			_collect_gotos(x, out)

# ---------------------------------------------------------------- Souvenirs
func test_souvenir_restore() -> void:
	var sid = "test_lineage"
	var f_before = DegradationManager.fidelity(sid, 10)
	var p_before = DegradationManager.descriptor(sid, 10)["active"].size()
	DegradationManager.restore(sid, 10, 20)
	var f_after = DegradationManager.fidelity(sid, 10)
	check(f_after == min(100, f_before + 20), "Souvenir : +20 F attendu (%d -> %d)" % [f_before, f_after])
	check(DegradationManager.fidelity(sid, 11) > DegradationManager.raw_fidelity(sid, 11), "Souvenir : les copies suivantes doivent en profiter")
	check(DegradationManager.fidelity(sid, 9) == DegradationManager.raw_fidelity(sid, 9), "Souvenir : la copie précédente ne doit pas changer")
	check(DegradationManager.descriptor(sid, 10)["active"].size() <= p_before, "Souvenir : les mutations ne doivent pas s'aggraver")
	DegradationManager.bonuses.clear()
	DegradationManager.invalidate()

# ---------------------------------------------------------------- Sauvegarde
func test_save_roundtrip() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	main.set_script(null)
	var root = Node2D.new()
	add_child(root)
	var cam = Camera2D.new()
	root.add_child(cam)
	var ui = CanvasLayer.new()
	add_child(ui)
	var fade = ColorRect.new()
	ui.add_child(fade)
	World.attach(self, root, cam, ui, fade)
	GameState.new_game("SAVE")
	GameState.game_seed = 4242
	World._load_room("test_lineage", 3, "", "default")
	World.player.global_position = Vector2(300, 260)
	GameState.give("cereal_bar")
	GameState.set_flag("test.flag", 7)
	GameState.kills.append("neon_flicker")
	DegradationManager.restore("test_lineage", 3, 20)
	GameState.set_flag("chest.test_chest", true)
	World._load_room("test_lineage", 3, "", "", Vector2(300, 260))
	var snap1 = SaveManager.snapshot()
	var sig1: String = World.current_room.signature()
	# on change tout, puis on recharge
	GameState.new_game("AUTRE")
	DegradationManager.bonuses.clear()
	World._load_room("test_lineage", 0, "", "default")
	var json = JSON.stringify(snap1)
	await SaveManager.apply_snapshot(JSON.parse_string(json))
	var snap2 = SaveManager.snapshot()
	snap1.erase("saved_at")
	snap2.erase("saved_at")
	check(JSON.stringify(snap1) == JSON.stringify(snap2), "Sauvegarde : l'état rechargé diffère\n%s\n%s" % [JSON.stringify(snap1), JSON.stringify(snap2)])
	check(World.current_room.signature() == sig1, "Sauvegarde : la salle rechargée diffère")
	check(World.player.global_position.distance_to(Vector2(300, 260)) < 1.0, "Sauvegarde : position du joueur")
	World.clear()
	DegradationManager.bonuses.clear()
	DegradationManager.invalidate()
	main.free()
	print("Sauvegarde : aller-retour vérifié")

# ---------------------------------------------------------------- Données
func test_data_files() -> void:
	var n = 0
	for dir in ["res://data", "res://rooms"]:
		for p in JsonUtil.list_files(dir, ".json"):
			var d = JsonUtil.load_json(p, false)
			check(d != null, "JSON invalide : " + p)
			n += 1
	for p in JsonUtil.list_files("res://data/enemies", ".json"):
		var e = JsonUtil.load_json(p)
		for pat in e.get("patterns", []):
			check(ResourceLoader.exists("res://scenes/battle/bullets/%s.gd" % pat), "%s : pattern inconnu %s" % [p, pat])
	for p in JsonUtil.list_files("res://rooms", ".json"):
		var r = JsonUtil.load_json(p)
		for npc in r.get("npcs", []):
			if npc.has("dialogue"):
				check(FileAccess.file_exists("res://data/dialogues/%s.json" % npc["dialogue"]), "%s : dialogue manquant %s" % [p, npc["dialogue"]])
		for c in r.get("chests", []):
			var it: String = c.get("contents", "")
			if it.begins_with("tape:"):
				check(FileAccess.file_exists("res://data/tapes/%s.json" % it.substr(5)), "%s : cassette inconnue %s" % [p, it])
			elif it.begins_with("souvenir:"):
				check(GameState.items_db.has(it.substr(9)), "%s : souvenir inconnu %s" % [p, it])
			elif it != "" and not it.begins_with("gold:"):
				check(GameState.items_db.has(it), "%s : objet inconnu %s" % [p, it])
	print("Fichiers de données : %d JSON valides" % n)
