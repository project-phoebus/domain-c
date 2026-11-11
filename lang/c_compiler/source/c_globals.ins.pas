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

{ TODO(pascal) most cells are named by offset

  Rename them as their owners and users are translated (c_main sets
  most of them up). }

var
  { c_def_sem.pas's data, A5 0x140054 (cc.m68k), 0x2C0054 (cc.a88k).
    cc (c_main) sets six (longword, word) pairs at +0x4..+0x2C. }
  cdef_00: extern integer32;            { +0x0: c_def_sem, c_main }
  cdef_04: extern integer;              { +0x4: c_main }
  cdef_08: extern integer32;            { +0x8: c_main }
  cdef_0c: extern integer;              { +0xC: c_main }
  cdef_10: extern integer32;            { +0x10: c_main }
  cdef_14: extern integer;              { +0x14: c_main }
  cdef_18: extern integer32;            { +0x18: c_main }
  cdef_1c: extern integer;              { +0x1C: c_main }
  cdef_20: extern integer32;            { +0x20: c_main }
  cdef_24: extern integer;              { +0x24: c_main }
  cdef_28: extern integer32;            { +0x28: c_main }
  cdef_2c: extern integer;              { +0x2C: c_main }
  cdef_38: extern integer32;            { +0x38: c_lex_pp section_sem,
                                          c_main make_main_pgm }
  cdef_3c: extern integer32;            { +0x3C: c_lex_pp section_sem,
                                          c_main }
  cdef_44: extern univ_ptr;             { +0x44: c_syntax }
  cdef_4c: extern integer32;            { +0x4C: c_syntax }
  cdef_50: extern univ_ptr;             { +0x50: c_expr_sem, c_expr_syn,
                                          c_main, c_stmt_sem, c_syntax }
  cdef_54: extern univ_ptr;             { +0x54: c_lex_pp module_sem,
                                          c_main, c_stmt_sem, c_syntax;
                                          cc sets it to il_180 }

  { c_error.pas's data, A5 0x1400AC (cc.m68k), 0x2C00AC (cc.a88k):
    one byte, tested (tst.b) by c_error's routines through A5 and by
    c_lex_pp, c_main and error_listing absolutely. }
  cerr_00: extern boolean;              { +0x0 }

  { c_expr_sem.pas's data, A5 0x1400B0 (cc.m68k), 0x2C00B0 (cc.a88k).
    The basic types, made by c_main's init_basic_types: 8-byte integral
    nodes (kind 122; +4 the length, +6 signed), 6-byte floating nodes
    (kind 123; +4 6 or 7) and 4-byte nodes of kinds 210 and 136. }
  cexs_390: extern integer32;           { +0x390: c_stmt_sem walk_tree }
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
  cexs_23bc: extern integer;            { +0x23BC: add_node, c_def_sem,
                                          c_expr_syn, c_main, c_stmt_sem,
                                          c_syntax }

  { c_lex_pp.pas's data, A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k). }
  lex_49a: extern integer;              { +0x49A: c_main (a length; a
                                          buffer follows at +0x49C) }
  lex_14b2: extern integer;             { +0x14B2: c_main (a length; a
                                          buffer follows at +0x14B4) }
  lex_line: extern integer;             { +0x24C8: the current source
                                          line (spos's encoding), the
                                          line errors are reported at:
                                          attributes, c_def_sem,
                                          c_expr_sem, c_expr_syn,
                                          c_macro_read, c_main,
                                          c_stmt_sem, c_syntax }
  lex_24cc: extern boolean;             { +0x24CC: c_error, c_main }
  lex_24cd: extern boolean;             { +0x24CD: c_error (set by
                                          error_hdr), c_main }
  lex_24d0: extern boolean;             { +0x24D0: c_error, c_syntax }
  lex_24d1: extern boolean;             { +0x24D1: c_error }
  lex_24d2: extern boolean;             { +0x24D2: c_error }
  lex_errors: extern integer;           { +0x24D4: errors reported
                                          (error_hdr); c_main,
                                          runbackend }
  lex_warnings: extern integer;         { +0x24D6: warnings reported
                                          (error_hdr); c_main }
  lex_infos: extern integer;            { +0x24D8: informational
                                          messages (error_hdr); c_main }
  lex_24da: extern integer;             { +0x24DA: attributes counts }
  lex_24dc: extern integer;             { +0x24DC: attributes counts }
  lex_text: extern varying [256] of char;  { +0x24DE: the current
                                          source line's text (error_hdr
                                          copies at most 256
                                          characters) }
  lex_26e8: extern array [0..9] of integer32;  { +0x26E8..+0x270C:
                                          c_main rword_init }
  lex_273c: extern integer32;           { +0x273C: c_syntax }
  lex_278c: extern integer32;           { +0x278C: c_expr_syn,
                                          c_syntax }
  lex_27e0: extern integer32;           { +0x27E0: c_syntax }
  lex_27ec: extern integer32;           { +0x27EC: c_expr_sem }
  lex_27f4: extern integer32;           { +0x27F4: c_stmt_sem }
  lex_280c: extern integer32;           { +0x280C: c_expr_sem }
  lex_2824: extern integer32;           { +0x2824: c_expr_sem,
                                          c_expr_syn, c_main, c_syntax }
  lex_28a8: extern integer32;           { +0x28A8: attributes, c_main }
  lex_28ac: extern integer32;           { +0x28AC: c_main }
  lex_28b0: extern integer32;           { +0x28B0: c_main }
  lex_2ae0: extern integer32;           { +0x2AE0: c_main }
  lex_2ae4: extern univ_ptr;            { +0x2AE4: c_expr_syn,
                                          c_syntax }
  lex_2af0: extern integer;             { +0x2AF0: c_main }
  lex_2af2: extern integer;             { +0x2AF2: c_def_sem }
  lex_2afe: extern boolean;             { +0x2AFE: c_main, c_syntax }

  { c_stmt_sem.pas's data, A5 0x14A694 (cc.m68k), 0x2CA694 (cc.a88k). }
  cst_400: extern integer32;            { +0x400: c_main, c_sym_map }
  cst_404: extern integer;              { +0x404: c_main }
  cst_408: extern integer32;            { +0x408: c_main, c_sym_map }
  cst_40c: extern integer;              { +0x40C: c_main }
  cst_5f4: extern integer32;            { +0x5F4: c_main }
  cst_5fa: extern integer;              { +0x5FA: c_main }

  { c_syntax.pas's data, A5 0x14AC94 (cc.m68k), 0x2CAC94 (cc.a88k;
    c_sym_map has none, its A5 is the same address).  +0x160..+0x1E4:
    longwords cc (c_main) sets, attributes's find_conflict and
    merge_attribs_natural read. }
  csyn_48: extern integer32;            { +0x48: c_def_sem, c_main }
  csyn_4c: extern integer;              { +0x4C: c_main }
  csyn_50: extern integer32;            { +0x50: c_def_sem, c_main,
                                          c_sym_map }
  csyn_54: extern integer;              { +0x54: c_main }
  csyn_58: extern integer32;            { +0x58: c_expr_syn, c_main,
                                          c_stmt_sem, c_sym_map }
  csyn_5c: extern integer;              { +0x5C: c_main }
  csyn_60: extern integer;              { +0x60: c_main }
  csyn_160: extern univ_ptr;            { +0x160 }
  csyn_164: extern integer32;           { +0x164 }
  csyn_168: extern integer32;           { +0x168 }
  csyn_16c: extern integer32;           { +0x16C }
  csyn_170: extern integer32;           { +0x170 }
  csyn_174: extern integer32;           { +0x174 }
  csyn_178: extern univ_ptr;            { +0x178 }
  csyn_17c: extern integer32;           { +0x17C }
  csyn_180: extern integer32;           { +0x180 }
  csyn_184: extern integer32;           { +0x184 }
  csyn_188: extern integer32;           { +0x188 }
  csyn_18c: extern integer32;           { +0x18C }
  csyn_190: extern integer32;           { +0x190 }
  csyn_194: extern univ_ptr;            { +0x194 }
  csyn_198: extern univ_ptr;            { +0x198 }
  csyn_19c: extern integer32;           { +0x19C }
  csyn_1a0: extern univ_ptr;            { +0x1A0 }
  csyn_1a4: extern integer32;           { +0x1A4 }
  csyn_1a8: extern integer32;           { +0x1A8 }
  csyn_1ac: extern univ_ptr;            { +0x1AC }
  csyn_1b0: extern univ_ptr;            { +0x1B0 }
  csyn_1b4: extern univ_ptr;            { +0x1B4 }
  csyn_1b8: extern univ_ptr;            { +0x1B8 }
  csyn_1bc: extern univ_ptr;            { +0x1BC }
  csyn_1c0: extern univ_ptr;            { +0x1C0 }
  csyn_1c4: extern univ_ptr;            { +0x1C4 }
  csyn_1c8: extern integer32;           { +0x1C8 }
  csyn_1cc: extern univ_ptr;            { +0x1CC }
  csyn_1d0: extern univ_ptr;            { +0x1D0 }
  csyn_1d4: extern univ_ptr;            { +0x1D4 }
  csyn_1d8: extern integer32;           { +0x1D8 }
  csyn_1dc: extern univ_ptr;            { +0x1DC }
  csyn_1e0: extern integer32;           { +0x1E0 }
  csyn_1e4: extern integer32;           { +0x1E4 }
  csyn_1e8: extern univ_ptr;            { +0x1E8: c_stmt_sem add_ldfn }
  csyn_1f0: extern integer32;           { +0x1F0: c_main }
  csyn_1f4: extern integer32;           { +0x1F4: c_main }
  csyn_1f8: extern univ_ptr;            { +0x1F8: c_expr_syn, c_main }
  csyn_1fc: extern integer32;           { +0x1FC: c_expr_syn, c_main }
  csyn_200: extern integer;             { +0x200: c_expr_sem,
                                          c_expr_syn, c_lex_pp, c_main }
  csyn_202: extern integer;             { +0x202: c_expr_sem,
                                          c_expr_syn, c_main }
  csyn_204: extern boolean;             { +0x204: c_expr_syn }
