{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.3 $    $Date: 1999/07/15 07:54:47 $    $Author: sag $ }
{                                                                             }
{ Converted from ioctl.h found on the OS/2 Warp 4 CD                          }
UNIT ioctl;

{&OrgName+,Use32-,Open32-}

INTERFACE

{#ifndef __IOCTL_32H
#define __IOCTL_32H}

{#define ioc(x,y)       ((x<<8)|y)}

CONST
  FIONREAD      = (Ord('f') SHL 8) OR 127;
  FIONBIO       = (Ord('f') SHL 8) OR 126;

  FIOASYNC      = (Ord('f') SHL 8) OR 125;
  FIOTCPCKSUM   = (Ord('f') SHL 8) OR 128;
  FIONSTATUS    = (Ord('f') SHL 8) OR 120;
  FIONURG       = (Ord('f') SHL 8) OR 121;

  SIOCSHIWAT    = (Ord('s') SHL 8) OR  0;
  SIOCGHIWAT    = (Ord('s') SHL 8) OR  1;
  SIOCSLOWAT    = (Ord('s') SHL 8) OR  2;
  SIOCGLOWAT    = (Ord('s') SHL 8) OR  3;
  SIOCATMARK    = (Ord('s') SHL 8) OR  7;
  SIOCSPGRP     = (Ord('s') SHL 8) OR  8;
  SIOCGPGRP     = (Ord('s') SHL 8) OR  9;
  SIOCSHOSTID   = (Ord('s') SHL 8) OR 10;

  SIOCADDRT     = (Ord('r') SHL 8) OR 10;
  SIOCDELRT     = (Ord('r') SHL 8) OR 11;
  SIOMETRIC1RT  = (Ord('r') SHL 8) OR 12;
  SIOMETRIC2RT  = (Ord('r') SHL 8) OR 13;
  SIOMETRIC3RT  = (Ord('r') SHL 8) OR 14;
  SIOMETRIC4RT  = (Ord('r') SHL 8) OR 15;

  SIOCREGADDNET = (Ord('r') SHL 8) OR 12;
  SIOCREGDELNET = (Ord('r') SHL 8) OR 13;
  SIOCREGROUTES = (Ord('r') SHL 8) OR 14;
  SIOCFLUSHROUTES=(Ord('r') SHL 8) OR 15;

  SIOCSIFADDR   = (Ord('i') SHL 8) OR 12;
  SIOCGIFADDR   = (Ord('i') SHL 8) OR 13;
  SIOCSIFDSTADDR= (Ord('i') SHL 8) OR 14;
  SIOCGIFDSTADDR= (Ord('i') SHL 8) OR 15;
  SIOCSIFFLAGS  = (Ord('i') SHL 8) OR 16;
  SIOCGIFFLAGS  = (Ord('i') SHL 8) OR 17;
  SIOCGIFBRDADDR= (Ord('i') SHL 8) OR 18;
  SIOCSIFBRDADDR= (Ord('i') SHL 8) OR 19;
  SIOCGIFCONF   = (Ord('i') SHL 8) OR 20;
  SIOCGIFNETMASK= (Ord('i') SHL 8) OR 21;
  SIOCSIFNETMASK= (Ord('i') SHL 8) OR 22;
  SIOCGIFMETRIC = (Ord('i') SHL 8) OR 23;
  SIOCSIFMETRIC = (Ord('i') SHL 8) OR 24;
  SIOCSIFSETSIG = (Ord('i') SHL 8) OR 25;
  SIOCSIFCLRSIG = (Ord('i') SHL 8) OR 26;
  SIOCSIFBRD    = (Ord('i') SHL 8) OR 27; { SINGLE-rt bcst. using old # for bkw cmpt }
  SIOCSIFALLRTB = (Ord('i') SHL 8) OR 63; { added to configure all-route broadcst }

  SIOCGIFLOAD     =(Ord('i') SHL 8) OR 27;
  SIOCSIFFILTERSRC=(Ord('i') SHL 8) OR 28;
  SIOCGIFFILTERSRC=(Ord('i') SHL 8) OR 29;

  SIOCSARP      = (Ord('i') SHL 8) OR 30;
  SIOCGARP      = (Ord('i') SHL 8) OR 31;
  SIOCDARP      = (Ord('i') SHL 8) OR 32;
  SIOCSIFSNMPSIG= (Ord('i') SHL 8) OR 33;
  SIOCSIFSNMPCLR= (Ord('i') SHL 8) OR 34;
  SIOCSIFSNMPCRC= (Ord('i') SHL 8) OR 35;
  SIOCSIFPRIORITY=(Ord('i') SHL 8) OR 36;
  SIOCGIFPRIORITY=(Ord('i') SHL 8) OR 37;
  SIOCSIFFILTERDST=(Ord('i') SHL 8) OR 38;
  SIOCGIFFILTERDST=(Ord('i') SHL 8) OR 39;
  SIOCSIF802_3  =  (Ord('i') SHL 8) OR 40;
  SIOCSIFNO802_3=  (Ord('i') SHL 8) OR 41;
  SIOCSIFNOREDIR=  (Ord('i') SHL 8) OR 42;
  SIOCSIFYESREDIR= (Ord('i') SHL 8) OR 43;

  SIOCSIFMTU    = (Ord('i') SHL 8) OR 45;
  SIOCSIFFDDI   = (Ord('i') SHL 8) OR 46;
  SIOCSIFNOFDDI = (Ord('i') SHL 8) OR 47;
  SIOCSRDBRD    = (Ord('i') SHL 8) OR 48;
  SIOCSARP_TR   = (Ord('i') SHL 8) OR 49;
  SIOCGARP_TR   = (Ord('i') SHL 8) OR 50;

{ multicast ioctls }
  SIOCADDMULTI  = (Ord('i') SHL 8) OR 51;    { add m'cast addr }
  SIOCDELMULTI  = (Ord('i') SHL 8) OR 52;    { del m'cast addr }
  SIOCMULTISBC  = (Ord('i') SHL 8) OR 61;    { use broadcast to send IP multicast }
  SIOCMULTISFA  = (Ord('i') SHL 8) OR 62;    { use functional addr to send IP multicast }


{$IFDEF SLBOOTP}
  SIOCGUNIT     = (Ord('i') SHL 8) OR 70;    { Used to retreive unit number on }
                                             { serial interface }
{$ENDIF}

  SIOCSIFSPIPE   = (Ord('i') SHL 8) OR 71;   { used to set pipe size on interface }
                                             { this is used as tcp send buffer size }
  SIOCSIFRPIPE   = (Ord('i') SHL 8) OR 72;   { used to set pipe size on interface }
                                             { this is used as tcp recv buffer size }
  SIOCSIFTCPSEG = (Ord('i') SHL 8) OR 73;    { set the TCP segment size on interface }
  SIOCSIFUSE576 = (Ord('i') SHL 8) OR 74;    { enable/disable the automatic change of mss to 576 }
                                             { if going through a router }
  SIOCGIFVALID  = (Ord('i') SHL 8) OR 75;    { to check if the interface is Valid or not }
                                             { sk June 14 1995 }
  SIOCGIFBOUND  = (Ord('i') SHL 8) OR 76;    { ioctl to return bound/shld bind ifs }
{ Interface Tracing Support }
  SIOCGIFEFLAGS = (Ord('i') SHL 8) OR 150;
  SIOCSIFEFLAGS = (Ord('i') SHL 8) OR 151;
  SIOCGIFTRACE  = (Ord('i') SHL 8) OR 152;
  SIOCSIFTRACE  = (Ord('i') SHL 8) OR 153;

{$IFDEF SLSTATS}
  SIOCSSTAT    = (Ord('i') SHL 8) OR 154;
  SIOCGSTAT    = (Ord('i') SHL 8) OR 155;
{$ENDIF}

{ NETSTAT stuff }
  SIOSTATMBUF   = (Ord('n') SHL 8) OR 40;
  SIOSTATTCP    = (Ord('n') SHL 8) OR 41;
  SIOSTATUDP    = (Ord('n') SHL 8) OR 42;
  SIOSTATIP     = (Ord('n') SHL 8) OR 43;
  SIOSTATSO     = (Ord('n') SHL 8) OR 44;
  SIOSTATRT     = (Ord('n') SHL 8) OR 45;
  SIOFLUSHRT    = (Ord('n') SHL 8) OR 46;
  SIOSTATICMP   = (Ord('n') SHL 8) OR 47;
  SIOSTATIF     = (Ord('n') SHL 8) OR 48;
  SIOSTATAT     = (Ord('n') SHL 8) OR 49;
  SIOSTATARP    = (Ord('n') SHL 8) OR 50;
  SIOSTATIF42   = (Ord('n') SHL 8) OR 51;
{#endif}

IMPLEMENTATION

END.


