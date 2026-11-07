## Énigme « Le plongeon » : suivre les carreaux de couleur qui n'ont pas mué, dans l'ordre
## rouge, jaune, vert, bleu. Un carreau délavé ou dans le mauvais ordre : retour au départ.
extends Node2D

var def: Dictionary
var room: Node
var order = ["r", "y", "g", "b"]
var _last = -1
var _busy = false
var _overlay_layer: CanvasLayer

func _process(_d: float) -> void:
	if _overlay_layer:
		_overlay_layer.visible = is_visible_in_tree()

func setup(d: Dictionary, r: Node) -> void:
	def = d
	room = r
	name = str(d.get("id", "tile_path"))
	var pd = Puzzles.data(d.get("puzzle", ""))
	if pd.has("order"):
		order = pd["order"]
	# les carreaux qui n'ont pas mué gardent leur vraie couleur : rendus au-dessus des effets d'écran
	var layer = CanvasLayer.new()
	layer.layer = 51
	layer.follow_viewport_enabled = true
	var drawer = Node2D.new()
	drawer.draw.connect(func():
		var t: TileGrid = room.tiles
		for y in t.height():
			for x in t.width():
				var c = t.get_cell(x, y)
				if t.tile_colors.has(c) and c != "x":
					drawer.draw_rect(Rect2(x * TileGrid.TILE + 6, y * TileGrid.TILE + 6, TileGrid.TILE - 12, TileGrid.TILE - 12), t.tile_colors[c], false, 6.0))
	layer.add_child(drawer)
	add_child(layer)
	_overlay_layer = layer

func _physics_process(_delta: float) -> void:
	var p = World.player
	if p == null or _busy or GameState.is_locked() or p.get_parent() != room:
		return
	var c: Vector2i = room.pos_cell(p.global_position - Vector2(0, 2))
	var ch: String = room.tiles.get_cell(c.x, c.y)
	if ch == "." or ch == "o":
		_last = -1
		return
	if ch == "x":
		_fail()
		return
	var k = order.find(ch)
	if k < 0:
		return
	if _last == -1:
		if k != 0:
			_fail()
		else:
			_last = 0
	elif k == _last:
		return
	elif k == (_last + 1) % order.size():
		_last = k
	else:
		_fail()

func _fail() -> void:
	_busy = true
	_last = -1
	var pd = Puzzles.data(def.get("puzzle", ""))
	AudioManager.sfx("wrong")
	await DialogueManager.say(pd.get("fail_text", ["* Tu manques d'air. Tu remontes."]))
	var start: Array = pd.get("start", [1, 6])
	World.player.global_position = room.cell_pos(start)
	_busy = false
