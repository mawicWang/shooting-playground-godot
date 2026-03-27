#!/bin/bash

# install_hooks.sh - 安装 Git hooks

echo "🔧 [Install] 安装 Git hooks..."

PROJECT_ROOT=$(dirname "$0")
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# 复制 pre-push hook
cp "$PROJECT_ROOT/hooks/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "✅ [Install] pre-push hook 安装完成"
echo "💡 [Install] 每次 push 前会自动运行 Web 构建"
echo "💡 [Install] 如需跳过，使用: git push --no-verify"
