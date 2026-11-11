{ bvs - BVS_, bit vectors: a header (the last longword's index, the
  last bit's number) and the longwords, each a set of 0..31, allocated
  from a MEM_ pool.  Each operation checks its vectors (nil, the bit in
  range, the sizes equal) through ASS_.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0679B4  0x067C34  check (internal)
    0x067A70  0x067CF0  check_same_size (internal)
    0x067B98  0x067E18  check2_same_size (internal)
    0x067CF4  0x067F74  bvs_$create_bit_vector
    0x067D5C  0x067FDC  bvs_$dispose_bit_vector
    0x067DC4  0x068044  bvs_$bit_vector_bit_count
    0x067E28  0x0680A8  bvs_$reset_bit_vector
    0x067EAC  0x06812C  bvs_$test_bit_vector
    0x067F38  0x0681B8  bvs_$test
    0x067F76  0x0681F6  bvs_$test_and_set
    0x067FBC  0x06823C  bvs_$test_and_clear
    0x068004  0x068284  bvs_$set
    0x068042  0x0682C2  bvs_$clear
    0x068082  0x068302  bvs_$copy
    0x0680CC  0x06834C  bvs_$copy_and_test
    0x068112  0x068392  bvs_$equal
    0x06815C  0x0683DC  bvs_$or
    0x0681A0  0x068420  bvs_$and
    0x0681E4  0x068464  bvs_$or_and_test
    0x068230  0x0684B0  bvs_$and_and_test
    0x068282  0x068502  bvs_$and_to
    0x0682D2  0x068552  bvs_$subtract
    0x068316  0x068596  bvs_$set1_subsumes_set2
    0x068362  0x0685E2  bvs_$find_next
    A5 0x14B000 (cc.m68k), 0x2CB000 (cc.a88k): the module's data, 0x80
    bytes to diag's: the 32 masks of bits n..31 (initialized, .rwdi; the
    same in both binaries), which only bvs_$find_next reads.

  The global routines load A5; the check routines, which do not, are
  internal.  The loops over a vector's longwords are `for' loops from 0
  to the last longword's index (`move.w (A2),D0; bmi'; `dbf').
}
module bvs;

%include 'lang/common/source/bvs.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include '/sys/ins/base.ins.pas';

var
  masks: array [0..31] of bvs_$word_t := [
    [0..31], [1..31], [2..31], [3..31], [4..31], [5..31], [6..31], [7..31],
    [8..31], [9..31], [10..31], [11..31], [12..31], [13..31], [14..31],
    [15..31], [16..31], [17..31], [18..31], [19..31], [20..31], [21..31],
    [22..31], [23..31], [24..31], [25..31], [26..31], [27..31], [28..31],
    [29..31], [30..31], [31]
    ];

{ check - v not nil and bit within it.

  0x0679B4, 0x58 bytes, internal: `cmpa.w #0; bne', else
  ass_$precondition_fail('BVS_$CHECK -- NIL bit vector%$') (0x067A0C);
  bit above the last bit (unsigned, `bls'):
  ass_$precondition_fail('BVS_$CHECK -- requested bit (%lsd) is beyond
  end of vector (%lsd)%$' (0x067A2C), bit and the last bit, each
  zero-extended into a frame longword). }

procedure check(
    v: bvs_$t;
    bit: bvs_$bit_t); options(val_param); internal;
var
  last: integer32;                      { (-8,A6) }
  requested: integer32;                 { (-12,A6) }
begin
  if v = nil then
    ass_$precondition_fail('BVS_$CHECK -- NIL bit vector%$');
  if bit > v^.last_bit then begin
    last := v^.last_bit;
    requested := bit;
    ass_$precondition_fail(
      'BVS_$CHECK -- requested bit (%lsd) is beyond end of vector (%lsd)%$',
      requested, last);
  end;
end;

{ check_same_size - src and dst not nil and of the same size.

  0x067A70, 0x74 bytes, internal: the nil checks ('BVS_$CHECK_SAME_SIZE
  -- NIL source bit vector%$' 0x067B34, '... -- NIL destination bit
  vector%$' 0x067B64); different last bits:
  ass_$precondition_fail('BVS_$CHECK_SAME_SIZE -- source (%lsd) is not
  same size as destination (%lsd)%$' (0x067AE4), both zero-extended). }

procedure check_same_size(
    src: bvs_$t;
    dst: bvs_$t); options(val_param); internal;
var
  dst_last: integer32;                  { (-8,A6) }
  src_last: integer32;                  { (-12,A6) }
begin
  if src = nil then
    ass_$precondition_fail('BVS_$CHECK_SAME_SIZE -- NIL source bit vector%$');
  if dst = nil then
    ass_$precondition_fail(
      'BVS_$CHECK_SAME_SIZE -- NIL destination bit vector%$');
  if src^.last_bit <> dst^.last_bit then begin
    dst_last := dst^.last_bit;
    src_last := src^.last_bit;
    ass_$precondition_fail(
      'BVS_$CHECK_SAME_SIZE -- source (%lsd) is not same size as destination (%lsd)%$',
      src_last, dst_last);
  end;
end;

{ check2_same_size - src1, src2 and dst not nil, src1 and dst of the
  same size.

  0x067B98, 0x90 bytes, internal: the nil checks ('... -- NIL source 1
  bit vector%$' 0x067C28, '... source 2 ...' 0x067C5A, the destination's
  0x067B64); src1's last bit against dst's only:
  ass_$precondition_fail('BVS_$CHECK3_SAME_SIZE -- source 1 (%lsd),
  source 2 (%lsd) and destination (%lsd) are not the same size%$'
  (0x067C8C), the three zero-extended).

  Not known from the original:
  - whether src2's size was meant to be compared too. }

procedure check2_same_size(
    src1: bvs_$t;
    src2: bvs_$t;
    dst: bvs_$t); options(val_param); internal;
var
  dst_last: integer32;                  { (-8,A6) }
  src2_last: integer32;                 { (-12,A6) }
  src1_last: integer32;                 { (-16,A6) }
begin
  if src1 = nil then
    ass_$precondition_fail(
      'BVS_$CHECK_SAME_SIZE -- NIL source 1 bit vector%$');
  if src2 = nil then
    ass_$precondition_fail(
      'BVS_$CHECK_SAME_SIZE -- NIL source 2 bit vector%$');
  if dst = nil then
    ass_$precondition_fail(
      'BVS_$CHECK_SAME_SIZE -- NIL destination bit vector%$');
  if src1^.last_bit <> dst^.last_bit then begin
    dst_last := dst^.last_bit;
    src2_last := src2^.last_bit;
    src1_last := src1^.last_bit;
    ass_$precondition_fail(
      'BVS_$CHECK3_SAME_SIZE -- source 1 (%lsd), source 2 (%lsd) and destination (%lsd) are not the same size%$',
      src1_last, src2_last, dst_last);
  end;
end;

{ bvs_$create_bit_vector - a new vector.

  0x067CF4, 0x68 bytes: last := nbits - 1 (zero-extended), at least 31
  (`bge'); the last longword := last div 32 (`lsr.w #5'); the last bit
  := (that + 1) * 32 - 1; MEM_$ALLOC (0x067D34) of (that + 1) * 4 + 4;
  the header set; bvs_$reset_bit_vector (`bsr') with initial; the
  vector in A0.

  Not known from the original:
  - the locals' names. }

function bvs_$create_bit_vector(
    pool: univ_ptr;
    nbits: bvs_$bit_t;
    initial: boolean): bvs_$t;
var
  last: integer32;
  last_word: integer;
  words: integer;
  last_bit: bvs_$bit_t;
  v: bvs_$t;
begin
  last := nbits - 1;
  if last < 31 then
    last := 31;
  last_word := last div 32;
  words := last_word + 1;
  last_bit := words * 32 - 1;
  v := mem_$alloc(pool, words * 4 + 4);
  v^.last_word := last_word;
  v^.last_bit := last_bit;
  bvs_$reset_bit_vector(v, initial);
  bvs_$create_bit_vector := v;
end;

{ bvs_$dispose_bit_vector - v back to the pool.

  0x067D5C, 0x3A bytes: `tst.l (A2); bne', else
  ass_$precondition_fail('BVS_$DISPOSE_BIT_VECTOR -- NIL bit vector%$')
  (0x067D98); MEM_$DISPOSE (0x067D84) of the pool and v. }

procedure bvs_$dispose_bit_vector(
    pool: univ_ptr;
    in out v: bvs_$t);
begin
  if v = nil then
    ass_$precondition_fail('BVS_$DISPOSE_BIT_VECTOR -- NIL bit vector%$');
  mem_$dispose(pool, v);
end;

{ bvs_$bit_vector_bit_count - the last bit + 1 (a word).

  0x067DC4, 0x36 bytes: the nil check ('BVS_$BIT_VECTOR_BIT_COUNT --
  NIL bit vector%$' 0x067DFA). }

function bvs_$bit_vector_bit_count(
    v: bvs_$t): integer;
begin
  if v = nil then
    ass_$precondition_fail('BVS_$BIT_VECTOR_BIT_COUNT -- NIL bit vector%$');
  bvs_$bit_vector_bit_count := v^.last_bit + 1;
end;

{ bvs_$reset_bit_vector - every longword all ones or zero.

  0x067E28, 0x5A bytes: the nil check ('BVS_$RESET_BIT_VECTOR -- NIL
  bit vector%$' 0x067E82); D0 := -1 or 0 by value; each longword :=
  D0. }

procedure bvs_$reset_bit_vector(
    v: bvs_$t;
    value: boolean);
var
  fill: bvs_$word_t;
  i: integer;
begin
  if v = nil then
    ass_$precondition_fail('BVS_$RESET_BIT_VECTOR -- NIL bit vector%$');
  if value then
    fill := [0..31]
  else
    fill := [];
  for i := 0 to v^.last_word do
    v^.words[i] := fill;
end;

{ bvs_$test_bit_vector - whether every longword is all ones (value) or
  zero.

  0x067EAC, 0x62 bytes: the nil check ('BVS_$TEST_BIT_VECTOR -- NIL bit
  vector%$' 0x067F10); a longword unlike D0: false (`clr.b D0') and
  out; true (`st D0') after the loop. }

function bvs_$test_bit_vector(
    v: bvs_$t;
    value: boolean): boolean;
var
  fill: bvs_$word_t;
  i: integer;
begin
  if v = nil then
    ass_$precondition_fail('BVS_$TEST_BIT_VECTOR -- NIL bit vector%$');
  if value then
    fill := [0..31]
  else
    fill := [];
  for i := 0 to v^.last_word do
    if v^.words[i] <> fill then begin
      bvs_$test_bit_vector := false;
      return;
    end;
  bvs_$test_bit_vector := true;
end;

{ bvs_$test - bit's value.

  0x067F38, 0x3E bytes: check (`bsr'); `btst' of bit & 31 in longword
  bit div 32 (`lsr.w #5; lsl.w #2'); `sne'. }

function bvs_$test(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean;
begin
  check(v, bit);
  bvs_$test := (bit & 31) in v^.words[bit div 32];
end;

{ bvs_$test_and_set - bit's value, then bit set.

  0x067F76, 0x46 bytes: as bvs_$test, then `bset' into a mask and
  `or.l' it in. }

function bvs_$test_and_set(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean;
begin
  check(v, bit);
  bvs_$test_and_set := (bit & 31) in v^.words[bit div 32];
  v^.words[bit div 32] := v^.words[bit div 32] + [bit & 31];
end;

{ bvs_$test_and_clear - bit's value, then bit cleared (`not.l; and.l').
  0x067FBC, 0x48 bytes. }

function bvs_$test_and_clear(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean;
begin
  check(v, bit);
  bvs_$test_and_clear := (bit & 31) in v^.words[bit div 32];
  v^.words[bit div 32] := v^.words[bit div 32] - [bit & 31];
end;

{ bvs_$set - bit set.  0x068004, 0x3E bytes. }

procedure bvs_$set(
    v: bvs_$t;
    bit: bvs_$bit_t);
begin
  check(v, bit);
  v^.words[bit div 32] := v^.words[bit div 32] + [bit & 31];
end;

{ bvs_$clear - bit cleared.  0x068042, 0x40 bytes. }

procedure bvs_$clear(
    v: bvs_$t;
    bit: bvs_$bit_t);
begin
  check(v, bit);
  v^.words[bit div 32] := v^.words[bit div 32] - [bit & 31];
end;

{ bvs_$copy - dst := src.  0x068082, 0x4A bytes: check_same_size
  (`bsr'), then the longwords copied. }

procedure bvs_$copy(
    src: bvs_$t;
    dst: bvs_$t);
var
  i: integer;
begin
  check_same_size(src, dst);
  for i := 0 to src^.last_word do
    dst^.words[i] := src^.words[i];
end;

{ bvs_$copy_and_test - dst := src; whether src has a bit set.

  0x0680CC, 0x46 bytes: D0 := false; each longword moved (`move.l
  (4,A2,..),(4,A3,..); beq'), true when it is not zero. }

function bvs_$copy_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean;
var
  any: boolean;
  i: integer;
begin
  check_same_size(src, dst);
  any := false;
  for i := 0 to src^.last_word do begin
    dst^.words[i] := src^.words[i];
    if src^.words[i] <> [] then
      any := true;
  end;
  bvs_$copy_and_test := any;
end;

{ bvs_$equal - whether a and b have the same bits.

  0x068112, 0x4A bytes: a longword unlike the other's: false and out;
  true after the loop. }

function bvs_$equal(
    a: bvs_$t;
    b: bvs_$t): boolean;
var
  i: integer;
begin
  check_same_size(a, b);
  for i := 0 to a^.last_word do
    if a^.words[i] <> b^.words[i] then begin
      bvs_$equal := false;
      return;
    end;
  bvs_$equal := true;
end;

{ bvs_$or - dst := dst + src (`or.l').  0x06815C, 0x44 bytes. }

procedure bvs_$or(
    src: bvs_$t;
    dst: bvs_$t);
var
  i: integer;
begin
  check_same_size(src, dst);
  for i := 0 to src^.last_word do
    dst^.words[i] := dst^.words[i] + src^.words[i];
end;

{ bvs_$and - dst := dst * src (`and.l').  0x0681A0, 0x44 bytes. }

procedure bvs_$and(
    src: bvs_$t;
    dst: bvs_$t);
var
  i: integer;
begin
  check_same_size(src, dst);
  for i := 0 to src^.last_word do
    dst^.words[i] := dst^.words[i] * src^.words[i];
end;

{ bvs_$or_and_test - dst := dst + src; whether src has a bit set (`tst.l
  (4,A2,..)', src's longword).  0x0681E4, 0x4C bytes. }

function bvs_$or_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean;
var
  any: boolean;
  i: integer;
begin
  check_same_size(src, dst);
  any := false;
  for i := 0 to src^.last_word do begin
    dst^.words[i] := dst^.words[i] + src^.words[i];
    if src^.words[i] <> [] then
      any := true;
  end;
  bvs_$or_and_test := any;
end;

{ bvs_$and_and_test - dst := dst * src; whether src has a bit set (the
  test reads src's longword too).  0x068230, 0x52 bytes.

  Not known from the original:
  - whether dst's longword was meant to be tested. }

function bvs_$and_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean;
var
  any: boolean;
  i: integer;
begin
  check_same_size(src, dst);
  any := false;
  for i := 0 to src^.last_word do begin
    dst^.words[i] := dst^.words[i] * src^.words[i];
    if src^.words[i] <> [] then
      any := true;
  end;
  bvs_$and_and_test := any;
end;

{ bvs_$and_to - dst := src1 * src2.  0x068282, 0x50 bytes:
  check2_same_size (`bsr'), the loop over src1's longwords. }

procedure bvs_$and_to(
    src1: bvs_$t;
    src2: bvs_$t;
    dst: bvs_$t);
var
  i: integer;
begin
  check2_same_size(src1, src2, dst);
  for i := 0 to src1^.last_word do
    dst^.words[i] := src1^.words[i] * src2^.words[i];
end;

{ bvs_$subtract - dst := dst - src (`not.l; and.l').  0x0682D2, 0x44
  bytes. }

procedure bvs_$subtract(
    src: bvs_$t;
    dst: bvs_$t);
var
  i: integer;
begin
  check_same_size(src, dst);
  for i := 0 to src^.last_word do
    dst^.words[i] := dst^.words[i] - src^.words[i];
end;

{ bvs_$set1_subsumes_set2 - whether every bit of set2 is in set1.

  0x068316, 0x4C bytes: a longword with ~set1 & set2 not zero: false
  and out; true after the loop. }

function bvs_$set1_subsumes_set2(
    set1: bvs_$t;
    set2: bvs_$t): boolean;
var
  i: integer;
begin
  check_same_size(set1, set2);
  for i := 0 to set1^.last_word do
    if (set2^.words[i] - set1^.words[i]) <> [] then begin
      bvs_$set1_subsumes_set2 := false;
      return;
    end;
  bvs_$set1_subsumes_set2 := true;
end;

{ bvs_$find_next - the first set bit after bit.

  0x068362, 0xB0 bytes: the nil check ('BVS_$FIND_NEXT_VAL -- NIL bit
  vector%$' 0x068412); D0 := 32769; bit = 32769 or bit + 1 beyond the
  last bit (`blt'): out.  The first longword's bits from bit + 1 on (the
  mask at (0,A5,..) and the longword, kept in D1); none: the next
  longwords up to the last until one is not zero (none: 32769), from its
  bit 0.  Then the bits counted up (`moveq #1; lsl.l; and.l') to the
  first set; the result longword * 32 + bit, or 32769 when that is
  beyond the last bit.

  Not known from the original:
  - how the loops and exits were written; the bit tests here read the
    vector's longword where the image tests its register copy (the same
    bits from the starting bit on). }

function bvs_$find_next(
    v: bvs_$t;
    bit: integer32): integer32;
var
  next: integer32;
  last: integer32;
  w: integer;
  b: integer;
begin
  if v = nil then
    ass_$precondition_fail('BVS_$FIND_NEXT_VAL -- NIL bit vector%$');
  bvs_$find_next := bvs_$none;
  if bit = bvs_$none then
    return;
  next := bit + 1;
  last := v^.last_bit;
  if last < next then
    return;
  w := next div 32;
  b := next & 31;
  if (masks[b] * v^.words[w]) = [] then begin
    repeat
      if w = v^.last_word then
        return;
      w := w + 1;
    until v^.words[w] <> [];
    b := 0;
  end;
  while not (b in v^.words[w]) do
    b := b + 1;
  next := w * 32 + b;
  if next > last then
    bvs_$find_next := bvs_$none
  else
    bvs_$find_next := next;
end;
