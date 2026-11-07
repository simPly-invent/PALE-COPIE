## Audio : bourdonnement des néons (~60 Hz + harmoniques) et drones générés en continu
## par AudioStreamGenerator, effets et musiques synthétisés par code (en attendant de vrais fichiers).
## Plus F baisse, plus le bourdonnement est fort et plus les autres sons s'étouffent (règle 3.3.7).
extends Node

const RATE := 22050.0

var ambient_player: AudioStreamPlayer
var ambient_playback: AudioStreamGeneratorPlayback
var music_player: AudioStreamPlayer
var washer_player: AudioStreamPlayer
var washer_target_db = -24.0
var sfx_pool: Array = []
var _sfx: Dictionary = {}
var _music_cache: Dictionary = {}
var current_music = ""
var fidelity = 100.0
var hum_gain = 0.0
var hum_target = 0.0
var drone_gain = 0.0
var drone_target = 0.0
var _t = 0.0
var _crackle = 0.0
var _lowpass_music: AudioEffectLowPassFilter
var _lowpass_sfx: AudioEffectLowPassFilter
var _rng = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_setup_buses()
	_build_sfx()
	ambient_player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.3
	ambient_player.stream = gen
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	ambient_player.play()
	ambient_playback = ambient_player.get_stream_playback()
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	_setup_washer()
	for i in 10:
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		sfx_pool.append(p)

func _setup_buses() -> void:
	for bus_name in ["Ambient", "Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	_lowpass_music = AudioEffectLowPassFilter.new()
	_lowpass_music.cutoff_hz = 20000
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), _lowpass_music)
	_lowpass_sfx = AudioEffectLowPassFilter.new()
	_lowpass_sfx.cutoff_hz = 20000
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"), _lowpass_sfx)
	var rev = AudioEffectReverb.new()
	rev.room_size = 0.6
	rev.wet = 0.15
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Ambient"), rev)

# ---------------------------------------------------------------- Fidélité
func set_fidelity(f: float, zone: Dictionary = {}) -> void:
	fidelity = f
	var hum_factor: float = float(zone.get("hum", 1.0))
	hum_target = DegradationManager.hum_level(f) * hum_factor
	drone_target = clampf((90.0 - f) / 85.0, 0.0, 1.0) * float(zone.get("drone", 1.0))
	var k = clampf((100.0 - f) / 95.0, 0.0, 1.0)
	_lowpass_music.cutoff_hz = lerpf(20000.0, 700.0, k * k)
	_lowpass_sfx.cutoff_hz = lerpf(20000.0, 1500.0, k * k)
	var mv: float = float(GameState.meta.get("options", {}).get("music_volume", 0.8))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(max(0.001, mv)) - k * 10.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -k * 8.0)

func on_room(room: Node) -> void:
	set_fidelity(room.fidelity, room.zone)
	# la machine à laver tourne pendant tout le jeu : forte dans les salles de sauvegarde, lointaine ailleurs
	washer_target_db = float(room.source.data.get("washer_db", room.zone.get("washer_db", -24.0)))
	var m: String = room.source.data.get("music", room.zone.get("music", ""))
	if m == "" or m == "none":
		stop_music()
	elif m != "keep":
		play_music(m, room.fidelity)

# ---------------------------------------------------------------- Ambiance continue
func _process(delta: float) -> void:
	if washer_player:
		washer_player.volume_db = move_toward(washer_player.volume_db, washer_target_db, delta * 12.0)
	hum_gain = move_toward(hum_gain, hum_target, delta * 0.5)
	drone_gain = move_toward(drone_gain, drone_target, delta * 0.3)
	if ambient_playback == null:
		return
	var n = ambient_playback.get_frames_available()
	var dt = 1.0 / RATE
	var low_f = clampf((100.0 - fidelity) / 100.0, 0.0, 1.0)
	for i in n:
		_t += dt
		var hum = sin(TAU * 60.0 * _t) * 0.45 + sin(TAU * 120.0 * _t) * 0.3 + sin(TAU * 180.0 * _t) * 0.14 + sin(TAU * 240.0 * _t) * 0.06
		# grésillement irrégulier des tubes
		if _rng.randf() < 0.0004 * (1.0 + low_f * 4.0):
			_crackle = 1.0
		_crackle *= 0.995
		hum += (_rng.randf() - 0.5) * _crackle * 0.6
		var lfo = 0.5 + 0.5 * sin(TAU * 0.07 * _t)
		var drone = sin(TAU * 41.2 * _t) * 0.5 + sin(TAU * 41.9 * _t) * 0.4 * lfo + sin(TAU * 61.7 * _t + sin(TAU * 0.11 * _t) * 2.0) * 0.25
		var s = hum * hum_gain * 0.16 + drone * drone_gain * 0.22
		ambient_playback.push_frame(Vector2(s, s))

# ---------------------------------------------------------------- Machine à laver
## Boucle de machine à laver jouée en continu. Un vrai fichier peut la remplacer :
## assets/sounds/washing_machine.ogg (ou .wav / .mp3), lu en boucle.
func _setup_washer() -> void:
	washer_player = AudioStreamPlayer.new()
	washer_player.bus = "Ambient"
	washer_player.volume_db = -40.0
	washer_player.stream = _load_washer_file()
	if washer_player.stream == null:
		washer_player.stream = _washer_loop()
	add_child(washer_player)
	washer_player.play()

func _load_washer_file() -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path = "res://assets/sounds/washing_machine." + ext
		var s: AudioStream = null
		if ResourceLoader.exists(path):
			s = load(path)
		elif FileAccess.file_exists(path):
			var g = ProjectSettings.globalize_path(path)
			match ext:
				"ogg": s = AudioStreamOggVorbis.load_from_file(g)
				"wav": s = AudioStreamWAV.load_from_file(g)
				"mp3": s = AudioStreamMP3.load_from_file(g)
		if s:
			if s is AudioStreamOggVorbis or s is AudioStreamMP3:
				s.loop = true
			elif s is AudioStreamWAV:
				s.loop_mode = AudioStreamWAV.LOOP_FORWARD
				s.loop_end = int(s.get_length() * s.mix_rate)
			return s
	return null

## Synthèse : ronron du moteur, tambour qui tourne (houle d'eau rythmée), claquements réguliers.
func _washer_loop() -> AudioStreamWAV:
	var dur = 8.0
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	var water = 0.0
	var water2 = 0.0
	for i in n:
		var t = i / RATE
		# le tambour fait exactement 6 tours en 8 s : la boucle est sans couture
		var rot = t * 0.75
		var drum = 0.5 + 0.5 * sin(TAU * rot)
		var motor = sin(TAU * 50.0 * t) * 0.25 + sin(TAU * 100.0 * t) * 0.12 + sin(TAU * 25.0 * t) * 0.18 * drum
		water = lerpf(water, rng.randf_range(-1, 1), 0.06)
		water2 = lerpf(water2, water, 0.2)
		var slosh = water2 * (0.25 + 0.75 * pow(drum, 3.0)) * 0.9
		var thump = 0.0
		var ph = fmod(rot, 1.0)
		if ph < 0.03:
			thump = sin(TAU * 60.0 * t) * (1.0 - ph / 0.03) * 0.6
		out[i] = (motor * 0.35 + slosh * 0.55 + thump) * 0.8
	return _wav(out, true)

# ---------------------------------------------------------------- Effets
func sfx(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream: AudioStreamWAV = _sfx.get(name)
	if stream == null:
		return
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

func voice(kind: String) -> void:
	var k = "voice_" + kind
	if not _sfx.has(k):
		k = "voice_default"
	sfx(k, -6.0, 1.0 + _rng.randf_range(-0.04, 0.04))

## Les pas résonnent selon la taille de la salle ; à faible fidélité, l'écho arrive trop tard.
func footstep(room_scale: float, f: float) -> void:
	sfx("step", -14.0, _rng.randf_range(0.9, 1.1))
	var delay = 0.05 + clampf(room_scale, 0.5, 4.0) * 0.06 + clampf((60.0 - f) / 60.0, 0.0, 1.0) * 0.45
	var vol = -26.0 + clampf(room_scale, 0.5, 4.0) * 2.0
	get_tree().create_timer(delay).timeout.connect(func(): sfx("step", vol, 0.85))

func _build_sfx() -> void:
	var voices = {"default": [520.0, "square"], "soft": [380.0, "sine"], "low": [190.0, "square"], "high": [820.0, "square"],
		"robot": [300.0, "saw"], "child": [660.0, "triangle"], "ghost": [440.0, "sine"], "deep": [130.0, "saw"], "mom": [470.0, "triangle"], "none": [1.0, "sine"]}
	for v in voices:
		_sfx["voice_" + v] = _tone(voices[v][0], voices[v][0], 0.045, voices[v][1], 0.35 if v != "none" else 0.0)
	_sfx["select"] = _tone(880, 880, 0.035, "square", 0.25)
	_sfx["confirm"] = _tone(660, 990, 0.07, "square", 0.3)
	_sfx["hurt"] = _mix([_noise(0.18, 0.5, 0.6), _tone(300, 80, 0.2, "square", 0.4)])
	_sfx["hit"] = _mix([_noise(0.12, 0.6, 0.3), _tone(200, 60, 0.12, "saw", 0.4)])
	_sfx["slash"] = _sweep_noise(0.25)
	_sfx["door"] = _mix([_tone(90, 50, 0.18, "sine", 0.7), _noise(0.08, 0.3, 0.8)])
	_sfx["step"] = _noise(0.035, 0.45, 0.9)
	_sfx["item"] = _arp([523, 659, 784, 1047], 0.06, "square", 0.25)
	_sfx["souvenir"] = _arp([392, 494, 587, 784, 988], 0.12, "sine", 0.35)
	_sfx["save"] = _arp([784, 988, 1175], 0.1, "triangle", 0.35)
	_sfx["heal"] = _arp([523, 784, 1047], 0.07, "triangle", 0.3)
	_sfx["spare"] = _mix([_sweep_noise(0.4), _tone(600, 200, 0.4, "sine", 0.2)])
	_sfx["flee"] = _tone(200, 900, 0.35, "triangle", 0.3)
	_sfx["levelup"] = _arp([523, 659, 784, 1047, 1319], 0.08, "square", 0.3)
	_sfx["encounter"] = _arp([1200, 0, 1200], 0.05, "square", 0.3)
	_sfx["static"] = _noise(1.2, 0.35, 0.0)
	_sfx["fall"] = _tone(800, 60, 2.2, "sine", 0.4)
	_sfx["phone_ring"] = _phone_ring()
	_sfx["entity"] = _entity_sound()
	_sfx["click"] = _noise(0.015, 0.6, 0.0)
	_sfx["wrong"] = _tone(180, 140, 0.25, "square", 0.3)
	_sfx["right"] = _arp([660, 880], 0.08, "square", 0.3)

# ---------------------------------------------------------------- Synthèse
func _wave(kind: String, phase: float) -> float:
	match kind:
		"square": return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		"saw": return fmod(phase, 1.0) * 2.0 - 1.0
		"triangle": return abs(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
	return sin(phase * TAU)

func _tone(f0: float, f1: float, dur: float, kind: String, amp: float) -> AudioStreamWAV:
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var ph = 0.0
	for i in n:
		var k = float(i) / n
		ph += lerpf(f0, f1, k) / RATE
		var env = minf(1.0, i / 60.0) * (1.0 - k)
		out[i] = _wave(kind, ph) * amp * env
	return _wav(out)

func _noise(dur: float, amp: float, decay: float) -> AudioStreamWAV:
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var last = 0.0
	for i in n:
		var k = float(i) / n
		last = lerpf(last, _rng.randf_range(-1, 1), 0.5)
		out[i] = last * amp * (1.0 - k * decay)
	return _wav(out)

func _sweep_noise(dur: float) -> AudioStreamWAV:
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var last = 0.0
	for i in n:
		var k = float(i) / n
		last = lerpf(last, _rng.randf_range(-1, 1), lerpf(0.9, 0.05, k))
		out[i] = last * 0.5 * (1.0 - k)
	return _wav(out)

func _arp(freqs: Array, step: float, kind: String, amp: float) -> AudioStreamWAV:
	var per = int(step * RATE)
	var out = PackedFloat32Array()
	out.resize(per * freqs.size() + per * 2)
	var ph = 0.0
	for j in freqs.size():
		for i in per * 3:
			var idx = j * per + i
			if idx >= out.size():
				break
			ph += float(freqs[j]) / RATE
			var env = (1.0 - float(i) / (per * 3)) * minf(1.0, i / 40.0)
			out[idx] += _wave(kind, ph) * amp * env * (0.0 if freqs[j] == 0 else 1.0) * 0.6
	return _wav(out)

func _mix(streams: Array) -> AudioStreamWAV:
	var datas: Array = []
	var n = 0
	for s in streams:
		var d: PackedByteArray = s.data
		datas.append(d)
		n = max(n, d.size() / 2)
	var out = PackedFloat32Array()
	out.resize(n)
	for d in datas:
		for i in d.size() / 2:
			out[i] += d.decode_s16(i * 2) / 32768.0
	return _wav(out)

func _phone_ring() -> AudioStreamWAV:
	var dur = 2.4
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t = i / RATE
		var on = fmod(t, 1.2) < 0.8
		if on:
			var am = 0.5 + 0.5 * sign(sin(TAU * 20.0 * t))
			out[i] = (sin(TAU * 440.0 * t) + sin(TAU * 480.0 * t)) * 0.18 * am
	return _wav(out)

## Le son de l'Entité : toujours le même. Une descente désaccordée, puis trois claquements.
func _entity_sound() -> AudioStreamWAV:
	var dur = 2.6
	var n = int(dur * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var rng = RandomNumberGenerator.new()
	rng.seed = 1997
	var ph1 = 0.0
	var ph2 = 0.0
	var last = 0.0
	for i in n:
		var t = i / RATE
		var k = t / dur
		ph1 += lerpf(110.0, 46.0, k) / RATE
		ph2 += lerpf(113.0, 44.0, k) / RATE
		last = lerpf(last, rng.randf_range(-1, 1), 0.08)
		var s = (_wave("saw", ph1) + _wave("saw", ph2)) * 0.18 * (1.0 - k * 0.7) + last * 0.25
		for c in [1.9, 2.15, 2.4]:
			if t > c and t < c + 0.02:
				s += rng.randf_range(-0.8, 0.8)
		out[i] = s
	return _wav(out)

func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = int(RATE)
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

# ---------------------------------------------------------------- Musique
## Musiques décrites dans data/music/<id>.json. Dans les copies, la même musique est rejouée
## ralentie, désaccordée, avec des notes qui manquent (selon le palier).
func play_music(id: String, f: float = 100.0) -> void:
	var palier = DegradationManager.palier_of(f)
	var key = "%s@%d" % [id, palier]
	if current_music == key and music_player.playing:
		return
	current_music = key
	if not _music_cache.has(key):
		var s = render_music(id, palier)
		if s == null:
			stop_music()
			return
		_music_cache[key] = s
	music_player.stream = _music_cache[key]
	music_player.play()

func stop_music() -> void:
	current_music = ""
	music_player.stop()

const NOTE_INDEX := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

static func note_freq(n: String) -> float:
	if n == "R" or n == "":
		return 0.0
	var name = n[0]
	var i = 1
	var semi: int = NOTE_INDEX.get(name, 0)
	if n.length() > i and (n[i] == "#" or n[i] == "b"):
		semi += 1 if n[i] == "#" else -1
		i += 1
	var octave = int(n.substr(i)) if n.length() > i else 4
	var midi = 12 * (octave + 1) + semi
	return 440.0 * pow(2.0, (midi - 69) / 12.0)

func render_music(id: String, palier: int) -> AudioStreamWAV:
	var d = JsonUtil.load_json("res://data/music/%s.json" % id)
	if not (d is Dictionary):
		return null
	var bpm: float = float(d.get("bpm", 90)) * (1.0 - palier * 0.07)
	var beat = 60.0 / bpm
	var detune = palier * 0.012
	var miss = palier * 0.07
	var tracks: Array = []
	for key in ["melody", "bass"]:
		if d.has(key):
			tracks.append([d[key], d.get(key + "_wave", "triangle" if key == "melody" else "sine"), float(d.get(key + "_amp", 0.22 if key == "melody" else 0.18))])
	var total = 0.0
	for tr in tracks:
		var t = 0.0
		for tok in str(tr[0]).split(" ", false):
			var parts = tok.split(":")
			t += float(parts[1] if parts.size() > 1 else "1") * beat
		total = max(total, t)
	var n = int(total * RATE)
	var out = PackedFloat32Array()
	out.resize(n)
	var rng = RandomNumberGenerator.new()
	for tr in tracks:
		var t = 0.0
		var idx = 0
		for tok in str(tr[0]).split(" ", false):
			idx += 1
			var parts = tok.split(":")
			var dur = float(parts[1] if parts.size() > 1 else "1") * beat
			var f = note_freq(parts[0])
			rng.seed = hash(id + str(idx) + str(tr[1]))
			if f > 0 and rng.randf() >= miss:
				f *= pow(2.0, rng.randf_range(-detune, detune) * 12.0 / 12.0)
				var start = int(t * RATE)
				var len = int(dur * RATE * 0.92)
				var ph = 0.0
				for i in len:
					if start + i >= n:
						break
					ph += f * (1.0 + sin(i / RATE * 5.0) * detune * 0.5) / RATE
					var env = minf(1.0, i / 200.0) * (1.0 - float(i) / len) * 0.8 + 0.2 * (1.0 - float(i) / len)
					out[start + i] += _wave(tr[1], ph) * tr[2] * env
			t += dur
	return _wav(out, d.get("loop", true))
