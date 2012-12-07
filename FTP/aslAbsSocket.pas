{ Ager's Socket Library (c) Copyright 1998-02 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.18 $    $Date: 2002/09/30 19:20:39 $    $Author: sag $ }
{                                                                             }
{ Abstract sockets class                                                      }
UNIT aslAbsSocket;

INTERFACE

USES SysUtils, strings, CTypes, aslSocket,
    Objects2,
{$IFDEF OS2}
     OS2Def, OS2Socket, NetDB, Utils, ioctl;
{$ELSE}
     Winsock;
{$ENDIF}

CONST
  INVALID_SOCKET = -1;

TYPE
  TLogLine = PROCEDURE(Msg: STRING);

  EaslException = CLASS(Exception)
    CONSTRUCTOR Create(CONST Where, ErrCode: STRING);
  END;

  EAbsSocket = CLASS(EaslException);

  TAbsSocket = object(TObject)
  PUBLIC
    SocketHandle : Integer;
    Connected    : Boolean;
    Protocol     : STRING;
    FPortN        : Integer;
    CONSTRUCTOR Init;
    DESTRUCTOR Done; virtual;
    PROCEDURE Disconnect;
    FUNCTION ResolvePort(Port: STRING): ushort;

    FUNCTION GetBytesAvail: Integer;
  END;

var
  SockLogLine: TLogLine;

IMPLEMENTATION
uses
  advance1;

{ EaslException }

  CONSTRUCTOR EaslException.Create(CONST Where, ErrCode: STRING);
  BEGIN
    INHERITED Create(Where+'. (Error='+ErrCode+')');
  END;


{ EAbsSocket }

  CONSTRUCTOR TAbsSocket.Init;
  BEGIN
    INHERITED Init;
    SocketHandle:=INVALID_SOCKET;
  END;

  DESTRUCTOR TAbsSocket.Done;
  BEGIN
    Disconnect;
    INHERITED Done;
  END;

  PROCEDURE TAbsSocket.Disconnect;
  BEGIN
    if Connected then
      begin
      SockLogLine(Format('Closing connection on socket %d...',[SocketHandle]));
      IF SockClose(SocketHandle)<0 THEN   // =-1
        RAISE EAbsSocket.Create('Disconnect', ItoS(SockErrNo));
      Connected:=False;
      SocketHandle:=INVALID_SOCKET;
      end;
  END;

  FUNCTION TAbsSocket.ResolvePort(Port: STRING): ushort;
  VAR
    PSE   : PServEnt;
  BEGIN
    SockLogLine(Format('Resolving port name %s',[Port]));
    PSE:=SockGetServByName(PORT, Protocol);
    IF not Assigned(PSE) THEN
    BEGIN
      SockLogLine(Format('Cannot resolv; using port number %s',[Port]));
      Result:=swap(StoI(PORT));
      FPortN:=StoI(PORT);
    END else
    BEGIN
      Result:=PSE.s_port;
      FPortN:=swap(PSE^.s_port);
      SockLogLine(Format('Resolved; port number %d',[FPortN]));
    END;
  END;

  FUNCTION TAbsSocket.GetBytesAvail;
  VAR
    Bytes: Integer;
  BEGIN
    IF SockIOCtl(SocketHandle, FIONRead, Bytes, SizeOf(Bytes))<0 THEN
      RAISE EAbsSocket.Create('GetBytesAvail', ItoS(SockErrNo));
    GetBytesAvail:=Bytes;
  END;

procedure nolog(Msg: string);
  begin
  end;

var
  SockLog: Text;

procedure FileLog(Msg: string);
  var
    ior: Longint;
  begin
  ior := InOutRes;
  if Dos.TextRec(SockLog).HAndle = 0 then
    begin
    Assign(SockLog, 'Q:\log');
    Rewrite(SockLog);
    end;
  writeln(SockLog, Msg);
  Flush(SockLog);
  InOutRes := ior;
  end;

begin
@SockLogLine:=@nolog;
//@SockLogLine:=@FileLog;
END.

