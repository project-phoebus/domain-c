{ lang/c_compiler/source/c_globals.ins.pas - the C front end's shared
  variables: the cells of the front end's modules that other units
  reach absolutely (tools/cc_globals.py over cc.m68k and cc.a88k; the
  front end is the same code in both, the blocks at the same offsets
  from each module's A5).  Each module that owns cells `define's them;
  the owner, the offset in its data and the units that use each cell
  are given with it.  Cells shared only within the preprocessor are in
  c_pre_proc.ins.pas, macro_read.ins.pas and c_lex_pp.pvt.pas.

  Opened after the prelude and c_objtype.ins.pas by every front-end
  unit, and by add_node, attributes, error_listing, inc_list and
  runbackend.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Widths are those of the accesses (a word integer, a longword
  integer32, a byte boolean); a cell some unit loads into an address
  register is a pointer, univ_ptr until its target is known.

  Not known from the original: every name here (cells whose role is
  not yet known are named by their owner and offset).
}

const
  { The tokens' classes (token_kind, a token node's kind): k in 0..75
    is the class of the identifier c_main's rword_init enters with
    idntk(k, ...) from c_data.asm's table of 10-character names
    (cc.m68k 0x0409E4; classes 7, 28, 30 and 45 have blank names, 75
    the bytes after the table) and keeps in lex_tokens[k]; an
    identifier a reserved word has not claimed is class 76 (idntk(76,
    ...)), constants and strings have their node kinds.  The names are
    the spellings. }
  ctk_rbrace = 0;           ctk_if = 1;               ctk_switch = 2;
  ctk_lbrace = 3;           ctk_else = 4;             ctk_do = 5;
  ctk_enum = 6;             ctk_7 = 7;                ctk_void = 8;
  ctk_while = 9;            ctk_case = 10;            ctk_int = 11;
  ctk_char = 12;            ctk_float = 13;           ctk_double = 14;
  ctk_for = 15;             ctk_union = 16;           ctk_struct = 17;
  ctk_va_type = 18;         ctk_incr = 19;            ctk_decr = 20;
  ctk_percent = 21;         ctk_oror = 22;            ctk_andand = 23;
  ctk_not = 24;             ctk_auto = 25;            ctk_register = 26;
  ctk_typedef = 27;         ctk_28 = 28;              ctk_std_call = 29;
  ctk_attribute = 30;       ctk_ellipsis = 31;        ctk_goto = 32;
  ctk_arrow = 33;           ctk_tilde = 34;           ctk_static = 35;
  ctk_extern = 36;          ctk_long = 37;            ctk_short = 38;
  ctk_unsigned = 39;        ctk_break = 40;           ctk_continue = 41;
  ctk_sizeof = 42;          ctk_return = 43;          ctk_default = 44;
  ctk_options = 45;         ctk_shl = 46;             ctk_shr = 47;
  ctk_question = 48;        ctk_dotdot = 49;          ctk_rbracket = 50;
  ctk_dot = 51;             ctk_assign = 52;          ctk_colon = 53;
  ctk_le = 54;              ctk_ne = 55;              ctk_lt = 56;
  ctk_eq = 57;              ctk_ge = 58;              ctk_gt = 59;
  ctk_lbracket = 60;        ctk_lparen = 61;          ctk_rparen = 62;
  ctk_comma = 63;           ctk_semicolon = 64;       ctk_star = 65;
  ctk_slash = 66;           ctk_plus = 67;            ctk_minus = 68;
  ctk_amp = 69;             ctk_bar = 70;             ctk_caret = 71;
  ctk_eof = 72;             ctk_dashes = 73;          ctk_bad_char = 74;
  ctk_other_char = 75;      { a character no token begins with (get
                              puts it in the name's first place) }
  ctk_identifier = 76;
  ctk_int_con = 81;         { smcontk's kinds: int, long, unsigned }
  ctk_long_con = 82;
  ctk_unsigned_con = 85;
  ctk_string = 92;          { strtk's node }
  ctk_wstring = 93;         { a wide string: strtk's node, kind 93 }

  { lex_tokens's entries for the compound assignments (class
    ctk_assign; c_main's rword_init enters `+=' .. `^=' with idntk(52,
    ...)). }
  lex_add_assign = -10;     lex_sub_assign = -9;      lex_mul_assign = -8;
  lex_div_assign = -7;      lex_mod_assign = -6;      lex_shr_assign = -5;
  lex_shl_assign = -4;      lex_and_assign = -3;      lex_or_assign = -2;
  lex_xor_assign = -1;

type
  { A diagnostic's arguments as error_listing's error0..error3 pass
    them to errorlst (a 16-byte frame array, by address). }
  cerr_args_t = array [1..3] of univ_ptr;

{ TODO(pascal) most cells are named by offset

  Rename them as their owners and users are translated (c_main sets
  most of them up). }

var
  { c_def_sem.pas's data, A5 0x140054 (cc.m68k), 0x2C0054 (cc.a88k).
    cc (c_main) enters six identifiers with idntk(76, ...) and clears
    the word after each: the routines c_def_sem treats specially.  The
    lengths cc passes for three of them are short (`_longjm', `longjm',
    `sigset': 7, 6 and 6 characters of `_longjmp', `longjmp' and
    `sigsetjmp'; probably copied from `_setjmp' and `setjmp'), so the
    names entered are those prefixes. }
  cdef_id_ulongjmp: extern il_$node_ptr_t;  { +0x0: `_longjm'; c_def_sem }
  cdef_04: extern integer;              { +0x4 }
  cdef_id_longjmp: extern il_$node_ptr_t;   { +0x8: `longjm' }
  cdef_0c: extern integer;              { +0xC }
  cdef_id_sigsetjmp: extern il_$node_ptr_t; { +0x10: `sigset' }
  cdef_14: extern integer;              { +0x14 }
  cdef_id_pfm_cleanup: extern il_$node_ptr_t;  { +0x18: `pfm_$cleanup' }
  cdef_1c: extern integer;              { +0x1C }
  cdef_id_usetjmp: extern il_$node_ptr_t;   { +0x20: `_setjmp' }
  cdef_24: extern integer;              { +0x24 }
  cdef_id_setjmp: extern il_$node_ptr_t;    { +0x28: `setjmp' }
  cdef_2c: extern integer;              { +0x2C }
  cdef_data_sect: extern il_$node_ptr_t;  { +0x38: the data section
                                          variables go to (#section's
                                          second name: c_lex_pp
                                          section_sem; c_main
                                          make_main_pgm) }
  cdef_code_sect: extern il_$node_ptr_t;  { +0x3C: the code section
                                          (#section's first name);
                                          c_main }
  cdef_44: extern univ_ptr;             { +0x44: c_syntax }
  cdef_4c: extern integer32;            { +0x4C: c_syntax }
  cdef_50: extern c_blk_ptr_t;          { +0x50: the current block (cc
                                          and make_main_pgm set it to
                                          il_180; c_expr_syn's `&' sets
                                          its b374_6); c_expr_sem,
                                          c_main, c_stmt_sem, c_syntax }
  cdef_outer_block: extern il_$node_ptr_t;  { +0x54: the outermost
                                          block (cc sets it to il_180;
                                          c_lex_pp's #module renames it
                                          when it is a module, 106, and
                                          #section is taken only while
                                          il_180 is still it); c_main,
                                          c_stmt_sem, c_syntax }

  { c_error.pas's data, A5 0x1400AC (cc.m68k), 0x2C00AC (cc.a88k):
    a byte (tested by c_error's routines through A5 and by c_lex_pp,
    c_main and error_listing absolutely), and at +0x2 a byte errorlst
    keeps to itself. }
  cerr_quiet: extern boolean;           { +0x0: diagnostics are listed
                                          but neither typed nor counted:
                                          set except while cgerr reports
                                          (cgerr clears it around its
                                          call of error0/error1);
                                          error_listing's error0..3 do
                                          not save diagnostics while it
                                          is set }

  { The diagnostics' tables, in c_data.asm's part of .text (cc.m68k
    0x0409E4..0x0451B3): the C compiler's diagnostic numbers for the
    code generator's codes (cgerr; attributes and c_lex_pp's get read
    single entries), each diagnostic's text offset and severity (0 a
    warning, 1 fatal, 2 an error, 3..6 information of level 1..4;
    errorlst, cgerr) and the texts (errorlst: '.' ends a text, '_' is
    a blank, '@n' the n-th argument, '@L' '[' and '@R' ']', '&n' the
    line of the n-th argument).  Defined by c_data.asm.

    Not known from the original: the names and the bounds. }
  cerr_code_map: extern array [0..85] of integer;      { 0x040CD2 }
  cerr_messages: extern array [1..330] of record       { 0x040D7E }
    text_at: integer;                   { +0: where the text begins in
                                          cerr_texts }
    severity: integer;                  { +2 }
  end;
  cerr_texts: extern array [0..16141] of char;         { 0x0412A6 }

  { The names c_main's rword_init enters as the token classes 0..75
    (ctk_ constants), 10 characters each, blank-padded (c_data.asm,
    cc.m68k 0x0409E4; the 76th entry is the bytes after the table). }
  c_rword_table: extern array [0..75] of array [1..10] of char;  { 0x0409E4 }

  { c_expr_sem.pas's data, A5 0x1400B0 (cc.m68k), 0x2C00B0 (cc.a88k).
    The basic types, made by c_main's init_basic_types: 8-byte integral
    nodes (kind 122; +4 the length, +6 signed), 6-byte floating nodes
    (kind 123; +4 6 or 7) and 4-byte nodes of kinds 210 and 136. }
  cexs_stack: extern array [1..128] of c_exp_t;  { +0x390: the
                                          expression stack (64-byte
                                          entries to +0x2390, cexs_23bc
                                          the top): c_main
                                          make_main_pgm, c_stmt_sem
                                          walk_tree }
  char_type: extern c_type_ptr_t;       { +0x2390: signed, 1 }
  short_type: extern c_type_ptr_t;      { +0x2394: signed, 2 (cc also
                                          stores it in runbackend_10) }
  int_type: extern c_type_ptr_t;        { +0x2398: signed, 4 (and in
                                          runbackend_0c); add_node,
                                          fe_cc_hooks_to_backend }
  uchar_type: extern c_type_ptr_t;      { +0x239C: unsigned, 1 }
  ushort_type: extern c_type_ptr_t;     { +0x23A0: unsigned, 2 }
  uint_type: extern c_type_ptr_t;       { +0x23A4: unsigned, 4 }
  float_type: extern c_type_ptr_t;      { +0x23A8: floating, 6 }
  double_type: extern c_type_ptr_t;     { +0x23AC: floating, 7 }
  void_type: extern c_type_ptr_t;       { +0x23B0: kind 210 }
  cexs_23b4: extern c_type_ptr_t;       { +0x23B4: uint_type's node
                                          again (c_expr_syn, c_main) }
  cexs_23b8: extern c_type_ptr_t;       { +0x23B8: kind 136 (c_main) }
  cexs_23bc: extern integer;            { +0x23BC: the expression
                                          stack's top (cexs_stack's
                                          index; c_expr_syn's swap_top
                                          exchanges the two top
                                          entries); add_node, c_def_sem,
                                          c_expr_syn, c_main, c_stmt_sem,
                                          c_syntax }

  { c_lex_pp.pas's data, A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k):
    the cells other units reach (c_lex_pp's own are in c_lex_pp.pas and
    c_lex_pp.pvt.pas). }
  kw_options: extern c_kw_node_t;       { +0x498: the token `#options'
                                          stands for: c_main copies the
                                          identifier `options' into it
                                          and makes its class
                                          ctk_options }
  kw_attribute: extern c_kw_node_t;     { +0x14B0: the token of
                                          `#attribute' (class
                                          ctk_attribute; c_main) }
  lex_line: extern integer;             { +0x24C8: the current source
                                          line (spos's encoding), the
                                          line errors are reported at:
                                          attributes, c_def_sem,
                                          c_expr_sem, c_expr_syn,
                                          c_macro_read, c_main,
                                          c_stmt_sem, c_syntax }
  lex_text_written: extern boolean;     { +0x24CC: the current line's
                                          text has been written out
                                          (errorlst writes it before the
                                          line's first diagnostic; cgerr
                                          sets it); c_main }
  lex_hdr_written: extern boolean;      { +0x24CD: the line's header
                                          has been typed (error_hdr;
                                          cgerr sets it); c_main }
  lex_fatal: extern boolean;            { +0x24D0: a fatal diagnostic
                                          was reported: errorlst
                                          reports no more (cgerr clears
                                          it, and c_lex_pp for each new
                                          line and before an #if's
                                          expression); c_syntax }
  lex_fatal_suppressed: extern boolean; { +0x24D1: errorlst dropped a
                                          diagnostic after a fatal one }
  lex_type_errors: extern boolean;      { +0x24D2: diagnostics are
                                          typed on the terminal as well
                                          as listed }
  lex_errors: extern integer;           { +0x24D4: errors reported
                                          (error_hdr); c_main,
                                          runbackend }
  lex_warnings: extern integer;         { +0x24D6: warnings reported
                                          (error_hdr); c_main }
  lex_infos: extern integer;            { +0x24D8: informational
                                          messages (error_hdr); c_main }
  lex_24da: extern integer;             { +0x24DA: attributes counts }
  lex_24dc: extern integer;             { +0x24DC: attributes counts }
  lex_text: extern varying [520] of char;  { +0x24DE: the current
                                          source line: characters 1..8
                                          hold the listing's line number
                                          field, the text begins at 9
                                          (the bound from the next cell,
                                          +0x26E8; error_hdr copies at
                                          most 256 characters) }
  lex_tokens: extern array [-10..236] of il_$node_ptr_t;  { +0x26E8:
                                          the tokens of the reserved
                                          words and the operators, made
                                          by c_main's rword_init: [k]
                                          for k in 0..75 the identifier
                                          of class k (the ctk_
                                          constants), [-10..-1] the
                                          compound assignments (class
                                          ctk_assign), [102..104]
                                          `const', `volatile' and
                                          `signed' under -XANSI (the
                                          upper bound from the next
                                          cell, +0x2AC4).  get hands
                                          them out as lex_token;
                                          attributes, c_expr_sem,
                                          c_expr_syn, c_stmt_sem and
                                          c_syntax compare them }
  lex_total_lines: extern integer32;    { +0x2AE0: the lines read when
                                          the main file ended (c_main) }
  lex_token: extern il_$node_ptr_t;     { +0x2AE4: the current token
                                          (get): an identifier (class
                                          76, or a reserved word's), a
                                          constant node (81, 82, 85,
                                          88, 89), a string (92, 93),
                                          an entry of lex_tokens, or
                                          kw_options or kw_attribute;
                                          c_expr_syn, c_syntax }
  lex_systype_state: extern integer;    { +0x2AF0: 2 once a #systype
                                          was taken (c_main) }
  lex_inline_state: extern integer;     { +0x2AF2: inside #pragma
                                          begin_inline (1),
                                          begin_noinline (2), neither
                                          (0); c_def_sem }
  lex_module_seen: extern boolean;      { +0x2AFE: a #module was seen;
                                          c_main, c_syntax }

  { c_stmt_sem.pas's data, A5 0x14A694 (cc.m68k), 0x2CA694 (cc.a88k). }
  { +0x400..+0x40C: two (identifier, word) pairs cc (c_main) sets up
    with idntk(76, ...) and a cleared word; sym_map (c_sym_map) omits
    variables of these names. }
  id_end_of_for: extern il_$node_ptr_t; { +0x400: `end_of_for' }
  cst_404: extern integer;              { +0x404: c_main }
  id_end_of_while: extern il_$node_ptr_t;  { +0x408: `end_of_while' }
  cst_40c: extern integer;              { +0x40C: c_main }
  cst_stack_size: extern integer32;     { +0x5F4: as_info_$stack_size
                                          (c_main) }
  cst_5fa: extern integer;              { +0x5FA: c_main }

  { c_syntax.pas's data, A5 0x14AC94 (cc.m68k), 0x2CAC94 (cc.a88k;
    c_sym_map has none, its A5 is the same address). }
  id_main: extern il_$node_ptr_t;       { +0x48: `main' (c_main, which
                                          passes its address, a
                                          c_name_t with csyn_4c);
                                          c_def_sem }
  csyn_4c: extern integer;              { +0x4C: c_main }
  id_at: extern il_$node_ptr_t;         { +0x50: the identifier `@'
                                          (idntk(76, ...) in cc), the
                                          name of unnamed fields and
                                          variables (c_sym_map omits
                                          them); c_def_sem, c_main }
  csyn_54: extern integer;              { +0x54: c_main }
  id_string_constant: extern il_$node_ptr_t;  { +0x58: the identifier
                                          `<string-constant>' (cc);
                                          c_expr_syn, c_main,
                                          c_stmt_sem, c_sym_map }
  csyn_5c: extern integer;              { +0x5C: c_main }
  csyn_60: extern array [1..128] of integer;  { +0x60..+0x15F: a
                                          stack of calling contexts,
                                          csyn_202 its top (cc pushes
                                          3; c_expr_syn's func_call_stat
                                          pushes the called block's
                                          conv, 3 for a function type,
                                          and pops it; 4 makes
                                          c_expr_syn skip the address
                                          of a string, its redundant-&
                                          warning and adjust_parm; the
                                          bound from the next cell) }
  { +0x160..+0x1E4: the attribute keywords, identifiers cc (c_main)
    enters with idntk(76, ...) (the `idu_' ones spelled with two
    leading underscores); attributes's find_conflict and
    merge_attribs_natural compare them. }
  id_volatile: extern il_$node_ptr_t;   { +0x160 }
  idu_volatile: extern il_$node_ptr_t;  { +0x164 }
  id_read: extern il_$node_ptr_t;       { +0x168 }
  idu_read: extern il_$node_ptr_t;      { +0x16C }
  id_write: extern il_$node_ptr_t;      { +0x170 }
  idu_write: extern il_$node_ptr_t;     { +0x174 }
  id_address: extern il_$node_ptr_t;    { +0x178 }
  idu_address: extern il_$node_ptr_t;   { +0x17C }
  id_bit: extern il_$node_ptr_t;        { +0x180 }
  id_byte: extern il_$node_ptr_t;       { +0x184 }
  id_word: extern il_$node_ptr_t;       { +0x188 }
  id_long: extern il_$node_ptr_t;       { +0x18C }
  id_quad: extern il_$node_ptr_t;       { +0x190 }
  id_size: extern il_$node_ptr_t;       { +0x194 }
  id_aligned: extern il_$node_ptr_t;    { +0x198 }
  idu_aligned: extern il_$node_ptr_t;   { +0x19C }
  id_natural: extern il_$node_ptr_t;    { +0x1A0 }
  idu_natural: extern il_$node_ptr_t;   { +0x1A4 }
  id_unaligned: extern il_$node_ptr_t;  { +0x1A8 }
  id_physical: extern il_$node_ptr_t;   { +0x1AC }
  id_processor_register: extern il_$node_ptr_t;  { +0x1B0 }
  id_fp_internal_register: extern il_$node_ptr_t;  { +0x1B4 }
  id_register: extern il_$node_ptr_t;   { +0x1B8 }
  id_immediate: extern il_$node_ptr_t;  { +0x1BC }
  id_reference: extern il_$node_ptr_t;  { +0x1C0 }
  id_atomic: extern il_$node_ptr_t;     { +0x1C4 }
  idu_atomic: extern il_$node_ptr_t;    { +0x1C8 }
  id_no_fp: extern il_$node_ptr_t;      { +0x1CC }
  id_save_db: extern il_$node_ptr_t;    { +0x1D0 }
  id_section: extern il_$node_ptr_t;    { +0x1D4 }
  idu_section: extern il_$node_ptr_t;   { +0x1D8 }
  id_resident_procedure: extern il_$node_ptr_t;  { +0x1DC }
  id_device: extern il_$node_ptr_t;     { +0x1E0 }
  idu_device: extern il_$node_ptr_t;    { +0x1E4 }
  csyn_1e8: extern univ_ptr;            { +0x1E8: c_stmt_sem add_ldfn }
  idu_options: extern il_$node_ptr_t;   { +0x1F0: `__options' (c_main) }
  idu_attribute: extern il_$node_ptr_t; { +0x1F4: `__attribute' }
  con_minus_one: extern il_$node_ptr_t; { +0x1F8: smcontk(81, -1)
                                          (c_main); c_expr_syn }
  con_zero: extern il_$node_ptr_t;      { +0x1FC: smcontk(81, 0)
                                          (c_main); c_expr_syn }
  token_kind: extern integer;           { +0x200: the current token's
                                          class, lex_token^.kind (set by
                                          c_lex_pp's get and
                                          clex_$unget; ctk_ constants,
                                          76 an identifier, 81..85 an
                                          integer constant, 92 and 93
                                          strings); c_expr_sem,
                                          c_expr_syn, c_main }
  csyn_202: extern integer;             { +0x202: csyn_60's top (cc
                                          sets 1); c_expr_sem,
                                          c_expr_syn, c_main }
  csyn_204: extern boolean;             { +0x204: an assignment or an
                                          increment was parsed
                                          (c_expr_syn's asn_expr,
                                          unary_expr set it; its
                                          test_side_effects clears it
                                          before the right operand of
                                          `&&', `||' and `?:'s last) }

  { unix_objmod.pas's data, A5 0x1A0314 (cc.m68k), 0x320384 (cc.a88k):
    two cells the front end sets (c_lex_pp, c_main) and the object
    module writer reads.  Here because neither front-end unit opens
    unix_objmod.ins.pas; unix_objmod defines them. }
  uobj_hp_standard: extern integer32;   { +0x5DD0: the bits #pragma
                                          HP_STANDARD n sets (bit n,
                                          0..31) }
  uobj_systype_2: extern boolean;       { +0x5E16: a #systype whose
                                          first version number
                                          (c_$decode_version) is 2 }

{ ERRORLST - list (and type) diagnostic code at line with its nargs
  arguments.  c_error.pas 0x0495EC; error_listing's error0..error3 pass
  everything by address (nargs a literal word), so the heading is here,
  in an insert error_listing opens. }
procedure errorlst(
    in code: integer;
    in line: integer;
    in args: univ cerr_args_t;
    in nargs: integer); extern;
