shader_type spatial;

uniform float scale;
uniform float thickness = 0.0005;

void fragment() {
	vec2 uv = mod(UV, 1. / scale);
	ALBEDO.rgb = uv.x < thickness || uv.y < thickness ? vec3(.1, .1, .1) : vec3(0, 0, 0);
}
