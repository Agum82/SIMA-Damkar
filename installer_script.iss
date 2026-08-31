[Setup]
AppName=SIMA Damkar
AppVersion=1.0
AppPublisher=Institut Teknologi Garut
DefaultDirName={autopf}\SIMADamkar
DefaultGroupName=SIMA DAmkar
OutputDir=D:\kerjapraktek
OutputBaseFilename=SIMA_Damkar_Setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "D:\kerjapraktek\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SIMA DAmkar"; Filename: "{app}\SIMA_Damkar.exe"
Name: "{autodesktop}\SIMA DAmkar"; Filename: "{app}\SIMA_Damkar.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\SIMA_Damkar.exe"; Description: "{cm:LaunchProgram,SIMA DAmkar}"; Flags: nowait postinstall skipifsilent