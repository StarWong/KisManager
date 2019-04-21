unit Unit_FDconnect;

interface
uses Classes;
procedure SetFDConnect;
procedure ConnectStrFromIni(var Constr:TStrings);
function RandKey256(mGuid: String; UserPsw: String): String;
function mEntryRSA_String(str: String): AnsiString;
function mDeEntryRSA_String(str: Ansistring): String;
procedure mGenerate_RSA_Key;
procedure mGenerate_ClientInfo(User,Psw:string;out Bin:TMemoryStream);
function mEntryRSA_Stream(TS: TMemoryStream;out Rs:TMemoryStream):Boolean;
function mDeEntryRSA_Stream(TS: TMemoryStream;out RS:TMemoryStream):Boolean;
implementation
uses
TPLB3.BaseNonVisualComponent,TPLB3.Codec,TPLB3.CryptographicLibrary,
TPLB3.Constants,TPLB3.Signatory,TPLB3.StreamUtils, TPLB3.StreamCipher,
TPLB3.Asymetric,DateUtils,
IniFiles,Windows,SysUtils,uADPhysMSSQL,uADGUIxFormsfConnEdit,
uADStanIntf, uADStanOption, uADStanError, uADGUIxIntf, uADPhysIntf,
  uADStanDef, uADStanPool, uADStanAsync, uADPhysManager, uADStanParam,
  uADDatSManager, uADDAptIntf, uADDAptManager, DB, uADCompDataSet, uADCompClient;
procedure SetFDConnect;
function IsNull(S:STRING;Ret:string =''):string;
begin
  if S = '' then
  Result:= Ret;
end;
function EncodeSa(Psw:AnsiString;const key:AnsiString):AnsiString;
var
Codec:TCodec;
Crypt:TCryptographicLibrary;
Ret:String;
begin
 Codec:=TCodec.Create(NIL);
 Crypt:=TCryptographicLibrary.Create(Nil);
 try
 Ret:='';
 Codec.CryptoLibrary:=Crypt;
 Codec.StreamCipherId:=BlockCipher_ProgId;
 Codec.BlockCipherId:='native.AES-256';
 Codec.ChainModeID:=CTR_ProgId;
 Codec.AsymetricKeySizeInBits:=1024;
 Codec.Password:=key;
 Codec.EncryptAnsiString(Psw,Ret);
 Result:=Ret;
  finally
  Codec.Free;
  Crypt.Free;
 end;
end;

Const
KeyStr:AnsiString ='qwertyuiopasdfghjklzxcvbnm';
var
inidir,Constr,DriveName:String;
mFDConnect:TADConnection;
FDini:TIniFile;
I,J:Integer;
begin
iniDir:=ExtractFilePath(Paramstr(0)) + 'FDDrivers.ini';
mFDConnect:=TADConnection.Create(nil);
FDini:=TIniFile.Create(iniDir);
ConStr:='';
try
try
ConStr:=mFDConnect.ResultConnectionDef.BuildString();
  if TfrmADGUIxFormsConnEdit.Execute(Constr,'') then
  begin
     mFDConnect.ResultConnectionDef.ParseString(ConStr);
     DriveName:= mFDConnect.DriverName;
    if UpperCase(DriveName) <> 'MSSQL' then
    begin
    MessageBoxW(0, PWideChar('不支持 '+DriveName), '错误', MB_OK + MB_ICONSTOP + MB_TOPMOST);
        Exit;
        end;

   case MessageBoxW(0, '数据库连接已更改，是否保存', '提示', MB_OKCANCEL + MB_ICONQUESTION +
     MB_TOPMOST) of
     IDOK:
       begin
            with mFDConnect.Params   do
       begin
       FDini.WriteString('Connection','SERVER',Values['Server']);
       FDini.WriteString('Connection','User_Name',Values['User_Name']);
       FDini.WriteString('Connection','Password',EncodeSa(Values['Password'],KeyStr));
       FDini.WriteString('Connection','ApplicationName',Values['ApplicationName']);
       FDini.WriteString('Connection','Workstation',Values['Workstation']);
       FDini.WriteString('Connection','DATABASE',Values['DATABASE']);
       FDini.WriteString('Connection','MARS',(IsNull((Values['MARS']),'Yes')));
       FDini.WriteString('Connection','DriverID',Values['DriverID']);
       FDini.WriteString('Connection','Pooled',IsNull((Values['Pooled']),'false'));
       FDini.WriteString('Connection','POOL_MaximumItems',
       (values['POOL_MaximumItems']));
        end;
       end;
     IDCANCEL:
       begin

       end;
   end;
  end;
 except
  raise;
end;
finally
   mFDConnect.Free;
   FDini.Free;
end;
end;

procedure ConnectStrFromIni(var Constr:TStrings);
const
key:AnsiString ='qwertyuiopasdfghjklzxcvbnm';
function DecodeSa(SecretStr:String;const key:AnsiString):AnsiString;
var
Codec:TCodec;
Crypt:TCryptographicLibrary;
Ret:String;
begin
 Codec:=TCodec.Create(NIL);
 Crypt:=TCryptographicLibrary.Create(Nil);
 try
 Ret:='';
 Codec.CryptoLibrary:=Crypt;
 Codec.StreamCipherId:=BlockCipher_ProgId;
 Codec.BlockCipherId:='native.AES-256';
 Codec.ChainModeID:=CTR_ProgId;
 Codec.AsymetricKeySizeInBits:=1024;
 Codec.Password:=key;
 Codec.DecryptAnsiString(Ret,SecretStr);
 Result:=Ret;
  finally
  Codec.Free;
  Crypt.Free;
 end;
end;
var
inidir,SecretStr:String;
FDini:TIniFile;
I,J:Integer;

begin
iniDir:=ExtractFilePath(Paramstr(0)) + 'FDDrivers.ini';
FDini:=TIniFile.Create(iniDir);
ConStr.Clear;
SecretStr:='';
try
try

       Constr.Add('SERVER='+FDini.ReadString('Connection','SERVER','{(local)}'));
       Constr.Add('User_Name='+FDini.ReadString('Connection','User_Name','sa'));
       SecretStr:=FDini.ReadString('Connection','Password','');
       ConStr.add('Password='+DecodeSa(SecretStr,Key));
       Constr.Add('ApplicationName='+FDini.ReadString('Connection','ApplicationName',''));
       Constr.Add('Workstation='+FDini.ReadString('Connection','Workstation',''));
       Constr.add('DATABASE='+FDini.ReadString('Connection','DATABASE',''));
       //Constr.Add('MARS='+(BoolToStr(FDini.ReadBool('Connection','MARS',True),true)));
       Constr.Add('DriverID='+FDini.ReadString('Connection','DriverID',''));
       Constr.Add('Pooled='+FDini.ReadString('Connection','Pooled','false'));
        OutputDebugString(PWideChar(constr));
       except
raise;
end;
finally
 FDini.Free;
end;
 end;

function mEntryRSA_Stream(TS: TMemoryStream;out RS:TMemoryStream):Boolean;
var
  Signatory: TSignatory;
  codecRSA: TCodec;
  CryptographicLibrary: TCryptographicLibrary;
  ms: TMemoryStream;
begin
  codecRSA := TCodec.Create(nil);
  CryptographicLibrary := TCryptographicLibrary.Create(nil);
  Signatory := TSignatory.Create(nil);
  ms := TMemoryStream.Create;
  Rs :=TMemoryStream.Create;
  Result:=True;
  try
  try
    codecRSA.CryptoLibrary := CryptographicLibrary;
    codecRSA.StreamCipherId := RSA_ProgId;
    codecRSA.ChainModeId := CBC_ProgId;
    codecRSA.AsymetricKeySizeInBits := 1024;
    Signatory.Codec := codecRSA;
    ms.LoadFromFile('Pub.Key');
    Signatory.LoadKeysFromStream(ms, [partPublic]);
    ms.Position:=0;
    codecRSA.EncryptStream(TS,Rs);
    except

      Result:=False;

  end;
  Finally
    ms.Free;
    codecRSA.Free;
    CryptographicLibrary.Free;
    Signatory.Free;
  end;

end;

function mDeEntryRSA_Stream(TS: TMemoryStream;out RS:TMemoryStream):Boolean;
var
  Signatory: TSignatory;
  codecRSA: TCodec;
  CryptographicLibrary: TCryptographicLibrary;
  ms: TMemoryStream;
  //base64Ciphertext: AnsiString;
begin
  Rs:=TMemoryStream.Create;
  codecRSA := TCodec.Create(nil);
  CryptographicLibrary := TCryptographicLibrary.Create(nil);
  Signatory := TSignatory.Create(nil);
  ms := TMemoryStream.Create;
  Result:=True;
  try
  try
    codecRSA.CryptoLibrary := CryptographicLibrary;
    codecRSA.StreamCipherId := 'native.RSA';
    codecRSA.ChainModeId := 'native.CBC';
    codecRSA.AsymetricKeySizeInBits := 1024;
    Signatory.Codec := codecRSA;

    ms.LoadFromFile('Pri.Key');
    Signatory.LoadKeysFromStream(ms, [partPrivate]);
    ms.Position:=0;
    codecRSA.DecryptStream(RS, TS);
  except

         Result:=False;

  end;
  finally
    ms.Free;
    codecRSA.Free;
    CryptographicLibrary.Free;
    Signatory.Free;
  end;

end;


function mDeEntryRSA_String(str: Ansistring): String;
var
  Signatory: TSignatory;
  codecRSA: TCodec;
  CryptographicLibrary: TCryptographicLibrary;
  ms: TMemoryStream;
  //base64Ciphertext: AnsiString;
begin
  Result := '';
  codecRSA := TCodec.Create(nil);
  CryptographicLibrary := TCryptographicLibrary.Create(nil);
  Signatory := TSignatory.Create(nil);
  ms := TMemoryStream.Create;
  try
    codecRSA.CryptoLibrary := CryptographicLibrary;
    codecRSA.StreamCipherId := 'native.RSA';
    codecRSA.ChainModeId := 'native.CBC';
    codecRSA.AsymetricKeySizeInBits := 1024;
    Signatory.Codec := codecRSA;

    ms.LoadFromFile('Pri.Key');
    Signatory.LoadKeysFromStream(ms, [partPrivate]);
    codecRSA.DecryptAnsistring(Result, str);
  finally
    ms.Free;
    codecRSA.Free;
    CryptographicLibrary.Free;
    Signatory.Free;
  end;
end;

procedure mGenerate_RSA_Key;
var
  Signatory: TSignatory;
  codecRSA: TCodec;
  CryptographicLibrary: TCryptographicLibrary;
  msPublic, msPrivate: TMemoryStream;
begin

  codecRSA := TCodec.Create(nil);
  CryptographicLibrary := TCryptographicLibrary.Create(nil);
  Signatory := TSignatory.Create(nil);
  msPublic := TMemoryStream.Create;
  msPrivate := TMemoryStream.Create;
  try
    codecRSA.CryptoLibrary := CryptographicLibrary;
    codecRSA.StreamCipherId := RSA_ProgId;
    codecRSA.ChainModeId := CBC_ProgId;
    codecRSA.AsymetricKeySizeInBits := 1024;
    Signatory.Codec := codecRSA;
    if Signatory.GenerateKeys then
    begin
      Signatory.StoreKeysToStream(msPublic, [partPublic]);
      Signatory.StoreKeysToStream(msPrivate, [partPrivate]);
      msPublic.Position:=0;
      msPrivate.Position:=0;
      msPublic.SaveToFile('Pub.key');
      msPrivate.SaveToFile('Pri.Key');
    end;

  finally
    msPublic.Free;
    msPrivate.Free;
    codecRSA.Free;
    CryptographicLibrary.Free;
    Signatory.Free;
  end;
end;

function mEntryRSA_String(str: String): AnsiString;
var
  Signatory: TSignatory;
  codecRSA: TCodec;
  CryptographicLibrary: TCryptographicLibrary;
  ms: TMemoryStream;
  base64Ciphertext: String;
begin
  Result := '';
  codecRSA := TCodec.Create(nil);
  CryptographicLibrary := TCryptographicLibrary.Create(nil);
  Signatory := TSignatory.Create(nil);
  ms := TMemoryStream.Create;
  try
    codecRSA.CryptoLibrary := CryptographicLibrary;
    codecRSA.StreamCipherId := RSA_ProgId;
    codecRSA.ChainModeId := CBC_ProgId;
    codecRSA.AsymetricKeySizeInBits := 1024;
    Signatory.Codec := codecRSA;
    ms.LoadFromFile('Pub.Key');
    Signatory.LoadKeysFromStream(ms, [partPublic]);
    codecRSA.EncryptAnsistring(str, base64Ciphertext);
    Result := base64Ciphertext;
  Finally
    ms.Free;
    codecRSA.Free;
    CryptographicLibrary.Free;
    Signatory.Free;
  end;
end;

function RandKey256(mGuid: String; UserPsw: String): String;

  function EncodePsw(PSW: String; const Key: String): String;
  var
    Codec: TCodec;
    Crypt: TCryptographicLibrary;
    Ret: String;
  begin
    Codec := TCodec.Create(NIL);
    Crypt := TCryptographicLibrary.Create(Nil);
    try
      Ret := '';
      Codec.CryptoLibrary := Crypt;
      Codec.StreamCipherId := BlockCipher_ProgId;
      Codec.BlockCipherId := 'native.AES-256';
      Codec.ChainModeID := CTR_ProgId;
      Codec.AsymetricKeySizeInBits := 1024;
      Codec.Password := Key;
      Codec.EncryptAnsiString(PSW, Ret);
      Result := Ret;
    finally
      Codec.Free;
      Crypt.Free;
    end;
  end;

var
  I: Integer;
  arrChar: array [0 .. 220] of AnsiChar;
  P: PAnsiChar;
  Ret: AnsiString;
begin
  FillChar(arrChar, SizeOf(arrChar), #0);
  for I := 0 to 219 do
  begin
    Randomize;
    arrChar[I] := AnsiChar(32 + Random(94));
  end;
  P := (@arrChar);

  Ret := P;
  Ret := mGuid + Ret;
  Result := EncodePsw(Ret, UserPsw);

end;

procedure mGenerate_ClientInfo(User,Psw:string;out Bin:TMemoryStream);
function RandomToken:string;
Var
aGuid:TGUID;
sGuid:string;
begin
     CreateGUID(aGuid);
     sGuid:=GUIDToString(aGuid);
     Delete(sGuid,1,1);
     Delete(sGuid,Length(sGuid),1);
     sGUID:= StringReplace(sGUID, '-', '', [rfReplaceAll]);
     Result:=sGuid+IntToStr(DateTimeToUnix(Now));
end;
var
List:TStringList;
begin
    List:=TStringList.Create;
    Bin:=TMemoryStream.Create;
    TRY
    List.Add(User);
    List.Add(Psw);
    List.Add(IntToStr(DateTimeToUnix(Now)));
    List.Add(RandomToken);
    List.SaveToStream(Bin,TEncoding.UTF8);
    FINALLY
      List.Free;
    END;

end;

end.
