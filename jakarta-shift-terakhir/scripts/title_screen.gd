class_name TitleScreen
extends Node2D
## Layar judul: latar Dukuh Atas ken-burns, logo stiker, Tara & Raka,
## struk lembur berjatuhan. Z / klik untuk mulai.

signal start

var bg: Sprite2D
var logo: Node2D
var prompt: Label
var _t := 0.0
var _ready_input := false


func _ready() -> void:
	bg = Sprite2D.new()
	bg.texture = load("res://assets/bg/dukuh_atas.jpg")
	bg.position = Vector2(640, 360)
	var mat := ShaderMaterial.new()
	mat.shader = LiveBg.SHADER
	mat.set_shader_parameter("warm", 1.0)
	bg.material = mat
	add_child(bg)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.08, 0.03, 0.08, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var rain := Fx.burst(self, Vector2(640, -60), "receipts", 20, 0.1, false)
	rain.one_shot = false
	rain.explosiveness = 0.0
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(700, 10)
	rain.gravity = Vector2(30, 90)
	rain.lifetime = 9.0
	rain.initial_velocity_min = 20
	rain.initial_velocity_max = 60
	rain.angular_velocity_min = -90
	rain.angular_velocity_max = 90

	# Karakter
	var chars := [["raka", Vector2(230, 760), 0.62, -1], ["tara", Vector2(1060, 760), 0.66, 1]]
	for c in chars:
		var s := Sprite2D.new()
		s.texture = load(Game.HEROES[c[0]].attack)
		s.position = c[1] + Vector2(c[3] * 600, 0)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0)
		s.scale = Vector2.ONE * c[2] * 0.62
		s.flip_h = c[0] == "tara"
		add_child(s)
		var tw := s.create_tween()
		tw.tween_interval(0.3)
		tw.tween_property(s, "position", c[1], 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	logo = Node2D.new()
	logo.position = Vector2(640, 250)
	add_child(logo)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(-400, -40), Vector2(410, -64), Vector2(420, 56), Vector2(-410, 70)])
	band.color = Game.ORANGE
	var band_sh := Polygon2D.new()
	band_sh.polygon = band.polygon
	band_sh.color = Game.INK
	band_sh.position = Vector2(10, 10)
	logo.add_child(band_sh)
	logo.add_child(band)
	var top := Fx.label("JAKARTA:", 56, Game.CREAM, 14)
	top.size = Vector2(600, 80)
	top.position = Vector2(-300, -150)
	logo.add_child(top)
	var main := Fx.label("SHIFT TERAKHIR", 124, Color.WHITE, 20)
	main.size = Vector2(1000, 160)
	main.position = Vector2(-500, -84)
	logo.add_child(main)
	var sub := Fx.label(Game.L("— RPG JELAJAH JAKARTA —", "— A JAKARTA ADVENTURE RPG —"), 30, Game.YELLOW, 9)
	sub.size = Vector2(600, 40)
	sub.position = Vector2(-300, 80)
	logo.add_child(sub)
	logo.rotation = deg_to_rad(-3)
	logo.scale = Vector2(0.2, 0.2)
	var tw2 := logo.create_tween()
	tw2.tween_property(logo, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	prompt = Fx.label(Game.L("SENTUH  UNTUK  MULAI", "TAP  TO  START") if Game.touch_mode else Game.L("TEKAN  Z  /  KLIK  UNTUK  MULAI", "PRESS  Z  /  CLICK  TO  START"), 40, Color.WHITE, 12)
	prompt.size = Vector2(1280, 60)
	prompt.position = Vector2(0, 470)
	add_child(prompt)
	var help := Fx.label(Game.L("Z / Spasi / Enter: pilih & aksi     X / Esc: batal     Panah / Mouse: navigasi", "Z / Space / Enter: select & act     X / Esc: back     Arrows / Mouse: navigate"), 22, Game.CREAM, 7, Game.FONT_UI)
	help.size = Vector2(1280, 30)
	help.position = Vector2(0, 676)
	add_child(help)

	Sfx.music("bgm_title")
	Sfx.play("sfx_paper", 0.0, 0.8)
	await get_tree().create_timer(0.8).timeout
	_ready_input = true
	Game.shot("judul")
	if Game.autoplay:
		await get_tree().create_timer(0.8).timeout
		_go()


func _process(delta: float) -> void:
	_t += delta
	var s := maxf(1280.0 / bg.texture.get_width(), 720.0 / bg.texture.get_height()) * (1.08 + sin(_t * 0.15) * 0.03)
	bg.scale = Vector2(s, s)
	bg.position = Vector2(640 + sin(_t * 0.1) * 20, 360)
	logo.position.y = 250 + sin(_t * 1.6) * 6
	prompt.modulate.a = 0.55 + 0.45 * sin(_t * 4.0)


func _unhandled_input(e: InputEvent) -> void:
	if _ready_input and Game.is_act(e):
		get_viewport().set_input_as_handled()
		_go()


func _go() -> void:
	if not _ready_input:
		return
	_ready_input = false
	Sfx.play("jingle_start", 0.0)
	var tw := prompt.create_tween()
	for i in 6:
		tw.tween_property(prompt, "scale", Vector2(1.05, 1.05), 0.05)
		tw.tween_property(prompt, "scale", Vector2.ONE, 0.05)
	await tw.finished
	start.emit()
