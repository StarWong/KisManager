program UKProject;

{#ROGEN:UKLibrary.rodl} // RemObjects: Careful, do not remove!

uses
  FastMM4,
  uROComInit,
  Forms,
  Windows,
  SysUtils,
  fServerForm in 'fServerForm.pas' {ServerForm},
  UKLibrary_Intf in 'UKLibrary_Intf.pas',
  UKLibrary_Invk in 'UKLibrary_Invk.pas',
  Unit_QryHelps in 'Extra\Unit_QryHelps.pas',
  Unit_DM_Source in 'Extra\Unit_DM_Source.pas' {DMHelps: TDataModule},
  Unit_FDconnect in 'Extra\Unit_FDconnect.pas',
  AppService_Impl in 'AppService_Impl.pas' {AppService: TRORemoteDataModule},
  LogonService_Impl in 'LogonService_Impl.pas' {LogonService: TRORemoteDataModule};

{$R *.res}
{$R RODLFile.res}
const
  Guid1 ='{A374F24F-849C-4033-BA1B-D3CEB9D58B05}';
  Guid2 ='{F6378C9D-E08A-4026-A52E-292F4F1F83BC}';
  var
HW:HWND;
Guid:WideString;
Ret:Integer;
Recipt:Cardinal;
{$REGION ''}
Function GetVolumeID: string;
var
  vVolumeNameBuffer: array[0..255]of Char;
  vVolumeSerialNumber: DWORD;
  vMaximumComponentLength: DWORD;
  vFileSystemFlags: DWORD;
  vFileSystemNameBuffer: array[0..255]of Char;
begin
  if GetVolumeInformation('C:\', vVolumeNameBuffer, SizeOf(vVolumeNameBuffer),
     @vVolumeSerialNumber, vMaximumComponentLength, vFileSystemFlags,
     vFileSystemNameBuffer, SizeOf(vFileSystemNameBuffer))   then
  begin
    Result := IntToHex(vVolumeSerialNumber, 8);
  end;
end;
{$ENDREGION}
begin
  ReportMemoryLeaksOnShutdown := DebugHook<>0;
  Guid:=Guid1+GetVolumeID+Guid2;
  HW:=CreateMutex(nil,False,PWideChar(Guid));
  AppMsg:=RegisterWindowMessage(PWideChar(Guid));
  Ret:=GetLastError;
  If Ret<>ERROR_ALREADY_EXISTS Then
  begin
  Application.Initialize;
  Application.CreateForm(TServerForm, ServerForm);
  Application.CreateForm(TDMHelps, DMHelps);
  Application.Run;
  end
  else
  begin
    Recipt:=BSM_ALLDESKTOPS;
    BroadcastSystemMessage(BSF_POSTMESSAGE,@Recipt,Appmsg,0,0);
    Application.Terminate;
    ReleaseMutex(HW);
  end;
end.
