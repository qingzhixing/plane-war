shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 inner_color : source_color = vec4(0.75, 1.0, 1.0, 0.95);
uniform vec4 mid_color : source_color = vec4(0.25, 0.85, 1.0, 0.72);
uniform vec4 outer_color : source_color = vec4(0.1, 0.45, 1.0, 0.4);

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);

	// 与 TIME 叠加呼吸，环更明显
	float breathe = 0.5 + 0.5 * sin(TIME * 2.8 + pulse * 6.28318);
	float edge_radius = mix(0.36, 0.5, breathe);
	float edge_softness = 0.1;

	// 内亮环 + 中外渐变
	float inner_ring = smoothstep(edge_radius + 0.06, edge_radius - 0.02, dist);
	float outer_fall = smoothstep(edge_radius, edge_radius - edge_softness, dist);
	vec4 col = mix(outer_color, mid_color, outer_fall);
	col = mix(col, inner_color, inner_ring * 0.85);

	// 内圈再提亮一条细边
	float rim = smoothstep(edge_radius - 0.04, edge_radius - 0.12, dist)
		* (1.0 - smoothstep(edge_radius - 0.02, edge_radius + 0.02, dist));
	col.rgb += vec3(0.35, 0.5, 0.55) * rim * 1.2;
	col.a = max(col.a, rim * 0.9);

	// 外缘裁切略放宽，大矩形上环更粗
	if (dist > 0.62) {
		col.a *= smoothstep(0.68, 0.62, dist);
	}
	if (dist > 0.72) {
		col.a = 0.0;
	}

	COLOR = col;
}
