#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="QuotaBar"

# 每次构建生成以时间命名的子文件夹，保留历史版本便于验证
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BUILD_DIR="$PROJECT/build/$TIMESTAMP"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
LATEST_LINK="$PROJECT/build/latest"

echo "Building $APP_NAME into $BUILD_DIR..."

# 1. 编译
cd "$PROJECT"
export CLANG_MODULE_CACHE_PATH="$PROJECT/.build/clang-module-cache"
export SWIFT_MODULE_CACHE_PATH="$PROJECT/.build/swift-module-cache"
swift build --disable-sandbox

# 2. 创建本次构建目录
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 3. 复制二进制（SwiftPM 6 输出到 arch-specific 路径，用 --show-bin-path 动态拿）
BIN_PATH="$(swift build --disable-sandbox --show-bin-path)/QuotaBar"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/QuotaBar"

# 4. 写入 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.taobe.quotabar</string>
    <key>CFBundleName</key>
    <string>QuotaBar</string>
    <key>CFBundleDisplayName</key>
    <string>Quota Bar</string>
    <key>CFBundleExecutable</key>
    <string>QuotaBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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

# 6. 更新 latest 软链到本次构建
rm -f "$LATEST_LINK"
ln -s "$BUILD_DIR" "$LATEST_LINK"

echo ""
echo "✅ Build complete: $APP_DIR"
echo ""
echo "Usage:"
echo "  直接双击运行，或者拖到 /Applications"
echo "  最新版本快捷入口: $LATEST_LINK/${APP_NAME}.app"
echo "  退出时按 Cmd+Q 或点菜单中的「退出」"
echo ""
echo "History builds are kept under: $PROJECT/build/"
