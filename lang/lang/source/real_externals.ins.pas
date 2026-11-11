{ lang/lang/source/real_externals.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Variables and foreign headings the compiler's units share (no unit
  of this name).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ The Pascal run time's NEW and DISPOSE, called directly where the size is
  known only at run time (gspace32 0x07D5B4, gspace_$release 0x07D6B8).
  The headings are the run time's own (lib/ftnlib/new_dispose.pas in the
  source repository).

  Not known from the original: which prelude insert declares them. }
procedure pas_$new(
    out p: univ univ_ptr;
    size: integer32); options(val_param); extern;

procedure pas_$dispose(
    in out p: univ univ_ptr;
    size: integer32); options(val_param); extern;

{ FTN_$DLOG10 - the Fortran library's double-precision log10 (transfer
  vector), called by add_node and kfold, which open no insert that
  declares it: two addresses, the first the result (add_node 0x0A3CEE
  `pea x; pea r; jsr', then reads r).  Placed here as the prelude's
  real-arithmetic externals.

  Not known from the original: the insert that declared it, and whether
  it was declared as this procedure or as a function. }
procedure ftn_$dlog10(
    out r: double;
    in x: double); extern;
