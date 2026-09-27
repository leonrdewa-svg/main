class_name Prologue
extends Node2D
## Pembukaan sinematik sebelum eksplorasi: latar hidup yang bergeser pelan,
## potongan kertas karakter, kartu judul adegan, dan dialog bersuara.
## Data adegan ada di Story.PROLOG. Tahan X (atau ketuk LEWATI) untuk melompati.

const FLOOR_Y := 772.0   # kaki di bawah kotak dialog: bingkai "setengah badan" ala visual novel

var dialog: Dialogue
var skipped := false
var bg_holder: Node2D
var bg: LiveBg
var cast_root: Node2D
var cast := {}            # id -> Sprite2D
var ui: CanvasLayer
var tint: ColorRect
var cap_box: Panel
var cap_title: Label
var cap_sub: Label
var skip_btn: Button
var _bg_path := ""
var _mood := ""
var _hold := 0.0
var _t := 0.0
var _pan: Tween
var _papers: CPUParticles2D


func _ready() -> void:
	bg_holder = Node2D.new()
	add_child(bg_holder)
	cast_root = Node2D.new()
	add_child(cast_root)
	ui = CanvasLayer.new()
	ui.layer = 40
	add_child(ui)
	tint = ColorRect.new()
	tint.size = Vector2(1280, 720)
	tint.color = Color(0, 0, 0, 0)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	# bilah sinema atas & bawah
	for i in 2:
		var b := ColorRect.new()
		b.color = Game.INK
		b.size = Vector2(1280, 54)
		b.position = Vector2(0, -54.0 if i == 0 else 720.0)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(b)
		b.create_tween().tween_property(b, "position:y", 0.0 if i == 0 else 666.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cap_box = Panel.new()
	cap_box.size = Vector2(540, 108)
	cap_box.position = Vector2(-600, 74)
	cap_box.rotation = deg_to_rad(-2)
	cap_box.add_theme_stylebox_override("panel", Game.paper_box(Color("201a26"), Game.YELLOW, 6, 6))
	cap_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(cap_box)
	cap_title = Fx.label("", 50, Game.YELLOW, 8)
	cap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cap_title.position = Vector2(22, 4)
	cap_title.size = Vector2(500, 60)
	cap_box.add_child(cap_title)
	cap_sub = Fx.label("", 23, Game.CREAM, 6, Game.FONT_UI)
	cap_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cap_sub.position = Vector2(24, 64)
	cap_sub.size = Vector2(500, 34)
	cap_box.add_child(cap_sub)
	skip_btn = Button.new()
	skip_btn.theme = Game.ui_theme
	skip_btn.text = Game.L("LEWATI >>", "SKIP >>") if Game.touch_mode else Game.L("Tahan X: lewati", "Hold X: skip")
	skip_btn.flat = true
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	skip_btn.add_theme_font_size_override("font_size", 22)
	skip_btn.position = Vector2(1040, 10)
	skip_btn.size = Vector2(220, 36)
	skip_btn.pressed.connect(_skip)
	ui.add_child(skip_btn)


func run(scenes: Array, p_dialog: Dialogue) -> void:
	dialog = p_dialog
	dialog.line_started.connect(_on_line)
	for sc in scenes:
		if skipped:
			break
		await _scene(sc)
	if dialog.line_started.is_connected(_on_line):
		dialog.line_started.disconnect(_on_line)


func _process(delta: float) -> void:
	_t += delta
	if Input.is_action_pressed("back"):
		_hold += delta
		if _hold > 0.7 and not skipped:
			_skip()
	else:
		_hold = 0.0
	if _mood == "alarm":
		tint.color = Color(0.85, 0.02, 0.12, 0.22 + 0.12 * sin(_t * 5.5))
	for id in cast:
		var s: Sprite2D = cast[id]
		s.rotation = sin(_t * 1.4 + s.position.x * 0.013) * 0.014


func _skip() -> void:
	if skipped:
		return
	skipped = true
	skip_btn.disabled = true
	dialog.abort()


# ------------------------------------------------------------------ adegan

func _scene(sc: Dictionary) -> void:
	var path: String = sc.get("bg", _bg_path)
	if path != _bg_path:
		if _bg_path != "":
			await get_parent().cover()
			_clear_cast()
		_set_bg(path, sc.get("style", ""), sc.get("pan", [0.0, -240.0]))
		await get_parent().reveal()
	_set_mood(sc.get("mood", ""))
	if sc.has("music"):
		Sfx.music(sc.music)
	if sc.has("sfx"):
		Sfx.play(sc.sfx, -2.0)
	if sc.has("caption"):
		_caption(sc.caption, sc.get("sub", ["", ""]))
	for c in sc.get("cast", []):
		_enter(c)
	if sc.get("shake", false):
		_shake(14.0)
	await get_tree().create_timer(float(sc.get("hold", 0.7))).timeout
	Game.shot("prolog_" + String(sc.get("key", "x")))
	if skipped:
		return
	if sc.has("key"):
		await dialog.play(Story.D[sc.key], sc.key)
	if skipped:
		return
	if sc.has("after"):
		await _after(sc.after)


func _set_bg(path: String, style: String, pan: Array) -> void:
	if bg:
		bg.queue_free()
	if _pan:
		_pan.kill()
	bg = LiveBg.new()
	bg_holder.add_child(bg)
	bg.setup(path, style, 1.0, 0)
	bg_holder.position = Vector2(float(pan[0]), 0)
	_pan = create_tween()
	_pan.tween_property(bg_holder, "position:x", float(pan[1]), 38.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bg_path = path


func _set_mood(m: String) -> void:
	_mood = m
	var col := Color(0, 0, 0, 0)
	match m:
		"dusk":
			col = Color(1.0, 0.5, 0.2, 0.10)
		"night":
			col = Color(0.05, 0.08, 0.3, 0.16)
		"alarm":
			col = Color(0.85, 0.02, 0.12, 0.2)
	if m != "alarm":
		tint.create_tween().tween_property(tint, "color", col, 0.8)
	if m == "alarm" and _papers == null:
		_papers = _black_papers()
	elif m != "alarm" and _papers:
		_papers.emitting = false
		_papers = null


func _caption(title: Array, sub: Array) -> void:
	cap_title.text = Game.L(title[0], title[1])
	cap_sub.text = Game.L(sub[0], sub[1])
	cap_box.position.x = -600
	var tw := create_tween()
	tw.tween_property(cap_box, "position:x", 28.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("sfx_paper", -4.0, 0.9)


## Karakter masuk sebagai potongan kertas yang berdiri (skala Y 0 -> 1).
func _enter(c: Dictionary) -> void:
	var id: String = c.id
	var tex: Texture2D = load(c.tex)
	var h: float = c.get("h", 540.0)
	var fy: float = c.get("y", FLOOR_Y)
	var s: Sprite2D = cast.get(id)
	if s == null:
		s = Sprite2D.new()
		var sh := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(Vector2(cos(a) * 60, sin(a) * 12))
		sh.polygon = pts
		sh.color = Color(0, 0, 0, 0.35)
		sh.position = Vector2(c.x, fy)
		sh.name = "sh_" + id
		cast_root.add_child(sh)
		cast_root.add_child(s)
		cast[id] = s
	s.texture = tex
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	s.position = Vector2(c.x, fy)
	s.set_meta("base_y", fy)
	s.z_index = int(fy)
	s.flip_h = c.get("flip", false)
	s.self_modulate = c.get("tint", Color.WHITE)
	var k := h / tex.get_height()
	s.scale = Vector2(k, 0.0)
	var tw := s.create_tween()
	tw.tween_interval(float(c.get("delay", 0.0)))
	tw.tween_property(s, "scale", Vector2(k, k), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("sfx_paper", -8.0, 1.2, 0.1)


func _clear_cast() -> void:
	for n in cast_root.get_children():
		n.queue_free()
	cast.clear()


## Sorot pembicara: yang bicara terang & sedikit melompat, lainnya redup.
func _on_line(who: String) -> void:
	for id in cast:
		var s: Sprite2D = cast[id]
		var on: bool = id == who
		s.create_tween().tween_property(s, "modulate", Color.WHITE if on or not cast.has(who) else Color(0.62, 0.62, 0.7), 0.2)
		if on:
			var tw := s.create_tween()
			var by: float = s.get_meta("base_y", FLOOR_Y)
			tw.tween_property(s, "position:y", by - 14.0, 0.09).set_ease(Tween.EASE_OUT)
			tw.tween_property(s, "position:y", by, 0.14).set_ease(Tween.EASE_IN)


func _after(a: Dictionary) -> void:
	if a.has("transform"):
		var s: Sprite2D = cast.get(a.transform)
		if s == null:
			return
		var tex: Texture2D = load(a.tex)
		var k: float = float(a.get("h", 460.0)) / tex.get_height()
		Sfx.play("sfx_boss_roar", -4.0)
		var tw := s.create_tween()
		tw.tween_property(s, "scale:x", 0.0, 0.12)
		tw.tween_callback(func():
			s.texture = tex
			s.offset = Vector2(0, -tex.get_height() / 2.0)
			s.self_modulate = Color.WHITE)
		tw.tween_property(s, "scale", Vector2(k, k), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.burst(cast_root, s.position + Vector2(0, -160), "paper", 36, 1.4)
		_flash(Color(1, 0.2, 0.3, 0.7))
		_shake(18.0)
		await tw.finished
		await get_tree().create_timer(0.5).timeout


func _flash(col: Color) -> void:
	var f := ColorRect.new()
	f.size = Vector2(1280, 720)
	f.color = col
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.45)
	tw.tween_callback(f.queue_free)


func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 8:
		var o := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * amount * (1.0 - i / 8.0)
		tw.tween_property(cast_root, "position", o, 0.04)
	tw.tween_property(cast_root, "position", Vector2.ZERO, 0.05)


## Kertas hitam beterbangan (saat kerasukan massal).
func _black_papers() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = Vector2(640, -30)
	p.z_index = 20
	p.amount = 46
	p.lifetime = 5.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	var img := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	p.texture = ImageTexture.create_from_image(img)
	p.direction = Vector2(0.3, 1)
	p.spread = 30
	p.initial_velocity_min = 40
	p.initial_velocity_max = 110
	p.gravity = Vector2(-10, 40)
	p.angular_velocity_min = -220
	p.angular_velocity_max = 220
	p.angle_max = 360
	p.scale_amount_min = 1.2
	p.scale_amount_max = 2.6
	p.color = Color(0.08, 0.06, 0.1, 0.92)
	ui.add_child(p)
	ui.move_child(p, 1)
	return p
