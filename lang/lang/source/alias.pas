{ alias - ALIAS, the optimizer's alias descriptors: for an IL
  reference, the storage it may touch (a base node, a displacement and
  size, the number of indirections, a storage class and flags), and
  whether two references, or a reference and a call, may touch the same
  storage (tables by class, the -ALIAS settings in cargs).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0739E4  0x0753C4  is_display_ptr
    0x073A22  0x075402  alias_ptr_node
    0x073CAE  0x07568E  check_the_ind
    0x073D38  0x075718  get_alias_desc
    0x0744D0  0x075EB0  build_alias_desc
    0x0745A4  0x075F84  alias_$get_alias_desc
    0x074688  0x076068  alias_$alias_desc_with_size
    0x0746B4  0x076094  alias_$basic_alias_desc
    0x0746E2  0x0760C2  alias_$add_disp
    0x074710  0x0760F0  alias_$ind_for_captured_lvalue
    0x074792  0x076172  assert_is_fortran_external_routine_parameter
    0x0747C8  0x0761A8  formal_may_alias_actual
    0x074964  0x076344  alias_$relationship
    0x074CE6  0x0766C6  alias_$related
    0x074D1A  0x0766FA  alias_$unrelated_or_exact
    0x074D50  0x076730  alias_$classes_may_be_related
    0x074E34  0x076814  alias_$ref_may_generate_exception
    0x074E7A  0x07685A  alias_$descriptors_are_identical
    0x074F46  0x076926  alias_$related_call
    A5 0x168D8C (cc.m68k), 0x2E8DFC (cc.a88k): the module's data, 0x854
    bytes, all initialized (.rwdi; the same in both): +0 the classes'
    names (17 of 20 characters; no routine reads them), +0x158 and
    +0x3A0 the relationship tables (an action for each pair of classes,
    the larger first: inexact descriptors, exact ones), +0x5E8
    classes_may_be_related's, +0x830 ref_may_generate_exception's (an
    entry per class).  Each table starts on a multiple of 8 (6 bytes
    after each 578-byte table; docs/rev889-patterns.md 50).

  is_display_ptr, alias_ptr_node, check_the_ind, get_alias_desc,
  assert_is_fortran_external_routine_parameter and
  formal_may_alias_actual do not load A5 (internal; is_display_ptr and
  assert_is_fortran_external_routine_parameter have no frame,
  docs/rev889-patterns.md 16); build_alias_desc is global and called
  only here.

  The IL nodes are read by offset (il.ins.pas's views; alias_blk_t for
  a routine block's level and flags, alias_sig_t for kind 159).  The
  cargs fields read are x27d_0 (the long at +0x27C, `andi.l #0x18000;
  lsr 15'), x27e_6 (+0x27E, `andi.b #0x60; lsr #5') and b27e_3: the
  -ALIAS settings (their defaults 2, 2, true).

  Not known from the original: the names of the data, the locals and
  the views' fields; what the relationship actions stand for.
}
module alias;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  alias_bits_t = set of 0..31;
  alias_name_t = array [1..20] of char;
  alias_table_t = array [0..16, 0..16] of integer;

  { A routine block (107, 108) as related_call and
    formal_may_alias_actual read it: the nesting level (a signed byte,
    `move.b; ext.w') and bits of +376 and +379. }
  alias_blk_ptr_t = ^alias_blk_t;
  alias_blk_t = packed record
    unused_0: array [0..293] of char;   { +0 }
    level: -128..127;                   { +294 }
    unused_295: char;
    unused_296: array [296..375] of char;
    b376_7: boolean;                    { +376.7 }
    b376_6: boolean;
    b376_5: boolean;                    { .5: calls nothing outside? }
    b376_x: 0..31;
    unused_377: char;                   { single characters (an array }
    unused_378: char;                   { would start on a word) }
    b379_7: boolean;                    { +379.7 }
    b379_6: boolean;
    b379_5: boolean;
    b379_4: boolean;                    { .4 }
    b379_x: 0..15;
  end;

  { A kind 159 node (a call through a routine type?): the number of
    parameter entries (+10) and two bytes per parameter from +12: bit 7
    of the first, the low four bits of the second (`andi.b #15'). }
  alias_sig_ptr_t = ^alias_sig_t;
  alias_sig_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer32;                { +4 }
    unused_8: integer;                  { +8 }
    count: integer;                     { +10 }
    args: array [1..1000] of packed record   { +12 }
      flag: boolean;
      unused: 0..127;
      unused_hi: 0..15;
      mode: 0..15;
    end;
  end;

var
  { +0: the classes' names. }
  class_names: array [0..16] of alias_name_t := [
    'never_invalidated   ',
    'common_block        ',
    'external            ',
    'static              ',
    'unaliased_static    ',
    'xstatic             ',
    'unaliased_xstatic   ',
    'dynamic             ',
    'unaliased_dynamic   ',
    'xdynamic            ',
    'unaliased_xdynamic  ',
    'dynamic_param_ptr   ',
    'ref_thru_param_ptr  ',
    'random_pointer      ',
    'xdb_relative        ',
    'xsf_relative        ',
    'argument_block      '];
  { +0x158: the action for classes [x, y] when either is inexact. }
  rel_inexact: alias_table_t := [
    [9, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 3, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 9, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 9, 9, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0],
    [9, 2, 7, 4, 0, 0, 0, 0, 0, 0, 0, 9, 6, 10, 0, 0, 0],
    [9, 7, 7, 7, 9, 7, 9, 7, 9, 7, 9, 9, 7, 7, 10, 10, 10],
    [9, 0, 0, 0, 0, 7, 7, 9, 0, 0, 0, 0, 7, 7, 7, 10, 10],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 9, 8, 7, 9, 7, 10],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7]];
  { +0x3A0: the same for exact descriptors. }
  rel_exact: alias_table_t := [
    [9, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 9, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 9, 9, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0],
    [9, 2, 7, 4, 0, 0, 0, 0, 0, 0, 0, 9, 5, 10, 0, 0, 0],
    [9, 7, 7, 7, 9, 7, 9, 7, 9, 7, 9, 9, 7, 7, 10, 10, 10],
    [9, 0, 0, 0, 0, 7, 7, 9, 0, 0, 0, 0, 7, 7, 1, 10, 10],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 9, 8, 7, 9, 1, 10],
    [9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]];
  { +0x5E8: alias_$classes_may_be_related's actions. }
  class_rel: alias_table_t := [
    [4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 4, 4, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0],
    [4, 1, 2, 0, 0, 0, 0, 3, 0, 0, 0, 4, 0, 5, 0, 0, 0],
    [4, 2, 2, 2, 4, 2, 4, 2, 4, 2, 4, 4, 2, 2, 5, 5, 5],
    [4, 0, 0, 0, 0, 2, 2, 4, 0, 0, 0, 0, 2, 2, 2, 5, 5],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 4, 3, 2, 4, 2, 5],
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]];
  { +0x830: alias_$ref_may_generate_exception's entry per class. }
  exc_table: array [0..16] of integer := [2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 1, 2];

{ is_display_ptr - n is a variable (109) or kind 110 with flag 23 (its
  +32 or +24 longword).

  0x0739E4, 0x3E bytes, no frame: n at (4,SP), the result in D0. }

function is_display_ptr(
    n: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if n = nil then
    is_display_ptr := false
  else if (n^.kind = 109) and (23 in alias_bits_t(n^.xl[8])) then
    is_display_ptr := true
  else if (n^.kind = 110) and (23 in alias_bits_t(n^.xl[6])) then
    is_display_ptr := true
  else
    is_display_ptr := false;
end;

function get_alias_desc(
    n: il_$node_ptr_t;
    var d: alias_$desc_t): boolean; options(val_param); internal; forward;

{ alias_ptr_node - d for the pointer expression p (a pointer plus or
  minus a constant, or any other), sym the variable the pointer is
  declared with.

  0x073A22, 0x248 bytes, no A5.  p an operator (137, 138) of + or -
  (+36 1, 2) with an integer constant (+44, the set of 0..207 after the
  routine: 77..87, 101, 200) takes its pointer operand's (+40)
  descriptor and the constant (negated for -) as the displacement; any
  other p its own descriptor with displacement 0.  Then: a parameter
  pointer (11) is ref_thru_param_ptr (12); a pointer into a section
  (195, or 163: its section +8 or +12, its kind (a word at +20, a byte
  for 163) and its offset (+16, +12) added) takes the section as base
  (kind 0 xsf_relative, 1 xdb_relative, 2 external, 3 a common block
  with sym's member found by alias_$get_alias_desc, else one more
  level); never_invalidated with a display base (154, 153), or a
  display pointer (is_display_ptr) with sym a variable, takes sym's
  descriptor (uplevel set); any other one more level, done.  For the
  display bases and the frame relative classes (14, 15) sym (a
  variable) is described into a copy (five longwords) and, when it
  succeeds, taken with sym's offset (+56 of 109, +12 of 110)
  subtracted (else bug_check; a failure for a display base makes the
  result false); without sym, one more level.  The result in D0.

  Not known from the original: the names. }

function alias_ptr_node(
    p: il_$node_ptr_t;
    var d: alias_$desc_t;
    sym: il_$node_ptr_t): boolean; options(val_param); internal;
var
  ok: boolean;
  deref: boolean;
  k: integer;
  t: alias_$desc_t;                     { -32 }
begin
  if ((p^.kind = 138) or (p^.kind = 137)) and
      ((p^.xw[18] = 2) or (p^.xw[18] = 1)) and then
      (p^.xp[11]^.kind in [77..87, 101, 200]) then begin
    ok := get_alias_desc(p^.xp[10], d);
    d.disp := p^.xp[11]^.int_value;
    if p^.xw[18] = 2 then
      d.disp := -d.disp;
  end
  else begin
    d.disp := 0;
    ok := get_alias_desc(p, d);
  end;
  deref := false;
  if d.class = alias_dynamic_param_ptr then
    d.class := alias_ref_thru_param_ptr
  else if (d.base <> nil) and then
      ((d.base^.kind = 195) or (d.base^.kind = 163)) then begin
    if d.base^.kind = 163 then begin
      k := ord(d.base^.xc[20]);
      d.disp := d.disp + d.base^.xl[3];
      d.base := d.base^.xp[2];
    end
    else begin
      k := d.base^.xw[10];
      d.disp := d.disp + d.base^.xl[4];
      d.base := d.base^.xp[3];
    end;
    d.levels := 0;
    case k of
      3: begin
        d.class := alias_common_block;
        if alias_$get_alias_desc(sym, d.size, t) then
          d.sym := t.sym;
      end;
      2: d.class := alias_external;
      1: d.class := alias_xdb_relative;
      0: d.class := alias_xsf_relative;
      otherwise
        d.levels := 1;
    end;
  end
  else if (d.class = alias_never_invalidated) and (d.base <> nil) and then
      ((d.base^.kind = 154) or (d.base^.kind = 153)) then
    deref := true
  else if is_display_ptr(d.base) and (sym <> nil) and then
      ((sym^.kind = 110) or (sym^.kind = 109)) then begin
    ok := get_alias_desc(sym, d);
    d.uplevel := true;
  end
  else begin
    d.levels := d.levels + 1;
    alias_ptr_node := ok;
    return;
  end;
  if deref or (d.class in [alias_xdb_relative, alias_xsf_relative]) then begin
    if (sym <> nil) and then ((sym^.kind = 110) or (sym^.kind = 109)) then begin
      t := d;
      if get_alias_desc(sym, t) then begin
        d := t;
        if sym^.kind = 109 then
          d.disp := d.disp - sym^.xl[14]
        else if sym^.kind = 110 then
          d.disp := d.disp - sym^.xl[3]
        else
          bug_check('\\alias_\alias_ptr_node -- dead beef!!!%.');
      end
      else if deref then
        ok := false;
    end
    else
      d.levels := d.levels + 1;
  end;
  alias_ptr_node := ok;
end;

{ check_the_ind - an indexed reference's index variable sym: for a
  common block member, a frame relative class or a display base, sym's
  descriptor (alias_$get_alias_desc with d's size) gives the member
  (common block) or replaces d, inexact.

  0x073CAE, 0x8A bytes, no A5: sym not nil, levels not negative, a
  base; the classes 1, 14, 15 (`btst' of #0xC002) or a base of kind
  154 or 153.

  Not known from the original: the names. }

procedure check_the_ind(
    sym: il_$node_ptr_t;
    var d: alias_$desc_t); options(val_param); internal;
var
  t: alias_$desc_t;                     { -32 }
begin
  if (sym <> nil) and (d.levels >= 0) and (d.base <> nil) then
    if (d.class in [alias_common_block, alias_xdb_relative,
        alias_xsf_relative]) or (d.base^.kind = 154) or
        (d.base^.kind = 153) then
      if alias_$get_alias_desc(sym, d.size, t) then
        if d.class = alias_common_block then
          d.sym := t.sym
        else begin
          d := t;
          d.inexact := true;
        end;
end;

{ get_alias_desc - d for the IL node n (false when it cannot be
  described).

  0x073D38, 0x758 bytes, no A5, link #-56.  phase_34 when getphase(n)
  has 3 or 4 (`andi.l #24').  An expression node (the set of 0..207:
  137, 138, 143, 145..147, 164, 171, 175, 189, 205) with flag 23 (+4)
  is its operand's (+40; `bsr.s', the arguments left on the stack).
  Else by kind (compared in turn): blocks, sections and constants of
  their own (153, 195, 107, 159, 108, 154, 208, 211, 163) are
  never_invalidated with n as base; 152 its +16's, or itself (+4 the
  displacement, +8 the size) unaliased_dynamic; 204 the argument block
  (il_180, +4); 111 a common block; 164 and 189 their +20's, 190 its
  +4's; 165 and 181 unaliased_dynamic; an indexed reference (145)
  alias_ptr_node(+24, sym +28), +32 added and the index (+36) a
  constant shifted by +40 (`lsl.l') or inexact; an offset reference
  (147) its +24's, check_the_ind(+28) and +32 added; kind 110 (a
  Fortran symbol: its equivalence chain at +28, the lowest node by
  address (`bcc': unsigned) and the union of the chain's flags (+24))
  the variable varn_from_fortran_symbol gives (its flags or-ed with
  the chain's 0, 8, 12, 17: `andi.l #0x21101'), the lowest node as base
  (or member) and the displacement adjusted by the two +12's; 146
  alias_ptr_node(+24, +28); 205 the pointer (+24, through offset
  references 147, then 146 or 145) and the variable +32 (109, 110,
  else inexact and false), inexact unless the pointer is a display
  (153, 211, 154 or is_display_ptr), the offsets added; an operator
  (138, 137) by +36: 26 (indirection) its operand's with one level
  less (ref_thru_param_ptr back to dynamic_param_ptr), 13 inexact, 0,
  63 and 17 with +38 positive its operand's, an operator of the set of
  0..95 after the routine never_invalidated, else false; a variable
  (109) as below; else a constant (the set of 0..207: 77..90, 92, 93,
  101, 156, 176, 198, 200) never_invalidated (no last test) or false.

  A variable: base itself, f19_3 its flag 13 (+34); a variable of a
  kind 121 type of class 2 (+44) without flags 0, 8, 12, 17 and not
  flag 25 without 26 is never_invalidated; flag 17 with a based pointer
  (+52, its +12's +68 a 137, its +52 5) its pointer's descriptor,
  inexact (no last test); else by its vat (+72, a jump table over
  0..11): local 0, stat 3 or 4 (aliased: flags 0, 8, 12, 17), dynm 7
  or 8 (flags 0, 8, 12; uplevel when its block +20 is not il_180),
  ext, extdef, xextdef, abs 2, param 11, xdynm 9 or 10 (uplevel), xstat
  5 or 6, sect a common block (+80 base, sym itself, +56 the
  displacement), based false; above 11 false (no last test).  A static
  class (3..6, `moveq #120') of a variable of a program block (105) is
  the dynamic one (a jump table) with uplevel.

  Last, an expression node (the first set) with flag 17 (+4) is
  never_invalidated with no levels and true.  The result in D0.

  Not known from the original: the names; what the node kinds and
  flags are. }

function get_alias_desc;
var
  ok: boolean;
  m: alias_bits_t;
  top: il_$node_ptr_t;
  v: il_$node_ptr_t;
  w: il_$node_ptr_t;
  x: il_$node_ptr_t;
  y: il_$node_ptr_t;
  off: integer32;
  t: alias_$desc_t;                     { -32 }
begin
  ok := true;
  if getphase(n) * [3, 4] <> [] then
    d.phase_34 := true;
  if (n^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205]) and
      (23 in alias_bits_t(n^.xl[1])) then begin
    get_alias_desc := get_alias_desc(n^.xp[10], d);
    return;
  end;
  case n^.kind of
    153, 195, 107, 159, 108, 154, 208, 211, 163: begin
      d.class := alias_never_invalidated;
      d.base := n;
    end;
    152:
      if n^.xp[4] <> nil then
        ok := get_alias_desc(n^.xp[4], d)
      else begin
        d.base := n;
        d.disp := n^.xl[1];
        d.size := n^.xl[2];
        d.class := alias_unaliased_dynamic;
      end;
    204: begin
      d.class := alias_argument_block;
      d.base := il_180;
      d.disp := n^.xl[1];
    end;
    111: begin
      d.class := alias_common_block;
      d.base := n;
    end;
    164:
      ok := get_alias_desc(n^.xp[5], d);
    165: begin
      d.class := alias_unaliased_dynamic;
      d.base := n;
    end;
    190:
      ok := get_alias_desc(n^.xp[1], d);
    189:
      ok := get_alias_desc(n^.xp[5], d);
    181: begin
      d.class := alias_unaliased_dynamic;
      d.base := n;
    end;
    145: begin
      ok := alias_ptr_node(n^.xp[6], d, n^.xp[7]);
      d.disp := d.disp + n^.xl[8];
      x := n^.xp[9];
      if not (x^.kind in [77..87, 101, 200]) then
        d.inexact := true
      else
        d.disp := d.disp + lshft(x^.int_value, n^.xw[20]);
    end;
    147: begin
      ok := get_alias_desc(n^.xp[6], d);
      check_the_ind(n^.xp[7], d);
      d.disp := d.disp + n^.xl[8];
    end;
    110: begin
      m := [];
      if n^.xp[7] = nil then
        top := n
      else begin
        top := n;
        v := n^.xp[7];
        m := alias_bits_t(top^.xl[6]);
        while v <> nil do begin
          if integer32(v) < integer32(top) then
            top := v;
          m := m + alias_bits_t(v^.xl[6]);
          v := v^.xp[7];
          if v = n then
            exit;
        end;
      end;
      w := varn_from_fortran_symbol(top, top^.xp[10], false);
      w^.xl[8] := integer32(alias_bits_t(w^.xl[8]) + m * [0, 8, 12, 17]);
      ok := get_alias_desc(w, d);
      if 13 in m then
        d.f19_3 := true;
      if d.class = alias_common_block then
        d.sym := top
      else
        d.base := top;
      if (top <> n) and (d.class <> alias_common_block) then
        d.disp := d.disp + n^.xl[3] - top^.xl[3];
    end;
    146:
      ok := alias_ptr_node(n^.xp[6], d, n^.xp[7]);
    205: begin
      x := n^.xp[6];
      off := 0;
      while x^.kind = 147 do begin
        off := off + x^.xl[8];
        x := x^.xp[6];
      end;
      if x^.kind = 146 then
        y := x^.xp[6]
      else if x^.kind = 145 then begin
        y := x^.xp[6];
        if not (x^.xp[9]^.kind in [77..87, 101, 200]) then
          d.inexact := true
        else
          off := off + lshft(x^.xp[9]^.int_value, x^.xw[20]);
      end
      else begin
        d.inexact := true;
        get_alias_desc := false;
        return;
      end;
      if not ((n^.xp[8]^.kind = 110) or (n^.xp[8]^.kind = 109)) then begin
        d.inexact := true;
        ok := false;
      end
      else if (y^.kind = 153) or (y^.kind = 211) or (y^.kind = 154) or
          is_display_ptr(y) then begin
        ok := get_alias_desc(n^.xp[8], d);
        d.disp := d.disp + off;
      end
      else begin
        ok := get_alias_desc(n^.xp[8], d);
        d.inexact := true;
        d.disp := d.disp + off;
      end;
    end;
    138, 137:
      if n^.xw[18] = 26 then begin
        ok := get_alias_desc(n^.xp[10], d);
        if d.class = alias_ref_thru_param_ptr then
          d.class := alias_dynamic_param_ptr
        else
          d.levels := d.levels - 1;
      end
      else if n^.xw[18] = 13 then begin
        ok := get_alias_desc(n^.xp[10], d);
        d.inexact := true;
      end
      else if ((n^.xw[18] = 0) or (n^.xw[18] = 63) or (n^.xw[18] = 17)) and
          (n^.xw[19] > 0) then
        ok := get_alias_desc(n^.xp[10], d)
      else if n^.xw[18] in [1..12, 14, 16, 18, 23..31, 33..41, 43..53, 56,
          57, 59..62, 64..66, 68..71, 74..84, 86, 87] then
        d.class := alias_never_invalidated
      else
        ok := false;
    109: begin
      d.base := n;
      d.disp := 0;
      d.levels := 0;
      d.f19_3 := 13 in alias_bits_t(n^.xl[8]);
      if (n^.xp[7] <> nil) and then (n^.xp[7]^.kind = 121) and
          (n^.xp[7]^.xw[22] = 2) and
          (alias_bits_t(n^.xl[8]) * [0, 8, 12, 17] = []) and
          (not (25 in alias_bits_t(n^.xl[8])) or
           (26 in alias_bits_t(n^.xl[8]))) then
        d.class := alias_never_invalidated
      else begin
        if 17 in alias_bits_t(n^.xl[8]) then begin
          x := n^.xp[13]^.xp[3];
          if (x^.xp[17]^.kind = 137) and (x^.xw[26] = 5) then begin
            t := d;
            if get_alias_desc(x^.xp[17], t) then begin
              d := t;
              d.inexact := true;
              get_alias_desc := ok;
              return;
            end;
          end;
        end;
        case n^.xw[36] of
          9:
            ok := false;
          0:
            d.class := alias_never_invalidated;
          2: begin
            if alias_bits_t(n^.xl[8]) * [0, 8, 12] <> [] then
              d.class := alias_dynamic
            else
              d.class := alias_unaliased_dynamic;
            d.uplevel := il_180 <> n^.xp[5];
          end;
          3, 4, 8, 11:
            d.class := alias_external;
          5:
            d.class := alias_dynamic_param_ptr;
          10: begin
            d.class := alias_common_block;
            d.base := n^.xp[20];
            d.sym := n;
            d.disp := n^.xl[14];
          end;
          1:
            if alias_bits_t(n^.xl[8]) * [0, 8, 12, 17] <> [] then
              d.class := alias_static
            else
              d.class := alias_unaliased_static;
          6: begin
            if alias_bits_t(n^.xl[8]) * [0, 8, 12, 17] <> [] then
              d.class := alias_xdynamic
            else
              d.class := alias_unaliased_xdynamic;
            d.uplevel := il_180 <> n^.xp[5];
          end;
          7:
            if alias_bits_t(n^.xl[8]) * [0, 8, 12, 17] <> [] then
              d.class := alias_xstatic
            else
              d.class := alias_unaliased_xstatic;
          otherwise begin
            get_alias_desc := false;
            return;
          end;
        end;
        if (n^.xp[5] <> nil) and (d.class in [3..6]) and then
            (n^.xp[5]^.kind = 105) then begin
          case d.class of
            3: d.class := alias_dynamic;
            5: d.class := alias_xdynamic;
            4: d.class := alias_unaliased_dynamic;
            6: d.class := alias_unaliased_xdynamic;
          end;
          d.uplevel := il_180 <> n^.xp[5];
        end;
      end;
    end;
    otherwise
      if n^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then begin
        d.class := alias_never_invalidated;
        d.base := n;
        get_alias_desc := ok;
        return;
      end
      else
        ok := false;
  end;
  if (n^.kind in [137, 138, 143, 145, 146, 147, 164, 171, 175, 189, 205]) and
      (17 in alias_bits_t(n^.xl[1])) then begin
    d.class := alias_never_invalidated;
    d.levels := 0;
    ok := true;
  end;
  get_alias_desc := ok;
end;

{ build_alias_desc - d for n with size bytes: false when n is nil or
  get_alias_desc fails (random_pointer, inexact, not valid), or an
  indirect reference through a display; else valid.

  0x0744D0, 0x0D4 bytes: +0..+11 and the levels cleared, five flags
  with one `andi.w #0xFF43' (docs/rev889-patterns.md 10).  A parameter
  pointer (11) becomes never_invalidated without f19_3 (`andi.w
  #0x00F7'); negative levels never_invalidated; positive levels
  random_pointer, inexact when the base is a strength reduction
  temporary (il_utils), false for a display base (153, 154: the size
  not stored).  The size stored last (also on the first failure). }

function build_alias_desc(
    n: il_$node_ptr_t;
    size: integer32;
    var d: alias_$desc_t): boolean; options(val_param);
var
  ok: boolean;
begin
  d.base := nil;
  d.sym := nil;
  d.disp := 0;
  d.levels := 0;
  d.inexact := false;
  d.uplevel := false;
  d.phase_34 := false;
  d.f19_3 := false;
  d.whole := false;
  if n = nil then
    ok := false
  else
    ok := get_alias_desc(n, d);
  if not ok then begin
    d.class := alias_random_pointer;
    d.inexact := true;
    d.valid := false;
    build_alias_desc := false;
  end
  else begin
    if d.class = alias_dynamic_param_ptr then begin
      d.class := alias_never_invalidated;
      d.f19_3 := false;
    end
    else if d.levels < 0 then
      d.class := alias_never_invalidated
    else if d.levels > 0 then begin
      d.class := alias_random_pointer;
      if (d.base <> nil) and then
          ((d.base^.kind = 154) or (d.base^.kind = 153)) then begin
        d.inexact := true;
        d.valid := false;
        build_alias_desc := false;
        return;
      end;
      if not d.inexact and (d.base <> nil) then
        if il_utils_$is_strength_reduction_temp(d.base) then
          d.inexact := true;
    end;
    d.valid := true;
    build_alias_desc := true;
  end;
  d.size := size;
end;

{ alias_$get_alias_desc - build_alias_desc; then for an exact
  descriptor of a variable (its sym, else its base: 110 or 109) whose
  size is known (109: +36 bits div 8; 110 by sz_fsym when its kind
  nibble (+44, `andi.b #0xF0; lsr #4') is 3 with +32 0 or 1 with +40
  set, and +10 not negative) whole is set when the variable's own
  descriptor of that size is identical.

  0x0745A4, 0xE4 bytes, link #-36: the second descriptor at -24. }

function alias_$get_alias_desc;
var
  v: il_$node_ptr_t;
  sz: integer32;
  t: alias_$desc_t;                     { -24 }
begin
  if not build_alias_desc(n, size, d) then begin
    alias_$get_alias_desc := false;
    return;
  end;
  if d.sym <> nil then
    v := d.sym
  else
    v := d.base;
  if (v <> nil) and then ((v^.kind = 110) or (v^.kind = 109)) and
      not d.inexact then begin
    if v^.kind = 109 then
      sz := v^.xl[9] div 8
    else if not (15 in alias_bits_t(v^.xl[2])) and
        (((rshft(v^.xl[11], 28) = 3) and (v^.xl[8] = 0)) or
         ((rshft(v^.xl[11], 28) = 1) and (v^.xl[10] <> 0))) then
      sz := sz_fsym(v)
    else
      sz := 0;
    if sz <> 0 then
      if build_alias_desc(v, sz, t) then
        if alias_$descriptors_are_identical(d, t) then
          d.whole := true;
  end;
  alias_$get_alias_desc := true;
end;

{ alias_$alias_desc_with_size - 0x074688, 0x2C bytes: the result of
  alias_$get_alias_desc not read (link #0: a procedure). }

procedure alias_$alias_desc_with_size;
begin
  discard(alias_$get_alias_desc(n, size, d));
end;

{ alias_$basic_alias_desc - 0x0746B4, 0x2E bytes: size 123456780
  (`move.l #0x075BCD0C'). }

procedure alias_$basic_alias_desc;
begin
  discard(alias_$get_alias_desc(n, 123456780, d));
end;

{ alias_$add_disp - 0x0746E2, 0x2E bytes: valid (`btst #6') or false. }

function alias_$add_disp;
begin
  if not d.valid then
    alias_$add_disp := false
  else begin
    d.disp := d.disp + n;
    alias_$add_disp := true;
  end;
end;

{ alias_$ind_for_captured_lvalue - 0x074710, 0x82 bytes: n's basic
  descriptor (-24); nil when that fails or for never_invalidated; a
  common block's member (sym), the base for the classes 1..12 (`btst'
  of #0x1FFE), il_node_154 for xdb_relative, il_node_153 for
  xsf_relative, else nil.  The result in A0. }

function alias_$ind_for_captured_lvalue;
var
  d: alias_$desc_t;                     { -24 }
begin
  if not alias_$get_alias_desc(n, 123456780, d) then
    alias_$ind_for_captured_lvalue := nil
  else if d.class = alias_never_invalidated then
    alias_$ind_for_captured_lvalue := nil
  else if d.class = alias_common_block then
    alias_$ind_for_captured_lvalue := d.sym
  else if d.class in [1..12] then
    alias_$ind_for_captured_lvalue := d.base
  else if d.class = alias_xdb_relative then
    alias_$ind_for_captured_lvalue := il_node_154
  else if d.class = alias_xsf_relative then
    alias_$ind_for_captured_lvalue := il_node_153
  else
    alias_$ind_for_captured_lvalue := nil;
end;

{ assert_is_fortran_external_routine_parameter - p is kind 110 with
  flag 1 (+11 bit 1), kind nibble 1 (+44) and +40 0.

  0x074792, 0x36 bytes, no frame: p at (4,SP), `seq' of `tst.l'. }

function assert_is_fortran_external_routine_parameter(
    p: il_$node_ptr_t): boolean; options(val_param); internal;
begin
  if (p <> nil) and then (p^.kind = 110) and (1 in alias_bits_t(p^.xl[2])) and
      (rshft(p^.xl[11], 28) = 1) then
    assert_is_fortran_external_routine_parameter := p^.xl[10] = 0
  else
    assert_is_fortran_external_routine_parameter := false;
end;

{ formal_may_alias_actual - a formal parameter (a) and an actual's
  storage (b) may overlap.

  0x0747C8, 0x110 bytes, no A5.  The routines: a's base's (109: +20,
  110: +40) and b's (109, 110 as a's, 165: +8, 152: il_180; else
  bug_check).  Either a Fortran external routine parameter: true.  A
  formal of a deeper routine (+294, signed) than the actual's: false
  for the unaliased classes and never_invalidated (`btst' of #0x551)
  without f19_3; else false for the dynamic classes, 15, 16 (#0x18F80)
  and for the unaliased ones unless f19_3 and the actual's routine has
  +379 bit 4 clear.  The bug_check messages are the image's.

  Not known from the original: the names. }

function formal_may_alias_actual(
    var a: alias_$desc_t;
    var b: alias_$desc_t): boolean; internal;
var
  ra: il_$node_ptr_t;
  rb: il_$node_ptr_t;
begin
  if a.base^.kind = 109 then
    ra := a.base^.xp[5]
  else if a.base^.kind = 110 then
    ra := a.base^.xp[10]
  else
    bug_check('\\alias_\formal_may_alias_actual -- unknown kind for formal parameter%.');
  if b.base^.kind = 109 then
    rb := b.base^.xp[5]
  else if b.base^.kind = 110 then
    rb := b.base^.xp[10]
  else if b.base^.kind = 165 then
    rb := b.base^.xp[2]
  else if b.base^.kind = 152 then
    rb := il_180
  else
    bug_check('\\alias_\formal_may_alias_actual -- unknown actual kind parameter%.');
  if assert_is_fortran_external_routine_parameter(a.base) or
      assert_is_fortran_external_routine_parameter(b.base) then
    formal_may_alias_actual := true
  else if alias_blk_ptr_t(ra)^.level > alias_blk_ptr_t(rb)^.level then
    formal_may_alias_actual := not ((b.class in [0, 4, 6, 8, 10]) and not b.f19_3)
  else if b.class in [7..11, 15, 16] then
    formal_may_alias_actual := false
  else if b.class in [0, 4, 6, 8, 10] then
    formal_may_alias_actual := b.f19_3 and not alias_blk_ptr_t(rb)^.b379_4
  else
    formal_may_alias_actual := true;
end;

{ alias_$relationship - how a and b may overlap: 0 not, 1 exactly, 2
  maybe.

  0x074964, 0x322 bytes, link #-20.  Either not valid: 0 when a valid
  one is never_invalidated, else 2.  Both phase_34: 2.  Then x is the
  one of the larger class (unsigned) or, of one class, the smaller
  displacement; the action is x's class's row, y's column of the
  inexact table (+0x158) when either is inexact, else the exact one
  (+0x3A0); by action (a jump table over 0..9): 0 2 unless both have
  bases that differ; 1 the same base overlapping (x's displacement
  plus size beyond y's) or a missing base 2; 2 by x27e_6 (2: 2, 1: 0),
  then without y's sym 2, either inexact 1, else y's displacement less
  its sym's offset (110: +12, 109: +56, else bug_check) overlapping x;
  3 bases differ 0, else 2 when b27e_3, the syms are the same or one
  is missing; 4 formal_may_alias_actual; 5 a missing base 2, the same
  base overlapping, else by x27d_0 (1: 0, 2: 2) overlapping; 6 by
  x27d_0 (2 or a missing base: 2; the same base or 0: 1); 7 2; 8
  either uplevel; 9 0; above, bug_check('ALIAS_$RELATIONSHIP:  Invalid
  action.%$').  The result a word in D0.

  Not known from the original: the names; what the actions stand for. }

function alias_$relationship;
var
  x: alias_$desc_ptr_t;
  y: alias_$desc_ptr_t;
  action: integer;
  off: integer32;
  setting: integer;
begin
  if not (a.valid and b.valid) then begin
    if (a.valid and (a.class = alias_never_invalidated)) or
        (b.valid and (b.class = alias_never_invalidated)) then
      alias_$relationship := 0
    else
      alias_$relationship := 2;
    return;
  end;
  if a.phase_34 and b.phase_34 then begin
    alias_$relationship := 2;
    return;
  end;
  if a.class <> b.class then
    if a.class > b.class then begin
      x := addr(a);
      y := addr(b);
    end
    else begin
      x := addr(b);
      y := addr(a);
    end
  else if a.disp < b.disp then begin
    x := addr(a);
    y := addr(b);
  end
  else begin
    x := addr(b);
    y := addr(a);
  end;
  if x^.inexact or y^.inexact then
    action := rel_inexact[x^.class, y^.class]
  else
    action := rel_exact[x^.class, y^.class];
  case action of
    0:
      if (y^.base = nil) or (x^.base = y^.base) or (x^.base = nil) then
        alias_$relationship := 2
      else
        alias_$relationship := 0;
    1:
      if (x^.base = nil) or (y^.base = nil) then
        alias_$relationship := 2
      else if (x^.base = y^.base) and (x^.disp + x^.size > y^.disp) then
        alias_$relationship := 2
      else
        alias_$relationship := 0;
    2: begin
      setting := cargs_$options.x27e_6;
      if setting = 2 then
        alias_$relationship := 2
      else if setting = 1 then
        alias_$relationship := 0
      else if y^.sym = nil then
        alias_$relationship := 2
      else if x^.inexact or y^.inexact then
        alias_$relationship := 1
      else begin
        if y^.sym^.kind = 110 then
          off := y^.sym^.xl[3]
        else if y^.sym^.kind = 109 then
          off := y^.sym^.xl[14]
        else
          bug_check('ALIAS_$RELATIONSHIP -- expected variable in SYM field%$');
        off := y^.disp - off;
        if off > x^.disp then
          if x^.disp + x^.size > off then
            alias_$relationship := 2
          else
            alias_$relationship := 0
        else if y^.size + off > x^.disp then
          alias_$relationship := 2
        else
          alias_$relationship := 0;
      end;
    end;
    3:
      if (x^.base = nil) or (y^.base = nil) then
        alias_$relationship := 2
      else if x^.base <> y^.base then
        alias_$relationship := 0
      else if cargs_$options.b27e_3 or (x^.sym = y^.sym) or
          (x^.sym = nil) or (y^.sym = nil) then
        alias_$relationship := 2
      else
        alias_$relationship := 0;
    4:
      if formal_may_alias_actual(x^, y^) then
        alias_$relationship := 2
      else
        alias_$relationship := 0;
    5:
      if (x^.base = nil) or (y^.base = nil) then
        alias_$relationship := 2
      else if x^.base = y^.base then
        if x^.disp + x^.size > y^.disp then
          alias_$relationship := 2
        else
          alias_$relationship := 0
      else begin
        setting := cargs_$options.x27d_0;
        if setting = 1 then
          alias_$relationship := 0
        else if (setting = 2) or (x^.disp + x^.size > y^.disp) then
          alias_$relationship := 2
        else
          alias_$relationship := 0;
      end;
    6: begin
      setting := cargs_$options.x27d_0;
      if (setting = 2) or (x^.base = nil) or (y^.base = nil) then
        alias_$relationship := 2
      else if (x^.base = y^.base) or (setting = 0) then
        alias_$relationship := 1
      else
        alias_$relationship := 0;
    end;
    7:
      alias_$relationship := 2;
    8:
      if x^.uplevel or y^.uplevel then
        alias_$relationship := 2
      else
        alias_$relationship := 0;
    9:
      alias_$relationship := 0;
    otherwise
      bug_check('ALIAS_$RELATIONSHIP:  Invalid action.%$');
  end;
end;

{ alias_$related - 0x074CE6, 0x34 bytes: `tst.w; sne'. }

function alias_$related;
begin
  alias_$related := alias_$relationship(a, b) <> 0;
end;

{ alias_$unrelated_or_exact - 0x074D1A, 0x36 bytes: `cmpi.w #2;
  sne'. }

function alias_$unrelated_or_exact;
begin
  alias_$unrelated_or_exact := alias_$relationship(a, b) <> 2;
end;

{ alias_$classes_may_be_related - 0x074D50, 0xB2 bytes: the larger
  class first (`bcc': unsigned), its row of the table at +0x5E8 (a
  jump table over 0..4): 0 2 when x27d_0 is 1, else 0; 1 2 when x27e_6
  is 1, else 0; 2 0; 3 1; 4 2; above,
  bug_check('ALIAS_$CLASSES_MAY_BE_RELATED:  invalid action.%$'). }

function alias_$classes_may_be_related;
var
  t: integer;
begin
  if c1 < c2 then begin
    t := c1;
    c1 := c2;
    c2 := t;
  end;
  case class_rel[c1, c2] of
    0:
      if cargs_$options.x27d_0 = 1 then
        alias_$classes_may_be_related := 2
      else
        alias_$classes_may_be_related := 0;
    1:
      if cargs_$options.x27e_6 = 1 then
        alias_$classes_may_be_related := 2
      else
        alias_$classes_may_be_related := 0;
    2:
      alias_$classes_may_be_related := 0;
    3:
      alias_$classes_may_be_related := 1;
    4:
      alias_$classes_may_be_related := 2;
    otherwise
      bug_check('ALIAS_$CLASSES_MAY_BE_RELATED:  invalid action.%$');
  end;
end;

{ alias_$ref_may_generate_exception - 0x074E34, 0x46 bytes: by the
  class's entry at +0x830: 0 true, 1 inexact, 2 false (compared in
  turn; no otherwise). }

function alias_$ref_may_generate_exception;
begin
  case exc_table[d.class] of
    0: alias_$ref_may_generate_exception := true;
    1: alias_$ref_may_generate_exception := d.inexact;
    2: alias_$ref_may_generate_exception := false;
  end;
end;

{ alias_$descriptors_are_identical - 0x074E7A, 0xCC bytes: every
  comparison made (`seq', `and.b'), phase_34 and +19 bits 1, 0 not
  compared. }

function alias_$descriptors_are_identical;
begin
  alias_$descriptors_are_identical := (a.base = b.base) and
      (a.sym = b.sym) and (a.disp = b.disp) and (a.size = b.size) and
      (a.levels = b.levels) and (a.class = b.class) and
      (a.inexact = b.inexact) and (a.valid = b.valid) and
      (a.uplevel = b.uplevel) and (a.f19_3 = b.f19_3) and
      (a.whole = b.whole);
end;

{ alias_$related_call - the call n (its routine or routine expression
  at +40, its arguments from +44, n^.xw[19] - n^.xw[13] - 1 of them)
  may touch d's storage.

  0x074F46, 0x3C4 bytes, link #-96.  Not valid: true; never_invalidated:
  false.  Unless the class is a dynamic one, 15 or 16 (#0x18F80) or the
  routine a kind 159, true unless the class is 3..11, 14..16
  (#0x1CFF8) and il_180 is a program (105).  Then by the routine's
  kind (175 looked through, +20): a routine block (108, 107) is true
  with +376 bit 5; a nested one (level, +294, not negative) is true
  for a variable of its scope chain (the variable's block +20 among
  the routine's +8 chain) when the variable has flag 8 (+34) or a
  static or dynamic class outside a program, or for a 110 with flag 8
  (+26) at a level above 0; then each argument against its parameter
  (the chain at +12, kind 121, a by-reference mode 1, 3, 4: `btst' of
  #26) by its basic descriptor, inexact, alias_$related; a missing or
  other parameter checks every argument instead.  174 and 173 the
  same (+79 bit 5; the parameters at +4).  159 the arguments whose
  entry (the last run of flagged entries before the count, `dbf') has
  mode 10 or 11.  171 (its routine +16, a block with +376 bit 5 true)
  the arguments that are indirections (26) of 137 or 138 (through 190
  +4 and 189 +20).  Any other: every argument whose basic descriptor's
  class is not 0.  The result a byte in D0.

  Not known from the original: the names; the node kinds. }

function alias_$related_call;
var
  f: il_$node_ptr_t;
  p: il_$node_ptr_t;
  a: il_$node_ptr_t;
  v: il_$node_ptr_t;
  r: il_$node_ptr_t;
  i: integer32;
  j: integer32;
  k: integer32;
  all_args: boolean;
  t: alias_$desc_t;                     { -24 }
begin
  if not d.valid then begin
    alias_$related_call := true;
    return;
  end;
  if d.class = alias_never_invalidated then begin
    alias_$related_call := false;
    return;
  end;
  alias_$related_call := true;
  f := n^.xp[10];
  if not (d.class in [7..11, 15, 16]) and (f^.kind <> 159) then
    if not (d.class in [3..11, 14..16]) or (il_180^.kind <> 105) then
      return;
  while f^.kind = 175 do
    f := f^.xp[5];
  all_args := false;
  case f^.kind of
    108, 107: begin
      if alias_blk_ptr_t(f)^.b376_5 then
        return;
      if alias_blk_ptr_t(f)^.level >= 0 then begin
        v := d.base;
        if v^.kind = 109 then begin
          if (8 in alias_bits_t(v^.xl[8])) or
              ((d.class in [3..11, 14..16]) and (il_180^.kind <> 105)) then begin
            r := f^.xp[2];
            while r <> nil do begin
              if v^.xp[5] = r then
                return;
              r := r^.xp[2];
            end;
          end;
        end
        else if (alias_blk_ptr_t(f)^.level > 0) and (v^.kind = 110) and
            (8 in alias_bits_t(v^.xl[6])) then
          return;
      end;
      p := f^.xp[3];
      for i := 0 to n^.xw[19] - n^.xw[13] - 2 do begin
        if (p = nil) or else (p^.kind <> 121) then begin
          all_args := true;
          exit;
        end;
        if p^.xw[22] in [1, 3, 4] then begin
          alias_$basic_alias_desc(n^.xp[11 + i], t);
          t.inexact := true;
          if alias_$related(d, t) then
            return;
        end;
        p := p^.xp[1];
      end;
    end;
    174, 173: begin
      if 5 in alias_bits_t(f^.xl[19]) then
        return;
      p := f^.xp[1];
      for i := 0 to n^.xw[19] - n^.xw[13] - 2 do begin
        if (p = nil) or else (p^.kind <> 121) then begin
          all_args := true;
          exit;
        end;
        if p^.xw[22] in [1, 3, 4] then begin
          alias_$basic_alias_desc(n^.xp[11 + i], t);
          t.inexact := true;
          if alias_$related(d, t) then
            return;
        end;
        p := p^.xp[1];
      end;
    end;
    159: begin
      j := 0;
      for i := 0 to n^.xw[19] - n^.xw[13] - 2 do begin
        j := j + 1;
        if alias_sig_ptr_t(f)^.count < j then begin
          j := alias_sig_ptr_t(f)^.count;
          for k := alias_sig_ptr_t(f)^.count downto 1 do begin
            if not alias_sig_ptr_t(f)^.args[k].flag then
              exit;
            j := k;
          end;
        end;
        if alias_sig_ptr_t(f)^.args[j].mode in [10, 11] then begin
          alias_$basic_alias_desc(n^.xp[11 + i], t);
          t.inexact := true;
          if alias_$related(d, t) then
            return;
        end;
      end;
    end;
    171: begin
      r := f^.xp[4];
      if ((r^.kind = 108) or (r^.kind = 107)) and
          alias_blk_ptr_t(r)^.b376_5 then
        return;
      for i := 0 to n^.xw[19] - n^.xw[13] - 2 do begin
        a := n^.xp[11 + i];
        while (a^.kind = 190) or (a^.kind = 189) do
          if a^.kind = 190 then
            a := a^.xp[1]
          else
            a := a^.xp[5];
        if ((a^.kind = 137) or (a^.kind = 138)) and (a^.xw[18] = 26) then begin
          alias_$basic_alias_desc(a^.xp[10], t);
          t.inexact := true;
          if alias_$related(d, t) then
            return;
        end;
      end;
    end;
    otherwise
      all_args := true;
  end;
  if all_args then
    for i := 0 to n^.xw[19] - n^.xw[13] - 2 do begin
      alias_$basic_alias_desc(n^.xp[11 + i], t);
      if t.class <> alias_never_invalidated then begin
        t.inexact := true;
        if alias_$related(d, t) then
          return;
      end;
    end;
  alias_$related_call := false;
end;
