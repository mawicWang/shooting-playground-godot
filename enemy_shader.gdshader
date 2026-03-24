shader_type canvas_item;

// --- 抖动参数 ---
uniform float shake_amplitude : hint_range(0.0, 30.0) = 2.0; // 抖动幅度（像素）
uniform float shake_fps : hint_range(1.0, 30.0) = 8.0;      // 抖动帧率（每秒跳变几次）

// --- 噪点贴图 ---
// 建议在 Inspector 中使用 Nearest 采样、FBM 类型噪音的纹理
uniform sampler2D shake_noise_tex : hint_default_black; 

void vertex() {
    // 1. 将时间离散化，实现"抽帧"感
	float snapped_time = floor(TIME * shake_fps);
	
    // 2. 基于时间采样噪点图
    // 我们用时间作为一个大的偏移量，确保每一帧采样的区域完全不同。
    // 给 X 和 Y 方向使用不同的偏移量采样，让XY轴抖动不同步
    // 使用 fract 确保 UV 始终在 0-1 循环，并加入一个较大的质数偏移
	vec2 noise_uv_x = vec2(fract(snapped_time * 0.584), fract(snapped_time * 0.231));
	vec2 noise_uv_y = vec2(fract(snapped_time * 0.147 + 0.5), fract(snapped_time * 0.752));

	float noise_val_x = texture(shake_noise_tex, noise_uv_x).r;
	float noise_val_y = texture(shake_noise_tex, noise_uv_y).r;

    // 3. 将采样得到的 [0, 1] 噪点值转换为 [-1, 1] 的偏移量
    float offset_x = (noise_val_x - 0.5) * 2.0;
    float offset_y = (noise_val_y - 0.5) * 2.0;

    // 4. 应用偏移（像素单位）
    VERTEX.x += offset_x * shake_amplitude;
    VERTEX.y += offset_y * shake_amplitude;
}
