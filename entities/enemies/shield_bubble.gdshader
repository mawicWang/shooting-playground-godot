shader_type canvas_item;

uniform float pulse_speed = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_max : hint_range(0.0, 1.0) = 0.7;
uniform float layer_intensity : hint_range(0.0, 1.0) = 1.0;
uniform vec4 shield_color : source_color = vec4(0.3, 0.5, 1.0, 0.5);
instance uniform float ripple_time = -1.0;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);

	// Circle mask with soft edge
	float radius = 0.45;
	float edge_width = 0.05;
	float circle_mask = 1.0 - smoothstep(radius - edge_width, radius, dist);

	// Breathing pulse
	float pulse = mix(pulse_min, pulse_max, (sin(TIME * pulse_speed) * 0.5 + 0.5));

	// Rim glow: brighter at edges
	float rim = smoothstep(0.25, radius - edge_width, dist);

	// Ripple effect
	float ripple = 0.0;
	if (ripple_time >= 0.0) {
		float elapsed = TIME - ripple_time;
		if (elapsed >= 0.0 && elapsed < 0.4) {
			float ring_progress = elapsed / 0.4;
			float ring_radius = ring_progress * radius;
			float ring_dist = abs(dist - ring_radius);
			float ring_width = 0.05 * (1.0 - ring_progress);
			ripple = (1.0 - smoothstep(0.0, ring_width, ring_dist)) * (1.0 - ring_progress);
		}
	}

	// Combine
	vec4 base = shield_color;
	base.a *= pulse * circle_mask * layer_intensity;
	base.rgb += rim * 0.4 * layer_intensity;
	base.rgb = clamp(base.rgb + ripple * vec3(0.6, 0.8, 1.0), 0.0, 1.0);
	base.a = clamp(base.a + ripple * circle_mask * 0.5, 0.0, 1.0);

	COLOR = base;
}
