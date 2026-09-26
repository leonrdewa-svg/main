class_name MapScreen
extends Node2D
## Peta MRT: pilih area tujuan (panah/klik, Z naik, X batal).
## Juga ada pilihan istirahat & simpan (HP penuh).

signal done(choice: String)   # id area, "rest", atau "" (batal)

var options: Array = []
var idx := 0
var pins := {}
var info: Label
var _active := false


func _ready() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/world/map.jpg")
	bg.centered = false
	bg.scale = Vector2(1280.0 / bg.texture.get_width(), 720.0 / bg.texture.get_height())
	add_child(bg)
	for name in Story.MAP_LOCKED:
		_pin(Story.MAP_LOCKED[name], name + Game.L(" (segera)", " (soon)"), Color(0.4, 0.4, 0.45), false)
	for id in Story.AREA_ORDER:
		var a: Dictionary = Story.AREAS[id]
		var open: bool = id == "dukuh" or Game.flag("prolog_done")
		var label: String = Story.area_name(id)
		if id == Game.area:
			label += Game.L(" (di sini)", " (here)")
		var done := _area_cleared(id)
		if done:
			label += " ✓"
		pins[id] = _pin(a.map, label, Game.ORANGE if open else Color(0.4, 0.4, 0.45), open)
		if open:
			options.append(id)
	options.append("rest")
	var panel := PanelContainer.new()
	panel.theme = Game.ui_theme
	panel.position = Vector2(760, 610)
	panel.custom_minimum_size = Vector2(500, 90)
	add_child(panel)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_font_size_override("font_size", 20)
	panel.add_child(info)
	idx = maxi(0, options.find(Game.area))
	_show()
	_active = true
	Sfx.play("sfx_paper")
	Game.shot("peta")
	if Game.autoplay:
		_auto()


func _area_cleared(id: String) -> bool:
	for e in Story.AREAS[id].enemies:
		if not Game.flag("def_" + e.id):
			return false
	return true


func _pin(p: Vector2, text: String, col: Color, open: bool) -> Node2D:
	var n := Node2D.new()
	n.position = p
	add_child(n)
	var c := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a), sin(a)) * 16)
	c.polygon = pts
	c.color = col
	n.add_child(c)
	var l := Fx.label(text.replace(" ✓", Game.L("  [BERSIH]", "  [CLEAR]")), 26 if open else 20, Color.WHITE if open else Color(0.8, 0.8, 0.8), 8)
	l.size = Vector2(320, 34)
	l.position = Vector2(-160, 16)
	n.add_child(l)
	return n


func _show() -> void:
	for id in pins:
		pins[id].scale = Vector2.ONE
	var cur: String = options[idx]
	if cur == "rest":
		info.text = Game.L("[ ISTIRAHAT & SIMPAN ]\nHP party pulih penuh dan progres disimpan.  (Z pilih · X batal · panah ganti)", "[ REST & SAVE ]\nFully restores party HP and saves.  (Z select · X back · arrows switch)")
	else:
		pins[cur].scale = Vector2(1.35, 1.35)
		var a: Dictionary = Story.AREAS[cur]
		var left := 0
		for e in a.enemies:
			if not Game.flag("def_" + e.id):
				left += 1
		info.text = Game.L("Naik MRT ke %s\nPekerja dirasuki tersisa: %d   (Z naik · X batal · panah ganti)", "Take the MRT to %s\nPossessed workers left: %d   (Z ride · X back · arrows switch)") % [Story.area_name(cur), left]


func _unhandled_input(e: InputEvent) -> void:
	if not _active:
		return
	if e.is_action_pressed("ui_left") or e.is_action_pressed("ui_up"):
		idx = (idx - 1 + options.size()) % options.size()
		Sfx.play("sfx_select", -4.0)
		_show()
	elif e.is_action_pressed("ui_right") or e.is_action_pressed("ui_down"):
		idx = (idx + 1) % options.size()
		Sfx.play("sfx_select", -4.0)
		_show()
	elif e.is_action_pressed("act"):
		_pick(options[idx])
	elif e.is_action_pressed("back"):
		_pick("")
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for id in pins:
			if pins[id].position.distance_to(e.position) < 40 and options.has(id):
				if options[idx] == id:
					_pick(id)
				else:
					idx = options.find(id)
					_show()
				return
	else:
		return
	get_viewport().set_input_as_handled()


func _pick(c: String) -> void:
	if not _active:
		return
	_active = false
	Sfx.play("sfx_confirm" if c != "" else "sfx_cancel")
	done.emit(c)


func _auto() -> void:
	await get_tree().create_timer(0.8).timeout
	var pick := "rest"
	for id in Story.AREA_ORDER:
		if options.has(id) and not _area_cleared(id) and id != "scbd":
			pick = id
			break
	if pick == "rest" and Game.cards() >= 3:
		pick = "scbd"
	if pick == Game.area and _area_cleared(pick):
		pick = "rest"
	_pick(pick)
