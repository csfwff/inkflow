@echo off
set HOOK_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\sqlite3-3.3.2\hook\build.dart
if not exist "tool\sqlite3_hook_patch\build.dart" (
    echo Error: tool\sqlite3_hook_patch\build.dart not found
    exit /b 1
)
copy /Y "tool\sqlite3_hook_patch\build.dart" "%HOOK_PATH%"
echo sqlite3 hook patch applied to: %HOOK_PATH%
