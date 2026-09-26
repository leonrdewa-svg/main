class_name Battle
extends Node2D
## Arena pertarungan turn-based ala Paper Mario.
## Party (Tara, Raka) bergiliran memilih aksi -> musuh bergiliran menyerang.

signal finished(result: String)
signal _nav(kind: String, pos: Vector2)

const STAGES := {
	1: {"bg": "res://assets/bg/dukuh_atas.jpg", "music": "bgm_battle",
		"title": "BABAK 1", "sub": "Stasiun MRT Dukuh Atas  ·  18.47",
		"enemies": [["deadline", Vector2(900, 632)], ["revisi", Vector2(1100, 626)]]},
	2: {"bg": "res://assets/bg/blok_m.jpg", "music": "bgm_boss",
		"title": "BABAK 2", "sub": "Blok M  ·  21.15",
		"enemies": [["target", Vector2(885, 636)], ["lembur", Vector2(1105, 630)]]},
}
const HERO_POS := {"raka": Vector2(215, 628), "tara": Vector2(400, 640)}
const MENU_POS := Vector2(505, 300)

var stage_no := 1
var world: Node2D
var units: Node2D
var cam: Camera2D
var stage: Stage
var ui: CanvasLayer
var cutin_layer: CanvasLayer
var hud: Hud
var menu: CommandMenu
var ac: ActionCmd
var heroes: Array = []
var enemies: Array = []
var round_no := 0
var _trauma := 0.0
var _nav_on := false
var _arrows: Array = []
var _aura := {}


func _ready() -> void:
	var st: Dictionary = STAGES[stage_no]
	world = Node2D.new()
	add_child(world)
	var bg := Sprite2D.new()
	bg.texture = load(st.bg)
	bg.position = Vector2(640, 360)
	var s := maxf(1280.0 / bg.texture.get_width(), 720.0 / bg.texture.get_height()) * 1.05
	bg.scale = Vector2(s, s)
	world.add_child(bg)
	world.add_child(_vignette())
	units = Node2D.new()
	units.y_sort_enabled = true
	world.add_child(units)
	ac = ActionCmd.new()
	world.add_child(ac)
	stage = Stage.new()
	stage.z_index = 20
	world.add_child(stage)
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	world.add_child(cam)
	cam.make_current()

	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	menu = CommandMenu.new()
	ui.add_child(menu)
	menu.desc_panel.position = Vector2(232, 648)
	menu.desc_panel.custom_minimum_size = Vector2(560, 56)
	menu.desc_panel.size = Vector2(560, 56)
	cutin_layer = CanvasLayer.new()
	cutin_layer.layer = 20
	add_child(cutin_layer)

	for id in ["raka", "tara"]:
		var b := Battler.new()
		units.add_child(b)
		b.setup(id, Game.HEROES[id], true)
		b.position = HERO_POS[id]
		b.home = b.position
		heroes.append(b)
	for pair in st.enemies:
		var e := Battler.new()
		units.add_child(e)
		e.setup(pair[0], Game.ENEMIES[pair[0]], false)
		e.position = pair[1]
		e.home = e.position
		enemies.append(e)


func _vignette() -> Sprite2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.05, 0.02, 0.08, 0.55))
	g.add_point(0.55, Color(0, 0, 0, 0.05))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.1, 1.1)
	gt.width = 256
	gt.height = 144
	var sp := Sprite2D.new()
	sp.texture = gt
	sp.position = Vector2(640, 360)
	sp.scale = Vector2(5, 5)
	return sp


func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 1.8)
		var k := _trauma * _trauma * 26.0
		cam.offset = Vector2(randf_range(-k, k), randf_range(-k, k))
	else:
		cam.offset = Vector2.ZERO


func shake(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _alive(list: Array) -> Array:
	return list.filter(func(b): return b.alive)


func _rand_hero() -> Battler:
	var l := _alive(heroes)
	return l[randi() % l.size()] if not l.is_empty() else null


# =====================================================================
# ALUR UTAMA
# =====================================================================

func run() -> String:
	var st: Dictionary = STAGES[stage_no]
	stage.caption = st.title
	stage.sub_caption = st.sub
	stage.openness = 0.0
	for h in heroes:
		h.position.x = -220
	for e in enemies:
		e.position.y = e.home.y - 760
	Sfx.music(st.music)
	await wait(1.0)
	Game.shot("tirai")
	await stage.open_curtain()
	# Hero melompat masuk
	for h in heroes:
		h.jump_to(h.home, 0.55, 150)
		await wait(0.15)
	await wait(0.4)
	# Musuh jatuh dari atas
	for e in enemies:
		var tw: Tween = e.create_tween()
		tw.tween_property(e, "position:y", e.home.y, 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_land_fx.bind(e))
		await wait(0.2)
	await wait(0.7)
	for h in heroes:
		h.idle_anim = h.alive
	if stage_no == 2:
		await _boss_intro()
	else:
		menu.say("Kolega kantor DIRASUKI LEMBUR! Kalahkan mereka!")
		await wait(1.3)
		menu.say("TIP: Saat musuh menyerang, tekan Z tepat sebelum kena untuk GUARD!")
		await wait(1.6)
	Game.shot("mulai")
	var result := await _loop()
	finished.emit(result)
	return result


func _land_fx(e: Battler) -> void:
	Sfx.play("sfx_land", 0.0, 0.8 if e.boss else 1.0)
	Fx.burst(world, e.global_position, "paper", 10, 0.6)
	shake(0.35 if e.boss else 0.15)


func _boss_intro() -> void:
	var boss: Battler = enemies[1]
	menu.say("LEMBUR: \"Kerja. Masih. Bisa. Lebih. Banyak.\"")
	await wait(0.6)
	Sfx.play("sfx_boss_roar")
	shake(0.9)
	boss.flash(Game.PINK, 0.8, 0.8)
	Fx.speed_lines(world, boss.center(), 0.9, Color(1, 0.2, 0.5, 0.7))
	Fx.burst(world, boss.center(), "glow", 30, 1.2)
	Fx.pop_text(world, boss.top() + Vector2(0, 40), "LEMBUR!", Game.PINK, 90, 1.0)
	Game.shot("boss")
	await wait(1.8)


func _loop() -> String:
	while true:
		round_no += 1
		Game.stats.turns += 1
		# --- giliran party
		for h in heroes:
			if not h.alive or _alive(enemies).is_empty():
				continue
			h.defending = false
			h.refresh_status_icons()
			var act: Dictionary = await _choose(h)
			await _do_hero_action(h, act)
			await _cleanup_dead()
		if _alive(enemies).is_empty():
			return await _victory()
		# --- giliran musuh
		hud.set_active("")
		for e in enemies:
			if not e.alive or _alive(heroes).is_empty():
				continue
			await _enemy_turn(e)
			await _cleanup_dead()
			await wait(0.2)
		if _alive(heroes).is_empty():
			return await _defeat()
		_end_round()
	return "lose"


func _end_round() -> void:
	for h in heroes:
		if h.atk_down > 0:
			h.atk_down -= 1
		if h.guard_up > 0:
			h.guard_up -= 1
		h.refresh_status_icons()


func _cleanup_dead() -> void:
	for e in enemies:
		if e.alive and e.hp <= 0:
			if _aura.has(e):
				_aura[e].queue_free()
				_aura.erase(e)
			await e.knock_out()


# =====================================================================
# PILIH AKSI
# =====================================================================

func _choose(h: Battler) -> Dictionary:
	hud.set_active(h.id)
	var d: Dictionary = h.data
	var spot := _turn_marker(h)
	while true:
		var opts := [
			{"id": "attack", "label": "Serang", "icon": d.weapon, "desc": "%s: %s" % [d.attack_name, d.attack_desc]},
			{"id": "skill", "label": "Jurus", "icon": "res://assets/ui/icon_star.png", "enabled": Game.sp >= _min_cost(d),
				"desc": "Jurus spesial. Pakai Semangat (SP)." if Game.sp >= _min_cost(d) else "Semangat (SP) tidak cukup. Coba Bertahan atau Es Teh Manis."},
			{"id": "item", "label": "Item", "icon": "res://assets/sprites/item_tas.png", "enabled": Game.bag_total() > 0,
				"desc": "Pakai barang dari tas kerja (%d barang)." % Game.bag_total()},
			{"id": "defend", "label": "Bertahan", "icon": "res://assets/ui/icon_shield.png", "desc": "Damage -1 sampai giliranmu lagi. +1 SP."},
		]
		var c = await menu.open(opts, "GILIRAN %s" % String(d.name).to_upper(), MENU_POS, false)
		match c:
			"attack":
				var t = await _pick_target("enemy")
				if t == null:
					continue
				spot.queue_free()
				return {"kind": "attack", "target": t}
			"skill":
				var sopts := []
				for sk in d.skills:
					sopts.append({"id": sk.id, "label": sk.name, "right": "%d SP" % sk.cost, "icon": "res://assets/ui/icon_sp.png",
						"desc": sk.desc, "enabled": Game.sp >= sk.cost})
				var sid = await menu.open(sopts, "JURUS  (SP %d)" % Game.sp, MENU_POS)
				if sid == null:
					continue
				var skill: Dictionary = {}
				for sk in d.skills:
					if sk.id == sid:
						skill = sk
				var t = await _pick_target(skill.target)
				if t == null:
					continue
				spot.queue_free()
				return {"kind": "skill", "skill": skill, "target": t}
			"item":
				var iopts := []
				for iid in Game.ITEMS:
					if Game.bag[iid] > 0:
						var it: Dictionary = Game.ITEMS[iid]
						iopts.append({"id": iid, "label": it.name, "right": "x%d" % Game.bag[iid], "icon": it.icon, "desc": it.desc})
				var iid2 = await menu.open(iopts, "TAS KERJA", MENU_POS)
				if iid2 == null:
					continue
				var t = await _pick_target(Game.ITEMS[iid2].target)
				if t == null:
					continue
				spot.queue_free()
				return {"kind": "item", "item": iid2, "target": t}
			"defend":
				spot.queue_free()
				return {"kind": "defend"}
	return {}


func _min_cost(d: Dictionary) -> int:
	var m := 99
	for sk in d.skills:
		m = mini(m, sk.cost)
	return m


## Penanda giliran: lingkaran sorot berdenyut di kaki hero.
func _turn_marker(h: Battler) -> Node2D:
	var n := Sprite2D.new()
	n.texture = Fx.GLOW_TEX
	n.modulate = Color(1, 0.9, 0.4, 0.7)
	n.scale = Vector2(2.2, 0.5)
	n.position = h.global_position
	n.z_index = -1
	world.add_child(n)
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "modulate:a", 0.35, 0.5)
	tw.tween_property(n, "modulate:a", 0.8, 0.5)
	Sfx.play("sfx_blip", -4.0, 1.4)
	h.paper_flip()
	return n


func _pick_target(kind: String) -> Variant:
	if kind == "none" or kind == "party":
		return kind
	var list: Array = heroes.duplicate() if kind == "ally" else _alive(enemies)
	var multi := kind == "all_enemies"
	var idx := 0
	if kind == "ally":
		var best := 2.0
		for i in list.size():
			var r: float = float(list[i].hp) / list[i].max_hp
			if r < best:
				best = r
				idx = i
	_nav_on = true
	if Game.autoplay:
		_auto_nav()
	var result: Variant = null
	while true:
		_point_at(list if multi else [list[idx]])
		if multi:
			menu.say("Target: SEMUA MUSUH.  [Z] pilih   [X] batal")
		else:
			var b: Battler = list[idx]
			if b.is_hero:
				menu.say("%s  —  HP %d/%d   [Z] pilih  [X] batal" % [b.display_name, b.hp, b.max_hp])
			else:
				menu.say("%s  HP %d/%d  —  \"%s\"" % [b.display_name, b.hp, b.max_hp, b.data.quote])
		var r: Array = await _nav
		var k: String = r[0]
		if k == "left" or k == "up":
			idx = (idx - 1 + list.size()) % list.size()
			Sfx.play("sfx_select", -6.0)
		elif k == "right" or k == "down":
			idx = (idx + 1) % list.size()
			Sfx.play("sfx_select", -6.0)
		elif k == "act":
			result = "all" if multi else list[idx]
			break
		elif k == "back":
			Sfx.play("sfx_cancel", -3.0)
			break
		elif k == "click":
			var hit := _battler_at(r[1], list)
			if hit != null:
				if multi or hit == list[idx]:
					result = "all" if multi else hit
					break
				idx = list.find(hit)
				Sfx.play("sfx_select", -6.0)
	_nav_on = false
	_clear_arrows()
	if result != null:
		Sfx.play("sfx_confirm", -3.0)
	return result


func _auto_nav() -> void:
	await wait(0.4)
	if _nav_on:
		_nav.emit("act", Vector2.ZERO)


func _battler_at(p: Vector2, list: Array) -> Battler:
	for b in list:
		var w: float = b.tex_idle.get_width() * b.base_scale * 0.5
		var r := Rect2(b.global_position.x - w, b.global_position.y - b.height(), w * 2, b.height())
		if r.has_point(p):
			return b
	return null


func _unhandled_input(e: InputEvent) -> void:
	if not _nav_on:
		return
	var kind := ""
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_nav.emit("click", world.get_global_mouse_position())
			return
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			kind = "back"
	elif e.is_action_pressed("ui_left"):
		kind = "left"
	elif e.is_action_pressed("ui_right"):
		kind = "right"
	elif e.is_action_pressed("ui_up"):
		kind = "up"
	elif e.is_action_pressed("ui_down"):
		kind = "down"
	elif e.is_action_pressed("act"):
		kind = "act"
	elif e.is_action_pressed("back"):
		kind = "back"
	if kind != "":
		get_viewport().set_input_as_handled()
		_nav.emit(kind, Vector2.ZERO)


class Arrow extends Node2D:
	var t := 0.0
	func _process(d: float) -> void:
		t += d
		position.y = sin(t * 8.0) * 8.0
		queue_redraw()
	func _draw() -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(-16, -28), Vector2(24, -28), Vector2(4, 0)]), Color(0, 0, 0, 0.45))
		draw_colored_polygon(PackedVector2Array([Vector2(-20, -32), Vector2(20, -32), Vector2(0, -4)]), Game.YELLOW)
		draw_polyline(PackedVector2Array([Vector2(-20, -32), Vector2(20, -32), Vector2(0, -4), Vector2(-20, -32)]), Game.INK, 4, true)


func _point_at(list: Array) -> void:
	_clear_arrows()
	for b in list:
		var holder := Node2D.new()
		holder.position = b.top() + Vector2(0, -34)
		holder.z_index = 80
		holder.add_child(Arrow.new())
		world.add_child(holder)
		_arrows.append(holder)
		b.flash(Color(1, 1, 0.7), 0.35, 0.45)


func _clear_arrows() -> void:
	for a in _arrows:
		a.queue_free()
	_arrows.clear()


# =====================================================================
# AKSI HERO
# =====================================================================

func _power(h: Battler) -> int:
	return maxi(1, h.atk - (1 if h.atk_down > 0 else 0))


func _do_hero_action(h: Battler, act: Dictionary) -> void:
	menu.close()
	hud.set_active("")
	match act.kind:
		"attack":
			if h.id == "tara":
				await _tara_attack(h, act.target)
			else:
				await _raka_attack(h, act.target)
		"skill":
			Game.set_sp(Game.sp - act.skill.cost)
			match act.skill.id:
				"badai":
					await _skill_badai(h)
				"semangat":
					await _skill_semangat(h, act.target)
				"tusukan":
					await _skill_tusukan(h, act.target)
				"pelindung":
					await _skill_pelindung(h)
		"item":
			await _use_item(h, act.item, act.target)
		"defend":
			await _defend(h)
	hud.refresh()


func _nice(h: Battler, text := "NICE!") -> void:
	Game.stats.nice += 1
	Fx.pop_text(world, h.top() + Vector2(0, -40), text, Game.YELLOW, 64)
	Fx.burst(world, h.top(), "stars", 8, 0.6)
	Sfx.play("sfx_nice")
	hud.mood(h.id, "happy")


func _hit_enemy(t: Battler, dmg: int, big: bool, _by: Battler = null) -> void:
	dmg = maxi(1, dmg)
	t.take_damage(dmg)
	t.hurt(big or dmg >= 4)
	Fx.damage_star(world, t.center() + Vector2(46, -40), dmg)
	Fx.burst(world, t.center(), "paper", 12 + dmg * 2)
	Sfx.play("sfx_hit_big" if big else "sfx_hit", 0.0, 1.0, 0.08)
	shake(0.35 if big else 0.2)
	if big:
		Fx.ring(world, t.center(), Color.WHITE, 150)
	await wait(0.08)


func _tara_attack(h: Battler, t: Battler) -> void:
	await h.dash_to(t.global_position + Vector2(-165, 6), 0.32)
	h.paper_flip("attack")
	var ok := await ac.timing(t.center(), 0.75)
	Sfx.play("sfx_paper", 2.0, 1.5)
	_slash(t.center())
	await _hit_enemy(t, _power(h) + (1 if ok else 0), ok, h)
	if ok:
		_nice(h)
	await wait(0.35)
	await h.paper_flip("idle")
	await h.go_home()


func _slash(p: Vector2) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([p + Vector2(-90, -80), p + Vector2(0, -10), p + Vector2(90, 70)])
	l.width = 26
	l.default_color = Color.WHITE
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	var c := Curve.new()
	c.add_point(Vector2(0, 0.1))
	c.add_point(Vector2(0.5, 1))
	c.add_point(Vector2(1, 0.1))
	l.width_curve = c
	l.z_index = 55
	world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


func _raka_attack(h: Battler, t: Battler) -> void:
	await h.dash_to(t.global_position + Vector2(-200, 6), 0.3)
	var land := Vector2(t.global_position.x, t.top().y + 24)
	h.jump_to(land, 0.55, 200)
	var ok := await ac.timing(land + Vector2(0, -20), 0.61)
	await _hit_enemy(t, _power(h), false, h)
	Sfx.play("sfx_land", -2.0, 1.3)
	var hits := 1
	while ok and t.hp > 0 and hits < 3:
		hits += 1
		_nice(h, "NICE!" if hits == 2 else "GREAT!")
		h.jump_to(land, 0.5, 150)
		var next_ok := false
		if hits < 3:
			next_ok = await ac.timing(land + Vector2(0, -20), 0.56)
		else:
			await wait(0.56)
		await _hit_enemy(t, _power(h) if hits == 2 else 1, true, h)
		ok = next_ok
	await h.jump_to(h.home, 0.55, 170)
	h.idle_anim = true


# ---------------- jurus

func _skill_badai(h: Battler) -> void:
	await Fx.cut_in(cutin_layer, h.tex_attack, "BADAI KERTAS!", Game.TEAL)
	await h.dash_to(Vector2(600, h.home.y), 0.3)
	h.paper_flip("attack")
	var swirl := Fx.burst(world, h.center(), "paper", 40, 0.5, false)
	swirl.one_shot = false
	swirl.explosiveness = 0.0
	swirl.gravity = Vector2(0, -200)
	var f := await ac.mash(Vector2(h.global_position.x, h.top().y - 70), 2.2)
	swirl.emitting = false
	get_tree().create_timer(1.5).timeout.connect(swirl.queue_free)
	var dmg := 1 + int(round(f * 3.0))
	if f >= 0.8:
		_nice(h, "GREAT!" if f >= 0.95 else "NICE!")
	Fx.speed_lines(world, h.center(), 0.6)
	Sfx.play("sfx_paper", 4.0, 0.8)
	for e in _alive(enemies):
		_paper_stream(h.center(), e.center())
		await wait(0.18)
		await _hit_enemy(e, dmg, f >= 0.8, h)
	await wait(0.4)
	await h.paper_flip("idle")
	await h.go_home()


func _paper_stream(from: Vector2, to: Vector2) -> void:
	var p := Fx.burst(world, from, "paper", 26, 1.0)
	var d := to - from
	p.direction = d.normalized()
	p.spread = 10
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 1200
	p.initial_velocity_max = 1500
	p.lifetime = d.length() / 1300.0
	p.explosiveness = 0.6
	p.damping_min = 0
	p.damping_max = 0


func _skill_semangat(h: Battler, t: Battler) -> void:
	h.paper_flip("attack")
	Fx.burst(world, h.center(), "stars", 10, 0.5)
	var ok := await ac.timing(t.center(), 0.8)
	await _heal_unit(t, 6 + (3 if ok else 0))
	if ok:
		_nice(h)
	await wait(0.3)
	await h.paper_flip("idle")


func _skill_tusukan(h: Battler, t: Battler) -> void:
	await Fx.cut_in(cutin_layer, h.tex_attack, "TUSUKAN PAYUNG!", Game.ORANGE)
	await h.dash_to(t.global_position + Vector2(-280, 4), 0.3)
	h.paper_flip("attack")
	var q := await ac.hold(Vector2(h.global_position.x + 40, h.top().y - 60), 1.1)
	h.flash(Color("ffb060"), 0.2)
	Fx.speed_lines(world, t.center(), 0.45, Color(1, 0.85, 0.6, 0.9))
	var tw := h.create_tween()
	tw.tween_property(h, "global_position", t.global_position + Vector2(-110, 4), 0.09).set_trans(Tween.TRANS_EXPO)
	await tw.finished
	var dmg := 2 + int(round(q * 5.0))
	if q >= 1.0:
		_nice(h, "SEMPURNA!")
	elif q <= 0.2:
		Fx.pop_text(world, h.top() + Vector2(0, -40), "KELAMAAN!", Color("ff6a6a"), 50)
	await _hit_enemy(t, dmg, q >= 1.0, h)
	await wait(0.4)
	await h.paper_flip("idle")
	await h.go_home()


func _skill_pelindung(h: Battler) -> void:
	h.paper_flip("attack")
	var ok := await ac.timing(h.center(), 0.8)
	var turns := 2 if ok else 1
	if ok:
		_nice(h)
	Sfx.play("sfx_guard")
	Sfx.play("sfx_buff", -4.0)
	for x in _alive(heroes):
		x.guard_up = turns
		x.refresh_status_icons()
		Fx.ring(world, x.center(), Color("7dd8ff"), 170, 0.5)
		x.flash(Color("7dd8ff"), 0.4, 0.6)
	menu.say("Payung Pelindung! Damage -2 selama %d giliran." % turns)
	await wait(0.9)
	await h.paper_flip("idle")


func _defend(h: Battler) -> void:
	h.defending = true
	Game.set_sp(Game.sp + 1)
	Sfx.play("sfx_guard")
	Fx.ring(world, h.center(), Color("7dd8ff"), 150, 0.4)
	Fx.pop_text(world, h.top() + Vector2(0, -30), "JAGA!", Color("7dd8ff"), 50, 0.6)
	h.refresh_status_icons()
	await wait(0.8)


func _heal_unit(t: Battler, amt: int) -> void:
	t.heal(amt)
	Fx.damage_star(world, t.center() + Vector2(-50, -50), amt, true)
	Fx.burst(world, t.center(), "heal", 18)
	Fx.ring(world, t.center(), Color("8ff0a0"), 140)
	t.flash(Color("c8ffc0"), 0.5, 0.6)
	Sfx.play("sfx_heal")
	if t.is_hero:
		hud.mood(t.id, "happy")
	hud.refresh()
	await wait(0.5)


func _use_item(h: Battler, id: String, target: Variant) -> void:
	Game.bag[id] -= 1
	var it: Dictionary = Game.ITEMS[id]
	var icon := Sprite2D.new()
	icon.texture = load(it.icon)
	icon.scale = Vector2.ONE * (84.0 / icon.texture.get_width())
	icon.position = h.top() + Vector2(0, -50)
	icon.z_index = 60
	world.add_child(icon)
	var sc := icon.scale
	icon.scale = Vector2.ZERO
	var tw := icon.create_tween()
	tw.tween_property(icon, "scale", sc * 1.3, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "scale", sc, 0.1)
	Sfx.play("sfx_star")
	Fx.burst(world, icon.position, "stars", 8, 0.4)
	menu.say("%s pakai %s!" % [h.display_name, it.name])
	await wait(0.7)
	icon.queue_free()
	match id:
		"kopi":
			await _heal_unit(target, 10)
		"esteh":
			Game.set_sp(Game.sp + 5)
			Fx.pop_text(world, h.top() + Vector2(0, -30), "+5 SP", Color("ffa23a"), 56)
			Fx.burst(world, h.center(), "heal", 16)
			Sfx.play("sfx_heal")
			await wait(0.6)
		"nasgor":
			for x in heroes:
				await _heal_unit(x, 8)
		"kartu":
			await _train(h)
	menu.close()


func _train(h: Battler) -> void:
	menu.say("TAP! Kereta MRT lewat!")
	Sfx.play("sfx_train", 2.0)
	var tr := Fx.Train.new()
	var x0 := -1250.0
	var x1 := 1500.0
	var dur := 1.3
	tr.position = Vector2(x0, 694)
	tr.z_index = 35
	world.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "position:x", x1, dur)
	shake(0.4)
	var speed := (x1 - x0) / dur
	var nose := 3 * 360.0 + 54.0
	var elapsed := 0.0
	var list := _alive(enemies)
	list.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for e in list:
		var at: float = (e.global_position.x - (x0 + nose)) / speed
		if at > elapsed:
			await wait(at - elapsed)
			elapsed = at
		Fx.speed_lines(world, e.center(), 0.25)
		await _hit_enemy(e, 5, true, h)
		elapsed += 0.08
	await tw.finished
	tr.queue_free()


# =====================================================================
# GILIRAN MUSUH
# =====================================================================

func _epower(e: Battler) -> int:
	return e.atk + e.atk_up


func _announce(e: Battler, text: String) -> void:
	menu.say("%s: %s" % [e.display_name, text])
	e.flash(e.data.color, 0.45, 0.6)
	Sfx.play("sfx_blip", -4.0, 0.7)
	await wait(0.55)


func _enemy_turn(e: Battler) -> void:
	e.turn_count += 1
	var t := _rand_hero()
	if t == null:
		return
	match e.id:
		"deadline":
			if e.turn_count % 3 == 0:
				await _announce(e, "WAKTU HABIS! (serang 2x)")
				Sfx.play("sfx_clock")
				Fx.pop_text(world, e.top() + Vector2(0, 30), "TIK. TAK.", Color("f07a1f"), 54, 0.6)
				await wait(0.5)
				for i in 2:
					var tt := _rand_hero()
					if tt == null:
						break
					await _enemy_melee(e, tt, 2)
			else:
				await _announce(e, "Tusuk Jarum Jam")
				await _enemy_melee(e, t, _epower(e))
		"revisi":
			var hurt_ally: Battler = null
			for o in _alive(enemies):
				if o != e and o.hp < o.max_hp * 0.6:
					hurt_ally = o
			var clean := _alive(heroes).filter(func(x): return x.atk_down == 0)
			if hurt_ally != null and randf() < 0.6:
				await _announce(e, "\"Revisi lagi :)\" (pulihkan teman)")
				await e.windup(0.3)
				await _heal_unit(hurt_ally, 4)
			elif not clean.is_empty() and randf() < 0.45:
				await _announce(e, "Coret Semangat (ATK turun)")
				await _enemy_projectile(e, clean[randi() % clean.size()], 1, true)
			else:
				await _announce(e, "Coret Merah")
				await _enemy_projectile(e, t, _epower(e))
		"target":
			if e.atk_up < 2 and (e.turn_count == 1 or randf() < 0.35):
				await _announce(e, "ANGKA HARUS NAIK! (ATK naik)")
				e.atk_up += 1
				Sfx.play("sfx_buff")
				e.flash(Color("9be02a"), 0.5, 0.6)
				Fx.pop_text(world, e.top() + Vector2(0, 20), "LEBIH TINGGI!", Color("9be02a"), 52)
				Fx.ring(world, e.center(), Color("9be02a"), 170, 0.45)
				e.refresh_status_icons()
				await wait(0.8)
			else:
				await _announce(e, "Gigit Kalkulator")
				await _enemy_melee(e, t, _epower(e), "sfx_bite")
		"lembur":
			if e.charging:
				e.charging = false
				if _aura.has(e):
					_aura[e].queue_free()
					_aura.erase(e)
				await _announce(e, "HARI INI. BESOK. SETIAP HARI.")
				Fx.speed_lines(world, e.center(), 0.7, Color(1, 0.2, 0.5, 0.8))
				await _enemy_melee(e, t, 7, "sfx_hit_big")
			elif e.turn_count % 3 == 2:
				e.charging = true
				await _announce(e, "Shift Tambahan...")
				Sfx.play("sfx_charge")
				var aura := Fx.burst(world, e.center(), "glow", 24, 0.6, false)
				aura.one_shot = false
				aura.explosiveness = 0.0
				_aura[e] = aura
				shake(0.3)
				menu.say("LEMBUR mengumpulkan tenaga! Giliran depan serangan BESAR. Siap-siap GUARD!")
				await wait(1.4)
			elif randf() < 0.55:
				await _announce(e, "Struk Tanpa Akhir (serang semua)")
				await _receipt_rain(e, 3)
			else:
				await _announce(e, "Tinju Lembur")
				await _enemy_melee(e, t, _epower(e))


func _enemy_melee(e: Battler, t: Battler, dmg: int, snd := "sfx_hit") -> void:
	await e.dash_to(t.global_position + Vector2(190 if not e.boss else 230, -2), 0.35)
	ac.guard_begin(t.top() + Vector2(0, -30))
	await e.windup(0.32)
	await e.lunge(t.global_position, 70, 0.1)
	var g := ac.guard_result()
	await _hit_hero(t, dmg, g, snd)
	await wait(0.25)
	await e.jump_to(e.home, 0.4, 90, false)
	e.idle_anim = true


func _enemy_projectile(e: Battler, t: Battler, dmg: int, debuff := false) -> void:
	await e.windup(0.28)
	Sfx.play("sfx_paper", 0.0, 1.8)
	ac.guard_begin(t.top() + Vector2(0, -30))
	var pen := Node2D.new()
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-34, -6), Vector2(22, -6), Vector2(36, 0), Vector2(22, 6), Vector2(-34, 6)])
	body.color = Color("d8243a")
	pen.add_child(body)
	var outline := Line2D.new()
	outline.points = body.polygon + PackedVector2Array([body.polygon[0]])
	outline.width = 3
	outline.default_color = Game.INK
	pen.add_child(outline)
	pen.position = e.center()
	pen.z_index = 50
	world.add_child(pen)
	var tw := pen.create_tween()
	tw.tween_property(pen, "position", t.center(), 0.5).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(pen, "rotation", -TAU * 2, 0.5)
	await tw.finished
	pen.queue_free()
	var g := ac.guard_result()
	await _hit_hero(t, dmg, g)
	if debuff:
		if not g:
			t.atk_down = 2
			t.refresh_status_icons()
			Sfx.play("sfx_debuff")
			Fx.pop_text(world, t.top() + Vector2(0, -70), "ATK -1", Color("b27ae8"), 48)
		else:
			Fx.pop_text(world, t.top() + Vector2(0, -70), "DITANGKIS!", Color("7dd8ff"), 44)
	await wait(0.3)


func _receipt_rain(e: Battler, dmg: int) -> void:
	await e.windup(0.4)
	Sfx.play("sfx_paper", 3.0, 0.7)
	shake(0.25)
	for t in _alive(heroes):
		ac.guard_begin(t.top() + Vector2(0, -30))
		var p := Fx.burst(world, t.top() + Vector2(0, -260), "receipts", 16, 0.25)
		p.gravity = Vector2(0, 1400)
		p.direction = Vector2(0, 1)
		p.spread = 20
		await wait(0.5)
		var g := ac.guard_result()
		await _hit_hero(t, dmg, g)
		await wait(0.15)


func _hit_hero(t: Battler, dmg: int, guarded: bool, snd := "sfx_hit") -> void:
	var d := dmg
	if guarded:
		d -= 1
	if t.defending:
		d -= 1
	if t.guard_up > 0:
		d -= 2
	d = maxi(0, d)
	if guarded:
		Game.stats.guard += 1
		Fx.pop_text(world, t.top() + Vector2(0, -60), "GUARD!", Color("7dd8ff"), 58, 0.6)
		Fx.ring(world, t.center(), Color("7dd8ff"), 150)
		Sfx.play("sfx_guard")
	Fx.damage_star(world, t.center() + Vector2(-50, -40), d)
	if d > 0:
		t.take_damage(d)
		t.hurt(d >= 4)
		Sfx.play(snd, 0.0, 1.0, 0.08)
		Fx.burst(world, t.center(), "ink", 10 + d * 2)
		shake(0.22 + d * 0.04)
		hud.shake_card(t.id)
		hud.mood(t.id, "hurt")
	hud.refresh()
	if t.hp <= 0 and t.alive:
		t.knock_out()
		Fx.pop_text(world, t.top() + Vector2(0, 40), "TUMBANG!", Color("ff6a6a"), 50)
		hud.refresh()
	await wait(0.1)


# =====================================================================
# MENANG / KALAH
# =====================================================================

func _victory() -> String:
	menu.close()
	hud.set_active("")
	Sfx.stop_music(0.2)
	Sfx.play("jingle_victory", 2.0)
	var l := Fx.label("MENANG!", 130, Game.YELLOW, 22)
	l.size = Vector2(1280, 200)
	l.position = Vector2(0, 170)
	l.pivot_offset = Vector2(640, 100)
	l.rotation = deg_to_rad(-5)
	l.scale = Vector2.ZERO
	ui.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		Fx.burst(world, Vector2(320 + i * 320, 140), "confetti", 40, 1.0)
	for h in _alive(heroes):
		hud.mood(h.id, "happy", 3.0)
		h.jump_to(h.home, 0.4, 90)
	await wait(0.5)
	for h in _alive(heroes):
		h.jump_to(h.home, 0.4, 120)
	Game.shot("menang")
	await wait(2.2)
	stage.caption = ""
	await stage.close_curtain()
	return "win"


func _defeat() -> String:
	menu.close()
	Sfx.stop_music(0.3)
	Sfx.play("jingle_gameover")
	var l := Fx.label("SEMUA TUMBANG...", 90, Color("ff6a6a"), 18)
	l.size = Vector2(1280, 160)
	l.position = Vector2(0, 220)
	ui.add_child(l)
	Game.shot("kalah")
	await wait(2.4)
	stage.caption = "DIRASUKI LEMBUR..."
	stage.sub_caption = ""
	l.queue_free()
	await stage.close_curtain()
	await wait(1.0)
	return "lose"
