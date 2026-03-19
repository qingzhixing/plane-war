shader_type canvas_item;

uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_tint : source_color = vec4(1.0, 0.2, 0.2, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 tinted_rgb = mix(base.rgb, hit_tint.rgb, clamp(hit_strength, 0.0, 1.0));
	COLOR = vec4(tinted_rgb, base.a);
}
