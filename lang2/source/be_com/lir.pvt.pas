{ lang2/source/be_com/lir.pvt.pas - the LIR builder's private insert (cc.a88k only): opened by lir,
  lir_main, lir_utils and ra_utils, after the ISC inserts and
  isc_var_externs.ins.pas.  It holds what those four share and the
  other units do not reach: lir.pas's cells at +0x3B80..+0x3C48,
  +0x41F0..+0x4216 (lir_main, lir_utils, ra_utils), lir_main.pas's
  +0x250..+0xAC0 and +0xDA0 (lir, lir_utils), ra_utils.pas's +0x10..
  +0x7C (lir, lir_utils), and the headings of the routines only they
  call (docs/backend-plan.md).

  No Apollo copy survives.  A stub, created with the back end's core
  (translator MM) so that the parallel translators extend one file;
  nothing in it yet.

  Not known from the original: everything about its contents. }

{ TODO(pascal) lir.pvt.pas: the cells and headings listed above }
