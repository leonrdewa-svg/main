class_name ShopScreen
extends Node2D
## Warung Bu Sari: beli makanan/minuman pakai Rupiah.

signal done

var menu: CommandMenu
var wallet: Label
var dialog: Dialogue

const STOCK := ["nasi", "kopi", "air", "roti", "permen", "plester", "kartu"]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.size = Vector2(1280, 720)
	bg.color = Color("2a1f1c")
	add_child(bg)
	var scene := Sprite2D.new()
	scene.texture = load("res://assets/world/warung_scene.jpg")
	scene.centered = false
	var s := 720.0 / scene.texture.get_height()
	scene.scale = Vector2(s, s)
	add_child(scene)
	var ui := CanvasLayer.new()
	add_child(ui)
	var title := Fx.label(Game.L("WARUNG BU SARI", "BU SARI'S STALL"), 60, Game.YELLOW, 14)
	title.position = Vector2(740, 20)
	title.size = Vector2(520, 80)
	title.rotation = deg_to_rad(-2)
	ui.add_child(title)
	var wp := Panel.new()
	wp.theme = Game.ui_theme
	wp.position = Vector2(760, 100)
	wp.size = Vector2(480, 44)
	wp.add_theme_stylebox_override("panel", Game.paper_box(Game.INK, Game.YELLOW, 8, 4))
	ui.add_child(wp)
	wallet = Fx.label("", 26, Game.YELLOW, 6)
	wallet.size = Vector2(480, 44)
	wp.add_child(wallet)
	menu = CommandMenu.new()
	ui.add_child(menu)
	menu.desc_panel.position = Vector2(740, 640)
	menu.desc_panel.custom_minimum_size = Vector2(520, 56)
	dialog = Dialogue.new()
	var dl := CanvasLayer.new()
	dl.layer = 30
	add_child(dl)
	dl.add_child(dialog)
	Sfx.play("sfx_paper")
	_run()


func _refresh() -> void:
	wallet.text = Game.L("DOMPET  %s", "WALLET  %s") % Game.rp(Game.money)


func _run() -> void:
	_refresh()
	await dialog.play(Story.D.busari_hi, "busari_hi")
	Game.shot("warung")
	while true:
		_refresh()
		var opts := []
		for id in STOCK:
			var it: Dictionary = Game.ITEMS[id]
			opts.append({"id": id, "label": Game.T(it.name), "right": Game.rp(it.price), "icon": it.icon,
				"desc": Game.L("%s  (punya: %d)", "%s  (owned: %d)") % [Game.T(it.desc), Game.bag.get(id, 0)], "enabled": Game.money >= it.price})
		opts.append({"id": "rest", "label": Game.L("Numpang Istirahat", "Take a Rest"), "right": Game.L("gratis", "free"), "icon": "res://assets/ui/icon_heart.png",
			"desc": Game.L("HP party pulih penuh. Bu Sari baik hati.", "Fully restores party HP. Bu Sari is kind.")})
		if Game.autoplay:
			await get_tree().create_timer(0.5).timeout
			if Game.money >= 15000:
				Game.money -= 15000
				Game.add_item("nasi")
			break
		var c = await menu.open(opts, "", Vector2(760, 160))
		if c == null:
			break
		if c == "rest":
			Game.full_heal()
			Sfx.play("sfx_heal")
			menu.say(Game.L("HP pulih penuh! \"Jangan lupa minum air putih, Nak.\"", "HP fully restored! \"Don't forget to drink water, dear.\""))
			await get_tree().create_timer(1.0).timeout
			continue
		var price: int = Game.ITEMS[c].price
		if Game.money >= price:
			Game.money -= price
			Game.add_item(c)
			Sfx.play("sfx_star")
			menu.say(Game.L("Beli %s! Terima kasih, Nak.", "Bought %s! Thank you, dear.") % Game.T(Game.ITEMS[c].name))
			await get_tree().create_timer(0.6).timeout
	menu.close()
	done.emit()
