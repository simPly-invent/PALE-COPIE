## Distributeur automatique : produits et prix dégradés selon la fidélité.
extends Control

signal closed

var shop: Dictionary
var fidelity = 100
var palier = 0
var entries: Array = []
var menu: ListMenu
var info: Label

func setup(sd: Dictionary, f: int, p: int) -> void:
	shop = sd
	fidelity = f
	palier = p

func _ready() -> void:
	GameState.lock("shop")
	var rng = JsonUtil.make_rng([GameState.game_seed, "shop", shop.get("id", ""), fidelity])
	for it in shop.get("items", []):
		var price = int(it["price"])
		var level = 0
		if palier >= 3:
			price = int(price * (1.0 + (100 - fidelity) / 70.0) + rng.randi_range(-2, 7))
		if palier >= 5:
			level = 1 if palier < 7 else 2
		var id: String = it["item"] if level == 0 else "%s~%d" % [it["item"], level]
		entries.append({"id": id, "price": max(1, price)})
	var names: Array = entries.map(func(e): return "%-18s %3d T" % [GameState.item_name(e["id"]), e["price"]])
	names.append("Partir")
	menu = ListMenu.create(self, Rect2(40, 60, 380, 60 + names.size() * 30), names, 20)
	info = UI.label("", 18)
	var p = UI.panel(Rect2(430, 60, 180, 140), 3)
	add_child(p)
	info.position = Vector2(440, 72)
	info.size = Vector2(160, 120)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	menu.on_move = func(i): _describe(i)
	_describe(0)
	_loop()

func _describe(i: int) -> void:
	var txt = "Tickets : %d\n" % GameState.gold
	if i < entries.size():
		txt += GameState.item_def(entries[i]["id"]).get("desc", "")
	info.text = txt

func _loop() -> void:
	await DialogueManager.say([shop.get("greeting", "* Le distributeur s'allume en grésillant.")])
	while true:
		var i: int = await menu.done
		if i < 0 or i >= entries.size():
			break
		var e: Dictionary = entries[i]
		if GameState.gold < e["price"]:
			await DialogueManager.say(["* Pas assez de tickets."])
		elif GameState.inventory.size() >= GameState.MAX_INVENTORY:
			await DialogueManager.say(["* Tes poches sont pleines."])
		else:
			GameState.gold -= e["price"]
			GameState.give(e["id"])
			AudioManager.sfx("item")
			await DialogueManager.say(["* Clonk. %s tombe dans le bac." % GameState.item_name(e["id"])])
		_describe(menu.idx)
		menu._accept_after = Time.get_ticks_msec() + 150
	GameState.unlock("shop")
	closed.emit()
	queue_free()
