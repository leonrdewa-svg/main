class_name Stage
extends Node2D
## Bingkai panggung teater ala Paper Mario: tirai merah kiri/kanan yang bisa
## dibuka/ditutup, valance bergelombang di atas, bibir panggung + lampu sorot.

var openness := 0.0:
	set(v):
		openness = v
		queue_redraw()
var caption := ""
var sub_caption := ""

const RED := Color("a3122b")
const RED_D := Color("6e0a1c")
const RED_L := Color("c92a41")
const GOLD := Color("e8b43a")


func _draw() -> void:
	var W := 1280.0
	var H := 720.0
	# bibir panggung
	draw_rect(Rect2(0, H - 30, W, 30), Color("5a3520"))
	draw_rect(Rect2(0, H - 30, W, 6), Color("8a5a36"))
	for i in 9:
		var x := 80 + i * 140.0
		draw_circle(Vector2(x, H - 14), 7, Color("ffe89a"))
		draw_circle(Vector2(x, H - 14), 7, Game.INK, false, 2)
	# tirai samping
	var side := 34.0 + (W / 2 - 34.0) * (1.0 - openness)
	_curtain(Rect2(0, 0, side, H), false)
	_curtain(Rect2(W - side, 0, side, H), true)
	# valance atas
	draw_rect(Rect2(0, 0, W, 30), RED_D)
	var n := 16
	var w := W / n
	for i in n:
		var cx := i * w + w / 2
		draw_circle(Vector2(cx, 30), w / 2, RED)
		draw_arc(Vector2(cx, 30), w / 2, 0, PI, 20, GOLD, 5)
		draw_arc(Vector2(cx, 30), w / 2 - 12, 0.3, PI - 0.3, 16, RED_L, 4)
	draw_rect(Rect2(0, 0, W, 30), RED)
	draw_line(Vector2(0, 30), Vector2(W, 30), GOLD, 4)
	# teks pada tirai tertutup
	if openness < 0.35 and caption != "":
		var a := 1.0 - openness / 0.35
		var fs := 84
		var tw := Game.FONT_TITLE.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := Vector2(W / 2 - tw / 2, H / 2)
		draw_string_outline(Game.FONT_TITLE, p + Vector2(6, 6), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, Color(0, 0, 0, 0.5 * a))
		draw_string_outline(Game.FONT_TITLE, p, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 14, Color(Game.INK, a))
		draw_string(Game.FONT_TITLE, p, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Game.YELLOW, a))
		if sub_caption != "":
			var fs2 := 36
			var tw2 := Game.FONT_UI.get_string_size(sub_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			var p2 := Vector2(W / 2 - tw2 / 2, H / 2 + 60)
			draw_string_outline(Game.FONT_UI, p2, sub_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, 10, Color(Game.INK, a))
			draw_string(Game.FONT_UI, p2, sub_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(Game.CREAM, a))


func _curtain(r: Rect2, right: bool) -> void:
	draw_rect(r, RED)
	var folds := maxi(2, int(r.size.x / 46))
	var fw := r.size.x / folds
	for i in folds:
		var x := r.position.x + i * fw
		draw_rect(Rect2(x, r.position.y, fw * 0.35, r.size.y), RED_D)
		draw_rect(Rect2(x + fw * 0.55, r.position.y, fw * 0.18, r.size.y), RED_L)
	var edge_x := r.position.x if right else r.end.x
	draw_line(Vector2(edge_x, 0), Vector2(edge_x, r.size.y), Game.INK, 5)
	draw_line(Vector2(edge_x + (4 if right else -4), 0), Vector2(edge_x + (4 if right else -4), r.size.y), GOLD, 3)


func open_curtain(dur := 1.1) -> void:
	Sfx.play("sfx_curtain", -2.0)
	var tw := create_tween()
	tw.tween_property(self, "openness", 1.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func close_curtain(dur := 0.9) -> void:
	Sfx.play("sfx_curtain", -2.0, 0.9)
	var tw := create_tween()
	tw.tween_property(self, "openness", 0.0, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
