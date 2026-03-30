# Effect System Architecture

## 核心设计原则

三类 Effect，对应三个触发时机，职责严格分离：

| 类型 | 触发时机 | 持有者 |
|------|---------|--------|
| `FireEffect` | 炮塔开火时，修改 BulletData | Tower |
| `BulletEffect` | 子弹碰撞时，随子弹携带 | BulletData |
| `TowerEffect` | 炮塔被子弹击中时 | Tower |

**Module** 是纯粹的生命周期管理器，持有 FireEffect / TowerEffect 列表，安装时自动装载到炮塔，不含任何触发逻辑。

---

## FireEffect

### 类定义

```gdscript
class_name FireEffect extends Resource

## 开火时自动 append 到 BulletData 的 BulletEffect
@export var bullet_effects: Array[BulletEffect] = []

## 开火时调用，修改 BulletData 参数，并自动挂载 bullet_effects
## 调用位置：tower.gd _do_fire()
## 子类若需修改属性（如 speed、attack），重写此方法并调用 super
func apply(_tower: Node, bd: BulletData) -> void:
    bd.effects.append_array(bullet_effects)
```

### 示例：属性修改型

```gdscript
class_name SpeedFireEffect extends FireEffect

@export var bonus: float = 150.0

func apply(tower: Node, bd: BulletData) -> void:
    super.apply(tower, bd)
    bd.speed += bonus
```

---

## BulletEffect

### 类定义

```gdscript
class_name BulletEffect extends Resource

## 子弹击中炮塔时触发（子弹侧）
## 调用位置：bullet.gd _on_hitbox_area_entered()
## 典型应用：补充弹药、对被击塔施加效果
func on_hit_tower(_bullet_data: BulletData, _tower: Node) -> void:
    pass

## 子弹击中敌人时触发
## 调用位置：enemy_manager.gd _on_enemy_hit()
## 触发时机：碰撞检测完成，回收子弹之前
func on_hit_enemy(_bullet_data: BulletData, _enemy: Node) -> void:
    pass

## 子弹造成伤害时触发
## 调用位置：enemy_manager.gd _on_enemy_hit()
## 触发时机：on_hit_enemy 之后，enemy.take_damage() 之前
func on_deal_damage(_bullet_data: BulletData, _target: Node, _damage: float) -> void:
    pass

## 敌人被击杀时触发
## 调用位置：enemy.gd take_damage()
## 触发时机：生命值 ≤ 0，destroy() 之前
func on_killed_enemy(_bullet_data: BulletData, _enemy: Node) -> void:
    pass
```

---

## TowerEffect

### 类定义

```gdscript
class_name TowerEffect extends Resource

## 炮塔被子弹击中时触发
## 调用位置：tower.gd on_bullet_hit()
## 触发时机：BulletEffect.on_hit_tower 之后
func on_receive_bullet_hit(_bullet_data: BulletData, _tower: Node) -> void:
    pass
```

### 未来可扩展的触发时机（待需求确认再实现）

```gdscript
func on_tower_spawned(_tower: Node) -> void: pass
func on_firing(_tower: Node) -> void: pass
```

---

## Module

### 类定义

```gdscript
class_name Module extends Resource

@export var module_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var slot_color: Color = Color(0.5, 0.5, 0.5)

## 安装到炮塔时，自动将 fire_effects / tower_effects 装载进去
@export var fire_effects: Array[FireEffect] = []
@export var tower_effects: Array[TowerEffect] = []

func on_install(tower: Node) -> void:
    tower.fire_effects.append_array(fire_effects)
    tower.tower_effects.append_array(tower_effects)

func on_uninstall(tower: Node) -> void:
    for e in fire_effects: tower.fire_effects.erase(e)
    for e in tower_effects: tower.tower_effects.erase(e)
```

**需要复杂逻辑时（条件判断、状态追踪等）才继承此类并重写 on_install / on_uninstall。**

---

## Tower 持有的列表

```gdscript
# tower.gd
var fire_effects: Array[FireEffect] = []
var tower_effects: Array[TowerEffect] = []

func _do_fire() -> void:
    var bd := BulletData.new()
    for fe in fire_effects:
        fe.apply(self, bd)
    BulletPool.spawn(bd, ...)

func on_bullet_hit(bullet_data: BulletData) -> void:
    play_hit_effect()
    for effect in bullet_data.effects:
        effect.on_hit_tower(bullet_data, self)
    for te in tower_effects:
        te.on_receive_bullet_hit(bullet_data, self)
```

---

## 触发流程

```
敌人路线：
  子弹击中敌人 → BulletEffect.on_hit_enemy()
      ↓
  BulletEffect.on_deal_damage()
      ↓
  enemy.take_damage()
      ↓（生命值 ≤ 0）
  BulletEffect.on_killed_enemy()

炮塔路线：
  子弹击中炮塔 → BulletEffect.on_hit_tower()    ← 子弹侧
      ↓
  tower.on_bullet_hit()
      ↓
  TowerEffect.on_receive_bullet_hit()             ← 炮塔侧
```

---

## 荆棘系统整合

荆棘作为被动防御塔，敌人接触时构造一个 BulletData 触发标准流程：

```gdscript
# thorns.gd（待实现）
func _on_enemy_contact(enemy: Node) -> void:
    var bd := BulletData.new()
    bd.attack = THORN_DAMAGE
    # 可附加任意 BulletEffect
    for effect in bd.effects:
        effect.on_hit_enemy(bd, enemy)
    for effect in bd.effects:
        effect.on_deal_damage(bd, enemy, bd.attack)
    enemy.take_damage(bd.attack, bd)
```

---

## 新建模块所需文件

| 场景 | 需要写代码？ | 文件数 |
|------|------------|--------|
| 调整已有 Effect 参数 | 否，Inspector 配置 | 1 .tres |
| 组合已有 Effect | 否 | 1 .tres |
| 新效果类型 | 是，1 个 .gd | 1 .gd + 1 .tres |
| 复杂状态逻辑 | 是，继承 Module | 1 .gd + 1 .tres |

---

## 术语对照表

| 术语 | 定义 | 所属类 | 触发时机 |
|------|------|--------|---------|
| **支援** | 子弹击中炮塔时对目标的效果 | BulletEffect | `on_hit_tower()` |
| **受支援** | 炮塔被击中时的反应 | TowerEffect | `on_receive_bullet_hit()` |
| **击中敌人** | 子弹击中敌人 | BulletEffect | `on_hit_enemy()` |
| **造成伤害** | 子弹对敌人施加伤害 | BulletEffect | `on_deal_damage()` |
| **击杀** | 敌人因此子弹死亡 | BulletEffect | `on_killed_enemy()` |
