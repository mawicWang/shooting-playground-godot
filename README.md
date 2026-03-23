# shooting-playground-godot

一个 Godot 塔防游戏原型，支持拖拽部署炮塔、射击子弹、响应式布局。

## 功能特性

- ✅ 5x5 网格布局，支持拖拽放置炮塔
- ✅ 拖拽旋转：拖拽时移动鼠标可调整炮塔朝向（上/下/左/右）
- ✅ 游戏控制：开始/停止按钮控制炮塔射击
- ✅ 死亡区域：子弹飞出屏幕后自动销毁
- ✅ 响应式布局：
  - 屏幕宽度 > 600px：游戏居中，左右深灰色边距
  - 屏幕宽度 ≤ 600px：游戏占满宽度
- ✅ 中文像素字体（Zpix）
- ✅ HTML5 导出支持

## 操作说明

| 操作 | 说明 |
|------|------|
| 拖拽商店图标 | 从底部拖拽炮塔到网格 |
| 拖拽网格炮塔 | 移动已部署的炮塔位置 |
| 拖拽时移动鼠标 | 调整炮塔发射方向 |
| 点击开始/停止 | 控制游戏运行状态 |
| 拖拽到删除区 | 移除炮塔 |

## 项目结构

```
shooting-playground-godot/
├── main.tscn              # 主场景
├── main.gd                # 主控制器（游戏状态、限宽布局）
├── grid_manager.gd        # 网格管理器
├── cell.gd                # 单元格逻辑（拖拽、放置）
├── tower.gd               # 炮塔逻辑（发射子弹）
├── bullet.gd              # 子弹逻辑
├── tower_icon.gd          # 商店图标（拖拽生成）
├── DragManager.gd         # 全局拖拽管理器（单例）
├── dead_zone_manager.gd   # 死亡区域管理器
├── removal_zone.gd        # 删除区域
├── assets/
│   ├── zpix.ttf          # 中文像素字体
│   ├── tower1.svg        # 炮塔图标
│   └── bullet.svg        # 子弹图标
├── default_theme.tres     # 默认主题（字体设置）
└── web/                   # HTML5 导出文件
    └── index.html
```

## 运行方法

### Godot 编辑器
1. 使用 Godot 4.4+ 打开项目
2. 按 **F5** 运行

### HTML5 导出
1. **导出**：项目 → 导出 → Web → 导出项目到 `web/` 文件夹
2. **运行服务器**：
   ```bash
   cd web
   python3 -m http.server 8000
   ```
3. **访问**：浏览器打开 `http://localhost:8000`

## 技术说明

### 布局系统
- 根节点 `main` 为 `Control` 类型，全屏显示
- `Background` 节点：深灰色背景（`#1a1a1a`）
- `GameContent` 节点：白色游戏区域，最大宽度 600px，自动居中
- 通过 `_on_window_resize()` 动态计算大小和位置

### 拖拽系统
- `DragManager` 单例管理全局拖拽状态
- 支持从商店拖拽新炮塔
- 支持在网格间移动已有炮塔
- 拖拽时实时计算鼠标相对位置，确定炮塔朝向

### 字体
- 使用 [Zpix](https://github.com/SolidZORO/zpix-pixel-font) 开源中文像素字体
- 通过 `default_theme.tres` 设置为项目默认字体

### Godot 项目设置
```
[display]
window/stretch/mode = "canvas_items"
window/stretch/aspect = "expand"
window/size/viewport_width = 720
window/size/viewport_height = 1280

[gui]
theme/custom = "res://default_theme.tres"
```

## HTML5 适配

CSS 关键设置（`web/index.html`）：
```css
html, body, #canvas {
    width: 100%;
    height: 100%;
    margin: 0;
    background-color: #1a1a1a;
}
```

Godot 配置：
```javascript
"canvasResizePolicy": 2  // 让 Godot 自动适配父容器
```

## 注意事项

- ❌ 不要直接用 `file://` 打开 HTML（CORS 错误）
- ✅ 必须使用 HTTP 服务器运行
- ✅ 浏览器需要支持 WebGL

## 开源资源

- 字体：[Zpix](https://github.com/SolidZORO/zpix-pixel-font) - 开源中文像素字体

## 修改历史

**2026-03-23**: 完整游戏功能
- 添加拖拽部署和旋转系统
- 添加开始/停止游戏控制
- 添加死亡区域和子弹清理
- 添加响应式布局（最大宽度 600px）
- 添加中文像素字体
- 优化 HTML5 导出体验

**2026-03-22**: 初始版本
- 基础网格布局
- HTML5 导出支持
