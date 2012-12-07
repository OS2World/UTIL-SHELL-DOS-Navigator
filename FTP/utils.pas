{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.4 $    $Date: 1999/07/15 07:54:48 $    $Author: sag $ }
{                                                                             }
{ Converted from utils.h found on the OS/2 Warp 4 CD                          }
UNIT Utils;

{&OrgName+,Use32-,Open32-}

INTERFACE

USES CTypes;

{#ifndef __UTILS_32H
#define __UTILS_32H}

{&CDECL+}
FUNCTION lswap(a: ulong): ulong;
FUNCTION bswap(a: ushort): ushort;
FUNCTION rexec(host: pchar; port: int; user: pchar; passwd: pchar; cmd: pchar; var err_sd2p: int): int;
{ int _System getpid(void); }
{&CDECL-}

{ Definition for bswap }
FUNCTION htonl(x: ulong): ulong; INLINE; BEGIN htonl:=lswap(x); END;
FUNCTION ntohl(x: ulong): ulong; INLINE; BEGIN ntohl:=lswap(x); END;
FUNCTION htons(x: ushort): ushort; INLINE; BEGIN htons:=bswap(x); END;
FUNCTION ntohs(x: ushort): ushort; INLINE; BEGIN ntohs:=bswap(x); END;

{#endif  __UTILS_32H }

IMPLEMENTATION

{&CDECL+}
FUNCTION lswap;         EXTERNAL;
FUNCTION bswap;         EXTERNAL;
FUNCTION rexec;         EXTERNAL;
{&CDECL-}

END.

