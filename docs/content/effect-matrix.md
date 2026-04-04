# Effect Matrix — 触发时机 × 触发效果

> Agent guidance: This table tracks which combinations of trigger × effect are implemented.
> ✅ = implemented; ❌ = not yet implemented.
> See `docs/content/effects.md` for class interfaces and `docs/content/modules.md` for module specs.

| 触发时机 | 减0.5s CD | 补充1弹药 | 补充2弹药 | 恢复速度提升1s |
|---------|:---------:|:--------:|:--------:|:------------:|
| **击中炮塔时** | ✅ `CdReduceOnHitTowerEffect` | ✅ `ReplenishEffect`(×1) | ✅ `ReplenishEffect`(×2) | ✅ `HitSpeedBoostEffect` |
| **击中敌人时** | ✅ `CdReduceOnEnemyEffect` | ❌ | ❌ | ❌ |
| **被击中时** | ✅ `CdReduceOnReceiveTowerEffect` | ❌ | ❌ | ❌ |
| **造成伤害时** | ❌ | ❌ | ❌ | ❌ |

## 备注

- **击中炮塔时**：子弹命中友方炮塔，触发 `BulletEffect.on_hit_tower`
- **击中敌人时**：子弹命中敌人，触发 `BulletEffect.on_hit_enemy`
- **被击中时**：炮塔被子弹命中，触发 `TowerEffect.on_receive_bullet_hit`
- **造成伤害时**：子弹对目标造成伤害，触发 `BulletEffect.on_deal_damage`

### 已实现效果对应类

| 效果 | 类 | 文件 |
|------|-----|------|
| 减0.5s CD（击中炮塔，减源塔CD） | `CdReduceOnHitTowerEffect` | `bullet_effects/cd_reduce_on_hit_tower_effect.gd` |
| 减0.5s CD（击中炮塔，减目标塔CD） | `CdReduceTargetTowerEffect` | `bullet_effects/cd_reduce_target_tower_effect.gd` |
| 减0.5s CD（击中敌人，减源塔CD） | `CdReduceOnEnemyEffect` | `bullet_effects/cd_reduce_on_enemy_effect.gd` |
| 减0.5s CD（被击中时）| `CdReduceOnReceiveTowerEffect` | `tower_effects/cd_reduce_on_receive_tower_effect.gd` |
| 补充1弹药（击中炮塔） | `ReplenishEffect`(ammo_amount=1) | `bullet_effects/replenish_effect.gd` |
| 补充2弹药（击中炮塔） | `ReplenishEffect`(ammo_amount=2) | `bullet_effects/replenish_effect.gd` |
| 恢复速度提升1s（击中炮塔） | `HitSpeedBoostEffect` | `bullet_effects/hit_speed_boost_effect.gd` |
