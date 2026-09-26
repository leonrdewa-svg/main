class_name Hud
extends Control
## HUD atas: kartu tiap hero (wajah + HP) dan meter Semangat (SP).

var cards := {}   # id -> {root, face, hp_label, bar, bar_fill}
var sp_label: Label
var sp_fill: ColorRect
var _faces := {}


func _ready() -> void:
	theme = Game.ui_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 18.0
	for id in Game.HEROES:
		cards[id] = _make_card(id, Vector2(x, 10))
		x += 268
	_make_sp(Vector2(x, 10))
	Game.sp_changed.connect(refresh)
	refresh()


func _face_tex(id: String, mood: String) -> Texture2D:
	var name: String = Game.HEROES[id].faces.get(mood, mood)
	var key := "%s_%s" % [id, name]
	if not _faces.has(key):
		_faces[key] = load("res://assets/sprites/face_%s_%s.png" % [id, name])
	return _faces[key]


func _make_card(id: String, pos: Vector2) -> Dictionary:
	var d: Dictionary = Game.HEROES[id]
	var root := Panel.new()
	root.position = pos
	root.size = Vector2(254, 78)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 10, 5))
	add_child(root)
	var face_bg := Panel.new()
	face_bg.position = Vector2(8, 7)
	face_bg.size = Vector2(64, 64)
	face_bg.clip_contents = true
	face_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_bg.add_theme_stylebox_override("panel", Game.paper_box(d.color, Game.INK, 8, 0))
	root.add_child(face_bg)
	var face := TextureRect.new()
	face.texture = _face_tex(id, "normal")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.position = Vector2(-6, -4)
	face.size = Vector2(76, 76)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_bg.add_child(face)
	var name_l := Fx.label(d.name.to_upper(), 28, d.color, 6)
	name_l.position = Vector2(82, 0)
	name_l.size = Vector2(120, 36)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(name_l)
	var heart := TextureRect.new()
	heart.texture = load("res://assets/ui/icon_heart.png")
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.size = Vector2(30, 30)
	heart.position = Vector2(80, 38)
	root.add_child(heart)
	var hp_l := Fx.label("20/20", 26, Color.WHITE, 7)
	hp_l.position = Vector2(112, 34)
	hp_l.size = Vector2(80, 36)
	hp_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(hp_l)
	var bar := ColorRect.new()
	bar.color = Game.INK
	bar.position = Vector2(186, 46)
	bar.size = Vector2(58, 14)
	root.add_child(bar)
	var fill := ColorRect.new()
	fill.color = Color("4fd06a")
	fill.position = Vector2(2, 2)
	fill.size = Vector2(54, 10)
	bar.add_child(fill)
	return {"root": root, "face": face, "hp": hp_l, "fill": fill, "mood": "normal", "active": false}


func _make_sp(pos: Vector2) -> void:
	var root := Panel.new()
	root.position = pos
	root.size = Vector2(196, 78)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 10, 5))
	add_child(root)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/icon_sp.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size = Vector2(54, 54)
	icon.position = Vector2(8, 12)
	root.add_child(icon)
	var t := Fx.label("SEMANGAT", 22, Game.ORANGE, 6)
	t.position = Vector2(66, 2)
	t.size = Vector2(120, 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(t)
	sp_label = Fx.label("10/10", 26, Color.WHITE, 7)
	sp_label.position = Vector2(66, 34)
	sp_label.size = Vector2(70, 36)
	sp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(sp_label)
	var bar := ColorRect.new()
	bar.color = Game.INK
	bar.position = Vector2(132, 46)
	bar.size = Vector2(54, 14)
	root.add_child(bar)
	sp_fill = ColorRect.new()
	sp_fill.color = Color("ffa23a")
	sp_fill.position = Vector2(2, 2)
	sp_fill.size = Vector2(50, 10)
	bar.add_child(sp_fill)


func refresh() -> void:
	for id in cards:
		var c: Dictionary = cards[id]
		var hp: int = Game.party[id].hp
		var mx: int = Game.party[id].max_hp
		c.hp.text = "%d/%d" % [hp, mx]
		var f := float(hp) / mx
		c.fill.size.x = 54 * f
		c.fill.color = Color("4fd06a") if f > 0.5 else (Color("ffcf30") if f > 0.25 else Color("ff4a4a"))
		if c.mood == "normal" or c.mood == "tired":
			var m := "tired" if f <= 0.3 else "normal"
			if m != c.mood:
				c.mood = m
				c.face.texture = _face_tex(id, m)
		c.root.modulate = Color(0.6, 0.6, 0.65) if hp <= 0 else Color.WHITE
	sp_label.text = "%d/%d" % [Game.sp, Game.sp_max]
	sp_fill.size.x = 50.0 * Game.sp / Game.sp_max


## Ganti ekspresi sementara (happy/focus/hurt), lalu balik normal.
func mood(id: String, m: String, dur := 1.2) -> void:
	if not cards.has(id):
		return
	var c: Dictionary = cards[id]
	c.mood = m
	c.face.texture = _face_tex(id, m)
	var face: TextureRect = c.face
	var tw := face.create_tween()
	tw.tween_property(face, "scale", Vector2(1.15, 1.15), 0.08)
	tw.tween_property(face, "scale", Vector2.ONE, 0.15)
	if dur > 0:
		await get_tree().create_timer(dur).timeout
		if c.mood == m:
			c.mood = "normal"
			refresh()


func set_active(id: String) -> void:
	for k in cards:
		var root: Panel = cards[k].root
		var on: bool = k == id
		var tw := root.create_tween()
		tw.tween_property(root, "position:y", 18.0 if on else 10.0, 0.15).set_trans(Tween.TRANS_BACK)
		root.add_theme_stylebox_override("panel", Game.paper_box(Game.YELLOW if on else Game.CREAM, Game.INK, 10, 5))


func shake_card(id: String) -> void:
	if not cards.has(id):
		return
	var root: Panel = cards[id].root
	var x := root.position.x
	var tw := root.create_tween()
	for i in 4:
		tw.tween_property(root, "position:x", x + (8 if i % 2 == 0 else -8), 0.04)
	tw.tween_property(root, "position:x", x, 0.04)
