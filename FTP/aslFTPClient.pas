{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.4 $    $Date: 2002/09/30 20:32:51 $    $Author: sag $ }
{                                                                             }
{ File Transfer Protocol (FTP) client class (RFC 959)                         }
UNIT aslFTPClient;

INTERFACE

USES aslSocket, aslAbsSocket, aslAbsClient, aslTCPSocket;

type
  StringFunction = function: string;

TYPE
  TFTPWriteFileProc = PROCEDURE(VAR Buffer; Size: Integer);
  TFTPReadFileProc  = FUNCTION(VAR Buffer; Size: Integer; VAR Actual: Integer): Boolean;


  EAbsFTPClient = CLASS(EaslException);

  TAbsFTPClient = object(TAbsClient)
  PUBLIC
    Passive    : Boolean;
    PrePassive: boolean; // PASV уже выдана заранее
    DataSocket : PTCPClientSocket;
    DataPort   : String;
    DataIP     : String;
    FUNCTION ConnectDataSocket: Integer;
    FUNCTION CloseDataSocket: Integer;
    CONSTRUCTOR Init;
    DESTRUCTOR Done; virtual;
    PROCEDURE Connect(AHost: STRING);

{ Standard commands }
    PROCEDURE User(Name: String);
    PROCEDURE Pass(Password: String);
    PROCEDURE Acct(AccountInfo: String);
    function Cwd(Path: String): Boolean;
    PROCEDURE CdUp;
    PROCEDURE SMnt(Path: String);
    PROCEDURE ReIn;
    PROCEDURE Quit;

    PROCEDURE Port(APort: String); VIRTUAL; { x,x,x,x,y,y (x=hostno, y=portno) }
    PROCEDURE Pasv; VIRTUAL;
    PROCEDURE Type_(AType: String);     { A[<sp> N | T |C ] |
                                          E[<sp> N | T |C ] |
                                          I |
                                          L <byte-size>}
    PROCEDURE Stru(Structure: String);  { F | R | P }
    PROCEDURE Mode(AMode: String);      { S | B | C }

    procedure StartRetr(RemoteFileName: String);
    PROCEDURE Retr(RemoteFileName: String; WriteProc: TFTPWriteFileProc);
    function EndData: Boolean;
    procedure StartStor(RemoteFileName: String);
    PROCEDURE Stor(RemoteFileName: String; ReadProc: TFTPReadFileProc);
    FUNCTION  StoU(ReadProc: TFTPReadFileProc): String;
    PROCEDURE Appe(FileName: String; ReadProc: TFTPReadFileProc);
    PROCEDURE Allo(Size, RecSize: LongInt);
    PROCEDURE Rest(From: String);
    PROCEDURE RnFr(FromName: String);
    PROCEDURE RnTo(ToName: String);
    PROCEDURE Abor;
    PROCEDURE Dele(FileName: String);
    PROCEDURE RmD(Path: String);
    PROCEDURE MkD(Path: String);
    FUNCTION  PwD: String;
    function StartList(FileSpec: String): Boolean;
    PROCEDURE List(FileSpec: String; DirList: TExtra);
    PROCEDURE NLst(FileSpec: String; DirList: TExtra);
    PROCEDURE Site(Cmd: String);
    FUNCTION  Syst: String;
    PROCEDURE Stat(FileSpec: String; StatInfo: TExtra);
    PROCEDURE Help(Command: String; HelpInfo: TExtra);
    PROCEDURE Noop;
    function KeepAlive: Boolean;
  END;

  PFTPClient = ^TFTPClient;
  TFTPClient = Object(TAbsFTPClient)
  PUBLIC
    PROCEDURE Connect(AHost, Name: string; Password: StringFunction);
    PROCEDURE Port(APort: String); virtual;
    PROCEDURE Pasv; virtual;
  END;

const
  KeepAliveInterval = 2*60*1000; // milliseconds

IMPLEMENTATION

USES
  advance1, Objects2
{$IFDEF OS2}
     ,OS2Socket, sockin, netdb, Utils
{$ELSE}
     ,Winsock
{$ENDIF}
  , Events
;


FUNCTION NextWordDelim(VAR s: STRING; Delim: Char): STRING;
VAR
  p  : Byte;
BEGIN
  p:=Pos(Delim,s);
  IF p>0 THEN
  BEGIN
    NextWordDelim:=Copy(s, 1, p-1);
    Delete(s, 1, p);
    DelLeft(s);
  END ELSE
  BEGIN
    NextWordDelim:=s;
    s:='';
  END;
END;

{ TAbsFTPClient }

  CONSTRUCTOR TAbsFTPClient.Init;
  BEGIN
    INHERITED Init;
    Passive:=False;
    DataPort:='ftp-data';
  END;

  DESTRUCTOR TAbsFTPClient.Done;
  BEGIN
    IF Assigned(Socket) THEN
      Quit;
    INHERITED Done;
  END;

  PROCEDURE TAbsFTPClient.Connect(AHost: STRING);
  BEGIN
    Host:=AHost;
    Socket.ConnectT(Host, 'ftp');
    GetResponse(Nil);
    IF LastResponseCode<>220 THEN
      RAISE EAbsFTPClient.Create('Connect: Error connecting to server.', LastResponse);
  END;


  PROCEDURE TAbsFTPClient.User(Name: String);
  BEGIN
    SendCommand('USER '+Name);
    IF (LastResponseCode<>230) AND (LastResponseCode<>331) THEN
      RAISE EAbsFTPClient.Create('User', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Pass(Password: String);
  BEGIN
    SendCommand('PASS '+Password);
    IF (LastResponseCode<>230) AND (LastResponseCode<>202) THEN
      RAISE EAbsFTPClient.Create('Pass', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Acct(AccountInfo: String);
  BEGIN
    SendCommand('ACCT '+AccountInfo);
    IF (LastResponseCode<>230) AND (LastResponseCode<>202) THEN
      RAISE EAbsFTPClient.Create('Acct', LastResponse);
    PrePassive := False;
  END;

  function TAbsFTPClient.Cwd(Path: String): Boolean;
  BEGIN
    SendCommand('CWD '+Path);
    Result := (LastResponseCode = 250);
//     THEN
//      RAISE EAbsFTPClient.Create('Cwd', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.CdUp;
  BEGIN
    SendCommand('CDUP');
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('CdUp', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.SMnt(Path: String);
  BEGIN
    SendCommand('SMNT '+Path);
    IF (LastResponseCode<>202) AND (LastResponseCode<>250) THEN
      RAISE EAbsFTPClient.Create('SMnt', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.ReIn;
  BEGIN
    SendCommand('REIN');
    IF (LastResponseCode<>120) AND (LastResponseCode<>220) THEN
      RAISE EAbsFTPClient.Create('ReIn', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Quit;
  BEGIN
    if Socket^.Connected then
      begin
      EndData;
      SendCommand('QUIT');
      IF LastResponseCode=226 {Transfer complete} THEN
        GetResponse(Nil);
      IF LastResponseCode<>221 THEN
        RAISE EAbsFTPClient.Create('Quit', LastResponse);
      end;
    FreeObject(Socket);
  END;


  PROCEDURE TAbsFTPClient.Port(APort: String);
  BEGIN
    SendCommand('PORT '+APort);
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('Port', LastResponse);

    DataIP:=NextWordDelim(APort,',');
    DataIP:=DataIP+'.'+NextWordDelim(APort,',');
    DataIP:=DataIP+'.'+NextWordDelim(APort,',');
    DataIP:=DataIP+'.'+NextWordDelim(APort,',');

    DataPort:=ItoS(StoI(NextWordDelim(APort,','))*256+StoI(APort));
  END;

  PROCEDURE TAbsFTPClient.Pasv;
  VAR
    S         : String;
    StartPos,
    EndPos    : Integer;
  BEGIN
    if PrePassive then
      begin
      PrePassive := False;
      Exit;
      end;
    Passive:=True;
    SendCommand('PASV');
    IF LastResponseCode<>227 THEN
      RAISE EAbsFTPClient.Create('Pasv', LastResponse);

    StartPos:=Pos('(', LastResponse)+1;
    EndPos:=Pos(')', LastResponse);

    S:=Copy(LastResponse, StartPos, EndPos-Pos('(', LastResponse)-1);
    DataIP:=NextWordDelim(S,',');
    DataIP:=DataIP+'.'+NextWordDelim(S,',');
    DataIP:=DataIP+'.'+NextWordDelim(S,',');
    DataIP:=DataIP+'.'+NextWordDelim(S,',');

    DataPort:=ItoS(StoI(NextWordDelim(S,','))*256+StoI(S));
    PrePassive := True;
  END;

  PROCEDURE TAbsFTPClient.Type_(AType: String);
  BEGIN
    SendCommand('TYPE '+AType);
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('Type', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Stru(Structure: String);
  BEGIN
    SendCommand('STRU '+Structure);
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('Stru', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Mode(AMode: String);
  BEGIN
    SendCommand('MODE '+AMode);
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('Mode', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.StartRetr(RemoteFileName: String);
    begin
SockLogLine('StartRetr ' + RemoteFileName);
    IF Passive THEN Pasv ELSE Port('');
    SendCommand('RETR '+RemoteFileName);
    IF (LastResponseCode<>125) AND (LastResponseCode<>150) THEN
      begin
      CloseDataSocket;
      RAISE EAbsFTPClient.Create('Retr', LastResponse);
      end;
    IF Not Passive THEN
      ConnectDataSocket;
    end;

  PROCEDURE TAbsFTPClient.Retr(RemoteFileName: String; WriteProc: TFTPWriteFileProc);
  VAR
    Act : Integer;
    Buf : ARRAY[0..1023] OF Byte;
  BEGIN
    StartRetr(RemoteFileName);
// bin/txt mode?
    TRY
      REPEAT
        Act:=DataSocket.Read(Buf, SizeOf(Buf));
        WriteProc(Buf, Act);
      UNTIL Act=0;
    EXCEPT
      ON e: ETCPClientSocket DO ;
      ELSE RAISE;
    END;
    IF not EndData THEN
      RAISE EAbsFTPClient.Create('Retr (Getting data)', LastResponse);
  END;

  function TAbsFTPClient.EndData: Boolean;
    BEGIN
SockLogLine('EndData');
    if DataSocket <> nil then
      begin
      CloseDataSocket;
      GetResponse(Nil);
      Result := (LastResponseCode = 226) or (LastResponseCode = 250);
      end;
    PrePassive := False;
    END;

  procedure TAbsFTPClient.StartStor(RemoteFileName: String);
    begin
SockLogLine('StartStor ' + RemoteFileName);
    IF Passive THEN Pasv ELSE Port('');
    SendCommand('STOR '+RemoteFileName);
    IF (LastResponseCode<>125) AND (LastResponseCode<>150) THEN
      RAISE EAbsFTPClient.Create('Stor', LastResponse);
    IF Not Passive THEN
      ConnectDataSocket;
    end;

  PROCEDURE TAbsFTPClient.Stor(RemoteFileName: String; ReadProc: TFTPReadFileProc);
  VAR
    Buf : ARRAY[0..1023] OF Byte;
    Act : Integer;
  BEGIN
    StartStor(RemoteFileName);
    WHILE ReadProc(Buf, SizeOf(Buf), Act) DO
      DataSocket.Write(Buf, Act);
    if Act <> 0 then
      DataSocket.Write(Buf, Act);
    EndData;
    PrePassive := False;
  END;

  FUNCTION TAbsFTPClient.StoU(ReadProc: TFTPReadFileProc): String;
  VAR
    Buf : ARRAY[0..1023] OF Byte;
    Act : Integer;
  BEGIN
    IF Passive THEN Pasv ELSE Port('');
    SendCommand('STOU');
    IF (LastResponseCode<>125) AND (LastResponseCode<>150) THEN
      RAISE EAbsFTPClient.Create('', LastResponse);

    IF Not Passive THEN ConnectDataSocket;

    WHILE ReadProc(Buf, SizeOf(Buf), Act) DO
      DataSocket.Write(Buf, Act);

    CloseDataSocket;
    GetResponse(Nil);
    IF (LastResponseCode<>226) AND (LastResponseCode<>250) THEN
      RAISE EAbsFTPClient.Create('StoU (Saving data)', LastResponse);
    StoU:=Copy(LastResponse, 5, Pos('"', LastResponse)-6);
  END;

  PROCEDURE TAbsFTPClient.Appe(FileName: String; ReadProc: TFTPReadFileProc);
  VAR
    Buf : ARRAY[0..1023] OF Byte;
    Act : Integer;
  BEGIN
    IF Passive THEN Pasv ELSE Port('');
    SendCommand('APPE '+FileName);
    IF (LastResponseCode<>125) AND (LastResponseCode<>150) THEN
      RAISE EAbsFTPClient.Create('Appe', LastResponse);

    IF Not Passive THEN ConnectDataSocket;

    WHILE ReadProc(Buf, SizeOf(Buf), Act) DO
      DataSocket.Write(Buf, Act);

    CloseDataSocket;
    GetResponse(Nil);
    IF (LastResponseCode<>226) AND (LastResponseCode<>250) THEN
      RAISE EAbsFTPClient.Create('Appe (Saving data)', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Allo(Size, RecSize: LongInt);
  VAR
    S : String;
  BEGIN
    IF Passive THEN Pasv ELSE Port('');
    IF RecSize<>0 THEN S:=' R '+ItoS(RecSize) ELSE S:='';
    SendCommand('ALLO '+ItoS(Size)+S);
    IF (LastResponseCode<>200) AND (LastResponseCode<>202) THEN
      RAISE EAbsFTPClient.Create('Allo', LastResponse);
  END;

  PROCEDURE TAbsFTPClient.Rest(From: String);
  BEGIN
    if DataSocket <> nil then
      CloseDataSocket;
    SendCommand('REST '+From);
   while (LastResponseCode = 426) or (LastResponseCode = 226) do
     GetResponse(nil);
(* Пусть анализирует вызывающий
    IF LastResponseCode<>350 THEN
      RAISE EAbsFTPClient.Create('Rest', LastResponse);
*)
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.RnFr(FromName: String);
  BEGIN
    SendCommand('RNFR '+FromName);
    IF LastResponseCode<>350 THEN
      RAISE EAbsFTPClient.Create('RnFn', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.RnTo(ToName: String);
  BEGIN
    SendCommand('RNTO '+ToName);
    IF LastResponseCode<>250 THEN
      RAISE EAbsFTPClient.Create('RnTo', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Abor;
  BEGIN
    SendCommand('ABOR');
    IF (LastResponseCode<>225) AND (LastResponseCode<>226) THEN
      RAISE EAbsFTPClient.Create('Abor', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Dele(FileName: String);
  BEGIN
    SendCommand('DELE '+FileName);
    IF LastResponseCode<>250 THEN
      RAISE EAbsFTPClient.Create('Dele', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.RmD(Path: String);
  BEGIN
    SendCommand('RMD '+Path);
    IF LastResponseCode<>250 THEN
      RAISE EAbsFTPClient.Create('RmD', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.MkD(Path: String);
  BEGIN
    SendCommand('MKD '+Path);
    IF LastResponseCode<>257 THEN
      RAISE EAbsFTPClient.Create('MkD', LastResponse);
    PrePassive := False;
  END;

  FUNCTION TAbsFTPClient.PwD: String;
  BEGIN
    SendCommand('PWD');
    IF LastResponseCode<>257 THEN
      RAISE EAbsFTPClient.Create('PWD', LastResponse);
    Result := Copy(LastResponse, 6, 255);
    SetLength(Result, Pos('"', Result)-1);
    PrePassive := False;
  END;

  function  TAbsFTPClient.StartList(FileSpec: String): Boolean;
    var
      s: string;
    begin
SockLogLine('StartList ' + FileSpec);
    IF Passive THEN
      Pasv
    ELSE
      Port('');
    PrePassive := False;
    if FileSpec <> '' then
      s := 'LIST '+FileSpec
    else
      s := 'LIST';
    SendCommand(s);
    Result := (LastResponseCode = 125) or (LastResponseCode = 150);
    if Result then
      begin
      IF Not Passive THEN
        ConnectDataSocket;
      end
    else
      CloseDataSocket;
    end;

  PROCEDURE TAbsFTPClient.List(FileSpec: String; DirList: TExtra);
  VAR
    S : String;
  BEGIN
    if not StartList(FileSpec) then
      RAISE EAbsFTPClient.Create('List', LastResponse);
    TRY
      REPEAT
        DataSocket.ReadLn(S);
        IF @DirList<>nil THEN
          DirList(S);
      UNTIL NOT DataSocket.Connected;
    EXCEPT
      ON e: ETCPClientSocket DO ;
      ELSE RAISE;
    END;
    CloseDataSocket;

    GetResponse(Nil);
    IF (LastResponseCode<>226) AND (LastResponseCode<>250) THEN
      RAISE EAbsFTPClient.Create('List (Getting data)', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.NLst(FileSpec: String; DirList: TExtra);
  VAR
    S : String;
  BEGIN
    IF Passive THEN Pasv ELSE Port('');
    SendCommand('NLST '+FileSpec);
    IF (LastResponseCode<>125) AND (LastResponseCode<>150) THEN
      RAISE EAbsFTPClient.Create('NLst', LastResponse);

    IF Not Passive THEN ConnectDataSocket;

    TRY
      REPEAT
        DataSocket.ReadLn(S);
        IF @DirList<>nil THEN
          DirList(S);
      UNTIL NOT DataSocket.Connected;
    EXCEPT
      ON e: ETCPClientSocket DO ;
      ELSE RAISE;
    END;
    CloseDataSocket;

    GetResponse(Nil);
    IF (LastResponseCode<>226) AND (LastResponseCode<>250) THEN
      RAISE EAbsFTPClient.Create('NLst (Getting data)', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Site(Cmd: String);
  BEGIN
    SendCommand('SITE '+Cmd);
    IF (LastResponseCode<>200) AND (LastResponseCode<>202) THEN
      RAISE EAbsFTPClient.Create('', LastResponse);
    PrePassive := False;
  END;

  FUNCTION TAbsFTPClient.Syst: String;
  BEGIN
    SendCommand('SYST');
    IF LastResponseCode<>215 THEN
      RAISE EAbsFTPClient.Create('Syst', LastResponse);
    Syst:=Copy(LastResponse, 5, Length(LastResponse)-4);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Stat(FileSpec: String; StatInfo: TExtra);
  VAR
    S : String;
  BEGIN
    SendCommandEx('STAT '+FileSpec, StatInfo);
    IF (LastResponseCode<>211) AND (LastResponseCode<>212) AND (LastResponseCode<>213) THEN
      RAISE EAbsFTPClient.Create('Stat', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Help(Command: String; HelpInfo: TExtra);
  BEGIN
    SendCommandEx('HELP '+Command, HelpInfo);
    IF (LastResponseCode<>211) AND (LastResponseCode<>214) THEN
      RAISE EAbsFTPClient.Create('Help', LastResponse);
    PrePassive := False;
  END;

  PROCEDURE TAbsFTPClient.Noop;
  BEGIN
    SendCommand('NOOP');
    IF LastResponseCode<>200 THEN
      RAISE EAbsFTPClient.Create('Noop', LastResponse);
    PrePassive := False;
  END;

  function TAbsFTPClient.KeepAlive: Boolean;
    var
      t: Longint;
    begin
    Result := True;
    if not Socket.Connected then
      Exit;
    t := GetCurMSec - KeepAliveInterval;
    if (t < Socket.LastTime) then
      Exit;
    if (DataSocket <> nil) and DataSocket.Connected then
      Exit;
    try
      Noop;
    except
      on E: EaslException do
        Result := False;
    end;
    end;


  FUNCTION TAbsFTPClient.ConnectDataSocket: Integer;
  VAR
    FSvrSocket : PTCPServerSocket;
    rc: integer;
  BEGIN
SockLogLine('ConnectDataSocket');
    IF NOT Passive THEN
    BEGIN
      New(FSvrSocket, Init(DataPort));
//      FSvrSocket.Listen;
  rc:=listen(FSvrSocket.SocketHandle, 1);
  IF rc<0 THEN
    RAISE ETCPServerSocket.Create('Listen', ItoS(SockErrNo));
      DataSocket:=FSvrSocket.AcceptConnection;
      FreeObject(FSvrSocket);
    END ELSE
    BEGIN
      New(DataSocket, Init);
      DataSocket.ConnectT(DataIP, DataPort);
    END;
  END;

  FUNCTION TAbsFTPClient.CloseDataSocket: Integer;
  BEGIN
SockLogLine('CloseDataSocket');
    FreeObject(DataSocket);
  END;

{ TFTPClient }

  PROCEDURE TFTPClient.Connect(AHost, Name: string; Password: StringFunction);
    var
      p: string;
  BEGIN
    INHERITED Connect(AHost);
    IF Name<>'' THEN
      User(Name);
    if LastResponseCode = 331 then
      begin
      p := Password;
      Pass(p);
      end;
  END;

  PROCEDURE TFTPClient.Port(APort: STRING);
  VAR
    FSvrSocket : PTCPServerSocket;
    PortNum, Ok: LongInt;
    S          : STRING;
  BEGIN
//!! Check RFC for port number usage
    Val(DataPort, PortNum, Ok);
    IF (Ok=0) AND (PortNum>=10000) AND (PortNum<65000) THEN
    BEGIN
       DataPort:=ItoS(StoI(DataPort)+1);
    END ELSE
       DataPort:='10000';

    S:=SockClientIP;
    Ok:=Pos('.', S);
    WHILE (Ok>0) DO
    BEGIN
      S[Ok]:=',';
      Ok:=Pos('.', S);
    END;

    INHERITED Port(S+','+ItoS(Hi(StoI(DataPort)))+','+ItoS(Lo(StoI(DataPort))));
  END;

  PROCEDURE TFTPClient.Pasv;
  BEGIN
    INHERITED Pasv;
    ConnectDataSocket;
  END;

END.

