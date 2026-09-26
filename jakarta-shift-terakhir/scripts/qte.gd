class_name Qte
extends Node2D
## Quick-time event. Semua serangan hanya pakai tombol Z, dengan 3 variasi:
##   "tap"  : tekan Z saat lingkaran menyusut pas di tengah
##   "hold" : TAHAN Z, lepas saat meter di zona hijau
##   "mash" : tekan Z berulang-ulang sampai meter penuh
## Bertahan: lingkaran menyusut ke hero = waktu serangan kena.
##   kuning -> PARRY dengan Z (sempit) atau DODGE dengan X
##   merah  -> tidak bisa di-parry, harus DODGE dengan X

const PERFECT := 0.08
const GOOD := 0.18
const PARRY_WIN := 0.18
const DODGE_WIN := 0.32
const LOCKOUT := 0.35

var mode := ""
var kind := "tap"
var _pos := Vector2.ZERO
var _t := 0.0
var _dur := 0.8
var _result := ""
var _fill := 0.0
var _holding := false
var _mash_target := 10
var _mash_count := 0
var _last_def_press := {"parry": -99.0, "dodge": -99.0}
var _lock_until := 0.0
var _flash := 0.0
var _heavy := false
var _def_start := 0.0
var _def_len := 1.0
var auto_skill := 0.75


func _ready() -> void:
	z_index = 75
	set_process(false)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _unhandled_input(e: InputEvent) -> void:
	if mode == "":
		return
	if e is InputEventKey and e.is_echo():
		return
	var z_down : bool = e.is_action_pressed("parry") or e.is_action_pressed("act") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT)
	var z_up : bool = e.is_action_released("parry") or e.is_action_released("act") or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT)
	var x_down : bool = e.is_action_pressed("dodge") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT)
	if z_down:
		virtual_press("Z")
	elif z_up:
		virtual_release("Z")
	elif x_down:
		virtual_press("X")
	else:
		return
	get_viewport().set_input_as_handled()


func virtual_press(k: String) -> void:
	match mode:
		"prompt":
			if _result != "" or k != "Z":
				return
			match kind:
				"tap":
					var dt := absf(_t - _dur)
					_result = "perfect" if dt <= PERFECT else ("good" if dt <= GOOD else "miss")
					_flash = 1.0
				"hold":
					_holding = true
				"mash":
					_mash_count += 1
					_fill = minf(1.0, float(_mash_count) / _mash_target)
					_flash = 1.0
					Sfx.play("sfx_tick", -8.0, 0.8 + _fill)
		"defend":
			var now := _now()
			if now < _lock_until:
				return
			_lock_until = now + LOCKOUT
			if k == "Z":
				_last_def_press.parry = now
			elif k == "X":
				_last_def_press.dodge = now
			_flash = 1.0
	queue_redraw()


func virtual_release(k: String) -> void:
	if mode == "prompt" and kind == "hold" and _holding and _result == "" and k == "Z":
		_holding = false
		_result = "perfect" if (_fill >= 0.8 and _fill <= 0.95) else ("good" if (_fill >= 0.65 and _fill < 1.0) else "miss")
		_flash = 1.0


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 5.0)
	if mode == "prompt" and kind == "hold" and _holding and _result == "":
		_fill += delta / 0.9
		if _fill >= 1.0:
			_result = "miss"
	queue_redraw()


# ------------------------------------------------------------------ serangan

## kind: "tap" / "hold" / "mash". Kembalikan "perfect" / "good" / "miss".
func prompt(pos: Vector2, p_kind := "tap", dur := 0.75) -> String:
	mode = "prompt"
	kind = p_kind
	_pos = pos
	_t = 0.0
	_dur = dur
	_result = ""
	_fill = 0.0
	_holding = false
	_mash_count = 0
	_mash_target = 9
	set_process(true)
	var ok := Game.auto_chance(auto_skill)
	var perf := Game.auto_chance(0.5)
	match kind:
		"tap":
			while _t < _dur + GOOD + 0.02 and _result == "":
				if Game.autoplay and ok and _t >= _dur - (0.03 if perf else 0.13):
					virtual_press("Z")
				await get_tree().process_frame
		"hold":
			# tunggu mulai ditahan (maks 2.5 dtk), lalu tunggu dilepas
			var auto_rel := randf_range(0.82, 0.93) if perf else 0.7
			while _result == "" and (_holding or _t < 2.5):
				if Game.autoplay:
					if not _holding and _t > 0.3:
						virtual_press("Z")
					if _holding and _fill >= (auto_rel if ok else 1.1):
						virtual_release("Z")
				await get_tree().process_frame
		"mash":
			var span := 1.3
			while _t < span and _result == "":
				if Game.autoplay and fmod(_t, 0.11 if ok else 0.3) < get_process_delta_time():
					virtual_press("Z")
				await get_tree().process_frame
			_result = "perfect" if _fill >= 1.0 else ("good" if _fill >= 0.6 else "miss")
	if _result == "":
		_result = "miss"
	var r := _result
	await get_tree().create_timer(0.08).timeout
	mode = ""
	set_process(false)
	queue_redraw()
	return r


# ------------------------------------------------------------------ bertahan

## Mulai jendela bertahan. delay = waktu sampai serangan kena (untuk indikator).
func defend_begin(pos: Vector2, heavy := false, delay := 1.0) -> void:
	mode = "defend"
	_pos = pos
	_t = 0.0
	_heavy = heavy
	_def_start = _now()
	_def_len = maxf(0.15, delay)
	_last_def_press = {"parry": -99.0, "dodge": -99.0}
	_lock_until = 0.0
	set_process(true)


func defend_result(heavy := false) -> String:
	var now := _now()
	var r := "hit"
	if Game.autoplay:
		var x := randf()
		r = "parry" if (x < 0.4 and not heavy) else ("dodge" if x < 0.7 else "hit")
	else:
		var dp: float = now - _last_def_press.parry
		var dd: float = now - _last_def_press.dodge
		if not heavy and dp >= 0.0 and dp <= PARRY_WIN:
			r = "parry"
		elif dd >= 0.0 and dd <= DODGE_WIN:
			r = "dodge"
	_last_def_press = {"parry": -99.0, "dodge": -99.0}
	_lock_until = 0.0
	return r


func defend_end() -> void:
	mode = ""
	set_process(false)
	queue_redraw()


# ------------------------------------------------------------------ gambar

static func draw_key(ci: CanvasItem, c: Vector2, r: float, key: String, fill: Color) -> void:
	ci.draw_circle(c + Vector2(4, 5), r, Color(0, 0, 0, 0.5))
	ci.draw_circle(c, r, fill)
	ci.draw_arc(c, r, 0, TAU, 40, Game.INK, 4, true)
	var fs := int(r * 1.25)
	var w := Game.FONT_TITLE.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(Game.FONT_TITLE, c + Vector2(-w / 2, r * 0.42), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Game.INK)


func _caption(p: Vector2, text: String, col := Color.WHITE, fs := 28) -> void:
	var w := Game.FONT_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(Game.FONT_TITLE, p - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Game.INK)
	draw_string(Game.FONT_TITLE, p - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _bar(p: Vector2, w: float, f: float, zone := Vector2(-1, -1), col := Game.YELLOW) -> void:
	var base := p + Vector2(-w / 2, 0)
	draw_rect(Rect2(base + Vector2(5, 6), Vector2(w, 28)), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(base, Vector2(w, 28)), Color("3a3440"))
	if zone.x >= 0:
		draw_rect(Rect2(base + Vector2(w * zone.x, 0), Vector2(w * (zone.y - zone.x), 28)), Color("2f8a3c"))
	draw_rect(Rect2(base + Vector2(3, 3), Vector2((w - 6) * clampf(f, 0, 1), 22)), col)
	draw_rect(Rect2(base, Vector2(w, 28)), Game.INK, false, 4)


func _draw() -> void:
	match mode:
		"prompt":
			var fill := Game.CREAM
			if _result == "perfect":
				fill = Color("7dff8a")
			elif _result == "good":
				fill = Game.YELLOW
			elif _result == "miss":
				fill = Color("ff6a6a")
			match kind:
				"tap":
					var k := clampf(_t / _dur, 0.0, 1.3)
					var r := lerpf(120.0, 34.0, minf(k, 1.0))
					var dt := absf(_t - _dur)
					draw_arc(_pos, 34, 0, TAU, 48, Game.INK, 8, true)
					draw_arc(_pos, 34, 0, TAU, 48, Color.WHITE, 4, true)
					if _result == "":
						var col := Color("7dff8a") if dt <= PERFECT else (Game.YELLOW if dt <= GOOD else Color("ff9a3c"))
						draw_arc(_pos, r, 0, TAU, 64, Game.INK, 11, true)
						draw_arc(_pos, r, 0, TAU, 64, col, 6, true)
					draw_key(self, _pos, 30, "Z", fill)
					_caption(_pos + Vector2(0, 74), Game.L("TEKAN!", "TAP!"))
				"hold":
					var col2 := Color("7dff8a") if (_fill >= 0.8 and _fill <= 0.95) else Color("ff9a3c")
					_bar(_pos + Vector2(0, 40), 240, _fill, Vector2(0.8, 0.95), col2)
					draw_key(self, _pos, 30, "Z", Game.YELLOW if _holding else fill)
					_caption(_pos + Vector2(0, 104), Game.L("LEPAS DI HIJAU!", "RELEASE ON GREEN!") if _holding else Game.L("TAHAN Z!", "HOLD Z!"))
				"mash":
					_bar(_pos + Vector2(0, 40), 240, _fill, Vector2(-1, -1), Color("7dff8a") if _fill >= 1.0 else Game.YELLOW)
					draw_key(self, _pos, 30 * (1.0 + _flash * 0.25), "Z", fill if _result != "" else (Game.YELLOW if _flash > 0.3 else Game.CREAM))
					_caption(_pos + Vector2(0, 104), Game.L("TEKAN Z TERUS!", "MASH Z!"))
		"defend":
			var el := _now() - _def_start
			var k2 := clampf(el / _def_len, 0.0, 1.0)
			var c := _pos
			var col := Color("ff4a4a") if _heavy else Game.YELLOW
			var r2 := lerpf(150.0, 30.0, k2)
			var near := _def_len - el <= PARRY_WIN
			draw_circle(c, 30, Color(col, 0.25 + (0.5 if near else 0.0)))
			draw_arc(c, 30, 0, TAU, 40, Game.INK, 6, true)
			draw_arc(c, 30, 0, TAU, 40, Color.WHITE, 3, true)
			if el < _def_len + 0.1:
				draw_arc(c, r2, 0, TAU, 64, Game.INK, 11, true)
				draw_arc(c, r2, 0, TAU, 64, col, 6, true)
			if _heavy:
				draw_key(self, c, 22, "X", Color("7dd8ff") if _flash > 0.2 else Game.CREAM)
				_caption(c + Vector2(0, -48), Game.L("DODGE!  (X)", "DODGE!  (X)"), Color("ff6a6a"), 30)
			else:
				draw_key(self, c + Vector2(-26, 0), 18, "Z", Game.YELLOW if _flash > 0.2 else Game.CREAM)
				draw_key(self, c + Vector2(26, 0), 18, "X", Color("7dd8ff") if _flash > 0.2 else Game.CREAM)
				_caption(c + Vector2(0, -48), "PARRY (Z) / DODGE (X)", Game.YELLOW, 24)
