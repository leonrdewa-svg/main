extends Node
## Global state: data tabel karakter/musuh/item, status party, input map,
## theme UI, dan hook autoplay untuk testing (--autoplay --shots=DIR).

signal sp_changed

const INK := Color("17151b")
const CREAM := Color("f6efe1")
const TEAL := Color("1f8a8a")
const ORANGE := Color("e8692c")
const PINK := Color("e6186e")
const YELLOW := Color("ffd23f")

const FONT_TITLE := preload("res://assets/fonts/Bangers.ttf")
const FONT_UI := preload("res://assets/fonts/ArchivoNarrow-Bold.ttf")

const HEROES := {
	"tara": {
		"name": "Tara", "hp": 20, "atk": 2, "color": Color("1f8a8a"),
		"idle": "res://assets/sprites/tara_idle.png",
		"attack": "res://assets/sprites/tara_attack.png",
		"weapon": "res://assets/sprites/item_kipas.png",
		"scale": 0.42,
		"faces": {"normal": "skeptis", "happy": "usil", "focus": "fokus", "hurt": "lelah", "tired": "lelah"},
		"attack_name": "Tampar Kipas",
		"attack_desc": "Sabet musuh pakai kipas dokumen. Tekan Z saat lingkaran pas!",
		"skills": [
			{"id": "badai", "name": "Badai Kertas", "cost": 3, "target": "all_enemies",
				"desc": "Serang SEMUA musuh dengan badai dokumen. Tekan Z berulang-ulang!"},
			{"id": "semangat", "name": "Semangat Pagi", "cost": 2, "target": "ally",
				"desc": "Pulihkan 6 HP satu teman (bisa bangkitkan). Tekan Z tepat waktu untuk bonus."},
		],
	},
	"raka": {
		"name": "Raka", "hp": 24, "atk": 2, "color": Color("e8692c"),
		"idle": "res://assets/sprites/raka_idle.png",
		"attack": "res://assets/sprites/raka_attack.png",
		"weapon": "res://assets/sprites/item_payung.png",
		"scale": 0.39,
		"faces": {"normal": "datar", "happy": "senyum", "focus": "marah", "hurt": "marah", "tired": "lelah"},
		"attack_name": "Lompat Payung",
		"attack_desc": "Lompat ke kepala musuh. Tekan Z pas mendarat untuk lompat lagi!",
		"skills": [
			{"id": "tusukan", "name": "Tusukan Payung", "cost": 3, "target": "enemy",
				"desc": "Tusukan super ke satu musuh. TAHAN Z, lepas di zona hijau!"},
			{"id": "pelindung", "name": "Payung Pelindung", "cost": 2, "target": "none",
				"desc": "Semua teman kebal -2 damage. Tekan Z tepat waktu = 2 giliran."},
		],
	},
}

const ENEMIES := {
	"deadline": {"name": "Deadline", "hp": 12, "atk": 3, "scale": 0.47, "color": Color("f07a1f"),
		"sprite": "res://assets/sprites/deadline.png",
		"quote": "Waktu tidak pernah cukup. TIK. TAK. Tetap kurang."},
	"revisi": {"name": "Revisi", "hp": 10, "atk": 2, "scale": 0.46, "color": Color("9a5ad0"),
		"sprite": "res://assets/sprites/revisi.png",
		"quote": "Masih ada yang bisa diperbaiki kok. Sedikit lagi. Pasti sempurna."},
	"target": {"name": "Target", "hp": 16, "atk": 3, "scale": 0.47, "color": Color("9be02a"),
		"sprite": "res://assets/sprites/target.png",
		"quote": "Angka harus naik. Lebih tinggi. Lebih banyak. Lebih terus."},
	"lembur": {"name": "LEMBUR", "hp": 32, "atk": 4, "scale": 0.6, "color": Color("e6186e"),
		"sprite": "res://assets/sprites/lembur.png", "boss": true,
		"quote": "Kerja masih bisa lebih banyak. Hari ini. Besok. Setiap hari. Selamanya."},
}

const ITEMS := {
	"kopi": {"name": "Kopi Susu", "icon": "res://assets/ui/icon_kopi.png", "count": 3, "target": "ally",
		"desc": "+10 HP untuk satu teman. Bisa membangunkan yang tumbang."},
	"esteh": {"name": "Es Teh Manis", "icon": "res://assets/ui/icon_esteh.png", "count": 2, "target": "none",
		"desc": "+5 Semangat (SP). Manisnya pas."},
	"nasgor": {"name": "Nasi Goreng", "icon": "res://assets/ui/icon_nasgor.png", "count": 1, "target": "party",
		"desc": "+8 HP untuk semua teman."},
	"kartu": {"name": "Kartu MRT", "icon": "res://assets/sprites/item_kartu.png", "count": 1, "target": "all_enemies",
		"desc": "Tap! Kereta MRT lewat, 5 damage ke semua musuh."},
}

var party := {}
var bag := {}
var sp := 10
var sp_max := 10
var stats := {"nice": 0, "guard": 0, "turns": 0}

var ui_theme: Theme
var autoplay := false
var shot_dir := ""
var _shot_i := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	ui_theme = _make_theme()
	get_tree().root.theme = ui_theme
	for a in OS.get_cmdline_user_args():
		if a == "--autoplay":
			autoplay = true
		elif a.begins_with("--shots="):
			shot_dir = a.substr(8)
	new_run()
	if autoplay and shot_dir != "":
		_auto_shots()


func _auto_shots() -> void:
	while true:
		await get_tree().create_timer(0.8).timeout
		shot("auto")


func new_run() -> void:
	party.clear()
	for id in HEROES:
		party[id] = {"hp": HEROES[id].hp, "max_hp": HEROES[id].hp}
	bag.clear()
	for id in ITEMS:
		bag[id] = ITEMS[id].count
	sp = sp_max
	stats = {"nice": 0, "guard": 0, "turns": 0}


func full_heal() -> void:
	for id in party:
		party[id].hp = party[id].max_hp
	set_sp(sp_max)


func set_sp(v: int) -> void:
	sp = clampi(v, 0, sp_max)
	sp_changed.emit()


func bag_total() -> int:
	var n := 0
	for id in bag:
		n += bag[id]
	return n


## True kalau event adalah tombol aksi (keyboard/gamepad) atau klik/tap kiri.
func is_act(e: InputEvent) -> bool:
	if e.is_action_pressed("act"):
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


func act_held() -> bool:
	return Input.is_action_pressed("act") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


## Autoplay: simulasi pemain untuk tes otomatis.
func auto_chance(p: float) -> bool:
	return randf() < p


func shot(tag: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_shot_i += 1
	img.save_png("%s/%03d_%s.png" % [shot_dir, _shot_i, tag])


func _setup_input() -> void:
	_add_keys("act", [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_J])
	_add_keys("back", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE, KEY_K])
	_add_keys("ui_accept", [KEY_Z, KEY_J])
	_add_keys("ui_cancel", [KEY_X, KEY_K])
	for pair in [["act", JOY_BUTTON_A], ["back", JOY_BUTTON_B]]:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pair[1]
		InputMap.action_add_event(pair[0], jb)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.keycode = k
		InputMap.action_add_event(action, e)


static func paper_box(bg: Color = CREAM, border: Color = INK, radius := 8, shadow := 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 1 if shadow > 0 else 0
	s.shadow_offset = Vector2(shadow, shadow)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_UI
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", paper_box())
	t.set_stylebox("hover", "Button", paper_box(Color("fff4cf")))
	t.set_stylebox("focus", "Button", paper_box(YELLOW, INK, 8, 7))
	t.set_stylebox("pressed", "Button", paper_box(Color("ffb830"), INK, 8, 2))
	t.set_stylebox("disabled", "Button", paper_box(Color("bdb6a8"), Color("5a5560"), 8, 3))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("6b6570"))
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("icon_max_width", "Button", 44)
	t.set_stylebox("panel", "PanelContainer", paper_box())
	t.set_stylebox("panel", "Panel", paper_box())
	t.set_color("font_color", "Label", INK)
	return t
