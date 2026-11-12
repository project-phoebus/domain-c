{ bv - the back end's bit vectors (cc.a88k only): one bit per complex
  live range (a live range's complex id, its +4 word), the operations
  on vectors of them, and the data flow vectors of a routine's blocks:
  the lifetimes (live_in, live_gen, transparent, live_out: four a
  block) and the availability (avail_in, avail_out, avail_gen: three
  more), kept in two spaces from rws_$alloc_heap (lir_main_c78, c7c)
  and enlarged when complex ids run past the bits allotted
  (lir_main_c80); lir_main_c84 counts the vectors a block has.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x224C8C  zero (internal)
    --------  0x224CA4  bv_$release_rws_allocation (internal)
    --------  0x224D0E  bv_$test
    --------  0x224D40  bv_$test_and_set
    --------  0x224D86  bv_$test_and_clear
    --------  0x224DCE  bv_$set
    --------  0x224E06  bv_$set_if_not_killed
    --------  0x224E4A  bv_$clear
    --------  0x224E84  bv_$copy
    --------  0x224ECC  bv_$copy_and_test
    --------  0x224F18  bv_$equal
    --------  0x224F72  bv_$or
    --------  0x224FC2  bv_$and
    --------  0x225012  bv_$and_to
    --------  0x225066  bv_$subtract
    --------  0x2250B8  bv_$set1_subsumes_set2
    --------  0x225114  bv_$find_next_val
    --------  0x22519C  bv_$find_next
    --------  0x225242  bv_$allocate_rws_space (internal)
    --------  0x2252A4  bv_$enlarge_complex_id_to_lr_map (internal)
    --------  0x225326  fill_vector (internal)
    --------  0x225370  bv_$make_live_range_complex
    --------  0x2255F0  bv_$allocate_availability_bit_vectors (internal)
    --------  0x2256A4  bv_$initialize_availability_bit_vectors (internal)
    --------  0x22572C  bv_$initialize_lifetimes_bit_vectors (internal)
    --------  0x225846  bv_$create_dfa_bit_vectors
    --------  0x2258EE  bv_$initialize_bit_vectors
    --------  0x22599A  bv_$propagate_lifetimes
    --------  0x225B18  bv_$propagate_availability
    --------  0x225D1C  bv_$release_bit_vectors
    --------  0x225D78  bv_$release_availability_bit_vectors
    --------  0x225DC4  bv_$release_lr_map
    A5 0x485DC8: the module's data (0x98 bytes): five longwords at +0
    .. +0x10 (+0x14 unused) and the 32 masks at +0x18 (initialized).

  The routines that do not load A5 (bv_$release_rws_allocation,
  bv_$allocate_rws_space, bv_$enlarge_complex_id_to_lr_map,
  fill_vector and the three that make the vectors) are internal
  though named bv_$: no other unit calls them.  The vector loops count
  a word from 0 and stop past the last longword ((n + 31) div 32 - 1,
  compared unsigned, tested at the bottom).

  Not known from the original: every local and parameter name, the
  module variables' names. }
module bv;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';

type
  word_index_t = 0..65535;

var
  fill_words: integer32;                { +0: the longwords fill_vector
                                          appends }
  lr_map_size: integer32;               { +4: the entries of the
                                          routine's lr_map }
  old_words: integer32;                 { +8: the longwords fill_vector
                                          copies }
  transparent_fill: bv_word_t;          { +0xC: the new bits of a
                                          transparent vector }
  avail_fill: bv_word_t;                { +0x10: the new bits of an
                                          avail_out vector (all for the
                                          and of all paths) }
  unused_14: integer32;                 { +0x14 }
  { +0x18: masks[k] has bits k..31. }
  masks: array [0..31] of bv_word_t := [
    [0..31], [1..31], [2..31], [3..31], [4..31], [5..31], [6..31],
    [7..31], [8..31], [9..31], [10..31], [11..31], [12..31],
    [13..31], [14..31], [15..31], [16..31], [17..31], [18..31],
    [19..31], [20..31], [21..31], [22..31], [23..31], [24..31],
    [25..31], [26..31], [27..31], [28..31], [29..31], [30..31],
    [31]];

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0).

  0x224C8C, 0x18 bytes, internal, no frame: p at (4,SP), n at (8,SP);
  `addq.l #3; lsr.l #2', `clr.l (A0)+' until the count is 0 (zzzzz
  has the same routine). }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
type
  longs_t = array [1..1000000] of integer32;
var
  q: ^longs_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := 0;
  end;
end;

{ bv_$release_rws_allocation - the space p points to returned to
  rws_$release_heap (bug_check on a bad status) and p cleared; nothing
  for nil.

  0x224CA4, 0x34 bytes, internal: p by address (A2; `tst.l (A2)'); the
  status at -8. }

procedure bv_$release_rws_allocation(
    var p: univ univ_ptr); internal;
var
  status: status_$t;
begin
  if p <> nil then begin
    rws_$release_heap(p, status);
    ok_or_bug_check(status,
      'BV_$RELEASE_RWS_ALLOCATION -- freeing data structure%$');
    p := nil;
  end;
end;

{ bv_$test - whether lr's bit is set in v.

  0x224D0E, 0x32 bytes: the id (+4) `lsr.w #5', `lsl.w #2' the
  longword's offset, `and.w #31' the bit, `btst Dn,Dn; sne'. }

function bv_$test(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean;
begin
  bv_$test := (lr^.id & 31) in v^[rshft(lr^.id, 5)];
end;

{ bv_$test_and_set - whether lr's bit was set in v; set.

  0x224D40, 0x46 bytes: `btst; sne', then `bset' of a cleared register
  or-ed into the longword. }

function bv_$test_and_set(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean;
var
  w: word_index_t;
begin
  w := rshft(lr^.id, 5);
  bv_$test_and_set := (lr^.id & 31) in v^[w];
  v^[w] := v^[w] + [lr^.id & 31];
end;

{ bv_$test_and_clear - whether lr's bit was set in v; cleared.

  0x224D86, 0x48 bytes: `btst; sne', then the mask `not.l' and-ed. }

function bv_$test_and_clear(
    v: bv_ptr_t;
    lr: lr_ptr_t): boolean;
var
  w: word_index_t;
begin
  w := rshft(lr^.id, 5);
  bv_$test_and_clear := (lr^.id & 31) in v^[w];
  v^[w] := v^[w] - [lr^.id & 31];
end;

{ bv_$set - lr's bit set in v.

  0x224DCE, 0x38 bytes: `bset' of a cleared register, `or.l' into the
  longword. }

procedure bv_$set(
    v: bv_ptr_t;
    lr: lr_ptr_t);
var
  w: word_index_t;
begin
  w := rshft(lr^.id, 5);
  v^[w] := v^[w] + [lr^.id & 31];
end;

{ bv_$set_if_not_killed - lr's bit set in v when it is set in
  not_killed.

  0x224E06, 0x44 bytes: not_killed (8) a longword moved to A2; `btst;
  beq' past the `or.l'. }

procedure bv_$set_if_not_killed(
    not_killed: bv_ptr_t;
    lr: lr_ptr_t;
    v: bv_ptr_t);
var
  w: word_index_t;
begin
  w := rshft(lr^.id, 5);
  if (lr^.id & 31) in not_killed^[w] then
    v^[w] := v^[w] + [lr^.id & 31];
end;

{ bv_$clear - lr's bit cleared in v.

  0x224E4A, 0x3A bytes: `bset; not.l; and.l'. }

procedure bv_$clear(
    v: bv_ptr_t;
    lr: lr_ptr_t);
var
  w: word_index_t;
begin
  w := rshft(lr^.id, 5);
  v^[w] := v^[w] - [lr^.id & 31];
end;

{ bv_$copy - dst := src, (n + 31) div 32 longwords.

  0x224E84, 0x48 bytes: `addi.l #31; lsr.l #5; subq.l #1' the last
  index; the word index from 0 (`clr.w', `addq.w #1', zero-extended
  for `cmp.l; bls'); `move.l (A1,D0.w),(A0,D0.w)' with A1 src (12), A0
  dst (16). }

procedure bv_$copy(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t);
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    dst^[i] := src^[i];
end;

{ bv_$copy_and_test - dst := src; whether a bit of it is set.

  0x224ECC, 0x4C bytes: the result cleared (`clr.b D0'), `st' when a
  longword moved (`move.l' from A0, src (12), to A1, dst (16)) is not
  zero. }

function bv_$copy_and_test(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t): boolean;
var
  i: word_index_t;
begin
  bv_$copy_and_test := false;
  for i := 0 to rshft(n + 31, 5) - 1 do begin
    dst^[i] := src^[i];
    if dst^[i] <> [] then
      bv_$copy_and_test := true;
  end;
end;

{ bv_$equal - whether a and b have the same bits.

  0x224F18, 0x5A bytes: `cmp.l; beq' to the next longword, else `clr.b
  D0' and out; `st' after the last. }

function bv_$equal(
    n: linteger;
    a: bv_ptr_t;
    b: bv_ptr_t): boolean;
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    if a^[i] <> b^[i] then begin
      bv_$equal := false;
      return;
    end;
  bv_$equal := true;
end;

{ bv_$or - dst := dst or src.

  0x224F72, 0x50 bytes: `or.l' of src's (12, A1) into dst's (16, A0). }

procedure bv_$or(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t);
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    dst^[i] := dst^[i] + src^[i];
end;

{ bv_$and - dst := dst and src.

  0x224FC2, 0x50 bytes: `and.l' of src's (12, A1) into dst's (16,
  A0). }

procedure bv_$and(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t);
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    dst^[i] := dst^[i] * src^[i];
end;

{ bv_$and_to - dst := a and b.

  0x225012, 0x54 bytes: a (12, A0) and-ed with b (16, A1), stored to
  dst (20, A2). }

procedure bv_$and_to(
    n: linteger;
    a: bv_ptr_t;
    b: bv_ptr_t;
    dst: bv_ptr_t);
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    dst^[i] := a^[i] * b^[i];
end;

{ bv_$subtract - dst := dst and not src.

  0x225066, 0x52 bytes: src's longword (12, A1) `not.l', `and.l' into
  dst's (16, A0).  No result (D0 is the loop's index at the end). }

procedure bv_$subtract(
    n: linteger;
    src: bv_ptr_t;
    dst: bv_ptr_t);
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    dst^[i] := dst^[i] - src^[i];
end;

{ bv_$set1_subsumes_set2 - whether set2 has no bit set1 lacks.

  0x2250B8, 0x5C bytes: set1's longword (12, A0) `not.l', `and.l' with
  set2's (16, A1), `beq' to the next, else `clr.b D0' and out; `st'
  after the last. }

function bv_$set1_subsumes_set2(
    n: linteger;
    set1: bv_ptr_t;
    set2: bv_ptr_t): boolean;
var
  i: word_index_t;
begin
  for i := 0 to rshft(n + 31, 5) - 1 do
    if set2^[i] - set1^[i] <> [] then begin
      bv_$set1_subsumes_set2 := false;
      return;
    end;
  bv_$set1_subsumes_set2 := true;
end;

{ bv_$find_next_val - the number of the first bit of v after bit k, no
  further than the routine's last complex id (l192, +192), or 0.

  0x225114, 0x88 bytes: k + 1 (D1); the longwords to look at, (l192 +
  32) `lsr.l #5' (D2); 0 when k + 1 > l192 (`cmp.l; bgt', signed);
  the first longword and-ed with masks[(k + 1) and 31] (`(0x18,A5,
  D4.w)'); when that is zero the following longwords (`addq.w #1'; out
  with 0 at the limit, `cmp.w; bcc') until one is not, from bit 0; the
  bit by `moveq #1; lsl.l; and.l', counting up; the result the
  longword's index `lsl.w #5', zero-extended (`andi.l #65535'), plus
  the bit. }

function bv_$find_next_val(
    rtn: rtn_ptr_t;
    v: bv_ptr_t;
    k: integer32): integer32;
var
  next: integer32;
  limit: integer32;
  w: word_index_t;
  b: word_index_t;
  bits: bv_word_t;
begin
  next := k + 1;
  limit := rshft(rtn^.l192 + 32, 5);
  w := rshft(next, 5);
  if next > rtn^.l192 then begin
    bv_$find_next_val := 0;
    return;
  end;
  b := next & 31;
  bits := masks[b] * v^[w];
  if bits = [] then begin
    repeat
      w := w + 1;
      if w >= limit then begin
        bv_$find_next_val := 0;
        return;
      end;
      bits := v^[w];
    until bits <> [];
    b := 0;
  end;
  while not (b in bits) do
    b := b + 1;
  bv_$find_next_val := w * 32 + b;
end;

{ bv_$find_next - the live range of v's first bit after lr's (from the
  start for nil) whose lr_map entry is not nil and still has its
  complex id; nil when none is left.

  0x22519C, 0x78 bytes: bug_check when the routine's lr_map (+60) is
  nil; the id a word (D2, cleared for nil); bv_$find_next_val(rtn, v,
  id) zero-extended; nil (`suba.l A0,A0') for 0; the map's entry (`lsl.l
  #2'), `beq' and `tst.w (4,A0); beq' back to the search. }

function bv_$find_next(
    rtn: rtn_ptr_t;
    v: bv_ptr_t;
    lr: lr_ptr_t): lr_ptr_t;
var
  id: word_index_t;
  r: lr_ptr_t;
begin
  if rtn^.lr_map = nil then
    bug_check('BV_$FIND_NEXT -- LR map has been reclaimed.%$');
  if lr = nil then
    id := 0
  else
    id := lr^.id;
  repeat
    id := bv_$find_next_val(rtn, v, id);
    if id = 0 then begin
      bv_$find_next := nil;
      return;
    end;
    r := rtn^.lr_map^[id];
  until (r <> nil) and then (r^.id <> 0);
  bv_$find_next := r;
end;

{ bv_$allocate_rws_space - n bytes from rws_$alloc_heap; bug_check when
  there are none.

  0x225242, 0x2E bytes, internal: n passed on by address (`pea
  (8,A6)'); the pointer at -8, moved to -12 and A0. }

function bv_$allocate_rws_space(
    n: integer32): univ_ptr; options(val_param); internal;
var
  p: univ_ptr;
begin
  p := rws_$alloc_heap(n);
  if p = nil then
    bug_check('BV_$ALLOCATE_RWS_SPACE -- failed (no disk space?)%$');
  bv_$allocate_rws_space := p;
end;

{ bv_$enlarge_complex_id_to_lr_map - room in the routine's lr_map for
  ids up to n (n + 1 entries) when it has fewer: a new map, the old
  entries (up to l192 + 1 of them, no more than the old size) copied,
  the rest cleared, the old map released.

  0x2252A4, 0x82 bytes, internal: n + 1 compared with lr_map_size (A5
  +4, `cmp.l; ble' signed); the copy and the clearing `move.l
  (A1)+,(A0)+' and `clr.l (A0)+' counting down (`subq.l #1; tst.l;
  bgt'). }

procedure bv_$enlarge_complex_id_to_lr_map(
    rtn: rtn_ptr_t;
    n: integer32); options(val_param); internal;
var
  size: integer32;
  new: lr_map_ptr_t;
  old: lr_map_ptr_t;
  m: integer32;
  k: integer32;
begin
  size := n + 1;
  if size > lr_map_size then begin
    new := bv_$allocate_rws_space(size * 4);
    old := rtn^.lr_map;
    m := rtn^.l192 + 1;
    if m > lr_map_size then
      m := lr_map_size;
    for k := 0 to m - 1 do
      new^[k] := old^[k];
    for k := m to size - 1 do
      new^[k] := nil;
    bv_$release_lr_map(rtn);
    rtn^.lr_map := new;
    lr_map_size := size;
  end;
end;

{ fill_vector - a block's vector moved to new: its old_words longwords
  copied, fill_words longwords of fill after them; vec then points to
  new.

  0x225326, 0x4A bytes, internal: vec by address (8), new (12), fill
  (16); the old_words (A5 +8) and fill_words (A5 +0) loops `move.l
  (A1)+,(A0)+' and `move.l D0,(A0)+' counting down. }

procedure fill_vector(
    var vec: bv_ptr_t;
    new: bv_ptr_t;
    fill: bv_word_t); options(val_param); internal;
var
  k: integer32;
begin
  for k := 0 to old_words - 1 do
    new^[k] := vec^[k];
  for k := old_words to old_words + fill_words - 1 do
    new^[k] := fill;
  vec := new;
end;

{ bv_$make_live_range_complex - lr given the next complex id (l192 + 1)
  unless it has one, and entered in the routine's lr_map; then the
  live range at its +16 likewise when that has none.  When the id
  reaches the bits allotted (lir_main_c80), the bits are doubled (no
  further than maxint): the map enlarged, and, when there are
  lifetime vectors (lir_main_c78), every block's vectors (four, seven
  with availability, lir_main_c84) moved to one new space with the
  new bits filled (transparent and avail_out with their fills), both
  old spaces released.

  0x225370, 0x214 bytes: bug_check when lr_map (+60) is nil; `tst.w
  (4,A0); bne' past the numbering; cgerr_no_source(24, idntk(76, ...))
  for an id over 65535 (`cmpi.l #65535; ble') and for one not below
  the doubled count; the new space's size nbbs (+184) times
  lir_main_c84 (M$MIS$LLW), times 4, times the new longwords
  (M$MIS$LLL: (n + 32) div 32); fill_words the new longwords less the
  old ((c80 + 32) div 32, old_words); the blocks along +118 in the
  order live_in (94), live_gen (90), transparent (110), live_out (86),
  and with seven avail_in (122), avail_out (126), avail_gen (130); the
  id the low word of l192 (`move.w (194,A3),(4,A0)'). }

procedure bv_$make_live_range_complex(
    rtn: rtn_ptr_t;
    lr: lr_ptr_t);
var
  n: integer32;
  words: integer32;
  size: integer32;
  space: univ_ptr;
  p: integer32;
  bytes: integer32;
  bb: bb_ptr_t;
begin
  if rtn^.lr_map = nil then
    bug_check('BV_$MAKE_LIVE_RANGE_COMPLEX -- LR map has been reclaimed.%$');
  if lr^.id = 0 then begin
    rtn^.l192 := rtn^.l192 + 1;
    if rtn^.l192 > 65535 then
      cgerr_no_source(24, integer32(idntk(76, 'too many complex IDs', 20)));
    if rtn^.l192 >= lir_main_c80 then begin
      n := lir_main_c80 + lir_main_c80;
      if n > 2147483647 then
        n := 2147483647;
      if rtn^.l192 >= n then
        cgerr_no_source(24,
          integer32(idntk(76, 'too many complex live ranges', 28)));
      bv_$enlarge_complex_id_to_lr_map(rtn, n);
      if lir_main_c78 <> nil then begin
        words := rshft(n + 32, 5);
        size := rtn^.nbbs * lir_main_c84 * 4 * words;
        space := bv_$allocate_rws_space(size);
        p := integer32(space);
        bb := rtn^.bbs;
        bytes := words * 4;
        old_words := rshft(lir_main_c80 + 32, 5);
        fill_words := words - old_words;
        while bb <> nil do begin
          fill_vector(bb^.live_in, bv_ptr_t(p), []);
          p := p + bytes;
          fill_vector(bb^.live_gen, bv_ptr_t(p), []);
          p := p + bytes;
          fill_vector(bb^.transparent, bv_ptr_t(p), transparent_fill);
          p := p + bytes;
          fill_vector(bb^.live_out, bv_ptr_t(p), []);
          p := p + bytes;
          if lir_main_c84 = 7 then begin
            fill_vector(bb^.avail_in, bv_ptr_t(p), []);
            p := p + bytes;
            fill_vector(bb^.avail_out, bv_ptr_t(p), avail_fill);
            p := p + bytes;
            fill_vector(bb^.avail_gen, bv_ptr_t(p), []);
            p := p + bytes;
          end;
          bb := bb^.next;
        end;
        bv_$release_rws_allocation(lir_main_c78);
        bv_$release_rws_allocation(lir_main_c7c);
        lir_main_c78 := space;
      end;
      lir_main_c80 := n;
    end;
    lr^.id := rtn^.l192;
    rtn^.lr_map^[lr^.id] := lr;
  end;
  if lr^.mate <> nil then
    if lr^.mate^.id = 0 then
      bv_$make_live_range_complex(rtn, lr^.mate);
end;

{ bv_$allocate_availability_bit_vectors - the availability vectors for
  n bits: one space (lir_main_c7c) of three vectors a block, cleared
  when zero is set, dealt out as each block's avail_in, avail_out and
  avail_gen; lir_main_c84 gets 3 more.

  0x2255F0, 0xB4 bytes, internal: rtn (8), n (12), zero (16, a byte);
  lir_main_c80 := n after the map is enlarged; the size nbbs times 12
  (`add.l D1,D1; add.l D1,D0; lsl.l #2') times the longwords
  (M$MIS$LLL); zero(space, size). }

procedure bv_$allocate_availability_bit_vectors(
    rtn: rtn_ptr_t;
    n: integer32;
    zero_them: boolean); options(val_param); internal;
var
  words: integer32;
  size: integer32;
  space: univ_ptr;
  p: integer32;
  bb: bb_ptr_t;
begin
  bv_$enlarge_complex_id_to_lr_map(rtn, n);
  lir_main_c80 := n;
  words := rshft(n + 31, 5);
  size := rtn^.nbbs * 12 * words;
  space := bv_$allocate_rws_space(size);
  lir_main_c7c := space;
  if zero_them then
    zero(space, size);
  p := integer32(space);
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.avail_in := bv_ptr_t(p);
    bb^.avail_out := bv_ptr_t(p + words * 4);
    bb^.avail_gen := bv_ptr_t(p + words * 8);
    p := p + words * 12;
    bb := bb^.next;
  end;
  lir_main_c84 := lir_main_c84 + 3;
end;

{ bv_$initialize_availability_bit_vectors - the availability vectors
  for n bits, every block's avail_in and avail_gen cleared and its
  avail_out all ones for the and of all paths (nothing set for
  any_path), which avail_fill remembers.

  0x2256A4, 0x88 bytes, internal: bv_$allocate_availability_bit_vectors
  (rtn, n, false); the fill 0 or -1 (D1); the words of each block from
  0 to the last (`cmp.l; ble', signed, tested at the bottom). }

procedure bv_$initialize_availability_bit_vectors(
    rtn: rtn_ptr_t;
    n: integer32;
    any_path: boolean); options(val_param); internal;
var
  last: integer32;
  fill: bv_word_t;
  bb: bb_ptr_t;
  i: word_index_t;
begin
  bv_$allocate_availability_bit_vectors(rtn, n, false);
  if any_path then
    fill := []
  else
    fill := [0..31];
  last := rshft(n + 31, 5) - 1;
  bb := rtn^.bbs;
  while bb <> nil do begin
    for i := 0 to last do begin
      bb^.avail_in^[i] := [];
      bb^.avail_out^[i] := fill;
      bb^.avail_gen^[i] := [];
    end;
    bb := bb^.next;
  end;
  avail_fill := fill;
end;

{ bv_$initialize_lifetimes_bit_vectors - the lifetime vectors for n
  bits: the old vectors released, the map enlarged, one space
  (lir_main_c78) of four vectors a block (cleared when zero is set),
  dealt out as each block's live_in, live_gen, transparent and
  live_out; without zero each block's are cleared but transparent,
  which is all ones (and transparent_fill too); lir_main_c84 := 4.

  0x22572C, 0x11A bytes, internal: bv_$release_bit_vectors(rtn) first;
  the size nbbs `lsl.l #4' times the longwords (M$MIS$LLL); the words
  of each block from 0 to the last (`cmp.l; ble', signed). }

procedure bv_$initialize_lifetimes_bit_vectors(
    rtn: rtn_ptr_t;
    n: integer32;
    zero_them: boolean); options(val_param); internal;
var
  words: integer32;
  size: integer32;
  space: univ_ptr;
  p: integer32;
  bb: bb_ptr_t;
  i: word_index_t;
begin
  bv_$release_bit_vectors(rtn);
  bv_$enlarge_complex_id_to_lr_map(rtn, n);
  lir_main_c80 := n;
  words := rshft(n + 31, 5);
  size := rtn^.nbbs * 16 * words;
  space := bv_$allocate_rws_space(size);
  lir_main_c78 := space;
  if zero_them then
    zero(space, size);
  p := integer32(space);
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.live_in := bv_ptr_t(p);
    bb^.live_gen := bv_ptr_t(p + words * 4);
    bb^.transparent := bv_ptr_t(p + words * 8);
    bb^.live_out := bv_ptr_t(p + words * 12);
    if not zero_them then
      for i := 0 to words - 1 do begin
        bb^.live_in^[i] := [];
        bb^.live_gen^[i] := [];
        bb^.transparent^[i] := [0..31];
        bb^.live_out^[i] := [];
      end;
    p := p + words * 16;
    bb := bb^.next;
  end;
  lir_main_c84 := 4;
  if not zero_them then
    transparent_fill := [0..31];
end;

{ bv_$create_dfa_bit_vectors - the vectors for the global data flow:
  the old vectors and map released, the bits twice the routine's
  complex ids (no more than maxint) rounded up past a multiple of 32,
  l192 cleared, a new cleared map of that size, and cleared lifetime
  and availability vectors (both fills cleared).

  0x225846, 0xA8 bytes: `add.l D2,D2', `cmpi.l #maxint; ble'; `addi.l
  #32; andi.b #-32'; lir_main_c80 and lr_map_size the count; the map
  `clr.l (A0)+' counting down; the fills `move.l #0'. }

procedure bv_$create_dfa_bit_vectors(
    rtn: rtn_ptr_t);
var
  n: integer32;
  k: integer32;
begin
  bv_$release_bit_vectors(rtn);
  bv_$release_lr_map(rtn);
  n := rtn^.l192 + rtn^.l192;
  if n > 2147483647 then
    n := 2147483647;
  rtn^.l192 := 0;
  n := (n + 32) & ~31;
  lir_main_c80 := n;
  lr_map_size := n;
  rtn^.lr_map := bv_$allocate_rws_space(n * 4);
  for k := 0 to n - 1 do
    rtn^.lr_map^[k] := nil;
  bv_$initialize_lifetimes_bit_vectors(rtn, n, true);
  bv_$allocate_availability_bit_vectors(rtn, n, true);
  transparent_fill := [];
  avail_fill := [];
end;

{ bv_$initialize_bit_vectors - the lifetime vectors (nvectors 4), or
  those and the availability vectors (7), for n bits; bug_check for
  another count.

  0x2258EE, 0x6E bytes: `cmpi.l #4; bne', `cmpi.l #7; bne'. }

procedure bv_$initialize_bit_vectors(
    rtn: rtn_ptr_t;
    n: linteger;
    nvectors: integer32;
    any_path: boolean);
begin
  if nvectors = 4 then
    bv_$initialize_lifetimes_bit_vectors(rtn, n, false)
  else if nvectors = 7 then begin
    bv_$initialize_lifetimes_bit_vectors(rtn, n, false);
    bv_$initialize_availability_bit_vectors(rtn, n, any_path);
  end
  else
    bug_check('BV_$INITIALIZE_BIT_VECTORS -- only 4 and 7 vectors permitted%$');
end;

{ bv_$propagate_lifetimes - the lifetimes solved backwards: over the
  blocks in the routine's +72 order (along +114), live_out the union
  of the successors' live_in (left alone without successors), live_in
  (live_out and transparent) or live_gen, until a pass changes nothing.

  0x22599A, 0x17E bytes: a frame of 4132 bytes, the union in the 4096
  at -4096 (1024 longwords); `st D2' at the start of each pass, `clr.b
  D2' at a change; each comparison runs to the first longword that
  differs and then stores the rest (the word index kept); the block
  at -4124, its vectors at -4112, -4120, the new longword at -4100. }

procedure bv_$propagate_lifetimes(
    n: linteger;
    rtn: rtn_ptr_t);
var
  last: integer32;
  stable: boolean;
  bb: bb_ptr_t;
  e: fg_edge_ptr_t;
  s: bb_ptr_t;
  i, j: word_index_t;
  w: bv_word_t;
  tmp: array [0..1023] of bv_word_t;
begin
  last := rshft(n + 31, 5) - 1;
  repeat
    stable := true;
    bb := rtn^.bbs72;
    while bb <> nil do begin
      e := bb^.succs;
      if e <> nil then begin
        s := e^.target;
        for i := 0 to last do
          tmp[i] := s^.live_in^[i];
        e := e^.next_succ;
        while e <> nil do begin
          s := e^.target;
          for i := 0 to last do
            tmp[i] := tmp[i] + s^.live_in^[i];
          e := e^.next_succ;
        end;
        for i := 0 to last do
          if bb^.live_out^[i] <> tmp[i] then begin
            stable := false;
            for j := i to last do
              bb^.live_out^[j] := tmp[j];
            exit;
          end;
      end;
      for i := 0 to last do begin
        w := (bb^.live_out^[i] * bb^.transparent^[i]) + bb^.live_gen^[i];
        if w <> bb^.live_in^[i] then begin
          stable := false;
          bb^.live_in^[i] := w;
          for j := i + 1 to last do
            bb^.live_in^[j] := (bb^.live_out^[j] * bb^.transparent^[j])
                               + bb^.live_gen^[j];
          exit;
        end;
      end;
      bb := bb^.next114;
    end;
  until stable;
end;

{ bv_$propagate_availability - the availability solved forwards: over
  the blocks in code order (+76, along +118), avail_in the union
  (any_path) or the intersection of the predecessors' avail_out (left
  alone without predecessors), avail_out (avail_in and transparent) or
  avail_gen, until a pass changes nothing.  bug_check when any_path
  does not match how the vectors were made (avail_fill).

  0x225B18, 0x1BE bytes: `tst.l (16,A5); seq; cmp.b; beq'; the
  passes' flag at -4132; the union or intersection chosen for each
  predecessor (`tst.b D4; bpl'); the comparisons as in
  bv_$propagate_lifetimes. }

procedure bv_$propagate_availability(
    n: linteger;
    rtn: rtn_ptr_t;
    any_path: boolean);
var
  last: integer32;
  stable: boolean;
  bb: bb_ptr_t;
  e: fg_edge_ptr_t;
  p: bb_ptr_t;
  i, j: word_index_t;
  w: bv_word_t;
  tmp: array [0..1023] of bv_word_t;
begin
  if (avail_fill = []) <> any_path then
    bug_check('BV_$PROPAGATE_AVAILABILITY -- any_path value conflicts with bv init%$');
  last := rshft(n + 31, 5) - 1;
  repeat
    stable := true;
    bb := rtn^.bbs;
    while bb <> nil do begin
      e := bb^.preds;
      if e <> nil then begin
        p := e^.source;
        for i := 0 to last do
          tmp[i] := p^.avail_out^[i];
        e := e^.next_pred;
        while e <> nil do begin
          p := e^.source;
          if any_path then
            for i := 0 to last do
              tmp[i] := tmp[i] + p^.avail_out^[i]
          else
            for i := 0 to last do
              tmp[i] := tmp[i] * p^.avail_out^[i];
          e := e^.next_pred;
        end;
        for i := 0 to last do
          if bb^.avail_in^[i] <> tmp[i] then begin
            stable := false;
            for j := i to last do
              bb^.avail_in^[j] := tmp[j];
            exit;
          end;
      end;
      for i := 0 to last do begin
        w := (bb^.avail_in^[i] * bb^.transparent^[i]) + bb^.avail_gen^[i];
        if w <> bb^.avail_out^[i] then begin
          stable := false;
          bb^.avail_out^[i] := w;
          for j := i + 1 to last do
            bb^.avail_out^[j] := (bb^.avail_in^[j] * bb^.transparent^[j])
                                 + bb^.avail_gen^[j];
          exit;
        end;
      end;
      bb := bb^.next;
    end;
  until stable;
end;

{ bv_$release_bit_vectors - both vector spaces released, every block's
  lifetime vectors cleared, lir_main_c84 := 0.

  0x225D1C, 0x5C bytes: bv_$release_rws_allocation of lir_main_c78 and
  c7c (`pea 0x48C024'); the blocks' +90, +94, +110, +86. }

procedure bv_$release_bit_vectors(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
begin
  bv_$release_rws_allocation(lir_main_c78);
  bv_$release_rws_allocation(lir_main_c7c);
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.live_gen := nil;
    bb^.live_in := nil;
    bb^.transparent := nil;
    bb^.live_out := nil;
    bb := bb^.next;
  end;
  lir_main_c84 := 0;
end;

{ bv_$release_availability_bit_vectors - the availability space
  released, the blocks' availability vectors cleared, lir_main_c84 3
  less.

  0x225D78, 0x4C bytes: the blocks' +130, +122, +126; `subq.w #3'. }

procedure bv_$release_availability_bit_vectors(
    rtn: rtn_ptr_t);
var
  bb: bb_ptr_t;
begin
  bv_$release_rws_allocation(lir_main_c7c);
  bb := rtn^.bbs;
  while bb <> nil do begin
    bb^.avail_gen := nil;
    bb^.avail_in := nil;
    bb^.avail_out := nil;
    bb := bb^.next;
  end;
  lir_main_c84 := lir_main_c84 - 3;
end;

{ bv_$release_lr_map - the routine's lr_map released, lr_map_size 0.

  0x225DC4, 0x2E bytes: `pea (60,A2)'; `move.l #0,(4,A5)'. }

procedure bv_$release_lr_map(
    rtn: rtn_ptr_t);
begin
  bv_$release_rws_allocation(rtn^.lr_map);
  lr_map_size := 0;
end;
