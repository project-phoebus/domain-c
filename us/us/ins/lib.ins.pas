{ us/us/ins/lib.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  Apollo's internal /us/ins insert for the global library's LIB_
  routines (the compiler calls lib_$cv_fp_in, lib_$cv_sfp_out,
  lib_$cv_dfp_out and lib_$data_move).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ The headings are those of the global library's routines as
  reconstructed in the source repository (lib/syslib/lib_$cvfp_io.pas,
  lib/clib/ins/lib.ins.pas), checked against the compiler's call sites:
  lib_$cv_fp_in c_lex_pp get_number 0x0556C4 (s, len, exp words, neg
  and dbl bytes, r, overflow: 20 bytes); lib_$cv_dfp_out and
  lib_$cv_sfp_out prtobj_$prtobj_full 0x0AF9FC, 0x0AFA92 (s, value by
  address, five words and a byte pushed as three longwords);
  lib_$data_move (33 call sites: add_node, c_lex_pp, debug_sym_dmp,
  iosub, opt_inline) three addresses. }

type
  lib_$fp_result_t = record case integer of
    1: (d: double);
    2: (hi, lo: integer32);
    3: (s: real);
  end;

procedure lib_$cv_fp_in(
    in s: univ string;
    len: integer;
    exp: integer;
    neg: boolean;
    dbl: boolean;
    out r: univ lib_$fp_result_t;
    out overflow: boolean); options(val_param); extern;

procedure lib_$cv_dfp_out(
    out s: univ string;
    in value: double;
    kind: integer;
    width: integer;
    digits: integer;
    exp_width: integer;
    scale: integer;
    plus: boolean); options(val_param); extern;

procedure lib_$cv_sfp_out(
    out s: univ string;
    in value: real;
    kind: integer;
    width: integer;
    digits: integer;
    exp_width: integer;
    scale: integer;
    plus: boolean); options(val_param); extern;

procedure lib_$data_move(
    in src: univ_ptr;
    in dst: univ_ptr;
    in len: integer32); extern;
