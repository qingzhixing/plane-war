shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ring_bright : source_color = vec4(0.85, 1.0, 1.0, 0.88);
uniform vec4 ring_mid : source_color = vec4(0.2, 0.75, 1.0, 0.55);
uniform vec4 ring_outer : source_color = vec4(0.05, 0.35, 0.95, 0.22);

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);

	float hole_inner = 0.26;
	float hole_outer = 0.36;
	float out_of_hole = smoothstep(hole_inner, hole_outer, dist);

	float breathe = 0.5 + 0.5 * sin(TIME * 2.6);
	float outer_r = mix(0.54, 0.62, breathe);
	float fade_outer = 1.0 - smoothstep(outer_r - 0.06, outer_r + 0.08, dist);

	float mask = out_of_hole * fade_outer;
	float mask_vis = smoothstep(0.0, 0.04, mask);

	float t = clamp((dist - hole_outer) / max(outer_r - hole_outer, 0.01), 0.0, 1.0);
	vec4 col = mix(ring_mid, ring_outer, t * 0.5);
	col = mix(col, ring_bright, smoothstep(0.42, 0.52, dist) * 0.75);
	col.a *= mask * mask_vis;

	float rim = smoothstep(outer_r - 0.05, outer_r - 0.12, dist)
		* (1.0 - smoothstep(outer_r - 0.02, outer_r + 0.04, dist));
	col.rgb += vec3(0.25, 0.45, 0.55) * rim * mask_vis;
	col.a = max(col.a, rim * 0.65 * mask * mask_vis);

	COLOR = col;
}
