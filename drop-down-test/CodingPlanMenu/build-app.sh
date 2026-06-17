#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$SCRIPT_DIR"
APP_NAME="CodingPlanMenu"
APP_DIR="$PROJECT/${APP_NAME}.app"

# 1. 编译
echo "Building..."
cd "$PROJECT"
swift build

# 2. 清理旧的 .app
rm -rf "$APP_DIR"

# 3. 创建 .app 结构
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 4. 复制二进制
cp ".build/debug/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# 5. 写入 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.CodingPlanMenu</string>
    <key>CFBundleName</key>
    <string>CodingPlanMenu</string>
    <key>CFBundleDisplayName</key>
    <string>CodingPlanMenu</string>
    <key>CFBundleExecutable</key>
    <string>CodingPlanMenu</string>
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

echo ""
echo "Done: $APP_DIR"
echo ""
echo "Usage:"
echo "  直接双击运行，或者拖到 /Applications"
echo "  退出时按 Cmd+Q 或点菜单中的「退出」"
