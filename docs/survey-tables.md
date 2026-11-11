## cc.m68k

- maker: ld - DOMAIN version 7.11
- maker: bind
- maker: C compiler PRISM=>68K Rev 6.89(586)
- maker: ASM
- maker: Pascal compiler PRISM=>68K Rev 8.89(549)
- maker: Pascal compiler 68K Rev 8.89(546)
- maker: bind
- maker: Fortran 77 compiler PRISM=>68K Rev 10.89(615)
- maker: cc (program)
- units: 105 (asm 1, c 3, ftn 1, pas 100); routines: 2170; routine bytes: 731246

| # | file | lang | routines | code start | A5 | routine bytes | span |
|---|------|------|----------|------------|----|---------------|------|
| 0 | `lang/c_compiler/source/c_cond_read.pas` | pas | 7 | 0x0403D8 | 0x140000 | 1396 | 1548 |
| 1 | `lang/c_compiler/source/c_data.asm` | asm | 0 | 0x0409E4 | - | 0 | 18384 |
| 2 | `lang/c_compiler/source/c_def_sem.pas` | pas | 59 | 0x0451B4 | 0x140054 | 16336 | 16440 |
| 3 | `lang/c_compiler/source/c_error.pas` | pas | 8 | 0x0491EC | 0x1400AC | 2404 | 2508 |
| 4 | `lang/c_compiler/source/c_expr_sem.pas` | pas | 43 | 0x049BB8 | 0x1400B0 | 24678 | 24888 |
| 5 | `lang/c_compiler/source/c_expr_syn.pas` | pas | 28 | 0x04FCF0 | 0x142470 | 12070 | 12824 |
| 6 | `lang/c_compiler/source/c_general_utl.pas` | pas | 10 | 0x052F08 | 0x142520 | 974 | 976 |
| 7 | `lang/c_compiler/source/c_get_rlen.pas` | pas | 1 | 0x0532D8 | 0x142524 | 124 | 124 |
| 8 | `lang/c_compiler/source/c_initdate.c` | c | 1 | 0x053354 | 0x142528 | 146 | 148 |
| 9 | `lang/c_compiler/source/c_lex_pp.pas` | pas | 38 | 0x0533E8 | 0x142528 | 11858 | 12340 |
| 10 | `lang/c_compiler/source/c_macro_read.pas` | pas | 23 | 0x05641C | 0x14907C | 9978 | 10980 |
| 11 | `lang/c_compiler/source/c_macro_utl.pas` | pas | 19 | 0x058F00 | 0x1496B8 | 3668 | 4116 |
| 12 | `lang/c_compiler/source/c_main.pas` | pas | 13 | 0x059F14 | 0x1498C4 | 7142 | 7972 |
| 13 | `lang/c_compiler/source/c_run_acpp.c` | c | 3 | 0x05BE38 | 0x14A684 | 190 | 192 |
| 14 | `lang/c_compiler/source/c_stmt_sem.pas` | pas | 52 | 0x05BEF8 | 0x14A694 | 13032 | 13212 |
| 15 | `lang/c_compiler/source/c_sym_map.pas` | pas | 11 | 0x05F294 | 0x14AC94 | 5226 | 5956 |
| 16 | `lang/c_compiler/source/c_syntax.pas` | pas | 59 | 0x0609D8 | 0x14AC94 | 26112 | 27040 |
| 17 | `lang/c_compiler/source/fe_cc_hooks_to_backend.pas` | pas | 3 | 0x067378 | 0x14AEC8 | 60 | 60 |
| 18 | `lang/c_compiler/source/frontend_cc_dummies.pas` | pas | 4 | 0x0673B4 | 0x14AECC | 106 | 108 |
| 19 | `lang/common/source/ass.pas` | pas | 14 | 0x067420 | 0x14AECC | 1322 | 1428 |
| 20 | `lang/common/source/bvs.pas` | pas | 24 | 0x0679B4 | 0x14B000 | 1994 | 2692 |
| 21 | `lang/common/source/diag.pas` | pas | 13 | 0x068438 | 0x14B080 | 964 | 976 |
| 22 | `lang/common/source/ecb.pas` | pas | 1 | 0x068808 | 0x14B2F4 | 178 | 256 |
| 23 | `lang/common/source/htm.pas` | pas | 12 | 0x068908 | 0x14B2F4 | 1962 | 1996 |
| 24 | `lang/common/source/mem.pas` | pas | 19 | 0x0690D4 | 0x14B7F4 | 1902 | 2612 |
| 25 | `lang/common/source/pds.pas` | pas | 124 | 0x069B08 | 0x14B814 | 21480 | 33128 |
| 26 | `lang/common/source/spos.pas` | pas | 31 | 0x071C70 | 0x14B874 | 3356 | 5644 |
| 27 | `lang/common/source/std.pas` | pas | 11 | 0x07327C | 0x168D88 | 680 | 704 |
| 28 | `lang/common/source/token.pas` | pas | 8 | 0x07353C | 0x168D8C | 822 | 1192 |
| 29 | `lang/lang/source/opt_assign.pas` | pas | 9 | 0x0D393C | 0x2D2E48 | 3474 | 3596 |
| 30 | `lang/lang/source/opt_cse.pas` | pas | 16 | 0x0D4748 | 0x2D2E48 | 6888 | 6956 |
| 31 | `lang/lang/source/opt_general.pas` | pas | 9 | 0x0D6274 | 0x2D2ED8 | 1962 | 2072 |
| 32 | `lang/lang/source/opt_livevar.pas` | pas | 19 | 0x0D6A8C | 0x2D2ED8 | 7832 | 7892 |
| 33 | `lang/lang/source/opt_loop.pas` | pas | 12 | 0x0D8960 | 0x2D2EE0 | 8898 | 9000 |
| 34 | `lang/lang/source/opt_main.pas` | pas | 109 | 0x0DAC88 | 0x2D2EF0 | 26544 | 27736 |
| 35 | `lang/lang/source/opt_reachdef.pas` | pas | 37 | 0x0E18E0 | 0x352F8C | 15600 | 15860 |
| 36 | `lang/lang/source/opt_select.pas` | pas | 11 | 0x0E56D4 | 0x3530D4 | 1976 | 1976 |
| 37 | `lang/lang/source/opt_strength.pas` | pas | 59 | 0x0E5E8C | 0x3530D8 | 24138 | 24512 |
| 38 | `lang/lang/source/alias.pas` | pas | 19 | 0x0739E4 | 0x168D8C | 6020 | 6440 |
| 39 | `lang2/source/lt_utils/source/arith.pas` | pas | 2 | 0x07530C | 0x1695E4 | 434 | 436 |
| 40 | `lang2/source/lt_utils/source/bug_check.pas` | pas | 3 | 0x0754C0 | 0x1695E8 | 334 | 348 |
| 41 | `lang/lang/source/commit_top_node.pas` | pas | 7 | 0x07561C | 0x1695EC | 2352 | 2952 |
| 42 | `lang2/source/ftn/source/const_op.ftn` | ftn | 14 | 0x0761A4 | 0x1695F0 | 1204 | 1204 |
| 43 | `lang/lang/source/delay.pas` | pas | 15 | 0x076658 | 0x1695F0 | 10782 | 11028 |
| 44 | `ivory/volume_4/report/source/do_report.pas` | pas | 1 | 0x07916C | 0x169A7C | 360 | 360 |
| 45 | `lang/lang/source/gen_debug.pas` | pas | 31 | 0x0792D4 | 0x169A7C | 3238 | 3292 |
| 46 | `lang/lang/source/gen_exception.pas` | pas | 8 | 0x079FB0 | 0x169BF4 | 1774 | 2260 |
| 47 | `lang/lang/source/gen_unwind.pas` | pas | 21 | 0x07A884 | 0x169C10 | 6014 | 6976 |
| 48 | `lang/lang/source/gen_utils.pas` | pas | 21 | 0x07C3C4 | 0x169C64 | 4248 | 4356 |
| 49 | `lang/lang/source/gspace.pas` | pas | 6 | 0x07D4C8 | 0x169C64 | 644 | 644 |
| 50 | `lang/lang/source/il.pas` | pas | 1 | 0x07D74C | 0x169C70 | 580 | 600 |
| 51 | `lang/lang/source/il_utils.pas` | pas | 14 | 0x07D9A4 | 0x169DF8 | 3412 | 3612 |
| 52 | `lang/lang/source/list_tree.pas` | pas | 42 | 0x07E7C0 | 0x169DFC | 24786 | 32400 |
| 53 | `us1/us1/lib/dblib/loc/src/loc_build.c` | c | 33 | 0x086650 | 0x35319C | 4220 | 4220 |
| 54 | `lang2/source/lt_utils/source/mrh.pas` | pas | 15 | 0x0876CC | 0x169F48 | 1912 | 2396 |
| 55 | `lang/bind/source/objio.pas` | pas | 34 | 0x088028 | 0x18E788 | 10512 | 10688 |
| 56 | `lang/bind/source/objutil.pas` | pas | 18 | 0x08A9E8 | 0x196D6C | 4576 | 16976 |
| 57 | `lang/lang/source/opt_inline.pas` | pas | 62 | 0x08EC38 | 0x196DC8 | 21518 | 21968 |
| 58 | `lang/lang/source/opt_vector.pas` | pas | 20 | 0x094208 | 0x19CCC4 | 9802 | 9932 |
| 59 | `lang/lang/source/prfpkg.pas` | pas | 11 | 0x0968D4 | 0x19CCE4 | 5616 | 6600 |
| 60 | `lang/lang/source/prtsub.pas` | pas | 7 | 0x09829C | 0x19DB6C | 632 | 656 |
| 61 | `lang2/source/lt_utils/source/seg_size.pas` | pas | 1 | 0x09852C | 0x19DB7C | 90 | 108 |
| 62 | `lang/lang/source/sortidntk.pas` | pas | 3 | 0x098598 | 0x19DB88 | 548 | 548 |
| 63 | `ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/std_lib.mac/hf398b043.001/std_lib.pas` | pas | 0 | 0x0B3E9C | - | 0 | 4488 |
| 64 | `lang/lang/source/strings.pas` | pas | 7 | 0x0987BC | 0x19DB8C | 702 | 720 |
| 65 | `lang/lang/source/time.pas` | pas | 2 | 0x098A8C | 0x19DF8C | 244 | 328 |
| 66 | `lang/lang/source/token.pas` | pas | 12 | 0x098BD4 | 0x19DF90 | 1946 | 1972 |
| 67 | `lang/lang/source/unix_objmod.pas` | pas | 46 | 0x099388 | 0x1A0314 | 25156 | 26140 |
| 68 | `lang/lang/source/add_node.pas` | pas | 23 | 0x09F9A4 | 0x2C2080 | 18204 | 21412 |
| 69 | `lang/lang/source/attributes.pas` | pas | 19 | 0x0A4D48 | 0x2C20B8 | 6206 | 6312 |
| 70 | `lang/lang/source/coff_syms.pas` | pas | 16 | 0x0A65F0 | 0x2C20BC | 7314 | 7520 |
| 71 | `lang/lang/source/debug_sym_dmp.pas` | pas | 56 | 0x0A8350 | 0x2C20CC | 15050 | 17124 |
| 72 | `lang/lang/source/error_listing.pas` | pas | 6 | 0x0AC634 | 0x2C3168 | 894 | 904 |
| 73 | `lang/lang/source/inc_list.pas` | pas | 5 | 0x0AC9BC | 0x2C3178 | 916 | 984 |
| 74 | `lang/lang/source/kfold.pas` | pas | 14 | 0x0ACD94 | 0x2C338C | 9784 | 9956 |
| 75 | `lang/lang/source/prtobj.pas` | pas | 4 | 0x0AF478 | 0x2C33B0 | 4258 | 5220 |
| 76 | `lang/lang/source/runbackend.pas` | pas | 24 | 0x0B08DC | 0x2C33B0 | 6162 | 7308 |
| 77 | `lang/lang/source/cargs.pas` | pas | 24 | 0x0B2568 | 0x2C33EC | 9064 | 6452 |
| 78 | `lang/lang/source/iosub.pas` | pas | 36 | 0x0B5024 | 0x2CD7E4 | 4726 | 4868 |
| 79 | `lang/lang/source/target_properties.pas` | pas | 3 | 0x0B6328 | 0x2CE528 | 294 | 308 |
| 80 | `lang/lang/source/empty.pas` | pas | 0 | 0x0FDEA4 | - | 0 | 4396 |
| 81 | `lang/lang/source/banshee.pas` | pas | 1 | 0x0EE84C | 0x354F44 | 1922 | 1960 |
| 82 | `lang/lang/source/celpkg.pas` | pas | 11 | 0x0B645C | 0x2CE674 | 1162 | 1196 |
| 83 | `lang/lang/source/cg_addr.pas` | pas | 50 | 0x0EEFF4 | 0x354FB8 | 16148 | 16500 |
| 84 | `lang/lang/source/cg_assign.pas` | pas | 15 | 0x0F3068 | 0x355274 | 14340 | 14464 |
| 85 | `lang/lang/source/cg_call.pas` | pas | 10 | 0x0F68E8 | 0x3552F8 | 7850 | 7956 |
| 86 | `lang/lang/source/cg_fp.pas` | pas | 9 | 0x0F87FC | 0x3552F8 | 3714 | 3904 |
| 87 | `lang/lang/source/cg_misc.pas` | pas | 24 | 0x0F973C | 0x356310 | 9360 | 9488 |
| 88 | `lang/lang/source/cg_top.pas` | pas | 18 | 0x0FBC4C | 0x356314 | 13058 | 8792 |
| 89 | `lang/lang/source/cg_tree.pas` | pas | 44 | 0x0FEFD0 | 0x356460 | 38966 | 39260 |
| 90 | `lang/lang/source/emit.pas` | pas | 11 | 0x0B6908 | 0x2CE6A8 | 4346 | 4484 |
| 91 | `lang/lang/source/final.pas` | pas | 120 | 0x10892C | 0x3566F8 | 38354 | 0 |
| 92 | `lang/lang/source/fpa.pas` | pas | 20 | 0x0B7A8C | 0x2CE7CC | 8386 | 8644 |
| 93 | `lang/lang/source/instr_reorder.pas` | pas | 14 | 0x0B9C50 | 0x2CE8BC | 2988 | 3040 |
| 94 | `lang/lang/source/jmp_br_resolve.pas` | pas | 21 | 0x0BA830 | 0x2CE8BC | 5604 | 5624 |
| 95 | `lang/lang/source/opinfo.pas` | pas | 0 | - | - | 0 | 0 |
| 96 | `lang/lang/source/outbin.pas` | pas | 70 | 0x0BBE28 | 0x2D179C | 24354 | 26100 |
| 97 | `lang/lang/source/reg_action.pas` | pas | 11 | 0x0C241C | 0x2D2558 | 5372 | 5508 |
| 98 | `lang/lang/source/reg_alloc.pas` | pas | 15 | 0x0C39A0 | 0x2D256C | 5590 | 5900 |
| 99 | `lang/lang/source/reg_color_68k.pas` | pas | 16 | 0x0C50AC | 0x2D257C | 2990 | 2992 |
| 100 | `lang/lang/source/reg_cost_68k.pas` | pas | 3 | 0x0C5C5C | 0x2D2580 | 4138 | 4216 |
| 101 | `lang/lang/source/reg_life.pas` | pas | 17 | 0x0C6CD4 | 0x2D2590 | 7724 | 7764 |
| 102 | `lang/lang/source/reg_save.pas` | pas | 23 | 0x0EBE4C | 0x353194 | 4926 | 10752 |
| 103 | `lang/lang/source/reg_vars.pas` | pas | 13 | 0x0C8B28 | 0x2D2590 | 5878 | 5880 |
| 104 | `lang/lang/source/target_68k_dummies.pas` | pas | 8 | 0x0CA220 | 0x2D2654 | 76 | 76 |

## cc.a88k

- maker: ld - DOMAIN version 7.11
- maker: bind
- maker: C compiler PRISM=>68K Rev 6.89(586)
- maker: ASM
- maker: Pascal compiler PRISM=>68K Rev 8.89(549)
- maker: Pascal compiler 68K Rev 8.89(546)
- maker: Fortran 77 compiler PRISM=>68K Rev 10.89(615)
- maker: cc (program)
- units: 132 (asm 1, c 3, ftn 1, pas 127); routines: 3368; routine bytes: 1171364

| # | file | lang | routines | code start | A5 | routine bytes | span |
|---|------|------|----------|------------|----|---------------|------|
| 0 | `lang/c_compiler/source/c_cond_read.pas` | pas | 7 | 0x040658 | 0x2C0000 | 1396 | 1548 |
| 1 | `lang/c_compiler/source/c_data.asm` | asm | 0 | 0x040C64 | - | 0 | 18384 |
| 2 | `lang/c_compiler/source/c_def_sem.pas` | pas | 59 | 0x045434 | 0x2C0054 | 16336 | 16440 |
| 3 | `lang/c_compiler/source/c_error.pas` | pas | 8 | 0x04946C | 0x2C00AC | 2404 | 2508 |
| 4 | `lang/c_compiler/source/c_expr_sem.pas` | pas | 43 | 0x049E38 | 0x2C00B0 | 24678 | 24888 |
| 5 | `lang/c_compiler/source/c_expr_syn.pas` | pas | 28 | 0x04FF70 | 0x2C2470 | 12070 | 12824 |
| 6 | `lang/c_compiler/source/c_general_utl.pas` | pas | 10 | 0x053188 | 0x2C2520 | 974 | 976 |
| 7 | `lang/c_compiler/source/c_get_rlen.pas` | pas | 1 | 0x053558 | 0x2C2524 | 124 | 124 |
| 8 | `lang/c_compiler/source/c_initdate.c` | c | 1 | 0x0535D4 | 0x2C2528 | 146 | 148 |
| 9 | `lang/c_compiler/source/c_lex_pp.pas` | pas | 38 | 0x053668 | 0x2C2528 | 11858 | 12340 |
| 10 | `lang/c_compiler/source/c_macro_read.pas` | pas | 23 | 0x05669C | 0x2C907C | 9978 | 10980 |
| 11 | `lang/c_compiler/source/c_macro_utl.pas` | pas | 19 | 0x059180 | 0x2C96B8 | 3668 | 4116 |
| 12 | `lang/c_compiler/source/c_main.pas` | pas | 13 | 0x05A194 | 0x2C98C4 | 7142 | 7972 |
| 13 | `lang/c_compiler/source/c_run_acpp.c` | c | 3 | 0x05C0B8 | 0x2CA684 | 190 | 192 |
| 14 | `lang/c_compiler/source/c_stmt_sem.pas` | pas | 52 | 0x05C178 | 0x2CA694 | 13032 | 13212 |
| 15 | `lang/c_compiler/source/c_sym_map.pas` | pas | 11 | 0x05F514 | 0x2CAC94 | 5226 | 5956 |
| 16 | `lang/c_compiler/source/c_syntax.pas` | pas | 59 | 0x060C58 | 0x2CAC94 | 26112 | 27040 |
| 17 | `lang/c_compiler/source/fe_cc_hooks_to_backend.pas` | pas | 3 | 0x0675F8 | 0x2CAEC8 | 60 | 60 |
| 18 | `lang/c_compiler/source/frontend_cc_dummies.pas` | pas | 4 | 0x067634 | 0x2CAECC | 106 | 108 |
| 19 | `lang/common/source/ass.pas` | pas | 14 | 0x0676A0 | 0x2CAECC | 1322 | 1428 |
| 20 | `lang/common/source/bvs.pas` | pas | 24 | 0x067C34 | 0x2CB000 | 1994 | 2692 |
| 21 | `lang/common/source/diag.pas` | pas | 13 | 0x0686B8 | 0x2CB080 | 964 | 976 |
| 22 | `lang/common/source/ecb.pas` | pas | 1 | 0x068A88 | 0x2CB2F4 | 178 | 256 |
| 23 | `lang/common/source/exs.pas` | pas | 27 | 0x068B88 | 0x2CB2F4 | 4168 | 5984 |
| 24 | `lang/common/source/htm.pas` | pas | 12 | 0x06A2E8 | 0x2CB364 | 1962 | 1996 |
| 25 | `lang/common/source/mem.pas` | pas | 19 | 0x06AAB4 | 0x2CB864 | 1902 | 2612 |
| 26 | `lang/common/source/pds.pas` | pas | 124 | 0x06B4E8 | 0x2CB884 | 21480 | 33128 |
| 27 | `lang/common/source/spos.pas` | pas | 31 | 0x073650 | 0x2CB8E4 | 3356 | 5644 |
| 28 | `lang/common/source/std.pas` | pas | 11 | 0x074C5C | 0x2E8DF8 | 680 | 704 |
| 29 | `lang/common/source/token.pas` | pas | 8 | 0x074F1C | 0x2E8DFC | 822 | 1192 |
| 30 | `lang/lang/source/opt_assign.pas` | pas | 9 | 0x2A0B2C | 0x4937F4 | 3474 | 3596 |
| 31 | `lang/lang/source/opt_cse.pas` | pas | 16 | 0x2A1938 | 0x4937F4 | 6888 | 6956 |
| 32 | `lang/lang/source/opt_general.pas` | pas | 9 | 0x2A3464 | 0x493884 | 1962 | 2072 |
| 33 | `lang/lang/source/opt_livevar.pas` | pas | 19 | 0x2A3C7C | 0x493884 | 7832 | 7892 |
| 34 | `lang/lang/source/opt_loop.pas` | pas | 12 | 0x2A5B50 | 0x49388C | 8898 | 9000 |
| 35 | `lang/lang/source/opt_main.pas` | pas | 109 | 0x2A7E78 | 0x49389C | 26544 | 27736 |
| 36 | `lang/lang/source/opt_reachdef.pas` | pas | 37 | 0x2AEAD0 | 0x513938 | 15600 | 15860 |
| 37 | `lang/lang/source/opt_select.pas` | pas | 11 | 0x2B28C4 | 0x513A80 | 1976 | 1976 |
| 38 | `lang/lang/source/opt_strength.pas` | pas | 12 | 0x2B307C | 0x513A84 | 2698 | 0 |
| 39 | `lang/lang/source/alias.pas` | pas | 19 | 0x0753C4 | 0x2E8DFC | 6020 | 6440 |
| 40 | `lang2/source/lt_utils/source/arith.pas` | pas | 2 | 0x076CEC | 0x2E9654 | 434 | 436 |
| 41 | `lang2/source/lt_utils/source/bug_check.pas` | pas | 3 | 0x076EA0 | 0x2E9658 | 334 | 348 |
| 42 | `lang/lang/source/commit_top_node.pas` | pas | 7 | 0x076FFC | 0x2E965C | 2352 | 2952 |
| 43 | `lang2/source/ftn/source/const_op.ftn` | ftn | 14 | 0x077B84 | 0x2E9660 | 1204 | 1204 |
| 44 | `lang/lang/source/delay.pas` | pas | 15 | 0x078038 | 0x2E9660 | 10782 | 11028 |
| 45 | `ivory/volume_4/report/source/do_report.pas` | pas | 1 | 0x07AB4C | 0x2E9AEC | 360 | 360 |
| 46 | `lang/lang/source/gen_debug.pas` | pas | 31 | 0x07ACB4 | 0x2E9AEC | 3238 | 3292 |
| 47 | `lang/lang/source/gen_exception.pas` | pas | 8 | 0x07B990 | 0x2E9C64 | 1774 | 2260 |
| 48 | `lang/lang/source/gen_unwind.pas` | pas | 21 | 0x07C264 | 0x2E9C80 | 6014 | 6976 |
| 49 | `lang/lang/source/gen_utils.pas` | pas | 21 | 0x07DDA4 | 0x2E9CD4 | 4248 | 4356 |
| 50 | `lang/lang/source/gspace.pas` | pas | 6 | 0x07EEA8 | 0x2E9CD4 | 644 | 644 |
| 51 | `lang/lang/source/il.pas` | pas | 1 | 0x07F12C | 0x2E9CE0 | 580 | 600 |
| 52 | `lang/lang/source/il_utils.pas` | pas | 14 | 0x07F384 | 0x2E9E68 | 3412 | 3612 |
| 53 | `lang/lang/source/list_tree.pas` | pas | 42 | 0x0801A0 | 0x2E9E6C | 24786 | 32400 |
| 54 | `us1/us1/lib/dblib/loc/src/loc_build.c` | c | 33 | 0x088030 | 0x513B44 | 4220 | 4220 |
| 55 | `lang2/source/lt_utils/source/mrh.pas` | pas | 15 | 0x0890AC | 0x2E9FB8 | 1912 | 2396 |
| 56 | `lang/bind/source/objio.pas` | pas | 34 | 0x089A08 | 0x30E7F8 | 10512 | 10688 |
| 57 | `lang/bind/source/objutil.pas` | pas | 18 | 0x08C3C8 | 0x316DDC | 4576 | 16976 |
| 58 | `lang/lang/source/opt_inline.pas` | pas | 62 | 0x090618 | 0x316E38 | 21518 | 21968 |
| 59 | `lang/lang/source/opt_vector.pas` | pas | 20 | 0x095BE8 | 0x31CD34 | 9802 | 9932 |
| 60 | `lang/lang/source/prfpkg.pas` | pas | 11 | 0x0982B4 | 0x31CD54 | 5616 | 6600 |
| 61 | `lang/lang/source/prtsub.pas` | pas | 7 | 0x099C7C | 0x31DBDC | 632 | 656 |
| 62 | `lang2/source/lt_utils/source/seg_size.pas` | pas | 1 | 0x099F0C | 0x31DBEC | 90 | 108 |
| 63 | `lang/lang/source/sortidntk.pas` | pas | 3 | 0x099F78 | 0x31DBF8 | 548 | 548 |
| 64 | `ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/std_lib.mac/hf398b043.001/std_lib.pas` | pas | 0 | 0x0B2640 | - | 0 | 6408 |
| 65 | `lang/lang/source/strings.pas` | pas | 7 | 0x09A19C | 0x31DBFC | 702 | 720 |
| 66 | `lang/lang/source/time.pas` | pas | 2 | 0x09A46C | 0x31DFFC | 244 | 328 |
| 67 | `lang/lang/source/token.pas` | pas | 12 | 0x09A5B4 | 0x31E000 | 1946 | 1972 |
| 68 | `lang/lang/source/unix_objmod.pas` | pas | 46 | 0x09AD68 | 0x320384 | 25156 | 26140 |
| 69 | `lang/lang/source/add_node.pas` | pas | 23 | 0x0A1384 | 0x4420F0 | 18204 | 21412 |
| 70 | `lang/lang/source/attributes.pas` | pas | 19 | 0x0A6728 | 0x442128 | 6206 | 6312 |
| 71 | `lang/lang/source/coff_syms.pas` | pas | 16 | 0x0A7FD0 | 0x44212C | 7314 | 7520 |
| 72 | `lang/lang/source/debug_sym_dmp.pas` | pas | 56 | 0x0A9D30 | 0x44213C | 15050 | 17124 |
| 73 | `lang/lang/source/error_listing.pas` | pas | 6 | 0x0AE014 | 0x4431D8 | 894 | 904 |
| 74 | `lang/lang/source/inc_list.pas` | pas | 5 | 0x0AE39C | 0x4431E8 | 916 | 984 |
| 75 | `lang/lang/source/kfold.pas` | pas | 14 | 0x0AE774 | 0x4433FC | 9784 | 9956 |
| 76 | `lang/lang/source/prtobj.pas` | pas | 4 | 0x0B0E58 | 0x443420 | 4258 | 5220 |
| 77 | `lang/lang/source/runbackend.pas` | pas | 24 | 0x0B22BC | 0x443420 | 6162 | 900 |
| 78 | `lang2/source/be_com/call_conv.pas` | pas | 9 | 0x0B3F48 | 0x44345C | 8696 | 8928 |
| 79 | `lang/lang/source/cargs.pas` | pas | 24 | 0x0B6228 | 0x443570 | 8628 | 10436 |
| 80 | `lang/lang/source/iosub.pas` | pas | 36 | 0x0B8AEC | 0x44D968 | 4726 | 4868 |
| 81 | `lang/lang/source/target_properties.pas` | pas | 3 | 0x0B9DF0 | 0x44E6AC | 294 | 308 |
| 82 | `lang/lang/source/empty.pas` | pas | 0 | 0x101194 | - | 0 | 293168 |
| 83 | `lang2/source/isc/isc_call_handling.pas` | pas | 6 | 0x0B9F24 | 0x44E7F8 | 1542 | 1616 |
| 84 | `lang2/source/isc/isc_cse_handling.pas` | pas | 57 | 0x0BA574 | 0x44E7FC | 5780 | 11368 |
| 85 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_debug.pas` | pas | 4 | 0x0BD1DC | 0x44E9A8 | 102558 | 114924 |
| 86 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_main.pas` | pas | 18 | 0x0D92C8 | 0x44E9B0 | 4684 | 8684 |
| 87 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_main.pas` | pas | 186 | 0x0DB4B4 | 0x44EBE8 | 82954 | 154848 |
| 88 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_main.pas` | pas | 1 | 0x18C588 | 0x47F788 | 536 | 474788 |
| 89 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pattern_matcher.pas` | pas | 2 | 0x20042C | 0x4800BC | 32552 | 33924 |
| 90 | `lang2/source/isc/isc_to_lir.pas` | pas | 30 | 0x2088B0 | 0x480DFC | 15164 | 21708 |
| 91 | `lang2/source/isc/isc_user_routines.pas` | pas | 138 | 0x20DD7C | 0x480E00 | 39392 | 55452 |
| 92 | `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_vars.pas` | pas | 0 | 0x148AC4 | - | 0 | 277188 |
| 93 | `lang2/source/isc/rewrite.pas` | pas | 16 | 0x21B618 | 0x48115C | 9296 | 9900 |
| 94 | `lang2/source/be_com/asm.pas` | pas | 21 | 0x21DCC4 | 0x4851D4 | 11360 | 15772 |
| 95 | `lang2/source/be_com/at_backend.pas` | pas | 15 | 0x221A60 | 0x485830 | 3744 | 4316 |
| 96 | `lang2/source/be_com/bin.pas` | pas | 32 | 0x222B3C | 0x485D38 | 6958 | 8528 |
| 97 | `lang2/source/be_com/bv.pas` | pas | 32 | 0x224C8C | 0x485DC8 | 4062 | 4456 |
| 98 | `lang2/source/be_com/com.pas` | pas | 63 | 0x225DF4 | 0x485E60 | 24270 | 26692 |
| 99 | `lang2/source/be_com/dbg_life.pas` | pas | 24 | 0x22C638 | 0x485FA0 | 7750 | 7980 |
| 100 | `lang2/source/be_com/df_utils.pas` | pas | 17 | 0x22E564 | 0x486058 | 2698 | 2884 |
| 101 | `lang2/source/be_com/dfa.pas` | pas | 4 | 0x22F0A8 | 0x48606C | 224 | 224 |
| 102 | `lang2/source/be_com/dmp.pas` | pas | 27 | 0x22F188 | 0x486074 | 13336 | 22520 |
| 103 | `lang2/source/be_com/fg_utils.pas` | pas | 53 | 0x234980 | 0x48646C | 11286 | 12512 |
| 104 | `lang2/source/be_com/fga.pas` | pas | 11 | 0x237A60 | 0x4864D0 | 2084 | 2260 |
| 105 | `lang2/source/be_com/hal.pas` | pas | 19 | 0x238334 | 0x4864D4 | 2656 | 2684 |
| 106 | `lang2/source/be_com/iv.pas` | pas | 127 | 0x238DB0 | 0x486500 | 28876 | 29620 |
| 107 | `lang2/source/be_com/jbr.pas` | pas | 4 | 0x240164 | 0x486D00 | 8 | 8 |
| 108 | `lang2/source/be_com/konst.pas` | pas | 32 | 0x24016C | 0x486D04 | 5888 | 6776 |
| 109 | `lang2/source/be_com/life.pas` | pas | 14 | 0x241BE4 | 0x486D94 | 2788 | 3132 |
| 110 | `lang2/source/be_com/lir.pas` | pas | 63 | 0x242820 | 0x487180 | 20608 | 25184 |
| 111 | `lang2/source/be_com/lir_main.pas` | pas | 25 | 0x248A80 | 0x48B3AC | 13156 | 13948 |
| 112 | `lang2/source/be_com/lir_utils.pas` | pas | 15 | 0x24C0FC | 0x48C164 | 7972 | 9508 |
| 113 | `lang2/source/be_com/lst.pas` | pas | 33 | 0x24E620 | 0x48C1A4 | 12704 | 14248 |
| 114 | `lang2/source/be_com/mmt.pas` | pas | 39 | 0x251DC8 | 0x48C368 | 12282 | 13328 |
| 115 | `lang2/source/be_com/mmt_utils.pas` | pas | 37 | 0x2551D8 | 0x48C544 | 10124 | 11144 |
| 116 | `lang2/source/be_com/oli.pas` | pas | 120 | 0x257D60 | 0x48C5C4 | 37772 | 38212 |
| 117 | `lang2/source/be_com/post.pas` | pas | 66 | 0x2612A4 | 0x48F438 | 20856 | 22964 |
| 118 | `lang2/source/be_com/ra.pas` | pas | 62 | 0x266C58 | 0x48F488 | 25086 | 29388 |
| 119 | `lang2/source/be_com/ra_utils.pas` | pas | 45 | 0x26DF24 | 0x48FAF4 | 14838 | 15884 |
| 120 | `lang2/source/be_com/sanity.pas` | pas | 6 | 0x271D30 | 0x48FD08 | 4158 | 8032 |
| 121 | `lang2/source/be_com/sched.pas` | pas | 50 | 0x273C90 | 0x48FD08 | 17436 | 21760 |
| 122 | `lang2/source/be_com/sched_utils.pas` | pas | 15 | 0x279190 | 0x492E6C | 3708 | 4744 |
| 123 | `lang2/source/be_com/sem_utils.pas` | pas | 7 | 0x27A418 | 0x492E74 | 542 | 616 |
| 124 | `lang2/source/be_com/sym.pas` | pas | 19 | 0x27A680 | 0x492E74 | 3488 | 4160 |
| 125 | `lang2/source/be_com/target_at_dummies.pas` | pas | 9 | 0x27B6C0 | 0x492F7C | 82 | 84 |
| 126 | `lang2/source/be_com/tm_utils.pas` | pas | 14 | 0x27B714 | 0x492F80 | 2492 | 2680 |
| 127 | `lang2/source/be_com/tr_utils.pas` | pas | 68 | 0x27C18C | 0x492F80 | 21154 | 22396 |
| 128 | `lang2/source/be_com/trans.pas` | pas | 37 | 0x281908 | 0x492FA4 | 11454 | 12308 |
| 129 | `lang2/source/be_com/utils.pas` | pas | 54 | 0x28491C | 0x492FA8 | 11194 | 12704 |
| 130 | `lang2/source/be_com/xtp.pas` | pas | 7 | 0x287ABC | 0x492FEC | 1100 | 1220 |
| 131 | `lang2/source/be_com/zzzzz.pas` | pas | 9 | 0x287F80 | 0x492FEC | 1724 | 1740 |

## shared units: cc.m68k vs cc.a88k

| file | routines a | routines b | same names | same lengths |
|------|------------|------------|------------|--------------|
| `lang/c_compiler/source/c_cond_read.pas` | 7 | 7 | yes | yes |
| `lang/c_compiler/source/c_data.asm` | 0 | 0 | yes | yes |
| `lang/c_compiler/source/c_def_sem.pas` | 59 | 59 | yes | yes |
| `lang/c_compiler/source/c_error.pas` | 8 | 8 | yes | yes |
| `lang/c_compiler/source/c_expr_sem.pas` | 43 | 43 | yes | yes |
| `lang/c_compiler/source/c_expr_syn.pas` | 28 | 28 | yes | yes |
| `lang/c_compiler/source/c_general_utl.pas` | 10 | 10 | yes | yes |
| `lang/c_compiler/source/c_get_rlen.pas` | 1 | 1 | yes | yes |
| `lang/c_compiler/source/c_initdate.c` | 1 | 1 | yes | yes |
| `lang/c_compiler/source/c_lex_pp.pas` | 38 | 38 | yes | yes |
| `lang/c_compiler/source/c_macro_read.pas` | 23 | 23 | yes | yes |
| `lang/c_compiler/source/c_macro_utl.pas` | 19 | 19 | yes | yes |
| `lang/c_compiler/source/c_main.pas` | 13 | 13 | yes | yes |
| `lang/c_compiler/source/c_run_acpp.c` | 3 | 3 | yes | yes |
| `lang/c_compiler/source/c_stmt_sem.pas` | 52 | 52 | yes | yes |
| `lang/c_compiler/source/c_sym_map.pas` | 11 | 11 | yes | yes |
| `lang/c_compiler/source/c_syntax.pas` | 59 | 59 | yes | yes |
| `lang/c_compiler/source/fe_cc_hooks_to_backend.pas` | 3 | 3 | yes | yes |
| `lang/c_compiler/source/frontend_cc_dummies.pas` | 4 | 4 | yes | yes |
| `lang/common/source/ass.pas` | 14 | 14 | yes | yes |
| `lang/common/source/bvs.pas` | 24 | 24 | yes | yes |
| `lang/common/source/diag.pas` | 13 | 13 | yes | yes |
| `lang/common/source/ecb.pas` | 1 | 1 | yes | yes |
| `lang/common/source/htm.pas` | 12 | 12 | yes | yes |
| `lang/common/source/mem.pas` | 19 | 19 | yes | yes |
| `lang/common/source/pds.pas` | 124 | 124 | yes | yes |
| `lang/common/source/spos.pas` | 31 | 31 | yes | yes |
| `lang/common/source/std.pas` | 11 | 11 | yes | yes |
| `lang/common/source/token.pas` | 8 | 8 | yes | yes |
| `lang/lang/source/opt_assign.pas` | 9 | 9 | yes | yes |
| `lang/lang/source/opt_cse.pas` | 16 | 16 | yes | yes |
| `lang/lang/source/opt_general.pas` | 9 | 9 | yes | yes |
| `lang/lang/source/opt_livevar.pas` | 19 | 19 | yes | yes |
| `lang/lang/source/opt_loop.pas` | 12 | 12 | yes | yes |
| `lang/lang/source/opt_main.pas` | 109 | 109 | yes | yes |
| `lang/lang/source/opt_reachdef.pas` | 37 | 37 | yes | yes |
| `lang/lang/source/opt_select.pas` | 11 | 11 | yes | yes |
| `lang/lang/source/opt_strength.pas` | 59 | 12 | no | no |
| `lang/lang/source/alias.pas` | 19 | 19 | yes | yes |
| `lang2/source/lt_utils/source/arith.pas` | 2 | 2 | yes | yes |
| `lang2/source/lt_utils/source/bug_check.pas` | 3 | 3 | yes | yes |
| `lang/lang/source/commit_top_node.pas` | 7 | 7 | yes | yes |
| `lang2/source/ftn/source/const_op.ftn` | 14 | 14 | yes | yes |
| `lang/lang/source/delay.pas` | 15 | 15 | yes | yes |
| `ivory/volume_4/report/source/do_report.pas` | 1 | 1 | yes | yes |
| `lang/lang/source/gen_debug.pas` | 31 | 31 | yes | yes |
| `lang/lang/source/gen_exception.pas` | 8 | 8 | yes | yes |
| `lang/lang/source/gen_unwind.pas` | 21 | 21 | yes | yes |
| `lang/lang/source/gen_utils.pas` | 21 | 21 | yes | yes |
| `lang/lang/source/gspace.pas` | 6 | 6 | yes | yes |
| `lang/lang/source/il.pas` | 1 | 1 | yes | yes |
| `lang/lang/source/il_utils.pas` | 14 | 14 | yes | yes |
| `lang/lang/source/list_tree.pas` | 42 | 42 | yes | yes |
| `us1/us1/lib/dblib/loc/src/loc_build.c` | 33 | 33 | yes | yes |
| `lang2/source/lt_utils/source/mrh.pas` | 15 | 15 | yes | yes |
| `lang/bind/source/objio.pas` | 34 | 34 | yes | yes |
| `lang/bind/source/objutil.pas` | 18 | 18 | yes | yes |
| `lang/lang/source/opt_inline.pas` | 62 | 62 | yes | yes |
| `lang/lang/source/opt_vector.pas` | 20 | 20 | yes | yes |
| `lang/lang/source/prfpkg.pas` | 11 | 11 | yes | yes |
| `lang/lang/source/prtsub.pas` | 7 | 7 | yes | yes |
| `lang2/source/lt_utils/source/seg_size.pas` | 1 | 1 | yes | yes |
| `lang/lang/source/sortidntk.pas` | 3 | 3 | yes | yes |
| `ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/std_lib.mac/hf398b043.001/std_lib.pas` | 0 | 0 | yes | yes |
| `lang/lang/source/strings.pas` | 7 | 7 | yes | yes |
| `lang/lang/source/time.pas` | 2 | 2 | yes | yes |
| `lang/lang/source/token.pas` | 12 | 12 | yes | yes |
| `lang/lang/source/unix_objmod.pas` | 46 | 46 | yes | yes |
| `lang/lang/source/add_node.pas` | 23 | 23 | yes | yes |
| `lang/lang/source/attributes.pas` | 19 | 19 | yes | yes |
| `lang/lang/source/coff_syms.pas` | 16 | 16 | yes | yes |
| `lang/lang/source/debug_sym_dmp.pas` | 56 | 56 | yes | yes |
| `lang/lang/source/error_listing.pas` | 6 | 6 | yes | yes |
| `lang/lang/source/inc_list.pas` | 5 | 5 | yes | yes |
| `lang/lang/source/kfold.pas` | 14 | 14 | yes | yes |
| `lang/lang/source/prtobj.pas` | 4 | 4 | yes | yes |
| `lang/lang/source/runbackend.pas` | 24 | 24 | yes | yes |
| `lang/lang/source/cargs.pas` | 24 | 24 | yes | no |
| `lang/lang/source/iosub.pas` | 36 | 36 | yes | no |
| `lang/lang/source/target_properties.pas` | 3 | 3 | yes | yes |
| `lang/lang/source/empty.pas` | 0 | 0 | yes | yes |

only in cc.m68k: `lang/lang/source/banshee.pas`, `lang/lang/source/celpkg.pas`, `lang/lang/source/cg_addr.pas`, `lang/lang/source/cg_assign.pas`, `lang/lang/source/cg_call.pas`, `lang/lang/source/cg_fp.pas`, `lang/lang/source/cg_misc.pas`, `lang/lang/source/cg_top.pas`, `lang/lang/source/cg_tree.pas`, `lang/lang/source/emit.pas`, `lang/lang/source/final.pas`, `lang/lang/source/fpa.pas`, `lang/lang/source/instr_reorder.pas`, `lang/lang/source/jmp_br_resolve.pas`, `lang/lang/source/opinfo.pas`, `lang/lang/source/outbin.pas`, `lang/lang/source/reg_action.pas`, `lang/lang/source/reg_alloc.pas`, `lang/lang/source/reg_color_68k.pas`, `lang/lang/source/reg_cost_68k.pas`, `lang/lang/source/reg_life.pas`, `lang/lang/source/reg_save.pas`, `lang/lang/source/reg_vars.pas`, `lang/lang/source/target_68k_dummies.pas`

only in cc.a88k: `lang/common/source/exs.pas`, `lang2/source/be_com/call_conv.pas`, `lang2/source/isc/isc_call_handling.pas`, `lang2/source/isc/isc_cse_handling.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_debug.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_main.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_main.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_main.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pattern_matcher.pas`, `lang2/source/isc/isc_to_lir.pas`, `lang2/source/isc/isc_user_routines.pas`, `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_vars.pas`, `lang2/source/isc/rewrite.pas`, `lang2/source/be_com/asm.pas`, `lang2/source/be_com/at_backend.pas`, `lang2/source/be_com/bin.pas`, `lang2/source/be_com/bv.pas`, `lang2/source/be_com/com.pas`, `lang2/source/be_com/dbg_life.pas`, `lang2/source/be_com/df_utils.pas`, `lang2/source/be_com/dfa.pas`, `lang2/source/be_com/dmp.pas`, `lang2/source/be_com/fg_utils.pas`, `lang2/source/be_com/fga.pas`, `lang2/source/be_com/hal.pas`, `lang2/source/be_com/iv.pas`, `lang2/source/be_com/jbr.pas`, `lang2/source/be_com/konst.pas`, `lang2/source/be_com/life.pas`, `lang2/source/be_com/lir.pas`, `lang2/source/be_com/lir_main.pas`, `lang2/source/be_com/lir_utils.pas`, `lang2/source/be_com/lst.pas`, `lang2/source/be_com/mmt.pas`, `lang2/source/be_com/mmt_utils.pas`, `lang2/source/be_com/oli.pas`, `lang2/source/be_com/post.pas`, `lang2/source/be_com/ra.pas`, `lang2/source/be_com/ra_utils.pas`, `lang2/source/be_com/sanity.pas`, `lang2/source/be_com/sched.pas`, `lang2/source/be_com/sched_utils.pas`, `lang2/source/be_com/sem_utils.pas`, `lang2/source/be_com/sym.pas`, `lang2/source/be_com/target_at_dummies.pas`, `lang2/source/be_com/tm_utils.pas`, `lang2/source/be_com/tr_utils.pas`, `lang2/source/be_com/trans.pas`, `lang2/source/be_com/utils.pas`, `lang2/source/be_com/xtp.pas`, `lang2/source/be_com/zzzzz.pas`

