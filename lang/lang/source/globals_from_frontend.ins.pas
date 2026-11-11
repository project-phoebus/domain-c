{ lang/lang/source/globals_from_frontend.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Variables and foreign headings the compiler's units share (no unit
  of this name).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ What each front end supplies to the common code. }

{ CGERR_NO_SOURCE - report error code (with arg) with no source position.
  The C front end's is c_error.pas 0x0491EC (cc.m68k): code a word at
  (8,A6), arg a longword at (10,A6), passed on to cgerr with the current
  line.  Callers: gspace32 (codes 28, 9).

  Not known from the original: the parameter names; arg's meaning. }
procedure cgerr_no_source(
    code: integer;
    arg: integer32); options(val_param); extern;

{ How the declarations were placed (docs/core-plan.md, step 4): a
  routine or cell is declared in the prelude when a unit that opens the
  prelude uses it and opens no other insert that could declare it (the
  owner's own insert, or the front end's c_externs.ins.pas and
  c_globals.ins.pas, or the back end's codegen, cg, g_opt and final
  inserts).  globals_from_frontend holds what the C front end (lang/
  c_compiler) supplies, globals_from_backend what the back ends supply
  to runbackend and the common units, globals_from_general what the
  other lang/lang units supply.  lang/lang/source/target_68k_dummies.pas,
  cc.m68k's empty a88k back-end entries, opens the prelude only as far
  as globals_from_backend, where those entries are declared.

  Not known from the original: which of the three inserts (or which
  earlier insert of the prelude) declared each name; every name given
  by offset. }

{ The headings below are read off the frames and the call sites (the
  method of gen_utils.ins.pas): a pointer is univ_ptr until its target is
  known, every slot a value (val_param).

  Not known from the original: the parameter names and most types. }

{ TYPE_EXP - c_def_sem.pas 0x04590A (cc.a88k 0x045B8A): 8 a pointer
  (moved to an address register), 12 an address (callers `pea'); 135
  call sites, those outside the front end in coff_syms, debug_sym_dmp,
  list_tree and opt_inline, which open neither c_externs nor c_globals;
  the callers do not read D0 or A0. }
procedure type_exp(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ CGERR - report error code at line with one argument (an address).
  c_error.pas 0x049A00 (cc.a88k 0x049C80): 8 and 10 words, 12 a
  pointer; 77 call sites (commit_top_node, debug_sym_dmp, opt_inline,
  cc.a88k's bin, fg_utils, lir_utils, rewrite, ...). }
procedure cgerr(
    code: integer;
    line: integer;
    arg: univ_ptr); options(val_param); extern;

{ ADVANCE_LISTING_TO_LINE - c_lex_pp.pas 0x0533E8 (cc.a88k 0x053668):
  a word by value; list_tree, outbin (cc.a88k lst), runbackend. }
procedure advance_listing_to_line(
    line: integer); options(val_param); extern;

{ MODIFY_M2_NATIVE_EXTERNAL_NAME - frontend_cc_dummies.pas 0x0673EC
  (cc.a88k 0x06766C): an address; the callers (coff_syms) read A0. }
function modify_m2_native_external_name(
    name: univ_ptr): univ_ptr; options(val_param); extern;

{ ISC_$INIT_WELL_KNOWN_TYPES - fe_cc_hooks_to_backend.pas 0x06737C
  (cc.a88k 0x0675FC): stores the front end's int, float and double
  type nodes through its three by-address parameters (cc.a88k's
  lir_$begin_compilation 0x2429B2 passes the addresses of three
  longwords of its data); no caller in cc.m68k. }
procedure isc_$init_well_known_types(
    out int_type_node: univ_ptr;
    out float_type_node: univ_ptr;
    out double_type_node: univ_ptr); extern;

{ GET_ALIGNMENT - frontend_cc_dummies.pas 0x0673B4 (cc.a88k 0x067634):
  the C front end's dummy returns a longword in D0; cc.a88k's
  isc_user_routines passes an address. }
function get_alignment(
    p: univ_ptr): integer32; options(val_param); extern;
