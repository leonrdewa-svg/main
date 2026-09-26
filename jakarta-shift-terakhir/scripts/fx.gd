class_name Fx
extends RefCounted
## Kumpulan efek visual: angka damage starburst, teks pop, partikel kertas,
## ring, speed lines, cut-in jurus, dan kereta MRT.

const STAR_TEX := preload("res://assets/ui/icon_star.png")
const RECEIPT_TEX := preload("res://assets/ui/receipt.png")
const GLOW_TEX := preload("res://assets/ui/glow.png")


static func _star_points(r_out: float, r_in: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n * 2:
		var r := r_out if i % 2 == 0 else r_in
		var a := -PI / 2 + i * PI / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


static func label(text: String, size: int, color: Color, outline := 10, font: Font = Game.FONT_TITLE) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = outline
	ls.outline_color = Game.INK
	ls.shadow_size = 0
	ls.shadow_color = Color(0, 0, 0, 0.6)
	ls.shadow_offset = Vector2(4, 4)
	l.label_settings = ls
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Angka damage dalam starburst ala Paper Mario.
static func damage_star(parent: Node, pos: Vector2, amount: int, heal := false) -> void:
	var n := Node2D.new()
	n.position = pos
	n.z_index = 50
	parent.add_child(n)
	var back := Polygon2D.new()
	back.polygon = _star_points(58, 36, 8)
	back.color = Game.INK
	back.position = Vector2(4, 5)
	n.add_child(back)
	var star := Polygon2D.new()
	star.polygon = _star_points(52, 32, 8)
	star.color = Color("4fd06a") if heal else Color("ffcf30")
	n.add_child(star)
	var inner := Polygon2D.new()
	inner.polygon = _star_points(40, 26, 8)
	inner.color = Color("8ff0a0") if heal else Color("ff7a2a")
	n.add_child(inner)
	var l := label(("+%d" if heal else "%d") % amount, 46, Color.WHITE, 12)
	l.size = Vector2(120, 70)
	l.position = Vector2(-60, -37)
	n.add_child(l)
	n.scale = Vector2.ZERO
	n.rotation = randf_range(-0.3, 0.3)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2.ONE * 1.25, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(n, "rotation", 0.0, 0.2)
	tw.tween_property(n, "scale", Vector2.ONE, 0.1)
	tw.tween_property(n, "position:y", pos.y - 26, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "modulate:a", 0.0, 0.25)
	tw.tween_callback(n.queue_free)


## Teks pop besar (NICE!, GUARD!, MISS...).
static func pop_text(parent: Node, pos: Vector2, text: String, color: Color, size := 60, life := 0.9) -> void:
	var l := label(text, size, color, 14)
	l.size = Vector2(420, size * 1.4)
	l.pivot_offset = l.size / 2
	l.position = pos - l.size / 2
	l.z_index = 60
	l.rotation = deg_to_rad(randf_range(-9, -4))
	l.scale = Vector2(0.2, 0.2)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE * 1.15, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(life)
	tw.parallel().tween_property(l, "position:y", l.position.y - 30, life)
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	tw.tween_callback(l.queue_free)


static func _rect_tex(w: int, h: int, c: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	for x in w:
		img.set_pixel(x, 0, Game.INK)
		img.set_pixel(x, h - 1, Game.INK)
	for y in h:
		img.set_pixel(0, y, Game.INK)
		img.set_pixel(w - 1, y, Game.INK)
	return ImageTexture.create_from_image(img)


## Ledakan partikel. kind: paper, stars, confetti, ink, receipts, heal, glow
static func burst(parent: Node, pos: Vector2, kind := "paper", amount := 18, spread := 1.0, auto_free := true) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 40
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 180
	p.initial_velocity_min = 180 * spread
	p.initial_velocity_max = 420 * spread
	p.gravity = Vector2(0, 700)
	p.angular_velocity_min = -540
	p.angular_velocity_max = 540
	p.angle_min = 0
	p.angle_max = 360
	p.damping_min = 20
	p.damping_max = 60
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.7, Color.WHITE)
	p.color_ramp = fade
	match kind:
		"paper":
			p.texture = _rect_tex(14, 18, Color("f7f3e8"))
			p.scale_amount_min = 0.7
			p.scale_amount_max = 1.4
		"ink":
			p.texture = _rect_tex(10, 10, Color("2a2530"))
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.5
		"receipts":
			p.texture = RECEIPT_TEX
			p.scale_amount_min = 0.35
			p.scale_amount_max = 0.6
		"stars":
			p.texture = STAR_TEX
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.24
			p.gravity = Vector2(0, 300)
		"confetti":
			p.texture = _rect_tex(10, 16, Color.WHITE)
			var g := Gradient.new()
			g.offsets = PackedFloat32Array([0, 0.25, 0.5, 0.75, 1])
			g.colors = PackedColorArray([Color("ffd23f"), Color("e6186e"), Color("1f8a8a"), Color("e8692c"), Color("9be02a")])
			p.color_initial_ramp = g
			p.lifetime = 2.2
			p.gravity = Vector2(0, 260)
			p.damping_min = 60
			p.damping_max = 120
		"heal":
			p.texture = STAR_TEX
			p.scale_amount_min = 0.08
			p.scale_amount_max = 0.16
			p.gravity = Vector2(0, -260)
			p.initial_velocity_min = 40
			p.initial_velocity_max = 140
			p.explosiveness = 0.4
			p.lifetime = 1.2
			p.color = Color("b8ffb0")
		"glow":
			p.texture = GLOW_TEX
			p.scale_amount_min = 0.2
			p.scale_amount_max = 0.5
			p.gravity = Vector2(0, -120)
			p.color = Color(1, 0.3, 0.6, 0.8)
	parent.add_child(p)
	p.emitting = true
	if auto_free:
		parent.get_tree().create_timer(p.lifetime + 0.6).timeout.connect(p.queue_free)
	return p


## Cincin yang mengembang.
class Ring extends Node2D:
	var r_to := 140.0
	var color := Color.WHITE
	var progress := 0.0:
		set(v):
			progress = v
			modulate.a = 1.0 - v
			queue_redraw()
	func _draw() -> void:
		draw_arc(Vector2.ZERO, lerpf(12, r_to, progress), 0, TAU, 48, color, lerpf(16, 2, progress), true)


static func ring(parent: Node, pos: Vector2, color: Color, r_to := 140.0, dur := 0.35) -> void:
	var n := Ring.new()
	n.position = pos
	n.color = color
	n.r_to = r_to
	n.z_index = 45
	parent.add_child(n)
	var tw := n.create_tween()
	tw.tween_property(n, "progress", 1.0, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(n.queue_free)


## Garis kecepatan manga di seluruh layar.
class SpeedLines extends Node2D:
	var center := Vector2(640, 360)
	var color := Color(1, 1, 1, 0.9)
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(t * 30)
		for i in 46:
			var a := rng.randf() * TAU
			var dir := Vector2(cos(a), sin(a))
			var inner := rng.randf_range(260, 420)
			var w := rng.randf_range(0.01, 0.035)
			var p1 := center + dir * inner
			var p2 := center + Vector2(cos(a - w), sin(a - w)) * 1100
			var p3 := center + Vector2(cos(a + w), sin(a + w)) * 1100
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)


static func speed_lines(parent: Node, center: Vector2, dur := 0.5, color := Color(1, 1, 1, 0.85)) -> void:
	var n := SpeedLines.new()
	n.center = center
	n.color = color
	n.z_index = 30
	parent.add_child(n)
	var tw := n.create_tween()
	tw.tween_interval(dur)
	tw.tween_property(n, "modulate:a", 0.0, 0.15)
	tw.tween_callback(n.queue_free)


## Cut-in jurus: pita diagonal dengan art karakter + nama jurus.
static func cut_in(layer: CanvasLayer, tex: Texture2D, title: String, color: Color, flip := false) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var band := Node2D.new()
	band.position = Vector2(640, 360)
	band.rotation = deg_to_rad(-8)
	root.add_child(band)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-900, -118), Vector2(900, -118), Vector2(900, 128), Vector2(-900, 128)])
	shadow.color = Game.INK
	band.add_child(shadow)
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([Vector2(-900, -110), Vector2(900, -110), Vector2(900, 110), Vector2(-900, 110)])
	poly.color = color
	band.add_child(poly)
	var stripe := Polygon2D.new()
	stripe.polygon = PackedVector2Array([Vector2(-900, 70), Vector2(900, 70), Vector2(900, 88), Vector2(-900, 88)])
	stripe.color = Game.CREAM
	band.add_child(stripe)
	var clip := Control.new()
	clip.clip_contents = true
	clip.position = Vector2(-900, -110)
	clip.size = Vector2(1800, 220)
	band.add_child(clip)
	var art := TextureRect.new()
	art.texture = tex
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size = Vector2(620, 560)
	art.position = Vector2(560, -150)
	art.flip_h = flip
	clip.add_child(art)
	var l := label(title, 78, Color.WHITE, 16)
	l.size = Vector2(900, 120)
	l.position = Vector2(-120, -70)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	band.add_child(l)
	band.scale = Vector2(1, 0)
	var tw := root.create_tween()
	tw.tween_property(dim, "color:a", 0.45, 0.12)
	tw.parallel().tween_property(band, "scale:y", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(art, "position:x", 1080.0, 0.9).from(1500.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "position:x", -60.0, 0.9).from(-500.0).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(band, "scale:y", 0.0, 0.12)
	tw.parallel().tween_property(dim, "color:a", 0.0, 0.12)
	tw.tween_callback(root.queue_free)
	Sfx.play("sfx_paper", 2.0, 1.3)
	Sfx.play("sfx_star", -2.0)
	await tw.finished


## Kereta MRT yang melintas.
class Train extends Node2D:
	func _draw() -> void:
		var cars := 3
		for c in cars:
			var x := c * 360.0
			var body := Rect2(x, -150, 344, 150)
			draw_rect(Rect2(body.position + Vector2(6, 8), body.size), Color(0, 0, 0, 0.45))
			draw_rect(body, Color("eef1f4"))
			draw_rect(Rect2(x, -58, 344, 22), Color("1d4f9c"))
			draw_rect(Rect2(x, -36, 344, 8), Color("16a0a8"))
			for w in 5:
				draw_rect(Rect2(x + 22 + w * 64, -128, 46, 50), Color("22364f"))
				draw_rect(Rect2(x + 26 + w * 64, -124, 16, 42), Color(1, 1, 1, 0.25))
			draw_rect(body, Game.INK, false, 5)
			draw_circle(Vector2(x + 60, 4), 16, Game.INK)
			draw_circle(Vector2(x + 284, 4), 16, Game.INK)
		# moncong depan
		var nx := cars * 360.0 - 16
		draw_colored_polygon(PackedVector2Array([Vector2(nx, -150), Vector2(nx + 70, -90), Vector2(nx + 70, 0), Vector2(nx, 0)]), Color("eef1f4"))
		draw_polyline(PackedVector2Array([Vector2(nx, -150), Vector2(nx + 70, -90), Vector2(nx + 70, 0), Vector2(nx, 0)]), Game.INK, 5)
		draw_circle(Vector2(nx + 52, -40), 10, Color("ffe066"))
		draw_string(Game.FONT_TITLE, Vector2(40, -70), "MRT JAKARTA", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("1d4f9c"))
