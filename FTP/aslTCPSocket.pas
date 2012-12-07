{ Ager's Socket Library (c) Copyright 1998-02 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.29 $    $Date: 2002/09/29 21:58:49 $    $Author: sag $ }
{                                                                             }
{ OO interface to TCP sockets                                                 }
UNIT aslTCPSocket;

INTERFACE

USES SysUtils, strings, VPUtils, CTypes, aslSocket, aslAbsSocket,
     Objects2,
{$IFDEF OS2}
     OS2Socket, NetDB, SockIn, Utils;
{$ELSE}
     Winsock;
{$ENDIF}

CONST
  BufSize = 4096;

TYPE
  ETCPSocket = CLASS(EaslException);
  ETCPClientSocket = CLASS(EaslException);
  EBufTCPClientSocket = CLASS(EaslException);
  ETCPServerSocket = CLASS(EaslException);

  TTCPSocket = object(TAbsSocket)
  PUBLIC
    PeerIP    : STRING;
    PeerName  : STRING;
    CONSTRUCTOR Init;
    END;

  PTCPClientSocket = ^TTCPClientSocket;
  TTCPClientSocket = object(TTCPSocket)
  PUBLIC
    LineSep   : STRING;
    LastTime: Longint; // время последнего обращения
    CONSTRUCTOR Init;
    PROCEDURE ConnectT(adr: STRING; PORT: STRING);
    FUNCTION Read(VAR Buf; len: Word): Integer; VIRTUAL;
    FUNCTION ReadLn(VAR S: STRING): Integer; VIRTUAL;
    FUNCTION Write(VAR Buf; len: Word): Integer;
    FUNCTION WriteLn(S: STRING): Integer;
  END;

  TBufTCPClientSocket = object(TTCPClientSocket)
  PRIVATE
    FReadBuf : ARRAY[0..BufSize] OF Char;
    FBufPos  : Integer;
    FBufEnd  : Integer;
  PUBLIC
    CONSTRUCTOR Init;
    FUNCTION Read(VAR Buf; len: Word): Integer; virtual;
    FUNCTION ReadLn(VAR S: STRING): Integer; virtual;
  END;

  PTCPServerSocket = ^TTCPServerSocket;
  TTCPServerSocket = object(TTCPSocket)
  PUBLIC
    CONSTRUCTOR Init(Port: STRING);
    FUNCTION AcceptConnection: PTCPClientSocket;
  END;

IMPLEMENTATION
uses
  Advance1, Events;

{ TTCPSocket }

  CONSTRUCTOR TTCPSocket.Init;
  BEGIN
    INHERITED Init;
    Protocol:='tcp';
  END;


{ TTCPClientSocket }

  CONSTRUCTOR TTCPClientSocket.Init;
  BEGIN
    INHERITED Init;
    LineSep:=#13#10;
  END;

  PROCEDURE TTCPClientSocket.ConnectT(adr: STRING; PORT: STRING);
  VAR
    phe   : PHostEnt;
    sin   : sockaddr_in;
    PE    : PProtoEnt;
  BEGIN
    SockLogLine('Creating client socket...');

    PE:=SockGetProtoByName(Protocol);  // ERROR check
    SocketHandle := Socket(PF_INET, SOCK_STREAM, PE^.p_proto);
    IF SocketHandle < 0 THEN
      RAISE ETCPClientSocket.Create('Connect', ItoS(SockErrNo));
    sin.sin_family:=AF_INET;
    sin.sin_port:=ResolvePort(Port);
    sin.sin_addr.s_addr:=SockInetAddr(Adr);
    IF sin.sin_addr.s_addr=INADDR_NONE THEN
    BEGIN
      SockLogLine(Format('%s does not look like ip. Trying to use it as host name ',[adr]));
      phe:=SockGetHostByName(adr);
      IF not Assigned(phe) THEN
        RAISE ETCPClientSocket.Create('Connect: Host name '+adr+' unknown.', ItoS(SockErrNo));
      SockLogLine('resolved host name');
      Sin.sin_addr:=phe^.h_addr^^;
    END;
    SockLogLine(Format('trying to connect to %s:%s',[adr, PORT]));
    if connect(SocketHandle, sockaddr(sin), SizeOf(sin)) < 0 then
      RAISE ETCPSocket.Create('Connect: Cannot connect to '+adr+':'+Port, ItoS(SockErrNo));
    Connected:=True;
    PeerName:=adr;
  SockLogLine('   socket handle =' + ItoS(SocketHandle));
  END;

  FUNCTION TTCPClientSocket.Read(VAR Buf; len: Word): Integer;
  BEGIN
    SockLogLine(Format('Reading data on socket %d...',[SocketHandle]));
    Result := recv(SocketHandle, buf, len, 0);
    IF Result<0 THEN
      RAISE ETCPClientSocket.Create('Read', ItoS(SockErrNo));
    LastTime := GetCurMSec;
  END;

  FUNCTION TTCPClientSocket.ReadLn(VAR S: STRING): Integer;
  VAR
    c : Char;
    rc: Longint;
  BEGIN
    SockLogLine(Format('Reading data on socket %d...',[SocketHandle]));
    S:='';
    while true do
      begin
      rc := recv(SocketHandle, c, 1, 0);
      if rc = 0 then
        begin // not connected
        Connected := False;
        Exit;
        end;
      if rc < 0 then
        RAISE ETCPClientSocket.Create('ReadLn', ItoS(SockErrNo));
      if c=#10 then
        break;
      if c <> #13 then
        S:=S+c;
      end;
    Result:=Length(S);
  END;

  FUNCTION TTCPClientSocket.Write(VAR Buf; len: Word): Integer;
  BEGIN
    SockLogLine(Format('Writing data to socket %d...',[SocketHandle]));
    IF Not Connected THEN
      RAISE EabsSocket.Create('Write', 'Lost connection');
    Result:=send(SocketHandle, Buf, Len, 0);
    IF Result<0 THEN
      RAISE ETCPClientSocket.Create('Write', ItoS(SockErrNo));
    LastTime := GetCurMSec;
  END;

  FUNCTION TTCPClientSocket.WriteLn(S: STRING): Integer;
  BEGIN
    S:=S+LineSep;
    Result:=Write(S[1],Length(S));
  END;

{ TBufTCPClientSocket }

  CONSTRUCTOR TBufTCPClientSocket.Init;
  BEGIN
    INHERITED Init;
    FBufPos:=0; FBufEnd:=0;
  END;

  FUNCTION TBufTCPClientSocket.Read(VAR Buf; Len: Word): Integer;
  BEGIN
    IF FBufPos=FBufEnd THEN
    BEGIN
      FBufEnd:=INHERITED Read(FReadBuf, BufSize);
      FBufPos:=0;
      IF FBufEnd<0 THEN
      BEGIN
        FBufEnd:=0;
        Result:=-1;
        Exit;
      END;
    END;

    Move(Buf, FReadBuf[FBufPos], Min(FBufEnd, Len));
    FBufPos:=Min(FBufEnd, Len);
    Result:=FBufEnd-FBufPos;
  END;

  FUNCTION TBufTCPClientSocket.ReadLn(VAR S: STRING): Integer;
  VAR
    c : Char;
    i : Integer;
  BEGIN
    S:=''; i:=FBufEnd;
    REPEAT
      IF FBufPos=FBufEnd THEN
        i:=Read(c, 0);       // Just fill buffer
      c:=FReadBuf[FBufPos];
      Inc(FBufPos);
      IF (c<>#10) AND (c<>#13) AND (FBufEnd>0) THEN S:=S+c;
    UNTIL (c=#10) OR (i<=0) OR (FBufEnd=0);
    IF i<0 THEN
      RAISE EBufTCPClientSocket.Create('ReadLn', ItoS(SockErrNo));
    Result:=Length(S);
  END;


{ TTCPServerSocket }

  CONSTRUCTOR TTCPServerSocket.Init(PORT: STRING);
  VAR
    sn : SockAddr_In;
    PE : PProtoEnt;
  BEGIN
    INHERITED Init;
    SockLogLine(Format('Creating master socket on port %s',[Port]));
    SockErrNo;
    PE:=SockGetProtoByName(Protocol);  // ERROR check
    Socket(PF_INET, SOCK_STREAM, PE^.p_proto);
    IF SockErrNo<>0 THEN
      RAISE ETCPServerSocket.Create('Init', ItoS(SockErrNo));
    SockLogLine(Format('master socket: %d',[SocketHandle]));
    sn.sin_family := AF_INET;
    sn.sin_addr.s_addr := INADDR_ANY;
    sn.sin_port:=ResolvePort(Port);
    SockLogLine('Binding socket');
    (* Bind the socket to the port *)
    IF bind(SocketHandle, SockAddr(sn),SizeOf(sn))<0 THEN
      RAISE ETCPServerSocket.Create('Init', ItoS(SockErrNo));
  END;

  FUNCTION TTCPServerSocket.AcceptConnection;
  VAR
    TmpSock: int;
    sad    : SockAddr_In;
    phe    : PHostEnt;
    TmpCs  : PTCPClientSocket;
    l      : ULong;
  BEGIN
    Result := nil;
    SockLogLine('Accepting connection...');
    l:=SizeOf(Sad);
    TmpSock:=accept(SocketHandle, sockaddr(sad),l);
    IF TmpSock=INVALID_SOCKET THEN
      RAISE ETCPServerSocket.Create('AcceptConnection', ItoS(SockErrNo));

    PeerIP:=SockInetntoa(sad.sin_addr);
    phe:=GetHostByAddr(sad.sin_addr, SizeOf(sad.sin_addr), AF_INET);
    IF NOT Assigned(phe) THEN
    BEGIN
      SockLogLine(Format('TTCPServerSocket.AcceptConnection: gethostbyaddr() failed; error code %d',[SockErrNo]));
      PeerName := '';
    END else
      PeerName := StrPas(phe^.h_name);
    New(TmpCs, Init);
//!! Maybe check in when socket handle is set?
    TmpCs.SocketHandle:=TmpSock;
    TmpCs.Connected:=True;
    Result:=TmpCs;
  END;

END.

