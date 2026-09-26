class_name TouchControls
extends CanvasLayer
## Kontrol layar sentuh untuk HP (mode Sentuh).
##  mode "world": joystick kiri + tombol AKSI (Z) + MENU
##  mode "battle": tombol Z besar (tekan/tahan) + X (dodge/batal)

var mode := "world"
var _stick_base: Control
var _stick_knob: Control
var _stick_touch := -1
var _stick_center := Vector2.ZERO
var _dir := Vector2.ZERO


func _ready() -> void:
	layer = 35
	if mode == "world":
		_make_stick()
		_button("Z", Game.L("AKSI", "ACT"), Vector2(1110, 560), 78, ["act"], Color("ffd23f"))
		_button("C", "MENU", Vector2(1210, 440), 46, ["menu"], Color("f6efe1"))
	else:
		_button("Z", "Z", Vector2(1120, 560), 84, ["act"], Color("ffd23f"))
		_button("X", "X", Vector2(980, 630), 58, ["dodge", "back"], Color("7dd8ff"))


func _button(key: String, text: String, center: Vector2, r: float, actions: Array, col: Color) -> void:
	var b := TouchButton.new()
	b.text = text
	b.radius = r
	b.col = col
	b.actions = actions
	b.position = center - Vector2(r, r)
	b.size = Vector2(r * 2, r * 2)
	add_child(b)


func _make_stick() -> void:
	_stick_base = StickDraw.new()
	_stick_base.position = Vector2(60, 440)
	_stick_base.size = Vector2(240, 240)
	_stick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_stick_base)
	_stick_center = _stick_base.position + _stick_base.size / 2
	_stick_base.gui_input.connect(_on_stick)


func _on_stick(e: InputEvent) -> void:
	var p := Vector2.ZERO
	var active := false
	if e is InputEventScreenTouch:
		active = e.pressed
		p = e.position
	elif e is InputEventScreenDrag:
		active = true
		p = e.position
	elif e is InputEventMouseButton:
		active = e.pressed
		p = e.position
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		active = true
		p = e.position
	else:
		return
	_stick_base.accept_event()
	var v := Vector2.ZERO
	if active:
		v = (p - _stick_base.size / 2) / 90.0
		if v.length() > 1.0:
			v = v.normalized()
		if v.length() < 0.2:
			v = Vector2.ZERO
	_apply(v)
	(_stick_base as StickDraw).knob = v
	_stick_base.queue_redraw()


func _apply(v: Vector2) -> void:
	_dir = v
	for pair in [["move_left", -v.x], ["move_right", v.x], ["move_up", -v.y], ["move_down", v.y]]:
		if pair[1] > 0.0:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])


func _exit_tree() -> void:
	_apply(Vector2.ZERO)


class StickDraw extends Control:
	var knob := Vector2.ZERO
	func _draw() -> void:
		var c := size / 2
		draw_circle(c, 110, Color(0, 0, 0, 0.28))
		draw_arc(c, 110, 0, TAU, 48, Color(1, 1, 1, 0.55), 4, true)
		draw_circle(c + knob * 80, 46, Color(1, 1, 1, 0.55))
		draw_arc(c + knob * 80, 46, 0, TAU, 32, Game.INK, 4, true)


class TouchButton extends Control:
	var text := "Z"
	var radius := 70.0
	var col := Color.WHITE
	var actions: Array = []
	var down := false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(e: InputEvent) -> void:
		var pressed := false
		if e is InputEventScreenTouch or e is InputEventMouseButton:
			pressed = e.pressed
		else:
			return
		accept_event()
		if pressed == down:
			return
		down = pressed
		for a in actions:
			var ev := InputEventAction.new()
			ev.action = a
			ev.pressed = pressed
			Input.parse_input_event(ev)
		queue_redraw()
	func _draw() -> void:
		var c := size / 2
		draw_circle(c + Vector2(4, 5), radius, Color(0, 0, 0, 0.45))
		draw_circle(c, radius, Color(col, 0.95 if down else 0.72))
		draw_arc(c, radius, 0, TAU, 48, Game.INK, 5, true)
		var fs := int(radius * (0.8 if text.length() <= 1 else 0.42))
		var w := Game.FONT_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(Game.FONT_TITLE, c + Vector2(-w / 2, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Game.INK)
