@echo off
echo ====================================================================
echo BUILDING DEVICE CONTROL AI WINDOWS INSTALLER (.EXE)
echo ====================================================================

echo 1. Building Flutter Windows Executable...
cd ..\mobile_app
call flutter build windows --release

echo.
echo 2. Compiling Inno Setup Installer...
cd ..\installer

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
) else (
    echo [!] Inno Setup 6 compiler ISCC.exe not found. Please verify installation.
)

echo ====================================================================
echo DONE! Check installer/Output/ for your setup file.
echo ====================================================================
pause
