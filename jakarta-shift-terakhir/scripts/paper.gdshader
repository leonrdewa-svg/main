shader_type canvas_item;
// Sprite kertas: flash warna saat kena hit.
// Catatan: di Godot 4, COLOR di fragment() sudah = warna tekstur x modulate.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
	vec4 c = COLOR;
	c.rgb = mix(c.rgb, flash_color.rgb, flash);
	COLOR = c;
}
