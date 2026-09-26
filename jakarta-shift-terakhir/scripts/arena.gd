class_name Arena
extends Node2D
## Arena battle 2.5D: lantai berperspektif + latar lokasi di kejauhan.
## depth_scale(y) memberi skala karakter sesuai jarak.

const SHADER := preload("res://scripts/arena.gdshader")
const HORIZON_Y := 216.0

var rect: ColorRect


func setup(bg_path: String) -> void:
	var tex: Texture2D = load(bg_path)
	rect = ColorRect.new()
	rect.position = Vector2(-80, -60)
	rect.size = Vector2(1440, 840)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("backdrop", tex)
	m.set_shader_parameter("backdrop_aspect", float(tex.get_width()) / tex.get_height())
	m.set_shader_parameter("horizon", (HORIZON_Y + 60.0) / 840.0)
	var style := LiveBg.style_for(bg_path)
	var night := 1.0 if style in ["night", "rain"] else 0.0
	m.set_shader_parameter("night", night)
	var pal := _palette(tex)
	m.set_shader_parameter("tile_a", pal[0])
	m.set_shader_parameter("tile_b", pal[1])
	m.set_shader_parameter("light", Color(1.0, 0.72, 0.42) if night == 0.0 else Color(0.9, 0.35, 0.75))
	rect.material = m
	add_child(rect)
	# partikel suasana
	var lb := LiveBg.new()
	add_child(lb)
	lb.setup_particles_only(style)


## Ambil warna lantai dari bagian bawah gambar lokasi.
func _palette(tex: Texture2D) -> Array:
	var img := tex.get_image()
	if img == null:
		return [Color(0.62, 0.52, 0.44), Color(0.55, 0.46, 0.40)]
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var acc := Color(0, 0, 0)
	var n := 0
	for i in 40:
		var c := img.get_pixel(int(w * (0.05 + 0.9 * i / 40.0)), int(h * 0.93))
		acc += c
		n += 1
	var base := Color(acc.r / n, acc.g / n, acc.b / n)
	base = base.lightened(0.08)
	return [base, base.darkened(0.12)]


static func depth_scale(y: float) -> float:
	return lerpf(0.78, 1.18, clampf((y - 330.0) / 330.0, 0.0, 1.0))
