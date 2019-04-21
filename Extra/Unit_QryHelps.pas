unit Unit_QryHelps;

interface
uses
Classes;
type

TEnums = (_Qry_CCStock,_Qry_Voucher);
TQryHelps = array [TEnums] of string;
const
TQryhelp:TQryHelps =
(('select  t1.FBillNO,T1.FDATE,t1.FSupplyID,t2.Fitemid,t2.FunitID,T2.')+
('FPrice,T2.FQty,t2.famount,T2.FINDEX from T_CC_StockBill t1 left join ')+
('T_CC_StockBillEntry t2 ')
+('on t1.FID = t2.FID'),
'select (CONVERT(Nvarchar(2),t1.iperiod)'+#43+#39+#45+#39+#43+
'CONVERT(Nvarchar(3),t1.isignseq)'+#43+#39+#45+#39+#43+
'CONVERT(Nvarchar(5),t1.ino_id)) as i_Key'+
',t1.i_id, t1.iperiod,t1.csign,t1.isignseq,t1.ino_id,t1.inid,'+
't1.dbill_date,t1.idoc,t1.cbill,t1.ccheck,t1.cbook,t1.ibook,t1.iflag,'+
't1.cdigest,t1.ccode,t3.ccode_name as codename,t1.cexch_name,'+
't1.md,t1.mc,t1.md_f,t1.mc_f,t1.nfrat,t1.nd_s,t1.nc_s,t1.csettle,'+
't1.cn_id,t1.dt_date,t1.cdept_id,'+
't1.cperson_id,t1.ccus_id,t4.cCusname,t1.csup_id,t5.cVenname,t1.citem_id,'+
't1.citem_class,t1.ccode_equal,t1.iflagbank,t1.iflagperson,t1.cdefine1,'+
't1.cdefine2,t1.cdefine3,t1.cdefine4,t1.cdefine5,t1.cdefine6,t1.cdefine7,'+
't1.cdefine8,t1.cdefine9,t1.cdefine10 '+
'from GL_accvouch t1 left join dsign t2 on t1.csign = t2.csign'+
' left join code t3 on t3.ccode = t1.ccode'+
' left join customer t4 on t4.cCuscode = t1.ccus_id'+
' left join Vendor t5 on t5.cVenCode = t1.csup_id' );

UFsysDB1:string = 'select cAcc_id from ua_account where cAcc_Name = ';

function DecodeFilter(Fs:string;out Flist:TStringList):Boolean;


implementation

function DecodeFilter(Fs:string;out Flist:TStringList):Boolean;
var
List:TStringList;
begin
     list:=TStringList.Create;
     TRY
     try
     List.StrictDelimiter := True;
     List.Delimiter:='?';
     List.DelimitedText:=Fs;
     if not (List.Count = 3) then
     begin
       Result :=False;
       Exit;
     end;
     Flist.Add(List[0]);
     Flist.Add(List[1]);
     Flist.Add(List[2]);
     Result:=True;
     finally
       List.Free;
     end;
     except
         Result:=False;
     END;



end;




end.
