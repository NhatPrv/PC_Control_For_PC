@echo off
echo ====================================================================
echo BUILDING PC CONTROL ALL-IN-ONE (WINDOWS SETUP .EXE AND ANDROID .APK)
echo ====================================================================

echo 1/3. Fetching dependencies and building Flutter Windows Executable...
cd ..\mobile_app
call flutter clean
call flutter pub get
call flutter build windows --release

echo.
echo 2/3. Building Flutter Android Release APK...
call flutter build apk --release

echo.
echo 3/3. Compiling Inno Setup Windows Installer...
cd ..\installer

if not exist "Output" mkdir "Output"
if not exist "..\cloud_server\static\downloads" mkdir "..\cloud_server\static\downloads"

echo Copying Android APK to installer/Output/ and cloud_server/static/downloads/ ...
copy /Y "..\mobile_app\build\app\outputs\flutter-apk\app-release.apk" "Output\PC_Control_v1.0.0.apk"
copy /Y "..\mobile_app\build\app\outputs\flutter-apk\app-release.apk" "..\cloud_server\static\downloads\PC_Control_v1.0.0.apk"

set ISCC_PATH=""

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set ISCC_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set ISCC_PATH="C:\Program Files\Inno Setup 6\ISCC.exe"
) else if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" (
    set ISCC_PATH="%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
)

if not %ISCC_PATH%=="" (
    echo Found Inno Setup Compiler at %ISCC_PATH%
    %ISCC_PATH% setup_script.iss
    echo Copying Windows Setup.exe to cloud_server/static/downloads/ ...
    copy /Y "Output\PC_Control_Setup_v1.0.0.exe" "..\cloud_server\static\downloads\PC_Control_Setup_v1.0.0.exe"
) else (
    echo [!] Inno Setup 6 compiler ISCC.exe not found. Please verify installation.
)

echo ====================================================================
echo SUCCESS! All release packages generated in installer/Output/
echo 📱 Android App: installer/Output/PC_Control_v1.0.0.apk
echo 💻 Windows Setup: installer/Output/PC_Control_Setup_v1.0.0.exe
echo 🌐 Web Downloads: cloud_server/static/downloads/
echo ====================================================================
pause