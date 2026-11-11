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
