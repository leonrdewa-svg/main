class_name LiveBg
extends Node2D
## Latar yang hidup: gambar + shader (daun bergoyang, neon, cahaya),
## gerak kamera pelan, dan partikel sesuai suasana.
## style: "sunset" / "day" / "night" / "rain"

const SHADER := preload("res://scripts/live_bg.gdshader")

var sprite: Sprite2D
var _t := 0.0
var _base_scale := 1.0
var zoom_extra := 0.03


static func style_for(path: String) -> String:
	if "scbd" in path:
		return "rain"
	if "blok_m" in path:
		return "night"
	if "dukuh" in path:
		return "sunset"
	return "day"


var width := 1280.0
var panels := 1


## panels > 1: panorama (gambar, cermin, gambar, ...) yang menyambung mulus.
func setup(path: String, style := "", extra_scale := 1.0, p_panels := 1) -> void:
	if style == "":
		style = style_for(path)
	panels = p_panels
	var tex: Texture2D = load(path)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("sway", 0.0035)
	m.set_shader_parameter("neon", 1.0 if style in ["night", "rain"] else 0.0)
	m.set_shader_parameter("warm", 1.0 if style in ["sunset", "day"] else 0.35)
	if panels <= 1:
		sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.position = Vector2(640, 360)
		_base_scale = maxf(1280.0 / tex.get_width(), 720.0 / tex.get_height()) * extra_scale * (1.0 + zoom_extra)
		sprite.scale = Vector2.ONE * _base_scale
		sprite.material = m
		add_child(sprite)
	else:
		var sc := 720.0 / tex.get_height()
		var pw := tex.get_width() * sc
		width = pw * panels
		for i in panels:
			var p := Sprite2D.new()
			p.texture = tex
			p.centered = false
			p.scale = Vector2(sc, sc)
			p.flip_h = i % 2 == 1
			p.position = Vector2(pw * i, 0)
			p.material = m
			add_child(p)
	match style:
		"sunset":
			_motes(Color(1.0, 0.8, 0.5, 0.7), 26, Vector2(0, -12))
			_mist(Color(1.0, 0.6, 0.4, 0.10))
		"day":
			_leaves()
			_mist(Color(1, 1, 1, 0.12))
			_motes(Color(1, 1, 0.85, 0.5), 16, Vector2(8, -6))
		"night":
			_motes(Color(1.0, 0.9, 0.5, 0.85), 22, Vector2(0, -20))
			_motes(Color(1.0, 0.3, 0.6, 0.6), 10, Vector2(0, -10))
		"rain":
			_rain()
			_motes(Color(0.4, 0.9, 1.0, 0.6), 14, Vector2(0, -10))


func _process(delta: float) -> void:
	_t += delta
	if sprite:
		var z := 1.0 + sin(_t * 0.07) * 0.012
		sprite.scale = Vector2.ONE * _base_scale * z
		sprite.position = Vector2(640 + sin(_t * 0.05) * 10.0, 360 + sin(_t * 0.09) * 4.0)


func _dot_tex(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var dx := (x + 0.5) / w * 2.0 - 1.0
			var dy := (y + 0.5) / h * 2.0 - 1.0
			var a := clampf(1.0 - sqrt(dx * dx + dy * dy), 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(img)


func _base_particles(amount: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = int(amount * maxf(1.0, width / 1280.0))
	p.lifetime = life
	p.preprocess = life
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width / 2.0 + 60, 380)
	p.position = Vector2(width / 2.0, 360)
	p.gravity = Vector2.ZERO
	p.z_index = 1
	add_child(p)
	return p


## Debu/kunang-kunang yang melayang pelan dan berkelip.
func _motes(col: Color, n: int, drift: Vector2) -> void:
	var p := _base_particles(n, 7.0)
	p.texture = _dot_tex(16, 16)
	p.direction = Vector2(0, -1)
	p.spread = 180
	p.initial_velocity_min = 6
	p.initial_velocity_max = 22
	p.gravity = drift
	p.scale_amount_min = 0.3
	p.scale_amount_max = 1.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0, 0.2, 0.5, 0.8, 1])
	g.colors = PackedColorArray([Color(col, 0), col, Color(col, col.a * 0.3), col, Color(col, 0)])
	p.color_ramp = g


func _leaves() -> void:
	var p := _base_particles(14, 9.0)
	var img := Image.create(10, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color("5f9a3a"))
	for x in 10:
		img.set_pixel(x, 0, Color(0, 0, 0, 0))
		img.set_pixel(x, 5, Color(0, 0, 0, 0))
	p.texture = ImageTexture.create_from_image(img)
	p.emission_rect_extents = Vector2(width / 2.0 + 60, 20)
	p.position = Vector2(width / 2.0, -20)
	p.direction = Vector2(1, 1)
	p.spread = 30
	p.initial_velocity_min = 30
	p.initial_velocity_max = 70
	p.gravity = Vector2(12, 22)
	p.angular_velocity_min = -120
	p.angular_velocity_max = 120
	p.angle_max = 360
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1, 1, 1, 0.9)


func _rain() -> void:
	var p := _base_particles(160, 0.9)
	var img := Image.create(2, 26, false, Image.FORMAT_RGBA8)
	for y in 26:
		img.set_pixel(0, y, Color(0.8, 0.9, 1.0, y / 26.0 * 0.7))
		img.set_pixel(1, y, Color(0.8, 0.9, 1.0, y / 26.0 * 0.4))
	p.texture = ImageTexture.create_from_image(img)
	p.emission_rect_extents = Vector2(width / 2.0 + 120, 10)
	p.position = Vector2(width / 2.0 - 80, -30)
	p.direction = Vector2(0.18, 1)
	p.spread = 2
	p.initial_velocity_min = 900
	p.initial_velocity_max = 1100
	p.angle_min = -10
	p.angle_max = -10
	p.z_index = 2
	# cipratan di tanah
	var s := _base_particles(40, 0.35)
	s.texture = _dot_tex(8, 8)
	s.emission_rect_extents = Vector2(width / 2.0, 90)
	s.position = Vector2(width / 2.0, 620)
	s.preprocess = 0
	s.direction = Vector2(0, -1)
	s.spread = 60
	s.initial_velocity_min = 40
	s.initial_velocity_max = 90
	s.gravity = Vector2(0, 400)
	s.color = Color(0.8, 0.9, 1.0, 0.5)
	s.scale_amount_max = 0.6


## Kabut/awan lembut yang lewat pelan.
func _mist(col: Color) -> void:
	for i in 3 * panels:
		var m := Sprite2D.new()
		m.texture = Fx.GLOW_TEX
		m.modulate = col
		m.scale = Vector2(9, 2.2)
		m.position = Vector2(randf_range(0, width), randf_range(80, 300))
		m.z_index = 1
		add_child(m)
		var tw := m.create_tween().set_loops()
		var dur := randf_range(40, 70)
		var span := width + 800.0
		tw.tween_property(m, "position:x", width + 400.0, dur * (width + 400.0 - m.position.x) / span)
		tw.tween_property(m, "position:x", -400.0, 0.0)
		tw.tween_property(m, "position:x", m.position.x, dur * (m.position.x + 400.0) / span)
