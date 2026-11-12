{ dfa - the DFA phase of the PRISM back end (at_backend's phase table
  entry 3, 'd', "DFA"): the flow graph's intervals, the global data
  flow (unless at_backend_$begin_compilation's options say not, or the
  phase's switch 9 is set) and the dominators.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x22F0A8  dfa_$begin_compilation
    --------  0x22F0AA  dfa_$end_routine
    --------  0x22F0AC  dfa_$end_compilation
    --------  0x22F0AE  dfa_$process_routine
    A5 0x48606C: the module's data, 8 bytes to dmp's (level at +0).

  Not known from the original: the names of level and of the routine
  parameter. }
module dfa;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/utils.ins.pas';

var
  level: integer32;                     { +0: the phase's switches'
                                          level, for the walks }

{ dfa_$begin_compilation - nothing.  0x22F0A8, 2 bytes. }

procedure dfa_$begin_compilation;
begin
end;

{ dfa_$end_routine - nothing.  0x22F0AA, 2 bytes. }

procedure dfa_$end_routine(
    rtn: rtn_ptr_t);
begin
end;

{ dfa_$end_compilation - nothing.  0x22F0AC, 2 bytes. }

procedure dfa_$end_compilation;
begin
end;

{ dfa_$process_routine - the routine's intervals, its global data flow
  and its dominators.

  0x22F0AE, 0xDA bytes: the routine in A2.  level := the switches' bits
  2..0 (`moveq #7; and.b 0x485D31', stored at (A5)).  Every lifetime
  segment of every live range has its +40 cleared (the lrs at +52
  chained at +12, each one's segments at +36 chained at +8).  Unless
  lir_main_da4 (`tst.b; bmi') or switch 9 (`btst #1,0x485D30'): the
  bit vectors released, the loops made unconditional, the dfs lists
  (level, switch 3 by `sne'), the intervals again and the global walk
  (the routine's +192, 1 as a word, level).  Last the dominators (true
  by `st', the switches' level read again; a 2-byte pad pushed first). }

procedure dfa_$process_routine(
    rtn: rtn_ptr_t);
var
  lr: lr_ptr_t;
  lts: lts_ptr_t;
begin
  lir_utils_$sanity_check(rtn);
  level := at_backend_switches.level;
  lr := rtn^.lrs;
  while lr <> nil do begin
    lts := lr^.ltss;
    while lts <> nil do begin
      lts^.l40 := 0;
      lts := lts^.next;
    end;
    lr := lr^.next;
  end;
  fg_utils_$intervals(rtn);
  if not lir_main_da4 and not at_backend_switches.sw9 then begin
    bv_$release_bit_vectors(rtn);
    fg_utils_$make_loops_unconditional(rtn);
    fg_utils_$compute_dfs_lists(rtn, level, at_backend_switches.sw3);
    fg_utils_$intervals(rtn);
    df_utils_$global_walk(rtn, rtn^.l192, 1, level);
  end;
  fg_utils_$dominators(rtn, true, at_backend_switches.level);
end;
