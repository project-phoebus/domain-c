{ gen_unwind - GEN_UNWIND, the unwind table (and the exception table's
  frame lists) written into the object file.  The back ends add a scope
  for each routine's code (gen_unwind_$add_scope): the scopes are kept
  per section (a psect record), sorted by start and length, and the
  exception frames of a scope hang from it
  (gen_unwind_$add_exception_table_entry).  The exception table is
  written first (gen_unwind_$dump_exception_table, gen_exception's
  records for each frame); then the unwind table: the scopes are
  grouped (at most 10 or 5 to a group, then the groups by twos, a skip
  tree), and each psect gets a header, its groups and scopes a record
  each in the SR10.0 form (an address, a length and a kind, then the
  kind's description of the frame, relocated against the section) or
  the SR10.3 form (range records of the code's offsets, then a record of
  the kind's), and the table is padded to a multiple of 8.  The kind is
  chosen from the scope by target: m68k, PA or a88k (the i860 is not
  implemented).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x07A884  0x07C264  gen_unwind_$begin_compilation
    0x07A8E4  0x07C2C4  gen_unwind_$new_unwind (internal)
    0x07A8FA  0x07C2DA  gen_unwind_$new_exception (internal)
    0x07A910  0x07C2F0  gen_unwind_$dispose_all_unwind (internal)
    0x07A920  0x07C300  gen_unwind_$add_scope
    0x07AA42  0x07C422  reg_mask_is_contiguous (internal)
    0x07AAE0  0x07C4C0  add_skips (in gen_unwind_$dump_unwind_table)
    0x07AB88  0x07C568  allocate (in gen_unwind_$dump_unwind_table)
    0x07ABDE  0x07C5BE  unwind_record_kind_sr10_0 (in gen_unwind_$dump_unwind_table)
    0x07AD34  0x07C714  unwind_record_kind_sr10_3 (in gen_unwind_$dump_unwind_table)
    0x07AF6C  0x07C94C  write_unwind_info_rec (in gen_unwind_$dump_unwind_table)
    0x07B9CA  0x07D3AA  write_range_rec (in gen_unwind_$dump_unwind_table)
    0x07BB04  0x07D4E4  write_padding (in gen_unwind_$dump_unwind_table)
    0x07BBCA  0x07D5AA  scope_rec_dump (in gen_unwind_$dump_unwind_table)
    0x07BE44  0x07D824  write_unwind_header_recs (in psect_rec_dump)
    0x07BFA0  0x07D980  psect_rec_dump (in gen_unwind_$dump_unwind_table)
    0x07C0AE  0x07DA8E  gen_unwind_$dump_unwind_table
    0x07C12E  0x07DB0E  gen_unwind_$add_exception_table_entry
    0x07C24C  0x07DC2C  sub_one (in gen_unwind_$dump_exception_table)
    0x07C2D2  0x07DCB2  gen_unwind_$dump_exception_table
    0x07C392  0x07DD72  gen_unwind_$end_compilation
    A5 0x169C10 (cc.m68k), 0x2E9C80 (cc.a88k): the module's data, 84
    bytes (gen_utils's begins at +0x54): +0 the records' MRH heap, +20
    the psects (.rwdi nil), +24 the unwind table's first exception
    record, +28 the unwind section, +32 the last scope added (.rwdi
    nil), +36 the target (a word), +38 whether there are exceptions,
    +40 the current psect's symbol, +44 its base, +48 the record
    allocate hands out when the table is only sized (to +84).

  gen_unwind_$new_unwind, gen_unwind_$new_exception,
  gen_unwind_$dispose_all_unwind and reg_mask_is_contiguous do not load
  A5 (internal).  The routines nested in gen_unwind_$dump_unwind_table
  reach its offset (-4) and last range start (-12) and its parameters;
  write_unwind_header_recs reaches psect_rec_dump's header record and
  offset.  The SR10.0 and SR10.3 records are a packed record by kind
  (gen_unwind_rec_t), their fields read off the masks.

  The unit opens none of the prelude: putobj (iosub's, declared in
  globals_from_general.ins.pas) is declared here, and the two prelude
  types unix_objmod.ins.pas names (il_$node_ptr_t and
  runbackend_$lex_proc_t) are declared before it is opened
  (docs/questions.md 97, 94).

  Not known from the original: every name but the routines'; the
  records' fields; the PA and a88k fields of the scope (the reads here
  and cc.a88k's bin.pas's prints); the set types the image's register
  masks suggest (fields shifted from a register set without a mask,
  sets of 10..21 and 24..39: integers and shifts here, dpc refusing a
  set not based at 0 in a packed record).
}
module gen_unwind;

%include 'us/us/ins/ubase.ins.pas';
%include 'lang/lang/source/gen_unwind.ins.pas';
%include 'lang/lang/source/real_globals.ins.pas';
%include 'us/us/sys/ins/unwind.ins.pas';
%include 'lang/lang/source/gen_exception.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'us/us/ins/objmod.ins.pas';

type
  { The prelude's (il.ins.pas, globals_from_backend.ins.pas), which
    unix_objmod.ins.pas names: gen_unwind passes only the section's
    record and nil. }
  il_$node_ptr_t = univ_ptr;
  runbackend_$lex_proc_t = ^procedure;

%include 'lang/lang/source/unix_objmod.ins.pas';

type
  gen_unwind_regs_t = set of 0..31;

  { An exception frame of a scope (16 bytes from the heap). }
  gen_unwind_exc_ptr_t = ^gen_unwind_exc_t;
  gen_unwind_exc_t = record
    next: gen_unwind_exc_ptr_t;         { +0 }
    frame: univ_ptr;                    { +4 }
    start: integer32;                   { +8 }
    len: integer32;                     { +12 }
  end;

  { A node of the unwind lists (from the heap): a psect (kind 0, 40
    bytes: its scopes, first to last, and its section), a group of
    scopes or groups (kind 1, 28: the skip records), a scope (kind 2,
    70: the back end's description, its exception frames and their
    offset in the exception table).  start and len cover the code. }
  gen_unwind_node_ptr_t = ^gen_unwind_node_t;
  gen_unwind_node_t = record
    next: gen_unwind_node_ptr_t;        { +0 }
    start: integer32;                   { +4 }
    len: integer32;                     { +8 }
    exceptions: gen_unwind_exc_ptr_t;   { +12 }
    exc_offset: integer32;              { +16 }
    kind: integer32;                    { +20 }
    case integer of
      0: (first: gen_unwind_node_ptr_t; { +24 }
          last: gen_unwind_node_ptr_t;  { +28 }
          base: ^integer32;             { +32 }
          symndx: integer32);           { +36 }
      1: (members: gen_unwind_node_ptr_t); { +24 }
      2: (scope: gen_unwind_$scope_t);  { +24 }
  end;

  { The 64-bit floating registers' mask of kinds 19 and 20. }
  gen_unwind_fr64_t = record
    high: integer32;
    mid: integer;
    low: integer;
  end;

  { A record of the unwind table, by kind.  SR10.0 (form 0): the code's
    address, its length (halved but on the m68k) and the kind at +7:
    0 and 2 the a88k's (2 also the masks), 1 and 3 the m68k's (3 also
    the flags), 4 a group's header (its records' size), 5 a psect's.
    SR10.3 (form 1): the kind at +0: 5 and 6 a range of code (short and
    long: from the last range, halved, and the records' size), 7 and 8
    the a88k's small, 10 its large, 11 and 12 the m68k's, 14 the
    exception table's offset, 15 to 20 the PA's; 0 padding.  The
    exception records the psect header is followed by: 1 the tuple's
    and handler's addresses, 3 the exception table's. }
  gen_unwind_rec_ptr_t = ^gen_unwind_rec_t;
  gen_unwind_rec_t = packed record
    case integer of
      0: (start: integer32;             { +0 }
          len: 0..16777215;             { +4 }
          kind: 0..255;                 { +7 }
          case integer of
            0: (o0_gregs: 0..16383;     { +8: registers 10..23 }
                o0_frame_pushed: boolean;
                o0_b43: boolean;
                o0_sf: 0..4095;         { +10: offset div 4 }
                o0_fregs: 0..15;        { +11 }
                o0_sf4_reg: 0..31;      { +12 }
                o0_sf12_reg: 0..31;
                o0_rp_reg: 0..31;       { +13 }
                o0_rp_saved: boolean;
                o0_b44: boolean;        { +14 }
                o0_regs_pc: 0..255;
                o0_frame_pc: 0..15;     { +15 }
                o0_pad: 0..7;
                o2_gregs: integer32;    { +16: kind 2 }
                o2_fregs1: integer32;   { +20 }
                o2_fregs2: integer32);  { +24 }
            1: (o1_aregs: set of 0..7;  { +8 }
                o1_dregs: set of 0..7;  { +9 }
                o1_fregs: set of 0..15; { +10 }
                o1_x8: integer32;       { +12 }
                o3_b22: boolean;        { +16: kind 3 }
                o3_b23: boolean;
                o3_b24: boolean;
                o3_pad: 0..31;
                o3_pad2: 0..16777215;
                o3_x12: integer32);     { +20 }
            4: (o4_size: integer32));   { +8 }
      1: (nkind: 0..255;                { +0 }
          case integer of
            1: (e_pad: 0..255;          { +1 }
                e_addr1: integer32;     { +2 }
                e_addr2: integer32);    { +6 }
            5: (r5_delta: 0..65535;     { +1 }
                r5_len: 0..65535;       { +3 }
                r5_size: 0..255);       { +5 }
            6: (r6_delta: 0..16777215;  { +1 }
                r6_len: 0..16777215;    { +4 }
                r6_size: 0..16777215);  { +7 }
            7: (r7_gregs: 0..4095;      { +1: registers 10..21 }
                r7_sf: 0..15;           { +2 }
                r7_regs_pc: 0..31;      { +3 }
                r7_has_sf4: boolean;
                r7_has_sf12: boolean;
                r7_rp_saved: boolean);
            10: (r10_pad: 0..255;       { +1 }
                 r10_gregs: integer32;  { +2 }
                 r10_fregs1: integer32; { +6 }
                 r10_fregs2: integer32; { +10 }
                 r10_frame_pushed: boolean; { +14 }
                 r10_b43: boolean;
                 r10_sf: 0..4095;
                 r10_sf4_reg: 0..31;
                 r10_sf12_reg: 0..31;   { +16 }
                 r10_rp_reg: 0..31;     { +17 }
                 r10_rp_saved: boolean;
                 r10_b44: boolean;
                 r10_regs_pc: 0..255;
                 r10_frame_pc: 0..15);  { +18 }
            11: (r11_aregs: 0..15;      { +1: A2..A5 }
                 r11_dregs: 0..63;      { D2..D7 }
                 r11_fregs: 0..63;      { +2: FP2..FP7 }
                 r11_off: -128..127);   { +3 }
            12: (r12_off: -8388608..8388607; { +1 }
                 r12_aregs: set of 0..7; { +4 }
                 r12_dregs: set of 0..7; { +5 }
                 r12_fregs: set of 0..15); { +6 }
            14: (r14_offset: 0..16777215); { +1 }
            15: (r15_first: 0..15;      { +1 }
                 r15_count: 0..15;
                 r15_sf: 0..15;         { +2 }
                 r15_regs_pc: 0..15;
                 case integer of
                   15: (r15_w32: 0..3); { +3 }
                   16: (r16_frame: 0..255));
            17: (r17_regs_pc: 0..255;   { +1 }
                 r17_gregs: 0..65535;   { +2: registers 3..18 }
                 r17_fregs: 0..65535;   { +4: 24..39 }
                 r17_b37: boolean;      { +6 }
                 r17_sf: 0..4095;
                 r17_w32: 0..3;         { +7 }
                 r17_pad: 0..3;
                 r17_frame: 0..32767);  { +8: kind 17 }
            19: (r19_regs_pc: 0..255;   { +1 }
                 r19_gregs: integer32;  { +2 }
                 r19_fregs: gen_unwind_fr64_t; { +6 }
                 r19_b37: boolean;      { +14 }
                 r19_sf: 0..4095;
                 r19_rp_reg: 0..31;
                 r19_w32: 0..3;         { +16 }
                 r19_pad: 0..8191;
                 r19_frame: 0..32767)); { +18: kind 19 }
  end;

var
  heap: mrh_$heap_t;                    { +0 }
  psects: gen_unwind_node_ptr_t := nil; { +20 }
  exc_rec: gen_unwind_rec_ptr_t;        { +24 }
  section: univ_ptr;                    { +28 }
  last_scope: gen_unwind_node_ptr_t := nil; { +32 }
  target: integer;                      { +36 }
  exceptions: boolean;                  { +38 }
  symndx: integer32;                    { +40 }
  base: integer32;                      { +44 }
  buffer: array [0..35] of char;        { +48 }

{ PUTOBJ - iosub.pas's (0x0B5FD0): size bytes of the object file at
  offset mapped, their address returned.  Declared here: gen_unwind
  opens none of the prelude, whose globals_from_general.ins.pas
  declares putobj. }
function putobj(
    offset: integer32;
    size: integer32): univ_ptr; options(val_param); extern;

{ gen_unwind_$begin_compilation - the heap set up and the lists empty.

  0x07A884, 0x46 bytes: +28 := sect; mrh_$initialize(heap, 0, 70,
  'gen_unwind unwind heap%') (the two words pushed as one longword,
  `pea 0x46'); +20 := nil, +36 := target, +38 := false. }

procedure gen_unwind_$begin_compilation;
begin
  section := sect;
  mrh_$initialize(heap, 0, 70, 'gen_unwind unwind heap%');
  psects := nil;
  target := isp;
  exceptions := false;
end;

{ gen_unwind_$new_unwind, gen_unwind_$new_exception - size bytes from
  the heap.

  0x07A8E4, 0x07A8FA, 0x16 bytes each, no A5: mrh_$alloc(heap, size),
  the result left in A0. }

function gen_unwind_$new_unwind(
    size: integer): univ_ptr; options(val_param); internal;
begin
  gen_unwind_$new_unwind := mrh_$alloc(heap, size);
end;

function gen_unwind_$new_exception(
    size: integer): univ_ptr; options(val_param); internal;
begin
  gen_unwind_$new_exception := mrh_$alloc(heap, size);
end;

{ gen_unwind_$dispose_all_unwind - the heap's records given back.

  0x07A910, 0x10 bytes, no A5: mrh_$release_all(heap). }

procedure gen_unwind_$dispose_all_unwind; internal;
begin
  mrh_$release_all(heap);
end;

{ gen_unwind_$add_scope - scope added to the psect of symndx (a new
  psect at the head of the list when there is none), in order of start
  and then length; it becomes the last scope; the psect's start and
  length cover its scopes.

  0x07A920, 0x122 bytes: the psect searched for (`cmp.l (36,A2)'); a
  new one (40 bytes) +20, +24, +28 cleared, +0 the old head, +32 base,
  +36 symndx; the scope's node (70 bytes): +20 := 2, +0 nil, +4 and +8
  the scope's start and length, the scope copied to +24 (46 bytes),
  +12 nil; appended when the psect is empty (+24 and +28) or after the
  last (its start below, or equal and its length below:
  `blt'/`bne'/`bge'), else inserted before the first not below it
  (the chain walked from +24 through the address of each next field,
  `movea.l (A0),A0'); last the psect's +4 from its first and +8 to its
  last's end. }

procedure gen_unwind_$add_scope;
type
  node_pp_t = ^gen_unwind_node_ptr_t;
var
  ps: gen_unwind_node_ptr_t;
  s: gen_unwind_node_ptr_t;
  pp: node_pp_t;
begin
  ps := psects;
  while ps <> nil do begin
    if ps^.symndx = sym then
      exit;
    ps := ps^.next;
  end;
  if ps = nil then begin
    ps := gen_unwind_$new_unwind(40);
    ps^.kind := 0;
    ps^.next := psects;
    ps^.first := nil;
    ps^.last := nil;
    ps^.base := base_addr;
    ps^.symndx := sym;
    psects := ps;
  end;
  s := gen_unwind_$new_unwind(70);
  s^.kind := 2;
  s^.next := nil;
  s^.start := scope.start;
  s^.len := scope.len;
  s^.scope := scope;
  s^.exceptions := nil;
  last_scope := s;
  if ps^.last = nil then begin
    ps^.first := s;
    ps^.last := s;
  end
  else if (ps^.last^.start < s^.start) or
          ((ps^.last^.start = s^.start) and (ps^.last^.len < s^.len)) then begin
    ps^.last^.next := s;
    ps^.last := s;
  end
  else begin
    pp := addr(ps^.first);
    while (pp^^.start < s^.start) or
          ((pp^^.start = s^.start) and (pp^^.len < s^.len)) do
      pp := addr(pp^^.next);
    s^.next := pp^;
    pp^ := s;
  end;
  ps^.start := ps^.first^.start;
  ps^.len := ps^.last^.start - ps^.start + ps^.last^.len;
end;

{ reg_mask_is_contiguous - whether the registers of mask are one run;
  first the lowest (0 for none), count the run's length.

  0x07AA42, 0x9E bytes, no A5: first := -1, count := 0; three counted
  loops over 0..31 (`dbf', the third with the high word's borrow), each
  `in' a `btst' of the register after a range check (`cmp.w; bcs'); the
  result kept in D0 (`st', `clr.b'). }

function reg_mask_is_contiguous(
    mask: gen_unwind_regs_t;
    out first: integer32;
    out count: integer32): boolean; options(val_param); internal;
var
  i: integer32;
  last: integer32;
begin
  first := -1;
  count := 0;
  for i := 0 to 31 do
    if i in mask then begin
      first := i;
      exit;
    end;
  if first = -1 then begin
    first := 0;
    count := 0;
    reg_mask_is_contiguous := true;
  end
  else begin
    last := 32;
    for i := first + 1 to 31 do
      if not (i in mask) then begin
        last := i;
        exit;
      end;
    count := last - first;
    reg_mask_is_contiguous := true;
    for i := last + 1 to 31 do
      if i in mask then begin
        reg_mask_is_contiguous := false;
        exit;
      end;
  end;
end;

{ gen_unwind_$dump_unwind_table - the unwind table written at pos; its
  size.

  0x07C0AE, 0x80 bytes: offset (-4) := pos; at most 10 to a group for
  form 0, else 5 (`tst.w'); each psect's scopes grouped
  (add_skips(ps, max)), then the groups by twos while add_skips finds
  more than one; psect_rec_dump(pos, the psects, form); +20 := nil and
  the heap released.

  Not known from the original:
  - what the frame's -8 held (no instruction reads it). }

function gen_unwind_$dump_unwind_table;
var
  offset: integer32;
  last_pc: integer32;
  ps: gen_unwind_node_ptr_t;
  max: integer;
  size: integer32;

  { add_skips - the members of ps (a psect or a group) gathered into
    groups of max (a group when more than one), the groups in their
    place; whether more than one group results.

    0x07AAE0, 0xA8 bytes: the run counted in D3 (`bge' at max, `bne'
    to go on), the last member kept at -16; a group (28 bytes) +0 nil,
    +4 the first's start, +8 to the last's end, +20 := 1, +24 the first;
    linked from the psect's +24 when the previous is the psect (its +20
    0), else from the previous group's +0; the last member's +0
    cleared.  A run of one left at the end is linked after the groups
    and counted.  The result `cmpi.w #1; sgt'. }

  function add_skips(
      ps: gen_unwind_node_ptr_t;
      max: integer): boolean; options(val_param);
  var
    n: integer;
    k: integer;
    prev: gen_unwind_node_ptr_t;
    p: gen_unwind_node_ptr_t;
    first: gen_unwind_node_ptr_t;
    last: gen_unwind_node_ptr_t;
    g: gen_unwind_node_ptr_t;
  begin
    n := 0;
    prev := ps;
    p := ps^.first;
    while p <> nil do begin
      first := p;
      k := 0;
      repeat
        last := p;
        k := k + 1;
        p := p^.next;
      until (k >= max) or (p = nil);
      if k > 1 then begin
        g := gen_unwind_$new_unwind(28);
        g^.next := nil;
        g^.start := first^.start;
        g^.len := last^.start - first^.start + last^.len;
        g^.kind := 1;
        g^.members := first;
        if prev^.kind = 0 then
          prev^.first := g
        else
          prev^.next := g;
        prev := g;
        n := n + 1;
        last^.next := nil;
      end;
    end;
    if k = 1 then begin
      if n > 0 then
        prev^.next := first;
      n := n + 1;
    end;
    add_skips := n > 1;
  end;

  { allocate - size bytes of the table at offset, offset advanced to an
    even offset after them; when the table is only sized (mode not
    above 0) the module's buffer (+48).

    0x07AB88, 0x56 bytes: mode is the parent's (12) (`tst.l
    (12,A0); bgt'); putobj(offset, size zero-extended); `btst #0' of
    the low byte, `addq.l #1'; the address from a frame slot in A0. }

  function allocate(
      var offset: integer32;
      size: integer): gen_unwind_rec_ptr_t; options(val_param);
  var
    p: gen_unwind_rec_ptr_t;
  begin
    if mode <= 0 then
      p := addr(buffer)
    else
      p := putobj(offset, size);
    offset := offset + size;
    if odd(offset) then
      offset := offset + 1;
    allocate := p;
  end;

  { unwind_record_kind_sr10_0 - the SR10.0 record kind for scope (0..3)
    by target.

    0x07ABDE, 0x94 bytes: the scope copied (46 bytes); a `case' on +36
    (a table of 4): the m68k 3 when any of the flags is set (`or.b' of
    the three, `bpl'), else 1; the i860 and the PA fail a precondition
    ('GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_0 -- i860 unimplemented%$',
    '... -- PA not supported in old format%$'); the a88k 2 when
    registers outside 10..23 (`andi.l #0xFF0003FF') or floating
    registers (+12; +16 `andi.w #0xFF0F' of its low word) are saved,
    else 0; any other target fails ('... -- bad target isp%$'). }

  function unwind_record_kind_sr10_0(
      scope: gen_unwind_$scope_t): integer;
  begin
    case target of
      0:
        if scope.b22 or scope.b23 or scope.b24 then
          unwind_record_kind_sr10_0 := 3
        else
          unwind_record_kind_sr10_0 := 1;
      1:
        ass_$precondition_fail(
            'GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_0 -- i860 unimplemented%$');
      2:
        ass_$precondition_fail(
            'GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_0 -- PA not supported in old format%$');
      3:
        if ((scope.a_gregs & 16#FF0003FF) <> 0) or (scope.a_fregs1 <> 0) or
           ((scope.a_fregs2 & 16#FFFFFF0F) <> 0) then
          unwind_record_kind_sr10_0 := 2
        else
          unwind_record_kind_sr10_0 := 0;
      otherwise
        ass_$precondition_fail(
            'GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_0 -- bad target isp%$');
    end;
  end;

  { unwind_record_kind_sr10_3 - the SR10.3 record kind for scope (7..20)
    by target.

    0x07AD34, 0x1C0 bytes: the scope copied; a `case' on +36: the m68k
    12 when a flag is set, or A0, A1, A6, A7 (`andi.l #0xC3'), D0, D1
    (#3) or FP0, FP1, FP8..FP15 (#0xFF03) are saved, or the offset is
    outside -512..508, else 11; the i860 fails ('GEN_UNWIND_\UNWIND_
    RECORD_KIND_SR10_3 -- i860 unimplemented%$'); the PA: when its
    general registers are one run (reg_mask_is_contiguous) and (+36
    clear and +20 below 4080, or +32 at most 12 and +36 set: `notb',
    `slt', `and.b', `sle', `and.b', `or.b') and +28 at most 60, +24 at
    most 64, no floating registers, +34 31, +16 0, the run from 3 and
    of at most 15: 15 (+36 set) or 16; else when only floating
    registers 24..39 (+12 `lsr.l #8', +16 `andi.l #0xFFFFFF') and
    general registers 3..18 (`andi.l #0xFFF80007') are saved and +34 is
    31: 18 or 17; else 20 or 19; the a88k 10 when floating registers
    are saved or the offsets pass 64, 124 or 0, else 7 when the frame is
    pushed (+42), else 8; any other target fails ('... -- bad target
    isp%$'). }

  function unwind_record_kind_sr10_3(
      scope: gen_unwind_$scope_t): integer;
  var
    first: integer32;
    count: integer32;
  begin
    case target of
      0:
        if (scope.b22 or scope.b23 or scope.b24) or
           ((integer(scope.aregs) & 16#C3) <> 0) or
           ((integer(scope.dregs) & 3) <> 0) or
           ((integer(scope.fregs) & 16#FF03) <> 0) or
           (scope.x8 < -512) or (scope.x8 > 508) then
          unwind_record_kind_sr10_3 := 12
        else
          unwind_record_kind_sr10_3 := 11;
      1:
        ass_$precondition_fail(
            'GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_3 -- i860 unimplemented%$');
      2: begin
        if reg_mask_is_contiguous(gen_unwind_regs_t(scope.pa_gregs),
                                  first, count) then
          if ((not scope.pa_b36 and (scope.pa_frame_size < 4080)) or
              ((scope.pa_w32 <= 12) and scope.pa_b36)) and
             (scope.pa_regs_pc <= 60) and (scope.pa_save_off <= 64) and
             (scope.pa_fregs_hi = 0) and (scope.pa_rp_reg = 31) and
             (scope.pa_fregs_lo = 0) and (first >= 3) and
             (count <= 15) then begin
            if scope.pa_b36 then
              unwind_record_kind_sr10_3 := 15
            else
              unwind_record_kind_sr10_3 := 16;
            return;
          end;
        if (rshft(scope.pa_fregs_hi, 8) = 0) and
           ((scope.pa_fregs_lo & 16#FFFFFF) = 0) and
           (scope.pa_rp_reg = 31) and
           ((scope.pa_gregs & 16#FFF80007) = 0) then
          if scope.pa_b36 then
            unwind_record_kind_sr10_3 := 18
          else
            unwind_record_kind_sr10_3 := 17
        else if scope.pa_b36 then
          unwind_record_kind_sr10_3 := 20
        else
          unwind_record_kind_sr10_3 := 19;
      end;
      3:
        if (scope.a_fregs2 <> 0) or (scope.a_fregs1 <> 0) or
           (scope.a_sf_offset > 64) or (scope.a_regs_pc > 124) or
           (scope.a_frame_pc > 0) then
          unwind_record_kind_sr10_3 := 10
        else if scope.a_frame_pushed then
          unwind_record_kind_sr10_3 := 7
        else
          unwind_record_kind_sr10_3 := 8;
      otherwise
        ass_$precondition_fail(
            'GEN_UNWIND_\UNWIND_RECORD_KIND_SR10_3 -- bad target isp%$');
    end;
  end;

  { write_unwind_info_rec - scope p's record in form (0 SR10.0, 1
    SR10.3; another form writes nothing).

    0x07AF6C, 0x960 bytes.  SR10.0: the offset kept (-28); a `case' on
    the kind (a table of 4, 'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- can't
    get here%$' otherwise); kind 2 32 bytes (+16, +20, +24 the a88k
    masks) joining kind 0's 16 at the a88k fields (+8 registers 10..23
    `lsr.l #10' with no mask; +9 bits 1, 0; +10 the offset div 4 (12
    bits); +11 the second floating mask `lsr.l #4' with no mask; +12,
    +13 the registers at [SF,4] and [SF,12] and the return PC register
    and whether it is saved; +14 bit 7, +14 and +15 the PC offsets div
    4), failing a precondition ('... -- max offset exceeded%$') past
    16380, 1020 or 60; kind 3 24 bytes (+16 bits 7..5 the flags, +20)
    joining kind 1's 16 (+8 and +9 the low bytes of the address and
    data registers, +10 the floating registers, +12 the offset);
    add_reloc(the kept offset, the section, +40, nil); +0 the start plus
    +44, +7 the kind.  The length at +4 is halved for the a88k (kinds 0
    and 2) only.  SR10.3: a `case' on the kind less 7 (a table of 14):
    7 and 8 4 bytes (registers 10..21 `lsr.l #10' with no mask, each
    register saved at [SF,4] and [SF,12] added to them as a set of
    10..21 in a word temporary, `bset'; the offset div 4 less 4; failing
    past 64 or 124); 9 fails ('... -- os_compressed not implemented%$');
    10 20 bytes (the masks at +2, +6, +10; the fields from +14; failing
    past 16384, 1020 or 60); 11 4 bytes (A2..A5, D2..D7, FP2..FP7 `lsr.w
    #2'; the offset div 4); 12 8 (the offset div 4, then the low bytes
    and the word); 11 and 12 fail ('... -- saved_reg_off must be
    multiple of 4%$') when the offset is not; 15 and 16 4 bytes
    (reg_mask_is_contiguous's run less 3 and its length, the offsets div
    4; 16 the frame size div 16, 15 +32 div 4); 17 10 bytes and 18 8
    (+28 div 4, the registers `lsr.l #3', the floating registers
    24..39: `andi.l #0xFFFF00' of +14 and `lsr.l #8'; 17 the frame size
    div 16); 19 20 bytes and 20 18 (the masks: an 8-byte temporary at
    -116, cleared but its last word); 13, 14 and any other kind fail
    ('... -- can't get here%$'); +0 the kind.

  Not known from the original:
  - the set types behind the unmasked stores (registers 10..21 or
    10..23 as a set of their own, the floating registers 24..39);
  - whether the source shared kind 0's and 1's code with kinds 2 and 3
    (one `case' arm each here). }

  procedure write_unwind_info_rec(
      p: gen_unwind_node_ptr_t;
      form: integer); options(val_param);
  var
    kind: integer;
    r: gen_unwind_rec_ptr_t;
    vaddr: integer32;
    first: integer32;
    count: integer32;
    contiguous: boolean;
    fr: gen_unwind_fr64_t;
  begin
    if form = 0 then begin
      vaddr := offset;
      kind := unwind_record_kind_sr10_0(p^.scope);
      case kind of
        0, 2: begin
          if kind = 2 then begin
            r := allocate(offset, 32);
            r^.o2_gregs := p^.scope.a_gregs;
            r^.o2_fregs1 := p^.scope.a_fregs1;
            r^.o2_fregs2 := p^.scope.a_fregs2;
          end
          else
            r := allocate(offset, 16);
          r^.o0_gregs := rshft(p^.scope.a_gregs, 10);
          r^.o0_frame_pushed := p^.scope.a_frame_pushed;
          r^.o0_b43 := p^.scope.a_b43;
          r^.o0_sf := p^.scope.a_sf_offset div 4;
          r^.o0_fregs := rshft(p^.scope.a_fregs2, 4);
          r^.o0_sf4_reg := p^.scope.a_sf4_reg;
          r^.o0_sf12_reg := p^.scope.a_sf12_reg;
          r^.o0_rp_reg := p^.scope.a_rp_reg;
          r^.o0_rp_saved := p^.scope.a_rp_saved;
          r^.o0_b44 := p^.scope.a_b44;
          r^.o0_regs_pc := p^.scope.a_regs_pc div 4;
          r^.o0_frame_pc := p^.scope.a_frame_pc div 4;
          r^.len := p^.len div 2;
          if (p^.scope.a_sf_offset > 16380) or (p^.scope.a_regs_pc > 1020) or
             (p^.scope.a_frame_pc > 60) then
            ass_$precondition_fail(
                'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- max offset exceeded%$');
        end;
        1, 3: begin
          if kind = 3 then begin
            r := allocate(offset, 24);
            r^.o3_b22 := p^.scope.b22;
            r^.o3_b23 := p^.scope.b23;
            r^.o3_b24 := p^.scope.b24;
            r^.o3_x12 := p^.scope.x12;
          end
          else
            r := allocate(offset, 16);
          r^.o1_aregs := p^.scope.aregs;
          r^.o1_dregs := p^.scope.dregs;
          r^.o1_fregs := p^.scope.fregs;
          r^.o1_x8 := p^.scope.x8;
          r^.len := p^.len;
        end;
        otherwise
          ass_$precondition_fail(
              'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- can''t get here%$');
      end;
      add_reloc(vaddr, section, symndx, nil);
      r^.start := base + p^.start;
      r^.kind := kind;
    end
    else if form = 1 then begin
      kind := unwind_record_kind_sr10_3(p^.scope);
      case kind of
        7, 8: begin
          r := allocate(offset, 4);
          r^.r7_gregs := rshft(p^.scope.a_gregs, 10);
          r^.r7_sf := p^.scope.a_sf_offset div 4 - 4;
          r^.r7_regs_pc := p^.scope.a_regs_pc div 4;
          if p^.scope.a_sf4_reg = -1 then
            r^.r7_has_sf4 := false
          else begin
            r^.r7_has_sf4 := true;
            r^.r7_gregs := r^.r7_gregs ! lshft(1, p^.scope.a_sf4_reg - 10);
          end;
          if p^.scope.a_sf12_reg = -1 then
            r^.r7_has_sf12 := false
          else begin
            r^.r7_has_sf12 := true;
            r^.r7_gregs := r^.r7_gregs ! lshft(1, p^.scope.a_sf12_reg - 10);
          end;
          r^.r7_rp_saved := p^.scope.a_rp_saved;
          if (p^.scope.a_sf_offset > 64) or (p^.scope.a_regs_pc > 124) then
            ass_$precondition_fail(
                'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- max offset exceeded%$');
        end;
        9:
          ass_$precondition_fail(
              'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- os_compressed not implemented%$');
        10: begin
          r := allocate(offset, 20);
          r^.r10_gregs := p^.scope.a_gregs;
          r^.r10_fregs1 := p^.scope.a_fregs1;
          r^.r10_fregs2 := p^.scope.a_fregs2;
          r^.r10_frame_pushed := p^.scope.a_frame_pushed;
          r^.r10_b43 := p^.scope.a_b43;
          r^.r10_sf := p^.scope.a_sf_offset div 4 - 4;
          r^.r10_sf4_reg := p^.scope.a_sf4_reg;
          r^.r10_sf12_reg := p^.scope.a_sf12_reg;
          r^.r10_rp_reg := p^.scope.a_rp_reg;
          r^.r10_rp_saved := p^.scope.a_rp_saved;
          r^.r10_b44 := p^.scope.a_b44;
          r^.r10_regs_pc := p^.scope.a_regs_pc div 4;
          r^.r10_frame_pc := p^.scope.a_frame_pc div 4;
          if (p^.scope.a_sf_offset > 16384) or (p^.scope.a_regs_pc > 1020) or
             (p^.scope.a_frame_pc > 60) then
            ass_$precondition_fail(
                'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- max offset exceeded%$');
        end;
        11: begin
          r := allocate(offset, 4);
          r^.r11_aregs := rshft(integer(p^.scope.aregs), 2);
          r^.r11_dregs := rshft(integer(p^.scope.dregs), 2);
          r^.r11_fregs := rshft(integer(p^.scope.fregs), 2);
          r^.r11_off := p^.scope.x8 div 4;
          if (p^.scope.x8 & 3) <> 0 then
            ass_$precondition_fail(
                'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- saved_reg_off must be multiple of 4%$');
        end;
        12: begin
          r := allocate(offset, 8);
          r^.r12_aregs := p^.scope.aregs;
          r^.r12_dregs := p^.scope.dregs;
          r^.r12_fregs := p^.scope.fregs;
          r^.r12_off := p^.scope.x8 div 4;
          if (p^.scope.x8 & 3) <> 0 then
            ass_$precondition_fail(
                'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- saved_reg_off must be multiple of 4%$');
        end;
        15, 16: begin
          r := allocate(offset, 4);
          contiguous := reg_mask_is_contiguous(
              gen_unwind_regs_t(p^.scope.pa_gregs), first, count);
          r^.r15_first := first - 3;
          r^.r15_count := count;
          r^.r15_sf := p^.scope.pa_save_off div 4 - 4;
          r^.r15_regs_pc := p^.scope.pa_regs_pc div 4;
          if kind = 16 then
            r^.r16_frame := p^.scope.pa_frame_size div 16
          else
            r^.r15_w32 := p^.scope.pa_w32 div 4;
        end;
        17, 18: begin
          if kind = 17 then
            r := allocate(offset, 10)
          else
            r := allocate(offset, 8);
          r^.r17_regs_pc := p^.scope.pa_regs_pc div 4;
          r^.r17_gregs := rshft(p^.scope.pa_gregs, 3);
          r^.r17_fregs := lshft(p^.scope.pa_fregs_hi & 16#FF, 8) !
                          rshft(p^.scope.pa_fregs_lo, 24);
          r^.r17_b37 := p^.scope.pa_b37;
          r^.r17_sf := p^.scope.pa_save_off div 4 - 4;
          r^.r17_w32 := p^.scope.pa_w32 div 4;
          if kind = 17 then
            r^.r17_frame := p^.scope.pa_frame_size div 16;
        end;
        19, 20: begin
          if kind = 19 then
            r := allocate(offset, 20)
          else
            r := allocate(offset, 18);
          r^.r19_regs_pc := p^.scope.pa_regs_pc div 4;
          r^.r19_gregs := p^.scope.pa_gregs;
          fr.high := 0;
          fr.mid := 0;
          fr.low := lshft(p^.scope.pa_fregs_hi & 16#FF, 8) !
                    rshft(p^.scope.pa_fregs_lo, 24);
          r^.r19_fregs := fr;
          r^.r19_b37 := p^.scope.pa_b37;
          r^.r19_sf := p^.scope.pa_save_off div 4 - 4;
          r^.r19_rp_reg := p^.scope.pa_rp_reg;
          r^.r19_w32 := p^.scope.pa_w32 div 4;
          if kind = 19 then
            r^.r19_frame := p^.scope.pa_frame_size div 16;
        end;
        otherwise
          ass_$precondition_fail(
              'GEN_UNWIND_\WRITE_UNWIND_INFO_REC -- can''t get here%$');
      end;
      r^.nkind := kind;
    end;
  end;

  { write_range_rec - an SR10.3 range record: the code from start, len
    bytes, the records of size bytes after it; the range's start kept
    (-12).

    0x07B9CA, 0x13A bytes: the long form (6, 10 bytes: the start's
    distance from the last range, halved, 24 bits; the length halved;
    (size + 10) halved) when (size + 6) div 2 passes 255 or the start
    or the length halved pass 65535 (signed `bgt'); else the short (5,
    6 bytes: 16 bits each, the distance taken as a word (`ext.l'), and
    (size + 6) div 2 as a byte). }

  procedure write_range_rec(
      start: integer32;
      len: integer32;
      size: integer32); options(val_param);
  var
    r: gen_unwind_rec_ptr_t;
  begin
    if ((size + 6) div 2 > 255) or (start div 2 > 65535) or
       (len div 2 > 65535) then begin
      r := allocate(offset, 10);
      r^.nkind := 6;
      r^.r6_delta := (start - last_pc) div 2;
      r^.r6_len := len div 2;
      r^.r6_size := (size + 10) div 2;
    end
    else begin
      r := allocate(offset, 6);
      r^.nkind := 5;
      r^.r5_delta := (start - last_pc) div 2;
      r^.r5_len := len div 2;
      r^.r5_size := (size + 6) div 2;
    end;
    last_pc := start;
  end;

  { write_padding - padding records (kind 0, 2 bytes) to bring n bytes
    to a multiple of 8.

    0x07BB04, 0x7C bytes: `divs.w #8; swap' (the remainder); an odd
    count fails a precondition ('GEN_UNWIND_\WRITE_PADDING -- unwind
    size is odd (padding needed = %lsd)%$', the count as a longword at
    -20); 8 is 0; the records counted with `dbf', only their first byte
    cleared (`clr.b'). }

  procedure write_padding(
      n: integer); options(val_param);
  var
    rem: integer;
    pad: integer32;
    k: integer;
    i: integer;
    r: gen_unwind_rec_ptr_t;
  begin
    rem := n mod 8;
    k := 8 - rem;
    if odd(k) then begin
      pad := k;
      ass_$precondition_fail(
          'GEN_UNWIND_\WRITE_PADDING -- unwind size is odd (padding needed = %lsd)%$',
          pad);
    end;
    if k = 8 then
      k := 0;
    for i := 1 to k div 2 do begin
      r := allocate(offset, 2);
      r^.nkind := 0;
    end;
  end;

  { scope_rec_dump - the records of list (groups and scopes) in form.

    0x07BBCA, 0x24E bytes: a group (+20 = 1): SR10.3 a long range record
    (6, 10 bytes: its distance from the last range and length halved,
    the range's start kept), SR10.0 a header (add_reloc of the offset;
    16 bytes at -12: the start plus +44, the length halved but for the
    m68k (+36 0), 4 at +7); its members' records (recursively, the
    static link passed on); then the range's size halved (24 bits at
    +7) or the header's +8 (the bytes since).  A scope: SR10.3 a range
    record whose size is the kind's record's (a `case' on the kind less
    7: 4, 20, 4, 8, 4, 4, 8, 10, 18, 20 in the order of the arms;
    'GEN_UNWIND_\SCOPE_REC_DUMP -- unknown size%$' for 13, 14 and
    others) and 4 more with exceptions (+12); write_unwind_info_rec; in
    SR10.3 a kind 14 record (4 bytes) of the exceptions' offset (+16)
    after it.  Last the list's first start is kept (-12). }

  procedure scope_rec_dump(
      list: gen_unwind_node_ptr_t;
      form: integer); options(val_param);
  var
    p: gen_unwind_node_ptr_t;
    save: integer32;
    hdr: gen_unwind_rec_ptr_t;
    r: gen_unwind_rec_ptr_t;
    k: integer;
    size: integer32;
  begin
    p := list;
    while p <> nil do begin
      if p^.kind = 1 then begin
        if form = 1 then begin
          save := offset;
          r := allocate(offset, 10);
          r^.nkind := 6;
          r^.r6_delta := (p^.start - last_pc) div 2;
          r^.r6_len := p^.len div 2;
          last_pc := p^.start;
        end
        else begin
          save := offset;
          add_reloc(offset, section, symndx, nil);
          hdr := allocate(offset, 16);
          hdr^.start := p^.start + base;
          if target = 0 then
            hdr^.len := p^.len
          else
            hdr^.len := p^.len div 2;
          hdr^.kind := 4;
        end;
        scope_rec_dump(p^.members, form);
        if form = 1 then
          r^.r6_size := (offset - save) div 2
        else
          hdr^.o4_size := offset - save;
      end
      else begin
        if form = 1 then begin
          k := unwind_record_kind_sr10_3(p^.scope);
          case k of
            7, 8, 9: size := 4;
            10: size := 20;
            11: size := 4;
            12: size := 8;
            15: size := 4;
            16: size := 4;
            18: size := 8;
            17: size := 10;
            20: size := 18;
            19: size := 20;
            otherwise
              ass_$precondition_fail(
                  'GEN_UNWIND_\SCOPE_REC_DUMP -- unknown size%$');
          end;
          if p^.exceptions <> nil then
            size := size + 4;
          write_range_rec(p^.start, p^.len, size);
        end;
        write_unwind_info_rec(p, form);
        if (form = 1) and (p^.exceptions <> nil) then begin
          r := allocate(offset, 4);
          r^.nkind := 14;
          r^.r14_offset := p^.exc_offset;
        end;
      end;
      p := p^.next;
    end;
    last_pc := list^.start;
  end;

  { psect_rec_dump - the records of the psects of list from pos in
    form, the last padded; the bytes written.

    0x07BFA0, 0xD4 bytes: for each psect -12 of the parent := 0, +40
    the psect's symbol, +44 its base's longword (0 for nil); one that is
    not a psect (+20 not 0) fails a precondition ('GEN_UNWIND_\PSECT_
    REC_DUMP -- this is not a psect header%$'); its header records; its
    scopes (in SR10.3 a first group's members); after the last
    write_padding(the bytes so far, a word); in SR10.3 the header's +8
    the psect's bytes. }

  function psect_rec_dump(
      pos: integer32;
      list: gen_unwind_node_ptr_t;
      form: integer): integer32; options(val_param);
  var
    hdr: gen_unwind_rec_ptr_t;
    save: integer32;
    ps: gen_unwind_node_ptr_t;
    e: gen_unwind_rec_ptr_t;

    { write_unwind_header_recs - in SR10.3, ps's header (a kind 5
      record of 16 bytes: the start plus +44, the length halved but for
      the m68k, +8 0; its offset and address kept), and when there are
      exceptions the exception table's records: kind 1 (10 bytes: the
      tuple's and handler's addresses, filled by
      gen_unwind_$end_compilation, +24) relocated at +2 and +6 against
      data_sym, kind 3 (6 bytes: table_addr) at +2 against table_sym.

      0x07BE44, 0x15C bytes: psect_rec_dump's frame from its dynamic
      link (`movea.l (A6),A2'), the table's from that's (`movea.l
      (A2),A3'); the first add_reloc's arguments popped 14 bytes (the
      next call's word pushed into the pad, docs/rev889-patterns.md
      51). }

    procedure write_unwind_header_recs(
        ps: gen_unwind_node_ptr_t;
        form: integer); options(val_param);
    begin
      if form = 1 then begin
        save := offset;
        add_reloc(save, section, symndx, nil);
        hdr := allocate(offset, 16);
        hdr^.kind := 5;
        hdr^.start := ps^.start + base;
        if target = 0 then
          hdr^.len := ps^.len
        else
          hdr^.len := ps^.len div 2;
        hdr^.o4_size := 0;
        if exceptions then begin
          add_reloc(offset + 2, section, data_sym, nil);
          add_reloc(offset + 6, section, data_sym, nil);
          e := allocate(offset, 10);
          e^.nkind := 1;
          e^.e_addr1 := 0;
          e^.e_addr2 := 0;
          exc_rec := e;
          add_reloc(offset + 2, section, table_sym, nil);
          e := allocate(offset, 6);
          e^.nkind := 3;
          e^.e_addr1 := table_addr;
        end;
      end;
    end;

  begin
    ps := list;
    while ps <> nil do begin
      last_pc := 0;
      symndx := ps^.symndx;
      if ps^.base = nil then
        base := 0
      else
        base := ps^.base^;
      if ps^.kind <> 0 then
        ass_$precondition_fail(
            'GEN_UNWIND_\PSECT_REC_DUMP -- this is not a psect header%$');
      write_unwind_header_recs(ps, form);
      if (form = 1) and (ps^.first^.kind = 1) then
        scope_rec_dump(ps^.first^.members, form)
      else
        scope_rec_dump(ps^.first, form);
      if ps^.next = nil then
        write_padding(offset - pos);
      if form = 1 then
        hdr^.o4_size := offset - save;
      ps := ps^.next;
    end;
    psect_rec_dump := offset - pos;
  end;

begin
  offset := pos;
  if form = 0 then
    max := 10
  else
    max := 5;
  ps := psects;
  while ps <> nil do begin
    if add_skips(ps, max) then
      repeat
      until not add_skips(ps, 2);
    ps := ps^.next;
  end;
  size := psect_rec_dump(pos, psects, form);
  psects := nil;
  gen_unwind_$dispose_all_unwind;
  gen_unwind_$dump_unwind_table := size;
end;

{ gen_unwind_$add_exception_table_entry - the exception frame of the
  code from start, len bytes, added at the end of the last scope's
  frames (none when frame is nil).

  0x07C12E, 0xA6 bytes: no scope yet fails a precondition
  ('GEN_UNWIND_$ADD_EXCEPTION_TABLE_ENTRY -- no unwind record yet%$');
  a start outside the scope's code ('... -- bad PC (%lsd)%$', start by
  address); +38 := true; a 16-byte record from the heap: +0 nil, +4
  frame, +8 start, +12 len. }

procedure gen_unwind_$add_exception_table_entry;
var
  e: gen_unwind_exc_ptr_t;
  q: gen_unwind_exc_ptr_t;
begin
  if frame <> nil then begin
    if last_scope = nil then
      ass_$precondition_fail(
          'GEN_UNWIND_$ADD_EXCEPTION_TABLE_ENTRY -- no unwind record yet%$');
    if (start < last_scope^.start) or
       (last_scope^.start + last_scope^.len < start) then
      ass_$precondition_fail(
          'GEN_UNWIND_$ADD_EXCEPTION_TABLE_ENTRY -- bad PC (%lsd)%$', start);
    exceptions := true;
    e := gen_unwind_$new_exception(16);
    e^.next := nil;
    e^.frame := frame;
    e^.start := start;
    e^.len := len;
    if last_scope^.exceptions = nil then
      last_scope^.exceptions := e
    else begin
      q := last_scope^.exceptions;
      while q^.next <> nil do
        q := q^.next;
      q^.next := e;
    end;
  end;
end;

{ gen_unwind_$dump_exception_table - the exception frames' records
  written at pos, scope by scope; the bytes written.

  0x07C2D2, 0x78 bytes: offset (-16) := pos; each psect's first scope
  (kept at -8) to sub_one; gen_exception_$end_table(offset)'s word
  added; a total that is not the offset's advance fails a precondition
  ('GEN_UNWIND_$DUMP_EXCEPTION_TABLE -- exception table sizes
  inconsistent%$'). }

function gen_unwind_$dump_exception_table;
var
  offset: integer32;
  first: gen_unwind_node_ptr_t;
  ps: gen_unwind_node_ptr_t;
  total: integer32;

  { sub_one - the records of the frames of list's scopes (a group's
    members when list is one), each scope's offset in the table kept
    (+16); the bytes written.

    0x07C24C, 0x86 bytes: the static link in A1 (pos read at its (8));
    write_frame_and_handler_records(frame, start, len, pos, offset) for
    each frame, its word result extended (`ext.l'). }

  function sub_one(
      list: gen_unwind_node_ptr_t;
      var offset: integer32): integer32; options(val_param);
  var
    total: integer32;
    p: gen_unwind_node_ptr_t;
    e: gen_unwind_exc_ptr_t;
  begin
    total := 0;
    p := list;
    if p^.kind = 1 then
      total := total + sub_one(p^.members, offset)
    else
      while p <> nil do begin
        if p^.exceptions <> nil then
          p^.exc_offset := offset - pos;
        e := p^.exceptions;
        while e <> nil do begin
          total := total + gen_exception_$write_frame_and_handler_records(
              e^.frame, e^.start, e^.len, pos, offset);
          e := e^.next;
        end;
        p := p^.next;
      end;
    sub_one := total;
  end;

begin
  offset := pos;
  total := 0;
  ps := psects;
  while ps <> nil do begin
    first := ps^.first;
    total := total + sub_one(first, offset);
    ps := ps^.next;
  end;
  total := total + gen_exception_$end_table(offset);
  if offset - pos <> total then
    ass_$precondition_fail(
        'GEN_UNWIND_$DUMP_EXCEPTION_TABLE -- exception table sizes inconsistent%$');
  gen_unwind_$dump_exception_table := total;
end;

{ gen_unwind_$end_compilation - the exception table's tuple and handler
  addresses into the unwind table's first exception record (+24) when
  there were exceptions.

  0x07C392, 0x32 bytes: +2 handler_addr, +6 tuple_addr. }

procedure gen_unwind_$end_compilation;
begin
  if exceptions then begin
    exc_rec^.e_addr1 := handler_addr;
    exc_rec^.e_addr2 := tuple_addr;
  end;
end;
