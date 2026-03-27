#!/bin/bash

# build_web.sh - Godot Web 构建脚本

set -e

echo "🚀 [Build] 开始 Godot Web 构建..."

# 检查 Godot
if ! command -v godot > /dev/null 2>&1; then
    echo "❌ [Build] 错误: 未找到 godot 命令"
    exit 1
fi

# 导入项目
echo "📦 [Build] 导入项目资源..."
godot --headless --import --quit

# 构建 Web 版本
echo "🌐 [Build] 导出 Web 版本..."
godot --headless --export-release "Web" web/index.html

echo "✅ [Build] Web 构建完成!"
echo "📁 [Build] 输出: web/index.html"
