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

if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup_script.iss
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    "C:\Program Files\Inno Setup 6\ISCC.exe" setup_script.iss
) else (
    echo [!] Inno Setup 6 is not installed. Please download and install from: https://jrsoftware.org/download.php/is.exe
)

echo ====================================================================
echo DONE! Check installer/Output/ for your setup file.
echo ====================================================================
pause
