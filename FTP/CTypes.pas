{ Ager's Socket Library (c) Copyright 1998-99 by Soren Ager (sag@poboxes.com) }
{                                                                             }
{ $Revision: 1.4 $    $Date: 1999/07/15 07:54:47 $    $Author: sag $ }
{                                                                             }
{ Definition af c types                                                       }
UNIT CTypes;

{&OrgName+,Use32-,Open32-}

INTERFACE

//USES Use32;

CONST
  BUFSIZ = 128; // ???

TYPE
  int    = LongInt;
  uint   = LongInt;
  long   = LongInt;
  ulong  = LongInt;
  short  = Integer;
  ushort = Word;

IMPLEMENTATION

END.

