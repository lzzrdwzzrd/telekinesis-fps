shader_type spatial;
render_mode depth_draw_always, blend_mix, cull_disabled;

uniform vec4 main_color: source_color;
uniform sampler2D noise_texture: source_color;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
uniform float scroll_speed = 1.0;
uniform float alpha_threshold = 0.0;
uniform bool use_threshold = false;
uniform bool invert_boost_direction = false;

uniform float uv_threshold = 1.0;
uniform float margin = 0.05;

uniform float wobble_amplitude = 0.05;
uniform float wobble_speed = 2.0;
uniform float wobble_scale = 3.0;

void vertex() {
	float scroll = TIME * wobble_speed;
	vec2 noise_uv = vec2(UV.y * wobble_scale, scroll);

	float n = texture(noise_texture, noise_uv).r;

	n = n * 2.0 - 1.0;

	vec2 radial = normalize(VERTEX.xz);

	if (length(radial) < 0.0001) {
		radial = vec2(1.0, 0.0);
	}

	VERTEX.xz += radial * n * wobble_amplitude;
}

void fragment() {
	if (UV.y - margin > uv_threshold) discard;

	vec2 moving_uv = UV;
	vec4 noise = texture(noise_texture, moving_uv);
	
	if (invert_boost_direction) {
		moving_uv.y += TIME * scroll_speed;
	} else{
		moving_uv.y -= TIME * scroll_speed;
	}
	
	float noise_value = texture(noise_texture, moving_uv).r;

	ALBEDO = main_color.rgb;
	EMISSION = emission.rgb * (UV.y < uv_threshold ? emission_energy : 3.0) * noise.rgb;
	float alpha = main_color.a * noise_value;

	if (use_threshold && alpha < alpha_threshold) {
		discard;
	} else {
		ALPHA = alpha;
	}
}
