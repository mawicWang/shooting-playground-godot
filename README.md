# 🔫 Shooting Playground Godot

一个轻量级、响应式的 Godot 4.4 塔防游戏原型。项目展示了高级拖拽逻辑、网格对齐、实时旋转调整以及 Web 端高度适配。

![Godot Engine](https://img.shields.io/badge/Godot-4.4+-478CBF?logo=godot-engine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 功能亮点

- 🎮 **高级拖拽系统**: 支持从商店拖拽新炮塔或在网格间移动已有炮塔。
- 🔄 **动态旋转**: 在拖动过程中，通过鼠标偏移量实时控制炮塔的 4 方向（上/下/左/右）朝向。
- 📱 **全平台响应式**: 适配宽屏与移动端，通过动态计算实现最高 720px 的居中限制布局。
- 👾 **敌人波次预警**: 游戏开始前显示敌人即将入侵的位置警告图标。
- 🎨 **视觉反馈**: 拖拽时的可放置区域高亮（绿色/红色）、屏幕受击抖动以及 Zpix 中文像素字体支持。
- ⚡ **HTML5 导出**: 预置了完善的 Web 导出脚本和适配。

## 🕹️ 操作指南

| 动作 | 描述 |
| :--- | :--- |
| **部署炮塔** | 从底部商店拖拽图标到网格中 |
| **调整朝向** | 拖拽时移动鼠标位置（相对网格中心）以控制方向 |
| **移动炮塔** | 拖拽已部署在网格中的炮塔 |
| **删除炮塔** | 将网格中的炮塔拖拽到底部红色删除区 |
| **开始/停止** | 点击右上角按钮切换游戏状态 |

## 🏗️ 开发者指南

本项目旨在作为 Godot 塔防游戏开发的一个模版。如果您对实现逻辑感兴趣，请参考：

👉 **[开发者文档 (DEVELOPER.md)](./doc/DEVELOPER.md)**

涵盖了：
- 系统架构与模块职责
- 拖拽与旋转的核心算法 (带 Mermaid 图表)
- 响应式布局的代码实现
- 信号传递与游戏循环逻辑

## 🚀 快速开始

1. **环境准备**: 下载并安装 [Godot Engine 4.4+](https://godotengine.org/)。
2. **克隆项目**:
   ```bash
   git clone https://github.com/[your-repo]/shooting-playground-godot.git
   ```
3. **运行**: 在 Godot 编辑器中打开 `project.godot`，按 **F5** 运行。

## 📦 导出至 Web

项目提供了一个便利的导出脚本 `build_web.sh`：

1. 确保已在 Godot 中配置好 Web 导出模板。
2. 运行脚本：`./build_web.sh`
3. 使用本地服务器预览：
   ```bash
   python3 -m http.server 8000 --directory web
   ```
4. 访问 `http://localhost:8000`。

## 📜 开源协议

本项目基于 MIT 协议开源。
字体资源来自 [Zpix](https://github.com/SolidZORO/zpix-pixel-font) 开源像素字体。
