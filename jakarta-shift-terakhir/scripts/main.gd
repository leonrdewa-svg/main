extends Node
## Scene manager: Judul -> Dunia (eksplorasi) <-> Battle / Peta MRT / Warung
## -> Menara Shift -> Ending. Transisi sobekan kertas.

var current: Node
var wipe: Polygon2D
var dialog: Dialogue


func _ready() -> void:
	randomize()
	var dl := CanvasLayer.new()
	dl.layer = 50
	add_child(dl)
	dialog = Dialogue.new()
	dl.add_child(dialog)
	var fl := CanvasLayer.new()
	fl.layer = 100
	add_child(fl)
	wipe = Polygon2D.new()
	wipe.color = Game.INK
	var pts := PackedVector2Array([Vector2(-40, -40)])
	for i in 25:
		pts.append(Vector2(1400 + (i % 2) * 40 + randf_range(-10, 10), -40 + i * 33))
	pts.append(Vector2(-40, 800))
	wipe.polygon = pts
	wipe.position.x = -1500
	fl.add_child(wipe)
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
	tw.tween_property(wipe, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished


func reveal() -> void:
	var tw := create_tween()
	tw.tween_property(wipe, "position:x", 1500.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	wipe.position.x = -1500


# ------------------------------------------------------------------ judul

func _title() -> void:
	var t := TitleScreen.new()
	_swap(t)
	await t.start
	var m := CommandMenu.new()
	t.add_child(m)
	var c = "new"
	while true:
		var opts := []
		if Game.has_save():
			opts.append({"id": "load", "label": Game.L("Lanjutkan", "Continue"), "icon": "res://assets/ui/icon_star.png", "desc": Game.L("Lanjut dari simpanan terakhir.", "Continue from your last save.")})
		opts.append({"id": "new", "label": Game.L("Main Baru", "New Game"), "icon": "res://assets/ui/icon_sp.png", "desc": Game.L("Mulai cerita dari awal (sekitar 1 jam).", "Start the story from the beginning (about 1 hour).")})
		opts.append({"id": "touch", "label": Game.L("Kontrol: Sentuh (HP)", "Controls: Touch (phone)") if Game.touch_mode else Game.L("Kontrol: PC (keyboard)", "Controls: PC (keyboard)"), "icon": "res://assets/ui/icon_heart.png", "desc": Game.L("Sentuh = joystick & tombol besar di layar untuk HP. PC = keyboard/mouse.", "Touch = on-screen joystick & big buttons for phones. PC = keyboard/mouse.")})
		opts.append({"id": "lang", "label": Game.L("Bahasa: Indonesia", "Language: English"), "icon": "res://assets/ui/icon_shield.png", "desc": Game.L("Ganti bahasa teks. Suara tetap bahasa Jepang.", "Switch text language. Voices stay in Japanese.")})
		if Game.autoplay and not Game.has_save():
			break
		t.prompt.visible = false
		m.desc_panel.position = Vector2(290, 640)
		c = await m.open(opts, "", Vector2(515, 400), false)
		if c == "touch":
			Game.set_touch(not Game.touch_mode)
			continue
		if c != "lang":
			break
		Game.set_lang("en" if Game.lang == "id" else "id")
	await cover()
	if c == "load" and Game.load_game():
		_world(Game.area)
	else:
		Game.new_run()
		_world("dukuh", true)


# ------------------------------------------------------------------ dunia

func _world(area: String, intro := false) -> void:
	Game.area = area
	var w := World.new()
	w.area_id = area
	_swap(w)
	await reveal()
	Game.shot("dunia_" + area)
	if intro:
		await w.talk(Story.D.intro, "intro")
	_continue_world(w, area)


func _battle(area: String, def: Dictionary, strike: String) -> void:
	await cover()
	var b := Battle.new()
	b.bg_path = Story.AREAS[area].bg
	b.group = def.group
	b.first_strike = strike
	b.lvl = float(Story.AREAS[area].get("lvl", 1.0))
	b.music = "bgm_boss" if def.get("boss", false) else "bgm_battle"
	if def.get("boss", false):
		b.title = Game.L("BOS: ", "BOSS: ") + Game.T(Game.enemy_data(def.group[0]).name).to_upper()
	_swap(b)
	await reveal()
	var result := await b.run()
	await cover()
	if result == "win":
		Game.set_flag("def_" + def.id)
		Game.area = area
		var w := World.new()
		w.area_id = area
		_swap(w)
		await reveal()
		if def.has("post"):
			await w.talk(Story.D[def.post], def.post)
			Game.set_flag(def.card)
			Sfx.play("sfx_star")
		if area == "dukuh" and not Game.flag("prolog_done") and Game.area_defeated("dukuh") >= 4:
			await w.talk(Story.D.prolog_done, "prolog_done")
			Game.set_flag("prolog_done")
		w.refresh_ui()
		Game.save_game()
		# lanjutkan loop dunia dengan node yang sudah ada
		_continue_world(w, area)
	else:
		await _game_over(area)


func _continue_world(w: World, area: String) -> void:
	var ev: Array = await w.event
	match ev[0]:
		"battle":
			await _battle(area, ev[1].def, ev[1].strike)
		"station":
			await _map()
		"shop":
			await cover()
			var s := ShopScreen.new()
			_swap(s)
			await reveal()
			await s.done
			await cover()
			_world(area)
		"gate":
			await _final()
		"reload":
			_world(area)
		"title":
			await cover()
			_title()


func _map() -> void:
	await cover()
	var m := MapScreen.new()
	_swap(m)
	await reveal()
	var c: String = await m.done
	await cover()
	if c == "rest":
		Game.full_heal()
		Sfx.play("sfx_heal")
		Game.save_game()
		_world(Game.area)
	elif c == "" or c == Game.area:
		_world(Game.area)
	else:
		Game.pos = Vector2(Story.AREAS[c].station.x + 110, 640)
		Game.area = c
		Game.save_game()
		_world(c)


func _final() -> void:
	var w: World = current
	await w.talk(Story.D.final_pre, "final_pre")
	await _battle_final()


func _battle_final() -> void:
	await cover()
	var b := Battle.new()
	b.bg_path = Story.AREAS.scbd.bg
	b.group = ["lembur_abadi"]
	b.lvl = 2.3
	b.music = "bgm_boss"
	b.title = Game.L("BOS TERAKHIR: LEMBUR ABADI", "FINAL BOSS: ETERNAL OVERTIME")
	_swap(b)
	await reveal()
	var result := await b.run()
	await cover()
	if result == "win":
		await _ending()
	else:
		await _game_over("scbd")


func _game_over(area: String) -> void:
	var v = await _card_screen(Game.L("KAMU LEMBUR...", "OVERTIME WINS..."), Color("ff6a6a"),
		[Game.L("Tara dan Raka tumbang. Tapi Bu Sari menemukan kalian dan memberi teh hangat.", "Tara and Raka collapsed. But Bu Sari found you and brought warm tea."),
		 Game.L("HP pulih. Kalian kembali ke papan MRT (uang -10%).", "HP restored. You're back at the MRT sign (money -10%).")],
		[{"id": "retry", "label": Game.L("Bangkit Lagi", "Get Back Up"), "icon": "res://assets/ui/icon_star.png", "desc": ""},
		 {"id": "title", "label": Game.L("Ke Judul", "Title Screen"), "icon": "res://assets/ui/icon_shield.png", "desc": ""}])
	await cover()
	Game.full_heal()
	Game.money = int(Game.money * 0.9)
	if v == "retry":
		Game.pos = Vector2(Story.AREAS[area].station.x + 110, 640)
		_world(area)
	else:
		_title()


func _ending() -> void:
	var root := Node2D.new()
	var bg := LiveBg.new()
	root.add_child(bg)
	bg.setup("res://assets/bg/dukuh_atas.jpg")
	_swap(root)
	Sfx.music("bgm_title")
	await reveal()
	await dialog.play(Story.D.ending, "ending")
	await cover()
	var mins := int(Game.play_time / 60.0)
	await _card_screen(Game.L("SHIFT SELESAI!", "SHIFT OVER!"), Game.YELLOW, [
		Game.L("Terima kasih sudah bermain JAKARTA: SHIFT TERAKHIR!", "Thank you for playing JAKARTA: LAST SHIFT!"),
		Game.L("Raka Lv %d · Tara Lv %d · Parry %d · Perfect %d · Waktu %d menit", "Raka Lv %d · Tara Lv %d · Parry %d · Perfect %d · Time %d min") % [Game.party.raka.level, Game.party.tara.level, Game.stats.parry, Game.stats.perfect, mins],
	], [{"id": "title", "label": Game.L("Kembali ke Judul", "Back to Title"), "icon": "res://assets/ui/icon_star.png", "desc": ""}],
	["res://assets/sprites/raka_attack.png", "res://assets/sprites/tara_attack.png"])
	await cover()
	_title()


func _card_screen(title: String, color: Color, lines: Array, options: Array, art: Array = []) -> Variant:
	var root := Control.new()
	root.theme = Game.ui_theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bgc := ColorRect.new()
	bgc.color = Color("201a26")
	bgc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bgc)
	var t := Fx.label(title, 110, color, 20)
	t.size = Vector2(1280, 150)
	t.position = Vector2(0, 80)
	t.pivot_offset = Vector2(640, 75)
	t.rotation = deg_to_rad(-3)
	root.add_child(t)
	var y := 260.0
	for l in lines:
		var ll := Fx.label(l, 30, Game.CREAM, 8, Game.FONT_UI)
		ll.size = Vector2(1280, 44)
		ll.position = Vector2(0, y)
		root.add_child(ll)
		y += 46
	for i in art.size():
		var tr := TextureRect.new()
		tr.texture = load(art[i])
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		tr.size = Vector2(300, 320)
		tr.position = Vector2(30 if i == 0 else 950, 380)
		tr.flip_h = i == 1
		root.add_child(tr)
	var menu := CommandMenu.new()
	root.add_child(menu)
	_swap(root)
	if color == Game.YELLOW:
		for i in 3:
			Fx.burst(root, Vector2(320 + i * 320, 120), "confetti", 40, 1.0)
	await reveal()
	Game.shot("kartu")
	return await menu.open(options, "", Vector2(515, y + 30), false)
