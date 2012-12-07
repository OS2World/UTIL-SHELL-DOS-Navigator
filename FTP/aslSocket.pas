{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.12 $       $Date: 2002/09/30 20:27:27 $    $Author: sag $ }
{                                                                             }
{ Platform independend socket routines                                        }
UNIT aslSocket;

INTERFACE

USES strings,
{$IFDEF OS2}
     OS2Socket, sockin, netdb, Utils;
{$ELSE}
     Winsock;
{$ENDIF}

FUNCTION SockIOCtl(s: Integer; cmd: Integer; var data; datalen: Integer): Integer; INLINE;
BEGIN
{$IFDEF OS2}
  Result:=OS2Socket.ioctl(s, cmd, data, datalen);
{$ELSE}
  Result:=ioctlsocket(s, cmd, u_long(data));
{$ENDIF}
END;

FUNCTION SockErrNo: Integer; INLINE;
BEGIN
{$IFDEF OS2}
  Result:=sock_errno;
{$ELSE}
  Result:=WSAGetLastError;
{$ENDIF}
END;

FUNCTION SockClose(s: Integer): Integer; INLINE;
BEGIN
{$IFDEF OS2}
  Result:=soclose(s);
{$ELSE}
  Result:=closesocket(s);
{$ENDIF}
END;

FUNCTION SockAbort(s: Integer): Integer; INLINE;
BEGIN
{$IFDEF OS2}
  Result:=soabort(s);
{$ELSE}
  Result:=-1;
{$ENDIF}
END;

FUNCTION SockCancel(s: Integer): Integer; INLINE;
BEGIN
{$IFDEF OS2}
  Result:=so_cancel(s);
{$ELSE}
  Result:=-1;
{$ENDIF}
END;

PROCEDURE Sockpsock_errno(error: STRING);

FUNCTION SockGetServByName(Name: STRING; Proto: STRING): PServEnt;
FUNCTION SockGetHostByName(Name: STRING): PHostEnt;
FUNCTION SockGetProtoByName(Name: STRING): PProtoEnt;
FUNCTION SockInetAddr(Adr: STRING): LongInt;
FUNCTION SockInetNtoA(ina: in_addr): STRING;

FUNCTION SockClientIP: STRING;

function GetRecvDataSize(var sock: Longint): Longint;

IMPLEMENTATION

  PROCEDURE Sockpsock_errno(error: STRING);
  BEGIN
{$IFDEF OS2}
      Error:=Error+#0;
      psock_errno(@error[1]);
{$ELSE}
    WriteLn(error);
{$ENDIF}
  END;

  FUNCTION SockGetServByName(Name: STRING; Proto: STRING): PServEnt;
  BEGIN
    Name:=Name+#0; Proto:=Proto+#0;
    SockGetServByName:=PServEnt(GetServByName(@Name[1], @Proto[1]));
  END;

  FUNCTION SockGetHostByName(Name: STRING): PHostEnt;
  BEGIN
    Name:=Name+#0;
    SockGetHostByName:=PHostEnt(GetHostByName(@Name[1]));
  END;

  FUNCTION SockGetProtoByName(Name: STRING): PProtoEnt;
  BEGIN
    Name:=Name+#0;
    SockGetProtoByName:=PProtoEnt(GetProtoByName(@Name[1]));
  END;

  FUNCTION SockInetAddr(Adr: STRING): LongInt;
  BEGIN
    Adr:=Adr+#0;
    SockInetAddr:=inet_Addr(@Adr[1]);
  END;

  FUNCTION SockInetNtoA(ina: in_addr): STRING;
  VAR
    p: PChar;
  BEGIN
    p:=inet_ntoa(ina);
    SockINetNtoA:=StrPas(p);
  END;

  FUNCTION SockClientIP: STRING;
  VAR
    Name : ARRAY[0..40] OF Char;
    phe  : phostent;
    p    : PChar;
    ina: in_addr;
    Err: integer;
  BEGIN
  Err := SockErrNo;
{$IFDEF OS2}
    ina.s_addr := htonl(gethostid);
    Result:=SockInetNtoA(ina);
{$ELSE}
    GetHostName(Name, SizeOf(Name));
  Err := SockErrNo;
    phe:=GetHostByName(Name);
  Err := SockErrNo;
    SockClientIP:=SockInetNtoA(phe^.h_addr^^);
  Err := SockErrNo;
{$ENDIF}
  writeln(result, ' ', SockErrNo);
  END;

function GetRecvDataSize(var sock: Longint): Longint;
  var
    rc: Longint;
  begin
  {$IFDEF OS2}
  rc := ioctl(sock, FIONREAD, Result, 4);
{$ELSE}
  rc := ioctlsocket(sock, FIONREAD, Result);
{$ENDIF}
  if rc <> 0 then
    Result := 0;
  end;

{$IFDEF Win32}
VAR
  WSAD: WSAData;
{$ENDIF}

INITIALIZATION
{$IFDEF OS2}
  sock_init;
{$ELSE}
  IF WSAStartUp($0101, WSAD)<>0 THEN
;//    RAISE ESocketError.Create('WSAStartUp() failed');

FINALIZATION
  IF WSACleanup=SOCKET_ERROR THEN
;//    RAISE ESocketError.Create('WSACleanup() failed');
{$ENDIF}
END.

