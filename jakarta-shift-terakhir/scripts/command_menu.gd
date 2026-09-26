class_name CommandMenu
extends Control
## Menu perintah bertumpuk (kartu kertas) + kotak deskripsi.
## open(options) -> id pilihan, atau null kalau batal (X / Esc / klik kanan).

signal picked(value)

var box: VBoxContainer
var title_l: Label
var desc_panel: PanelContainer
var desc_l: Label
var _open := false
var _can_back := true
var _options: Array = []


func _ready() -> void:
	theme = Game.ui_theme
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_l = Fx.label("", 30, Game.YELLOW, 9)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_l.size = Vector2(320, 40)
	add_child(title_l)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	desc_panel = PanelContainer.new()
	desc_panel.position = Vector2(290, 646)
	desc_panel.size = Vector2(700, 58)
	desc_panel.custom_minimum_size = Vector2(700, 58)
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desc_panel)
	desc_l = Label.new()
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_l.add_theme_font_size_override("font_size", 21)
	desc_panel.add_child(desc_l)
	visible = false


func say(text: String) -> void:
	desc_l.text = text
	desc_panel.visible = text != ""
	visible = true
	box.visible = false
	title_l.visible = false


## options: [{id, label, icon(path|Texture2D), desc, enabled, right(text)}]
func open(options: Array, title := "", pos := Vector2(500, 300), can_back := true) -> Variant:
	for c in box.get_children():
		c.queue_free()
	_options = options
	_can_back = can_back
	box.visible = true
	title_l.visible = title != ""
	title_l.text = title
	box.position = pos
	title_l.position = pos + Vector2(4, -46)
	desc_l.text = ""
	var first: Button = null
	var buttons: Array[Button] = []
	for i in options.size():
		var o: Dictionary = options[i]
		var b := Button.new()
		b.text = o.label
		if o.has("right"):
			b.text = "%s   %s" % [o.label, o.right]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(250, 54)
		b.add_theme_font_size_override("font_size", 24)
		if o.has("icon") and o.icon != null:
			b.icon = o.icon if o.icon is Texture2D else load(o.icon)
			b.expand_icon = false
		b.disabled = not o.get("enabled", true)
		b.focus_entered.connect(_on_focus.bind(b, i))
		b.mouse_entered.connect(_on_hover.bind(b))
		b.pressed.connect(_on_pressed.bind(i))
		b.pivot_offset = Vector2(20, 27)
		box.add_child(b)
		buttons.append(b)
		if first == null and not b.disabled:
			first = b
	# kunci navigasi atas/bawah melingkar
	for i in buttons.size():
		buttons[i].focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()
	visible = true
	desc_panel.visible = false
	_open = true
	# animasi masuk: kartu meluncur satu per satu
	for i in buttons.size():
		var b := buttons[i]
		b.modulate.a = 0.0
		var tw := b.create_tween()
		tw.tween_interval(i * 0.04)
		tw.tween_property(b, "modulate:a", 1.0, 0.1)
	await get_tree().process_frame
	if first:
		first.grab_focus()
	else:
		desc_l.text = "Tidak ada pilihan."
	if Game.autoplay:
		_autopick()
	var v = await picked
	_open = false
	box.visible = false
	title_l.visible = false
	return v


func close() -> void:
	visible = false
	_open = false


func _autopick() -> void:
	await get_tree().create_timer(0.45).timeout
	if not _open:
		return
	var ids: Array = []
	for o in _options:
		if o.get("enabled", true):
			ids.append(o.id)
	if ids.is_empty():
		picked.emit(null)
		return
	# Sedikit variasi supaya semua fitur ikut dites.
	var choice = ids[0]
	if ids.has("skill") and randf() < 0.45:
		choice = "skill"
	elif ids.has("item") and randf() < 0.2:
		choice = "item"
	elif not ids.has("attack"):
		choice = ids[randi() % ids.size()]
	var i := 0
	for o in _options:
		if o.id == choice:
			break
		i += 1
	_on_pressed(i)


func _on_hover(b: Button) -> void:
	if _open and not b.disabled:
		b.grab_focus()


func _on_focus(b: Button, i: int) -> void:
	var o: Dictionary = _options[i]
	desc_l.text = o.get("desc", "")
	desc_panel.visible = desc_l.text != ""
	Sfx.play("sfx_select", -6.0)
	for c in box.get_children():
		if c is Button and c != b:
			c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.08)
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_pressed(i: int) -> void:
	if not _open:
		return
	Sfx.play("sfx_confirm", -3.0)
	picked.emit(_options[i].id)


func _unhandled_input(e: InputEvent) -> void:
	if not _open or not _can_back:
		return
	var back: bool = e.is_action_pressed("back") or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT)
	if back:
		get_viewport().set_input_as_handled()
		Sfx.play("sfx_cancel", -3.0)
		picked.emit(null)
