{ lang/lang/source/unix_objmod.ins.pas - the interface of
  lang/lang/source/unix_objmod.pas (the COFF object module).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the parameter names.
}

{ TODO(pascal) unix_objmod.ins.pas is incomplete

  The rest of the interface is added when unix_objmod.pas and its users
  are translated. }

{ TARGET_MAGIC - the COFF magic number of the target (404..407 by
  target_properties.p_10).  unix_objmod.pas 0x09949A (cc.m68k): no
  parameters, the result in D0. }
function target_magic: integer32; extern;

{ The routine run_backend's caller passes for unix_obj_gen (c_main's
  do_lex_for_listings, by value: `move.l #addr,-(SP)'). }
type
  unix_objmod_$lex_proc_t = runbackend_$lex_proc_t;  { the prelude's }

{ UNIX_OBJ_INIT - set up the object module.  cc.m68k 0x09F952 (cc.a88k
  0x0A1332): no parameters (run_backend). }
procedure unix_obj_init; extern;

{ UNIX_OBJ_GEN - write the object module.  cc.m68k 0x09F128 (cc.a88k
  0x0A0B08): a routine pointer by value at (8,A6), called through
  (run_backend passes its own). }
procedure unix_obj_gen(
    do_lex: unix_objmod_$lex_proc_t); options(val_param); extern;
