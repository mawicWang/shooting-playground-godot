shader_type canvas_item;

// --- 抖动参数 ---
uniform float shake_amplitude : hint_range(0.0, 30.0) = 2.0;
uniform float shake_fps : hint_range(1.0, 30.0) = 8.0;

// --- 旋转参数 ---
uniform float rot_amplitude : hint_range(0.0, 45.0) = 30.0;

// --- 关键修改：改为 instance uniform ---
// 这样每个 Sprite 实例可以拥有独立的种子，而不需要 Unique Material
instance uniform float noise_seed : hint_range(0.0, 1000.0) = 0.0;

// --- 时间偏移：让不同敌人在不同时刻触发抖动帧，避免同步 ---
instance uniform float time_offset : hint_range(0.0, 10.0) = 0.0;

// --- 受击白闪 ---
instance uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;

// --- 噪点贴图 ---
uniform sampler2D shake_noise_tex : hint_default_black;

void vertex() {
    // 1. 获取离散时间（加入 time_offset 让每个敌人错峰跳动）
    float snapped_time = floor(TIME * shake_fps + time_offset);

    // 2. 引入实例 ID 和种子，产生极大的随机偏移
    // 加入 INSTANCE_ID 是为了双重保险，即便忘记在脚本里设 seed，它们也会不同
    float total_seed = noise_seed + float(INSTANCE_ID) * 13.456;

    // 3. 采样位移噪点
    // 使用更大的质数乘数来彻底打乱不同实例间的采样位置
    vec2 noise_uv_x = vec2(fract(snapped_time * 0.584 + total_seed * 0.123),
                           fract(snapped_time * 0.231 + total_seed * 0.456));
    vec2 noise_uv_y = vec2(fract(snapped_time * 0.147 + 0.5 + total_seed * 0.789),
                           fract(snapped_time * 0.752 + total_seed * 0.321));

    // 使用 textureLod 提高顶点着色器采样的稳定性
    float noise_val_x = textureLod(shake_noise_tex, noise_uv_x, 0.0).r;
    float noise_val_y = textureLod(shake_noise_tex, noise_uv_y, 0.0).r;

    float offset_x = (noise_val_x - 0.5) * 2.0;
    float offset_y = (noise_val_y - 0.5) * 2.0;

    // 4. 采样旋转噪点
    vec2 rot_uv = vec2(fract(snapped_time * 0.357 + 0.3 + total_seed * 0.555),
                       fract(snapped_time * 0.619 + 0.7 + total_seed * 0.111));
    float rot_noise = textureLod(shake_noise_tex, rot_uv, 0.0).r;
    float rot_radians = radians((rot_noise - 0.5) * 2.0 * rot_amplitude);

    // 5. 应用旋转（围绕中心点）
    float cos_r = cos(rot_radians);
    float sin_r = sin(rot_radians);
    vec2 rotated = vec2(
        VERTEX.x * cos_r - VERTEX.y * sin_r,
        VERTEX.x * sin_r + VERTEX.y * cos_r
    );

    // 6. 应用最终位置
    VERTEX = rotated + vec2(offset_x, offset_y) * shake_amplitude;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    // 受击时将颜色混入白色，alpha 保持不变
    COLOR = vec4(mix(tex.rgb * COLOR.rgb, vec3(1.0), hit_flash_intensity), tex.a * COLOR.a);
}