{ gspace - GSPACE, the compilers' arena allocator.  Space is cut from a
  list of chunks (each at least 131008 bytes, its first 8 bytes the link
  and the size), cleared when the chunk is obtained; GSPACE_$MARK notes
  where the next allocation will be and GSPACE_$RELEASE frees every chunk
  allocated after a mark and clears the rest of the mark's chunk.  The
  space in use and its peak are kept for PRFPKG's statistics.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07D4C8  0x07EEA8  gspace_$open
    0x07D4F2  0x07EED2  gspace
    0x07D51C  0x07EEFC  gspace32
    0x07D64E  0x07F02E  gspace_$mark
    0x07D66C  0x07F04C  gspace_$release
    0x07D72C  0x07F10C  gspace_$close
    A5 0x169C64 (cc.m68k): the module's data, 12 bytes (to il's).

  Every routine is global and loads A5.
}
module gspace;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';

type
  { A chunk: its link and its size in bytes, then the space. }
  gspace_chunk_ptr_t = ^gspace_chunk_t;
  gspace_chunk_t = record
    next: gspace_chunk_ptr_t;           { +0 }
    size: integer32;                    { +4 }
  end;

  gspace_long_ptr_t = ^integer32;

  { 16 bytes, the unit a new chunk is cleared in. }
  gspace_clear_ptr_t = ^gspace_clear_t;
  gspace_clear_t = array [1..4] of integer32;

var
  head: gspace_chunk_ptr_t;             { +0: the newest chunk }
  next_free: integer32;                 { +4: where the next space starts }
  allocated: integer32;                 { +8: what has been handed out }

{ gspace_$open - no chunks yet.

  0x07D4C8, 0x2A bytes: `move.l #0' to +0, +4 and +8. }

procedure gspace_$open;
begin
  head := nil;
  next_free := 0;
  allocated := 0;
end;

{ gspace - n bytes, n a 16-bit count.

  0x07D4F2, 0x2A bytes: n (a word at (8,A6)) sign-extended and passed by
  value to gspace32 (`bsr'); its A0 kept as the result. }

function gspace(
    n: integer): univ_ptr;
begin
  gspace := gspace32(n);
end;

{ gspace32 - n bytes of cleared space.

  0x07D51C, 0x132 bytes.  n < 0 is reported (cgerr_no_source(28, 0),
  0x07D538; the 6 bytes of arguments padded to 8).  The alignment mask
  (D3): 7 for n > 7, 3 for n > 3, 1 for n > 1, else 0; next_free is
  rounded up by it (`not.l; and.l; add.l; addq.l #1').  When there is no
  chunk or n bytes do not fit before the chunk's end (`cmp.l D4,D1;
  ble'), a chunk of n + 16 bytes, at least 131008 (0x1FFC0) and rounded up
  to 16 (`andi.b #-16; addi.l #16'), is obtained with PAS_$NEW
  (0x07D5B4; a nil one reported, code 9), cleared 16 bytes at a time
  (size div 16 passes, `asr.l #4' with the negative correction), linked
  in at the head, and next_free set past its 8-byte header and aligned
  again.  Then allocated and PRFPKG's in-use count grow by n, the peak
  follows, the result is next_free and next_free moves past n.

  Not known from the original:
  - the locals' names; how the clearing loop was written (the image
    stores through a pointer post-incremented four times a pass, a
    repeat loop counting down). }

function gspace32(
    n: integer32): univ_ptr;
var
  align: integer32;
  size: integer32;
  p: gspace_chunk_ptr_t;
  q: gspace_clear_ptr_t;
  count: integer32;
begin
  if n < 0 then
    cgerr_no_source(28, 0);
  if n > 7 then
    align := 7
  else if n > 3 then
    align := 3
  else if n > 1 then
    align := 1
  else
    align := 0;
  if (next_free & align) <> 0 then
    next_free := (~align & next_free) + align + 1;
  if (head = nil) or
     (next_free + n > integer32(head) + head^.size) then begin
    size := n + 16;
    if size < 16#1FFC0 then
      size := 16#1FFC0;
    if (size & 15) <> 0 then
      size := (size & 16#FFFFFFF0) + 16;
    pas_$new(p, size);
    if p = nil then
      cgerr_no_source(9, 0);
    count := size div 16;
    q := gspace_clear_ptr_t(p);
    repeat
      q^[1] := 0;
      q^[2] := 0;
      q^[3] := 0;
      q^[4] := 0;
      q := gspace_clear_ptr_t(integer32(q) + 16);
      count := count - 1;
    until count = 0;
    p^.next := head;
    p^.size := size;
    head := p;
    next_free := integer32(head) + 8;
    if (next_free & align) <> 0 then
      next_free := (~align & next_free) + align + 1;
  end;
  allocated := allocated + n;
  prf_gspace_in_use := prf_gspace_in_use + n;
  if prf_gspace_in_use > prf_gspace_peak then
    prf_gspace_peak := prf_gspace_in_use;
  gspace32 := univ_ptr(next_free);
  next_free := next_free + n;
end;

{ gspace_$mark - where the next allocation will be.

  0x07D64E, 0x1E bytes: +4 through the result slot to A0. }

function gspace_$mark: univ_ptr;
begin
  gspace_$mark := univ_ptr(next_free);
end;

{ gspace_$release - free the chunks allocated after mark, and clear the
  rest of mark's chunk.

  0x07D66C, 0xC0 bytes.  When there are chunks: while mark lies outside
  the newest chunk (`blt' below its start, `ble' at or past its end; a
  signed test), the chunk is unlinked, its size taken off allocated and
  PRFPKG's in-use count (allocated kept at 0 or more), and it is given
  back with PAS_$DISPOSE (0x07D6B8; the chunk, held in A3, copied to a
  frame temporary to be passed by address); the loop is left when no
  chunk remains (`exit').  Then next_free := mark; when that is not 0
  it is rounded up to 4 and the longwords from it to the chunk's end are
  cleared (a guarded loop counting down).

  Not known from the original:
  - the locals' names. }

procedure gspace_$release(
    in mark: univ_ptr);
var
  c: gspace_chunk_ptr_t;
  used: integer32;
  count: integer32;
  q: gspace_long_ptr_t;
begin
  if head <> nil then begin
    while (integer32(mark) < integer32(head)) or
          (integer32(head) + head^.size <= integer32(mark)) do begin
      c := head;
      head := c^.next;
      allocated := allocated - c^.size;
      prf_gspace_in_use := prf_gspace_in_use - c^.size;
      if allocated < 0 then
        allocated := 0;
      pas_$dispose(c, c^.size);
      if head = nil then
        exit;
    end;
    next_free := integer32(mark);
    if next_free <> 0 then begin
      if (next_free & 3) <> 0 then
        next_free := (-4 & next_free) + 4;
      used := next_free - integer32(head);
      count := (head^.size - used) div 4;
      q := gspace_long_ptr_t(next_free);
      while count > 0 do begin
        q^ := 0;
        q := gspace_long_ptr_t(integer32(q) + 4);
        count := count - 1;
      end;
    end;
  end;
end;

{ gspace_$close - free everything.

  0x07D72C, 0x20 bytes: a nil mark in a frame temporary (`clr.l
  (-4,A6)'), passed by address to gspace_$release. }

procedure gspace_$close;
var
  none: univ_ptr;
begin
  none := nil;
  gspace_$release(none);
end;
