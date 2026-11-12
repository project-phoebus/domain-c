{ jbr - the JBR phase of the PRISM back end: at_backend's phase table
  entry 16 ('j', "JBR", A5 0x485A4C) names its four routines, which do
  nothing (the branches' resolution is bin's and asm's in this back
  end; "jbr" after lang's jmp_br_resolve, most likely).

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x240164  jbr_$begin_compilation
    --------  0x240166  jbr_$end_compilation
    --------  0x240168  jbr_$process_routine
    --------  0x24016A  jbr_$end_routine
    A5 0x486D04 (konst's): the module has no data.

  Each routine is a lone `rts' (docs/rev889-patterns.md 13); at_backend
  calls them through its table (run_phase: process_routine and
  end_routine with the routine).

  Not known from the original: the routine parameter's name. }
module jbr;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';

{ jbr_$begin_compilation - nothing.  0x240164, 2 bytes. }

procedure jbr_$begin_compilation;
begin
end;

{ jbr_$end_compilation - nothing.  0x240166, 2 bytes. }

procedure jbr_$end_compilation;
begin
end;

{ jbr_$process_routine - nothing.  0x240168, 2 bytes. }

procedure jbr_$process_routine(
    rtn: rtn_ptr_t);
begin
end;

{ jbr_$end_routine - nothing.  0x24016A, 2 bytes. }

procedure jbr_$end_routine(
    rtn: rtn_ptr_t);
begin
end;
