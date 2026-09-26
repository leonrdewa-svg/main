class_name ActionCmd
extends Node2D
## Action command ala Paper Mario:
##  - timing(): tekan saat lingkaran menyusut pas di target
##  - mash():   tekan berulang untuk mengisi meter
##  - hold():   tahan lalu lepas di zona hijau
##  - guard:    tekan tepat sebelum serangan musuh kena

signal _pressed
signal _released

var mode := ""
var _pos := Vector2.ZERO
var _t := 0.0
var _dur := 1.0
var _window := 0.14
var _result := false
var _locked := false
var _fill := 0.0
var _holding := false
var _flash := 0.0
var _press_time := -1.0
var _hint := ""


func _ready() -> void:
	z_index = 70
	set_process(false)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _unhandled_input(e: InputEvent) -> void:
	if mode == "":
		return
	if Game.is_act(e):
		get_viewport().set_input_as_handled()
		_on_press()
	elif e.is_action_released("act") or (e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		_released.emit()


func _on_press() -> void:
	match mode:
		"timing":
			if _locked or _result:
				return
			var remaining := _dur - _t
			if remaining <= _window and remaining >= -0.08:
				_result = true
				Sfx.play("sfx_tick", -2.0, 1.6)
			else:
				_locked = true
				Sfx.play("sfx_miss", -8.0, 1.4)
		"mash":
			_fill = min(1.0, _fill + 0.075)
			_flash = 1.0
			Sfx.play("sfx_tick", -6.0, 0.8 + _fill)
		"hold":
			_pressed.emit()
		"guard":
			if _press_time < 0:
				_press_time = _now()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_flash = max(0.0, _flash - delta * 6.0)
	if mode == "mash":
		_fill = max(0.0, _fill - delta * 0.1)
		if Game.autoplay and fmod(_t, 0.09) < delta:
			_on_press()
	queue_redraw()


# ---------------------------------------------------------------- timing

## Lingkaran menyusut dari besar ke target dalam `dur` detik. Selalu kembali
## setelah dur+0.1 detik supaya sinkron dengan animasi serangan.
func timing(pos: Vector2, dur := 0.8, window := 0.16) -> bool:
	mode = "timing"
	_pos = pos
	_t = 0.0
	_dur = dur
	_window = window
	_result = false
	_locked = false
	set_process(true)
	var auto_ok := Game.auto_chance(0.7)
	while _t < dur + 0.1:
		if Game.autoplay and auto_ok and not _result and _dur - _t < window * 0.6:
			_on_press()
		await get_tree().process_frame
	var ok := _result
	_end()
	if ok:
		Fx.ring(get_parent(), pos, Color("7dff8a"), 110, 0.3)
	return ok


# ---------------------------------------------------------------- mash

func mash(pos: Vector2, dur := 2.2) -> float:
	mode = "mash"
	_pos = pos
	_t = 0.0
	_dur = dur
	_fill = 0.0
	set_process(true)
	while _t < dur:
		await get_tree().process_frame
	var f := _fill
	_end()
	return f


# ---------------------------------------------------------------- hold

## Tahan tombol: meter naik; lepas di zona hijau (0.78-0.97) = sempurna.
## Kelamaan (penuh) = gagal.
func hold(pos: Vector2, fill_time := 1.1) -> float:
	mode = "hold"
	_pos = pos
	_t = 0.0
	_fill = 0.0
	_holding = false
	_hint = "TAHAN Z!"
	set_process(true)
	# Tunggu mulai ditahan (maks 2.5 detik).
	var waited := 0.0
	while not Game.act_held() and waited < 2.5:
		if Game.autoplay and waited > 0.3:
			break
		await get_tree().process_frame
		waited += get_process_delta_time()
	_holding = true
	_hint = "LEPAS DI HIJAU!"
	var auto_release := randf_range(0.8, 0.95) if Game.auto_chance(0.85) else 0.5
	var q := 0.0
	while true:
		await get_tree().process_frame
		_fill += get_process_delta_time() / fill_time
		if int(_fill * 20) != int((_fill - get_process_delta_time() / fill_time) * 20):
			Sfx.play("sfx_blip", -10.0, 0.6 + _fill)
		var held := Game.act_held() if not Game.autoplay else _fill < auto_release
		if _fill >= 1.0:
			q = 0.15
			break
		if not held:
			q = 1.0 if (_fill >= 0.78 and _fill <= 0.97) else _fill * 0.6
			break
	_end()
	return q


# ---------------------------------------------------------------- guard

## Mulai jendela guard. Panggil guard_result() tepat saat serangan kena.
func guard_begin(pos: Vector2) -> void:
	mode = "guard"
	_pos = pos
	_t = 0.0
	_press_time = -1.0
	_hint = ""
	set_process(true)


func guard_result() -> bool:
	var ok := false
	var now := _now()
	if Game.autoplay:
		ok = Game.auto_chance(0.5)
	elif _press_time > 0:
		var early := now - _press_time
		ok = early >= 0.0 and early <= 0.24
	_end()
	return ok


func _end() -> void:
	mode = ""
	_hint = ""
	set_process(false)
	queue_redraw()


# ---------------------------------------------------------------- draw

func _button(center: Vector2, r: float, lit: bool, label := "Z") -> void:
	draw_circle(center + Vector2(4, 5), r, Color(0, 0, 0, 0.5))
	draw_circle(center, r, Game.YELLOW if lit else Game.CREAM)
	draw_arc(center, r, 0, TAU, 40, Game.INK, 4, true)
	var fs := int(r * 1.2)
	draw_string(Game.FONT_TITLE, center + Vector2(-r * 0.36, r * 0.42), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Game.INK)


func _caption(pos: Vector2, text: String, col := Color.WHITE) -> void:
	var fs := 30
	var w := Game.FONT_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string_outline(Game.FONT_TITLE, pos - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Game.INK)
	draw_string(Game.FONT_TITLE, pos - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw() -> void:
	match mode:
		"timing":
			var k := clampf(_t / _dur, 0.0, 1.2)
			var r := lerpf(110.0, 30.0, min(k, 1.0))
			var in_win := (_dur - _t) <= _window and (_dur - _t) >= -0.08
			draw_circle(_pos, 30, Color(1, 1, 1, 0.25))
			draw_arc(_pos, 30, 0, TAU, 48, Game.INK, 6, true)
			draw_arc(_pos, 30, 0, TAU, 48, Color.WHITE, 3, true)
			if not _locked and not _result:
				var col := Color("7dff8a") if in_win else Color("ff9a3c")
				draw_arc(_pos, r, 0, TAU, 64, Game.INK, 10, true)
				draw_arc(_pos, r, 0, TAU, 64, col, 6, true)
			_button(_pos + Vector2(0, -82), 22, in_win and not _locked)
			if _locked:
				_caption(_pos + Vector2(0, 70), "TERLALU CEPAT!", Color("ff6a6a"))
		"mash":
			var w := 220.0
			var base := _pos + Vector2(-w / 2, 0)
			draw_rect(Rect2(base + Vector2(5, 6), Vector2(w, 30)), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(base, Vector2(w, 30)), Color("3a3440"))
			var col := Color("7dff8a") if _fill >= 0.8 else Color("ffcf30")
			draw_rect(Rect2(base + Vector2(3, 3), Vector2((w - 6) * _fill, 24)), col)
			draw_rect(Rect2(base, Vector2(w, 30)), Game.INK, false, 4)
			draw_line(base + Vector2(w * 0.8, -4), base + Vector2(w * 0.8, 34), Color.WHITE, 2)
			var bump := 1.0 + _flash * 0.25
			_button(_pos + Vector2(0, -44), 24 * bump, _flash > 0.3)
			_caption(_pos + Vector2(0, 66), "TEKAN Z BERULANG!")
			var left := maxf(0.0, _dur - _t)
			_caption(_pos + Vector2(w / 2 + 40, 26), "%.1f" % left, Color("ffd23f"))
		"hold":
			var w := 240.0
			var base := _pos + Vector2(-w / 2, 0)
			draw_rect(Rect2(base + Vector2(5, 6), Vector2(w, 30)), Color(0, 0, 0, 0.5))
			draw_rect(Rect2(base, Vector2(w, 30)), Color("3a3440"))
			draw_rect(Rect2(base + Vector2(w * 0.78, 0), Vector2(w * 0.19, 30)), Color("2f8a3c"))
			var col := Color("7dff8a") if (_fill >= 0.78 and _fill <= 0.97) else Color("ff9a3c")
			draw_rect(Rect2(base + Vector2(3, 3), Vector2((w - 6) * min(_fill, 1.0), 24)), col)
			draw_rect(Rect2(base, Vector2(w, 30)), Game.INK, false, 4)
			_button(_pos + Vector2(0, -44), 24, _holding)
			_caption(_pos + Vector2(0, 66), _hint)
		"guard":
			if _t < 0.05:
				return
			var lit := _press_time < 0
			draw_circle(_pos + Vector2(3, 4), 17, Color(0, 0, 0, 0.45))
			draw_circle(_pos, 17, Game.CREAM if lit else Color("9a949e"))
			draw_arc(_pos, 17, 0, TAU, 32, Game.INK, 3, true)
			draw_string(Game.FONT_TITLE, _pos + Vector2(-7, 9), "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Game.INK)
