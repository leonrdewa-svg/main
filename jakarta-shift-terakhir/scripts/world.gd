class_name World
extends Node2D
## Satu area yang bisa dijelajahi: pemain (Raka) + Tara mengikuti, NPC,
## pekerja dirasuki yang berkeliaran, papan MRT, warung, gerbang.
## Mengirim event ke main: battle / map / shop / gate / title.

signal event(kind: String, data: Dictionary)

const SPEED := 270.0
const TALK_DIST := 120.0

var area_id := "dukuh"
var A: Dictionary
var actors: Node2D
var player: Walker
var tara: Walker
var trail: Array = []
var npcs: Array = []      # {node, def}
var roamers: Array = []   # Roamer
var marks: Array = []     # {node, kind, pos}
var dialog: Dialogue
var menu: CommandMenu
var ui: CanvasLayer
var prompt_l: Label
var obj_l: Label
var money_l: Label
var busy := false
var _grace := 1.2
var _click_target := Vector2.INF
var _click_interact: Variant = null
var _auto_t := 0.0


func _ready() -> void:
	A = Story.AREAS[area_id]
	var bg := LiveBg.new()
	add_child(bg)
	bg.setup(A.bg)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)

	# penanda interaksi
	_mark("station", A.station, "MRT", Color("1d4f9c"))
	if A.has("shop"):
		_mark("shop", A.shop, Game.L("WARUNG BU SARI", "BU SARI'S STALL"), Color("c0392b"))
		var bs := Sprite2D.new()
		bs.texture = load("res://assets/world/face_busari.png")
		bs.scale = Vector2(0.32, 0.32)
		bs.position = A.shop + Vector2(0, -70)
		actors.add_child(bs)
	if A.has("gate"):
		_mark("gate", A.gate, Game.L("GERBANG MENARA (%d/3)", "TOWER GATE (%d/3)") % Game.cards(), Color("8a1a32"))

	for n in A.npcs:
		_add_npc(n.sprite, n.pos, {"talk": n.talk, "who": n.who})
	for e in A.enemies:
		if Game.flag("def_" + e.id):
			var kind: String = Game.enemy_data(e.group[0]).kind
			var spr: String = "res://assets/world/%s.png" % Game.ENEMIES[kind].npc
			_add_npc(spr, e.pos, {"freed": true, "n": abs(e.id.hash()) % Story.FREED.size()})
		else:
			var r := Roamer.new()
			r.def = e
			r.world = self
			actors.add_child(r)
			r.setup()
			roamers.append(r)

	player = Walker.new()
	player.floor_y = Vector2(A.floor[0], A.floor[1])
	actors.add_child(player)
	player.setup({"right": load("res://assets/world/raka_walk_right.png"), "left": load("res://assets/world/raka_walk_left.png"),
		"up": load("res://assets/world/raka_walk_up.png"), "down": load("res://assets/world/raka_walk_down.png")}, 0.95)
	player.position = Game.pos
	player.face("right")
	tara = Walker.new()
	tara.floor_y = player.floor_y
	actors.add_child(tara)
	tara.setup({"right": load("res://assets/world/tara_side.png")}, 0.64, true)
	tara.position = player.position + Vector2(-70, -6)
	for i in 14:
		trail.append(tara.position)

	_build_ui()
	Sfx.music(A.music)


func _mark(kind: String, pos: Vector2, text: String, col: Color) -> void:
	var n := Node2D.new()
	n.position = pos
	actors.add_child(n)
	var p := Panel.new()
	p.theme = Game.ui_theme
	p.add_theme_stylebox_override("panel", Game.paper_box(col, Game.INK, 8, 4))
	var l := Fx.label(text, 24, Color.WHITE, 6)
	var w: float = Game.FONT_TITLE.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 30
	p.size = Vector2(w, 38)
	p.position = Vector2(-w / 2, -150)
	l.size = p.size
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_child(p)
	var pole := ColorRect.new()
	pole.color = Game.INK
	pole.size = Vector2(6, 112)
	pole.position = Vector2(-3, -112)
	n.add_child(pole)
	var tw := p.create_tween().set_loops()
	tw.tween_property(p, "position:y", -156.0, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(p, "position:y", -150.0, 0.8).set_trans(Tween.TRANS_SINE)
	marks.append({"node": n, "kind": kind, "pos": pos})


func _add_npc(path: String, pos: Vector2, info: Dictionary) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.offset = Vector2(0, -s.texture.get_height() / 2.0)
	s.position = pos
	s.scale = Vector2.ONE * (170.0 / s.texture.get_height())
	actors.add_child(s)
	var tw := s.create_tween().set_loops()
	tw.tween_property(s, "skew", 0.04, 1.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(s, "skew", -0.04, 1.3).set_trans(Tween.TRANS_SINE)
	npcs.append({"node": s, "info": info, "pos": pos})


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var top := Panel.new()
	top.theme = Game.ui_theme
	top.position = Vector2(16, 12)
	top.size = Vector2(820, 70)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_stylebox_override("panel", Game.paper_box(Color(0.12, 0.1, 0.14, 0.88), Game.INK, 10, 5))
	ui.add_child(top)
	var an := Fx.label(Story.area_name(area_id).to_upper(), 32, Game.YELLOW, 8)
	an.position = Vector2(14, 0)
	an.size = Vector2(800, 40)
	an.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(an)
	obj_l = Fx.label("", 20, Game.CREAM, 6, Game.FONT_UI)
	obj_l.position = Vector2(14, 36)
	obj_l.size = Vector2(800, 28)
	obj_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(obj_l)
	var mp := Panel.new()
	mp.theme = Game.ui_theme
	mp.position = Vector2(1000, 12)
	mp.size = Vector2(264, 70)
	mp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mp.add_theme_stylebox_override("panel", Game.paper_box(Game.CREAM, Game.INK, 10, 5))
	ui.add_child(mp)
	money_l = Label.new()
	money_l.position = Vector2(14, 4)
	money_l.size = Vector2(240, 62)
	money_l.add_theme_font_size_override("font_size", 22)
	mp.add_child(money_l)
	var hint := Fx.label(Game.L("Panah/WASD: jalan   Z: bicara/serang duluan   C: menu   (klik = jalan ke sana)", "Arrows/WASD: walk   Z: talk/strike first   C: menu   (click = walk there)"), 18, Game.CREAM, 6, Game.FONT_UI)
	hint.position = Vector2(0, 692)
	hint.size = Vector2(1280, 26)
	ui.add_child(hint)
	prompt_l = Fx.label("", 26, Color.WHITE, 8)
	prompt_l.size = Vector2(300, 40)
	prompt_l.visible = false
	add_child(prompt_l)
	prompt_l.z_index = 90
	dialog = Dialogue.new()
	var dl := CanvasLayer.new()
	dl.layer = 40
	add_child(dl)
	dl.add_child(dialog)
	menu = CommandMenu.new()
	ui.add_child(menu)
	menu.desc_panel.position = Vector2(290, 600)
	menu.visible = false
	refresh_ui()


func refresh_ui() -> void:
	obj_l.text = Game.L("Tujuan: ", "Goal: ") + Story.objective()
	var r: Dictionary = Game.party.raka
	var t: Dictionary = Game.party.tara
	money_l.text = Game.L("%s   Kartu %d/3\nRaka %d/%d  ·  Tara %d/%d", "%s   Cards %d/3\nRaka %d/%d  ·  Tara %d/%d") % [Game.rp(Game.money), Game.cards(), r.hp, r.max_hp, t.hp, t.max_hp]


func talk(lines: Array, key := "") -> void:
	busy = true
	player.moving = false
	tara.moving = false
	await dialog.play(lines, key)
	busy = false


# ------------------------------------------------------------------ gerak

func _process(delta: float) -> void:
	_grace = maxf(0.0, _grace - delta)
	if busy:
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Game.autoplay:
		v = _auto_dir(delta)
	if v.length() > 0.1:
		_click_target = Vector2.INF
	elif _click_target != Vector2.INF:
		var d := _click_target - player.position
		if d.length() < 10:
			_click_target = Vector2.INF
			if _click_interact != null:
				var ci = _click_interact
				_click_interact = null
				_interact(ci)
		else:
			v = d.normalized()
	player.moving = v.length() > 0.1
	if player.moving:
		var mv := Vector2(v.x, v.y * 0.65) * SPEED * delta
		player.position += mv
		player.position.x = clampf(player.position.x, 40, 1240)
		player.position.y = clampf(player.position.y, A.floor[0], A.floor[1])
		if absf(v.x) > absf(v.y):
			player.face("right" if v.x > 0 else "left")
		else:
			player.face("down" if v.y > 0 else "up")
		trail.append(player.position)
		if trail.size() > 16:
			var p: Vector2 = trail.pop_front()
			tara.moving = tara.position.distance_to(p) > 0.5
			if absf(p.x - tara.position.x) > 0.3:
				tara.face("right" if p.x > tara.position.x else "left")
			tara.position = p
	else:
		tara.moving = false
	_update_prompt()
	for r in roamers:
		if is_instance_valid(r) and r.touching(player.position) and _grace <= 0.0:
			_start_battle(r, "enemy")
			return


func _nearest() -> Variant:
	var best: Variant = null
	var bd := TALK_DIST
	for n in npcs:
		var d: float = n.pos.distance_to(player.position)
		if d < bd:
			bd = d
			best = {"type": "npc", "ref": n}
	for m in marks:
		var d: float = (m.pos as Vector2).distance_to(player.position)
		if d < bd + 20:
			bd = d
			best = {"type": m.kind, "ref": m}
	for r in roamers:
		if is_instance_valid(r):
			var d: float = r.position.distance_to(player.position)
			if d < bd + 30:
				bd = d
				best = {"type": "enemy", "ref": r}
	return best


func _update_prompt() -> void:
	var n = _nearest()
	if n == null:
		prompt_l.visible = false
		return
	prompt_l.visible = true
	var txt := {"npc": Game.L("Z: BICARA", "Z: TALK"), "station": "Z: MRT", "shop": Game.L("Z: WARUNG", "Z: SHOP"), "gate": Game.L("Z: GERBANG", "Z: GATE"), "enemy": Game.L("Z: SERANG DULUAN!", "Z: STRIKE FIRST!")}
	prompt_l.text = txt.get(n.type, "Z")
	prompt_l.label_settings.font_color = Color("ff6a6a") if n.type == "enemy" else Game.YELLOW
	prompt_l.position = player.position + Vector2(-150, -230)


func _unhandled_input(e: InputEvent) -> void:
	if busy:
		return
	if e.is_action_pressed("act"):
		get_viewport().set_input_as_handled()
		var n = _nearest()
		if n != null:
			_interact(n)
	elif e.is_action_pressed("menu") or (e.is_action_pressed("back") and not e is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		_pause_menu()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		_click_interact = null
		for n in npcs:
			if (n.pos as Vector2).distance_to(p + Vector2(0, 60)) < 80:
				_click_interact = {"type": "npc", "ref": n}
		for m in marks:
			if (m.pos as Vector2).distance_to(p + Vector2(0, 60)) < 100:
				_click_interact = {"type": m.kind, "ref": m}
		for r in roamers:
			if is_instance_valid(r) and r.position.distance_to(p + Vector2(0, 60)) < 90:
				_click_interact = {"type": "enemy", "ref": r}
		var target := p
		if _click_interact != null:
			var ref = _click_interact.ref
			target = (ref.position if ref is Node2D else ref.pos) + Vector2(-80, 0)
		_click_target = Vector2(clampf(target.x, 40, 1240), clampf(target.y, A.floor[0], A.floor[1]))
		if _click_interact != null and _click_target.distance_to(player.position) < TALK_DIST:
			_click_target = Vector2.INF
			var ci = _click_interact
			_click_interact = null
			_interact(ci)


func _interact(n: Dictionary) -> void:
	match n.type:
		"npc":
			var info: Dictionary = n.ref.info
			if info.get("freed", false):
				var fl: Array = Story.FREED[info.n]
				await talk([["pekerja", "", fl[0], fl[1], fl[2]]], "freed_%d" % info.n)
			else:
				await talk(Story.D[info.talk], info.talk)
		"station":
			Game.pos = player.position
			busy = true
			event.emit("station", {})
		"shop":
			Game.pos = player.position
			busy = true
			event.emit("shop", {})
		"gate":
			if Game.cards() < 3:
				var l: Array = Story.D.gate_locked.duplicate(true)
				l[0][2] = l[0][2] % Game.cards()
				l[0][3] = l[0][3] % Game.cards()
				await talk(l, "gate_locked")
			else:
				Game.pos = player.position
				busy = true
				event.emit("gate", {})
		"enemy":
			var r: Roamer = n.ref
			player.face("right" if r.position.x > player.position.x else "left")
			Sfx.play("sfx_hit_big")
			Fx.ring(self, r.position + Vector2(0, -80), Color.WHITE, 140)
			Fx.speed_lines(self, r.position + Vector2(0, -80), 0.3)
			_start_battle(r, "player")


func _start_battle(r: Roamer, strike: String) -> void:
	if busy:
		return
	busy = true
	player.moving = false
	Game.pos = player.position
	if r.def.get("boss", false):
		await dialog.play(Story.D[r.def.pre], r.def.pre)
		strike = ""
	else:
		r.flash_alert()
		await get_tree().create_timer(0.35).timeout
	event.emit("battle", {"def": r.def, "strike": strike})


func _pause_menu() -> void:
	busy = true
	player.moving = false
	while true:
		var c = await menu.open([
			{"id": "bag", "label": Game.L("Tas", "Bag"), "icon": "res://assets/sprites/item_tas.png", "desc": Game.L("Pakai makanan & minuman.", "Use food & drinks."), "enabled": Game.bag_total() > 0},
			{"id": "status", "label": "Status", "icon": "res://assets/ui/icon_star.png", "desc": Game.L("Level, HP, dan ATK party.", "Party level, HP and ATK.")},
			{"id": "lang", "label": Game.L("Bahasa: Indonesia", "Language: English"), "icon": "res://assets/ui/icon_sp.png", "desc": Game.L("Ganti bahasa teks (suara tetap Jepang).", "Switch text language (voices stay Japanese).")},
			{"id": "save", "label": Game.L("Simpan", "Save"), "icon": "res://assets/ui/icon_shield.png", "desc": Game.L("Simpan progres di browser/PC ini.", "Save your progress on this browser/PC.")},
			{"id": "title", "label": Game.L("Ke Judul", "Title Screen"), "icon": "res://assets/ui/icon_sp.png", "desc": Game.L("Kembali ke layar judul (progres terakhir yang disimpan tetap ada).", "Return to the title screen (your last save is kept).")},
		], "MENU", Vector2(80, 180))
		if c == null:
			break
		match c:
			"bag":
				await _bag_menu()
			"lang":
				Game.set_lang("en" if Game.lang == "id" else "id")
				Sfx.play("sfx_confirm")
				refresh_ui()
			"status":
				var lines := []
				for id in ["raka", "tara"]:
					var p: Dictionary = Game.party[id]
					lines.append([id, "normal", "Lv %d   HP %d/%d   ATK %d   EXP %d/%d" % [p.level, p.hp, p.max_hp, p.atk, p.exp, Game.exp_next(p.level)]])
				lines.append(["narator", "", Game.L("Parry: %d   Perfect: %d   Pertarungan: %d   Waktu main: %d menit", "Parry: %d   Perfect: %d   Battles: %d   Play time: %d min") % [Game.stats.parry, Game.stats.perfect, Game.stats.battles, int(Game.play_time / 60)]])
				menu.close()
				await dialog.play(lines)
			"save":
				Game.pos = player.position
				Game.area = area_id
				Game.save_game()
				Sfx.play("sfx_star")
				menu.say(Game.L("Tersimpan!", "Saved!"))
				await get_tree().create_timer(0.8).timeout
			"title":
				menu.close()
				event.emit("title", {})
				return
	menu.close()
	busy = false
	refresh_ui()


func _bag_menu() -> void:
	while true:
		var opts := []
		for iid in Game.bag:
			var it: Dictionary = Game.ITEMS[iid]
			opts.append({"id": iid, "label": Game.T(it.name), "right": "x%d" % Game.bag[iid], "icon": it.icon, "desc": Game.T(it.desc),
				"enabled": it.has("hp") or it.get("cure", false)})
		if opts.is_empty():
			return
		var iid2 = await menu.open(opts, Game.L("TAS", "BAG"), Vector2(80, 180))
		if iid2 == null:
			return
		var who = await menu.open([
			{"id": "raka", "label": "Raka  %d/%d" % [Game.party.raka.hp, Game.party.raka.max_hp], "icon": "res://assets/sprites/face_raka_datar.png", "desc": ""},
			{"id": "tara", "label": "Tara  %d/%d" % [Game.party.tara.hp, Game.party.tara.max_hp], "icon": "res://assets/sprites/face_tara_skeptis.png", "desc": ""},
		], Game.L("UNTUK SIAPA?", "FOR WHOM?"), Vector2(80, 180))
		if who == null:
			continue
		var it2: Dictionary = Game.ITEMS[iid2]
		var p: Dictionary = Game.party[who]
		p.hp = mini(p.max_hp, p.hp + int(it2.get("hp", 10)))
		Game.use_item(iid2)
		Sfx.play("sfx_heal")
		refresh_ui()


# ------------------------------------------------------------------ autoplay (tes)

func _auto_dir(delta: float) -> Vector2:
	_auto_t += delta
	var goal := Vector2.INF
	var best := 1e9
	for r in roamers:
		if is_instance_valid(r):
			var d: float = r.position.distance_to(player.position)
			if d < best:
				best = d
				goal = r.position
	if goal == Vector2.INF:
		for m in marks:
			if m.kind == ("gate" if Game.cards() >= 3 and A.has("gate") else "station"):
				goal = m.pos
	if goal == Vector2.INF:
		return Vector2.ZERO
	var d2 := goal - player.position
	if d2.length() < 90:
		var n = _nearest()
		if n != null and _auto_t > 0.5:
			_auto_t = 0.0
			_interact(n)
		return Vector2.ZERO
	return d2.normalized()


## Pekerja dirasuki yang berkeliaran.
class Roamer extends Node2D:
	var def: Dictionary
	var world: Node
	var sprite: Sprite2D
	var home := Vector2.ZERO
	var goal := Vector2.ZERO
	var t := 0.0
	var aura: CPUParticles2D

	func setup() -> void:
		position = def.pos
		home = position
		goal = position
		var boss: bool = def.get("boss", false)
		var sh := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 20:
			var a := TAU * i / 20.0
			pts.append(Vector2(cos(a) * 50, sin(a) * 12))
		sh.polygon = pts
		sh.color = Color(0, 0, 0, 0.35)
		add_child(sh)
		aura = Fx.burst(self, Vector2(0, -80), "glow", 10, 0.3, false)
		aura.one_shot = false
		aura.explosiveness = 0.0
		aura.position = Vector2(0, -80)
		aura.color = Color(0.9, 0.1, 0.4, 0.55)
		sprite = Sprite2D.new()
		sprite.texture = load(def.sprite)
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		var h := 230.0 if boss else 175.0
		sprite.scale = Vector2.ONE * (h / sprite.texture.get_height())
		if boss:
			sprite.self_modulate = Color(1.0, 0.8, 0.9)
			var tag := Fx.label("BOS", 26, Game.PINK, 8)
			tag.size = Vector2(100, 34)
			tag.position = Vector2(-50, -h - 44)
			add_child(tag)
		add_child(sprite)

	func _process(delta: float) -> void:
		t += delta
		sprite.skew = sin(t * 3.0) * 0.06
		if def.get("boss", false) or world.busy:
			return
		var pp: Vector2 = world.player.position
		var fl: Array = world.A.floor
		if pp.distance_to(position) < 240 and world._grace <= 0:
			goal = pp
			position += (goal - position).normalized() * 95.0 * delta
		else:
			if position.distance_to(goal) < 6 or fmod(t, 2.5) < delta:
				goal = home + Vector2(randf_range(-130, 130), randf_range(-40, 40))
			position += (goal - position).normalized() * 45.0 * delta
		position.y = clampf(position.y, fl[0], fl[1])
		sprite.flip_h = pp.x > position.x

	func touching(p: Vector2) -> bool:
		if def.get("boss", false):
			return false
		return absf(p.x - position.x) < 55 and absf(p.y - position.y) < 32

	func flash_alert() -> void:
		var l := Fx.label("!", 70, Game.YELLOW, 14)
		l.size = Vector2(60, 80)
		l.position = Vector2(-30, -270)
		add_child(l)
		Sfx.play("sfx_blip", 0.0, 0.6)
