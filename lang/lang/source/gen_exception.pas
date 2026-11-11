{ gen_exception - GEN_EXCEPTION, the exception table's records in the
  object file: for each frame a frame record (its code's start and
  length, short or long, nested or outermost), a record of its parent
  frame's offset or patched in later, its handlers' variables, its
  cleanup's displacement; at the end the frames still referred to, an
  end record and padding to 8 bytes.  The records are mapped with
  putobj; a patch list (an MRH heap) remembers the records whose parent
  frame was not written yet.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x079FB0  0x07B990  gen_exception_$new_exception
    0x079FC6  0x07B9A6  allocate
    0x07A008  0x07B9E8  make_sure_frame_is_written
    0x07A04E  0x07BA2E  do_patches
    0x07A0AE  0x07BA8E  gen_exception_$begin_exception_compilation
    0x07A178  0x07BB58  add_to_patch_list
    0x07A1AE  0x07BB8E  gen_exception_$write_frame_and_handler_records
    0x07A7FE  0x07C1DE  gen_exception_$end_table
    A5 0x169BF4 (cc.m68k), 0x2E9C64 (cc.a88k): the module's data: +0
    the records' MRH heap, +20 the table's start (the last base
    passed), +24 the patch list.  At -4 the address of pas_$output.

  gen_exception_$new_exception and allocate do not load A5 (internal;
  they run on their caller's A5); make_sure_frame_is_written is nested
  in do_patches (the static link in A1: it adds to do_patches' total
  and passes its offset), add_to_patch_list in
  gen_exception_$write_frame_and_handler_records (no static link).

  The frames, handlers and variables are read by offset (il.ins.pas's
  views); the records by tag (gen_exception_rec_t).

  Not known from the original: every name but the routines'; the
  records' and the frames' fields.
}
module gen_exception;

%include 'lang/lang/source/globals.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'us/us/ins/exception_table.ins.pas';
%include 'lang/lang/source/gen_exception.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/diag.ins.pas';

type
  { A record of the table (2 to 12 bytes; the first byte its tag):
    1 an outermost frame (start, len, size: 8 bytes), 7 the same with a
    long start (10), 2 a nested frame (start, len, size, the parent's
    offset: 10), 8 the same with a long start (12), 5 the frame's own
    offset (4 or 6), 3 and 9 a handler's variable (displacement and
    the variable's word: 6 or 8), 4 and 10 the cleanup's displacement
    (4 or 6), 6 the end, 0 padding. }
  gen_exception_rec_ptr_t = ^gen_exception_rec_t;
  gen_exception_rec_t = packed record
    tag: 0..255;                        { +0 }
    f7: boolean;                        { +1.7: the cleanup is used }
    f6: boolean;                        { +1.6: there are handlers }
    f5: boolean;                        { +1.5 }
    f4: boolean;                        { +1.4: cleared, outermost }
    f_low: 0..15;                       { +1.3..0 }
    case integer of
      1: (w2: integer;                  { +2 }
          w4: integer;                  { +4 }
          w6: integer;                  { +6 }
          w8: integer;                  { +8 }
          w10: integer);                { +10 }
      2: (l2: integer32;                { +2 }
          l_w6: integer;                { +6 }
          l_w8: integer;                { +8 }
          l_w10: integer);              { +10 }
  end;

  { A patch: a nested frame's record waiting for its parent's offset. }
  gen_exception_patch_ptr_t = ^gen_exception_patch_t;
  gen_exception_patch_t = record
    next: gen_exception_patch_ptr_t;    { +0 }
    rec: gen_exception_rec_ptr_t;       { +4 }
    frame: il_$node_ptr_t;              { +8 }
  end;

var
  heap: mrh_$heap_t;                    { +0 }
  table_base: integer32;                { +20 }
  patches: gen_exception_patch_ptr_t;   { +24 }

{ gen_exception_$new_exception - size bytes from the heap.

  0x079FB0, 0x16 bytes, no A5: mrh_$alloc(heap, size), the result left
  in A0. }

function gen_exception_$new_exception(
    size: integer): univ_ptr; options(val_param); internal;
begin
  gen_exception_$new_exception := mrh_$alloc(heap, size);
end;

{ allocate - size bytes of the object file at offset, offset advanced
  to an even offset after them.

  0x079FC6, 0x42 bytes, no A5: putobj(offset, size zero-extended), the
  address kept in a frame slot and left in A0; `add.l', `btst #0' of
  the low byte, `addq.l #1'. }

function allocate(
    var offset: integer32;
    size: integer): gen_exception_rec_ptr_t; options(val_param); internal;
var
  p: gen_exception_rec_ptr_t;
begin
  p := putobj(offset, size);
  offset := offset + size;
  if odd(offset) then
    offset := offset + 1;
  allocate := p;
end;

{ do_patches - the records of the frames the patch list waits for, and
  each patched record's parent offset; the bytes written.

  0x07A04E, 0x60 bytes: total (-6) := 0; while the list is not empty
  its first patch taken off, make_sure_frame_is_written(the frame) (the
  frame in A1), the frame's offset word (+38) stored at +8 of a tag 2
  record, else at +10.  offset (8) is read only by the nested routine. }

function do_patches(
    var offset: integer32): integer;
var
  total: integer;
  p: gen_exception_patch_ptr_t;

  { make_sure_frame_is_written - frame's records (its parent's first)
    unless written (+36 not 0).

    0x07A008, 0x46 bytes: write_frame_and_handler_records(frame, 0, 0,
    +20, the parent's offset), its result added to the parent's
    total. }

  procedure make_sure_frame_is_written(
      frame: il_$node_ptr_t); options(val_param);
  begin
    if frame^.xl[9] = 0 then begin
      if frame^.xp[4] <> nil then
        make_sure_frame_is_written(frame^.xp[4]);
      total := total + gen_exception_$write_frame_and_handler_records(
          frame, 0, 0, table_base, offset);
    end;
  end;

begin
  total := 0;
  while patches <> nil do begin
    p := patches;
    patches := p^.next;
    make_sure_frame_is_written(p^.frame);
    if p^.rec^.tag = 2 then
      p^.rec^.w8 := p^.frame^.xw[19]
    else
      p^.rec^.w10 := p^.frame^.xw[19];
  end;
  do_patches := total;
end;

{ gen_exception_$begin_exception_compilation - the heap and the list
  set up.

  0x07A0AE, 0x5A bytes: writes 'GEN_EXCEPTION_$BEGIN_EXCEPTION_
  COMPILATION -- called begin_exception_compilation' (80 characters)
  to standard output (PAS_$WRITE and PAS_$WRITELN on the file at
  (-4,A5); docs/dpc-gaps.md 4); mrh_$initialize(heap, 0, 12, 'gen_
  exception exception heap%') (the two words pushed as one longword);
  +24 and +20 cleared. }

procedure gen_exception_$begin_exception_compilation;
begin
  writeln('GEN_EXCEPTION_$BEGIN_EXCEPTION_COMPILATION -- called begin_exception_compilation');
  mrh_$initialize(heap, 0, 12, 'gen_exception exception heap%');
  patches := nil;
  table_base := 0;
end;

{ gen_exception_$write_frame_and_handler_records - frame's records.

  0x07A1AE, 0x4DC bytes: +20 := base; a nil frame fails a precondition
  (ass_$precondition_fail); the offset at entry kept (D6).  A nested
  frame (+16, its parent, not nil): start or start + len above 32767
  (signed) a tag 8 record (12 bytes: +2 start, +6 len), else tag 2 (10:
  +2, +4); bit 7 of +1 cleared without a cleanup (+32 nil), set when
  the cleanup's +52 is not 0 (else left); bit 6 as the handler count
  (+24) is not 0; the parent's offset (its +38) at +10 (+8), or the
  record added to the patch list when the parent is not written (+36
  0).  An outermost frame: tag 7 (10) or 1 (8), bit 4 cleared, bits 7
  and 6 as before.  The record's size (12, 10, 10, 8) counted.  A frame
  already written: a tag 5 record of its offset, the word (4 bytes)
  when at most 32767 (`bhi'), else the longword (6 bytes, 4 counted).
  Else its offset := the entry offset less base; for each handler
  (+28, the chain at +72, +24 of them; the counted loops `dbf' with the
  high word's borrow) with variables (+52 not 0), each variable (+48
  + 4 * j, j to the word at +70) a tag 9 (8 bytes, the handler's
  sym_$displacement above 32767) or tag 3 (6) record: an address
  constant (kind 163) its +18 and +1 bits 7..6 := 2; else it must be a
  variable (109), static (its +72 in [1, 4, 7, 8]: `move.w #402; btst')
  in the main section (+20's +192 = IL's +0x110), its +58, bits 7..6
  cleared; a handler left over fails a precondition; a cleanup (+32,
  its +52 not 0) a tag 4 (4) or 10 (6) record of its displacement.
  Last the frame record's size field (tags 1 and 2 +6, 7 and 8 +8: the
  offset's low word less the entry offset; a `case' on the tag, a
  table of 8 from 1).  The result, the bytes counted, a word in D0.

  Not known from the original:
  - the records' fields (by tag and offset here); why the long tag 5
    record counts 4 bytes;
  - the form of the tests of bits 7 and 6 (the cleanup's +52 test
    leaves bit 7 as it was). }

function gen_exception_$write_frame_and_handler_records;
var
  f: il_$node_ptr_t;
  r: gen_exception_rec_ptr_t;
  q: gen_exception_rec_ptr_t;
  e: gen_exception_rec_ptr_t;
  parent: il_$node_ptr_t;
  h: il_$node_ptr_t;
  v: il_$node_ptr_t;
  s: il_$node_ptr_t;
  bytes: integer32;
  entry_offset: integer32;
  disp: integer32;
  i, j: integer32;

  { add_to_patch_list - rec waits for frame's offset.

    0x07A178, 0x36 bytes: a 12-byte patch from the heap at the list's
    head. }

  procedure add_to_patch_list(
      rec: gen_exception_rec_ptr_t;
      frame: il_$node_ptr_t); options(val_param);
  var
    p: gen_exception_patch_ptr_t;
  begin
    p := gen_exception_$new_exception(12);
    p^.rec := rec;
    p^.frame := frame;
    p^.next := patches;
    patches := p;
  end;

begin
  table_base := base;
  f := frame;
  if f = nil then
    ass_$precondition_fail(
        'GEN_EXCEPTION_$WRITE_FRAME_HANDLER_RECORDS -- NIL exception frame%$');
  entry_offset := offset;
  if f^.xp[4] <> nil then begin
    if (start > 32767) or (start + len > 32767) then begin
      r := allocate(offset, 12);
      r^.tag := 8;
      r^.l2 := start;
      r^.l_w6 := len;
    end
    else begin
      r := allocate(offset, 10);
      r^.tag := 2;
      r^.w2 := start;
      r^.w4 := len;
    end;
    if f^.xp[8] = nil then
      r^.f7 := false
    else if f^.xp[8]^.xl[13] <> 0 then
      r^.f7 := true;
    r^.f6 := f^.xl[6] <> 0;
    parent := f^.xp[4];
    if parent^.xl[9] = 0 then
      add_to_patch_list(r, parent)
    else if r^.tag = 8 then
      r^.l_w10 := parent^.xw[19]
    else
      r^.w8 := parent^.xw[19];
    if r^.tag = 8 then
      bytes := 12
    else
      bytes := 10;
  end
  else begin
    if (start > 32767) or (start + len > 32767) then begin
      r := allocate(offset, 10);
      r^.tag := 7;
      r^.l2 := start;
      r^.l_w6 := len;
      bytes := 10;
    end
    else begin
      r := allocate(offset, 8);
      r^.tag := 1;
      r^.w2 := start;
      r^.w4 := len;
      bytes := 8;
    end;
    r^.f4 := false;
    if f^.xp[8] = nil then
      r^.f7 := false
    else if f^.xp[8]^.xl[13] <> 0 then
      r^.f7 := true;
    r^.f6 := f^.xl[6] <> 0;
  end;
  if f^.xl[9] <> 0 then begin
    if (f^.xl[9] >= 0) and (f^.xl[9] <= 32767) then begin
      q := allocate(offset, 4);
      q^.tag := 5;
      q^.w2 := f^.xw[19];
    end
    else begin
      q := allocate(offset, 6);
      q^.tag := 5;
      q^.l2 := f^.xl[9];
    end;
    bytes := bytes + 4;
  end
  else begin
    f^.xl[9] := entry_offset - base;
    h := f^.xp[7];
    for i := 1 to f^.xl[6] do begin
      if h^.xl[13] <> 0 then
        for j := 1 to h^.xw[35] do begin
          v := h^.xp[12 + j];
          disp := sym_$displacement(h);
          if disp > 32767 then begin
            e := allocate(offset, 8);
            e^.tag := 9;
            e^.l2 := disp;
            if v^.kind = 163 then begin
              e^.l_w6 := v^.xw[9];
              e^.f7 := true;
              e^.f6 := false;
            end
            else begin
              if v^.kind <> 109 then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- not a var_name%$');
              if not (v^.xw[36] in [1, 4, 7, 8]) then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- not a static var_name%$');
              if v^.xp[5]^.xp[48] <> il_110 then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- var_name not in main dsect%$');
              e^.l_w6 := v^.xw[29];
              e^.f7 := false;
              e^.f6 := false;
            end;
            bytes := bytes + 8;
          end
          else begin
            e := allocate(offset, 6);
            e^.tag := 3;
            e^.w2 := disp;
            if v^.kind = 163 then begin
              e^.w4 := v^.xw[9];
              e^.f7 := true;
              e^.f6 := false;
            end
            else begin
              if v^.kind <> 109 then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- not a var_name%$');
              if not (v^.xw[36] in [1, 4, 7, 8]) then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- not a static var_name%$');
              if v^.xp[5]^.xp[48] <> il_110 then
                ass_$precondition_fail(
                    'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- var_name not in main dsect%$');
              e^.w4 := v^.xw[29];
              e^.f7 := false;
              e^.f6 := false;
            end;
            bytes := bytes + 6;
          end;
        end;
      h := h^.xp[18];
    end;
    if h <> nil then
      ass_$precondition_fail(
          'GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS -- handler count does not match list%$');
    s := f^.xp[8];
    if (s <> nil) and (s^.xl[13] <> 0) then begin
      disp := sym_$displacement(s);
      if disp <= 32767 then begin
        q := allocate(offset, 4);
        q^.tag := 4;
        q^.w2 := disp;
        bytes := bytes + 4;
      end
      else begin
        q := allocate(offset, 6);
        q^.tag := 10;
        q^.l2 := disp;
        bytes := bytes + 6;
      end;
    end;
  end;
  case r^.tag of
    1, 2: r^.w6 := offset - entry_offset;
    7: r^.l_w8 := offset - entry_offset;
    8: r^.l_w8 := offset - entry_offset;
    otherwise ;
  end;
  gen_exception_$write_frame_and_handler_records := bytes;
end;

{ gen_exception_$end_table - the end of the table.

  0x07A7FE, 0x84 bytes: total := 0 plus do_patches(offset); a tag 6
  record (2 bytes); offset mod 8 (M$OIS$WLW: signed) when positive,
  (8 - it) div 2 (signed) padding records of tag 0, 2 bytes each;
  mrh_$release_all(heap); the total in D0. }

function gen_exception_$end_table;
var
  total: integer;
  r: gen_exception_rec_ptr_t;
  m: integer;
  i: integer;
begin
  total := 0;
  total := total + do_patches(offset);
  r := allocate(offset, 2);
  r^.tag := 6;
  total := total + 2;
  m := offset mod 8;
  if m > 0 then
    for i := 1 to (8 - m) div 2 do begin
      r := allocate(offset, 2);
      r^.tag := 0;
      total := total + 2;
    end;
  mrh_$release_all(heap);
  gen_exception_$end_table := total;
end;
