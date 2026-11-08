## Accès aux images du jeu. Si un asset manque, un placeholder est généré
## d'après data/asset_manifest.json (rectangle, polygone ou cercle coloré).
class_name Assets
extends RefCounted

const MANIFEST_PATH := "res://data/asset_manifest.json"

static var _cache: Dictionary = {}
static var _manifest: Dictionary = {}
static var _manifest_loaded = false
static var missing_logged: Dictionary = {}
static var col_override = Color(0, 0, 0, 0)

## name : "chair_red" (cherché dans assets/sprites/) ou "tiles/carpet_yellow", "portraits/cat", "vhs/static"...
static func tex(name: String) -> Texture2D:
	if name == "":
		return null
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D = null
	for path in _candidate_paths(name):
		if ResourceLoader.exists(path):
			t = load(path)
			break
		if FileAccess.file_exists(path):
			var img = Image.load_from_file(ProjectSettings.globalize_path(path))
			if img:
				t = ImageTexture.create_from_image(img)
				break
	if t == null:
		t = placeholder(name)
	_cache[name] = t
	return t

static func has_real(name: String) -> bool:
	for path in _candidate_paths(name):
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return true
	return false

static func _candidate_paths(name: String) -> Array:
	if name.contains("/"):
		return ["res://assets/%s.png" % name]
	return ["res://assets/sprites/%s.png" % name, "res://assets/%s.png" % name]

static func manifest() -> Dictionary:
	if not _manifest_loaded:
		_manifest_loaded = true
		var data = JsonUtil.load_json(MANIFEST_PATH)
		if data is Dictionary:
			for entry in data.get("placeholders", []):
				_manifest[entry["name"]] = entry
	return _manifest

static func placeholder(name: String) -> Texture2D:
	var entry: Dictionary = manifest().get(name, {})
	if not missing_logged.has(name):
		missing_logged[name] = true
		if entry.is_empty():
			push_warning("Asset manquant et absent du manifeste : %s" % name)
	var size: Array = entry.get("size", [32, 32])
	var col = Color.from_string(entry.get("color", "#ff00ff"), Color.MAGENTA)
	var shape: String = entry.get("shape", "rect")
	var w = int(size[0])
	var h = int(size[1])
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline = col.darkened(0.6)
	for y in h:
		for x in w:
			var inside = true
			col_override = Color(0, 0, 0, 0)
			match shape:
				"circle":
					var dx = (x + 0.5 - w / 2.0) / (w / 2.0)
					var dy = (y + 0.5 - h / 2.0) / (h / 2.0)
					inside = dx * dx + dy * dy <= 1.0
				"poly":
					# triangle/silhouette : plus large en bas
					var half = (w / 2.0) * (0.35 + 0.65 * float(y) / max(1, h - 1))
					inside = abs(x + 0.5 - w / 2.0) <= half
				"washer":
					# machine à laver : caisse avec un hublot
					var r = min(w, h) * 0.3
					var c = Vector2(w / 2.0, h * 0.58)
					var p = Vector2(x + 0.5, y + 0.5)
					inside = true
					if p.distance_to(c) < r and p.distance_to(c) > r - 3:
						col_override = Color(0.25, 0.25, 0.3)
					elif p.distance_to(c) <= r - 3:
						col_override = Color(0.35, 0.5, 0.75)
					elif y < h * 0.18 and y > h * 0.12:
						col_override = Color(0.5, 0.5, 0.55)
				"lock":
					# cadenas : anse en haut, corps plein en bas, trou de serrure
					var cx = w / 2.0
					var by = h * 0.45
					if y < by:
						var r = w * 0.32
						var dd = Vector2(x + 0.5 - cx, y + 0.5 - by).length()
						inside = dd <= r and dd >= r - 2.5 and y + 0.5 <= by
					else:
						inside = true
						if abs(x + 0.5 - cx) < 1.5 and y > h * 0.6 and y < h * 0.85:
							col_override = Color(0.2, 0.15, 0.05)
				"figure":
					# silhouette humaine grossière
					var cx = w / 2.0
					var head = h * 0.22
					if y < head:
						var r = head / 2.0
						inside = Vector2(x + 0.5 - cx, y + 0.5 - r).length() <= r
					else:
						inside = abs(x + 0.5 - cx) <= w * (0.28 if y < h * 0.7 else 0.18)
			if inside:
				img.set_pixel(x, y, col if col_override.a == 0 else col_override)
	# contour
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0:
				var edge = x == 0 or y == 0 or x == w - 1 or y == h - 1
				if not edge:
					edge = img.get_pixel(x - 1, y).a == 0 or img.get_pixel(x + 1, y).a == 0 or img.get_pixel(x, y - 1).a == 0 or img.get_pixel(x, y + 1).a == 0
				if edge:
					img.set_pixel(x, y, outline)
	return ImageTexture.create_from_image(img)

## Texture « générique » : un bloc uni de la couleur moyenne (mutation Détail).
static func generic_block(name: String) -> Texture2D:
	var key = "__block__" + name
	if _cache.has(key):
		return _cache[key]
	var src = tex(name)
	var img = src.get_image()
	var sum = Color(0, 0, 0, 0)
	var n = 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var c = img.get_pixel(x, y)
			if c.a > 0.5:
				sum += c
				n += 1
	var avg = Color(0.6, 0.6, 0.5)
	if n > 0:
		avg = Color(sum.r / n, sum.g / n, sum.b / n, 1.0)
	var out = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var used = img.get_used_rect()
	var inner = Rect2i(used.position + Vector2i(2, used.size.y / 3), Vector2i(max(2, used.size.x - 4), max(2, used.size.y * 2 / 3)))
	out.fill_rect(inner, avg)
	var t = ImageTexture.create_from_image(out)
	_cache[key] = t
	return t
