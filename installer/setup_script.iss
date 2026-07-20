; ====================================================================
; INNO SETUP SCRIPT FOR DEVICE CONTROL AI (WINDOWS INSTALLER)
; ====================================================================

#define MyAppName "PC Control"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "PC Control Team"
#define MyAppURL "https://github.com/NhatPrv/PC_Control_For_PC"
#define MyAppExeName "mobile_app.exe"

[Setup]
AppId={{D3A8F124-7C92-4F1A-B829-91283F1C9901}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputBaseFilename=PC_Control_Setup_v1.0.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostart"; Description: "Tự động chạy ngầm Agent khi khởi động Windows (Auto-start on Windows boot)"; GroupDescription: "Tùy chọn hệ thống:"

[Files]
; Thư mục ứng dụng Flutter Desktop
Source: "..\mobile_app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Thư mục Python Backend Agent
Source: "..\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\.venv\*"; DestDir: "{app}\.venv"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "PCControlAgent"; ValueData: """{app}\backend\start_agent_hidden.vbs"""; Flags: uninsdeletevalue
; Tự động khởi chạy Agent ngầm cùng Windows nếu người dùng tích chọn
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "DeviceControlAIAgent"; ValueData: """{app}\.venv\Scripts\pythonw.exe"" ""{app}\backend\agent_client.py"""; Flags: uninsdeletevalue; Tasks: autostart

[Run]
; Khởi chạy Agent ngầm ngay sau khi hoàn tất cài đặt
Filename: "{app}\.venv\Scripts\pythonw.exe"; Parameters: """{app}\backend\agent_client.py"""; Flags: nowait postinstall skipifsilent; Description: "Khởi chạy Agent ngầm ngay bây giờ"
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
