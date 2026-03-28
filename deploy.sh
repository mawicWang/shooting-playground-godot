#!/bin/bash

# deploy.sh - 部署 Godot Web 游戏到 Netlify + R2
# 用法: ./deploy.sh ["自定义部署消息"] [--upload-r2]
#
# 默认行为:
#   - 构建项目
#   - 复制到临时目录（自动排除 WASM）
#   - 部署到 Netlify（WASM 走 R2 代理）
#
# 可选参数:
#   --upload-r2    上传 WASM 到 R2（更新 CDN 文件）

set -e

echo "🚀 [Deploy] 开始部署..."

# 解析参数
UPLOAD_R2=false
DEPLOY_MESSAGE=""

for arg in "$@"; do
    if [ "$arg" = "--upload-r2" ]; then
        UPLOAD_R2=true
    elif [ -z "$DEPLOY_MESSAGE" ]; then
        DEPLOY_MESSAGE="$arg"
    fi
done

# 获取默认部署消息
if [ -z "$DEPLOY_MESSAGE" ]; then
    DEPLOY_MESSAGE=$(git log -1 --pretty=%B 2>/dev/null || echo "Deploy $(date '+%Y-%m-%d %H:%M:%S')")
fi

echo "📝 [Deploy] 部署消息: $DEPLOY_MESSAGE"

# 1. 构建 Web 版本
echo "📦 [Deploy] 构建 Web 版本..."
./build_web.sh

# 2. 确保 _redirects 存在
echo "📝 [Deploy] 检查 _redirects..."
if [ ! -f "web/_redirects" ]; then
    echo '# Proxy WASM requests to R2 to avoid CORS
/index.wasm https://pub-5da216c5c1864a1ba66ebc98a09e46ff.r2.dev/index.wasm 200
' > web/_redirects
    echo "✅ [Deploy] 已创建 _redirects"
fi

# 3. 可选：上传 WASM 到 R2
if [ "$UPLOAD_R2" = true ]; then
    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        echo "❌ [Deploy] 错误: CLOUDFLARE_API_TOKEN 未设置"
        exit 1
    fi
    echo "☁️  [Deploy] 上传 WASM 到 R2..."
    wrangler r2 object put shooting-playground-godot/index.wasm \
        --file=web/index.wasm \
        --remote
    echo "✅ [Deploy] WASM 已上传到 R2"
fi

# 4. 创建临时部署目录（排除 WASM）
echo "📁 [Deploy] 创建临时部署目录..."
DEPLOY_DIR=$(mktemp -d)
rsync -a --exclude='index.wasm' --exclude='.netlify' web/ "$DEPLOY_DIR/"
echo "✅ [Deploy] 已复制到临时目录（排除 WASM）"

# 5. 部署到 Netlify
echo "🌐 [Deploy] 部署到 Netlify..."
netlify deploy --prod --dir="$DEPLOY_DIR" --site=5a5e44e4-8bd4-405f-bf3d-8a7102b197e9 --message="$DEPLOY_MESSAGE"

# 6. 清理临时目录
rm -rf "$DEPLOY_DIR"

echo "✅ [Deploy] 部署完成!"
echo "🎮 游戏地址: https://ruchu-heinemann-english.cloud"
