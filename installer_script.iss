[Setup]
; ==============================================================================
; PENTING: Jangan pernah mengubah AppId ini pada versi-versi pembaruan selanjutnya!
; ==============================================================================
AppId={{SIMADamkar_ITG_AppId_2026}}
AppName=SIMA Damkar
AppVersion=1.0
AppPublisher=Institut Teknologi Garut
DefaultDirName={autopf}\SIMADamkar
DefaultGroupName=SIMA Damkar
OutputDir=D:\kerjapraktek
OutputBaseFilename=SIMA_Damkar_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; Fitur agar otomatis menutup aplikasi yang sedang berjalan saat proses update
CloseApplications=yes
CloseApplicationsFilter=*.exe
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Menggunakan flag ignoreversion agar file lama otomatis ditimpa dengan file build terbaru
Source: "D:\kerjapraktek\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SIMA Damkar"; Filename: "{app}\SIMA_Damkar.exe"
Name: "{autodesktop}\SIMA Damkar"; Filename: "{app}\SIMA_Damkar.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\SIMA_Damkar.exe"; Description: "{cm:LaunchProgram,SIMA Damkar}"; Flags: nowait postinstall skipifsilent