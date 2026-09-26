class_name Qte
extends Node2D
## Quick-time event ala Expedition 33.
##  prompt(pos, key, dur) -> "perfect" / "good" / "miss"
##      satu tombol; lingkaran menyusut, tekan tombol yang tepat saat pas.
##  defend_begin(pos) + defend_result(heavy) -> "parry" / "dodge" / "hit"
##      Z (parry, jendela sempit) atau X (dodge, jendela lebar) tepat sebelum kena.
## Tombol: Z, X, L, R, U, D (panah). Bisa juga lewat tombol layar (virtual_press).

signal _pressed(key: String)

const PERFECT := 0.075
const GOOD := 0.17
const PARRY_WIN := 0.16
const DODGE_WIN := 0.30
const LOCKOUT := 0.35

var mode := ""
var _pos := Vector2.ZERO
var _key := ""
var _t := 0.0
var _dur := 0.8
var _result := ""
var _last_def_press := {"parry": -99.0, "dodge": -99.0}
var _lock_until := 0.0
var _flash := 0.0
var _heavy_hint := false
var auto_skill := 0.75   # peluang sukses di mode autoplay


func _ready() -> void:
	z_index = 75
	set_process(false)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func key_from_event(e: InputEvent) -> String:
	if e.is_echo():
		return ""
	if e.is_action_pressed("move_left"):
		return "L"
	if e.is_action_pressed("move_right"):
		return "R"
	if e.is_action_pressed("move_up"):
		return "U"
	if e.is_action_pressed("move_down"):
		return "D"
	if e.is_action_pressed("parry") or e.is_action_pressed("act"):
		return "Z"
	if e.is_action_pressed("dodge"):
		return "X"
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			return "Z"
		if e.button_index == MOUSE_BUTTON_RIGHT:
			return "X"
	return ""


func _unhandled_input(e: InputEvent) -> void:
	if mode == "":
		return
	var k := key_from_event(e)
	if k == "":
		return
	get_viewport().set_input_as_handled()
	virtual_press(k)


func virtual_press(k: String) -> void:
	match mode:
		"prompt":
			if _result != "":
				return
			var dt := _t - _dur
			if k != _key:
				_result = "miss"
			elif absf(dt) <= PERFECT:
				_result = "perfect"
			elif absf(dt) <= GOOD:
				_result = "good"
			else:
				_result = "miss"
			_flash = 1.0
		"defend":
			var now := _now()
			if now < _lock_until:
				return
			_lock_until = now + LOCKOUT
			if k == "Z":
				_last_def_press.parry = now
				_flash = 1.0
			elif k == "X":
				_last_def_press.dodge = now
				_flash = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 5.0)
	queue_redraw()


# ------------------------------------------------------------------ prompt

func prompt(pos: Vector2, key: String, dur := 0.75) -> String:
	mode = "prompt"
	_pos = pos
	_key = key
	_t = 0.0
	_dur = dur
	_result = ""
	set_process(true)
	var auto_ok := Game.auto_chance(auto_skill)
	var auto_perfect := Game.auto_chance(0.5)
	while _t < _dur + GOOD + 0.02 and _result == "":
		if Game.autoplay and auto_ok and _t >= _dur - (0.03 if auto_perfect else 0.12):
			virtual_press(key)
		await get_tree().process_frame
	if _result == "":
		_result = "miss"
	var r := _result
	# tampilkan hasil sebentar
	await get_tree().create_timer(0.06).timeout
	mode = ""
	set_process(false)
	queue_redraw()
	return r


# ------------------------------------------------------------------ bertahan

func defend_begin(pos: Vector2, heavy := false) -> void:
	mode = "defend"
	_pos = pos
	_t = 0.0
	_heavy_hint = heavy
	_last_def_press = {"parry": -99.0, "dodge": -99.0}
	_lock_until = 0.0
	set_process(true)


## Dipanggil pada saat hit mengenai. heavy = tidak bisa di-parry.
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
	# reset untuk hit berikutnya dalam rangkaian yang sama
	_last_def_press = {"parry": -99.0, "dodge": -99.0}
	_lock_until = 0.0
	return r


func defend_set_heavy(h: bool) -> void:
	_heavy_hint = h
	queue_redraw()


func defend_end() -> void:
	mode = ""
	set_process(false)
	queue_redraw()


# ------------------------------------------------------------------ gambar

static func draw_key(ci: CanvasItem, c: Vector2, r: float, key: String, fill: Color) -> void:
	ci.draw_circle(c + Vector2(4, 5), r, Color(0, 0, 0, 0.5))
	ci.draw_circle(c, r, fill)
	ci.draw_arc(c, r, 0, TAU, 40, Game.INK, 4, true)
	match key:
		"Z", "X":
			var fs := int(r * 1.25)
			var w := Game.FONT_TITLE.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(Game.FONT_TITLE, c + Vector2(-w / 2, r * 0.42), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Game.INK)
		_:
			var ang := {"R": 0.0, "D": PI / 2, "L": PI, "U": -PI / 2}[key] as float
			var pts := PackedVector2Array()
			for p in [Vector2(0.55, 0), Vector2(-0.1, -0.5), Vector2(-0.1, -0.2), Vector2(-0.5, -0.2), Vector2(-0.5, 0.2), Vector2(-0.1, 0.2), Vector2(-0.1, 0.5)]:
				pts.append(c + (p * r).rotated(ang))
			ci.draw_colored_polygon(pts, Game.INK)


func _draw() -> void:
	match mode:
		"prompt":
			var k := clampf(_t / _dur, 0.0, 1.3)
			var r := lerpf(120.0, 34.0, minf(k, 1.0))
			var dt := _t - _dur
			var in_perf := absf(dt) <= PERFECT
			var in_good := absf(dt) <= GOOD
			draw_arc(_pos, 34, 0, TAU, 48, Game.INK, 8, true)
			draw_arc(_pos, 34, 0, TAU, 48, Color.WHITE, 4, true)
			if _result == "":
				var col := Color("7dff8a") if in_perf else (Color("ffd23f") if in_good else Color("ff9a3c"))
				draw_arc(_pos, r, 0, TAU, 64, Game.INK, 11, true)
				draw_arc(_pos, r, 0, TAU, 64, col, 6, true)
			var fill := Game.CREAM
			if _result == "perfect":
				fill = Color("7dff8a")
			elif _result == "good":
				fill = Game.YELLOW
			elif _result == "miss":
				fill = Color("ff6a6a")
			draw_key(self, _pos, 30, _key, fill)
		"defend":
			var c := _pos
			var lit := _flash > 0.2
			draw_circle(c + Vector2(3, 4), 44, Color(0, 0, 0, 0.35))
			draw_circle(c, 44, Color(1, 0.25, 0.25, 0.35) if _heavy_hint else Color(1, 1, 1, 0.18))
			draw_key(self, c + Vector2(-24, 0), 18, "Z", Game.YELLOW if lit else Game.CREAM)
			draw_key(self, c + Vector2(24, 0), 18, "X", Color("7dd8ff") if lit else Game.CREAM)
			if _heavy_hint:
				draw_string(Game.FONT_TITLE, c + Vector2(-40, -52), "DODGE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("ff5a5a"))
