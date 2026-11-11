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

  Translated so far: initialize_legal_specs, error, warning, check,
  type_qualifiers, int_ob_kind_from_integer_type, add_top_node,
  call_kfold, call_kfold_fold_addrs, cc_walk_it, continue_break,
  goto_stat.  The other routines (syntax, program_,
  the declarations', the initializers', the statements', constant_expr,
  pp_constant, abstract_decl, c_type_name, data_init) are not written
  yet: syntax (0x0609D8) clears cdef_fwd_ptrs, enters the nine
  keywords below with idntk(76, ...), sets csyn_44 to il_178, calls
  initialize_legal_specs(-XANSI) and program_.  The headings of the
  routines not written (c_externs.ins.pas, c_syntax.ins.pas) are still
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

var
  legal_specs: array [0..12] of integer;  { +0x0 }
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

{ initialize_legal_specs - the type specifiers' legal combinations,
  one word per specifier (+0x4: 0 under -XANSI, else 32).

  0x060B38, 0x5E bytes, no frame (docs/rev889-patterns.md 16): the
  words stored in turn, +0x4 last.

  Not known from the original:
  - the names; the words' meaning (the specifiers each may join, for
    type_specifier's check_add_spec). }

procedure initialize_legal_specs(
    xansi: boolean); options(val_param); internal;
begin
  legal_specs[0] := 192;
  legal_specs[1] := 240;
  legal_specs[3] := 32;
  legal_specs[4] := 194;
  legal_specs[5] := 202;
  legal_specs[6] := 51;
  legal_specs[7] := 51;
  legal_specs[8] := 0;
  legal_specs[9] := 0;
  legal_specs[10] := 49;
  legal_specs[11] := 0;
  legal_specs[12] := 0;
  if xansi then
    legal_specs[2] := 0
  else
    legal_specs[2] := 32;
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

{ call_kfold - see c_externs.ins.pas.

  0x066162, 0x2A bytes, link #0: the parent nil passed by address (a
  longword 0 after the routine, 0x06618C). }

procedure call_kfold;
begin
  kfold(nil, n);
end;

{ call_kfold_fold_addrs - fold the tree n, address constants too
  (kfold_$general with no parent and addrs set).

  0x066190, 0x2C bytes, link #-4.

  Not known from the original:
  - the names; who uses it (no instruction of either binary takes its
    address). }

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

{ continue_break - break or continue (nxtext_s), then the next token.

  0x0669A0, 0x14 bytes, link #-4. }

procedure continue_break; internal;
begin
  nxtext_s;
  get;
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
