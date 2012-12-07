{/////////////////////////////////////////////////////////////////////////
//
//  Dos Navigator Open Source 1.51.08
//  Based on Dos Navigator (C) 1991-99 RIT Research Labs
//
//  This programs is free for commercial and non-commercial use as long as
//  the following conditions are aheared to.
//
//  Copyright remains RIT Research Labs, and as such any Copyright notices
//  in the code are not to be removed. If this package is used in a
//  product, RIT Research Labs should be given attribution as the RIT Research
//  Labs of the parts of the library used. This can be in the form of a textual
//  message at program startup or in documentation (online or textual)
//  provided with the package.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the copyright
//     notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//     must display the following acknowledgement:
//     "Based on Dos Navigator by RIT Research Labs."
//
//  THIS SOFTWARE IS PROVIDED BY RIT RESEARCH LABS "AS IS" AND ANY EXPRESS
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
//  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
//  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The licence and distribution terms for any publically available
//  version or derivative of this code cannot be changed. i.e. this code
//  cannot simply be copied and put under another distribution licence
//  (including the GNU Public Licence).
//
//////////////////////////////////////////////////////////////////////////}
{$I STDEFINE.INC}
{DataCompBoy = Anton Fedorov, 2:5000/111.33@fidonet}
{JO = Jaroslaw Osadtchiy, 2:5030/1082.53@fidonet}
{AK155 = Alexey Korop, 2:461/155@fidonet}
{Cat = Aleksej Kozlov, 2:5030/1326.13@fidonet}
{Interface part from LFN.PAS}
{$AlignRec-}

{Cat
   05/12/2001 - попытка бороться с виндозной глюкофичей: запоминается текущий
   каталог не для всех дисков, а только для текущего диска, что приводит к
   различным мелким неприятностям; чтобы это пофиксить, при lChDir сохраняем
   устанавливаемый путь в массиве, а при lGetDir - извлекаем оттуда
}

unit LFNVP;

interface

uses
  VPSysLow, // см. комментарий в конце vpsysos2
  VPSysLo2, Dos, Defines, Objects2
  ;

type
  lAPIType = (lDOS, lWIN95);
  CompRec = record
             Lo, Hi: LongInt
            end;
  TNameZ = array[0..259] of Char;
  {The type for file names. (String is suitable for most purpuses)}

  PlFile = ^lFile;

  {Extended search structure to be used instead of SearchRec}
  lSearchRec = record
    SR: TOSSearchRecNew; {Basic field set}
    FullSize: TSize; {True file size}
    (*  LoCreationTime: Longint; {Time created (low-order byte)}
    HiCreationTime: Longint; {Time created (high-order byte)}
    LoLastAccessTime: Longint; {Time accessed (low-order byte)}
    HiLastAccessTime: Longint; {Time accessed (high-order byte)}
    LoLastModificationTime: Longint; {Time modified (low-order byte)}
    HiLastModificationTime: Longint; {Time modified (high-order byte)} *)
    FullName: String;
    {True file name or short name if LFNs not available}
    AbsFile: PlFile;
    {$IFDEF OS2}
    PrevName: String;
    {$ENDIF}
    {$IFDEF DPMI32}
    FileHandle: Word; {Search handle, undefined in lDOS mode}
    FindFirstMode : lAPIType;
    {$ENDIF}
    { Other fields will be added later }
    end;

  lFile = object(TObject)
    {` Абстрактный файл или даже, скорее, файловая система.
      Сейчас (03.2009) есть три реальных
      воплощения - локальный файл (TLocFile), файл на
      удалённом FTP-сервере (TFtpFile) и в DPMI-версии
      файл с Win95 API (TWin95File).
        Если требуется работа с данными, а не только с именем
      файла, это нужно делать либо через методы Read и Write, либо
      через объект TFileStreem. Использование не виртуализированных
      файловых функций, вроде BlockRead, не допускается.
        Типичной является динамическая инициализация
      статического объекта (см. lFileInit), так что область
      данных должна иметь одинаковый размер у всех
      наследников lFile. Поэтому если наследнику нужны дополнительные
      поля, их надо добавалять прямо в lFile, а не в наследника.
      Это очень некрасиво, так что по-хорошему, надо бы избавиться
      от статических lFile.
      }
    FNameZ: AsciiZ; // для всех типов
    AllMask: string[3];
    Handle: Longint;
    FMode: Word;
    FSize: TFileSize;
    FPos: TFileSize;
    MaxDataBlock: Longint;
    RestPos: TSize; // позиция, которую надо будет установить (FTP)
    AssignFileMode : lAPIType; // DPMI Win95; наверно, не нужна вообще
    constructor Init;
    procedure FindFirst(const Path: String;
      Attr: Word; var R: lSearchRec); virtual;
    procedure FindNext(var R: lSearchRec); virtual;
    procedure FindClose(var R: lSearchRec); virtual;
    procedure Assign(const FileName: FNameStr); virtual;
    procedure SetFTime(Time: Longint); virtual;
    procedure GetFTime(var Time: Longint); virtual;
    procedure SetFAttr(Attr: Longint); virtual;
    procedure GetFAttr(var Attr: Longint); virtual;
    procedure ClearReadOnly; virtual;
    procedure Rename(const NewName: string); virtual;
    procedure Open(Mode: Word); virtual;
    procedure Seek(Pos: TFileSize); virtual;
    procedure SeekEOF; virtual;
    procedure Truncate; virtual;
    procedure SetSize(NewSize: TFileSize); virtual;
    procedure Read(var Buf; Count: Longint; var Actual: Longint); virtual;
    procedure Write(const Buf; Count: Longint; var Actual: Longint); virtual;
    procedure Close; virtual;
    procedure MkDir; virtual;
    procedure RmDir; virtual;
    procedure Erase(Options: word); virtual;
    end;
    {`}

  PLocFile = ^TLocFile;
  TLocFile = object(lFile)
    procedure FindFirst(const Path: String;
      Attr: Word; var R: lSearchRec); virtual;
    procedure FindNext(var R: lSearchRec); virtual;
    procedure FindClose(var R: lSearchRec); virtual;
    procedure SetFTime(Time: Longint); virtual;
    procedure GetFTime(var Time: Longint); virtual;
    procedure SetFAttr(Attr: Longint); virtual;
    procedure GetFAttr(var Attr: Longint); virtual;
    procedure Open(Mode: Word); virtual;
    procedure Rename(const NewName: string); virtual;
    procedure Seek(Pos: TFileSize); virtual;
    procedure SeekEOF; virtual;
    procedure Truncate; virtual;
    procedure SetSize(NewSize: TFileSize); virtual;
    procedure Read(var Buf; Count: Longint; var Actual: Longint); virtual;
    procedure Write(const Buf; Count: Longint; var Actual: Longint); virtual;
    procedure Close; virtual;
    destructor Done; virtual;
    procedure MkDir; virtual;
    procedure RmDir; virtual;
    procedure Erase(Options: word); virtual;
    end;

  {$IFDEF DPMI32}
  TWin95File = object(lFile)
    procedure Rename(const NewName: string); virtual;
    {` для DPMI32 в системе с поддержкой Win95 DOS LFN API `}
    procedure SetFAttr(Attr: Longint); virtual;
    procedure GetFAttr(var Attr: Longint); virtual;
//!! методы
    procedure WIN95DirFunc(AFunction: Word);
    procedure MkDir; virtual;
    procedure RmDir; virtual;
    end;
  {$ENDIF}

type
  TFileInit = function(var F: lFile; const Name: String): Boolean;
  { Если полный путь Name подходящий, то F инициализируется и
    результат True }
var
  FileInit: array[0..15] of TFileInit;

const
  FModeCreate = $FFFF; // должно совпадать с streams.stCreate

procedure RegisterFileInit(T: TFileInit);
  {` Добавить нестандартный тип файлов в FileInit. `}
function lFileInit(var F: lFile; const Name: String): string;
  {` Инициализировать F соответствующим типом (определяется путём)
    и вернуть полный путь `}

type
  lText = record {!! AK155 Не виртуализирован - усердия не хватило.}
    {Extended text file record to be used instead of Text}
    T: Text;
    {$IFDEF DPMI32}
    FullName       : TNameZ;
    AssignTextMode : lAPIType;
    {$ENDIF}
    { Other fields will be added later }
    end;

{$IFDEF DPMI32}
var
  lAPI       : lApiType = lWin95;
{$ENDIF}

  {   Basic parameters   }
const

  {$IFDEF DPMI32}
  ltMod = 0;    {Store time modified}
  ltAcc = 1;    {Store time accessed}
  ltCre = 2;    {Store time created}

  LFNTimes: Byte = ltMod; { What time info to store in lSearchRec.SR.Time? }

  faOpen = 1;
  faTruncate = 2;
  faCreate = $10;
  faRewrite = faTruncate + faCreate;

  faGetAttr = 0;
  faSetAttr = 1;
  {$ENDIF}
  MaxPathLen: Byte = 255; { Maximum name length for the present moment }

const
  IllegalChars = '<>|:';
  { Characters invalid for short names }
  IllegalCharSet = ['<', '>', '|', ':'];
  { Characters invalid for short names }

  { File searching routines. lFindClose must be called /in all cases/ }
procedure lFindFirstAll(const Path: String; Attr: Word; var R: lSearchRec);
procedure lFindFirst(const Path: String; Attr: Word; var R: lSearchRec);
procedure lFindNext(var R: lSearchRec);
procedure lFindClose(var R: lSearchRec);

{$IFDEF DualName}
function lfGetShortFileName(const Name: String): String;
{$ENDIF}
{$IFDEF DPMI32}
function SysFileCreate(FileName: PChar; Mode,Attr: Longint; var Handle: Longint): Longint;
function SysFileOpen(FileName: PChar; Mode: Longint; var Handle: Longint): Longint;
function lfGetLongFileName(const Name: String): String;
{$ENDIF}

{ Name correction routine }
procedure lTrueName(const Name: String; var S: String);

function GetShareEnd(const S: String): Integer;
{` AK155 22-11-2003 Найти конец шары в пути. 0 - если это не UNC-путь `}

function IsFtpAddr(const Path: String): Boolean;

function GetRootStart(const Path: String): Integer;
{` Найти начало корня; например, для C:\DIR результат 3,
для \\Server\Share\Dir результат 15. Для путей без
явного корня результат 1. `}

{ Basic file operation routines. To use IO functions from standard units,
              specify lFile.F or lText.T }

procedure lAssignFile(var F: lFile; const Name: String);
  {` F инициализируется нужным типом в зависимости от
     корня расширенного пути и от ОС. `}

procedure lAssignDevice(var F: lFile; const Name: String);
  {` F инициализируется TLocFile без расширения пути `}

procedure lResetFile(var F: lFile);
procedure lResetFileReadOnly(var F: lFile);
procedure lReWriteFile(var F: lFile);
procedure lAssignText(var T: lText; const Name: String);
procedure lResetText(var F: lText);
  inline;
  begin
  Reset(F.T)
  end;
procedure lResetTextReadOnly(var F: lText);
procedure lRewriteText(var F: lText);
procedure lAppendText(var T: lText);
  inline;
  begin
  Append(T.T);
  end;

const
  efoForce = 1;

procedure lEraseText(var T: lText);
{$IFNDEF DPMI32}
  inline;
  begin
  Erase(T.T);
  end;
{$ENDIF}
procedure lRenameText(var T: lText; const NewName: String);
procedure lChangeFileName(Name, NewName: String);
function lFileNameOf(var lF: lFile): String;
function lTextNameOf(var lT: lText): String;

{ File attributes manipulation }
procedure lGetTAttr(var T: lText; var Attr: Word);
procedure lSetTAttr(var T: lText; Attr: Word);

{ Directory manipulation }
procedure lMkDir(const Path: String);
procedure lRmDir(const Path: String);
procedure lChDir(Path: String);
  {` Если указанный каталог существует, то перейти на него, то есть
  присвоить его ActiveDir. Код ошибки реально формируется в FindFirst,
  то есть находится в DosError. Для совместимости со стандартной
  ChDir он дублируется также в InOutRes. `}
procedure lGetDir(D: Byte; var Path: String);

{ Name expansion and splitting }
function lFExpand(Path: String): String;
  {` расширить Path относительно ActiveDir. Если в Path были
  '/', то в результате им будут соответствовать '\'.
  Всякие . и .. коректно удаляются, скажем, вместо C:\TEMP\$$$\..
  будет C:\TEMP. '\' на конце - только в корне диска.
  Также удаляюся кавычки из имени.`}
procedure lFSplit(const Path: String; var Dir, Name, ext: String);

{$IFDEF DualName}
const
  NoShortName: String[12] = #22#22#22#22#22#22#22#22'.'#22#22#22;
  {JO, AK155: зачем нужны эти #22:
  В виндах функции API FindFileFirst и FindFileNext отдают два имени
файла: основное и альтернативное (короткое).
  Под НТ возможна ненормальная (с моей точки зрения,
по крайней мере) ситуация, когда для файла с длинным (не укладывающимся
в 8.3) имением файла альтернатвное имя недоступно. Так бывает, если
файловая система в принципе не поддерживает двухименности (HPFS), или
если формирование коротких имен отключено (на NTFS и FAT32).
  Тогда в режиме показа коротких имён мы будем иметь для таких файлов
обрезанные как попало имена в панели, не соответствующие
действительности. Для этого JO и придумал этот условный заменитель
недоступного короткого имени, так как символ #22 заведомо не
может быть в принципе в реальном имени файла. Так показывать в
режиме коротких имён файлы, для которых доступно только длинное имя, -
честнее, чем с обрезанным именем, под которым файл недоступен.
}
  {$ENDIF}

{Cat: Windows запоминает текущий каталог только для текущего диска;
запоминание остальных текущих каталогов приходится брать на себя}
var
  CurrentPaths: array[1..1+Byte('Z')-Byte('A')] of PathStr;
  ActiveDir: String; // всегда с '\' в конце
  CurrentRoot: String; // без '\' в конце; может быть шара
  StartDir: String;
  LastFindDir: String; // каталог последнего lFindFirst

implementation

uses
  {$IFDEF WIN32}Windows, {$ENDIF}
  Strings, Commands {Cat}
  , Advance1, Advance2, VPUtils
  {$IFDEF DPMI32} ,Startup ,Dpmi32 ,Dpmi32df {$ENDIF}
  , fnotify
  ;

(*
 Offset  Size    Description
  00h    DWORD   file attributes
                 bits 0-6 standard DOS attributes
                 bit 8: temporary file
  04h    QWORD   file creation time
                 (number of 100ns intervals since 1/1/1601)
  0Ch    QWORD   last access time
  14h    QWORD   last modification time
  1Ch    DWORD   file size (high 32 bits)
  20h    DWORD   file size (low 32 bits)
  24h  8 BYTEs   reserved
  2Ch 260 BYTEs  ASCIZ full filename
 130h 14 BYTEs   ASCIZ short filename (for backward compatibility)
*)

function SetDosError(ErrCode: Integer): Integer;
  begin
  DosError := ErrCode;
  SetDosError := ErrCode;
  end;

{AK155}
{$IFDEF DualName}
function NotShortName(const S: String): Boolean;
  var
    i, l: Integer;
    iPoint: Integer;
  begin
  NotShortName := True;
  if S[1] = '.' then
    Exit;
  l := Length(S);
  if l > 12 then
    Exit;
  iPoint := 0;
  for i := 1 to l do
    begin
    if S[i] = '.' then
      begin
      if  (iPoint <> 0) or (i > 9) then
        Exit;
      iPoint := i;
      end
    else if S[i] in IllegalCharSet then
      Exit; {DataCompBoy}
    end;
  if  (iPoint = 0) and (l > 8) then
    Exit;
  if  (iPoint <> 0) and (l-iPoint > 3) then
    Exit;
  NotShortName := False;
  end { NotShortName };
{$ENDIF}

procedure CorrectSearchRec(var R: lSearchRec);
  begin
  R.FullName := R.SR.Name;
  {$IFDEF Win32}
  if  (R.SR.Name <> '.') and (R.SR.Name <> '..') then
    begin
    if  (R.SR.ShortName <> '') then
      R.SR.Name := R.SR.ShortName
    else if NotShortName(R.FullName) then
      R.SR.Name := NoShortName;
    R.SR.Attr := R.SR.FindData.dwFileAttributes; {AK155}
    end;
  {$ENDIF}
  {$IFDEF DPMI32}
  {JO: CorrectSearchRec вызывается только в отсутствие Win32 LFN API}
  R.SR.CreationTime := 0;
  R.SR.LastAccessTime := 0;
  {/JO}
  {$ENDIF}
  (*R.LoCreationTime:= R.SR.Time;
  R.HiCreationTime:= 0;
  R.LoLastAccessTime:= R.SR.Time;
  R.HiLastAccessTime:= 0;
  R.LoLastModificationTime:= R.SR.Time;
  R.HiLastModificationTime:= 0; *)
  R.FullSize := R.SR.Size;
  end;

{$IFDEF DPMI32}{lfn functions for dpmi32}
type
  lFindDataRec = record
    LoAttr: SmallWord;
    HiAttr: SmallWord;
    LoCreationTime: Longint;
    HiCreationTime: Longint;
    LoLastAccessTime: Longint;
    HiLastAccessTime: Longint;
    LoLastModificationTime: Longint;
    HiLastModificationTime: Longint;
    HiSize: Longint;
    LoSize: Longint;
    Reserved: Array[0..7] of Byte;
    FullName: TNameZ;
    ShortName: Array[0..13] of Char;
  end;

Const
      DriveBuffer: array[1..4] of char = ('?',':','\',#0);

procedure CheckColonAndSlash(const Name: String; var S: String);
var
  ColonPos: Integer;
begin
  ColonPos := Pos(':', S);
  if (ColonPos > 2) and (Name[2] = ':') then
  begin
    Delete(S, 1, ColonPos - 1);
    S := Name[1] + S;
  end;

  if Name[Length(Name)] <> '\' then
    while S[Length(S)] = '\' do Dec(S[0])
  else if (Name[Length(Name)] = '\') and
    (S[Length(S)] <> '\') and (Length(S) < 255) then
  begin
    Inc(S[0]);
    S[Length(S)] := '\';
  end;
end;

procedure FindDataToSearchRec(var FindData: lFindDataRec; var R: lSearchRec);
begin
  R.SR.Attr := FindData.LoAttr;
{ if LFNTimes = ltCre then R.SR.Time := FindData.LoCreationTime
   else if LFNTimes = ltAcc then R.SR.Time := FindData.LoLastAccessTime
    else} R.SR.Time := FindData.LoLastModificationTime;
{JO}
  R.SR.CreationTime := FindData.LoCreationTime;
  R.SR.LastAccessTime := FindData.LoLastAccessTime;
{/JO}
  R.SR.Name := StrPas(FindData.ShortName);
  R.FullName := StrPas(FindData.FullName);
  if R.SR.Name = '' then R.SR.Name := R.FullName;
  if R.FullName = '' then R.FullName := R.SR.Name;
  R.FullSize:= FindData.LoSize;
  if FindData.HiSize=0 then R.SR.Size := FindData.LoSize
  else
   begin
    R.SR.Size := MaxLongInt;
    CompRec(R.FullSize).Hi:=FindData.HiSize;
   end;
end;

procedure lWIN95GetFileNameFunc(const Name: String; var S: String; AFunction: Byte);
var
  NameZ, GetNameZ: TNameZ;
  regs: real_mode_call_structure_typ;
begin
  Path(NameZ, Name);
  init_register(regs);
  with regs do
  begin
    ax_ := $7160;
    cl_ := AFunction;
    ch_ := $80;
    ds_ := segdossyslow16;
    si_ := 0;
    es_ := segdossyslow16;
    di_ := SizeOf(TNameZ);
    Move(NameZ,Mem[segdossyslow32],SizeOf(TNameZ));
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0 then S := Name
    else
    begin
      Move(Mem[segdossyslow32+SizeOf(TNameZ)],GetNameZ,SizeOf(TNameZ));
      S := StrPas(GetNameZ);
      CheckColonAndSlash(Name, S);
    end;
  end;
end;

procedure WIN95TrueName(const Name: String; var S: String);
var
  NameZ, GetNameZ: TNameZ;
  regs: real_mode_call_structure_typ;
begin
  StrPCopy(NameZ, Name);
  init_register(regs);
  with Regs do
  begin
    ax_ := $7160;
    cl_ := 0;
    ch_ := $00;
    ds_ := segdossyslow16;
    si_ := 0;
    es_ := segdossyslow16;
    di_ := SizeOf(TNameZ);
    Move(NameZ,Mem[segdossyslow32],SizeOf(TNameZ));
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0 then S := Name
    else
    begin
      Move(Mem[segdossyslow32+SizeOf(TNameZ)],GetNameZ,SizeOf(TNameZ));
      S := StrPas(GetNameZ);
      CheckColonAndSlash(Name, S);
    end;
  end;
end;

function SysFileCreate(FileName: PChar; Mode,Attr: Longint; var Handle: Longint): Longint;
var
  regs     : real_mode_call_structure_typ;
  FullName : TNameZ;
begin
 FillChar(FullName, SizeOf(FullName), #0);
 StrCopy(FullName, FileName);
 init_register(regs);
 with regs do
  begin
   if lAPI=lDOS then
    begin
     ah_ := $3C;
     al_ := Mode;
     bx_ := 0;
     cx_ := Attr;
     ds_ := segdossyslow16;
    end else
    begin
     ax_ := $716C;
     bx_ := Mode;
     cx_ := Attr;
     dx_ := $12;
     ds_ := segdossyslow16;
     si_ := 0;
     di_ := 0;
    end;
   Move(FullName, Mem[segdossyslow32], SizeOf(FullName));
   flags_:=fCarry;
   intr_realmode(regs, $21);
   if flags_ and fCarry <> 0
     then begin
           Handle := 0;
           SysFileCreate := ax_;
          end
     else begin
           SysFileCreate := 0;
           Handle := ax_;
          end;
  end;
end;

function SysFileOpen(FileName: PChar; Mode: Longint; var Handle: Longint): Longint;
var
  regs     : real_mode_call_structure_typ;
  FullName : TNameZ;
begin
 FillChar(FullName, SizeOf(FullName), #0);
 StrCopy(FullName, FileName);
 init_register(regs);
 with regs do
  begin
   If lapi=ldos then
    begin
     ah_ := $3D;
     al_ := Mode;
     bx_ := 0;
     cx_ := 0;
     ds_ := segdossyslow16;
    end else
    begin
     ax_ := $716C;
     bx_ := Mode;
     cx_ := 0;
     dx_ := 1;
     ds_ := segdossyslow16;
     si_ := 0;
     di_ := 0;
    end;
   Move(FullName, Mem[segdossyslow32], SizeOf(FullName));
   flags_ := fCarry;
   intr_realmode(regs, $21);
   if flags_ and fCarry <> 0
     then begin
           Handle := 0;
           SysFileOpen := ax_;
          end
     else begin
           SysFileOpen := 0;
           Handle := ax_;
          end;
  end;
end;

procedure lWIN95ChDir(const Path: string);
var
  regs: real_mode_call_structure_typ;
  C: Char;
  NameZ: TNameZ;
begin
  StrPCopy(NameZ, Path);
  Move(NameZ,Mem[segdossyslow32],SizeOf(TNameZ));
  init_register(regs);
  with regs do
  begin
    C := Upcase(NameZ[0]);
    if (C in ['A'..'Z']) and (NameZ[1] = ':') then
    begin
      ah_ := $0E;
      dl_ := Byte(C) - $41;
      intr_realmode(regs,$21);
    end;

    ax_ := $713B;
    ds_ := segdossyslow16;
    dx_ := 0;
    flags_:=fCarry;
    intr_realmode(regs, $21);

    if (flags_ and fCarry <> 0)
    then InOutRes := ax_
    else InOutRes := 0;
  end;
end;

procedure lWIN95GetDir(D: Byte; var Path: string);
var
  regs: real_mode_call_structure_typ;
  NameZ: TNameZ;
begin
  init_register(regs);
  with regs do
  begin
    ax_ := $7147;
    dl_ := D;
    ds_ := segdossyslow16;
    si_ := 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0 then NameZ[0] := #0
    else
     Move(Mem[segdossyslow32],NameZ,SizeOf(TNameZ));
    Path := Char(D + $40) + ':\' + StrPas(NameZ);
  end;
end;

procedure lWIN95EraseFile(var F: lFile);
var
  regs: real_mode_call_structure_typ;
begin
  Move(F.FullName,Mem[segdossyslow32],SizeOf(F.FullName));
  init_register(regs);
  with regs do
  begin
    ax_ := $7141;
    ds_ := segdossyslow16;
    dx_ := 0;
    si_ := 0;
    flags_:=fCarry;
    intr_realmode(regs, $21);
    if flags_ and fCarry <> 0
    then InOutRes := ax_
    else InOutRes := 0;
  end;
end;

procedure lWIN95EraseText(var T: lText);
var
  regs: real_mode_call_structure_typ;
begin
  Move(T.FullName,Mem[segdossyslow32],SizeOf(T.FullName));
  init_register(regs);
  with regs do
  begin
    ax_ := $7141;
    ds_ := segdossyslow16;
    dx_ := 0;
    si_ := 0;
    flags_:=fCarry;
    intr_realmode(regs, $21);
    if flags_ and fCarry <> 0
    then InOutRes := ax_
    else InOutRes := 0;
  end;
end;

procedure lWIN95RenameText(var T: lText; const NewName: shortstring);
var
  NameZ: TNameZ;
  regs: real_mode_call_structure_typ;
begin
  StrPCopy(NameZ, NewName);
  Move(T.FullName,Mem[segdossyslow32],SizeOf(T.FullName));
  Move(NameZ,Mem[segdossyslow32+SizeOf(T.FullName)],SizeOf(NameZ));
  init_register(regs);
  with Regs do
  begin
    ax_ := $7156;
    ds_ := segdossyslow16;
    dx_ := 0;
    es_ := segdossyslow16;
    di_ := SizeOf(NameZ);
    flags_:=fCarry;
    intr_realmode(regs, $21);
    if flags_ and fCarry <> 0
    then InOutRes := ax_
    else InOutRes := 0;
  end;
end;

procedure lWIN95FileAttrFunc(var F: lFile; var Attr: Word; Action: Byte);
  var
    regs: real_mode_call_structure_typ;
  begin
  Move(F.FNameZ,Mem[segdossyslow32],SizeOf(F.FNameZ));
  init_register(regs);
  with regs do
    begin
    ax_ := $7143;
    bl_ := Action;
    if Action = faSetAttr then cx_ := Attr;
    ds_ := segdossyslow16;
    dx_ := 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0
      then DosError := ax_
    else
      begin
      if Action = faGetAttr then Attr := cx_;
      DosError := 0;
      end;
    end;
  end;

procedure lWIN95TextAttrFunc(var T: lText; var Attr: Word; Action: Byte);
var
  regs: real_mode_call_structure_typ;
begin
  Move(T.FullName,Mem[segdossyslow32],SizeOf(T.FullName));
  init_register(regs);
  with Regs do
  begin
    ax_ := $7143;
    bl_ := Action;
    if Action = faSetAttr then cx_ := Attr;
    ds_ := segdossyslow16;
    dx_ := 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0
    then DosError := ax_
    else
    begin
      if Action = faGetAttr then Attr := cx_;
      DosError := 0;
    end;
  end;
end;

procedure lEraseFile(const FName: string; Options: word {efo...});
  begin
  F.DelFile(FName; Options);
  end;

procedure lEraseText(var T: lText);
  begin
  if T.AssignTextMode = lWIN95 then lWIN95EraseText(T) else
  Erase(T.T);
  end;

{$ENDIF}{*** lfn functions for dpmi32 ***}

function lFileInit(var F: lFile; const Name: String): string;
  var
    i: Integer;
  begin
  Result := lFExpand(Name);
    { текущий каталог панели - это не текущий каталог ОС, поэтому
     надо развернуть имя до полного пути.}
  for i := 0 to High(FileInit) do
    begin
    if @FileInit[i] = nil then
      Break;
    if FileInit[i](F, Name) then
      Exit;
    end;
  TLocFile(F).Init;
  end;

procedure lFindFirstAll(const Path: String; Attr: Word; var R: lSearchRec);
  var
    FullPath: string;
  begin
  New(R.AbsFile);
  FullPath := lFileInit(R.AbsFile^, Path);
  MakeSlash(FullPath);
  R.AbsFile^.FindFirst(FullPath + R.AbsFile^.AllMask, Attr, R);
  end;

procedure lFindFirst(const Path: String; Attr: Word; var R: lSearchRec);
  var
    FullPath: string;
  begin
  New(R.AbsFile);
  FullPath := lFileInit(R.AbsFile^, Path);
  R.AbsFile^.FindFirst(FullPath, Attr, R);
  end;

procedure lFindNext(var R: lSearchRec);
  begin
  R.AbsFile^.FindNext(R);
  end;

procedure lFindClose(var R: lSearchRec);
  var
    DEr: LongInt;
  begin
  if R.AbsFile <> nil then
    begin
    DEr := DosError; {JO}
    R.AbsFile^.FindClose(R);
    DosError := DEr; {JO}
    FreeObject(R.AbsFile);
    end;
  end;

{$IFDEF WIN32}
function lfGetShortFileName(const Name: String): String;
  var
    NZ, NZ2: TNameZ;
    l: LongInt;
  begin
  if  (Name = '.') or (Name = '..') then
    begin
    lfGetShortFileName := Name;
    Exit;
    end;
  StrPCopy(NZ2, Name);
  if SysPlatformId = 1 then
    OemToChar(@NZ2, @NZ2);
  {AK155 18.07.2003 Тут и ниже приходится испралять баг Win9x,
      в которых GetShortPathName работает в кодировке ANSI несмотря на
      SetFileApisToOEM
    }
  l := GetShortPathName(@NZ2, @NZ, SizeOf(NZ));
  if l = 0 then
    lfGetShortFileName := NoShortName
  else
    begin
    if SysPlatformId = 1 then
      CharToOEM(@NZ, @NZ);
    lfGetShortFileName := StrPas(NZ);
    end;
  end { lfGetShortFileName };
{$ENDIF}
{$IFDEF DPMI32}
function lfGetShortFileName(const Name: String): String;
  begin
  if lApi = lDOS
  then Result := Name
  else lWIN95GetFileNameFunc(Name, Result, 1);
  end;

function lfGetLongFileName(const Name: String): String;
  begin
  if lApi = lDOS
  then Result := Name
  else lWIN95GetFileNameFunc(Name, Result, 2);
  end;
{$ENDIF}

procedure lTrueName(const Name: String; var S: String);
  begin
  {$IFDEF DPMI32}
  if lApi = lWin95 then
    WIN95TrueName(Name, S)
  else
  {$ENDIF}
  S := Name;
  end;

{AK155 22-11-2003 Найти конец шары в пути. 0 - если это не UNC-путь
}
function GetShareEnd(const S: String): Integer;
  var
    SlashFound: Boolean;
  begin
  Result := 0;
  if Copy(S, 1, 2) <> '\\' then
    Exit;
  { ищем '\' после '\\', и далее до конца или до второго '\' }
  Result := 3;
  SlashFound := False;
  while Result < Length(S) do
    begin
    if S[Result+1] = '\' then
      begin
      if SlashFound then
        Exit; // Успех. Сейчас Copy(S, 1, i) - это '\\server\share'
      SlashFound := True;
      end;
    Inc(Result);
    end;
  if not SlashFound then
    Result := 0;
  { Неправильный это путь: '\\' в начале есть,
      а '\' потом - нет. Надо бы как-то признак ошибки выставить,
      но непонятно как и для кого. }
  end { GetShareEnd };
{/AK155 22-11-2003}

function IsFtpAddr(const Path: String): Boolean;
  begin
  Result := Upstrg(Copy(Path, 1, 6)) = 'FTP:\\';
  end;

function GetRootStart(const Path: String): Integer;
  begin
  if IsFtpAddr(Path) then
    begin
    Result := PosChar('\', Copy(Path, 7, 255));
    if Result = 0 then
      Result := Length(Path)+1
    else
      Result := Result + 6;
    end
  else
    begin
    Result := GetShareEnd(Path)+1;
    if (Result = 1) and (Path[2] = ':') then
      Result := 3;
    end;
  end;

{AK155 22-11-2003 Доработано с учётом UNC-путей }
procedure lFSplit(const Path: String; var Dir, Name, ext: String);
  var
    DriveEnd: Integer;
    DotPos, SlashPos, B: Byte;
    D: String;
    N: String;
    E: String;
  begin
  Dir := '';
  Name := '';
  ext := '';
  DotPos := 0;
  SlashPos := 0;
  DriveEnd := GetRootStart(Path)-1;

  for B := Length(Path) downto DriveEnd+1 do
    begin
    if  (Path[B] = '.') and (DotPos = 0) then
      begin
      DotPos := B; {JO: имена могут состоять только из расширения}
      if SlashPos <> 0 then
        Break;
      end;
    if  (Path[B] = '\') and (SlashPos = 0) then
      begin
      SlashPos := B;
      if DotPos <> 0 then
        Break;
      end;
    end;

  if DotPos+SlashPos = 0 then
    if DriveEnd <> 0 then
      Dir := Path
    else
      Name := Path
  else
    begin
    if DotPos > SlashPos then
      ext := Copy(Path, DotPos, MaxStringLength)
    else
      DotPos := 255;

    if SlashPos <> 0 then
      Dir := Copy(Path, 1, SlashPos);

    Name := Copy(Path, SlashPos+1, DotPos-SlashPos-1);
    end;
  end { lFSplit };

function lFileNameOf(var lF: lFile): String;
  begin
  lFileNameOf := StrPas(lF.FNameZ);
  end;

function lTextNameOf(var lT: lText): String;
  begin
  lTextNameOf := StrPas(TextRec(lT.T).Name);
  end;

procedure lAssignDevice(var F: lFile; const Name: String);
  begin
  with TLocFile(F) do
    begin
    Init;
    StrPCopy(FNameZ , Name);
    end;
  end;

procedure lResetFile(var F: lFile);
  begin
  F.Open(FileMode);
  end;

procedure lResetFileReadOnly(var F: lFile);
  begin
  F.Open($40);
  end;

procedure lReWriteFile(var F: lFile);
  begin
  F.Open(FModeCreate);
  end;

procedure lResetTextReadOnly(var F: lText);
  var
    SaveMode: Byte;
  begin
  SaveMode := FileMode;
  FileMode := 64;
  lResetText(F);
  FileMode := SaveMode;
  end;

procedure lRewriteText(var F: lText);
  var
    OldMode: Byte;
  begin
  OldMode := FileMode;
  FileMode := FileMode and $FC or 2;
  Rewrite(F.T);
  FileMode := OldMode;
  end;

procedure lAssignFile(var F: lFile; const Name: String);
  var
    FName: string;
  begin
  FName := lFileInit(F, Name);
  F.Assign(FName);
  end;

procedure lAssignText(var T: lText; const Name: String);
  begin
  Assign(T.T, lFExpand(Name));
    { см. комментарий к lAssignFile }
  end;

procedure lRenameText(var T: lText; const NewName: String);
  begin
{$IFDEF DPMI32}
  if T.AssignTextMode = lWIN95 then lWIN95RenameText(T, NewName) else
{$ENDIF}
  Rename(T.T, NewName);
  end;

procedure lChangeFileName(Name, NewName: String);
  var
    I: Integer;
    F: lFile;
  begin
  lAssignFile(F, Name);
//удалим кавычки из длинного имени
  for I := Length(NewName) downto 1 do
    if NewName[I] = #34{"} then
      Delete(NewName, I, 1);
  F.Rename(NewName);
  end;

procedure lGetTAttr(var T: lText; var Attr: Word);
  begin
{$IFDEF DPMI32}
  if T.AssignTextMode = lWIN95 then lWIN95TextAttrFunc(T, Attr, faGetAttr) else
{$ENDIF}
  Dos.GetFAttr(T.T, Attr);
  end;
procedure lSetTAttr(var T: lText; Attr: Word);
  begin
{$IFDEF DPMI32}
  if T.AssignTextMode = lWIN95 then lWIN95TextAttrFunc(T, Attr, faSetAttr) else
{$ENDIF}
  Dos.SetFAttr(T.T, Attr);
  end;

procedure lMkDir(const Path: String);
  var
    f: lFile;
  begin
  lAssignFile(f, Path);
  f.MkDir;
  end;

{AK155: В DN/2, если каталог имеет атрибут ReadOnly, то на FAT или HPFS
он удаляется нормально, а на FAT32 - не удаляется. Так что на всякий
случай надо ReadOnly снять. }
procedure lRmDir(const Path: String);
  var
    f: lFile;
  begin
  InOutRes := 0;
  DosError := 0;
  lAssignFile(f, Path);
  f.ClearReadOnly;
  if DosError = 0 then
    f.RmDir;
  end;
{/AK155}

function lFExpand(Path: String): String;
  var
    D: Byte;
    i, j: Integer;
    RootEnd: Integer;
  begin
  for i := Length(Path) downto 1 do
    if Path[i] = #34{"} then
      Delete(Path, i, 1)
    else
    if Path[i] = '/' then
      Path[i] := '\';
  RootEnd := 0;
  if Path = '' then
    Result := ActiveDir
  else if (Copy(Path, 2, 2) = ':\') or (Copy(Path, 1, 2) = '\\') then
    Result := Path // полный путь
  else if Path[1] = '\' then
    Result := CurrentRoot + Path // от корня текущего диска/шары
  else if  (Length(Path) >= 2) and (Path[2] = ':') then
    begin // относительный путь указанного диска
    D := Byte(UpCase(Path[1]))-Byte('A')+1;
    Result := CurrentPaths[D] + Copy(Path, 3, 255);
    end
  else if IsFtpAddr(Path) then
    begin
    Result := Path; // полный путь
    RootEnd := 6;
    end
  else
    Result := ActiveDir + Path; // относительный путь
  MakeNoSlash(Result);

  { Удаление '\Dir\..' }
  if RootEnd = 0 then
    RootEnd := GetShareEnd(Result);
  if RootEnd = 0 then
    RootEnd := 2;
  while True do
    begin
    j := Pos('\..', Result);
    if (j = 0) or ((j <> Length(Result)-2) and (Result[j+3] <> '\')) then
      Break;
    i := j-1;
    while (i > RootEnd) and (Result[i] <> '\') do
      Dec(i);
    if i <> RootEnd then
      Delete(Result, i+1, j-i+3)
    else // странный путь вроде C:\.., удаляем ..\
      begin
      Delete(Result, j+1, 2);
      if Result[j] = '\' then
        Delete(Result, j, 1);
      end;
    end;
  Replace('.\', '', Result);
  if Result[Length(Result)] = '.' then
    SetLength(Result, Length(Result)-1);
  end;

procedure lChDir(Path: String);
  var
    i: Longint;
  begin
  Path := lFExpand(Path);
  InOutRes := 0;
  if PathExist(Path) then
    begin
    ActiveDir := LastFindDir;
    MakeSlash(ActiveDir);
    i := GetRootStart(ActiveDir)-1;
    CurrentRoot := Copy(ActiveDir, 1, i);
    if  (InOutRes = 0) and (Length(Path) > 2) and (Path[2] = ':') then
      CurrentPaths[Byte(UpCase(Path[1]))-Byte('A')+1] := ActiveDir;
    end
  else
    InOutRes := DosError;
  end;

procedure lGetDir(D: Byte; var Path: String);
  label
    DelSlash;
  begin
  if D = 0 then
    begin
    Path := ActiveDir;
    if (Path[1] = '\') or IsFtpAddr(Path) then
      goto DelSlash;
    D := Byte(UpCase(Path[1]))-Byte('A')+1;
    end;
  if CurrentPaths[D] = '' then
    Path := Char(D+Byte('A')-1)+':\' {GetDir(D, Path)}
  else
    Path := CurrentPaths[D];
DelSlash:
  MakeNoSlash(Path);
  end;
{/Cat}

constructor lFile.Init;
  begin
  inherited Init;
  Handle := -1;
  AllMask := AllFilesMask;
  MaxDataBlock := MaxLongint;
  end;

procedure lFile.FindFirst(const Path: String;
  Attr: Word; var R: lSearchRec);
    begin
    end;

procedure lFile.FindNext(var R: lSearchRec);
    begin
    end;

procedure lFile.FindClose(var R: lSearchRec);
    begin
    end;

procedure lFile.Assign(const FileName: FNameStr);
  begin
  StrPCopy(FNameZ, FileName);
  end;

procedure lFile.SetFTime(Time: Longint);
  begin
  end;

procedure lFile.GetFTime(var Time: Longint);
  begin
  end;

procedure lFile.SetFAttr(Attr: Longint);
  begin
  end;

procedure lFile.GetFAttr(var Attr: Longint);
  begin
  end;

procedure lFile.Open(Mode: Word);
  begin
  end;

procedure lFile.Rename(const NewName: string);
  begin
  end;

procedure lFile.SeekEOF;
  begin
  end;

procedure lFile.Seek(Pos: TFileSize);
  begin
  end;

procedure lFile.Truncate;
  begin
  end;

procedure lFile.SetSize(NewSize: TFileSize);
  begin
  end;

procedure lFile.Read(var Buf; Count: Longint; var Actual: Longint);
  begin
  end;

procedure lFile.Write(const Buf; Count: Longint; var Actual: Longint);
  begin
  end;

procedure lFile.Close;
  begin
  end;

procedure lFile.MkDir;
  begin
  end;

procedure lFile.ClearReadOnly;
  var
    Attr: Word;
  begin
  GetFAttr(Attr);
  if Attr and ReadOnly <> 0 then
    SetFAttr(Attr and not ReadOnly);
  if DosError <> 0 then
    begin
    InOutRes := DosError;
    Exit;
    end;
  end;

procedure lFile.RmDir;
  begin
  end;

procedure lFile.Erase(Options: word);
  begin
  end;

//========= TLocFile
procedure TLocFile.FindFirst(const Path: String;
  Attr: Word; var R: lSearchRec);
  var
    PathBuf: array[0..SizeOf(PathStr)-1] of Char;
  begin
  StrPCopy(PathBuf, Path);
  R.FullName := '';
{$IFDEF DPMI32}
  R.FindFirstMode := lDOS;
{$ENDIF}
  SetDosError(SysFindFirstNew(PathBuf, Attr, R.SR, False));
  CorrectSearchRec(R);
{$IFDEF OS2}
  R.PrevName := R.FullName;
{$ENDIF}
  if Path[Length(Path)] = '*' then
    LastFindDir := GetPath(Path)
  else
    LastFindDir := Path;
  end;

procedure TLocFile.FindNext(var R: lSearchRec);
  begin
  SetDosError(SysFindNextNew(R.SR, False));
  CorrectSearchRec(R);
  {JO: ошибка 49 в оси зарезервирована; мы её будем использовать для}
  {    отлова дупов на HPFS}
  {$IFDEF OS2}
  if  (DosError = 0) and (R.FullName <> '') and (R.FullName <> '.')
       and (R.FullName <> '..')
  then
    begin
    if R.PrevName = R.FullName then
      DosError := 49;
    R.PrevName := R.FullName;
    end;
  {$ENDIF}
  end;

procedure TLocFile.FindClose(var R: lSearchRec);
  begin
  SysFindCloseNew(R.SR);
  end;

procedure TLocFile.SetFTime(Time: Longint);
  begin
  DosError := SysSetFileTime(Handle, Time);
  end;

procedure TLocFile.GetFTime(var Time: Longint);
  begin
  DosError := SysGetFileTime(Handle, Time);
  end;

procedure TLocFile.SetFAttr(Attr: Longint);
  begin
  DosError := SysSetFileAttr(FNameZ, Attr);
  end;

procedure TLocFile.GetFAttr(var Attr: Longint);
  begin
  DosError := SysGetFileAttr(FNameZ, Attr);
  end;

procedure TLocFile.Rename(const NewName: string);
  var
    NewNameZ: TNameZ;
  begin
  StrpCopy(NewNameZ, NewName);
  InOutRes := SysFileMove(FNameZ, NewNameZ);
  end;

procedure TLocFile.Open(Mode: Word);
  begin
  if Mode = FModeCreate then
    begin
    FMode := $22;
    end
  else
    FMode := Mode;
  Handle := -1;
  InOutRes := SysFileOpen(FNameZ, FMode, Handle);
  if ((InOutRes = 110 {not exists}) or (InOutRes = 2 {not found})) and
     (Mode = FModeCreate)
  then
    InOutRes := SysFileCreate(FNameZ, FMode, Archive, Handle);
  if InOutRes = 0 then
    SeekEOF;
  if InOutRes = 0 then
    Seek(0);
  end;

procedure TLocFile.SeekEOF;
  begin
  InOutRes := SysFileSeek(Handle, 0, 2, FSize);
  FPos := FSize;
  end;

procedure TLocFile.Seek(Pos: TFileSize);
  begin
  if Pos < 0 then
    Pos := 0;
  InOutRes := SysFileSeek(Handle, Pos, 0, FPos);
  end { TLocFile.Seek };

procedure TLocFile.Truncate;
  begin
  SetSize(FPos);
  end;

procedure TLocFile.SetSize(NewSize: TFileSize);
  begin
  if InOutRes = 0 then
    begin
    InOutRes := SysFileSetSize(Handle, NewSize);
    if InOutRes = 0 then
       FSize := NewSize;
    end;
  end;

procedure TLocFile.Read(var Buf; Count: Longint; var Actual: Longint);
  var
    Success: Integer;
    W, BytesMoved: Longint;
    P: PByteArray;
  begin
  P := @Buf;
  Actual := 0;
  if Handle = -1 then
    InOutRes := 103
  else
    begin
    while (Count > 0) do
      begin
      W := Count;
      InOutRes := SysFileRead(Handle, P^, W, BytesMoved);
      if InOutRes = 0 then
        begin
        FPos := FPos + BytesMoved;
        if (BytesMoved <> W) and (FPos < FSize) then
          FSize := FPos;
        Actual := Actual + BytesMoved;
        P := Pointer(LongInt(P)+BytesMoved);
        Dec(Count, BytesMoved);
        end;
      if  (InOutRes <> 0) or (BytesMoved <> W) then
        Break;
      end;
    end;
  if Count <> 0 then
    FillChar(P^, Count, #0); { Error clear buffer }
  end { TLocFile.Read };

procedure TLocFile.Write(const Buf; Count: Longint; var Actual: Longint);
  var
    Success: Integer;
    W, BytesMoved: Longint;
    P: PByteArray;
  begin
  Actual := 0;
  if Handle = -1 then
    InOutRes := 103
  else
    begin
    if (FMode and $000F) = open_access_ReadOnly then
      InOutRes := 103
    else
      begin
      P := @Buf;
      Actual := 0;
      while (Count > 0) and (InOutRes = 0) do
        begin
        W := Count;
        InOutRes := SysFileWrite(Handle, P^, W, BytesMoved);
        if InOutRes = 0 then
          begin
          FPos := FPos + BytesMoved;
          Actual := Actual + BytesMoved;
          P := Pointer(LongInt(P)+BytesMoved);
          Dec(Count, BytesMoved);
          if  (FPos > FSize) then
            FSize := FPos;
          end;
        end;
      end;
    end;
  end { TLocFile.Write };

procedure TLocFile.Close;
  begin
  if Handle <> -1 then
    SysFileClose(Handle);
  FPos := 0;
  FSize := 0;
  Handle := -1;
  end;

destructor TLocFile.Done;
  begin
  Close;
  inherited Done;
  end;

procedure TLocFile.MkDir;
  begin
  System.MkDir(StrPas(FNameZ));
  end;

procedure TLocFile.RmDir;
  var
    Path: string;
  begin
  Path := StrPas(FNameZ);
  NotifyDeleteWatcher(Path);
  System.RmDir(Path);
  end;

procedure TLocFile.Erase(Options: word {efo...});
  begin
  if (Options and efoForce) <> 0 then
    SetFAttr($20);
  InOutRes := SysFileDelete(FNameZ);
  end;
//=========== TLocFile

{$IFDEF DPMI32}
procedure SetFAttr(Time: Longint);
  begin
  lWIN95FileAttrFunc(F, Attr, faGetAttr);
  end;

procedure GetFAttr(var ime: Longint);
  begin
  lWIN95FileAttrFunc(F, Attr, faGetAttr);
  end;

procedure SetFTime(Time: Longint);
  begin
  lWIN95FileAttrFunc(F, Attr, faGetAttr);
  end;

procedure GetFTime(var ime: Longint);
  begin
  lWIN95FileAttrFunc(F, Attr, faGetAttr);
  end;

// ======== TWin95File

function Win95FileInit(var F: lFile; const Name: String): Boolean;
  begin
  Result := (Name[2] = ':') and (lAPI = lWin95);
  if Result then
    TWin95File(F).Init;
  end;

procedure TWin95File.Open(Mode: Word);
  var
    regs: real_mode_call_structure_typ;
    begin
    init_register(regs);
    if Handle <> -1 then
      Close;
    InOutRes := 0;

    if FNameZ[0] <> #0 then with regs do
      begin
      ax_ := $716C;
      bx_ := FileMode;
      cx_ := Attr;
      dx_ := Action;
      ds_ := segdossyslow16;
      si_ := 0;
      di_ := 0;
      Move(F.FullName,Mem[segdossyslow32],SizeOf(F.FullName));
      flags_:=fCarry;
      intr_realmode(regs,$21);
      if flags_ and fCarry <> 0 then
        begin
        InOutRes := ax_;
        Handle := -1;
        end;
      else
        Handle := ax_;
      end;
  end;

function TWin95File.Rename(const NewName: string);
  var
    NewNameZ: TNameZ;
    regs: real_mode_call_structure_typ;
  begin
  Move(F.FNameZ,Mem[segdossyslow32],SizeOf(F.FNameZ));
  StrPCopy(PChar(@Mem[segdossyslow32+SizeOf(F.FNameZ)]), NewName);
  init_register(regs);
  with Regs do
  begin
    ax_ := $7156;
    ds_ := segdossyslow16;
    dx_ := 0;
    es_ := segdossyslow16;
    di_ := SizeOf(NameZ);
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0
    then InOutRes := ax_
    else InOutRes := 0;
  end;
  end;

(*
 INT 21h  AX=714E
 INT 21 - Windows95 - LONG FILENAME - FIND FIRST MATCHING FILE
         AX = 714Eh
         CL = allowable-attributes mask (bits 0 and 5 ignored)
         CH = required-attributes mask
         SI = date/time format
         DS:DX -> ASCIZ filespec (both "*" and "*.*" match any filename)
         ES:DI -> FindData record
 Return: CF clear if successful
             AX = filefind handle (needed to continue search)
             CX = Unicode conversion flags
         CF set on error
             AX = error code
                 7100h if function not supported
 Notes:  this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
         the application should close the filefind handle
         with AX=71A1h as soon as it has completed its search
*)
  Attr: Word; var R: lSearchRec);
  var
    FindData: ^lFindDataRec;
    regs: real_mode_call_structure_typ;
    PathBuf: array[0..SizeOf(PathStr)-1] of Char;
  begin
  R.FullName := '';
  R.FindFirstMode := lWIN95;
  FindData:=Ptr(segdossyslow32);
  StrPCopy(FindData^.FullName, Path);
  init_register(regs);
  with regs do
    begin
    ax_:= $714E;
    cx_:= Attr;
    si_:= 1;
    ds_:= segdossyslow16;
    dx_:= $2c;
    es_:= segdossyslow16;
    di_:= 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0 then
      begin
      R.FileHandle := $FFFF;
      DosError := ax_;
      end
    else
      begin
      R.FileHandle := ax_;
      FindDataToSearchRec(FindData^, R);
      DosError := 0;
      end;
    end;
  end;


(*
 INT 21h  AX=714F
 INT 21 - Windows95 - LONG FILENAME - FIND NEXT MATCHING FILE
         AX = 714Fh
         BX = filefind handle (from AX=714Eh)
         SI = date/time format
         ES:DI -> buffer for FindData record
 Return: CF clear if successful
             CX = Unicode conversion flags
         CF set on error
             AX = error code
                 7100h if function not supported
 Note:   this function is only available when IFSMgr is running,
         not under bare MS-DOS 7

*)
procedure TWin95File.FindNext(var R: lSearchRec);
  var
    FindData: ^lFindDataRec;
    regs: real_mode_call_structure_typ;
  begin
  FindData:=Ptr(segdossyslow32);
  init_register(regs);
  with regs do
    begin
    ax_:= $714F;
    bx_:= R.FileHandle;
    si_:= 1;
    es_:= segdossyslow16;
    di_:= 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0 then
      DosError := ax_
    else
      begin
      FindDataToSearchRec(FindData^, R);
      DosError := 0;
      end;
    end;
  end;

(*
 INT 21h  AX=71A1
 INT 21 - Windows95 - LONG FILENAME - "FindClose" -
          TERMINATE DIRECTORY SEARCH
         AX = 71A1h
         BX = filefind handle (from AX=714Eh)
 Return: CF clear if successful
         CF set on error
            AX = error code
                 7100h if function not supported
 Notes:  this function must be called after starting a search
         with AX=714Eh, to indicate that the search handle
         returned by that function will no longer be used
         this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
*)
procedure TWin95File.FindClose(var R: lSearchRec);
  var
    regs: real_mode_call_structure_typ;
  begin
  init_register(regs);
  if R.FileHandle <> $FFFF then with regs do
    begin
    ax_:= $71A1;
    bx_:= R.FileHandle;
    intr_realmode(regs,$21);
    end;
  end;

procedure TWin95File.WIN95DirFunc(AFunction: Word);
var
  regs: real_mode_call_structure_typ;
begin
  Move(FNameZ,Mem[segdossyslow32],SizeOf(TNameZ));
  init_register(regs);
  with regs do
  begin
    ax_ := AFunction;
    ds_ := segdossyslow16;
    dx_ := 0;
    flags_:=fCarry;
    intr_realmode(regs,$21);
    if flags_ and fCarry <> 0
    then InOutRes := ax_
    else InOutRes := 0;
  end;
end;

procedure TWin95File.MkDir;
  begin
  WIN95DirFunc($7139);
  end;

procedure TWin95File.RmDir;
  begin
  WIN95DirFunc($713A);
  end;

// ======== TWin95File
{$ENDIF}

procedure InitPath;
  var
    D: Integer;
    P: String[3];
{$IFDEF DPMI32}
    lsr: lSearchRec;
{$ENDIF}
  begin
{$IFDEF DPMI32}
  //check LFN Api presence
  lsr.FindFirstMode := lWIN95;
  lWIN95FindFirst(ParamStr(0), AnyFileDir, lsr);
  lFindClose(lsr);
  if DosError <> 0 then
    lApi := lDOS;
{$ENDIF}
  P := 'A:\';
  for D := 1 to High(CurrentPaths) do
    begin
    CurrentPaths[D] := P;
    Inc(P[1]);
    end;
  GetDir(0, StartDir);
  StartDir[1] := Upcase(StartDir[1]);
     //piwamoto: w32 shortcut may have c:\ as directory
     //but DN needs C:\ for internal use
  lChDir(StartDir);
  end;

procedure RegisterFileInit(T: TFileInit);
  var
    i: Integer;
  begin
  for i := 0 to High(FileInit) do
    begin
    if @FileInit[i] = nil then
      begin
      @FileInit[i] := @T;
      Exit;
      end;
    end;
  end;

begin
InitPath;
{$IFDEF DPMI32}
RegisterFileInit(Win95FileInit);
{$ENDIF}
end.
