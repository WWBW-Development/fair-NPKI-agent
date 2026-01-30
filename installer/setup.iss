; NPKI Agent Inno Setup Script
; Creates a Windows installer (fair-npki-agent-windows.exe)

#define MyAppName "NPKI Agent"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "WWBW"
#define MyAppURL "https://github.com/your-org/fair-NPKI-agent"
#define MyAppExeName "fair-npki-agent.exe"
#define MyServiceName "NPKIAgent"

[Setup]
; Basic Information
AppId={{F8A9D2C1-4B5E-4A3D-9F1C-7E8D2A4B6C9E}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation Directories
DefaultDirName={autopf}\NPKIAgent
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Output
OutputDir=..\build
OutputBaseFilename=fair-npki-agent-windows
Compression=lzma
SolidCompression=yes

; Privileges (Required for service installation)
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; UI
WizardStyle=modern
; SetupIconFile=..\assets\icon.ico
; UninstallDisplayIcon={app}\{#MyAppExeName}

; Architecture
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
; Main executable
Source: "..\build\npki-agent-win.exe"; DestDir: "{app}"; DestName: "{#MyAppExeName}"; Flags: ignoreversion

; NSSM (Service Manager) - Included in repository
Source: "..\tools\nssm.exe"; DestDir: "{app}"; Flags: ignoreversion

; Manual install/uninstall scripts (for advanced users)
Source: "..\scripts\install.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\scripts\uninstall.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; No desktop icons for background service
; Create shortcuts in start menu
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{group}\Uninstall (Manual)"; Filename: "{app}\uninstall.bat"; Comment: "Manually uninstall NPKI Agent service"
Name: "{group}\Reinstall Service"; Filename: "{app}\install.bat"; Comment: "Reinstall NPKI Agent service"

[Run]
; Install and start Windows Service using NSSM
Filename: "{app}\nssm.exe"; Parameters: "install {#MyServiceName} ""{app}\{#MyAppExeName}"""; StatusMsg: "Installing Windows Service..."; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "set {#MyServiceName} DisplayName ""NPKI Certificate Agent"""; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "set {#MyServiceName} Description ""NPKI Certificate Auto-Discovery Agent"""; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "set {#MyServiceName} Start SERVICE_AUTO_START"; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "set {#MyServiceName} AppStdout ""{commonappdata}\fair-npki-agent\npki-agent.log"""; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "set {#MyServiceName} AppStderr ""{commonappdata}\fair-npki-agent\npki-agent.log"""; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "start {#MyServiceName}"; StatusMsg: "Starting Windows Service..."; Flags: runhidden waituntilterminated

[UninstallRun]
; Stop and remove Windows Service
Filename: "{app}\nssm.exe"; Parameters: "stop {#MyServiceName}"; Flags: runhidden
Filename: "{cmd}"; Parameters: "/c timeout /t 2 /nobreak"; Flags: runhidden
Filename: "{app}\nssm.exe"; Parameters: "remove {#MyServiceName} confirm"; Flags: runhidden

[UninstallDelete]
; Clean up log files
Type: files; Name: "{tmp}\fair-npki-agent.log"

[Code]
// Post-installation verification
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Wait for service to start
    Sleep(3000);
    
    // Verify service is running
    if Exec('cmd.exe', '/c sc query {#MyServiceName} | find "RUNNING"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0) then
    begin
      MsgBox('NPKI Agent has been installed and started successfully!' + #13#10 + #13#10 +
             'Windows Service is now running.' + #13#10 + #13#10 +
             'Server is available on http://localhost:62735' + #13#10 + #13#10 +
             'To verify: curl http://localhost:62735/npki/health', 
             mbInformation, MB_OK);
    end
    else
    begin
      MsgBox('Service installed but may not be running.' + #13#10 +
             'Please check Services (services.msc)', 
             mbInformation, MB_OK);
    end;
  end;
end;
