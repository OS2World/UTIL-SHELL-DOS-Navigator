{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.8 $    $Date: 1999/07/15 07:54:48 $    $Author: sag $ }
{                                                                             }
{ Converted from nerrno.h found on the OS/2 Warp 4 CD                         }
UNIT NetDB;

{&OrgName+,Use32-,Open32-}

INTERFACE

USES OS2Def, CTypes, SockIn;

{#ifndef __NETDB_32H
#define __NETDB_32H}
{
 * Copyright (c) 1980,1983,1988 Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that this notice is preserved and that due credit is given
 * to the University of California at Berkeley. The name of the University
 * may not be used to endorse or promote products derived from this
 * software without specific prior written permission. This software
 * is provided ``as is'' without express or implied warranty.
 *
 *      @(#)netdb.h     5.9 (Berkeley) 4/5/88
 }


{
 * Structures returned by network
 * data base library.  All addresses
 * are supplied in host order, and
 * returned in network order (suitable
 * for use in system calls).
 }
TYPE
  phostent = ^hostent;
  hostent = RECORD
    h_name      : pchar;     { official name of host }
    h_aliases   : ^pchar;    { alias list }
    h_addrtype  : int;       { host address type }
    h_length    : int;       { length of address }
    case integer of
     0: (h_addr_list : ^pointer);    { list of addresses from name server }
     1: (h_addr      : ^pin_addr); { address, for backward compatiblity }
  END;

{
 * Assumption here is that a network number
 * fits in 32 bits -- probably a poor one.
 }
  pnetent = ^netent;
  netent = RECORD
    n_name     : pchar;          { official name of net }
    n_aliases  : ^pchar;         { alias list }
    n_addrtype : int;            { net address type }
    n_net      : ulong;          { network # }
  END;

  Pservent = ^servent;
  servent = RECORD
    s_name    : pchar;       { official service name }
    s_aliases : ^pchar;      { alias list }
    s_port    : int;         { port # }
    s_proto   : pchar;       { protocol to use }
  END;

  pprotoent = ^protoent;
  protoent = RECORD
    p_name    : pchar;     { official protocol name }
    p_aliases : ^pchar;    { alias list }
    p_proto   : int;       { protocol # }
  END;

{#include <stdio.h>
#include <string.h>
#include <netinet\in.h>}

CONST
  _MAXALIASES     = 35;
  _MAXADDRS       = 35;
  _MAXLINELEN     = 1024;
  _HOSTBUFSIZE    = (BUFSIZ + 1);

{
 * After a successful call to gethostbyname_r()/gethostbyaddr_r(), the
 * structure hostent_data will contain the data to which pointers in
 * the hostent structure will point to.
 }
TYPE
  hostent_data = RECORD
    host_addr      : in_addr;                          { host address pointer }
    h_addr_ptrs    : ARRAY[1.._MAXADDRS+1] of pchar;   { host address         }
    hostaddr       : ARRAY[1.._MAXADDRS] of char;
    hostbuf        : ARRAY[1.._HOSTBUFSIZE+1] of char; { host data            }
    host_aliases   : ARRAY[1.._MAXALIASES] of pchar;
    host_addrs     : ARRAY[1..2] of pchar;
    hostf          : ^file;
    stayopen       : int;                              { AIX addon            }
    host_addresses : ARRAY[1.._MAXADDRS] of ulong;     { As per defect 48367. }
  END;                                                 {    Actual Addresses. }

  servent_data = RECORD          { should be considered opaque }
    serv_fp        : ^file;
    line           : ARRAY[1.._MAXLINELEN] of char;
    serv_aliases   : ARRAY[1.._MAXALIASES] of pchar;
    _serv_stayopen : int;
  END;

{&CDECL+}
//int _System gethostbyname_r(char *, struct hostent *, struct hostent_data *);
//int _System gethostbyaddr_r(char *, int, int, struct hostent *, struct hostent_data *);
//int _System getservbyname_r(char *, char *, struct servent *, struct servent_data *);
FUNCTION gethostname(name: pchar; namelen: int): ApiRet;
FUNCTION gethostbyname(name: pchar): phostent;
//struct hostent * _System _gethtbyname( char * );
FUNCTION gethostbyaddr(var addr: in_addr; addrlen: int; addrfam: int): phostent;
//struct hostent * _System _gethtbyaddr( char *, int, int );
FUNCTION getnetbyname(name: pchar): pnetent;
FUNCTION getnetbyaddr(net:  ulong; atype: int): pnetent;
FUNCTION getservbyname(name: pchar; proto: pchar): pservent;
FUNCTION getservbyport(port: int; proto: pchar): pservent;
FUNCTION getservent: pservent;
FUNCTION getprotobyname(proto: pchar): pprotoent;
FUNCTION getprotobynumber(proto: int): pprotoent;
PROCEDURE sethostent(stayopen: int);
FUNCTION gethostent: phostent;
PROCEDURE endhostent;
PROCEDURE setnetent(stayopen: int);
FUNCTION getnetent: pnetent;
PROCEDURE endnetent;
PROCEDURE setprotoent(stayopen: int);
FUNCTION getprotoent: pprotoent;
PROCEDURE endprotoent;
PROCEDURE setservent(stayopen: int);
//FUNCTION getservent: pservent;
PROCEDURE endservent;
FUNCTION tcp_h_errno: ApiRet;
{&CDECL-}

{
 * Error return codes from gethostbyname() and gethostbyaddr()
 * (left in extern int h_errno).
 }
CONST
//  h_errno = (tcp_h_errno);   { Thread Re-entrant }

  HOST_NOT_FOUND  = 1; { Authoritative Answer Host not found }
  TRY_AGAIN       = 2; { Non-Authoritive Host not found, or SERVERFAIL }
  NO_RECOVERY     = 3; { Non recoverable errors, FORMERR, REFUSED, NOTIMP }
  NO_DATA         = 4; { Valid name, no data record of requested type }
  NO_ADDRESS      = NO_DATA;         { no address, look for MX record }

{#endif  __NETDB_32H  }

IMPLEMENTATION

{$L TCP32DLL.LIB}

{&CDECL+}
//int _System gethostbyname_r(char *, struct hostent *, struct hostent_data *);
//int _System gethostbyaddr_r(char *, int, int, struct hostent *, struct hostent_data *);
//int _System getservbyname_r(char *, char *, struct servent *, struct servent_data *);
FUNCTION gethostname;              EXTERNAL;
FUNCTION gethostbyname;            EXTERNAL;
//struct hostent * _System _gethtbyname( char * );
FUNCTION gethostbyaddr;            EXTERNAL;
//struct hostent * _System _gethtbyaddr( char *, int, int );
FUNCTION getnetbyname;             EXTERNAL;
FUNCTION getnetbyaddr;             EXTERNAL;
FUNCTION getservbyname;            EXTERNAL;
FUNCTION getservbyport;            EXTERNAL;
FUNCTION getservent;               EXTERNAL;
FUNCTION getprotobyname;           EXTERNAL;
FUNCTION getprotobynumber;         EXTERNAL;
PROCEDURE sethostent;              EXTERNAL;
FUNCTION gethostent;               EXTERNAL;
PROCEDURE endhostent;              EXTERNAL;
PROCEDURE setnetent;               EXTERNAL;
FUNCTION getnetent;                EXTERNAL;
PROCEDURE endnetent;               EXTERNAL;
PROCEDURE setprotoent;             EXTERNAL;
FUNCTION getprotoent;              EXTERNAL;
PROCEDURE endprotoent;             EXTERNAL;
PROCEDURE setservent;              EXTERNAL;
//FUNCTION getservent: pservent;
PROCEDURE endservent;              EXTERNAL;
FUNCTION tcp_h_errno;              EXTERNAL;
{&CDECL-}

END.

