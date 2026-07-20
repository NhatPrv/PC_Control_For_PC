@echo off
echo ====================================================================
echo BUILDING DEVICE CONTROL AI WINDOWS INSTALLER (.EXE)
echo ====================================================================

echo 1. Building Flutter Windows Executable...
cd ..\mobile_app
call flutter build windows --release

echo 2. Compiling Inno Setup Installer...
cd ..\installer
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" setup_script.iss

echo ====================================================================
echo DONE! Output file: installer/Output/Device_Control_AI_Setup_v1.0.0.exe
echo ====================================================================
pause
