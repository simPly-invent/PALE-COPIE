## Reflet dans l'eau : montre la salle à un autre palier (porte disparue, maillot...).
extends Interactable

func default_solid() -> bool:
	return false

func setup(d: Dictionary, r: Node) -> void:
	super.setup(d, r)
	if sprite:
		sprite.flip_v = true
		sprite.offset = Vector2(0, sprite.texture.get_height() / 2.0 - 8)
		sprite.modulate = Color(0.55, 0.75, 1.0, 0.55)
	z_index = -6

func interact(_player: Node) -> void:
	var t = def.get("text", ["* Dans le reflet, la pièce est plus nette qu'ici."])
	await DialogueManager.say(t if t is Array else [t])
	if def.has("actions"):
		await Actions.run(def["actions"], self)
