unit LogoService_Impl;

// ----------------------------------------------------------------------
//  This file was automatically generated by Remoting SDK from a
//  RODL file downloaded from a server or associated with this project.
// 
//  Do not modify this file manually, or your changes will be lost when
//  it is regenerated the next time you update your RODL.
// ----------------------------------------------------------------------

{$I RemObjects.inc}

interface

uses
  {$IFDEF DELPHIXE2UP}System.SysUtils{$ELSE}SysUtils{$ENDIF},
  {$IFDEF DELPHIXE2UP}System.Classes{$ELSE}Classes{$ENDIF},
  {$IFDEF DELPHIXE2UP}System.TypInfo{$ELSE}TypInfo{$ENDIF},
  uROEncoding,
  uROXMLIntf,
  uROClientIntf,
  uROClasses,
  uROTypes,
  uROServer,
  uROServerIntf,
  uROSessions,
  uRORemoteDataModule,
  UKLibrary_Intf;

type
  { Forward declarations }
  TLogoService = class;

  TLogoService = class(TRORemoteDataModule, ILogoService)
  public
    procedure mLogoOut(const mSessionID: UnicodeString); virtual;
    function ConnRequire(const ClientInfo: Binary; out Token: Binary; out Msg: UnicodeString): Boolean; virtual;
  end;

implementation

{$IFDEF DELPHIXE2UP}
  {%CLASSGROUP 'System.Classes.TPersistent'}
{$ENDIF}
{$IFNDEF FPC}
  {$R *.dfm}
{$ENDIF}
{$IFDEF FPC}
  {$R *.lfm}
{$ENDIF}

uses
  UKLibrary_Invk;

var fClassFactory_LogoService: IROClassFactory;

procedure Create_LogoService(out anInstance: IInterface);
begin
  anInstance := TLogoService.Create(nil);
end;

procedure TLogoService.mLogoOut(const mSessionID: UnicodeString);
begin
  {$Message Hint 'mLogoOut is not implemented yet!'}
end;

function TLogoService.ConnRequire(const ClientInfo: Binary; out Token: Binary; out Msg: UnicodeString): Boolean;
begin
  {$Message Hint 'ConnRequire is not implemented yet!'}
end;

initialization
  fClassFactory_LogoService := TROClassFactory.Create('LogoService', {$IFDEF FPC}@{$ENDIF}Create_LogoService, TLogoService_Invoker);
  // RegisterForZeroConf(fClassFactory_LogoService, '_LogoService_rosdk._tcp.');
finalization
  UnRegisterClassFactory(fClassFactory_LogoService);
  fClassFactory_LogoService := nil;
end.
