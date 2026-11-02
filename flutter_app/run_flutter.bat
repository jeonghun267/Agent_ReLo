@echo off
REM ReLo 2.0.0 Flutter App Launcher
cd /d "%~dp0"

where flutter >nul 2>nul
if %errorlevel% equ 0 goto USE_SYSTEM_FLUTTER
if exist "C:\flutter\bin\cache\dart-sdk\bin\dart.exe" goto USE_LOCAL_FLUTTER
goto NO_FLUTTER

:USE_SYSTEM_FLUTTER
echo [Info] Standard Flutter detected in PATH.
call flutter pub get
call flutter run %*
exit /b %errorlevel%

:USE_LOCAL_FLUTTER
set FLUTTER_ROOT=C:\flutter
if exist "C:\Users\admin_34\AppData\Local\Pub\Cache" set PUB_CACHE=C:\Users\admin_34\AppData\Local\Pub\Cache
set GIT_CONFIG_COUNT=1
set GIT_CONFIG_KEY_0=safe.directory
set GIT_CONFIG_VALUE_0=*

"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" --suppress-analytics pub get --offline
"C:\flutter\bin\cache\dart-sdk\bin\dart.exe" "C:\flutter\bin\cache\flutter_tools.snapshot" run --no-pub --no-version-check --suppress-analytics %*
exit /b %errorlevel%

:NO_FLUTTER
echo [Error] Flutter SDK not found. Please install Flutter or add it to PATH.
echo See: https://docs.flutter.dev/get-started/install
exit /b 1
