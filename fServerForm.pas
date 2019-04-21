unit fServerForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ScktComp, StdCtrls, DB, WinSock, ExtCtrls,
  CoolTrayIcon, ImgList, ComCtrls, ShellAPI, Registry, Mask, RzEdit, Menus,
  DateUtils, uROClient, uROPoweredByRemObjectsButton, uROClientIntf, uROServer,
  uROBinMessage, TypInfo, uROServerIntf, uROCustomRODLReader, uROBaseConnection,
  uROCustomHTTPServer, uROBaseHTTPServer, uROComponent, uROMessage, uROAsync,
  uROServerLocator, uROTransportChannel, uROBaseActiveEventChannel,
  uROBaseSuperChannel, uROBaseSuperHttpChannel, uROSynapseSuperHttpChannel,
  SyncObjs, uROSessions, uRODBSessionManager, uROIndyHTTPServer,
  IdBaseComponent, IdComponent, IdServerIOHandler, IdSSL, IdSSLOpenSSL,
  IdContext;



type
TMyIdSSLContext = class(TIdSSLContext)
end;
  TCheckThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  PLogoninfo = ^TLogoninfo;   //logon data

  TLogonInfo = record
  UserName:string;
  PassWord:string;
  ClientVersion:Integer;
  ClientTime:TDateTime;
  ClientName:string;
  IP:string;
  Mac:string;
  end;

  TServerForm = class(TForm)
    il2: TImageList;
    btn1: TButton;
    stat1: TStatusBar;
    pnl1: TPanel;
    pnl2: TPanel;
    pnl3: TPanel;
    lv1: TListView;
    lv2: TListView;
    spl1: TSplitter;
    mm1: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    pm1: TPopupMenu;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    v1: TMenuItem;
    N16: TMenuItem;
    ROMessage: TROBinMessage;
    TrayIcon1: TCoolTrayIcon;
    ROInMemorySessionManager: TROInMemorySessionManager;
    RoServer: TROIndyHTTPServer;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure v1Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure N16Click(Sender: TObject);
    procedure RoServerInternalIndyServerConnect(AContext: TIdContext);
    procedure IdServerIOHandlerSSLOpenSSL1GetPassword(var Password: string);
  private
    { Private declarations }
    mm: TMemoryStream;
    Fport: Integer;
    tm1, tm2: TTimer;
    Fbegindate: TDateTime;
    SessionEnding: Boolean;
    tm10: TTimer;
    tm3, tm4, tm5, tm6, tm7, tm8, tm9: TTimer; //更新用

    tm21, tm22, tm23, tm24, tm25, tm26: TTimer; //关闭用

    FMCSLock: TCriticalSection;




    //

    function GetHostIP: string;
    function GetComputerName: string;
  public
    procedure ShowFDconnect(Conn, UsedConns: Integer);
    procedure WndProc(var message: TMessage); override;

  end;

var
  ServerForm: TServerForm;
  Appmsg: DWORD;
  CheckThread: TCheckThread;
  Docheck: Boolean;
  FSSLContext: TMyIdSSLContext;
implementation

uses
  IdSSLOpenSSLHeaders,Unit_FDconnect, Unit_DM_Source;

{$R *.dfm}

procedure TServerForm.WndProc(var message: TMessage);
begin
  if message.Msg = AppMsg then
  begin
    if not (Application.MainForm.Visible) then
      TrayIcon1.ShowMainForm;
  end;
  inherited WndProc(message);
end;

procedure TServerForm.ShowFDconnect(Conn, UsedConns: Integer);
var
  Item: TListItem;
begin
  if FMCSLock = NIL then
    Exit;
 //    FMCSLock.Enter;
  try
    if (lv1.FindCaption(0, Trim('对象池'), True, True, True) = nil) then
    begin
      lv1.Items.BeginUpdate;
      Item := lv1.Items.Add;
      Item.Caption := '对象池';
      Item.SubItems.Add(IntToStr(Conn));
      Item.SubItems.Add(IntToStr(UsedConns));
      lv1.Items.EndUpdate;
      Exit;
    end
    else
    begin
      Item := (lv1.FindCaption(0, Trim('对象池'), True, True, True));
      lv1.Items.BeginUpdate;
      Item.SubItems.Strings[0] := IntToStr(Conn);
      Item.SubItems.Strings[1] := IntToStr(UsedConns);
      lv1.Items.EndUpdate;

    end;
  finally
  // FMCSLock.Leave;
  end;
end;

procedure TServerForm.TrayIcon1Click(Sender: TObject);
begin
  if Application.MainForm.Visible then
    TrayIcon1.HideMainForm
  else
    TrayIcon1.ShowMainForm;
end;

procedure TServerForm.v1Click(Sender: TObject);
begin
if RoServer.Active then
RoServer.Active:=False;
  if Assigned(FMCSLock) then
    FMCSLock.Free;
  Docheck := False;
  CheckThread.WaitFor;
  if Assigned(checkThread) then
    CheckThread.Free;

  Application.Terminate;
end;

procedure TCheckThread.Execute;
var
  I: Integer;
begin
  FreeOnTerminate := False;
  while Docheck do
  begin
    for I := 1 to 600 do
    begin
      SleepEx(100, False);
      if not Docheck then
        Exit;
    end;
    _GetQuery(0, True);

  end;
end;

procedure TServerForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FMCSLock.Free;
end;

procedure TServerForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  TrayIcon1.HideMainForm;
  CanClose := False;
end;

procedure TServerForm.FormCreate(Sender: TObject);
var
appdir:string;
begin
{$REGION 'SSL'}

appdir:=ExtractFilePath(ParamStr(0));
  {$DEFINE ECDHE}
  {$IFDEF ECDHE}
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.RootCertFile:=appdir+'CA.crt';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.KeyFile:=appdir+'Server.key';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.CertFile:=appdir+'Server.crt';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.DHParamsFile:=appdir+'dhparam.pem';
  {$ELSE}
   {$IFDEF DHE}
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.RootCertFile:=appdir+'EccCA.pem';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.KeyFile:=appdir+'EccSite.key';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.CertFile:=appdir+'EccSite.pem';
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.DHParamsFile:=appdir+'dhparam.pem';
  {$ENDIF}
  {$ENDIF}
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.Method:=sslvTLSv1_2;
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.SSLVersions:=[sslvTLSv1_2];
  IdServerIOHandlerSSLOpenSSL1.SSLOptions.CipherList:=
    //'ECDHE-ECDSA-AES128-GCM-SHA256:' +
    'ECDHE-RSA-AES128-GCM-SHA256:' +
    //'ECDHE-RSA-AES256-GCM-SHA384:' +
    //'ECDHE-ECDSA-AES256-GCM-SHA384:' +
    //'DHE-RSA-AES128-GCM-SHA256:' +
    //'ECDHE-RSA-AES128-SHA256:' +
    //'DHE-RSA-AES128-SHA256:' +
    //'ECDHE-RSA-AES256-SHA384:' +
    //'DHE-RSA-AES256-SHA384:' +
    //'ECDHE-RSA-AES256-SHA256:' +
    //'DHE-RSA-AES256-SHA256:' +
    'HIGH:' +
    '!aNULL:' +
    '!eNULL:' +
    '!EXPORT:' +
    '!DES:' +
    '!RC4:' +
    '!MD5:' +
    '!PSK:' +
    '!SRP:' +
    '!CAMELLIA';


    RoServer.IndyServer.IOHandler:=IdServerIOHandlerSSLOpenSSL1;

     RoServer.Active := True;
    //FSSLContext:=TIdSSLContext(IdServerIOHandlerSSLOpenSSL1.SSLContext);
    FSSLContext := TMyIdSSLContext(IdServerIOHandlerSSLOpenSSL1.SSLContext);
    SSL_CTX_set_ecdh_auto(FSSLContext.fContext, 1);





{$ENDREGION}
  TrayIcon1.IconVisible := True;
  TrayIcon1.HideMainForm;
  TrayIcon1.Hint := '金友加密服务器';
  TrayIcon1.ShowHint := True;
  TrayIcon1.MinimizeToTray := True;
  stat1.Panels[2].Text := ' 服务器名称：' + GetComputerName;
  stat1.Panels[3].Text := ' 服务器IP:' + gethostip;
  stat1.Panels[4].Text := ' ' + DateToStr(date);
  FMCSLock := TCriticalSection.Create;
  ServerForm.ShowFDconnect(10, 0);
  Docheck := True;
  CheckThread := TCheckThread.Create(true);
  CheckThread.Resume;
end;

procedure TServerForm.FormShow(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
//TrayIcon1.Icon:=Application.Icon;
  TrayIcon1.IconVisible := True;
end;

function TServerForm.GetComputerName: string;
var
  buffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of Char;
  Size: Cardinal;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  Windows.GetComputerName(@buffer, Size);
  Result := strpas(buffer);
end;

function TServerForm.GetHostIP: string;
{*******************************************************
描述:取得本机的IP地址函数
版本: V1.0
日期:2002-11-01
作者: 胡建平
更新:
TODO:取得本机的IP地址函数
*******************************************************}
var
  ch: array[1..32] of Char;
  i: Integer;
  WSData: TWSAData;
  MyHost: PHostEnt;
  IP: string;
begin
  IP := '';
  if WSAstartup(2, WSData) <> 0 then
    Result := '0.0.0.0';

  try
    if getHostName(@ch[1], 32) <> 0 then
      Result := '0.0.0.0';
  except
    Result := '0.0.0.0';
  end;

  MyHost := GetHostByName(@ch[1]);
  if MyHost <> nil then
  begin
    for i := 1 to 4 do
    begin
      IP := IP + inttostr(Ord(MyHost.h_addr^[i - 1]));
      if i < 4 then
        IP := IP + '.'
    end;
  end;
  Result := IP;
end;

procedure TServerForm.IdServerIOHandlerSSLOpenSSL1GetPassword(
  var Password: string);
begin
   Password:='12345678';
end;

procedure TServerForm.N16Click(Sender: TObject);
begin
  SetFDConnect;
end;

procedure TServerForm.N5Click(Sender: TObject);
begin
RoServer.Active:=False;
  if Assigned(FMCSLock) then
    FMCSLock.Free;
  Docheck := False;
  CheckThread.WaitFor;
  if Assigned(checkThread) then
    CheckThread.Free;

  Application.Terminate;
end;

procedure TServerForm.RoServerInternalIndyServerConnect(AContext: TIdContext);
begin
 if (AContext.Connection.IOHandler is TIdSSLIOHandlerSocketBase) then
    TIdSSLIOHandlerSocketBase(AContext.Connection.IOHandler).PassThrough:= false;
end;

end.

