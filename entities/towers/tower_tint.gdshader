shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	// Saturation of tint color: 0 for white/gray (NEUTRAL) → preserve original.
	// 1 for pure hues (NEGATIVE blue / POSITIVE red) → strong colorize.
	float tint_sat = max(0.0, 1.0 - 3.0 * min(color.r, min(color.g, color.b)));

	// Luminance-preserving colorize: tint color scaled by pixel brightness.
	vec3 colorized = color.rgb * (lum + 0.2);

	// Mix: NEUTRAL (tint_sat=0) keeps original; NEGATIVE/POSITIVE (tint_sat=1) → 80% colorized.
	COLOR = vec4(mix(tex.rgb, clamp(colorized, 0.0, 1.0), tint_sat * 0.8), tex.a);
}
