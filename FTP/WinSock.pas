{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.8 $    $Date: 1999/07/15 07:54:48 $    $Author: sag $ }
{                                                                             }
{ Converted from winsock.h found in wsa_dev.zip                               }
UNIT Winsock;

{&OrgName+,Use32-,Open32-}

INTERFACE

USES Windows, CTypes;
{ WINSOCK.H--definitions to be used with the WINSOCK.DLL

 *
 * This header file corresponds to ESocketn 1.1.Create ets specification.
 *
 * This file includes parts which are Copyright (c) 1982-1986 Regents
 * of the University of California.  All rights reserved.  The
UNIT Winsock;
 * Berkeley Software License Agreement he terms and
 * conditions for redistribution.
 *
 * 05/19/95  rcq  removed const from buf argument WSAAsyncGetHostByAddr()
 }

{#ifndef _WINSOCKAPI_
#define _WINSOCKAPI_}

{
 * Pull in WINDOWS.H if necessary
 }
{#ifndef _INC_WINDOWS
#include <windows.h>
#endif} { _INC_WINDOWS }

{
 * Basic system type definitions, taken from the BSD file sys/types.h.
 }
TYPE
  u_char  = Char;
  u_short = Word;
  u_int   = uint;
  u_long  = ulong;

{
 * The new type to be used in all
 * instances which refer to sockets.
 }
TYPE
  TSOCKET = u_int;

{
 * Select uses arrays of SOCKETs.  These macros manipulate such
 * arrays.  FD_SETSIZE may be defined by the user before including
 * this file, but the default here should be >= 64.
 *
 * CAVEAT IMPLEMENTOR and USER: THESE MACROS AND TYPES MUST BE
 * INCLUDED IN WINSOCK.H EXACTLY AS SHOWN HERE.
 }
{#ifndef FD_SETSIZE}
CONST
  FD_SETSIZE   = 64;
{#endif  FD_SETSIZE }

TYPE
  pfd_set = ^fd_set;
  fd_set = RECORD
    fd_count : LongInt;           //u_short;      { how many are SET? }
    fd_array : ARRAY[1..FD_SETSIZE] OF TSOCKET;   { an array of SOCKETs }
  END;  {fd_set;}

{&StdCall+}
FUNCTION __WSAFDIsSet(Socket: TSOCKET; VAR fd_set): int;
{&StdCall-}

{$IFDEF XXYYZZ}
#define FD_CLR(fd, set) do { \
    u_int __i; \
    for (__i = 0; __i < ((fd_set FAR *)(set))->fd_count ; __i++) { \
  if (((fd_set FAR *)(set))->fd_array[__i] == fd) { \
      while (__i < ((fd_set FAR *)(set))->fd_count-1) { \
    ((fd_set FAR *)(set))->fd_array[__i] = \
        ((fd_set FAR *)(set))->fd_array[__i+1]; \
    __i++; \
      } \
      ((fd_set FAR *)(set))->fd_count--; \
      break; \
  } \
    } \
} while(0)

#define FD_SET(fd, set) do { \
    if (((fd_set FAR *)(set))->fd_count < FD_SETSIZE) \
  ((fd_set FAR *)(set))->fd_array[((fd_set FAR *)(set))->fd_count++]=fd;\
} while(0)

#define FD_ZERO(set) (((fd_set FAR *)(set))->fd_count=0)

#define FD_ISSET(fd, set) __WSAFDIsSet((SOCKET)fd, (fd_set FAR *)set)
{$ENDIF}

{
 * Structure used in select() call, taken from the BSD file sys/time.h.
 }
TYPE
  ptimeval = ^timeval;
  timeval = RECORD
    tv_sec  : long;    { seconds }
    tv_usec : long;    { and microseconds }
  END;

{
 * Operations on timevals.
 *
 * NB: timercmp does not work for >= or <=.
 }
(*
#define timerisset(tvp)   ((tvp)->tv_sec || (tvp)->tv_usec)
#define timercmp(tvp, uvp, cmp) \
  ((tvp)->tv_sec cmp (uvp)->tv_sec || \
   (tvp)->tv_sec == (uvp)->tv_sec && (tvp)->tv_usec cmp (uvp)->tv_usec)
#define timerclear(tvp)   (tvp)->tv_sec = (tvp)->tv_usec = 0
*)
{
 * Commands for ioctlsocket(),  taken from the BSD file fcntl.h.
 *
 *
 * Ioctl's have the command encoded in the lower word,
 * and the size of any in or out parameters in the upper
 * word.  The high 2 bits of the upper word are used
 * to encode the in/out status of the parameter; for now
 * we restrict parameters to at most 128 bytes.
 }
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

(*
{ Socket I/O Controls }
#define SIOCSHIWAT  _IOW('s',  0, u_long)  { set high watermark }
#define SIOCGHIWAT  _IOR('s',  1, u_long)  { get high watermark }
#define SIOCSLOWAT  _IOW('s',  2, u_long)  { set low watermark }
#define SIOCGLOWAT  _IOR('s',  3, u_long)  { get low watermark }
#define SIOCATMARK  _IOR('s',  7, u_long)  { at oob mark? }
*)

{
 * Internet address (old style... should be updated)
 }
TYPE
  SunB = RECORD
    s_b1, s_b2, s_b3, s_b4: u_char;
  END;

  SunW = RECORD
    s_w1, s_w2: u_short;
  END;

  pin_addr = ^in_addr;
  in_addr = RECORD
    CASE Integer OF
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: u_long);
  END;

{
 * Structures returned by network data base library, taken from the
 * BSD file netdb.h.  All addresses are supplied in host order, and
 * returned in network order (suitable for use in system calls).
 }
TYPE
  phostent = ^hostent;
  hostent = RECORD
    h_name      : PChar;     { official name of host }
    h_aliases   : ^PChar;    { alias list }
    h_addrtype  : short;     { host address type }
    h_length    : short;     { length of address }
    case integer of
     0: (h_addr_list : ^pointer);    { list of addresses }
     1: (h_addr      : ^pin_addr);   { address, for backward compat }
 END;

{
 * It is assumed here that a network number
 * fits in 32 bits.
 }
TYPE
  netent = RECORD
    n_name     : pchar;     { official name of net }
    n_aliases  : ^pchar;    { alias list }
    n_addrtype : short;     { net address type }
    n_net      : u_long;    { network # }
  END;

  pservent = ^servent;
  servent = RECORD
    s_name    : pchar;     { official service name }
    s_aliases : ^pchar;    { alias list }
    s_port    : short;     { port # }
    s_proto   : pchar;     { protocol to use }
  END;

  pprotoent = ^protoent;
  protoent = RECORD
    p_name    : pchar;     { official protocol name }
    p_aliases : ^pchar;    { alias list }
    p_proto   : short;     { protocol # }
  END;

{
 * Constants and structures defined by the internet system,
 * Per RFC 790, September 1981, taken from the BSD file netinet/in.h.
 }

{
 * Protocols
 }
CONST
  IPPROTO_IP     = 0;       { dummy for IP }
  IPPROTO_ICMP   = 1;       { control message protocol }
  IPPROTO_GGP    = 2;       { gateway^2 (deprecated) }
  IPPROTO_TCP    = 6;       { tcp }
  IPPROTO_PUP    = 12;      { pup }
  IPPROTO_UDP    = 17;      { user datagram protocol }
  IPPROTO_IDP    = 22;      { xns idp }
  IPPROTO_ND     = 77;      { UNOFFICIAL net disk proto }

  IPPROTO_RAW    = 255;     { raw IP packet }
  IPPROTO_MAX    = 256;

{
 * Port/socket numbers: network standard functions
 }
CONST
  IPPORT_ECHO        = 7;
  IPPORT_DISCARD     = 9;
  IPPORT_SYSTAT      = 11;
  IPPORT_DAYTIME     = 13;
  IPPORT_NETSTAT     = 15;
  IPPORT_FTP         = 21;
  IPPORT_TELNET      = 23;
  IPPORT_SMTP        = 25;
  IPPORT_TIMESERVER  = 37;
  IPPORT_NAMESERVER  = 42;
  IPPORT_WHOIS       = 43;
  IPPORT_MTP         = 57;

{
 * Port/socket numbers: host specific functions
 }
CONST
  IPPORT_TFTP        = 69;
  IPPORT_RJE         = 77;
  IPPORT_FINGER      = 79;
  IPPORT_TTYLINK     = 87;
  IPPORT_SUPDUP      = 95;

{
 * UNIX TCP sockets
 }
CONST
  IPPORT_EXECSERVER  = 512;
  IPPORT_LOGINSERVER = 513;
  IPPORT_CMDSERVER   = 514;
  IPPORT_EFSSERVER   = 520;

{
 * UNIX UDP sockets
 }
CONST
  IPPORT_BIFFUDP     = 512;
  IPPORT_WHOSERVER   = 513;
  IPPORT_ROUTESERVER = 520;
          { 520+1 also used }

{
 * Ports < IPPORT_RESERVED are reserved for
 * privileged processes (e.g. root).
 }
CONST
  IPPORT_RESERVED    = 1024;

{
 * Link numbers
 }
CONST
  IMPLINK_IP         = 155;
  IMPLINK_LOWEXPER   = 156;
  IMPLINK_HIGHEXPER  = 158;

(*
#define s_addr  S_un.S_addr
        { can be used for most tcp & ip code }
#define s_host  S_un.S_un_b.s_b2
        { host on imp }
#define s_net S_un.S_un_b.s_b1
        { network }
#define s_imp S_un.S_un_w.s_w2
        { imp }
#define s_impno S_un.S_un_b.s_b4
        { imp # }
#define s_lh  S_un.S_un_b.s_b3
        { logical host }
*)

{
 * Definitions of bits in internet address integers.
 * On subnets, the decomposition of addresses to host and net parts
 * is done according to subnet mask, not the masks here.
}
CONST
{  IN_CLASSA(i)     = (((long)(i) & $80000000) == 0);}
  IN_CLASSA_NET    = $ff000000;
  IN_CLASSA_NSHIFT = 24;
  IN_CLASSA_HOST   = $00ffffff;
  IN_CLASSA_MAX    = 128;

{  IN_CLASSB(i)     = (((long)(i) & $c0000000) == $80000000);}
  IN_CLASSB_NET    = $ffff0000;
  IN_CLASSB_NSHIFT = 16;
  IN_CLASSB_HOST   = $0000ffff;
  IN_CLASSB_MAX    = 65536;

{  IN_CLASSC(i)     = (((long)(i) & $c0000000) == $c0000000);}
  IN_CLASSC_NET    = $ffffff00;
  IN_CLASSC_NSHIFT = 8;
  IN_CLASSC_HOST   = $000000ff;

  INADDR_ANY       : u_long = $00000000;
  INADDR_LOOPBACK  = $7f000001;
  INADDR_BROADCAST : ulong = $ffffffff;
  INADDR_NONE      = $ffffffff;

{
 * Socket address, internet style.
 }
TYPE
  sockaddr_in = RECORD
    sin_family : short;
    sin_port   : u_short;
    sin_addr   : in_addr;
    sin_zero   : ARRAY[1..8] OF Char;
  END;

CONST
  WSADESCRIPTION_LEN   = 256;
  WSASYS_STATUS_LEN    = 128;

TYPE
  WSAData = RECORD
    wVersion     : Word;
    wHighVersion   : Word;
    szDescription  : ARRAY[0..WSADESCRIPTION_LEN+1] OF Char;
    szSystemStatus : ARRAY[0..WSASYS_STATUS_LEN+1] OF Char;
    iMaxSockets    : ushort;
    iMaxUdpDg      : ushort;
    lpVendorInfo   : PChar;
  END; //= WSADATA;

//typedef WSADATA FAR *LPWSADATA;

{
 * Options for use with [gs]etsockopt at the IP level.
 }
CONST
  IP_OPTIONS   = 1;       { set/get IP per-packet options }

{
 * Definitions related to sockets: types, address families, options,
 * taken from the BSD file sys/socket.h.
 }

{
 * This is used instead of -1, since the
 * SOCKET type is unsigned.
 }
CONST
  INVALID_SOCKET : TSOCKET = NOT 0;
  SOCKET_ERROR             = -1;

{
 * Types
 }
CONST
  SOCK_STREAM    = 1;       { stream socket }
  SOCK_DGRAM     = 2;       { datagram socket }
  SOCK_RAW       = 3;       { raw-protocol interface }
  SOCK_RDM       = 4;       { reliably-delivered message }
  SOCK_SEQPACKET = 5;       { sequenced packet stream }

{
 * Option flags per-socket.
 }
CONST
  SO_DEBUG       = $0001;    { turn on debugging info recording }
  SO_ACCEPTCONN  = $0002;    { socket has had listen() }
  SO_REUSEADDR   = $0004;    { allow local address reuse }
  SO_KEEPALIVE   = $0008;    { keep connections alive }
  SO_DONTROUTE   = $0010;    { just use interface addresses }
  SO_BROADCAST   = $0020;    { permit sending of broadcast msgs }
  SO_USELOOPBACK = $0040;    { bypass hardware when possible }
  SO_LINGER      = $0080;    { linger on close if data present }
  SO_OOBINLINE   = $0100;    { leave received OOB data in line }

  SO_DONTLINGER  : u_int = NOT SO_LINGER;

{
 * Additional options.
 }
CONST
  SO_SNDBUF    = $1001;    { send buffer size }
  SO_RCVBUF    = $1002;    { receive buffer size }
  SO_SNDLOWAT  = $1003;    { send low-water mark }
  SO_RCVLOWAT  = $1004;    { receive low-water mark }
  SO_SNDTIMEO  = $1005;    { send timeout }
  SO_RCVTIMEO  = $1006;    { receive timeout }
  SO_ERROR     = $1007;    { get error status and clear }
  SO_TYPE      = $1008;    { get socket type }

{
 * TCP options.
 }
CONST
  TCP_NODELAY  = $0001;

{
 * Address families.
 }
CONST
  AF_UNSPEC    = 0;       { unspecified }
  AF_UNIX      = 1;       { local to host (pipes, portals) }
  AF_INET      = 2;       { internetwork: UDP, TCP, etc. }
  AF_IMPLINK   = 3;       { arpanet imp addresses }
  AF_PUP       = 4;       { pup protocols: e.g. BSP }
  AF_CHAOS     = 5;       { mit CHAOS protocols }
  AF_NS        = 6;       { XEROX NS protocols }
  AF_ISO       = 7;       { ISO protocols }
  AF_OSI       = AF_ISO;  { OSI is ISO }
  AF_ECMA      = 8;       { european computer manufacturers }
  AF_DATAKIT   = 9;       { datakit protocols }
  AF_CCITT     = 10;      { CCITT protocols, X.25 etc }
  AF_SNA       = 11;      { IBM SNA }
  AF_DECnet    = 12;      { DECnet }
  AF_DLI       = 13;      { Direct data link interface }
  AF_LAT       = 14;      { LAT }
  AF_HYLINK    = 15;      { NSC Hyperchannel }
  AF_APPLETALK = 16;      { AppleTalk }
  AF_NETBIOS   = 17;      { NetBios-style addresses }
  AF_MAX       = 18;

{
 * Structure used by kernel to store most
 * addresses.
 }
TYPE
  sockaddr = RECORD
    sa_family : u_short;    { address family }
    sa_data   : ARRAY[1..14] OF Char; { up to 14 bytes of direct address }
  END;


{
 * Structure used pro.Createtocol
 * information in raw sockets.
 }
TYPE
  sockproto = RECORD
    sp_family : u_short;    { address family }
    sp_protocol : u_short;    { protocol }
  END;

{
 * Protocol families, same as address families for now.
 }
CONST
  PF_UNSPEC    = AF_UNSPEC;
  PF_UNIX      = AF_UNIX;
  PF_INET      = AF_INET;
  PF_IMPLINK   = AF_IMPLINK;
  PF_PUP       = AF_PUP;
  PF_CHAOS     = AF_CHAOS;
  PF_NS        = AF_NS;
  PF_ISO       = AF_ISO;
  PF_OSI       = AF_OSI;
  PF_ECMA      = AF_ECMA;
  PF_DATAKIT   = AF_DATAKIT;
  PF_CCITT     = AF_CCITT;
  PF_SNA       = AF_SNA;
  PF_DECnet    = AF_DECnet;
  PF_DLI       = AF_DLI;
  PF_LAT       = AF_LAT;
  PF_HYLINK    = AF_HYLINK;
  PF_APPLETALK = AF_APPLETALK;

  PF_MAX       = AF_MAX;

{
 * Structure used for manipulating linger option.
 }
TYPE
  linger = RECORD
    l_onoff  : u_short;          { option on/off }
    l_linger : u_short;          { linger time }
  END;

{
 * Level number for (get/set)sockopt() to apply to socket itself.
 }
CONST
  SOL_SOCKET   = $ffff;    { options for socket level }

{
 * Maximum queue length specifiable by listen.
 }
CONST
  SOMAXCONN      = 5;

  MSG_OOB        = $1;       { process out-of-band data }
  MSG_PEEK       = $2;       { peek at incoming message }
  MSG_DONTROUTE  = $4;       { send without using routing tables }

  MSG_MAXIOVLEN  = 16;

{
 * Define constant based on rfc883, used by gethostbyxxxx() calls.
 }
CONST
  MAXGETHOSTSTRUCT   = 1024;

{
 * Define flags to be used with the WSAAsyncSelect() call.
 }
CONST
  FD_READ      = $01;
  FD_WRITE     = $02;
  FD_OOB       = $04;
  FD_ACCEPT    = $08;
  FD_CONNECT   = $10;
  FD_CLOSE     = $20;

{
 * All Windows Sockets error constants are biased by WSABASEERR from
 * the "normal"
 }
CONST
  WSABASEERR     = 10000;
{
 * Windows Sockets definitions of regular Microsoft C error constants
 }
CONST
  WSAEINTR     = (WSABASEERR+4);
  WSAEBADF     = (WSABASEERR+9);
  WSAEACCES    = (WSABASEERR+13);
  WSAEFAULT    = (WSABASEERR+14);
  WSAEINVAL    = (WSABASEERR+22);
  WSAEMFILE    = (WSABASEERR+24);

{
 * Windows Sockets definitions of regular Berkeley error constants
 }
CONST
  WSAEWOULDBLOCK       = (WSABASEERR+35);
  WSAEINPROGRESS       = (WSABASEERR+36);
  WSAEALREADY          = (WSABASEERR+37);
  WSAENOTSOCK          = (WSABASEERR+38);
  WSAEDESTADDRREQ      = (WSABASEERR+39);
  WSAEMSGSIZE          = (WSABASEERR+40);
  WSAEPROTOTYPE        = (WSABASEERR+41);
  WSAENOPROTOOPT       = (WSABASEERR+42);
  WSAEPROTONOSUPPORT   = (WSABASEERR+43);
  WSAESOCKTNOSUPPORT   = (WSABASEERR+44);
  WSAEOPNOTSUPP        = (WSABASEERR+45);
  WSAEPFNOSUPPORT      = (WSABASEERR+46);
  WSAEAFNOSUPPORT      = (WSABASEERR+47);
  WSAEADDRINUSE        = (WSABASEERR+48);
  WSAEADDRNOTAVAIL     = (WSABASEERR+49);
  WSAENETDOWN          = (WSABASEERR+50);
  WSAENETUNREACH       = (WSABASEERR+51);
  WSAENETRESET         = (WSABASEERR+52);
  WSAECONNABORTED      = (WSABASEERR+53);
  WSAECONNRESET        = (WSABASEERR+54);
  WSAENOBUFS           = (WSABASEERR+55);
  WSAEISCONN           = (WSABASEERR+56);
  WSAENOTCONN          = (WSABASEERR+57);
  WSAESHUTDOWN         = (WSABASEERR+58);
  WSAETOOMANYREFS      = (WSABASEERR+59);
  WSAETIMEDOUT         = (WSABASEERR+60);
  WSAECONNREFUSED      = (WSABASEERR+61);
  WSAELOOP             = (WSABASEERR+62);
  WSAENAMETOOLONG      = (WSABASEERR+63);
  WSAEHOSTDOWN         = (WSABASEERR+64);
  WSAEHOSTUNREACH      = (WSABASEERR+65);
  WSAENOTEMPTY         = (WSABASEERR+66);
  WSAEPROCLIM          = (WSABASEERR+67);
  WSAEUSERS            = (WSABASEERR+68);
  WSAEDQUOT            = (WSABASEERR+69);
  WSAESTALE            = (WSABASEERR+70);
  WSAEREMOTE           = (WSABASEERR+71);

{
 * Extended Windows Sockets error constant definitions
 }
CONST
  WSASYSNOTREADY       = (WSABASEERR+91);
  WSAVERNOTSUPPORTED   = (WSABASEERR+92);
  WSANOTINITIALISED    = (WSABASEERR+93);

{
 * Error return codes from gethostbyname() and gethostbyaddr()
 * (when using the resolver). Note that these errors are
 * retrieved via WSAGetLastError() and must therefore follow
 * the rules for avoiding clashes with error numbers from
 * specific implementations or language run-time systems.
 * For this reason the codes are based at WSABASEERR+1001.
 * Note also that [WSA]NO_ADDRESS is defined only for
 * compatibility purposes.
 }

//#define h_errno   WSAGetLastError()

CONST
{ Authoritative Answer: Host not found }
  WSAHOST_NOT_FOUND  = (WSABASEERR+1001);
  HOST_NOT_FOUND     = WSAHOST_NOT_FOUND;

{ Non-Authoritative: Host not found, or SERVERFAIL }
  WSATRY_AGAIN       = (WSABASEERR+1002);
  TRY_AGAIN          = WSATRY_AGAIN;

{ Non recoverable errors, FORMERR, REFUSED, NOTIMP }
  WSANO_RECOVERY     = (WSABASEERR+1003);
  NO_RECOVERY        = WSANO_RECOVERY;

{ Valid name, no data record of requested type }
  WSANO_DATA         = (WSABASEERR+1004);
  NO_DATA            = WSANO_DATA;

{ no address, look for MX record }
  WSANO_ADDRESS      = WSANO_DATA;
  NO_ADDRESS         = WSANO_ADDRESS;

{
 * Windows Sockets errors redefined as regular Berkeley error constants
 }
CONST
  EWOULDBLOCK      = WSAEWOULDBLOCK;
  EINPROGRESS      = WSAEINPROGRESS;
  EALREADY         = WSAEALREADY;
  ENOTSOCK         = WSAENOTSOCK;
  EDESTADDRREQ     = WSAEDESTADDRREQ;
  EMSGSIZE         = WSAEMSGSIZE;
  EPROTOTYPE       = WSAEPROTOTYPE;
  ENOPROTOOPT      = WSAENOPROTOOPT;
  EPROTONOSUPPORT  = WSAEPROTONOSUPPORT;
  ESOCKTNOSUPPORT  = WSAESOCKTNOSUPPORT;
  EOPNOTSUPP       = WSAEOPNOTSUPP;
  EPFNOSUPPORT     = WSAEPFNOSUPPORT;
  EAFNOSUPPORT     = WSAEAFNOSUPPORT;
  EADDRINUSE       = WSAEADDRINUSE;
  EADDRNOTAVAIL    = WSAEADDRNOTAVAIL;
  ENETDOWN         = WSAENETDOWN;
  ENETUNREACH      = WSAENETUNREACH;
  ENETRESET        = WSAENETRESET;
  ECONNABORTED     = WSAECONNABORTED;
  ECONNRESET       = WSAECONNRESET;
  ENOBUFS          = WSAENOBUFS;
  EISCONN          = WSAEISCONN;
  ENOTCONN         = WSAENOTCONN;
  ESHUTDOWN        = WSAESHUTDOWN;
  ETOOMANYREFS     = WSAETOOMANYREFS;
  ETIMEDOUT        = WSAETIMEDOUT;
  ECONNREFUSED     = WSAECONNREFUSED;
  ELOOP            = WSAELOOP;
  ENAMETOOLONG     = WSAENAMETOOLONG;
  EHOSTDOWN        = WSAEHOSTDOWN;
  EHOSTUNREACH     = WSAEHOSTUNREACH;
  ENOTEMPTY        = WSAENOTEMPTY;
  EPROCLIM         = WSAEPROCLIM;
  EUSERS           = WSAEUSERS;
  EDQUOT           = WSAEDQUOT;
  ESTALE           = WSAESTALE;
  EREMOTE          = WSAEREMOTE;

{ Socket function prototypes }
{#ifdef __cpluspl
extern "C"
#endif}

{&StdCall+}
FUNCTION accept(s: TSOCKET; VAR addr: sockaddr; VAR addrlen: int): TSOCKET;
FUNCTION bind(s: TSOCKET; VAR addr: sockaddr; namelen: int): int;
FUNCTION closesocket(s: TSOCKET): int;
FUNCTION connect(s: TSOCKET; VAR name: sockaddr; namelen: int): int;
FUNCTION ioctlsocket(s: TSOCKET; cmd: long; VAR argp: u_long): int;
FUNCTION getpeername(s: TSOCKET; VAR name: sockaddr; VAR namelen: int): int;
FUNCTION getsockname(s: TSOCKET; VAR name: sockaddr; VAR namelen: int): int;
FUNCTION getsockopt(s: TSOCKET; level: int; optname: int; VAR optval; VAR optlen: int): int;
FUNCTION htonl(hostlong: u_long): u_long;
FUNCTION htons(hostshort: u_short): u_short;
FUNCTION inet_addr(cp: PChar): ulong;
FUNCTION inet_ntoa(ina: in_addr): pchar;
FUNCTION listen(s: TSOCKET; backlog: int): int;
FUNCTION ntohl(netlong: u_long): u_long;
FUNCTION ntohs(netshort: u_short): u_short;
FUNCTION recv(s: TSOCKET; VAR buf; len: int; flags: int): int;
FUNCTION recvfrom(s: TSOCKET; VAR buf; len: int; flags: int; VAR from: sockaddr; VAR fromlen: int): int;
FUNCTION select(nfds: int; readfds: pfd_set; writefds: pfd_set; exceptfds: pfd_set; timeout: ptimeval): int;
FUNCTION send(s: TSOCKET; VAR buf; len: int; flags: int): int;
FUNCTION sendto(s: TSOCKET; VAR buf; len: int; flags: int; VAR to_: sockaddr; tolen: int): int;
FUNCTION setsockopt(s: TSOCKET; level: int; optname: int; VAR optval; optlen: int): int;
FUNCTION shutdown(s: TSOCKET; how: int): int;
FUNCTION socket(af: int; type_: int; protocol: int): TSOCKET;

{ Database function prototypes }

FUNCTION gethostbyaddr(var addr: in_addr; len: int; type_: int): phostent;
FUNCTION gethostbyname(name: PChar): phostent;
FUNCTION gethostname (name: PChar; namelen: int): int;
FUNCTION getservbyport(port: int; proto: PChar): pservent;
FUNCTION getservbyname(name: PChar; proto: PChar): pservent;
FUNCTION getprotobynumber(proto: int): pprotoent;
FUNCTION getprotobyname(name: PChar): pprotoent;

{ Microsoft Windows Extension function prototypes }

FUNCTION WSAStartup(wVersionRequired: Word; VAR lpWSAData: WSAData): int; stdcall;
FUNCTION WSACleanup: int;
PROCEDURE WSASetLastError(iError: int);
FUNCTION WSAGetLastError: int;
FUNCTION WSAIsBlocking: BOOL;
FUNCTION WSAUnhookBlockingHook: int;
FUNCTION WSASetBlockingHook(lpBlockFunc: Pointer): Pointer;
FUNCTION WSACancelBlockingCall: int;

{
HANDLE PASCAL FAR WSAAsyncGetServByName(HWND hWnd, u_int wMsg, const char FAR * name, const char FAR * proto, char FAR * buf, int buflen);

HANDLE PASCAL FAR WSAAsyncGetServByPort(HWND hWnd, u_int wMsg, int port, const char FAR * proto, char FAR * buf, int buflen);

HANDLE PASCAL FAR WSAAsyncGetProtoByName(HWND hWnd, u_int wMsg, const char FAR * name, char FAR * buf, int buflen);

HANDLE PASCAL FAR WSAAsyncGetProtoByNumber(HWND hWnd, u_int wMsg, int number, char FAR * buf, int buflen);

HANDLE PASCAL FAR WSAAsyncGetHostByName(HWND hWnd, u_int wMsg, const char FAR * name, char FAR * buf, int buflen);

HANDLE PASCAL FAR WSAAsyncGetHostByAddr(HWND hWnd, u_int wMsg, const char FAR * addr, int len, int type, char FAR * buf, int buflen);

int PASCAL FAR WSACancelAsyncRequest(HANDLE hAsyncTaskHandle);

int PASCAL FAR WSAAsyncSelect(SOCKET s, HWND hWnd, u_int wMsg, long lEvent);
}
{&StdCall-}
{#ifdef __cplusplus

#endif}

{ Microsoft Windows Extended data types }
{
typedef struct sockaddr SOCKADDR;
typedef struct sockaddr *PSOCKADDR;
typedef struct sockaddr FAR *LPSOCKADDR;

typedef struct sockaddr_in SOCKADDR_IN;
typedef struct sockaddr_in *PSOCKADDR_IN;
typedef struct sockaddr_in FAR *LPSOCKADDR_IN;

typedef struct linger LINGER;
typedef struct linger *PLINGER;
typedef struct linger FAR *LPLINGER;

typedef struct in_addr IN_ADDR;
typedef struct in_addr *PIN_ADDR;
typedef struct in_addr FAR *LPIN_ADDR;

typedef struct fd_set FD_SET;
typedef struct fd_set *PFD_SET;
typedef struct fd_set FAR *LPFD_SET;

typedef struct hostent HOSTENT;
typedef struct hostent *PHOSTENT;
typedef struct hostent FAR *LPHOSTENT;

typedef struct servent SERVENT;
typedef struct servent *PSERVENT;
typedef struct servent FAR *LPSERVENT;

typedef struct protoent PROTOENT;
typedef struct protoent *PPROTOENT;
typedef struct protoent FAR *LPPROTOENT;

typedef struct timeval TIMEVAL;
typedef struct timeval *PTIMEVAL;
typedef struct timeval FAR *LPTIMEVAL;
}
{
 * Windows message parameter composition and decomposition
 * macros.
 *
 * WSAMAKEASYNCREPLY is intended for use by the Windows Sockets implementation
 * when constructing the response to a WSAAsyncGetXByY() routine.
 }
(*
#define WSAMAKEASYNCREPLY(buflen,error)     MAKELONG(buflen,error)
{
 * WSAMAKESELECTREPLY is intended for use by the Windows Sockets implementation
 * when constructing the response to WSAAsyncSelect().
 }
#define WSAMAKESELECTREPLY(event,error)     MAKELONG(event,error)
{
 * WSAGETASYNCBUFLEN is intended for use by the Windows Sockets application
 * to extract the buffer length from the lParam in the response
 * to a WSAGetXByY().
 }
#define WSAGETASYNCBUFLEN(lParam)     LOWORD(lParam)
{
 * WSAGETASYNCERROR is intended for use by the Windows Sockets application
 * to extract the error code from the lParam in the response
 * to a WSAGetXByY().
 }
#define WSAGETASYNCERROR(lParam)      HIWORD(lParam)
{
 * WSAGETSELECTEVENT is intended for use by the Windows Sockets application
 * to extract the event code from the lParam in the response
 * to a WSAAsyncSelect().
 }
#define WSAGETSELECTEVENT(lParam)     LOWORD(lParam)
{
 * WSAGETSELECTERROR is intended for use by the Windows Sockets application
 * to extract the error code from the lParam in the response
 * to a WSAAsyncSelect().
 }
#define WSAGETSELECTERROR(lParam)     HIWORD(lParam)
*)
{#endif   _WINSOCKAPI_ }

IMPLEMENTATION

{.$L WSOCK32.LIB}

{&StdCall+}
FUNCTION __WSAFDIsSet;            EXTERNAL 'wsock32.dll' NAME '__WSAFDIsSet';

FUNCTION accept;                  EXTERNAL 'wsock32.dll' NAME 'accept';
FUNCTION bind;                    EXTERNAL 'wsock32.dll' NAME 'bind';
FUNCTION closesocket;             EXTERNAL 'wsock32.dll' NAME 'closesocket';
FUNCTION connect;                 EXTERNAL 'wsock32.dll' NAME 'connect';
FUNCTION ioctlsocket;             EXTERNAL 'wsock32.dll' NAME 'ioctlsocket';
FUNCTION getpeername;             EXTERNAL 'wsock32.dll' NAME 'getpeername';
FUNCTION getsockname;             EXTERNAL 'wsock32.dll' NAME 'getsockname';
FUNCTION getsockopt;              EXTERNAL 'wsock32.dll' NAME 'getsockopt';
FUNCTION htonl;                   EXTERNAL 'wsock32.dll' NAME 'htonl';
FUNCTION htons;                   EXTERNAL 'wsock32.dll' NAME 'htons';
FUNCTION inet_addr;               EXTERNAL 'wsock32.dll' NAME 'inet_addr';
FUNCTION inet_ntoa;               EXTERNAL 'wsock32.dll' NAME 'inet_ntoa';
FUNCTION listen;                  EXTERNAL 'wsock32.dll' NAME 'listen';
FUNCTION ntohl;                   EXTERNAL 'wsock32.dll' NAME 'ntohl';
FUNCTION ntohs;                   EXTERNAL 'wsock32.dll' NAME 'ntohs';
FUNCTION recv;                    EXTERNAL 'wsock32.dll' NAME 'recv';
FUNCTION recvfrom;                EXTERNAL 'wsock32.dll' NAME 'recvfrom';
FUNCTION select;                  EXTERNAL 'wsock32.dll' NAME 'select';
FUNCTION send;                    EXTERNAL 'wsock32.dll' NAME 'send';
FUNCTION sendto;                  EXTERNAL 'wsock32.dll' NAME 'sendto';
FUNCTION setsockopt;              EXTERNAL 'wsock32.dll' NAME 'setsockopt';
FUNCTION shutdown;                EXTERNAL 'wsock32.dll' NAME 'shutdown';
FUNCTION socket;                  EXTERNAL 'wsock32.dll' NAME 'socket';


FUNCTION gethostbyaddr;           EXTERNAL 'wsock32.dll' NAME 'gethostbyaddr';
FUNCTION gethostbyname;           EXTERNAL 'wsock32.dll' NAME 'gethostbyname';
FUNCTION gethostname;             EXTERNAL 'wsock32.dll' NAME 'gethostname';
FUNCTION getservbyport;           EXTERNAL 'wsock32.dll' NAME 'getservbyport';
FUNCTION getservbyname;           EXTERNAL 'wsock32.dll' NAME 'getservbyname';
FUNCTION getprotobynumber;        EXTERNAL 'wsock32.dll' NAME 'getprotobynumber';
FUNCTION getprotobyname;          EXTERNAL 'wsock32.dll' NAME 'getprotobyname';


FUNCTION WSAStartup;              EXTERNAL 'wsock32.dll' NAME 'WSAStartup';
FUNCTION WSACleanup;              EXTERNAL 'wsock32.dll' NAME 'WSACleanup';
PROCEDURE WSASetLastError;        EXTERNAL 'wsock32.dll' NAME 'WSASetLastError';
FUNCTION WSAGetLastError;         EXTERNAL 'wsock32.dll' NAME 'WSAGetLastError';
FUNCTION WSAIsBlocking;           EXTERNAL 'wsock32.dll' NAME 'WSAIsBlocking';
FUNCTION WSAUnhookBlockingHook;   EXTERNAL 'wsock32.dll' NAME 'WSAUnhookBlockingHook';
FUNCTION WSASetBlockingHook;      EXTERNAL 'wsock32.dll' NAME 'WSASetBlockingHook';
FUNCTION WSACancelBlockingCall;   EXTERNAL 'wsock32.dll' NAME 'WSACancelBlockingCall';

{
HANDLE PASCAL FAR WSAAsyncGetServByName(HWND hWnd, u_int wMsg, const char FAR * name, const char FAR * proto, char FAR * buf, int buflen);
HANDLE PASCAL FAR WSAAsyncGetServByPort(HWND hWnd, u_int wMsg, int port, const char FAR * proto, char FAR * buf, int buflen);
HANDLE PASCAL FAR WSAAsyncGetProtoByName(HWND hWnd, u_int wMsg, const char FAR * name, char FAR * buf, int buflen);
HANDLE PASCAL FAR WSAAsyncGetProtoByNumber(HWND hWnd, u_int wMsg, int number, char FAR * buf, int buflen);
HANDLE PASCAL FAR WSAAsyncGetHostByName(HWND hWnd, u_int wMsg, const char FAR * name, char FAR * buf, int buflen);
HANDLE PASCAL FAR WSAAsyncGetHostByAddr(HWND hWnd, u_int wMsg, const char FAR * addr, int len, int type, char FAR * buf, int buflen);
int PASCAL FAR WSACancelAsyncRequest(HANDLE hAsyncTaskHandle);
int PASCAL FAR WSAAsyncSelect(SOCKET s, HWND hWnd, u_int wMsg, long lEvent);
}
{&StdCall-}

END.

