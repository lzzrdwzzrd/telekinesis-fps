shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 modelColor : source_color;
uniform vec4 wireframeColor : source_color;
uniform float width : hint_range(0.0, 15.) = 1.;
uniform float modelOpacity : hint_range(0.0, 1.0) = 1.;

// how far from vertices wireframe disappears (fraction of edge length)
uniform float vertex_margin : hint_range(0.0, 0.5) = 0.15;

varying vec3 baryCoord;

const vec3 vectors[3] = {
	vec3(1.0, 0.0 ,0.0),
	vec3(0.0, 1.0 ,0.0),
	vec3(0.0, 0.0 ,1.0)
};

void vertex()
{
	baryCoord = vectors[VERTEX_ID % 3];
}

void fragment()
{
	// --- original edge detection ---
	vec3 dBaryCoordX = dFdx(baryCoord);
	vec3 dBaryCoordY = dFdy(baryCoord);
	vec3 dBaryCoord  = sqrt(dBaryCoordX*dBaryCoordX + dBaryCoordY*dBaryCoordY);

	vec3 remap = smoothstep(
		vec3(0.0),
		dBaryCoord * width,
		baryCoord
	);

	remap = step(.5, remap);

	float closestEdge = min(min(remap.x, remap.y), remap.z);

	// --- edge position along each edge (0..1) ---
	float t_x = baryCoord.y / (baryCoord.y + baryCoord.z + 1e-6);
	float t_y = baryCoord.x / (baryCoord.x + baryCoord.z + 1e-6);
	float t_z = baryCoord.x / (baryCoord.x + baryCoord.y + 1e-6);

	// --- keep only middle portion of edges ---
	float edge_mask_x = step(vertex_margin, t_x) * step(vertex_margin, 1.0 - t_x);
	float edge_mask_y = step(vertex_margin, t_y) * step(vertex_margin, 1.0 - t_y);
	float edge_mask_z = step(vertex_margin, t_z) * step(vertex_margin, 1.0 - t_z);

	// choose mask of the active edge
	float segmentMask =
		min(remap.x, 1.0 - edge_mask_x) +
		min(remap.y, 1.0 - edge_mask_y) +
		min(remap.z, 1.0 - edge_mask_z);

	segmentMask = 1.0 - step(1.0, segmentMask);
	float finalWire = closestEdge * segmentMask;

	ALBEDO = mix(modelColor.rgb, wireframeColor.rgb, finalWire);
	ALPHA  = mix(1., modelOpacity, finalWire);
}
