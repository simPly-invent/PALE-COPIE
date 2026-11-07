## Outils de debug : F3 overlay, F4 fidélité, F5 téléportation, F6 combat.
## Désactivés dans un export « release ».
extends Node

var layer: CanvasLayer
var overlay: Label
var enabled = false
var _menu: Control

func _ready() -> void:
	enabled = OS.is_debug_build()
	layer = CanvasLayer.new()
	layer.layer = 99
	add_child(layer)
	overlay = UI.label("", 14, Color(0.6, 1.0, 0.6))
	overlay.position = Vector2(6, 4)
	overlay.add_theme_color_override("font_shadow_color", Color.BLACK)
	overlay.add_theme_constant_override("shadow_offset_x", 1)
	overlay.add_theme_constant_override("shadow_offset_y", 1)
	overlay.visible = false
	layer.add_child(overlay)

func _process(_d: float) -> void:
	if overlay.visible:
		overlay.text = overlay_text()

func overlay_text() -> String:
	var r: Room = World.current_room
	if r == null:
		return "[F3] pas de salle"
	var desc = DegradationManager.descriptor(r.source.id, r.depth)
	var lines = PackedStringArray()
	lines.append("%s  (zone %d)  profondeur %d" % [r.source.id, r.source.zone, r.depth])
	lines.append("Fidélité %d   palier %d   graine %d" % [r.fidelity, r.palier, GameState.game_seed])
	lines.append("Lignée : " + " > ".join(DegradationManager.lineage(r.source.id, r.depth).map(func(k): return "#" + k.split("#")[1])))
	lines.append("Mutations actives :")
	for m in r.active_mutations:
		lines.append("  p%d %s (copie #%d, %.0f%%)" % [DegradationManager.mutation_by_id[m["id"]].palier, m["id"], m["depth"], m["intensity"] * 100.0])
	var inactive: Array = []
	for m in desc["mutations"]:
		var found = false
		for a in r.active_mutations:
			if a["id"] == m["id"]:
				found = true
		if not found:
			inactive.append(m["id"])
	if not inactive.is_empty():
		lines.append("Restaurées (Souvenir) : " + ", ".join(inactive))
	lines.append("PV %d/%d  LV %d  Souvenirs %d  Tués %d  Épargnés %d" % [GameState.hp, GameState.max_hp(), GameState.lv, GameState.souvenirs.size(), GameState.kills.size(), GameState.spared.size()])
	lines.append("F4 : -10 F  (Maj+F4 : +10)   F5 : salles   F6 : combats")
	return "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("debug_overlay"):
		overlay.visible = not overlay.visible
	elif event.is_action_pressed("debug_fidelity") and World.current_room and not GameState.is_locked():
		var r: Room = World.current_room
		var k = DegradationManager.key(r.source.id, r.depth)
		var off = int(DegradationManager.debug_offset.get(k, 0)) + (10 if event.shift_pressed else -10)
		DegradationManager.set_debug_offset(r.source.id, r.depth, off)
		World.rebuild_current()
	elif event.is_action_pressed("debug_teleport") and World.in_game and not GameState.is_locked():
		_open_list("Salles (←/→ profondeur)", DegradationManager.sources.keys(), func(id, depth): World.goto_room(id, depth))
	elif event.is_action_pressed("debug_battle") and World.in_game and not GameState.is_locked():
		var ids: Array = []
		for p in JsonUtil.list_files("res://data/enemies", ".json"):
			ids.append(p.get_file().get_basename())
		_open_list("Combats", ids, func(id, _depth): BattleManager.start(id))

func _open_list(title: String, items: Array, cb: Callable) -> void:
	var m = preload("res://scenes/tools/debug_list.gd").new()
	m.setup(title, items, cb)
	layer.add_child(m)
