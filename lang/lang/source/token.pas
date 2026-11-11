{ token - TOKEN, the literal constants' nodes, each value entered once:
  integer constants in 2176 chains sorted by value, reals in 16 chains
  per precision sorted by their longwords, complex values and real pairs
  in one sorted chain each, strings in one chain sorted by length and
  characters, sets of more than two words in chains by size.  il.pas's
  initialize_module empties the tables.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x098BD4  0x09A5B4  smcontk
    0x098C82  0x09A662  floating_token (internal)
    0x098D82  0x09A762  rlcontk
    0x098E1E  0x09A7FE  dpcontk
    0x098E48  0x09A828  get_reciprocal
    0x098E8E  0x09A86E  cmplxtk
    0x098F2E  0x09A90E  token_$make_real_lit_pair
    0x099020  0x09AA00  dpcmplxtk
    0x0990F0  0x09AAD0  strtk
    0x0991A6  0x09AB86  token_$make_string_token
    0x0991D0  0x09ABB0  setcontk
    0x09930E  0x09ACEE  set_is_nil
    A5 0x19DF90 (cc.m68k), 0x31E000 (cc.a88k): the module's data, 0x2384
    bytes: the chains (token.ins.pas).  Nothing is initialized.

  The global routines load A5; floating_token, which does not, is
  internal.  Real arithmetic is the FPP emulator's (`jsr fpp_$' and
  inline operation words, docs/rev889-patterns.md 13); dpc has none yet
  (docs/dpc-gaps.md 2).
}
module token;

%include 'lang/lang/source/globals.ins.pas';

define
  token_set_chains,                     { +0x0 }
  token_real_chains,                    { +0xF8 }
  token_dreal_chains,                   { +0x138 }
  token_integer_chains,                 { +0x178 }
  token_string_chain,                   { +0x2378 }
  token_dcomplex_chain,                 { +0x237C }
  token_pair_chain;                     { +0x2380 }

type
  { A double as its two longwords, high first. }
  token_bits_t = array [1..2] of integer32;
  token_bits_ptr_t = ^token_bits_t;
  token_chains_ptr_t = ^token_chain_array_t;
  token_chain_array_t = array [0..15] of il_$node_ptr_t;

{ smcontk - the integer constant node of kind with value (12 bytes).

  0x098BD4, 0xAE bytes.  The chain: for kind 81 (`cmpi.w #81') value &
  1023, or for a negative value 1024 + (value & 127); for other kinds
  1152 + (value & 1023).  The chain is sorted by value: an entry of the
  value and kind is the result; the search stops at a greater value.  A
  new node (gspace, 12 bytes) is linked in before it (at the chain's
  head when no entry was passed: a byte flag, D5), with kind and value.

  Not known from the original:
  - the locals' names. }

function smcontk(
    kind: integer;
    value: integer32): il_$node_ptr_t;
var
  h: integer32;
  first: boolean;
  p, prev, t: il_$node_ptr_t;
begin
  if kind <> 81 then
    h := (value & 1023) + 1152
  else if value >= 0 then
    h := value & 1023
  else
    h := (value & 127) + 1024;
  first := true;
  p := token_integer_chains[h];
  while p <> nil do begin
    if (value = p^.int_value) and (kind = p^.kind) then begin
      smcontk := p;
      return;
    end;
    if value < p^.int_value then
      exit;
    first := false;
    prev := p;
    p := p^.int_next;
  end;
  t := gspace(12);
  t^.int_next := p;
  if first then
    token_integer_chains[h] := t
  else
    prev^.int_next := t;
  t^.kind := kind;
  t^.int_value := value;
  smcontk := t;
end;

{ floating_token - the real constant node of kind (88 single, else
  double) with the value whose longwords are value.

  0x098C82, 0x100 bytes, internal (no A5 load; its callers' A5).  The
  high longword 16#80000000 with a low one of 0 (-0) is taken as 0.  The
  chains: token_real_chains for kind 88, else token_dreal_chains (the
  address kept in a frame cell, -8); the chain bits 23..20 of the high
  longword (`clr.w; swap; lsr.l #4; andi.l #15').  Sorted by the high
  longword, then the low (signed compares): an equal entry is the
  result, a greater one stops the search.  A new node (24 bytes) is
  linked in before it with kind, the longwords and, when the low
  longword and the high one's 20 mantissa bits are 0, the flags: the
  exponent (bits 30..20) in 897..1149 sets both, else in 1..2045 sets
  real_single_range.

  Not known from the original:
  - the locals' names; whether the flags' test was meant to be this
    narrow (only mantissas of no fraction bits). }

function floating_token(
    in value: univ token_bits_t;
    kind: integer): il_$node_ptr_t; internal;
var
  hi, lo: integer32;
  chains: token_chains_ptr_t;
  h: integer32;
  first: boolean;
  p, prev, t: il_$node_ptr_t;
  e: integer32;
begin
  lo := value[2];
  if lo <> 0 then
    hi := value[1]
  else if value[1] = 16#80000000 then
    hi := 0
  else
    hi := value[1];
  if kind = 88 then
    chains := addr(token_real_chains)
  else
    chains := addr(token_dreal_chains);
  first := true;
  h := rshft(hi, 20) & 15;
  p := chains^[h];
  while p <> nil do begin
    if hi < p^.bits[1] then
      exit;
    if hi = p^.bits[1] then begin
      if lo = p^.bits[2] then begin
        floating_token := p;
        return;
      end;
      if lo < p^.bits[2] then
        exit;
    end;
    first := false;
    prev := p;
    p := p^.real_next;
  end;
  t := gspace(24);
  if first then
    chains^[h] := t
  else
    prev^.real_next := t;
  t^.kind := kind;
  t^.real_next := p;
  t^.bits[1] := hi;
  t^.bits[2] := lo;
  if (lo = 0) and ((t^.bits[1] & 16#FFFFF) = 0) then begin
    e := rshft(t^.bits[1] & 16#7FF00000, 20);
    if (e >= 897) and (e <= 1149) then begin
      t^.real_single_exact := true;
      t^.real_single_range := true;
    end
    else if (e > 0) and (e <= 2045) then
      t^.real_single_range := true;
  end;
  floating_token := t;
end;

{ rlcontk - the node of a single-precision real (kind 88).

  0x098D82, 0x9C bytes.  The value's longwords are copied to a local
  (-8, -4).  With cargs_$options.frnd (+0x27F bit 6, `btst #6,0x2C366B'):
  m := the high longword & 16#FFFFF, e := m & 16#7FF00000; unless e is
  16#7FF00000 or 0, the low longword is rounded to single precision: a
  low longword whose bits 29..0 are 16#10000000 (a tie) has its low 29
  bits cleared; else 16#10000000 is added (`addi.b #16' to its high
  byte), a carry out of it (negative before, not after) adds 1 to the
  high longword, and the low 29 bits are cleared.  Then
  floating_token(local, 88) (0x098E0E), whose result is the result.

  Not known from the original:
  - the locals' names.  e is taken from the mantissa bits, so it is
    always 0 and the rounding never happens: kept as the image does
    it. }

function rlcontk(
    in value: double): il_$node_ptr_t;
var
  pv: token_bits_ptr_t;
  r: token_bits_t;
  m, e: integer32;
  neg: boolean;
begin
  pv := addr(value);
  r[1] := pv^[1];
  r[2] := pv^[2];
  if cargs_$options.frnd then begin
    m := r[1] & 16#FFFFF;
    e := m & 16#7FF00000;
    if (e <> 16#7FF00000) and (e <> 0) then begin
      if (r[2] & 16#3FFFFFFF) = 16#10000000 then
        r[2] := r[2] & 16#E0000000
      else begin
        neg := r[2] < 0;
        r[2] := r[2] + 16#10000000;
        if neg and (r[2] >= 0) then
          r[1] := r[1] + 1;
        r[2] := r[2] & 16#E0000000;
      end;
    end;
  end;
  rlcontk := floating_token(r, 88);
end;

{ dpcontk - the node of a double-precision real (kind 89).

  0x098E1E, 0x2A bytes: floating_token(value, 89). }

function dpcontk(
    in value: double): il_$node_ptr_t;
begin
  dpcontk := floating_token(value, 89);
end;

{ get_reciprocal - the node of 1 / t's value, of t's kind.

  0x098E48, 0x46 bytes: `jsr fpp_$' with the operands' addresses (a
  local double, -12, and t's value, +12) and the operation words 0x0078
  (the immediate double 1.0 follows), 0x00A4, 0x0080; then
  floating_token(the local, t's kind).

  Not known from the original:
  - the local's name. }

function get_reciprocal(
    t: il_$node_ptr_t): il_$node_ptr_t;
var
  r: double;
begin
  r := 1.0 / t^.real_value;
  get_reciprocal := floating_token(r, t^.kind);
end;

{ cmplxtk - the node of a single-precision complex (kind 90).

  0x098E8E, 0xA0 bytes.  re's and im's longwords (16#80000000, -0, taken
  as 0); token_pair_chain is sorted by re then im (signed): an equal
  entry is the result, a greater one stops the search.  A new node (20
  bytes) is linked in before it (at the head when none was passed, a
  byte flag) with kind 90, re, im and +8 cleared.

  Not known from the original:
  - the locals' names. }

function cmplxtk(
    in re: real;
    in im: real): il_$node_ptr_t;
var
  pre, pim: ^integer32;
  a, b: integer32;
  first: boolean;
  p, prev, t: il_$node_ptr_t;
begin
  pre := addr(re);
  pim := addr(im);
  if pre^ = 16#80000000 then
    a := 0
  else
    a := pre^;
  if pim^ = 16#80000000 then
    b := 0
  else
    b := pim^;
  first := true;
  p := token_pair_chain;
  while p <> nil do begin
    if a = p^.pair_a then begin
      if b = p^.pair_b then begin
        cmplxtk := p;
        return;
      end;
      if b < p^.pair_b then
        exit;
    end
    else if a < p^.pair_a then
      exit;
    first := false;
    prev := p;
    p := p^.pair_next;
  end;
  t := gspace(20);
  t^.pair_next := p;
  if first then
    token_pair_chain := t
  else
    prev^.pair_next := t;
  t^.kind := 90;
  t^.pair_a := a;
  t^.pair_b := b;
  t^.pair_unused_8 := 0;
  cmplxtk := t;
end;

{ token_$make_real_lit_pair - the kind 90 node of a and b converted to
  single precision.

  0x098F2E, 0xF2 bytes.  Each double is converted by `jsr fpp_$' (the
  operation words 0x0074, 0x00D4, 0xFF3E) into a temporary (-36) and
  moved to a local (-16, -12); 16#80000000 (-0) is taken as 0.
  found_swapped := false.  token_pair_chain as in cmplxtk (the previous
  entry nil until one is passed, `suba.l A3,A3'), except that unless
  exact (`tst.b D6; bmi'), an entry whose a is b and b is a is the
  result with found_swapped true.

  Not known from the original:
  - the locals' names. }

function token_$make_real_lit_pair(
    in a: double;
    in b: double;
    exact: boolean;
    var found_swapped: boolean): il_$node_ptr_t;
var
  sa, sb: record case integer of
    1: (r: real);
    2: (i: integer32);
  end;
  ia, ib: integer32;
  p, prev, t: il_$node_ptr_t;
begin
  sa.r := a;
  sb.r := b;
  ia := sa.i;
  ib := sb.i;
  if ia = 16#80000000 then
    ia := 0;
  if ib = 16#80000000 then
    ib := 0;
  found_swapped := false;
  prev := nil;
  p := token_pair_chain;
  while p <> nil do begin
    if ia = p^.pair_a then begin
      if ib = p^.pair_b then begin
        token_$make_real_lit_pair := p;
        return;
      end;
      if ib < p^.pair_b then
        exit;
    end
    else begin
      if (ia = p^.pair_b) and (ib = p^.pair_a) and not exact then begin
        found_swapped := true;
        token_$make_real_lit_pair := p;
        return;
      end;
      if ia < p^.pair_a then
        exit;
    end;
    prev := p;
    p := p^.pair_next;
  end;
  t := gspace(20);
  t^.pair_next := p;
  if prev = nil then
    token_pair_chain := t
  else
    prev^.pair_next := t;
  t^.kind := 90;
  t^.pair_a := ia;
  t^.pair_b := ib;
  t^.pair_unused_8 := 0;
  token_$make_real_lit_pair := t;
end;

{ dpcmplxtk - the node of a double-precision complex (kind 198).

  0x099020, 0xD0 bytes.  token_dcomplex_chain is sorted by re's
  longwords then im's (signed, high first; the four compared through re's
  address and im): an equal entry is the result; the search stops at an
  entry with a greater re, or an equal re and a greater im.  A new node
  (28 bytes) is linked in before it (at the head when none was passed, a
  byte flag) with kind 198, the four longwords and +8 cleared.

  Not known from the original:
  - the locals' names; how the comparisons were grouped (the image tests
    high < first, then low >= to go on, then high = to stop). }

function dpcmplxtk(
    in re: double;
    im: univ_ptr): il_$node_ptr_t;
var
  pre, pim: token_bits_ptr_t;
  first: boolean;
  p, prev, t: il_$node_ptr_t;
begin
  pre := addr(re);
  pim := im;
  first := true;
  p := token_dcomplex_chain;
  while p <> nil do begin
    if (pre^[1] = p^.bits[1]) and (pre^[2] = p^.bits[2]) then begin
      if (pim^[1] = p^.bits[3]) and (pim^[2] = p^.bits[4]) then begin
        dpcmplxtk := p;
        return;
      end;
      if (pim^[1] < p^.bits[3]) or
         ((pim^[1] = p^.bits[3]) and (pim^[2] < p^.bits[4])) then
        exit;
    end
    else if (pre^[1] < p^.bits[1]) or
            ((pre^[2] < p^.bits[2]) and (pre^[1] = p^.bits[1])) then
      exit;
    first := false;
    prev := p;
    p := p^.bits_next;
  end;
  t := gspace(28);
  t^.bits_next := p;
  if first then
    token_dcomplex_chain := t
  else
    prev^.bits_next := t;
  t^.kind := 198;
  t^.bits[1] := pre^[1];
  t^.bits[2] := pre^[2];
  t^.bits[3] := pim^[1];
  t^.bits[4] := pim^[2];
  t^.bits_unused_8 := 0;
  dpcmplxtk := t;
end;

{ strtk - the string constant node (kind 92) of the len characters s.

  0x0990F0, 0xB6 bytes.  token_string_chain is sorted by length, then
  by compare_bytes (0x099120): an entry of len characters comparing
  equal is the result; one comparing greater, or a longer entry, stops
  the search.  A new node (len + 18 bytes) gets s copied to +18, len,
  the following entry, is linked in (at the head when none was passed,
  a byte flag), then kind 92 and +8, +12 cleared.

  Not known from the original:
  - the locals' names. }

function strtk(
    s: univ_ptr;
    len: integer): il_$node_ptr_t;
var
  ps: ^strings_$bytes_t;
  first: boolean;
  c: integer;
  i: integer;
  p, prev, t: il_$node_ptr_t;
begin
  ps := s;
  first := true;
  p := token_string_chain;
  while p <> nil do begin
    if len = p^.str_len then begin
      c := compare_bytes(ps^, len, p^.str_chars, p^.str_len);
      if c = 0 then begin
        strtk := p;
        return;
      end;
      if c < 0 then
        exit;
    end
    else if len < p^.str_len then
      exit;
    first := false;
    prev := p;
    p := p^.str_next;
  end;
  t := gspace(len + 18);
  for i := 1 to len do
    t^.str_chars[i] := ps^[i];
  t^.str_len := len;
  t^.str_next := p;
  if first then
    token_string_chain := t
  else
    prev^.str_next := t;
  t^.kind := 92;
  t^.str_unused_8 := 0;
  t^.str_unused_12 := 0;
  strtk := t;
end;

{ token_$make_string_token - strtk of a varying string.

  0x0991A6, 0x2A bytes: strtk(s's characters, s's length) (0x0991C0). }

function token_$make_string_token(
    in s: univ token_$vstring_t): il_$node_ptr_t;
begin
  token_$make_string_token := strtk(addr(s.body), s.length);
end;

{ setcontk - the node of the set constant of len bytes from byte first
  of bits.

  0x0991D0, 0x13E bytes.  w := first div 2, n := (len + 1) div 2 (both
  `asr.l #1' with the negative correction).  One word: smcontk(81, the
  word zero-extended) (a local longword, -4, its high word cleared); two
  words: smcontk(81, the two words) (0x09923E).  Else the chain n mod 65
  (`divs.w #65'), at least 3 (3 added when smaller); an entry of len
  bytes (+16) whose words from +18 equal bits[w..w + n - 1] is the
  result.  Else a new node (len + 18 bytes) gets kind 156, the chain's
  head as its next, +8 cleared, len and the words, and becomes the
  head.

  Not known from the original:
  - the locals' names; how the one- and two-word values were built
    (a local record of two words here). }

function setcontk(
    in bits: univ token_$set_bits_t;
    first: integer;
    len: integer): il_$node_ptr_t;
label
  next;
var
  w, n: integer;
  v: record case integer of
    1: (hi, lo: integer);
    2: (l: integer32);
  end;
  h: integer;
  i: integer;
  p, t: il_$node_ptr_t;
begin
  w := first div 2;
  n := (len + 1) div 2;
  if n = 1 then begin
    v.hi := 0;
    v.lo := bits[w];
    setcontk := smcontk(81, v.l);
  end
  else if n = 2 then begin
    v.hi := bits[w];
    v.lo := bits[w + 1];
    setcontk := smcontk(81, v.l);
  end
  else begin
    h := n mod 65;
    if h < 3 then
      h := h + 3;
    p := token_set_chains[h];
    while p <> nil do begin
      if len = p^.set_len then begin
        for i := 1 to n do
          if bits[w + i - 1] <> p^.set_words[i] then
            goto next;
        setcontk := p;
        return;
      end;
    next:
      p := p^.set_next;
    end;
    t := gspace(len + 18);
    t^.kind := 156;
    t^.set_next := token_set_chains[h];
    t^.set_unused_8 := 0;
    t^.set_len := len;
    for i := 1 to n do
      t^.set_words[i] := bits[w + i - 1];
    token_set_chains[h] := t;
    setcontk := t;
  end;
end;

{ set_is_nil - whether the set constant node t has no members.

  0x09930E, 0x60 bytes.  A kind in [77..87, 101, 200] (the 26-byte set
  constant at 0x09936E): whether its value (+8) is 0; kind 156: whether
  every word of its len div 2 is 0; else false.

  Not known from the original:
  - the local's name. }

function set_is_nil(
    t: il_$node_ptr_t): boolean;
var
  i: integer;
begin
  if t^.kind in [77..87, 101, 200] then
    set_is_nil := t^.int_value = 0
  else if t^.kind = 156 then begin
    for i := 1 to t^.set_len div 2 do
      if t^.set_words[i] <> 0 then begin
        set_is_nil := false;
        return;
      end;
    set_is_nil := true;
  end
  else
    set_is_nil := false;
end;
