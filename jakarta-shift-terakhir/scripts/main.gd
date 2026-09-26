extends Node
## Scene manager: Judul -> Cerita -> Babak 1 -> Cerita -> Babak 2 (boss)
## -> Ending. Transisi pakai sobekan kertas.

const STORY := {
	"intro": [
		["narator", "", "Jakarta, 18.47. Stasiun MRT Dukuh Atas. Jam pulang kantor."],
		["tara", "tired", "Akhirnya... pulang. Delapan jam rapat yang harusnya cukup jadi email."],
		["raka", "happy", "Semangat, Tar! Tinggal tap kartu, duduk, tidur sampai Blok M."],
		["tara", "normal", "Raka... kenapa orang-orang kantor jalannya kayak zombie gitu?"],
		["raka", "normal", "Hah? Itu Pak Dedi dari Finance... kok kepalanya jadi jam dinding?"],
		["deadline", "", "TIK. TAK. TIK. TAK. WAKTU... TIDAK PERNAH... CUKUP."],
		["tara", "focus", "Mereka DIRASUKI LEMBUR! Raka, siapin payungmu!"],
		["raka", "focus", "Nggak ada yang boleh ganggu jam pulangku!"],
	],
	"mid": [
		["narator", "", "Blok M, 21.15. Warung kopi masih buka. HP & Semangat pulih sepenuhnya!"],
		["raka", "happy", "Kopi susu dua, Bu! ...Ahh, hidup lagi."],
		["tara", "happy", "Tadi kamu teriak 'JAM PULANGKU' kenceng banget lho."],
		["raka", "normal", "...Nggak usah dibahas."],
		["tara", "normal", "Tunggu. Udaranya berat... kayak hari Senin pagi."],
		["lembur", "", "KERJA. MASIH. BISA. LEBIH. BANYAK."],
		["raka", "focus", "Itu sumbernya! Bos terakhir: LEMBUR!"],
		["tara", "focus", "Ini shift terakhir kita. Ayo selesaikan!"],
	],
	"end": [
		["narator", "", "Kertas-kertas lembur beterbangan, lalu lenyap tertiup angin malam Jakarta."],
		["tara", "happy", "Jadi... besok masuk jam berapa?"],
		["raka", "tired", "Jangan. Sebut. Kerjaan."],
		["tara", "happy", "Hahaha! Yuk, pulang. Kali ini beneran pulang."],
	],
}

var current: Node
var fade_layer: CanvasLayer
var wipe: Polygon2D
var dialog: Dialogue
var dialog_layer: CanvasLayer


func _ready() -> void:
	randomize()
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 50
	add_child(dialog_layer)
	dialog = Dialogue.new()
	dialog_layer.add_child(dialog)
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	wipe = Polygon2D.new()
	wipe.color = Game.INK
	var pts := PackedVector2Array([Vector2(-40, -40)])
	for i in 25:
		pts.append(Vector2(1400 + (i % 2) * 40 + randf_range(-10, 10), -40 + i * 33))
	pts.append(Vector2(-40, 800))
	wipe.polygon = pts
	wipe.position.x = -1500
	fade_layer.add_child(wipe)
	_title()


func _swap(n: Node) -> void:
	if current:
		current.queue_free()
	current = n
	add_child(n)
	move_child(n, 0)


func cover() -> void:
	Sfx.play("sfx_paper", -2.0, 0.7)
	wipe.position.x = -1500
	var tw := create_tween()
	tw.tween_property(wipe, "position:x", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func reveal() -> void:
	var tw := create_tween()
	tw.tween_property(wipe, "position:x", 1500.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	wipe.position.x = -1500


func _title() -> void:
	var t := TitleScreen.new()
	_swap(t)
	await t.start
	await cover()
	Game.new_run()
	await _story("intro", "res://assets/bg/dukuh_atas.jpg", "bgm_title")
	await _battle(1)


## Adegan cerita di atas latar panggung.
func _story(key: String, bg_path: String, music: String) -> void:
	var root := Node2D.new()
	var bg := Sprite2D.new()
	bg.texture = load(bg_path)
	bg.position = Vector2(640, 360)
	var s := maxf(1280.0 / bg.texture.get_width(), 720.0 / bg.texture.get_height()) * 1.05
	bg.scale = Vector2(s, s)
	root.add_child(bg)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0, 0, 0, 0.25)
	root.add_child(shade)
	# Pemeran berdiri di panggung
	var cast := {"tara": Vector2(760, 560), "raka": Vector2(560, 550)}
	for id in cast:
		var sp := Sprite2D.new()
		sp.texture = load(Game.HEROES[id].idle)
		sp.offset = Vector2(0, -sp.texture.get_height() / 2.0)
		sp.position = cast[id]
		sp.scale = Vector2.ONE * Game.HEROES[id].scale * 0.9
		root.add_child(sp)
		var tw := sp.create_tween().set_loops()
		tw.tween_property(sp, "skew", 0.03, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(sp, "skew", -0.03, 1.2).set_trans(Tween.TRANS_SINE)
	_swap(root)
	Sfx.music(music)
	await reveal()
	Game.shot("cerita_" + key)
	await dialog.play(STORY[key])
	await cover()


func _battle(n: int) -> void:
	var b := Battle.new()
	b.stage_no = n
	_swap(b)
	await reveal()
	var result := await b.run()
	await cover()
	if result == "win":
		if n == 1:
			Game.full_heal()
			await _story("mid", "res://assets/bg/blok_m.jpg", "bgm_title")
			await _battle(2)
		else:
			await _story("end", "res://assets/bg/blok_m.jpg", "bgm_title")
			await _ending()
	else:
		await _game_over(n)


func _card_screen(title: String, color: Color, lines: Array, options: Array, art: Array = []) -> Variant:
	var root := Control.new()
	root.theme = Game.ui_theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bgc := ColorRect.new()
	bgc.color = Color("201a26")
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bgc)
	var conf := Node2D.new()
	root.add_child(conf)
	var t := Fx.label(title, 110, color, 20)
	t.size = Vector2(1280, 150)
	t.position = Vector2(0, 90)
	t.pivot_offset = Vector2(640, 75)
	t.rotation = deg_to_rad(-3)
	root.add_child(t)
	var y := 270.0
	for l in lines:
		var ll := Fx.label(l, 34, Game.CREAM, 8, Game.FONT_UI)
		ll.size = Vector2(1280, 44)
		ll.position = Vector2(0, y)
		root.add_child(ll)
		y += 48
	for i in art.size():
		var tr := TextureRect.new()
		tr.texture = load(art[i])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.size = Vector2(300, 320)
		tr.position = Vector2(30 if i == 0 else 950, 380)
		tr.flip_h = i == 1
		tr.pivot_offset = tr.size / 2
		tr.rotation = deg_to_rad(-6 if i == 0 else 6)
		root.add_child(tr)
		var tw := tr.create_tween().set_loops()
		tw.tween_property(tr, "position:y", 368.0, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(tr, "position:y", 380.0, 0.9).set_trans(Tween.TRANS_SINE)
	var menu := CommandMenu.new()
	root.add_child(menu)
	_swap(root)
	if color == Game.YELLOW:
		for i in 3:
			Fx.burst(root, Vector2(320 + i * 320, 120), "confetti", 40, 1.0)
	await reveal()
	Game.shot("kartu")
	var v = await menu.open(options, "", Vector2(515, y + 30), false)
	return v


func _ending() -> void:
	Sfx.music("bgm_title")
	var lines := [
		"Terima kasih sudah main demo JAKARTA: SHIFT TERAKHIR!",
		"NICE! x%d     GUARD! x%d     Ronde: %d" % [Game.stats.nice, Game.stats.guard, Game.stats.turns],
	]
	var v = await _card_screen("DEMO SELESAI!", Game.YELLOW, lines,
		[{"id": "title", "label": "Kembali ke Judul", "icon": "res://assets/ui/icon_star.png", "desc": ""}],
		["res://assets/sprites/raka_attack.png", "res://assets/sprites/tara_attack.png"])
	await cover()
	_title()


func _game_over(n: int) -> void:
	Sfx.music("bgm_title")
	var v = await _card_screen("KAMU LEMBUR...", Color("ff6a6a"),
		["Tara dan Raka tumbang. Kantor menang malam ini.", "Tapi besok masih ada kesempatan!"],
		[{"id": "retry", "label": "Coba Lagi", "icon": "res://assets/ui/icon_star.png", "desc": ""},
		 {"id": "title", "label": "Ke Judul", "icon": "res://assets/ui/icon_shield.png", "desc": ""}],
		["res://assets/sprites/face_raka_lelah.png", "res://assets/sprites/face_tara_lelah.png"])
	await cover()
	if v == "retry":
		Game.full_heal()
		for id in Game.ITEMS:
			Game.bag[id] = max(Game.bag[id], 1)
		await _battle(n)
	else:
		_title()
