{ target_at_dummies - the entries of cc.m68k's code generator (reg_save,
  reg_alloc, cg_top, final, outbin) and the ISC's language hook that the
  common code calls: dummies in cc.a88k.  The functions answer no
  registers (reg_save, reg_save_$registers_preserved_by_statement) or
  the stack size 0x7FFC0 (as_info_$stack_size); the procedures do
  nothing.  The counterpart of cc.m68k's target_68k_dummies.pas.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x27B6C0  reg_save
    --------  0x27B6D6  reg_save_$registers_preserved_by_statement
    --------  0x27B6EC  f_initialize
    --------  0x27B6EE  finaldriver
    --------  0x27B6F0  as_info_$stack_size
    --------  0x27B70A  isc_$set_source_language
    --------  0x27B70C  outcode
    --------  0x27B70E  reg_alloc
    --------  0x27B710  add_proc_reloc
    A5 0x492F7C (tm_utils'): the module has no data.

  The unit opens base, pgm, vfmt and bug_check only, so its headings
  are its own; they follow the prelude's (globals_from_backend.ins.pas:
  reg_save, f_initialize, finaldriver, isc_$set_source_language;
  g_opt.ins.pas: reg_alloc; outbin.ins.pas: add_proc_reloc, outcode;
  us/us/ins/as_info.ins.pas) with univ_ptr for the prelude's node
  pointers.  The functions load A5 (`link #-4', the result slot); the
  procedures are a lone `rts' (docs/rev889-patterns.md 13).  In cc.m68k
  reg_save and reg_save_$registers_preserved_by_statement are
  reg_save.pas's, f_initialize cg_top's, finaldriver final's, reg_alloc
  reg_alloc.pas's, add_proc_reloc and outcode outbin's;
  as_info_$stack_size is a system library routine there.

  Not known from the original: the parameters' names (none is read). }
module target_at_dummies;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { globals_from_backend.ins.pas's: register numbers 0..31. }
  reg_save_$regs_t = set of 0..31;

{ reg_save - no registers.  0x27B6C0, 0x16 bytes: `clr.l D0'. }

function reg_save(
    n: univ_ptr): reg_save_$regs_t; options(val_param);
begin
  reg_save := [];
end;

{ reg_save_$registers_preserved_by_statement - no registers.  0x27B6D6,
  0x16 bytes: `clr.l D0'. }

function reg_save_$registers_preserved_by_statement(
    s: univ_ptr): reg_save_$regs_t; options(val_param);
begin
  reg_save_$registers_preserved_by_statement := [];
end;

{ f_initialize - nothing.  0x27B6EC, 2 bytes. }

procedure f_initialize;
begin
end;

{ finaldriver - nothing.  0x27B6EE, 2 bytes. }

procedure finaldriver;
begin
end;

{ as_info_$stack_size - 0x7FFC0.  0x27B6F0, 0x1A bytes: `move.l
  #524224,D0'. }

function as_info_$stack_size: integer32;
begin
  as_info_$stack_size := 16#7FFC0;
end;

{ isc_$set_source_language - nothing.  0x27B70A, 2 bytes. }

procedure isc_$set_source_language(
    lang: integer); options(val_param);
begin
end;

{ outcode - nothing.  0x27B70C, 2 bytes. }

procedure outcode;
begin
end;

{ reg_alloc - nothing.  0x27B70E, 2 bytes. }

procedure reg_alloc;
begin
end;

{ add_proc_reloc - nothing.  0x27B710, 2 bytes. }

procedure add_proc_reloc(
    vaddr: integer32;
    sect: univ_ptr;
    symndx: integer32;
    target: univ_ptr); options(val_param);
begin
end;
