Program PMLife;
{$PMTYPE PM}
{$X+ }
(* A test program for high-speed life game defined by Conway.
   Definition :

    For cell A, the neighbouring cells are cells 1..8

        1 2 3
        4 A 5
        6 7 8

    If A is alive, it remains alive in case of total number of living cells
    in its neighbourhood is 2 or 3 else A shall be dead in the next stage.
    If A is branc (a dead cell is thought as a blanc one) and 3 neighbouring
    cell are alive, then A become alive in the next stage.

    This program employ invented algorythm basically introduced in
      'Programming Seminor' by K. Kakei et. al. 1985.

    vers 0.1 : 10, Dec., 1990   life.pas
                Original
    vers 0.2 : 12, Dec., 1990   life2.pas
                Life Editor
    vers 0.21: 14, Dec., 1990   life21.pas
                Preperation for colour version.
                * Cell status bit assignment is changed.
                * Display status is stored as colour code (bit 6-4)
                * Current registration status is set at bit 7 as negative
                        logic (1-not registered in current stage )
    vers 0.22: 19, Dec., 1990   life22.pas
                Run Faster.  faster than vers 0.2x
                * Linear access for cell field.
                * Field size/assignments are changed.
    vers 0.23: , Dec., 1990   life23.pas
                Faster than vers 0.22.
                Colour change.
                Cell pattern can be stroed in a text file.
         0.231  TP6, no colour
         0.232  mouse
         0.233  13, Feb., 1993 LIFE0233.PAS
                Editor Store/Recall
         0.240  LIFE0240.PAS
                Two Tribe
         0.241  LIFE0241.PAS
                bug fix (X, Y display)
         0.242  LIFE0242.PAS
                zooming
    versions above are for PC9801
    followings are for OS/2 PM

    vers 0.3 :  Ported to OS/2 PM
                  PMLIFE00, 01, 02, and 03    March..April, 1995
    vers 0.4
    vers 0.5
    vers 0.6 :  Revised for Virtual Pascal for OS/2
    vers 0.7 :  Planer 32bit!
    vers 0.8 :  Large field
    vers 0.9 :  Small, Medium, Large field
    vers 1.0 :  Field size dialogue

*)

uses DOS, os2def, os2base, os2PMApi, strings, PMLCONST;
{$R PMLIFE10}
{$R-,S-,I-}
const
(* for game itself *)
(*  +----------------------+ 0   *)
(*  |                      |     *)
(*  ~   vers 0.22          ~     *)
(*  |                      |     *)
(*  +----------------------+ col_size+1 *)
  MaxXIndex       = 1023;
  MaxXIndexMinus1 = MaxXIndex - 1;
  MaxXIndexPlus1  = MaxXIndex + 1;
  MaxXIndexPlus2  = MaxXIndex + 2;
  MaxYIndex       = 1023;
  MaxYIndexMinus1 = MaxYIndex - 1;
  MaxYIndexPlus1  = MaxYIndex + 1;
  MaxYIndexPlus2  = MaxYIndex + 2;
  MaxLindex       = MaxXIndexPlus1 * MaxYIndexPlus1 - 1;
  MaxXIndexMedium       = 511;
  MaxXIndexMinus1Medium = MaxXIndexMedium - 1;
  MaxXIndexPlus1Medium  = MaxXIndexMedium + 1;
  MaxXIndexPlus2Medium  = MaxXIndexMedium + 2;
  MaxYIndexMedium       = 511;
  MaxYIndexMinus1Medium = MaxYIndexMedium - 1;
  MaxYIndexPlus1Medium  = MaxYIndexMedium + 1;
  MaxYIndexPlus2Medium  = MaxYIndexMedium + 2;
  MaxLindexMedium       = MaxXIndexPlus1Medium * MaxYIndexPlus1Medium - 1;
  MaxXIndexSmall       = 255;
  MaxXIndexMinus1Small = MaxXIndexSmall - 1;
  MaxXIndexPlus1Small  = MaxXIndexSmall + 1;
  MaxXIndexPlus2Small  = MaxXIndexSmall + 2;
  MaxYIndexSmall       = 255;
  MaxYIndexMinus1Small = MaxYIndexSmall - 1;
  MaxYIndexPlus1Small  = MaxYIndexSmall + 1;
  MaxYIndexPlus2Small  = MaxYIndexSmall + 2;
  MaxLindexSmall       = MaxXIndexPlus1Small * MaxYIndexPlus1Small - 1;
  MaxAlive      =10000;
  LiveMask      =   7;
  toLive        =   3;
  Colour1       = $80;
  ColourMask    = $80;
  notRegistered =   8;
  MaxAlive2     = MaxAlive div 2;
  EditFieldSize =  40;
  EditFieldSizePlus1 = EditFieldSize + 1;
  EditMaxAlive  =1000;
  CharHeight    = 24;
  MaxZoom       = 3;
  VersNum       = 'PMLIFE 1.0';
  ClassName     = 'LIFE';
  InfoName      = 'INFO';
  ININame       = 'PMLIFE.INI';

(* for PM control *)

(* For calculation thread *)
  StackSize    = 8192;
  WM_USER1     = WM_USER + 1;
  WM_USER2     = WM_USER + 2;
  WM_USER3     = WM_USER + 3;
  WM_USER4     = WM_USER + 4;

  fSwp         = SWP_ACTIVATE + SWP_SIZE + SWP_MOVE + SWP_SHOW;

type
  CellStatus   = byte;          (* bits |7654|3210|
                                        |    |    +----+
                                        |    |for count|
                                        |    ||
                                        |    |registered in current stage
                                        |    |
                                        |    +-----------+
                                        |for tribe count |
                                         |
                                         displayed
                                bit 3 is overrided safely, because the
                                count is always 1 to 8. bit 3 has no in-
                                formation.
                                This assignment is employed in vers 0.21
                                changed in vers 0.24 *)
  ColNum        = 1..MaxXIndex;      (* vers 0.22 *)
  ColNumPlus1   = 0..MaxXIndexPlus1; (* vers 0.22 *)
  RowNum        = 1..MaxYIndex;      (* vers 0.22 *)
  RowNumPlus1   = 0..MaxYIndexPlus1; (* vers 0.22 *)
  Xindex        = 0..MaxXindex;
  Yindex        = 0..MaxYindex;
  Lindex        = 0..MaxLindex;
  BioRow        = array[Xindex] of CellStatus;   (* vers 0.22 *)
  BioField      = array[Yindex] of BioRow;       (* vers 0.22 *)
  BioFieldLinear= array[Lindex] of CellStatus;   (* vers 0.22 *)
  ColNumMedium        = 1..MaxXIndexMedium;      (* vers 0.9 *)
  ColNumPlus1Medium   = 0..MaxXIndexPlus1Medium; (* vers 0.9 *)
  RowNumMedium        = 1..MaxYIndexMedium;      (* vers 0.9 *)
  RowNumPlus1Medium   = 0..MaxYIndexPlus1Medium; (* vers 0.9 *)
  XindexMedium        = 0..MaxXindexMedium;
  YindexMedium        = 0..MaxYindexMedium;
  LindexMedium        = 0..MaxLindexMedium;
  BioRowMedium        = array[XindexMedium] of CellStatus;   (* vers 0.22 *)
  BioFieldMedium      = array[YindexMedium] of BioRowMedium; (* vers 0.22 *)
  BioFieldLinearMedium= array[LindexMedium] of CellStatus;   (* vers 0.22 *)
  ColNumSmall        = 1..MaxXIndexSmall;      (* vers 0.9 *)
  ColNumPlus1Small   = 0..MaxXIndexPlus1Small; (* vers 0.9 *)
  RowNumSmall        = 1..MaxYIndexSmall;      (* vers 0.9 *)
  RowNumPlus1Small   = 0..MaxYIndexPlus1Small; (* vers 0.9 *)
  XindexSmall        = 0..MaxXindexSmall;
  YindexSmall        = 0..MaxYindexSmall;
  LindexSmall        = 0..MaxLindexSmall;
  BioRowSmall        = array[XindexSmall] of CellStatus;   (* vers 0.22 *)
  BioFieldSmall      = array[YindexSmall] of BioRowSmall; (* vers 0.22 *)
  BioFieldLinearSmall= array[LindexSmall] of CellStatus;   (* vers 0.22 *)
  BioFieldCmp   = record                                (* vers 0.22 *)
    case integer of
      0 : (linear  : BioFieldLinear);
      1 : (matrix  : BioField);
      2 : (linearm : BioFieldLinearMedium);
      3 : (matrixm : BioFieldMedium);
      4 : (linears : BioFieldLinearSmall);
      5 : (matrixs : BioFieldSmall)
    end;
  pBioFieldCmp  = ^BioFieldCmp;
  RunningModes  = (LargeField,  LargeFieldWrap,
                   MediumField, MediumFieldWrap,
                   SmallField,  SmallFieldWrap);
  coordinate    = record
    column      : ColNumPlus1;                  (* x *)
    row         : RowNumPlus1                   (* y *)
  end;
  BioNumber     = 1..MaxAlive;
  BioNumberPlus1= 0..MaxAlive+1;
  AliveArray    = array[BioNumber] of coordinate;
  BioStatus     = record
    alive       : AliveArray;
    CellNumber1,                    (* forward scan *)
    CellNumber2 : BioNumberPlus1;   (* reverse scan *)
    generation  : word
  end;
  tribes        = (none, Tribe1, Tribe2);
  BioNumber2    = 1..MaxAlive2;
  BioNumber2Plus1 = 0..MaxAlive2+1;
  AliveArray2   = array[BioNumber2] of coordinate;
  BioStatus2    = record
    alive1,                         (* Tribe1 *)
    alive2      : AliveArray2;      (* Tribe2 *)
    CellNumber11,                   (* Tribe1 forward scan *)
    CellNumber21,                   (* Tribe1 reverse scan *)
    CellNumber12,                   (* Tribe2 forward scan *)
    CellNumber22 : BioNumberPlus1;  (* Tribe2 reverse scan *)
    generation : word
  end;
  BioStat       = record
    case boolean of
      false     : (for1 : BioStatus);
      true      : (for2 : BioStatus2)
    end;
  EditAlive     = array [1..EditMaxAlive] of coordinate;
  EditCells     = record
    Ealive      : EditAlive;
    CellNumber  : integer;
    initColumn,
    initRow     : word;
    n           : byte
  end;
  pEditCells    = ^EditCells;

  dialogdata    = record
    cb          : word; (* size of dialogdata *)
    posx0, posy0,
    posx1, posy1: integer;
    delayval    : word;
    prtyidle    : boolean;
    RunMode     : RunningModes;
    forecolour,
    backcolour  : byte
  end;
  pdialogdata   = ^dialogdata;
  char13        = array [0..13] of char;
  char255       = array [0..255] of char;
  pchar255      = ^char255;
  str13         = string[13];
  str30         = string[30];
  lifeFile      = record
    fname       : str13;
    comment     : str30;
    initx, inity: word
  end;
  lifeFileAry   = array [1..100] of lifeFile;
  filedlgdt     = record
    cb          : word;
    filenm      : pchar255;
    hmirror,
    vmirror     : boolean;
    rot         : byte;
    ofsx, ofsy  : word
  end;
  pfiledlgdt    = ^filedlgdt;

var
  status        : BioStat;             (* globally defined bio field status *)

  flst          : lifeFileAry;
  fnum          : integer;

(* PM control *)
  myhab         : HAB;
  myhmq         : HMQ;
  hwndFrame,                           (* Frame window HWND *)
  hwndClient,                          (* Client window HWND *)
  hwndHscroll,                         (* Horiz Scrollbar HWND *)
  hwndVscroll,                         (* Vert Scrollbar HWND *)
  hwndInfo      : HWND;                (* Sub HWND for Cell Number *)
  myqmsg        : QMSG;
  hpsInit       : HPS;                 (* Main - Life Field *)
  idThread      : TID;                 (* Calculation Thread ID *)
  UsePS         : HMTX;
  ctlData       : ULONG;
  ScrnCleared,                         (* Cells must be redraw *)
  continue,                            (* running game *)
  runcalc,
  inited        : boolean;             (* Initial pattern loaded *)
  MaxX          : XIndex;
  MaxY          : YIndex;
  Xscrn, Yscrn,                        (* Logical screen size *)
  Xsize, Ysize  : word;                (* Phisical screen size *)
  Xmove, Ymove  : integer;             (* size of hidden area *)
  dx, dy        : integer;             (* display offset *)
  ForeColour,
  BackColour    : ULONG;
  colour        : array [IDD_FOREBLACK - IDD_COLOUR ..
                         IDD_BACKGREY - IDD_COLOUR] of ULONG;
  zoom          : byte;                (* Zoom factor *)
  dlgorg        : dialogdata;

function LoUShort(w : ULONG) : UShort; inline;
begin
  LoUShort := SmallWord( w )
end;

function HiUShort(w : ULONG) : UShort; inline;
begin
  HiUShort := SmallWord( w shr 16 )
end;

procedure ReadCellFromText(SourceName : string; var cells : EditCells);
(* read cell pattern from a text file.
  -- text file format --         example
[pattern 1st line]              |-aaa---aaa---
[pattern 2nd line]              |a---a-a---a--
[pattern 3rd line]              |-aaa---aaa---
        ...                     |---aaa---aaa-
In <pattern>, the following     |--a---a-a---a
charactors are available.       |---aaa---aaa-
 cell     exists : <a>
 cell not exist  : <space> or <-> or <_>
 any other charactor is neglected and skipped.
Every line must be terminated by EOLN charactor (CR-LF) and cannot
exceed 249 charactors.
Number of pattern must be less than 200 lines.
Number of cells must be less than 4000.
*)
const
  cExist     = 'a';
var
  source     : text;
  SourceLine : string;
  xp         : ColNum;
  yp         : RowNum;
  i          : integer;
begin
  if SourceName <> '' then
    with cells do begin
      assign(source, SourceName);
      reset(source);
      readln(source, SourceLine);
      readln(source, SourceLine);
      n  := 0;
      yp := 1;
      CellNumber := 0;
      SourceLine := '';
      while not eof(source) and (SourceLine<>'BEGIN') do
        readln(source, SourceLine);
      while not eof(source) do begin
        readln(source, SourceLine);
        xp := 1;
        for i := 1 to length(SourceLine) do
          case SourceLine[i] of
            cExist :
                with cells do begin
                  inc(CellNumber);
                  with Ealive[CellNumber] do begin
                    column := xp;
                    row    := yp;
                    inc(xp)
                  end
                end;
            ' ', '-', '_' : inc(xp)
          end;
        if n < length(SourceLine) then n := length(SourceLine);
        inc(yp)
      end;
      close(source);
      dec(yp);
      if n < yp then n := yp
    end
end;

procedure RotateField(var ecl : EditCells; r : integer);
var i, j, c : word;
begin
  with ecl do
    for i := 1 to r do
      for j := 1 to CellNumber do
        with Ealive[j] do begin
          c      := column;
          column := row;
          row    := succ(n - c)
        end
end;

procedure ReverseFieldH(var ecl : EditCells);
var i : word;
begin
  with ecl do
    for i := 1 to CellNumber do
      with Ealive[i] do column := succ(n - column)
end;

procedure ReverseFieldV(var ecl : EditCells);
var i : word;
begin
  with ecl do
    for i := 1 to CellNumber do
      with Ealive[i] do row := succ(n - row)
end;

procedure SetViewParam(magx, magy, ofsx, ofsy : integer);
var mat : MATRIXLF;
begin
  fillchar(mat, sizeof(mat), 0);
  with mat do begin
    fxM11 := MAKEFIXED(magx, 0);
    fxM22 := MAKEFIXED(magy, 0);
    lM31  := ofsx;
    lM32  := ofsy + CharHeight;
    lM33  := 1
  end;
  GpiSetDefaultViewMatrix(hpsInit, 9, mat, TRANSFORM_REPLACE)
end;

procedure DrawCell(ix : ColNumPlus1; iy : RowNumPlus1; c : integer);
var ptl : POINTL;
begin
  with ptl do begin
    x := ix;
    y := iy;
    GpiSetColor(hpsInit, c);
    GpiSetPel(hpsInit, ptl)
  end
end;

procedure DispField;
var i : BioNumberPlus1;
begin
  with status.for1 do
    if odd(generation) then begin
      WinPostMsg(hwndClient, WM_USER3,
                 succ(MaxAlive - CellNumber2), generation);
      for i := CellNumber2 to MaxAlive do
        with alive[i] do DrawCell(column, row, ForeColour)
    end else begin
      WinPostMsg(hwndClient, WM_USER3, CellNumber1, generation);
      for i := CellNumber1 downto 1 do
        with alive[i] do DrawCell(column, row, ForeColour)
    end;
  ScrnCleared := false
end;

procedure InitLifeField(var cell : EditCells; init : boolean);
var i : integer;
    mx,
    my: word;
begin
  mx := pred(MaxX);
  my := pred(MaxY);
  with status.for1, cell do begin
    if init then begin
      CellNumber1 := 0;
      generation := 0
    end;
    for i := 1 to CellNumber do begin (* generation is even *)
      inc(CellNumber1);
      with alive[CellNumber1] do begin
        column := (Ealive[i].column + initColumn + MaxX) and mx;
        row    := (initRow - Ealive[i].row + MaxY * 2)   and my
      end
    end
  end
end;

procedure LimitLifeField;
var i      : BioNumberPlus1;
    ii     : integer;
    mx, my,
    x,  y  : word;
begin
  mx := pred(MaxX);
  my := pred(MaxY);
  ii := 0;
  with status.for1 do begin
    for i := 1 to CellNumber1 do begin
      x := alive[i].column;
      y := alive[i].row;
      if odd(ord(dlgorg.RunMode)) then begin
        inc(ii);
        alive[ii].column := x and mx;
        alive[ii].row    := y and my
      end else if (x <= mx) and (y <= my) then begin
        inc(ii);
        alive[ii].column := x;
        alive[ii].row    := y
      end
    end;
    CellNumber1 := ii
  end
end;

procedure SetMaxXY;
begin
  MaxX := MaxXIndexPlus1 shr (ord(dlgorg.RunMode) div 2);
  MaxY := MaxYIndexPlus1 shr (ord(dlgorg.RunMode) div 2)
end;

procedure MakeFileList(s : string;
                       var flist : lifeFileAry; var n : integer);
var sr : SearchRec;
    f  : text;
begin
  n  := 0;
  FindFirst(s, ReadOnly + Archive, sr);
  while DOS.DosError = 0 do begin
    inc(n);
    with flist[n] do begin
      fname := sr.Name;
      assign(f, fname);
      reset(f);
      readln(f, comment);
      readln(f, initx, inity);
      close(f)
    end;
    FindNext(sr)
  end;
  FindClose(sr)
end;

procedure MyMessage(h : HWND; title, mes : string);
begin
  title := title + chr(0);
  mes   := mes + chr(0);
  WinMessageBox(HWND_DESKTOP, h, @mes[1], @title[1], 0, MB_OK)
end;

procedure MyNumMessage(h : HWND; n : integer);
var ss: string[20];
begin
  str(n, ss);
  MyMessage(h, 'Num Message', ss)
end;

procedure LoadSettings(h : HWND; fn : string);
type
    rm = record
      case boolean of
        false : (n : byte);
        true  : (m : RunningModes)
      end;
var t : text;
    x0, y0, x1, y1, d, d2, f, b, z : integer;
    r : rm;
begin
  if fn<>'' then begin
    assign(t, fn);
    reset(t);
    if IOResult<>0 then begin
      if h<>NULLHANDLE then MyMessage(h, '', 'File Not Found')
    end else begin
      readln(t, x0, y0, x1, y1);  (* Window Position *)
      readln(t, d, d2);           (* d - 1 : idol, 0 : normal, delay *)
      readln(t, r.n);             (* ord(RunMode) *)
      readln(t, f, b);            (* forecolour, backcolour *)
      readln(t, z);
      if IOResult = 0 then begin
        with dlgorg do begin
          posx0 := x0;
          posy0 := y0;
          posx1 := x1;
          posy1 := y1;
          prtyidle := d > 0;
          delayval := d2;
          RunMode  := r.m;
          forecolour := f;
          backcolour := b
        end;
        ForeColour := colour[dlgorg.forecolour];
        BackColour := colour[dlgorg.backcolour];
        zoom       := z
      end;
      close(t)
    end
  end
end;

procedure SaveSettings(h : HWND; fn : string);
var t     : text;
    myswp : SWP;
begin
  WinQueryWindowPos(h, myswp);
  if fn<>'' then begin
    assign(t, fn);
    rewrite(t);
    with dlgorg, myswp do begin
      writeln(t, x, ' ', y, ' ', cx, ' ', cy);
      writeln(t, ord(prtyidle), ' ', delayval);
      writeln(t, ord(RunMode));
      writeln(t, forecolour, ' ', backcolour);
      writeln(t, zoom)
    end;
    close(t)
  end
end;

procedure InitVar;
var i : integer;
begin
  ctlData := FCF_TITLEBAR + FCF_SYSMENU    + FCF_SIZEBORDER +
             FCF_MINMAX   + FCF_HORZSCROLL + FCF_VERTSCROLL +
             FCF_TASKLIST + FCF_MENU       + FCF_ACCELTABLE +
             FCF_ICON;
  with dlgorg do begin
    cb       := sizeof(dlgorg);
    posx0 := 0;
    posy0 := 0;
    posx1 := 550;
    posy1 := 450;
    delayval := 20;
    prtyidle := true;
    RunMode  := SmallFieldWrap;
    forecolour := IDD_FOREWHITE - IDD_COLOUR;
    backcolour := IDD_BACKBLACK - IDD_COLOUR
  end;
  colour[IDD_FOREBLACK  - IDD_COLOUR] := CLR_BLACK;
  colour[IDD_FOREYELLOW - IDD_COLOUR] := CLR_YELLOW;
  colour[IDD_FORECYAN   - IDD_COLOUR] := CLR_CYAN;
  colour[IDD_FORERED    - IDD_COLOUR] := CLR_RED;
  colour[IDD_FOREWHITE  - IDD_COLOUR] := CLR_WHITE;
  colour[IDD_FOREGREY   - IDD_COLOUR] := CLR_PALEGRAY;
  colour[IDD_BACKBLACK  - IDD_COLOUR] := CLR_BLACK;
  colour[IDD_BACKYELLOW - IDD_COLOUR] := CLR_YELLOW;
  colour[IDD_BACKBLUE   - IDD_COLOUR] := CLR_BLUE;
  colour[IDD_BACKMAGENTA- IDD_COLOUR] := CLR_DARKPINK;
  colour[IDD_BACKWHITE  - IDD_COLOUR] := CLR_WHITE;
  colour[IDD_BACKGREY   - IDD_COLOUR] := CLR_DARKGRAY;
  ForeColour    := CLR_WHITE;
  BackColour    := CLR_BLACK;
  zoom          := 1;
  LoadSettings(NULLHANDLE, ININame);
  SetMaxXY;
  ScrnCleared   := true;
  dx            := 0;
  dy            := 0
end;


procedure InitialisePS(h : HWND; var hp : HPS);
var s  : SIZEL;
    hd : HDC;
begin
  hd := WinOpenWindowDC(h);
  s.cx := 0;
  s.cy := 0;
  hp := GpiCreatePS(myhab, hd, s,
                    PU_PELS + GPIF_DEFAULT + GPIT_MICRO + GPIA_ASSOC)
end;

procedure SetEntryBoxVal(h : HWND; id : word; d : integer);
(* set numeric value of entry box.
    h : HWND of the Dialog Box
    id: id of the Entry Field
    d : number to set
*)
var s : string[4];
    rc: boolean;
begin
  str(d, s);
  s := s + chr(0);
  rc := WinSetDlgItemText(h, id, @s[1])
end;

(* Procedures / Functions for running LIFE GAME *)

function CalcMain(dummy : pointer) : longint;
(* Main Routine for High-Speed calculation *)
const
  Inited    = colour1 or notRegistered or 1;
var
  localHAB : HAB;
  field    : pBioFieldCmp;
  memsz    : ULONG;
  delayval : word;
  RunMode  : RunningModes;

  procedure InitField; (* called only in the case of generation is even *)
  var i : BioNumberPlus1;
  begin
    with status.for1, field^ do begin
      case RunMode of
        LargeField, LargeFieldWrap : begin
            fillchar(field^, sizeof(BioField), 0);
            for i := 1 to CellNumber1 do
              with alive[i] do matrix[row, column] := colour1
                                                  (* displayed and set now *)
          end;
        MediumField, MediumFieldWrap : begin
            fillchar(field^, sizeof(BioFieldMedium), 0);
            for i := 1 to CellNumber1 do
              with alive[i] do matrixm[row, column] := colour1
                                                  (* displayed and set now *)
          end;
        SmallField, SmallFieldWrap : begin
            fillchar(field^, sizeof(BioFieldSmall), 0);
            for i := 1 to CellNumber1 do
              with alive[i] do matrixs[row, column] := colour1
                                                  (* displayed and set now *)
          end
      end
    end
  end;  { of InitField }

  procedure SetSentinel;
  var ii : Yindex;
  begin
    with field^ do begin
      fillchar(matrix[0], sizeof(BioRow), notRegistered);
      for ii := 1 to MaxYIndexMinus1 do begin
        matrix[ii, 0]         := notRegistered;
        matrix[ii, MaxXIndex] := notRegistered
      end;
      fillchar(matrix[MaxYIndex], sizeof(BioRow), notRegistered)
    end
  end;

  procedure SetSentinelMedium;
  var ii : Yindex;
  begin
    with field^ do begin
      fillchar(matrixm[0], sizeof(BioRowMedium), notRegistered);
      for ii := 1 to MaxYIndexMinus1Medium do begin
        matrixm[ii, 0]         := notRegistered;
        matrixm[ii, MaxXIndexMedium] := notRegistered
      end;
      fillchar(matrixm[MaxYIndexMedium], sizeof(BioRowMedium), notRegistered)
    end
  end;

  procedure SetSentinelSmall;
  var ii : Yindex;
  begin
    with field^ do begin
      fillchar(matrixs[0], sizeof(BioRowSmall), notRegistered);
      for ii := 1 to MaxYIndexMinus1Small do begin
        matrixs[ii, 0]         := notRegistered;
        matrixs[ii, MaxXIndexSmall] := notRegistered
      end;
      fillchar(matrixs[MaxYIndexSmall], sizeof(BioRowSmall), notRegistered)
    end
  end;

  procedure SeedField(var f : BioFieldLinear; p : Lindex);
  begin
    inc(f[p - MaxXIndexPlus2 ]); (* [pred(row), pred(column)] *)
    inc(f[p - MaxXIndexPlus1 ]); (* [pred(row), column      ] *)
    inc(f[p - MaxXIndex      ]); (* [pred(row), succ(column)] *)
    inc(f[pred(p)]);             (* [row  , pred(column)] *)
    inc(f[succ(p)]);             (* [row  , succ(column)] *)
    inc(f[p + MaxXIndex      ]); (* [succ(row), pred(column)] *)
    inc(f[p + MaxXIndexPlus1 ]); (* [succ(row), column      ] *)
    inc(f[p + MaxXIndexPlus2 ])  (* [succ(row), succ(column)] *)
  end;

  procedure SeedFieldWrap(var f : BioField; x : XIndex; y : YIndex);
  var x0, x1, y0, y1 : word;
  begin
    x0 := (x + MaxXIndex)       and MaxXIndex;
    x1 := (x + MaxXIndexPlus2)  and MaxXIndex;
    y0 := (y + MaxYIndex)       and MaxYIndex;
    y1 := (y + MaxYIndexPlus2)  and MaxYIndex;
    inc(f[y0, x0]); (* [pred(row), pred(column)] *)
    inc(f[y0, x ]); (* [pred(row), column      ] *)
    inc(f[y0, x1]); (* [pred(row), succ(column)] *)
    inc(f[y,  x0]); (* [row  , pred(column)] *)
    inc(f[y,  x1]); (* [row  , succ(column)] *)
    inc(f[y1, x0]); (* [succ(row), pred(column)] *)
    inc(f[y1, x ]); (* [succ(row), column      ] *)
    inc(f[y1, x1])  (* [succ(row), succ(column)] *)
  end;

  procedure SeedFieldMedium(var f : BioFieldLinearMedium; p : Lindex);
  begin
    inc(f[p - MaxXIndexPlus2Medium ]); (* [pred(row), pred(column)] *)
    inc(f[p - MaxXIndexPlus1Medium ]); (* [pred(row), column      ] *)
    inc(f[p - MaxXIndexMedium      ]); (* [pred(row), succ(column)] *)
    inc(f[pred(p)]);                   (* [row  , pred(column)] *)
    inc(f[succ(p)]);                   (* [row  , succ(column)] *)
    inc(f[p + MaxXIndexMedium      ]); (* [succ(row), pred(column)] *)
    inc(f[p + MaxXIndexPlus1Medium ]); (* [succ(row), column      ] *)
    inc(f[p + MaxXIndexPlus2Medium ])  (* [succ(row), succ(column)] *)
  end;

  procedure SeedFieldWrapMedium(var f : BioFieldMedium;
                                x : XIndex; y : YIndex);
  var x0, x1, y0, y1 : word;
  begin
    x0 := (x + MaxXIndexMedium)       and MaxXIndexMedium;
    x1 := (x + MaxXIndexPlus2Medium)  and MaxXIndexMedium;
    y0 := (y + MaxYIndexMedium)       and MaxYIndexMedium;
    y1 := (y + MaxYIndexPlus2Medium)  and MaxYIndexMedium;
    inc(f[y0, x0]); (* [pred(row), pred(column)] *)
    inc(f[y0, x ]); (* [pred(row), column      ] *)
    inc(f[y0, x1]); (* [pred(row), succ(column)] *)
    inc(f[y , x0]); (* [row  , pred(column)] *)
    inc(f[y,  x1]); (* [row  , succ(column)] *)
    inc(f[y1, x0]); (* [succ(row), pred(column)] *)
    inc(f[y1, x ]); (* [succ(row), column      ] *)
    inc(f[y1, x1])  (* [succ(row), succ(column)] *)
  end;

  procedure SeedFieldSmall(var f : BioFieldLinearSmall; p : Lindex);
  begin
    inc(f[p - MaxXIndexPlus2Small ]); (* [pred(row), pred(column)] *)
    inc(f[p - MaxXIndexPlus1Small ]); (* [pred(row), column      ] *)
    inc(f[p - MaxXIndexSmall      ]); (* [pred(row), succ(column)] *)
    inc(f[pred(p)]);                  (* [row  , pred(column)] *)
    inc(f[succ(p)]);                  (* [row  , succ(column)] *)
    inc(f[p + MaxXIndexSmall      ]); (* [succ(row), pred(column)] *)
    inc(f[p + MaxXIndexPlus1Small ]); (* [succ(row), column      ] *)
    inc(f[p + MaxXIndexPlus2Small ])  (* [succ(row), succ(column)] *)
  end;

  procedure SeedFieldWrapSmall(var f : BioFieldSmall;
                               x : XIndex; y : YIndex);
  var x0, x1, y0, y1 : word;
  begin
    x0 := (x + MaxXIndexSmall)       and MaxXIndexSmall;
    x1 := (x + MaxXIndexPlus2Small)  and MaxXIndexSmall;
    y0 := (y + MaxYIndexSmall)       and MaxYIndexSmall;
    y1 := (y + MaxYIndexPlus2Small)  and MaxYIndexSmall;
    inc(f[y0, x0]); (* [pred(row), pred(column)] *)
    inc(f[y0, x ]); (* [pred(row), column      ] *)
    inc(f[y0, x1]); (* [pred(row), succ(column)] *)
    inc(f[y , x0]); (* [row  , pred(column)] *)
    inc(f[y,  x1]);             (* [row  , succ(column)] *)
    inc(f[y1, x0]); (* [succ(row), pred(column)] *)
    inc(f[y1, x ]); (* [succ(row), column      ] *)
    inc(f[y1, x1])  (* [succ(row), succ(column)] *)
  end;

  procedure ScanStatus;
   (* scans alive array and seeds on field *)
  var
    i : BioNumber;
    istart, iend : BioNumberPlus1;

  begin
    with status.for1 do begin
      if odd(generation) then begin
        istart := CellNumber2;
        iend   := MaxAlive
      end else begin
        istart := 1;
        iend   := CellNumber1
      end;
      with field^ do
        case RunMode of
          LargeField : begin
              for i := istart to iend do
                with alive[i] do
                  SeedField(linear, row * MaxXIndexPlus1 + column);
              for i := istart to iend do
                with alive[i] do
                  matrix[row, column] :=
                    (matrix[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end;
          LargeFieldWrap : begin
              for i := istart to iend do
                with alive[i] do
                  SeedFieldWrap(matrix, column, row);
              for i := istart to iend do
                with alive[i] do
                  matrix[row, column] :=
                    (matrix[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end;
          MediumField : begin
              for i := istart to iend do
                with alive[i] do
                  SeedFieldMedium(linearm,
                                  row * MaxXIndexPlus1Medium + column);
              for i := istart to iend do
                with alive[i] do
                  matrixm[row, column] :=
                    (matrixm[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end;
          MediumFieldWrap : begin
              for i := istart to iend do
                with alive[i] do
                  SeedFieldWrapMedium(matrixm, column, row);
              for i := istart to iend do
                with alive[i] do
                  matrixm[row, column] :=
                    (matrixm[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end;
          SmallField : begin
              for i := istart to iend do
                with alive[i] do
                  SeedFieldSmall(linears,
                                 row * MaxXIndexPlus1Small + column);
              for i := istart to iend do
                with alive[i] do
                  matrixs[row, column] :=
                    (matrixs[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end;
          SmallFieldWrap : begin
              for i := istart to iend do
                with alive[i] do
                  SeedFieldWrapSmall(matrixs, column, row);
              for i := istart to iend do
                with alive[i] do
                  matrixs[row, column] :=
                    (matrixs[row, column] and LiveMask ) or inited
                                                (* vers 0.24 *)
            end  { SmallFieldWrap }
        end  { case }
    end  { with }
  end;  { of CalcMain.ScanStatus }

  procedure CheckField;
  var
    i         : BioNumberPlus1;
    CurrentCell, AddFactor : integer;

    procedure SetCell(var cell : CellStatus;
                      ix : ColNumPlus1; iy : RowNumPlus1);
      (* check cell at [p] (linear) or [iy, ix] (matrix)
                and set new generation. vers 0.23 *)
    const
      ClearMask = ColourMask or notRegistered;
      toClear   = colour1 or notRegistered; (* displayed and not registered *)
    var c : CellStatus;
    begin
      c := cell;
      if           (c and LiveMask) = toLive then begin
                        (* 0000 0111    3 - will be alive *)
        inc(CurrentCell, AddFactor); (* progress cell number *)
        if (CurrentCell < 0) or (CurrentCell > MaxAlive) then begin
          WinPostMsg(hwndClient, WM_USER2, 0, 0);
          status.for1.CellNumber1 := 0;
          status.for1.CellNumber2 := MaxAlive
        end else begin
          with status.for1.alive[CurrentCell] do begin
            column := ix;       (* regist it *)
            row    := iy
          end;
          if (c and ColourMask) = 0 then (* 1000 0000   0 - not displayed *)
            DrawCell(ix, iy, ForeColour);
          cell := colour1               (* 1000 0000 displayed and registered *)
        end
      end else if (c and ClearMask) = toClear then begin
                        (* 1000 1000    1000 1000 - will be dead *)
        DrawCell(ix, iy, BackColour);
        cell := notRegistered           (* 0000 1000    - not registered *)
      end else
        cell := c and ClearMask         (* 1000 1000    - clear seed count *)
    end;  { of CheckField.SetCell }

    procedure SetCells(var f : BioFieldLinear;
                       x : ColNumPlus1; y : RowNumPlus1);
    var p : Lindex;
    begin
      p := y * MaxXIndexPlus1 + x;
      SetCell(f[p - MaxXIndexPlus2 ], pred(x), pred(y));
      SetCell(f[p - MaxXIndexPlus1 ], x,       pred(y));
      SetCell(f[p - MaxXIndex      ], succ(x), pred(y));
      SetCell(f[pred(p)],             pred(x), y      );
      SetCell(f[p],                   x,       y      );        (* itself *)
      SetCell(f[succ(p)],             succ(x), y      );
      SetCell(f[p + MaxXIndex      ], pred(x), succ(y));
      SetCell(f[p + MaxXIndexPlus1 ], x,       succ(y));
      SetCell(f[p + MaxXIndexPlus2 ], succ(x), succ(y))
    end;

    procedure SetCellsWrap(var f : BioField;
                           x : ColNumPlus1; y : RowNumPlus1);
    var x0, x1, y0, y1 : word;
    begin
      x0 := (x + MaxXIndex)       and MaxXIndex;
      x1 := (x + MaxXIndexPlus2)  and MaxXIndex;
      y0 := (y + MaxYIndex)       and MaxYIndex;
      y1 := (y + MaxYIndexPlus2)  and MaxYIndex;
      SetCell(f[y0, x0 ], x0, y0);
      SetCell(f[y0, x  ], x,  y0);
      SetCell(f[y0, x1 ], x1, y0);
      SetCell(f[y,  x0 ], x0, y );
      SetCell(f[y,  x  ], x,  y );        (* itself *)
      SetCell(f[y,  x1 ], x1, y );
      SetCell(f[y1, x0 ], x0, y1);
      SetCell(f[y1, x  ], x,  y1);
      SetCell(f[y1, x1 ], x1, y1)
    end;

    procedure SetCellsMedium(var f : BioFieldLinearMedium;
                             x : ColNumPlus1; y : RowNumPlus1);
    var p : Lindex;
    begin
      p := y * MaxXIndexPlus1Medium + x;
      SetCell(f[p - MaxXIndexPlus2Medium ], pred(x), pred(y));
      SetCell(f[p - MaxXIndexPlus1Medium ], x,       pred(y));
      SetCell(f[p - MaxXIndexMedium      ], succ(x), pred(y));
      SetCell(f[pred(p)],                   pred(x), y      );
      SetCell(f[p],                         x,       y      ); (* itself *)
      SetCell(f[succ(p)],                   succ(x), y      );
      SetCell(f[p + MaxXIndexMedium      ], pred(x), succ(y));
      SetCell(f[p + MaxXIndexPlus1Medium ], x,       succ(y));
      SetCell(f[p + MaxXIndexPlus2Medium ], succ(x), succ(y))
    end;

    procedure SetCellsWrapMedium(var f : BioFieldMedium;
                                 x : ColNumPlus1; y : RowNumPlus1);
    var x0, x1, y0, y1 : word;
    begin
      x0 := (x + MaxXIndexMedium)       and MaxXIndexMedium;
      x1 := (x + MaxXIndexPlus2Medium)  and MaxXIndexMedium;
      y0 := (y + MaxYIndexMedium)       and MaxYIndexMedium;
      y1 := (y + MaxYIndexPlus2Medium)  and MaxYIndexMedium;
      SetCell(f[y0, x0 ], x0, y0);
      SetCell(f[y0, x  ], x,  y0);
      SetCell(f[y0, x1 ], x1, y0);
      SetCell(f[y,  x0 ], x0, y );
      SetCell(f[y,  x  ], x,  y );        (* itself *)
      SetCell(f[y,  x1 ], x1, y );
      SetCell(f[y1, x0 ], x0, y1);
      SetCell(f[y1, x  ], x,  y1);
      SetCell(f[y1, x1 ], x1, y1)
    end;

    procedure SetCellsSmall(var f : BioFieldLinearSmall;
                            x : ColNumPlus1; y : RowNumPlus1);
    var p : Lindex;
    begin
      p := y * MaxXIndexPlus1Small + x;
      SetCell(f[p - MaxXIndexPlus2Small ], pred(x), pred(y));
      SetCell(f[p - MaxXIndexPlus1Small ], x,       pred(y));
      SetCell(f[p - MaxXIndexSmall      ], succ(x), pred(y));
      SetCell(f[pred(p)],                  pred(x), y      );
      SetCell(f[p],                        x,       y      ); (* itself *)
      SetCell(f[succ(p)],                  succ(x), y      );
      SetCell(f[p + MaxXIndexSmall      ], pred(x), succ(y));
      SetCell(f[p + MaxXIndexPlus1Small ], x,       succ(y));
      SetCell(f[p + MaxXIndexPlus2Small ], succ(x), succ(y))
    end;

    procedure SetCellsWrapSmall(var f : BioFieldSmall;
                                x : ColNumPlus1; y : RowNumPlus1);
    var x0, x1, y0, y1 : word;
    begin
      x0 := (x + MaxXIndexSmall)       and MaxXIndexSmall;
      x1 := (x + MaxXIndexPlus2Small)  and MaxXIndexSmall;
      y0 := (y + MaxYIndexSmall)       and MaxYIndexSmall;
      y1 := (y + MaxYIndexPlus2Small)  and MaxYIndexSmall;
      SetCell(f[y0, x0 ], x0, y0);
      SetCell(f[y0, x  ], x,  y0);
      SetCell(f[y0, x1 ], x1, y0);
      SetCell(f[y,  x0 ], x0, y );
      SetCell(f[y,  x  ], x,  y );        (* itself *)
      SetCell(f[y,  x1 ], x1, y );
      SetCell(f[y1, x0 ], x0, y1);
      SetCell(f[y1, x  ], x,  y1);
      SetCell(f[y1, x1 ], x1, y1)
    end;

  begin { of CalcMain.CheckField }
    with field^ do
      case RunMode of
        LargeField : begin
            SetSentinel;
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do SetCells(linear, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do SetCells(linear, column, row);
                CellNumber2 := CurrentCell
              end
            end
          end;
        LargeFieldWrap :
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do
                    SetCellsWrap(matrix, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do
                    SetCellsWrap(matrix, column, row);
                CellNumber2 := CurrentCell
              end
            end;
        MediumField : begin
            SetSentinelMedium;
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do
                    SetCellsMedium(linearm, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do
                    SetCellsMedium(linearm, column, row);
                CellNumber2 := CurrentCell
              end
            end
          end;
        MediumFieldWrap :
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do
                    SetCellsWrapMedium(matrixm, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do
                    SetCellsWrapMedium(matrixm, column, row);
                CellNumber2 := CurrentCell
              end { else }
            end; { with }
        SmallField : begin
            SetSentinelSmall;
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do
                    SetCellsSmall(linears, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do
                    SetCellsSmall(linears, column, row);
                CellNumber2 := CurrentCell
              end
            end
          end;
        SmallFieldWrap :
            with status.for1 do begin
              if odd(generation) then begin
                CurrentCell := 0;
                AddFactor   := 1;
                for i := CellNumber2 to MaxAlive do
                  with status.for1.alive[i] do
                    SetCellsWrapSmall(matrixs, column, row);
                CellNumber1 := CurrentCell
              end else begin
                CurrentCell := succ(MaxAlive);
                AddFactor   :=-1;
                for i := CellNumber1 downto 1 do
                  with status.for1.alive[i] do
                    SetCellsWrapSmall(matrixs, column, row);
                CellNumber2 := CurrentCell
              end { else }
            end  { with }
      end  { case }
  end;  { of CalcMain.CheckField }

begin   { of CalcMain }
  localHAB := WinInitialize(0);

  delayval := dlgorg.delayval;
  RunMode  := dlgorg.RunMode;
  case RunMode of
    LargeField, LargeFieldWrap   : memsz := sizeof(BioField);
    MediumField, MediumFieldWrap : memsz := sizeof(BioFieldMedium);
    SmallField, SmallFieldWrap   : memsz := sizeof(BioFieldSmall)
  end;
  DosAllocMem(pointer(field), memsz, PAG_COMMIT + PAG_WRITE + PAG_READ);
  InitField;
  with status.for1 do
    repeat
      if ScrnCleared then begin
        DosRequestMutexSem(UsePS, SEM_INDEFINITE_WAIT);
        DispField;
        ScrnCleared := false;
        DosReleaseMutexSem(UsePS)
      end;
      if (generation and 7) = 0 then
        WinPostMsg(hwndClient, WM_USER3, CellNumber1, generation);
      ScanStatus;
      DosRequestMutexSem(UsePS, SEM_INDEFINITE_WAIT);
      CheckField;
      DosReleaseMutexSem(UsePS);
      inc(generation);
      if delayval <> 0 then DosSleep(delayval-10)
    until not continue and not odd(generation);
  DosFreeMem(pointer(field));
  with status.for1 do
    WinPostMsg(hwndClient, WM_USER3, CellNumber1, generation);

  WinTerminate(localHAB);
  runcalc := false;
  DosExit(EXIT_THREAD, 0)
end;    { of CalcMain }

(* Dialog box procedures *)

function AboutDlgBoxProc (h : HWND;
                          w : ULONG;
                          m1: MPARAM;
                          m2: MPARAM) : MRESULT; CDECL;
begin
  AboutDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
end;


function FileDlgBoxProc  (h : HWND;
                          w : ULONG;
                          m1: MPARAM;
                          m2: MPARAM) : MRESULT; CDECL;
var dlgdt : pfiledlgdt;
    i : integer;
    id: word;
    s : string;

  procedure SetInitPos(var dt : filedlgdt);
  var sel : ULONG;
  begin
    sel := WinSendDlgItemMsg(h, IDD_LISTBOX, LM_QUERYSELECTION, LIT_FIRST, 0);
    if sel <> LIT_NONE then
      with flst[succ(sel)], dt do begin
        SetEntryBoxVal(h, IDD_INITCOLUMN, initx);
        ofsx := initx;
        SetEntryBoxVal(h, IDD_INITROW,    inity);
        ofsy := inity
      end
  end;

  procedure GetFileName(var dt : filedlgdt);
  type
    str4 = string[4];
  var
    s   : str4;
    sel : ULONG;
    b1, b2 : boolean;

    procedure SetInt(var n : word; s : str4; var b : boolean);
    var n1 : word;
        i  : longint;
    begin
      if s <> '' then begin
        val(s, n1, i);
        if i = 0 then n := n1
      end else
        i := 1;
      b := i = 0
    end;

  begin
    sel := WinSendDlgItemMsg(h, IDD_LISTBOX, LM_QUERYSELECTION, LIT_FIRST, 0);
    if sel <> LIT_NONE then
      with dt do begin
        WinSendDlgItemMsg(h, IDD_LISTBOX, LM_QUERYITEMTEXT,
                           MAKELONG(sel, sizeof(filenm^)),
                           MPARAM(filenm));
        s[0] := chr(WinQueryDlgItemText(h, IDD_INITCOLUMN, 4, @s[1]));
        SetInt(ofsx, s, b1);
        s[0] := chr(WinQueryDlgItemText(h, IDD_INITROW,    4, @s[1]));
        SetInt(ofsy, s, b2);
        if b1 and b2 then WinDismissDlg(h, 1)
                     else MyMessage(h, '', 'Error in Numerical Format.')
      end
  end;

begin
  FileDlgBoxProc := 0;
  case w of
    WM_INITDLG : begin
        dlgdt := pfiledlgdt(m2);
        WinSetWindowPtr(h, QWL_USER, dlgdt);
        for i := 1 to fnum do
          with flst[i] do begin
            s := fname + ' ' + comment + chr(0);
            WinSendDlgItemMsg(h, IDD_LISTBOX, LM_INSERTITEM,
                              LIT_END, MPARAM(@s[1]))
          end
      end;
    WM_CONTROL : begin
        dlgdt := WinQueryWindowPtr(h, QWL_USER);
        id := LoUShort(m1);
        with dlgdt^ do
          case id of
            IDD_ROTATE0,
            IDD_ROTATE90,
            IDD_ROTATE180,
            IDD_ROTATE270 : rot := id - IDD_ROTATE0;
            IDD_MIRRORH,
            IDD_MIRRORV   :
                if HiUShort(m1) = BN_CLICKED then
                  if id = IDD_MIRRORH then hmirror := not hmirror
                                      else vmirror := not vmirror;
            IDD_LISTBOX   :
                case HiUShort(m1) of
                  LN_SELECT : SetInitPos(dlgdt^);
                  LN_ENTER  : GetFileName(dlgdt^)
                end;
          else
            FileDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
          end
      end;
    WM_COMMAND :
        case LoUShort(m1) of
          DID_OK     : begin
              dlgdt := WinQueryWindowPtr(h, QWL_USER);
              GetFileName(dlgdt^)
            end;
          DID_CANCEL : WinDismissDlg(h, 0)
        end;
  else
    FileDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
  end
end;

function DelayDlgBoxProc (h : HWND;
                          w : ULONG;
                          m1: MPARAM;
                          m2: MPARAM) : MRESULT; CDECL;
var dlgdt : pdialogdata;
    d : ULONG;
    m : word;
begin
  DelayDlgBoxProc := 0;
  case w of
    WM_INITDLG : begin
        dlgdt := pdialogdata(m2);
        WinSetWindowPtr(h, QWL_USER, dlgdt);
        with dlgdt^ do begin
          WinSendDlgItemMsg(h, IDD_SCROLLBAR,
                            SLM_SETSLIDERINFO,
                            MAKEULONG(SMA_SLIDERARMPOSITION,
                                      SMA_INCREMENTVALUE),
                                      delayval div 10);
          SetEntryBoxVal(h, IDD_ENTRYBOX, delayval);
          WinSendDlgItemMsg(h, IDD_SETPRTY, BM_SETCHECK,
                            ord(prtyidle), 0)
        end
      end;
    WM_CONTROL : begin
        dlgdt := WinQueryWindowPtr(h, QWL_USER);
        m     := HiUShort(m1);
        case LoUShort(m1) of
          IDD_SETPRTY :
              if m = BN_CLICKED then
                with dlgdt^ do begin
                  prtyidle := not prtyidle;
                  WinSendDlgItemMsg(h, IDD_SETPRTY, BM_SETCHECK,
                                    ord(prtyidle), 0)
                end;
          IDD_SCROLLBAR :
              if m = SLN_CHANGE then begin
                d := WinSendDlgItemMsg(h, IDD_SCROLLBAR,
                                       SLM_QUERYSLIDERINFO,
                                       MAKEULONG(SMA_SLIDERARMPOSITION,
                                                 SMA_INCREMENTVALUE),
                                       0);
                d := d * 10;
                with dlgdt^ do
                  if d<>delayval then begin
                    delayval := d;
                    SetEntryBoxVal(h, IDD_ENTRYBOX, d)
                  end
              end
        end
      end;
    WM_COMMAND :
        case LoUShort(m1) of
          DID_OK     : WinDismissDlg(h, 1);
          DID_CANCEL : WinDismissDlg(h, 0)
        end;
  else
    DelayDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
  end
end;

function FieldDlgBoxProc (h : HWND;
                          w : ULONG;
                          m1: MPARAM;
                          m2: MPARAM) : MRESULT; CDECL;
var dlgdt : pdialogdata;
    d : ULONG;
    md: RunningModes;
begin
  FieldDlgBoxProc := 0;
  case w of
    WM_INITDLG : begin
        dlgdt := pdialogdata(m2);
        WinSetWindowPtr(h, QWL_USER, dlgdt);
        with dlgdt^ do begin
          WinSendDlgItemMsg(h, IDD_LARGEFIELD + ord(RunMode) div 2,
                            BM_SETCHECK, 1, 0);
          WinSendDlgItemMsg(h, IDD_FIELDWRAP, BM_SETCHECK,
                            ord(odd(ord(RunMode))), 0)
        end
      end;
    WM_COMMAND :
        case LoUShort(m1) of
          DID_OK     : begin
              dlgdt := WinQueryWindowPtr(h, QWL_USER);
              with dlgdt^ do begin
                d := WinSendDlgItemMsg(h, IDD_LARGEFIELD,
                                       BM_QUERYCHECKINDEX, 0, 0);
                if d in [0..2] then begin
                  case d of
                    0 : md := LargeField;
                    1 : md := MediumField;
                    2 : md := SmallField
                  end;
                  d := WinSendDlgItemMsg(h, IDD_FIELDWRAP,
                                         BM_QUERYCHECK, 0, 0);
                  if d = 1 then inc(md);
                  RunMode := md;
                  WinDismissDlg(h, 1)
                end
              end
            end;
          DID_CANCEL : WinDismissDlg(h, 0)
        end;
  else
    FieldDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
  end
end;


function ColourDlgBoxProc (h : HWND;
                           w : ULONG;
                           m1: MPARAM;
                           m2: MPARAM) : MRESULT; CDECL;
var id : word;
    dlgdt : pdialogdata;
begin
  case w of
    WM_INITDLG : begin
        dlgdt := pdialogdata(m2);
        WinSetWindowPtr(h, QWL_USER, dlgdt);
        with dlgdt^ do begin
          WinSendDlgItemMsg(h, forecolour + IDD_COLOUR, BM_SETCHECK, 1, 0);
          WinSendDlgItemMsg(h, backcolour + IDD_COLOUR, BM_SETCHECK, 1, 0)
        end;
        ColourDlgBoxProc := 0
      end;
    WM_CONTROL : begin
        dlgdt := WinQueryWindowPtr(h, QWL_USER);
        id := LoUShort(m1);
        ColourDlgBoxProc := 0;
        case id of
          IDD_FOREBLACK..IDD_FOREGREY : dlgdt^.forecolour := id - IDD_COLOUR;
          IDD_BACKBLACK..IDD_BACKGREY : dlgdt^.backcolour := id - IDD_COLOUR
        else
          ColourDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
        end
      end;
    WM_COMMAND : begin
        case LoUShort(m1) of
          DID_OK      : WinDismissDlg(h, 1);
          DID_CANCEL  : WinDismissDlg(h, 0)
        end
      end;
  else
    ColourDlgBoxProc := WinDefDlgProc(h, w, m1, m2)
  end
end;

function InfoWndProc(   h : HWND;
                        w : ULONG;
                        m1: MPARAM;
                        m2: MPARAM) : MRESULT; CDECL;
type
  cellinfo = record
    cb  : word;
    num : word;
    gen : integer
  end;
var r : RECTL;
    hp: HPS;
    cinf : ^cellinfo;
    s : string[39];
    ss: string[5];
begin
  InfoWndProc := 0;
  case w of
    WM_CREATE: begin
        new(cinf);
        with cinf^ do begin
          cb := sizeof(cinf^);
          num:= 0;
          gen:= 0
        end;
        WinSetWindowPtr(h, QWL_USER, cinf)
      end;
    WM_PAINT : with status.for1 do begin
        cinf := WinQueryWindowPtr(h, QWL_USER);
        s := 'CELL :       TIME :       ' + VersNum;
        with cinf^ do begin
          str(num, ss);
          move(ss[1], s[8], length(ss));
          str(gen, ss);
          move(ss[1], s[21], length(ss))
        end;
        hp := WinBeginPaint(h, NULLHANDLE, @r);
        WinDrawText(hp, length(s), @s[1], r,
                    CLR_BLUE, 0, DT_LEFT + DT_ERASERECT);
        WinEndPaint(hp)
      end;
    WM_USER4 : begin
        cinf := WinQueryWindowPtr(h, QWL_USER);
        with cinf^ do begin
          num := m1;
          gen := m2
        end
      end;
    WM_ERASEBACKGROUND :
        InfoWndProc := 1;
    WM_CLOSE : begin
        cinf := WinQueryWindowPtr(h, QWL_USER);
        dispose(cinf);
        InfoWndProc := WinDefWindowProc(h, w, m1, m2)
      end
  else
    InfoWndProc := WinDefWindowProc(h, w, m1, m2)
  end
end;


function AppWndProc(    h : HWND;
                        w : ULONG;
                        m1: MPARAM;
                        m2: MPARAM) : MRESULT; CDECL;
(* Main Window Procedure *)
var
  myhps : HPS;
  rcl   : RECTL;
  currentpoint,
  waitpoint : HPOINTER;

  procedure EnableMenuItem(h : HWND; id : word; enable : boolean);
  begin
    WinSendMsg(h, MM_SETITEMATTR,
               MAKEULONG(id, 1),
               MAKEULONG(MIA_DISABLED, MIA_DISABLED * ord(not enable)))
  end;  { AppWndProc.EnableMenuItem }

  function hwndParent : HWND;
  begin
    hwndParent := WinQueryWindow(h, QW_PARENT)
  end;  { AppWndProc.hwndParent }

  procedure SetScrollParam;
  begin
    Xscrn := MaxX * zoom;
    Xmove := Xscrn - Xsize;
    if Xmove < 0 then Xmove := 0;
    Yscrn := MaxY * zoom;
    Ymove := Yscrn - Ysize;
    if Ymove < 0 then Ymove := 0;
    WinSendMsg(hwndHscroll, SBM_SETSCROLLBAR, 0, MAKELONG(0, Xmove));
    WinSendMsg(hwndHscroll, SBM_SETPOS, dx, 0);
    WinSendMsg(hwndVscroll, SBM_SETSCROLLBAR, 0, MAKELONG(0, Ymove));
    WinSendMsg(hwndVscroll, SBM_SETPOS, Ymove - dy, 0)
  end;  { AppWndProc.SetScrollParam }

  procedure ZoomInOut(zoomin : boolean);
  begin
    inc(zoom, pred(ord(zoomin) * 2));
    SetScrollParam;
    SetViewParam(zoom, zoom, -dx, -dy);
    WinInvalidateRect(h, nil, false)
  end;  { AppWndProc.ZoomInOut }

  procedure InitWin;
  begin
    continue  := false;
    runcalc   := false;
    inited    := false;
    InitialisePS(h, hpsInit);
    DosCreateMutexSem(nil, UsePS, 0, true);
    SetViewParam(1, 1, 0, 0);
    GpiSetBackColor(hpsInit, CLR_BLACK);
    DosReleaseMutexSem(UsePS);
    WinRegisterClass(myhab, InfoName, InfoWndProc, CS_SIZEREDRAW, 16);
    hwndInfo := WinCreateWindow(h, InfoName, nil, WS_VISIBLE,
                                0, 0, MaxXIndex, CharHeight,
                                h, HWND_TOP, 1, nil, nil);
    hwndHscroll := WinWindowFromID(hwndParent, FID_HORZSCROLL);
    hwndVscroll := WinWindowFromID(hwndParent, FID_VERTSCROLL);
    WinSendMsg(hwndVscroll, SBM_SETPOS, dy, 0)
  end;  { AppWndProc.InitWin }

  procedure InitMenu(cmd : word; mhwnd : HWND);
  begin
    case cmd of
      IDM_LIFE : begin
          EnableMenuItem(mhwnd, IDM_INIT,  not runcalc);
          EnableMenuItem(mhwnd, IDM_ADD,   inited > runcalc);
          EnableMenuItem(mhwnd, IDM_START, inited)
        end;
      IDM_OPTION : begin
          EnableMenuItem(mhwnd, IDM_ENLARGE,   zoom < MaxZoom);
          EnableMenuItem(mhwnd, IDM_SHRINK,    zoom > 1);
          EnableMenuItem(mhwnd, IDM_FIELDSIZE, not runcalc)
        end
    end
  end;  { AppWndProc.InitMenu }

  procedure CommandProcs(cmd : word);
  var dlgdata : pdialogdata;
      fdlg    : pfiledlgdt;
      changed : ULONG;
      s       : string;

    procedure ReadCellDataFile;
    var fname   : string;
        ecl     : pEditCells;
        i       : integer;
    begin
      currentpoint := WinQueryPointer(HWND_DESKTOP);
      waitpoint    := WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, false);
      WinSetPointer(HWND_DESKTOP, waitpoint);
      new(ecl);
      with ecl^, fdlg^ do begin
        fname := StrPas(filenm^);
        i := pos(' ', fname);
        fname := copy(fname, 1, pred(i));
        ReadCellFromText(fname, ecl^);
        if ofsx = 0 then initColumn := MaxX div 2
                    else initColumn := ofsx;
        if ofsy = 0 then initRow    := MaxY div 2
                    else initRow    := ofsy;
        RotateField(ecl^, rot);
        if hmirror then ReverseFieldH(ecl^);
        if vmirror then ReverseFieldV(ecl^)
      end;
      InitLifeField(ecl^, cmd = IDM_INIT);
      dispose(ecl);
      WinSetPointer(HWND_DESKTOP, currentpoint)
    end;

    procedure SetPriority;
    var u : ULONG;
    begin
      if dlgorg.prtyidle then u := PRTYC_IDLETIME
                         else u := PRTYC_REGULAR;
      DosSetPriority(PRTYS_THREAD, u, 0, idThread)
    end;

    function GetFileName(title, extention : string; save : boolean) : string;
    var fdlg  : FILEDLG;
        cTitle: string;
        i     : integer;
        s     : string;
    begin
      cTitle     := title + ' File' + chr(0);
      fillchar(fdlg, sizeof(fdlg), 0);
      with fdlg do begin
        cbsize     := sizeof(fdlg);
        fl         := FDS_HELPBUTTON + FDS_CENTER;
        if save then inc(fl, FDS_SAVEAS_DIALOG)
                else inc(fl, FDS_OPEN_DIALOG);
        pszTitle   := @cTitle[1];
        s          := '';
        i := WinFileDlg(HWND_DESKTOP, h, fdlg);
        if (i<>0) and (lReturn = DID_OK) then begin
          if papszFQFilename<>nil then begin
            s := StrPas(papszFQFilename^[0]);
            WinFreeFileDlgList(papszFQFilename)
          end else
            s := StrPas(szFullFile)
        end
      end;
      GetFileName := s
    end;

  begin
    case cmd of
      IDM_INIT, IDM_ADD    : begin
          currentpoint := WinQueryPointer(HWND_DESKTOP);
          waitpoint    := WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, false);
          WinSetPointer(HWND_DESKTOP, waitpoint);
          MakeFileList('*.lif', flst, fnum);
          WinSetPointer(HWND_DESKTOP, currentpoint);
          new(fdlg);
          fillchar(fdlg^, sizeof(fdlg^), 0);
          with fdlg^ do begin
            cb := sizeof(fdlg^);
            new(filenm);
            fillchar(filenm^, sizeof(filenm^), 0)
          end;
          changed := WinDlgBox(HWND_DESKTOP, h, FileDlgBoxProc,
                               NULLHANDLE, IDD_FILELIST, fdlg);
          if changed <> 0 then begin
            ReadCellDataFile;
            inited := true;
            WinInvalidateRect(h, nil, false)
          end;
          dispose(fdlg^.filenm);
          dispose(fdlg)
        end;
      IDM_START   :
          if not runcalc then begin
            runcalc := true;
            continue:= true;
            BeginThread(nil, StackSize, CalcMain,
                        nil, CREATE_READY, idThread);
            SetPriority
          end;
      IDM_END     :
          continue := false;
      IDM_ENLARGE,
      IDM_SHRINK  :
          ZoomInOut(cmd = IDM_ENLARGE);
      IDM_SETDELAY: begin
          new(dlgdata);
          dlgdata^ := dlgorg;
          changed  := WinDlgBox(HWND_DESKTOP, h, DelayDlgBoxProc,
                                NULLHANDLE, IDD_SETDELAY, dlgdata);
          if changed <> 0 then begin
            dlgorg := dlgdata^;
            if runcalc then SetPriority
          end;
          dispose(dlgdata)
        end;
      IDM_SETCOLOUR : begin
          new(dlgdata);
          dlgdata^ := dlgorg;
          changed  := WinDlgBox(HWND_DESKTOP, h, ColourDlgBoxProc,
                                NULLHANDLE, IDD_COLOUR, dlgdata);
          if changed <> 0 then begin
            dlgorg := dlgdata^;
            ForeColour := colour[dlgorg.forecolour];
            BackColour := colour[dlgorg.backcolour];
            WinInvalidateRect(h, nil, false)
          end;
          dispose(dlgdata)
        end;
      IDM_FIELDSIZE : begin
          new(dlgdata);
          dlgdata^ := dlgorg;
          changed  := WinDlgBox(HWND_DESKTOP, h, FieldDlgBoxProc,
                               NULLHANDLE, IDD_FIELDSIZE, dlgdata);
          if changed <> 0 then begin
            dlgorg := dlgdata^;
            SetMaxXY;
            LimitLifeField;
            WinInvalidateRect(h, nil, false)
          end;
          dispose(dlgdata)
        end;
      IDM_LOADSETTINGS : begin
          s := GetFileName('Loading Setting', '*.ini', false);
          LoadSettings(h, s);
          SetMaxXY;
          LimitLifeField;
          WinInvalidateRect(h, nil, false)
        end;
      IDM_SAVESETTINGS : begin
          s := GetFileName('Saving Setting', '*.ini', false);
          SaveSettings(hwndFrame, s)
        end;
      IDM_SAVEDEFSETTINGS :
          SaveSettings(hwndFrame, ININame);
      IDM_ABOUT   :
          WinDlgBox(HWND_DESKTOP, h, AboutDlgBoxProc,
                    NULLHANDLE, IDD_ABOUT, nil)
    end
  end;  { AppWndProc.CommandProc }

  procedure HScrollProc(cmd : word);
  begin
    case cmd of
      SB_LINELEFT : dec(dx, zoom);
      SB_LINERIGHT: inc(dx, zoom);
      SB_PAGELEFT : dec(dx, zoom * 10);
      SB_PAGERIGHT: inc(dx, zoom * 10);
      SB_SLIDERPOSITION : dx := LoUShort(m2)
    end;
    if      dx < 0     then dx := 0
    else if dx > Xmove then dx := Xmove;
    WinSendMsg(hwndHscroll,  SBM_SETPOS, dx, 0);
    SetViewParam(zoom, zoom, -dx, -dy);
    WinInvalidateRect(h, nil, false)
  end;  { AppWndProc.HScrollProc }

  procedure VScrollProc(cmd : word);
  begin
    case cmd of
      SB_LINEUP  : inc(dy, zoom);
      SB_LINEDOWN: dec(dy, zoom);
      SB_PAGEUP  : inc(dy, zoom * 10);
      SB_PAGEDOWN: dec(dy, zoom * 10);
      SB_SLIDERPOSITION : dy := Ymove - LoUShort(m2)
    end;
    if      dy < 0     then dy := 0
    else if dy > Ymove then dy := Ymove;
    WinSendMsg(hwndVscroll, SBM_SETPOS, Ymove - dy, 0);
    SetViewParam(zoom, zoom, -dx, -dy);
    WinInvalidateRect(h, nil, false)
  end;  { AppWndProc.VScrollProc }

begin   { AppWndProc }
  AppWndProc := 0;
  case w of
    WM_CREATE :
        InitWin;
    WM_SIZE  : begin
        Xsize := LoUShort(m2);
        Ysize := HiUShort(m2);
        SetScrollParam;
        WinSetWindowPos(hwndInfo, HWND_TOP, 0, 0, Xsize, CharHeight, fSwp);
        WinInvalidateRect(h, nil, false)
      end;
    WM_PAINT : begin
        DosRequestMutexSem(UsePS, 500);
        WinBeginPaint(h, hpsInit, @rcl);
        WinFillRect(hpsInit, rcl, BackColour);
        if not continue then DispField;
        WinEndPaint(hpsInit);
        DosReleaseMutexSem(UsePS);
        ScrnCleared := true
      end;
    WM_USER2       : begin                (* Cell number overflow *)
        continue := false;
        MyMessage(h, '', 'Too Many Cells. Program Stopped.')
      end;
    WM_USER3       : begin
        WinSendMsg(hwndInfo, WM_USER4, m1, m2);
        WinInvalidateRect(hwndInfo, nil, false)
      end;
    WM_INITMENU :
        InitMenu(CommandMsgMP1(m1).cmd, HWND(m2));
    WM_COMMAND :
        CommandProcs(CommandMsgMP1(m1).cmd);
    WM_HSCROLL :
        HScrollProc(HiUShort(m2));
    WM_VSCROLL :
        VScrollProc(HiUShort(m2));
    WM_ERASEBACKGROUND :
        AppWndProc := 1;
    WM_CLOSE : begin
        WinReleasePS(hpsInit);
        AppWndProc := WinDefWindowProc(h, w, m1, m2)
      end
  else
    AppWndProc := WinDefWindowProc(h, w, m1, m2)
  end
end;   { AppWndProc }

begin  { Main }
  InitVar;

  myhab := WinInitialize(0);
  myhmq := WinCreateMsgQueue(myhab, 0);

  WinRegisterClass(myhab, ClassName, AppWndProc, CS_SIZEREDRAW, 0);

  hwndFrame := WinCreateStdWindow(HWND_DESKTOP,
                                  WS_VISIBLE + WS_CLIPCHILDREN,
                                  ctlData, ClassName, VersNum, 0,
                                  NULLHANDLE, ID_RESOURCE, @hwndClient);

  with dlgorg do
    WinSetWindowPos(hwndFrame, HWND_TOP, posx0, posy0, posx1, posy1, fSwp);

  while WinGetMsg(myhab, myqmsg, NULLHANDLE, 0, 0) do
    WinDispatchMsg(myhab, myqmsg);

  if continue then begin
    DosResumeThread(idThread);
    DosKillThread(idThread)
  end;

  WinDestroyMsgQueue(myhmq);
  WinTerminate(myhab)
end.

