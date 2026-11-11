{ lang/lang/source/final.ins.pas - the insert of the m68k back end's
  final phase (lang/lang/source/final.pas, cc.m68k only).

  No Apollo copy survives.  A stub: lang/lang/source/celpkg.pas opens it
  and uses nothing from it; cg_top calls peepholer and jmp_br_setup
  (jmp_br_resolve.pas, whose units open this insert).

  Not known from the original: everything about its contents.
}

{ TODO(pascal) final.ins.pas is a stub

  Declarations are added as final.pas and its callers are translated. }

{ PEEPHOLER - the peephole pass over a routine's code cells, from first
  (the cell after the one that ended the previous routine) in section
  sect.  final 0x1120A0: 8 a pointer, 12 a longword (cg_top's codegen,
  after the last pass). }
procedure peepholer(
    sect: univ_ptr;
    first: univ_ptr); options(val_param); extern;

{ JMP_BR_SETUP - the branches of a routine's code cells (from first, in
  section sect) set up for their sizes.  jmp_br_resolve 0x0BA8A6: two
  pointers (cg_top's codegen). }
procedure jmp_br_setup(
    sect: univ_ptr;
    first: univ_ptr); options(val_param); extern;
