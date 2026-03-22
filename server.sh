#!/bin/bash
# 启动本地服务器运行 Godot HTML5 导出的游戏

cd "$(dirname "$0")/web"
PORT=8888

echo "🚀 启动本地服务器..."
echo "📁 服务目录: $(pwd)"
echo "🌐 访问地址: http://localhost:$PORT"
echo "按 Ctrl+C 停止服务器"
echo ""

# 检查是否有 Python 3
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
# 否则尝试 Python 2
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT
# 否则尝试 Node.js
elif command -v npx &> /dev/null; then
    npx serve -l $PORT .
else
    echo "❌ 未找到 Python 或 Node.js，请安装其中一个后重试"
    exit 1
fi
