shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Saturation of tint color: 0 for white/gray (NEUTRAL) → no overlay.
	// 1 for pure hues (NEGATIVE blue / POSITIVE red) → full overlay.
	float tint_sat = max(0.0, 1.0 - 3.0 * min(color.r, min(color.g, color.b)));

	// Color overlay on opaque pixels only (transparent pixels stay transparent).
	// 45% tint ensures the variant color is clearly visible on any sprite.
	COLOR = vec4(mix(tex.rgb, color.rgb, tex.a * tint_sat * 0.45), tex.a);
}
