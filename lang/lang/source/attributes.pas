{ attributes - ATTRIBUTES, the C front end's data attributes (#attribute
  and __attribute: volatile, device, address, register, size, aligned,
  natural, ...): adding one to a type's attributes with its checks,
  merging a type's into a declaration's, validating them for a kind of
  declaration, the alignment and size they give (texp's alignment, a
  bit field's or packed object's width, the padding of a structure),
  the #pragma alignment environment and its stack, and a routine's
  options inherited from the enclosing routine or the target.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0A4D48  0x0A6728  find_conflict
    0x0A4E84  0x0A6864  attr_align_messages
    0x0A4E9E  0x0A687E  attr_check_align
    0x0A4F38  0x0A6918  attr_natural_align_from_bytes
    0x0A4F62  0x0A6942  attr_calc_align
    0x0A503C  0x0A6A1C  attr_set_align_dsc
    0x0A5300  0x0A6CE0  attr_packed_size
    0x0A5424  0x0A6E04  volatile_check
    0x0A5466  0x0A6E46  add_attribute
    0x0A564E  0x0A702E  attr_validate
    0x0A59F0  0x0A73D0  attr_tattr_to_vattr
    0x0A5A26  0x0A7406  merge_attribs_natural
    0x0A628C  0x0A7C6C  merge_attribs
    0x0A62FA  0x0A7CDA  attr_push_align
    0x0A634C  0x0A7D2C  attr_pop_align
    0x0A63A8  0x0A7D88  attr_al_stk_empty
    0x0A63C4  0x0A7DA4  attr_set_align_env
    0x0A63F6  0x0A7DD6  attr_curr_align_env
    0x0A6412  0x0A7DF2  attr_compute_routine_options
    A5 0x2C20B8 (cc.m68k), 0x442128 (cc.a88k): the module's data, 4
    bytes: +0 a boolean, initially true (.rwdi 0xFF).
    Section attr_al_stk: cc.m68k 0x2D2960, cc.a88k 0x49330C, 516
    bytes: the alignment stack's top (a word, initially -1), then 256
    two-byte entries from +2.

  find_conflict and attr_calc_align do not load A5 (internal);
  volatile_check is nested in add_attribute (it reads add_attribute's
  attr through its dynamic link, docs/rev889-patterns.md 25); every
  other routine is global and loads A5.  attr_packed_size is called
  only here and is declared here.

  The alignment environment is cargs_$options.b28b_0 (cargs +0x28B
  bit 0, true for natural alignment): the image moves it as a 0/1 value
  (`moveq #1; and.b' into a word result, compares `cmpi.w #1', `tst.w')
  and stores attr_set_align_env's word into it unchanged, as for a
  one-bit enumeration (docs/questions.md); it is written here with
  the boolean cargs.ins.pas declares.

  Diagnostics: the codes are cerr_code_map[64..81] (c_data.asm's
  table), reported at lex_line; error1..error3's arguments name the
  attribute (find_conflict, the c_syntax keyword identifiers) or give
  a number (smcontk).

  The nodes attributes reads are types, symbols, fields and blocks by
  kind; their attributes lie at offsets by kind (attr_node_t), the
  other fields are read by offset through il.ins.pas's views.

  Not known from the original: the names of the module's variables,
  the locals and attr_node_t's; the meaning of the routine options.
}
module attributes;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';

type
  { A node holding attributes: a type's form (attr_tattr_t) in a
    typedef (118, c_sym_t's td_attr at +40), kind 202 (+28), kind 121
    (+24), kind 174 (+12) and a block (107, 108: +312); a variable's
    form (attr_vattr_t, c_objtype's c_attr_t) in a pointer (130, 133,
    177) and a structure (132) at +12, an array (127, 131, 197, 218)
    at +16, a field (119, 120) at +24 and a variable (109) at +36. }
  attr_node_ptr_t = ^attr_node_t;
  attr_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      1: (pad_12t: array [1..2] of integer32;
          tattr_12: attr_tattr_t);      { +12 }
      2: (pad_12v: array [1..2] of integer32;
          vattr_12: attr_vattr_t);          { +12 }
      3: (pad_16v: array [1..3] of integer32;
          vattr_16: attr_vattr_t);          { +16 }
      4: (pad_24t: array [1..5] of integer32;
          tattr_24: attr_tattr_t);      { +24 }
      5: (pad_24v: array [1..5] of integer32;
          vattr_24: attr_vattr_t);          { +24 }
      6: (pad_28t: array [1..6] of integer32;
          tattr_28: attr_tattr_t);      { +28 }
      7: (pad_36v: array [1..8] of integer32;
          vattr_36: attr_vattr_t);          { +36 }
      8: (pad_40t: array [1..9] of integer32;
          tattr_40: attr_tattr_t);      { +40 }
      9: (pad_312t: array [1..77] of integer32;
          tattr_312: attr_tattr_t);     { +312 }
  end;

  { An entry of the alignment stack: a byte at the entry's first byte
    (`move.b' to (2,A0,D0.w) with D0 twice the index). }
  attr_al_entry_t = record
    natural: boolean;
  end;

var
  align_messages: boolean := true;      { +0 }

var (attr_al_stk)
  al_top: integer := -1;                { +0: -1 when empty }
  al_stack: array [0..255] of attr_al_entry_t;  { +2 }

{ find_conflict - the keyword of the lowest attribute in s, taken out
  of s (il_178 for an empty s or a bit above 17).

  0x0A4D48, 0x120 bytes, no A5: s = [] gives il_178; the lowest bit by
  a mask shifted left (D1) and its number counted (D2), cleared in s
  (`bset; not.l; and.l' into (A0)); then a jump table over 0..17: the
  c_syntax identifiers (absolute: 0x14ADF4 id_volatile, ...), for 3
  and 4 idntk(76, 'DEVICE(READ)', 12) and idntk(76, 'DEVICE(WRITE)',
  13); 18 and above (`bcc') il_178.  The result in A0.

  Not known from the original: the names. }

function find_conflict(
    var s: attr_bits_t): il_$node_ptr_t; internal;
var
  k: integer;
begin
  if s = [] then
    find_conflict := il_178
  else begin
    k := 0;
    while not (k in s) do
      k := k + 1;
    s := s - [k];
    case k of
      0: find_conflict := id_volatile;
      1: find_conflict := id_physical;
      2: find_conflict := id_atomic;
      3: find_conflict := idntk(ctk_identifier, 'DEVICE(READ)', 12);
      4: find_conflict := idntk(ctk_identifier, 'DEVICE(WRITE)', 13);
      5: find_conflict := id_address;
      6: find_conflict := id_immediate;
      7: find_conflict := id_reference;
      8: find_conflict := id_processor_register;
      9: find_conflict := id_fp_internal_register;
      10: find_conflict := id_register;
      11: find_conflict := id_size;
      12: find_conflict := id_aligned;
      13: find_conflict := id_natural;
      14: find_conflict := id_no_fp;
      15: find_conflict := id_save_db;
      16: find_conflict := id_section;
      17: find_conflict := id_resident_procedure;
      otherwise
        find_conflict := il_178;
    end;
  end;
end;

{ attr_align_messages - whether attr_check_align warns.

  0x0A4E84, 0x1A bytes: the byte parameter stored at +0. }

procedure attr_align_messages(
    on: boolean);
begin
  align_messages := on;
end;

{ attr_check_align - warn once that the k-th expression stack entry is
  not aligned.

  0x0A4E9E, 0x9A bytes: with +0 set (`tst.b; bpl'), the entry's
  type_exp_t flags (cexs_stack at 0x140440, k * 64 less 12: +52) not
  align_ok (bit 1), not align_attr unless cargs_$options.info (cargs
  +0x27E, `andi.l #0x38000', shifted 15) is at least 4 (`bcs'), not
  b24_0: lex_24dc (align_attr) or lex_24da counted, error1(code 64,
  lex_line, the entry's +4), align_ok set (`bset #9' on the byte: bit
  1).

  Not known from the original: the names of the two counters' roles. }

procedure attr_check_align(
    k: integer);
begin
  if align_messages then
    with cexs_stack[k] do
      if not typ.flags.align_ok and
          (not typ.flags.align_attr or (cargs_$options.info >= 4)) and
          not typ.flags.b24_0 then begin
        if typ.flags.align_attr then
          lex_24dc := lex_24dc + 1
        else
          lex_24da := lex_24da + 1;
        error1(cerr_code_map[64], lex_line, sym);
        typ.flags.align_ok := true;
      end;
end;

{ attr_natural_align_from_bytes - log2 of bytes, at most 3: the
  natural alignment of an object of that size.

  0x0A4F38, 0x2A bytes: D0 from -1; repeat bytes shifted right
  (`lsr.l'), D0 counted, until bytes is 0 or D0 is 3. }

function attr_natural_align_from_bytes(
    bytes: integer32): integer;
var
  n: integer;
begin
  n := -1;
  repeat
    bytes := rshft(bytes, 1);
    n := n + 1;
  until (bytes = 0) or (n = 3);
  attr_natural_align_from_bytes := n;
end;

{ attr_calc_align - the natural alignment of node's type of bytes
  bytes.

  0x0A4F62, 0xBE bytes, no A5: by node's kind (compared in turn): a
  typedef (118) with a Size attribute in a (word +2 bit 11) larger than
  its own (+44, its attributes' size) takes its type's (type_exp(+28))
  when that is an aggregate (a set of 0..223 after the routine: 127,
  131, 132, 196, 197, 218; docs/dpc-gaps.md 8), else bytes' natural
  alignment; otherwise its +48 (its attributes' natural alignment);
  arrays (218, 127, 131) their +26, 196 2, 197 0, a structure (132)
  its +22, routines (107, 108) 2; any other kind bytes' natural
  alignment (attr_natural_align_from_bytes, `bsr').  The result in
  D0.

  Not known from the original: the names. }

function attr_calc_align(
    node: il_$node_ptr_t;
    bytes: integer32;
    in a: attr_tattr_t): integer; options(val_param); internal;
var
  texp: type_exp_t;
begin
  case node^.kind of
    118:
      if (11 in a.bits) and (a.size > node^.xl[11]) then begin
        type_exp(node^.xp[7], addr(texp));
        if texp.base^.kind in [127, 131, 132, 196, 197, 218] then
          attr_calc_align := node^.xw[24]
        else
          attr_calc_align := attr_natural_align_from_bytes(bytes);
      end
      else
        attr_calc_align := node^.xw[24];
    218, 127, 131:
      attr_calc_align := node^.xw[13];
    196:
      attr_calc_align := 2;
    197:
      attr_calc_align := 0;
    132:
      attr_calc_align := node^.xw[11];
    107, 108:
      attr_calc_align := 2;
    otherwise
      attr_calc_align := attr_natural_align_from_bytes(bytes);
  end;
end;

{ attr_set_align_dsc - texp's alignment from node's attributes.

  0x0A503C, 0x2AA bytes, link #-76.  By node's kind (compared in turn)
  the alignment (D0), the natural alignment (D1), the attribute bits
  (D3) and the type to look into (A3) are taken from node's attributes
  (attr_node_t), and whether node is a type component (D2: arrays,
  197, fields); variables, 121, 108 and 174 clear texp's b24_0 (`bclr
  D2' with D2 still 0); a kind of a set of 0..207 after the routine
  (the constants: 77..90, 92, 93, 101, 156, 176, 198, 200; docs/dpc-
  gaps.md 8) takes attr_calc_align(node, texp.size, a local) for both
  alignments, no bits and node as the type; any other kind is error0
  (code 65) and align_ok.  Then: under -ALNCHK's default (cpu 6 equal
  to alnchk: `sne' twice, `cmp.b') a natural alignment above 1 is 1; a
  component takes texp's alignment (`asr.b #3; ext.w') when lower,
  dropping the Aligned bit (`andi.l #0xFFFFEFFF'), any other node
  clears align_attr; texp's alignment stored; align_attr or-ed with
  bit 12; align_ok := alignment at least natural or kind 197 or 120;
  when not, an object above 4 bytes with no type, or whose type
  (type_exp) is 131, 197 or 132, is align_ok.

  Not known from the original: the names; why D2's register serves
  as the bit number (docs/rev889-patterns.md 24). }

procedure attr_set_align_dsc(
    node: il_$node_ptr_t;
    texp: univ_ptr);
var
  te: type_exp_ptr_t;
  an: attr_node_ptr_t;
  align: integer;
  natural: integer;
  bits: attr_bits_t;
  typ: il_$node_ptr_t;
  in_type: boolean;
  a: attr_tattr_t;                      { -24: not set }
  t: type_exp_t;                        { -56 }
begin
  te := texp;
  an := attr_node_ptr_t(node);
  in_type := false;
  case node^.kind of
    109: begin
      te^.flags.b24_0 := false;
      align := an^.vattr_36.align;
      natural := an^.vattr_36.natural;
      bits := an^.vattr_36.bits;
      typ := node^.xp[7];
    end;
    131, 218, 127: begin
      align := an^.vattr_16.align;
      natural := an^.vattr_16.natural;
      bits := an^.vattr_16.bits;
      typ := node^.xp[1];
      in_type := true;
    end;
    197: begin
      align := an^.vattr_16.align;
      natural := an^.vattr_16.natural;
      bits := an^.vattr_16.bits;
      typ := nil;
      in_type := true;
    end;
    132: begin
      align := an^.vattr_12.align;
      natural := an^.vattr_12.natural;
      bits := an^.vattr_12.bits;
      typ := node;
    end;
    119: begin
      align := an^.vattr_24.align;
      natural := an^.vattr_24.natural;
      bits := an^.vattr_24.bits;
      typ := node^.xp[4];
      in_type := true;
    end;
    120: begin
      align := an^.vattr_24.align;
      natural := an^.vattr_24.natural;
      bits := an^.vattr_24.bits;
      typ := nil;
      in_type := true;
    end;
    121: begin
      te^.flags.b24_0 := false;
      align := an^.tattr_24.align;
      natural := an^.tattr_24.natural;
      bits := an^.tattr_24.bits;
      typ := node^.xp[4];
    end;
    108: begin
      te^.flags.b24_0 := false;
      align := an^.tattr_312.align;
      natural := an^.tattr_312.natural;
      bits := an^.tattr_312.bits;
      typ := node^.xp[7];
    end;
    174: begin
      te^.flags.b24_0 := false;
      align := an^.tattr_12.align;
      natural := an^.tattr_12.natural;
      bits := an^.tattr_12.bits;
      typ := node^.xp[2];
    end;
    130, 177, 133: begin
      align := an^.vattr_12.align;
      natural := an^.vattr_12.natural;
      bits := an^.vattr_12.bits;
      typ := node^.xp[1];
    end;
    otherwise
      if node^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then begin
        natural := attr_calc_align(node, te^.size, a);
        align := natural;
        bits := [];
        typ := node;
      end
      else begin
        error0(cerr_code_map[65], lex_line);
        te^.flags.align_ok := true;
        return;
      end;
  end;
  if ((6 in cargs_$options.cpu) = cargs_$options.alnchk) and (natural > 1) then
    natural := 1;
  if in_type then begin
    if te^.flags.align < align then begin
      align := te^.flags.align;
      bits := bits - [12];
    end;
  end
  else
    te^.flags.align_attr := false;
  te^.flags.align := align;
  te^.flags.align_attr := (12 in bits) or te^.flags.align_attr;
  te^.flags.align_ok := (align >= natural) or (node^.kind = 197) or
      (node^.kind = 120);
  if not te^.flags.align_ok then
    if te^.size > 4 then
      if typ = nil then
        te^.flags.align_ok := true
      else begin
        type_exp(typ, addr(t));
        if (t.base^.kind = 131) or (t.base^.kind = 197) or
            (t.base^.kind = 132) then
          te^.flags.align_ok := true;
      end;
end;

{ attr_packed_size - the bits an object of texp's type takes when
  packed (a Size attribute's least value); negative when a sign bit is
  counted.

  0x0A5300, 0x124 bytes.  An integral type (ranged): the larger of
  |low| (less 1 for a negative low) and high, its bits counted by
  halving (`asr.l #1' after the rounding for negatives) and one more
  with negative for a negative low; 32 and negative when |low|
  overflows (`blt' after `neg.l') or high is 16#7FFFFFFF.  Else a set
  (134) of at most 32 elements (its word at +12, `bhi': unsigned) its
  count; with scalar, the size in bytes times 8; else a structure's
  bits (+12), 197's (+16), an array's index range (type_exp of +8)
  times its element's +12 times 8 (M$MIS$LLL, `lsl.l #3'), or the
  size times 8, rounded up to a byte (M$OIS$WLW: `mod 8' of a word).

  Not known from the original: the names; the set's +12 (a word read
  unsigned, here through a signed view). }

function attr_packed_size(
    var texp: type_exp_t;
    scalar: boolean;
    out negative: boolean): integer32; options(val_param);
var
  b: il_$node_ptr_t;
  n: integer32;
  bits: integer32;
  r: type_exp_t;                        { -32 }
begin
  negative := false;
  if texp.flags.ranged then begin
    n := abs(texp.low);
    if (n < 0) or (texp.high = 16#7FFFFFFF) then begin
      bits := 32;
      negative := true;
    end
    else begin
      if texp.low < 0 then
        n := n - 1;
      if n < texp.high then
        n := texp.high;
      bits := 0;
      repeat
        bits := bits + 1;
        n := n div 2;
      until n = 0;
      if texp.low < 0 then begin
        bits := bits + 1;
        negative := true;
      end;
    end;
  end
  else begin
    b := il_$node_ptr_t(texp.base);
    if (b^.kind = 134) and (b^.xw[6] <= 32) then
      bits := b^.xw[6]
    else if scalar then
      bits := texp.size * 8
    else begin
      if b^.kind = 132 then
        bits := b^.xl[3]
      else if b^.kind = 197 then
        bits := b^.xl[4]
      else if b^.kind = 131 then begin
        type_exp(b^.xp[2], addr(r));
        bits := (r.high - r.low + 1) * b^.xl[3] * 8;
      end
      else
        bits := texp.size * 8;
      n := bits mod 8;
      if n <> 0 then
        bits := bits + 8 - n;
    end;
  end;
  attr_packed_size := bits;
end;

{ add_attribute - add attribute code (an attr_tattr_t bit number) with
  its operand value to attr; name is the attribute's keyword for the
  diagnostics.

  0x0A5466, 0x1DE bytes, link #-4.  The storage attributes 1 and 6..10
  (`btst' of #0x7C2) are error1(code 71, name) unless cpu 6 (cargs
  +0x284 bit 0): nothing else is done.  One of 5..10 already given
  must repeat its value (code 66); one of them after another (bit 18)
  is a conflict, error2(code 72, name, the other's keyword; the
  conflict in a frame longword, -4); else bit 18 and the code's bit
  are set.  Const (19) twice is code 66; any other code's bit is set.
  Then (a jump table over 0..13): volatile (0) volatile_check; address,
  processor_register, fp_internal_register (5, 8, 9) the value at +16;
  immediate (6) volatile_check, then as reference and register (7,
  10) the value's high word (`clr.w; swap') at +18 and its low word at
  +16; size (11) the value at +4; aligned (12) the value at +10, above
  10 error1(code 67, smcontk(81, 10)) and 10; natural (13) sets
  aligned (bit 12), error1(code 66, idntk(76, 'Alignment', 9)) when it
  was set.

  Not known from the original: the names. }

procedure add_attribute(
    code: integer;
    var attr: attr_tattr_t;
    value: integer32;
    name: il_$node_ptr_t);
var
  conflict: attr_bits_t;                  { -4 }

  { volatile_check - volatile and immediate together: volatile dropped
    and reported.

    0x0A5424, 0x42 bytes, nested (add_attribute's attr at (10) of its
    dynamic link): attr's bits and #0x41 equal to it; bit 0 cleared;
    error2(code 72, id_volatile, id_immediate). }

  procedure volatile_check;
  begin
    if attr.bits * [0, 6] = [0, 6] then begin
      attr.bits := attr.bits - [0];
      error2(cerr_code_map[72], lex_line, id_volatile, id_immediate);
    end;
  end;

begin
  if (code in [1, 6..10]) and not (6 in cargs_$options.cpu) then begin
    error1(cerr_code_map[71], lex_line, name);
    return;
  end;
  if code in [5..10] then begin
    if code in attr.bits then begin
      if value <> attr.value then
        error1(cerr_code_map[66], lex_line, name);
    end
    else if 18 in attr.bits then begin
      conflict := attr.bits * [5..10];
      error2(cerr_code_map[72], lex_line, name, find_conflict(conflict));
    end
    else begin
      attr.bits := attr.bits + [18];
      attr.bits := attr.bits + [code];
    end;
  end
  else if (code = 19) and (code in attr.bits) then
    error1(cerr_code_map[66], lex_line, name)
  else
    attr.bits := attr.bits + [code];
  case code of
    0:
      volatile_check;
    5, 8, 9:
      attr.value := value;
    6: begin
      volatile_check;
      attr.value_hi := rshft(value, 16);
      attr.value_lo := value;
    end;
    7, 10: begin
      attr.value_hi := rshft(value, 16);
      attr.value_lo := value;
    end;
    11:
      attr.size := value;
    12:
      if value > 10 then begin
        error1(cerr_code_map[67], lex_line, smcontk(81, 10));
        attr.align := 10;
      end
      else
        attr.align := value;
    13:
      if 12 in attr.bits then
        error1(cerr_code_map[66], lex_line,
            idntk(ctk_identifier, 'Alignment', 9))
      else
        attr.bits := attr.bits + [12];
    otherwise
      ;
  end;
end;

{ attr_validate - report each attribute in attr that node's kind does
  not take.

  0x0A564E, 0x394 bytes, link #-16.  The bits not taken (D0) by kind
  (compared in turn): no node 0..13; a variable (109) none when its
  type is a 121, else 6, 7, 14, 15, 17, physical (1) without address
  (5) being error0(code 73); a typedef (118) none; 174, 121 (by its
  word at +44, a jump table over 0..4 with no otherwise: a value above
  4 leaves D0 as it was), pointers (130, 177), fields (119, 120),
  arrays (131, 218, 127, 197; a separate arm with the same set), 133
  the sets below; a routine (108, 107): first each parameter (the
  chain at +12, linked by +4) given immediate or reference (its bits
  at +24 and #0xC0, kept at -12 for find_conflict) is checked by its
  register class (+40, a jump table over 0..4): 0 a number (+42) in
  4..29, 1 in 0..63, 2 even and in 0..63, else error3(code 76, the
  keyword, smcontk(81, the number), the name at +8); 3 and 4 error1(code
  74, idntk(76, 'CONTROL', 7) or 'SPACE', 5); one given immediate
  (bit 6 of +27) whose size (+28) exceeds its class's 32, 32 or 64
  bits (D2, not set for another class) is error1(code 77, the name);
  then a procedure (107) is done, a function takes 0..9 when its 2-bit
  field at +376 (`andi.w #0x180; lsr.w #7') is 2, else 0..5, 8, 9; any
  other kind error0(code 65) and 0..17, 19, 20.  Last, each bit of attr
  among them (kept at -12) error1(code 74, find_conflict) (`bne' after
  the first find_conflict: a while loop).

  Not known from the original: the names; what the parameter fields
  and the register classes are. }

procedure attr_validate(
    in attr: attr_tattr_t;
    node: il_$node_ptr_t);
var
  mask: attr_bits_t;
  bad: attr_bits_t;                       { -12 }
  p: il_$node_ptr_t;
  limit: integer32;
begin
  if node = nil then
    mask := [0..13]
  else
    case node^.kind of
      109:
        if node^.xp[7]^.kind = 121 then
          mask := []
        else begin
          if (1 in attr.bits) and not (5 in attr.bits) then
            error0(cerr_code_map[73], lex_line);
          mask := [6, 7, 14, 15, 17];
        end;
      118:
        mask := [];
      174:
        mask := [0..8, 14..17];
      121:
        case node^.xw[22] of
          0, 2: mask := [1, 3..5, 8..10, 14..17];
          1: mask := [1, 5, 6, 8..10, 14..17];
          3, 4: mask := [1, 5, 8..10, 14..17];
        end;
      130, 177:
        mask := [5..10, 14..17];
      119, 120:
        mask := [1, 5..10, 14..17];
      131, 218, 127, 197:
        mask := [1, 5..10, 14..17];
      133:
        mask := [0..10, 12, 14..17];
      108, 107: begin
        p := node^.xp[3];
        while p <> nil do begin
          bad := attr_bits_t(p^.xl[6]) * [6, 7];
          if bad <> [] then
            case p^.xw[20] of
              0:
                if (p^.xw[21] < 4) or (p^.xw[21] > 29) then
                  error3(cerr_code_map[76], lex_line, find_conflict(bad),
                      smcontk(81, p^.xw[21]), p^.xp[2]);
              1:
                if (p^.xw[21] < 0) or (p^.xw[21] > 63) then
                  error3(cerr_code_map[76], lex_line, find_conflict(bad),
                      smcontk(81, p^.xw[21]), p^.xp[2]);
              2:
                if (p^.xw[21] > 63) or odd(p^.xw[21]) or (p^.xw[21] < 0) then
                  error3(cerr_code_map[76], lex_line, find_conflict(bad),
                      smcontk(81, p^.xw[21]), p^.xp[2]);
              3:
                error1(cerr_code_map[74], lex_line,
                    idntk(ctk_identifier, 'CONTROL', 7));
              4:
                error1(cerr_code_map[74], lex_line,
                    idntk(ctk_identifier, 'SPACE', 5));
            end;
          if 6 in attr_bits_t(p^.xl[6]) then begin
            case p^.xw[20] of
              0: limit := 32;
              1: limit := 32;
              2: limit := 64;
            end;
            if limit < p^.xl[7] then
              error1(cerr_code_map[77], lex_line, p^.xp[2]);
          end;
          p := p^.xp[1];
        end;
        if node^.kind = 107 then
          return;
        if rshft(node^.xw[188] & 16#180, 7) = 2 then
          mask := [0..9]
        else
          mask := [0..5, 8, 9];
      end;
      otherwise
        error0(cerr_code_map[65], lex_line);
        mask := [0..17, 19, 20];
    end;
  bad := attr.bits * mask;
  while bad <> [] do
    error1(cerr_code_map[74], lex_line, find_conflict(bad));
end;

{ attr_tattr_to_vattr - a type's attributes t in a variable's form v.

  0x0A59F0, 0x36 bytes: v+4 := t+0, v+0 := t+4, v+8 := t+10, v+10 :=
  t+8, v+12 := t+12 (14 bytes; c_sym_map has its own copy of this
  routine).

  Not known from the original: the names. }

procedure attr_tattr_to_vattr(
    in t: attr_tattr_t;
    out v: univ attr_vattr_t);
begin
  v.bits := t.bits;
  v.size := t.size;
  v.align := t.align;
  v.natural := t.natural;
  v.min_align := t.min_align;
end;

{ merge_attribs_natural - add the attributes of typ (a typedef, an
  attributed type, an array or structure) to attr, check the size and
  alignment attr gives against typ's, settle attr's size (padded) and
  alignments; the result the flags of a symbol with attr.

  0x0A5A26, 0x866 bytes, link #-92.  No type (nil or il_178): attr is
  no bits, 32 bits, alignment 2.  Else typ's attributes (D2 set when
  there are any) into a frame copy (-56): a typedef's (+40, 20 bytes)
  or 202's (+28), 121's (+24: 14 bytes), an array's (127, 131, 218,
  197: the variable form at +16 converted, its size, aligned and const
  bits dropped, `andi.l #0xFFF7E7FF') or a structure's (132: +12
  converted).  Merged: bits 0..4; device bits (3, 4) that differ are
  error1(code 70, id_device); differing storage attributes (5..10)
  with bit 18 in both error2(code 72, find_conflict twice of their
  union at -68), else typ's storage attribute and value taken (a
  differing value with bit 18 in attr error1(code 70, find_conflict of
  attr's bits)); size (11): a different size error1(code 70, id_size),
  bit and size taken; aligned (12): against natural (13) in attr,
  id_natural when typ's alignment is not its natural one, against
  aligned id_unaligned (attr's -1) or id_aligned when they differ; the
  bits, both alignments (one longword) and the least taken; const
  twice error1(code 66, the token of `const', lex_tokens[102]), else
  taken; 20 taken.

  Then type_exp(typ) (-32).  With a size (bit 11), checked by the type
  (error1(code 68, smcontk(81, size)) and the size replaced): an
  integral type's at most 32 and at least attr_packed_size's (kind 125
  exactly 8), a set's at most 256 and at least its count, a float's 32
  and a double's 64, an aggregate's (131, 197, 132) at least its
  packed size, else at least its bytes times 8; texp's size and bytes
  := (size + 7) div 8.  Without, the size := bytes times 8.

  Alignment without Aligned (12): typ's (both words at +10 as one
  longword) when typ has attributes that are aligned or attr has no
  size, the natural alignment typ's without a size, else
  attr_calc_align; otherwise both from attr_calc_align and the least
  typ's or -1.  With Aligned: below typ's least, error1(code 70,
  id_aligned) (typ not aligned, attr not natural); unless typ was
  aligned the natural alignment from attr_calc_align, the alignment
  the natural one when natural, the least the alignment; then an
  unaligned (-1) aggregate (the set of attr_calc_align) is error0(code
  69) and alignment 0, a structure with an aligned field (its +30 bit
  12) above the alignment error1(code 70, id_aligned) (the loop left),
  a scalar (123, 122) aligned above its natural alignment error1(code
  67, smcontk(81, natural)) and the natural one.

  Then the alignment is at least the least; without a size, the size
  padded to the natural alignment (8 shl natural - 1 as the mask, when
  natural > 0) and to the alignment (least at least 1, at most the
  alignment); under natural alignment (cargs +0x28B bit 0) and no
  Aligned the first, else the second; a structure (typ 132) whose two
  paddings differ, error2(code 81, smcontk(81, the second in bytes),
  smcontk(81, the first in bytes)).  The result: flags 0 for volatile
  (and each of atomic, device read and write), 1 atomic, 3 and 4 the
  device ones, 5 and 18 processor_register, 18 address, 2 physical,
  31 const (`ori.l' in turn; atomic tested twice).

  Not known from the original: the names; why atomic is tested twice. }

function merge_attribs_natural(
    var attr: attr_tattr_t;
    typ: il_$node_ptr_t): attr_bits_t;
var
  an: attr_node_ptr_t;
  have: boolean;
  t: attr_tattr_t;                      { -56 }
  texp: type_exp_t;                     { -32 }
  conflict: attr_bits_t;                  { -68 }
  negative: boolean;                    { -90 }
  bits: integer32;
  mask: integer32;
  n: integer;
  pad_natural: integer32;
  pad_align: integer32;
  f: c_field_ptr_t;
  flags: attr_bits_t;
begin
  have := false;
  if (typ = nil) or (typ = il_178) then begin
    attr.bits := [];
    attr.size := 32;
    attr.align := 2;
  end
  else begin
    an := attr_node_ptr_t(typ);
    if typ^.kind = 118 then begin
      t := an^.tattr_40;
      have := true;
    end
    else if typ^.kind = 121 then begin
      t.bits := an^.tattr_24.bits;
      t.size := an^.tattr_24.size;
      t.natural := an^.tattr_24.natural;
      t.align := an^.tattr_24.align;
      t.min_align := an^.tattr_24.min_align;
      have := true;
    end
    else if (typ^.kind = 127) or (typ^.kind = 131) or (typ^.kind = 218) or
        (typ^.kind = 197) then begin
      t.bits := an^.vattr_16.bits - [11, 12, 19];
      t.size := an^.vattr_16.size;
      t.align := an^.vattr_16.align;
      t.natural := an^.vattr_16.natural;
      t.min_align := an^.vattr_16.min_align;
      have := true;
    end
    else if typ^.kind = 132 then begin
      t.bits := an^.vattr_12.bits;
      t.size := an^.vattr_12.size;
      t.align := an^.vattr_12.align;
      t.natural := an^.vattr_12.natural;
      t.min_align := an^.vattr_12.min_align;
      have := true;
    end
    else if typ^.kind = 202 then begin
      t := an^.tattr_28;
      have := true;
    end;
    if have then begin
      attr.bits := attr.bits + t.bits * [0..4];
      if (attr.bits * [3, 4] <> t.bits * [3, 4]) and
          (attr.bits * [3, 4] <> []) and (t.bits * [3, 4] <> []) then
        error1(cerr_code_map[70], lex_line, id_device);
      if (attr.bits * [5..10] <> t.bits * [5..10]) and
          (18 in t.bits * attr.bits) then begin
        conflict := (attr.bits + t.bits) * [5..10];
        error2(cerr_code_map[72], lex_line, find_conflict(conflict),
            find_conflict(conflict));
      end
      else if 18 in t.bits then begin
        if (18 in attr.bits) and (attr.value <> t.value) then
          error1(cerr_code_map[70], lex_line, find_conflict(attr.bits));
        attr.bits := attr.bits + t.bits * [5..10, 18];
        attr.value := t.value;
      end;
      if 11 in t.bits then begin
        if (11 in attr.bits) and (attr.size <> t.size) then
          error1(cerr_code_map[70], lex_line, id_size);
        attr.bits := attr.bits + [11];
        attr.size := t.size;
      end;
      if 12 in t.bits then begin
        if 13 in attr.bits then begin
          if t.align <> t.natural then
            error1(cerr_code_map[70], lex_line, id_natural);
        end
        else if 12 in attr.bits then begin
          if attr.align <> t.align then
            if attr.align = -1 then
              error1(cerr_code_map[70], lex_line, id_unaligned)
            else
              error1(cerr_code_map[70], lex_line, id_aligned);
        end;
        attr.bits := attr.bits + [12];
        if 13 in t.bits then
          attr.bits := attr.bits + [13];
        attr.natural := t.natural;
        attr.align := t.align;
        attr.min_align := t.min_align;
      end;
      if 19 in t.bits then begin
        if 19 in attr.bits then
          error1(cerr_code_map[66], lex_line, lex_tokens[102])
        else
          attr.bits := attr.bits + [19];
      end;
      if 20 in t.bits then
        attr.bits := attr.bits + [20];
    end;
  end;

  type_exp(typ, addr(texp));
  if 11 in attr.bits then begin
    if texp.flags.ranged then begin
      bits := attr_packed_size(texp, true, negative);
      if (attr.size > 32) or (attr.size < bits) or
          ((texp.base^.kind = 125) and (attr.size <> 8)) then begin
        error1(cerr_code_map[68], lex_line, smcontk(81, attr.size));
        attr.size := bits;
      end;
    end
    else if texp.base^.kind = 134 then begin
      if (attr.size > 256) or
          (il_$node_ptr_t(texp.base)^.xw[6] > attr.size) then begin
        error1(cerr_code_map[68], lex_line, smcontk(81, attr.size));
        attr.size := il_$node_ptr_t(texp.base)^.xw[6];
      end;
    end
    else if texp.base^.kind = 123 then begin
      if ((texp.base^.len = 6) and (attr.size <> 32)) or
          ((texp.base^.len = 7) and (attr.size <> 64)) then begin
        error1(cerr_code_map[68], lex_line, smcontk(81, attr.size));
        if texp.base^.len = 6 then
          attr.size := 32
        else
          attr.size := 64;
      end;
    end
    else if (texp.base^.kind = 131) or (texp.base^.kind = 197) or
        (texp.base^.kind = 132) then begin
      bits := attr_packed_size(texp, false, negative);
      if bits > attr.size then begin
        error1(cerr_code_map[68], lex_line, smcontk(81, attr.size));
        attr.size := bits;
      end;
    end
    else begin
      bits := texp.bytes * 8;
      if bits > attr.size then begin
        error1(cerr_code_map[68], lex_line, smcontk(81, attr.size));
        attr.size := bits;
      end;
    end;
    texp.size := (attr.size + 7) div 8;
    texp.bytes := texp.size;
  end
  else
    attr.size := texp.bytes * 8;

  if not (12 in attr.bits) then begin
    if have and ((12 in t.bits) or not (11 in attr.bits)) then begin
      attr.align := t.align;
      attr.min_align := t.min_align;
      if not (11 in attr.bits) then
        attr.natural := t.natural
      else
        attr.natural := attr_calc_align(typ, texp.bytes, attr);
    end
    else begin
      attr.natural := attr_calc_align(typ, texp.bytes, attr);
      attr.align := attr.natural;
      if have then
        attr.min_align := t.min_align
      else
        attr.min_align := -1;
    end;
  end
  else begin
    if have and not (12 in t.bits) and not (13 in attr.bits) and
        (attr.align < t.min_align) then
      error1(cerr_code_map[70], lex_line, id_aligned);
    if not have or not (12 in t.bits) then begin
      attr.natural := attr_calc_align(typ, texp.bytes, attr);
      if 13 in attr.bits then
        attr.align := attr.natural;
      attr.min_align := attr.align;
    end;
    if (attr.align = -1) and
        (texp.base^.kind in [127, 131, 132, 196, 197, 218]) then begin
      error0(cerr_code_map[69], lex_line);
      attr.align := 0;
    end
    else if texp.base^.kind = 132 then begin
      f := texp.base^.su_fields;
      while f <> nil do begin
        if (12 in f^.attr.bits) and (attr.align < f^.attr.align) then begin
          error1(cerr_code_map[70], lex_line, id_aligned);
          exit;
        end;
        f := f^.next;
      end;
    end
    else if (texp.base^.kind = 123) or (texp.base^.kind = 122) then begin
      if attr.align > attr.natural then begin
        error1(cerr_code_map[67], lex_line, smcontk(81, attr.natural));
        attr.align := attr.natural;
      end;
    end;
  end;

  if attr.align < attr.min_align then
    attr.align := attr.min_align;
  if not (11 in attr.bits) then begin
    if attr.natural > 0 then begin
      mask := lshft(8, attr.natural) - 1;
      if (attr.size & mask) <> 0 then
        pad_natural := (attr.size & ~mask) + mask + 1
      else
        pad_natural := attr.size;
    end
    else
      pad_natural := attr.size;
    n := 1;
    if n < attr.min_align then
      n := attr.min_align;
    if n > attr.align then
      n := attr.align;
    if n > 0 then begin
      mask := lshft(8, n) - 1;
      if (attr.size & mask) <> 0 then
        pad_align := (attr.size & ~mask) + mask + 1
      else
        pad_align := attr.size;
    end
    else
      pad_align := attr.size;
    if cargs_$options.b28b_0 and not (12 in attr.bits) then
      attr.size := pad_natural
    else
      attr.size := pad_align;
    if (typ <> nil) and (pad_align <> pad_natural) and
        not (12 in attr.bits) and then (typ^.kind = 132) then
      error2(cerr_code_map[81], lex_line, smcontk(81, pad_align div 8),
          smcontk(81, pad_natural div 8));
  end;

  flags := [];
  if 0 in attr.bits then
    flags := [0];
  if 2 in attr.bits then
    flags := flags + [0, 1];
  if 3 in attr.bits then
    flags := flags + [0, 3];
  if 4 in attr.bits then
    flags := flags + [0, 4];
  if 8 in attr.bits then
    flags := flags + [5, 18];
  if 5 in attr.bits then
    flags := flags + [18];
  if 2 in attr.bits then
    flags := flags + [1];
  if 1 in attr.bits then
    flags := flags + [2];
  if 19 in attr.bits then
    flags := flags + [31];
  merge_attribs_natural := flags;
end;

{ merge_attribs - merge_attribs_natural; under -ALNCHK's default (cpu 6
  equal to alnchk) and word alignment the alignment is at most the
  least (at least 1).

  0x0A628C, 0x6E bytes: merge_attribs_natural's result left in D0
  (docs/rev889-patterns.md 32); the environment read as a value
  (`moveq #1; and.b; tst.w'). }

function merge_attribs(
    var attr: attr_tattr_t;
    typ: il_$node_ptr_t): attr_bits_t;
var
  n: integer;
begin
  merge_attribs := merge_attribs_natural(attr, typ);
  if ((6 in cargs_$options.cpu) = cargs_$options.alnchk) and
      not cargs_$options.b28b_0 then begin
    n := 1;
    if n < attr.min_align then
      n := attr.min_align;
    if n > attr.align then
      n := attr.align;
    attr.align := n;
  end;
end;

{ attr_push_align - save the alignment environment.

  0x0A62FA, 0x52 bytes: below 255 (`bge'), the top counted and the
  environment (cargs +0x28B bit 0) stored in the entry (section
  attr_al_stk, 0x2D2960, the entry at +2 + 2 * top); else error0(code
  78). }

procedure attr_push_align;
begin
  if al_top < 255 then begin
    al_top := al_top + 1;
    al_stack[al_top].natural := cargs_$options.b28b_0;
  end
  else
    error0(cerr_code_map[78], lex_line);
end;

{ attr_pop_align - restore the saved environment.

  0x0A634C, 0x5C bytes: the top not negative (`bmi'), the entry stored
  back and the top decremented; else error0(code 79). }

procedure attr_pop_align;
begin
  if al_top >= 0 then begin
    cargs_$options.b28b_0 := al_stack[al_top].natural;
    al_top := al_top - 1;
  end
  else
    error0(cerr_code_map[79], lex_line);
end;

{ attr_al_stk_empty - nothing is saved.

  0x0A63A8, 0x1C bytes: `tst.w; slt'. }

function attr_al_stk_empty: boolean;
begin
  attr_al_stk_empty := al_top < 0;
end;

{ attr_set_align_env - the environment: env 1 natural, 0 word.

  0x0A63C4, 0x32 bytes: env's low byte or-ed into cargs +0x28B after
  bit 0 is cleared (no test: the image takes env as 0 or 1). }

procedure attr_set_align_env(
    env: integer);
begin
  cargs_$options.b28b_0 := env <> 0;
end;

{ attr_curr_align_env - the environment, 1 natural, 0 word.

  0x0A63F6, 0x1C bytes: `moveq #1; and.b' of cargs +0x28B, a word. }

function attr_curr_align_env: integer;
begin
  attr_curr_align_env := ord(cargs_$options.b28b_0);
end;

{ attr_compute_routine_options - complete opts, a routine's options,
  from those of parent, its enclosing block, or (no parent) the
  target's defaults (target_properties.user_mode).

  0x0A6412, 0x1DE bytes, link #-88.  The convention (+40): given when
  bit 13 of +38 is set, else parent's (+372) or target_properties'
  +0x13A, stored.  When it is in neither +24 nor +32, it is added to
  +28.  Each longword set takes the parent's (+356, +360, +364) or the
  target's (+0xE8, +0xEC, +0xF0) elements that none of the three has
  (`not.l' of their union once, `and.l', `or.l'); each 8-byte set the
  parent's (+332, +340, +348) or the target's (+0xD0, +0xD8, +0xE0)
  that none of the three has (the union at -8; the two-longword loops
  `dbf'; the last set's code shared by both arms).

  Not known from the original: the names; what the sets hold. }

procedure attr_compute_routine_options(
    var opts: attr_rtn_opts_t;
    parent: il_$node_ptr_t);
var
  pb: attr_block_ptr_t;
  conv: integer;
  all: set of 0..31;
  all64: set of 0..63;                  { -8 }
begin
  pb := attr_block_ptr_t(parent);
  if 13 in opts.given then
    conv := opts.convention
  else begin
    if parent <> nil then
      conv := pb^.opts.convention
    else
      conv := ord(target_properties.p_13a);
    opts.convention := conv;
  end;
  if not (conv in opts.opts_24) and not (conv in opts.opts_32) then
    opts.opts_28 := opts.opts_28 + [conv];
  all := opts.opts_24 + opts.opts_28 + opts.opts_32;
  if parent <> nil then begin
    opts.opts_24 := opts.opts_24 + (pb^.opts.opts_24 - all);
    opts.opts_28 := opts.opts_28 + (pb^.opts.opts_28 - all);
    opts.opts_32 := opts.opts_32 + (pb^.opts.opts_32 - all);
  end
  else begin
    opts.opts_24 := opts.opts_24 + (target_properties.user_mode.m_18 - all);
    opts.opts_28 := opts.opts_28 + (target_properties.user_mode.m_1c - all);
    opts.opts_32 := opts.opts_32 + (target_properties.user_mode.m_20 - all);
  end;
  all64 := opts.opts_0 + opts.opts_8 + opts.opts_16;
  if parent <> nil then begin
    opts.opts_0 := opts.opts_0 + (pb^.opts.opts_0 - all64);
    opts.opts_8 := opts.opts_8 + (pb^.opts.opts_8 - all64);
    opts.opts_16 := opts.opts_16 + (pb^.opts.opts_16 - all64);
  end
  else begin
    opts.opts_0 := opts.opts_0 + (target_properties.user_mode.m_0 - all64);
    opts.opts_8 := opts.opts_8 + (target_properties.user_mode.m_8 - all64);
    opts.opts_16 := opts.opts_16 + (target_properties.user_mode.m_10 - all64);
  end;
end;
