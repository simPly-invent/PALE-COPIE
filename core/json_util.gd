class_name JsonUtil
extends RefCounted

static var _cache: Dictionary = {}

static func load_json(path: String, use_cache := true) -> Variant:
	if use_cache and _cache.has(path):
		return _cache[path]
	if not FileAccess.file_exists(path):
		return null
	var text = FileAccess.get_file_as_string(path)
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		push_error("JSON invalide %s ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	_cache[path] = json.data
	return json.data

## Liste récursive des fichiers d'une extension sous un dossier res://.
static func list_files(dir: String, ext: String) -> Array:
	var out: Array = []
	var d = DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		var fname = f.trim_suffix(".remap")
		if fname.ends_with(ext):
			out.append(dir.path_join(fname))
	for sub in d.get_directories():
		out.append_array(list_files(dir.path_join(sub), ext))
	out.sort()
	return out

## Graine stable à partir de plusieurs valeurs.
static func hash_seed(parts: Array) -> int:
	var s = ""
	for p in parts:
		s += str(p) + "|"
	return s.hash() & 0x7fffffff

static func make_rng(parts: Array) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash_seed(parts)
	return rng

## JSON ne distingue pas entier et flottant : on remet en entiers les nombres ronds.
static func normalize(v: Variant) -> Variant:
	if v is float and v == floor(v) and abs(v) < 1e15:
		return int(v)
	if v is Array:
		var out: Array = []
		for x in v:
			out.append(normalize(x))
		return out
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = normalize(v[k])
		return d
	return v
