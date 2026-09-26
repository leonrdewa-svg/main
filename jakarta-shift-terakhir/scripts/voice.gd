extends Node
## Voice acting (bahasa Jepang). Baris dialog: res://assets/voice/<key>_<i>.wav
## Teriakan battle: res://assets/voice/bark_<siapa>_<jenis>_<n>.wav

var _line: AudioStreamPlayer
var _bark: AudioStreamPlayer
var _cache := {}
var enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_line = AudioStreamPlayer.new()
	_bark = AudioStreamPlayer.new()
	add_child(_line)
	add_child(_bark)
	_line.volume_db = 6.0
	_bark.volume_db = 5.0


func _get_stream(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


func line(key: String, i: int) -> void:
	_line.stop()
	if not enabled or key == "":
		return
	var s := _get_stream("res://assets/voice/%s_%d.wav" % [key, i])
	if s:
		_line.stream = s
		_line.play()


func stop() -> void:
	_line.stop()


func bark(who: String, kind: String) -> void:
	if not enabled:
		return
	var opts := []
	for n in 3:
		var s := _get_stream("res://assets/voice/bark_%s_%s_%d.wav" % [who, kind, n])
		if s:
			opts.append(s)
	if opts.is_empty():
		return
	_bark.stream = opts[randi() % opts.size()]
	_bark.play()


## Musik mengecil otomatis saat ada suara bicara (ducking).
func _process(delta: float) -> void:
	var talking := _line.playing or _bark.playing
	Sfx.duck = move_toward(Sfx.duck, 1.0 if talking else 0.0, delta * (6.0 if talking else 1.5))
