{ c_def_sem - the declarations' semantics: name lookup in the block
  chain (blk_fnd_name, fnd_name, def_name), the externs declared in
  blocks (the link table, a module block of its own, emptied into the
  outermost block at the end), the types the declarations build
  (pointers and forward pointers, arrays, subranges, enumerations,
  structures and unions with their fields and bit fields, functions),
  incomplete structure types, type_exp (what a type is: bounds, sizes,
  alignment), type compatibility (check_types and the prototypes'),
  variables (def_varn: redeclarations merged, storage classes, common
  block sections, .bss), typedefs, enumeration constants, static and
  dynamic initializers, and the blocks (def_blk_skeleton, the
  parameters' allocation in def_blk_params, def_alloc_var).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0451B4  0x045434  calc_align
    0x0451EE  0x04546E  get_constant_size
    0x0452A4  0x045524  fnd_param
    0x045302  0x045582  blk_fnd_name
    0x045390  0x045610  fnd_name
    0x0453C2  0x045642  def_name
    0x04548E  0x04570E  lnktbl_init
    0x0454AC  0x04572C  lnktbl_del_name
    0x04552C  0x0457AC  lnktbl_first_name
    0x045540  0x0457C0  lnktbl_to_modblk
    0x045582  0x045802  def_lnktbl_clear
    0x0455B0  0x045830  lnktbl_def_name
    0x0455DA  0x04585A  def_virt_varn
    0x045622  0x0458A2  def_drop_tnames
    0x045650  0x0458D0  def_incomplete_su
    0x04571C  0x04599C  add_incomplete_type
    0x04576E  0x0459EE  def_resolve_incomplete_types
    0x04590A  0x045B8A  type_exp
    0x045878  0x045AF8  fix_array_decl
    0x045E62  0x0460E2  promote_type
    0x045F22  0x0461A2  all_promoted_types
    0x045F7C  0x0461FC  check_oldef_proto
    0x04607E  0x0462FE  check_protos
    0x046162  0x0463E2  check_types
    0x046334  0x0465B4  has_data_init
    0x046342  0x0465C2  def_sect
    0x046742  0x0469C2  def_varn
    0x0463DE  0x04665E  update_attr
    0x04647E  0x0466FE  delete_section
    0x0464CC  0x04674C  redecl_as_static
    0x0465F4  0x046874  ext2sect_addr_cons
    0x04666E  0x0468EE  make_comblk_sect
    0x0466FC  0x04697C  alloc_bss
    0x046D98  0x047018  add_varn
    0x046E60  0x0470E0  add_reg_var
    0x046EC4  0x047144  add_parm
    0x046F7C  0x0471FC  lookup_su
    0x046FDC  0x04725C  add_su
    0x047012  0x047292  def_su
    0x047064  0x0472E4  create_and_link_data_rec
    0x04717A  0x0473FA  def_data
    0x0471CE  0x04744E  def_dynm_data
    0x047230  0x0474B0  def_typn
    0x0472C6  0x047546  def_conn
    0x04731A  0x04759A  def_enum_skeleton
    0x04734E  0x0475CE  def_enum_list
    0x0475C2  0x047842  def_subr
    0x047614  0x047894  def_ptr
    0x0476DC  0x04795C  def_fwd_ptr
    0x047738  0x0479B8  def_resolve_fwd_ptrs
    0x04780C  0x047A8C  def_final_res_fwd_ptrs
    0x0478B4  0x047B34  def_func
    0x047956  0x047BD6  def_fld
    0x047FDC  0x04825C  def_rec
    0x0480A4  0x048324  def_arr
    0x0484F8  0x048778  def_blk_skeleton
    0x048A96  0x048D16  def_blk_params
    0x048F0C  0x04918C  alloc_on_stk
    0x048FE0  0x049260  def_alloc_var
    A5 0x140054 (cc.m68k), 0x2C0054 (cc.a88k), 0x58 bytes: six
    (identifier, word) pairs cc enters (+0x0..+0x2C, c_globals.ins.pas),
    the link table (+0x30), the sections (+0x38, +0x3C), the dynamic
    initializers' last and first (+0x40, +0x44), the forward pointers
    (+0x4C), the current and the outermost block (+0x50, +0x54); +0x34
    and +0x48 are reached by no instruction of either binary.

  The routines that load A5 are global (def_name, called only here,
  is declared in this unit); the others are internal and reach the
  module's data on their callers' A5.  fix_array_decl is nested in
  type_exp, update_attr, delete_section, redecl_as_static,
  ext2sect_addr_cons, make_comblk_sect and alloc_bss in def_varn
  (redecl_as_static reads def_varn's vat through its dynamic link).

  Probable slips of the original kept (docs/questions.md 56): add_parm and
  def_fld, on a second parameter or field of a name, set the earlier
  one's type to il_178; def_virt_varn stores at +28 of a 28-byte node;
  redecl_as_static does not step past an address constant it changed
  when the variable's type has no size.
}
module c_def_sem;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';

define
  cdef_id_ulongjmp;                     { +0x0 (c_globals.ins.pas) }
  cdef_04;
  cdef_id_longjmp;
  cdef_0c;
  cdef_id_sigsetjmp;
  cdef_14;
  cdef_id_pfm_cleanup;
  cdef_1c;
  cdef_id_usetjmp;
  cdef_24;
  cdef_id_setjmp;
  cdef_2c;
  cdef_data_sect;                       { +0x38 }
  cdef_code_sect;                       { +0x3C }
  cdef_dynm_inits;                      { +0x44 }
  cdef_fwd_ptrs;                        { +0x4C }
  cdef_50;                              { +0x50 }
  cdef_outer_block;                     { +0x54 }

type
  { A static initializer's piece (113, 24 bytes; a section's or the
    data section's chain): the variable, the offset, the constant and
    its size; a run of one constant (114, 16 bytes) as the value. }
  drec_ptr_t = ^drec_t;
  drec_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    next: drec_ptr_t;                   { +4 }
    dsym: c_sym_ptr_t;                  { +8 }
    offset: integer32;                  { +12 }
    value: il_$node_ptr_t;              { +16: a constant, or a 114 }
    size: integer32;                    { +20 }
  end;
  drep_ptr_t = ^drep_t;
  drep_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: integer32;                { +4 }
    con: il_$node_ptr_t;                { +8 }
    count: integer32;                   { +12 }
  end;

var
  lnktbl: c_blk_ptr_t;                  { +0x30: the link table, a
                                          module block (106) of the
                                          externs declared in blocks }
  dynm_last: c_dynm_ptr_t;              { +0x40 }

{ calc_align - round x up (down <> 0: down) to a multiple of 2**n.

  0x0451B4, 0x3A bytes, link #-8 (no locals used).

  Not known from the original:
  - the names; why the frame has 8 bytes. }

procedure calc_align(
    var x: integer32;
    n: integer;
    down: integer); options(val_param); internal;
var
  m: integer32;
begin
  m := lshft(-1, n) & x;
  if m <> x then
    if down = 0 then
      x := m + lshft(1, n)
    else
      x := m;
end;

{ get_constant_size - the bytes of a constant node by its kind (a
  string's or a set's length, a 176's +8).

  0x0451EE, 0xB6 bytes, no frame (docs/rev889-patterns.md 16); the
  labels compared in this order (the string's arm shared by 156).

  Not known from the original:
  - the names. }

function get_constant_size(
    con: il_$node_ptr_t): integer32; options(val_param); internal;
begin
  case con^.kind of
    92:
      get_constant_size := con^.str_len;
    77, 87, 86, 200:
      get_constant_size := 1;
    78, 83, 80, 84, 81:
      get_constant_size := 2;
    137, 195, 163, 88, 79, 85, 82:
      get_constant_size := 4;
    90, 89:
      get_constant_size := 8;
    198:
      get_constant_size := 16;
    156:
      get_constant_size := con^.set_len;
    176:
      get_constant_size := con^.xl[2];
    otherwise
      get_constant_size := 0;
  end;
end;

{ fnd_param - see c_externs.ins.pas: the spellings compared
  (compare_bytes), not the identifiers.

  0x0452A4, 0x5E bytes, link #-8. }

function fnd_param;
var
  p, r: c_parm_ptr_t;
begin
  r := c_parm_ptr_t(il_178);
  p := list;
  while p <> nil do begin
    if compare_bytes(p^.pname.id^.idnt_name, p^.pname.id^.idnt_len,
                     name.id^.idnt_name, name.id^.idnt_len) = 0 then begin
      r := p;
      exit;
    end;
    p := p^.next;
  end;
  fnd_param := r;
end;

{ blk_fnd_name - see c_externs.ins.pas: the identifier's chain of
  symbols searched for one of the block, then of each enclosing block
  (unless local); a symbol found from an inner block gets its uplevel
  flag; a virtual one (230) answers its variable.  Only identifiers
  (76) are looked up.

  0x045302, 0x8E bytes, link #-12; `not local and report' evaluated
  whole (`not.b; and.b; bpl').

  Not known from the original:
  - the names. }

function blk_fnd_name;
var
  b: c_blk_ptr_t;
  s: c_sym_ptr_t;
begin
  if name.id^.kind = 76 then begin
    b := blk;
    repeat
      s := c_sym_ptr_t(name.id^.idnt_unused_8);
      while s <> nil do begin
        if s^.block = il_$node_ptr_t(b) then begin
          if b <> blk then
            s^.uplevel := true;
          if s^.kind = 230 then
            s := s^.virt_sym;
          blk_fnd_name := il_$node_ptr_t(s);
          return;
        end;
        s := s^.next;
      end;
      b := b^.outer;
    until local or (b = nil);
    if not local and report then
      error1(23, name.line, name.id);
  end;
  blk_fnd_name := il_178;
end;

{ fnd_name - see c_externs.ins.pas.

  0x045390, 0x32 bytes, link #-4. }

function fnd_name;
begin
  fnd_name := blk_fnd_name(name, local, report, c_blk_ptr_t(il_180));
end;

{ def_name - enter the symbol s as name's meaning in blk: its name
  (the pair copied whole, the uplevel flag cleared), the identifier's
  chain and the block's.  A name already declared in blk is
  diagnostic 258 under -USRCH, else 24 (with the earlier line); s then
  gets il_178 as its name and block.

  0x0453C2, 0xCC bytes, link #-4.

  Not known from the original:
  - the names; why -USRCH chooses the diagnostic. }

procedure def_name(
    in name: univ c_name_t;
    s: c_sym_ptr_t;
    blk: c_blk_ptr_t); options(val_param);
var
  old: il_$node_ptr_t;
begin
  if name.id^.kind = 76 then begin
    old := blk_fnd_name(name, true, true, blk);
    if old = il_178 then begin
      s^.name := name.id;
      s^.line := name.line;
      s^.unused_11 := name.unused_7;
      s^.uplevel := false;
      s^.next := c_sym_ptr_t(name.id^.idnt_unused_8);
      s^.blk_next := blk^.syms;
      s^.block := il_$node_ptr_t(blk);
      name.id^.idnt_unused_8 := integer32(s);
      blk^.syms := il_$node_ptr_t(s);
    end
    else begin
      if cargs_$options.usrch then
        error1(258, name.line, name.id)
      else
        error2(24, name.line, name.id,
               smcontk(81, c_sym_ptr_t(old)^.line));
      s^.name := il_178;
      s^.block := il_178;
    end;
  end;
end;

{ lnktbl_init - the link table: a module block (106, 520 bytes).

  0x04548E, 0x1E bytes, link #-4. }

procedure lnktbl_init; internal;
begin
  lnktbl := gspace(520);
  lnktbl^.kind := 106;
end;

{ lnktbl_del_name - take name's symbol out of the link table: out of
  the table's chain and the identifier's.

  0x0454AC, 0x80 bytes, link #-16. }

procedure lnktbl_del_name(
    in name: univ c_name_t); internal;
var
  s, p: c_sym_ptr_t;
  id: il_$node_ptr_t;
begin
  s := c_sym_ptr_t(blk_fnd_name(name, true, false, lnktbl));
  if s <> c_sym_ptr_t(il_178) then begin
    if lnktbl^.syms = il_$node_ptr_t(s) then
      lnktbl^.syms := s^.blk_next
    else begin
      p := c_sym_ptr_t(lnktbl^.syms);
      while p^.blk_next <> il_$node_ptr_t(s) do
        p := c_sym_ptr_t(p^.blk_next);
      p^.blk_next := s^.blk_next;
    end;
    id := s^.name;
    if c_sym_ptr_t(id^.idnt_unused_8) = s then
      id^.idnt_unused_8 := integer32(s^.next)
    else begin
      p := c_sym_ptr_t(id^.idnt_unused_8);
      while p^.next <> s do
        p := p^.next;
      p^.next := s^.next;
    end;
  end;
end;

{ lnktbl_first_name - the link table's first symbol (nil without a
  table).

  0x04552C, 0x14 bytes, no frame. }

function lnktbl_first_name: c_sym_ptr_t; internal;
begin
  if lnktbl = nil then
    lnktbl_first_name := nil
  else
    lnktbl_first_name := c_sym_ptr_t(lnktbl^.syms);
end;

{ lnktbl_to_modblk - move s from the link table to the outermost block
  (diagnostic 290 for nil).

  0x045540, 0x42 bytes, link #-4: s's name passed as the pair at +4. }

procedure lnktbl_to_modblk(
    s: c_sym_ptr_t); options(val_param); internal;
begin
  if s = nil then
    error0(290, lex_line)
  else begin
    lnktbl_del_name(s^.name);
    def_name(s^.name, s, c_blk_ptr_t(cdef_outer_block));
  end;
end;

{ def_lnktbl_clear - see c_externs.ins.pas.

  0x045582, 0x2E bytes, link #-4. }

procedure def_lnktbl_clear;
var
  s: c_sym_ptr_t;
begin
  s := lnktbl_first_name;
  while s <> nil do begin
    lnktbl_to_modblk(s);
    s := lnktbl_first_name;
  end;
end;

{ lnktbl_def_name - enter s in the link table (made at first use).

  0x0455B0, 0x2A bytes, link #-4. }

procedure lnktbl_def_name(
    in name: c_name_t;
    s: c_sym_ptr_t); options(val_param); internal;
begin
  if lnktbl = nil then
    lnktbl_init;
  def_name(name, s, lnktbl);
end;

{ def_virt_varn - a virtual symbol (230) for the variable v named name
  in blk.

  0x0455DA, 0x48 bytes, link #-12: gspace(28), then a store at +28
  (beyond the 28 bytes).

  Not known from the original:
  - the names; the node's size (a slip, or gspace's rounding). }

procedure def_virt_varn(
    in name: c_name_t;
    v: c_sym_ptr_t;
    blk: c_blk_ptr_t); options(val_param); internal;
var
  s: c_sym_ptr_t;
begin
  s := gspace(28);
  s^.kind := 230;
  s^.virt_sym := v;
  def_name(name, s, blk);
end;

{ def_drop_tnames - see c_externs.ins.pas.

  0x045622, 0x2E bytes, link #-8. }

function def_drop_tnames;
var
  r: c_type_ptr_t;
begin
  r := t;
  while (r <> nil) and then (r^.kind = 118) do
    r := c_sym_ptr_t(r)^.td_type;
  def_drop_tnames := r;
end;

{ def_incomplete_su - see c_externs.ins.pas: through typedefs (118) and
  arrays (127, 131); diagnostic 284 for a kind not expected.

  0x045650, 0xCC bytes, link #-8; the loop's kinds compared 131, 118,
  127.

  Not known from the original:
  - the names. }

function def_incomplete_su;
var
  r: boolean;
begin
  r := false;
  holder := nil;
  while (t^.kind = 131) or (t^.kind = 118) or (t^.kind = 127) do
    case t^.kind of
      118:
        t := c_sym_ptr_t(t)^.td_type;
      131, 127:
        t := t^.arr_elem;
    end;
  case t^.kind of
    132:
      if (t^.su_fields = nil) and (t^.su_tag <> nil) then begin
        holder := t^.su_tag;
        r := true;
      end;
    129, 210, 108, 234, 123, 122, 130, 73:
      ;
    otherwise
      error0(284, lex_line);
  end;
  def_incomplete_su := r;
end;

{ add_incomplete_type - append n (a variable, typedef or array) to the
  tag's list of what waits for it (a kind 160 entry, 12 bytes).

  0x04571C, 0x52 bytes, link #-12. }

procedure add_incomplete_type(
    n: il_$node_ptr_t;
    tag: c_tag_ptr_t); options(val_param); internal;
var
  e, p: c_reglist_ptr_t;
begin
  e := gspace(12);
  e^.kind := 160;
  e^.rvar := n;
  p := tag^.body.incomplete;
  if p = nil then
    tag^.body.incomplete := e
  else begin
    while p^.next <> nil do
      p := p^.next;
    p^.next := e;
  end;
end;

{ def_resolve_incomplete_types - see c_externs.ins.pas: each waiting
  entry once its type is complete: a typedef's flags merged again, an
  array made again in place (def_arr, the declarations built from the
  array and the tag's name and line), a variable's flags and size
  again; diagnostic 285 for another kind.  The list is consumed.

  0x04576E, 0x10A bytes, link #-116; lex_line's address loaded into D2
  and not used.

  Not known from the original:
  - the names. }

procedure def_resolve_incomplete_types;
var
  ix, el: c_decl_t;
  a: c_dattr_t;
  n: il_$node_ptr_t;
  s: c_sym_ptr_t;
  t: c_type_ptr_t;
begin
  while tag.incomplete <> nil do begin
    n := tag.incomplete^.rvar;
    case n^.kind of
      118: begin
        s := c_sym_ptr_t(n);
        s^.td_flags := c_flags_t(merge_attribs_natural(
          s^.td_attr, il_$node_ptr_t(s^.td_type)));
      end;
      131: begin
        t := c_type_ptr_t(n);
        ix.dtype := t^.arr_index;
        ix.line := tag.name.line;
        ix.name := tag.name.id;
        el.dtype := t^.arr_elem;
        el.line := tag.name.line;
        el.name := tag.name.id;
        el.flags := t^.arr_attr.bits;
        discard(def_arr(ix, el, c_type_ptr_t(tag.incomplete^.rvar),
                        attr_curr_align_env = 0));
      end;
      109: begin
        s := c_sym_ptr_t(n);
        a.flags := s^.var_attr.bits;
        s^.var_flags := c_flags_t(merge_attribs_natural(a,
                                    il_$node_ptr_t(s^.var_type)));
        attr_tattr_to_vattr(a, s^.var_attr);
      end;
      otherwise
        error0(285, lex_line);
    end;
    tag.incomplete := tag.incomplete^.next;
  end;
end;

{ type_exp - see globals_from_frontend.ins.pas: d's base and node the
  node, its bounds and size the defaults (0, 0, 2), ranged cleared,
  align_ok (+24.1) set; then by kind: names (118), parameters (121), variables
  (109) and fields (119, 120) take their type's and their own size and
  qualifiers (b25_5 const, bit 19; b25_4 volatile, bit 0) and alignment
  (attr_set_align_dsc: a field's never raised); integral (122) and
  enumeration (129) types their bounds; subranges (128) their base's
  size; pointers (130) a longword's bounds; arrays (127, 131) their size
  (fix_array_decl first for one whose element was incomplete);
  structures (132) their size rounded to words; sets (134), 136 and
  void (210) theirs; constants an alignment.  d.bytes is d.size unless
  set before.

  0x04590A, 0x51A bytes, link #-44: the defaults copied from 12 bytes
  after the routine (0x045E3E), the 4-byte integer's bounds from
  0x045E4A (-2147483647, 2147483647, 4), the char's from 0x045E56
  (-128, 127, 1); the last arm's kinds a 26-byte set (docs/dpc-gaps.md
  8).

  Not known from the original:
  - the names; why a 2-byte unsigned type keeps the default size. }

procedure type_exp;
var
  n: c_type_ptr_t;
  e: type_exp_ptr_t;
  old: integer;
  w: integer32;

  { fix_array_decl - complete the array a whose element type was
    incomplete when it was made: its element size (an inner array's
    first), its size from the index's bounds, 127 for a byte element,
    else an even size.

    0x045878, 0x92 bytes, link #-68. }

  procedure fix_array_decl(
      a: c_type_ptr_t); options(val_param);
  var
    el: c_type_ptr_t;
    te, ti: type_exp_t;
  begin
    el := a^.arr_elem;
    if (el^.kind = 131) or (el^.kind = 127) then
      if el^.arr_elsize = 0 then begin
        fix_array_decl(el);
        if el^.arr_elsize = 0 then
          return;
      end;
    type_exp(el, addr(te));
    type_exp(a^.arr_index, addr(ti));
    a^.arr_elsize := te.bytes;
    a^.arr_size := (ti.high - ti.low + 1) * te.bytes;
    if te.size = 1 then
      a^.kind := 127
    else if odd(a^.arr_size) then
      a^.arr_size := a^.arr_size + 1;
  end;

begin
  n := t;
  e := d;
  e^.base := n;
  e^.node := n;
  e^.low := 0;
  e^.high := 0;
  e^.size := 2;
  e^.flags.ranged := false;
  e^.flags.align_ok := true;
  case n^.kind of
    118: begin
      type_exp(c_sym_ptr_t(n)^.td_type, e);
      e^.node := n;
      with c_dattr_ptr_t(addr(c_sym_ptr_t(n)^.td_attr))^ do begin
        e^.bytes := (size_bits + 7) div 8;
        e^.flags.b25_5 := 19 in flags;
        e^.flags.b25_4 := 0 in flags;
      end;
      return;
    end;
    121: begin
      type_exp(c_parm_ptr_t(n)^.ptype, e);
      with c_parm_ptr_t(n)^.attr do begin
        e^.bytes := (size_bits + 7) div 8;
        e^.flags.b25_5 := 19 in flags;
        e^.flags.b25_4 := 0 in flags;
      end;
      attr_set_align_dsc(il_$node_ptr_t(n), e);
      return;
    end;
    109: begin
      type_exp(c_sym_ptr_t(n)^.var_type, e);
      with c_sym_ptr_t(n)^ do begin
        w := (var_attr.size_bits + 7) div 8;
        e^.bytes := w;
        if (e^.size = 0) or (14 in var_flags) then
          e^.size := w;
        e^.flags.b25_5 := 19 in var_attr.bits;
        e^.flags.b25_4 := 0 in var_attr.bits;
      end;
      attr_set_align_dsc(il_$node_ptr_t(n), e);
      return;
    end;
    119: begin
      type_exp(c_field_ptr_t(n)^.ftype, e);
      with c_field_ptr_t(n)^ do begin
        e^.bytes := (attr.size_bits + 7) div 8;
        e^.flags.b25_5 := 19 in attr.bits;
        e^.flags.b25_4 := 0 in attr.bits;
      end;
      old := e^.flags.align;
      attr_set_align_dsc(il_$node_ptr_t(n), e);
      if e^.flags.align > old then begin
        e^.flags.align := old;
        e^.flags.align_ok := false;
      end;
      if e^.bytes < e^.size then
        e^.size := e^.bytes;
      return;
    end;
    120: begin
      type_exp(c_field_ptr_t(n)^.ftype, e);
      with c_field_ptr_t(n)^ do begin
        if bits.width + bits.at > 16 then
          e^.size := 4
        else
          e^.size := 2;
        old := e^.flags.align;
        e^.flags.b25_5 := 19 in attr.bits;
        e^.flags.b25_4 := 0 in attr.bits;
      end;
      attr_set_align_dsc(il_$node_ptr_t(n), e);
      if e^.flags.align > old then begin
        e^.flags.align := old;
        e^.flags.align_ok := false;
      end;
    end;
    210:
      e^.size := 0;
    122: begin
      if n^.signed then begin
        if n^.len = 1 then begin
          e^.low := -128;
          e^.high := 127;
          e^.size := 1;
        end
        else if n^.len = 2 then begin
          e^.low := -32768;
          e^.high := 32767;
        end
        else begin
          e^.low := -2147483647;
          e^.high := 2147483647;
          e^.size := 4;
        end;
      end
      else if n^.len = 1 then begin
        e^.high := 255;
        e^.size := 1;
      end
      else if n^.len = 2 then
        e^.high := 65535
      else begin
        e^.high := 2147483647;
        e^.size := 4;
      end;
      e^.flags.ranged := true;
    end;
    123:
      if n^.len = 6 then
        e^.size := 4
      else
        e^.size := 8;
    128: begin
      e^.base := n^.sub_base;
      if e^.base <> c_type_ptr_t(il_178) then begin
        e^.low := n^.sub_low^.int_value;
        e^.high := n^.sub_high^.int_value;
        e^.flags.ranged := true;
        if e^.base^.kind = 122 then
          e^.size := e^.base^.len;
      end;
    end;
    129: begin
      with n^.enum_int^ do
        if signed then begin
          if len = 1 then begin
            e^.low := -128;
            e^.high := 127;
            e^.size := 1;
          end
          else if len = 2 then begin
            e^.low := -32768;
            e^.high := 32767;
          end
          else begin
            e^.low := -2147483647;
            e^.high := 2147483647;
            e^.size := 4;
          end;
        end
        else if len = 1 then begin
          e^.high := 255;
          e^.size := 1;
        end
        else if len = 2 then
          e^.high := 65535
        else begin
          e^.high := 2147483647;
          e^.size := 4;
        end;
      e^.flags.ranged := true;
    end;
    130: begin
      e^.low := -2147483647;
      e^.high := 2147483647;
      e^.size := 4;
    end;
    127, 131: begin
      if n^.arr_elsize = 0 then
        fix_array_decl(n);
      e^.size := n^.arr_size;
    end;
    132: begin
      e^.size := ((n^.su_attr.size_bits + 15) div 16) * 2;
      e^.bytes := n^.su_size;
      return;
    end;
    134:
      e^.size := n^.set_size;
    136:
      e^.size := 128;
    otherwise
      if n^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
        attr_set_align_dsc(il_$node_ptr_t(n), e);
  end;
  e^.bytes := e^.size;
end;

{ promote_type - t's type after the default argument promotions: int
  for a 1- or 2-byte integral or enumeration type, double for float,
  else t (diagnostic 298 for nil or a kind not expected).

  0x045E62, 0xC0 bytes, link #-12: the two diagnostics share one call
  (docs/rev889-patterns.md 23).

  Not known from the original:
  - the names. }

function promote_type(
    t: c_type_ptr_t): c_type_ptr_t; options(val_param); internal;
var
  r, u: c_type_ptr_t;
begin
  r := t;
  if t = nil then
    error0(298, lex_line)
  else begin
    u := def_drop_tnames(t);
    case u^.kind of
      122, 129: begin
        if u^.kind = 129 then
          u := u^.enum_int;
        if (u^.len = 1) or (u^.len = 2) then
          r := int_type;
      end;
      123:
        if u^.len = 6 then
          r := double_type;
      130, 132, 127, 131, 73, 210, 108, 234:
        ;
      otherwise
        error0(298, lex_line);
    end;
  end;
  promote_type := r;
end;

{ all_promoted_types - every type of the list (to an ellipsis) is its
  own promotion; false for nil.

  0x045F22, 0x5A bytes, link #-16. }

function all_promoted_types(
    l: c_parlist_ptr_t): boolean; options(val_param); internal;
var
  i: integer;
  t, u: c_type_ptr_t;
begin
  all_promoted_types := false;
  if l <> nil then begin
    for i := 1 to l^.count do begin
      t := def_drop_tnames(l^.types[i]);
      if t^.kind <> 31 then begin
        u := promote_type(t);
        if u <> t then
          return;
      end;
    end;
    all_promoted_types := true;
  end;
end;

{ check_oldef_proto - an old-style definition's cnt parameters (the
  list parms) against the prototype's types: the counts (212, an
  ellipsis allowing more), each promoted type (211 with its number).

  0x045F7C, 0x102 bytes, link #-28: the routine's name at (8,A6) is not
  read (def_blk_skeleton, def_blk_params pass it); the count
  diagnostics share one call.

  Not known from the original:
  - the names; what the first parameter was for. }

function check_oldef_proto(
    name: il_$node_ptr_t;
    l: c_parlist_ptr_t;
    parms: c_parm_ptr_t;
    cnt: integer): boolean; options(val_param); internal;
label
  9;
var
  ok, ell: boolean;
  n, i: integer;
  p: c_parm_ptr_t;
  t: c_type_ptr_t;
begin
  ok := true;
  if l <> nil then begin
    n := l^.count;
    ell := false;
    if l^.types[n]^.kind = 31 then begin
      n := n - 1;
      ell := true;
    end;
    if (cnt = 0) and (l^.types[1]^.kind = 210) then
      goto 9;
    if ((cnt > n) and not ell) or (cnt < n) then begin
      error0(212, lex_line);
      ok := false;
    end
    else begin
      p := parms;
      for i := 1 to cnt do begin
        if l^.types[i]^.kind = 31 then
          exit;
        t := promote_type(p^.ptype);
        if not check_types(t, l^.types[i], false) then begin
          error3(211, lex_line, smcontk(81, i), t, l^.types[i]);
          ok := false;
        end;
        p := p^.next;
      end;
    end;
  end;
9:
  check_oldef_proto := ok;
end;

{ check_protos - two prototypes' types agree: both or neither (a
  missing one matches types that are their own promotions), the same
  count (212), each type (211), to an ellipsis.

  0x04607E, 0xE4 bytes, link #-12: the two calls of
  all_promoted_types share one (docs/rev889-patterns.md 23).

  Not known from the original:
  - the names. }

function check_protos(
    a: c_parlist_ptr_t;
    b: c_parlist_ptr_t): boolean; options(val_param); internal;
var
  ok: boolean;
  i: integer;
begin
  ok := true;
  if (a = nil) or (b = nil) then begin
    if (a <> nil) or (b <> nil) then
      if a = nil then begin
        if not all_promoted_types(b) then
          ok := false;
      end
      else if b = nil then
        if not all_promoted_types(a) then
          ok := false;
  end
  else if a^.count <> b^.count then begin
    error0(212, lex_line);
    ok := false;
  end
  else
    for i := 1 to a^.count do begin
      if a^.types[i]^.kind = 31 then
        exit;
      if not check_types(a^.types[i], b^.types[i], false) then begin
        error3(211, lex_line, smcontk(81, i), a^.types[i], b^.types[i]);
        ok := false;
      end;
    end;
  check_protos := ok;
end;

{ check_types - see c_externs.ins.pas: the same node, or through
  typedefs, pointers (to void, when loose), arrays (of sizes that
  agree or are unknown) and functions or blocks (results and
  prototypes) to the same node; under -XANSI an enumeration matches its
  integral type.

  0x046162, 0x1D2 bytes, link #-20; the pairs of kinds evaluated whole
  (`seq; and.b').

  Not known from the original:
  - the names. }

function check_types;
label
  9;
var
  ok: boolean;
  pa, pb: c_parlist_ptr_t;
begin
  ok := true;
  if a = b then
    goto 9;
  while (b^.kind = 118) or (a^.kind = 118) or
        ((a^.kind = 127) and (b^.kind = 127)) or
        ((a^.kind = 131) and (b^.kind = 131)) or
        ((a^.kind = 130) and (b^.kind = 130)) or
        (((a^.kind = 234) or (a^.kind = 108)) and
         ((b^.kind = 234) or (b^.kind = 108))) do begin
    if a^.kind = 118 then
      a := c_sym_ptr_t(a)^.td_type
    else if b^.kind = 118 then
      b := c_sym_ptr_t(b)^.td_type
    else if a^.kind = 130 then begin
      a := def_drop_tnames(a^.ptr_to);
      b := def_drop_tnames(b^.ptr_to);
      if loose then
        if (a^.kind = 210) or (b^.kind = 210) then
          goto 9;
    end
    else if (a^.kind = 234) or (a^.kind = 108) then begin
      if a^.kind = 234 then begin
        pa := a^.fn_params;
        a := a^.fn_result;
      end
      else begin
        pa := c_blk_ptr_t(a)^.params;
        a := c_blk_ptr_t(a)^.result;
      end;
      if b^.kind = 234 then begin
        pb := b^.fn_params;
        b := b^.fn_result;
      end
      else begin
        pb := c_blk_ptr_t(b)^.params;
        b := c_blk_ptr_t(b)^.result;
      end;
      if not check_protos(pa, pb) then begin
        ok := false;
        goto 9;
      end;
    end
    else begin
      if (a^.arr_size <> b^.arr_size) and (a^.arr_size <> 0) and
         (b^.arr_size <> 0) then begin
        ok := false;
        goto 9;
      end;
      a := a^.arr_elem;
      b := b^.arr_elem;
    end;
  end;
  if a <> b then
    if cargs_$options.xansi then begin
      if not (((a^.kind = 129) and (b^.kind = 122) and
               (a^.enum_int = b)) or
              ((b^.kind = 129) and (a^.kind = 122) and
               (b^.enum_int = a))) then
        ok := false;
    end
    else
      ok := false;
9:
  check_types := ok;
end;

{ has_data_init - v was given an initializer (flag 6).

  0x046334, 0xE bytes, no frame. }

function has_data_init(
    v: c_sym_ptr_t): boolean; options(val_param); internal;
begin
  has_data_init := 6 in v^.var_flags;
end;

{ def_sect - the section (111, 56 bytes, chained from il_118) named
  as name, made when the name is new; an existing one not defined is
  diagnostic 237; a name that is not a section's 152 (il_178).

  0x046342, 0x9C bytes, link #-8. }

procedure def_sect(
    in name: c_name_t;
    var sect: il_$node_ptr_t); internal;
var
  n: il_$node_ptr_t;
begin
  n := check_section_name(name.id);
  if n^.kind = 111 then begin
    sect := n;
    if sect^.xp[3] = nil then
      error1(237, name.line, name.id);
  end
  else if n^.kind = 76 then begin
    sect := gspace(56);
    sect^.kind := 111;
    sect^.xp[1] := name.id;
    sect^.xp[2] := il_118;
    il_118 := sect;
  end
  else begin
    error1(152, name.line, name.id);
    sect := il_178;
  end;
end;

{ def_varn - see c_externs.ins.pas.  The storage class given is first
  adjusted (extdef: a common block section without -BSS or with
  section(...), ext in .bss for an uninitialized one under -BSS;
  an initialized extern in a block is diagnostic 77 unless -XANSI and
  at the outermost level).  An extern, extdef, or a static at the
  outermost level, already declared (in the block, the outermost
  block under -XANSI, or the link table) as a compatible variable of a
  class that allows it, is merged: the larger type, the attributes,
  .bss and section changes (the extern's address constants moved),
  132 for a second initializer; a static redeclaring an extern makes it
  static (redecl_as_static).  Otherwise 258 or 24.  A new variable
  (88 bytes for stat, ext and extdef, else 84) is entered in its block
  (the outermost for an extern without -XANSI; under -XANSI an extern
  in a block also in the link table, with a virtual symbol), counted
  in il_144, given its section, and noted when its type is incomplete.

  0x046742, 0x656 bytes, link #-104: the two jump tables at 0x04694E
  (on vat, 1..7) and 0x046A62 (the merge's change, 1..4); the class
  tests `btst' on the constants 0x408, 0x82, 0x518 and 0x59A, each
  condition evaluated whole.

  Not known from the original:
  - the names; il_144's meaning (a count of external definitions?). }

function def_varn;
label
  8, 9;
var
  nvat: c_vat_t;
  bss: boolean;
  s, v, res: c_sym_ptr_t;
  ov: c_vat_t;
  t1, t2: type_exp_t;
  k: integer;
  blk: c_blk_ptr_t;
  t: c_type_ptr_t;
  holder: c_tag_ptr_t;
  x: il_$node_ptr_t;

  { update_attr - the declaration's attributes into v: its flags
    (replaced, or added to), its size (the variable's kept when none
    is given) and alignment, an address(n) given (flag 18, the offset),
    then attr_validate.

    0x0463DE, 0xA0 bytes, link #-28. }

  procedure update_attr(
      v: c_sym_ptr_t;
      in decl: c_decl_t;
      replace: boolean); options(val_param);
  var
    a: c_dattr_t;
    size: integer32;
  begin
    a := decl.attr;
    if replace then
      v^.var_flags := c_flags_t(merge_attribs(a, decl.dtype))
    else
      v^.var_flags := v^.var_flags +
        c_flags_t(merge_attribs(a, decl.dtype));
    size := a.size_bits;
    if size = 0 then
      size := v^.var_attr.size_bits;
    attr_tattr_to_vattr(a, v^.var_attr);
    v^.var_attr.size_bits := size;
    if 5 in decl.attr.flags then begin
      v^.var_flags := v^.var_flags + [18];
      v^.var_offset := decl.attr.x16;
    end;
    attr_validate(a, il_$node_ptr_t(v));
  end;

  { delete_section - take sect out of il_118's chain.

    0x04647E, 0x4E bytes, link #-8. }

  procedure delete_section(
      sect: il_$node_ptr_t); options(val_param);
  var
    p: il_$node_ptr_t;
  begin
    if sect = il_118 then
      il_118 := il_118^.xp[2]
    else begin
      p := il_118;
      while p <> nil do
        if p^.xp[2] = sect then
          p^.xp[2] := p^.xp[2]^.xp[2]
        else
          p := p^.xp[2];
    end;
  end;

  { redecl_as_static - v, an extern (kind 3, 2) or a section's (kind
    3: its section deleted) or one in .bss (kind 1), becomes static
    as def_varn's vat: allocated when its type has a size, il_130's
    references (a word kind at +20) and the outermost block's data
    section's address constants (163, a byte kind at +20; the blocks
    of the chain stepped through +116) that named it redirected.

    0x0464CC, 0x128 bytes, link #-48: def_varn's frame from the
    dynamic link (`movea.l (A6),A3'); a `btst #18' of v's flags whose
    result is not used (0x046514).

    Not known from the original:
    - the names; the unused test. }

  procedure redecl_as_static(
      kind: integer;
      v: c_sym_ptr_t); options(val_param);
  var
    te: type_exp_t;
    a: il_$node_ptr_t;
    c: integer;
  begin
    if (kind = 3) and (v^.var_vat = vat_sect) then begin
      delete_section(v^.var_sect);
      v^.var_sect := il_178;
    end;
    v^.var_vat := vat;
    type_exp(v^.var_type, addr(te));
    if te.size > 0 then
      def_alloc_var(v, te.bytes);
    a := il_130;
    while a <> nil do begin
      if (a^.xp[3] = il_$node_ptr_t(v)) or
         ((a^.xp[3]^.kind = 111) and (a^.xp[3]^.xp[1] = v^.name)) then begin
        a^.xw[10] := 10;
        a^.xp[3] := il_$node_ptr_t(v);
      end;
      a := a^.xp[1];
    end;
    a := c_blk_ptr_t(cdef_outer_block)^.data_sect^.xp[3];
    while a <> nil do
      if a^.kind <> 163 then
        a := a^.xp[29]
      else begin
        c := ord(a^.xc[20]);
        if c = kind then
          if ((c = 3) and (a^.xp[2]^.xp[1] = v^.name)) or
             ((c <> 3) and (a^.xp[2] = il_$node_ptr_t(v))) then begin
            a^.xl[3] := a^.xl[3] + v^.var_offset;
            if v^.var_vat = vat_stat then
              a^.xc[20] := chr(10)
            else
              a^.xc[20] := chr(1);
            if te.size > 0 then
              a^.xp[2] := c_blk_ptr_t(il_180)^.data_sect;
          end
          else
            a := a^.xp[1]
        else
          a := a^.xp[1];
      end;
  end;

  { ext2sect_addr_cons - v now lives in its section: il_130's
    references (word kind 3) and the address constants of every section
    of il_110 (byte kind 3) that named it name the section.

    0x0465F4, 0x7A bytes, link #-24. }

  procedure ext2sect_addr_cons(
      v: c_sym_ptr_t); options(val_param);
  var
    s, a, sc: il_$node_ptr_t;
  begin
    s := v^.var_sect;
    a := il_130;
    while a <> nil do begin
      if a^.xp[3] = il_$node_ptr_t(v) then begin
        a^.xw[10] := 3;
        a^.xp[3] := s;
      end;
      a := a^.xp[1];
    end;
    sc := il_110;
    while sc <> nil do begin
      a := sc^.xp[3];
      while a <> nil do
        if a^.kind <> 163 then
          a := a^.xp[29]
        else begin
          if a^.xp[2] = il_$node_ptr_t(v) then begin
            a^.xc[20] := chr(3);
            a^.xp[2] := s;
          end;
          a := a^.xp[1];
        end;
      sc := sc^.xp[1];
    end;
  end;

  { make_comblk_sect - v (vat_sect) in its common block section: named
    by section(id) (flag 16 of its attributes) or by its own name;
    appended to the section's variables at the section's size so far.

    0x04666E, 0x8E bytes, link #-52. }

  procedure make_comblk_sect(
      v: c_sym_ptr_t;
      in name: c_name_t;
      id: il_$node_ptr_t); options(val_param);
  var
    te: type_exp_t;
    nm: c_name_t;
    sect: il_$node_ptr_t;
  begin
    type_exp(v, addr(te));
    if 16 in v^.var_attr.bits then begin
      nm.id := id;
      nm.line := v^.line;
      def_sect(nm, sect);
    end
    else
      def_sect(name, sect);
    if sect^.xp[3] <> nil then begin
      c_sym_ptr_t(sect^.xp[4])^.var_sect_next := v;
      sect^.xp[4] := il_$node_ptr_t(v);
    end
    else begin
      sect^.xp[3] := il_$node_ptr_t(v);
      sect^.xp[4] := il_$node_ptr_t(v);
    end;
    v^.var_sect := sect;
    v^.var_offset := sect^.xl[5];
    sect^.xl[5] := sect^.xl[5] + te.bytes;
  end;

  { alloc_bss - v in .bss (flag 16, its offset the bss size il_114 so
    far), unless already there with an offset.

    0x0466FC, 0x46 bytes, link #-32. }

  procedure alloc_bss(
      v: c_sym_ptr_t); options(val_param);
  var
    te: type_exp_t;
  begin
    if not (16 in v^.var_flags) or
       ((16 in v^.var_flags) and (v^.var_offset = 0)) then begin
      type_exp(v, addr(te));
      v^.var_flags := v^.var_flags + [16];
      v^.var_offset := te.bytes;
      il_114 := il_114 + te.bytes;
    end;
  end;

begin
  bss := false;
  if vat = vat_extdef then begin
    if not (11 in cargs_$options.flags_286) or (16 in decl.flags) then
      nvat := vat_sect
    else if not init and (11 in cargs_$options.flags_286) then begin
      nvat := vat_ext;
      bss := true;
    end
    else
      nvat := vat_extdef;
  end
  else if (vat = vat_ext) and init then begin
    if cargs_$options.xansi and
       not ((il_180^.kind = 172) or (il_180^.kind = 108)) then begin
      if 11 in cargs_$options.flags_286 then
        nvat := vat_extdef
      else
        nvat := vat_sect;
    end
    else begin
      error1(77, lex_line, name.id);
      nvat := vat;
    end;
  end
  else
    nvat := vat;

  if ((vat = vat_extdef) or (vat = vat_ext)) or
     ((il_180 = cdef_outer_block) and (vat = vat_stat)) then begin
    if (vat = vat_ext) and cargs_$options.xansi then begin
      s := c_sym_ptr_t(blk_fnd_name(name, true, false,
                                    c_blk_ptr_t(il_180)));
      if s = c_sym_ptr_t(il_178) then
        s := c_sym_ptr_t(blk_fnd_name(name, false, false,
                                      c_blk_ptr_t(cdef_outer_block)));
    end
    else
      s := c_sym_ptr_t(blk_fnd_name(name, false, false,
                                    c_blk_ptr_t(il_180)));
    if s = c_sym_ptr_t(il_178) then
      if lnktbl_first_name <> nil then
        s := c_sym_ptr_t(blk_fnd_name(name, false, false, lnktbl));
    if (s <> c_sym_ptr_t(il_178)) and (s^.kind = 109) then begin
      res := s;
      v := s;
      ov := v^.var_vat;
      if not (((not cargs_$options.xansi and
                (ov in [vat_ext, vat_sect])) or
               (ov in [vat_stat, vat_xstat])) and (vat = vat_stat)) and
         not ((vat = vat_extdef) and
              (ov in [vat_ext, vat_extdef, vat_xextdef, vat_sect])) then
        if not ((vat = vat_ext) and
                (ov in [vat_stat, vat_ext, vat_extdef, vat_xstat,
                        vat_xextdef, vat_sect])) or
           ((ov in [vat_stat, vat_xstat]) and
            (v^.block <> cdef_outer_block)) then
          goto 8;
      if not check_types(v^.var_type, decl.dtype, false) then
        goto 8;
      case vat of
        vat_ext, vat_extdef: begin
          bss := false;
          type_exp(v^.var_type, addr(t1));
          type_exp(decl.dtype, addr(t2));
          if t1.size < t2.size then begin
            v^.var_type := decl.dtype;
            if (v^.var_vat = vat_ext) and (16 in v^.var_flags) then
              bss := true;
          end
          else
            decl.dtype := v^.var_type;
          update_attr(s, decl, false);
          if bss then
            alloc_bss(s);
          if init then
            if has_data_init(s) then
              error2(132, lex_line, s, smcontk(81, s^.line));
          k := 0;
          if v^.var_vat = vat_ext then begin
            if 16 in v^.var_flags then begin
              if init then
                k := 4;
            end
            else if init then begin
              if nvat = vat_sect then
                k := 1
              else if nvat = vat_extdef then
                k := 2;
            end
            else if vat = vat_extdef then
              if nvat = vat_sect then
                k := 1
              else if nvat = vat_ext then
                k := 3;
          end;
          case k of
            1: begin
              il_144 := il_144 + 1;
              v^.var_vat := vat_sect;
              make_comblk_sect(s, name, il_$node_ptr_t(decl.unused_28));
              ext2sect_addr_cons(s);
            end;
            2: begin
              il_144 := il_144 + 1;
              v^.var_vat := vat_extdef;
            end;
            3: begin
              il_144 := il_144 + 1;
              alloc_bss(s);
            end;
            4: begin
              il_114 := il_114 - v^.var_offset;
              v^.var_vat := vat_extdef;
              v^.var_flags := v^.var_flags - [16];
              v^.var_offset := 0;
            end;
            otherwise
              ;
          end;
          if (vat = vat_ext) and (il_180 <> cdef_outer_block) and
             cargs_$options.xansi then begin
            x := blk_fnd_name(name, true, false, c_blk_ptr_t(il_180));
            if x = il_178 then
              def_virt_varn(name, s, c_blk_ptr_t(il_180));
          end;
          if (il_180 = cdef_outer_block) and
             (v^.block = il_$node_ptr_t(lnktbl)) then
            lnktbl_to_modblk(s);
        end;
        vat_stat, vat_xstat:
          if (v^.var_vat = vat_stat) or (v^.var_vat = vat_xstat) then begin
            if init then
              if has_data_init(s) then
                error2(132, lex_line, s, smcontk(81, s^.line));
          end
          else if cargs_$options.xansi then
            goto 8
          else if not has_data_init(s) then begin
            v^.var_type := decl.dtype;
            update_attr(s, decl, false);
            case v^.var_vat of
              vat_sect:
                redecl_as_static(3, s);
              vat_ext:
                redecl_as_static(2, s);
              vat_xextdef:
                redecl_as_static(1, s);
              otherwise
                ;
            end;
          end;
        otherwise
          goto 8;
      end;
      goto 9;
8:
      if cargs_$options.usrch then
        error1(258, name.line, name.id)
      else
        error2(24, name.line, name.id, smcontk(81, s^.line));
      goto 9;
    end;
  end;

  if (vat = vat_stat) or (vat = vat_extdef) or (vat = vat_ext) then begin
    v := gspace(88);
    v^.var_sect := il_178;
  end
  else
    v := gspace(84);
  v^.kind := 109;
  v^.var_type := decl.dtype;
  update_attr(v, decl, true);
  v^.var_vat := nvat;
  v^.var_78 := -1;
  if bss then
    alloc_bss(v);
  if not cargs_$options.xansi and ((vat = vat_extdef) or (vat = vat_ext)) then
    blk := c_blk_ptr_t(cdef_outer_block)
  else
    blk := c_blk_ptr_t(il_180);
  if (vat = vat_ext) and (il_180 <> cdef_outer_block) and
     cargs_$options.xansi then begin
    lnktbl_def_name(name, v);
    def_virt_varn(name, v, blk);
  end
  else
    def_name(name, v, blk);
  if (vat = vat_extdef) or (init and (vat = vat_ext)) then
    il_144 := il_144 + 1;
  if nvat = vat_sect then
    make_comblk_sect(v, name, il_$node_ptr_t(decl.unused_28));
  t := v^.var_type;
  if t^.kind = 121 then
    t := c_parm_ptr_t(t)^.ptype;
  if def_incomplete_su(t, holder) then
    add_incomplete_type(il_$node_ptr_t(v), holder);
  res := v;
9:
  def_varn := res;
end;

{ add_varn - see c_externs.ins.pas: 88 bytes (var_sect il_178) for stat,
  extdef and ext, else 84; the attributes merged and converted, +78 -1.

  0x046D98, 0xC8 bytes, link #-36. }

function add_varn;
var
  v: c_sym_ptr_t;
  a: c_dattr_t;
begin
  if (vat = vat_stat) or (vat = vat_extdef) or (vat = vat_ext) then begin
    v := gspace(88);
    v^.var_sect := il_178;
  end
  else
    v := gspace(84);
  v^.kind := 109;
  v^.var_type := decl.dtype;
  v^.var_vat := vat;
  a := decl.attr;
  v^.var_flags := c_flags_t(merge_attribs(a, decl.dtype));
  attr_tattr_to_vattr(a, v^.var_attr);
  v^.var_78 := -1;
  v^.name := name;
  v^.blk_next := il_180^.xp[4];
  v^.block := il_180;
  c_blk_ptr_t(il_180)^.syms := il_$node_ptr_t(v);
  add_varn := v;
end;

{ add_reg_var - see c_externs.ins.pas: a kind 160 entry (12 bytes)
  appended to il_180's reg_vars.

  0x046E60, 0x64 bytes, link #-8. }

procedure add_reg_var;
var
  e, p: c_reglist_ptr_t;
begin
  if v <> c_sym_ptr_t(il_178) then begin
    e := gspace(12);
    e^.kind := 160;
    e^.rvar := il_$node_ptr_t(v);
    if c_blk_ptr_t(il_180)^.reg_vars = nil then
      c_blk_ptr_t(il_180)^.reg_vars := e
    else begin
      p := c_blk_ptr_t(il_180)^.reg_vars;
      while p^.next <> nil do
        p := p^.next;
      p^.next := e;
    end;
  end;
end;

{ add_parm - see c_externs.ins.pas: a parameter node (121, 56 bytes):
  the name pair, the type, decl's flags, w44 and b46.  A name met again
  is diagnostic 36: the new parameter's name and the earlier one's
  type become il_178, and the search goes on with il_178.

  0x046EC4, 0xB8 bytes, link #-16; il_178's address loaded into D3 and
  not used.

  Not known from the original:
  - the names; why the earlier parameter's type is cleared. }

procedure add_parm;
var
  p, q: c_parm_ptr_t;
  id: il_$node_ptr_t;
begin
  p := gspace(56);
  p^.kind := 121;
  p^.pname := name;
  p^.ptype := decl.dtype;
  p^.w44 := w44;
  p^.attr.flags := decl.flags;
  p^.b46 := b46;
  if list = nil then
    list := p
  else begin
    q := list;
    id := name.id;
    repeat
      if id = q^.pname.id then begin
        error1(36, name.line, id);
        p^.pname.id := il_178;
        id := il_178;
        q^.ptype := c_type_ptr_t(il_178);
      end;
      if q^.next = nil then begin
        q^.next := p;
        q := nil;
      end
      else
        q := q^.next;
    until q = nil;
  end;
end;

{ lookup_su - see c_externs.ins.pas: a tag found in an enclosing block
  gets its uplevel byte.

  0x046F7C, 0x60 bytes, link #-12: the result in D0, moved to A0. }

function lookup_su;
var
  b: c_blk_ptr_t;
  t: c_tag_ptr_t;
begin
  lookup_su := nil;
  b := c_blk_ptr_t(il_180);
  while b <> nil do begin
    t := b^.tags;
    while t <> nil do begin
      if t^.body.name.id = id then begin
        if b <> c_blk_ptr_t(il_180) then
          t^.body.name.uplevel := true;
        lookup_su := t;
        return;
      end;
      t := t^.body.next;
    end;
    b := b^.outer;
  end;
end;

{ add_su - see c_externs.ins.pas.

  0x046FDC, 0x36 bytes, link #-4. }

procedure add_su;
var
  p: c_tag_ptr_t;
begin
  if list = nil then
    list := t
  else begin
    p := list;
    while p^.body.next <> nil do
      p := p^.body.next;
    p^.body.next := t;
  end;
end;

{ def_su - see c_externs.ins.pas: the type il_178, the block il_180.

  0x047012, 0x52 bytes, link #-12; the result left in A0 from gspace
  (docs/rev889-patterns.md 32). }

function def_su;
var
  t: c_tag_ptr_t;
begin
  t := gspace(28);
  t^.kind := kind;
  t^.body.name := name;
  t^.body.stype := c_type_ptr_t(il_178);
  t^.body.block := c_blk_ptr_t(il_180);
  def_su := t;
end;

{ create_and_link_data_rec - add the constant con at offset of v to
  the initializer list first..last: a piece of its own (113), or, when
  it follows the last piece's bytes with the same constant, a run (114)
  of two made from the last piece, or a run lengthened.

  0x047064, 0x116 bytes, link #-24.

  Not known from the original:
  - the names. }

procedure create_and_link_data_rec(
    v: c_sym_ptr_t;
    offset: integer32;
    con: il_$node_ptr_t;
    var first: il_$node_ptr_t;
    var last: il_$node_ptr_t); options(val_param); internal;
var
  r, l: drec_ptr_t;
  x: drep_ptr_t;
begin
  if first = nil then begin
    r := gspace(24);
    r^.kind := 113;
    r^.dsym := v;
    r^.offset := offset;
    r^.value := con;
    r^.size := get_constant_size(con);
    first := il_$node_ptr_t(r);
    last := il_$node_ptr_t(r);
    return;
  end;
  l := drec_ptr_t(last);
  if l^.dsym = v then begin
    if (l^.value = con) and (l^.offset + l^.size = offset) then begin
      x := gspace(16);
      x^.kind := 114;
      x^.con := con;
      x^.count := 2;
      drec_ptr_t(last)^.value := il_$node_ptr_t(x);
      drec_ptr_t(last)^.size := drec_ptr_t(last)^.size +
                                drec_ptr_t(last)^.size;
      return;
    end;
    x := drep_ptr_t(l^.value);
    if (x^.kind = 114) and (x^.con = con) and
       (l^.offset + l^.size = offset) then begin
      x^.count := x^.count + 1;
      l^.size := l^.size + get_constant_size(con);
      return;
    end;
  end;
  r := gspace(24);
  r^.kind := 113;
  r^.dsym := v;
  r^.offset := offset;
  r^.value := con;
  r^.size := get_constant_size(con);
  drec_ptr_t(last)^.next := r;
  last := il_$node_ptr_t(r);
end;

{ def_data - see c_externs.ins.pas: a section's variable's to the
  section's list (+36, +40), else to il_180's data section's (+28,
  +32).

  0x04717A, 0x54 bytes, link #-4. }

procedure def_data;
var
  ds: il_$node_ptr_t;
begin
  if v^.var_vat = vat_sect then
    create_and_link_data_rec(v, offset, con, v^.var_sect^.xp[9],
                             v^.var_sect^.xp[10])
  else begin
    ds := c_blk_ptr_t(il_180)^.data_sect;
    create_and_link_data_rec(v, offset, con, ds^.xp[7], ds^.xp[8]);
  end;
end;

{ def_dynm_data - see c_externs.ins.pas: a 68-byte record holding the
  entry (62 bytes copied) appended to cdef_dynm_inits.

  0x0471CE, 0x62 bytes, link #-4. }

procedure def_dynm_data;
var
  d: c_dynm_ptr_t;
begin
  d := gspace(68);
  d^.e := cexs_stack[cexs_23bc];
  if cdef_dynm_inits = nil then
    cdef_dynm_inits := d
  else
    dynm_last^.next := d;
  dynm_last := d;
end;

{ def_typn - see c_externs.ins.pas: a typedef symbol (118, 60 bytes):
  the type, the attributes (copied whole to +40) and their flags,
  noted when the type is incomplete, entered in il_180.

  0x047230, 0x96 bytes, link #-8. }

procedure def_typn;
var
  s: c_sym_ptr_t;
  holder: c_tag_ptr_t;
begin
  s := gspace(60);
  s^.kind := 118;
  s^.td_type := decl.dtype;
  c_dattr_ptr_t(addr(s^.td_attr))^ := decl.attr;
  s^.td_flags := c_flags_t(merge_attribs_natural(s^.td_attr,
                                                 decl.dtype));
  attr_validate(s^.td_attr, il_$node_ptr_t(s));
  if def_incomplete_su(decl.dtype, holder) then
    add_incomplete_type(il_$node_ptr_t(s), holder);
  def_name(name, s, c_blk_ptr_t(il_180));
end;

{ def_conn - see c_externs.ins.pas: a constant symbol (116, 40 bytes).

  0x0472C6, 0x54 bytes, link #-12. }

function def_conn;
var
  s: c_sym_ptr_t;
begin
  s := gspace(40);
  s^.kind := 116;
  s^.con_type := ctype;
  s^.con_value := value;
  def_name(name, s, c_blk_ptr_t(il_180));
  def_conn := s;
end;

{ def_enum_skeleton - see c_externs.ins.pas (129, 60 bytes).

  0x04731A, 0x34 bytes, link #-8; the result left in A0 from gspace. }

function def_enum_skeleton;
var
  t: c_type_ptr_t;
begin
  t := gspace(60);
  t^.kind := 129;
  t^.enum_int := int_t;
  def_enum_skeleton := t;
end;

{ def_enum_list - see c_externs.ins.pas: the constants copied to a list
  of their own; the extremes of their values, a negative value of an
  unsigned constant kind (83..86) counted as 0 in the signed ones and
  as itself in the unsigned, others the reverse; a type of 1 or 2 bytes
  (or 4) widened to the unsigned type when no value is negative and the
  largest passes the signed type, the constant kind of the result
  (87, 86, 80, 83, 82, 85) then checked against each value (28).

  0x04734E, 0x264 bytes, link #-20: the extremes' starting values
  copied from 16 bytes after the routine (0x0475B2); the unsigned
  comparisons `bls', `bhi', `bcs'.

  Not known from the original:
  - the names; why 200 is among the labels. }

procedure def_enum_list;
var
  arr: ^c_enum_list_t;
  i: integer;
  k: integer;
  c: il_$node_ptr_t;
  sv, uv, m: integer32;
  s: c_sym_ptr_t;
begin
  if list.count <> 0 then begin
    t^.enum_high := -2147483647 - 1;
    t^.enum_low := 2147483647;
    t^.enum_uhigh := 0;
    t^.enum_ulow := -1;
    arr := gspace(list.count * 4);
    for i := 1 to list.count do begin
      arr^[i] := il_$node_ptr_t(list.syms[i]);
      c := list.syms[i]^.con_value;
      sv := c^.int_value;
      uv := sv;
      if sv < 0 then
        if (c^.kind = 83) or (c^.kind = 84) or (c^.kind = 86) or
           (c^.kind = 85) then
          sv := 0
        else
          uv := 0;
      m := sv;
      if m > t^.enum_low then
        m := t^.enum_low;
      t^.enum_low := m;
      if sv < t^.enum_high then
        sv := t^.enum_high;
      t^.enum_high := sv;
      { TODO(pascal) the unsigned extremes: the image compares them
        unsigned (`bls', `bhi'); written signed here. }
      m := uv;
      if m > t^.enum_ulow then
        m := t^.enum_ulow;
      t^.enum_ulow := m;
      if uv < t^.enum_uhigh then
        uv := t^.enum_uhigh;
      t^.enum_uhigh := uv;
    end;
    case t^.enum_int^.len of
      1:
        if (t^.enum_low >= 0) and (t^.enum_uhigh > 127) then begin
          t^.enum_int := uchar_type;
          k := 86;
        end
        else
          k := 87;
      2:
        if (t^.enum_low >= 0) and (t^.enum_uhigh > 32767) then begin
          t^.enum_int := ushort_type;
          k := 83;
        end
        else
          k := 80;
      otherwise
        if (t^.enum_low >= 0) and (t^.enum_uhigh < 0) then begin
          t^.enum_int := uint_type;
          k := 85;
        end
        else
          k := 82;
    end;
    for i := 1 to list.count do begin
      s := list.syms[i];
      c := s^.con_value;
      sv := c^.int_value;
      case k of
        87, 200:
          if (sv < -128) or (sv > 127) then
            error1(28, s^.line, c);
        86:
          if (sv < 0) or (sv > 255) then
            error1(28, s^.line, c);
        80:
          if (sv < -32768) or (sv > 32767) then
            error1(28, s^.line, c);
        83:
          if (sv < 0) or (sv > 65535) then
            error1(28, s^.line, c);
        82:
          if ((c^.kind = 83) or (c^.kind = 84) or (c^.kind = 86) or
              (c^.kind = 85)) and (sv < 0) then
            error1(28, s^.line, c);
        85:
          if not ((c^.kind = 86) or (c^.kind = 85) or (c^.kind = 84) or
                  (c^.kind = 83)) and (sv < 0) then
            error1(28, s^.line, c);
        otherwise
          ;
      end;
    end;
    t^.enum_count := list.count;
    t^.enum_list := arr;
  end;
end;

{ def_subr - see c_externs.ins.pas (16 bytes).

  0x0475C2, 0x52 bytes, link #-8. }

procedure def_subr;
var
  t: c_type_ptr_t;
begin
  t := gspace(16);
  t^.kind := 128;
  t^.sub_base := low.ctype;
  t^.sub_low := low.value;
  t^.sub_high := high.value;
  d.dtype := t;
end;

{ def_ptr - see c_externs.ins.pas (36 bytes): the target's attributes
  merged (merge_attribs' result not used) and converted; a size given
  that is not the target's is diagnostic 262.

  0x047614, 0xC8 bytes, link #-64: only the attributes' first longword
  cleared.

  Not known from the original:
  - the names. }

function def_ptr;
var
  p: c_type_ptr_t;
  a: c_dattr_t;
  te: type_exp_t;
  n: integer32;
begin
  if into <> nil then
    p := into
  else
    p := gspace(36);
  p^.kind := 130;
  p^.ptr_to := target;
  a.flags := [];
  discard(merge_attribs(a, il_$node_ptr_t(target)));
  attr_tattr_to_vattr(a, p^.ptr_attr);
  attr_validate(a, il_$node_ptr_t(p));
  type_exp(target, addr(te));
  n := a.size_bits div 8;
  if n <> te.bytes then
    error2(262, lex_line, smcontk(81, n), smcontk(81, te.size));
  def_ptr := p;
end;

{ def_fwd_ptr - see c_externs.ins.pas: to d's tag (+8) when set, else
  to d's type; its line; chained first in cdef_fwd_ptrs.

  0x0476DC, 0x5C bytes, link #-12. }

function def_fwd_ptr;
var
  p: c_type_ptr_t;
begin
  p := gspace(36);
  p^.kind := 130;
  if d.tag <> nil then
    p^.ptr_to := c_type_ptr_t(d.tag)
  else
    p^.ptr_to := d.dtype;
  p^.ptr_fwd_next := cdef_fwd_ptrs;
  p^.ptr_line := d.line;
  cdef_fwd_ptrs := p;
  def_fwd_ptr := p;
end;

{ def_resolve_fwd_ptrs - see c_externs.ins.pas: a pointer whose target
  is an identifier takes its tag's type; one that is now a complete
  structure gets its attributes and leaves the chain.

  0x047738, 0xD4 bytes, link #-60: a name pair formed (-32, -28) and
  not used.

  Not known from the original:
  - the names; the pair. }

procedure def_resolve_fwd_ptrs;
var
  prev, p, next, tgt, u: c_type_ptr_t;
  nm: c_name_t;
  s: c_tag_ptr_t;
  a: c_dattr_t;
  ok: boolean;
begin
  prev := nil;
  p := cdef_fwd_ptrs;
  while p <> nil do begin
    next := p^.ptr_fwd_next;
    tgt := p^.ptr_to;
    if tgt^.kind = 76 then begin
      nm.id := il_$node_ptr_t(tgt);
      nm.line := p^.ptr_line;
      s := lookup_su(il_$node_ptr_t(tgt));
      if s <> nil then
        tgt := s^.body.stype;
    end;
    u := def_drop_tnames(tgt);
    ok := false;
    if u <> nil then
      if u^.kind = 132 then
        ok := (u^.su_fields <> nil) and
              (u^.su_fields <> c_field_ptr_t(il_178));
    if ok then begin
      p^.ptr_to := tgt;
      a.flags := [];
      discard(merge_attribs(a, il_$node_ptr_t(p^.ptr_to)));
      attr_tattr_to_vattr(a, p^.ptr_attr);
      attr_validate(a, il_$node_ptr_t(p));
      if prev <> nil then
        prev^.ptr_fwd_next := next
      else
        cdef_fwd_ptrs := next;
    end
    else
      prev := p;
    p := next;
  end;
end;

{ def_final_res_fwd_ptrs - see c_externs.ins.pas.

  0x04780C, 0xA8 bytes, link #-44: the name pair (-32, -28) formed and
  its identifier passed. }

procedure def_final_res_fwd_ptrs;
var
  p, st: c_type_ptr_t;
  nm: c_name_t;
  s: c_tag_ptr_t;
  a: c_dattr_t;
  ok: boolean;
begin
  p := cdef_fwd_ptrs;
  while p <> nil do begin
    nm.id := il_$node_ptr_t(p^.ptr_to);
    nm.line := p^.ptr_line;
    s := lookup_su(nm.id);
    ok := false;
    if s <> nil then begin
      st := s^.body.stype;
      if (st <> c_type_ptr_t(il_178)) and (st <> nil) then
        ok := st^.kind = 132;
    end;
    if ok then
      p^.ptr_to := st
    else
      p^.ptr_to := void_type;
    a.flags := [];
    discard(merge_attribs(a, il_$node_ptr_t(p^.ptr_to)));
    attr_tattr_to_vattr(a, p^.ptr_attr);
    attr_validate(a, il_$node_ptr_t(p));
    p := p^.ptr_fwd_next;
  end;
  cdef_fwd_ptrs := nil;
end;

{ def_func - see c_externs.ins.pas (26 bytes): a float result of a
  function without a prototype, unless conv is 4, is double.

  0x0478B4, 0xA2 bytes, link #-16.

  Not known from the original:
  - the names; what x4, x16 and x20 are. }

function def_func;
var
  f, r: c_type_ptr_t;
begin
  if into <> nil then
    f := into
  else
    f := gspace(26);
  f^.kind := 234;
  f^.fn_result := d.dtype;
  f^.fn_conv := conv;
  f^.fn_unused_4 := x4;
  f^.fn_params := params;
  f^.fn_unused_16 := x16;
  f^.fn_unused_20 := x20;
  r := def_drop_tnames(f^.fn_result);
  if (f^.fn_conv <> 4) and (f^.fn_params = nil) and (r^.kind = 123) and
     (r^.len = 6) then
    f^.fn_result := double_type;
  def_func := f;
end;

{ def_fld - see c_externs.ins.pas.  A bit width must be an integer
  constant (66), not negative (160), at most 32 (238), 0 only unnamed
  (84); a bit field of a type without bounds is 91, a field of no size
  113.  The field's offset: 0 in a union; a bit field packed after the
  last unless it would pass 32 bits (then from the next byte, aligned to
  a word: straddle) or is 0 wide; another field aligned by the
  environment (natural: its alignment; word: bytes and byte arrays
  unaligned, else words), unless an alignment was given.  An
  enumeration bit field must hold the values (317); a signed one is
  `signed' or of a signed integral type (-XANSI: others 91).  The
  alignment met is checked under -ALNCHK (234; 235 for a straddling bit
  field).  A bit field of 8, 16 or 32 bits on a boundary becomes an
  ordinary field of char, short or int.  The structure's flags,
  alignments, has_bf, has_arr and size (a union's the largest) are
  updated; the field node (119, 120 a bit field; 52 bytes) appended
  (53 for a name met again: the earlier field's type becomes
  il_178).

  0x047956, 0x66C bytes, link #-136; the width's kinds a 26-byte set
  after the routine (0x047FC2: 80..86, 200; docs/dpc-gaps.md 8); id_at's
  and il_178's addresses loaded into D3, D2 before the last loop.
  The bit field's +48 low 6 bits get the bit offset and +49 the width
  (c_field_t names them width and at the other way round).

  Not known from the original:
  - the names; why the earlier field's type is cleared. }

procedure def_fld;
var
  ftype: c_type_ptr_t;
  a: c_dattr_t;
  isbf, straddle, neg: boolean;
  te: type_exp_t;
  fflags: c_flags_t;
  w: il_$node_ptr_t;
  al, fal, nbit: integer;
  off, x, nsz: integer32;
  bitoff: integer;
  f, p: c_field_ptr_t;
  id: il_$node_ptr_t;
  tmp: integer32;
begin
  ftype := decl.dtype;
  a := decl.attr;
  isbf := false;
  straddle := false;
  type_exp(ftype, addr(te));
  fflags := c_flags_t(merge_attribs_natural(a, decl.dtype));
  w := width.value;
  al := a.w10;
  if (w <> nil) and (w <> il_178) then
    if not (w^.kind in [80..86, 200]) then
      error1(66, width.line, width.sym)
    else if w^.int_value < 0 then
      error1(160, width.line, w)
    else if w^.int_value > 32 then
      error1(238, width.line, width.sym)
    else if (w^.int_value = 0) and (name.id <> id_at) then
      error1(84, name.line, name.id)
    else begin
      isbf := true;
      a.size_bits := w^.int_value;
    end;
  if isbf and not te.flags.ranged then begin
    isbf := false;
    error1(91, name.line, name.id);
  end;
  if te.size = 0 then
    error1(113, name.line, name.id);
  if kind = 16 then begin
    off := 0;
    bitoff := 0;
  end
  else begin
    if not (12 in a.flags) then
      if isbf then begin
        if st.bitoff + a.size_bits > 32 then begin
          al := 1;
          straddle := true;
        end
        else if a.size_bits = 0 then
          al := 1
        else
          al := -1;
      end
      else if attr_curr_align_env = 1 then begin
        al := a.align;
        if al < a.x12 then
          al := a.x12;
        a.align := al;
      end
      else begin
        if (te.size = 1) or (te.base^.kind = 127) then
          al := 0
        else
          al := 1;
        if al < a.x12 then
          al := a.x12;
      end;
    if al = -1 then begin
      off := st.size;
      bitoff := st.bitoff;
    end
    else begin
      tmp := (st.bitoff + 7) div 8 + st.size;
      calc_align(tmp, al, 0);
      off := tmp;
      bitoff := 0;
    end;
  end;
  if isbf then begin
    if te.base^.kind = 129 then begin
      neg := te.base^.enum_low < 0;
      if w^.int_value < 32 then
        if neg then begin
          if (lshft(-1, w^.int_value - 1) > te.base^.enum_low) or
             (lshft(1, w^.int_value - 1) <= te.base^.enum_high) then
            error0(317, name.line);
        end
        else if lshft(1, w^.int_value) <= te.base^.enum_uhigh then
          error0(317, name.line);
    end
    else if 20 in a.flags then
      neg := true
    else if cargs_$options.xansi then begin
      if te.base^.kind = 122 then
        neg := false
      else begin
        error1(91, name.line, name.id);
        isbf := false;
      end;
    end
    else
      neg := false;
    if bitoff + a.size_bits <= 16 then
      a.align := 1
    else
      a.align := 2;
  end;
  if off = 0 then
    fal := a.align
  else if odd(off) then
    fal := 0
  else begin
    fal := 0;
    x := off;
    while not odd(x) do begin
      x := x div 2;
      fal := fal + 1;
    end;
    if fal > a.align then
      fal := a.align;
  end;
  if (6 in cargs_$options.cpu) <> cargs_$options.alnchk then
    if not isbf then begin
      if (fal < a.align) and not (12 in a.flags) then
        error3(234, name.line, name.id, smcontk(81, fal),
               smcontk(81, a.align));
    end
    else if straddle and (fal < 2) then
      error1(235, lex_line, name.id);
  if isbf then
    if (((bitoff = 0) and ((w^.int_value = 16) or (w^.int_value = 8))) or
        ((w^.int_value = 32) and not odd(off)) or
        ((bitoff = 8) and (w^.int_value = 8))) and
       (te.base^.kind = 122) then begin
      isbf := false;
      if w^.int_value = 8 then begin
        if neg then
          ftype := char_type
        else
          ftype := uchar_type;
        if bitoff = 8 then
          off := off + 1;
      end
      else if w^.int_value = 16 then
        if neg then
          ftype := short_type
        else
          ftype := ushort_type
      else if neg then
        ftype := int_type
      else
        ftype := uint_type;
      fflags := c_flags_t(merge_attribs_natural(a, il_$node_ptr_t(ftype)));
    end;
  st.attr.flags := st.attr.flags + (a.flags * [3, 4]);
  if st.attr.x12 < a.x12 then
    st.attr.x12 := a.x12;
  if not (12 in a.flags) then
    a.w10 := fal;
  if st.attr.w10 < a.w10 then
    st.attr.w10 := a.w10;
  if st.attr.align < a.w10 then
    st.attr.align := a.w10;
  if not st.has_bf then
    st.has_bf := isbf;
  if (ftype^.kind = 131) or (ftype^.kind = 127) then
    st.has_arr := true;
  f := gspace(52);
  f^.name := name.id;
  f^.line := name.line;
  f^.ftype := ftype;
  f^.offset := off;
  f^.flags := fflags;
  f^.attr.size_bits := a.size_bits;
  f^.attr.align := a.w10;
  f^.attr.unused_10 := a.w10;
  f^.attr.unused_12 := a.x12;
  f^.attr.bits := a.flags;
  if isbf then begin
    f^.kind := 120;
    f^.bits.width := bitoff;
    f^.bits.at := a.size_bits;
    f^.bits.signed := neg;
  end
  else
    f^.kind := 119;
  if odd(off) then begin
    off := off - 1;
    bitoff := 8;
  end;
  nsz := off + ((bitoff + a.size_bits) div 16) * 2;
  nbit := (bitoff + a.size_bits) mod 16;
  if kind = 16 then begin
    if (nsz > st.size) or ((nsz = st.size) and (nbit > st.bitoff)) then begin
      st.size := nsz;
      st.bitoff := nbit;
    end;
  end
  else begin
    st.size := nsz;
    st.bitoff := nbit;
  end;
  attr_validate(a, il_$node_ptr_t(f));
  if st.first = nil then
    st.first := f
  else begin
    p := st.first;
    id := name.id;
    repeat
      if (name.id <> id_at) and (p^.name = id) then begin
        error1(53, name.line, id);
        id := il_178;
        p^.ftype := c_type_ptr_t(il_178);
      end;
      if p^.next = nil then begin
        p^.next := f;
        p := nil;
      end
      else
        p := p^.next;
    until p = nil;
  end;
end;

{ def_rec - see c_externs.ins.pas (56 bytes): the fields, the tag, the
  size (2 more for bits past it) rounded to the alignment (natural: the
  greater of x12 and align), the attributes, the size in bits, has_arr.

  0x047FDC, 0xC8 bytes, link #-20. }

function def_rec;
var
  t: c_type_ptr_t;
  al: integer;
  m, b: integer32;
begin
  if into <> nil then
    t := into
  else
    t := gspace(56);
  t^.kind := 132;
  t^.su_fields := st.first;
  t^.su_tag := st.tag;
  t^.su_size := st.size;
  if st.bitoff <> 0 then
    t^.su_size := t^.su_size + 2;
  if attr_curr_align_env = 1 then begin
    al := st.attr.x12;
    if al < st.attr.align then
      al := st.attr.align;
  end
  else
    al := st.attr.x12;
  if al > 0 then begin
    b := lshft(1, al);
    m := b - 1;
    if (t^.su_size & m) <> 0 then
      t^.su_size := (t^.su_size & ~m) + b;
  end;
  attr_tattr_to_vattr(st.attr, t^.su_attr);
  t^.su_attr.size_bits := st.size * 8 + st.bitoff;
  t^.su_has_arr := st.has_arr;
  def_rec := t;
end;

{ def_arr - see c_externs.ins.pas (44 bytes).  The element's alignment
  (w10) from the attributes (word environment: at least 1, at most
  what was met; else the greater of align and x12), a size given that
  is not a multiple of the alignment rounded (241: to 8 bits, or to
  words when larger and not a byte array), the alignment met from the
  element's size; the bound from the index type (54 for one without
  bounds); 127 for byte elements, else an even size; 240 and 239 for
  sizes that defeat the alignment; 261 for a typedef element whose size
  was changed.

  0x0480A4, 0x454 bytes, link #-116: merge_attribs_natural's result not
  used; `mod' of the sizes by M$OIS$LLL.

  Not known from the original:
  - the names. }

function def_arr;
label
  1;
var
  te, ti: type_exp_t;
  a: c_dattr_t;
  al2, x, n: integer;
  m, r, sz, old, y: integer32;
  arr: c_type_ptr_t;
  holder: c_tag_ptr_t;
begin
  type_exp(elem.dtype, addr(te));
  a := elem.attr;
  discard(merge_attribs_natural(a, elem.dtype));
  al2 := a.w10;
  if not (12 in a.flags) then
    if word_env then begin
      x := 1;
      if x < a.x12 then
        x := a.x12;
      if x > al2 then
        x := al2;
      a.w10 := x;
      if (6 in cargs_$options.cpu) = cargs_$options.alnchk then
        al2 := x;
    end
    else begin
      x := a.align;
      if x < a.x12 then
        x := a.x12;
      a.w10 := x;
    end;
  m := lshft(8, a.w10);
  if a.w10 >= 0 then begin
    r := a.size_bits mod m;
    if r <> 0 then begin
      sz := (m - r + a.size_bits) div 8;
      if a.size_bits < 8 then begin
        error2(241, lex_line, smcontk(81, a.size_bits), smcontk(81, 8));
        a.size_bits := 8;
      end
      else if (a.size_bits > 8) and ((a.size_bits & 15) <> 0) then begin
        old := a.size_bits;
        a.size_bits := ((a.size_bits + 15) div 16) * 16;
        error2(241, lex_line, smcontk(81, old), smcontk(81, a.size_bits));
      end;
      goto 1;
    end;
  end;
  if ((a.size_bits > 8) and ((a.size_bits & 15) <> 0)) and
     not ((te.base^.kind = 197) or (te.base^.kind = 131) or
          (te.base^.kind = 127)) then begin
    old := a.size_bits;
    sz := ((a.size_bits + 15) div 16) * 2;
    a.size_bits := sz * 8;
    error2(241, lex_line, smcontk(81, old), smcontk(81, a.size_bits));
  end
  else
    sz := a.size_bits div 8;
1:
  if not (12 in a.flags) and (sz <> 0) then begin
    y := sz;
    n := 0;
    while not odd(y) do begin
      y := y div 2;
      n := n + 1;
    end;
    if n > a.align then
      n := a.align;
    a.w10 := n;
  end;
  if into <> nil then
    arr := into
  else
    arr := gspace(44);
  arr^.arr_elem := elem.dtype;
  arr^.arr_index := c_type_ptr_t(il_178);
  arr^.arr_elsize := sz;
  arr^.arr_size := 2;
  attr_tattr_to_vattr(a, arr^.arr_attr);
  type_exp(index.dtype, addr(ti));
  if ti.base <> c_type_ptr_t(il_178) then
    if not ti.flags.ranged then
      error1(54, index.line, index.name)
    else begin
      arr^.arr_size := (ti.high - ti.low + 1) * sz;
      arr^.arr_index := index.dtype;
    end;
  if (a.w10 = 0) and ((te.size = 1) or (te.base^.kind = 127)) then
    arr^.kind := 127
  else begin
    arr^.kind := 131;
    if odd(arr^.arr_size) then
      arr^.arr_size := arr^.arr_size + 1;
  end;
  if def_incomplete_su(elem.dtype, holder) then
    add_incomplete_type(il_$node_ptr_t(arr), holder);
  attr_validate(a, il_$node_ptr_t(arr));
  if ((a.size_bits div 8) mod lshft(1, a.align) <> 0) and
     not (12 in a.flags) then
    error0(240, lex_line);
  if al2 > a.w10 then
    if sz mod lshft(1, al2) <> 0 then
      error2(239, lex_line, smcontk(81, a.w10), smcontk(81, al2))
    else
      arr^.arr_attr.align := al2;
  if (arr^.arr_elem^.kind = 118) and (sz <> te.bytes) then
    error3(261, lex_line, smcontk(81, sz), elem.name, smcontk(81, te.size));
  def_arr := arr;
end;

{ def_blk_skeleton - see c_externs.ins.pas.  A function's result type
  is the declaration's (its function type's result); float, without a
  prototype and unless conv is 4, double.  A function already
  declared must be a function of the same convention and a compatible
  result and prototypes (old-style ones checked against an old-style
  definition), else 258 or 24 (the name then il_178 and a new block
  made); a definition after declarations updates the existing block.
  The new block (396 bytes) gets its enclosing block, name,
  parameters, class, result, attributes, nesting, options (setjmp and
  the like 4) and sections; a function gets a variable of its block's
  type in the outermost block.  Unless declared only, the block
  becomes il_180 (chained from il_17c).  conv 4 needs a prototype
  without class 0 (283); 213 for a function without a prototype under
  -TYPE.

  0x0484F8, 0x59E bytes, link #-140; the options' field (+374.7 to
  +376.3) by `lsr.l #11' and `andi.l #0x7FF'.

  Not known from the original:
  - the names; what p28 and opts mean. }

procedure def_blk_skeleton;
label
  7, 8;
var
  nm: c_name_t;
  s: c_sym_ptr_t;
  proto: boolean;
  rtype: c_type_ptr_t;
  t1, t2: type_exp_t;
  a: c_dattr_t;
  n, lev: integer;
  fl: integer32;
  p: c_parm_ptr_t;
  b, blk, enc: c_blk_ptr_t;
  ok: boolean;
  v: c_sym_ptr_t;
  o: integer32;
begin
  nm := name;
  s := c_sym_ptr_t(il_178);
  proto := false;
  if kind = 108 then begin
    s := c_sym_ptr_t(fnd_name(nm, false, false));
    type_exp(decl.dtype, addr(t1));
    if t1.base^.kind = 234 then
      rtype := t1.base^.fn_result
    else
      rtype := t1.base;
  end
  else
    rtype := c_type_ptr_t(s);
  if s <> c_sym_ptr_t(il_178) then
    if s^.var_type^.kind = 108 then begin
      b := c_blk_ptr_t(s^.var_type);
      if b^.params <> nil then
        proto := true
      else if b^.bits.x376_0 = 2 then
        proto := true;
    end;
  proto := proto or (protos <> nil);
  if proto then
    if s <> c_sym_ptr_t(il_178) then begin
      b := c_blk_ptr_t(s^.var_type);
      if (b^.params = nil) and (b^.bits.x376_0 = 2) then
        proto := false;
    end;
  if kind = 108 then begin
    type_exp(rtype, addr(t2));
    if (conv <> 4) and (t2.base^.kind = 123) and (t2.base^.len = 6) and
       not proto then
      rtype := double_type;
    a := decl.attr;
    discard(merge_attribs(a, il_$node_ptr_t(rtype)));
    if conv = 4 then
      if (cls = 0) or (protos <> nil) then
        error0(283, nm.line);
  end;
  n := 0;
  p := parms;
  while p <> nil do begin
    n := n + 1;
    p := p^.next;
  end;
  if kind = 106 then begin
    lev := -1;
    fl := 0;
  end
  else if kind = 172 then begin
    lev := c_blk_ptr_t(il_180)^.lev.level + 1;
    fl := 1;
  end
  else if cls = 2 then begin
    lev := -2;
    fl := 0;
  end
  else if p28 then begin
    lev := 1;
    fl := 1;
  end
  else begin
    lev := 0;
    fl := 2;
  end;
  if (nm.id = cdef_id_setjmp) or (nm.id = cdef_id_usetjmp) or
     (nm.id = cdef_id_sigsetjmp) or (nm.id = cdef_id_pfm_cleanup) then
    fl := fl ! 4;
  if s <> c_sym_ptr_t(il_178) then begin
    b := c_blk_ptr_t(s^.var_type);
    if b^.kind <> 108 then
      goto 8;
    blk := b;
    if b^.bits.conv <> conv then
      goto 8;
    if not check_types(b^.result, rtype, false) then
      goto 8;
    ok := true;
    if (protos <> nil) or (b^.params <> nil) then begin
      if b^.params = nil then begin
        if b^.bits.x376_0 = 0 then
          ok := check_oldef_proto(nm.id, protos, b^.old_parms,
                                  b^.lev.nparms)
        else
          ok := check_protos(b^.params, protos);
      end
      else if protos = nil then begin
        if cls = 2 then
          ok := check_protos(b^.params, protos);
      end
      else
        ok := check_protos(b^.params, protos);
    end;
    if ok then begin
      if cls = 2 then
        return;
      if (b^.bits.x376_0 <> 0) or (cls <> 0) then begin
        b^.old_parms := parms;
        b^.bits.x376_0 := cls;
        if proto then
          b^.lev.nparms := 255
        else
          b^.lev.nparms := 0;
        b^.lev.level := lev;
        b^.name.line := nm.line;
        o := b^.bits.opts;
        b^.bits.opts := o ! fl ! opts;
        goto 7;
      end;
    end;
8:
    if cargs_$options.usrch then
      error1(258, nm.line, nm.id)
    else
      error2(24, nm.line, nm.id, smcontk(81, s^.line));
    nm.id := il_178;
  end
  else if (protos = nil) and (kind = 108) and cargs_$options.type_opt then
    error1(213, lex_line, nm.id);
  enc := c_blk_ptr_t(il_180);
  if kind = 108 then
    enc := c_blk_ptr_t(cdef_outer_block);
  if into <> nil then
    blk := into
  else
    blk := gspace(396);
  blk^.kind := kind;
  blk^.outer := enc;
  blk^.name := nm;
  blk^.old_parms := parms;
  blk^.bits.x376_0 := cls;
  blk^.result := rtype;
  blk^.attr := a;
  blk^.x88 := -1;
  blk^.ret_lab := il_178;
  blk^.lev.level := lev;
  if proto then
    blk^.lev.nparms := 255
  else
    blk^.lev.nparms := 0;
  blk^.entry_lab := il_178;
  blk^.b378.made := true;
  blk^.bits.conv := conv;
  blk^.x84 := -16777216;
  blk^.bits.opts := fl ! opts;
  blk^.params := protos;
  attr_compute_routine_options(blk^.ropts, il_180);
  if lex_inline_state = 1 then
    blk^.bits.opts := (blk^.bits.opts & ~2048) ! 1024
  else if lex_inline_state = 2 then
    blk^.bits.opts := (blk^.bits.opts & ~1024) ! 2048;
  blk^.code_sect := cdef_code_sect;
  blk^.data_sect := cdef_data_sect;
  if kind = 108 then begin
    v := gspace(84);
    v^.kind := 109;
    v^.var_type := c_type_ptr_t(blk);
    v^.var_vat := vat_local;
    v^.var_78 := -1;
    def_name(nm, v, c_blk_ptr_t(cdef_outer_block));
  end;
7:
  if cls <> 2 then begin
    if il_17c <> nil then
      c_blk_ptr_t(il_17c)^.next_blk := blk;
    il_17c := blk;
    il_180 := il_$node_ptr_t(blk);
    blk^.x196 := 0;
  end;
  if blk^.kind = 108 then
    attr_validate(a, il_$node_ptr_t(blk));
end;

{ def_blk_params - see c_externs.ins.pas.  A function's result type
  (a 1- or 2-byte integral one int or unsigned without a prototype)
  and its register class; its parameters by name made variables (int
  for one never declared: 35 under -TYPE; float double unless the
  prototype keeps it) at offsets from 8 (12 when the result is
  returned in memory: 128 for main), each its slot (4, 8 for a
  double, a structure's size, 2 for a short kept by a prototype);
  checked against the prototype under -TYPE (258 or 24); the result's
  variable (in memory beyond the class 6, or at 8 for a double when not
  cpu 6).  A program's (105) and a function's data section get their
  frame offsets without -ABS.

  0x048A96, 0x476 bytes, link #-164; def_varn's class and flag pushed
  as one longword (0x50000 a parameter array, 0x20000 dynamic); both
  arms of the result's frame offset 8.

  Not known from the original:
  - the names; why both arms give 8. }

procedure def_blk_params;
var
  b, blk: c_blk_ptr_t;
  d: c_decl_t;
  nopromo, proto: boolean;
  rt, r: c_type_ptr_t;
  pl, p: c_parm_ptr_t;
  t, tp: type_exp_t;
  rl, n, i, off, sz, total: integer;
  v, rv: c_sym_ptr_t;
  ds: il_$node_ptr_t;
  vat: c_vat_t;
begin
  b := c_blk_ptr_t(il_180);
  d.flags := [];
  d.unused_28 := 0;
  blk := b;
  nopromo := false;
  proto := false;
  if cargs_$options.type_opt and (blk^.params <> nil) then begin
    proto := true;
    if promote and (blk^.params^.types[1]^.kind <> 31) then
      nopromo := proto;
  end;
  case b^.kind of
    105:
      ;
    108: begin
      rt := blk^.result;
      pl := blk^.old_parms;
      blk^.code_sect := cdef_code_sect;
      blk^.data_sect := cdef_data_sect;
      type_exp(rt, addr(t));
      if (t.base^.kind = 122) and not proto and (t.base^.len < 4) then begin
        if t.base^.signed then
          rt := int_type
        else
          rt := uint_type;
        type_exp(rt, addr(t));
      end;
      rl := get_rlen(t);
      n := 0;
      p := pl;
      while p <> nil do begin
        n := n + 1;
        p := p^.next;
      end;
      blk^.lev.nparms := n;
      if blk^.bits.db_adjusted then
        off := 8
      else
        off := 8;
      if rl > 6 then begin
        if blk^.name.id = id_main then
          error1(128, lex_line, rt);
        off := 12;
      end;
      p := pl;
      total := 0;
      for i := 1 to n do begin
        if p^.ptype = c_type_ptr_t(il_178) then begin
          p^.ptype := int_type;
          if cargs_$options.type_opt then
            error2(35, lex_line, blk^.name.id, p^.pname.id);
        end;
        type_exp(p^.ptype, addr(tp));
        if (tp.base^.kind = 123) and (tp.base^.len = 6) and
           not nopromo then begin
          p^.ptype := double_type;
          type_exp(p^.ptype, addr(tp));
        end;
        sz := 4;
        if tp.base^.kind = 123 then begin
          if ((tp.base^.len = 6) and not nopromo) or
             (tp.base^.len = 7) then
            sz := 8;
        end
        else if tp.base^.kind = 132 then
          sz := tp.bytes
        else if ((tp.base^.kind = 129) or (tp.base^.kind = 122)) and
                (tp.size < 4) and nopromo then
          sz := 2;
        total := total + sz;
        p^.flags := c_flags_t(merge_attribs(p^.attr,
                                            il_$node_ptr_t(p^.ptype)));
        attr_validate(p^.attr, il_$node_ptr_t(p));
        d.dtype := p;
        d.flags := [];
        if (tp.base^.kind = 131) or (tp.base^.kind = 127) then
          vat := vat_param
        else
          vat := vat_dynm;
        v := def_varn(p^.pname, d, vat, false);
        if v^.kind = 109 then begin
          if not nopromo and
             ((tp.base^.kind = 122) or (tp.base^.kind = 129)) then
            v^.var_offset := off + 4 - tp.size
          else
            v^.var_offset := off;
          v^.var_flags := v^.var_flags + [10];
          if p^.reg then
            add_reg_var(v);
        end;
        off := off + sz;
        p := p^.next;
      end;
      blk^.parm_size := total;
      if cargs_$options.type_opt and (blk^.params <> nil) and
         not promote and (blk^.params^.types[1]^.kind <> 31) then
        if not check_oldef_proto(blk^.name.id, blk^.params, pl, n) then
          if cargs_$options.usrch then
            error1(258, blk^.name.line, blk^.name.id)
          else
            error2(24, lex_line, blk^.name.id,
                   smcontk(81, blk^.name.line));
      r := rt;
      while r^.kind = 118 do
        r := c_sym_ptr_t(r)^.td_type;
      if r^.kind <> 210 then begin
        d.dtype := rt;
        d.flags := [];
        rv := add_varn(blk^.name.id, d, vat_dynm);
        blk^.ret_var := rv;
        if (rl > 6) and
           not ((rl = 7) and (6 in cargs_$options.cpu)) then begin
          rv^.var_offset := 8;
          blk^.ret_var^.var_vat := vat_param;
          blk^.ret_var^.var_flags := blk^.ret_var^.var_flags + [18];
        end
        else
          def_alloc_var(rv, t.bytes);
      end;
    end;
    otherwise
      return;
  end;
  if not (7 in cargs_$options.flags_286) then begin
    ds := b^.data_sect;
    if 6 in cargs_$options.cpu then
      ds^.xl[4] := ds^.xl[4] - 24
    else begin
      ds^.xl[4] := ds^.xl[4] - 12;
      if cargs_$options.db <> 0 then
        ds^.xl[4] := ds^.xl[4] - 4;
    end;
    blk^.x108 := ds^.xl[4];
    blk^.sect_next := ds^.xp[3];
    ds^.xp[3] := il_$node_ptr_t(b);
  end;
end;

{ alloc_on_stk - size bytes of the current block's frame (aligned to
  2**align, downward), or, when the frame would pass 24K and the size
  is large and not -CPU M020, of its far area (x176; vat becomes
  xdynm); both kept word-aligned, the frame saved.

  0x048F0C, 0xD4 bytes, link #-4; `(frame + 31000) lsr 2' unsigned.

  Not known from the original:
  - the names; the limits' reasons. }

procedure alloc_on_stk(
    size: integer32;
    align: integer;
    var off: integer32;
    var vat: c_vat_t); options(val_param); internal;
begin
  cdef_50^.frame_size := cdef_50^.saved_frame;
  if (cdef_50^.frame_size - size < -24576) and
     ((cdef_50^.frame_size + 31000) div 4 < size) and
     not (3 in cargs_$options.cpu) then begin
    calc_align(cdef_50^.x176, align, 0);
    off := cdef_50^.x176;
    cdef_50^.x176 := cdef_50^.x176 + size;
    vat := vat_xdynm;
  end
  else begin
    calc_align(cdef_50^.frame_size, align, 1);
    cdef_50^.frame_size := cdef_50^.frame_size - size;
    off := cdef_50^.frame_size;
  end;
  calc_align(cdef_50^.x176, 1, 0);
  calc_align(cdef_50^.frame_size, 1, 1);
  cdef_50^.saved_frame := cdef_50^.frame_size;
end;

{ def_alloc_var - see c_externs.ins.pas.  The alignment: the natural
  one of its size, or the attributes' (at least 1); a section's first
  variable gives the section its size.  Routines, section, extern and
  already placed variables are not allocated; a local becomes static
  (in a module) or dynamic; a size of 0 is 15 (unless flag 14); static
  and extdef ones in the data section (in its far part, xstat or
  xextdef, past 24K for a large one, not -CPU M020), others on the
  frame (alloc_on_stk); flag 18.  The data section's sizes kept even.

  0x048FE0, 0x20C bytes, link #-8. }

procedure def_alloc_var;
var
  avat: c_vat_t;
  al, x: integer;
  ds: il_$node_ptr_t;
begin
  if il_180^.kind = 106 then
    avat := vat_stat
  else
    avat := vat_dynm;
  if v^.kind = 109 then begin
    al := attr_natural_align_from_bytes((v^.var_attr.size_bits + 7) div 8);
    x := v^.var_attr.align;
    if x < v^.var_attr.unused_10 then
      x := v^.var_attr.unused_10;
    if al < x then
      al := x;
    if al <= 0 then
      al := 1;
    if (v^.var_vat = vat_sect) and (v^.var_sect^.xl[5] = 0) then begin
      if odd(size) then
        size := size + 1;
      v^.var_sect^.xl[5] := size;
      x := 3;
      if x > al then
        x := al;
      v^.var_attr.align := x;
    end;
    if not ((v^.var_type^.kind = 108) or (v^.var_type^.kind = 107)) and
       (v^.var_vat <> vat_sect) and (v^.var_vat <> vat_ext) and
       not (18 in v^.var_flags) and (v^.var_offset = 0) then begin
      if v^.var_vat = vat_local then
        v^.var_vat := avat;
      if (size = 0) and not (14 in v^.var_flags) then
        error1(15, v^.line, v^.name);
      if odd(size) then
        size := size + 1;
      v^.var_attr.align := al;
      if (v^.var_vat = vat_stat) or (v^.var_vat = vat_extdef) then begin
        ds := c_blk_ptr_t(il_180)^.data_sect;
        if (ds^.xl[5] + size > 24576) and
           ((32768 - ds^.xl[5]) div 4 < size) and
           not (3 in cargs_$options.cpu) then begin
          calc_align(ds^.xl[6], al, 0);
          v^.var_offset := ds^.xl[6];
          ds^.xl[6] := ds^.xl[6] + size;
          if v^.var_vat = vat_stat then
            v^.var_vat := vat_xstat
          else
            v^.var_vat := vat_xextdef;
        end
        else begin
          calc_align(ds^.xl[5], al, 0);
          v^.var_offset := ds^.xl[5];
          ds^.xl[5] := ds^.xl[5] + size;
        end;
      end
      else
        alloc_on_stk(size, al, v^.var_offset, v^.var_vat);
      v^.var_flags := v^.var_flags + [18];
    end;
  end;
  calc_align(c_blk_ptr_t(il_180)^.data_sect^.xl[5], 1, 0);
  calc_align(c_blk_ptr_t(il_180)^.data_sect^.xl[6], 1, 0);
end;
