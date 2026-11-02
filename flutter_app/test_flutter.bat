@echo off
REM ReLo 2.0.0 Flutter Analyzer and 390px Widget Test Runner
REM Auto-configures FLUTTER_ROOT, PUB_CACHE, and Git safe.directory for this PC
set FLUTTER_ROOT=C:\flutter
set PUB_CACHE=C:\Users\admin_34\AppData\Local\Pub\Cache
set GIT_CONFIG_COUNT=1
set GIT_CONFIG_KEY_0=safe.directory
set GIT_CONFIG_VALUE_0=*

cd /d "%~dp0"
echo [1/3] Verifying offline Pub packages...
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" --suppress-analytics pub get --offline
if errorlevel 1 exit /b 1

echo [2/3] Running Dart static analyzer (dart analyze)...
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" --suppress-analytics analyze
if errorlevel 1 exit /b 1

echo [3/3] Running Flutter 390px viewport widget tests (flutter test)...
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\bin\cache\flutter_tools.snapshot" test --no-pub --no-version-check --suppress-analytics
