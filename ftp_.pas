{$I STDEFINE.INC}
{$IFNDEF FTP} Этот модуль не должен использоваться! {$ENDIF}

unit Ftp_;

interface

uses
  Drives, Collect, Streams, defines, aslFTPClient
  , lfn
  ;

type
  TEncodeFunc = procedure(var s: string; const table);

{<ftp_.001>}
const
  nFtpConn = 10;
type
  iFtpConn = 0..nFtpConn; // 0 - "пустое" значение
  TFtpHost = record {описатель хоста (с паролем)}
    HostName: string; // включая логин
    Passw: string; // пароль
    ToRemoteCP, FromRemoteCP: TEncodeFunc;
    PToRemoteCP, PFromRemoteCP: Pointer;
    Connections: Integer; // число соединений
    Mlst, Mlsd: Boolean; // флаги сервера, полученные командой  FEAT
    end;
  TFtpConn = record {описатель соединения}
    Next: iFtpConn;
    Host: Integer; // позиция в массиве FtpHost
    Path: string;
    Prefix: string; // для IBM FTP Server это что-то вроде 'C:/ftproot'
    WD: string; // текущий каталог
    FTPCli: PFTPClient;
    end;
var
  FtpConn: array [1..nFtpConn] of TFtpConn;
  FreeFtp, OrphanFtp: iFtpConn;
  FtpHost: array [1..nFtpConn] of TFtpHost;

type
  PFtpFile = ^TFtpFile;
  {` файл на удалённом FTP-сервере }
  TFtpFile = object(lFile)
    constructor Init;
    procedure FindFirst(const Path: String;
      Attr: Word; var R: lSearchRec); virtual;
    procedure FindNext(var R: lSearchRec); virtual;
    procedure FindClose(var R: lSearchRec); virtual;
    procedure GetFileInfo(var lSR: lSearchRec);
    procedure GetFTime(var Time: Longint); virtual;
    procedure GetFAttr(var Attr: Longint); virtual;
    procedure Rename(const NewName: string); virtual;
    procedure Open(Mode: Word); virtual;
    procedure Seek(Pos: TFileSize); virtual;
    procedure SeekEOF; virtual;
    procedure Truncate; virtual;
    procedure Read(var Buf; Count: SW_Word; var Actual: SW_Word); virtual;
    procedure Write(const Buf; Count: SW_Word; var Actual: SW_Word); virtual;
    procedure Close; virtual;
    procedure Erase(Options: word); virtual;
    procedure MkDir; virtual;
    procedure ClearReadOnly; virtual;
    procedure RmDir; virtual;
    function DoRest: Boolean;
    destructor Done; virtual;
    end;
    {`}

function GetFtpConn(FtpPath: string {без 'ftp://'}): iFtpConn;
procedure FreeFtpConn(i: iFtpConn);
procedure OrphanFtpConn(var Handle: Integer);
procedure KeepAlive;

implementation
uses
  sysutils, Commands, dnApp, pdsetup, messages, Dos, strings,
  VPUtils, aslTCPSocket, aslAbsSocket
  , Objects2, advance1, advance2, memory, filescol
  , FlPanelx, u_keymap

  ;


var
  CurTime: DateTime;
  HostNum: Integer;

const
  month: array[1..12] of string[5] =
    (' JAN ', ' FEB ', ' MAR ', ' APR ', ' MAY ', ' JUN ',
     ' JUL ',  ' AUG ', ' SEP ', ' OCT ', ' NOV ', ' DEC ' );

procedure EncodeFromUTF(var s: string; const table);
  begin
  s := LongStrFromUtf(s);
  end;

procedure EncodeToUTF(var s: string; const table);
  begin
  s := LongStr2Utf(s);
  end;

procedure ParseListLine(const Msg: String; var SR: lSearchRec);
  { если неудача, то SR.FullName = '' }
  var
    i: Integer;
    l: TSize;
    T: DateTime;

  procedure SkipBlank;
    begin
    while (i <= Length(Msg)) and (Msg[i] = ' ') do
      inc(i);
    end;

  procedure SkipNonBlank;
    begin
    while (i <= Length(Msg)) and (Msg[i] <> ' ') do
      inc(i);
    end;

  procedure mmddyy;
    var
      Err: Longint;
    begin
    Val(Copy(Msg, i, 2), T.Month, Err);
    Val(Copy(Msg, i+3, 2), T.Day, Err);
    Val(Copy(Msg, i+6, 2), T.Year, Err);
    T.Year := (CurTime.Year div 100) * 100 + T.Year;
    if CurTime.Year < T.Year then
      Dec(T.Year, 100);
    inc(i, 9);
    SkipBlank;
    end;

  procedure hhmm;
    var
      Err: Longint;
    begin
    Val(Copy(Msg, i, 2), T.Hour, Err);
    Val(Copy(Msg, i+3, 2), T.Min, Err);
    end;

  procedure GetWord(var s: string);
    var
      j: Integer;
    begin
    j := i;
    SkipNonBlank;
    s := Copy(Msg, j, i-j);
    end;

  var
    s: String;
    Err: Longint;
    j, m: Integer;
    Dir, Link: Boolean;
  begin
  SR.FullName := '';
  SR.FullSize := 0;
  SR.SR.Attr := 0;
  s := Upstrg(Msg);
  if (Msg = '') or (Copy(s, 1, 5) = 'TOTAL') then
    Exit;
  Dir := False;
  Link := False;
  i := 1;
  if Msg[1] in ['0'..'9'] then
    begin {============ MS FTP Service
08-05-09  01:38PM       <DIR>          mspress
05-20-96  07:47PM                 1715 readme.txt
mm-dd-yy }
    mmddyy;
    hhmm;
    if Copy(Msg, i+5, 2) = 'PM' then
      inc(T.Hour, 12);
    SkipNonBlank;
    SkipBlank;
    { сейчас <DIR> для каталога или длина для файла }
    GetWord(s);
    if s = '<DIR>' then
      SR.SR.Attr := $10 // Directory
    else
      Val(s, SR.FullSize, Err);
    SkipBlank;
    end
  else if Msg[1] = ' ' then
    begin {============ IBM OS/2 FTP Server:
                      0           DIR   10-19-09   06:21  moveton
                 903079      A          04-03-10   16:20  os2krnlSVN2185_unoff.zip
                                        mm-dd-yy
}
    SkipBlank;
    GetWord(s);
    Val(s, SR.FullSize, Err);
    inc(i, 11); // пропускаем атрибуты
    s := Copy(Msg, i, 3);
    if Copy(Msg, i, 3) = 'DIR' then
      SR.SR.Attr := $10; // Directory
    inc(i, 3);
    SkipBlank;
    mmddyy;
    hhmm;
    SkipNonBlank;
    SkipBlank;
    end
  else
    begin { ============= прочие форматы, все они начинаются с U
      и заканчиваются на L TU N}
    case Msg[1] of
     '-':
       ;
     'd':
      Dir := True;
     'l':
      Link := True;
     else
      Exit;
    end {case};
    s := Copy(s, 12, 255);
    T.Month := 0;
    for j := 1 to 12 do
      begin
      i := Pos(month[j], s);
      if i <> 0 then
        begin
        T.Month := j;
        Break;
        end;
      end;
    if T.Month = 0 then
      Exit; // странная строчка, не нашли дату
    { Сейчас i указывает в s на месяц, перед этим длина }
    if Dir then
      SR.SR.Attr := $10 // Directory
    else
      begin
      l := 1;
      j := i;
      while s[j-1] in Digits do
        begin
        dec(j);
        SR.FullSize :=
          SR.FullSize + l*(byte(s[j])-byte('0'));
        l := l*10;
        end;
      end;
    { сейчас в Msg, начаная от [i+11], будет дата-время и затем имя }
    inc(i, 11); // месяц
    inc(i, 5); // месяц
    SkipBlank;
    j := i;
    SkipNonBlank; // число
    Val(Copy(Msg, j, i-j), T.Day, Err);
    SkipBlank;
    j := i;
    SkipNonBlank; // год или время
    s := Copy(Msg, j, i-j);
    j := Pos(':', s);
    if j = 0 then
      begin // год
      Val(s, T.Year, Err);
      T.Hour := 0;
      T.Min := 0;
      end
    else
      begin // время
      T.Year := CurTime.Year;
      if (CurTime.Month < T.Month) or
         ((CurTime.Month = T.Month) and (CurTime.Day < T.Day))
      then
        Dec(T.Year);
      Val(Copy(s, 1, j-1), T.Hour, Err);
      Val(Copy(s, j+1, 255), T.Min, Err);
      end;
    T.Sec := 0;
    SkipBlank; // Msg[i] и далее - имя
    end;

  PackTime(T, SR.SR.Time);
  s := Copy(Msg, i, 255);
  SR.FullName := s;
  SR.SR.Name := Copy(s, 1, 11);
  end;

const
  fmInput  = $00010000;
  fmOutput = $00020000;

constructor TFtpFile.Init;
  begin
  inherited Init;
  AllMask := '';
  RestPos := -1;
  MaxDataBlock := 32*1024;
  end;

var
  nCntrlMsg: Integer;
  CntrlMsg: array[0..100] of String;

procedure GetCntrlMsg(const Msg: string);
  begin
  with FtpHost[HostNum] do
    begin
    CntrlMsg[nCntrlMsg] := Msg;
    Replace(#$FF#$FF, #$FF, CntrlMsg[nCntrlMsg]);
    FromRemoteCP(CntrlMsg[nCntrlMsg], PFromRemoteCP^);
    inc(nCntrlMsg);
    end;
  end;

procedure TFtpFile.FindFirst(const Path: String;
    Attr: Word; var R: lSearchRec);
  var
    s: string;
    NewWD: string;
    i: Integer;
    dummy1: word;
    Label Ex;
  begin
  //!! надо бы использовать биты Directory у Attr
  s := Copy(Path, 7, 255);
  Handle := GetFtpConn(s);
  if Handle = 0 then
    begin
    DosError := 21; // ERROR_NOT_READY
    Exit;
    end;
  with FtpConn[Handle] do
    begin
    HostNum := Host;
    DosError := 3; // ERROR_PATH_NOT_FOUND
    if Path = '' then
       s := '/'
    else
      begin
      s := Path;
      Replace('\', '/', s);
      Replace(#$FF, #$FF#$FF, s);
      FtpHost[Host].ToRemoteCP(s, FtpHost[Host].PToRemoteCP^);
      end;
    s := Prefix + s;
  if (Attr = DirOnly) then
    begin { Реально такой вариант поиска используется только
      для проверки существования конкретного каталога.
      При этом Path не содержит джокеров, и за FindFirst
      сразу же следует FindClose, без FundNext.
        На большинстве ftp-серверов операция list имя-файла
      не поддерживается, вопреки rfc. Делать list для объемлющего
      каталога и искать  там указанный каталог - может быт очень
      долго. Поэтому проверяем наличие данного каталга путём
      установления его текущим. }
    if FtpConn[Handle].FTPCli^.Cwd(s) then
      begin
      DosError := 0;
      R.FullName := s;
      R.FullSize := 0;
      R.SR.Attr := Directory;
      end
    else
      begin
      if FtpConn[Handle].FTPCli^.LastResponseCode = 550 then
        DosError := 5 // ERROR_ACCESS_DENIED
      end;
    goto Ex;
    end;

    GetDate(CurTime.Year, CurTime.Month, CurTime.Day, dummy1);
    i := Length(s);
    while (i > 0) and (s[i] <> '/') do
      dec(i);
    if i <> 0 then
      begin
      NewWD := Copy(s, 1, i);
      if NewWD <> WD then
        begin
        if not FTPCli^.Cwd(Copy(s, 1, i)) then
          Exit;
        WD := NewWD;
        end;
      delete(s, 1, i);
      end;
    try
      if FTPCli^.StartList(s) then
        FindNext(R);
    except
     on E: Exception do
      begin
      MessageBox(E.Message, nil, mfOKButton or mfError);
      DosError := 21; // ERROR_NOT_READY
      end;
    end;

    end;
Ex:
  LastFindDir := 'ftp:\\' +
    FtpHost[FtpConn[Handle].Host].HostName + FtpConn[Handle].Path;
  end;

procedure TFtpFile.FindNext(var R: lSearchRec);
  var
    s: string;
  begin
  DosError := 0;
  with FtpConn[Handle].FTPCli do
    begin
    repeat
      if not DataSocket.Connected then
        begin
        DosError := 18; // ERROR_NO_MORE_FILES
        Break;
        end
      else
        begin
        DataSocket.ReadLn(s);
        with  FtpHost[FtpConn[Handle].Host] do
          FromRemoteCP(s, PFromRemoteCP^);
        ParseListLine(s, R);
        end;
      until R.FullName <> ''
    end;
  end;

procedure TFtpFile.FindClose(var R: lSearchRec);
  begin
  OrphanFtpConn(Handle);
  end;

procedure TFtpFile.GetFileInfo(var lSR: lSearchRec);
  begin
  FindFirst(StrPas(FNameZ), AnyFileDir, lSR);
  FindClose(lSR);
  end;

procedure TFtpFile.GetFTime(var Time: Longint);
  var
    lSR: lSearchRec;
  begin
  GetFileInfo(lSR);
  if DosError <> 0 then
    Time := 0
  else
    Time := lSR.SR.Time;
  end;

procedure TFtpFile.GetFAttr(var Attr: Longint);
  var
    lSR: lSearchRec;
  begin
  FillChar(lSR, SizeOf(lSR), 0);
  GetFileInfo(lSR);
  if DosError <> 0 then
    Attr := 0
  else
    Attr := lSR.SR.Attr;
  end;

procedure TFtpFile.Rename(const NewName: string);
  var
    s, NewS: string;
    l: Integer;
  begin
  s := StrPas(FNameZ+6);
  Handle := GetFtpConn(s);
  if Handle = 0 then
    begin
    InOutRes := 21; // ERROR_NOT_READY
    Exit;
    end;
  l := Pos('\', s);
  s := Copy(s, l, 255);
  Replace('\', '/', s);
  Replace(#$FF, #$FF#$FF, s);
  with  FtpHost[FtpConn[Handle].Host] do
    begin
    ToRemoteCP(s, PToRemoteCP^);
    s := FtpConn[Handle].Prefix + s;
    end;
  NewS := Copy(NewName, 7, 255);
  l := Pos('\', NewS);
  NewS := Copy(NewS, l, 255);
  Replace('\', '/', NewS);
  Replace(#$FF, #$FF#$FF, NewS);
  with  FtpHost[FtpConn[Handle].Host] do
    ToRemoteCP(NewS, PToRemoteCP^);
  NewS := FtpConn[Handle].Prefix + NewS;
  try
    FtpConn[Handle].FTPCli^.RnFr(s);
    FtpConn[Handle].FTPCli^.RnTo(NewS);
  except
   on E: Exception do
    begin
    if FtpConn[Handle].FTPCli^.LastResponseCode = 550 then
      InOutRes := 5 // ERROR_ACCESS_DENIED
    end;
  end;
  OrphanFtpConn(Handle);
  end;

procedure TFtpFile.Open(Mode: Word);
  var
    lSR: lSearchRec;
  begin
  RestPos := -1;
  FMode := Mode;
//  GetFileInfo(lSR);
  FindFirst(StrPas(FNameZ), AnyFileDir, lSR);
  FtpConn[Handle].FTPCli^.EndData;
  FSize := lSR.FullSize;
  FPos := 0;
  end;

procedure TFtpFile.Seek(Pos: TFileSize);
  begin
  if FPos = Pos then
    Exit;
  RestPos := Pos;
  FPos := Pos;
  end;

procedure TFtpFile.SeekEOF;
  begin
  RestPos := FSize;
  end;

procedure TFtpFile.Truncate;
  begin
  end;

procedure TFtpFile.Read(var Buf; Count: SW_Word; var Actual: SW_Word);
  var
    l: Longint;
    PBuf: PChar;
    s: string;
  begin
  DoRest;
  if FMode and $FFFF0000 = 0 then
    begin
    FMode := FMode or fmInput;
    with FtpConn[Handle] do
      begin
      s := Path;
      Replace('\', '/', s);
      Replace(#$FF, #$FF#$FF, s);
      with  FtpHost[FtpConn[Handle].Host] do
        ToRemoteCP(s, PToRemoteCP^);
      s := Prefix + s;
      FTPCli^.Type_('I');
      try
        FTPCli^.StartRetr(s);
      except
       on E: Exception do
        begin
        MessageBox(E.Message, nil, mfOKButton or mfError);
        InOutRes := 5; // ERROR_ACCESS_DENIED
        end;
      end;
      end;
    end;
  if InOutRes <> 0 then
    Exit;
  PBuf := @Buf;
  Actual := 0;
  while Count <> 0 do
    begin
    try
      l := FtpConn[Handle].FTPCli^.DataSocket.Read(PBuf^, Count);
    except
     on E: Exception do
      begin
      MessageBox(E.Message, nil, mfOKButton or mfError);
      InOutRes := 5; // ERROR_ACCESS_DENIED
      l := 0;
      end;
    end;
    if l = 0 then
      Break;
    inc(Actual, l);
    dec(Count, l);
    inc(PBuf, l);
    FPos := FPos + l;
    if FPos > FSize then
      FSize := FPos;
    end;
  end;

procedure TFtpFile.Write(const Buf; Count: SW_Word; var Actual: SW_Word);
  var
    l: Longint;
    PBuf: PChar;
    s: string;
    l1: Longint;
  begin
  DoRest;
  if FMode and $FFFF0000 = 0 then
    begin
    FMode := FMode or fmOutput;
    with FtpConn[Handle] do
      begin
      s := Path;
      Replace('\', '/', s);
      Replace(#$FF, #$FF#$FF, s);
      with  FtpHost[FtpConn[Handle].Host] do
        ToRemoteCP(s, PToRemoteCP^);
      s := Prefix + s;
      FTPCli^.Type_('I');
      try
        FTPCli^.StartStor(s);
      except
       on E: Exception do
        begin
          MessageBox(E.Message, nil, mfOKButton or mfError);
          FTPCli^.CloseDataSocket;
          InOutRes := 05; //
          Exit;
        end;
      end;
      end;
    end;
  PBuf := @Buf;
  Actual := 0;
  while Count <> 0 do
    begin
    l1 := Min(Count, MaxDataBlock);
    try
      l := FtpConn[Handle].FTPCli^.DataSocket.Write(PBuf^, l1);
    except
     on E: Exception do
      begin
        MessageBox(E.Message, nil, mfOKButton or mfError);
        FtpConn[Handle].FTPCli^.CloseDataSocket;
        InOutRes := 05; //
        Exit;
      end;
    end;
    if l = 0 then
      Break;
    inc(Actual, l);
    dec(Count, l);
    inc(PBuf, l);
    FPos := FPos + l;
    FSize := FPos;
    end;
  end;

procedure TFtpFile.Close;
  begin
  if FMode and $FFFF0000 <> 0 then
    begin
    FtpConn[Handle].FTPCli^.EndData;
    FMode := 0;
    OrphanFtpConn(Handle);
    end;
  end;

procedure TFtpFile.Erase(Options: word);
  var
    s: string;
  begin
  s := StrPas(FNameZ+6);
  Handle := GetFtpConn(s);
  if Handle = 0 then
    begin
    InOutRes := 21; // ERROR_NOT_READY
    Exit;
    end;
  s := Copy(s, Pos('\', s), 255);
  Replace('\', '/', s);
  Replace(#$FF, #$FF#$FF, s);
  with  FtpHost[FtpConn[Handle].Host] do
    ToRemoteCP(s, PToRemoteCP^);
  s := FtpConn[Handle].Prefix + s;
  try
    FtpConn[Handle].FTPCli^.Dele(s);
  except
   on E: Exception do
    begin
//    if FtpConn[Handle].FTPCli^.LastResponseCode = 550 then
      InOutRes := 5 // ERROR_ACCESS_DENIED
    end;
  end;
  OrphanFtpConn(Handle);
  end;

procedure TFtpFile.MkDir;
  var
    s: string;
  begin
  s := StrPas(FNameZ+6);
  Handle := GetFtpConn(s);
  if Handle = 0 then
    begin
    InOutRes := 21; // ERROR_NOT_READY
    Exit;
    end;
  s := Copy(s, Pos('\', s), 255);
  Replace('\', '/', s);
  Replace(#$FF, #$FF#$FF, s);
  with  FtpHost[FtpConn[Handle].Host] do
    ToRemoteCP(s, PToRemoteCP^);
  s := FtpConn[Handle].Prefix + s;
  try
    FtpConn[Handle].FTPCli^.MkD(s);
  except
   on E: Exception do
    begin
//    if FtpConn[Handle].FTPCli^.LastResponseCode = 550 then
      InOutRes := 5 // ERROR_ACCESS_DENIED
    end;
  end;
  OrphanFtpConn(Handle);
  end;

procedure TFtpFile.ClearReadOnly;
  begin // на ftp нет такого атрибута
  end;

procedure TFtpFile.RmDir;
  var
    s: string;
  begin
  s := StrPas(FNameZ+6);
  Handle := GetFtpConn(s);
  if Handle = 0 then
    begin
    InOutRes := 21; // ERROR_NOT_READY
    Exit;
    end;
  s := Copy(s, Pos('\', s), 255);
  Replace('\', '/', s);
  Replace(#$FF, #$FF#$FF, s);
  with  FtpHost[FtpConn[Handle].Host] do
    ToRemoteCP(s, PToRemoteCP^);
  s := FtpConn[Handle].Prefix + s;
  try
    FtpConn[Handle].FTPCli^.RmD(s);
  except
   on E: Exception do
    begin
    InOutRes := 5 // ERROR_ACCESS_DENIED
    end;
  end;
  OrphanFtpConn(Handle);
  end;

function TFtpFile.DoRest: Boolean;
  var
    s: string;
  begin
  result := True;
  if RestPos <> -1 then
    begin
    result := True;
    Str(RestPos:0:0, s);
    FtpConn[Handle].FTPCli^.Rest(s);
    result := (FtpConn[Handle].FTPCli^.LastResponseCode = 350);
    if Result then
      FMode := FMode and $0000FFFF;
    RestPos := -1;
    end;
  end;

destructor TFtpFile.Done;
  begin
  OrphanFtpConn(Handle);
  inherited Done;
  end;

procedure InitFtpConn;
  var
    i: Integer;
  begin
  for i := 1 to nFtpConn-1 do
    FtpConn[i].Next := i+1;
  FreeFtp := 1;
  end;

var
  Password: string;
  km: TKeyMap; // номер кодировки

function GetPassw: string;
  begin
  if Password = '' then
    begin
    if ExecResource(dlgSetPassword, Password) <> cmOK then
       Password := 'dn@osp';
    end;
  Result := Password;
  end;

function GetFtpConn(FtpPath: string {без 'ftp://'}): iFtpConn;
  var
    i, l1, l2: Integer;
    P: ^iFtpConn;
    NewHost: string;
    Login, s: string;
  label
    TryConnect, Connected;
  begin
  Replace('/', '\', FtpPath);
  Login := 'anonymous';
  Password := 'dn@osp';
  { Ищем последний '@' - это разделитель логина и хоста. Перед
   этим может быть пароль вида 'dn@osp', пожтому ищем не первый,
   а последний '@' }
  l1 := Length(FtpPath);
  while l1 <> 0 do
    begin
    if FtpPath[l1] = '@' then
      Break;
    Dec(l1);
    end;
  if l1 <> 0 then
    begin
    Login := copy(FtpPath, 1, l1-1);
    system.delete(FtpPath, 1, l1);
    i := PosChar(':', Login);
    if i <> 0 then
      begin
      Password := Copy(Login, i+1, 255);
      SetLength(Login, i-1);
      end
    else
      Password := '';
    end;
  km := kmNone;
  l1 := Pos('>', FtpPath);
  if l1 <> 0 then
    begin
    s := Copy(FtpPath, l1+1, 3);
    delete(FtpPath, l1, 4);
    UpStrg(s);
    km := ProcessDefCodepage(s);
    end;
  l2 := PosChar('\', FtpPath);
  if l2 = 0 then
    l2 := Length(FtpPath)+1;
  NewHost := Copy(FtpPath, 1, l2-1);
  s := Login + '@' + NewHost;
  HostNum := 0;
  for i := High(FtpHost) downto Low(FtpHost) do
    begin
    if (FtpHost[i].Connections <> 0) and (FtpHost[i].HostName = s) then
      begin
      HostNum := i;
      Break;
      end;
    end;
  if HostNum = 0 then
    for i := Low(FtpHost) to High(FtpHost) do
      with FtpHost[i] do
        if Connections = 0 then
          begin
          HostName := s;
          Passw := Password;
          HostNum := i;
          if km = kmNone then
            km := kmAscii;
          Break;
          end;
  if HostNum = 0 then
    begin
    Result := 0;
    Exit;
    end;

  if km <> kmNone then
    with FtpHost[HostNum] do
      if km = kmUtf8 then
        begin
        @ToRemoteCP := @EncodeToUTF;
        PToRemoteCP := nil;
        @FromRemoteCP := @EncodeFromUTF;
        PFromRemoteCP := nil;
        end
      else
        begin
        @ToRemoteCP := @XLatStr;
        PToRemoteCP := @KeyMapDescr[km].XlatCP^[FromAscii];
        @FromRemoteCP := @XLatStr;
        PFromRemoteCP := @KeyMapDescr[km].XlatCP^[ToAscii];
        end;
  { ищем осиротевший элемент с нужным хостом }
  P := @OrphanFtp;
  while P^ <> 0 do
    begin
    if FtpConn[P^].Host = HostNum then
      begin
      Result := P^;
      P^ := FtpConn[Result].Next;
      FtpConn[Result].Path := Copy(FtpPath, l2, 255);
      goto Connected;
      end;
    P := @FtpConn[P^].Next;
    end;
  { Не нашли. Занимаем свободный }
  if FreeFtp = 0 then
    begin  { Свободных нет. Освобождаем осиротевший. }
    if OrphanFtp <> 0 then
      begin
      Result := OrphanFtp;
      OrphanFtp := FtpConn[Result].Next;
      FreeFtpConn(Result);
      end;
    end;
  { Теперь таки занимаем свободный }
  Result := FreeFtp;
  if FreeFtp <> 0 then
    begin
    with FtpConn[Result] do
      begin
      FreeFtp := Next;
      Host := HostNum;

TryConnect:

      New(FTPCli, Init);
      Host := HostNum;
      Path := Copy(FtpPath, l2, 255);
      FTPCli^.Passive:=True;
      Password := FtpHost[HostNum].Passw;
      try
        FTPCli^.Connect(NewHost, Login, GetPassw);
      except
       on E: Exception do
        begin
        s := E.Message;
        FreeFtpConn(Result);
        Result := 0;
        end;
      end {try};
      end;
    if Result = 0 then
      begin
      MessageBox(s, nil, mfOKButton or mfError);
      end
    else
      begin
      with FtpHost[HostNum] do
        begin
        if Connections = 0 then
          begin
          Passw := Password;
          with FtpConn[Result].FTPCli^ do
            begin
            PrePassive := False;
            nCntrlMsg := 0;
            SendCommandEx('FEAT', GetCntrlMsg);
            for i := 0 to nCntrlMsg-1 do
              begin
              if CntrlMsg[i] = ' UTF8' then
                begin
                km := kmUtf8;
                @ToRemoteCP := @EncodeToUTF;
                PToRemoteCP := nil;
                @FromRemoteCP := @EncodeFromUTF;
                PFromRemoteCP := nil;
                end
              else if Copy(CntrlMsg[i], 1, 5) = ' MLST' then
                Mlst := True
              else if CntrlMsg[i] = ' MLSD' then
                Mlsd := True
              end;
            end;
          end;
        inc(Connections);
        end;
      s := FtpConn[Result].FTPCli^.PWD;
      if s[Length(s)] = '/' then
        SetLength(s, Length(s)-1);
      Replace(#$FF#$FF, #$FF, s);
      FtpConn[Result].Prefix := s;
      FtpConn[Result].WD := '';
      end;
    end;
Connected:
  end;

procedure FreeFtpConn(i: iFtpConn);
  begin
  if i <> 0 then
    with FtpConn[i] do
      begin
      try
        FTPCli^.Free;
      except
        on E: Exception do
          ;
      end;
      FTPCli := nil;
      Dec(FtpHost[Host].Connections);
      Next := FreeFtp;
      FreeFtp := i;
      end;
  end;

procedure OrphanFtpConn(var Handle: Integer);
  begin
  if Handle <> 0 then
    begin
    with FtpConn[Handle] do
      begin
      FTPCli^.EndData;
      Next := OrphanFtp;
      end;
    OrphanFtp := Handle;
    Handle := 0;
    end;
  end;

function FtpFileInit(var F: lFile; const Name: String): Boolean;
  begin
  Result := IsFtpAddr(Name);
  if Result then
    TFtpFile(F).Init;
  end;

procedure KeepAlive;
  var
    Prev: ^iFtpConn;
  begin
  Prev := @OrphanFtp;
  while Prev^ <> 0 do with FtpConn[Prev^] do
    begin
    if FTPCli^.KeepAlive then
      Prev := @Next
    else
      begin
      Prev^ := Next;
      FreeFtpConn(Prev^);
        { Выдавать тут сообщение не очень нужно, а главное,
        не очень можно, так как пока окошко ообщения будет висеть,
        KeepAlive может опять выоваться. Если очень уж надо выдать
        сообщение, то это надо делать через PutEvent, а не выдавать
        прямо тут.  }
      end;
    end;
  end;

begin
InitFtpConn;
RegisterFileInit(FtpFileInit);
end.

