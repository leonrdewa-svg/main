class_name BattleHud
extends Control
## HUD battle: kartu hero (wajah, Lv, HP, AP), meter SEMANGAT, dan timeline giliran.

var battle: Node
var cards := {}
var meter_fill: ColorRect
var meter_label: Label
var order_box: HBoxContainer
var _faces := {}


func _ready() -> void:
	theme = Game.ui_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var x := 16.0
	for id in ["raka", "tara"]:
		cards[id] = _card(id, Vector2(x, 12))
		x += 282
	# meter semangat
	var mp := Panel.new()
	mp.position = Vector2(16, 104)
	mp.size = Vector2(546, 34)
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.add_theme_stylebox_override("panel", Game.paper_box(Color("2a2330"), Game.INK, 8, 4))
	add_child(mp)
	var ml := Fx.label("SEMANGAT", 22, Game.YELLOW, 6)
	ml.position = Vector2(10, 2)
	ml.size = Vector2(110, 30)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mp.add_child(ml)
	var bar := ColorRect.new()
	bar.color = Color("3a3440")
	bar.position = Vector2(118, 9)
	bar.size = Vector2(360, 16)
	mp.add_child(bar)
	meter_fill = ColorRect.new()
	meter_fill.color = Game.ORANGE
	meter_fill.size = Vector2(0, 16)
	bar.add_child(meter_fill)
	meter_label = Fx.label("0%", 22, Color.WHITE, 6)
	meter_label.position = Vector2(484, 2)
	meter_label.size = Vector2(56, 30)
	mp.add_child(meter_label)
	# timeline
	var op := Panel.new()
	op.position = Vector2(760, 12)
	op.size = Vector2(504, 70)
	op.mouse_filter = Control.MOUSE_FILTER_IGNORE
	op.add_theme_stylebox_override("panel", Game.paper_box(Color("2a2330"), Game.INK, 8, 4))
	add_child(op)
	var ol := Fx.label("GILIRAN", 18, Game.CREAM, 5)
	ol.position = Vector2(8, 0)
	ol.size = Vector2(80, 22)
	ol.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	op.add_child(ol)
	order_box = HBoxContainer.new()
	order_box.position = Vector2(84, 8)
	order_box.add_theme_constant_override("separation", 6)
	op.add_child(order_box)


func _face_tex(id: String, mood: String) -> Texture2D:
	var name: String = Game.HEROES[id].faces.get(mood, mood)
	var key := "%s_%s" % [id, name]
	if not _faces.has(key):
		_faces[key] = load("res://assets/sprites/face_%s_%s.png" % [id, name])
	return _faces[key]


func _card(id: String, pos: Vector2) -> Dictionary:
	var d: Dictionary = Game.HEROES[id]
	var root := Panel.new()
	root.position = pos
	root.size = Vector2(270, 84)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 10, 5))
	add_child(root)
	var fb := Panel.new()
	fb.position = Vector2(8, 8)
	fb.size = Vector2(66, 66)
	fb.clip_contents = true
	fb.add_theme_stylebox_override("panel", Game.paper_box(d.color, Game.INK, 8, 0))
	root.add_child(fb)
	var face := TextureRect.new()
	face.texture = _face_tex(id, "normal")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.position = Vector2(-6, -4)
	face.size = Vector2(78, 78)
	fb.add_child(face)
	var nl := Fx.label(String(d.name).to_upper(), 26, d.color, 6)
	nl.position = Vector2(82, -2)
	nl.size = Vector2(110, 32)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(nl)
	var lv := Fx.label("Lv1", 20, Game.CREAM, 5)
	lv.position = Vector2(196, 0)
	lv.size = Vector2(66, 30)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(lv)
	var hp := Fx.label("", 22, Color.WHITE, 6)
	hp.position = Vector2(82, 26)
	hp.size = Vector2(100, 28)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(hp)
	var bar := ColorRect.new()
	bar.color = Game.INK
	bar.position = Vector2(180, 34)
	bar.size = Vector2(80, 14)
	root.add_child(bar)
	var fill := ColorRect.new()
	fill.position = Vector2(2, 2)
	fill.size = Vector2(76, 10)
	bar.add_child(fill)
	var pips := HBoxContainer.new()
	pips.position = Vector2(82, 58)
	pips.add_theme_constant_override("separation", 3)
	root.add_child(pips)
	for i in 9:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(16, 14)
		pips.add_child(p)
	return {"root": root, "face": face, "hp": hp, "fill": fill, "lv": lv, "pips": pips, "mood": "normal"}


func refresh() -> void:
	if battle == null:
		return
	for b in battle.heroes:
		var c: Dictionary = cards[b.id]
		c.hp.text = "%d/%d" % [b.hp, b.max_hp]
		var f: float = float(b.hp) / b.max_hp
		c.fill.size.x = 76 * f
		c.fill.color = Color("4fd06a") if f > 0.5 else (Color("ffcf30") if f > 0.25 else Color("ff4a4a"))
		c.lv.text = "Lv%d" % Game.party[b.id].level
		var apn: int = battle.ap[b.id]
		for i in 9:
			var p: ColorRect = c.pips.get_child(i)
			p.color = Game.YELLOW if i < apn else Color(0.23, 0.2, 0.26)
		if c.mood == "normal" or c.mood == "tired":
			var m := "tired" if f <= 0.3 else "normal"
			c.mood = m
			c.face.texture = _face_tex(b.id, m)
		c.root.modulate = Color(0.6, 0.6, 0.65) if b.hp <= 0 else Color.WHITE
	var mtr: float = battle.meter
	meter_fill.size.x = 360.0 * mtr / 100.0
	meter_fill.color = Game.YELLOW if mtr >= 100 else Game.ORANGE
	meter_label.text = "MAX" if mtr >= 100 else "%d%%" % int(mtr)


func mood(id: String, m: String, dur := 1.2) -> void:
	if not cards.has(id):
		return
	var c: Dictionary = cards[id]
	c.mood = m
	c.face.texture = _face_tex(id, m)
	if dur > 0:
		await get_tree().create_timer(dur).timeout
		if c.mood == m:
			c.mood = "normal"
			refresh()


func _icon_for(u: Node) -> Texture2D:
	if u.is_hero:
		return _face_tex(u.id, "normal")
	return load("res://assets/sprites/core_%s.png" % u.id)


func set_order(list: Array) -> void:
	for c in order_box.get_children():
		c.queue_free()
	for u in list:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(48, 52)
		p.clip_contents = true
		p.add_theme_stylebox_override("panel", Game.paper_box(Game.TEAL if u.is_hero else Color("8a1a32"), Game.INK, 6, 0))
		var t := TextureRect.new()
		t.texture = _icon_for(u)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.size = Vector2(48, 52)
		p.add_child(t)
		p.set_meta("unit", u)
		order_box.add_child(p)


func set_current(u: Node) -> void:
	for p in order_box.get_children():
		var on: bool = p.get_meta("unit") == u
		p.modulate = Color.WHITE if on else Color(0.75, 0.75, 0.8)
		p.scale = Vector2(1.12, 1.12) if on else Vector2.ONE
	if u.is_hero:
		for k in cards:
			var root: Panel = cards[k].root
			root.add_theme_stylebox_override("panel", Game.paper_box(Game.YELLOW if k == u.id else Game.CREAM, Game.INK, 10, 5))
	else:
		for k in cards:
			cards[k].root.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 10, 5))


func pop_order() -> void:
	if order_box.get_child_count() > 0:
		var c := order_box.get_child(0)
		order_box.remove_child(c)
		c.queue_free()
