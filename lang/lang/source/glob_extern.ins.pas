{ lang/lang/source/glob_extern.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Variables and foreign headings the compiler's units share (no unit
  of this name).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ Nothing in the image requires a declaration here: every shared cell
  and foreign routine the prelude's users need is declared in the
  provider inserts or in globals_from_frontend, globals_from_backend,
  globals_from_general, real_externals and us/us/ins/lib.ins.pas
  (docs/core-plan.md, step 4).  What the original held here is not
  known; a translator who finds a name no insert declares and no
  customer insert provides adds it to one of those, or here with the
  evidence. }
