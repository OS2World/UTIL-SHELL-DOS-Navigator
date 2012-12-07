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

unit Tree;

interface

uses
  Objects2, Collect, Drivers, Defines, Streams,
  Dialogs, Views, FilesCol, flpanelx, Drives
  ;

{ В этом модуле нормализованным путём называется путь с '\' на конце
и на верхнем регистре}

type
  PNode = ^TNode;
  PTreeView = ^TTreeView;
  PTreeInfoView = ^TTreeInfoView;

  PTreeDialog = ^TTreeDialog;
  TTreeDialog = object(TDialog)
    Tree: PTreeView;
    isValid: Boolean;
    constructor Init(R: TRect; const ATitle: string; ADrive: PDrive);
    {procedure HandleEvent(var Event: TEvent); virtual;}
    function GetPalette: PPalette; virtual;
    function Valid(Command: Word): Boolean; virtual;
    end;

  PChilds = ^TChilds;
    { Каталоги одного уровня с общим надкаталогом (Parent),
      сортируется по нормализованным именам }
  TChilds = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    end;

  TNode = object(TObject)
     { Узел дерева каталогов }
    Tree: PTreeView; // никогда не nil
    Parent: PNode;
    Level: Integer;
    Childs: PChilds; // всегда Childs<>nil
    Number: Integer; // индекс в DC
    Size: TSize; // значение -1 показывает, что размер не сканировался
    NumFiles: LongInt;
    Date: LongInt;
    NodeAttr: Byte; // это чисто "деревянные" атрибуты, см. trExpanded
    NodeName: TFlName;
    Dummy: array[1..SizeOf(ShortString)-SizeOf(TShortName)] of Char;
      { см. комментарий к Filescol.TFileRec.Dummy}
    constructor Init(AParent: PNode; ATree: PTreeView; const Name: String);
    destructor Done; virtual;
    function GetFullPath: string;
      { Всегда с '\' на конце, регистр букв - как есть. }
    procedure ReadBranch(const APath: string; ReadMode: Integer);
      { Читается поддерево:
        - полностью (ReadMode=rmAll);
        - один уровень (ReadMode=rmLevel) плюс вдоль APath;
        - только вдоль APath (ReadMode=rmNone);
        - перечитывается то и только то, что было прочитано ранее
      (ReadMode=rmReread) (в этом случае чтения вдоль APath нет).
        При перечитывании по возможности сохраняем старые элементы
      Childs, вместе с их атрибутами и поддеревьями.
        APath должен быть нормализован.}
    end;

  PDirCollection = ^TDirCollection;
   { Для показа на экране, каждый элемент - строка дерева на экране.
     Элементы - добавочные ссылки на узлы, освобждать их не надо.
     Сохранять эту коллекцию тоже не надо. }
  TDirCollection = object(TCollection)
    procedure FreeItem(P: Pointer); virtual;
    end;

  TTreeView = object(TView)
    Drive: PDrive;
    ScrollBar: PScrollBar;
    SelNode: PNode; // выбранный узел (где курсор)
    CurNode: PNode; // узел, завершающий видимую часть CurPath
    CurPath: String; // нормализованный
    Root: PNode; // корень; дальше Childs^ и по ссылкам
    DC: PDirCollection;
      { ссылки (PNode) на элементы дерева для отображения:
        каждый элемент DC - очередная строка. }
    Delta: TPoint;
    Info: PTreeInfoView;
      { Подвал; заполняется в его Init. Подвал имеет размер
        по вертикали 2 строки, но в диалгое из них показывается
        почему-то только одна. }
    RecurseLevel: Integer; // для рекурсивных методов
    isValid: Boolean;
    PanelMode, // режим панели (а не диалога)
    DrawDisabled,
    LocateEnabled, MouseTracking, WasChanged: Boolean;
    Expanded: Boolean;
    constructor Init(R: TRect; const ACurPath: string; APanelMode: Boolean;
        ScrBar: PScrollBar; ADrive: PDrive);
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
      { перечитать указанный каталог }
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure CancelSearch;
    procedure HandleCommand(var Event: TEvent);
    procedure NodeToDC(Node: PNode; ParentPath: string);
    procedure ReadTree(const APath: string; ForceRead: Boolean);
      { полное перечитывание (ForceRead) или дочитывание
        только необходимого; читается корень и вдоль APath.
        APath должен быть нормализован }
    procedure SetData(var Rec); virtual;
    procedure GetData(var Rec); virtual;
    procedure CollapseBranch(P: PNode; NewState: word; Recurse: Boolean);
      { Развернуть (NewState = trExpanded) или свернуть (NewState=0)
      один уровень (not Recurse) или всю ветку (Recurse)}
    function DataSize: Word; virtual;
    function FindPath(APath: string; var Node: PNode): Longint;
      { Найти в существующем дереве узел с указанным путём или его
      частью. Результат - длина найденной части APath.
      Если результат 0, то Node = nil.
        APath должен быть нормализован }
    procedure GotoPath(var APath: string);
      { APath на входе любой, на выходе будет нормализованным.
        APath не должен быть "ненастоящий", вроде пути внутри архива. }
    procedure ReadAfterLoad(ACurPath: string);
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    destructor Done; virtual;
    end;

  TTreeInfoView = object(TView)
    Tree: PTreeView;
    Down: String;
    Loaded: Boolean;
    constructor Init(R: TRect; ATree: PTreeView);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure MakeDown;
    constructor Load(var S: TStream);
    procedure Store(var S: TStream);
    function GetPalette: PPalette; virtual;
    destructor Done; virtual;
    end;

  PDTreeInfoView = ^TDTreeInfoView; { дерево в диалоге }
  TDTreeInfoView = object(TTreeInfoView)
    function GetPalette: PPalette; virtual;
    end;

  PHTreeView = ^THTreeView;
   {`2 дерево-панель `}
  THTreeView = object(TTreeView)
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    destructor Done; virtual;
    end;

function ChangeDir(ATitle: TTitleStr; const ACurPath: string): String;
  {` вызвать дерево-диалог и вернуть выбранный в нём путь `}
procedure CheckMkDir(const Path: String);
 {` MkDir and check result AK155 `}
procedure MakeDirectory;
 {` Создать каталог(и) в диалоге. Фактически, это TDrive.MakeDir.
  В введённой строке можнт быть несколько каталогов, разделённых
  точками с запятой.
  Имя первого созданного каталог с полным путём без слэша помещается в
  переменную CreatedDir. Если каталог не создался - CreatedDir=''.
  Переменная CreatedDir используется в ARVIDAVT.PAS, и подозреваю, что
  в каком-то другом смысле. `}

function CreateDirInheritance(var S: String; Confirm: Boolean): Byte;
  {` Создать каталог любой вложенности. S разворачивается при
   помощи lFExpand и дополняется '\' в конце, и это значение
   остаётся после вызова.
     Результат - длина пути (то есть подстроки S) каталога, в
   котором находится самый внешний созданный каталог (без слэша).
   Например, если s='C:\TEMP\AAA\BBB' и каталог C:\TEMP существовал,
   а C:\TEMP\AAA был создан, то результат - 7. Смысл этого в том,
   что если C:\TEMP открыт на какой-то панели, то эту панель надо
   перечитать, чтобы на ней появился AAA.
     Если каталоги не создавались - результат 0. `}

const
  CreatedDir: String = '';
    {` Результат MakeDirectory `}
  TreeError: Boolean = False;

  CHTreeView = #15#16#17#18#19#20#21;
  CTreeInfoView = #22;
  CDTreeInfoView = #30;
  CTreeView = #38#39#40#41#42#43#44;
  CTreeDialog = CDialog+#104#105#106#107#108#109#110;

implementation
uses
  Lfn, Files, Memory, Startup, Dos, DnIni, DNHelp, DNUtil,
  Advance, Advance1, Advance2, Advance3,
  DNApp, Messages, Commands, Eraser, Menus,
  xTime, FileCopy, FileDiz
  ;

const
 { Атрибуты узла дерева (NodeAttr)}
  trLast = $01;
    { Данный узел в объемлющем каталоге последний на экране (от этого
      зависит, какую линию около него рисовать - ответвление
      (не последний) или поворот (последний)}
  trExpanded = $02; // развёрнут на экране; при этом trHasChildrens и trScanned
  trHasChildrens = $04;
  trScanned = $08;
    { Подкаталоги просканировны. О подкаталогах следующих уровней
      это ничего не говорит. При этом trHasChildrens }

const { режимы ReadBranch }
  rmNone = 0;
  rmLevel = 1;
  rmAll = 2;
  rmReread = 3;
  rmSize = 4;

const
  LevelTab = 3;

const
  cmDirChanged = 201;
    { cmDirChanged отсюда выдаётся к owner, но
      обрабатывается только тут же (TTreeInfoView.HandleEvent);
      в Commands с этим кодом cmQuickView, которая явно сюда не
      относится.}

procedure Norm(var Path: string);
  begin
//  UpStr(Path);
  MakeSlash(Path);
  if Path = '' then
    Path := '\';
  end;

function ESC_Pressed: Boolean;
  var
    E: TEvent;
  begin
  Application^.Idle;
  GetKeyEvent(E);
  ESC_Pressed := (E.What = evKeyDown) and (E.KeyCode = kbESC)
  end;

type
  TScanData = record
    SR: lSearchRec; // обязательный первый элемент
    PSize: TSize; // обязательный элемент
    FCount: Longint; // обязательный элемент
    Node: PNode;
    OldChilds: PChilds;
    FSize: TSize;
    ScannedAttr: word;
    AtCurPath: Boolean;
    OnlyFirst: Boolean;
    end;

function PutIntoChilds(
    Drive: PDrive;
    const Path: String;
    N: Integer; // номер элемента, от 0; -1 = завершение
    var UserData
    ): Boolean;
  var
    ScanData: TScanData absolute UserData;
    P: PNode;
    i: Longint;
  begin
  case N of
   -1:
     begin { инициализация }
     end;
   -2:
     begin { завершение }
     end;
   else
     begin { очередное имя }
     if ScanData.SR.SR.Attr and Directory <> 0 then
       begin
       inc(ScanData.Node^.NumFiles, ScanData.FCount);
       ScanData.Node^.NodeAttr := ScanData.Node^.NodeAttr or trHasChildrens;
       if ScanData.OnlyFirst then
         begin
         Result := False;
         Exit;
         end;
       ScanData.Node^.NodeAttr :=
         (ScanData.Node^.NodeAttr and not ScanData.ScannedAttr) or
           ScanData.ScannedAttr;
       New(P, Init(ScanData.Node, ScanData.Node^.Tree, ScanData.SR.FullName));
{$IFDEF DualName}
       P^.NodeName[False] := ScanData.SR.SR.Name;
{$ENDIF}
       P^.Level := ScanData.Node^.Level+1;
       if ScanData.OldChilds^.Search(P, i) then
         begin
         P^.Free;
         P := ScanData.OldChilds^.At(i);
         ScanData.OldChilds^.AtDelete(i);
         P^.NodeAttr := P^.NodeAttr and not trLast;
         end;
       P^.Size := ScanData.SR.FullSize;
       P^.NumFiles := ScanData.FCount;
       ScanData.Node^.Childs^.Insert(P);
       end
     else
       begin
       ScanData.Node^.Size := ScanData.Node^.Size + ScanData.SR.FullSize;
       inc(ScanData.Node^.NumFiles);
       end;
     Result := True;
     end;
  end { case };
  end;

procedure TNode.ReadBranch(const APath: string; ReadMode: Integer);
  var
    I: Integer;
    S: String;
    P: PNode;
    SearchAttr: Word;
    ScanData: TScanData;
  begin
  if Abort then
    Exit;
  S := GetFullPath;
  Norm(S);
  ScanData.Node := @Self;
  ScanData.AtCurPath := Copy(APath, 1, Length(S)) = S;
  ScanData.OnlyFirst := not ScanData.AtCurPath and (ReadMode=rmNone);
  if (ReadMode = rmSize) or
    (((NodeAttr and trScanned) <> 0) = (ReadMode = rmReread))
  then
    begin { строим или перестраиваем Childs; иначе используем старую Childs }
    NodeAttr := NodeAttr and not (trScanned or trHasChildrens);
    New(ScanData.OldChilds, Init(Childs^.Count, 10));
    for i := 0 to Childs^.Count-1 do
      ScanData.OldChilds^.Insert(Childs^.At(i));
    Childs^.DeleteAll;
    if (ReadMode = rmSize) then
      begin { для подсчёта размера сканируем всё,
        а подкаталоги не раскрываем }
      SearchAttr := AnyFileDir;
      ScanData.ScannedAttr := trScanned;
      Size := 0;
      NumFiles := 0;
      end
    else
      begin{ сканируем только каталоги, и если все - то для раскрытия }
      SearchAttr := AnyFileDir or (Directory shl 8);
      ScanData.ScannedAttr := trScanned;
      if ReadMode <> rmReread then
        ScanData.ScannedAttr := ScanData.ScannedAttr or trExpanded;
        { дерево могло быть построено полностью после F3, но при этом
          не быть раскрыто. Так что при rmReread trExpanded надо
          оставлять старый }
//      Size := -1;
      end;
    Tree^.Drive^.ScanDirectory(S, SearchAttr, PutIntoChilds, ScanData);
    Dispose(ScanData.OldChilds, Done);
    end;

  if not ScanData.OnlyFirst or (ReadMode = rmReread) or (ReadMode = rmSize)
  then
    begin
    if (ReadMode = rmLevel) or
       ((ReadMode = rmReread) and ((NodeAttr and trExpanded) = 0))
    then
      ReadMode := rmNone;
    for i := 0 to Childs^.Count-1 do
      begin
      P := Childs^.At(i);
      P^.ReadBranch(APath, ReadMode);
      if ReadMode = rmSize then
        begin
        Size := Size + P^.Size;
        inc(NumFiles, P^.NumFiles);
        end;
      end;
    end;

  { помечаем последний подкаталог. Поскольку коллекция сортированная,
   последний становится известен только после полного построения }
  I := Childs^.Count-1;
  if I >= 0 then with PNode(Childs^.At(I)) do
    NodeAttr := NodeAttr or trLast;

  end { TNode.ReadBranch };

procedure TTreeView.NodeToDC(Node: PNode; ParentPath: string);
  var
    I, N: Integer;
  begin
  inc(RecurseLevel);

  if Node = Root then
    begin
    DC^.FreeAll;
    CurNode := Root;
    end;
  Node^.Number := DC^.Count;
  DC^.Insert(Node);
  ParentPath := ParentPath + Node^.NodeName[uLFN];
  Norm(ParentPath);
  if (ParentPath = Copy(CurPath, 1, Length(ParentPath)))
    and (Node^.Level > CurNode^.Level)
  then
    CurNode := Node;
  if (Node^.NodeAttr and trExpanded) <> 0 then
    begin
    N := Node^.Childs^.Count;
    for i := 1 to N do
      NodeToDC(Node^.Childs^.At(i-1), ParentPath);
    end;
  dec(RecurseLevel);
  if RecurseLevel = 0 then
    begin
    N := 0;
    if SelNode <> nil then
      N := SelNode.Number;
    ScrollBar^.SetParams(N, 0, DC^.Count-1, Size.Y-1, 1);
    end;
  end;

procedure TTreeView.ReadTree(const APath: string; ForceRead: Boolean);
  var
    S: String;
    Lv, N, I: Integer;
    Tmr: TEventTimer;
    Msg: PView;

  procedure ChkESC;
    begin
    if Abort then
      Exit;
    if TimerExpired(Tmr) then
      begin
      NewTimer(Tmr, 150);
      if ESC_Pressed then
        Abort := True;
      end;
    end;

  begin { TTreeView.ReadTree }
  {AK155: warn надо добавить вывод дерева для архивов }
  NewTimer(Tmr, 1);
  TreeError := True;
  if LowMemory then
    Exit;
  if ForceRead or (Root = nil) then
    begin
    if Root <> nil then
      Dispose(Root, Done);
    New(Root, Init(nil, @Self, Drive^.RootPath));
    end;
  Abort := False;
  Msg := WriteMsg(GetString(dlScanningDirs));
  Root^.ReadBranch(APath, rmLevel);
  Dispose(Msg, Done);
  TreeError := Abort;
  if Abort then
    begin
    Dispose(Root, Done);
    Root := nil;
    end;

  { для отобржения: диск и каталоги корня и текущего пути }
  N := Root^.Childs^.Count;
  if DC = nil then
    New(DC, Init(N+1, 10));
  NodeToDC(Root, '');
  SelNode := CurNode;
  end { TTreeView.ReadTree };

procedure CheckMkDir(const Path: String);
  var
    rc: LongInt;
  label Start;
  begin
Start:
  lMkDir(Path);
  rc := IOResult;
  {AK155 29-05-2002
При создании существующего каталога (что не есть ошибка)
под OS/2 rc=5, а под WinNT - rc=183.
При создании каталога на CD (что есть ошибка)
под OS/2 rc=19, а под WinNT - rc=5.
Как оно будет под Win9x или DPMI - тоже еще вопрос.
Поэтому проще и аккуратнее проверить фактическое наличие, а не
анализировать rc }
  if not PathExist(Path) then
    begin
    if SysErrorFunc(rc, Byte(Path[1])-Byte('A')) = 1 then
      goto Start;
    rc := MessageBox(GetString(dlFCNoCreateDir)+Path, nil,
         mfError+mfOKButton);
    Abort := True;
    end;
  end { CheckMkDir };

procedure MakeDirectory;
  var
    S, S1: String;
    Nm: String;
    XT: String;
    B: Byte;
    I: Integer;
    j: Boolean;
    W: Word;
  begin
  CreatedDir := '';
  if LowMemory then
    Exit;
  S := '';
  W := ExecResource(dlgMkDir, S);
  if W = cmYes then
    UpStr(S)
  else if W = cmNo then
    LowStr(S)
  else if W <> cmOK then
    Exit;
  DelRight(S);
  {$IFDEF DPMI32}
  DelLeft(S);
  {$ENDIF}
  if S = '' then
    Exit;
  {$IFDEF RecodeWhenDraw}
  S := OemToCharStr(S);
  {$ENDIF}
  CreatedDir := '';
  while S <> '' do
    begin
    j := False;
    I := 0;
    while (I < Length(S)) do
      begin
      Inc(I);
      if not j and (S[I] = ';') then
        Break;
      if S[I] = '"' then
        j := not j;
      end;
    if I = Length(S) then
      Inc(I);
    if I = 0 then
      I := Length(S)+1;
    S1 := DelSquashes(Copy(S, 1, I-1));
    Delete(S, 1, I);
    if S1 = '' then
      Continue;
    B := CreateDirInheritance(S1, False);
    if Abort or (IOResult <> 0) then
      Exit;
    MakeNoSlash(S1);
    if CreatedDir = '' then
      CreatedDir := S1;
    { определение каталога для перечитывания }
    if B > 0 then
      SetLength(S1, B)
    else
      begin
      lFSplit(S1, S1, Nm, XT);
      MakeNoSlash(S1);
      end;
    RereadDirectory(S1);
    GlobalMessage(evCommand, cmRereadTree, @S1);
    GlobalMessage(evCommand, cmRereadInfo, nil);
    end;
  end { MakeDirectory };

function ChangeDir(ATitle: TTitleStr; const ACurPath: string): String;
  var
    D: PTreeDialog;
    R: TRect;
    WorkDrive: PDrive;
  begin
  R.Assign(1, 1, 50, 18);
  Abort := False;
  ChangeDir := '';
  New(WorkDrive, Init(Byte(ACurPath[1])-64, nil));
  WorkDrive^.lChDir(ACurPath);
  New(D, Init(R, ATitle, WorkDrive));
  D^.Options := D^.Options or ofCentered;
  Result := '';
  D := PTreeDialog(Application^.ValidView(D));
  if Desktop^.ExecView(D) = cmOK then
    D^.GetData(Result);
  Dispose(WorkDrive, Done);
  end;

destructor TTreeInfoView.Done;
  begin
  PHTreeView(Tree).Info := nil;
  inherited Done;
  end;

constructor TTreeInfoView.Init;
  begin
  inherited Init(R);
  Tree := ATree;
  Tree.Info := @Self;
  Options := Options or ofPostProcess;
  EventMask := evBroadcast;
  GrowMode := gfGrowHiX+gfGrowHiY+gfGrowLoY;
  MakeDown;
  Loaded := False;
  end;

procedure TTreeInfoView.HandleEvent;
  begin
  inherited HandleEvent(Event);
  if  (Event.What = evBroadcast) and (Event.Command = cmDirChanged) then
    begin
    MakeDown;
    DrawView
    end;
  end;

constructor TTreeInfoView.Load;
  begin
  inherited Load(S);
  GetPeerViewPtr(S, Tree);
  Loaded := True;
  end;

procedure TTreeInfoView.Store;
  begin
  inherited Store(S);
  PutPeerViewPtr(S, Tree);
  end;

function TTreeInfoView.GetPalette;
  const
    S: String[Length(CTreeInfoView)] = CTreeInfoView;
  begin
  GetPalette := @S;
  end;

function TDTreeInfoView.GetPalette;
  const
    S: String[Length(CDTreeInfoView)] = CDTreeInfoView;
  begin
  GetPalette := @S;
  end;

procedure TTreeInfoView.Draw;
  var
    B: TDrawBuffer;
    C: Byte;
    S: String;
  begin
  C := GetColor(1);
  if (QSPanel <> Tree) then
    begin
    if Loaded then
      MakeDown;
    Loaded := False;
    S := Tree^.SelNode^.GetFullPath;
    MakeNoSlash(S);
    MoveChar(B, ' ', C, Size.X);
    MoveStr(B[1], Cut(S, Size.X), C);
    WriteLine(0, 0, Size.X, 1, B);
    MoveChar(B, ' ', C, Size.X);
    MoveStr(B[1], Down, C);
    WriteLine(0, 1, Size.X, 1, B);
    end
  else
    begin
    MoveChar(B, ' ', C, Size.X);
    WriteLine(0, 1, Size.X, 1, B);
    MoveStr(B[1], QSMask, C);
    WriteLine(0, 0, Size.X, 1, B);
    end;
  end;

procedure TTreeInfoView.MakeDown;
  var
    L1: LongInt;
    L2: TSize;
  begin
  if  (Tree <> nil) and (Tree^.SelNode <> nil) then
    begin
    L2 := Tree^.SelNode^.Size;
    if L2 = -1 then
      Down := ''
    else
      begin
      L1 := Tree^.SelNode^.NumFiles;
      if L1 <> 1 then
        Down := ItoS(L1)+GetString(dlTreeFilesWith)
      else
        Down := GetString(dlTree1FileWith);
      if L2 <> 1 then
        Down := Down+FStr(L2) + ' ' + GetString(dlDIBytes)
      else
        Down := Down + ' 1' + GetString(dlDIByte);
      end;
      end;
  end;

constructor TTreeDialog.Init(R: TRect; const ATitle: String;
       ADrive: PDrive);
  var
    R1, R2: TRect;
    P: PView;
  begin
  inherited Init(R, ATitle);
  HelpCtx := hcDirTree;
  isValid := True;
  if R.B.X-R.A.X < 24 then
    R.Grow(24+R.A.X-R.B.X, 0);
  if R.B.Y-R.A.Y < 8 then
    R.B.Y := R.A.Y+8;
  GetExtent(R);
  R.Grow(-1, -1);
  R1 := R;
  Dec(R1.B.X, 14);
  P := StandardScrollBar(sbVertical+sbHandleKeyboard);
  Dec(P^.Origin.X, 14);
  Dec(R1.B.Y);
  Tree := New(PTreeView, Init(R1, ADrive^.CurDir, False, PScrollBar(P),
    ADrive));
  if Tree^.Valid(0) then
    Insert(Tree)
  else
    begin
    Dispose(Tree, Done);
    Tree := nil;
    isValid := False;
    Exit;
    end;

  R1.A.Y := R1.B.Y;
  Inc(R1.B.Y);
  P := New(PDTreeInfoView, Init(R1, PTreeView(Tree)));
  Insert(P);

  R1.Assign(R.B.X-13, R.A.Y+1, R.B.X-1, R.A.Y+3);
  P := New(PButton, Init(R1, GetString(dlOKButton), cmOK, bfDefault));
  Insert(P);
  R1.Assign(R.B.X-13, R.A.Y+4, R.B.X-1, R.A.Y+6);
  P := New(PButton, Init(R1, GetString(dlDriveButton), cmChangeDrive,
         bfBroadcast));
  {P^.Options := P^.Options and not ofSelectable;}
  Insert(P);
  R1.Assign(R.B.X-13, R.A.Y+7, R.B.X-1, R.A.Y+9);
  P := New(PButton, Init(R1, GetString(dlRereadButton), cmPanelReread,
         bfBroadcast));
  Insert(P);
  R1.Assign(R.B.X-13, R.A.Y+10, R.B.X-1, R.A.Y+12);
  P := New(PButton, Init(R1, GetString(dlMkDirButton), cmPanelMkDir,
         bfBroadcast));
  Insert(P);
  R1.Assign(R.B.X-13, R.A.Y+13, R.B.X-1, R.A.Y+15);
  P := New(PButton, Init(R1, GetString(dlCancelButton), cmCancel, 0));
  Insert(P);
  SelectNext(False);
  Options := Options or ofTopSelect;
  end { TTreeDialog.Init };

function TTreeDialog.GetPalette;
  const
    S: String[Length(CTreeDialog)] = CTreeDialog;
  begin
  GetPalette := @S;
  end;

function TTreeDialog.Valid;
  begin
  Valid := isValid and inherited Valid(Command)
  end;

constructor TTreeView.Init(R: TRect; const ACurPath: string;
    APanelMode: Boolean; ScrBar: PScrollBar; ADrive: PDrive);
  var
    I, Lv: Integer;
    S, D: String;
    P: PNode;
  begin
  inherited Init(R);
  Abort := False;
  if APanelMode then
    HelpCtx := hcDirTree;
  EventMask := $FFFF;
  CurPath := ACurPath;
  Norm(CurPath);
  ScrollBar := ScrBar;
  Drive := ADrive;
  Options := Options or ofSelectable {or ofTopSelect} or ofFirstClick;
  PanelMode := APanelMode;
  if PanelMode then
    Options := Options or ofTopSelect;
  GrowMode := gfGrowHiX+gfGrowHiY;
  WasChanged := False;
  DC := nil;
  MouseTracking := False;
  LocateEnabled := True;
  if not Abort then
    ReadTree(CurPath, False);
  ScrollBar^.SetValue(CurNode^.Number);
  DrawDisabled := False;
  isValid := not Abort and (ScrollBar <> nil);
  end { TTreeView.Init };

destructor TTreeView.Done;
  begin
  PObject(DC)^.Free;
  DC := nil;
  Root^.Free;
  Root := nil;
  inherited Done;
  end;

function TTreeView.GetPalette;
  const
    S: String[Length(CTreeView)] = CTreeView;
  begin
  GetPalette := @S;
  end;

constructor TTreeView.Load;
  var
    P: Pointer;
  begin
  inherited Load(S);
  GetPeerViewPtr(S, ScrollBar);
  GetPeerViewPtr(S, Info);
  PanelMode := True;
  StopQuickSearch;
  LocateEnabled := True;
  DC := nil;
  isValid := True;
  end;

procedure TTreeView.ReadAfterLoad(ACurPath: string);
  begin
  Abort := False;
  CurPath := ACurPath;
  ReadTree(CurPath, False);
  isValid := not Abort and (ScrollBar <> nil);
  end;

procedure TTreeView.Store;
  begin
  inherited Store(S);
  PutPeerViewPtr(S, ScrollBar);
  PutPeerViewPtr(S, Info);
  end;

function THTreeView.GetPalette;
  const
    S: String[Length(CHTreeView)] = CHTreeView;
  begin
  GetPalette := @S;
  end;

function TTreeView.Valid;
  begin
  Valid := isValid and inherited Valid(Command)
  end;

procedure TTreeView.SetData;
  begin
  end;

procedure TTreeView.GetData;
  begin
  String(Rec) := SelNode^.GetFullPath;
  end;

function TTreeView.DataSize;
  begin
  DataSize := 256;
  end;

procedure TTreeView.CollapseBranch(P: PNode; NewState: word;
       Recurse: Boolean);
  var
    i, rm: Integer;
    C: PNode;
  begin
  inc(RecurseLevel);
  if (P^.NodeAttr and trExpanded) <> NewState then
    begin
    if NewState <> 0 then
      begin { раскрытие ветви }
      P^.NodeAttr := P^.NodeAttr xor trExpanded;
      if (P^.NodeAttr and trScanned) = 0 then
        begin
        if not Recurse then
          rm := rmLevel
        else
          rm := rmAll;
        P^.ReadBranch(P^.GetFullPath, rm);
        end;
      end
    else
      begin { свёртка ветви }
      if (P <> Root) then
        begin {корень не сворачиваем}
        P^.NodeAttr := P^.NodeAttr xor trExpanded;
        end;
      end;
    end;
  if Recurse then
    for i := 0 to P^.Childs^.Count-1 do
      begin
      C := P^.Childs^.At(i);
      if (NewState = 0) and (C = SelNode) then
        SelNode := P;
      CollapseBranch(C, NewState, True);
      end;
  dec(RecurseLevel);
  if RecurseLevel = 0 then
    NodeToDC(Root, '');
  end { TTreeView.CollapseBranch };

procedure TTreeView.HandleEvent;
  begin
  if Valid(0) then
    begin
    if WheelEvent then
      WheelEvent := WheelEvent;
    inherited HandleEvent(Event);
    HandleCommand(Event);
    if not Valid(0) then
      Message(Owner, evCommand, cmCancel, nil)
    end;
  end;

function MkFcFromDirRec(D: PNode): PFilesCollection;
  { Создать файловую коллекцию из единственного каталога, не корневого.
    Эта коллекция должна сразу же использоваться (для удаления или
    копирования) и унитожаться. По крайней мере, это должно быть сделано
    до следующего вызова MkFcFromDirRec. В связи с этим для Owner
    файловой записи используетс статическая область памяти. }
  const
    S: String = '';
  var
    l: LongInt;
    fr: PFileRec;
  begin
  New(Result, Init(1, 1));
  l := Length(D^.NodeName[True]);
  GetMem(fr, TFileRecFixedSize+l);
  with fr^ do
    begin
    Move(D^.NodeName, FlName, SizeOf(FlName)+(l+1)-SizeOf(FlName[True]));
    Attr := Directory;
    S := D^.Parent^.GetFullPath;
    MakeNoSlash(S);
    Owner := @S; // для уведомлений из EraseFiles и для GetDiz
    DIZ := nil;
    GetDiz(fr);
    end;
  Result^.Insert(fr);
  end;

function DC2Name(DR: Pointer): string; {TItem2Name}
  begin
  Result := PNode(DR)^.NodeName[uLfn]
  end;

procedure TTreeView.CancelSearch;
  begin
  if (QSPanel <> @Self) then
    Exit;
  StopQuickSearch;
  DrawView;
  Info^.DrawView;
  end;

procedure TTreeView.HandleCommand;

  procedure CE;
    begin
    ClearEvent(Event)
    end;


  procedure ChangeDrive;
    var
      T: TPoint;
      S: String;
    begin
  { AK155 Поскольку теперь дерево опирается на Drive, включая его
  RootPath и CurDir, смена диска дерева стала штукой очень непонятной.
  Например, если открыто дерево в архиве, то где взять PDrive
  нужного типа? Создать временный? А что делать с его полем Panel?
  Или создать ещё и временную невидимую панель?
    В общем, пока ну её, эту команду. }
    T.X := Size.X div 2;
    T.Y := 1;
    MakeGlobal(T, T);
    Desktop^.MakeLocal(T, T);
    S := SelectDrive(T.X, T.Y, CurPath[1], False);
    if S = '' then
      Exit;
    ClrIO;
    lGetDir(Byte(S[1])-64, S);
    if Abort then
      Exit;
    CurPath := S;
    Norm(CurPath);
    Drive^.lChDir(CurPath);
    if not Abort then
      ReadTree(CurPath, True);
    end { ChangeDrive };

  procedure SendLocated;
    begin
    if LocateEnabled then
      begin
      CurPath := SelNode^.GetFullPath;
      Norm(CurPath);
      CurNode := SelNode;
      Message(Owner, evCommand, cmChangeDirectory, @CurPath);
      GotoPath(CurPath);
      end;
    end;

  procedure MkDirectory;
    var
      OldDir, NewDir: String;
    begin
    lGetDir(0, OldDir);
    GetData(NewDir);
    lChDir(NewDir);
    MakeDirectory;
    lChDir(OldDir);
    GlobalMessage(evCommand, cmRereadInfo, nil);
    end;

  procedure EraseDir;
    var
      FC: PFilesCollection;
      S: String;
    begin
    if ScrollBar^.Value < 1 then
      Exit;
    if Abort then
      Exit;
    FC := MkFcFromDirRec(SelNode);
    if EraseFiles(FC) then
      begin
      NodeToDC(Root, '');
      DrawView;
      end;
    Dispose(FC, Done);
    ClrIO;
    end { EraseDir };

  var
    Ev: TEvent;
    P: PNode;
    NewDrive: PDrive;
    CurPos, I, L: Integer;
    PD: PNode;
    MP: TPoint;
    Msg: PView;
    S: String;
    NewPath: string;
    ClasterLen: TSize;
    C: Char;
    fExpand: Boolean;

  function MaskSearch: Boolean;
{ Поиск файла, соответствия маске быстрого поиска, начиная с CurPos
  с шагом QSStep. Поиск циклический. Позиция остановки - тоже CurPos.
  QSStep может быть -1 или 1. Результат - сместиться удалось.
  }
    begin
    Result := QSSearch(CurPos, DC, DC2Name);
    if Result then
      ScrollBar^.SetValue(CurPos);
    end { MaskSearch };

  begin { TTreeView.HandleCommand }
  CurPos := ScrollBar^.Value;
  QSStep := 1;
  case Event.What of
    evCommand:
      begin
      case Event.Command of
        cmPanelErase:
          EraseDir;
        cmDoSendLocated:
          SendLocated;
        cmPanelMkDir:
          MkDirectory;
        cmChangeDrive:
          ChangeDrive;
        cmRereadTree:
          begin
          if Root = nil then
            Exit;
          S := PString(Event.InfoPtr)^;
          Norm(S);
          L := FindPath(S, PD);
          if L = Length(S) then
            begin
            PD^.NodeAttr := PD^.NodeAttr and not trScanned;
            PD^.ReadBranch(CurPath, rmLevel);
            NodeToDC(Root, '');
            DrawView;
            end;
          end;
        cmPanelReread, cmRereadForced, cmForceRescan:
          begin
          Root^.ReadBranch(CurPath, rmReread);
          NodeToDC(Root, '');
          DrawView;
          end;
        cmChangeTree:
          begin { данные - Drive }
          NewDrive := Event.InfoPtr;
          CurPath := NewDrive^.CurDir;
          Norm(CurPath);
          if (NewDrive <> Drive) or (NewDrive^.RootPath <> Drive^.RootPath)
          then
            begin
            Drive := NewDrive;
            ReadTree(CurPath, True)
            end
          else
            GotoPath(CurPath);
          end;
        cmGetName:
          PString(Event.InfoPtr)^:= GetString(dlTreeTitle);
        cmGetDirName:
          PString(Event.InfoPtr)^:= SelNode^.GetFullPath;
        cmViewFile:
          begin
          Msg := WriteMsg(GetString(dlScanningDirs));
          SelNode^.ReadBranch(CurPath, rmSize);
          Dispose(Msg, Done);
          Info^.Loaded := True;
          Info^.DrawView;
          end;
        else
          Exit;
      end {case};
      end;
    evKeyDown:
      case Event.KeyCode of
        kbHome:
          begin
          CancelSearch;
          ScrollBar^.SetValue(0);
          end;
        kbEnd:
          begin
          CancelSearch;
          ScrollBar^.SetValue(DC^.Count-1);
          end;
        kbDown, kbCtrlDown:
          begin
          CancelSearch;
          if WheelEvent or (Event.KeyCode = kbCtrlDown) then
            begin
            if Delta.Y < DC^.Count-Size.Y then
              begin
              inc(Delta.Y, 1);
              ScrollBar^.SetValue(CurPos+1);
              end;
            end
          else
            Exit;
          end;
        kbUp, kbCtrlUp:
          begin
          CancelSearch;
          if WheelEvent or (Event.KeyCode = kbCtrlUp) then
            begin
            if Delta.Y > 0 then
              begin
              Dec(Delta.Y, 1);
              ScrollBar^.SetValue(CurPos-1);
              end;
            end
          else
            Exit;
          end;

        kbAlt1, kbAlt2, kbAlt3, kbAlt4, kbAlt5, kbAlt6, kbAlt7, kbAlt8,
         kbAlt9:
          begin { переход на каталог быстрого доступа }
          CancelSearch;
          NewPath := CnvString(DirsToChange[Event.ScanCode-Hi(kbAlt1)]);
          if NewPath <> '' then
            GotoPath(NewPath);
          end;
        kbEnter:
          begin
          CancelSearch;
          if PanelMode then
            SendLocated
          else
            Exit; // обработает кнопка "OK"
          end;
        kbDel:
          begin
          CancelSearch;
          if  (FMSetup.Options and fmoDelErase <> 0) then
            EraseDir;
          end;
        kbGrayAst:
          begin
          CancelSearch;
          Expanded := not Expanded;
          CollapseBranch(Root, trExpanded*Ord(Expanded), True);
          DrawView;
          end;
        kbSpace:
          begin
          CancelSearch; //?? А если имя с пробелом?
          CollapseBranch(SelNode,
             (SelNode^.NodeAttr xor trExpanded) and trExpanded,
             False);
          DrawView;
          end;
        kbGrayPlus, kbGrayMinus, kbCtrlGrayPlus, kbCtrlGrayMinus:
          begin
          CancelSearch;
          fExpand := (Event.KeyCode = kbGrayPlus) or
             (Event.KeyCode = kbCtrlGrayPlus);
          CollapseBranch(SelNode,
             (trExpanded * Ord(fExpand)),
             (Event.KeyCode and $40000) <> 0) ;
          DrawView;
          end;
        kbRight, kbCtrlPgDn:
          begin
          CancelSearch;
          if (SelNode^.NodeAttr and trHasChildrens) <> 0 then
            begin
            CollapseBranch(SelNode, trExpanded, False);
            ScrollBar^.SetValue(SelNode^.Number+1);
            end;
          end;
        kbLeft, kbCtrlPgUp:
          begin
          CancelSearch;
          PD := SelNode^.Parent;
          if PD <> nil then
            begin
            L := PD^.Number;
            if Event.KeyCode = kbCtrlPgUp then
              CollapseBranch(PD, 0, False);
            ScrollBar^.SetValue(L);
            end;
          end;
        kbAltUp:
          begin
          if (QSPanel = @Self) then
            begin
            QSStep := -1;
            Dec(CurPos);
            MaskSearch;
            end
          else
            begin
            PD := SelNode^.Parent;
            if PD <> nil then
              begin
              I := PD^.Childs^.IndexOf(SelNode);
              if I > 0 then
                ScrollBar^.SetValue(PNode(PD^.Childs^.At(I-1))^.Number);
              end;
            end;
          end;
        kbCtrlEnter, kbAltDown:
          begin
          if (QSPanel = @Self) then
            begin
            Inc(CurPos);
            MaskSearch;
            end
          else
            begin
            PD := SelNode^.Parent;
            if PD <> nil then
              begin
              I := PD^.Childs^.IndexOf(SelNode);
              if I < PD^.Childs^.Count-1 then
                ScrollBar^.SetValue(PNode(PD^.Childs^.At(I+1))^.Number);
              end;
            end;
          end;
        kbAltHome:
          begin
          if (QSPanel = @Self) then
            begin
            CurPos := 0;
            MaskSearch;
            end
          else
            if SelNode^.Parent <> nil then
              ScrollBar^.SetValue(PNode(SelNode^.Parent^.Childs^.At(0))^.Number);
          end;
        kbAltEnd:
          begin
          if (QSPanel = @Self) then
            begin
            QSStep := -1;
            CurPos := 0;
            MaskSearch;
            end
          else
            begin
            PD := SelNode^.Parent;
            if PD <> nil then
              ScrollBar^.SetValue(PNode(PD^.Childs^.At(PD^.Childs^.Count-1))^.Number);
            end;
          end;
        kbBack:
          if (QSPanel = @Self) then
            begin
            DoQuickSearch(Event.KeyCode);
            if QSMask = '' then
              CancelSearch
            else
              begin
              MaskSearch;
              Info^.DrawView;
              DrawView;
              end;
            end;
        kbCtrlIns:
          PutInClip(SelNode^.NodeName[uLFN]);
        kbCtrlShiftIns:
          begin
          S := SelNode^.GetFullPath;
          MakeNoSlash(S);
          PutInClip(S);
          end;
        else {case}
          begin
          if Event.CharCode >= #32 then
            begin
            if (QSPanel <> @Self) then
              InitQuickSearch(@Self);
            DoQuickSearch(Event.KeyCode);
            if not MaskSearch then
              DoQuickSearch(kbBack);
            Info^.DrawView;
            DrawView;
            end;
          Exit;
          end;
      end {case};
    evBroadcast:
      begin
      case Event.Command of
        cmPanelReread,
        cmPanelMkDir,
        cmChangeDrive:
          Message(@Self, evCommand, Event.Command, nil);
        cmDropped:
          begin
          MP := PCopyRec(Event.InfoPtr)^.Where;
          if not MouseInView(MP) then
            begin
            CE;
            Exit;
            end;
          MakeLocal(MP, MP);
          I := Delta.Y+MP.Y;
          if I >= DC^.Count then
            begin
            CE;
            Exit;
            end;
          CopyDirName := PNode(DC^.At(I))^.GetFullPath;
          if PCopyRec(Event.InfoPtr)^.Owner <> nil then
            begin
            Ev.What := evBroadcast;
            Ev.Command := cmUnArchive;
            Ev.InfoPtr := Event.InfoPtr;
            PCopyRec(Event.InfoPtr)^.Owner^.HandleEvent(Ev);
            if Ev.What = evNothing then
              begin
              CE;
              Exit;
              end;
            end;
          if ReflectCopyDirection
          then
            RevertBar := not (Message(Desktop, evBroadcast,
                   cmIsRightPanel, @Self) <> nil)
          else
            RevertBar := False;
          CopyFiles(PCopyRec(Event.InfoPtr)^.FC,
             PCopyRec(Event.InfoPtr)^.Owner,
            ShiftState and 3 <> 0, 0);
          CE;
          end;
        cmScrollBarChanged:
          if ScrollBar = Event.InfoPtr then
            begin
            CE;
            SelNode := DC^.At(CurPos);
            DrawView;
            Info^.DrawView;
            Message(Owner, evBroadcast, cmDirChanged, @CurPath);
            if not MouseTracking and (FMSetup.Options and
                 fmoAutoChangeDir <> 0)
            then
              NeedLocated := GetSTime;
            end;
        else
          Exit;
      end {case};
      end;
    evMouseDown:
      begin
      MakeLocal(Event.Where, MP);
      if MP.Y+Delta.Y < DC^.Count then
        begin
        PD := DC^.At(MP.Y+Delta.Y);
        if  (PD^.Level > 0) and
            (MP.X >= PD^.Level*LevelTab+Delta.X) and
            (MP.X <= PD^.Level*LevelTab+2+Delta.X)
        then
          begin
          ScrollBar^.SetValue(MP.Y+Delta.Y);
          Message(@Self, evKeyDown, $3920, nil);
          while MouseEvent(Event, evMouseAuto+evMouseMove) do
            ;
          end
        else
          {if (MP.X >= P^.Level*3 + 1 + 3*Byte(P^.Level>0) + Delta.X) and
                      (MP.X <= P^.Level*3 + 2 + 3*Byte(P^.Level>0) + Delta.X + Length(P^.Name)) then}
          begin
          if Event.Double and not PanelMode then
            begin
            ScrollBar^.SetValue(MP.Y+Delta.Y);
            Message(Owner, evCommand, cmOK, nil);
            end;
          CurPos := RepeatDelay;
          RepeatDelay := 0;
          MouseTracking := True;
          repeat
            MakeLocal(Event.Where, MP);
            if  (MP.X > 0) and (MP.X < Size.X) then
              ScrollBar^.SetValue(MP.Y+Delta.Y);
          until not MouseEvent(Event, evMouseAuto+evMouseMove);
          MouseTracking := False;
          SendLocated;
          RepeatDelay := CurPos;
          end;
        end;
      end;
    else
      Exit;
  end {case};
  CE;
  end { TTreeView.HandleCommand };

{ Палитра дерева:
1 Дерево (линии)
2 Нормальный узел
3  └─ выделенный (под курсором)
4 Текущий узел (каталог другой панели)
5  ├─ выделенный
6  └─ на пассивной панели дерева
7 Окно инфоpмации
}

procedure TTreeView.Draw;
  var
    I, J, K, NCol, CurPos, Idx: Integer;
    P: PNode;
    B: TDrawBuffer;
    C: Char;
    Levels: array[0..255] of Char;
    S, Q: String;
    C1, CC: Byte;
  begin
  if  (DrawDisabled) or (DC = nil) then
    Exit;
  FillChar(Levels, SizeOf(Levels), ' ');
  CurPos := ScrollBar^.Value;
  if DC^.Count <= Size.Y then
    Delta.Y := 0;
  if CurPos < Delta.Y then
    Delta.Y := CurPos;
  if CurPos >= Delta.Y+Size.Y then
    Delta.Y := CurPos-Size.Y+1;
  P := DC^.At(CurPos);
  if P^.Level*LevelTab+6+Length(P^.NodeName[uLfn])+Delta.X > Size.X then
    Delta.X := P^.Level*3+6+Length(P^.NodeName[uLfn])-Size.X;
  if P^.Level*LevelTab-4 < Delta.X then
    Delta.X := P^.Level*LevelTab-4;
  if Delta.X < 0 then
    Delta.X := 0;
  for I := 0 to Delta.Y-1 do
    begin
    P := DC^.At(I);
    if P^.NodeAttr and trLast = 0 then
      Levels[P^.Level] := '│';
    end;
  C1 := GetColor(1);
  for I := 1 to Size.Y do
    begin
    MoveChar(B, ' ', C1, 200);
    Idx := I+Delta.Y-1;
    if Idx < DC^.Count then
      begin
      P := DC^.At(Idx);
      if P^.NodeAttr and trLast = 0 then
        C := '├'
      else
        C := '└';
      if P^.Level = 0 then
        S := ''
      else
        begin
        S := C + '──── ';
        if  (P^.NodeAttr and trHasChildrens) <> 0 then
          begin
          if (P^.NodeAttr and trExpanded) <> 0 then
            S := C+'─[-] '
          else
            S := C+'─[+] '
          end;
        end;
      K := 1;
      if P^.Level > 0 then
        for J := 1 to P^.Level-1 do
          begin
          MoveChar(B[K], Levels[J], C1, 1);
          Inc(K, LevelTab);
          end;
      if (P^.NodeAttr and trLast = 0) then
        Levels[P^.Level] := '│'
      else
        Levels[P^.Level] := ' ';
      MoveStr(B[K], S, C1);

      { цвет имени }
      NCol := 2;
      if PanelMode and not (GetState(sfSelected) and Owner^.GetState(sfActive))
      then
         begin { на неактивной панели подсвечиваем только текущий }
         if P = CurNode then
           NCol := 6
         end
      else
        begin
        if P = SelNode then
          NCol := 3; // выделенный
        if P = CurNode then
          inc(NCol, 2); // текущий
        end;
      CC := GetColor(NCol);

      if (Idx = 0) and (Drive^.Panel <> nil) then {корень}
        begin
        Q := PFilePanelRoot(Drive^.Panel)^.DirectoryName;
        if PosChar(':', Q) > 2 then
          begin // что-то вроде  'RAR:TEMP.RAR\DOC'
          Q := Q + '\';
          SetLength(Q, PosChar('\', Q));
          end
        else
          Q := P^.NodeName[uLfn];
        end
      else
        Q := P^.NodeName[uLfn];
      if P = SelNode then
        begin
        MoveStr(B[K+Length(S)], Q, CC);
        if (QSPanel = @Self) then
          begin
          ShowCursor;
          NormalCursor;
          SetCursor(K+Length(S)+QSLastSuccessPos-1, I-1)
          end
        else
          HideCursor;
        end
      else
        MoveStr(B[K+Length(S)], Q, CC)
      end;
    WriteLine(0, I-1, Size.X, 1, B[Delta.X]);
    end;
  end { TTreeView.Draw };

procedure TDirCollection.FreeItem;
  begin
  end;

function TTreeView.FindPath(APath: string; var Node: PNode): Longint;
  var
    L, i: Longint;
    S: string;
    Step: string;
    P: PNode;
  label
    NextStep;
  begin
  Norm(APath);
  S := Drive^.RootPath;
  Norm(S);
  Result := 0;
  if S <> {!!Upstrg}(Root^.GetFullPath) then
    begin
    Node := nil;
    Exit;
    end;
  { корень совпадает, теперь шагаем вдоль пути }
  Node := Root;
  L := Length(S);
  while True do
    begin
    inc(Result, L);
    System.delete(APath, 1, L);
    if APath = '' then
      Exit;
    L := Pos('\', APath);
    Step := {!!UpStrg}(Copy(APath, 1, L-1)); // без '\' на конце
    for i := 0 to Node^.Childs^.Count-1 do
      begin
      P := Node^.Childs^.At(i);
      if {!!UpStrg}(P^.NodeName[uLFN]) = Step then
        goto NextStep;
      end;
    Exit;
  NextStep:
    Node := P;
    end;
  end {TTreeView.SearchPath};

procedure TTreeView.GotoPath(var APath: string);
  var
    i: Integer;
  begin
  Norm(APath);
  DrawDisabled := True;
  FindPath(APath, SelNode);
  if SelNode <> nil then
    SelNode^.ReadBranch(APath, rmLevel)
  else
    begin
    CurNode := nil;
    Root^.Free;
    Root := nil;
    ReadTree(APath, False);
    end;
  FindPath(APath, SelNode);
  NodeToDC(Root, '');
  ScrollBar^.SetValue(SelNode^.Number);
  DrawDisabled := False;
  Draw;
  end;

procedure TTreeView.SetState;
  begin
  inherited SetState(AState, Enable);
  if  (AState and sfFocused <> 0) and not Enable then
    if PanelMode then
      DisableCommands([cmCopyFiles, cmPanelErase, cmMoveFiles,
         cmPanelMkDir,
        cmChangeDrive, cmPanelReread]);
  if AState and (sfFocused or sfActive or sfSelected) <> 0 then
    if Owner^.GetState(sfActive) and GetState(sfSelected) then
      begin
      if ScrollBar <> nil then
        ScrollBar^.Show;
      if PanelMode then
        EnableCommands([cmCopyFiles, cmPanelErase, cmMoveFiles,
           cmPanelReread,
          cmPanelMkDir, cmChangeDrive]);
      {EventMask := EventMask or evBroadcast;}
      DrawView
      end
    else
      begin
      if ScrollBar <> nil then
        ScrollBar^.Hide;
      {EventMask := EventMask and (not evBroadcast);}
      DrawView
      end;
  end { TTreeView.SetState };

procedure THTreeView.HandleEvent;
  procedure CE;
    begin
    ClearEvent(Event)
    end;

  procedure CopyDir;
    var
      FC: PFilesCollection;
      D: PNode;
      S: String;
      OldDir, NewDir: String;
    begin
    lGetDir(0, OldDir);
    GetData(NewDir);
    lChDir(MakeNormName(NewDir, '..'));
    CE;
    if ScrollBar^.Value < 1 then
      Exit;
    FC := MkFcFromDirRec(SelNode);
    if ReflectCopyDirection
    then
      RevertBar := (Message(Desktop, evBroadcast, cmIsRightPanel, @Self)
           <> nil)
    else
      RevertBar := False;
    CopyFiles(FC, @Self, Event.Command = cmMoveFiles, 0);
    Dispose(FC, Done);
    FC := nil;
    lChDir(OldDir);
    GlobalMessage(evCommand, cmRereadInfo, nil);
    end { CopyDir };

  begin { THTreeView.HandleEvent }
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      case Event.Command of
        cmMoveFiles, cmCopyFiles:
          CopyDir;
      end {case};
  end {case};
  end { THTreeView.HandleEvent };

procedure THTreeView.ChangeBounds;
  var
    R: TRect;
  begin
  Dec(Bounds.B.Y, 2);
  SetBounds(Bounds);
  R := Bounds;
  R.A.Y := R.B.Y;
  Inc(R.B.Y, 2);
  if Info <> nil then
    Info^.SetBounds(R);
  if ScrollBar <> nil then
    begin
    R := Bounds;
    R.A.X := R.B.X;
    Inc(R.B.X);
    ScrollBar^.SetBounds(R)
    end
  end;

{ AK155 10.06.05. Подвал надо прятать и показывать вместе с панелью }
procedure THTreeView.SetState(AState: Word; Enable: Boolean);
  begin
  inherited SetState(AState, Enable);
  if (AState and sfFocused <> 0) and (not Enable) then
    CancelSearch;
  if (AState and sfVisible <> 0) and (Info <> nil) then
     Info^.SetState(sfVisible, Enable);
  end;

{ AK155 26-01-2003. Раньше Info не освобождалось вообще }
destructor THTreeView.Done;
  begin
  if Info <> nil then
    Info^.Free;
  inherited Done;
  end;

{-DataCompBoy-}
function CreateDirInheritance;
  var
    I, J: Integer;
    SR: lSearchRec;
    M: String;
  begin
  Result := 0;
  ClrIO;
  S := lFExpand(S);
  MakeSlash(S);
  if Abort then
    Exit;
  I := GetRootStart(S);
  if I > Length(S) then
    Exit;
  while I < Length(S) do
    begin
    J := I;  // указывает на '\' перед началом имени на очередном уровне
    repeat
      Inc(I);
    until (S[I] = '\');
     // I указывает на первый символ за концом имени
    M := Copy(S, 1, I-1); // полный путь очередного уровня
    ClrIO;
    lFindFirst(M, AnyFileDir, SR); {JO}
    lFindClose(SR);
    if Abort then
      Exit;
    if DosError <> 0 then
      begin // каталог не найден, надо создавать
      if Confirm and (Confirms and cfCreateSubdir <> 0) then
        begin
        if  (MessageBox(GetString(dlQueryCreateDir)+Cut(S, 40)+' ?',
               nil, mfYesNoConfirm) <> cmYes)
        then
          Exit;
        end;
      ClrIO;
      CheckMkDir(M);
      if Abort then
        Exit;
      // Каталог создан успешно
      if Result = 0 then // это был первый созданный каталог
        Result := J-1;
      end;
    end;
  end { CreateDirInheritance };
{-DataCompBoy-}

constructor TNode.Init(AParent: PNode; ATree: PTreeView; const Name: String);
  begin
  inherited Init;
  Parent := AParent;
  Tree := ATree;
  New(Childs, Init(10, 10));
  CopyShortString(Name, NodeName[True]);
  Size := -1;
  end;

destructor TNode.Done;
  begin
  Dispose(Childs, Done);
  if Tree^.CurNode = @Self then
    Tree^.CurNode := Parent;
  if Tree^.SelNode = @Self then
    Tree^.SelNode := Parent;
  Inherited Done;
  end;

function TNode.GetFullPath: string;
  var
    D: String;
    P: PNode;
  begin
  Result := '';
  P := @Self;
  repeat
    D := P^.NodeName[uLfn];
    MakeSlash(D);
    Result := D + Result;
    P := P^.Parent;
  until P = nil;
  if Result = '' then
    Result := '\';
  end;

function TChilds.Compare(Key1, Key2: Pointer): Integer;
  var
    D1: PNode absolute Key1;
    D2: PNode absolute Key2;
    Str1, Str2: string;
  begin
  Str1 := {!!UpStrg}(D1.NodeName[uLfn]);
  Str2 := {!!UpStrg}(D2.NodeName[uLfn]);
  if Str1 < Str2 then
    Result := -1
  else if Str1 = Str2 then
    Result := 0
  else
    Result := 1;
  end;

procedure TChilds.FreeItem(Item: Pointer);
  begin
  Dispose(PNode(Item), Done);
  end;

end.
