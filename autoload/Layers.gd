## Layers — 全局碰撞层/遮罩常量
## bitmask 值 = 2^(层编号 - 1)，与 Godot 编辑器中的 Layer 编号对应：
##   Layer 1 = 1, Layer 2 = 2, Layer 3 = 4, Layer 4 = 8, Layer 5 = 16, Layer 6 = 32, Layer 8 = 128
extends Node

const TOWER_CLICK: int = 1    ## 第1层：炮塔 Area2D — 鼠标点击旋转检测
const ENEMY: int = 2          ## 第2层：敌人 Hitbox（Area2D）
const BULLET: int = 4         ## 第3层：子弹 Hitbox（Area2D）
const DEAD_ZONE: int = 8      ## 第4层：死亡区域（Area2D）
const GRID_BORDER: int = 16   ## 第5层：网格边界 Hitbox（Area2D）
const TOWER_BODY: int = 32    ## 第6层：炮塔实体 Hitbox — 供子弹碰撞检测用
const AIR_TOWER_BODY: int = 64  ## 第7层：飞行炮塔实体 Hitbox — FlyingModule 使用
