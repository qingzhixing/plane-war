shader_type canvas_item;

uniform float scroll_speed : hint_range(10.0, 400.0) = 80.0;

float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 17.5);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(0.10, 0.12, 0.25);

	float t = TIME * scroll_speed / 1280.0;

	// 3 star layers: far (slow/dim) → near (fast/bright)
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float layer_speed = fi * 0.55 + 0.45;  // 0.45, 1.0, 1.55

		vec2 layer_uv = vec2(uv.x, uv.y - t * layer_speed);
		layer_uv *= vec2(1.0, 8.0 + fi * 3.0);

		vec2 cell = floor(layer_uv);
		vec2 local_uv = fract(layer_uv);

		float r = hash(cell + fi * vec2(47.3, 31.7));
		if (r > 0.78) {
			vec2 star_pos = vec2(hash(cell + vec2(1.0)), hash(cell + vec2(2.0)));
			vec2 diff = abs(local_uv - star_pos);
			float y_tiles = 8.0 + fi * 3.0;
			// 将 diff 换算成屏幕像素，使方块在视觉上等宽高
			float star_px = 3.0 + hash(cell + vec2(3.0)) * 2.0;
			float star = step(max(diff.x * 720.0, diff.y * 1280.0 / y_tiles), star_px);
			float twinkle = 0.75 + 0.25 * sin(TIME * (1.5 + r * 4.0) + r * 60.0);
			float brightness = (0.35 + fi * 0.25) * twinkle;
			col += star * brightness;
		}
	}

	COLOR = vec4(col, 1.0);
}
