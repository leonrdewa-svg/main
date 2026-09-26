shader_type canvas_item;
// Lantai arena 2.5D: bidang tanah berperspektif dengan ubin isometrik,
// garis pemandu kuning, dan cahaya hangat. Di atas horizon: latar lokasi.

uniform sampler2D backdrop : filter_linear;
uniform float backdrop_aspect = 3.5;
uniform float horizon = 0.30;
uniform vec3 tile_a : source_color = vec3(0.62, 0.52, 0.44);
uniform vec3 tile_b : source_color = vec3(0.55, 0.46, 0.40);
uniform vec3 grout : source_color = vec3(0.30, 0.24, 0.22);
uniform vec3 light : source_color = vec3(1.0, 0.72, 0.42);
uniform float night = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	vec3 col;
	if (uv.y < horizon + 0.12) {
		// latar: potongan tengah panorama, sedikit diperbesar & digeser pelan
		float bx = 0.5 + (uv.x - 0.5) * (1.7777 / backdrop_aspect) * 1.25 + sin(TIME * 0.03) * 0.01;
		float by = uv.y / (horizon + 0.12) * 0.62 + 0.02;
		col = texture(backdrop, vec2(bx, by)).rgb;
		col = mix(col, col * vec3(0.85, 0.8, 0.9), 0.25);
	}
	if (uv.y > horizon) {
		float d = max(uv.y - horizon, 0.001);
		float z = 0.35 / d;
		vec2 g = vec2((uv.x - 0.5) * z * 1.9, z);
		// putar 40 derajat -> ubin diagonal (isometrik)
		float a = 0.70;
		vec2 r = vec2(g.x * cos(a) - g.y * sin(a), g.x * sin(a) + g.y * cos(a)) * 7.0;
		vec2 cell = floor(r);
		vec2 f = fract(r);
		float n = hash(cell);
		vec3 t = mix(tile_a, tile_b, step(0.55, n)) * (0.9 + 0.2 * hash(cell + 3.1));
		// tekstur batu halus
		t *= 0.94 + 0.08 * hash(floor(r * 6.0));
		vec2 w = fwidth(r) * 1.2;
		vec2 e = smoothstep(vec2(0.0), w + 0.02, f) * smoothstep(vec2(0.0), w + 0.02, 1.0 - f);
		float line = e.x * e.y;
		t = mix(grout, t, line);
		// kilap tepi atas ubin
		t += 0.05 * smoothstep(0.9, 1.0, 1.0 - f.y);
		// jalur pemandu kuning (taktil) diagonal
		float band = abs(r.x - r.y * 0.35 - 4.0);
		float yl = step(band, 1.6) * step(0.18, f.x) * step(0.18, f.y) * step(f.x, 0.82) * step(f.y, 0.82);
		t = mix(t, vec3(0.86, 0.66, 0.18), yl * 0.85);
		// cahaya hangat dari kanan atas + kabut jarak
		float glow = exp(-length((uv - vec2(0.72, horizon + 0.05)) * vec2(1.2, 2.2)) * 1.6);
		t += light * glow * (0.35 + night * 0.25);
		float fog = clamp(1.0 - d * 3.2, 0.0, 1.0);
		t = mix(t, t * 0.55 + light * 0.18, fog * 0.6);
		t *= mix(1.0, 0.65, night);
		// pinggiran gelap (vignette bawah)
		t *= 1.0 - smoothstep(0.8, 1.2, length((uv - vec2(0.5, 0.7)) * vec2(1.1, 1.3))) * 0.55;
		float blend = smoothstep(horizon, horizon + 0.12, uv.y);
		col = mix(col, t, blend);
	}
	COLOR = vec4(col, 1.0);
}
