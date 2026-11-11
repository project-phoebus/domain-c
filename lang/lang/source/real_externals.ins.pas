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
