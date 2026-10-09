#!/bin/sh
# 应用 sqlite3 native hook 补丁（macOS / Linux）
set -e

PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache}"
HOOK_PATH=$(ls -d "$PUB_CACHE"/hosted/pub.dev/sqlite3-*/hook/build.dart 2>/dev/null | head -n 1)

if [ -z "$HOOK_PATH" ]; then
    echo "Error: sqlite3 hook not found under $PUB_CACHE (请先运行 flutter pub get)" >&2
    exit 1
fi

cp -f tool/sqlite3_hook_patch/build.dart "$HOOK_PATH"
echo "sqlite3 hook patch applied to: $HOOK_PATH"

# 清掉 hook 的编译缓存，否则下一次构建可能继续使用旧的 hook.dill
rm -rf .dart_tool/hooks_runner/sqlite3
echo "cleared stale hook cache: .dart_tool/hooks_runner/sqlite3"
