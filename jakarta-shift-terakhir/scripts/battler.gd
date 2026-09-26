class_name Battler
extends Node2D
## Satu unit di arena: sprite kertas + bayangan, animasi idle "goyang kertas",
## lompat, dash, flip, flash kena hit, dan tumbang/remuk.

const PAPER_SHADER := preload("res://scripts/paper.gdshader")

var id := ""
var data := {}
var is_hero := false
var display_name := ""
var hp := 10
var max_hp := 10
var atk := 1
var alive := true
var boss := false
var home := Vector2.ZERO
var turn_count := 0

# status
var defending := false
var atk_down := 0      # giliran tersisa
var guard_up := 0      # giliran tersisa
var atk_up := 0        # tumpukan buff
var charging := false

var sprite: Sprite2D
var drop: Sprite2D
var ground: Polygon2D
var tex_idle: Texture2D
var tex_attack: Texture2D
var tex_kick: Texture2D
var base_scale := 0.4
var idle_anim := true
var _t := 0.0
var _mat: ShaderMaterial
var status_root: Node2D
var hpbar: Node2D
var _mv_from := Vector2.ZERO
var _mv_to := Vector2.ZERO
var _mv_h := 0.0
var _lean := 0.0
var trail := false
var _trail_t := 0.0


func setup(p_id: String, p_data: Dictionary, p_is_hero: bool) -> void:
	id = p_id
	data = p_data
	is_hero = p_is_hero
	display_name = data.name
	atk = data.atk
	base_scale = data.get("scale", 0.45)
	boss = data.get("boss", false)
	if is_hero:
		max_hp = Game.party[id].max_hp
		hp = Game.party[id].hp
		tex_idle = load(data.idle)
		tex_attack = load(data.attack)
	else:
		max_hp = data.hp
		hp = max_hp
		tex_idle = load(data.sprite)
		tex_attack = tex_idle
	alive = hp > 0
	_t = randf() * 10.0
	if data.has("h"):
		base_scale = float(data.h) / tex_idle.get_height()

	ground = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 80, sin(a) * 16) * (1.3 if boss else 1.0))
	ground.polygon = pts
	ground.color = Color(0, 0, 0, 0.38)
	add_child(ground)

	_mat = ShaderMaterial.new()
	_mat.shader = PAPER_SHADER

	drop = Sprite2D.new()
	drop.texture = tex_idle
	drop.centered = true
	drop.modulate = Color(0, 0, 0, 0.35)
	drop.position = Vector2(10, -2)
	add_child(drop)

	sprite = Sprite2D.new()
	sprite.texture = tex_idle
	sprite.material = _mat
	add_child(sprite)
	_apply_tex(tex_idle)

	status_root = Node2D.new()
	add_child(status_root)

	if not is_hero:
		hpbar = HpBar.new()
		hpbar.b = self
		hpbar.position = Vector2(0, 34)
		add_child(hpbar)
	if not alive:
		_show_down(true)


func _apply_tex(t: Texture2D) -> void:
	sprite.texture = t
	drop.texture = t
	var off := Vector2(0, -t.get_height() / 2.0)
	sprite.offset = off
	drop.offset = off
	sprite.scale = Vector2.ONE * base_scale
	drop.scale = sprite.scale


static var _anchors := {}
var _anim_scale := 0.0


## Tampilkan satu frame jurus (dari sheet gerakan) dengan kaki tetap di titik yang sama.
func show_frame(key: String, idx: int) -> void:
	if _anchors.is_empty():
		var f := FileAccess.open("res://assets/skill/anchors.json", FileAccess.READ)
		if f:
			_anchors = JSON.parse_string(f.get_as_text())
	var name := "%s_%d" % [key, idx]
	if not _anchors.has(name):
		return
	var t: Texture2D = load("res://assets/skill/%s.png" % name)
	var a: Array = _anchors[name]
	var a0: Array = _anchors.get(key + "_0", a)
	idle_anim = false
	var flip := not is_hero
	sprite.texture = t
	drop.texture = t
	sprite.flip_h = flip
	drop.flip_h = flip
	var ox: float = t.get_width() / 2.0 - float(a[0])
	if flip:
		ox = -ox
	sprite.offset = Vector2(ox, -t.get_height() / 2.0)
	drop.offset = sprite.offset
	var sc := height() / float(a0[2]) * 1.08
	sprite.scale = Vector2(sc, sc)
	sprite.rotation = 0.0
	sprite.skew = 0.0
	drop.scale = sprite.scale


## Putar frame jurus a..b berurutan selama dur detik.
func play_frames(key: String, from: int, to: int, dur: float) -> void:
	var n := to - from + 1
	for i in n:
		show_frame(key, from + i)
		await get_tree().create_timer(dur / n).timeout


func end_frames() -> void:
	sprite.flip_h = false
	drop.flip_h = false
	set_pose("idle")


func height() -> float:
	return tex_idle.get_height() * base_scale


func top() -> Vector2:
	return global_position + Vector2(0, -height())


func center() -> Vector2:
	return global_position + Vector2(0, -height() * 0.5)


func _process(delta: float) -> void:
	_t += delta
	if idle_anim and alive:
		var b := sin(_t * 3.2)
		sprite.scale = Vector2(base_scale * (1.0 + b * 0.012), base_scale * (1.0 - b * 0.018))
		sprite.skew = sin(_t * 1.6) * 0.035
		sprite.rotation = 0.0
		drop.scale = sprite.scale
		drop.skew = sprite.skew
	if idle_anim and alive and not is_hero:
		sprite.position.y = sin(_t * 2.1) * 5.0
	if charging:
		sprite.position.x = randf_range(-2, 2)
	if trail:
		_trail_t -= delta
		if _trail_t <= 0.0:
			_trail_t = 0.03
			_ghost()
	status_root.position = Vector2(0, -height() - 26)


func set_pose(pose: String) -> void:
	if not is_instance_valid(sprite):
		return
	if pose == "kick" and tex_kick:
		_apply_tex(tex_kick)
		idle_anim = false
		sprite.scale = Vector2.ONE * (height() / tex_kick.get_height())
		drop.scale = sprite.scale
		return
	_apply_tex(tex_attack if pose == "attack" else tex_idle)
	if pose == "attack":
		idle_anim = false
		sprite.scale = Vector2.ONE * base_scale * 0.92
		drop.scale = sprite.scale
	elif alive:
		idle_anim = true


## Efek flip kertas (ganti pose di tengah flip).
func paper_flip(pose := "") -> void:
	idle_anim = false
	var s := sprite.scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale:x", 0.0, 0.08)
	tw.parallel().tween_property(drop, "scale:x", 0.0, 0.08)
	if pose != "":
		tw.tween_callback(set_pose.bind(pose))
	tw.tween_property(sprite, "scale:x", s.x, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(drop, "scale:x", s.x, 0.1)
	Sfx.play("sfx_paper", -8.0, 1.6, 0.1)
	await tw.finished
	if pose == "" or pose == "idle":
		idle_anim = true


func flash(color := Color.WHITE, dur := 0.3, strength := 1.0) -> void:
	_mat.set_shader_parameter("flash_color", color)
	var tw := create_tween()
	tw.tween_method(_set_flash, strength, 0.0, dur)


func _set_flash(v: float) -> void:
	_mat.set_shader_parameter("flash", v)


func hurt(big := false) -> void:
	flash()
	idle_anim = false
	var dir := -1.0 if is_hero else 1.0
	var s := Vector2.ONE * base_scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(s.x * 1.18, s.y * 0.82), 0.06)
	tw.parallel().tween_property(sprite, "rotation", dir * (0.22 if big else 0.12), 0.06)
	tw.parallel().tween_property(sprite, "position:x", dir * (26.0 if big else 14.0), 0.06)
	tw.tween_property(sprite, "scale", s, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "position:x", 0.0, 0.3)
	tw.tween_callback(_resume_idle)


## Lompat melengkung ke posisi (global). Squash saat take-off dan landing.
func jump_to(pos: Vector2, dur := 0.5, h := 160.0, sound := true) -> void:
	idle_anim = false
	var from := global_position
	var s := Vector2.ONE * base_scale
	if sound:
		Sfx.play("sfx_jump", -4.0, 1.0, 0.05)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(s.x * 1.15, s.y * 0.85), 0.06)
	tw.tween_property(sprite, "scale", Vector2(s.x * 0.9, s.y * 1.12), 0.06)
	_mv_from = from
	_mv_to = pos
	_mv_h = h
	tw.parallel().tween_method(_jump_step, 0.0, 1.0, dur)
	tw.tween_property(sprite, "scale", Vector2(s.x * 1.2, s.y * 0.8), 0.05)
	tw.tween_property(sprite, "scale", s, 0.12).set_trans(Tween.TRANS_BACK)
	await tw.finished
	ground.position.y = 0
	ground.scale = Vector2.ONE


## Lari cepat (hop kecil) ke posisi.
## Meluncur halus (easing) ke posisi, dengan bayangan jejak (afterimage).
func dash_to(pos: Vector2, dur := 0.35) -> void:
	idle_anim = false
	_mv_from = global_position
	_mv_to = pos
	_lean = clampf((pos.x - global_position.x) / 600.0, -1.0, 1.0)
	trail = true
	var tw := create_tween()
	tw.tween_method(_dash_step, 0.0, 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	trail = false
	var tw2 := create_tween()
	tw2.tween_property(sprite, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func go_home(dur := 0.42) -> void:
	if global_position.distance_to(home) < 4:
		set_pose("idle")
		idle_anim = alive
		return
	await dash_to(home, dur)
	set_pose("idle")
	idle_anim = alive


## Maju sedikit ke arah target (serangan musuh).
func lunge(toward: Vector2, dist := 60.0, dur := 0.12) -> void:
	var dir := (toward - global_position).normalized()
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position + dir * dist, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished


func windup(dur := 0.35) -> void:
	idle_anim = false
	var s := Vector2.ONE * base_scale
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(s.x * 1.1, s.y * 0.88), dur * 0.7)
	tw.parallel().tween_property(sprite, "rotation", (0.1 if is_hero else -0.1) * -1.0, dur * 0.7)
	tw.tween_property(sprite, "scale", s, dur * 0.3)
	tw.parallel().tween_property(sprite, "rotation", 0.0, dur * 0.3)
	await tw.finished


func take_damage(n: int) -> void:
	hp = max(0, hp - n)
	if is_hero:
		Game.party[id].hp = hp
	if hpbar:
		hpbar.queue_redraw()


func heal(n: int) -> void:
	hp = min(max_hp, hp + n)
	if is_hero:
		Game.party[id].hp = hp
	if not alive and hp > 0:
		alive = true
		_show_down(false)
	if hpbar:
		hpbar.queue_redraw()


func _show_down(down: bool) -> void:
	if down:
		idle_anim = false
		var tw := create_tween()
		tw.tween_property(sprite, "rotation", -1.35, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(sprite, "modulate", Color(0.55, 0.55, 0.65), 0.35)
		tw.parallel().tween_property(drop, "modulate:a", 0.0, 0.2)
	else:
		var tw := create_tween()
		tw.tween_property(sprite, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.3)
		tw.parallel().tween_property(drop, "modulate:a", 0.35, 0.3)
		tw.tween_callback(_resume_idle)


func knock_out() -> void:
	alive = false
	charging = false
	clear_status_icons()
	if is_hero:
		_show_down(true)
		return
	# Musuh: kertas diremas lalu hilang.
	idle_anim = false
	if hpbar:
		hpbar.visible = false
	Sfx.play("sfx_enemy_down")
	flash(Color.WHITE, 0.5)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(base_scale * 1.2, base_scale * 0.7), 0.12)
	tw.tween_property(sprite, "rotation", TAU * 1.5, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "scale", Vector2.ONE * 0.02, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(drop, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(ground, "scale", Vector2.ZERO, 0.5)
	tw.tween_callback(_ko_burst)
	await tw.finished
	visible = false


## Bayangan jejak saat bergerak cepat.
func _ghost() -> void:
	if not is_inside_tree() or sprite.texture == null:
		return
	var g := Sprite2D.new()
	g.texture = sprite.texture
	g.offset = sprite.offset
	g.flip_h = sprite.flip_h
	g.global_position = sprite.global_position
	g.rotation = sprite.rotation
	g.scale = sprite.scale * scale
	g.modulate = Color(data.get("color", Color.WHITE), 0.45)
	g.z_index = -1
	get_parent().add_child(g)
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, 0.22)
	tw.tween_callback(g.queue_free)


func _jump_step(v: float) -> void:
	var arc := sin(v * PI)
	global_position = _mv_from.lerp(_mv_to, v) + Vector2(0, -arc * _mv_h)
	ground.position.y = arc * _mv_h
	ground.scale = Vector2.ONE * (1.0 - arc * 0.5)


func _dash_step(v: float) -> void:
	global_position = _mv_from.lerp(_mv_to, v) + Vector2(0, -sin(v * PI) * 14)
	sprite.rotation = _lean * 0.16 * sin(v * PI)


func _resume_idle() -> void:
	if alive:
		idle_anim = true


func _ko_burst() -> void:
	Fx.burst(get_parent(), center(), "paper", 30, 1.2)
	Fx.burst(get_parent(), center(), "stars", 10, 0.8)
	Fx.ring(get_parent(), center(), Color.WHITE, 160)


# ---------------- status icon di atas kepala ----------------

func refresh_status_icons() -> void:
	clear_status_icons()
	var icons: Array = []
	if atk_down > 0:
		icons.append(["res://assets/ui/sticky.png", "ATK-1"])
	if guard_up > 0:
		icons.append(["res://assets/ui/icon_shield.png", "-2"])
	if defending:
		icons.append(["res://assets/ui/icon_shield.png", "JAGA"])
	if atk_up > 0:
		icons.append(["res://assets/ui/icon_star.png", "ATK+%d" % atk_up])
	for i in icons.size():
		var n := Node2D.new()
		n.position = Vector2((i - (icons.size() - 1) / 2.0) * 58, 0)
		var s := Sprite2D.new()
		s.texture = load(icons[i][0])
		s.scale = Vector2.ONE * (48.0 / s.texture.get_width())
		n.add_child(s)
		var l := Fx.label(icons[i][1], 18, Color.WHITE, 6, Game.FONT_UI)
		l.size = Vector2(80, 24)
		l.position = Vector2(-40, 18)
		n.add_child(l)
		status_root.add_child(n)
		n.scale = Vector2.ZERO
		n.create_tween().tween_property(n, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var tw := n.create_tween().set_loops()
		tw.tween_property(s, "position:y", -5.0, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(s, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func clear_status_icons() -> void:
	for c in status_root.get_children():
		c.queue_free()


## Bar HP kecil di bawah kaki musuh.
class HpBar extends Node2D:
	var b: Battler
	func _draw() -> void:
		var w := 130.0
		var r := Rect2(-w / 2, 0, w, 30)
		draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(0, 0, 0, 0.5))
		draw_rect(r, Game.CREAM)
		draw_rect(r, Game.INK, false, 3)
		var inner := Rect2(-w / 2 + 44, 9, w - 52, 12)
		draw_rect(inner, Color("3a3440"))
		var f := float(b.hp) / b.max_hp
		var col := Color("4fd06a") if f > 0.5 else (Color("ffcf30") if f > 0.25 else Color("ff4a4a"))
		draw_rect(Rect2(inner.position, Vector2(inner.size.x * f, inner.size.y)), col)
		draw_rect(inner, Game.INK, false, 2)
		draw_string(Game.FONT_TITLE, Vector2(-w / 2 + 8, 24), str(b.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Game.INK)
