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

[Icons]
; No desktop icons for background service
; Create uninstall shortcut in start menu
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
; Register startup task using Windows Task Scheduler
Filename: "schtasks.exe"; Parameters: "/create /tn ""{#MyServiceName}"" /tr ""\""{app}\{#MyAppExeName}\"""" /sc onstart /ru SYSTEM /rl highest /f"; StatusMsg: "Registering startup task..."; Flags: runhidden

; Start the application immediately after installation
Filename: "{app}\{#MyAppExeName}"; Description: "Start {#MyAppName} now"; Flags: postinstall nowait skipifsilent

[UninstallRun]
; Stop the application
Filename: "taskkill.exe"; Parameters: "/F /IM {#MyAppExeName}"; Flags: runhidden
; Remove startup task
Filename: "schtasks.exe"; Parameters: "/delete /tn ""{#MyServiceName}"" /f"; Flags: runhidden

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
    // Wait for application to start
    Sleep(2000);
    
    // Verify task is registered
    if Exec('cmd.exe', '/c schtasks /query /tn {#MyServiceName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0) then
    begin
      MsgBox('NPKI Agent has been installed successfully!' + #13#10 + #13#10 +
             'The application will start automatically on system boot.' + #13#10 + #13#10 +
             'Server will be available on http://localhost:62735' + #13#10 + #13#10 +
             'To verify: curl http://localhost:62735/npki/health', 
             mbInformation, MB_OK);
    end
    else
    begin
      MsgBox('Installation completed but startup task may not be registered.' + #13#10 +
             'Please check Task Scheduler (taskschd.msc)', 
             mbInformation, MB_OK);
    end;
  end;
end;
