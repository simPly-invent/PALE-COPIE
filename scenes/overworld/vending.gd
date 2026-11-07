## Distributeur automatique = boutique. Prix et produits se dégradent avec la fidélité.
class_name Vending
extends Interactable

func default_sprite() -> String:
	return "vending_machine"

func interact(_player: Node) -> void:
	var shop = JsonUtil.load_json("res://data/items/shops.json")
	var sd: Dictionary = {}
	if shop is Dictionary:
		sd = shop.get(def.get("shop", ""), {})
	if sd.is_empty():
		await DialogueManager.say(["* Le distributeur ronronne. Il est vide."])
		return
	var ui = preload("res://scenes/ui/shop_menu.gd").new()
	ui.setup(sd, room.fidelity, room.palier)
	World.ui_layer.add_child(ui)
	await ui.closed
