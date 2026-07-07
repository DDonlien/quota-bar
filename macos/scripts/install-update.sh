#!/bin/bash
# Quota Bar 更新助手（v0.11.0-TOOL-A，ad-hoc 预开发版）。
#
# 用法：install-update.sh [--dry-run] <path-to-dmg>
#
# 流程：
#   1. 等主进程 QuotaBar 退出（超时 5s 后 pkill 强杀）；
#   2. 挂载 dmg；
#   3. codesign --verify 校验 dmg 内 .app（ad-hoc 阶段跳过 spctl —— ad-hoc 永远被
#      spctl 拒绝，跳过不视为不通过；v0.12.0 升级 Developer ID 后强制加 spctl）；
#   4. 替换 /Applications/Quota Bar.app（先备份，失败回滚）；
#   5. 卸载 dmg，重新拉起新版 app。
#
# 失败时保留旧 .app，把原因写入
# ~/Library/Application Support/QuotaBar/update-error.log，
# 主 app 下次启动时会检测该文件并提示「上次更新失败」。
set -u

APP_NAME="Quota Bar"
PROCESS_NAME="QuotaBar"
DEST="/Applications/${APP_NAME}.app"
SUPPORT_DIR="$HOME/Library/Application Support/QuotaBar"
ERROR_LOG="$SUPPORT_DIR/update-error.log"
DRY_RUN=0

log() { echo "[install-update] $*"; }

fail() {
    local reason="$1"
    log "FAILED: $reason"
    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$SUPPORT_DIR"
        printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$reason" >> "$ERROR_LOG"
        # 失败也要尝试把旧版拉起来，避免用户面对"应用消失"。
        if [ -d "$DEST" ]; then
            open "$DEST" || true
        fi
    fi
    exit 1
}

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=1
    shift
fi

DMG_PATH="${1:-}"
[ -n "$DMG_PATH" ] || { echo "usage: install-update.sh [--dry-run] <path-to-dmg>"; exit 64; }
[ -f "$DMG_PATH" ] || fail "dmg 不存在: $DMG_PATH"

if [ "$DRY_RUN" -eq 1 ]; then
    log "(dry-run) 将执行:"
    log "(dry-run) 1. 等待/结束进程 $PROCESS_NAME"
    log "(dry-run) 2. hdiutil attach '$DMG_PATH'"
    log "(dry-run) 3. codesign --verify dmg 内 ${APP_NAME}.app"
    log "(dry-run) 4. 替换 $DEST（旧版备份为 ${DEST}.previous）"
    log "(dry-run) 5. hdiutil detach + open '$DEST'"
    exit 0
fi

# 1. 等主进程退出（v0.11.0-TOOL-A-003）
log "waiting for $PROCESS_NAME to exit..."
WAITED=0
while pgrep -x "$PROCESS_NAME" > /dev/null 2>&1; do
    if [ "$WAITED" -ge 5 ]; then
        log "timeout, force killing $PROCESS_NAME"
        pkill -x "$PROCESS_NAME" || true
        sleep 1
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

# 2. 挂载 dmg
MOUNT_OUTPUT="$(hdiutil attach -nobrowse -readonly "$DMG_PATH" 2>&1)" \
    || fail "dmg 挂载失败: $MOUNT_OUTPUT"
MOUNT_POINT="$(echo "$MOUNT_OUTPUT" | grep -oE '/Volumes/.*' | tail -1)"
[ -n "$MOUNT_POINT" ] || fail "无法确定 dmg 挂载点"

cleanup_mount() { hdiutil detach "$MOUNT_POINT" -quiet || true; }

SRC_APP="$MOUNT_POINT/${APP_NAME}.app"
if [ ! -d "$SRC_APP" ]; then
    cleanup_mount
    fail "dmg 内未找到 ${APP_NAME}.app"
fi

# 3. 签名校验（v0.11.0-TOOL-A-001：ad-hoc 阶段只跑 codesign --verify，跳过 spctl）
if ! codesign --verify --verbose=2 "$SRC_APP" 2>&1; then
    cleanup_mount
    fail "dmg 内 .app 签名校验失败"
fi

# 4. 替换（先备份旧版，任何一步失败都回滚）
BACKUP=""
if [ -d "$DEST" ]; then
    BACKUP="${DEST}.previous"
    rm -rf "$BACKUP"
    if ! mv "$DEST" "$BACKUP"; then
        cleanup_mount
        fail "无法备份旧版 $DEST"
    fi
fi

if ! cp -R "$SRC_APP" "$DEST"; then
    # 回滚
    rm -rf "$DEST"
    [ -n "$BACKUP" ] && mv "$BACKUP" "$DEST"
    cleanup_mount
    fail "复制新版到 $DEST 失败（磁盘空间/权限？），已回滚旧版"
fi

rm -rf "$BACKUP"

# 5. 卸载 + 重启
cleanup_mount
log "update installed, relaunching..."
open "$DEST" || fail "新版启动失败"
log "done"
exit 0
