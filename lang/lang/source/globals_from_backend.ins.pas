{ lang/lang/source/globals_from_backend.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Variables and foreign headings the compiler's units share (no unit
  of this name).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

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

var
  { runbackend.pas's data, A5 0x2C33B0 (cc.m68k), 0x443420 (cc.a88k).
    gen_utils, which opens no back-end insert, reads +0xC; c_main sets
    +0xC and +0x10 from c_expr_sem's +0x2398 and +0x2394. }
  runbackend_08: extern univ_ptr;       { +0x8: cg_addr, cg_top (cc.m68k) }
  runbackend_0c: extern univ_ptr;       { +0xC: c_main, gen_utils,
                                          opt_strength, reg_alloc }
  runbackend_10: extern univ_ptr;       { +0x10: c_main, opt_strength }
  runbackend_14: extern integer;        { +0x14: the source language
                                          run_backend is given; cc.a88k's
                                          post reads it }
  runbackend_16: extern integer;        { +0x16: opt_main sets it; opt_*,
                                          reg_*, cc.a88k's at_backend
                                          and dmp read it }

  { A back-end cell: cc.a88k's at_backend.pas, A5 0x485830, +0x506
    (rewrite clears it); cc.m68k's cg_top.pas, A5 0x356314, +0x148
    (0x35645C: emit, fpa, cg_addr, cg_call, cg_fp test it).  runbackend
    sets it and clears it (run_backend, optimize_and_code). }
  at_backend_506: extern boolean;

{ The back end's entry points runbackend calls: cc.m68k's in lang/lang
  (cg_top, final, opt_inline, opt_main) and empty a88k ones in
  target_68k_dummies.pas; cc.a88k's in lang2/source/be_com and empty
  m68k ones in target_at_dummies.pas.  None takes parameters or returns
  a value unless shown. }
procedure codegen; extern;                      { cg_top 0x0FE62A; cc.a88k at_backend 0x222756 }
procedure f_initialize; extern;                 { cg_top 0x0FBCA8 }
procedure finaldriver; extern;                  { final 0x112116 }
procedure inline_$inline_expand; extern;        { opt_inline 0x094066 (cc.a88k 0x095A46) }
procedure g_opt; extern;                        { opt_main 0x0E0D46 (cc.a88k 0x2ADF36) }
procedure opt_main_$initialize; extern;         { opt_main 0x0E1740 (cc.a88k 0x2AE930) }
procedure at_backend_$end_compilation; extern;  { cc.a88k 0x2221BA }
procedure bin_$emit_compilation_pure_text; extern;  { cc.a88k bin 0x224314; unix_objmod calls it }

{ RUN_BACKEND - the back end, after the front end (runbackend.pas
  0x0B22CC, cc.a88k 0x0B3CAC): compiler (a word, by address: c_main
  passes 1 from its literals), the routine that lists the source up to
  a line (c_main passes do_lex_for_listings' address, `move.l #'; it
  is called with `jsr (A0)'), the last line (by address) and a pointer
  by address (c_main's literal nil: `pea' of a constant in the code,
  cc.m68k 0x05B95C).  The parameter names are runbackend.pas's (dpc
  takes a routine's parameters from its first declaration). }
type
  { The routine run_backend is given to list the source up to a line
    (c_main's do_lex_for_listings), called with `jsr (A0)'.  Here
    because the prelude's heading needs it; unix_objmod.ins.pas's
    unix_objmod_$lex_proc_t is this type. }
  runbackend_$lex_proc_t = ^procedure;

procedure run_backend(
    in lang: univ integer;
    do_lex: runbackend_$lex_proc_t;
    in line: univ integer;
    in hook: univ runbackend_$lex_proc_t); options(val_param); extern;

{ AT_BACKEND_$BEGIN_COMPILATION - cc.a88k 0x221D3C: a word by value. }
procedure at_backend_$begin_compilation(
    p: integer); options(val_param); extern;

{ AT_BACKEND_$INITIALIZE_FTN_ENTRY - cc.a88k 0x22235A: a pointer
  (runbackend pushes an address). }
procedure at_backend_$initialize_ftn_entry(
    p: univ_ptr); options(val_param); extern;

{ AT_BACKEND_$CAN_LOAD_MODULE_DB - cc.a88k 0x222376: a pointer;
  runbackend tests the byte in D0.  cc.m68k's dummy 0x0CA220. }
function at_backend_$can_load_module_db(
    p: univ_ptr): boolean; options(val_param); extern;

{ ISC_$SET_SOURCE_LANGUAGE - a word by value (both dummies; runbackend). }
procedure isc_$set_source_language(
    lang: integer); options(val_param); extern;

{ SYM_$DISPLACEMENT - cc.a88k sym 0x27AF82: a pointer; callers
  (gen_exception, unix_objmod, cc.a88k's bin, lst, lir_utils, utils)
  read D0 as a longword.  cc.m68k's dummy 0x0CA240. }
function sym_$displacement(
    p: univ_ptr): integer32; options(val_param); extern;

{ SYM_$DISPLACEMENT_LITERAL_POOL - cc.a88k sym 0x27AF3E: two pointers;
  unix_objmod reads D0.  cc.m68k's dummy 0x0CA256. }
function sym_$displacement_literal_pool(
    p1: univ_ptr;
    p2: univ_ptr): integer32; options(val_param); extern;
