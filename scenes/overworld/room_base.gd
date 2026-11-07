## Instance d'une salle (source ou copie). Construite à partir d'un RoomSource,
## puis modifiée par les mutations. Nœuds fixes : Tiles, Props, Anchor, Doors, NPCs, Spawns.
class_name Room
extends Node2D

const TILE := 40

var source: RoomSource
var depth = 0
var fidelity = 100
var palier = 0
var zone: Dictionary = {}
var active_mutations: Array = []
var tint = {"desaturate": 0.0, "yellow_shift": 0.0, "flatten": 0.0}
var text_decay = 0.0
var erased = false
var chest_relock_level = 0
var dark = false

var tiles: TileGrid
var props: Node2D
var anchor_root: Node2D
var doors: Node2D
var npcs: Node2D
var spawns: Node2D
var lights: Node2D
var triggers: Node2D
var walls: StaticBody2D
var tint_material: ShaderMaterial

func build(src: RoomSource, d: int, f: int) -> void:
	source = src
	depth = d
	fidelity = f
	palier = DegradationManager.palier_of(f)
	zone = DegradationManager.zones.get(src.zone, {})
	name = "Room_%s_%d" % [src.id, d]
	tiles = $Tiles
	props = $Props
	anchor_root = $Anchor
	doors = $Doors
	npcs = $NPCs
	spawns = $Spawns
	lights = $Lights
	triggers = $Triggers
	walls = $Tiles/Walls
	dark = src.data.get("dark", zone.get("dark", false))
	var layout = src.layout
	if layout.is_empty():
		layout = default_layout(src.size, int(src.data.get("top_wall", 3)))
	tiles.setup(layout)
	tiles.floor_tex = Assets.tex("tiles/" + src.data.get("floor", zone.get("floor", "carpet_yellow")))
	tiles.wall_tex = Assets.tex("tiles/" + src.data.get("wall", zone.get("wall", "wall_beige")))
	if src.data.has("alt_floor"):
		tiles.alt_floor_tex = Assets.tex("tiles/" + src.data["alt_floor"])
	for p in src.props:
		if visible_now(p):
			add_prop(p)
	if not src.anchor.is_empty():
		var a = RoomAnchor.new()
		a.setup(src.anchor, self)
		anchor_root.add_child(a)
	for dd in src.doors:
		if visible_now(dd):
			var door = Door.new()
			door.setup(dd, self)
			doors.add_child(door)
	for n in src.get_list("npcs"):
		if visible_now(n):
			var npc = Npc.new()
			npc.setup(n, self)
			npcs.add_child(npc)
	for c in src.get_list("chests"):
		if visible_now(c):
			var ch = Chest.new()
			ch.setup(c, self)
			props.add_child(ch)
	for ph in src.get_list("phones"):
		if visible_now(ph):
			var s = SavePhone.new()
			s.setup(ph, self)
			props.add_child(s)
	for v in src.get_list("vendings"):
		if visible_now(v):
			var vm = Vending.new()
			vm.setup(v, self)
			props.add_child(vm)
	for pz in src.get_list("puzzles"):
		if visible_now(pz):
			var node = Puzzles.create(pz, self)
			if node:
				props.add_child(node)
	for t in src.get_list("triggers"):
		if visible_now(t):
			var tr = RoomTrigger.new()
			tr.setup(t, self)
			triggers.add_child(tr)
	var sp: Dictionary = src.data.get("spawns", {})
	for k in sp:
		var m = Marker2D.new()
		m.name = str(k)
		m.position = cell_pos(sp[k])
		spawns.add_child(m)

## Conditions d'apparition : {"when": {"depth": [a,b], "palier": [a,b], "if": "cond", "min_fidelity": n, "max_fidelity": n}}
func visible_now(d: Dictionary) -> bool:
	if d.has("if") and not d.has("when") and not GameState.check(d["if"]):
		return false
	var w: Dictionary = d.get("when", {})
	if w.is_empty():
		return true
	if w.has("depth") and (depth < int(w["depth"][0]) or depth > int(w["depth"][1])):
		return false
	if w.has("palier") and (palier < int(w["palier"][0]) or palier > int(w["palier"][1])):
		return false
	if w.has("min_fidelity") and fidelity < int(w["min_fidelity"]):
		return false
	if w.has("max_fidelity") and fidelity > int(w["max_fidelity"]):
		return false
	if w.has("if") and not GameState.check(w["if"]):
		return false
	return true

static func default_layout(size: Vector2i, top: int) -> PackedStringArray:
	var out = PackedStringArray()
	for y in size.y:
		var line = ""
		for x in size.x:
			var wall = y < top or y == size.y - 1 or x == 0 or x == size.x - 1
			line += "#" if wall else "."
		out.append(line)
	return out

func cell_pos(c: Array) -> Vector2:
	return Vector2(float(c[0]) * TILE + TILE / 2.0, (float(c[1]) + 1.0) * TILE)

func pos_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TILE)), int(floor((p.y - 1) / TILE)))

func add_prop(p: Dictionary) -> Prop:
	var prop = Prop.new()
	prop.setup(p, self)
	props.add_child(prop)
	return prop

func all_props() -> Array:
	var out: Array = []
	for c in props.get_children():
		if c is Prop:
			out.append(c)
	return out

func count_tag(tag: String) -> int:
	var n = 0
	for p in all_props():
		if p.has_tag(tag) and p.visible:
			n += 1
	return n

func anchor_node() -> RoomAnchor:
	for c in anchor_root.get_children():
		if c is RoomAnchor:
			return c
	return null

func anchor_cell() -> Vector2i:
	var a = anchor_node()
	return pos_cell(a.position) if a else Vector2i(-1, -1)

## Insère des colonnes (mutation Géométrie). L'ancre ne bouge jamais : on insère à sa droite.
func insert_columns(at: int, count: int) -> void:
	var ac = anchor_cell()
	if ac.x >= 0 and at <= ac.x:
		at = ac.x + 1
	tiles.insert_columns(at, count)
	var dx = count * TILE
	for group in [props, doors, npcs, spawns, lights, triggers]:
		for c in group.get_children():
			if c is Door:
				if c.cell.x >= at:
					c.cell.x += count
			elif c is Node2D and c.position.x >= at * TILE:
				c.position.x += dx

func insert_rows(at: int, count: int) -> void:
	var ac = anchor_cell()
	if ac.y >= 0 and at <= ac.y:
		at = ac.y + 1
	tiles.insert_rows(at, count)
	var dy = count * TILE
	for group in [props, doors, npcs, spawns, lights, triggers]:
		for c in group.get_children():
			if c is Door:
				if c.cell.y >= at:
					c.cell.y += count
			elif c is Node2D and c.position.y > at * TILE:
				c.position.y += dy

func pixel_size() -> Vector2:
	return tiles.pixel_size()

func find_door(id: String) -> Door:
	for d in doors.get_children():
		if d is Door and str(d.def.get("id", "")) == id:
			return d
	return null

## Appelé après les mutations : collisions, teinte, textes, éclairage.
func finalize() -> void:
	for d in doors.get_children():
		if d is Door:
			d.place()
	tiles.refresh_flags()
	tiles.build_collision(walls)
	# barrières invisibles autour de la salle
	var size = pixel_size()
	for r in [Rect2(-40, -40, size.x + 80, 40), Rect2(-40, size.y, size.x + 80, 40), Rect2(-40, 0, 40, size.y), Rect2(size.x, 0, 40, size.y)]:
		var s = CollisionShape2D.new()
		var rs = RectangleShape2D.new()
		rs.size = r.size
		s.shape = rs
		s.position = r.position + r.size / 2.0
		walls.add_child(s)
	tint_material = ShaderMaterial.new()
	tint_material.shader = preload("res://shaders/room_tint.gdshader")
	for k in tint:
		tint_material.set_shader_parameter(k, tint[k])
	tiles.material = tint_material
	props.material = tint_material
	npcs.material = tint_material
	doors.material = tint_material
	for n in [props, npcs, doors]:
		for c in n.get_children():
			c.use_parent_material = true
			for cc in c.get_children():
				if cc is CanvasItem:
					cc.use_parent_material = true
	# textes dégradés (palier 5) : SORTIE -> SORTE -> S RT
	for node in get_tree_nodes_in_group_local("room_text"):
		var orig: String = node.get_meta("original", "") if node is Label else node.original_text
		var t = TextFx.corrupt_label(orig, text_decay, source.id + orig)
		if node is Label:
			node.text = t
		else:
			node.set_text(t)
	var cm = CanvasModulate.new()
	cm.name = "Ambient"
	var amb: String = source.data.get("ambient", zone.get("ambient", "#ffffff"))
	cm.color = Color.from_string(amb, Color.WHITE)
	if dark:
		cm.color = Color(0.06, 0.06, 0.08)
	add_child(cm)

## Les groupes ne fonctionnent qu'une fois dans l'arbre : parcours manuel.
func get_tree_nodes_in_group_local(group: String) -> Array:
	var out: Array = []
	var stack: Array = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_in_group(group):
			out.append(n)
		stack.append_array(n.get_children())
	return out

## Signature textuelle de la salle (tests de déterminisme).
func signature() -> String:
	var parts: Array = ["F%d" % fidelity, "W%dx%d" % [tiles.width(), tiles.height()]]
	for r in tiles.rows:
		parts.append("".join(r))
	for group in [props, anchor_root, doors, npcs]:
		for c in group.get_children():
			var extra = ""
			if c is Prop:
				extra = "%s|%s|%s|%s" % [c.tex_name, c.generic, c.visible, c.label.text if c.label else ""]
			elif c is Door:
				extra = "%s|%s|%s" % [c.side, c.cell, c.def.get("to", "")]
			parts.append("%s@%s:%s" % [c.name, c.position.round(), extra])
	parts.append(str(tint))
	return "\n".join(parts)
