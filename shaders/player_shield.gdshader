shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 inner_color : source_color = vec4(0.3, 0.8, 1.0, 0.65);
uniform vec4 outer_color : source_color = vec4(0.0, 0.4, 0.9, 0.0);

void fragment() {
	// 以中心为原点计算半径
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);

	// 脉冲：让护盾边缘轻微呼吸
	float edge_radius = mix(0.35, 0.42, pulse);
	float edge_softness = 0.08;

	float edge = smoothstep(edge_radius, edge_radius - edge_softness, dist);
	vec4 col = mix(outer_color, inner_color, edge);

	// 只在一定半径内绘制，避免占满整个矩形
	if (dist > 0.55) {
		col.a = 0.0;
	}

	COLOR = col;
}

