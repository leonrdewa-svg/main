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
	var opts := []
	if Game.has_save():
		opts.append({"id": "load", "label": "Lanjutkan", "icon": "res://assets/ui/icon_star.png", "desc": "Lanjut dari simpanan terakhir."})
	opts.append({"id": "new", "label": "Main Baru", "icon": "res://assets/ui/icon_sp.png", "desc": "Mulai cerita dari awal (sekitar 1 jam)."})
	var m := CommandMenu.new()
	t.add_child(m)
	var c = "new"
	if not Game.autoplay or Game.has_save():
		c = await m.open(opts, "", Vector2(515, 540), false)
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
		await w.talk(Story.D.intro)
	_continue_world(w, area)


func _battle(area: String, def: Dictionary, strike: String) -> void:
	await cover()
	var b := Battle.new()
	b.bg_path = Story.AREAS[area].bg
	b.group = def.group
	b.first_strike = strike
	b.music = "bgm_boss" if def.get("boss", false) else "bgm_battle"
	if def.get("boss", false):
		b.title = "BOS: " + Game.enemy_data(def.group[0]).name.to_upper()
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
			await w.talk(Story.D[def.post])
			Game.set_flag(def.card)
			Sfx.play("sfx_star")
		if area == "dukuh" and not Game.flag("prolog_done") and Game.flag("def_da_1") and Game.flag("def_da_2"):
			await w.talk(Story.D.prolog_done)
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
	await w.talk(Story.D.final_pre)
	await _battle_final()


func _battle_final() -> void:
	await cover()
	var b := Battle.new()
	b.bg_path = Story.AREAS.scbd.bg
	b.group = ["lembur_abadi"]
	b.music = "bgm_boss"
	b.title = "BOS TERAKHIR: LEMBUR ABADI"
	_swap(b)
	await reveal()
	var result := await b.run()
	await cover()
	if result == "win":
		await _ending()
	else:
		await _game_over("scbd")


func _game_over(area: String) -> void:
	var v = await _card_screen("KAMU LEMBUR...", Color("ff6a6a"),
		["Tara dan Raka tumbang. Tapi Bu Sari menemukan kalian dan memberi teh hangat.",
		 "HP pulih. Kalian kembali ke papan MRT (uang -10%)."],
		[{"id": "retry", "label": "Bangkit Lagi", "icon": "res://assets/ui/icon_star.png", "desc": ""},
		 {"id": "title", "label": "Ke Judul", "icon": "res://assets/ui/icon_shield.png", "desc": ""}])
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
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/bg/dukuh_atas.jpg")
	bg.position = Vector2(640, 360)
	bg.scale = Vector2.ONE * (1280.0 / bg.texture.get_width())
	root.add_child(bg)
	_swap(root)
	Sfx.music("bgm_title")
	await reveal()
	await dialog.play(Story.D.ending)
	await cover()
	var mins := int(Game.play_time / 60.0)
	await _card_screen("SHIFT SELESAI!", Game.YELLOW, [
		"Terima kasih sudah bermain JAKARTA: SHIFT TERAKHIR!",
		"Raka Lv %d · Tara Lv %d · Parry %d · Perfect %d · Waktu %d menit" % [Game.party.raka.level, Game.party.tara.level, Game.stats.parry, Game.stats.perfect, mins],
	], [{"id": "title", "label": "Kembali ke Judul", "icon": "res://assets/ui/icon_star.png", "desc": ""}],
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
