class_name Walker
extends Node2D
## Karakter berjalan dengan sprite strip 8 frame per arah.
## Skala mengikuti posisi Y (pseudo-kedalaman).

var strips := {}          # "right"/"left"/"up"/"down" -> Texture2D
var side_only := false    # hanya punya strip "right" (dibalik untuk kiri)
var base := 1.0
var floor_y := Vector2(540, 690)
var dir := "down"
var moving := false
var sprite: Sprite2D
var shadow: Polygon2D
var _t := 0.0


func setup(p_strips: Dictionary, p_base: float, p_side_only := false) -> void:
	strips = p_strips
	base = p_base
	side_only = p_side_only
	shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * 42, sin(a) * 10))
	shadow.polygon = pts
	shadow.color = Color(0, 0, 0, 0.35)
	add_child(shadow)
	sprite = Sprite2D.new()
	sprite.hframes = 8
	add_child(sprite)
	if side_only:
		dir = "right"
	_apply()


func _apply() -> void:
	var key := dir
	if side_only:
		key = "right"
		sprite.flip_h = dir == "left"
	var tex: Texture2D = strips.get(key, strips.values()[0])
	if sprite.texture != tex:
		sprite.texture = tex
		sprite.offset = Vector2(0, -tex.get_height() / 2.0)


func face(d: String) -> void:
	if side_only and (d == "up" or d == "down"):
		return
	dir = d
	_apply()


func _process(delta: float) -> void:
	if moving:
		_t += delta * 11.0
		sprite.frame = int(_t) % 8
	else:
		_t = 0.0
		sprite.frame = 0 if not side_only else 2
	var k := clampf((position.y - floor_y.x) / maxf(1.0, floor_y.y - floor_y.x), 0.0, 1.0)
	var s := base * lerpf(0.82, 1.05, k)
	scale = Vector2(s, s)
	sprite.position.y = -absf(sin(_t * PI / 4.0)) * 3.0 if moving else 0.0
