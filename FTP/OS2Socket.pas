{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.8 $    $Date: 1999/07/15 07:54:48 $    $Author: sag $ }
{                                                                             }
{ Converted from socket.h found on the OS/2 Warp 4 CD                         }
UNIT OS2Socket;

{&OrgName+,Use32-,Open32-}

INTERFACE

USES OS2Def, CTypes;

{#ifndef __SOCKET_32H
#define __SOCKET_32H}

{#include <types.h>}

{
 * Copyright (c) 1982, 1985, 1986 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that this notice is preserved and that due credit is given
 * to the University of California at Berkeley. The name of the University
 * may not be used to endorse or promote products derived from this
 * software without specific prior written permission. This software
 * is provided ``as is'' without express or implied warranty.
 *
 *      @(#)socket.h    7.2 (Berkeley) 12/30/87
 }

{
 * Definitions related to sockets: types, address families, options.
 }

{
 * Types
 }
CONST
  SOCK_STREAM     =1;               { stream socket }
  SOCK_DGRAM      =2;               { datagram socket }
  SOCK_RAW        =3;               { raw-protocol interface }
  SOCK_RDM        =4;               { reliably-delivered message }
  SOCK_SEQPACKET  =5;               { sequenced packet stream }

{
 * Option flags per-socket.
 }
CONST
  SO_DEBUG        = $0001;          { turn on debugging info recording }
  SO_ACCEPTCONN   = $0002;          { socket has had listen() }
  SO_REUSEADDR    = $0004;          { allow local address reuse }
  SO_KEEPALIVE    = $0008;          { keep connections alive }
  SO_DONTROUTE    = $0010;          { just use interface addresses }
  SO_BROADCAST    = $0020;          { permit sending of broadcast msgs }
  SO_USELOOPBACK  = $0040;          { bypass hardware when possible }
  SO_LINGER       = $0080;          { linger on close if data present }
  SO_OOBINLINE    = $0100;          { leave received OOB data in line }
  SO_L_BROADCAST  = $0200;          { limited broadcast sent on all IFs}
  SO_RCV_SHUTDOWN = $0400;          { set if shut down called for rcv }
  SO_SND_SHUTDOWN = $0800;          { set if shutdown called for send }

{
 * Additional options, not kept in so_options.
 }
CONST
  SO_SNDBUF       = $1001;          { send buffer size }
  SO_RCVBUF       = $1002;          { receive buffer size }
  SO_SNDLOWAT     = $1003;          { send low-water mark }
  SO_RCVLOWAT     = $1004;          { receive low-water mark }
  SO_SNDTIMEO     = $1005;          { send timeout }
  SO_RCVTIMEO     = $1006;          { receive timeout }
  SO_ERROR        = $1007;          { get error status and clear }
  SO_TYPE         = $1008;          { get socket type }
  SO_OPTIONS      = $1010;          { get socket options }

{
 * Structure used for manipulating linger option.
 }
TYPE
  linger = RECORD
    l_onoff : Int;                { option on/off }
    l_linger: Int;               { linger time }
  END;

{
 * Level number for (get/set)sockopt() to apply to socket itself.
 }
CONST
  SOL_SOCKET      = $ffff;          { options for socket level }

{
 * Address families.
 }
CONST
  AF_UNSPEC       = 0;               { unspecified }
  AF_UNIX         = 1;               { local to host (pipes, portals) }
  AF_INET         = 2;               { internetwork: UDP, TCP, etc. }
  AF_IMPLINK      = 3;               { arpanet imp addresses }
  AF_PUP          = 4;               { pup protocols: e.g. BSP }
  AF_CHAOS        = 5;               { mit CHAOS protocols }
  AF_NS           = 6;               { XEROX NS protocols }
  AF_NBS          = 7;               { nbs protocols }
  AF_ECMA         = 8;               { european computer manufacturers }
  AF_DATAKIT      = 9;               { datakit protocols }
  AF_CCITT        = 10;              { CCITT protocols, X.25 etc }
  AF_SNA          = 11;              { IBM SNA }
  AF_DECnet       = 12;              { DECnet }
  AF_DLI          = 13;              { Direct data link interface }
  AF_LAT          = 14;              { LAT }
  AF_HYLINK       = 15;              { NSC Hyperchannel }
  AF_APPLETALK    = 16;              { Apple Talk }

  AF_OS2          = AF_UNIX;

  AF_NB           = 17;              { Netbios }
  AF_NETBIOS      = AF_NB;

  AF_MAX          = 18;


{
 * Structure used by kernel to store most
 * addresses.
 }
TYPE
  sockaddr = RECORD
    sa_family : UShort;                    { address family }
    sa_data   : ARRAY[1..14] Of Char;      { up to 14 bytes of direct address }
  END;

{
 * Structure used by kernel to pass protocol
 * information in raw sockets.
 }
TYPE
  sockproto = RECORD
    sp_family  : UShort;              { address family }
    sp_protocol: UShort;            { protocol }
  END;

{
 * Protocol families, same as address families for now.
 }
CONST
  PF_UNSPEC       = AF_UNSPEC;
  PF_UNIX         = AF_UNIX;
  PF_INET         = AF_INET;
  PF_IMPLINK      = AF_IMPLINK;
  PF_PUP          = AF_PUP;
  PF_CHAOS        = AF_CHAOS;
  PF_NS           = AF_NS;
  PF_NBS          = AF_NBS;
  PF_ECMA         = AF_ECMA;
  PF_DATAKIT      = AF_DATAKIT;
  PF_CCITT        = AF_CCITT;
  PF_SNA          = AF_SNA;
  PF_DECnet       = AF_DECnet;
  PF_DLI          = AF_DLI;
  PF_LAT          = AF_LAT;
  PF_HYLINK       = AF_HYLINK;
  PF_APPLETALK    = AF_APPLETALK;
  PF_NETBIOS      = AF_NB;
  PF_NB           = AF_NB;
  PF_OS2          = PF_UNIX;
  PF_MAX          = AF_MAX;

{
 * Maximum queue length specifiable by listen.
 }
CONST
  SOMAXCONN       = 5;


{
 * Message header for recvmsg and sendmsg calls.
 }
TYPE
  piovece = ^iovec;

  msghdr = RECORD
    msg_name         : PChar;               { optional address }
    msg_namelen      : Int;                 { size of address }
    msg_iov          : piovece;             { scatter/gather array }
//    struct  iovec *  msg_iov;             { scatter/gather array }
    msg_iovlen       : Int;                 { # elements in msg_iov }
    msg_accrights    : PChar;               { access rights sent/received }
    msg_accrightslen : Int;
  END;

  iovec = RECORD
    iov_base : PChar;
    iov_len  : Int;
  END;

  uio = RECORD
    uio_iov    : piovece;
    uio_iovcnt : Int;
    uio_offset : longint;
    uio_segflg : Int;
    uio_resid  : UInt;
  END;

CONST
// enum    uio_rw { UIO_READ, UIO_WRITE };

  FREAD  = 1;
  FWRITE = 2;

  MSG_OOB         = $1;             { process out-of-band data }
  MSG_PEEK        = $2;             { peek at incoming message }
  MSG_DONTROUTE   = $4;             { send without using routing tables }
  MSG_FULLREAD    = $8;             { send without using routing tables }

  MSG_MAXIOVLEN   = 16;

{&CDECL+}
FUNCTION accept(s: int; var name: sockaddr; var namelen: int): ApiRet;
FUNCTION bind(s: int; var name: sockaddr; namelen: int): ApiRet;
FUNCTION connect(s: int; var name: sockaddr; namelen: int): ApiRet;
FUNCTION gethostid: ApiRet;
FUNCTION getpeername(s: int; var name: sockaddr; namelen: int): ApiRet;
FUNCTION getsockname(s: int; var name: sockaddr; namelen: int): ApiRet;
FUNCTION getsockopt(s: int; level: int; optname: int; var optval; var optlen: int): ApiRet;
FUNCTION ioctl(s: int; cmd: int; var data; datalen: int): ApiRet;
FUNCTION listen(s: int; backlog: int): ApiRet;
FUNCTION recvmsg(s: int; var msg: msghdr; flags: int): ApiRet;
FUNCTION recv(s: int; var buf; len: int; flags: int): ApiRet;
FUNCTION recvfrom(s: int; var buf; len: int; flags: int; var name: sockaddr; var namelen: int): ApiRet;
{$ifndef BSD_SELECT}
FUNCTION select(s: pointer; noreads: int; nowrites: int; noexcepts: int; timeout: long): ApiRet;
{$endif}
FUNCTION send(s: int; var buf; len: int; flags: int): ApiRet;
FUNCTION sendmsg(s: int; var msg: msghdr; flags: int): ApiRet;
FUNCTION sendto(s: int; var buf; len: int; flags: int; var name: sockaddr; namelen: int): ApiRet;
FUNCTION setsockopt(s: int; level: int; optname: int; var optval; optlen: int): ApiRet;
FUNCTION sock_init: ApiRet;
FUNCTION sock_errno: ApiRet;
PROCEDURE psock_errno(error: pchar);
FUNCTION socket(domain: int; stype: int; protocol: int): ApiRet;
FUNCTION soclose(s: int): ApiRet;
FUNCTION soabort(s: int): ApiRet;
FUNCTION so_cancel(s: int): ApiRet;
FUNCTION readv(s: int; var iov; iovcnt: int): ApiRet;
FUNCTION writev(s: int; var iov; iovcnt: int): ApiRet;
FUNCTION shutdown(s: int; howto: int): ApiRet;
FUNCTION getinetversion(ver: pchar): ApiRet;
{&CDECL-}

CONST
  MT_FREE         = 0;       { should be on free list }
  MT_DATA         = 1;       { dynamic (data) allocation }
  MT_HEADER       = 2;       { packet header }
  MT_SOCKET       = 3;       { socket structure }
  MT_PCB          = 4;       { protocol control block }
  MT_RTABLE       = 5;       { routing tables }
  MT_HTABLE       = 6;       { IMP host tables }
  MT_ATABLE       = 7;       { address resolution tables }
  MT_SONAME       = 8;       { socket name }
  MT_ZOMBIE       = 9;       { zombie proc status }
  MT_SOOPTS       = 10;      { socket options }
  MT_FTABLE       = 11;      { fragment reassembly header }
  MT_RIGHTS       = 12;      { access rights }
  MT_IFADDR       = 13;      { interface address }

const
  MAXHOSTNAMELEN = 120;
  MAXSOCKETS = 2048;

{#pragma pack(1)}
{ used to get mbuf statistics }
TYPE
  mbstat = RECORD
    m_mbufs   : ushort;                   { mbufs obtained from page pool }
    m_clusters: ushort;                   { clusters obtained from page pool }
    m_clfree  : ushort;                   { free clusters }
    m_drops   : ushort;                   { times failed to find space }
    m_wait    : ulong;                    { times waited for space }
    m_mtypes  : ARRAY[1..256] of UShort;  { type specific mbuf allocations }
  END;

  sostats = RECORD
    count     : short;
    socketdata: ARRAY[1..9*MAXSOCKETS] of short;
  END;

{#pragma pack()}

{#endif  __SOCKET_32H}

CONST
  IOCPARM_MASK   = $7f;          { parameters must be < 128 bytes }
  IOC_VOID       = $20000000;    { no parameters }
  IOC_OUT        = $40000000;    { copy out parameters }
  IOC_IN         = $80000000;    { copy in parameters }
  IOC_INOUT      = (IOC_IN OR IOC_OUT);
          { $20000000 distinguishes new &
             old ioctl's }
(*
#define _IO(x,y)  (IOC_VOID|(x<<8)|y)
#define _IOR(x,y,t) (IOC_OUT|(((long)sizeof(t)&IOCPARM_MASK)<<16)|(x<<8)|y)
#define _IOW(x,y,t) (IOC_IN|(((long)sizeof(t)&IOCPARM_MASK)<<16)|(x<<8)|y)
*)

  FIONREAD   = (IOC_OUT OR ((4 AND IOCPARM_MASK) SHL 16) OR (ord('f') SHL 8) OR 127);  { get # bytes to read }
  FIONBIO    = (IOC_IN OR ((4 AND IOCPARM_MASK) SHL 16) OR (ord('f') SHL 8) OR 126);   { set/clear non-blocking i/o }
  FIOASYNC   = (IOC_IN OR ((4 AND IOCPARM_MASK) SHL 16) OR (ord('f') SHL 8) OR 125);   { set/clear async i/o }

IMPLEMENTATION

{$L SO32DLL.LIB}

{&CDECL+}
FUNCTION accept;                EXTERNAL;
FUNCTION bind;                  EXTERNAL;
FUNCTION connect;               EXTERNAL;
FUNCTION gethostid;             EXTERNAL;
FUNCTION getpeername;           EXTERNAL;
FUNCTION getsockname;           EXTERNAL;
FUNCTION getsockopt;            EXTERNAL;
FUNCTION ioctl;                 EXTERNAL;
FUNCTION listen;                EXTERNAL;
FUNCTION recvmsg;               EXTERNAL;
FUNCTION recv;                  EXTERNAL;
FUNCTION recvfrom;              EXTERNAL;
{$ifndef BSD_SELECT}
FUNCTION select;                EXTERNAL;
{$endif}
FUNCTION send;                  EXTERNAL;
FUNCTION sendmsg;               EXTERNAL;
FUNCTION sendto;                EXTERNAL;
FUNCTION setsockopt;            EXTERNAL;
FUNCTION sock_init;             EXTERNAL;
FUNCTION sock_errno;            EXTERNAL;
PROCEDURE psock_errno;          EXTERNAL;
FUNCTION socket;                EXTERNAL;
FUNCTION soclose;               EXTERNAL;
FUNCTION soabort;               EXTERNAL;
FUNCTION so_cancel;             EXTERNAL;
FUNCTION readv;                 EXTERNAL;
FUNCTION writev;                EXTERNAL;
FUNCTION shutdown;              EXTERNAL;
FUNCTION getinetversion;        EXTERNAL;
{&CDECL-}

END.

