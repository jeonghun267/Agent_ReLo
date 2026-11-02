@echo off
REM ReLo 2.0.0 Flutter App Launcher
REM Auto-configures FLUTTER_ROOT, PUB_CACHE, and Git safe.directory for this PC
set FLUTTER_ROOT=C:\flutter
set PUB_CACHE=C:\Users\admin_34\AppData\Local\Pub\Cache
set GIT_CONFIG_COUNT=1
set GIT_CONFIG_KEY_0=safe.directory
set GIT_CONFIG_VALUE_0=*

cd /d "%~dp0"
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" --suppress-analytics pub get --offline
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\bin\cache\flutter_tools.snapshot" run --no-pub --no-version-check --suppress-analytics %*
