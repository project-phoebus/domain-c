{ c_expr_syn - the expression parser: one routine for each precedence
  level of C's expressions (c_expr, asn_expr, cond_expr, log_or_expr
  ... multip_expr, unary_expr, primary_expr), each taking the follow
  set, skipping to it after a diagnostic, and handing each operand and
  operator to the expression semantics (c_expr_sem's body_opr,
  expr_op) as it is recognized; and the builtin functions
  (_builtin_fabs ... _builtin_strncat), whose calls expr_op is given
  their own operator codes.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x04FDFC  0x05007C  c_expr_syn_$begin_compilation
    0x04FCF0  0x04FF70  alloc_builtins
    0x0503BC  0x05063C  error
    0x05044A  0x0506CA  check
    0x05047C  0x0506FC  swap_top
    0x0504E0  0x050760  get_builtin_func
    0x050526  0x0507A6  cast_int_const
    0x0506B0  0x050930  not_an_lvalue
    0x050792  0x050A12  test_side_effects
    0x0507A2  0x050A22  do_c_string
    0x05090E  0x050B8E  identifier
    0x050962  0x050BE2  func_call_stat
    0x050DCC  0x05104C  primary_expr
    0x051650  0x0518D0  unary_expr
    0x052248  0x0524C8  multip_expr
    0x05234C  0x0525CC  addit_expr
    0x05243A  0x0526BA  shift_expr
    0x05252A  0x0527AA  rel_expr
    0x05265E  0x0528DE  eq_expr
    0x05274C  0x0529CC  bit_and_expr
    0x052828  0x052AA8  bit_eor_expr
    0x052904  0x052B84  bit_ior_expr
    0x0529E0  0x052C60  log_and_expr
    0x052AC0  0x052D40  log_or_expr
    0x052BA0  0x052E20  cond_expr
    0x052CD4  0x052F54  asn_expr
    0x052DE4  0x053064  c_expr
    0x052EC8  0x053148  eval_expr
    A5 0x142470 (cc.m68k), 0x2C2470 (cc.a88k): the builtins' table,
    17 entries of 10 bytes at +0x0..+0xA9 (the module's data is 0xB0
    bytes).

  The routines c_syntax and c_main call (begin_compilation,
  not_an_lvalue, identifier, cond_expr, asn_expr, c_expr, eval_expr)
  load A5; the others are internal.  alloc_builtins is nested in
  begin_compilation (it comes first in the image).

  The expression stack (c_expr_sem's cexs_stack, cexs_23bc the top) is
  read and changed directly (c_objtype.ins.pas's c_exp_t).  The
  parsing levels' parameters are described in c_expr_syn.ins.pas.

  The operator codes passed to expr_op: 0 ==, 1 !=, 2 <=, 3 >=, 4 <,
  5 >, 8 +, 9 -, 11 *, 12 /, 14 %, 16 !, 17 & (address), 18 a call,
  19 a subscript of a non-pointer, 20 unary +, 21 unary -, 22 an
  argument or a cast, 24 ?:, 25 ||, 26 &&, 27 = (and the compound
  assignments and prefix ++ and --, the token in the name telling
  which), 28 postfix ++ and --, 29 <<, 30 >>, 33 &, 34 |, 44 the comma,
  45 ^, 46 ~, 0x20..0x3D the builtins.  body_opr's: 1 a name, 3 a
  dereference, 4 a member, 5 an rvalue, 6 a real constant, 7 a string's
  array, 8 an integer constant.

  Probable slip of the original kept: unary_expr's increment tests the
  operand's node, not its type, for kind 130 (docs/questions.md).
}
module c_expr_syn;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/externals.ins.pas';
%include 'lang/lang/source/fop.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/c_compiler/source/c_syntax.ins.pas';
%include 'lang/c_compiler/source/c_expr_syn.ins.pas';

type
  { A builtin function: its symbol (blk_fnd_name's), its type (234)
    and the operator code expr_op is given for its calls (10 bytes;
    the table is indexed 10 * i: `add.w; lsl.w #2; add.w'). }
  builtin_t = record
    sym: il_$node_ptr_t;                { +0 }
    ftype: c_type_ptr_t;                { +4 }
    code: integer;                      { +8 }
  end;

var
  builtins: array [0..16] of builtin_t; { +0x0 }

{ c_expr_syn_$begin_compilation - make the builtin functions.

  0x04FDFC, 0x4D0 bytes, link #-252 (-252: alloc_builtins' result, 10
  bytes, copied to the table entry with two `move.l' and a `move.w').
  The parameter lists in registers: (double) A4, (double, double) D2,
  (char *, const char *) D3, (char *, const char *, unsigned) D4,
  (const char *, const char *) D5, (const char *, const char *,
  unsigned) D6, (const char *) A3; the const char pointer (A2) gets
  attribute bit 19 (`move.l #0x80000, (16,A2)': the whole set).  The
  entries in order: fabs, sin, cos, tan, log, exp, atan, atan2, pow,
  sqrt (doubles; codes 0x20, 0x29, 0x26, 0x35, 0x34, 0x27, 0x25, 0x33,
  0x36, 0x2A), strncpy, strcpy (char *; 0x3C, 0x3B), strcmp, strncmp
  (int; 0x39, 0x3A), strlen (0x3D), strcat, strncat (char *; 0x37,
  0x38), each named `_builtin_' and the function (idntk(76, ...)).  The
  result kind and the code are pushed as one longword (`pea 0x20',
  `move.l #65596').

  Not known from the original:
  - the locals' names; whether the table was filled by a loop over
    constants (the image has 17 calls). }

procedure c_expr_syn_$begin_compilation;
var
  dbl1, dbl2, cpy, ncpy, cmp, ncmp, len: c_parlist_ptr_t;
  ccp, cp: c_type_ptr_t;

  { alloc_builtins - a builtin: a function type (234) returning double
    (kind 0), char * (1), int (2) or size_t (3: unsigned under -XANSI,
    else int) with the parameters params, its block (def_blk_skeleton
    108, 2, ..., the parameters, false, 3) and its symbol.

    0x04FCF0, 0x10C bytes, link #-56; the result's address at (8,A6)
    (a function of a record).  The kind by a jump table of 4 (no
    otherwise: `cmpi.w #4; bcc').  The name (-48) and the declaration
    (-40, c_decl_t: the result type, il_178, line 0) are frame records;
    blk_fnd_name looks the name up in il_180.  +24 of the type is 3,
    +4 cleared.

    Not known from the original:
    - the parameters' and locals' names; whether the result was built
      in a local (here b) or field by field. }

  function alloc_builtins(
      name: il_$node_ptr_t;
      params: c_parlist_ptr_t;
      kind: integer;
      code: integer): builtin_t; options(val_param);
  var
    ft: c_type_ptr_t;
    fname: c_name_t;
    decl: c_decl_t;
    b: builtin_t;
  begin
    ft := gspace(58);
    ft^.kind := 234;
    case kind of
      0: ft^.fn_result := double_type;
      1: ft^.fn_result := def_ptr(char_type, nil);
      2: ft^.fn_result := int_type;
      3: if cargs_$options.xansi then
           ft^.fn_result := cexs_23b4
         else
           ft^.fn_result := int_type;
    end;
    ft^.fn_conv := 3;
    ft^.fn_params := params;
    ft^.fn_unused_4 := 0;
    fname.line := 0;
    fname.id := name;
    decl.dtype := ft^.fn_result;
    decl.name := il_178;
    decl.line := 0;
    decl.flags := [];
    def_blk_skeleton(108, addr(fname), 2, addr(decl), nil, params, false,
                     3, 0, nil);
    b.sym := blk_fnd_name(addr(fname), false, false, il_180);
    b.ftype := ft;
    b.code := code;
    alloc_builtins := b;
  end;

begin
  dbl1 := gspace(8);
  dbl1^.count := 1;
  dbl1^.types[1] := double_type;
  dbl2 := gspace(12);
  dbl2^.count := 2;
  dbl2^.types[1] := double_type;
  dbl2^.types[2] := double_type;
  ccp := def_ptr(char_type, nil);
  ccp^.ptr_attr.bits := [19];
  cp := def_ptr(char_type, nil);
  cpy := gspace(12);
  cpy^.count := 2;
  cpy^.types[1] := cp;
  cpy^.types[2] := ccp;
  ncpy := gspace(16);
  ncpy^.count := 3;
  ncpy^.types[1] := cp;
  ncpy^.types[2] := ccp;
  ncpy^.types[3] := cexs_23b4;
  cmp := gspace(12);
  cmp^.count := 2;
  cmp^.types[1] := ccp;
  cmp^.types[2] := ccp;
  ncmp := gspace(16);
  ncmp^.count := 3;
  ncmp^.types[1] := ccp;
  ncmp^.types[2] := ccp;
  ncmp^.types[3] := cexs_23b4;
  len := gspace(8);
  len^.count := 1;
  len^.types[1] := ccp;
  builtins[0] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_fabs', 13), dbl1, 0, 16#20);
  builtins[1] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_sin', 12), dbl1, 0, 16#29);
  builtins[2] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_cos', 12), dbl1, 0, 16#26);
  builtins[3] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_tan', 12), dbl1, 0, 16#35);
  builtins[4] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_log', 12), dbl1, 0, 16#34);
  builtins[5] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_exp', 12), dbl1, 0, 16#27);
  builtins[6] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_atan', 13), dbl1, 0, 16#25);
  builtins[7] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_atan2', 14), dbl2, 0, 16#33);
  builtins[8] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_pow', 12), dbl2, 0, 16#36);
  builtins[9] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_sqrt', 13), dbl1, 0, 16#2A);
  builtins[10] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strncpy', 16), ncpy, 1, 16#3C);
  builtins[11] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strcpy', 15), cpy, 1, 16#3B);
  builtins[12] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strcmp', 15), cmp, 2, 16#39);
  builtins[13] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strncmp', 16), ncmp, 2, 16#3A);
  builtins[14] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strlen', 15), len, 3, 16#3D);
  builtins[15] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strcat', 15), cpy, 1, 16#37);
  builtins[16] := alloc_builtins(
      idntk(ctk_identifier, '_builtin_strncat', 16), ncpy, 1, 16#38);
end;

{ error - diagnostic code (the current token its argument), then skip
  tokens up to one in follow or the end of the file.

  0x0503BC, 0x80 bytes, link #-56: error1(code, lex_line, lex_token);
  the set follow + [ctk_eof] formed at -56 and copied to -24; the loop
  tests first (`bra' to the `btst').

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

{ check - error(code, follow) unless the current token is in follow.

  0x05044A, 0x32 bytes, link #-4.

  Not known from the original:
  - the names. }

procedure check(
    code: integer;
    in follow: c_tokset_t); options(val_param); internal;
begin
  if not (token_kind in follow) then
    error(code, follow);
end;

{ swap_top - exchange the expression stack's two top entries.

  0x05047C, 0x64 bytes, link #-72: three copies of 62 bytes (`moveq
  #4; dbf' of three longwords, then a word) through -72; the entries
  are 64 bytes apart (`lsl.w #6').

  Not known from the original:
  - the local's name. }

procedure swap_top; internal;
var
  t: c_exp_t;
begin
  t := cexs_stack[cexs_23bc];
  cexs_stack[cexs_23bc] := cexs_stack[cexs_23bc - 1];
  cexs_stack[cexs_23bc - 1] := t;
end;

{ get_builtin_func - whether sym is a builtin's symbol; code its
  operator code, else 18 (a call).

  0x0504E0, 0x46 bytes, link #-12: the result in D0 (`clr.b' first,
  `st' when found), a `dbf' loop of 17 with the index in D2 and 10 * i
  in D3; the first match leaves the loop (`bra' to the epilogue).

  Not known from the original:
  - the names. }

function get_builtin_func(
    in sym: il_$node_ptr_t;
    out code: integer): boolean; internal;
var
  i: integer;
begin
  get_builtin_func := false;
  code := 18;
  for i := 0 to 16 do
    if builtins[i].sym = sym then begin
      code := builtins[i].code;
      get_builtin_func := true;
      exit;
    end;
end;

{ cast_int_const - after a cast or an argument's conversion, an
  integer constant on the top of the stack whose type is integral
  (122) or an enumeration (129) is remade with the type's size and
  signedness: the value truncated (or sign-extended) to 1 or 2 bytes,
  the node of kind 87 or 86 (a byte, signed or not; 80 or 83 when
  widen and the context (csyn_60) is not 4), 80 or 83 (2 bytes), 82 or
  85 (4), and the entry's low and high set to it (high the largest
  integer for a negative unsigned value).

  0x050526, 0x170 bytes, link #-16; the kind at -10.  The constant
  test is `in [77..87, 101, 200]' (the 26-byte set after the routine,
  `ble'; docs/dpc-gaps.md 8); the signedness is the type's byte at +6
  (`tst.b; bpl'); `or.l #-256', `andi.l #255', `or.l #-65536',
  `andi.l #65535' after `tst.b' or `tst.w' of the value.

  Not known from the original:
  - the names; how the truncation was written. }

procedure cast_int_const(
    widen: boolean); options(val_param); internal;
var
  k: integer;
  v: integer32;
  t: c_type_ptr_t;
  n: il_$node_ptr_t;
  signed: boolean;
begin
  with cexs_stack[cexs_23bc] do begin
    t := typ.base;
    n := node;
    signed := t^.signed;
    if n^.kind in [77..87, 101, 200] then
      if (t^.kind = 122) or (t^.kind = 129) then begin
        v := n^.int_value;
        if typ.size = 1 then begin
          if widen and (csyn_60[csyn_202] <> 4) then begin
            if signed then
              k := 80
            else
              k := 83;
          end
          else if signed then
            k := 87
          else
            k := 86;
        end
        else if typ.size = 4 then begin
          if signed then
            k := 82
          else
            k := 85;
        end
        else if signed then
          k := 80
        else
          k := 83;
        if signed then begin
          if typ.size = 1 then begin
            if (v & 16#80) <> 0 then
              v := v ! (-256)
            else
              v := v & 16#FF;
          end
          else if typ.size = 2 then begin
            if (v & 16#8000) <> 0 then
              v := v ! (-65536)
            else
              v := v & 16#FFFF;
          end;
        end
        else if typ.size = 1 then
          v := v & 16#FF
        else if typ.size = 2 then
          v := v & 16#FFFF;
        node := smcontk(k, v);
        typ.low := v;
        if signed or (v >= 0) then
          typ.high := v
        else
          typ.high := 16#7FFFFFFF;
      end;
  end;
end;

{ not_an_lvalue - the top entry is not an lvalue: a function (234,
  108), or a node other than an identifier (73), a variable (109) or
  kinds 145, 146, 147, 205.  Unless addr_op, an array is not an lvalue
  either, except an array parameter (146 whose operand +24 is a
  variable allocated vat_param), which becomes the parameter itself
  with the type pointer to its element (def_ptr, type_exp).

  0x0506B0, 0x0C8 bytes, link #-8; the result in D2 (`clr.b', `st').
  The kinds `in [73, 109, 145, 146, 147, 205]' (a 26-byte set, `bgt';
  docs/dpc-gaps.md 8).

  Not known from the original:
  - the names. }

function not_an_lvalue;
var
  bad: boolean;
begin
  bad := false;
  with cexs_stack[cexs_23bc] do begin
    if not addr_op and
       ((typ.base^.kind = 131) or (typ.base^.kind = 127)) then begin
      if (node^.kind = 146) and then (node^.xp[6]^.kind = 109) and then
         (c_sym_ptr_t(node^.xp[6])^.var_vat = vat_param) then begin
        node := node^.xp[6];
        type_exp(def_ptr(typ.base^.arr_elem, nil), addr(typ));
      end
      else
        bad := true;
    end
    else if (typ.base^.kind = 234) or (typ.base^.kind = 108) then
      bad := true
    else if not (node^.kind in [73, 109, 145, 146, 147, 205]) then
      bad := true;
  end;
  not_an_lvalue := bad;
end;

{ test_side_effects - forget that an assignment was seen (csyn_204),
  before the operand of `&&', `||' or `?:' that may not be evaluated.

  0x050792, 0x10 bytes: no frame (`tst.b; bpl; clr.b; rts';
  docs/rev889-patterns.md 14).

  Not known from the original:
  - why the test. }

procedure test_side_effects; internal;
begin
  if csyn_204 then
    csyn_204 := false;
end;

{ do_c_string - the current string token (92, or 93 wide) becomes a
  static array variable named <string-constant>, initialized with it,
  and its name the top of the stack.

  0x0507A2, 0x16C bytes, link #-176.  The index type is
  int_type's subrange 0..-1 (def_subr of the constants con_zero and
  con_minus_one: -168 and its copy -152), into the declaration -96 (+4
  int_type, +12 cleared, +32 the line); the element (-136) char_type
  with 8 bits (+16) and +20 0, or for a wide string uint_type with 32
  and 2; the array type (def_arr, the last argument `attr_curr_align_env
  = 0', `tst.w; seq') in the declaration -56 (+12 and +28 cleared);
  add_varn(id_string_constant, ..., 1) (vat_stat); flag 14 set (`bset
  #6, (34,A2)'); data_init(0, the variable, the type, 1); body_opr(7)
  with the variable's name pair (-16) (no stack adjustment after it);
  the entry's +8 the string token (taken before data_init).

  Not known from the original:
  - the locals' names. }

procedure do_c_string; internal;
var
  lo, hi: c_cexp_t;
  idx, elem, arr: c_decl_t;
  v: c_sym_ptr_t;
  str: il_$node_ptr_t;
  name: c_name_t;
begin
  lo.ctype := int_type;
  lo.value := con_zero;
  lo.line := lex_line;
  lo.sym := con_zero;
  hi := lo;
  hi.value := con_minus_one;
  hi.sym := con_minus_one;
  idx.name := int_type;
  idx.line := lex_line;
  idx.flags := [];
  def_subr(lo, hi, idx);
  if token_kind = ctk_string then begin
    elem.dtype := char_type;
    elem.name := char_type;
    elem.size_bits := 8;
    elem.align := 0;
  end
  else begin
    elem.dtype := uint_type;
    elem.name := uint_type;
    elem.size_bits := 32;
    elem.align := 2;
  end;
  elem.line := lex_line;
  elem.flags := [];
  arr.dtype := def_arr(idx, elem, 0, attr_curr_align_env = 0);
  arr.flags := [];
  arr.unused_28 := 0;
  arr.line := lex_line;
  v := add_varn(id_string_constant, arr, vat_stat);
  v^.var_flags := v^.var_flags + [14];
  str := lex_token;
  data_init(0, v, arr.dtype, 1);
  name.id := il_$node_ptr_t(v);
  name.line := lex_line;
  body_opr(7, addr(name));
  cexs_stack[cexs_23bc].item := str;
end;

{ identifier - see c_expr_syn.ins.pas.

  0x05090E, 0x54 bytes, link #0.

  Not known from the original:
  - the names. }

procedure identifier;
begin
  name.line := lex_line;
  if token_kind = ctk_identifier then begin
    name.id := lex_token;
    get;
  end
  else begin
    name.id := il_178;
    error(code, follow);
  end;
end;

{ func_call_stat - a call's argument list (the function on the top of
  the stack): each argument an assignment expression handed on with
  expr_op(22); under -TYPE (cargs_$options.type_opt) an argument for a
  reference parameter (a pointer type with ptr_reference) is checked
  against the referenced type (check_types for an lvalue node, else
  coerce: diagnostic 83 when incompatible), converted and its address
  taken; adjust_parm unless the context is 4; a void argument is
  diagnostic 207.  Then expr_op(code, name, the arguments + 1), code 18
  unless builtin.  The called block's (108: its 3-bit field at +377,
  its parameters at +392) or function type's (234: +24, +12) calling
  context is pushed on csyn_60 for the call; a function type without
  parameters is diagnostic 213 under -TYPE.

  0x050962, 0x41A bytes, link #-160.  check(102, follow + [ctk_lparen])
  first (the set formed at -160 and passed there); the follow set of
  the arguments (-64, the expression starters with `)' and `,'), the
  argument's label and context (-48, -92), the function's name pair
  (-40: il_178 and the line; ctk_amp's token for the reference
  argument's `&'), the parameters (-84), the conversion flag (-96, by
  address to adjust_parm), the referenced type (-32).  In registers:
  the argument count D2, the argument number D6 (and 4 * it in D4, the
  parameter's offset), the done flag D5.  The loop's test after an
  argument is `in' a 26-byte set (the starters and `,', docs/dpc-gaps.md
  8): `,' is taken, another starter is diagnostic 102, anything else
  ends the list; the lvalue kinds likewise (`in [109, 145, 146, 147,
  205]', `ble').  The 3-bit field is `moveq #112; and.b (377); lsr.w
  #4'.  code (by value) is overwritten (`move.w #18, (18,A6)').

  Not known from the original:
  - the names; that the referenced parameter's diagnostic names the
    entry argno below the top (`sub.w D6'). }

procedure func_call_stat(
    in follow: c_tokset_t;
    var name: c_name_t;
    builtin: boolean;
    code: integer); options(val_param); internal;
var
  s: c_tokset_t;
  fname, lab: c_name_t;
  ctx: integer;
  conv: boolean;
  params: c_parlist_ptr_t;
  tt: type_exp_t;
  nargs, argno: integer;
  no_proto, done, ok: boolean;
  t, pt: c_type_ptr_t;
begin
  check(102, follow + [ctk_lparen]);
  nargs := 0;
  params := nil;
  no_proto := false;
  fname.id := il_178;
  fname.line := lex_line;
  csyn_202 := csyn_202 + 1;
  csyn_60[csyn_202] := 3;
  with cexs_stack[cexs_23bc] do begin
    t := typ.base;
    if t^.kind = 108 then begin
      csyn_60[csyn_202] := c_blk_ptr_t(t)^.bits.conv;
      params := c_blk_ptr_t(t)^.params;
    end
    else if t^.kind = 234 then begin
      csyn_60[csyn_202] := t^.fn_conv;
      params := t^.fn_params;
      no_proto := params = nil;
    end;
    if no_proto and cargs_$options.type_opt then
      error2(213, lex_line, sym, lex_tokens[ctk_ellipsis]);
  end;
  if token_kind = ctk_lparen then begin
    get;
    done := false;
    s := follow + [ctk_not, ctk_tilde, ctk_sizeof, ctk_lparen, ctk_rparen,
                   ctk_comma, ctk_star, ctk_plus, ctk_minus, ctk_amp,
                   ctk_identifier, 77..89, ctk_string, ctk_wstring, 101];
    argno := 1;
    if token_kind <> ctk_rparen then
      repeat
        ctx := 2;
        asn_expr(s, lab, ctx);
        check(102, s);
        expr_op(22, addr(fname), 1);
        if cargs_$options.type_opt and (params <> nil) and then
           (argno <= params^.count) and then
           (params^.types[argno]^.kind <> 31) then begin
          conv := false;
          pt := params^.types[argno];
          with cexs_stack[cexs_23bc] do
            if (pt^.kind = 130) and pt^.ptr_reference then begin
              type_exp(pt^.ptr_to, addr(tt));
              tt.flags.b25_5 := 19 in pt^.ptr_attr.bits;
              tt.flags.b25_4 := 0 in pt^.ptr_attr.bits;
              if node^.kind in [109, 145, 146, 147, 205] then
                ok := check_types(typ.base, tt.base, true)
              else
                ok := coerce(tt, cexs_23bc, true);
              if not ok then
                error2(83, fname.line, smcontk(81, argno),
                       cexs_stack[cexs_23bc - argno].sym);
              cast_int_const(false);
              fname.id := lex_tokens[ctk_amp];
              expr_op(17, addr(fname), 1);
            end;
          argno := argno + 1;
        end
        else
          conv := true;
        if csyn_60[csyn_202] <> 4 then
          adjust_parm(conv);
        nargs := nargs + 1;
        t := cexs_stack[cexs_23bc].typ.base;
        if t^.kind = 108 then
          type_exp(c_blk_ptr_t(t)^.result, addr(tt))
        else if t^.kind = 234 then
          type_exp(t^.fn_result, addr(tt))
        else
          type_exp(t, addr(tt));
        if tt.base^.kind = 210 then
          error1(207, lex_line, smcontk(81, nargs));
        if token_kind in [24, 34, 42, 61, 63, 65, 67, 68, 69, 76..89, 92, 93, 101, 200] then begin
          if token_kind = ctk_comma then
            get
          else
            error(102, follow);
        end
        else
          done := true;
      until done;
    if token_kind = ctk_rparen then
      get
    else
      error(102, follow);
  end;
  if not builtin then
    code := 18;
  nargs := nargs + 1;
  expr_op(code, addr(name), nargs);
  csyn_202 := csyn_202 - 1;
  attr_check_align(cexs_23bc);
end;

{ primary_expr - a primary expression and its postfix operators (`.',
  `->', calls, subscripts): a constant (body_opr 8, or 6 for a real),
  adjacent strings joined (clex_$catstring, the result given back with
  clex_$unget for do_c_string; then its address unless `[' follows or
  the context is 4), a parenthesized expression (an ANSI paren flag set
  in a 137 or 143 node: bit 5 of its byte +5), or an identifier (an
  undeclared one followed by `(' declared a function returning int; a
  function whose block needs it adjusted for the debugger; a builtin's
  code found; under -TYPE a reference dereferenced).  paren: the `('
  was taken by the caller; postfix: only the postfix operators remain
  (the operand is on the stack).  An identifier followed by `:' while
  ctx is not 2 is a label (lab, ctx 1).

  0x050DCC, 0x826 bytes, link #-248.  The locals: the token at entry
  (-136), the follow set with `->', `.', `[', `(' (-120), the name
  (-128), the member (-88), the `&' pair (-80), the declaration (-72),
  the subscript's follow set (-104), the referenced type (-32), the
  builtin flag and code (-164, -154), the symbol passed by address
  (-148), body_opr's code (-158); the operator in D3, the integer-
  subscript flag in D2 (`int[pointer]': both operands made rvalues and
  swapped).  The starter and constant tests are `in' 26-byte sets
  ([61, 76..89, 92, 93, 101, 200], [77..89, 101, 200], [77..87, 101,
  200]; docs/dpc-gaps.md 8).  The postfix loop compares `->', `.',
  `(', `[' and dispatches `.', `->', `(', `['; `.' and `->' share
  their tail (`bra' to the body_opr(4)).  The expr_op of a subscript
  pops 6 of its 8 bytes (`addq.l #6,SP'; docs/rev889-patterns.md 11).

  Not known from the original:
  - the names; whether the original jumped with gotos (here 10 the
    parenthesized expression, 20 the postfix loop) or nested the cases;
  - nm is not set on the constant path when `[' follows (the image
    passes the frame's -128 as it is). }

procedure primary_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer;
    paren: boolean;
    postfix: boolean); options(val_param); internal;
label
  10, 20;
var
  name, nm, fld, amp: c_name_t;
  s, s2: c_tokset_t;
  decl: c_decl_t;
  tt: type_exp_t;
  builtin, int_index: boolean;
  code, mode, op: integer;
  tmp_sym, fsym, str: il_$node_ptr_t;
  cb: c_blk_ptr_t;
  t: c_type_ptr_t;
begin
  name.id := lex_token;
  name.line := lex_line;
  s := follow + [ctk_arrow, ctk_dot, ctk_lbracket, ctk_lparen];
  builtin := false;
  int_index := false;
  if paren then
    goto 10;
  if postfix then
    goto 20;
  check(116, follow);
  if not (token_kind in [61, 76..89, 92, 93, 101, 200]) then begin
    error(116, follow);
    name.id := il_178;
    body_opr(1, addr(name));
    return;
  end;
  if token_kind in [77..89, 101, 200] then begin
    if token_kind in [77..87, 101, 200] then
      mode := 8
    else if (token_kind = 89) or (token_kind = 88) then
      mode := 6;
    body_opr(mode, addr(name));
    get;
    if token_kind = ctk_lbracket then
      goto 20;
    return;
  end;
  if (token_kind = ctk_string) or (token_kind = ctk_wstring) then begin
    str := nil;
    while (token_kind = ctk_string) or (token_kind = ctk_wstring) do begin
      str := clex_$catstring(str, lex_token);
      get;
    end;
    clex_$unget(str^.kind, str);
    do_c_string;
    nm := name;
    if token_kind = ctk_lbracket then
      goto 20;
    body_opr(5, addr(nm));
    if csyn_60[csyn_202] = 4 then
      return;
    nm.id := lex_tokens[ctk_amp];
    expr_op(17, addr(nm), 1);
    return;
  end;
  if token_kind = ctk_lparen then
    get
  else begin
    identifier(s, 117, nm);
    check(4, s);
    if (ctx <> 2) and (token_kind = ctk_colon) then begin
      ctx := 1;
      lab := nm;
      return;
    end;
    if token_kind = ctk_lparen then begin
      fsym := fnd_name(addr(nm), false, false);
      if fsym = il_178 then begin
        decl.flags := [];
        decl.dtype := int_type;
        decl.name := nm.id;
        decl.line := nm.line;
        def_blk_skeleton(108, addr(nm), 2, addr(decl), nil, nil, false,
                         3, 0, nil);
      end
      else begin
        cb := c_blk_ptr_t(c_sym_ptr_t(fsym)^.var_type);
        if (cb^.kind = 108) and cb^.bits.b376_3 and
           not cb^.bits.db_adjusted and
           (cb^.data_sect <> c_blk_ptr_t(il_180)^.data_sect) then begin
          cb^.bits.db_adjusted := true;
          adjust_blk_for_db(c_sym_ptr_t(fsym)^.var_type);
        end
        else begin
          tmp_sym := fsym;
          builtin := get_builtin_func(tmp_sym, code);
        end;
      end;
    end;
    body_opr(1, addr(nm));
    with cexs_stack[cexs_23bc] do
      if cargs_$options.type_opt and (typ.base^.kind = 130) and
         typ.base^.ptr_reference then
        body_opr(3, addr(nm));
    goto 20;
  end;
10:
  eval_expr(s + [ctk_rparen]);
  with cexs_stack[cexs_23bc] do
    if ((node^.kind = 143) or (node^.kind = 137)) and
       cargs_$options.ansi then
      node^.xw[2] := node^.xw[2] ! 16#2000;
  if token_kind = ctk_rparen then
    get
  else
    error(116, s);
20:
  while (token_kind = ctk_arrow) or (token_kind = ctk_dot) or
        (token_kind = ctk_lparen) or (token_kind = ctk_lbracket) do begin
    case token_kind of
      ctk_dot: begin
        get;
        identifier(s, 118, fld);
        body_opr(4, addr(fld));
      end;
      ctk_arrow: begin
        with cexs_stack[cexs_23bc] do
          if (typ.base^.kind = 131) or (typ.base^.kind = 127) then begin
            body_opr(5, addr(nm));
            amp.id := lex_tokens[ctk_amp];
            expr_op(17, addr(amp), 1);
            t := typ.base;
            if t^.kind <> 130 then begin
              error2(62, lex_line, sym, t);
              typ.base := c_type_ptr_t(il_178);
            end
            else begin
              item := il_$node_ptr_t(t^.ptr_to);
              node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
              attr_set_align_dsc(typ.base, addr(typ));
              type_exp(item, addr(typ));
            end;
          end
          else
            body_opr(3, addr(nm));
        get;
        identifier(s, 118, fld);
        body_opr(4, addr(fld));
      end;
      ctk_lparen: begin
        with cexs_stack[cexs_23bc] do begin
          if typ.base^.kind = 130 then begin
            type_exp(typ.base^.ptr_to, addr(tt));
            if tt.base^.kind = 234 then begin
              body_opr(5, addr(nm));
              item := il_$node_ptr_t(typ.base^.ptr_to);
              node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
              attr_set_align_dsc(typ.base, addr(typ));
              type_exp(item, addr(typ));
            end;
          end;
          if (typ.base^.kind <> 108) and (typ.base^.kind <> 234) then begin
            error2(67, line, sym, typ.base);
            typ.base := c_type_ptr_t(il_178);
          end;
          func_call_stat(s, name, builtin, code);
          if cargs_$options.type_opt and (typ.base^.kind = 130) and
             typ.base^.ptr_reference then
            body_opr(3, addr(nm));
        end;
      end;
      ctk_lbracket: begin
        s2 := s + [ctk_not, ctk_tilde, ctk_sizeof, ctk_rbracket, ctk_lparen,
                   ctk_comma, ctk_star, ctk_plus, ctk_minus, ctk_amp,
                   ctk_identifier, 77..89, ctk_string, ctk_wstring, 101];
        get;
        with cexs_stack[cexs_23bc] do
          if typ.base^.kind = 122 then begin
            int_index := true;
            mode := 5;
          end
          else if typ.base^.kind = 130 then begin
            mode := 5;
            op := 8;
          end
          else begin
            mode := 2;
            op := 19;
          end;
        body_opr(mode, addr(nm));
        eval_expr(s2);
        if int_index then begin
          with cexs_stack[cexs_23bc] do
            if typ.base^.kind = 130 then begin
              mode := 5;
              op := 8;
            end
            else begin
              mode := 2;
              op := 19;
            end;
          body_opr(mode, addr(nm));
          swap_top;
          int_index := false;
        end;
        expr_op(op, addr(nm), 2);
        check(119, s2);
        if op = 8 then
          body_opr(3, addr(nm));
        if token_kind = ctk_rbracket then
          get
        else
          error(119, s);
      end;
    end;
    check(4, s);
  end;
  body_opr(5, addr(nm));
  with cexs_stack[cexs_23bc] do
    if cargs_$options.type_opt and (typ.base^.kind = 130) and
       typ.base^.ptr_reference then begin
      item := il_$node_ptr_t(typ.base^.ptr_to);
      node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
      attr_set_align_dsc(typ.base, addr(typ));
      type_exp(item, addr(typ));
    end;
end;

{ unary_expr - a unary expression: `*' (an array or function first
  made a pointer; not a pointer: diagnostic 62; a pointer to an
  incomplete structure: 293; the entry made the pointed-to object,
  flag 22 set on a variable subscripted within bounds), `&' (of a bit
  field: 92; of a string's array or, outside context 4, of an array:
  206; of a register variable that is not an array: 131; not an
  lvalue: 40), `-', `+', `!', `~', prefix `++' and `--' (expr_op 27),
  sizeof of a type (pushed constant; 175 an unknown type name, 75
  zero, 158 a function) or of an expression (its storage size, 4 for a
  constant or an array parameter, an array variable's section size or
  initializer, a string's length), a cast (expr_op 22; a void cast
  replaces the type; coerce else diagnostic 76; under -TYPE a
  reference's address taken and the result dereferenced), else a
  primary expression with postfix `++' and `--' (expr_op 28; the
  increment the pointed-to size, 1.0 for a floating operand).

  0x051650, 0xBAA bytes, link #-292.  The locals: the token at entry
  (-112), the follow set (-128, formed at -292), the type (-104), the
  type name (-40, c_decl_t) and its flag (-160), the paren flag
  (-158), the operator (-156), sizeof's token (-144), the increment
  (-148), def_incomplete_su's structure (-140); the size in D2 (the
  label's address register reused).  A compare chain dispatches `*',
  `&', `-', `+', `!', `~', `--', `++', sizeof, `('.  `&''s follow set
  is follow + [61, 76..89, 92, 93, 101] less [77..89, 101] (`or.l',
  then `and.l' with the complement); the default's is follow + [19,
  20] + [61, 76..89, 92, 93, 101] (two `or.l').  The unary operators
  share the expr_op call (`bra'); the cast's not-a-type branch joins
  the default after its paren := false, prefix `++' and `--' join the
  postfix code after its get (here labels 10 and 20).  The flag pairs
  `sne; lsr.b #7; lsl.b #5; andi.b #-33; or.b' set type_exp_t's b25_5
  and b25_4.  sizeof's constant test is `in [80..86, 200]' (a 26-byte
  set, `ble'; docs/dpc-gaps.md 8).  The 1.0 is a double after the
  routine (`pea (0x052240,PC)', 0x3FF0000000000000; docs/dpc-gaps.md 7).

  Not known from the original:
  - the names; the gotos (see primary_expr);
  - the increment's test of the node for kind 130 (a pointer type's
    kind: probably the type was meant; the image reads +0, the node,
    and on a match type_exp's its +4 into the entry's own type). }

procedure unary_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
label
  10, 20;
var
  name: c_name_t;
  s: c_tokset_t;
  tt: type_exp_t;
  tn: c_decl_t;
  is_type, paren: boolean;
  op, k: integer;
  tok, x, old_sym: il_$node_ptr_t;
  incr, size: integer32;
  t: c_type_ptr_t;
  regs, q: c_reglist_ptr_t;
begin
  name.id := lex_token;
  name.line := lex_line;
  case token_kind of
    ctk_star: begin
      get;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      with cexs_stack[cexs_23bc] do begin
        k := typ.base^.kind;
        if (k = 108) or (k = 127) or (k = 234) or (k = 131) then begin
          name.id := lex_tokens[ctk_amp];
          expr_op(17, addr(name), 1);
        end;
        t := typ.base;
        if t^.kind <> 130 then begin
          error2(62, lex_line, sym, t);
          typ.base := c_type_ptr_t(il_178);
          return;
        end;
        if t^.ptr_to^.kind = 76 then
          error1(293, lex_line, t^.ptr_to)
        else if def_incomplete_su(t^.ptr_to, addr(x)) then
          error1(293, lex_line, x^.xp[5]);
        item := il_$node_ptr_t(typ.base^.ptr_to);
        node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
        typ.flags.b25_5 := 19 in typ.base^.ptr_attr.bits;
        typ.flags.b25_4 := 0 in typ.base^.ptr_attr.bits;
        attr_set_align_dsc(typ.base, addr(typ));
        t := typ.base;
        type_exp(item, addr(typ));
        typ.bytes := (t^.ptr_attr.size_bits + 7) div 8;
        if flag_61 and (disp >= 0) and (disp < typ.size) and then
           (sym^.kind = 109) then
          c_sym_ptr_t(sym)^.var_flags := c_sym_ptr_t(sym)^.var_flags + [22];
      end;
    end;
    ctk_amp: begin
      get;
      ctx := 2;
      s := follow + [ctk_lparen, ctk_identifier, 77..89, ctk_string,
                     ctk_wstring, 101] - [77..89, 101];
      unary_expr(s, lab, ctx);
      check(116, s);
      with cexs_stack[cexs_23bc] do begin
        if sym^.kind = 120 then
          error1(92, c_field_ptr_t(sym)^.line, c_field_ptr_t(sym)^.name);
        if (item^.kind = 92) and then (node^.kind = 137) and then
           (node^.xw[18] = 26) and then (node^.xp[10]^.kind = 109) and then
           (c_sym_ptr_t(node^.xp[10])^.name = id_string_constant) then begin
          if csyn_60[csyn_202] = 4 then
            return;
          error0(206, line);
          return;
        end;
        type_exp(typ.base, addr(tt));
        if ((tt.base^.kind = 131) or (tt.base^.kind = 127)) and
           (csyn_60[csyn_202] <> 4) then begin
          error0(206, line);
          return;
        end;
        if node^.kind = 109 then begin
          regs := c_blk_ptr_t(il_180)^.reg_vars;
          if regs <> nil then begin
            q := regs;
            while q <> nil do begin
              if q^.rvar = node then begin
                type_exp(c_sym_ptr_t(node)^.var_type, addr(tt));
                if not ((tt.base^.kind = 131) or (tt.base^.kind = 127)) then
                  error1(131, line, node);
                exit;
              end;
              q := q^.next;
            end;
          end;
        end;
        if (node^.kind = 109) and (10 in c_sym_ptr_t(node)^.var_flags) then
          cdef_50^.bits.b374_6 := true;
        if (typ.base^.kind <> 234) and (typ.base^.kind <> 108) then
          if not_an_lvalue(true) then
            error2(40, lex_line, sym, name.id);
      end;
      expr_op(17, addr(name), 1);
    end;
    ctk_minus: begin
      get;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      expr_op(21, addr(name), 1);
    end;
    ctk_plus: begin
      get;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      expr_op(20, addr(name), 1);
    end;
    ctk_not: begin
      get;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      expr_op(16, addr(name), 1);
    end;
    ctk_tilde: begin
      get;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      expr_op(46, addr(name), 1);
    end;
    ctk_decr, ctk_incr: begin
      op := 27;
      get;
      s := follow + [ctk_lparen, ctk_identifier, 77..89, ctk_string,
                     ctk_wstring, 101];
      ctx := 2;
      csyn_204 := true;
      if token_kind = ctk_star then
        unary_expr(s, lab, ctx)
      else
        primary_expr(s, lab, ctx, false, false);
      check(116, s);
      goto 20;
    end;
    ctk_sizeof: begin
      get;
      ctx := 2;
      if token_kind = ctk_lparen then begin
        get;
        tok := lex_token;
        c_type_name(follow, tn, is_type);
        if is_type then begin
          if c_type_ptr_t(tn.dtype)^.kind = 73 then
            error0(175, lex_line);
          type_exp(tn.dtype, addr(tt));
          push_con(tt.bytes);
          if tt.bytes = 0 then
            error1(75, lex_line, tok);
          if tt.base^.kind = 234 then
            error0(158, lex_line);
          return;
        end;
        s := follow + [ctk_lparen, ctk_identifier, 77..89, ctk_string,
                       ctk_wstring, 101];
        primary_expr(s, lab, ctx, true, false);
        check(116, s);
      end
      else begin
        unary_expr(follow, lab, ctx);
        check(116, follow);
      end;
      with cexs_stack[cexs_23bc] do begin
        if (typ.base^.kind = 234) or (typ.base^.kind = 108) then
          error0(158, lex_line);
        size := typ.bytes;
        k := node^.kind;
        if k in [80..86, 200] then
          if (typ.base^.kind = 129) and then (typ.base^.enum_int^.len = 2) then
            size := 2
          else
            size := 4;
        if ((typ.base^.kind = 131) or (typ.base^.kind = 127)) and
           (k = 146) and then (node^.xp[6]^.kind = 109) and then
           (c_sym_ptr_t(node^.xp[6])^.var_vat = vat_param) then
          size := 4;
        if (typ.bytes = 0) and
           ((typ.base^.kind = 131) or (typ.base^.kind = 127)) and then
           (item^.kind = 109) then begin
          if c_sym_ptr_t(item)^.var_vat = vat_sect then
            size := c_sym_ptr_t(item)^.var_sect^.xl[5]
          else if (c_sym_ptr_t(item)^.var_vat = vat_stat) and then
                  (c_sym_ptr_t(item)^.var_sect^.kind = 81) then
            size := c_sym_ptr_t(item)^.var_sect^.int_value;
        end;
        if item^.kind = 92 then
          size := item^.str_len;
        node := smcontk(81, size);
        type_exp(int_type, addr(typ));
        old_sym := sym;
        if sym^.kind = 120 then
          sym := node;
        if size = 0 then
          error1(75, lex_line, old_sym);
      end;
    end;
    ctk_lparen: begin
      get;
      c_type_name(follow, tn, is_type);
      if not is_type then begin
        paren := true;
        goto 10;
      end;
      ctx := 2;
      unary_expr(follow, lab, ctx);
      check(116, follow);
      expr_op(22, addr(name), 1);
      type_exp(tn.dtype, addr(tt));
      tt.flags.b25_5 := 19 in tn.flags;
      tt.flags.b25_4 := 0 in tn.flags;
      if cargs_$options.type_opt and
         (c_type_ptr_t(tn.dtype)^.kind = 130) and
         c_type_ptr_t(tn.dtype)^.ptr_reference then begin
        if not_an_lvalue(true) then
          error2(40, lex_line, cexs_stack[cexs_23bc].sym, name.id);
        expr_op(17, addr(name), 1);
      end;
      with cexs_stack[cexs_23bc] do begin
        if tt.base^.kind = 210 then begin
          typ := tt;
          return;
        end;
        if coerce(tt, cexs_23bc, false) then
          typ := tt
        else
          error1(76, lex_line, sym);
        cast_int_const(true);
        if cargs_$options.type_opt and (typ.base^.kind = 130) and
           typ.base^.ptr_reference then begin
          item := il_$node_ptr_t(typ.base^.ptr_to);
          node := add_pn(node, item, typ.base^.ptr_attr.align, 0);
          attr_set_align_dsc(typ.base, addr(typ));
          type_exp(item, addr(typ));
        end;
      end;
    end;
    otherwise begin
      paren := false;
      goto 10;
    end;
  end;
  return;
10:
  s := follow + [ctk_incr, ctk_decr] + [ctk_lparen, ctk_identifier, 77..89,
                                        ctk_string, ctk_wstring, 101];
  primary_expr(s, lab, ctx, paren, false);
  check(116, s);
  if (token_kind <> ctk_incr) and (token_kind <> ctk_decr) then
    return;
  op := 28;
  name.id := lex_token;
  name.line := lex_line;
  get;
  csyn_204 := true;
20:
  if not_an_lvalue(false) then
    error2(40, lex_line, cexs_stack[cexs_23bc].sym, name.id);
  incr := 1;
  with cexs_stack[cexs_23bc] do begin
    if node^.kind = 130 then begin
      type_exp(node^.xp[1], addr(typ));
      incr := typ.size;
    end;
    if typ.base^.kind = 123 then
      push_fcon(1.0)
    else
      push_con(incr);
  end;
  expr_op(op, addr(name), 2);
  if (token_kind = ctk_arrow) or (token_kind = ctk_dot) or
     (token_kind = ctk_lparen) or (token_kind = ctk_lbracket) then
    primary_expr(s, lab, ctx, paren, true);
end;

{ The binary levels: each parses its operands with the next level
  (follow set: its own plus the operators it takes, formed at -64 and
  copied to -32), takes its operators left to right (the name pair of
  the operator at -16, the code at -34; ctx := 2 before the right
  operand) and hands each to expr_op with 2 operands.  The operator
  tests are compare chains in the image's order; rel_expr's codes come
  from a jump table over `<=' .. `>' (the two other tokens in the
  range not set); `&&' and `||' call test_side_effects before their
  right operand.

  Not known from the original:
  - the names. }

{ multip_expr - `*' (11), `/' (12), `%' (14).  0x052248, 0xF6 bytes. }

procedure multip_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  op: integer;
  name: c_name_t;
begin
  s := follow + [ctk_percent, ctk_star, ctk_slash];
  unary_expr(s, lab, ctx);
  check(116, s);
  while (token_kind = ctk_percent) or (token_kind = ctk_slash) or
        (token_kind = ctk_star) do begin
    if token_kind = ctk_star then
      op := 11
    else if token_kind = ctk_slash then
      op := 12
    else
      op := 14;
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    unary_expr(s, lab, ctx);
    check(116, s);
    expr_op(op, addr(name), 2);
  end;
end;

{ addit_expr - `+' (8), `-' (9).  0x05234C, 0xE0 bytes. }

procedure addit_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  op: integer;
  name: c_name_t;
begin
  s := follow + [ctk_plus, ctk_minus];
  multip_expr(s, lab, ctx);
  check(116, s);
  while (token_kind = ctk_minus) or (token_kind = ctk_plus) do begin
    if token_kind = ctk_plus then
      op := 8
    else
      op := 9;
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    multip_expr(s, lab, ctx);
    check(116, s);
    expr_op(op, addr(name), 2);
  end;
end;

{ shift_expr - `<<' (29), `>>' (30).  0x05243A, 0xE2 bytes. }

procedure shift_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  op: integer;
  name: c_name_t;
begin
  s := follow + [ctk_shl, ctk_shr];
  addit_expr(s, lab, ctx);
  check(116, s);
  while (token_kind = ctk_shr) or (token_kind = ctk_shl) do begin
    if token_kind = ctk_shl then
      op := 29
    else
      op := 30;
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    addit_expr(s, lab, ctx);
    check(116, s);
    expr_op(op, addr(name), 2);
  end;
end;

{ rel_expr - `<=' (2), `<' (4), `>=' (3), `>' (5).  0x05252A, 0x126
  bytes: the codes by a jump table of 6 from `<=' (`subi.w #54; cmpi.w
  #6; bcc'). }

procedure rel_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  op: integer;
  name: c_name_t;
begin
  s := follow + [ctk_le, ctk_lt, ctk_gt, ctk_ge];
  shift_expr(s, lab, ctx);
  check(116, s);
  while (token_kind = ctk_le) or (token_kind = ctk_lt) or
        (token_kind = ctk_gt) or (token_kind = ctk_ge) do begin
    case token_kind of
      ctk_le: op := 2;
      ctk_lt: op := 4;
      ctk_ge: op := 3;
      ctk_gt: op := 5;
    end;
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    shift_expr(s, lab, ctx);
    check(116, s);
    expr_op(op, addr(name), 2);
  end;
end;

{ eq_expr - `==' (0), `!=' (1).  0x05265E, 0xE0 bytes. }

procedure eq_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  op: integer;
  name: c_name_t;
begin
  s := follow + [ctk_eq, ctk_ne];
  rel_expr(s, lab, ctx);
  check(116, s);
  while (token_kind = ctk_eq) or (token_kind = ctk_ne) do begin
    if token_kind = ctk_eq then
      op := 0
    else
      op := 1;
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    rel_expr(s, lab, ctx);
    check(116, s);
    expr_op(op, addr(name), 2);
  end;
end;

{ bit_and_expr - `&' (33).  0x05274C, 0xCE bytes. }

procedure bit_and_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_amp];
  eq_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_amp do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    eq_expr(s, lab, ctx);
    check(116, s);
    expr_op(33, addr(name), 2);
  end;
end;

{ bit_eor_expr - `^' (45).  0x052828, 0xCE bytes. }

procedure bit_eor_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_caret];
  bit_and_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_caret do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    bit_and_expr(s, lab, ctx);
    check(116, s);
    expr_op(45, addr(name), 2);
  end;
end;

{ bit_ior_expr - `|' (34).  0x052904, 0xCE bytes. }

procedure bit_ior_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_bar];
  bit_eor_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_bar do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    bit_eor_expr(s, lab, ctx);
    check(116, s);
    expr_op(34, addr(name), 2);
  end;
end;

{ log_and_expr - `&&' (26).  0x0529E0, 0xD2 bytes. }

procedure log_and_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_andand];
  bit_ior_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_andand do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    test_side_effects;
    bit_ior_expr(s, lab, ctx);
    check(116, s);
    expr_op(26, addr(name), 2);
  end;
end;

{ log_or_expr - `||' (25).  0x052AC0, 0xD2 bytes. }

procedure log_or_expr(
    in follow: c_tokset_t;
    var lab: c_name_t;
    var ctx: integer); internal;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_oror];
  log_and_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_oror do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    test_side_effects;
    log_and_expr(s, lab, ctx);
    check(116, s);
    expr_op(25, addr(name), 2);
  end;
end;

{ cond_expr - `?:' (24, 3 operands): the middle operand a full
  expression up to `:', which is skipped without a test; the last
  checked against the set with `:'.

  0x052BA0, 0x118 bytes, link #-72 (the set at -24, formed at -72; the
  `?' pair at -8).

  Not known from the original:
  - the names; why the `:' is not checked. }

procedure cond_expr;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_question];
  log_or_expr(s, lab, ctx);
  check(116, s);
  if token_kind = ctk_question then begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    s := follow + [ctk_colon];
    ctx := 2;
    c_expr(s, lab, ctx);
    check(116, s);
    get;
    test_side_effects;
    cond_expr(follow, lab, ctx);
    check(116, s);
    expr_op(24, addr(name), 3);
  end;
end;

{ asn_expr - `=' and the compound assignments (27, the token telling
  which), right to left: the left operand must be an lvalue
  (diagnostic 40); csyn_204 is set.

  0x052CD4, 0x102 bytes, link #-56 (the set at -24; the operator's pair
  at -8); the right operand is parsed with the caller's follow set.

  Not known from the original:
  - the names. }

procedure asn_expr;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_assign];
  cond_expr(s, lab, ctx);
  check(116, s);
  if token_kind = ctk_assign then begin
    csyn_204 := true;
    if not_an_lvalue(false) then
      error2(40, lex_line, cexs_stack[cexs_23bc].sym, lex_token);
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    asn_expr(follow, lab, ctx);
    check(116, follow);
    expr_op(27, addr(name), 2);
  end;
end;

{ c_expr - assignment expressions separated by commas (44).

  0x052DE4, 0xD6 bytes, link #-56 (the set at -24, the comma's pair at
  -8; token_kind's, lex_token's and lex_line's addresses kept in
  registers for the loop).

  Not known from the original:
  - the names. }

procedure c_expr;
var
  s: c_tokset_t;
  name: c_name_t;
begin
  s := follow + [ctk_comma];
  asn_expr(s, lab, ctx);
  check(116, s);
  while token_kind = ctk_comma do begin
    name.id := lex_token;
    name.line := lex_line;
    get;
    ctx := 2;
    asn_expr(s, lab, ctx);
    check(116, s);
    expr_op(44, addr(name), 2);
  end;
end;

{ eval_expr - c_expr with context 2 (no label) and a label name no one
  reads.

  0x052EC8, 0x40 bytes, link #-12 (the name at -8, the context at
  -10).

  Not known from the original:
  - the locals' names. }

procedure eval_expr;
var
  lab: c_name_t;
  ctx: integer;
begin
  ctx := 2;
  c_expr(follow, lab, ctx);
  check(116, follow);
end;
