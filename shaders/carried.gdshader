shader_type spatial;

//uniform bool enabled;
uniform float alpha : hint_range(0.0, 1.0);
uniform vec4 base_color : source_color;
uniform vec3 fresnel_color : source_color;

uniform float level : hint_range(0.0, 1.0) = 1.0;
uniform float emission_intensity : hint_range(0.0, 1.0);

uniform float fresnel_intensity : hint_range(0.0, 10.0);
uniform float fresnel_power : hint_range(1.0, 10.0);

uniform vec3 rim_color : source_color;
uniform float rim_size : hint_range(0.0, 0.8);
uniform float rim_intensity : hint_range(0.0, 1.0);
uniform float rim_start : hint_range(-1.0, 1.0);
uniform float rim_end : hint_range(-1.0, 1.0);

uniform sampler2D noise : source_color;
uniform vec4 noise_color : source_color;
uniform vec2 scroll_direction = vec2(0.0, 1.0);
uniform float scroll_speed = 1.0;
uniform float noise_threshold = 0.5;
uniform float noise_width = 0.002;
uniform float noise_override = 0.0;

void fragment()
{
	if (alpha <= 0.001) discard;
	float dir = 1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel_amount = pow(dir, fresnel_power) * fresnel_intensity;
	vec3 fresnel = fresnel_color * fresnel_amount;

	float top_align = dot(normalize(NORMAL), vec3(0.0, 1.0, 0.0));
	float top_limit = smoothstep(rim_start, rim_end, top_align);
	float rim_amount = step(1.0 - rim_size, dir) * rim_intensity * top_limit;
	vec3 rim = rim_color * rim_amount;

	float noise_value = mod((sin(TIME * 1.5) + 1.0) * 13.0, 26.0) / 26.0;
	vec2 uv = vec2(UV.x, UV.y);
	vec4 albedo = texture(noise, uv);
	bool show_noise = abs(albedo.r - noise_value) - noise_override < 0.03;

	ALBEDO = show_noise ? fresnel_color : (fresnel + rim + base_color.rgb);
	EMISSION = show_noise ? fresnel_color * 7.0 : (fresnel + rim) * emission_intensity * level;
	ALPHA = (show_noise ? 0.8 : clamp((rim_amount + fresnel_amount * level + .2), 0., 1.)) * alpha;
}

void light() {
	DIFFUSE_LIGHT = vec3(1,1,1);
}