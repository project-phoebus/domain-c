{ c_syntax - the parser for declarations and statements: one routine
  per construct (declaration_stmts, declaration, declaration_specifiers,
  struct_union_type, enum__type, abstract_decl, function_prototype, the
  initializers, body, stat, if_stat, switch_stat, the loops, ...), the
  attribute and option clauses, constant expressions, and the tree
  walker the statement semantics use to fold constants (cc_walk_it,
  call_kfold).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0609D8  0x060C58  syntax
    0x060B38  0x060DB8  initialize_legal_specs
    0x060B96  0x060E16  error
    0x060C20  0x060EA0  warning
    0x060C38  0x060EB8  check
    0x060C68  0x060EE8  program_
    0x060E88  0x061108  parse_attributes
    0x0612DE  0x06155E  avoid_void
    0x061394  0x061614  get_options
    0x061560  0x0617E0  add_top_node
    0x061596  0x061816  declaration_stmts
    0x061EA8  0x062128  storage_class
    0x061FBE  0x06223E  type_qualifiers
    0x06228E  0x06250E  declaration_specifiers
    0x0620AC  0x06232C  type_specifier
    0x062068  0x0622E8  check_add_spec
    0x0623EC  0x06266C  declaration
    0x062B38  0x062DB8  function_prototype
    0x062E88  0x063108  function_def
    0x062ECA  0x06314A  array_decl
    0x063098  0x063318  struct_union_type
    0x0633CE  0x06364E  member_list
    0x063784  0x063A04  enum__type
    0x063A00  0x063C80  int_ob_kind_from_integer_type
    0x063AB2  0x063D32  enum_list
    0x063C6C  0x063EEC  data_init
    0x063E08  0x064088  dynm_init
    0x0640AE  0x06432E  array_init
    0x064286  0x064506  array_dim_init
    0x06456E  0x0647EE  struct_init
    0x0649E2  0x064C62  init_with_string
    0x064BEA  0x064E6A  get_constant
    0x064AB4  0x064D34  address_exposed
    0x064AE0  0x064D60  varn_from_addr_con
    0x064B3C  0x064DBC  check_addr_init
    0x06508E  0x06530E  body
    0x0652A4  0x065524  stat_list
    0x0653D4  0x065654  stat
    0x065668  0x0658E8  compound_stat
    0x065774  0x0659F4  if_stat
    0x065884  0x065B04  case_or_default_stat
    0x065A26  0x065CA6  switch_stat
    0x065994  0x065C14  push_switch
    0x065A0A  0x065C8A  pop_switch
    0x065D0C  0x065F8C  while_stat
    0x065E02  0x066082  do_while_stat
    0x065F5E  0x0661DE  for_stat
    0x066162  0x0663E2  call_kfold
    0x066190  0x066410  call_kfold_fold_addrs
    0x0661BC  0x06643C  cc_walk_it
    0x0665DC  0x06685C  constant_expr
    0x0669A0  0x066C20  continue_break
    0x0669B4  0x066C34  return_stat
    0x066AFA  0x066D7A  goto_stat
    0x066B52  0x066DD2  clear_operands
    0x066C7A  0x066EFA  init_refvar
    0x066E54  0x0670D4  pp_constant
    0x066F12  0x067192  abstract_decl
    0x067286  0x067506  c_type_name
    A5 0x14AC94 (cc.m68k), 0x2CAC94 (cc.a88k; c_sym_map has no data of
    its own and runs on the same address): the legal type specifier
    combinations (+0x0, 13 words), the routine attribute keywords
    syntax enters (+0x20..+0x40), +0x44 (il_178), and the cells
    c_globals.ins.pas declares (+0x48..+0x204).

  TODO(pascal) c_syntax is translated in part

  Not written yet: parse_attributes, get_options, declaration_stmts,
  declaration, function_prototype, array_decl, data_init, dynm_init, array_init,
  array_dim_init, struct_init, init_with_string, get_constant
  (check_addr_init, varn_from_addr_con, address_exposed), abstract_decl,
  c_type_name; declaration_stmts, declaration and parse_attributes are
  declared extern meanwhile.  The
  headings of the routines not written (c_syntax.ins.pas) are still
  those read off the frames.

  The routines other units call load A5; the others are internal.
  check_addr_init, varn_from_addr_con and address_exposed are nested
  in get_constant, push_switch and pop_switch in switch_stat,
  type_specifier in declaration_specifiers and check_add_spec in
  type_specifier.
}
module c_syntax;

%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/pfm.ins.pas';
%include 'us/us/ins/error.ins.pas';
%include '/sys/ins/error.ins.pas';
%include 'us/us/ins/fpp_errs.ins.pas';
%include 'us/us/ins/peb.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/externals.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/c_compiler/source/c_syntax.ins.pas';
%include 'lang/c_compiler/source/c_expr_syn.ins.pas';

define
  id_main;                              { +0x48 (c_globals.ins.pas) }
  csyn_4c;
  id_at;
  csyn_54;
  id_string_constant;
  csyn_5c;
  csyn_60;
  id_volatile;                          { +0x160 }
  idu_volatile;
  id_read;
  idu_read;
  id_write;
  idu_write;
  id_address;
  idu_address;
  id_bit;
  id_byte;
  id_word;
  id_long;
  id_quad;
  id_size;
  id_aligned;
  idu_aligned;
  id_natural;
  idu_natural;
  id_unaligned;
  id_physical;
  id_processor_register;
  id_fp_internal_register;
  id_register;
  id_immediate;
  id_reference;
  id_atomic;
  idu_atomic;
  id_no_fp;
  id_save_db;
  id_section;
  idu_section;
  id_resident_procedure;
  id_device;
  idu_device;                           { +0x1E4 }
  csyn_1e8;
  idu_options;
  idu_attribute;
  con_minus_one;
  con_zero;
  token_kind;                           { +0x200 }
  csyn_202;
  csyn_204;

{ KFOLD, KFOLD_$GENERAL - kfold.pas's constant folding of the tree t
  (kfold.pas 0x0AF444, 0x0AD1A0; cc.a88k 0x0AF6C4, 0x0AD420): kfold
  takes the parent by address and calls kfold_$general with it, the
  tree's address and false; with addrs set address constants are folded
  too.  Declared here: c_syntax opens no kfold insert. }
procedure kfold(
    in parent: il_$node_ptr_t;
    var t: il_$node_ptr_t); extern;

procedure kfold_$general(
    parent: il_$node_ptr_t;
    var t: il_$node_ptr_t;
    addrs: boolean); options(val_param); extern;

type
  { The type specifiers met in a declaration (type_specifier's numbers:
    0 char, 1 int, 2 float, 3 double, 4 short, 5 long, 6 signed, 7
    unsigned, 8 void, 9 struct or union, 10 enum, 11 a typedef name; 12
    an identifier that is not a type name ends them). }
  c_specs_t = set of 0..15;

var
  legal_specs: array [0..12] of c_specs_t;  { +0x0 }
  kw_save_db: il_$node_ptr_t;           { +0x20: `save_db' }
  kw_abnormal: il_$node_ptr_t;          { +0x24: `abnormal' }
  kwu_abnormal: il_$node_ptr_t;         { +0x28: `__abnormal' }
  kw_nosave: il_$node_ptr_t;            { +0x2C: `nosave' }
  kwu_nosave: il_$node_ptr_t;           { +0x30: `__nosave' }
  kw_noreturn: il_$node_ptr_t;          { +0x34: `noreturn' }
  kwu_noreturn: il_$node_ptr_t;         { +0x38: `__noreturn' }
  kw_a0_return: il_$node_ptr_t;         { +0x3C: `a0_return' }
  kwu_a0_return: il_$node_ptr_t;        { +0x40: `__a0_return' }
  csyn_44: il_$node_ptr_t;              { +0x44: il_178 (syntax) }
  csyn_1ec: c_tag_ptr_t;                { +0x1EC: a tag declared before
                                          a block's scope is made
                                          (declaration_stmts enters it
                                          in the scope's tags) }
  { +0x208: the basic types' cells by type specifier (char, short, int,
    float, double) and unsigned. }
  basic_types: array [0..4, 0..1] of ^c_type_ptr_t := [
    [addr(char_type), addr(uchar_type)],
    [addr(short_type), addr(ushort_type)],
    [addr(int_type), addr(uint_type)],
    [addr(float_type), addr(float_type)],
    [addr(double_type), addr(double_type)]];

{ The routines called before they are defined. }

procedure initialize_legal_specs(
    xansi: boolean); options(val_param); internal; forward;

procedure program_; internal; forward;

procedure declaration_stmts(
    ctx: integer;
    first: boolean;
    out more: boolean); options(val_param); extern;   { TODO(pascal) not written yet }

procedure declaration(
    ctx: integer;
    in md: c_decl_t;
    conv: integer;
    out d: c_decl_t;
    out name: c_name_t); options(val_param); extern;   { TODO(pascal) not written yet }

procedure parse_attributes(
    var d: c_decl_t); extern;   { TODO(pascal) not written yet }

procedure struct_union_type(
    ctx: integer;
    first: boolean;
    kind: integer;
    var d: c_decl_t); options(val_param); internal; forward;

procedure enum__type(
    ctx: integer;
    first: boolean;
    var d: c_decl_t); options(val_param); internal; forward;

procedure member_list(
    ctx: integer;
    kind: integer;
    var fl: c_fldlist_t;
    var d: c_decl_t); options(val_param); internal; forward;

procedure enum_list(
    var es: c_enumset_t;
    in t: c_type_ptr_t); forward;

procedure body(
    in follow: c_tokset_t); internal; forward;

procedure stat_list(
    in follow: c_tokset_t); internal; forward;

procedure stat(
    in follow: c_tokset_t); internal; forward;

procedure compound_stat(
    in follow: c_tokset_t); internal; forward;

procedure if_stat(
    in follow: c_tokset_t); internal; forward;

procedure case_or_default_stat(
    in follow: c_tokset_t); internal; forward;

procedure switch_stat(
    in follow: c_tokset_t); internal; forward;

procedure while_stat(
    in follow: c_tokset_t); internal; forward;

procedure do_while_stat(
    in follow: c_tokset_t); internal; forward;

procedure for_stat(
    in follow: c_tokset_t); internal; forward;

procedure constant_expr(
    in follow: c_tokset_t;
    out cx: c_cexp_t); internal; forward;

procedure continue_break; internal; forward;

procedure return_stat(
    in follow: c_tokset_t); internal; forward;

procedure goto_stat(
    in follow: c_tokset_t); internal; forward;

procedure clear_operands(
    top: integer); options(val_param); internal; forward;

procedure init_refvar(
    t: c_type_ptr_t); options(val_param); internal; forward;

{ syntax - parse the translation unit: the routine attribute keywords
  entered, the legal specifier combinations set, program_.

  0x0609D8, 0x110 bytes, link #0; A5: the nine names literals after
  the routine (`__abnormal', `a0_return', `__noreturn', `nosave',
  `save_db', `__a0_return', `noreturn', `__nosave', `abnormal'), each
  entered with idntk(76, ...).

  Not known from the original:
  - the names. }

procedure syntax;
begin
  cdef_fwd_ptrs := nil;
  kw_save_db := idntk(76, 'save_db', 7);
  kw_abnormal := idntk(76, 'abnormal', 8);
  kwu_abnormal := idntk(76, '__abnormal', 10);
  kw_nosave := idntk(76, 'nosave', 6);
  kwu_nosave := idntk(76, '__nosave', 8);
  kw_noreturn := idntk(76, 'noreturn', 8);
  kwu_noreturn := idntk(76, '__noreturn', 10);
  kw_a0_return := idntk(76, 'a0_return', 9);
  kwu_a0_return := idntk(76, '__a0_return', 11);
  csyn_44 := il_178;
  initialize_legal_specs(cargs_$options.xansi);
  program_;
end;

{ initialize_legal_specs - the type specifiers each type specifier may
  join (check_add_spec): char signed and unsigned; int short, long,
  signed and unsigned; float long, except under -XANSI; double long;
  short int, signed and unsigned; long int, double, signed and
  unsigned; signed and unsigned char, int, short and long; enum char,
  short and long (a short enum); none for void, struct, union and a
  typedef name.

  0x060B38, 0x5E bytes, no frame (docs/rev889-patterns.md 16): the
  words stored in turn, +0x4 last.

  Not known from the original:
  - the names. }

procedure initialize_legal_specs(
    xansi: boolean); options(val_param); internal;
begin
  legal_specs[0] := [6, 7];
  legal_specs[1] := [4..7];
  legal_specs[3] := [5];
  legal_specs[4] := [1, 6, 7];
  legal_specs[5] := [1, 3, 6, 7];
  legal_specs[6] := [0, 1, 4, 5];
  legal_specs[7] := [0, 1, 4, 5];
  legal_specs[8] := [];
  legal_specs[9] := [];
  legal_specs[10] := [0, 4, 5];
  legal_specs[11] := [];
  legal_specs[12] := [];
  if xansi then
    legal_specs[2] := []
  else
    legal_specs[2] := [5];
end;

{ error - diagnostic code at the current token, then tokens skipped to
  one of follow or the end of the source.

  0x060B96, 0x7C bytes, link #-56: follow + [ctk_eof] formed with
  `or.l'/`or.w' of a 14-byte constant after the routine (0x060C12).

  Not known from the original:
  - the names. }

procedure error(
    code: integer;
    in follow: c_tokset_t); options(val_param); internal;
var
  s: c_tokset_t;
begin
  error1(code, lex_line, lex_token);
  s := follow + [ctk_eof];
  while not (token_kind in s) do
    get;
end;

{ warning - diagnostic code at the current line.

  0x060C20, 0x18 bytes, link #-4. }

procedure warning(
    code: integer); options(val_param); internal;
begin
  error0(code, lex_line);
end;

{ check - error(code, follow) unless the current token is in follow.

  0x060C38, 0x30 bytes, link #-4. }

procedure check(
    code: integer;
    in follow: c_tokset_t); options(val_param); internal;
begin
  if not (token_kind in follow) then
    error(code, follow);
end;

{ program_ - the translation unit: the outermost block, a module named
  `file_name_useless_for_module' (def_blk_skeleton 106, conv 3), then
  external declarations to the end of the source.  Without #module the
  block is named after the source file's leaf (from its first letter,
  `$' or `_': letters, digits, `$', `_' and `.'; a final `.c' or `_c'
  dropped); then the forward pointers left are resolved
  (def_final_res_fwd_ptrs), unless the leaf could not be had.

  0x060C68, 0x1D4 bytes, link #-576: the name's 256 characters stored
  from a 28-character literal and blanks; name_$strip_leaf_lc's
  maximum a word constant (255) after the routine; the leaf's
  characters tested with three set constants (letters and `$', `_'
  first; then `.', the lower case letters, the rest).

  Not known from the original:
  - the names. }

procedure program_;
var
  d: c_decl_t;
  leaf: array [1..256] of char;
  s: array [1..256] of char;
  nm: c_name_t;
  status: status_$t;
  leaf_len: integer;
  len: integer;
  more: boolean;
  i, j: integer;
begin
  s := 'file_name_useless_for_module';
  len := 28;
  nm.line := spos_$null_position;
  nm.id := idntk(76, s, len);
  d.dtype := il_178;
  d.name := nm.id;
  d.line := spos_$null_position;
  d.flags := [];
  def_blk_skeleton(106, nm, 0, d, nil, nil, false, 3, 0, nil);
  cdef_outer_block := il_180;
  get;
  while token_kind <> ctk_eof do begin
    csyn_1ec := nil;
    declaration_stmts(0, true, more);
  end;
  if not lex_module_seen then begin
    name_$strip_leaf_lc(iosub_$source_pathname,
                        iosub_$source_pathname_length, 255, len, leaf,
                        leaf_len, status);
    if status.fail then
      return;
    j := 0;
    for i := 1 to leaf_len do
      if (j <> 0) or
         (leaf[i] in ['$', 'A'..'Z', '_', 'a'..'z']) then
        if (leaf[i] = '.') or (leaf[i] in ['a'..'z']) or
           (leaf[i] in ['$', '0'..'9', 'A'..'Z', '_']) then begin
          j := j + 1;
          s[j] := leaf[i];
        end;
    if (s[j - 1] = '_') or (s[j - 1] = '.') then
      if s[j] = 'c' then
        j := j - 2;
    if j > 0 then
      c_blk_ptr_t(cdef_outer_block)^.name.id := idntk(76, s, j);
  end;
  def_final_res_fwd_ptrs;
end;

{ avoid_void - d's type is void (the callers test it): unless the void
  is reached through a pointer or a function (the last of the pointers,
  functions and arrays d's type is made of), it becomes int (the type,
  its specifier token, the line; flags cleared) with diagnostic 9 naming
  name when report is set; false then.

  0x0612DE, 0xB6 bytes, link #-12; A5 (no other unit calls it): the
  derivations followed by kind (130 +4, 234 +8, the arrays +4), tested
  127, 131, 130, 234.

  Not known from the original:
  - the names. }

function avoid_void(
    var d: c_decl_t;
    in name: c_name_t;
    in report: boolean): boolean;
var
  t, last: c_type_ptr_t;
begin
  avoid_void := true;
  last := nil;
  t := d.dtype;
  while t^.kind in [127, 131, 130, 234] do begin
    last := t;
    if t^.kind = 130 then
      t := t^.ptr_to
    else if t^.kind = 234 then
      t := t^.fn_result
    else
      t := t^.arr_elem;
  end;
  if last <> nil then
    if last^.kind in [130, 234] then
      return;
  avoid_void := false;
  if report then
    error1(9, lex_line, name.id);
  d.dtype := int_type;
  d.name := lex_tokens[ctk_int];
  d.line := lex_line;
  d.flags := [];
end;

{ storage_class - the storage class specifiers to sc (std_call makes
  conv 4 and is a storage class only when there is none yet); a second
  class is diagnostic 12.  At file level (ctx 0) only extern, static
  and typedef are taken (diagnostic 12, extern), for the parameters of
  an old-style definition (ctx 2) only register (diagnostic 12, auto).

  0x061EA8, 0x110 bytes, link #-4: the context's case a jump table
  (0..4); the tests `(sc = 216) or (sc = 29)' and the class lists
  evaluated whole.

  Not known from the original:
  - the names. }

procedure storage_class(
    ctx: integer;
    var sc: integer;
    var conv: integer); options(val_param); internal;
begin
  conv := 3;
  while token_kind in [ctk_auto, ctk_register, ctk_typedef, ctk_std_call,
                       ctk_static, ctk_extern] do begin
    if token_kind = ctk_std_call then begin
      conv := 4;
      if sc = 216 then
        sc := token_kind;
    end
    else begin
      if not ((sc = 216) or (sc = ctk_std_call)) then
        error1(12, lex_line, lex_token);
      sc := token_kind;
      case ctx of
        0:
          if not ((token_kind = ctk_extern) or (token_kind = ctk_static) or
                  (token_kind = ctk_typedef)) then begin
            error1(12, lex_line, lex_token);
            sc := ctk_extern;
          end;
        2:
          if token_kind <> ctk_register then begin
            error1(12, lex_line, lex_token);
            sc := ctk_auto;
          end;
        otherwise
          ;
      end;
    end;
    get;
  end;
end;

{ type_qualifiers - const and volatile (lex_tokens 102, 103) taken into
  the flags q: const 19, volatile 0, 3 and 4 (add_attribute with the
  token).

  0x061FBE, 0xAA bytes, link #-24: a 20-byte attribute record of which
  the first longword is q; volatile's three calls and const's share the
  last call (docs/rev889-patterns.md 23); the loop's test compares 103
  first.

  Not known from the original:
  - the names; add_attribute's third argument (0 here). }

procedure type_qualifiers(
    var q: c_flags_t); internal;
var
  a: c_dattr_t;
begin
  a.flags := q;
  while (token_kind = 103) or (token_kind = 102) do begin
    case token_kind of
      102:
        add_attribute(19, a, 0, lex_token);
      103: begin
        add_attribute(0, a, 0, lex_token);
        add_attribute(3, a, 0, lex_token);
        add_attribute(4, a, 0, lex_token);
      end;
      otherwise
        ;
    end;
    get;
  end;
  q := a.flags;
end;

{ declaration_specifiers - the storage class, qualifiers and type
  specifiers of a declaration to d (its type, il_174 until one is
  given, then the basic type the specifiers make: void, or by char,
  short, float, double (else int) and unsigned; signed sets the
  attribute bit 20), sc (216 when none was given: sc 216 on entry asks
  for none; anything else is made auto and back 216 at the end) and
  conv (3, 4 for std_call); res is set when anything was given.

  0x06228E, 0x15E bytes, link #-12: the specifiers in D2, passed to
  type_specifier through a frame word; the basic types through the
  table at +0x208 of c_syntax's data; the specifier set cleared of 12
  (`andi.w #0xEFFF') before the result `(sc <> 216) or (d.flags <> [])
  or (specs <> [])' is evaluated whole.

  Not known from the original:
  - the names. }

procedure declaration_specifiers(
    ctx: integer;
    first: boolean;
    var res: boolean;
    var d: c_decl_t;
    var conv: integer;
    var sc: integer); options(val_param); internal;
var
  t: c_specs_t;
  specs: c_specs_t;
  none: boolean;
  u, k: integer;

  { type_specifier - type specifiers to specs and d: the basic type
    names (check_add_spec), a structure or union (struct_union_type), an
    enumeration (enum__type, held in char or short when those were
    given) and a typedef name; an identifier that is not one, or comes
    after other specifiers, adds 12 and ends them.  d.name is the last
    specifier's token.

    0x0620AC, 0x1D4 bytes, link #-20: the token's case a compare chain
    (12, 11, 13, 14, 38, 37, 104, 39, 8, 16, 17, 6, 76), the specifier
    calls sharing their tail; the typedef name looked up with
    fnd_name(nm, false, false).

    Not known from the original:
    - the names. }

  procedure type_specifier(
      ctx: integer;
      first: boolean;
      var d: c_decl_t;
      var specs: c_specs_t); options(val_param);
  var
    nm: c_name_t;
    s: il_$node_ptr_t;

    { check_add_spec - add the specifier k to specs, diagnostic 25 when
      it may not join those given (legal_specs[k]).

      0x062068, 0x44 bytes, link #-12: the test `(specs = []) or (specs
      - legal_specs[k] = [])' as `not.w; and.w'.

      Not known from the original:
      - the names. }

    procedure check_add_spec(
        k: integer;
        var specs: c_specs_t); options(val_param);
    begin
      if (specs = []) or (specs - legal_specs[k] = []) then
        specs := specs + [k]
      else
        error1(25, lex_line, lex_token);
    end;

  begin
    while token_kind in [ctk_enum, ctk_void, ctk_int, ctk_char, ctk_float,
                         ctk_double, ctk_union, ctk_struct, ctk_long,
                         ctk_short, ctk_unsigned, ctk_identifier,
                         104] do
      case token_kind of
        ctk_char: begin
          check_add_spec(0, specs);
          d.name := lex_token;
          get;
        end;
        ctk_int: begin
          check_add_spec(1, specs);
          d.name := lex_token;
          get;
        end;
        ctk_float: begin
          check_add_spec(2, specs);
          d.name := lex_token;
          get;
        end;
        ctk_double: begin
          check_add_spec(3, specs);
          d.name := lex_token;
          get;
        end;
        ctk_short: begin
          check_add_spec(4, specs);
          d.name := lex_token;
          get;
        end;
        ctk_long: begin
          check_add_spec(5, specs);
          d.name := lex_token;
          get;
        end;
        104: begin
          check_add_spec(6, specs);
          d.name := lex_token;
          get;
        end;
        ctk_unsigned: begin
          check_add_spec(7, specs);
          d.name := lex_token;
          get;
        end;
        ctk_void: begin
          check_add_spec(8, specs);
          d.name := lex_token;
          get;
        end;
        ctk_union, ctk_struct: begin
          check_add_spec(9, specs);
          d.name := lex_token;
          struct_union_type(ctx, first, token_kind, d);
        end;
        ctk_enum: begin
          check_add_spec(10, specs);
          d.name := lex_token;
          if 0 in specs then
            d.dtype := char_type
          else if 4 in specs then
            d.dtype := short_type
          else
            d.dtype := int_type;
          enum__type(ctx, first, d);
        end;
        ctk_identifier: begin
          if specs <> [] then begin
            specs := specs + [12];
            return;
          end;
          nm.id := lex_token;
          nm.line := lex_line;
          s := fnd_name(nm, false, false);
          if (s = il_178) or (s^.kind <> 118) then begin
            specs := specs + [12];
            return;
          end;
          check_add_spec(11, specs);
          d.dtype := s;
          d.name := lex_token;
          get;
        end;
        otherwise begin
          d.name := lex_token;
          get;
        end;
      end;
  end;

begin
  specs := [];
  d.line := lex_line;
  d.tag := nil;
  d.dtype := il_174;
  d.flags := [];
  conv := 3;
  if sc <> 216 then begin
    sc := ctk_auto;
    none := true;
  end
  else
    none := false;
  while token_kind in [ctk_enum, ctk_void, ctk_int, ctk_char, ctk_float,
                       ctk_double, ctk_union, ctk_struct, ctk_auto,
                       ctk_register, ctk_typedef, ctk_std_call, ctk_static,
                       ctk_extern, ctk_long, ctk_short, ctk_unsigned,
                       ctk_identifier, 102, 103, 104] do
    if token_kind in [ctk_auto, ctk_register, ctk_typedef, ctk_std_call,
                      ctk_static, ctk_extern] then
      storage_class(ctx, sc, conv)
    else if (token_kind = 103) or (token_kind = 102) then
      type_qualifiers(d.flags)
    else begin
      t := specs;
      type_specifier(ctx, first, d, t);
      specs := t;
      if 12 in specs then
        exit;
    end;
  if none then
    sc := 216;
  specs := specs - [12];
  res := (sc <> 216) or (d.flags <> []) or (specs <> []);
  if d.dtype = il_174 then
    if specs = [8] then
      d.dtype := void_type
    else begin
      if 7 in specs then
        u := 1
      else
        u := 0;
      if 0 in specs then
        k := 0
      else if 4 in specs then
        k := 1
      else if 2 in specs then
        k := 3
      else if 3 in specs then
        k := 4
      else
        k := 2;
      d.dtype := basic_types[k, u]^;
    end;
  if 6 in specs then
    d.flags := d.flags + [20];
end;

{ function_def - a function's definition after its declarator: the
  parameter declarations of an old-style definition (declaration_stmts
  with ctx 2), the parameters made variables (def_blk_params; promote
  for an old-style definition) and the body (follow empty).

  0x062E88, 0x34 bytes, link #-8: body's follow set an empty 14-byte
  constant after the routine.

  Not known from the original:
  - the names. }

procedure function_def(
    promote: boolean); options(val_param); internal;
var
  more: boolean;
begin
  repeat
    declaration_stmts(2, true, more);
  until not more;
  def_blk_params(promote);
  body([]);
end;

{ struct_union_type - struct or union (kind 17 or 16), a tag, members
  in braces, to d.dtype (d.tag the tag's identifier).  A tag is looked up
  (lookup_su): an enumeration's is diagnostic 24 (258 under -USRCH);
  with a body, a tag of another block (or, for the first declaration of
  a compound statement, ctx 4, any tag) is declared anew (def_su, in
  the scope's tags through csyn_1ec or in il_180's), a complete one is
  redefined (diagnostic 24 or 258).  The body's fields (member_list)
  make the type (def_rec), the tag's attributes merged
  (merge_attribs_natural), its incomplete users and the forward
  pointers resolved; a body without a tag gets an unnamed one.

  0x063098, 0x336 bytes, link #-92: the field list's alignment words
  set together (`move.l #0x10001') and x12 -1; while the body is read
  the structure's field pointer is il_178 (a member of its own type is
  incomplete).

  Not known from the original:
  - the names. }

procedure struct_union_type(
    ctx: integer;
    first: boolean;
    kind: integer;
    var d: c_decl_t); options(val_param); internal;
label
  body;
var
  fl: c_fldlist_t;
  nm: c_name_t;
  a: attr_tattr_t;
  tag: c_tag_ptr_t;
  st: c_type_ptr_t;
  err: boolean;
  save: c_field_ptr_t;
begin
  get;
  lex_fatal := false;
  tag := nil;
  st := c_type_ptr_t(il_178);
  err := false;
  fl.first := nil;
  fl.tag := nil;
  fl.has_bf := err;
  fl.size := 0;
  fl.bitoff := 0;
  fl.attr.flags := [];
  fl.attr.align := 1;
  fl.attr.w10 := 1;
  fl.attr.x12 := -1;
  if token_kind = ctk_identifier then begin
    nm.line := lex_line;
    nm.id := lex_token;
    d.tag := lex_token;
    get;
    tag := lookup_su(nm.id);
    if tag <> nil then begin
      if tag^.kind = ctk_enum then begin
        if cargs_$options.usrch then
          error1(258, lex_line, nm.id)
        else
          error2(24, lex_line, nm.id, smcontk(81, tag^.body.name.line));
        err := true;
        st := c_type_ptr_t(il_178);
        d.dtype := st;
        if token_kind <> ctk_lbrace then
          return;
        goto body;
      end;
      st := tag^.body.stype;
      d.dtype := st;
      if token_kind <> ctk_lbrace then
        return;
      if (tag^.body.block = c_blk_ptr_t(il_180)) and
         not (first and (ctx = 4)) then begin
        if st^.su_fields = nil then
          goto body;
        if cargs_$options.usrch then
          error1(258, lex_line, nm.id)
        else
          error2(24, lex_line, nm.id, smcontk(81, tag^.body.name.line));
        err := true;
        if st^.su_fields <> c_field_ptr_t(il_178) then
          goto body;
        st := c_type_ptr_t(il_178);
        d.dtype := st;
        d.tag := il_178;
        tag := nil;
        if token_kind <> ctk_lbrace then
          return;
        goto body;
      end;
    end;
    st := c_type_ptr_t(il_178);
    tag := def_su(nm, kind);
    fl.tag := tag;
    if first and (ctx = 4) then
      add_su(tag, csyn_1ec)
    else
      add_su(tag, c_blk_ptr_t(il_180)^.tags);
    if token_kind <> ctk_lbrace then begin
      d.dtype := def_rec(fl, nil);
      a.bits := fl.attr.flags;
      discard(merge_attribs_natural(a, d.dtype));
      tag^.body.stype := d.dtype;
      return;
    end;
  end;
body:
  if token_kind = ctk_lbrace then
    get
  else begin
    error1(99, lex_line, lex_token);
    if token_kind = ctk_semicolon then
      return;
  end;
  if st <> c_type_ptr_t(il_178) then begin
    save := st^.su_fields;
    st^.su_fields := c_field_ptr_t(il_178);
  end;
  member_list(ctx, kind, fl, d);
  if st <> c_type_ptr_t(il_178) then
    st^.su_fields := save;
  if err then
    return;
  if st <> c_type_ptr_t(il_178) then begin
    st := def_rec(fl, st);
    if tag <> nil then begin
      a.bits := fl.attr.flags;
      discard(merge_attribs_natural(a, il_$node_ptr_t(st)));
      def_resolve_incomplete_types(tag^.body);
      def_resolve_fwd_ptrs;
    end;
    return;
  end;
  d.dtype := def_rec(fl, nil);
  if tag = nil then begin
    nm.line := lex_line;
    nm.id := il_178;
    tag := def_su(nm, kind);
    if first and (ctx = 4) then
      add_su(tag, csyn_1ec)
    else
      add_su(tag, c_blk_ptr_t(il_180)^.tags);
  end
  else begin
    a.bits := fl.attr.flags;
    discard(merge_attribs_natural(a, d.dtype));
  end;
  tag^.body.stype := d.dtype;
end;

{ member_list - the members of a structure or union up to the closing brace: each
  declaration's specifiers (diagnostic 41 when there are none) and its
  declarators or `: width' bit fields (named by id_at), laid out by
  def_fld; a function member is diagnostic 42, a member of an unknown
  type 161, a void member made int (avoid_void).  The members' storage
  attribute bits (all but 0, 2, 5, 12 and 19) are or-ed into d's.  A
  `)' or `]' is diagnostic 58; after a declaration anything but `;'
  is diagnostic 55 (101 for a typedef name, or another declaration's
  start).  No members, or a size of 0, is diagnostic 174.

  0x0633CE, 0x370 bytes, link #-236: the specifiers called with the
  register holding false (docs/rev889-patterns.md 24) and sc 36; the
  bit field declaration copied whole (34 bytes); the tests on s +
  [rbrace, semicolon] and s - [rbrace, semicolon] in a frame temporary.

  Not known from the original:
  - the names. }

procedure member_list(
    ctx: integer;
    kind: integer;
    var fl: c_fldlist_t;
    var d: c_decl_t); options(val_param); internal;
var
  te: type_exp_t;
  nm: c_name_t;
  s: c_tokset_t;
  cs: c_tokset_t;
  width: c_cexp_t;
  fname: c_name_t;
  fd: c_decl_t;
  md: c_decl_t;
  conv: integer;
  sc: integer;
  res: boolean;
  empty: boolean;
  t: c_type_ptr_t;
  sym: il_$node_ptr_t;
begin
  cs := [ctk_sizeof, ctk_comma, ctk_semicolon, ctk_plus, ctk_minus,
         ctk_eof, ctk_identifier, 77..89, ctk_string, ctk_wstring, 101];
  s := [ctk_lbrace, ctk_enum, ctk_void, ctk_int, ctk_char, ctk_float,
        ctk_double, ctk_union, ctk_struct, ctk_auto, ctk_register,
        ctk_typedef, ctk_static, ctk_extern, ctk_long, ctk_short,
        ctk_unsigned, 102, 103, 104];
  empty := true;
  conv := 3;
  sc := ctk_extern;
  while not ((token_kind = ctk_eof) or (token_kind = ctk_rbrace)) do begin
    empty := false;
    if (token_kind = ctk_rparen) or (token_kind = ctk_rbracket) then begin
      error1(58, lex_line, lex_token);
      exit;
    end;
    if token_kind in [ctk_enum, ctk_void, ctk_int, ctk_char, ctk_float,
                      ctk_double, ctk_union, ctk_struct, ctk_std_call,
                      ctk_long, ctk_short, ctk_unsigned, ctk_identifier,
                      102, 103, 104] then begin
      md.name := nil;
      md.flags := [];
      declaration_specifiers(ctx, false, res, md, conv, sc);
      if not res then begin
        error1(41, lex_line, lex_token);
        md.dtype := il_178;
      end;
    end
    else begin
      error1(41, lex_line, lex_token);
      md.dtype := il_178;
    end;
    repeat
      width.value := nil;
      if token_kind = ctk_colon then begin
        get;
        constant_expr(cs, width);
        fname.id := id_at;
        fname.line := csyn_54;
        fd := md;
      end
      else begin
        declaration(3, md, conv, fd, fname);
        if (token_kind = ctk_attribute) or (lex_token = idu_attribute) then
          parse_attributes(fd);
        type_exp(fd.dtype, addr(te));
        while te.base^.kind = 131 do begin
          t := te.base^.arr_elem;
          type_exp(t, addr(te));
        end;
        if te.base^.kind = 234 then begin
          error1(42, lex_line, fname.id);
          fd.dtype := il_178;
        end
        else if (fd.dtype = il_178) and (fd.tag <> nil) then
          error1(161, lex_line, fd.tag);
        if c_type_ptr_t(md.dtype)^.kind = 210 then
          discard(avoid_void(fd, fname, true));
        d.flags := d.flags + (fd.flags - [0, 2, 5, 12, 19]);
        if token_kind = ctk_colon then begin
          get;
          constant_expr(cs, width);
        end;
      end;
      def_fld(fl, fname, fd, kind, width);
      if token_kind <> ctk_comma then
        exit;
      get;
    until false;
    if not (token_kind in s + [ctk_rbrace, ctk_semicolon]) then
      if token_kind = ctk_identifier then begin
        nm.id := lex_token;
        nm.line := lex_line;
        sym := fnd_name(nm, false, false);
        if sym <> il_178 then
          if sym^.kind = 118 then
            error1(101, lex_line, lex_token);
      end
      else
        error1(55, lex_line, lex_token);
    if token_kind = ctk_semicolon then
      get
    else if token_kind in s - [ctk_rbrace, ctk_semicolon] then
      error1(101, lex_line, lex_token);
  end;
  get;
  if empty or ((fl.size = 0) and (fl.bitoff = 0)) then
    error0(174, lex_line);
end;

{ enum__type - enum [tag] [enumerators in braces] to d.dtype, held in the
  type d.dtype gives (int, short or char; diagnostic 204 when an
  existing tag's differs).  A tag of a structure or union is diagnostic
  24 (258 under -USRCH); with a body, a tag of another block (or, for
  the first declaration of a compound statement, ctx 4, any tag) is
  declared anew, a complete one is redefined (diagnostic 24 or 258).
  The enumerators (enum_list) give the type its constants
  (def_enum_list).

  0x063784, 0x27C bytes, link #-4128: the enumerators' record (4104
  bytes) in the frame, the type passed to enum_list through a frame
  copy.

  Not known from the original:
  - the names. }

procedure enum__type(
    ctx: integer;
    first: boolean;
    var d: c_decl_t); options(val_param); internal;
label
  body, define;
var
  es: c_enumset_t;
  nm: c_name_t;
  t: c_type_ptr_t;
  tag: c_tag_ptr_t;
  err: boolean;
  et: c_type_ptr_t;
  int_t: c_type_ptr_t;
begin
  get;
  lex_fatal := false;
  tag := nil;
  err := false;
  es.count := 0;
  et := c_type_ptr_t(il_178);
  int_t := d.dtype;
  if token_kind = ctk_identifier then begin
    nm.line := lex_line;
    nm.id := lex_token;
    d.tag := lex_token;
    get;
    tag := lookup_su(nm.id);
    if tag <> nil then begin
      if tag^.kind = ctk_enum then begin
        d.dtype := tag^.body.stype;
        et := d.dtype;
      end
      else begin
        if cargs_$options.usrch then
          error1(258, lex_line, nm.id)
        else
          error2(24, lex_line, nm.id, smcontk(81, tag^.body.name.line));
        err := true;
        d.dtype := il_178;
      end;
      if token_kind <> ctk_lbrace then begin
        if tag^.body.stype^.enum_int <> int_t then
          error2(204, lex_line, nm.id, tag^.body.stype^.enum_int);
        return;
      end;
      if (tag^.body.block = c_blk_ptr_t(il_180)) and
         not (first and (ctx = 4)) then begin
        if tag^.body.stype <> c_type_ptr_t(il_178) then
          if tag^.body.stype^.enum_list <> nil then begin
            if cargs_$options.usrch then
              error1(258, lex_line, nm.id)
            else
              error2(24, lex_line, nm.id, smcontk(81, tag^.body.name.line));
            err := true;
          end
          else if tag^.body.stype^.enum_int <> int_t then
            error2(204, lex_line, nm.id, tag^.body.stype^.enum_int);
        goto body;
      end;
    end;
    tag := def_su(nm, ctk_enum);
    if first and (ctx = 4) then
      add_su(tag, csyn_1ec)
    else
      add_su(tag, c_blk_ptr_t(il_180)^.tags);
    et := def_enum_skeleton(int_t);
    if token_kind <> ctk_lbrace then
      goto define;
  end
  else
    et := def_enum_skeleton(int_t);
body:
  if token_kind = ctk_lbrace then
    get
  else begin
    error1(99, lex_line, lex_token);
    if token_kind = ctk_semicolon then
      return;
  end;
  t := et;
  enum_list(es, t);
  if err then
    return;
define:
  def_enum_list(es, et);
  d.dtype := et;
  if tag <> nil then
    tag^.body.stype := d.dtype;
end;

{ int_ob_kind_from_integer_type - the integer constant kind of the
  integral (or enumeration) type t: 82 int, 85 unsigned, 80 short, 83
  unsigned short, 200 char, 86 unsigned char; another kind is cgerr 28
  (the result then not set).

  0x063A00, 0x88 bytes, link #-8: the message a 41-character literal
  after the routine (strtk).

  Not known from the original:
  - the names. }

function int_ob_kind_from_integer_type(
    t: c_type_ptr_t): integer; options(val_param); internal;
begin
  case t^.kind of
    122:
      if t^.len = 4 then
        if t^.signed then
          int_ob_kind_from_integer_type := 82
        else
          int_ob_kind_from_integer_type := 85
      else if t^.len = 2 then
        if t^.signed then
          int_ob_kind_from_integer_type := 80
        else
          int_ob_kind_from_integer_type := 83
      else if t^.signed then
        int_ob_kind_from_integer_type := 200
      else
        int_ob_kind_from_integer_type := 86;
    129:
      int_ob_kind_from_integer_type :=
        int_ob_kind_from_integer_type(t^.enum_int);
    otherwise
      cgerr(28, 0, strtk('int_ob_kind_from_integer_type -- bad kind', 41));
  end;
end;

{ enum_list - the enumerators up to the closing brace to es, each a constant of t
  (def_conn) with the value given (`= constant'; diagnostic 26 for a
  value not an integer constant, naming a tree's first operand) or the
  one after the last; past 1024 the last entry is overwritten
  (diagnostic 20, once).  A `)' or `]' is diagnostic 58, anything but
  `,' or the closing brace after an enumerator 55.

  0x063AB2, 0x19E bytes, link #-56; A5 (no other unit calls it): the
  value's type t's enum_int set up front in the constant's record;
  es's entry addressed from the count times 4 kept in the frame.

  Not known from the original:
  - the names. }

procedure enum_list(
    var es: c_enumset_t;
    in t: c_type_ptr_t);
var
  s: c_tokset_t;
  nm: c_name_t;
  cx: c_cexp_t;
  warn: boolean;
  v: integer32;
  n: integer;
begin
  s := [ctk_rbrace, ctk_sizeof, ctk_comma, ctk_semicolon, ctk_plus,
        ctk_minus, ctk_eof, ctk_identifier, 77..89, ctk_string,
        ctk_wstring, 101];
  warn := true;
  v := 0;
  n := 0;
  cx.ctype := t^.enum_int;
  while not ((token_kind = ctk_eof) or (token_kind = ctk_rbrace)) do begin
    if (token_kind = ctk_rparen) or (token_kind = ctk_rbracket) then begin
      error1(58, lex_line, lex_token);
      exit;
    end;
    if n < 1024 then
      n := n + 1
    else if warn then begin
      error0(20, lex_line);
      warn := false;
    end;
    identifier([ctk_rbrace, ctk_assign, ctk_comma], 117, nm);
    if token_kind = ctk_assign then begin
      get;
      constant_expr(s, cx);
      if cx.value^.kind in [77..87, 101, 200] then
        v := cx.value^.int_value
      else if cx.value^.kind = 137 then
        error1(26, lex_line, c_tree_ptr_t(cx.value)^.opnd[1])
      else
        error1(26, lex_line, cx.value);
    end;
    es.syms[n] := def_conn(nm, t,
                           smcontk(int_ob_kind_from_integer_type(t), v));
    v := v + 1;
    if not ((token_kind = ctk_comma) or (token_kind = ctk_rbrace)) then
      error1(55, lex_line, lex_token);
    if token_kind = ctk_comma then
      get;
  end;
  get;
  es.count := n;
end;

{ add_top_node - a top-level node of kind and size bytes, linked
  (c_stmt_sem's link_top).

  0x061560, 0x36 bytes, link #-12; A0.

  Not known from the original:
  - the names (c_stmt_sem has an internal routine of the same name). }

function add_top_node(
    kind: integer;
    size: integer): il_$node_ptr_t; options(val_param); internal;
var
  n: il_$node_ptr_t;
begin
  n := gspace(size);
  n^.kind := kind;
  link_top(n);
  add_top_node := n;
end;

{ body - a function's body: an opening brace, its declarations, the dynamic
  initializers (cdef_dynm_inits) evaluated after body_s, for main
  returning an integral type `main = 0' first (its block's main_int
  set), the statements and body_e at the closing brace.

  0x06508E, 0x1FA bytes, link #-100: il_d0 kept in D2 around the
  initializers (each one's line made current while it is evaluated);
  the assignment through body_opr 0 and 5 of id_main (by address),
  push_con(0) and expr_op(27) with the `=' token.

  Not known from the original:
  - the names. }

procedure body(
    in follow: c_tokset_t); internal;
var
  te: type_exp_t;
  op: c_name_t;
  top: integer;
  more: boolean;
  line: integer;
  p: c_dynm_ptr_t;
begin
  if token_kind = ctk_lbrace then begin
    lex_fatal := false;
    get;
  end
  else
    error(99, follow + [ctk_rbrace, ctk_if, ctk_switch, ctk_lbrace, ctk_do,
                        ctk_while, ctk_for, ctk_incr, ctk_decr, ctk_not,
                        ctk_goto, ctk_tilde, ctk_sizeof, ctk_return,
                        ctk_lparen, ctk_star, ctk_plus, ctk_minus, ctk_amp,
                        ctk_identifier, 77..89, ctk_string, ctk_wstring,
                        101]);
  cdef_dynm_inits := nil;
  repeat
    declaration_stmts(3, true, more);
  until not more;
  def_resolve_fwd_ptrs;
  il_d0 := lex_line;
  il_c3 := true;
  body_s;
  p := cdef_dynm_inits;
  top := cexs_23bc;
  line := il_d0;
  while p <> nil do begin
    if p^.e.line <> il_d0 then begin
      il_d0 := p^.e.line;
      il_c3 := true;
    end;
    cexs_23bc := cexs_23bc + 1;
    cexs_stack[cexs_23bc] := p^.e;
    clear_operands(top);
    p := p^.next;
  end;
  il_d0 := line;
  if (cdef_50^.kind = 108) and (cdef_50^.name.id = id_main) then begin
    type_exp(cdef_50^.result, addr(te));
    cdef_50^.bits.main_int := true;
    if te.base^.kind = 122 then begin
      top := cexs_23bc;
      body_opr(0, addr(id_main));
      body_opr(5, addr(id_main));
      push_con(0);
      op.id := lex_tokens[ctk_assign];
      op.line := lex_line;
      expr_op(27, addr(op), 2);
      clear_operands(top);
    end;
  end;
  stat_list(follow + [ctk_rbrace]);
  il_d0 := lex_line;
  il_c3 := true;
  body_e;
  if token_kind = ctk_rbrace then
    get
  else
    error(100, follow);
end;

{ stat_list - statements up to one that cannot begin a statement (case
  and default too inside a switch's body).

  0x0652A4, 0xF6 bytes, link #-312: follow + cases formed once before
  the loop (docs/rev889-patterns.md 5); the loop's test on a set of
  0..239 (the statement starters with 200) formed from cases each
  time.

  Not known from the original:
  - the names. }

procedure stat_list;
var
  fs: c_tokset_t;
  cases: c_tokset_t;
begin
  fs := follow + [ctk_if, ctk_switch, ctk_lbrace, ctk_do, ctk_while,
                  ctk_for, ctk_incr, ctk_decr, ctk_not, ctk_goto,
                  ctk_tilde, ctk_sizeof, ctk_return, ctk_colon,
                  ctk_lparen, ctk_semicolon, ctk_star, ctk_plus,
                  ctk_minus, ctk_amp, ctk_identifier, 77..89, ctk_string,
                  ctk_wstring, 101];
  cases := [];
  if csyn_1e8 <> nil then
    if csyn_1e8^.active then
      cases := [ctk_case, ctk_default];
  repeat
    stat(fs);
    check(101, fs + cases);
  until not (token_kind in cases + [ctk_if, ctk_switch, ctk_lbrace, ctk_do,
                                    ctk_while, ctk_for, ctk_incr, ctk_decr,
                                    ctk_not, ctk_goto, ctk_tilde,
                                    ctk_break, ctk_continue, ctk_sizeof,
                                    ctk_return, ctk_lparen, ctk_semicolon,
                                    ctk_star, ctk_plus, ctk_minus, ctk_amp,
                                    ctk_identifier, 77..89, ctk_string,
                                    ctk_wstring, 101, 200]);
end;

{ stat - a statement: by its first token goto, return, break and
  continue, a compound statement, if, switch, while, do, for, the empty
  statement, case and default (inside a switch's body), else an
  expression; an expression that turns out to be a label (the context
  1) defines it and the statement after it is taken.  A statement
  other than case or default makes its token and line current
  (il_cc, il_d0) and clears lex_fatal and csyn_204; all but compound,
  if, switch, while, for, case and default end with `;'.

  0x0653D4, 0x278 bytes, link #-196: the test on a set of 0..239 (the
  starters with 200, cases or-ed in); the case as a compare chain.

  Not known from the original:
  - the names; whether the label's loop was a goto. }

procedure stat;
label
  again;
var
  cases: c_tokset_t;
  top: integer;
  ctx: integer;
  lab: c_name_t;
  semi: boolean;
begin
  cases := [];
  if csyn_1e8 <> nil then
    if csyn_1e8^.active then
      cases := [ctk_case, ctk_default];
again:
  check(86, follow + cases + [ctk_if, ctk_switch, ctk_lbrace, ctk_do,
                              ctk_while, ctk_for, ctk_incr, ctk_decr,
                              ctk_not, ctk_goto, ctk_tilde, ctk_sizeof,
                              ctk_return, ctk_lparen, ctk_star, ctk_plus,
                              ctk_minus, ctk_amp, ctk_identifier, 77..89,
                              ctk_string, ctk_wstring, 101]);
  if token_kind in cases + [ctk_if, ctk_switch, ctk_lbrace, ctk_do,
                            ctk_while, ctk_for, ctk_incr, ctk_decr,
                            ctk_not, ctk_goto, ctk_tilde, ctk_break,
                            ctk_continue, ctk_sizeof, ctk_return,
                            ctk_lparen, ctk_semicolon, ctk_star, ctk_plus,
                            ctk_minus, ctk_amp, ctk_identifier, 77..89,
                            ctk_string, ctk_wstring, 101, 200] then begin
    if not (token_kind in cases) then begin
      il_cc := lex_token;
      il_d0 := lex_line;
      il_c3 := true;
      lex_fatal := false;
      csyn_204 := false;
    end;
    semi := not (token_kind in cases + [ctk_if, ctk_switch, ctk_lbrace,
                                        ctk_while, ctk_for]);
    case token_kind of
      ctk_goto:
        goto_stat(follow);
      ctk_return:
        return_stat(follow);
      ctk_break, ctk_continue:
        continue_break;
      ctk_lbrace:
        compound_stat(follow);
      ctk_if:
        if_stat(follow);
      ctk_switch:
        switch_stat(follow);
      ctk_while:
        while_stat(follow);
      ctk_do:
        do_while_stat(follow);
      ctk_for:
        for_stat(follow);
      ctk_semicolon:
        ;
      ctk_default, ctk_case:
        case_or_default_stat(follow);
      otherwise begin
        top := cexs_23bc;
        ctx := 0;
        c_expr(follow, lab, ctx);
        if ctx = 1 then begin
          def_labl(lab);
          get;
          goto again;
        end;
        clear_operands(top);
      end;
    end;
    if semi then
      if token_kind = ctk_semicolon then
        get
      else
        error(101, [ctk_if, ctk_switch, ctk_lbrace, ctk_do, ctk_while,
                    ctk_for, ctk_incr, ctk_decr, ctk_not, ctk_goto,
                    ctk_tilde, ctk_break, ctk_continue, ctk_sizeof,
                    ctk_return, ctk_lparen, ctk_semicolon, ctk_star,
                    ctk_plus, ctk_minus, ctk_amp, ctk_identifier, 77..89,
                    ctk_string, ctk_wstring, 101]);
  end;
end;

{ compound_stat - an opening brace, declarations (a scope block made when there are
  any), the dynamic initializers, the statements and the closing brace; the scope's
  end node (149) closes it.

  0x065668, 0x10C bytes, link #-20: the end node add_top_node(149, 52)
  with the scope as its block, the scope's end node and end line set
  and il_180 its enclosing block (whose x196 is cleared).

  Not known from the original:
  - the names. }

procedure compound_stat;
var
  more: boolean;
  first: boolean;
  top: integer;
  any: boolean;
  p: c_dynm_ptr_t;
  n: il_$node_ptr_t;
  line: integer;
begin
  get;
  cdef_dynm_inits := nil;
  first := true;
  any := false;
  csyn_1ec := nil;
  repeat
    declaration_stmts(4, first, more);
    any := any or more;
    first := false;
  until not more;
  def_resolve_fwd_ptrs;
  p := cdef_dynm_inits;
  top := cexs_23bc;
  while p <> nil do begin
    cexs_23bc := cexs_23bc + 1;
    cexs_stack[cexs_23bc] := p^.e;
    clear_operands(top);
    p := p^.next;
  end;
  stat_list(follow);
  if any then begin
    n := add_top_node(149, 52);
    c_top_ptr_t(n)^.blk := il_180;
    c_blk_ptr_t(il_180)^.end_node := n;
    line := lex_line;
    c_top_ptr_t(n)^.line := line;
    c_blk_ptr_t(il_180)^.end_line := line;
    il_180 := il_$node_ptr_t(c_blk_ptr_t(il_180)^.outer);
    c_blk_ptr_t(il_180)^.x196 := 0;
  end;
  if token_kind = ctk_rbrace then
    get
  else
    error(100, follow);
end;

{ if_stat - if (expression) statement [else statement]: if_s, else_s
  and endif_s around the parts, the labels in the frame; diagnostics
  103 and 104 name the `if' and the token met.

  0x065774, 0x102 bytes, link #-48.

  Not known from the original:
  - the names. }

procedure if_stat;
var
  t: il_$node_ptr_t;
  else_lab: il_$node_ptr_t;
  end_lab: il_$node_ptr_t;
begin
  t := lex_token;
  get;
  if token_kind = ctk_lparen then
    get
  else
    error2(103, lex_line, t, lex_token);
  eval_expr(follow + [ctk_rparen]);
  test_ne_zero;
  if token_kind = ctk_rparen then
    get
  else
    error2(104, lex_line, t, lex_token);
  if_s(else_lab, end_lab);
  stat(follow);
  if token_kind = ctk_else then begin
    lex_fatal := false;
    else_s(else_lab, end_lab);
    get;
    stat(follow);
  end;
  endif_s(else_lab, end_lab);
end;

{ case_or_default_stat - case constant-expression : (case_con, its value
  pushed) or default : (diagnostic 107 for a second), then
  case_default of the innermost switch.

  0x065884, 0x102 bytes, link #-56: the two case_default calls share
  their tail (docs/rev889-patterns.md 23).

  Not known from the original:
  - the names. }

procedure case_or_default_stat;
var
  cx: c_cexp_t;
begin
  if token_kind = ctk_case then begin
    get;
    constant_expr(follow + [ctk_colon], cx);
    case_con(cx, csyn_1e8^.c, true);
    if token_kind = ctk_colon then
      get
    else
      error1(105, lex_line, lex_token);
    case_default(csyn_1e8^.c, false);
  end
  else if token_kind = ctk_default then begin
    get;
    if csyn_1e8^.has_default then
      error0(107, lex_line);
    csyn_1e8^.has_default := true;
    if token_kind = ctk_colon then
      get
    else
      error1(105, lex_line, lex_token);
    case_default(csyn_1e8^.c, true);
  end;
end;

{ switch_stat - switch (expression) followed by `;', a braced body
  (declarations, a scope block made when there are any, diagnostic 129
  for dynamic initializers there; the statements, the pending label
  defined at the end) or a single case or default statement
  (diagnostic 106 for anything else).  The selector must be integral,
  an enumeration or a pointer (diagnostic 43; its type then il_178).

  0x065A26, 0x2BC bytes, link #-124: push_switch first, pop_switch
  last; case_s and case_e take the switch record's +8.

  Not known from the original:
  - the names; whether the exits to case_e were gotos. }

procedure switch_stat;
label
  done;
var
  t: il_$node_ptr_t;
  more: boolean;
  first: boolean;
  fs: c_tokset_t;
  braces: boolean;
  any: boolean;
  n: il_$node_ptr_t;
  line: integer;

  { push_switch - csyn_1e8 a fresh switch record (one kept from an
    earlier switch at this depth when there is one), active.

    0x065994, 0x76 bytes, link #-8.

    Not known from the original:
    - the names. }

  procedure push_switch;
  begin
    if csyn_1e8 = nil then begin
      csyn_1e8 := gspace(124);
      csyn_1e8^.next := nil;
      csyn_1e8^.prev := nil;
    end
    else if csyn_1e8^.active then
      if csyn_1e8^.next = nil then begin
        csyn_1e8^.next := gspace(124);
        csyn_1e8^.next^.prev := csyn_1e8;
        csyn_1e8 := csyn_1e8^.next;
        csyn_1e8^.next := nil;
      end
      else
        csyn_1e8 := csyn_1e8^.next;
    csyn_1e8^.active := true;
    csyn_1e8^.has_default := false;
  end;

  { pop_switch - the innermost switch no longer active; csyn_1e8 the
    enclosing one when there is one.

    0x065A0A, 0x1C bytes, no frame.

    Not known from the original:
    - the names. }

  procedure pop_switch;
  begin
    csyn_1e8^.active := false;
    if csyn_1e8^.prev <> nil then
      csyn_1e8 := csyn_1e8^.prev;
  end;

begin
  push_switch;
  fs := follow + [ctk_if, ctk_switch, ctk_lbrace, ctk_do, ctk_while,
                  ctk_for, ctk_incr, ctk_decr, ctk_not, ctk_goto,
                  ctk_tilde, ctk_sizeof, ctk_return, ctk_colon,
                  ctk_lparen, ctk_semicolon, ctk_star, ctk_amp,
                  ctk_identifier, 77..89, ctk_string, ctk_wstring, 101];
  braces := false;
  any := braces;
  t := lex_token;
  get;
  if token_kind = ctk_lparen then
    get
  else
    error2(103, lex_line, t, lex_token);
  eval_expr(follow + [ctk_rparen]);
  if token_kind = ctk_rparen then
    get
  else
    error2(104, lex_line, t, lex_token);
  with cexs_stack[cexs_23bc] do
    if (typ.base^.kind <> 130) and (typ.base^.kind <> 122) and
       (typ.base^.kind <> 129) then begin
      error0(43, lex_line);
      typ.base := c_type_ptr_t(il_178);
    end;
  case_s(csyn_1e8^.c);
  if token_kind = ctk_semicolon then
    get
  else begin
    if token_kind = ctk_lbrace then begin
      get;
      braces := true;
      if token_kind = ctk_rbrace then begin
        get;
        goto done;
      end;
    end;
    if braces then begin
      cdef_dynm_inits := nil;
      first := true;
      repeat
        declaration_stmts(4, first, more);
        any := any or more;
        first := false;
      until not more;
      def_resolve_fwd_ptrs;
      if cdef_dynm_inits <> nil then
        error0(129, lex_line);
      if token_kind = ctk_rbrace then begin
        get;
        goto done;
      end;
    end;
    if token_kind <> ctk_eof then
      if braces then begin
        stat_list(fs + [ctk_break] + [ctk_rbrace, ctk_if, ctk_switch,
                                      ctk_lbrace, ctk_do, ctk_while,
                                      ctk_case, ctk_for, ctk_incr,
                                      ctk_decr, ctk_not, ctk_goto,
                                      ctk_tilde, ctk_sizeof, ctk_return,
                                      ctk_default, ctk_colon, ctk_lparen,
                                      ctk_semicolon, ctk_star, ctk_amp,
                                      ctk_eof, ctk_identifier, 77..89,
                                      ctk_string, ctk_wstring, 101]);
        def_def_label;
        if token_kind = ctk_rbrace then
          get;
      end
      else if (token_kind = ctk_case) or (token_kind = ctk_default) then begin
        case_or_default_stat(fs);
        stat(follow);
      end
      else
        error1(106, lex_line, lex_token);
  end;
done:
  case_e(csyn_1e8^.c);
  if any then begin
    n := add_top_node(149, 52);
    c_top_ptr_t(n)^.blk := il_180;
    c_blk_ptr_t(il_180)^.end_node := n;
    line := lex_line;
    c_top_ptr_t(n)^.line := line;
    c_blk_ptr_t(il_180)^.end_line := line;
    il_180 := il_$node_ptr_t(c_blk_ptr_t(il_180)^.outer);
    c_blk_ptr_t(il_180)^.x196 := 0;
  end;
  pop_switch;
end;

{ while_stat - while (expression) statement: while_label, while_s
  after the condition, while_e.

  0x065D0C, 0xE8 bytes, link #-56.

  Not known from the original:
  - the names. }

procedure while_stat;
var
  t: il_$node_ptr_t;
begin
  t := lex_token;
  get;
  while_label;
  if token_kind = ctk_lparen then
    get
  else
    error2(103, lex_line, t, lex_token);
  eval_expr(follow + [ctk_rparen]);
  test_ne_zero;
  if token_kind = ctk_rparen then
    get
  else
    error2(104, lex_line, t, lex_token);
  while_s;
  stat(follow + [ctk_break, ctk_continue]);
  while_e;
end;

{ do_while_stat - do statement while (expression): repeat_s, repeat_e;
  the `while' made the current token and line (il_cc, il_d0) before
  the condition (il_178 named in diagnostics 103 and 104 when it is
  missing, diagnostic 110).

  0x065E02, 0x140 bytes, link #-72.

  Not known from the original:
  - the names. }

procedure do_while_stat;
var
  t: il_$node_ptr_t;
begin
  repeat_s;
  get;
  stat(follow + [ctk_while, ctk_break, ctk_continue]);
  if token_kind = ctk_while then begin
    t := lex_token;
    get;
  end
  else begin
    t := il_178;
    error(110, follow + [ctk_lparen]);
  end;
  il_cc := lex_token;
  il_d0 := lex_line;
  il_c3 := true;
  if token_kind = ctk_lparen then
    get
  else
    error2(103, lex_line, t, lex_token);
  eval_expr(follow + [ctk_rparen]);
  test_ne_zero;
  if token_kind = ctk_rparen then
    get
  else
    error2(104, lex_line, t, lex_token);
  repeat_e;
end;

{ for_stat - for (init; condition; step) statement: the initializer's
  operands cleared at once, for_start_lab, the condition (1 when
  omitted) and for_s, the step parsed now and its operands cleared
  after the statement and for_next_lab, for_e.

  0x065F5E, 0x1F6 bytes, link #-88: the step's stack top kept in the
  initializer's word (-10).

  Not known from the original:
  - the names. }

procedure for_stat;
var
  t: il_$node_ptr_t;
  top: integer;
begin
  t := lex_token;
  get;
  if token_kind = ctk_lparen then
    get
  else
    error2(103, lex_line, t, lex_token);
  if token_kind = ctk_semicolon then
    get
  else begin
    top := cexs_23bc;
    eval_expr(follow + [ctk_semicolon]);
    clear_operands(top);
    if token_kind = ctk_semicolon then
      get
    else
      error1(111, lex_line, lex_token);
  end;
  for_start_lab;
  if token_kind = ctk_semicolon then begin
    push_con(1);
    test_ne_zero;
    get;
  end
  else begin
    eval_expr(follow + [ctk_semicolon]);
    test_ne_zero;
    if token_kind = ctk_semicolon then
      get
    else
      error1(111, lex_line, lex_token);
  end;
  for_s;
  top := cexs_23bc;
  if token_kind = ctk_rparen then
    get
  else begin
    eval_expr(follow + [ctk_rparen]);
    if token_kind = ctk_rparen then
      get
    else
      error2(104, lex_line, t, lex_token);
  end;
  stat(follow + [ctk_break, ctk_continue]);
  for_next_lab;
  clear_operands(top);
  for_e;
end;

{ call_kfold - see c_externs.ins.pas.

  0x066162, 0x2A bytes, link #0: the parent nil passed by address (a
  longword 0 after the routine, 0x06618C). }

procedure call_kfold;
begin
  kfold(nil, n);
end;

{ call_kfold_fold_addrs - fold the tree n, address constants too
  (kfold_$general with no parent and addrs set): constant_expr passes
  it to cc_walk_it under -XANSI (`move.l #0x066190,-(SP)').

  0x066190, 0x2C bytes, link #-4.

  Not known from the original:
  - the names. }

procedure call_kfold_fold_addrs(
    var n: il_$node_ptr_t);
begin
  kfold_$general(nil, n, true);
end;

{ cc_walk_it - see c_externs.ins.pas.  By kind: 151, 148, 150 and 141
  their +48; 144 and 140 +64 and +68; 142 +48 and +56; 139 its
  operands; the tree nodes 137, 143, 138 their operands (for 51..53 the
  first, then as the constant first operand decides: `&&' of 0 is 0,
  `||' of -1, 1 or 255 is 1, `?:' takes the second or third operand,
  whose operands are walked; else the rest); 146, 147, 205 +24 and +28;
  145 +24, +28 and +36; 175 +16 and +20; 164 +20 and +24; 149 and
  others nothing.

  0x0661BC, 0x420 bytes, link #-8: the walker called with `jsr (A0)';
  the constant kinds a 26-byte set (0x0612AA: 77..87, 101, 200;
  docs/dpc-gaps.md 8); `&&' and `||' take the second operand's string
  at its second character where the first is taken at its first.

  Not known from the original:
  - the names; why the second operand's string is read at its second
    character. }

procedure cc_walk_it;
var
  i: integer;
  t1: il_$node_ptr_t;
  v: integer32;
begin
  if t = nil then
    return;
  if pre then
    walker^(t);
  case t^.kind of
    149:
      ;
    151, 148, 150, 141:
      cc_walk_it(t^.xp[12], walker, pre);
    144, 140: begin
      cc_walk_it(t^.xp[16], walker, pre);
      cc_walk_it(t^.xp[17], walker, pre);
    end;
    142: begin
      cc_walk_it(t^.xp[12], walker, pre);
      cc_walk_it(t^.xp[14], walker, pre);
    end;
    139:
      for i := 1 to c_top_ptr_t(t)^.eval_count do
        cc_walk_it(c_top_ptr_t(t)^.eval_opnd[i], walker, pre);
    137, 143, 138:
      with c_tree_ptr_t(t)^ do
        if (op = 51) or (op = 53) or (op = 52) then begin
          cc_walk_it(opnd[1], walker, pre);
          if (opnd[1]^.kind = 92) and (opnd[1]^.str_len = 1) then
            opnd[1] := smcontk(81, ord(opnd[1]^.str_chars[1]));
          t1 := opnd[1];
          if t1^.kind in [77..87, 101, 200] then
            case op of
              53:
                if t1^.int_value = 0 then
                  t := smcontk(81, 0)
                else begin
                  cc_walk_it(opnd[2], walker, pre);
                  if (opnd[2]^.kind = 92) and (opnd[2]^.str_len = 2) then
                    opnd[2] := smcontk(81, ord(opnd[2]^.str_chars[2]));
                end;
              52: begin
                v := t1^.int_value;
                if (v = -1) or (v = 1) or (v = 255) then
                  t := smcontk(81, 1)
                else begin
                  cc_walk_it(opnd[2], walker, pre);
                  if (opnd[2]^.kind = 92) and (opnd[2]^.str_len = 2) then
                    opnd[2] := smcontk(81, ord(opnd[2]^.str_chars[2]));
                end;
              end;
              51: begin
                v := t1^.int_value;
                if v = 0 then
                  t := opnd[3]
                else if (v = -1) or (v = 1) or (v = 255) then
                  t := opnd[2];
                if (t^.kind = 143) or (t^.kind = 137) then
                  for i := 1 to c_tree_ptr_t(t)^.count do
                    cc_walk_it(c_tree_ptr_t(t)^.opnd[i], walker, pre);
              end;
            end
          else
            for i := 2 to count do
              cc_walk_it(opnd[i], walker, pre);
        end
        else
          for i := 1 to count do
            cc_walk_it(opnd[i], walker, pre);
    146, 147, 205: begin
      cc_walk_it(t^.xp[6], walker, pre);
      cc_walk_it(t^.xp[7], walker, pre);
    end;
    145: begin
      cc_walk_it(t^.xp[6], walker, pre);
      cc_walk_it(t^.xp[7], walker, pre);
      cc_walk_it(t^.xp[9], walker, pre);
    end;
    175: begin
      cc_walk_it(t^.xp[4], walker, pre);
      cc_walk_it(t^.xp[5], walker, pre);
    end;
    164: begin
      cc_walk_it(t^.xp[5], walker, pre);
      cc_walk_it(t^.xp[6], walker, pre);
    end;
    otherwise
      ;
  end;
  if not pre then
    walker^(t);
end;

{ constant_expr - a constant expression (a conditional expression) to
  cx: its type, its constant node, what diagnostics name and the line
  it began on.  Under -XANSI the tree is folded with address constants
  (cc_walk_it with call_kfold_fold_addrs); a one-character string is
  its character; a function or an array is taken by address (expr_op
  17 with the `&' token).  Address constants are recognized: a variable
  plus or minus a constant (op 1, 2) becomes one displaced node
  (add_dn); through conversions (op 17, 39) and index (op 13) an
  address (op 26) of a displaced variable (145) is folded into one.
  Anything else not a constant (73, 77..89, 101, 156, 200), nor kinds
  163 and 195, is diagnostic 96 and il_178.

  0x0665DC, 0x3AA bytes, link #-56: cx's address kept in D4, the stack
  entry's in D5; add_dn's first two arguments the same pointer (`move.l
  (SP),-(SP)'); the conversion loop's arms tested in turn (op 26 and a
  folded index leave at once, op 17 and a non-constant index leave the
  loop for the test; an index of a constant on something other than a
  variable's address tests again unchanged).

  Not known from the original:
  - the names; the structure of the address loop (an index of a
    constant whose operand is not a variable's address loops for ever). }

procedure constant_expr;
label
  done;
var
  amp: c_name_t;
  lab: c_name_t;
  ctx: integer;
  line: integer;
  e: ^c_exp_t;
  n: il_$node_ptr_t;
  s: il_$node_ptr_t;
  v: integer32;
begin
  line := lex_line;
  ctx := 2;
  cond_expr(follow, lab, ctx);
  if cargs_$options.xansi then begin
    adjust_uc(cexs_stack[cexs_23bc].node, 1);
    cc_walk_it(cexs_stack[cexs_23bc].node, addr(call_kfold_fold_addrs),
               false);
    adjust_uc(cexs_stack[cexs_23bc].node, -1);
  end;
  e := addr(cexs_stack[cexs_23bc]);
  if (e^.node^.kind = 92) and (e^.node^.str_len = 1) then
    cexs_stack[cexs_23bc].node := smcontk(81, ord(e^.node^.str_chars[1]));
  if e^.typ.base^.kind in [108, 127, 234, 131] then begin
    amp.id := lex_tokens[ctk_amp];
    amp.line := line;
    expr_op(17, addr(amp), 1);
  end;
  n := e^.node;
  s := e^.sym;
  if s^.kind = 76 then
    s := il_$node_ptr_t(s^.idnt_unused_8);
  if (n^.kind = 163) or (n^.kind = 195) then
    goto done;
  if n^.kind = 137 then begin
    with c_tree_ptr_t(n)^ do
      if ((op = 2) or (op = 1)) and
         (opnd[2]^.kind in [77..87, 101, 200]) and
         (opnd[1]^.kind = 137) and
         (c_tree_ptr_t(opnd[1])^.opnd[1]^.kind = 109) then begin
        cexs_23bc := cexs_23bc + 1;
        v := opnd[2]^.int_value;
        if op = 2 then
          v := -v;
        cexs_stack[cexs_23bc].node :=
          add_dn(c_tree_ptr_t(opnd[1])^.opnd[1],
                 integer32(c_tree_ptr_t(opnd[1])^.opnd[1]), v);
        amp.id := lex_tokens[ctk_amp];
        amp.line := line;
        expr_op(17, addr(amp), 1);
        n := cexs_stack[cexs_23bc].node;
        cexs_23bc := cexs_23bc - 1;
        goto done;
      end;
      while c_tree_ptr_t(n)^.op in [13, 17, 39, 26] do
        with c_tree_ptr_t(n)^ do begin
          if op = 26 then begin
            if opnd[1]^.kind = 145 then
              if (opnd[1]^.xp[7]^.kind = 109) and
                 (opnd[1]^.xp[9]^.kind = 81) then
                opnd[1] := add_dn(opnd[1]^.xp[7],
                                  integer32(opnd[1]^.xp[7]),
                                  opnd[1]^.xp[9]^.int_value);
            goto done;
          end;
          if op = 17 then begin
            n := opnd[1];
            exit;
          end;
          if op = 13 then begin
            if not (opnd[2]^.kind in [77..87, 101, 200]) then
              exit;
            if (opnd[1]^.kind = 154) and (s^.kind = 109) then begin
              cexs_23bc := cexs_23bc + 1;
              v := opnd[2]^.int_value - c_sym_ptr_t(s)^.var_offset;
              cexs_stack[cexs_23bc].node := add_dn(s, integer32(s), v);
              amp.id := lex_tokens[ctk_amp];
              amp.line := line;
              expr_op(17, addr(amp), 1);
              n := cexs_stack[cexs_23bc].node;
              cexs_23bc := cexs_23bc - 1;
              goto done;
            end;
          end;
          if op = 39 then
            n := opnd[1];
        end;
    end;
  if not (n^.kind in [73, 77..89, 101, 156, 200]) then begin
    error1(96, line, e^.sym);
    n := il_178;
    e^.sym := n;
    e^.typ.base := c_type_ptr_t(il_178);
  end;
done:
  cx.ctype := e^.typ.base;
  cx.value := n;
  cx.sym := e^.sym;
  cx.line := line;
  cexs_23bc := cexs_23bc - 1;
end;

{ continue_break - break or continue (nxtext_s), then the next token.

  0x0669A0, 0x14 bytes, link #-4. }

procedure continue_break; internal;
begin
  nxtext_s;
  get;
end;

{ return_stat - return [expression] ;: in a function, the expression
  assigned to its result variable (`=' through expr_op 27; a reference
  result (a pointer with ptr_reference under -TYPE) through
  init_refvar); a value returned from a void function is diagnostic
  108 and skipped to `;'.  Then return_s.

  0x0669B4, 0x146 bytes, link #-60: the result variable's name (its
  +4..+11) copied to the frame and passed by address to body_opr 0 and
  5; the void test's loop `(token_kind = ctk_eof) or (token_kind =
  ctk_semicolon)' evaluated whole.

  Not known from the original:
  - the names. }

procedure return_stat;
var
  t: c_type_ptr_t;
  top: integer;
  nm: c_name_t;
  op: c_name_t;
begin
  get;
  if (cdef_50^.kind = 108) and (token_kind <> ctk_semicolon) then begin
    t := cdef_50^.result;
    while t^.kind = 118 do
      t := c_sym_ptr_t(t)^.td_type;
    if t^.kind = 210 then begin
      error1(108, lex_line, lex_token);
      while not ((token_kind = ctk_eof) or (token_kind = ctk_semicolon)) do
        get;
    end
    else begin
      top := cexs_23bc;
      with cdef_50^.ret_var^ do begin
        nm.id := name;
        nm.line := line;
        nm.uplevel := uplevel;
        nm.unused_7 := unused_11;
      end;
      body_opr(0, addr(nm));
      body_opr(5, addr(nm));
      eval_expr(follow + [ctk_semicolon]);
      if cargs_$options.type_opt then
        if t^.kind = 130 then
          if t^.ptr_reference then
            init_refvar(t);
      op.id := lex_tokens[ctk_assign];
      op.line := lex_line;
      expr_op(27, addr(op), 2);
      clear_operands(top);
    end;
  end;
  return_s;
end;

{ goto_stat - goto label: the identifier (87 when there is none: the
  label il_178) and goto_s.

  0x066AFA, 0x58 bytes, link #-16: the pair at -16 (its line set
  first). }

procedure goto_stat(
    in follow: c_tokset_t); internal;
var
  nm: c_name_t;
begin
  get;
  nm.line := lex_line;
  if token_kind = ctk_identifier then begin
    nm.id := lex_token;
    get;
  end
  else begin
    error(87, follow);
    nm.id := il_178;
  end;
  goto_s(nm);
end;

{ clear_operands - evaluate the expression stack's entries above top as
  statements, popping them: each tree folded under -XANSI (cc_walk_it
  with call_kfold, its use count raised around it), a one-character
  string made its character, lowered by walk_tree, a call (137, op 16)
  made a statement (call_s).

  0x066B52, 0x128 bytes, link #-12: cexs_23bc's address kept in A3,
  cargs_$options' byte in D4; the loop's test `top < cexs_23bc'.

  Not known from the original:
  - the names. }

procedure clear_operands;
begin
  while top < cexs_23bc do begin
    if cargs_$options.xansi then begin
      adjust_uc(cexs_stack[cexs_23bc].node, 1);
      cc_walk_it(cexs_stack[cexs_23bc].node, addr(call_kfold), false);
      adjust_uc(cexs_stack[cexs_23bc].node, -1);
    end;
    with cexs_stack[cexs_23bc] do
      if (node^.kind = 92) and (node^.str_len = 1) then
        node := smcontk(81, ord(node^.str_chars[1]));
    cexs_stack[cexs_23bc].node :=
      walk_tree(cexs_stack[cexs_23bc].node, nil, nil);
    with cexs_stack[cexs_23bc] do
      if node^.kind = 137 then
        if c_tree_ptr_t(node)^.op = 16 then
          call_s;
    cexs_23bc := cexs_23bc - 1;
  end;
end;

{ init_refvar - the value on the expression stack's top bound to the
  reference type t (a pointer with ptr_reference): coerced to the type
  t points to (with its const and volatile; diagnostic 70), copied to a
  temporary (temp_alloc) when it is not an lvalue (diagnostic 123 when
  the stack is full), then its address taken (expr_op 17 with the `&'
  token).

  0x066C7A, 0x1DA bytes, link #-48: te's two flags from the pointer's
  attribute bits 19 and 0 (`btst; sne; lsr.b #7; lsl.b'); temp_alloc's
  size the low word of the top entry's typ.bytes.

  Not known from the original:
  - the names. }

procedure init_refvar;
var
  nm: c_name_t;
  te: type_exp_t;
  rlen: integer;
  v: il_$node_ptr_t;
begin
  nm.line := lex_line;
  type_exp(t^.ptr_to, addr(te));
  te.flags.b25_5 := 19 in t^.ptr_attr.bits;
  te.flags.b25_4 := 0 in t^.ptr_attr.bits;
  if not coerce(te, cexs_23bc, true) then
    error3(70, nm.line, cexs_stack[cexs_23bc].sym,
           cexs_stack[cexs_23bc - 1].sym, lex_tokens[ctk_assign]);
  if not_an_lvalue(true) then begin
    nm.id := lex_tokens[ctk_assign];
    rlen := get_rlen(cexs_stack[cexs_23bc].typ);
    v := temp_alloc(cexs_stack[cexs_23bc].typ.bytes, rlen);
    if cexs_23bc < 128 then
      cexs_stack[cexs_23bc + 1] := cexs_stack[cexs_23bc]
    else
      error3(123, lex_line, c_blk_ptr_t(il_180)^.name.id,
             smcontk(81, 129), smcontk(81, 128));
    cexs_23bc := cexs_23bc - 1;
    body_opr(1, addr(c_sym_ptr_t(v)^.name));
    body_opr(5, addr(c_sym_ptr_t(v)^.name));
    cexs_23bc := cexs_23bc + 1;
    expr_op(27, addr(nm), 2);
  end;
  nm.id := lex_tokens[ctk_amp];
  expr_op(17, addr(nm), 1);
end;

{ pp_constant - the value of a preprocessor #if's constant expression
  (c_lex_pp): an integer constant's value, a real's 1 when it is not
  zero, 0 for an identifier (73); anything not a constant is
  diagnostic 96 (0).

  0x066E54, 0x96 bytes, link #-40: the follow set copied from a
  constant to the frame; the real's test `jsr fpp_$' with 0x0074
  0xFF34 then `beq' (docs/rev889-patterns.md 19); the kinds 89 then
  88 tested.

  Not known from the original:
  - the names. }

function pp_constant;
var
  cx: c_cexp_t;
  s: c_tokset_t;
  v: integer32;
begin
  s := [ctk_sizeof, ctk_semicolon, ctk_plus, ctk_minus, ctk_eof,
        ctk_identifier, 77..89, ctk_string, ctk_wstring, 101];
  constant_expr(s, cx);
  v := 0;
  if not (cx.value^.kind in [73, 77..89, 101, 200]) then
    error1(96, lex_line, cx.sym)
  else
    case cx.value^.kind of
      73:
        ;
      89, 88:
        if cx.value^.real_value <> 0.0 then
          v := 1;
      otherwise
        v := cx.value^.int_value;
    end;
  pp_constant := v;
end;
