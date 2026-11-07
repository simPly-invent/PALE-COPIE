## Horloge de l'énigme « Les horloges » : chaque copie avance d'un nombre fixe de minutes.
## Dans la salle source, le cadran est vide.
extends Prop

func setup(d: Dictionary, r: Node) -> void:
	var dd = d.duplicate(true)
	dd["sprite"] = d.get("sprite", "clock")
	var pid: String = d.get("puzzle", "z2_clocks")
	var t = Puzzles.clock_minutes(pid, r.depth)
	var label = "%d:%02d" % [int(t / 60) if int(t / 60) != 0 else 12, t % 60]
	if r.depth == 0 and d.get("blank_at_source", true):
		label = "--:--"
	dd["label"] = label
	dd["label_dy"] = -4
	dd["text"] = "* L'horloge indique %s." % label if label != "--:--" else "* Le cadran est vide. Pas d'aiguilles."
	dd["tags"] = ["clock"]
	dd["solid"] = false
	super.setup(dd, r)
