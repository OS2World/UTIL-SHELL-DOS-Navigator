{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.6 $    $Date: 1999/07/15 07:54:48 $    $Author: sag $ }
{                                                                             }
{ Converted from in.h found on the OS/2 Warp 4 CD                             }
UNIT SockIn;

{&OrgName+,Use32-,Open32-}

INTERFACE

USES CTypes;

{#ifndef __IN_32H
#define __IN_32H}
{
 * Copyright (c) 1982, 1986 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that this notice is preserved and that due credit is given
 * to the University of California at Berkeley. The name of the University
 * may not be used to endorse or promote products derived from this
 * software without specific prior written permission. This software
 * is provided ``as is'' without express or implied warranty.
 *
 *      @(#)in.h        7.5 (Berkeley) 2/22/88
 }

{
 * Constants and structures defined by the internet system,
 * Per RFC 790, September 1981.
 }

{
 * Protocols
 }
CONST
  IPPROTO_IP              = 0;               { dummy for IP }
  IPPROTO_ICMP            = 1;               { control message protocol }
  IPPROTO_IGMP            = 2;               { group management protocol}
  IPPROTO_GGP             = 3;               { gateway^2 (deprecated) }
  IPPROTO_TCP             = 6;               { tcp }
  IPPROTO_EGP             = 8;               { exterior gateway protocol }
  IPPROTO_PUP             = 12;              { pup }
  IPPROTO_UDP             = 17;              { user datagram protocol }
  IPPROTO_IDP             = 22;              { xns idp }

  IPPROTO_RAW             = 255;             { raw IP packet }
  IPPROTO_MAX             = 256;


{
 * Ports < IPPORT_RESERVED are reserved for
 * privileged processes (e.g. root).
 * Ports > IPPORT_USERRESERVED are reserved
 * for servers, not necessarily privileged.
 }
  IPPORT_RESERVED         = 1024;
  IPPORT_USERRESERVED     = 5000;

{
 * Link numbers
 }
  IMPLINK_IP              = 155;
  IMPLINK_LOWEXPER        = 156;
  IMPLINK_HIGHEXPER       = 158;

{
 * Internet address (a structure for historical reasons)
 }
TYPE
  pin_addr = ^in_addr;
  in_addr = RECORD
    s_addr: ulong;
  END;
  tin_addr = in_addr;

{
 * Definitions of bits in internet address integers.
 * On subnets, the decomposition of addresses to host and net parts
 * is done according to subnet mask, not the masks here.
 }
CONST
//  IN_CLASSA(i)            (((long)(i) & $80000000L) == 0)
  IN_CLASSA_NET           = $ff000000;
  IN_CLASSA_NSHIFT        = 24;
  IN_CLASSA_HOST          = $00ffffff;
  IN_CLASSA_MAX           = 128;

//  IN_CLASSB(i)            (((long)(i) & $c0000000L) == $80000000L)
  IN_CLASSB_NET           = $ffff0000;
  IN_CLASSB_NSHIFT        = 16;
  IN_CLASSB_HOST          = $0000ffff;
  IN_CLASSB_MAX           = 65536;

//  IN_CLASSC(i)            (((long)(i) & $e0000000L) == $c0000000L)
  IN_CLASSC_NET           = $ffffff00;
  IN_CLASSC_NSHIFT        = 8;
  IN_CLASSC_HOST          = $000000ff;

//  IN_CLASSD(i)            (((long)(i) & $f0000000L) == $e0000000L)
  IN_CLASSD_NET           = $ffffffff;
  IN_CLASSD_HOST          = $00000000;
//  IN_MULTICAST(i)         = IN_CLASSD(i)

//  IN_EXPERIMENTAL(i)      (((long)(i) & $e0000000) == $e0000000)
//  IN_BADCLASS(i)          (((long)(i) & $f0000000) == $f0000000)

  INADDR_ANY              = $00000000;
  INADDR_BROADCAST        = $ffffffff;     { must be masked }

  INADDR_UNSPEC_GROUP     = $e0000000;      { 224.0.0.0   }
  INADDR_ALLHOSTS_GROUP   = $e0000001;      { 224.0.0.1   }
  INADDR_MAX_LOCAL_GROUP  = $e00000ff;      { 224.0.0.255 }

{$ifndef KERNEL}
  INADDR_NONE             = $ffffffff;             { -1 return }
{$endif}

  IN_LOOPBACKNET          = 127;                   { official! }

{
 * Socket address, internet style.
 }
TYPE
  sockaddr_in = RECORD
    sin_family : short;
    sin_port   : ushort;
    sin_addr   : in_addr;
    sin_zero   : ARRAY[1..8] of Byte;
  END;

{
 * Options for use with [gs]etsockopt at the IP level.
 }
CONST
  IP_OPTIONS         = 1;            { set/get IP per-packet options }

  IP_MULTICAST_IF    = 2;            { set/get IP multicast interface}
  IP_MULTICAST_TTL   = 3;            { set/get IP multicast timetolive}
  IP_MULTICAST_LOOP  = 4;            { set/get IP multicast loopback }
  IP_ADD_MEMBERSHIP  = 5;            { add  an IP group membership   }
  IP_DROP_MEMBERSHIP = 6;            { drop an IP group membership   }

  IP_DEFAULT_MULTICAST_TTL  = 1;     { normally limit m'casts to 1 hop }
  IP_DEFAULT_MULTICAST_LOOP = 1;     { normally hear sends if a member }
  IP_MAX_MEMBERSHIPS      =  20;     { per socket; must fit in one mbuf}

{
 * Argument structure for IP_ADD_MEMBERSHIP and IP_DROP_MEMBERSHIP.
 }
TYPE
  p_mreq = RECORD
    imr_multiaddr: in_addr;  { IP multicast address of group }
    imr_interface: in_addr;  { local IP address of interface }
  END;

{&CDECL+}
FUNCTION inet_addr(cp: pchar): ulong;
FUNCTION inet_makeaddr(net: ulong; lna: ulong): in_addr;
FUNCTION inet_network(cp: pchar): ulong;
FUNCTION inet_ntoa(ina: in_addr): pchar;
FUNCTION inet_lnaof(ina: in_addr): ulong;
FUNCTION inet_netof(ina: in_addr): ulong;
{&CDECL-}

{#endif  __IN_32H }

IMPLEMENTATION

{$L TCP32DLL.LIB}

{&CDECL+}
FUNCTION inet_addr;             EXTERNAL;
FUNCTION inet_makeaddr;         EXTERNAL;
FUNCTION inet_network;          EXTERNAL;
FUNCTION inet_ntoa;             EXTERNAL;
FUNCTION inet_lnaof;            EXTERNAL;
FUNCTION inet_netof;            EXTERNAL;
{&CDECL-}

END.

