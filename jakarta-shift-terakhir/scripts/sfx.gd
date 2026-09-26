extends Node
## Audio manager: pool SFX + musik dengan crossfade.

const MUSIC_DB := -7.0

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _music: AudioStreamPlayer
var _music_old: AudioStreamPlayer
var current := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music_old = AudioStreamPlayer.new()
	for m in [_music, _music_old]:
		add_child(m)
		# Cadangan kalau WAV tidak ter-import sebagai loop.
		m.finished.connect(_on_music_finished.bind(m))


func _on_music_finished(m: AudioStreamPlayer) -> void:
	if m == _music and current.begins_with("bgm"):
		m.play()


func stream(name: String) -> AudioStream:
	if not _cache.has(name):
		_cache[name] = load("res://assets/audio/%s.wav" % name)
	return _cache[name]


func play(name: String, db := 0.0, pitch := 1.0, rand := 0.0) -> void:
	var p: AudioStreamPlayer = null
	for i in _pool.size():
		var c := _pool[(_next + i) % _pool.size()]
		if not c.playing:
			p = c
			break
	if p == null:
		p = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream(name)
	p.volume_db = db
	p.pitch_scale = pitch * (1.0 + randf_range(-rand, rand))
	p.play()


func music(name: String, fade := 0.8) -> void:
	if name == current:
		return
	current = name
	var tmp := _music_old
	_music_old = _music
	_music = tmp
	if _music_old.playing:
		var tw := create_tween()
		tw.tween_property(_music_old, "volume_db", -40.0, fade)
		tw.tween_callback(_music_old.stop)
	_music.stream = stream(name)
	_music.volume_db = -30.0 if fade > 0 else MUSIC_DB
	_music.play()
	if fade > 0:
		create_tween().tween_property(_music, "volume_db", MUSIC_DB, fade * 0.6)


func stop_music(fade := 0.6) -> void:
	current = ""
	if _music.playing:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -40.0, fade)
		tw.tween_callback(_music.stop)
