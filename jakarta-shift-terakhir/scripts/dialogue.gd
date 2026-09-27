class_name Dialogue
extends Control
## Kotak dialog dengan potret, nama, efek mesin ketik. Z / klik untuk lanjut.
## lines: [[speaker_id, mood, text], ...]  speaker_id: tara/raka/narator/<nama bebas>

signal _advance
signal line_started(who: String)

var panel: Panel
var portrait_bg: Panel
var portrait: TextureRect
var name_tag: Panel
var name_l: Label
var text_l: Label
var arrow: Polygon2D
var _typing := false
var _skip := false
var _active := false
var _abort := false


func _ready() -> void:
	theme = Game.ui_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = Panel.new()
	panel.position = Vector2(150, 520)
	panel.size = Vector2(980, 176)
	panel.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 14, 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	portrait_bg = Panel.new()
	portrait_bg.position = Vector2(-120, -60)
	portrait_bg.size = Vector2(200, 220)
	portrait_bg.clip_contents = true
	portrait_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_bg.rotation = deg_to_rad(-4)
	panel.add_child(portrait_bg)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size = Vector2(200, 220)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_bg.add_child(portrait)
	name_tag = Panel.new()
	name_tag.position = Vector2(96, -26)
	name_tag.size = Vector2(200, 46)
	name_tag.rotation = deg_to_rad(-2)
	name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_tag)
	name_l = Fx.label("", 32, Color.WHITE, 8)
	name_l.size = Vector2(200, 46)
	name_tag.add_child(name_l)
	text_l = Label.new()
	text_l.position = Vector2(100, 30)
	text_l.size = Vector2(850, 130)
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.add_theme_font_size_override("font_size", 27)
	text_l.add_theme_constant_override("line_spacing", 2)
	panel.add_child(text_l)
	# Segitiga "lanjut" digambar (font tidak punya glyph ▼ di build web).
	arrow = Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-12, -8), Vector2(12, -8), Vector2(0, 8)])
	arrow.color = Game.ORANGE
	var arrow_line := Line2D.new()
	arrow_line.points = PackedVector2Array([Vector2(-12, -8), Vector2(12, -8), Vector2(0, 8), Vector2(-12, -8)])
	arrow_line.width = 3
	arrow_line.default_color = Game.INK
	arrow.add_child(arrow_line)
	arrow.position = Vector2(945, 146)
	panel.add_child(arrow)
	var tw := arrow.create_tween().set_loops()
	tw.tween_property(arrow, "position:y", 138.0, 0.3)
	tw.tween_property(arrow, "position:y", 146.0, 0.3)
	visible = false


func _speaker(id: String, mood: String) -> Dictionary:
	if Game.HEROES.has(id):
		var d: Dictionary = Game.HEROES[id]
		var face: String = d.faces.get(mood, mood)
		return {"name": d.name, "color": d.color, "tex": load("res://assets/sprites/face_%s_%s.png" % [id, face])}
	if Game.ENEMIES.has(id):
		var e: Dictionary = Game.ENEMIES[id]
		return {"name": e.name, "color": e.color, "tex": load("res://assets/sprites/core_%s.png" % id)}
	if Game.NPCS.has(id):
		var n: Dictionary = Game.NPCS[id]
		return {"name": n.name, "color": n.color, "tex": load(n.tex) if n.tex != "" else null}
	return {"name": id, "color": Color("3a3440"), "tex": null}


func play(lines: Array, key := "") -> void:
	visible = true
	_active = true
	panel.scale = Vector2(1, 0)
	panel.pivot_offset = panel.size / 2
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("sfx_paper", -6.0)
	await tw.finished
	_abort = false
	for i in lines.size():
		if _abort:
			break
		var line: Array = lines[i]
		var txt: String = line[2]
		if Game.lang == "en" and line.size() > 3:
			txt = line[3]
		line_started.emit(line[0])
		Voice.line(key, i)
		await _show(line[0], line[1], txt)
	Voice.stop()
	_active = false
	var tw2 := create_tween()
	tw2.tween_property(panel, "scale", Vector2(1, 0), 0.12)
	await tw2.finished
	visible = false


func _show(who: String, mood: String, text: String) -> void:
	var sp := _speaker(who, mood)
	var has_portrait: bool = sp.tex != null
	portrait_bg.visible = has_portrait
	name_tag.visible = sp.name != "narator"
	if has_portrait:
		portrait.texture = sp.tex
		portrait_bg.add_theme_stylebox_override("panel", Game.paper_box(sp.color, Game.INK, 10, 6))
		portrait_bg.scale = Vector2(0.85, 0.85)
		portrait_bg.create_tween().tween_property(portrait_bg, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	name_tag.add_theme_stylebox_override("panel", Game.paper_box(sp.color, Game.INK, 8, 4))
	name_l.text = Game.T(String(sp.name)).to_upper()
	var narr: bool = sp.name == "narator"
	text_l.position.x = 100 if has_portrait else 40
	text_l.size.x = 850 if has_portrait else 900
	text_l.add_theme_color_override("font_color", Color("5a5068") if narr else Game.INK)
	text_l.text = text
	text_l.visible_characters = 0
	arrow.visible = false
	_typing = true
	_skip = false
	var n := text.length()
	var i := 0
	while i < n and not _skip:
		i += 1
		text_l.visible_characters = i
		if i % 2 == 0 and text[i - 1] != " ":
			Sfx.play("sfx_type", -14.0, 1.0 if not narr else 0.7, 0.1)
		await get_tree().create_timer(0.022).timeout
	text_l.visible_characters = -1
	_typing = false
	arrow.visible = true
	if _abort:
		return
	if Game.autoplay:
		await get_tree().create_timer(0.5).timeout
		return
	await _advance
	Sfx.play("sfx_blip", -6.0)


## Hentikan dialog yang sedang berjalan (mis. adegan dilewati).
func abort() -> void:
	if not _active:
		return
	_abort = true
	_skip = true
	_advance.emit()


func _unhandled_input(e: InputEvent) -> void:
	if not _active:
		return
	if Game.is_act(e):
		get_viewport().set_input_as_handled()
		if _typing:
			_skip = true
		else:
			_advance.emit()
