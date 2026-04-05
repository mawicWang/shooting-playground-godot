shader_type canvas_item;

uniform float outline_size : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	if (color.a > 0.1) {
		// 原始像素变红
		COLOR = vec4(1.0, 0.0, 0.0, color.a);
	} else {
		// Outline 采样：让相邻像素形成红色轮廓，实现"加粗"感
		vec2 texel = TEXTURE_PIXEL_SIZE;
		float alpha = 0.0;
		for (float x = -outline_size; x <= outline_size; x += 1.0) {
			for (float y = -outline_size; y <= outline_size; y += 1.0) {
				if (length(vec2(x, y)) <= outline_size) {
					alpha = max(alpha, texture(TEXTURE, UV + vec2(x, y) * texel).a);
				}
			}
		}
		COLOR = vec4(1.0, 0.0, 0.0, alpha);
	}
}
