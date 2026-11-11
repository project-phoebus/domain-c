{ celpkg - CELPKG, the m68k code generator's cells: code, label and
  reference cells taken from three GSPACE pools and kept on circular
  lists, the address descriptors packed into the cells and unpacked,
  and the temporary labels.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0B645C  --------  init_celpkg
    0x0B648E  --------  getlabcell
    0x0B650A  --------  getrefcell
    0x0B6582  --------  getcodecell
    0x0B6652  --------  after
    0x0B6682  --------  delink
    0x0B66AE  --------  join
    0x0B66EE  --------  empty
    0x0B670A  --------  pack_ads
    0x0B6838  --------  unpack_ads
    0x0B68AA  --------  create_temp_label
    A5 0x2CE674: the module's data: +0 three pools (the next free byte
    and the bytes left in the current 2048-byte GSPACE block; pool 1
    the reference cells and the code cells of seven kinds, pool 2 kind
    28's, pool 3 the others), +24 an empty address descriptor, +36 the
    number of the next label made without a node, +40 the template of
    a label's descriptor (its first byte 0x38: f1 7).  .rwdi zeroes
    +0x18..+0x25 and sets +0x28..+0x33.  At -4 the address of
    pas_$output (pack_ads's warning).

  Every routine is global and loads A5.

  Not known from the original: every name but the routines'; the
  descriptors' fields.
}
module celpkg;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';

type
  celpkg_pool_t = record
    next: univ_ptr;
    left: integer32;
  end;

  celpkg_bytes_t = array [0..2047] of char;
  celpkg_bytes_ptr_t = ^celpkg_bytes_t;

var
  pools: array [1..3] of celpkg_pool_t;         { +0 }
  null_ads: codegen_$ads_t := [f1 := 0, f2 := 0, f3 := 0, f4 := 0,
      f5 := 0, f6 := 0, pad := 0, x := 0, y := 0];      { +24 }
  label_count: integer := 0;                    { +36 }
  label_ads: codegen_$ads_t := [f1 := 7, f2 := 0, f3 := 0, f4 := 0,
      f5 := 0, f6 := 0, pad := 0, x := 0, y := 0];      { +40 }

{ init_celpkg - the pools empty.

  0x0B645C, 0x32 bytes: a counted loop of three (`dbf') storing 0 to
  each pool's two longwords. }

procedure init_celpkg;
var
  i: integer;
begin
  for i := 1 to 3 do begin
    pools[i].next := nil;
    pools[i].left := 0;
  end;
end;

{ getlabcell - a label cell (kind 0) for lab.

  0x0B648E, 0x7A bytes: getcodecell(0) (a word after the routine); the
  descriptors from +24 and +40 (three longwords each); +40 := lab; no
  lab: +44 := the label count, which grows; else lab's +80 := the cell,
  lab's +72 bit 7 set, and with lab's +74 bit 7 the cell's +38 bit 4
  (the second descriptor's f5, low bit).  The result stays in A0 from
  getcodecell (no move at the end).

  Not known from the original:
  - the lab node's fields (bits set through a byte here). }

function getlabcell;
var
  cell: codegen_$cell_ptr_t;
begin
  cell := getcodecell(0);
  cell^.ads1 := null_ads;
  cell^.ads2 := label_ads;
  cell^.ads2.x := integer32(lab);
  if lab = nil then begin
    cell^.ads2.y := label_count;
    label_count := label_count + 1;
  end
  else begin
    lab^.xp[20] := il_$node_ptr_t(cell);
    lab^.xc[72] := chr(ord(lab^.xc[72]) ! 16#80);
    if ord(lab^.xc[74]) >= 16#80 then
      cell^.ads2.f5 := cell^.ads2.f5 ! 1;
  end;
  getlabcell := cell;
end;

{ getrefcell - a reference cell (16 bytes, pool 1) to target, added to
  the end of owner's list (+32; the first becomes its head).

  0x0B650A, 0x78 bytes: a new 2048-byte block when fewer than 16 bytes
  are left (`cmpi.l #16; bge'); the cell linked to itself, +12 :=
  owner, +8 := target; after(head's prev, cell) when owner has a list. }

function getrefcell;
var
  cell: codegen_$cell_ptr_t;
  head: codegen_$cell_ptr_t;
begin
  if pools[1].left < 16 then begin
    pools[1].next := gspace(2048);
    pools[1].left := 2048;
  end;
  cell := pools[1].next;
  pools[1].next := addr(celpkg_bytes_ptr_t(pools[1].next)^[16]);
  pools[1].left := pools[1].left - 16;
  cell^.next := cell;
  cell^.prev := cell;
  cell^.owner := owner;
  cell^.target := target;
  head := owner^.refs;
  if head = nil then
    owner^.refs := cell
  else
    after(head^.prev, cell);
  getrefcell := cell;
end;

{ getcodecell - a code cell of kind.

  0x0B6582, 0xCA bytes: kind 24 18 bytes, kinds 32 and 33 16 (not
  cleared), pool 3; the others 50 bytes, pool 1 for the kinds 0, 17,
  18, 23, 31, 34, 39 (a set at 0x0B664C, `btst'), pool 2 for 28, else
  pool 3; the size rounded up to a multiple of 4 (a signed `div 4');
  a new block when the pool has fewer bytes left (`ble'); the cell
  linked to itself, +8 := kind, +10..+23 cleared for the large cells.

  Not known from the original:
  - whether the rounding was written as `div' and `*'. }

function getcodecell;
var
  size: integer;
  small: boolean;
  pool: integer;
  cell: codegen_$cell_ptr_t;
  i: integer;
begin
  if kind = 24 then begin
    size := 18;
    small := true;
    pool := 3;
  end
  else if (kind = 32) or (kind = 33) then begin
    size := 16;
    small := true;
    pool := 3;
  end
  else begin
    size := 50;
    small := false;
    if kind in [0, 17, 18, 23, 31, 34, 39] then
      pool := 1
    else if kind = 28 then
      pool := 2
    else
      pool := 3;
  end;
  size := ((size + 3) div 4) * 4;
  with pools[pool] do begin
    if size > left then begin
      next := gspace(2048);
      left := 2048;
    end;
    cell := next;
    next := addr(celpkg_bytes_ptr_t(next)^[size]);
    left := left - size;
  end;
  cell^.next := cell;
  cell^.prev := cell;
  cell^.kind := kind;
  if not small then
    for i := 1 to 7 do
      cell^.c_10[i] := 0;
  getcodecell := cell;
end;

{ after - link b after a.

  0x0B6652, 0x30 bytes. }

procedure after;
var
  n: codegen_$cell_ptr_t;
begin
  n := a^.next;
  b^.next := n;
  b^.prev := a;
  a^.next := b;
  n^.prev := b;
end;

{ delink - take c off its list and link it to itself.

  0x0B6682, 0x2C bytes. }

procedure delink;
begin
  c^.prev^.next := c^.next;
  c^.next^.prev := c^.prev;
  c^.next := c;
  c^.prev := c;
end;

{ join - list b spliced in after a.

  0x0B66AE, 0x40 bytes. }

procedure join;
var
  n: codegen_$cell_ptr_t;
begin
  n := a^.next;
  a^.next := b;
  n^.prev := b^.prev;
  b^.prev^.next := n;
  b^.prev := a;
end;

{ empty - c^.next = c.

  0x0B66EE, 0x1C bytes (`cmpa.l (A0),A0; seq'). }

function empty;
begin
  empty := c^.next = c;
end;

{ pack_ads - u packed into p.

  0x0B670A, 0x114 bytes: f1 stored as it is (its low byte shifted); f2,
  f3 and f4 cleared when above 31, 31 and 3 (`bhi'), f6 when above 5;
  f5 above 7 (`andi.w #-8') writes ' WARNING: Bad ADS record.' to
  standard output (PAS_$WRITE, PAS_$WRITELN on the file at (-4,A5);
  docs/dpc-gaps.md 4), its low 3 bits stored; y, x; f4 last.

  Not known from the original:
  - the fields' names and meaning. }

procedure pack_ads;
begin
  p.f1 := u.f1;
  if u.f2 <= 31 then
    p.f2 := u.f2
  else
    p.f2 := 0;
  if u.f3 <= 31 then
    p.f3 := u.f3
  else
    p.f3 := 0;
  if (u.f5 & 16#FFF8) <> 0 then
    writeln(' WARNING: Bad ADS record.');
  p.f5 := u.f5 & 7;
  if u.f6 <= 5 then
    p.f6 := u.f6
  else
    p.f6 := 0;
  p.y := u.y;
  p.x := u.x;
  if u.f4 <= 3 then
    p.f4 := u.f4
  else
    p.f4 := 0;
end;

{ unpack_ads - p unpacked into u.

  0x0B6838, 0x72 bytes: each field extracted (`and', shift), the
  longwords copied (y first). }

procedure unpack_ads;
begin
  u.f1 := p.f1;
  u.f2 := p.f2;
  u.f3 := p.f3;
  u.f5 := p.f5;
  u.f6 := p.f6;
  u.y := p.y;
  u.x := p.x;
  u.f4 := p.f4;
end;

{ create_temp_label - a temporary label node.

  0x0B68AA, 0x5E bytes: gspace(84); kind 144; +72 bits 7 and 6
  cleared and bits 5..1 := 14 (prtobj prints the letter 'A' + 14
  before its number); +48 := il_146[14] (IL's +0x162), which grows;
  +56 := -1, +64 and +80 cleared.

  Not known from the original:
  - the node's fields (written through il.ins.pas's views; the byte
    at +72 by arithmetic keeping bit 0). }

function create_temp_label;
var
  n: il_$node_ptr_t;
begin
  n := gspace(84);
  n^.kind := 144;
  n^.xc[72] := chr(ord(n^.xc[72]) & 16#01 ! 28);
  n^.xw[24] := il_146[14];
  il_146[14] := il_146[14] + 1;
  n^.xl[14] := -1;
  n^.xl[16] := 0;
  n^.xp[20] := nil;
  create_temp_label := n;
end;
