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
    psect: univ_ptr;
    first: univ_ptr); options(val_param); extern;

{ The routines of final.pas that jmp_br_resolve.pas calls, read off
  final's frames (tools/cc_params.py) and jmp_br_resolve's call sites.
  Not known from the original: the parameter names; what detach,
  moverefcell and reversecond return (some callers read D0 or A0). }

{ DETACH - code cell c taken off its list.  0x108A8C: a pointer by
  value. }
procedure detach(
    c: codegen_$cell_ptr_t); options(val_param); extern;

{ NXTCC, NXTLCC - the code cell after c (nxtlcc: the next label or code
  cell).  0x108BEE, 0x108C88: a pointer by value, the cell in A0. }
function nxtcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

function nxtlcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

{ MAKEJUMP - c made a jump to target.  0x10B22E: two by value, a cell
  in A0. }
function makejump(
    c: codegen_$cell_ptr_t;
    target: codegen_$cell_ptr_t): codegen_$cell_ptr_t;
    options(val_param); extern;

{ MOVEREFCELL - reference cell ref moved to label lab's list.
  0x10B466: two by value. }
procedure moverefcell(
    ref: codegen_$cell_ptr_t;
    lab: codegen_$cell_ptr_t); options(val_param); extern;

{ REVERSECOND - conditional branch c's condition reversed.  0x10B890: a
  pointer by value. }
procedure reversecond(
    c: codegen_$cell_ptr_t); options(val_param); extern;
