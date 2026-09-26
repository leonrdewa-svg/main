class_name Battle
extends Node2D
## Pertarungan turn-based reaktif (gaya Expedition 33):
##  - urutan giliran berdasarkan SPD (timeline di atas)
##  - serangan = combo pukulan/tendangan dengan QTE urutan tombol
##  - saat musuh menyerang: PARRY (Z, sempit) / DODGE (X, lebar);
##    parry semua hit -> COUNTER
##  - AP untuk jurus, meter SEMANGAT untuk Pamungkas duo

signal finished(result: String)
signal _nav(kind: String, pos: Vector2)

const HERO_POS := {"raka": Vector2(250, 628), "tara": Vector2(430, 640)}
const MENU_POS := Vector2(540, 250)
const KINDS := ["tap", "tap", "hold", "mash"]

var bg_path := "res://assets/bg/dukuh_atas.jpg"
var group: Array = ["deadline"]
var music := "bgm_battle"
var first_strike := ""   # "player" / "enemy" / ""
var title := ""

var world: Node2D
var units: Node2D
var cam: Camera2D
var ui: CanvasLayer
var cutin_layer: CanvasLayer
var hud: BattleHud
var menu: CommandMenu
var qte: Qte
var heroes: Array = []
var enemies: Array = []
var ap := {}
var meter := 0.0
var atk_buff := 0
var round_no := 0
var _trauma := 0.0
var _nav_on := false
var _arrows: Array = []
var _phase2_done := false


func _ready() -> void:
	world = Node2D.new()
	add_child(world)
	var bg := LiveBg.new()
	world.add_child(bg)
	bg.setup(bg_path, "", 1.06)
	var dim := ColorRect.new()
	dim.size = Vector2(1400, 800)
	dim.position = Vector2(-60, -40)
	dim.color = Color(0.05, 0.02, 0.08, 0.12)
	world.add_child(dim)
	units = Node2D.new()
	units.y_sort_enabled = true
	world.add_child(units)
	qte = Qte.new()
	world.add_child(qte)
	cam = Camera2D.new()
	cam.position = Vector2(640, 360)
	world.add_child(cam)
	cam.make_current()

	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	for id in ["raka", "tara"]:
		var b := Battler.new()
		units.add_child(b)
		b.setup(id, Game.HEROES[id], true)
		b.atk = Game.party[id].atk
		b.position = HERO_POS[id]
		b.home = b.position
		var side: Texture2D = load(Game.HEROES[id].side)
		var at := AtlasTexture.new()
		at.atlas = side
		var fw := side.get_width() / 8.0
		at.region = Rect2(fw * 3, 0, fw, side.get_height())
		b.tex_kick = at
		heroes.append(b)
		ap[id] = 1
	var n := group.size()
	for i in n:
		var d := Game.enemy_data(group[i])
		var e := Battler.new()
		units.add_child(e)
		e.setup(d.kind, d, false)
		e.display_name = Game.T(d.name)
		e.boss = d.get("boss", false)
		if d.has("tint"):
			e.sprite.self_modulate = d.tint
		var x := 1050.0 if n == 1 else lerpf(880.0, 1130.0, float(i) / (n - 1))
		if n == 3:
			x = [850.0, 1010.0, 1170.0][i]
		e.position = Vector2(x, 630 + (i % 2) * 12)
		e.home = e.position
		enemies.append(e)

	hud = BattleHud.new()
	hud.battle = self
	ui.add_child(hud)
	menu = CommandMenu.new()
	ui.add_child(menu)
	menu.desc_panel.position = Vector2(232, 650)
	menu.desc_panel.custom_minimum_size = Vector2(620, 56)
	menu.desc_panel.size = Vector2(620, 56)
	if Game.touch_mode:
		var tc := TouchControls.new()
		tc.mode = "battle"
		add_child(tc)
	else:
		var pad := TouchPad.new()
		pad.qte = qte
		ui.add_child(pad)
	cutin_layer = CanvasLayer.new()
	cutin_layer.layer = 20
	add_child(cutin_layer)


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


func add_meter(v: float) -> void:
	meter = clampf(meter + v, 0.0, 100.0)
	hud.refresh()


func add_ap(id: String, v: int) -> void:
	ap[id] = clampi(ap[id] + v, 0, 9)
	hud.refresh()


# =====================================================================
# ALUR
# =====================================================================

func run() -> String:
	Sfx.music(music)
	for h in heroes:
		h.position.x -= 400
	for e in enemies:
		e.position.x += 500
	hud.refresh()
	# Masuk arena
	var tw := create_tween().set_parallel()
	for h in heroes:
		tw.tween_property(h, "position:x", h.home.x, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for e in enemies:
		tw.tween_property(e, "position:x", e.home.x, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("sfx_paper", 0.0, 0.8)
	await tw.finished
	for h in heroes:
		h.idle_anim = h.alive
	var banner := title if title != "" else Game.L("PERTARUNGAN!", "BATTLE!")
	Fx.pop_text(world, Vector2(640, 250), banner, Game.YELLOW, 84, 0.7)
	Voice.bark("raka", "start")
	await wait(0.9)
	if first_strike == "player":
		Fx.pop_text(world, Vector2(640, 330), Game.L("SERANGAN PERTAMA!", "FIRST STRIKE!"), Color("7dff8a"), 60, 0.6)
		Sfx.play("sfx_hit_big")
		for e in enemies:
			await _hit_enemy(e, int(e.max_hp * 0.15), true)
		await wait(0.5)
	elif first_strike == "enemy":
		Fx.pop_text(world, Vector2(640, 330), Game.L("DISERGAP!", "AMBUSHED!"), Color("ff6a6a"), 60, 0.6)
		await wait(0.7)
	if Game.stats.battles == 0:
		menu.say(Game.L("TIP: lingkaran menyusut ke hero = waktu serangan kena. Z pas di tengah = PARRY. X = DODGE.", "TIP: the ring shrinking onto your hero shows when the hit lands. Z at the center = PARRY. X = DODGE."))
		await wait(2.4)
	Game.shot("battle_mulai")
	var result := await _loop()
	finished.emit(result)
	return result


func _order() -> Array:
	var list := _alive(heroes) + _alive(enemies)
	list.sort_custom(func(a, b):
		var sa: int = Game.party[a.id].spd if a.is_hero else Game.ENEMIES[a.id].spd
		var sb: int = Game.party[b.id].spd if b.is_hero else Game.ENEMIES[b.id].spd
		if sa == sb:
			return a.is_hero
		return sa > sb)
	if round_no == 1 and first_strike == "enemy":
		list.sort_custom(func(a, b): return (not a.is_hero) and b.is_hero)
	return list


func _loop() -> String:
	while true:
		round_no += 1
		var order := _order()
		hud.set_order(order)
		for u in order:
			if not u.alive:
				continue
			if _alive(enemies).is_empty() or _alive(heroes).is_empty():
				break
			hud.set_current(u)
			if u.is_hero:
				await _hero_turn(u)
			else:
				await _enemy_turn(u)
			await _cleanup_dead()
			await _check_phase2()
			hud.pop_order()
		if _alive(enemies).is_empty():
			return await _victory()
		if _alive(heroes).is_empty():
			return await _defeat()
		if atk_buff > 0:
			atk_buff -= 1
		for h in heroes:
			if h.atk_down > 0:
				h.atk_down -= 1
			h.refresh_status_icons()
	return "lose"


func _cleanup_dead() -> void:
	for e in enemies:
		if e.alive and e.hp <= 0:
			await e.knock_out()


func _check_phase2() -> void:
	for e in enemies:
		var d := Game.enemy_data(group[enemies.find(e)])
		if e.alive and d.get("final", false) and not _phase2_done and e.hp <= e.max_hp / 2:
			_phase2_done = true
			e.charging = false
			Sfx.play("sfx_boss_roar")
			shake(0.9)
			e.flash(Game.PINK, 1.0, 0.9)
			e.sprite.self_modulate = Color(0.95, 0.45, 0.75)
			Fx.speed_lines(world, e.center(), 1.0, Color(1, 0.2, 0.5, 0.7))
			Fx.burst(world, e.center(), "glow", 40, 1.3)
			await Fx.cut_in(cutin_layer, e.tex_idle, Game.L("FASE 2: SETIAP HARI. SELAMANYA.", "PHASE 2: EVERY DAY. FOREVER."), Game.PINK, true)
			e.atk += 3
			e.set_meta("fast", true)


# =====================================================================
# GILIRAN HERO
# =====================================================================

func _hero_turn(h: Battler) -> void:
	h.defending = false
	h.refresh_status_icons()
	if h.get_meta("stun", false):
		h.set_meta("stun", false)
		return
	var spot := _turn_marker(h)
	var act := await _choose(h)
	spot.queue_free()
	menu.close()
	_clear_arrows()
	match act.kind:
		"attack":
			await _combo(h, act.target, 2, 1.0, false)
			add_ap(h.id, 1)
		"skill":
			add_ap(h.id, -act.skill.ap)
			await _skill(h, act.skill, act.target)
		"item":
			await _use_item(h, act.item, act.target)
		"focus":
			add_ap(h.id, 2)
			h.defending = true
			Sfx.play("sfx_buff")
			Fx.ring(world, h.center(), Color("ffd23f"), 160)
			Fx.pop_text(world, h.top() + Vector2(0, -30), Game.L("FOKUS +2 AP", "FOCUS +2 AP"), Game.YELLOW, 48, 0.6)
			h.refresh_status_icons()
			await wait(0.8)
		"ultimate":
			meter = 0
			hud.refresh()
			await _ultimate()
	hud.refresh()


func _choose(h: Battler) -> Dictionary:
	var d: Dictionary = h.data
	while true:
		var opts := [
			{"id": "attack", "label": Game.L("Serang", "Attack"), "icon": "res://assets/ui/icon_star.png",
				"desc": Game.L("Combo pukulan + tendangan. Ikuti perintah Z (tekan / tahan / tekan terus). +1 AP.", "Punch + kick combo. Follow the Z prompts (tap / hold / mash). +1 AP.")},
			{"id": "skill", "label": Game.L("Jurus", "Skills"), "icon": "res://assets/ui/icon_sp.png",
				"desc": Game.L("Jurus spesial pakai AP. AP kamu: %d", "Special moves cost AP. Your AP: %d") % ap[h.id]},
			{"id": "item", "label": "Item", "icon": "res://assets/sprites/item_tas.png", "enabled": Game.bag_total() > 0,
				"desc": Game.L("Pakai barang dari tas (%d barang).", "Use something from your bag (%d items).") % Game.bag_total()},
			{"id": "focus", "label": Game.L("Fokus", "Focus"), "icon": "res://assets/ui/icon_shield.png",
				"desc": Game.L("Tarik napas: +2 AP dan damage diterima -30% sampai giliranmu lagi.", "Breathe: +2 AP and take 30% less damage until your next turn.")},
		]
		if meter >= 100:
			opts.push_front({"id": "ultimate", "label": Game.L("PAMUNGKAS!", "ULTIMATE!"), "icon": "res://assets/ui/icon_star.png",
				"desc": Game.L("Serangan duo Raka + Tara ke semua musuh!", "Raka + Tara duo attack on all enemies!")})
		var c = await menu.open(opts, Game.L("GILIRAN %s  ·  AP %d", "%s'S TURN  ·  AP %d") % [String(d.name).to_upper(), ap[h.id]], MENU_POS, false)
		match c:
			"attack":
				var t = await _pick_target("enemy")
				if t != null:
					return {"kind": "attack", "target": t}
			"skill":
				var sopts := []
				for sk in d.skills:
					sopts.append({"id": sk.id, "label": Game.T(sk.name), "right": "%d AP" % sk.ap, "icon": "res://assets/ui/icon_sp.png",
						"desc": Game.T(sk.desc), "enabled": ap[h.id] >= sk.ap})
				var sid = await menu.open(sopts, Game.L("JURUS  (AP %d)", "SKILLS  (AP %d)") % ap[h.id], MENU_POS)
				if sid == null:
					continue
				var skill: Dictionary = {}
				for sk in d.skills:
					if sk.id == sid:
						skill = sk
				var t = await _pick_target(skill.target)
				if t != null:
					return {"kind": "skill", "skill": skill, "target": t}
			"item":
				var iopts := []
				for iid in Game.bag:
					var it: Dictionary = Game.ITEMS[iid]
					iopts.append({"id": iid, "label": Game.T(it.name), "right": "x%d" % Game.bag[iid], "icon": it.icon, "desc": Game.T(it.desc)})
				var iid2 = await menu.open(iopts, Game.L("TAS", "BAG"), MENU_POS)
				if iid2 == null:
					continue
				var t = await _pick_target(Game.ITEMS[iid2].target)
				if t != null:
					return {"kind": "item", "item": iid2, "target": t}
			"focus":
				return {"kind": "focus"}
			"ultimate":
				return {"kind": "ultimate"}
	return {}


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
	hud.mood(h.id, "focus", 0.8)
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
			menu.say(Game.L("Target: SEMUA MUSUH.   [Z] pilih   [X] batal", "Target: ALL ENEMIES.   [Z] select   [X] back"))
		else:
			var b: Battler = list[idx]
			if b.is_hero:
				menu.say(Game.L("%s  HP %d/%d   [Z] pilih  [X] batal", "%s  HP %d/%d   [Z] select  [X] back") % [b.display_name, b.hp, b.max_hp])
			else:
				menu.say("%s  HP %d/%d  —  \"%s\"" % [b.display_name, b.hp, b.max_hp, Game.T(b.data.quote)])
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
	_nav_on = false
	_clear_arrows()
	if result != null:
		Sfx.play("sfx_confirm", -3.0)
	return result


func _auto_nav() -> void:
	await wait(0.35)
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
		b.flash(Color(1, 1, 0.7), 0.35, 0.4)


func _clear_arrows() -> void:
	for a in _arrows:
		a.queue_free()
	_arrows.clear()


# =====================================================================
# SERANGAN HERO (combo QTE)
# =====================================================================

func _power(h: Battler) -> float:
	var p := float(h.atk)
	if atk_buff > 0:
		p *= 1.3
	if h.atk_down > 0:
		p *= 0.7
	return p


## Variasi QTE (semua pakai Z): tap / hold / mash. Hit pertama selalu tap.
func _rand_keys(n: int) -> Array:
	var ks := []
	for i in n:
		var k: String = KINDS[randi() % KINDS.size()]
		if i > 0 and ks[i - 1] != "tap" and k != "tap":
			k = "tap"
		ks.append(k)
	ks[0] = "tap"
	return ks


## Combo ke satu target: tiap tombol = satu pukulan/tendangan.
## Kembalikan jumlah PERFECT.
func _combo(h: Battler, t: Battler, n: int, mult: float, big_finish: bool) -> int:
	var dest := t.global_position + Vector2(-170, 6)
	await h.dash_to(dest, 0.28)
	var keys := _rand_keys(n)
	var perfects := 0
	for i in n:
		if not t.alive or t.hp <= 0:
			break
		var r := await qte.prompt(t.center() + Vector2(0, -150), keys[i], 0.62 if i == 0 else 0.5)
		if r != "miss":
			Voice.bark(h.id, "hit")
		var kick := i % 2 == 1
		h.set_pose("kick" if kick else "attack")
		var tw := h.create_tween()
		tw.tween_property(h, "global_position", dest + Vector2(36, -18 if kick else 0), 0.06)
		tw.tween_property(h, "global_position", dest, 0.12)
		if r == "miss":
			Fx.pop_text(world, t.top() + Vector2(0, -20), "MISS", Color("ff6a6a"), 44, 0.4)
			Sfx.play("sfx_miss", -4.0)
			await wait(0.2)
			break
		var q := 1.3 if r == "perfect" else 1.0
		if r == "perfect":
			perfects += 1
			Game.stats.perfect += 1
			add_meter(7)
		else:
			add_meter(3)
		var dmg := int(round(_power(h) * mult * q * randf_range(0.92, 1.08)))
		var last := i == n - 1
		_impact(t.center() + Vector2(-20, -10 if kick else -40), kick)
		await _hit_enemy(t, dmg, r == "perfect" or (last and big_finish), "PERFECT" if r == "perfect" else "")
	await wait(0.2)
	h.set_pose("idle")
	await h.go_home()
	return perfects


func _impact(p: Vector2, kick: bool) -> void:
	Fx.ring(world, p, Color.WHITE, 110 if kick else 90, 0.22)
	var l := Line2D.new()
	var a := -0.6 if kick else 0.2
	var dir := Vector2(cos(a), sin(a))
	l.points = PackedVector2Array([p - dir * 80, p + dir * 80])
	l.width = 22
	l.default_color = Color(1, 0.95, 0.7)
	var c := Curve.new()
	c.add_point(Vector2(0, 0.1))
	c.add_point(Vector2(0.5, 1))
	c.add_point(Vector2(1, 0.1))
	l.width_curve = c
	l.z_index = 55
	world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.2)
	tw.tween_callback(l.queue_free)
	Sfx.play("sfx_paper", -4.0, 1.6, 0.1)


func _hit_enemy(t: Battler, dmg: int, big: bool, tag := "") -> void:
	dmg = maxi(1, dmg)
	t.take_damage(dmg)
	t.hurt(big)
	Fx.damage_star(world, t.center() + Vector2(randf_range(20, 70), randf_range(-70, -20)), dmg)
	Fx.burst(world, t.center(), "paper", 10 + mini(dmg, 20))
	Sfx.play("sfx_hit_big" if big else "sfx_hit", 0.0, 1.0, 0.1)
	shake(0.32 if big else 0.16)
	if tag != "":
		Fx.pop_text(world, t.top() + Vector2(0, -10), tag, Color("7dff8a"), 40, 0.35)
	if big:
		Engine.time_scale = 0.35
		await get_tree().create_timer(0.05, true, false, true).timeout
		Engine.time_scale = 1.0
	await wait(0.05)


func _skill(h: Battler, sk: Dictionary, target: Variant) -> void:
	match sk.id:
		"tinju":
			Voice.bark(h.id, "skill")
			await Fx.cut_in(cutin_layer, h.tex_attack, Game.T(sk.name).to_upper() + "!", Game.ORANGE)
			var p := await _combo(h, target, sk.keys, sk.power, true)
			if p == sk.keys:
				Fx.pop_text(world, Vector2(640, 260), Game.L("COMBO SEMPURNA!", "PERFECT COMBO!"), Game.YELLOW, 70, 0.6)
				add_ap(h.id, 1)
		"sapuan":
			Voice.bark(h.id, "skill")
			await Fx.cut_in(cutin_layer, h.tex_attack, Game.T(sk.name).to_upper() + "!", Game.TEAL)
			var p := await _combo(h, target, sk.keys, sk.power, true)
			if p == sk.keys and target.alive:
				target.set_meta("stun", true)
				Fx.pop_text(world, target.top() + Vector2(0, -40), Game.L("PUSING!", "DIZZY!"), Color("ffd23f"), 56)
				Fx.burst(world, target.top(), "stars", 12, 0.5)
		"putar", "badai":
			var name := Game.T(sk.name).to_upper() + "!"
			Voice.bark(h.id, "skill")
			await Fx.cut_in(cutin_layer, h.tex_attack, name, h.data.color)
			await h.dash_to(Vector2(620, h.home.y), 0.3)
			var keys := _rand_keys(sk.keys)
			var total := 0.0
			for i in sk.keys:
				var r := await qte.prompt(Vector2(640, 300), keys[i], 0.55)
				h.set_pose("kick" if i % 2 == 1 else "attack")
				if r == "miss":
					Fx.pop_text(world, Vector2(640, 380), "MISS", Color("ff6a6a"), 44, 0.4)
					break
				total += 1.3 if r == "perfect" else 1.0
				if r == "perfect":
					add_meter(5)
				Fx.ring(world, h.center(), Color.WHITE, 200, 0.25)
				Sfx.play("sfx_paper", 0.0, 1.2 + i * 0.1)
			if total > 0:
				Fx.speed_lines(world, Vector2(900, 480), 0.5)
				for e in _alive(enemies):
					var dmg := int(round(_power(h) * sk.power * total))
					Fx.burst(world, e.center(), "paper" if sk.id == "badai" else "stars", 20)
					await _hit_enemy(e, dmg, true)
			h.set_pose("idle")
			await h.go_home()
		"semangat":
			var t: Battler = target
			h.set_pose("attack")
			var bonus := 0
			for k in _rand_keys(sk.keys):
				var r := await qte.prompt(t.center() + Vector2(0, -150), k, 0.6)
				if r != "miss":
					bonus += 1
			await _heal_unit(t, int(t.max_hp * (0.3 + 0.1 * bonus)))
			h.set_pose("idle")
		"teriak":
			h.set_pose("attack")
			atk_buff = 2
			Sfx.play("sfx_buff")
			shake(0.3)
			Fx.pop_text(world, h.top() + Vector2(0, -40), Game.L("JAM PULANG!!", "QUITTING TIME!!"), Game.ORANGE, 64)
			for x in _alive(heroes):
				Fx.ring(world, x.center(), Game.ORANGE, 170, 0.45)
				x.flash(Game.ORANGE, 0.4, 0.5)
			menu.say(Game.L("ATK party +30% selama 2 giliran!", "Party ATK +30% for 2 turns!"))
			await wait(1.0)
			h.set_pose("idle")


func _ultimate() -> void:
	var r: Battler = heroes[0]
	var t: Battler = heroes[1]
	Voice.bark("raka", "ult")
	await Fx.cut_in(cutin_layer, r.tex_attack, Game.L("PAMUNGKAS:", "ULTIMATE:"), Game.ORANGE)
	Voice.bark("tara", "ult")
	await Fx.cut_in(cutin_layer, t.tex_attack, Game.L("SHIFT TERAKHIR!", "LAST SHIFT!"), Game.TEAL, true)
	var total := 0.0
	for i in 6:
		var who: Battler = r if i % 2 == 0 else t
		if not who.alive:
			who = r if r.alive else t
		var res := await qte.prompt(Vector2(640, 280), KINDS[randi() % KINDS.size()], 0.5)
		if res == "miss":
			break
		total += 1.4 if res == "perfect" else 1.0
		who.set_pose("kick" if i % 2 == 1 else "attack")
		Fx.speed_lines(world, Vector2(900, 480), 0.2)
		Sfx.play("sfx_hit", 0.0, 1.0 + i * 0.08)
		shake(0.2)
	Fx.burst(world, Vector2(900, 450), "confetti", 60, 1.4)
	for e in _alive(enemies):
		var dmg := int(round((_power(r) + _power(t)) * 0.9 * total))
		await _hit_enemy(e, dmg, true, "PAMUNGKAS")
	for x in heroes:
		x.set_pose("idle")


func _heal_unit(t: Battler, amt: int) -> void:
	t.heal(amt)
	Fx.damage_star(world, t.center() + Vector2(-50, -50), amt, true)
	Fx.burst(world, t.center(), "heal", 18)
	Fx.ring(world, t.center(), Color("8ff0a0"), 140)
	t.flash(Color("c8ffc0"), 0.5, 0.6)
	Sfx.play("sfx_heal")
	hud.refresh()
	await wait(0.5)


func _use_item(h: Battler, id: String, target: Variant) -> void:
	Game.use_item(id)
	var it: Dictionary = Game.ITEMS[id]
	var icon := Sprite2D.new()
	icon.texture = load(it.icon)
	icon.scale = Vector2.ONE * (84.0 / icon.texture.get_width())
	icon.position = h.top() + Vector2(0, -50)
	icon.z_index = 60
	world.add_child(icon)
	Sfx.play("sfx_star")
	menu.say(Game.L("%s pakai %s!", "%s uses %s!") % [h.display_name, Game.T(it.name)])
	await wait(0.6)
	icon.queue_free()
	if it.has("dmg"):
		await _train(int(it.dmg))
		return
	var t: Battler = target
	if it.has("hp"):
		await _heal_unit(t, int(it.hp))
	if it.has("ap"):
		add_ap(t.id, int(it.ap))
		Fx.pop_text(world, t.top() + Vector2(0, -30), "+%d AP" % it.ap, Game.YELLOW, 50)
		Sfx.play("sfx_heal")
		await wait(0.5)
	if it.get("cure", false):
		t.atk_down = 0
		t.refresh_status_icons()
		await _heal_unit(t, 10)


func _train(dmg: int) -> void:
	menu.say(Game.L("TAP! Kereta MRT lewat!", "TAP! The MRT train rushes past!"))
	Sfx.play("sfx_train", 2.0)
	var tr := Fx.Train.new()
	tr.position = Vector2(-1250, 694)
	tr.z_index = 35
	world.add_child(tr)
	var tw := tr.create_tween()
	tw.tween_property(tr, "position:x", 1500.0, 1.3)
	shake(0.4)
	await wait(0.75)
	for e in _alive(enemies):
		await _hit_enemy(e, dmg, true)
	await tw.finished
	tr.queue_free()


# =====================================================================
# GILIRAN MUSUH (parry / dodge / counter)
# =====================================================================

func _enemy_turn(e: Battler) -> void:
	if e.get_meta("stun", false):
		e.set_meta("stun", false)
		Fx.pop_text(world, e.top(), Game.L("pusing...", "dizzy..."), Color("ffd23f"), 40, 0.5)
		await wait(0.7)
		return
	var moves: Array = e.data.moves
	var mv: Dictionary = moves[randi() % moves.size()]
	if e.boss and randf() < 0.4:
		mv = moves[moves.size() - 1]
	var fast: bool = e.get_meta("fast", false)
	menu.say("%s: %s" % [e.display_name, Game.T(mv.name)])
	Voice.bark("enemy", "attack")
	e.flash(e.data.color, 0.45, 0.6)
	Sfx.play("sfx_blip", -4.0, 0.7)
	var all_targets: bool = mv.get("all", false)
	var t := _rand_hero()
	if t == null:
		return
	var hits: Array = mv.hits
	var heavy: Array = mv.get("heavy", [])
	await wait(0.35)
	if not all_targets:
		await e.dash_to(t.global_position + Vector2(210 if not e.boss else 250, -2), 0.3)
	var parried := 0
	var landed := 0
	for i in hits.size():
		var tgt: Battler = t
		if all_targets:
			var al := _alive(heroes)
			if al.is_empty():
				break
			tgt = al[i % al.size()]
		if not tgt.alive:
			var al2 := _alive(heroes)
			if al2.is_empty():
				break
			tgt = al2[0]
		var hv: bool = heavy[i] if i < heavy.size() else false
		var delay: float = hits[i] * (0.8 if fast else 1.0)
		qte.defend_begin(tgt.top() + Vector2(0, -40), hv, delay)
		# antisipasi: musuh menarik ancang-ancang selama delay
		var s := Vector2.ONE * e.base_scale
		e.idle_anim = false
		var tw := e.create_tween()
		tw.tween_property(e.sprite, "scale", Vector2(s.x * 1.08, s.y * 0.9), delay * 0.85)
		tw.tween_property(e.sprite, "scale", Vector2(s.x * 0.92, s.y * 1.1), delay * 0.15)
		if hv:
			e.flash(Color(1, 0.2, 0.2), delay, 0.5)
		if all_targets:
			var p := Fx.burst(world, tgt.top() + Vector2(0, -240), "receipts", 6, 0.2)
			p.gravity = Vector2(0, 1600)
			p.direction = Vector2(0, 1)
		await wait(delay)
		var res := qte.defend_result(hv)
		e.sprite.scale = s
		var dmg := int(round(float(e.atk) * float(mv.power) * randf_range(0.9, 1.1)))
		await _resolve_hit(e, tgt, dmg, res)
		if res == "parry":
			parried += 1
		landed += 1
	qte.defend_end()
	e.idle_anim = true
	if parried > 0 and parried == landed and not all_targets and t.alive and e.alive:
		await _counter(t, e)
	await wait(0.2)
	if not all_targets and e.alive:
		await e.jump_to(e.home, 0.35, 70, false)
	e.idle_anim = e.alive


func _resolve_hit(e: Battler, t: Battler, dmg: int, res: String) -> void:
	match res:
		"parry":
			Game.stats.parry += 1
			Fx.pop_text(world, t.top() + Vector2(0, -70), "PARRY!", Game.YELLOW, 56, 0.35)
			Voice.bark(t.id, "parry")
			Fx.ring(world, t.center() + Vector2(40, -30), Game.YELLOW, 130, 0.25)
			Fx.burst(world, t.center() + Vector2(40, -30), "stars", 8, 0.6)
			Sfx.play("sfx_guard", 2.0, 1.2)
			Sfx.play("sfx_tick", 0.0, 1.8)
			e.hurt(false)
			t.set_pose("attack")
			get_tree().create_timer(0.25).timeout.connect(t.set_pose.bind("idle"))
			add_ap(t.id, 1)
			add_meter(10)
			shake(0.15)
		"dodge":
			Fx.pop_text(world, t.top() + Vector2(0, -70), "DODGE", Color("7dd8ff"), 46, 0.3)
			Voice.bark(t.id, "dodge")
			Sfx.play("sfx_jump", -4.0, 1.4)
			var tw := t.create_tween()
			tw.tween_property(t, "position:x", t.home.x - 70, 0.08)
			tw.tween_property(t, "position:x", t.home.x, 0.2)
			add_meter(3)
		_:
			var d := dmg
			if t.defending:
				d = int(d * 0.7)
			t.take_damage(d)
			t.hurt(d >= 12)
			Fx.damage_star(world, t.center() + Vector2(-50, -40), d)
			Fx.burst(world, t.center(), "ink", 10)
			Sfx.play("sfx_hit", 0.0, 0.9, 0.1)
			shake(0.2 + d * 0.01)
			hud.mood(t.id, "hurt")
			Voice.bark(t.id, "hurt")
			if e.id == "revisi" and randf() < 0.35 and t.atk_down == 0:
				t.atk_down = 2
				t.refresh_status_icons()
				Fx.pop_text(world, t.top() + Vector2(0, -100), Game.L("PANIK! ATK turun", "PANIC! ATK down"), Color("b27ae8"), 40)
				Sfx.play("sfx_debuff")
			if t.hp <= 0 and t.alive:
				t.knock_out()
				Fx.pop_text(world, t.top() + Vector2(0, 40), Game.L("TUMBANG!", "DOWN!"), Color("ff6a6a"), 50)
	hud.refresh()
	await wait(0.08)


func _counter(h: Battler, e: Battler) -> void:
	Fx.pop_text(world, Vector2(640, 250), "COUNTER!", Game.YELLOW, 90, 0.5)
	Voice.bark(h.id, "counter")
	Sfx.play("sfx_nice")
	Engine.time_scale = 0.4
	await get_tree().create_timer(0.25, true, false, true).timeout
	Engine.time_scale = 1.0
	h.set_pose("kick")
	var from := h.global_position
	var tw := h.create_tween()
	tw.tween_property(h, "global_position", e.global_position + Vector2(-150, 0), 0.1)
	await tw.finished
	_impact(e.center(), true)
	await _hit_enemy(e, int(_power(h) * 2.0), true, "COUNTER")
	var tw2 := h.create_tween()
	tw2.tween_property(h, "global_position", from, 0.2)
	await tw2.finished
	h.set_pose("idle")
	add_meter(10)


# =====================================================================
# MENANG / KALAH
# =====================================================================

func _victory() -> String:
	menu.close()
	Sfx.stop_music(0.2)
	Sfx.play("jingle_victory", 2.0)
	var exp := 0
	var cash := 0
	for g in group:
		var d := Game.enemy_data(g)
		exp += int(d.exp)
		cash += int(d.money)
	Game.money += cash
	Game.stats.battles += 1
	var ups := Game.gain_exp(exp)
	for h in heroes:
		if h.alive:
			Game.party[h.id].hp = maxi(Game.party[h.id].hp, h.hp)
		else:
			Game.party[h.id].hp = 1
	for i in 3:
		Fx.burst(world, Vector2(320 + i * 320, 140), "confetti", 40, 1.0)
	for h in _alive(heroes):
		h.jump_to(h.home, 0.4, 100)
	var panel := PanelContainer.new()
	panel.theme = Game.ui_theme
	panel.position = Vector2(390, 200)
	panel.custom_minimum_size = Vector2(500, 0)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Fx.label(Game.L("MENANG!", "VICTORY!"), 72, Game.YELLOW, 16)
	Voice.bark("raka" if heroes[0].alive else "tara", "win")
	v.add_child(t)
	for line in ["+%d EXP" % exp, "+%s" % Game.rp(cash)] + ups:
		var l := Label.new()
		l.text = line
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 28 if line.begins_with("+") else 24)
		v.add_child(l)
	ui.add_child(panel)
	panel.scale = Vector2(1, 0)
	panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	if not ups.is_empty():
		Sfx.play("sfx_buff")
	Game.shot("menang")
	await wait(2.6 if ups.is_empty() else 3.4)
	return "win"


func _defeat() -> String:
	menu.close()
	Sfx.stop_music(0.3)
	Sfx.play("jingle_gameover")
	var l := Fx.label(Game.L("SEMUA TUMBANG...", "ALL DOWN..."), 90, Color("ff6a6a"), 18)
	l.size = Vector2(1280, 160)
	l.position = Vector2(0, 220)
	ui.add_child(l)
	Game.shot("kalah")
	await wait(2.6)
	return "lose"


# =====================================================================
# HUD & TOMBOL LAYAR
# =====================================================================

## Tombol layar untuk QTE (mouse / sentuh).
class TouchPad extends Control:
	var qte: Qte
	func _input(e: InputEvent) -> void:
		if e is InputEventScreenTouch or (e is InputEventMouseButton and e.pressed):
			visible = true
		elif e is InputEventKey and e.pressed:
			visible = false
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visible = false
		position = Vector2(1100, 420)
		var layout := {"Z": Vector2(0, 40), "X": Vector2(70, 90)}
		for k in layout:
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.text = k
			b.position = layout[k]
			b.custom_minimum_size = Vector2(64, 56)
			b.add_theme_font_size_override("font_size", 30)
			b.button_up.connect(func(): qte.virtual_release(k))
			b.modulate.a = 0.75
			b.button_down.connect(func(): qte.virtual_press(k))
			add_child(b)
