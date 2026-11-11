{ lang/lang/source/globals_from_general.ins.pas - part of the compilers' common prelude
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

{ PUTOBJ - iosub.pas 0x0B5FD0 (cc.a88k likewise in iosub): 8 a
  longword (added to the object's current size), 12 a pointer (its
  address taken); 81 call sites (coff_syms, debug_sym_dmp, gen_debug,
  gen_unwind, outbin, unix_objmod open iosub.ins.pas; gen_exception does
  not), which read A0. }
function putobj(
    len: integer32;
    p: univ_ptr): univ_ptr; options(val_param); extern;
