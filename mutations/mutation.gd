## Une mutation de la Dégradation (section 3.2). Chaque mutation concrète est un script
## qui hérite de celui-ci, avec une ressource .tres qui fixe id/palier/seuil/params.
## Les mutations n'agissent que sur les nœuds nommés de la salle :
## Tiles, Props, Anchor (jamais modifié), Doors, NPCs, Spawns.
class_name Mutation
extends Resource

@export var id = ""
@export var palier = 1
@export var seuil = 90
@export var params: Dictionary = {}
@export_multiline var description = ""

## À surcharger. `room_instance` est un Room (scenes/overworld/room_base.gd).
## Le rng est déterministe : (graine, salle source, profondeur d'apparition, id).
func apply(room_instance: Node, rng: RandomNumberGenerator) -> void:
	pass

## 0 quand F vient d'atteindre le seuil, 1 quand F = 0. Croît quand F baisse (monotonie).
func intensity(room_instance: Node) -> float:
	var f: float = room_instance.fidelity
	return clampf((seuil - f) / max(1.0, float(seuil)), 0.0, 1.0)

func is_allowed(room_source: RoomSource) -> bool:
	return not room_source.data.get("no_mutations", []).has(id)
