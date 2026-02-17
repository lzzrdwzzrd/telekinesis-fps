shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float falloff : hint_range(0.0, 1.0) = 0.5;
uniform int samples : hint_range(0, 64) = 16;
uniform vec2 center = vec2(0.5, 0.5);

// Vignette controls
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_radius : hint_range(0.0, 1.5) = 0.75;
uniform float vignette_softness : hint_range(0.001, 1.0) = 0.45;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - clamp(center, vec2(0.0), vec2(1.0));

	float dist = length(dir) * 2.0;
	float fall = pow(min(dist, 1.0), 3.0 * falloff);
	float step_scale = intensity / float(samples) * 0.05;

	vec4 color = texture(screen_texture, uv);

	for (int i = 1; i <= samples; i++) {
		float fi = float(i);
		float offset = fi * step_scale * fall;
		color += texture(screen_texture, uv - dir * offset);
	}

	color /= float(samples + 1);

	// --- Vignette ---
	float vignette_dist = distance(uv, center);
	float vignette = smoothstep(
		vignette_radius,
		vignette_radius - vignette_softness,
		vignette_dist
	);
	
	color.rgb *= mix(1.0, vignette, vignette_strength);

	COLOR = color;
}
