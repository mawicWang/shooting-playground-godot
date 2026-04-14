# Effect Matrix — 触发时机 × 触发效果

> Agent guidance: This table tracks which combinations of trigger × effect are implemented.
> ✅ = implemented; ❌ = not yet implemented.
> See `docs/content/effects.md` for class interfaces and `docs/content/modules.md` for module specs.

| 触发时机 | 减0.5s CD | 补充1弹药 | 补充2弹药 | 恢复速度提升1s |
|---------|:---------:|:--------:|:--------:|:------------:|
| **击中炮塔时** | ✅ `HitTowerSelfCdReduceEffect`<br>✅ `HitTowerTargetCdReduceEffect` | ✅ `HitTowerTargetReplenishEffect`(×1) | ✅ `HitTowerTargetReplenishEffect`(×2) | ✅ `HitTowerTargetSpeedBoostEffect` |
| **击中敌人时** | ✅ `HitEnemySelfCdReduceEffect` | ✅ `HitEnemySelfReplenishEffect`(×1) | ✅ `HitEnemySelfReplenishEffect`(×2) | ✅ `HitEnemySelfSpeedBoostEffect` |
| **被击中时** | ✅ `ReceiveHitSelfCdReduceEffect` | ✅ `ReceiveHitSelfReplenishEffect`(×1) | ✅ `ReceiveHitSelfReplenishEffect`(×2) | ✅ `ReceiveHitSelfSpeedBoostEffect` |
| **造成伤害时** | ✅ `DealDamageSelfCdReduceEffect` | ✅ `DealDamageSelfReplenishEffect`(×1) | ❌ (deferred) | ✅ `DealDamageSelfSpeedBoostEffect` |

## 备注

- **击中炮塔时**：子弹命中友方炮塔，触发 `BulletEffect.on_hit_tower`
- **击中敌人时**：子弹命中敌人，触发 `BulletEffect.on_hit_enemy`
- **被击中时**：炮塔被子弹命中，触发 `TowerEffect.on_receive_bullet_hit`
- **造成伤害时**：子弹对目标造成伤害，触发 `BulletEffect.on_deal_damage`
- **Self** (BulletEffect)：`bullet_data.transmission_chain[0]`（发射方炮塔）
- **Target** (BulletEffect on_hit_tower)：被击中的炮塔
- **Self** (TowerEffect)：接收事件的炮塔自身

## 已实现效果对应类

| 效果 | 类 | 文件 |
|------|-----|------|
| 减CD（击中塔，减来源塔） | `HitTowerSelfCdReduceEffect` | `bullet_effects/hit_tower_self_cd_reduce_effect.gd` |
| 减CD（击中塔，减目标塔） | `HitTowerTargetCdReduceEffect` | `bullet_effects/hit_tower_target_cd_reduce_effect.gd` |
| 减CD（击中敌，减来源塔） | `HitEnemySelfCdReduceEffect` | `bullet_effects/hit_enemy_self_cd_reduce_effect.gd` |
| 减CD（被击中时） | `ReceiveHitSelfCdReduceEffect` | `tower_effects/receive_hit_self_cd_reduce_effect.gd` |
| 减CD（造成伤害时） | `DealDamageSelfCdReduceEffect` | `bullet_effects/deal_damage_self_cd_reduce_effect.gd` |
| 补弹（击中塔，补目标塔） | `HitTowerTargetReplenishEffect` | `bullet_effects/hit_tower_target_replenish_effect.gd` |
| 补弹（击中敌，补来源塔） | `HitEnemySelfReplenishEffect` | `bullet_effects/hit_enemy_self_replenish_effect.gd` |
| 补弹（被击中时） | `ReceiveHitSelfReplenishEffect` | `tower_effects/receive_hit_self_replenish_effect.gd` |
| 补弹（造成伤害时） | `DealDamageSelfReplenishEffect` | `bullet_effects/deal_damage_self_replenish_effect.gd` |
| 加速（击中塔，加速目标塔） | `HitTowerTargetSpeedBoostEffect` | `bullet_effects/hit_tower_target_speed_boost_effect.gd` |
| 加速（击中敌，加速来源塔） | `HitEnemySelfSpeedBoostEffect` | `bullet_effects/hit_enemy_self_speed_boost_effect.gd` |
| 加速（被击中时） | `ReceiveHitSelfSpeedBoostEffect` | `tower_effects/receive_hit_self_speed_boost_effect.gd` |
| 加速（造成伤害时） | `DealDamageSelfSpeedBoostEffect` | `bullet_effects/deal_damage_self_speed_boost_effect.gd` |
| 加速（击杀敌人时） | `KillEnemySelfSpeedBoostEffect` | `bullet_effects/kill_enemy_self_speed_boost_effect.gd` |
