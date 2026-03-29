#!/bin/bash

# deploy.sh - 部署 Godot Web 游戏到云
# 用法:
#   ./deploy.sh                          # 打包 + 部署到 Cloudflare（默认）
#   ./deploy.sh cloudflare               # 同上
#   ./deploy.sh cloudflare --r2          # 同上，且先上传 wasm 到 R2
#   ./deploy.sh netlify                  # 打包 + 部署到 Netlify
#   ./deploy.sh [target] [--r2] --dry-run  # 仅打印将要执行的命令，不实际运行

set -e

TARGET=""
UPLOAD_R2=false
DRY_RUN=false
DEPLOY_ITCH=true

for arg in "$@"; do
  case "$arg" in
    --r2)           UPLOAD_R2=true ;;
    --dry-run)      DRY_RUN=true ;;
    --no-itch)      DEPLOY_ITCH=false ;;
    cloudflare|netlify) TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-cloudflare}"

# dry-run 模式下只打印命令，不执行
run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

if [[ "$DRY_RUN" == true ]]; then
  echo "🔍 [dry-run] 模式：仅打印命令，不实际执行"
  echo ""
fi

# 1. 打包
echo "📦 [Deploy] 打包 Web 版本..."
run ./build_web.sh
echo ""

# 2. 部署
if [[ "$TARGET" == "netlify" ]]; then
    DEPLOY_MESSAGE=$(git log -1 --pretty=%B 2>/dev/null || echo "Deploy $(date '+%Y-%m-%d %H:%M:%S')")
    echo "🌍 [Deploy] 部署到 Netlify..."
    DEPLOY_DIR=$(mktemp -d)
    run rsync -a --exclude='index.wasm' --exclude='.netlify' web/ "$DEPLOY_DIR/"
    run netlify deploy --prod --dir="$DEPLOY_DIR" --site=5a5e44e4-8bd4-405f-bf3d-8a7102b197e9 --message="$DEPLOY_MESSAGE"
    rm -rf "$DEPLOY_DIR"
    echo "✅ [Deploy] Netlify 部署完成!"
    echo "🎮 游戏地址: https://ruchu-heinemann-english.cloud"

elif [[ "$TARGET" == "cloudflare" ]]; then
    if [[ "$UPLOAD_R2" == true ]]; then
        echo "📦 [R2] 上传 index.wasm 到 R2..."
        run wrangler r2 object put shooting-playground-godot/index.wasm \
            --file web/index.wasm \
            --content-type application/wasm
        echo "✅ [R2] 上传完成!"
        echo ""
    fi
    echo "☁️  [Deploy] 部署到 Cloudflare Pages..."
    CF_DEPLOY_DIR=$(mktemp -d)
    run rsync -a --exclude='index.wasm' --exclude='_redirects' web/ "$CF_DEPLOY_DIR/"
    run wrangler pages deploy "$CF_DEPLOY_DIR" \
        --project-name shooting-playground-godot \
        --commit-dirty=true \
        --commit-message="deploy"
    rm -rf "$CF_DEPLOY_DIR"
    echo "✅ [Deploy] Cloudflare 部署完成!"

else
    echo "❌ 未知目标: $TARGET"
    echo "用法: $0 [cloudflare|netlify] [--r2] [--no-itch] [--dry-run]"
    exit 1
fi

# itch.io 部署
if [[ "$DEPLOY_ITCH" == true ]]; then
    BUTLER="${HOME}/.local/bin/butler-darwin-arm64/butler"
    if [[ ! -x "$BUTLER" ]]; then
        echo "⚠️  [itch] 未找到 butler，跳过 itch.io 部署 ($BUTLER)"
    else
        echo ""
        echo "🎮 [Deploy] 推送到 itch.io..."
        run "$BUTLER" push web/ mawicwang/pow-pow-defence:html5
        echo "✅ [Deploy] itch.io 部署完成!"
        echo "🎮 游戏地址: https://mawicwang.itch.io/pow-pow-defence"
    fi
fi
