{ lang/lang/source/prfpkg.ins.pas - PRFPKG, the compilers' performance
  statistics (lang/lang/source/prfpkg.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far.

  Not known from the original: the variables' names.
}

var
  { The space GSPACE has handed out and the most it ever had: longwords
    in prfpkg's data, A5 0x19CCE4 (cc.m68k) + 0x8FC and + 0x8F8
    (0x19D5E0, 0x19D5DC), kept by gspace32 and gspace_$release. }
  prf_gspace_in_use: extern integer32;
  prf_gspace_peak: extern integer32;

{ The compiler's phases are numbered 0..42 (prfpkg.pas's names: 0
  Syntax ... 19 Code Generation ... 42 Library Generation); 43 is no
  phase (and the totals' name). }

{ PERFINIT - clear the statistics.  0x0968D4. }
procedure perfinit; extern;

{ PERFSTART - start timing phase.  0x096960: a word by value. }
procedure perfstart(
    phase: integer); options(val_param); extern;

{ PERFSTOP - stop timing phase and add its times and counts.  0x0969FA:
  a word by value. }
procedure perfstop(
    phase: integer); options(val_param); extern;

{ PRFPKG_$ACTIVATE_PHASE - stop the active phase, if any, and start
  phase.  0x096B00: a word by value (35 call sites). }
procedure prfpkg_$activate_phase(
    phase: integer); options(val_param); extern;

{ PRFPKG_$STOP_ACTIVE_PHASE - stop the active phase, if any.
  0x096B32. }
procedure prfpkg_$stop_active_phase; extern;

{ PERFSUMMARY - the statistics into the listing (-STAT) and, with
  -METER, to standard output.  0x097648: c_main's cc passes the source
  line count, a longword by value, which only the nested
  print_meter_results reads. }
procedure perfsummary(
    source_line_count: integer32); options(val_param); extern;
