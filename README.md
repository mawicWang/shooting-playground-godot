# shooting-playground-godot

一个简单的 Godot 射击练习游戏原型，使用 5x5 网格布局。

## 项目结构

```
shooting-playground-godot/
├── main.tscn          # 主场景（包含 GridRoot 和 GridContainer）
├── grid_manager.gd    # 网格管理器脚本（处理单元格创建和点击交互）
├── project.godot      # Godot 项目配置
├── icon.svg          # 项目图标
└── README.md         # 本文件
```

## 功能特性

- ✅ 5x5 (25个) 单元格网格
- ✅ 网格居中显示，上下留空间放其他 UI
  - 顶部留 15%（标题/计分）
  - 底部留 15%（控制按钮）
  - 左右各留 10% 边距
- ✅ 点击单元格显示红色击中效果，0.2秒后恢复灰色
- ✅ 响应式布局，适配各种屏幕尺寸
- ✅ 单元格带边框
- ✅ 支持触摸屏（手机）
- ✅ 可导出为 HTML5 (WebAssembly)

## 运行方法

### 在 Godot 编辑器中（开发测试）
1. 使用 Godot 4.4 打开项目文件夹
2. 按 **F6** 运行项目
3. 点击任意单元格查看交互效果
4. 为了测试手机布局，可调整运行窗口大小为竖屏（如 720×1280）

### 导出为 HTML5 并在浏览器中运行

#### 1. 导出项目
1. 在 Godot 编辑器中选择 **项目 → 导出**
2. 添加 **Web** 平台（如果尚未添加）
3. 配置导出路径（例如 `web/index.html` 或 `web_build/index.html`）
4. 点击 **导出项目**

#### 2. 通过 HTTP 服务器运行（重要！）
**不要直接双击打开 `index.html`**，这会因为 CORS 策略导致 `.wasm` 和 `.pck` 文件无法加载。

正确做法是使用本地 HTTP 服务器：

**方法 A：使用提供的脚本**（如果你在 `web/` 目录导出）
```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot/web
./serve.sh
```
然后访问 `http://localhost:8000`

**方法 B：使用 Python**
```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot/web
python3 -m http.server 8000
```
然后访问 `http://localhost:8000`

**方法 C：使用 Node.js**
```bash
cd /Users/wangyiwen/Projects/shooting-playground-godot/web
npx serve .
```

#### 3. 手机测试（可选）
- 确保手机和电脑在同一网络
- 使用 `python3 -m http.server 0.0.0.0:8000` 监听所有网络接口
- 在手机浏览器访问 `http://你的电脑IP:8000`

### 部署到 Web 服务器
将整个导出文件夹（包含 `index.html`、`.wasm`、`.pck` 等文件）上传到任何 Web 服务器（如 GitHub Pages、Netlify、Vercel 或自己的服务器）即可。

## 技术说明

- 使用 **GridContainer** 进行网格布局
- 每个单元格是 **ColorRect** 控件
- 通过脚本动态生成 25 个单元格
- **锚点系统**实现响应式布局：
  - grid.anchor_left = 0.1, grid.anchor_right = 0.9（左右各 10% 边距）
  - grid.anchor_top = 0.15, grid.anchor_bottom = 0.85（上下各 15% 空间）
  - 网格占比：80% × 70%，始终居中
- 避免在 `_ready()` 中直接设置控件大小（Godot 锚点警告）
- 单元格使用 **StyleBoxFlat** 边框，点击时同步更新 `ColorRect.color` 和 `StyleBox.bg_color`
- 支持 **鼠标点击** 和 **触摸屏输入**（Godot 自动映射）
- 单元格尺寸 80×80 像素，适合手机触摸
- 显示模式：`canvas_items`（适合 HTML5 导出）

## HTML5 注意事项

- ❌ 不要使用 `file://` 协议打开（会触发 CORS 错误）
- ✅ 必须通过 HTTP/HTTPS 服务器访问
- ✅ 浏览器开发者工具按 F12 查看控制台，确保没有 404 错误

## 修改历史

**2026-03-22 15:00**: HTML5 导出和服务器运行指南
- 添加详细的 HTTP 服务器运行步骤
- 包含 Python、Node.js 和 serve.sh 脚本的使用方法
- 说明 CORS 问题的原因和解决方案
- 添加手机测试和部署说明
