shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled;
stencil_mode read, compare_equal, 4;

uniform vec3 output : source_color;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	ALBEDO = output;
}