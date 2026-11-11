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

{ TODO(pascal) prfpkg.ins.pas is incomplete

  The rest of PRFPKG's interface is added when prfpkg.pas is
  translated. }
