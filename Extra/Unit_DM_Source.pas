unit Unit_DM_Source;

interface

uses
  SysUtils, Classes, uADStanIntf, uADStanOption, uADStanError, uADGUIxIntf,
  uADPhysIntf, uADStanDef, uADStanPool, uADStanAsync, uADPhysManager,
  uADStanParam, uADDatSManager, uADDAptIntf, uADDAptManager, uADGUIxFormsWait,
  uADPhysODBCBase, uADPhysMSSQL, uADCompGUIx, DB, uADCompDataSet, uADCompClient,
  Generics.Collections, SyncObjs, DateUtils, uROTypes, ADODB;

const
  MaxQry: Integer = 10;

type
  PClientInfo = ^TClientInfo;

  TClientInfo = record
    Key:string;
    UserName: string;
    Password: String;
    ClientVersion:Integer;
    Ip:string;
    Mac:string;
    Session:string;
    Stats:Boolean;
    CreationTime: TDateTime;
    LastAccedTime: TDateTime;
  end;

//  PClientInfo = ^TClientInfo;
//
//  TClientInfo = record
//    Password:string;
//    DUserInfo: TDictionary<
//  string, //UserName
//  TDictionary<
//  string, //Session
//  PUserInfo
//  >>;
//  end;

  TQryPool = class
    Finuse: Boolean;
    Fidle: TDateTime;
    FDQry: TADQuery;
    FDStrIndex: Integer;
  end;

  TUserAction = (SetUserName,SetUserPassWord, DelUser,
  SetSession,SetStats,SetCreationTime,RegUser,
  SetLastAccedTime,UserLogin,UserLogout);
  // TUserActionS = set of TUserAction;

  TDMHelps = class(TDataModule)
    odm: TADManager;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }

    function GuidToAnistring: AnsiString;

  public
    { Public declarations }

  end;

var
  DMHelps: TDMHelps;
  DQueryList: TDictionary<Integer, TQryPool>;
//  DUserInfo: TDictionary<
//  string, //UserName
//  TDictionary<
//  string, //Session
//  PUserInfo
//  >>;
  DClientInfo: TDictionary<
  string, //user
  PClientInfo    //ClientInfo
  >;
  DUserInfo :TDictionary<string,string>;
  FQryIndex: Integer;
  CSLock, CheckLock, LogoLock: TCriticalSection;

procedure DecodeClientInfo(ClientInfo: String; var List: TStringList);
function ACT_UserDict(act: TUserAction;
  UserInfo: PClientInfo;out ErrorCode:Integer): Boolean;
function Act_Users(act: TUserAction; UserInfo: PClientInfo; out QryMsg: string;
  User: string = ''; Psw: string = ''): Boolean;

function CheckLoginDATA(UserDATA: TMemoryStream): Boolean;

function GetSqlStr(Qry: TADQuery; Index: Integer): string;

procedure CallFDShow(T: Integer; L: Integer);

function _GetQuery(QryStrIndex: Integer; DOCheck: Boolean = False): Integer;

function DMOpenQrys(const CodeOfSqls: Integer; const ParmasOfQry: string;
  out QryMsg: string; var QryRet: Binary): Boolean;

// function CreateSqlHelps:ISqlHelps;stdcall;external 'SqlHelps.dll';
implementation

uses
  Unit_FDconnect, fServerForm, Unit_QryHelps, TPLB3.BaseNonVisualComponent,
  TPLB3.Codec, TPLB3.CryptographicLibrary, TPLB3.Constants;
{ %CLASSGROUP 'Vcl.Controls.TControl' }
{$R *.dfm}

function ACT_UserDict(act: TUserAction;
  ClientInfo: PClientInfo; out ErrorCode:Integer): Boolean;
var
TmpClientInfo:PClientInfo;
UserName,Session:string;
OldName,OldPsw,OldSession:string;
I:Integer;
begin
  Result := True;
  UserName:= ClientInfo.UserName;
  Session:=ClientInfo.Session;

  try
  {$REGION 'UserLogin'}
    if act = UserLogin then
            if Not DUserInfo.ContainsKey(UserName) then
               begin
                 Result:=False;
                 ErrorCode:=-8;
                 Exit;
               end;

               if not SameText(DUserInfo.Items[UserName],
               ClientInfo.PASSWORD) then
                 begin
                   Result:=False;
                   ErrorCode:= -9;
                   Exit;
                 end;

            if  DClientInfo.ContainsKey(Session) then
                Exit
                else
                DClientInfo.Add(Session,ClientInfo);
         {$ENDREGION}
    {$REGION 'UserLogout'}
    if act = UserLogout then
       if DClientInfo.ContainsKey(Session) then
       begin
         Dispose(DClientInfo.Items[Session]);
         DClientInfo.Remove(Session);
       end
         else
            begin
              ErrorCode:=-6;
              Result:=False;
              Exit;
            end;
      {$ENDREGION}
      {$REGION 'SetUserName'}
    if act = SetUserName then
        begin
          OldName:= DClientInfo.Items[Session].UserName;
        if Not SameText(UserName,OldName) then  //change username
           begin
              for Session in DClientInfo.Keys do
             begin
                if SameText((DClientInfo.Items[Session].UserName),OldName) then
                  DClientInfo.Items[Session].UserName:=UserName;
             end;
               if DUserInfo.ContainsKey(OldName) then
                 begin
                   OldName:=DUserInfo.Items[OldName];
                   DUserInfo.Remove(OldName);
                   DUserInfo.Add(UserName,OldName);

                 end;
           end
           else
           begin
             ErrorCode:=-7; //user already exsit
             Result:=False;
             Exit;
           end;
        end;
   {$ENDREGION}
   {$REGION 'SetUserPassword'}
   if act = SetUserPassWord then
   begin
      DUserInfo.Items[UserName]:=ClientInfo.Password;

   end;

   {$ENDREGION}
{$REGION 'SetSession'}
 if act = SetSession then
 begin
    New(TmpClientInfo);
    OldSession:= ClientInfo.Key;
    TmpClientInfo.Key:=Session + UserName;
    TmpClientInfo.UserName:=DClientInfo.Items[OldSession].UserName;
    TmpClientInfo.Password:=DClientInfo.Items[OldSession].Password;
    TmpClientInfo.ClientVersion:=DClientInfo.Items[OldSession].ClientVersion;
    TmpClientInfo.Ip:=DClientInfo.Items[OldSession].Ip;
    TmpClientInfo.Mac:=DClientInfo.Items[OldSession].Mac;
    TmpClientInfo.Session:=Session;
    TmpClientInfo.Stats:=DClientInfo.Items[OldSession].Stats;
    TmpClientInfo.CreationTime:=DClientInfo.Items[OldSession].CreationTime;
    TmpClientInfo.LastAccedTime:=DClientInfo.Items[OldSession].LastAccedTime;
    Dispose(DClientInfo.Items[OldSession]);
    DClientInfo.Remove(Session);
    DClientInfo.Add(Session,TmpClientInfo);
 end;
{$ENDREGION}
{$REGION 'SetStats'}
     if act = SetStats then
     begin
       DClientInfo.Items[Session].Stats:=ClientInfo.stats;
     end;
{$ENDREGION}
{$REGION 'SetCreationTime'}
if act = SetCreationTime then
begin
   DClientInfo.Items[Session].CreationTime:=ClientInfo.CreationTime;
end;
{$ENDREGION}
{$REGION 'SetLastAccedTime'}
   if act = SetLastAccedTime then
     DClientInfo.Items[Session].LastAccedTime:=ClientInfo.LastAccedTime;
{$ENDREGION}
{$REGION 'RegUser'}
if act = RegUser then
begin

end;


{$ENDREGION}
{$REGION 'DelUser'}
   if act = DelUser then
   begin
     if not DClientInfo.ContainsKey(UserName) then
     begin
         Result:=False;
         ErrorCode:= -2;
         Exit;
     end;
     if DClientInfo.Items[UserName].Count <> 1 then
     begin
          Result:=False;
          ErrorCode:= -3;
          Exit;
     end;
     Dispose(DClientInfo.Items[UserName].Items[Session]);
     DClientInfo.Items[UserName].Free;
     DClientInfo.Remove(UserName);
   end;
{$ENDREGION}
  except
    Result := False;
  end;

end;

procedure TDMHelps.DataModuleDestroy(Sender: TObject);
//var
//I:Integer;
begin
//  LogoLock.Free;
//  if DQueryList.Count > 0 then
//  begin
//       for I in DQueryList.Keys do
//         begin
//           if Assigned(DQueryList.Items[I].FDQry) then
//              DQueryList.Items[I].FDQry.Free;
//
//              if Assigned(DQueryList.Items[I]) then
//              DQueryList.Items[I].Free;
//
//         end;
//  end;
  if Assigned(DQueryList) then
  DQueryList.Free;
  if Assigned(DClientInfo) then
  DClientInfo.Free;
  if Assigned(CSLock) then
  CSLock.Free;
end;

function TDMHelps.GuidToAnistring: AnsiString;
var
  Guid: TGUID;
  SGuid: AnsiString;
begin
  CreateGUID(Guid);
  SGuid := GUIDToString(Guid);
  Delete(SGuid, 1, 1);
  Delete(SGuid, Length(SGuid), 1);
  Result := SGuid;
end;

procedure DecodeClientInfo(ClientInfo: String; var List: TStringList);
var
  Guid, Mac, IP: string;
begin
  Guid := Copy(ClientInfo, 1, 36);
  List.ADD('Guid=' + Guid);
  Mac := Copy(ClientInfo, 37, 17);
  List.ADD('Mac=' + Mac);
  IP := Copy(ClientInfo, 54, 15);
  List.ADD('IP=' + IP);

end;

function GetSqlStr(Qry: TADQuery; Index: Integer): string;
var
  Ret: string;
begin
  with Qry do
  begin
    Close;
    SQL.Clear;
    SQL.ADD('Use UFPrint');
    ExecSQL;
    SQL.Clear;
    SQL.ADD('Select SqlStr From Rep_SqlStr where Index =' + Inttostr(Index));
    Open;
    Ret := FieldByName('SqlStr').AsString;
    Result := Ret;
  end;
end;

procedure CallFDShow(T: Integer; L: Integer);
begin
  ServerForm.ShowFDconnect(T, L);
end;
// **-2:check, -1:error  , 0 : maxqry reached

function _GetQuery(QryStrIndex: Integer; DOCheck: Boolean = False): Integer;

  function GetidleQry(QryStrIndex: Integer): Integer;
  var
    I: Integer;
  begin
    Result := -1;

    if DQueryList.Count = 0 then
    begin
      Result := 0;
      Exit;
    end;
    for I := 1 to MaxQry do
    begin
      if DQueryList.ContainsKey(I) then
      begin
        if DQueryList.Items[I].Finuse = False then
        begin
          if (not DOCheck) then
          begin
            Result := I;
            if DQueryList.Items[I].FDStrIndex = QryStrIndex then
            begin
              DQueryList.Items[I].Finuse := True; // LOCK
              Exit;
            end;
          end
          else
          begin
            if MinutesBetween(Now, DQueryList.Items[I].Fidle) > 1 then
            begin
              DQueryList.Items[I].FDQry.Free;
              DQueryList.Remove(I);
              CallFDShow(MaxQry, DQueryList.Count);
            end;

          end;
        end;

      end;

    end;

    if Result > 0 then
    begin
      DQueryList.Items[Result].FDStrIndex := QryStrIndex;
      DQueryList.Items[Result].Finuse := True;
      Exit;
    end;

    if Result = -1 then
      Result := 0;
  end;

  function GetFreeQry: Integer;
  var
    I: Integer;
  begin
    for I := 1 to MaxQry do
    begin
      if (not DQueryList.ContainsKey(I)) then
      begin
        Result := I;
        Exit;
      end;

    end;
    Exit;
  end;

var
  FDQry: TADQuery;
  FDQryPool: TQryPool;
  DCount, EXENO: Integer;
begin
  if CSLock = NIL then
  begin
    Result := -1;
    Exit;
  end;
  CSLock.Enter;
  try

    EXENO := GetidleQry(QryStrIndex);
    if not DOCheck then
    begin
      DCount := DQueryList.Count;
      if EXENO <> 0 then
      begin
        Result := EXENO;
        Exit;
      end
      else
      begin
        if DCount < MaxQry then
        begin
          FDQry := TADQuery.Create(Nil);
          FDQry.Name := 'FDQry' + Inttostr(DCount + 1);
          FDQryPool := TQryPool.Create;
          FDQryPool.Finuse := True;
          FDQryPool.Fidle := 0;
          FDQryPool.FDQry := FDQry;
          FDQryPool.FDStrIndex := QryStrIndex;
          Result := GetFreeQry;
          DQueryList.ADD(Result, FDQryPool);
          CallFDShow(MaxQry, DCount + 1);

        end
        else
        begin
          Result := 0;
        end;
      end;
    end
    else
      Result := -2;
  finally
    CSLock.Leave;

  end;
end;

procedure TDMHelps.DataModuleCreate(Sender: TObject);
var
  sConnect: TStrings;
begin
  //LogoLock := TCriticalSection.Create;
  sConnect := TStringList.Create;
  CSLock := TCriticalSection.Create;
  DQueryList := TDictionary<Integer, TQryPool>.Create;
  try
    try
      sConnect.Clear;
      ConnectStrFromIni(sConnect);
      sConnect.ADD('POOL_MaximumItems=10');

      odm.Close;
      odm.AddConnectionDef('MSSQL_Pooled', '', sConnect);

      odm.Active := True;
    except
      raise ;
    end;
  finally
    FreeAndNil(sConnect);
  end;

end;

function DMOpenQrys(const CodeOfSqls: Integer; const ParmasOfQry: string;
  out QryMsg: string; var QryRet: Binary): Boolean;
var
  mQry: TADQuery;
  mConn: TADConnection;
  SQLSTR: string;
  Qindex: Integer;
  List: TStringList;
begin

  mConn := TADConnection.Create(nil);
  List := TStringList.Create;
  try
    try
      mConn.ConnectionDefName := 'MSSQL_Pooled';

      Qindex := _GetQuery(CodeOfSqls);

      if Qindex = -1 then
      begin
        QryMsg := 'CriticalSection Error';
        Result := False;
        Exit;
      end;
      if Qindex = 0 then
      begin
        QryMsg := 'Qry Full';
        Result := False;
        Exit;
      end;

      mQry := DQueryList.Items[Qindex].FDQry;
      mQry.Connection := mConn;

      if not mConn.Connected then
        mConn.Connected := True;
      SQLSTR := GetSqlStr(mQry, CodeOfSqls);
      with mQry do
      begin
        Close;
        SQL.Clear;

        if ParmasOfQry <> '' then
        begin
          if not DecodeFilter(ParmasOfQry, List) then
            Exit;
          SQL.ADD('Use UFDATA_' + List[0] + '_' + List[1]);
          ExecSQL;
          SQL.Clear;

          SQL.ADD(SQLSTR + ' where ' + List[2])
        end
        else
          SQL.ADD(SQLSTR);
        Open;
        FetchAll;

        SaveToStream(QryRet, TADStorageFormat.sfBinary);

      end;
      mConn.Connected := False;

      Result := True;
    except
      QryMsg := 'error';
      Result := False;
    end;
  finally

    mQry.Close;
    DQueryList.Items[Qindex].Fidle := Now;
    DQueryList.Items[Qindex].Finuse := False;

    FreeAndNil(mConn);
    List.Free;
  end;
end;

function Act_Users(act: TUserAction; ClientInfo: PClientInfo; out QryMsg: string;
  User: string = ''; Psw: string = ''): Boolean;
{$REGION 'Intall Qry'}
  function IsUserExsitInDict(User: string): Boolean;
  begin
    try
      Result := DClientInfo.ContainsKey(User);
    except
      Result := False;
    end;
  end;

var
  mQry: TADQuery;
  mConn: TADConnection;
  SQLSTR: string;
  Qindex, I, RCount,ErrorCode: Integer;
begin
  QryMsg:='';
  if LogoLock = nil then
  begin
    QryMsg := 'Critical section error';
    Result := False;
    Exit;
  end;
  LogoLock.Enter;
  mConn := TADConnection.Create(nil);
  Result := False;
  try
    try

      mConn.ConnectionDefName := 'MSSQL_Pooled';

      Qindex := _GetQuery(-1);

      if Qindex = -1 then
      begin
        QryMsg := 'CriticalSection Error';

        Exit;
      end;
      if Qindex = 0 then
      begin
        QryMsg := 'Qry Full';

        Exit;
      end;

      mQry := DQueryList.Items[Qindex].FDQry;
      mQry.Connection := mConn;

      if not mConn.Connected then
        mConn.Connected := True;
{$ENDREGION}
{$REGION 'Reg User'}
      if act = RegUser then
      begin
        if User = '' then
        begin
          QryMsg := 'User must not be blank';
          Result := False;
          Exit;
        end;
        if IsUserExsitInDict(User) then
        begin
          QryMsg := 'User Aready exsit in dict';
          Result := False;
          Exit;
        end;

        with mQry do
        begin
          Close;
          SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -1);
          SQLSTR := StringReplace(SQLSTR, '######', User, [rfReplaceAll]);
          SQL.ADD(SQLSTR);
          Open;

          if RecordCount > 0 then
          begin
            QryMsg := 'User already exsit';
            Result := False;
            Exit;
          end;

          if SameText(User, '######') then
            Exit;
          // SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -2);
          SQLSTR := StringReplace(SQLSTR, '######', User, [rfReplaceAll]);
          // SQL.ADD(SQLSTR);

          if ExecSQL(SQLSTR) = 1 then
          begin
            if not ACT_UserDict(RegUser,ClientInfo,ErrorCode) then
            begin
              QryMsg := 'Dict cause a error while adding user to memory';
              Result := False;
              Exit;
            end;
          end
          else
          begin
            QryMsg := 'execsql <1';
            Result := False;
            Exit;
          end;

        end;
        QryMsg := 'ADD Succ';
      end;
{$ENDREGION}
{$REGION 'Del User'}
 if act = DelUser then
 begin
           if User = '' then
        begin
          QryMsg := 'User must not be blank';
          Result := False;
          Exit;
        end;
        if not IsUserExsitInDict(User) then
        begin
          QryMsg := 'User Not exsit';
          Result := False;
          Exit;
        end;

         with mQry do
        begin
          Close;
          SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -2);
          SQLSTR := StringReplace(SQLSTR, '######', User, [rfReplaceAll]);
          SQL.ADD(SQLSTR);
          Open;

          if not RecordCount > 0 then
          begin
            QryMsg := 'User Not exsit';
            Result := False;
            Exit;
          end;

          if SameText(User, '######') then
            Exit;
          // SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -3);
          SQLSTR := StringReplace(SQLSTR, '######', User, [rfReplaceAll]);
          // SQL.ADD(SQLSTR);

          if ExecSQL(SQLSTR) = 1 then
          begin
            if not ACT_UserDict(DelUser,ClientInfo,ErrorCode) then
            begin
              QryMsg := 'Dict cause a error while Delete User';
              Result := False;
              Exit;
            end;
          end
          else
          begin
            QryMsg := 'execsql <1';
            Result := False;
            Exit;
          end;

        end;
        QryMsg := 'Del Succ';
 end;
{$ENDREGION}
{$REGION 'UP Password'}
if act = SetUserPassWord then
begin
     if User = '' then
        begin
          QryMsg := 'User must not be blank';
          Result := False;
          Exit;
        end;
        if not IsUserExsitInDict(User) then
        begin
          QryMsg := 'User Not exsit';
          Result := False;
          Exit;
        end;

         with mQry do
        begin
          Close;
          SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -2);
          SQLSTR := StringReplace(SQLSTR, '######', User, [rfReplaceAll]);
          SQL.ADD(SQLSTR);
          Open;

          if not RecordCount > 0 then
          begin
            QryMsg := 'User Not exsit';
            Result := False;
            Exit;
          end;

          if SameText(Psw, '######') then
            Exit;
          // SQL.Clear;
          SQLSTR := GetSqlStr(mQry, -4);
          SQLSTR := StringReplace(SQLSTR, '######', Psw, [rfReplaceAll]);
          // SQL.ADD(SQLSTR);

          if ExecSQL(SQLSTR) = 1 then
          begin
            if not ACT_UserDict(SetUserPassWord,ClientInfo,ErrorCode) then
            begin
              QryMsg := 'Dict cause a error while Change Password';
              Result := False;
              Exit;
            end;
          end
          else
          begin
            QryMsg := 'execsql <1';
            Result := False;
            Exit;
          end;

        end;
        QryMsg := 'Change Password Succ';
end;
{$ENDREGION}
{$REGION 'Finally Qry'}
      mConn.Connected := False;

      Result := True;
    except
      On E: Exception do
      begin
        QryMsg := E.Message;

        Result := False;
      end;

    end;
  finally

    mQry.Close;
    DQueryList.Items[Qindex].Fidle := Now;
    DQueryList.Items[Qindex].Finuse := False;

    FreeAndNil(mConn);
    LogoLock.Leave;
  end;
{$ENDREGION}
end;

function CheckLoginDATA(UserDATA: TMemoryStream): Boolean;
begin

     LogoLock.Enter;
     Result:=False;
     try


     Result:=True;
    finally
     LogoLock.Leave;
    end;
end;


end.
