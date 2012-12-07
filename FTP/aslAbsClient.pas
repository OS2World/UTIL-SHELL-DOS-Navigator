{ Ager's Socket Library (c) Copyright 1998-02 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.28 $    $Date: 2002/09/29 21:53:36 $    $Author: sag $ }
{                                                                             }
{ Abstract Client class                                                       }
UNIT aslAbsClient;

INTERFACE

USES SysUtils, strings, aslAbsSocket, aslTCPSocket
  , Objects2
;

TYPE
  EAbsClient = class(EaslException);

  TExtra = procedure(const Msg: string);

  TAbsClient = object(TObject)
  PROTECTED
    PROCEDURE SendCommandNoResponse(Cmd: STRING);
    PROCEDURE GetResponse(Extra: TExtra); VIRTUAL;

  PUBLIC
    Host             : STRING;
    Socket           : PTCPClientSocket;
    LastResponse     : STRING;
    LastResponseCode : Word;
    PROCEDURE SendCommand(Cmd: STRING);
    PROCEDURE SendCommandEx(Cmd: STRING; Extra: TExtra);
    CONSTRUCTOR Init;
    DESTRUCTOR Done; virtual;
  END;

IMPLEMENTATION
uses
  VpUtils, AslSocket,
{$IFDEF OS2}
     OS2Socket, NetDB, SockIn, Utils;
{$ELSE}
     Winsock;
{$ENDIF}

{ TAbsClient }

  CONSTRUCTOR TAbsClient.Init;
  BEGIN
    INHERITED Init;
    New(Socket, Init);
  END;

  DESTRUCTOR TAbsClient.Done;
  BEGIN
    Socket^.Free;
    INHERITED Done;
  END;

  PROCEDURE TAbsClient.SendCommandNoResponse(Cmd: STRING);
  BEGIN
    SockLogLine('<'+Cmd);
    Socket.WriteLn(Cmd);
  END;

  PROCEDURE TAbsClient.SendCommand(Cmd: STRING);
    var
      l, l1: Longint;
      buf: array[0..1023] of byte;
  BEGIN
    l := GetRecvDataSize(Socket.SocketHandle);
    while l <> 0 do
      begin { игнорируем хвосты от прошлых команд }
      l1 := Min(l, SizeOf(buf));
      recv(Socket.SocketHandle, buf, l1, 0);
      dec(l, l1);
      end;
    SendCommandNoResponse(Cmd);
    GetResponse(Nil);
  END;

  PROCEDURE TAbsClient.SendCommandEx(Cmd: STRING; Extra: TExtra);
  BEGIN
    SendCommandNoResponse(Cmd);
    GetResponse(Extra);
  END;


  PROCEDURE TAbsClient.GetResponse(Extra: TExtra);
  VAR
    Ok, i : Integer;
    S     : String;
  BEGIN
    i:=Socket.ReadLn(LastResponse);
    IF i>0 THEN
    BEGIN
      SockLogLine('>'+LastResponse);
      Val(Copy(LastResponse,1,3), LastResponseCode, Ok);
if LastResponseCode = 226 then
  LastResponseCode := LastResponseCode;
      IF Copy(LastResponse,4,1)='-' THEN
      BEGIN
        REPEAT
          i:=Socket.ReadLn(S);
          IF (i>0) THEN
          BEGIN
            IF @Extra<>nil THEN
              Extra(S);
            SockLogLine('>'+S);
          END;
        UNTIL (Copy(S,1,4)=(Copy(LastResponse,1,3)+' ')) OR (i=0);
      END;
    END;
    IF i<0 THEN
      RAISE EabsClient.Create('GetResponse', '');
  END;

END.


