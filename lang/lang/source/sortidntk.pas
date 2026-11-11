{ sortidntk - SORTIDNTK, the identifier table in name order: every
  identifier of strings's hash chains in one chain, sorted by name with
  a quicksort over an array of the entries.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x098598  0x099F78  qsort (in sort)
    0x0986D8  0x09A0B8  sort (internal)
    0x0986FE  0x09A0DE  sortidentifiers
    A5 0x19DB88 (cc.m68k): the module's data, 4 bytes (to strings')
    no routine uses.

  sortidentifiers is global and loads A5; sort, which does not, is
  internal.
}
module sortidntk;

%include 'lang/lang/source/globals.ins.pas';

type
  node_array_t = array [1..1000000] of il_$node_ptr_t;
  node_array_ptr_t = ^node_array_t;

{ sort - sort the n identifiers of a by name.

  0x0986D8, 0x26 bytes (no A5): with n >= 2 (`cmpi.l #2'), qsort(1, n)
  (`pea 0x1'; its static link in A1).  The pivot (-12) and the swap's
  temporary (-8) are sort's locals, which qsort uses through the link
  at every depth.

  Not known from the original:
  - the names. }

procedure sort(
    var a: univ node_array_t;
    n: integer32); internal;
var
  pivot: il_$node_ptr_t;
  tmp: il_$node_ptr_t;

  { qsort - sort a[l..r].

    0x098598, 0x140 bytes.  The pivot is a[r]; i from l and j from r - 1
    move inward while i < j: i past names not greater than the pivot's,
    j past names not less (the names compared as 4096 characters,
    `cmpm.b; dbne' 4095 then `bhi', `bcs'), unequal ones swapped; then
    a greater a[i] (i < r) is swapped with a[r]; qsort(i + 1, r) when
    i + 1 < r and qsort(l, j) when j > l (l kept in a local, -16).

    Not known from the original:
    - the names. }

  procedure qsort(
      l: integer32;
      r: integer32);
  var
    i, j: integer32;
  begin
    i := l;
    j := r - 1;
    pivot := a[r];
    repeat
      while (i < j) and not (a[i]^.idnt_name > pivot^.idnt_name) do
        i := i + 1;
      while (i < j) and not (a[j]^.idnt_name < pivot^.idnt_name) do
        j := j - 1;
      if i < j then begin
        tmp := a[i];
        a[i] := a[j];
        a[j] := tmp;
      end;
    until i >= j;
    if i < r then
      if a[i]^.idnt_name > pivot^.idnt_name then begin
        tmp := a[i];
        a[i] := a[r];
        a[r] := tmp;
      end;
    i := i + 1;
    if i < r then
      qsort(i, r);
    if j > l then
      qsort(l, j);
  end;

begin
  if n >= 2 then
    qsort(1, n);
end;

{ sortidentifiers - every identifier in one chain sorted by name.

  0x0986FE, 0xBE bytes.  For each of the 256 chains of idnt_table (a
  `dbf' over the table, 0x19DB8C): each entry is counted and gets a NUL
  after its name when shorter than 4096 (`cmpi.w #4096; bcc'); the
  chain's last entry is linked to the list so far, and the chain's head
  becomes the list.  An array of count pointers (gspace32(count * 4))
  gets the list in order; sort; the entries are linked again from the
  last, and the first is the result.

  Not known from the original:
  - the locals' names. }

function sortidentifiers: il_$node_ptr_t;
var
  count: integer32;
  h: integer;
  list, p, q: il_$node_ptr_t;
  arr: node_array_ptr_t;
  i: integer32;
begin
  count := 0;
  list := nil;
  for h := 0 to 255 do begin
    p := idnt_table[h];
    if p <> nil then
      repeat
        count := count + 1;
        if p^.idnt_len < 4096 then
          p^.idnt_name[p^.idnt_len + 1] := chr(0);
        if p^.idnt_next = nil then begin
          p^.idnt_next := list;
          list := idnt_table[h];
          exit;
        end;
        p := p^.idnt_next;
      until false;
  end;
  arr := gspace32(count * 4);
  p := list;
  for i := 1 to count do begin
    arr^[i] := p;
    p := p^.idnt_next;
  end;
  sort(arr^, count);
  q := nil;
  for i := count downto 1 do begin
    arr^[i]^.idnt_next := q;
    q := arr^[i];
  end;
  sortidentifiers := q;
end;
