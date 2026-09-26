extends Node
## Global state: data karakter/musuh/item, party (level, EXP), uang, tas,
## flag cerita, simpan/muat, input map, theme UI, dan hook autoplay.

signal changed

const INK := Color("17151b")
const CREAM := Color("f6efe1")
const TEAL := Color("1f8a8a")
const ORANGE := Color("e8692c")
const PINK := Color("e6186e")
const YELLOW := Color("ffd23f")

const FONT_TITLE := preload("res://assets/fonts/Bangers.ttf")
const FONT_UI := preload("res://assets/fonts/ArchivoNarrow-Bold.ttf")

const SAVE_PATH := "user://shift_terakhir_save.json"

const HEROES := {
	"raka": {
		"name": "Raka", "hp": 60, "atk": 9, "spd": 10, "color": Color("e8692c"), "scale": 0.39,
		"idle": "res://assets/sprites/raka_idle.png",
		"attack": "res://assets/sprites/raka_attack.png",
		"side": "res://assets/world/raka_side.png",
		"faces": {"normal": "datar", "happy": "senyum", "focus": "marah", "hurt": "marah", "tired": "lelah"},
		"skills": [
			{"id": "tinju", "name": "Tinju Komuter", "ap": 2, "target": "enemy", "keys": 4, "power": 1.0,
				"desc": "Rentetan 4 pukulan ke satu musuh. Ikuti urutan tombol!"},
			{"id": "putar", "name": "Tendangan Putar", "ap": 3, "target": "all_enemies", "keys": 3, "power": 0.9,
				"desc": "Tendangan berputar ke SEMUA musuh."},
			{"id": "teriak", "name": "Teriak Jam Pulang", "ap": 1, "target": "none", "keys": 0, "power": 0,
				"desc": "Party ATK +30% selama 2 giliran. Tanpa QTE."},
		],
	},
	"tara": {
		"name": "Tara", "hp": 50, "atk": 8, "spd": 12, "color": Color("1f8a8a"), "scale": 0.42,
		"idle": "res://assets/sprites/tara_idle.png",
		"attack": "res://assets/sprites/tara_attack.png",
		"side": "res://assets/world/tara_side.png",
		"faces": {"normal": "skeptis", "happy": "usil", "focus": "fokus", "hurt": "lelah", "tired": "lelah"},
		"skills": [
			{"id": "sapuan", "name": "Sapuan Kaki", "ap": 2, "target": "enemy", "keys": 3, "power": 1.1,
				"desc": "Sapuan kaki rendah. Semua PERFECT = musuh pusing (lewat 1 giliran)."},
			{"id": "badai", "name": "Badai Dokumen", "ap": 3, "target": "all_enemies", "keys": 4, "power": 0.8,
				"desc": "Kipas dokumen ke SEMUA musuh."},
			{"id": "semangat", "name": "Semangat Pagi", "ap": 2, "target": "ally", "keys": 2, "power": 0,
				"desc": "Pulihkan HP satu teman (bisa bangkitkan). QTE bagus = pulih lebih banyak."},
		],
	},
}

## Serangan musuh: tiap serangan = daftar jeda antar hit (detik) + flag "berat"
## (hit merah: tidak bisa di-parry, harus DODGE).
const ENEMIES := {
	"deadline": {"name": "Deadline", "hp": 70, "atk": 8, "spd": 11, "scale": 0.47, "color": Color("f07a1f"),
		"sprite": "res://assets/sprites/deadline.png", "exp": 14, "money": 8000, "npc": "npc_deadline",
		"quote": "Waktu tidak pernah cukup.",
		"moves": [
			{"name": "Tusuk Jarum Jam", "hits": [0.7], "power": 1.0},
			{"name": "TIK-TAK-TIK", "hits": [0.6, 0.35, 0.35], "power": 0.5},
			{"name": "Waktu Habis!", "hits": [1.1, 0.25], "power": 0.8, "heavy": [false, true]},
		]},
	"revisi": {"name": "Revisi", "hp": 60, "atk": 7, "spd": 13, "scale": 0.46, "color": Color("9a5ad0"),
		"sprite": "res://assets/sprites/revisi.png", "exp": 14, "money": 8000, "npc": "npc_revisi",
		"quote": "Masih ada yang bisa diperbaiki kok.",
		"moves": [
			{"name": "Coret Merah", "hits": [0.55, 0.45], "power": 0.6},
			{"name": "Revisi Lagi :)", "hits": [0.9, 0.2, 0.2, 0.2], "power": 0.35},
			{"name": "Revisi Final_v7", "hits": [0.5, 0.9], "power": 0.8, "heavy": [false, true]},
		]},
	"target": {"name": "Target", "hp": 95, "atk": 9, "spd": 8, "scale": 0.47, "color": Color("9be02a"),
		"sprite": "res://assets/sprites/target.png", "exp": 20, "money": 12000, "npc": "npc_target",
		"quote": "Angka harus naik.",
		"moves": [
			{"name": "Gigit Kalkulator", "hits": [0.8], "power": 1.2},
			{"name": "Angka Naik Terus", "hits": [0.5, 0.5, 0.3], "power": 0.6},
			{"name": "Grafik Anjlok", "hits": [1.3], "power": 1.6, "heavy": [true]},
		]},
	"lembur": {"name": "Lembur", "hp": 150, "atk": 11, "spd": 9, "scale": 0.58, "color": Color("e6186e"),
		"sprite": "res://assets/sprites/lembur.png", "exp": 45, "money": 25000, "npc": "npc_lembur",
		"quote": "Kerja masih bisa lebih banyak.",
		"moves": [
			{"name": "Tinju Lembur", "hits": [0.75, 0.4], "power": 0.8},
			{"name": "Struk Tanpa Akhir", "hits": [0.6, 0.25, 0.25, 0.25, 0.25], "power": 0.35, "all": true},
			{"name": "Shift Tambahan", "hits": [1.4, 0.2], "power": 1.2, "heavy": [true, false]},
		]},
}

## Varian (mini-boss / boss) = musuh dasar + pengali + warna.
const VARIANTS := {
	"revisi_agung": {"base": "revisi", "name": "Revisi Agung", "hp_mul": 2.6, "atk_mul": 1.3, "scale_mul": 1.25,
		"tint": Color(1.0, 0.8, 1.1), "boss": true, "exp": 60, "money": 30000},
	"target_raksasa": {"base": "target", "name": "Target Raksasa", "hp_mul": 2.6, "atk_mul": 1.25, "scale_mul": 1.3,
		"tint": Color(0.9, 1.1, 0.8), "boss": true, "exp": 70, "money": 30000},
	"lembur_manajer": {"base": "lembur", "name": "Manajer Lembur", "hp_mul": 1.6, "atk_mul": 1.1, "scale_mul": 1.1,
		"tint": Color(1.1, 0.85, 0.95), "boss": true, "exp": 80, "money": 35000},
	"lembur_abadi": {"base": "lembur", "name": "LEMBUR ABADI", "hp_mul": 3.4, "atk_mul": 1.35, "scale_mul": 1.35,
		"tint": Color(0.75, 0.6, 0.9), "boss": true, "exp": 0, "money": 0, "final": true},
}

const ITEMS := {
	"nasi": {"name": "Nasi Bungkus", "icon": "res://assets/world/it_nasi.png", "price": 15000, "target": "ally", "hp": 50,
		"desc": "+50 HP satu teman. Bisa membangunkan yang tumbang."},
	"kopi": {"name": "Kopi Susu", "icon": "res://assets/world/it_kopi.png", "price": 18000, "target": "ally", "ap": 3,
		"desc": "+3 AP. Melek lagi."},
	"air": {"name": "Air Mineral", "icon": "res://assets/world/it_air.png", "price": 5000, "target": "ally", "hp": 15,
		"desc": "+15 HP."},
	"roti": {"name": "Roti Bakar", "icon": "res://assets/world/it_roti.png", "price": 12000, "target": "ally", "hp": 30,
		"desc": "+30 HP."},
	"permen": {"name": "Permen Jahe", "icon": "res://assets/world/it_permen.png", "price": 8000, "target": "ally", "cure": true,
		"desc": "Hapus panik (efek buruk) + 10 HP."},
	"plester": {"name": "Plester", "icon": "res://assets/world/it_plester.png", "price": 10000, "target": "ally", "hp": 25,
		"desc": "+25 HP."},
	"kartu": {"name": "Kartu MRT", "icon": "res://assets/sprites/item_kartu.png", "price": 25000, "target": "all_enemies", "dmg": 30,
		"desc": "Tap! Kereta MRT lewat: 30 damage ke semua musuh."},
}

## NPC (potret + nama) untuk dialog.
const NPCS := {
	"bu_sari": {"name": "Bu Sari", "color": Color("c0392b"), "tex": "res://assets/world/face_busari.png"},
	"pak_dedi": {"name": "Pak Dedi", "color": Color("f07a1f"), "tex": "res://assets/world/npc_deadline.png"},
	"mbak_rani": {"name": "Mbak Rani", "color": Color("9a5ad0"), "tex": "res://assets/world/npc_revisi.png"},
	"bang_joko": {"name": "Bang Joko", "color": Color("6a9a2a"), "tex": "res://assets/world/npc_target.png"},
	"pak_haris": {"name": "Pak Haris", "color": Color("b0104e"), "tex": "res://assets/world/npc_lembur.png"},
	"pekerja": {"name": "Pekerja", "color": Color("5a5068"), "tex": "res://assets/world/npc_deadline.png"},
	"karyawati": {"name": "Karyawati", "color": Color("5a5068"), "tex": "res://assets/world/npc_revisi.png"},
	"satpam": {"name": "Satpam", "color": Color("2c4a7a"), "tex": "res://assets/world/npc_target.png"},
}

var party := {}
var bag := {}
var money := 60000
var flags := {}
var area := "dukuh"
var pos := Vector2(300, 600)
var stats := {"parry": 0, "perfect": 0, "battles": 0}
var play_time := 0.0

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


func _process(delta: float) -> void:
	play_time += delta


func _auto_shots() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout
		shot("auto")


func new_run() -> void:
	party.clear()
	for id in HEROES:
		var d: Dictionary = HEROES[id]
		party[id] = {"hp": d.hp, "max_hp": d.hp, "atk": d.atk, "spd": d.spd, "level": 1, "exp": 0}
	bag = {"nasi": 2, "air": 3, "kopi": 1, "plester": 1}
	money = 60000
	flags = {}
	area = "dukuh"
	pos = Vector2(260, 610)
	stats = {"parry": 0, "perfect": 0, "battles": 0}
	play_time = 0.0
	changed.emit()


func full_heal() -> void:
	for id in party:
		party[id].hp = party[id].max_hp
	changed.emit()


func flag(k: String) -> bool:
	return flags.get(k, false)


func set_flag(k: String, v := true) -> void:
	flags[k] = v
	changed.emit()


func cards() -> int:
	var n := 0
	for k in ["kartu_monas", "kartu_kotatua", "kartu_blokm"]:
		if flag(k):
			n += 1
	return n


func add_item(id: String, n := 1) -> void:
	bag[id] = bag.get(id, 0) + n
	changed.emit()


func use_item(id: String) -> void:
	bag[id] = max(0, bag.get(id, 0) - 1)
	if bag[id] == 0:
		bag.erase(id)
	changed.emit()


func bag_total() -> int:
	var n := 0
	for id in bag:
		n += bag[id]
	return n


func exp_next(level: int) -> int:
	return 30 + level * 20


## Tambah EXP ke semua hero. Kembalikan daftar teks level up.
func gain_exp(n: int) -> Array:
	var ups := []
	for id in party:
		var p: Dictionary = party[id]
		p.exp += n
		while p.exp >= exp_next(p.level):
			p.exp -= exp_next(p.level)
			p.level += 1
			p.max_hp += 8
			p.atk += 2
			p.hp = p.max_hp
			ups.append("%s naik ke Lv %d!  HP +8  ATK +2" % [HEROES[id].name, p.level])
	changed.emit()
	return ups


func enemy_data(id: String) -> Dictionary:
	if ENEMIES.has(id):
		var d: Dictionary = ENEMIES[id].duplicate(true)
		d["kind"] = id
		return d
	var v: Dictionary = VARIANTS[id]
	var d: Dictionary = ENEMIES[v.base].duplicate(true)
	d["kind"] = v.base
	d.name = v.name
	d.hp = int(d.hp * v.hp_mul)
	d.atk = int(round(d.atk * v.atk_mul))
	d.scale = d.scale * v.scale_mul
	d["tint"] = v.tint
	d["boss"] = true
	d.exp = v.exp
	d.money = v.money
	d["final"] = v.get("final", false)
	return d


func rp(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return "Rp " + out


# ---------------------------------------------------------------- simpan

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var d := {"party": party, "bag": bag, "money": money, "flags": flags, "area": area,
		"pos": [pos.x, pos.y], "stats": stats, "time": play_time}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	new_run()
	for id in d.party:
		for k in d.party[id]:
			party[id][k] = int(d.party[id][k])
	bag = {}
	for k in d.bag:
		bag[k] = int(d.bag[k])
	money = int(d.money)
	flags = d.flags
	area = d.area
	pos = Vector2(d.pos[0], d.pos[1])
	for k in d.stats:
		stats[k] = int(d.stats[k])
	play_time = float(d.get("time", 0.0))
	changed.emit()
	return true


# ---------------------------------------------------------------- input

func is_act(e: InputEvent) -> bool:
	if e.is_action_pressed("act"):
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


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
	_add_keys("menu", [KEY_C, KEY_TAB, KEY_I])
	_add_keys("parry", [KEY_Z, KEY_J])
	_add_keys("dodge", [KEY_X, KEY_K])
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("ui_accept", [KEY_Z, KEY_J])
	_add_keys("ui_cancel", [KEY_X, KEY_K])
	for pair in [["act", JOY_BUTTON_A], ["back", JOY_BUTTON_B], ["parry", JOY_BUTTON_RIGHT_SHOULDER], ["dodge", JOY_BUTTON_B], ["menu", JOY_BUTTON_Y]]:
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
