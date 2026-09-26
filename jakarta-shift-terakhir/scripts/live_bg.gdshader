shader_type canvas_item;
// Latar hidup: dedaunan bergoyang, neon berkedip, sapuan cahaya.

uniform float sway = 0.004;
uniform float neon = 0.0;
uniform float warm = 0.0;

varying vec4 vmod;

void vertex() {
	vmod = COLOR;
}

void fragment() {
	vec2 uv = UV;
	vec4 base = texture(TEXTURE, uv);
	float green = clamp((base.g - max(base.r, base.b)) * 5.0, 0.0, 1.0);
	float wave = sin(TIME * 1.7 + uv.y * 42.0 + uv.x * 13.0) * sway * green;
	wave += sin(TIME * 0.9 + uv.x * 7.0) * sway * 0.5 * green;
	vec4 c = texture(TEXTURE, uv + vec2(wave, wave * 0.35));
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = mx - mn;
	float flick = 0.5 + 0.5 * sin(TIME * 3.1 + uv.x * 23.0) * sin(TIME * 7.7 + uv.y * 11.0);
	c.rgb += c.rgb * sat * neon * flick * step(0.55, mx) * 0.7;
	float sweep = smoothstep(0.06, 0.0, abs(fract(uv.x * 0.6 + uv.y * 0.25 - TIME * 0.035) - 0.5)) * warm;
	c.rgb += vec3(1.0, 0.85, 0.6) * sweep * 0.07;
	COLOR = c * vmod;
}
