#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXECUTABLE_NAME="QuotaBar"
APP_NAME="Quota Bar"
ICON_NAME="QuotaBar.icns"

# 2026-07-07 改版：不再区分"nightly/stable 两条通道"。每一次构建（本地或 CI）
# 都带一个真实版本号：`<VERSION 文件内容>-<git short sha>`，写入
# CFBundleShortVersionString。`VERSION` 文件里的 X.Y.Z 由 Agent 维护，见
# AGENTS.md「版本号维护规则」；UpdateChecker 只按这个 X.Y.Z 比大小，完全不看
# sha、也不看发布/构建时间——同一个 X.Y.Z 重复打包不会被误判成"有更新"。
VERSION_FILE="$PROJECT/../VERSION"
if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: 找不到 VERSION 文件（预期路径: $VERSION_FILE）" >&2
    exit 1
fi
BASE_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
if ! echo "$BASE_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: VERSION 文件内容必须是 X.Y.Z 形式（收到: '$BASE_VERSION'）" >&2
    exit 1
fi
GIT_SHORT_SHA="$(cd "$PROJECT/.." && git rev-parse --short HEAD 2>/dev/null || echo unknown)"
SHORT_VERSION="${BASE_VERSION}-${GIT_SHORT_SHA}"

# 每次构建生成 `YYYYMMDD-HHMMSS-<branch>` 命名的子文件夹，保留历史版本便于验证。
# branch 段来自当前 Git 分支；detached HEAD 时 fallback 到 detached-<short-sha>。
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BRANCH="$(cd "$PROJECT/.." && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
    SHORT_SHA="$(cd "$PROJECT/.." && git rev-parse --short HEAD 2>/dev/null || echo unknown)"
    BRANCH="detached-$SHORT_SHA"
fi
BRANCH_SAFE="$(echo "$BRANCH" | tr '/' '-')"
BUNDLE_VERSION="$(date -u +%y%m%d.%H%M%S)"
DISPLAY_BUILD="${BUNDLE_VERSION}.${BRANCH_SAFE}"
BUILD_DIR="$PROJECT/build/${TIMESTAMP}-${BRANCH_SAFE}"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
BUILD_ROOT="$PROJECT/build"
LATEST_LINK="$BUILD_ROOT/latest"

echo "Building $APP_NAME into $BUILD_DIR (branch: $BRANCH)..."

# 1. 编译
cd "$PROJECT"
export CLANG_MODULE_CACHE_PATH="$PROJECT/.build/clang-module-cache"
export SWIFT_MODULE_CACHE_PATH="$PROJECT/.build/swift-module-cache"
swift build --disable-sandbox

# 2. 创建本次构建目录
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 3. 复制二进制（SwiftPM 6 输出到 arch-specific 路径，用 --show-bin-path 动态拿）
BIN_PATH="$(swift build --disable-sandbox --show-bin-path)/$EXECUTABLE_NAME"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"
cp "$PROJECT/Resources/$ICON_NAME" "$APP_DIR/Contents/Resources/$ICON_NAME"
# 更新助手（v0.11.0-TOOL-A-002）：随包分发，UpdateChecker 通过
# Bundle.main.url(forResource:) 定位并在安装更新时调用。
cp "$SCRIPT_DIR/install-update.sh" "$APP_DIR/Contents/Resources/install-update.sh"
chmod +x "$APP_DIR/Contents/Resources/install-update.sh"

# 4. 写入 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.taobe.quotabar</string>
    <key>CFBundleName</key>
    <string>Quota Bar</string>
    <key>CFBundleDisplayName</key>
    <string>Quota Bar</string>
    <key>CFBundleExecutable</key>
    <string>QuotaBar</string>
    <key>CFBundleIconFile</key>
    <string>QuotaBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$SHORT_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUNDLE_VERSION</string>
    <key>QBDisplayBuild</key>
    <string>$DISPLAY_BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>26.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

# 5. 用稳定 identifier 重签名
# Swift toolchain 默认的 ad-hoc 签名 identifier 是 CodingPlanMenu-<hash>，
# 每次 build hash 都会变，导致 macOS keychain 的"始终允许"失效（被当成另一个 app）。
# 用固定的 identifier 重签一次，让 macOS 始终认它是同一个 app。
echo "Signing with stable identifier..."
codesign --force --deep --sign - --identifier com.taobe.quotabar "$APP_DIR"

# 6. 更新 latest 软链到本次构建；使用相对路径，避免本机绝对路径污染 Git 状态。
LATEST_TARGET="$(basename "$BUILD_DIR")"
rm -f "$LATEST_LINK"
ln -s "$LATEST_TARGET" "$LATEST_LINK"

echo ""
echo "✅ Build complete: $APP_DIR"
echo ""
echo "Usage:"
echo "  直接双击运行，或者拖到 /Applications"
echo "  最新版本快捷入口: $LATEST_LINK/${APP_NAME}.app"
echo "  退出时按 Cmd+Q 或点菜单中的「退出」"
echo ""
echo "History builds are kept under: $PROJECT/build/"
