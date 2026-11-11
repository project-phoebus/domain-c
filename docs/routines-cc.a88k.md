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

### `lang/c_compiler/source/c_cond_read.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`
- include `//lang/c_compiler/source/macro_read.ins.pas`

    pop_current_state                        0x040C52 0x12     level 2
    push_current_state                       0x040C40 0x12     level 2
    match_keyword                            0x040BA0 0x90     level 2
    first_token                              0x040A50 0x134    level 2
    cr_$if_is_on                             0x040684 0x1A     level 2
    cr_$get_cooked_line                      0x04069E 0x346    level 2
    cr_$initialize                           0x040658 0x2C     level 2

### `lang/c_compiler/source/c_data.asm`

- include `//lang/c_compiler/source/c_data.asm`


### `lang/c_compiler/source/c_def_sem.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`

    alloc_on_stk                             0x04918C 0xD4     level 2
    create_and_link_data_rec                 0x0472E4 0x116    level 2
    def_sect                                 0x0465C2 0x9C     level 2
    has_data_init                            0x0465B4 0xE      level 2
    check_protos                             0x0462FE 0xE4     level 2
    check_oldef_proto                        0x0461FC 0x102    level 2
    all_promoted_types                       0x0461A2 0x5A     level 2
    promote_type                             0x0460E2 0xC0     level 2
    add_incomplete_type                      0x04599C 0x52     level 2
    def_virt_varn                            0x04585A 0x48     level 2
    lnktbl_def_name                          0x045830 0x2A     level 2
    lnktbl_to_modblk                         0x0457C0 0x42     level 2
    lnktbl_first_name                        0x0457AC 0x14     level 2
    lnktbl_del_name                          0x04572C 0x80     level 2
    lnktbl_init                              0x04570E 0x1E     level 2
    get_constant_size                        0x04546E 0xB6     level 2
    calc_align                               0x045434 0x3A     level 2
    def_alloc_var                            0x049260 0x20C    level 2
    def_blk_params                           0x048D16 0x476    level 2
    def_blk_skeleton                         0x048778 0x59E    level 2
    def_arr                                  0x048324 0x454    level 2
    def_rec                                  0x04825C 0xC8     level 2
    def_fld                                  0x047BD6 0x66C    level 2
    def_func                                 0x047B34 0xA2     level 2
    def_incomplete_su                        0x0458D0 0xCC     level 2
    def_resolve_incomplete_types             0x0459EE 0x10A    level 2
    def_final_res_fwd_ptrs                   0x047A8C 0xA8     level 2
    def_resolve_fwd_ptrs                     0x0479B8 0xD4     level 2
    def_fwd_ptr                              0x04795C 0x5C     level 2
    def_ptr                                  0x047894 0xC8     level 2
    add_parm                                 0x047144 0xB8     level 2
    def_subr                                 0x047842 0x52     level 2
    def_enum_list                            0x0475CE 0x264    level 2
    def_enum_skeleton                        0x04759A 0x34     level 2
    def_conn                                 0x047546 0x54     level 2
    def_typn                                 0x0474B0 0x96     level 2
    def_dynm_data                            0x04744E 0x62     level 2
    def_data                                 0x0473FA 0x54     level 2
    def_su                                   0x047292 0x52     level 2
    lookup_su                                0x0471FC 0x60     level 2
    add_su                                   0x04725C 0x36     level 2
    add_reg_var                              0x0470E0 0x64     level 2
    add_varn                                 0x047018 0xC8     level 2
    def_varn                                 0x0469C2 0x656    level 2
    alloc_bss                                0x04697C 0x46     level 3
    make_comblk_sect                         0x0468EE 0x8E     level 3
    ext2sect_addr_cons                       0x046874 0x7A     level 3
    redecl_as_static                         0x04674C 0x128    level 3
    delete_section                           0x0466FE 0x4E     level 3
    update_attr                              0x04665E 0xA0     level 3
    check_types                              0x0463E2 0x1D2    level 2
    def_drop_tnames                          0x0458A2 0x2E     level 2
    def_lnktbl_clear                         0x045802 0x2E     level 2
    def_name                                 0x045642 0xCC     level 2
    fnd_name                                 0x045610 0x32     level 2
    blk_fnd_name                             0x045582 0x8E     level 2
    fnd_param                                0x045524 0x5E     level 2
    type_exp                                 0x045B8A 0x51A    level 2
    fix_array_decl                           0x045AF8 0x92     level 3

### `lang/c_compiler/source/c_error.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`

    error_hdr                                0x04951C 0x210    level 2
    print_line_number                        0x049492 0x84     level 2
    warning_text                             0x049DAC 0x8A     level 2
    error_text                               0x049D40 0x6C     level 2
    errorlst                                 0x04986C 0x410    level 2
    error_not_printed                        0x049788 0xE4     level 3
    cgerr_no_source                          0x04946C 0x26     level 2
    cgerr                                    0x049C80 0xC0     level 2

### `lang/c_compiler/source/c_expr_sem.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/fpp.ins.pas`
- include `//us/us/sys/ins/fpp.ins.pas`
- include `//us/us/ins/peb.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`

    swap_top                                 0x04BFF4 0x62     level 2
    scl_cmp                                  0x04BD94 0x17C    level 2
    reference_operand                        0x04AC40 0x69E    level 2
    float_operand                            0x04A0F0 0x130    level 2
    adjust_length                            0x049FB6 0x13A    level 2
    get_oc                                   0x049F2E 0x88     level 2
    adjust_blk_for_db                        0x04FEE2 0x8C     level 2
    test_ne_zero                             0x04FCC0 0x21A    level 2
    adjust_parm                              0x04FBF4 0xCC     level 2
    expr_op                                  0x04D03A 0x2B7A   level 2
    check_for_out_of_bounds                  0x04CFEA 0x50     level 3
    get_number_of_elements                   0x04CF2C 0xBE     level 4
    result_signedness                        0x04CEDA 0x52     level 3
    build_builtin_tree                       0x04CB9E 0x33C    level 3
    de_ref                                   0x04CADA 0xC4     level 4
    power_of_two                             0x04C9AC 0x12E    level 3
    mult_div_mod_sign                        0x04C93A 0x72     level 3
    mult_div_mod_prep                        0x04C89A 0xA0     level 3
    double_coerce                            0x04C6C8 0x1D2    level 3
    value_preserve                           0x04C4C2 0x206    level 4
    coerce_dominant                          0x04C3B6 0x10C    level 4
    coerce_as_usual                          0x04C2EA 0xCC     level 4
    fixup_bounds                             0x04C250 0x9A     level 4
    do_coerce                                0x04C0AE 0x1A2    level 3
    boolean_result                           0x04C056 0x4C     level 3
    push_fcon                                0x04BF50 0xA4     level 2
    push_con                                 0x04BF10 0x40     level 2
    body_opr                                 0x04B860 0x534    level 2
    stack_operand                            0x04B6E2 0x164    level 3
    select_field                             0x04B61C 0xC6     level 3
    exposed_member                           0x04B576 0xA6     level 3
    find_field_member                        0x04B41A 0x15C    level 3
    find_field_partial                       0x04B34A 0xD0     level 4
    find_field                               0x04B2F8 0x52     level 3
    coerce                                   0x04A8F8 0x348    level 2
    real_to_real                             0x04A72A 0x1BE    level 3
    real_to_integer_or_enum                  0x04A620 0x10A    level 3
    pointer_to_pointer                       0x04A4BE 0x162    level 3
    pointer_and_integer_or_enum              0x04A3F0 0xCE     level 3
    common_integer_code                      0x04A2E0 0x110    level 3
    common_enum_code                         0x04A220 0xA6     level 3
    init_aux                                 0x049E8A 0xA4     level 2
    init_exp_tbl                             0x049E38 0x34     level 2

### `lang/c_compiler/source/c_expr_syn.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/externals.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/c_compiler/source/c_syntax.ins.pas`
- include `//lang/c_compiler/source/c_expr_syn.ins.pas`

    log_or_expr                              0x052D40 0xD2     level 2
    log_and_expr                             0x052C60 0xD2     level 2
    bit_ior_expr                             0x052B84 0xCE     level 2
    bit_eor_expr                             0x052AA8 0xCE     level 2
    bit_and_expr                             0x0529CC 0xCE     level 2
    eq_expr                                  0x0528DE 0xE0     level 2
    rel_expr                                 0x0527AA 0x126    level 2
    shift_expr                               0x0526BA 0xE2     level 2
    addit_expr                               0x0525CC 0xE0     level 2
    multip_expr                              0x0524C8 0xF6     level 2
    unary_expr                               0x0518D0 0xBAA    level 2
    primary_expr                             0x05104C 0x826    level 2
    func_call_stat                           0x050BE2 0x41A    level 2
    do_c_string                              0x050A22 0x16C    level 2
    test_side_effects                        0x050A12 0x10     level 2
    cast_int_const                           0x0507A6 0x170    level 2
    get_builtin_func                         0x050760 0x46     level 2
    swap_top                                 0x0506FC 0x64     level 2
    check                                    0x0506CA 0x32     level 2
    error                                    0x05063C 0x80     level 2
    cond_expr                                0x052E20 0x118    level 2
    asn_expr                                 0x052F54 0x102    level 2
    not_an_lvalue                            0x050930 0xC8     level 2
    identifier                               0x050B8E 0x54     level 2
    eval_expr                                0x053148 0x40     level 2
    c_expr                                   0x053064 0xD6     level 2
    c_expr_syn_$begin_compilation            0x05007C 0x4D0    level 2
    alloc_builtins                           0x04FF70 0x10C    level 3

### `lang/c_compiler/source/c_general_utl.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`

    cgu_$make_line_no                        0x0534C0 0x96     level 2
    str_locate                               0x0533CC 0xF4     level 2
    str_slide                                0x053358 0x74     level 2
    str_strip_leading                        0x053300 0x58     level 2
    str_copy                                 0x0532CA 0x36     level 2
    str_eql_insensitive                      0x05325E 0x6C     level 2
    str_eql                                  0x05320E 0x50     level 2
    min                                      0x0531EC 0x22     level 2
    max                                      0x0531CA 0x22     level 2
    math_mod                                 0x053188 0x42     level 2

### `lang/c_compiler/source/c_get_rlen.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`

    get_rlen                                 0x053558 0x7C     level 2

### `lang/c_compiler/source/c_initdate.c`


    initdate                                 0x0535D4 0x92     level 2

### `lang/c_compiler/source/c_lex_pp.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`
- include `//us/us/ins/ev.ins.pas`
- include `//us/us/ins/pm.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/proc2.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`
- include `//us/us/ins/unix_resource.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pm.ins.pas`
- include `//us/us/ins/acl.ins.pas`
- include `//us/us/ins/c.ins.pas`
- include `//us/us/sys/ins/ios.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//us/us/ins/cvfp.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`
- include `//lang/c_compiler/source/macro_read.ins.pas`
- include `//lang/c_compiler/source/c_lex_pp.pvt.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`

    put_es_line                              0x0536C4 0xD4     level 2
    ppio_$lookahead                          0x056624 0x6E     level 2
    ppio_$error                              0x056368 0x50     level 2
    ppio_$get_line                           0x0563B8 0x26C    level 2
    init_lex                                 0x05379A 0x1E4    level 2
    clex_$catstring                          0x056264 0x104    level 2
    clex_$unget                              0x056230 0x34     level 2
    get                                      0x055A6A 0x7A4    level 2
    check_op_asn                             0x055A0E 0x5C     level 3
    get_number                               0x055748 0x2C6    level 3
    get_integer                              0x05566E 0xCC     level 4
    get_identifier                           0x0555B6 0xA8     level 3
    get_wchar_t                              0x05556C 0x4A     level 3
    peekchar                                 0x055550 0x1C     level 3
    get_wchar_const                          0x055524 0x2C     level 3
    get_char_const                           0x05546E 0xB6     level 3
    get_wstring                              0x0553A4 0xCA     level 3
    get_string                               0x0552E0 0xC4     level 3
    get_backslash_char                       0x05510A 0x1AE    level 3
    get_comment                              0x05507A 0x90     level 3
    get_character                            0x05503A 0x40     level 3
    pp_get_line                              0x054E7E 0x1BC    level 3
    open_include                             0x054BCC 0x2B0    level 3
    parse_directive                          0x054840 0x328    level 3
    do_pragma                                0x05448E 0x30E    level 4
    hp_standard_sem                          0x0543F8 0x7C     level 4
    systype_sem                              0x0542CC 0x112    level 4
    section_sem                              0x0540D6 0x1F6    level 4
    module_sem                               0x053F06 0x1D0    level 4
    sect_id                                  0x053EFA 0xC      level 4
    nolist_sem                               0x053EF4 0x6      level 4
    list_sem                                 0x053EE8 0xC      level 4
    eject_sem                                0x053EC8 0x20     level 4
    line_sem                                 0x053AEC 0x3D8    level 4
    open_file_to_get_info                    0x053A66 0x86     level 4
    set_ecb_bit                              0x053A04 0x62     level 4
    more_data_on_line                        0x0539A4 0x5A     level 3
    advance_listing_to_line                  0x053668 0x5C     level 2

### `lang/c_compiler/source/c_macro_read.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`
- include `//lang/c_compiler/source/macro_utl.ins.pas`
- include `//lang/c_compiler/source/macro_read.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/ev.ins.pas`
- include `//us/us/ins/c.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//lang/c_compiler/source/c_lex_pp.pvt.pas`

    get_decommented_line                     0x057114 0x4A4    level 2
    extract_params                           0x056D14 0x400    level 2
    append_actual                            0x056C7A 0x9A     level 2
    process_formals                          0x056C08 0x72     level 2
    text_identical                           0x056BA8 0x60     level 2
    find_id                                  0x056962 0x246    level 2
    insert_error_q                           0x056906 0x5C     level 2
    insert_q                                 0x0568C0 0x46     level 2
    insert_q_tlp                             0x0568A2 0x1E     level 2
    remove_q                                 0x056828 0x7A     level 2
    s_pick_off_name                          0x0566F2 0x114    level 2
    get_par_cooked_line                      0x0577F0 0x82E    level 2
    just_get_the_next_line_please            0x05774C 0xA4     level 3
    str_locate_c_id                          0x058E58 0x2A0    level 2
    mr_$check_define                         0x059100 0x80     level 2
    mr_$get_q_only                           0x058246 0x6E     level 2
    mr_$get_raw_line                         0x057620 0x114    level 2
    mr_$get_expanded_line                    0x0584E2 0x85E    level 2
    prep_split_id                            0x058464 0x7E     level 3
    skip_white_space                         0x058420 0x44     level 3
    queue_error                              0x058348 0xD8     level 3
    do_special_macro                         0x0582B4 0x94     level 3
    mr_$initialize                           0x05669C 0x56     level 2

### `lang/c_compiler/source/c_macro_utl.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`
- include `//lang/c_compiler/source/macro_read.ins.pas`
- include `//lang/c_compiler/source/macro_utl.ins.pas`

    copy_body                                0x059F18 0x70     level 2
    end_of_text_chain                        0x059F04 0x14     level 2
    hash_value                               0x059180 0x42     level 2
    mu_$find_hash_word                       0x059E32 0xC0     level 2
    mu_$free_tle_list                        0x059DFA 0x38     level 2
    mu_$free_tle                             0x059CC4 0x108    level 2
    mu_$alloc_tle                            0x059A92 0x1D0    level 2
    mu_$bind_params                          0x05A15C 0x38     level 2
    bind_backwards                           0x05A094 0xC8     level 3
    mu_$merge_line_tlp                       0x059FB6 0xDE     level 2
    mu_$copy_text_list                       0x059F88 0x2E     level 2
    mu_$compress_macro                       0x0599BC 0xD6     level 2
    mu_$convert_formal                       0x05990C 0xB0     level 2
    mu_$dump                                 0x059714 0x1AA    level 2
    mu_$initialize                           0x059448 0x240    level 2
    mu_$def_macro                            0x0593A8 0xA0     level 2
    mu_$cancel_name                          0x05931C 0x8C     level 2
    mu_$enter_name                           0x059230 0xA8     level 2
    mu_$lookup_name                          0x0591C2 0x6E     level 2

### `lang/c_compiler/source/c_main.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/time.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/c_compiler/source/c_pre_proc.ins.pas`
- include `//lang/c_compiler/source/general_utl.ins.pas`
- include `//lang/c_compiler/source/macro_utl.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/pfm.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/proc2.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`
- include `//us/us/ins/unix_resource.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/as_info.ins.pas`
- include `//us/us/ins/c.ins.pas`
- include `//us/us/ins/ev.ins.pas`
- include `//us/us/ins/pm.ins.pas`
- include `//us/us/sys/ins/pm.ins.pas`
- include `//us/us/ins/acl.ins.pas`
- include `//ivory/volume_4/report/source/report.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/c_compiler/source/cppansi.ins.pas`

    cc                                       0x05B1F2 0xC90    level 1
    init_basic_types                         0x05B052 0x1A0    level 2
    fe_cc_$end_compilation                   0x05B044 0xE      level 2
    preprocess                               0x05ABB4 0x3D4    level 2
    do_ansi_undefs                           0x05AAE2 0xD2     level 2
    do_ansi_defs                             0x05A952 0x190    level 2
    addincludes                              0x05A8A4 0xAE     level 2
    addarg                                   0x05A830 0x74     level 2
    rword_init                               0x05A644 0x1BE    level 2
    do_lex_for_listings                      0x05A600 0x44     level 2
    do_cmd_undefs                            0x05A558 0xA8     level 2
    do_cmd_defs                              0x05A3FA 0x15C    level 2
    make_main_pgm                            0x05A194 0x24A    level 2

### `lang/c_compiler/source/c_run_acpp.c`

- include `//us/us/unix/include/sys5.3/stdio.h`
- include `//us/us/unix/include/sys5.3/sys/types.h`
- include `//us/us/unix/include/sys5.3/sys/stdsyms.h`
- include `//us/us/unix/include/sys5.3/sys/stdtypes.h`
- include `//us/us/unix/include/sys5.3/sys/wait.h`

    c_cpp_present                            0x05C14C 0x2A     level 2
    c_delete_temp                            0x05C12A 0x22     level 2
    c_run_acpp                               0x05C0B8 0x72     level 2

### `lang/c_compiler/source/c_stmt_sem.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    fix_post_id                              0x05E9D0 0x166    level 2
    add_or_update                            0x05E950 0x80     level 2
    find_post_opnd                           0x05E8A4 0xAC     level 2
    only_logical                             0x05E7FE 0x9E     level 2
    build_cond_expr                          0x05E4CA 0x324    level 2
    eval_tree_nodes                          0x05E44E 0x7C     level 3
    build_not_expr                           0x05E2AA 0x1A4    level 2
    extend_boolean                           0x05E1EA 0xC0     level 2
    build_assign                             0x05DF82 0x262    level 2
    case_ini                                 0x05CC14 0x64     level 2
    pop_lbl                                  0x05CB16 0x34     level 2
    push_lbl                                 0x05CAEA 0x2C     level 2
    dcl_labl                                 0x05C9C6 0x6E     level 2
    fnd_labl                                 0x05C97A 0x4C     level 2
    add_cbrn                                 0x05C944 0x36     level 2
    add_cbranch                              0x05C6A8 0x274    level 2
    add_brn                                  0x05C5BC 0xEC     level 2
    add_ldfn                                 0x05C336 0x24E    level 2
    add_eval                                 0x05C27E 0xB8     level 2
    add_be_eval                              0x05C254 0x2A     level 2
    add_top_node                             0x05C220 0x34     level 2
    temp_alloc                               0x05DDBA 0x1BC    level 2
    walk_tree                                0x05EBB8 0x92E    level 2
    is_post_incr_candidate                   0x05EB36 0x82     level 3
    link_top                                 0x05C178 0xA8     level 2
    def_def_label                            0x05C584 0x38     level 2
    goto_s                                   0x05DD2C 0x8E     level 2
    return_s                                 0x05DD0A 0x22     level 2
    nxtext_s                                 0x05DC78 0x92     level 2
    body_e                                   0x05DA4E 0x22A    level 2
    finish_profiling                         0x05D918 0x12E    level 3
    body_s                                   0x05D8AC 0x6C     level 2
    do_monstartup                            0x05D6AC 0x1EA    level 3
    setup_profiling                          0x05D4B2 0x1E4    level 3
    call_s                                   0x05D2DC 0x1D6    level 2
    repeat_e                                 0x05D278 0x64     level 2
    repeat_s                                 0x05D234 0x44     level 2
    for_e                                    0x05D1E6 0x4E     level 2
    for_next_lab                             0x05D1B0 0x36     level 2
    for_s                                    0x05D180 0x30     level 2
    for_start_lab                            0x05D13C 0x44     level 2
    while_e                                  0x05D0EE 0x4E     level 2
    while_s                                  0x05D0BE 0x30     level 2
    while_label                              0x05D07A 0x44     level 2
    case_e                                   0x05D024 0x56     level 2
    case_default                             0x05CEFC 0x128    level 2
    case_s                                   0x05CDA6 0x156    level 2
    case_con                                 0x05CC78 0x12E    level 2
    endif_s                                  0x05CBCA 0x4A     level 2
    else_s                                   0x05CB80 0x4A     level 2
    if_s                                     0x05CB4A 0x36     level 2
    def_labl                                 0x05CA34 0xB6     level 2

### `lang/c_compiler/source/c_sym_map.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`

    sym_map                                  0x060804 0x42C    level 2
    print_addr_cons                          0x06043E 0x374    level 3
    print_ac_ref                             0x060338 0xCA     level 3
    print_ac_key                             0x0601CC 0xF8     level 3
    print_vat                                0x060056 0xF8     level 3
    print_block                              0x05FDCA 0x24C    level 3
    print_type                               0x05F81C 0x52A    level 3
    print_attr                               0x05F61E 0x190    level 3
    tattr_to_vattr                           0x05F5FA 0x24     level 3
    print_con                                0x05F540 0xBA     level 3
    print_10                                 0x05F514 0x2C     level 3

### `lang/c_compiler/source/c_syntax.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/peb.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/externals.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/c_compiler/source/c_syntax.ins.pas`
- include `//lang/c_compiler/source/c_expr_syn.ins.pas`

    abstract_decl                            0x067192 0x374    level 2
    call_kfold_fold_addrs                    0x066410 0x2C     level 2
    int_ob_kind_from_integer_type            0x063C80 0x88     level 2
    type_qualifiers                          0x06223E 0xAA     level 2
    storage_class                            0x062128 0x110    level 2
    add_top_node                             0x0617E0 0x36     level 2
    get_options                              0x061614 0x1BE    level 2
    avoid_void                               0x06155E 0xB6     level 2
    parse_attributes                         0x061108 0x414    level 2
    check                                    0x060EB8 0x30     level 2
    warning                                  0x060EA0 0x18     level 2
    error                                    0x060E16 0x7C     level 2
    initialize_legal_specs                   0x060DB8 0x5E     level 2
    init_refvar                              0x066EFA 0x1DA    level 2
    clear_operands                           0x066DD2 0x128    level 2
    constant_expr                            0x06685C 0x3AA    level 2
    return_stat                              0x066C34 0x146    level 2
    continue_break                           0x066C20 0x14     level 2
    goto_stat                                0x066D7A 0x58     level 2
    for_stat                                 0x0661DE 0x1F6    level 2
    do_while_stat                            0x066082 0x140    level 2
    while_stat                               0x065F8C 0xE8     level 2
    case_or_default_stat                     0x065B04 0x102    level 2
    switch_stat                              0x065CA6 0x2BC    level 2
    pop_switch                               0x065C8A 0x1C     level 3
    push_switch                              0x065C14 0x76     level 3
    if_stat                                  0x0659F4 0x102    level 2
    compound_stat                            0x0658E8 0x10C    level 2
    stat                                     0x065654 0x278    level 2
    stat_list                                0x065524 0xF6     level 2
    body                                     0x06530E 0x1FA    level 2
    get_constant                             0x064E6A 0x494    level 2
    check_addr_init                          0x064DBC 0xAE     level 3
    varn_from_addr_con                       0x064D60 0x5C     level 3
    address_exposed                          0x064D34 0x2C     level 3
    init_with_string                         0x064C62 0xD2     level 2
    struct_init                              0x0647EE 0x474    level 2
    array_dim_init                           0x064506 0x2E8    level 2
    array_init                               0x06432E 0x1D8    level 2
    dynm_init                                0x064088 0x298    level 2
    enum_list                                0x063D32 0x19E    level 2
    enum__type                               0x063A04 0x27C    level 2
    member_list                              0x06364E 0x370    level 2
    struct_union_type                        0x063318 0x336    level 2
    function_def                             0x063108 0x34     level 2
    declaration                              0x06266C 0x70C    level 2
    declaration_stmts                        0x061816 0x8BC    level 2
    program_                                 0x060EE8 0x1D4    level 2
    function_prototype                       0x062DB8 0x350    level 2
    array_decl                               0x06314A 0x1C0    level 2
    declaration_specifiers                   0x06250E 0x15E    level 2
    type_specifier                           0x06232C 0x1D4    level 3
    check_add_spec                           0x0622E8 0x44     level 4
    c_type_name                              0x067506 0xF2     level 2
    data_init                                0x063EEC 0x19C    level 2
    call_kfold                               0x0663E2 0x2A     level 2
    cc_walk_it                               0x06643C 0x420    level 2
    pp_constant                              0x0670D4 0x96     level 2
    syntax                                   0x060C58 0x110    level 2

### `lang/c_compiler/source/fe_cc_hooks_to_backend.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`

    coproc_$suppress_warnings                0x0675FA 0x2      level 2
    dump_namelist                            0x0675F8 0x2      level 2
    isc_$init_well_known_types               0x0675FC 0x38     level 2

### `lang/c_compiler/source/frontend_cc_dummies.pas`


    pass_char_len_diff                       0x067688 0x16     level 2
    modify_m2_native_external_name           0x06766C 0x1C     level 2
    create_m2_native_external_name           0x067650 0x1C     level 2
    get_alignment                            0x067634 0x1C     level 2

### `lang/common/source/ass.pas`

- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`

    show_context                             0x0676A0 0x40     level 2
    ass_$disable_context_call_back           0x067C16 0x1E     level 2
    ass_$enable_context_call_back            0x067BA4 0x38     level 2
    ass_$describe                            0x067B44 0x60     level 2
    ass_$warning                             0x067A9C 0xA2     level 2
    ass_$os_error                            0x067A04 0x72     level 2
    ass_$not_implemented                     0x0679A4 0x60     level 2
    ass_$invariant_fail                      0x067944 0x60     level 2
    ass_$postcondition_fail                  0x0678E4 0x60     level 2
    ass_$precondition_fail                   0x067884 0x60     level 2
    ass_$restriction                         0x067824 0x60     level 2
    ass_$external_resource_error             0x0677C4 0x60     level 2
    ass_$external_data_error                 0x067764 0x60     level 2
    ass_$initialise                          0x0676E0 0x80     level 2

### `lang/common/source/bvs.pas`

- include `//lang/common/source/bvs.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    check2_same_size                         0x067E18 0x90     level 2
    check_same_size                          0x067CF0 0x74     level 2
    check                                    0x067C34 0x58     level 2
    bvs_$find_next                           0x0685E2 0xB0     level 2
    bvs_$set1_subsumes_set2                  0x068596 0x4C     level 2
    bvs_$subtract                            0x068552 0x44     level 2
    bvs_$and_to                              0x068502 0x50     level 2
    bvs_$and_and_test                        0x0684B0 0x52     level 2
    bvs_$or_and_test                         0x068464 0x4C     level 2
    bvs_$and                                 0x068420 0x44     level 2
    bvs_$or                                  0x0683DC 0x44     level 2
    bvs_$equal                               0x068392 0x4A     level 2
    bvs_$copy_and_test                       0x06834C 0x46     level 2
    bvs_$copy                                0x068302 0x4A     level 2
    bvs_$clear                               0x0682C2 0x40     level 2
    bvs_$set                                 0x068284 0x3E     level 2
    bvs_$test_and_clear                      0x06823C 0x48     level 2
    bvs_$test_and_set                        0x0681F6 0x46     level 2
    bvs_$test                                0x0681B8 0x3E     level 2
    bvs_$test_bit_vector                     0x06812C 0x62     level 2
    bvs_$reset_bit_vector                    0x0680A8 0x5A     level 2
    bvs_$bit_vector_bit_count                0x068044 0x36     level 2
    bvs_$dispose_bit_vector                  0x067FDC 0x3A     level 2
    bvs_$create_bit_vector                   0x067F74 0x68     level 2

### `lang/common/source/diag.pas`

- include `//lang/common/source/diag.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`

    about_to_write_to_line                   0x0686B8 0x22     level 2
    diag_$banner                             0x068A3E 0x46     level 2
    diag_$indent                             0x0689D4 0x6A     level 2
    diag_$drop_and_yield_prefix              0x068978 0x5C     level 2
    diag_$drop_prefix                        0x06895C 0x1C     level 2
    diag_$set_prefix                         0x0688F6 0x66     level 2
    diag_$current_column                     0x0688DE 0x18     level 2
    diag_$tab_to_with_fill                   0x06885E 0x60     level 2
    diag_$tab_to                             0x0688BE 0x20     level 2
    diag_$assure_fresh_line                  0x068842 0x1C     level 2
    diag_$new_line                           0x0687DA 0x60     level 2
    diag_$writeln                            0x06877A 0x60     level 2
    diag_$write                              0x0686DA 0xA0     level 2

### `lang/common/source/ecb.pas`

- include `//lang/common/source/ecb.ins.pas`
- include `//lang/common/source/st.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`

    ecb_$allocate_ecb                        0x068A88 0xB2     level 2

### `lang/common/source/exs.pas`

- include `//lang/common/source/exs.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/bvs.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    set_frame                                0x06A018 0x1C     level 2
    exs_$cancel_exception_handler_enquiry    0x069EDE 0x1E     level 2
    find_next_exception_handler              0x0698C4 0x12E    level 2
    init_exception_handler_enquiry           0x0697BE 0xC0     level 2
    exception_info                           0x068E7C 0x450    level 2
    set_access_fault                         0x068E4E 0x2E     level 3
    set_predefined                           0x068E22 0x2C     level 3
    set_bit                                  0x068DF4 0x2E     level 3
    copy_bit_vector                          0x068DB8 0x3C     level 3
    reset_bit_vector                         0x068D80 0x38     level 3
    set_predefined_exception                 0x068D2C 0x54     level 2
    exception_name_index                     0x068C58 0x5A     level 2
    check_frame                              0x068B88 0x40     level 2
    exs_$frame_is_lexically_nested           0x06A26A 0x7C     level 2
    exs_$frame_has_handler_for_predefined_exception 0x06A22A 0x40     level 2
    exs_$subprogram_may_propogate_exceptions_by_explicit_raise 0x06A160 0x6A     level 2
    exs_$routines_next_exception_handler     0x06A0AC 0x78     level 2
    exs_$start_all_exception_handlers_of_routine_enquiry 0x06A034 0x36     level 2
    exs_$map_to_predefined_exception         0x069F3A 0x54     level 2
    exs_$exception_raise_strategy            0x069FCC 0x4C     level 2
    exs_$end_exception_handler_enquiry       0x069CB2 0xD0     level 2
    exs_$next_exception_handler              0x069C60 0x52     level 2
    exs_$start_exception_handler_enquiry     0x069A2A 0x1EE    level 2
    exs_$end_current_subprogram              0x06972A 0x62     level 2
    exs_$start_subprogram                    0x0695F0 0xAC     level 2
    exs_$finalise                            0x069552 0x80     level 2
    exs_$initialise                          0x06932A 0xD4     level 2

### `lang/common/source/htm.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/htm.ins.pas`

    htm_$hash_running_byte_multiple          0x06AA5A 0x5A     level 2
    htm_$hash_running_quad_multiple          0x06A8E8 0x172    level 2
    htm_$hash_upcased_name                   0x06A830 0xB8     level 2
    htm_$hash_string                         0x06A7C0 0x70     level 2
    htm_$hash_quad                           0x06A656 0x16A    level 2
    htm_$hash_long                           0x06A58C 0xCA     level 2
    htm_$hash_word                           0x06A50E 0x7E     level 2
    htm_$hash_byte                           0x06A4BE 0x50     level 2
    htm_$increment_table_entries             0x06A3A8 0xF6     level 2
    htm_$bucket                              0x06A49E 0x20     level 2
    htm_$release_table                       0x06A34C 0x3A     level 2
    htm_$create_table                        0x06A2E8 0x64     level 2

### `lang/common/source/mem.pas`

- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    mrh_release                              0x06B022 0x38     level 2
    mrh_mark                                 0x06AFF0 0x32     level 2
    mrh_empty_pool                           0x06AFCA 0x26     level 2
    mrh_alloc                                0x06AEFC 0x6C     level 2
    rws_release                              0x06AE34 0x8A     level 2
    rws_empty_pool                           0x06ADFC 0x38     level 2
    rws_dispose                              0x06AD32 0x8A     level 2
    rws_alloc                                0x06ACD2 0x60     level 2
    rws_dispose_chunk                        0x06ABDE 0x6A     level 2
    rws_alloc_chunk                          0x06AAD4 0xAC     level 2
    pool_name_len                            0x06AAB4 0x20     level 2
    mem_$reset                               0x06B0A2 0x80     level 2
    mem_$release                             0x06B44A 0x82     level 2
    mem_$mark                                0x06B3A6 0x82     level 2
    mem_$dispose                             0x06B2EC 0x5A     level 2
    mem_$empty_pool                          0x06B268 0x5C     level 2
    mem_$alloc                               0x06B1BE 0x84     level 2
    mem_$open_pool                           0x06B134 0x8A     level 2
    mem_$initialise                          0x06B05A 0x48     level 2

### `lang/common/source/pds.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/dst.ins.pas`
- include `//lang/common/source/pds.ins.pas`
- include `//lang/common/source/pds.pvt.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//us1/us1/lib/dblib/loc/src/loc_build.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/config_misc.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//lang/common/source/htm.ins.pas`

    construct_ordered_rec_list               0x07330A 0x3C     level 2
    order_this_rec                           0x07310A 0x1D4    level 2
    append_ordered_rec_to_bucket             0x0730BE 0x4C     level 2
    dump_local_file_table                    0x072FAA 0xE4     level 2
    dump_section_header                      0x072F6C 0x3E     level 2
    pool_local_file_table_entries            0x072E5C 0xD4     level 2
    add_local_file_entry                     0x072D26 0x100    level 2
    calculate_crc                            0x072B92 0x134    level 2
    construct_a_dag                          0x07292A 0x62     level 2
    build_dependency_graph                   0x07286E 0xBC     level 2
    dag_visit                                0x072722 0x14C    level 2
    add_to_dag                               0x0726EA 0x38     level 2
    append_to_merge_list                     0x072586 0xF2     level 2
    do_merge                                 0x072454 0x132    level 2
    do_dfs_ordering                          0x07234C 0x9E     level 2
    sprinkle_incl_end_scope_recs             0x0722EE 0x5E     level 2
    dump_incl_table                          0x0721A2 0xEC     level 2
    add_references                           0x07167C 0xA14    level 2
    add_aux_references                       0x0713CE 0x1BE    level 2
    make_type_ref_from_aux                   0x07117A 0x11A    level 2
    make_rec_ref_from_aux                    0x070F84 0xB0     level 2
    make_name_ref_from_aux                   0x070EAC 0x5E     level 2
    make_loc_ref_from_aux                    0x070DCA 0x6A     level 2
    make_loc_ref                             0x070CFA 0x6A     level 2
    make_name_ref                            0x070C34 0x5E     level 2
    make_type_ref                            0x0709D6 0x11A    level 2
    make_rec_ref                             0x070854 0xAE     level 2
    make_relative_ref                        0x07080E 0x46     level 2
    make_include_rec_ref                     0x0706A2 0xB6     level 2
    get_var_attrs                            0x0705CA 0x7E     level 2
    get_arg_attrs                            0x0704EC 0x84     level 2
    get_dtc                                  0x07041A 0xAE     level 2
    dump_rec                                 0x06FFE6 0x396    level 2
    dump_aux_recs                            0x06FD66 0x214    level 2
    dump_loc_pool                            0x06FCF0 0x76     level 2
    dump_string_table                        0x06FB4C 0x14E    level 2
    pool_crc_entries                         0x06F930 0x1A4    level 2
    add_crc_entry_for_type_ref               0x06F7E6 0x86     level 2
    add_crc_entry                            0x06F7AE 0x38     level 2
    get_include_table_index                  0x06F732 0x7C     level 2
    create_new_crc_table_entry               0x06F65C 0x78     level 2
    pool_strings                             0x06F4BE 0x174    level 2
    add_file_string                          0x06F49E 0x20     level 2
    add_string                               0x06F47C 0x22     level 2
    add_str                                  0x06F3CA 0xB2     level 2
    downcase_string                          0x06F386 0x44     level 2
    hash_it                                  0x06F35C 0x2A     level 2
    allocate_dst_rec                         0x06F272 0x76     level 2
    process_symbols_rec                      0x06EB90 0x2D2    level 2
    order_root_rec_in_bucket                 0x06E99C 0x106    level 2
    append_root_rec_to_bucket                0x06E948 0x54     level 2
    compare_bytes_case                       0x06E84A 0xEC     level 2
    memcmp                                   0x06E80C 0x3E     level 2
    get_name_p                               0x06E6E8 0xD4     level 2
    get_bucket_index                         0x06E644 0x72     level 2
    make_end_scope_rec                       0x06E366 0x1A     level 2
    make_incl_end_scope_rec                  0x06E34C 0x1A     level 2
    make_incl_start_scope_rec                0x06E28E 0x50     level 2
    get_bucket                               0x06E214 0x7A     level 2
    get_offset_within_section                0x06E094 0x66     level 2
    make_aux_field_off_rec                   0x06B5CC 0x3E     level 2
    alloc_aux_rec                            0x06B558 0x4A     level 2
    alloc_rec                                0x06B4E8 0x4A     level 2
    pds_$get_scope_offset_within_section     0x06DE8C 0x88     level 2
    pds_$dump_symbols_section                0x073346 0x212    level 2
    pds_$create_symbols_sections             0x0729B8 0xC0     level 2
    pds_$end_scope                           0x06F170 0xD8     level 2
    pds_$enter_named_record_current_scope    0x06F06C 0x82     level 2
    pds_$begin_scope                         0x06E5FE 0x46     level 2
    pds_$finalize                            0x06E5C8 0x36     level 2
    pds_$enter_main_file_table               0x06E4BC 0x82     level 2
    pds_$initialize                          0x06E380 0x92     level 2
    pds_$add_aux_rec                         0x06DDE0 0x64     level 2
    pds_$make_aux_ptr_base_rec               0x06DD26 0x52     level 2
    pds_$make_aux_lifetime_rec               0x06DCB8 0x40     level 2
    pds_$make_aux_type_deriv_rec             0x06DC2A 0x50     level 2
    pds_$make_aux_var_bound_rec              0x06DBEC 0x3E     level 2
    pds_$make_aux_field_align_rec            0x06DB6A 0x4C     level 2
    pds_$make_aux_align_rec                  0x06DB3C 0x2E     level 2
    pds_$make_aux_field_size_rec             0x06DABC 0x4C     level 2
    pds_$make_aux_size_rec                   0x06DA90 0x2C     level 2
    pds_$make_aux_reg_val_rec                0x06DA0E 0x50     level 2
    pds_$make_string_rec                     0x06D90E 0x9C     level 2
    pds_$make_array_rec                      0x06D7E0 0xCA     level 2
    pds_$add_field                           0x06D65C 0xC6     level 2
    pds_$make_field                          0x06D4BC 0xBE     level 2
    pds_$make_record_rec                     0x06D42C 0x90     level 2
    pds_$add_short_field                     0x06D2AA 0xA2     level 2
    pds_$make_short_field                    0x06D1F0 0x62     level 2
    pds_$make_short_record_rec               0x06D160 0x90     level 2
    pds_$add_explicit_enum_element           0x06CFE0 0x78     level 2
    pds_$make_explicit_enum_element          0x06CF5C 0x50     level 2
    pds_$make_explicit_enum_rec              0x06CEF0 0x6C     level 2
    pds_$add_implicit_enum_element           0x06CD70 0x78     level 2
    pds_$make_implicit_enum_rec              0x06CC88 0x88     level 2
    pds_$make_offset_rec                     0x06CB34 0xBA     level 2
    pds_$make_file_rec                       0x06CA94 0x6C     level 2
    pds_$make_subrange_rec                   0x06C9A0 0x94     level 2
    pds_$make_set_rec                        0x06C888 0x9C     level 2
    pds_$make_constant_rec                   0x06C760 0x92     level 2
    pds_$make_constant_value                 0x06C70C 0x54     level 2
    pds_$add_label_loc                       0x06C664 0x4E     level 2
    pds_$make_label_rec                      0x06C5D4 0x6A     level 2
    pds_$add_file_entry                      0x06C45C 0x80     level 2
    pds_$make_file_table                     0x06C3EC 0x4C     level 2
    pds_$make_file_entry                     0x06C374 0x50     level 2
    pds_$add_dependent_type_to_alias_rec     0x06C244 0x60     level 2
    pds_$make_alias_rec                      0x06C1B4 0x6A     level 2
    pds_$add_arg_to_signature                0x06C04C 0x74     level 2
    pds_$make_arg                            0x06BFCA 0x54     level 2
    pds_$add_arg_attr                        0x06BF26 0x50     level 2
    pds_$make_arg_attr                       0x06BF04 0x22     level 2
    pds_$make_signature_rec                  0x06BE98 0x6C     level 2
    pds_$add_entry_point_loc                 0x06BDF0 0x4E     level 2
    pds_$make_entry_rec                      0x06BD04 0x8A     level 2
    pds_$add_var_loc                         0x06BC64 0x4E     level 2
    pds_$make_variable_rec                   0x06BB6C 0x8A     level 2
    pds_$add_var_attr                        0x06BA84 0x66     level 2
    pds_$make_var_attr                       0x06BA62 0x22     level 2
    pds_$make_pointer_rec                    0x06B9C2 0x6A     level 2
    pds_$make_type                           0x06B894 0x80     level 2
    pds_$make_loc                            0x06B794 0x80     level 2
    pds_$make_src_loc                        0x06B6C8 0x64     level 2
    pds_$make_name                           0x06B640 0x60     level 2

### `lang/common/source/spos.pas`

- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/spos.pvt.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    calculate_source_position                0x073780 0x92     level 2
    spos_$capture_file_marks                 0x074748 0x52     level 2
    spos_$apply_over_marked_source_files     0x0746F4 0x54     level 2
    spos_$apply_over_source_files            0x0746A2 0x52     level 2
    spos_$number_of_marked_source_files      0x07468A 0x18     level 2
    spos_$lock_source_file_marks             0x074670 0x1A     level 2
    spos_$number_of_source_files             0x074656 0x1A     level 2
    spos_$region_is_marked                   0x07479A 0x72     level 2
    spos_$mark_main_source_file              0x074634 0x22     level 2
    spos_$mark_source_file                   0x0744FC 0x86     level 2
    spos_$diag_dump_source_position_database 0x074B44 0xAE     level 2
    spos_$diag_dump_source_position          0x074ABC 0x62     level 2
    spos_$diag_dump_source_region            0x07486E 0x14C    level 2
    spos_$region_unit_name                   0x07444C 0x4E     level 2
    spos_$region_dtm                         0x0743A2 0x4E     level 2
    spos_$region_full_path_name              0x0742EE 0x4E     level 2
    spos_$region_name_used_to_open           0x074236 0x4E     level 2
    spos_$region_user_name                   0x074186 0x4E     level 2
    spos_$last_source_region                 0x07416C 0x1A     level 2
    spos_$encode_source_position             0x073FA4 0x116    level 2
    spos_$decode_source_position             0x073F24 0x80     level 2
    spos_$line_is_in_main_source_file        0x073F08 0x1C     level 2
    spos_$is_main_source_file                0x073EEC 0x1C     level 2
    spos_$change_file                        0x073D58 0xAE     level 2
    spos_$resume_file                        0x073A2A 0x164    level 2
    spos_$may_start_include_file             0x073A04 0x26     level 2
    spos_$start_include_file                 0x07388E 0xE2     level 2
    spos_$skip_lines                         0x073866 0x28     level 2
    spos_$enquire_next_line                  0x07383A 0x2C     level 2
    spos_$next_line                          0x073812 0x28     level 2
    spos_$init_source_position               0x073650 0xCC     level 2

### `lang/common/source/std.pas`

- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    std_$diag_dump_var_string                0x074EEA 0x32     level 2
    std_$append_integer                      0x074E64 0x86     level 2
    std_$append_string                       0x074E28 0x3C     level 2
    std_$append_char                         0x074E04 0x24     level 2
    std_$diag_dump_any_string                0x074DA4 0x58     level 2
    std_$diag_dump_boolean                   0x074D6A 0x2A     level 2
    std_$round_up_to_multiple_of             0x074D1C 0x4E     level 2
    std_$in_range_lower_minus_1_to_upper_plus_1 0x074CEC 0x30     level 2
    std_$in_range_lower_minus_1_to_upper     0x074CBC 0x30     level 2
    std_$in_range_lower_to_upper_plus_1      0x074C8C 0x30     level 2
    std_$in_range_lower_to_upper             0x074C5C 0x30     level 2

### `lang/common/source/token.pas`

- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/token.low.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    token_$identifier                        0x0751E4 0x76     level 2
    token_$diag_dump_char_string             0x0752E2 0x8E     level 2
    token_$char_string                       0x075162 0x4C     level 2
    token_$double_float_to_constant          0x075136 0x2C     level 2
    token_$single_float_to_constant          0x0750F6 0x40     level 2
    token_$discrete_scalar_to_constant       0x0750DE 0x18     level 2
    token_$discrete_scalar                   0x075068 0x76     level 2
    token_$constant_byte_size                0x074F1C 0xEC     level 2

### `lang/lang/source/opt_assign.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    merge_assignments                        0x2A0B74 0x1E2    level 2
    assert_merge_would_produce_misleading_aliasing 0x2A0B2C 0x48     level 2
    assign_opt                               0x2A1236 0x6E8    level 2
    at_offset                                0x2A1152 0xE4     level 3
    ok_node                                  0x2A0F5E 0x1DA    level 3
    var_is_ok                                0x2A0E12 0x14C    level 3
    cplong                                   0x2A0DE2 0x30     level 3
    cpword                                   0x2A0DB4 0x2E     level 3
    cpbyte                                   0x2A0D9C 0x18     level 3

### `lang/lang/source/opt_cse.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`

    cse_$cse_two_nodes                       0x2A2A28 0xA4     level 2
    assert_zombie_tree                       0x2A2A02 0x26     level 2
    cse_$is_cseable                          0x2A22E8 0x710    level 2
    cse_$set_hoistability                    0x2A229E 0x4A     level 2
    assert_disp_over_ptr                     0x2A2272 0x2C     level 2
    cse_$next_cse_serial                     0x2A2214 0x5E     level 2
    cse_$cleanup_phase                       0x2A2070 0x1A4    level 2
    check_uplevel_and_moved_check            0x2A2022 0x4E     level 2
    walkopr                                  0x2A1BEC 0x1F6    level 2
    saveparent_and_patch                     0x2A1BB6 0x36     level 2
    patch                                    0x2A1AF6 0xC0     level 2
    make_cse_parent                          0x2A1A1E 0xD8     level 2
    moved_check                              0x2A1FD0 0x52     level 2
    make_cse_use                             0x2A1938 0xE6     level 2
    csecleanup                               0x2A1E02 0x1CE    level 2
    cse                                      0x2A2ACC 0x97E    level 2

### `lang/lang/source/opt_general.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/commit_top_node.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`

    squash_this_eval_operand                 0x2A3524 0x22     level 2
    assert_is_useless_under_eval             0x2A3502 0x22     level 2
    assert_is_explicitly_useless_object      0x2A34BA 0x2E     level 2
    assert_is_scrutable_tree_not_used_elsewhere 0x2A3486 0x34     level 2
    assert_is_a_variable                     0x2A3464 0x22     level 2
    opt_gen_$prune_eval_operands             0x2A3546 0x7E     level 2
    general_opts                             0x2A36E2 0x4CA    level 2
    find_var                                 0x2A3BFE 0x7C     level 2
    is_scale_candidate                       0x2A35C4 0x11E    level 2

### `lang/lang/source/opt_livevar.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`

    for_check                                0x2A5430 0x16E    level 2
    lvanalyze                                0x2A529E 0x192    level 2
    buildsets                                0x2A507A 0x224    level 2
    varcheck                                 0x2A4CBE 0x39A    level 2
    addvaruse                                0x2A4C1C 0xA2     level 2
    assign_elim                              0x2A44F2 0x72A    level 2
    stmtwalk                                 0x2A43AC 0x12C    level 2
    elim_chains                              0x2A42AA 0x102    level 2
    build_du_chains                          0x2A40C0 0x1EA    level 2
    check_cse_uses                           0x2A4014 0xAC     level 2
    remove_bad_parents                       0x2A3F0E 0x106    level 2
    pwalk                                    0x2A3DF8 0x116    level 2
    ensure_parental_correctness              0x2A3DC0 0x38     level 2
    bad_parent                               0x2A3D96 0x2A     level 2
    opt_livevar_$report_removal              0x2A3D36 0x60     level 2
    opt_livevar_$store_to_stack_temp         0x2A3D00 0x36     level 2
    opt_livevar_$formal_value_param_copy     0x2A3CB2 0x4E     level 2
    opt_livevar_$find_nearest_spos_node      0x2A3C7C 0x36     level 2
    liveanalysis                             0x2A559E 0x5B2    level 2

### `lang/lang/source/opt_loop.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    findlooptail                             0x2A75F2 0x4C     level 2
    moveinvariants                           0x2A6C12 0x9DA    level 2
    movenode                                 0x2A6A04 0x20C    level 2
    notalreadymoved                          0x2A68BE 0x146    level 2
    checkcses                                0x2A5DFE 0x702    level 2
    do_move_check                            0x2A5CD0 0x12E    level 2
    assert_contains_ref_to_sr_temp           0x2A5B50 0x180    level 2
    motion_constants                         0x2A7C7C 0x1FC    level 2
    walkt                                    0x2A7A64 0x208    level 3
    loopopt                                  0x2A763E 0x426    level 2
    fixupchildren                            0x2A65D4 0x2EA    level 2
    add_constant                             0x2A654E 0x86     level 2

### `lang/lang/source/opt_main.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/pfm.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    init_opt_info_for_vars                   0x2AC122 0x384    level 2
    use_def_proc                             0x2ABF52 0x184    level 2
    add_def_for_params_at_routine_entry      0x2ABEFC 0x56     level 2
    add_use_defs_for_statics_and_params      0x2ABD62 0x19A    level 2
    assert_defined_on_entry                  0x2ABC24 0x13E    level 2
    opt_main_$var_is_param_of_routine        0x2ABBCA 0x5A     level 2
    add_use_defs_for_call_site               0x2ABA38 0x192    level 2
    create_use_def_ob                        0x2AB8C4 0x174    level 2
    opt_main_$strip_all_use_def_obs          0x2AB788 0x98     level 2
    reviseuses                               0x2AB5F2 0x196    level 2
    distribute                               0x2AB51E 0xD4     level 2
    dwalk                                    0x2AB3B0 0x16E    level 2
    convert_exponentiation                   0x2AB1A2 0x1F4    level 2
    distrib_mul                              0x2AAC22 0x56C    level 2
    fixup_rlen_of_mul                        0x2AAAE2 0x116    level 3
    crush_disp_2                             0x2AAA58 0x8A     level 3
    possible_rlens_of_operand                0x2AA9A0 0xB8     level 3
    convert_lshf_to_mul                      0x2AA94A 0x56     level 3
    no_enforce_parens_and_ucs_eq_1           0x2AA8BE 0x8C     level 3
    recover_scaled                           0x2AA7AA 0x114    level 2
    recover                                  0x2AA420 0x38A    level 2
    makedindex                               0x2AA308 0x118    level 2
    coalesce_adjacent_and_eliminate_dead_assignments 0x2AA260 0xA8     level 2
    eliminate_dead_code_and_count_basic_blocks 0x2AA092 0x1CE    level 2
    recompute_usedef_for_uplevel_addressing  0x2A9EB4 0x1DE    level 2
    recompute_usedef_for_strength_reduction  0x2A9D8C 0x128    level 2
    compute_basic_block_dominance_relationships 0x2A9CC2 0xCA     level 2
    compute_preds_and_succs_for_dominance    0x2A9B84 0x13E    level 2
    compute_dominator_matrix                 0x2A9AB6 0xCE     level 2
    compute_depth_first_order_of_basic_blocks 0x2A99E6 0xD0     level 2
    compute_basic_block_relationships        0x2A98F8 0xEE     level 2
    compute_abnormality_due_to_proc_calls    0x2A966C 0x234    level 2
    assert_is_call_to_abnormal_routine       0x2A95B6 0xB6     level 2
    assert_is_pointer_deref_of_volatile_object 0x2A9596 0x20     level 2
    assert_cleanup_body                      0x2A9544 0x26     level 2
    compute_successors                       0x2A9402 0xDC     level 2
    resolve_nlbranch_targets                 0x2A9336 0x9A     level 2
    killvisited                              0x2A92B2 0x6A     level 2
    recompute_stmt_nodes                     0x2A9244 0x6E     level 2
    initialize_stmt_nodes                    0x2A9192 0xA6     level 2
    check_dominators                         0x2A9064 0x12E    level 2
    compute_variable_type_descriptors        0x2A8F48 0x11C    level 2
    compute_label_backward_refs_due_to_assigned_goto 0x2A8EBC 0x8C     level 2
    assert_is_lexically_earlier_statement    0x2A8E6C 0x50     level 2
    assert_is_fortran_assigned_goto          0x2A8E32 0x3A     level 2
    assert_is_nonlocal_branch                0x2A8E1A 0x18     level 2
    add_successor                            0x2A8D68 0x8A     level 2
    add_predecessor                          0x2A8D1A 0x4E     level 2
    new_successor_list                       0x2A8C52 0x60     level 2
    new_basic_block                          0x2A8B7E 0xA2     level 2
    mark_begins_basic_block                  0x2A8B08 0x2E     level 2
    mark_if_begins_basic_block               0x2A8A62 0x5C     level 2
    assert_reached_by_linear_flow_from_previous_basic_block 0x2A8A08 0x5A     level 2
    assert_is_unsafe_abnormal_label          0x2A89E2 0x26     level 2
    assert_is_assigned_goto_label            0x2A89A0 0x42     level 2
    assert_is_abnormal_label                 0x2A897A 0x26     level 2
    assert_is_entry_label                    0x2A8944 0x36     level 2
    assert_is_entry_block_entry              0x2A891A 0x2A     level 2
    assert_is_entry_block                    0x2A8902 0x18     level 2
    assert_is_predecessor                    0x2A887C 0x86     level 2
    opt_main_$collapse_fortran_complex_assigns 0x2A8748 0x134    level 2
    opt_main_$complex_intrinsic_decomposition 0x2A8694 0xB4     level 2
    opt_main_$complex_decomposition          0x2A84E8 0x1AC    level 2
    assert_is_call_tree                      0x2A8484 0x32     level 2
    assert_is_fortran_temp                   0x2A845A 0x2A     level 2
    assert_is_fortran_symbol                 0x2A8442 0x18     level 2
    assert_is_var_name                       0x2A842A 0x18     level 2
    assert_is_a_variable                     0x2A8408 0x22     level 2
    assert_statement_is_interesting_in_postorder_node_list 0x2A83D0 0x38     level 2
    new_postorder_node_list_entry            0x2A8394 0x3C     level 2
    realloc_postorder_node_list              0x2A826C 0xA2     level 2
    assert_is_artificial_statement           0x2A822C 0x40     level 2
    assert_is_branch_to_artificial_label     0x2A820C 0x20     level 2
    assert_is_conditional_branch_to_artificial_label 0x2A81CA 0x42     level 2
    assert_is_unconditional_branch_to_artificial_label 0x2A818A 0x40     level 2
    assert_is_artificial_label               0x2A8158 0x32     level 2
    assert_is_childless_eval                 0x2A8140 0x18     level 2
    assert_is_label                          0x2A8128 0x18     level 2
    assert_is_branch                         0x2A810A 0x1E     level 2
    assert_is_unconditional_branch           0x2A80E8 0x22     level 2
    assert_is_conditional_branch             0x2A80D0 0x18     level 2
    assert_is_top_level_statement            0x2A808C 0x26     level 2
    assert_is_defined_spos                   0x2A807C 0x10     level 2
    dispose_postorder_node_list              0x2A806A 0x12     level 2
    alloc_postorder_node_list                0x2A8044 0x26     level 2
    dispose_hoist                            0x2A802A 0x1A     level 2
    alloc_hoist                              0x2A800E 0x1C     level 2
    alloc_block_list                         0x2A7FE8 0x26     level 2
    zero_bytes                               0x2A7F92 0x56     level 2
    zero_longwords                           0x2A7F7E 0x14     level 2
    estimate_register_consumption_of_all_statements 0x2A7F32 0x4C     level 2
    limit_of_cse_backwards_reach             0x2A7F0E 0x24     level 2
    assert_language_on_il_spine_is_ada       0x2A7EC8 0x46     level 2
    assert_common_subexpression_phase_is_enabled 0x2A7EB0 0x18     level 2
    assert_optimizer_is_enabled              0x2A7E78 0x38     level 2
    opt_main_$symidx_of_varn_or_fsym         0x2AB820 0x5C     level 2
    opt_main_$is_fortran_asf                 0x2AC0D6 0x4C     level 2
    opt_main_$ensure_var_set                 0x2A84B6 0x32     level 2
    fixup_blocks                             0x2AC4A6 0x1A2    level 2
    g_opt                                    0x2ADF36 0x9FA    level 2
    recompute_node_lists                     0x2ADEC0 0x76     level 3
    make_new_postorder_node_list             0x2AD6A0 0x820    level 3
    add_interior_node_to_postorder_node_list 0x2AD1D2 0x4CE    level 3
    note_variable_use                        0x2AD16C 0x66     level 3
    count_for_postorder_node_list            0x2ACED6 0x296    level 3
    count_interior_nodes_for_postorder_node_list 0x2AC6D4 0x7FC    level 3
    crush_undesired_extend                   0x2AC67E 0x56     level 4
    find_eval                                0x2AC648 0x36     level 3
    opt_main_$initialize                     0x2AE930 0xD8     level 2

### `lang/lang/source/opt_reachdef.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`

    statement_contained_by_unreachable_basic_block 0x2B1348 0x84     level 2
    assert_is_dominated_by_some_entrypoint   0x2B1310 0x38     level 2
    assert_block_is_entrypoint               0x2B12F2 0x1E     level 2
    assert_predecessor_is_me                 0x2B12D4 0x1E     level 2
    assert_no_predecessors                   0x2B12BE 0x16     level 2
    evalforeffect                            0x2B047C 0xE28    level 2
    propagate                                0x2B027E 0x1FE    level 3
    build_ud_chains                          0x2AFAA0 0x1D2    level 2
    make_ud_chain                            0x2AF8D6 0x182    level 2
    compute_rd                               0x2AF6C4 0x212    level 2
    genkill                                  0x2AF494 0xB8     level 2
    add_def_stmt                             0x2AF3D0 0xC4     level 2
    bclr                                     0x2AF0B8 0x4A     level 2
    bset                                     0x2AF070 0x48     level 2
    zero_bytes                               0x2AF01A 0x56     level 2
    zero_longwords                           0x2AF006 0x14     level 2
    dumprd                                   0x2AEEB8 0xF4     level 2
    dumprdset                                0x2AEDE0 0xD4     level 2
    dbs                                      0x2AED16 0xC6     level 2
    pt                                       0x2AECE4 0x32     level 2
    assert_this_definition_on_ud_chain       0x2AECA6 0x3E     level 2
    assert_nonempty_var_use_set              0x2AEC88 0x1E     level 2
    assert_uninitialized_value_can_reach     0x2AEB70 0x118    level 2
    assert_def_dominates_use                 0x2AEB2E 0x42     level 2
    basic_block_of_def                       0x2AEAF8 0x36     level 2
    stmt_index_from_rdset                    0x2AEAD0 0x28     level 2
    releaserd                                0x2AF102 0x54     level 2
    reachingdefinitions                      0x2B181C 0x10A8   level 2
    init_block                               0x2B1506 0x316    level 3
    ftn_data_init                            0x2B1440 0xC6     level 3
    paramclass                               0x2AF54C 0x178    level 2
    markuses                                 0x2B0084 0x1FA    level 2
    walk_tree                                0x2AFC72 0x3C4    level 3
    make_motioned_ud_chain                   0x2AFA58 0x48     level 2
    initrd                                   0x2AF210 0x1C0    level 2
    alloc_rdset                              0x2AF156 0xBA     level 3
    adjust_ptr                               0x2AEFCC 0x3A     level 2

### `lang/lang/source/opt_select.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    eval                                     0x2B294E 0x24     level 2
    compress                                 0x2B2902 0x4C     level 2
    resetserial                              0x2B28C4 0x3E     level 2
    select_loop                              0x2B2AEC 0xA2     level 2
    find_loops                               0x2B2EFA 0x182    level 2
    dfs                                      0x2B2BE8 0x74     level 2
    dominators                               0x2B2D60 0x19A    level 2
    dom                                      0x2B2972 0x58     level 2
    depth_first_dom                          0x2B2C5C 0x104    level 2
    new_block                                0x2B2B8E 0x5A     level 2
    select_block_list                        0x2B29CA 0x122    level 2

### `lang/lang/source/opt_strength.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    walkuses                                 0x2B3A1C 0x26E    level 2
    strengthreduce                           0x2B3ED4 0x2      level 2
    opt_str_$product_of_consts               0x2B307C 0xC2     level 2
    opt_str_$product_of                      0x2B34D0 0x25E    level 2
    smuggle_constants                        0x2B338E 0x142    level 3
    identity_mul                             0x2B32F8 0x96     level 3
    opt_str_$opmod_of_operand                0x2B318E 0x132    level 2
    sizeof_dataclass                         0x2B3158 0x36     level 3
    delparent                                0x2B39CA 0x52     level 2
    deluse                                   0x2B3976 0x54     level 2
    opt_str_$add_substitution_point          0x2B37B4 0xB4     level 2
    opt_str_$set_substitution_point          0x2B3754 0x60     level 2

### `lang/lang/source/alias.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    formal_may_alias_actual                  0x0761A8 0x110    level 2
    assert_is_fortran_external_routine_parameter 0x076172 0x36     level 2
    build_alias_desc                         0x075EB0 0xD4     level 2
    check_the_ind                            0x07568E 0x8A     level 2
    alias_ptr_node                           0x075402 0x248    level 2
    is_display_ptr                           0x0753C4 0x3E     level 2
    get_alias_desc                           0x075718 0x758    level 2
    alias_$related_call                      0x076926 0x3C4    level 2
    alias_$descriptors_are_identical         0x07685A 0xCC     level 2
    alias_$classes_may_be_related            0x076730 0xB2     level 2
    alias_$unrelated_or_exact                0x0766FA 0x36     level 2
    alias_$related                           0x0766C6 0x34     level 2
    alias_$relationship                      0x076344 0x322    level 2
    alias_$ref_may_generate_exception        0x076814 0x46     level 2
    alias_$add_disp                          0x0760C2 0x2E     level 2
    alias_$alias_desc_with_size              0x076068 0x2C     level 2
    alias_$basic_alias_desc                  0x076094 0x2E     level 2
    alias_$ind_for_captured_lvalue           0x0760F0 0x82     level 2
    alias_$get_alias_desc                    0x075F84 0xE4     level 2

### `lang2/source/lt_utils/source/arith.pas`

- include `//lang2/source/lt_utils/source/arith.ins.pas`

    arith                                    0x076D30 0x16E    level 2
    add_middle                               0x076CEC 0x44     level 3

### `lang2/source/lt_utils/source/bug_check.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    unimplemented                            0x076F8A 0x6E     level 2
    ok_or_bug_check                          0x076F18 0x72     level 2
    bug_check                                0x076EA0 0x6E     level 2

### `lang/lang/source/commit_top_node.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/commit_top_node.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    implicit_atomicness                      0x0778F8 0x58     level 2
    user_atomicness                          0x07785A 0x5C     level 2
    contains_same_lvalue                     0x07776E 0xD2     level 2
    aop_to_mem                               0x07748C 0x29E    level 2
    aop_pattern_search                       0x07731A 0x158    level 2
    pack_aop_to_mem                          0x076FFC 0x280    level 2
    commit_top_$convert_aops_to__aop_to_mem  0x077998 0x134    level 2

### `lang2/source/ftn/source/const_op.ftn`


    c16_neg                                  0x077FFA 0x3E     level 1
    c16_div                                  0x077FB8 0x42     level 1
    c16_mul                                  0x077F76 0x42     level 1
    c16_sub                                  0x077F34 0x42     level 1
    c16_add                                  0x077EF2 0x42     level 1
    r8i4_expon                               0x077EAE 0x44     level 1
    r8_expon                                 0x077E6C 0x42     level 1
    c8_neg                                   0x077E32 0x3A     level 1
    c8_div                                   0x077DF4 0x3E     level 1
    c8_mul                                   0x077DB6 0x3E     level 1
    c8_sub                                   0x077D78 0x3E     level 1
    c8_add                                   0x077D3A 0x3E     level 1
    r8_math                                  0x077BBA 0x180    level 1
    long_expon                               0x077B84 0x36     level 1

### `lang/lang/source/delay.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/delay.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    delay_$shrink_tree_node                  0x079400 0x102A   level 2
    delay_$propagate_index_long              0x079348 0xB8     level 2
    is_indexer                               0x079326 0x22     level 3
    shrink_divide_operand                    0x07920E 0x118    level 2
    delay_sets                               0x078FCC 0x238    level 2
    resize_set                               0x078F38 0x94     level 3
    paramrlen                                0x078C30 0x308    level 2
    delay_$tailor_operands_to_hardware       0x0788AA 0x258    level 2
    delay_$find_size_and_signed              0x0780B8 0x158    level 2
    delay                                    0x07A444 0x61A    level 2
    delay_$value_guaranteed_between          0x078038 0x66     level 2
    delay_$splice                            0x078B38 0xDE     level 2
    delay_$divide_attributes                 0x07838A 0x4F4    level 2
    delay_$divide_table_dimension            0x07821C 0x13E    level 3
    delay_$shrink_top_level_node             0x07AA5E 0xEE     level 2

### `ivory/volume_4/report/source/do_report.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/pfm.ins.pas`
- include `//ivory/volume_4/report/source/report.ins.pas`

    do_report                                0x07AB4C 0x168    level 2

### `lang/lang/source/gen_debug.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/dst.ins.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`

    emit_line_pc_packet                      0x07B24A 0x102    level 2
    sum_sect_buffers                         0x07B136 0x44     level 2
    gen_debug_$copy_buffer                   0x07AEB8 0x52     level 2
    gen_debug_$emit_bytes                    0x07AE2C 0x8C     level 2
    page_is_full                             0x07ADD6 0x56     level 3
    gen_debug_$flush_buffer                  0x07AD64 0x72     level 2
    gen_debug_$flush_one_block               0x07AD08 0x5C     level 2
    current_sect_offset_of_buf               0x07ACDE 0x2A     level 2
    current_coff_offset_of_buf               0x07ACB4 0x2A     level 2
    gen_debug_$set_active_buffer             0x07B606 0x44     level 2
    gen_debug_$lines_return                  0x07B956 0x38     level 2
    gen_debug_$lines_entry                   0x07B90C 0x4A     level 2
    gen_debug_$lines_stmt_end                0x07B8CA 0x42     level 2
    gen_debug_$lines_def                     0x07B814 0xB6     level 2
    statement_switch                         0x07B7D0 0x44     level 3
    file_switch                              0x07B766 0x6A     level 3
    gen_debug_$exception_site                0x07B6EA 0x7C     level 2
    gen_debug_$exception_table_close         0x07B662 0x88     level 2
    gen_debug_$exception_table_size          0x07B64A 0x18     level 2
    gen_debug_$range_close                   0x07B524 0xE2     level 2
    gen_debug_$range_open                    0x07B34C 0x1D8    level 2
    gen_debug_$end_compilation               0x07B1FC 0x4E     level 2
    gen_debug_$ready_output                  0x07B0F4 0x42     level 2
    gen_debug_$end_pass                      0x07B1BC 0x40     level 2
    even_buffer                              0x07B17A 0x42     level 3
    gen_debug_$begin_pass                    0x07B0A2 0x52     level 2
    gen_debug_$begin_compilation             0x07AFFA 0x74     level 2
    init_buffers                             0x07AF74 0x86     level 3
    buffers_ala_mode                         0x07AF50 0x24     level 3
    gen_debug_$set_file_index                0x07AF30 0x20     level 2
    gen_debug_$read_file_index               0x07AF0A 0x26     level 2

### `lang/lang/source/gen_exception.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/ins/exception_table.ins.pas`
- include `//lang/lang/source/gen_exception.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    do_patches                               0x07BA2E 0x60     level 2
    make_sure_frame_is_written               0x07B9E8 0x46     level 3
    allocate                                 0x07B9A6 0x42     level 2
    gen_exception_$new_exception             0x07B990 0x16     level 2
    gen_exception_$end_table                 0x07C1DE 0x84     level 2
    gen_exception_$write_frame_and_handler_records 0x07BB8E 0x4DC    level 2
    add_to_patch_list                        0x07BB58 0x36     level 3
    gen_exception_$begin_exception_compilation 0x07BA8E 0x5A     level 2

### `lang/lang/source/gen_unwind.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//lang/lang/source/gen_unwind.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//us/us/sys/ins/unwind.ins.pas`
- include `//lang/lang/source/gen_exception.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`

    reg_mask_is_contiguous                   0x07C422 0x9E     level 2
    gen_unwind_$dispose_all_unwind           0x07C2F0 0x10     level 2
    gen_unwind_$new_exception                0x07C2DA 0x16     level 2
    gen_unwind_$new_unwind                   0x07C2C4 0x16     level 2
    gen_unwind_$end_compilation              0x07DD72 0x32     level 2
    gen_unwind_$add_exception_table_entry    0x07DB0E 0xA6     level 2
    gen_unwind_$dump_exception_table         0x07DCB2 0x78     level 2
    sub_one                                  0x07DC2C 0x86     level 3
    gen_unwind_$add_scope                    0x07C300 0x122    level 2
    gen_unwind_$dump_unwind_table            0x07DA8E 0x80     level 2
    psect_rec_dump                           0x07D980 0xD4     level 3
    write_unwind_header_recs                 0x07D824 0x15C    level 4
    scope_rec_dump                           0x07D5AA 0x24E    level 3
    write_padding                            0x07D4E4 0x7C     level 3
    write_range_rec                          0x07D3AA 0x13A    level 3
    write_unwind_info_rec                    0x07C94C 0x960    level 3
    unwind_record_kind_sr10_3                0x07C714 0x1C0    level 3
    unwind_record_kind_sr10_0                0x07C5BE 0x94     level 3
    allocate                                 0x07C568 0x56     level 3
    add_skips                                0x07C4C0 0xA8     level 3
    gen_unwind_$begin_compilation            0x07C264 0x46     level 2

### `lang/lang/source/gen_utils.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/loader.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//us/us/ins/objutil.ins.pas`
- include `//us/us/ins/uid_list.ins.pas`
- include `//us/us/sys/ins/type_uids.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`

    change_name_lower_case                   0x07E346 0x92     level 2
    inlib_error                              0x07DDA4 0x17A    level 2
    gen_utils_$alloc_new_addr_con            0x07EDF4 0xB2     level 2
    add_dsect                                0x07EBB4 0x7A     level 2
    add_psect                                0x07EB3C 0x78     level 2
    check_section_name                       0x07EAA4 0x98     level 2
    name_match                               0x07EA02 0xA2     level 3
    get_external_ref                         0x07ED96 0x5E     level 2
    get_transfer_vector                      0x07ECCE 0xC8     level 2
    get_id_name                              0x07EC2E 0x7E     level 3
    make_xdynm_ptr                           0x07E90E 0xF4     level 2
    get_xdynm_ptr                            0x07E8AE 0x60     level 2
    find_ac_dsect                            0x07E85A 0x54     level 2
    get_proc_addr_con                        0x07E732 0x10E    level 2
    make_abs_addr_con                        0x07DFA6 0x78     level 2
    make_new_addr_con                        0x07E3D8 0x344    level 2
    check_for_addr_con                       0x07E01E 0x2AE    level 2
    get_addr_con                             0x07E2CC 0x7A     level 2
    inlib_add                                0x07DF7C 0x2A     level 2
    inlib_term                               0x07DF62 0x1A     level 2
    inlib_init                               0x07DF32 0x2C     level 2

### `lang/lang/source/gspace.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`

    gspace_$close                            0x07F10C 0x20     level 2
    gspace_$open                             0x07EEA8 0x2A     level 2
    gspace_$release                          0x07F04C 0xC0     level 2
    gspace_$mark                             0x07F02E 0x1E     level 2
    gspace32                                 0x07EEFC 0x132    level 2
    gspace                                   0x07EED2 0x2A     level 2

### `lang/lang/source/il.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/fpp.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`

    initialize_module                        0x07F12C 0x244    level 2

### `lang/lang/source/il_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`

    il_utils_$search_tree_for_node           0x07FDB4 0x2A     level 2
    search_point                             0x07FBE6 0x4C     level 3
    search_walk                              0x07FC32 0x182    level 3
    il_utils_$trees_equivalent               0x07FF58 0x23C    level 2
    il_utils_$src_line                       0x07FEAC 0x70     level 2
    il_utils_$source_generated_top_level_node 0x07FDDE 0x68     level 2
    il_utils_$is_strength_reduction_temp     0x07FBAA 0x3C     level 2
    il_utils_$tree_node_operand_is_spine     0x07FB64 0x46     level 2
    il_utils_$do_substitution                0x07FA72 0xD8     level 2
    il_utl_$count_vars                       0x07F582 0x156    level 2
    il_utl_$classify_variable                0x07F384 0x1FE    level 2
    il_utils_$set_uc_walk_spine              0x07FA1A 0x58     level 2
    il_utils_$adjust_uc                      0x07F6D8 0x320    level 2
    adjust_uc                                0x07F9F8 0x22     level 2

### `lang/lang/source/list_tree.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    print_basic_block                        0x087074 0x384    level 2
    advance_and_print                        0x086FF6 0x7E     level 2
    begins_inline_block                      0x086F90 0x66     level 2
    print_data_node                          0x086BDA 0x310    level 2
    print_top_node                           0x084E42 0x167E   level 2
    write_68k_register_name                  0x084DCA 0x72     level 2
    print_routine_block                      0x083F40 0xA30    level 2
    print_exception_frame                    0x083C5E 0x218    level 2
    print_variable                           0x082960 0xB46    level 2
    print_tree_exp                           0x081774 0xDAC    level 2
    print_spine                              0x086BA4 0x36     level 2
    print_tree_ref                           0x0812CE 0x434    level 2
    print_known_aux                          0x08114E 0x128    level 2
    print_opmod_use                          0x080E1A 0x29E    level 2
    print_math                               0x080BAE 0x1F0    level 2
    print_relational                         0x080A2E 0x160    level 2
    print_rlen                               0x0808AC 0x122    level 2
    print_uc_and_phase                       0x080824 0x80     level 2
    prtphasebits                             0x080500 0x292    level 2
    print_object_ptr                         0x0804D0 0x30     level 2
    print_comma                              0x08049A 0x36     level 2
    print_bool                               0x08047A 0x20     level 2
    print_hex                                0x08044A 0x30     level 2
    print_integer                            0x080418 0x32     level 2
    print_string                             0x0803BC 0x5C     level 2
    print_3_chars                            0x08035E 0x5E     level 2
    print_2_chars                            0x080316 0x48     level 2
    print_char                               0x0802E6 0x30     level 2
    break_line                               0x0802AA 0x3C     level 2
    print_ln                                 0x080270 0x3A     level 2
    finialise_list_tree                      0x080258 0x18     level 2
    fresh_ln                                 0x0801C8 0x8C     level 2
    initialise_list_tree                     0x0801A0 0x28     level 2
    list_tree_$sanity_check                  0x087FC8 0x68     level 2
    sanity_check_walk                        0x087A52 0x27A    level 3
    sanity_check_walk_spine                  0x087D20 0x250    level 3
    sanity_check_bad_uc                      0x087922 0xBC     level 3
    sanity_check_countdown                   0x08778C 0xFA     level 3
    list_tree_$print_tree                    0x0876BA 0xB4     level 2
    list_tree_$print_whole_il                0x08749A 0x220    level 2
    list_tree_$print_aux                     0x081294 0x3A     level 2
    list_tree_$print_rlen                    0x080A04 0x2A     level 2

### `us1/us1/lib/dblib/loc/src/loc_build.c`

- include `//us/us/unix/include/sys5.3/stdarg.h`
- include `//us/us/unix/include/apollo/base.h`
- include `//us/us/unix/include/apollo/isp.h`
- include `//us1/us1/lib/dblib/loc/src/loc.h`
- include `//us1/us1/lib/dblib/loc/src/loc_private.h`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/dblib_locs/loc.ops/h3df592bb.000/loc/loc_codes.h`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/dblib_locs/loc.ops/h3df592bb.000/loc/loc_sets.h`
- include `//us1/us1/lib/dblib/loc/src/loc_build.h`
- include `//us1/us1/lib/dblib/loc/src/loc_pack.h`

    loc_build__unknown_loc                   0x089092 0x1A     level 2
    loc_build__prism_mode_loc                0x088FB6 0xDC     level 2
    loc_build__m68k_indirect_loc             0x088E7C 0x13A    level 2
    loc_build__relative_loc                  0x088D5C 0x120    level 2
    loc_build__register_loc                  0x088C64 0xF8     level 2
    loc_build__close_list                    0x088BD6 0x8E     level 2
    terminate_list                           0x088B9C 0x3A     level 2
    close_all_locs                           0x088B2A 0x72     level 2
    close_all_ranges                         0x088AE0 0x4A     level 2
    close_range                              0x0889DA 0x106    level 2
    fix_stmt_based_list                      0x088938 0xA2     level 2
    loc_put_clan_op                          0x088908 0x30     level 2
    loc_put_family_op                        0x08878A 0x17E    level 2
    nybble_pack                              0x08871A 0x70     level 2
    loc_build__stmt_range                    0x088664 0xB6     level 2
    loc_build__pc_range                      0x0885D6 0x8E     level 2
    loc_build__default                       0x088572 0x64     level 2
    range_insert                             0x08853E 0x34     level 2
    loc_build__close_pool                    0x0884B6 0x88     level 2
    loc_build__dump_pool                     0x08841E 0x98     level 2
    fill_buffer                              0x08838E 0x90     level 2
    next_dump_position                       0x088320 0x6E     level 2
    next_dump_string                         0x0882E2 0x3E     level 2
    loc_build__open_list                     0x088288 0x5A     level 2
    loc_build__pool_size                     0x088262 0x26     level 2
    loc_build__open_pool                     0x088248 0x1A     level 2
    loc_holder_dispose                       0x0881E0 0x68     level 2
    scrap                                    0x0881B4 0x2C     level 2
    loc_node_alloc                           0x088162 0x52     level 2
    loc_holder_alloc                         0x0880B4 0xAE     level 2
    pop_scrap                                0x08809C 0x18     level 2
    push_scrap                               0x088088 0x14     level 2
    loc_build__init                          0x088030 0x58     level 2

### `lang2/source/lt_utils/source/mrh.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/ms.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`

    release_chunk_list                       0x08945C 0x90     level 2
    allocate_new_chunk                       0x089188 0x252    level 2
    mrh_$release_all                         0x0898D0 0x3A     level 2
    mrh_$release_to_mark                     0x08990A 0xCC     level 2
    mrh_$get_map                             0x08981C 0x20     level 2
    mrh_$reset_chunks_in_use_max             0x089886 0x1C     level 2
    mrh_$chunks_in_use_max                   0x08986E 0x18     level 2
    mrh_$chunks_in_use                       0x089856 0x18     level 2
    mrh_$chunks_total                        0x08983C 0x1A     level 2
    mrh_$bytes_used                          0x0897D2 0x4A     level 2
    mrh_$mark                                0x0898A2 0x2E     level 2
    mrh_$alloc_fixed                         0x089774 0x5E     level 2
    mrh_$alloc                               0x0896B8 0x82     level 2
    mrh_$initialize                          0x08955C 0xE8     level 2
    mrh_$initialize_module                   0x0890AC 0xCA     level 2

### `lang/bind/source/objio.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/pfm.ins.pas`
- include `//us/us/ins/time.ins.pas`
- include `//us/us/ins/file.ins.pas`
- include `//us/us/ins/vol.ins.pas`
- include `//us/us/ins/term.ins.pas`
- include `//us/us/ins/streams.ins.pas`
- include `//us/us/ins/ios.ins.pas`
- include `//us/us/sys/ins/ios.ins.pas`
- include `//us/us/ins/ios_nr.ins.pas`
- include `//us/us/ins/prot.ins.pas`
- include `//us/us/sys/ins/mutex.ins.pas`
- include `//us/us/ins/rws.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/ins/ms.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/mst.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//us/us/ins/name.pvt.pas`
- include `//misc_server/misc1/ios/mgrs/dfile/stream_bypass.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//misc_server/clib/ins/unix_time.ins.pas`
- include `//us/us/ins/strl.ins.pas`
- include `//us/us/ins/coff.ins.pas`
- include `//us/us/ins/cmpexe.ins.pas`
- include `//us/us/ins/uid_list.ins.pas`
- include `//us/us/sys/ins/type_uids.ins.pas`
- include `//us/us/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`

    copy_back                                0x08AD12 0x9E     level 2
    copy_the_sucker                          0x08AC50 0xC2     level 2
    create_temp_file                         0x08AB78 0xC2     level 2
    num_to_hex                               0x08AB58 0x20     level 3
    obj_$open                                0x08A9F0 0x162    level 2
    make_bak_name                            0x08A530 0x84     level 2
    map_portion                              0x08A3BE 0x172    level 2
    find_chan                                0x08A346 0x78     level 2
    make_chan                                0x08A26C 0xD6     level 2
    obj_$add_free                            0x089B4C 0x58     level 2
    delete_free_list_entry                   0x089B02 0x4A     level 2
    obj_$remove_free                         0x089A88 0x7A     level 2
    check_init                               0x089A08 0x52     level 2
    objio_cleanup_handler                    0x08C2D0 0xF6     level 2
    search_apollo_section_tables             0x08BF7A 0x1A0    level 2
    search_apollo_global_tables              0x08C126 0x1A6    level 2
    obj_$inq_unix_ts                         0x08A90A 0xE6     level 2
    obj_$inq_ts                              0x08A81E 0xE4     level 2
    obj_$inq_type_uid                        0x08A7DC 0x42     level 2
    obj_$set_length                          0x08BF30 0x4A     level 2
    obj_$get_name                            0x08BD9C 0xB0     level 2
    obj_$map                                 0x08BE4E 0xE2     level 2
    obj_$free                                0x08BAFE 0xAC     level 2
    obj_$get                                 0x08BBAA 0x1F2    level 2
    obj_$put                                 0x08A5B4 0x228    level 2
    obj_$close                               0x08B876 0x288    level 2
    obj_$open_r_tag                          0x08B494 0x1C8    level 2
    obj_$open_r                              0x08B65E 0x218    level 2
    obj_$open_t                              0x08B04E 0x444    level 2
    obj_$open_wl                             0x08AEA8 0x1A6    level 2
    obj_$open_w                              0x08ADB2 0xF4     level 2
    obj_$get_my_obj_info                     0x089DCA 0x474    level 2
    obj_$validate_object_module              0x089C84 0x13E    level 2
    obj_$init_io                             0x089BA4 0xD8     level 2

### `lang/bind/source/objutil.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//us/us/ins/strl.ins.pas`
- include `//us/us/ins/rws.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/ins/objutil.ins.pas`
- include `//us/us/ins/coff.ins.pas`
- include `//us/us/ins/uid_list.ins.pas`
- include `//us/us/sys/ins/type_uids.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`

    inlib_read_inlib                         0x08FCF0 0x11E    level 2
    inlib_read_obj_inlib                     0x08E0A6 0x41A    level 2
    inlib_read_coff_inlib                    0x08C70A 0x57E    level 2
    extended_name_to_string                  0x08C642 0xC4     level 2
    free_string                              0x08C620 0x22     level 2
    get_string                               0x08C558 0xC8     level 2
    get_coff_stringtab_info                  0x08C4E8 0x6C     level 2
    object_target                            0x08C4A0 0x48     level 2
    inlib_list_add                           0x08C3C8 0xD0     level 2
    objutil_$inlib_find_symbol               0x0902C0 0x36     level 2
    objutil_$inlib_find_section              0x09042A 0x30     level 2
    objutil_$inlib_terminate                 0x090554 0xC2     level 2
    objutil_$inlib_lookup_section            0x0904BC 0x98     level 2
    inlib_checklist                          0x09045A 0x62     level 3
    objutil_$inlib_lookup_symbol             0x090356 0xD0     level 2
    inlib_checklist                          0x0902F6 0x60     level 3
    objutil_$inlib_libname                   0x090296 0x2A     level 2
    objutil_$inlib_init                      0x09021A 0x7C     level 2

### `lang/lang/source/opt_inline.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    anything_to_expand                       0x095956 0xF0     level 2
    callee_status                            0x09563E 0x318    level 2
    assert_routine_contains_symbolically_opaque_addressing 0x09558E 0x54     level 2
    assert_statement_contains_symbolically_opaque_addressing 0x0954A4 0xEA     level 2
    assert_contains_symbolically_opaque_addressing 0x095348 0x15C    level 2
    assert_is_symbolically_opaque_address    0x0952D0 0x78     level 2
    check_call_sites_and_expand              0x095216 0xAE     level 2
    dfs_walk                                 0x09503C 0x1BE    level 2
    remove_call_graph_edge                   0x094FD8 0x64     level 2
    call_status                              0x094C46 0x392    level 2
    cleanup_expansion                        0x094BDA 0x6C     level 2
    process_blocks                           0x0948CC 0x30E    level 2
    process_statements                       0x094800 0xB0     level 2
    process_operand                          0x093C08 0xBD8    level 2
    process_opr_ind                          0x09368E 0x576    level 3
    process_index_opr                        0x0933FE 0x290    level 3
    apply_disp                               0x09334A 0xB4     level 3
    disp_offset                              0x093336 0x14     level 3
    adjust_disp                              0x09330E 0x28     level 3
    get_sym_ind_info                         0x09329A 0x74     level 3
    substitutee_sym_ind                      0x093202 0x98     level 4
    process_labels                           0x09317A 0x84     level 2
    process_variables                        0x092E1E 0x35C    level 2
    process_display_ptrs                     0x092C8A 0x194    level 2
    process_parameters                       0x09259A 0x6F0    level 2
    ptr_variable                             0x0923F0 0x1AA    level 3
    assign_name                              0x092348 0x98     level 4
    assign                                   0x092242 0x106    level 3
    inliner_actual                           0x092228 0x1A     level 2
    set_address_exposed                      0x09215A 0x9E     level 2
    allocate_local_var                       0x091F3C 0x1E6    level 2
    allocate_space                           0x091DD2 0x16A    level 2
    align                                    0x091D98 0x3A     level 2
    copy_var                                 0x091C58 0x140    level 2
    copy_const                               0x091C1E 0x36     level 2
    put_on_bct                               0x091B9C 0x82     level 2
    pass_method                              0x0919F2 0x15E    level 2
    actual_actual                            0x091970 0x82     level 2
    put_on_il_stream                         0x09194E 0x22     level 2
    patch_il                                 0x0916F0 0x25E    level 2
    inline_$compatible_types                 0x0916BA 0x36     level 2
    start_il_stream                          0x09163C 0x7E     level 2
    coerce                                   0x09144C 0x1F0    level 2
    extend                                   0x09133A 0x112    level 3
    put_hash_info                            0x09124A 0xF0     level 2
    get_hash_info                            0x09117C 0xCE     level 2
    cleanup_hash                             0x091136 0x46     level 2
    current_ln                               0x09111C 0x1A     level 2
    function_return                          0x091054 0xC8     level 2
    get_size_rlen                            0x090934 0x486    level 2
    find_varn                                0x090808 0x12C    level 2
    find_block                               0x0907AE 0x40     level 2
    next_contained_block                     0x090716 0x98     level 2
    nil_out_dispinfo                         0x090702 0x14     level 2
    assert_routine_returns_void              0x0906B4 0x4E     level 2
    assert_is_void_type                      0x09069C 0x18     level 2
    assert_is_a_routine_block                0x090670 0x2C     level 2
    assert_is_nonleaf_lvalue                 0x09063A 0x36     level 2
    inline_$is_fortran_asf                   0x090618 0x22     level 2
    inline_$inline_expand                    0x095A46 0x1A0    level 2
    inline_$mark_reference_params            0x090E7A 0x1C4    level 2
    get_referenced_symbol                    0x090DBA 0xC0     level 3

### `lang/lang/source/opt_vector.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/delay.ins.pas`

    process_candidate                        0x097098 0x1108   level 2
    compare_dindex                           0x096FF2 0xA6     level 2
    compare_disp                             0x096F4C 0xA6     level 2
    bad_dindex                               0x096D70 0x1C2    level 2
    subvector                                0x096C48 0x128    level 2
    addvector                                0x096B20 0x128    level 2
    mult_constant                            0x0969BE 0x162    level 2
    addconst                                 0x09685C 0x162    level 2
    mult_add                                 0x096650 0x20C    level 2
    dot                                      0x0964A4 0x1AC    level 2
    sum                                      0x096278 0x22C    level 2
    opt_vec_$zero_vector                     0x096160 0x118    level 2
    opt_vec_$init_vector                     0x096042 0x11E    level 2
    opt_vec_$copy_vector                     0x095F24 0x11E    level 2
    epilog                                   0x095D02 0x1BC    level 2
    prolog                                   0x095C90 0x72     level 2
    get_increment                            0x095C1E 0x72     level 2
    opt_vec_$obj_is_float_const              0x095BE8 0x36     level 2
    opt_vec_$process_routine                 0x098234 0x7E     level 2
    opt_vec_$process_loop                    0x0981A0 0x94     level 2

### `lang/lang/source/prfpkg.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/fpp.ins.pas`
- include `//us/us/sys/ins/cal.ins.pas`
- include `//us/us/sys/ins/time.ins.pas`
- include `//us/us/sys/ins/proc1.ins.pas`
- include `//us/us/ins/proc2.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`
- include `//us/us/ins/unix_resource.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`

    prt_section_stats                        0x098688 0x11C    level 2
    prtsection                               0x098638 0x50     level 3
    hhmmss                                   0x098538 0x100    level 2
    perfsummary                              0x099028 0x982    level 2
    print_meter_results                      0x098844 0x744    level 3
    convert_time_$clock_t_to_hh_mm_ss        0x098808 0x3C     level 3
    prfpkg_$stop_active_phase                0x098512 0x26     level 2
    prfpkg_$activate_phase                   0x0984E0 0x32     level 2
    perfstop                                 0x0983DA 0x106    level 2
    perfstart                                0x098340 0x98     level 2
    perfinit                                 0x0982B4 0x8C     level 2

### `lang/lang/source/prtsub.pas`

- include `//lang/lang/source/prtsub.ins.pas`

    prtsub_$equal                            0x099EC2 0x48     level 2
    prttab                                   0x099E88 0x3A     level 2
    prthex                                   0x099E36 0x52     level 2
    prtint                                   0x099D58 0xD4     level 2
    prtcatb                                  0x099D0C 0x40     level 2
    prtcats                                  0x099CA6 0x66     level 2
    prtcatc                                  0x099C7C 0x2A     level 2

### `lang2/source/lt_utils/source/seg_size.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/loader.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`

    seg_size                                 0x099F0C 0x5A     level 2

### `lang/lang/source/sortidntk.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`

    sort                                     0x09A0B8 0x26     level 2
    qsort                                    0x099F78 0x140    level 3
    sortidentifiers                          0x09A0DE 0xBE     level 2

### `ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/std_lib.mac/hf398b043.001/std_lib.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`


### `lang/lang/source/strings.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`

    compare_bytes_case                       0x09A19C 0xD2     level 2
    strings_$compare_bytes_nocase            0x09A2BC 0x3C     level 2
    strings_$memmove                         0x09A350 0x34     level 2
    strings_$memcpy                          0x09A384 0x32     level 2
    strings_$memcmp                          0x09A2F8 0x58     level 2
    compare_bytes                            0x09A280 0x3C     level 2
    idntk                                    0x09A3B6 0xB6     level 2

### `lang/lang/source/time.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/time.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/time.ins.pas`
- include `//us/us/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/cal.ins.pas`
- include `//us/us/sys/ins/cal.ins.pas`

    cat_time_info                            0x09A48E 0xD2     level 2
    get_time_stamp                           0x09A46C 0x22     level 2

### `lang/lang/source/token.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`

    floating_token                           0x09A662 0x100    level 2
    setcontk                                 0x09ABB0 0x13E    level 2
    strtk                                    0x09AAD0 0xB6     level 2
    token_$make_string_token                 0x09AB86 0x2A     level 2
    dpcmplxtk                                0x09AA00 0xD0     level 2
    token_$make_real_lit_pair                0x09A90E 0xF2     level 2
    cmplxtk                                  0x09A86E 0xA0     level 2
    get_reciprocal                           0x09A828 0x46     level 2
    dpcontk                                  0x09A7FE 0x2A     level 2
    rlcontk                                  0x09A762 0x9C     level 2
    smcontk                                  0x09A5B4 0xAE     level 2
    set_is_nil                               0x09ACEE 0x60     level 2

### `lang/lang/source/unix_objmod.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/time.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/final.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//us/us/ins/streams.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/loader.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`
- include `//us/us/ins/ev.ins.pas`
- include `//us/us/ins/c.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/proc2.ins.pas`
- include `//us/us/ins/unix_resource.ins.pas`
- include `//us/us/ins/pm.ins.pas`
- include `//us/us/sys/ins/pm.ins.pas`
- include `//us/us/ins/acl.ins.pas`
- include `//us/us/ins/strl.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//us/us/ins/time.ins.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang/lang/source/gen_unwind.ins.pas`
- include `//us/us/sys/ins/unwind.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/spos.pvt.pas`

    emit_32                                  0x09B626 0x58     level 2
    emit_8                                   0x09B542 0xA2     level 2
    store_rel_info                           0x09B26A 0x92     level 2
    store_fixup_info                         0x09B13A 0x84     level 2
    get_reloc_symndx                         0x09AECC 0x252    level 2
    write_byte_to_temp_string_table          0x09AD68 0x50     level 2
    has_ecb                                  0x09AE36 0x44     level 2
    unix_obj_init                            0x0A1332 0x50     level 2
    dump_data                                0x09B36A 0x1D8    level 2
    unix_obj_gen                             0x0A0B08 0x76E    level 2
    add_exception_addr_con_tuple             0x0A0ABA 0x4E     level 3
    output_data_info                         0x09F7DE 0x1224   level 3
    create_tv_reloc_recs                     0x09F722 0xBC     level 3
    output_misc_sections                     0x09EF78 0x722    level 3
    change_name_lower_case                   0x09EF00 0x78     level 3
    line_numbers                             0x09EE88 0x78     level 3
    emit_rel                                 0x09EE06 0x82     level 3
    data_sections                            0x09E8B8 0x548    level 3
    align_data_position                      0x09E87E 0x3A     level 4
    dump_data_init_thread                    0x09E5E2 0x260    level 4
    sort_data_init_thread                    0x09E33A 0x2A8    level 5
    link_and_update_offset                   0x09E2B6 0x84     level 6
    adjust_head_and_tail                     0x09E28C 0x2A     level 6
    ddisp                                    0x09E1AE 0xDE     level 6
    qsort                                    0x09DFF4 0x1BA    level 6
    determine_section_headers_size           0x09DEFE 0xF6     level 3
    gen_proc_relocs                          0x09D8B0 0x640    level 3
    gen_data_relocs                          0x09D7FE 0xB2     level 3
    get_section_id                           0x09D74C 0xB2     level 3
    get_load_addr                            0x09D706 0x46     level 3
    write_transfer_vectors                   0x09D520 0x1D0    level 3
    create_global_reference                  0x09D352 0x1BA    level 3
    emit_ecb                                 0x09CCE6 0x620    level 3
    find_global_id                           0x09BFEC 0x5C     level 3
    emit_constant                            0x09BD28 0x2AC    level 3
    emit_data                                0x09BC5C 0xCC     level 3
    emit_tree_node_const                     0x09B896 0x3AC    level 3
    init_data                                0x09B830 0x66     level 3
    emit_abs_addr_con                        0x09C048 0x416    level 3
    emit_addr_con                            0x09C462 0x840    level 3
    add_to_section_header                    0x09B2FC 0x6E     level 2
    add_reloc                                0x09B1BE 0xAC     level 2
    emit_16                                  0x09B5E4 0x42     level 2
    unix_put_obj_name                        0x09B6E6 0x14A    level 2
    string_table                             0x09B67E 0x68     level 2
    target_magic                             0x09AE7A 0x52     level 2

### `lang/lang/source/add_node.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/peb.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    invariant_sizeof_top_level               0x0A1EC4 0xEC     level 2
    phasefromvatt                            0x0A144E 0x66     level 2
    push                                     0x0A141E 0x30     level 2
    add_top_node                             0x0A13D2 0x4C     level 2
    get_next_symbol                          0x0A1384 0x2      level 2
    init_aux_ftn                             0x0A13D0 0x2      level 2
    make_char_temp                           0x0A13B6 0x1A     level 2
    make_temp                                0x0A139C 0x1A     level 2
    char_maxlen                              0x0A1386 0x16     level 2
    buildtreenode                            0x0A6634 0xF4     level 2
    add_tn                                   0x0A349C 0x30AE   level 2
    distribute                               0x0A32A2 0x1FA    level 3
    add_routine_reference                    0x0A2C42 0x9E     level 2
    getphase                                 0x0A14B4 0xC0     level 2
    add_pn                                   0x0A3032 0x228    level 2
    add_sdn                                  0x0A2DDE 0xFA     level 2
    add_disp_node                            0x0A2CE0 0xD6     level 2
    add_dn                                   0x0A2DB6 0x28     level 2
    add_dindexn                              0x0A2ED8 0x15A    level 2
    add_node_$new_top_level                  0x0A2B70 0xD2     level 2
    add_node_$dispose_top_level              0x0A1FCE 0xB8     level 2
    copy_tree                                0x0A18E8 0x5A8    level 2
    walk_it                                  0x0A158E 0x35A    level 2

### `lang/lang/source/attributes.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`

    attr_calc_align                          0x0A6942 0xBE     level 2
    find_conflict                            0x0A6728 0x120    level 2
    attr_compute_routine_options             0x0A7DF2 0x1DE    level 2
    attr_natural_align_from_bytes            0x0A6918 0x2A     level 2
    attr_tattr_to_vattr                      0x0A73D0 0x36     level 2
    attr_validate                            0x0A702E 0x394    level 2
    attr_align_messages                      0x0A6864 0x1A     level 2
    attr_check_align                         0x0A687E 0x9A     level 2
    attr_set_align_dsc                       0x0A6A1C 0x2AA    level 2
    attr_packed_size                         0x0A6CE0 0x124    level 2
    merge_attribs_natural                    0x0A7406 0x866    level 2
    merge_attribs                            0x0A7C6C 0x6E     level 2
    add_attribute                            0x0A6E46 0x1DE    level 2
    volatile_check                           0x0A6E04 0x42     level 3
    attr_curr_align_env                      0x0A7DD6 0x1C     level 2
    attr_set_align_env                       0x0A7DA4 0x32     level 2
    attr_al_stk_empty                        0x0A7D88 0x1C     level 2
    attr_pop_align                           0x0A7D2C 0x5C     level 2
    attr_push_align                          0x0A7CDA 0x52     level 2

### `lang/lang/source/coff_syms.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`
- include `//us/us/ins/strl.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`

    flush_externs                            0x0A814E 0x46     level 2
    find_extern                              0x0A7FD0 0x17E    level 2
    coff_sym_dmp                             0x0A9684 0x66C    level 2
    put_func_def                             0x0A943A 0x24A    level 3
    put_tvs                                  0x0A93B2 0x88     level 3
    put_global_sym                           0x0A8BFC 0x79A    level 3
    put_sect_sym                             0x0A8B34 0xC8     level 3
    put_name                                 0x0A8AD8 0x5C     level 3
    map_name                                 0x0A8A9A 0x3E     level 3
    get_section_hdr                          0x0A8A6E 0x2C     level 3
    get_section_no                           0x0A8A16 0x58     level 3
    get_lnno_ptr                             0x0A8996 0x80     level 3
    get_coff_type                            0x0A8932 0x46     level 3
    number_coff_syms                         0x0A84A2 0x48C    level 2
    count_tvs                                0x0A8428 0x7A     level 3
    count_global_sym                         0x0A8194 0x244    level 3

### `lang/lang/source/debug_sym_dmp.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`
- include `//us/us/sys/ins/name.ins.pas`
- include `//us/us/sys/ins/ios.ins.pas`
- include `//lang/lang/source/attributes.ins.pas`
- include `//us/us/ins/isp.ins.pas`
- include `//us/us/sys/ins/isp.ins.pas`
- include `//us/us/sys/ins/dst.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//us1/us1/lib/dblib/loc/src/loc_build.ins.pas`
- include `//us/us/ins/uid_list.ins.pas`
- include `//us/us/sys/ins/type_uids.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/spos.pvt.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/pds.ins.pas`

    build_block_list                         0x0ADB36 0xB4     level 2
    gen_section_table                        0x0AD946 0x1F0    level 2
    write_files                              0x0AD68A 0x2BA    level 2
    add_unit_table_entry                     0x0AD632 0x58     level 3
    write_string_for_file_table_entry        0x0AD5E0 0x52     level 3
    add_file_table_entry                     0x0AD542 0x9E     level 3
    write_blocks                             0x0AD16A 0x36C    level 2
    make_relative_ref                        0x0AD122 0x48     level 2
    get_src_loc                              0x0AD0C2 0x60     level 2
    get_debug_offset                         0x0AD08A 0x38     level 2
    add_string                               0x0AD036 0x54     level 2
    clear_emitted_marker                     0x0ACF3E 0x64     level 2
    dump_string_table                        0x0ACE3C 0x102    level 2
    create_string_table                      0x0ACE20 0x1C     level 2
    process_debug_symbols                    0x0ACD24 0x74     level 2
    process_named_objects                    0x0AC996 0x30A    level 2
    skip_unreferenced_include_object         0x0AC910 0x86     level 2
    get_entry_rep                            0x0AC83E 0x9A     level 2
    get_const_rep                            0x0AC510 0x2DE    level 2
    get_label_rep                            0x0AC468 0x6C     level 2
    get_enum_rep                             0x0ABC96 0x132    level 2
    get_record_rep                           0x0AB99C 0x2BE    level 2
    get_tag                                  0x0AB932 0x6A     level 2
    get_signature_rep                        0x0AB782 0x15E    level 2
    get_variable_rep                         0x0AB5D8 0x16E    level 2
    get_alias_rep                            0x0AB560 0x78     level 2
    get_src_loc_rep                          0x0AB524 0x3C     level 2
    get_name_rep                             0x0AB44E 0x8A     level 2
    is_simple_type                           0x0AB396 0x9A     level 2
    may_need_common_aux                      0x0AB0E0 0x1B4    level 2
    get_sect_rel_location_rep                0x0AAD5C 0x7A     level 2
    get_var_location_rep                     0x0AA9B8 0x306    level 2
    get_memory_loc                           0x0AA4EC 0x44E    level 2
    reg_translate_68k                        0x0AA4B4 0x38     level 2
    reg_translate_at                         0x0AA430 0x4A     level 2
    add_obj_to_loc_fixup_list                0x0AA3F4 0x3C     level 2
    prep_sections                            0x0AA364 0x90     level 2
    add_to_reloc_obj_list                    0x0AA244 0xCA     level 2
    label_from_fortran_symbol                0x0AA144 0x90     level 2
    add_name_to_symbols_section              0x0A9F34 0x7C     level 2
    add_symbols_section                      0x0A9EA0 0x7E     level 2
    obj_alloc                                0x0A9E5A 0x46     level 2
    dumpfunc                                 0x0A9E08 0x52     level 2
    allocfunc                                0x0A9D90 0x4A     level 2
    get_type_rep                             0x0ABE02 0x636    level 2
    force_add_string                         0x0ACFA2 0x94     level 2
    sz_fsym                                  0x0A9D30 0x20     level 2
    varn_from_fortran_symbol                 0x0AA044 0x100    level 2
    debug_sym_dmp_$block_dmp                 0x0ADBEA 0x1B2    level 2
    debug_sym_dmp_$dump_symbols_section      0x0ACDE0 0x40     level 2
    debug_sym_dmp_$add_loc_info              0x0AAE38 0x266    level 2
    debug_sym_dmp_$create_symbols_sections   0x0ACD98 0x48     level 2
    debug_sym_dmp_$finalize                  0x0ADFC4 0x50     level 2
    debug_sym_dmp_$init                      0x0ADE2A 0x13E    level 2
    add_file_entry                           0x0ADD9C 0x8E     level 3
    get_include_file_index                   0x0AA1D4 0x70     level 2

### `lang/lang/source/error_listing.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`

    error3                                   0x0AE242 0x7C     level 2
    error2                                   0x0AE1D2 0x6E     level 2
    error1                                   0x0AE16A 0x66     level 2
    error0                                   0x0AE108 0x5E     level 2
    save_errors                              0x0AE014 0xF4     level 2
    print_error                              0x0AE2C0 0xDC     level 2

### `lang/lang/source/inc_list.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/c.ins.pas`
- include `//us/us/ins/pgm.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`

    open_inlib_list_sub                      0x0AE614 0x11E    level 2
    open_inlib_list                          0x0AE732 0x40     level 2
    open_include_list_sub                    0x0AE42A 0x1A8    level 2
    open_include_list                        0x0AE3EC 0x3E     level 2
    find_file_name                           0x0AE39C 0x50     level 2

### `lang/lang/source/kfold.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/peb.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang2/source/ftn/source/const_op.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    assert_is_shift_with_negative_count      0x0AEA80 0x3A     level 2
    assert_and_over_left_shift_produces_zero 0x0AE9CC 0xB4     level 2
    assert_is_shift                          0x0AE984 0x48     level 2
    assert_is_left_shift                     0x0AE950 0x34     level 2
    assert_is_integer_and                    0x0AE928 0x28     level 2
    assert_is_integer_constant               0x0AE8E6 0x28     level 2
    assert_is_shared_tree                    0x0AE8D8 0xE      level 2
    assert_is_tree                           0x0AE8C0 0x18     level 2
    report_failure_once                      0x0AE774 0x2E     level 2
    kfold                                    0x0B0E24 0x34     level 2
    kfold_$general                           0x0AEB80 0x223C   level 2
    node_number                              0x0AEABA 0xAC     level 3
    dfetch                                   0x0AE86C 0x54     level 2
    dbl_to_real                              0x0AE7A2 0xBA     level 2

### `lang/lang/source/prtobj.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//us/us/ins/cvfp.ins.pas`

    prtobj_$prtobj_full                      0x0B0F3A 0xFA4    level 2
    add_kind_if_full                         0x0B0EF4 0x46     level 3
    prt_logical                              0x0B0E58 0x8C     level 3
    prtobj                                   0x0B2290 0x2C     level 2

### `lang/lang/source/runbackend.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/condcomp.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/commit_top_node.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/sys/ins/errlog.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`

    adjust_disps_of_formals_for_fcw          0x0B3BDE 0xCE     level 2
    set_local_call_bits                      0x0B3B1E 0xC0     level 2
    optimize_and_code_depth_first            0x0B3A9E 0x80     level 2
    optimize_and_code                        0x0B3850 0x20C    level 2
    normalize_il                             0x0B319A 0x55E    level 2
    assert_is_useless_disp                   0x0B312A 0x56     level 2
    delete_unreferenced_blocks               0x0B3024 0x106    level 2
    assert_is_inlineable_utility_routine_in_include_file 0x0B2FDC 0x48     level 2
    build_call_graph                         0x0B2F62 0x7A     level 2
    build_call_graph_walk_il                 0x0B2928 0x3F0    level 2
    analyze_call_site_for_call_graph         0x0B2830 0xF8     level 2
    detect_fortran_param_scalarity_mismatches 0x0B2696 0xEA     level 2
    add_call_graph_edge                      0x0B25B8 0xDE     level 2
    build_call_graph_walk_block              0x0B2EC8 0x9A     level 2
    unconditionally_add_call_graph_edge      0x0B2522 0x78     level 2
    check_static_initializations             0x0B24DC 0x46     level 2
    check_fdata                              0x0B24B4 0x28     level 2
    is_routine_reference_addr_con            0x0B243A 0x7A     level 2
    routine_reference_class                  0x0B2364 0xD6     level 2
    assert_is_fortran_array                  0x0B2346 0x1E     level 2
    assert_is_a_callable_block               0x0B2310 0x36     level 2
    assert_is_a_call_node                    0x0B22DE 0x32     level 2
    assert_is_a_tree_node                    0x0B22BC 0x22     level 2
    run_backend                              0x0B3CAC 0x254    level 2

### `lang2/source/be_com/call_conv.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang/c_compiler/source/c_objtype.ins.pas`
- include `//lang/c_compiler/source/c_globals.ins.pas`
- include `//lang/c_compiler/source/c_externs.ins.pas`

    fill_arg_desc_using_ptt                  0x0B449C 0x168    level 2
    get_proto                                0x0B43DE 0xBE     level 2
    entry_blk_check                          0x0B43B0 0x2E     level 2
    ftn_param_vat_check                      0x0B4362 0x4E     level 2
    ftn_alt_rtn                              0x0B4326 0x3C     level 2
    pfm_cleanup_check                        0x0B42B2 0x74     level 2
    lib_dsc_name_cmp                         0x0B4252 0x60     level 2
    get_rlen_and_size                        0x0B3F48 0x30A    level 2
    at_call_conv                             0x0B4604 0x1B3C   level 2

### `lang/lang/source/cargs.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//us/us/ins/helplib.ins.pas`
- include `//lang/lang/source/versions.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//lang2/source/ftn/source/kap.ins.pas`

    parse_options                            0x0B6710 0x153E   level 2
    parse_opt_on_or_off                      0x0B6676 0x9A     level 3
    fill_array_with_args                     0x0B662C 0x4A     level 3
    arg_option_parameter_numeric             0x0B6514 0xB2     level 3
    arg_option_parameter                     0x0B646C 0x78     level 3
    match                                    0x0B6448 0x24     level 3
    option_error                             0x0B643C 0xC      level 3
    match_arg                                0x0B63A0 0x9C     level 2
    push_kap                                 0x0B6312 0x8E     level 2
    set_name                                 0x0B62A8 0x6A     level 2
    print_version                            0x0B6244 0x42     level 2
    argument_error                           0x0B6228 0x1A     level 2
    cargs_$parse_line_options                0x0B89D6 0x114    level 2
    cargs_$parse_command_line_options        0x0B8962 0x74     level 2
    cargs_$parse_command_line_fixed_arguments 0x0B885C 0xE4     level 2
    no_source_file                           0x0B87DE 0x2A     level 3
    match                                    0x0B87BA 0x24     level 3
    cargs_$init_option_defaults              0x0B8542 0x278    level 2
    get_little_version                       0x0B8510 0x32     level 2
    cargs_$identify_self                     0x0B84D4 0x3C     level 2
    build_my_version_string                  0x0B8424 0x70     level 3
    encode_it                                0x0B83BC 0x68     level 4
    get_compiler_image_timestamp_and_edit_number 0x0B8386 0x34     level 3
    build_my_name_string                     0x0B81E8 0x19C    level 3

### `lang/lang/source/iosub.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/sys/ins/ms.ins.pas`
- include `//us/us/sys/ins/ios.ins.pas`
- include `//us/us/ins/ios_nr.ins.pas`
- include `//us/us/ins/prot.ins.pas`
- include `//us/us/sys/ins/mutex.ins.pas`
- include `//us/us/ins/name.ins.pas`
- include `//us/us/ins/uid_list.ins.pas`
- include `//us/us/sys/ins/type_uids.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//us/us/ins/strl.ins.pas`

    open_src_file                            0x0B8B9C 0x88     level 2
    stream_error                             0x0B8B58 0x44     level 2
    error_exit                               0x0B8AEC 0x62     level 2
    set_obj_length                           0x0B9A70 0x28     level 2
    freeobj                                  0x0B9B5C 0x42     level 2
    getobj                                   0x0B9AFA 0x62     level 2
    putobj                                   0x0B9A98 0x62     level 2
    ejctln                                   0x0B9A36 0x36     level 2
    listln                                   0x0B9A0A 0x2C     level 2
    iosub_$write                             0x0B9762 0xB0     level 2
    write_ln                                 0x0B96A2 0xC0     level 2
    io_term_force                            0x0B9600 0xA2     level 2
    iosub_$selected_io_term                  0x0B9494 0x12C    level 2
    io_term                                  0x0B95D8 0x28     level 2
    iosub_$redirect_source_input             0x0B9418 0x7C     level 2
    close_include_file                       0x0B9DCE 0x22     level 2
    iosub_$get_full_path_name                0x0B9D00 0xCA     level 2
    iosub_$get_dtm                           0x0B9CB2 0x4E     level 2
    open_include_file                        0x0B9B9E 0x110    level 2
    io_release                               0x0B9912 0x70     level 2
    io_mark                                  0x0B989E 0x74     level 2
    get_listing_stream_id                    0x0B93F4 0x24     level 2
    typemsg                                  0x0B99CA 0x40     level 2
    typeln                                   0x0B9982 0x44     level 2
    read_ln                                  0x0B9812 0x8C     level 2
    iosub_$init_io                           0x0B9258 0x106    level 2
    open_plb_file                            0x0B914C 0xF4     level 3
    open_binary_file                         0x0B90EC 0x5A     level 3
    open_bin_file                            0x0B9094 0x58     level 4
    open_listing_file                        0x0B8F6C 0x11C    level 3
    open_source_file                         0x0B8EBC 0xB0     level 3
    build_name                               0x0B8D3A 0x180    level 3
    append_string                            0x0B8D14 0x26     level 3
    match_suffix                             0x0B8C82 0x92     level 3
    iosub_$init_default_properties           0x0B8C54 0x2E     level 2
    iosub_$init_all                          0x0B935E 0x96     level 2

### `lang/lang/source/target_properties.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/coff.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/at_lib_dsc.ins.pas`

    target_properties$cpu_rev_specific       0x0B9E7A 0x9C     level 2
    target_properties$kernel_mode_code       0x0B9E46 0x34     level 2
    target_properties$begin_compilation      0x0B9DF0 0x56     level 2

### `lang/lang/source/empty.pas`



### `lang2/source/isc/isc_call_handling.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    pass_2_isc_call                          0x0BA2FC 0x22E    level 2
    pass_1_isc_call_addr_of_temp             0x0BA2E0 0x1C     level 2
    pass_1_isc_call                          0x0BA006 0x2DA    level 2
    number_of_outputs                        0x0B9FAE 0x58     level 2
    number_of_inputs                         0x0B9F56 0x58     level 2
    get_slevel                               0x0B9F24 0x32     level 2

### `lang2/source/isc/isc_cse_handling.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    solution_kind_of_cse                     0x0BA70C 0x4C     level 2
    pass_2_cse_use_obj_w_name                0x0BCC4E 0x4A     level 2
    pass_2_cse_use_ob                        0x0BCE46 0x34E    level 2
    pass_2_cse_use_live_range                0x0BCD9C 0x4C     level 2
    pass_2_cse_use_index_reg                 0x0BCBA6 0x4C     level 2
    pass_2_cse_use_home_solution             0x0BCCF6 0x46     level 2
    pass_2_cse_use_base_reg                  0x0BCAFE 0x4C     level 2
    pass_2_cse_parent_obj_w_name             0x0BC4F0 0x32     level 2
    pass_2_cse_parent_ob                     0x0BC6AC 0x344    level 2
    pass_2_cse_parent_live_range             0x0BC618 0x34     level 2
    pass_2_cse_parent_index_reg              0x0BC45C 0x34     level 2
    pass_2_cse_parent_home_solution          0x0BC584 0x2E     level 2
    pass_2_cse_parent_base_reg               0x0BC3CA 0x34     level 2
    pass_1_cse_use_uses_index_reg            0x0BC318 0x50     level 2
    pass_1_cse_use_uses_disp                 0x0BC26C 0x50     level 2
    pass_1_cse_use_ob                        0x0BB4E8 0x104    level 2
    pass_1_cse_use_memory_refs               0x0BC114 0x4C     level 2
    pass_1_cse_use_ip_reg_result             0x0BBC4E 0x4C     level 2
    pass_1_cse_use_ip_reg_max                0x0BBBA4 0x4C     level 2
    pass_1_cse_use_lit_value                 0x0BBAFA 0x4C     level 2
    pass_1_cse_use_has_sym_disp              0x0BC1BE 0x4E     level 2
    pass_1_cse_use_fp_reg_result             0x0BBDA6 0x4C     level 2
    pass_1_cse_use_fp_reg_quad_result        0x0BC062 0x4C     level 2
    pass_1_cse_use_fp_reg_quad_max           0x0BBFB4 0x4C     level 2
    pass_1_cse_use_fp_reg_pair_result        0x0BBF02 0x4C     level 2
    pass_1_cse_use_fp_reg_pair_max           0x0BBE54 0x4C     level 2
    pass_1_cse_use_fp_reg_max                0x0BBCFC 0x4C     level 2
    pass_1_cse_use_eval_order                0x0BBA50 0x4C     level 2
    pass_1_cse_use_embedded_sr_temp          0x0BB99C 0x50     level 2
    pass_1_cse_use_disp                      0x0BB8F8 0x4C     level 2
    pass_1_cse_use_delay                     0x0BB852 0x4C     level 2
    pass_1_cse_use_code_bytes                0x0BB7A8 0x4C     level 2
    pass_1_cse_use_bits_trusted              0x0BB6FC 0x4C     level 2
    pass_1_cse_use_bits_known                0x0BB652 0x4C     level 2
    pass_1_cse_parent_uses_index_reg         0x0BB44C 0x38     level 2
    pass_1_cse_parent_uses_disp              0x0BB3B2 0x38     level 2
    pass_1_cse_parent_ob                     0x0BA7B0 0xFE     level 2
    pass_1_cse_parent_memory_refs            0x0BB284 0x34     level 2
    pass_1_cse_parent_ip_reg_result          0x0BAE50 0x34     level 2
    pass_1_cse_parent_ip_reg_max             0x0BADBC 0x34     level 2
    pass_1_cse_parent_lit_value              0x0BAD28 0x34     level 2
    pass_1_cse_parent_has_sym_disp           0x0BB31A 0x36     level 2
    pass_1_cse_parent_fp_reg_result          0x0BAF7C 0x34     level 2
    pass_1_cse_parent_fp_reg_quad_result     0x0BB1E6 0x34     level 2
    pass_1_cse_parent_fp_reg_quad_max        0x0BB14C 0x34     level 2
    pass_1_cse_parent_fp_reg_pair_result     0x0BB0AE 0x34     level 2
    pass_1_cse_parent_fp_reg_pair_max        0x0BB014 0x34     level 2
    pass_1_cse_parent_fp_reg_max             0x0BAEE8 0x34     level 2
    pass_1_cse_parent_eval_order             0x0BAC94 0x34     level 2
    pass_1_cse_parent_embedded_sr_temp       0x0BABF6 0x38     level 2
    pass_1_cse_parent_disp                   0x0BAB68 0x34     level 2
    pass_1_cse_parent_delay                  0x0BAAD8 0x34     level 2
    pass_1_cse_parent_code_bytes             0x0BAA42 0x34     level 2
    pass_1_cse_parent_bits_trusted           0x0BA9AC 0x34     level 2
    pass_1_cse_parent_bits_known             0x0BA918 0x34     level 2
    map_cse_use_ob_to_cse_parent_ob          0x0BA698 0x32     level 2
    choose_one_cse_solution                  0x0BA574 0xF6     level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_debug.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    print_permissible_solution_kinds         0x0D8E1A 0x388    level 2
    isc_print_il_node                        0x0BD1DC 0x168C0  level 2
    indent                                   0x0D6110 0x60     level 2
    dump_solution                            0x0D6174 0x23F6   level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_main.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    isc_$initialize_routine                  0x0D9B92 0xAA     level 2
    solution_list$preserve                   0x0D9992 0x94     level 2
    solution_list$delete                     0x0D989A 0x74     level 2
    solution_list$append                     0x0D980C 0x64     level 2
    solution_list$new                        0x0D97E6 0x26     level 2
    solution_list$empty                      0x0D9938 0x30     level 2
    preserve_solution                        0x0D94A6 0x340    level 2
    new_solution                             0x0D9318 0xAA     level 2
    new_inherited_attributes                 0x0D92C8 0x50     level 2
    duplicate_solution                       0x0D93FC 0x62     level 2
    duplicate_inherited_attributes           0x0D945E 0x48     level 2
    apply_pass_2_to_list                     0x0DA0BE 0xE6     level 2
    apply_pass_1_and_choose_to_list          0x0D9DDC 0x276    level 2
    isc_$process_statement                   0x0D9C6C 0x152    level 2
    isc_$end_compilation                     0x0DB25A 0x1A0    level 2
    isc_$end_routine                         0x0DA27E 0x336    level 2
    isc_$begin_routine                       0x0DA1E4 0x9A     level 2
    isc_$begin_compilation                   0x0D9A52 0xDE     level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_1_main.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    isc_var_name                             0x0EFE50 0x46     level 2
    isc_use_def_ob                           0x0EFE14 0x3C     level 2
    isc_tree_node                            0x0EFDB6 0x5E     level 2
    isc_tree_node_value_top                  0x0EFC90 0x126    level 2
    isc_tree_node_unsigned_mod_top           0x0EFA4E 0x242    level 2
    isc_tree_node_unsigned_div_top           0x0EF80C 0x242    level 2
    isc_tree_node_unpack_top                 0x0EF61A 0x1F2    level 2
    isc_tree_node_sub_top                    0x0EF418 0x202    level 2
    isc_tree_node_strncmp_top                0x0EF20E 0x20A    level 2
    isc_tree_node_strlen_top                 0x0EF136 0xD8     level 2
    isc_tree_node_strcmp_top                 0x0EEFD2 0x164    level 2
    isc_tree_node_sr_top                     0x0EEDBC 0x216    level 2
    isc_tree_node_signed_mod_top             0x0EEB7A 0x242    level 2
    isc_tree_node_signed_div_top             0x0EE938 0x242    level 2
    isc_tree_node_set_range_in_set_top       0x0EE686 0x2B2    level 2
    isc_tree_node_set_or_top                 0x0EE484 0x202    level 2
    isc_tree_node_set_extend_top             0x0EE364 0x120    level 2
    isc_tree_node_set_diff_top               0x0EE162 0x202    level 2
    isc_tree_node_set_compare_top            0x0EDFC2 0x1A0    level 2
    isc_tree_node_set_bit_in_set_top         0x0EDDEC 0x1D6    level 2
    isc_tree_node_set_and_top                0x0EDBEA 0x202    level 2
    isc_tree_node_rshf_top                   0x0ED9E8 0x202    level 2
    isc_tree_node_range_check_top            0x0ED752 0x296    level 2
    isc_tree_node_physical_top               0x0ED666 0xEC     level 2
    isc_tree_node_or_top                     0x0ED33C 0x32A    level 2
    isc_tree_node_not_top                    0x0ED216 0x126    level 2
    isc_tree_node_nop_top                    0x0ED0F0 0x126    level 2
    isc_tree_node_neg_top                    0x0ECFCA 0x126    level 2
    isc_tree_node_mul_top                    0x0ECC10 0x3BA    level 2
    isc_tree_node_mod_top                    0x0EC404 0x80C    level 2
    isc_tree_node_min_top                    0x0EC0B6 0x34E    level 2
    isc_tree_node_max_top                    0x0EBD94 0x322    level 2
    isc_tree_node_mark_dynamic_space_top     0x0EBC74 0x120    level 2
    isc_tree_node_lshf_top                   0x0EBA72 0x202    level 2
    isc_tree_node_isc_unsigned_rem_top       0x0EB912 0x160    level 2
    isc_tree_node_isc_unsigned_mod_top       0x0EB7A0 0x172    level 2
    isc_tree_node_isc_signed_rem_top         0x0EB624 0x17C    level 2
    isc_tree_node_isc_signed_mod_top         0x0EB4A8 0x17C    level 2
    isc_tree_node_isc_mul_top                0x0EAF0C 0x59C    level 2
    isc_tree_node_isc_func_call_top          0x0EAEBC 0x50     level 2
    isc_tree_node_isc_func_call_hidden_temp_top 0x0EAE6C 0x50     level 2
    isc_tree_node_isc_fio_init               0x0EAD84 0xE8     level 2
    isc_tree_node_isc_call_top               0x0EAD34 0x50     level 2
    isc_tree_node_isc_agg_lex_cmp_top        0x0EAA68 0x2CC    level 2
    isc_tree_node_isc_agg_cmp_top            0x0EA83C 0x22C    level 2
    isc_tree_node_isc_addr_top               0x0EA708 0x134    level 2
    isc_tree_node_index_top                  0x0EA556 0x1B2    level 2
    isc_tree_node_func_call_top              0x0EA3F0 0x166    level 2
    isc_tree_node_f_sub_top                  0x0EA1EE 0x202    level 2
    isc_tree_node_f_range_check_top          0x0E9F58 0x296    level 2
    isc_tree_node_f_neg_top                  0x0E9E32 0x126    level 2
    isc_tree_node_f_mul_top                  0x0E9C30 0x202    level 2
    isc_tree_node_f_math_top                 0x0E98E2 0x34E    level 2
    isc_tree_node_f_extend_top               0x0E9668 0x27A    level 2
    isc_tree_node_f_expon_top                0x0E9546 0x122    level 2
    isc_tree_node_f_div_top                  0x0E91FA 0x34C    level 2
    isc_tree_node_f_compare_top              0x0E8FB8 0x242    level 2
    isc_tree_node_f_add_top                  0x0E8DB6 0x202    level 2
    isc_tree_node_f_ada_expon_top            0x0E8C94 0x122    level 2
    isc_tree_node_extract_bit_field_top      0x0E8AEE 0x1A6    level 2
    isc_tree_node_extend_top                 0x0E89A8 0x146    level 2
    isc_tree_node_expon_top                  0x0E8886 0x122    level 2
    isc_tree_node_eor_top                    0x0E855C 0x32A    level 2
    isc_tree_node_div_top                    0x0E7F20 0x63C    level 2
    isc_tree_node_compare_top                0x0E7B80 0x3A0    level 2
    isc_tree_node_chk_top                    0x0E79AA 0x1D6    level 2
    isc_tree_node_call_top                   0x0E7886 0x124    level 2
    isc_tree_node_cache_top                  0x0E784A 0x3C     level 2
    isc_tree_node_bit_test_top               0x0E7686 0x1C4    level 2
    isc_tree_node_bit_set_top                0x0E7390 0x2F6    level 2
    isc_tree_node_bit_field_cmp_top          0x0E6EEE 0x4A2    level 2
    isc_tree_node_arshf_top                  0x0E6CE8 0x206    level 2
    isc_tree_node_and_top                    0x0E69B8 0x330    level 2
    isc_tree_node_alshf_top                  0x0E67B2 0x206    level 2
    isc_tree_node_allocate_dynamic_space_top 0x0E668E 0x124    level 2
    isc_tree_node_align_top                  0x0E65AA 0xE4     level 2
    isc_tree_node_agg_compare_top            0x0E6406 0x1A4    level 2
    isc_tree_node_addr_top                   0x0E62EE 0x118    level 2
    isc_tree_node_add_top                    0x0E5F98 0x356    level 2
    isc_tree_node_ada_expon_top              0x0E5E74 0x124    level 2
    isc_tree_node_abs_top                    0x0E5D64 0x110    level 2
    isc_sym_disp_node                        0x0E5C7E 0xE6     level 2
    isc_usinteger_ob                         0x0E5C42 0x3C     level 2
    isc_sinteger_ob                          0x0E5C06 0x3C     level 2
    isc_slogical_ob                          0x0E5BCA 0x3C     level 2
    isc_set_con_ob                           0x0E5A50 0x17A    level 2
    isc_sb_register                          0x0E5A14 0x3C     level 2
    isc_return_node                          0x0E5850 0x1C4    level 2
    isc_release_dynamic_space                0x0E572C 0x124    level 2
    isc_real_ob                              0x0E56F0 0x3C     level 2
    isc_raise_exception                      0x0E55BA 0x136    level 2
    isc_ptr_node                             0x0E549E 0x11C    level 2
    isc_procedure_blk                        0x0E5276 0x228    level 2
    isc_physical_register_ob                 0x0E523A 0x3C     level 2
    isc_pf_call                              0x0E5160 0xDA     level 2
    isc_nlbranch_node                        0x0E4F6E 0x1F2    level 2
    isc_namelist_constant_ob                 0x0E4DF4 0x17A    level 2
    isc_llogical_ob                          0x0E4DB8 0x3C     level 2
    isc_ulinteger_ob                         0x0E4D7C 0x3C     level 2
    isc_linteger_ob                          0x0E4D40 0x3C     level 2
    isc_lib_dsc                              0x0E4BE6 0x15A    level 2
    isc_lb_register                          0x0E4B7E 0x68     level 2
    isc_label_node                           0x0E4B42 0x3C     level 2
    isc_uinteger_ob                          0x0E4B06 0x3C     level 2
    isc_integer_ob                           0x0E4ACA 0x3C     level 2
    isc_insert_bit_field                     0x0E4864 0x266    level 2
    isc_function_blk                         0x0E463C 0x228    level 2
    isc_fortran_symbol                       0x0E434E 0x2EE    level 2
    isc_exception_register                   0x0E4312 0x3C     level 2
    isc_exception_handler_entry              0x0E42D6 0x3C     level 2
    isc_eval_node                            0x0E4280 0x56     level 2
    isc_entry_blk                            0x0E4058 0x228    level 2
    isc_dpreal_ob                            0x0E401C 0x3C     level 2
    isc_dpcomplex_ob                         0x0E3FE0 0x3C     level 2
    isc_display_register                     0x0E3FA4 0x3C     level 2
    isc_disp_node                            0x0E3EBA 0xEA     level 2
    isc_dindex_node                          0x0E3C9C 0x21E    level 2
    isc_db_register                          0x0E3C60 0x3C     level 2
    isc_cse_use_ob                           0x0E3C16 0x4A     level 2
    isc_cse_parent_ob                        0x0E3BCC 0x4A     level 2
    isc_cs_temp                              0x0E3AB0 0x11C    level 2
    isc_cs_node                              0x0E38F6 0x1BA    level 2
    isc_complex_ob                           0x0E38BA 0x3C     level 2
    isc_cmp_tree_node                        0x0E385A 0x60     level 2
    isc_cmp_tree_node_set_compare_top        0x0E36B6 0x1A4    level 2
    isc_cmp_tree_node_f_compare_top          0x0E3470 0x246    level 2
    isc_cmp_tree_node_compare_top            0x0E30D0 0x3A0    level 2
    isc_cmp_tree_node_bit_test_top           0x0E2F0C 0x1C4    level 2
    isc_cmp_tree_node_bit_field_cmp_top      0x0E2A6A 0x4A2    level 2
    isc_cmp_tree_node_agg_compare_top        0x0E28C6 0x1A4    level 2
    isc_char_string_ob                       0x0E274C 0x17A    level 2
    isc_char_ob                              0x0E2710 0x3C     level 2
    isc_cc_call                              0x0E26D4 0x3C     level 2
    isc_cbranch_node                         0x0E253C 0x198    level 2
    isc_case_node_no_range_check             0x0E2448 0xF4     level 2
    isc_case_node_range_check                0x0E216C 0x2DC    level 2
    isc_branch_node                          0x0E20E0 0x8C     level 2
    isc_blogical_ob                          0x0E20A4 0x3C     level 2
    isc_block_entry_node                     0x0E2068 0x3C     level 2
    isc_blk_end_node                         0x0E1F26 0x142    level 2
    isc_bit_field_assign                     0x0E1A60 0x4C6    level 2
    isc_ubinteger_ob                         0x0E1A24 0x3C     level 2
    isc_binteger_ob                          0x0E19E8 0x3C     level 2
    isc_at_lib_dsc                           0x0E188E 0x15A    level 2
    isc_assign_node                          0x0E182E 0x60     level 2
    isc_assign_node_sub_from_aop             0x0E1616 0x218    level 2
    isc_assign_node_strncpy_aop              0x0E13D2 0x244    level 2
    isc_assign_node_strncat_aop              0x0E118E 0x244    level 2
    isc_assign_node_strcpy_aop               0x0E0FF2 0x19C    level 2
    isc_assign_node_strcat_aop               0x0E0E56 0x19C    level 2
    isc_assign_node_set_or_to_aop            0x0E0CA0 0x1B6    level 2
    isc_assign_node_set_diff_from_aop        0x0E0AEA 0x1B6    level 2
    isc_assign_node_set_and_to_aop           0x0E0934 0x1B6    level 2
    isc_assign_node_scalar_aop               0x0E0632 0x302    level 2
    isc_assign_node_rshft_to_aop             0x0E041A 0x218    level 2
    isc_assign_node_range_check_to_aop       0x0E011E 0x2FC    level 2
    isc_assign_node_pack_aop                 0x0DFF22 0x1FC    level 2
    isc_assign_node_or_to_aop                0x0DFD0A 0x218    level 2
    isc_assign_node_not_to_aop               0x0DFBD6 0x134    level 2
    isc_assign_node_neg_to_aop               0x0DFAA2 0x134    level 2
    isc_assign_node_mul_to_aop               0x0DF984 0x11E    level 2
    isc_assign_node_lshft_to_aop             0x0DF76C 0x218    level 2
    isc_assign_node_isc_slice_aop            0x0DF648 0x124    level 2
    isc_assign_node_isc_mul_to_aop           0x0DF1BA 0x48E    level 2
    isc_assign_node_isc_fill_aop             0x0DEF70 0x24A    level 2
    isc_assign_node_isc_agg_zero_aop         0x0DEDD6 0x19A    level 2
    isc_assign_node_isc_agg_aop              0x0DE9E4 0x3F2    level 2
    isc_assign_node_fp_aop                   0x0DE6E2 0x302    level 2
    isc_assign_node_f_sub_from_aop           0x0DE4CA 0x218    level 2
    isc_assign_node_f_range_check_to_aop     0x0DE1CE 0x2FC    level 2
    isc_assign_node_f_mul_to_aop             0x0DDFB6 0x218    level 2
    isc_assign_node_f_div_by_aop             0x0DDD9E 0x218    level 2
    isc_assign_node_f_add_to_aop             0x0DDB86 0x218    level 2
    isc_assign_node_eor_to_aop               0x0DD96E 0x218    level 2
    isc_assign_node_div_by_aop               0x0DD4AE 0x4C0    level 2
    isc_assign_node_and_to_aop               0x0DD296 0x218    level 2
    isc_assign_node_agg_len_aop              0x0DD086 0x210    level 2
    isc_assign_node_agg_aop                  0x0DCD58 0x302    level 2
    isc_assign_node_add_to_aop               0x0DCB40 0x218    level 2
    isc_argument_block_location_ob           0x0DCB04 0x3C     level 2
    isc_ap_register                          0x0DCAC8 0x3C     level 2
    isc_addr_con                             0x0DC990 0x138    level 2
    isc_unrecognized_il_node                 0x0DB51C 0x25C    level 2
    cross_product_to_solutions_of_parent     0x0DB4B4 0x68     level 2
    pass_1                                   0x0F04BC 0x646    level 2
    isc_pass_1_begin_compilation             0x0EFE96 0x626    level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pass_2_main.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    pass_2                                   0x18C588 0x218    level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_pattern_matcher.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    hard_work                                0x20042C 0x5E4    level 2
    pattern_matcher                          0x200D6E 0x7944   level 2

### `lang2/source/isc/isc_to_lir.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    requests_to_string                       0x208BB4 0x3CA    level 2
    guarantee_has_live_range                 0x2088B0 0xDA     level 2
    end_statement                            0x209796 0x804    level 2
    end_routine                              0x2093F2 0x9A     level 2
    end_compilation                          0x20928C 0x9A     level 2
    end_basic_block                          0x2095D2 0xCC     level 2
    debug_lir_$pa_risc_shift_double_instruction 0x20DAE2 0x298    level 2
    debug_lir_main_$handler_reentry          0x20D994 0x12C    level 2
    debug_lir_main_$entry                    0x20D850 0x12C    level 2
    debug_lir_$store_instruction             0x20CB8C 0x3FA    level 2
    debug_lir_$simple_instruction            0x20C924 0x268    level 2
    debug_lir_$operate_and_branch_instruction 0x20D5FC 0x24A    level 2
    debug_lir_$mtpr_instruction              0x20D2C2 0x33A    level 2
    debug_lir_$mfpr_instruction              0x20CF8E 0x328    level 2
    debug_lir_$load_instruction              0x20C4D4 0x3EA    level 2
    debug_lir_$label                         0x20C388 0x14C    level 2
    debug_lir_$field_instruction             0x20C0BE 0x2AC    level 2
    debug_lir_$end_call_or_svc               0x20BF38 0x16A    level 2
    debug_lir_$emit_call_or_svc              0x20BCB2 0x242    level 2
    debug_lir_$dispatch_instruction          0x20BACE 0x1D8    level 2
    debug_lir_$disjoint_lhs_and_rhs_tokens   0x20B972 0x134    level 2
    debug_lir_$common_lhs_rhs_token          0x20B824 0x12C    level 2
    debug_lir_$break_basic_block             0x20B6E8 0x11E    level 2
    debug_lir_$branch_instruction            0x20B500 0x1DE    level 2
    debug_lir_$begin_fortran_io_sequence     0x20B3FA 0xDC     level 2
    debug_lir_$begin_call_or_svc             0x20B1A4 0x1FA    level 2
    begin_statement                          0x2096B2 0xD0     level 2
    begin_routine                            0x20933A 0xA6     level 2
    begin_compilation                        0x209168 0xBC     level 2
    begin_basic_block                        0x20949C 0xCC     level 2

### `lang2/source/isc/isc_user_routines.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`

    expression_has_side_effects              0x216A80 0x84     level 2
    side_effect_var_name_fill_in_size        0x216844 0x26     level 2
    side_effect_fortran_symbol_fill_in_size  0x216778 0x8A     level 2
    bits_trusted_of_var_name                 0x2120CE 0x6E     level 2
    bits_trusted_of_fortran_symbol           0x212058 0x76     level 2
    alignment_from_sr_info                   0x20E908 0x8D8    level 2
    number_of_one_bits                       0x20E8D2 0x36     level 2
    initialize_well_known_symbol             0x20E892 0x40     level 2
    local_initialize_var_name                0x20E7E4 0xAE     level 2
    local_initialize_fortran_symbol          0x20E6AA 0x13A    level 2
    local_initialize_symbol                  0x20DEC4 0x4E8    level 2
    local_create_soln_for_fp_reg_quad        0x20DE90 0x34     level 2
    local_create_soln_for_fp_reg_pair        0x20DE5C 0x34     level 2
    local_create_soln_for_fp_reg             0x20DE28 0x34     level 2
    local_create_soln_for_ip_reg             0x20DDF4 0x34     level 2
    is_in_range                              0x20DDC4 0x30     level 2
    literal_base_register                    0x20DD7C 0x48     level 2
    widen_char_string_ob                     0x216A1E 0x5E     level 2
    well_known_literal                       0x213042 0x5C     level 2
    warning_unaligned_atomic_access          0x21696E 0x8C     level 2
    verify_any_bits                          0x214916 0x268    level 2
    verify_bits                              0x2145EE 0x24C    level 2
    vatt_set_to_string                       0x21B17A 0x36A    level 2
    vatt_rec_to_string                       0x21AF9E 0x1A2    level 2
    value_top_over                           0x216D34 0x5A     level 2
    validate_shift_count                     0x216D8E 0xB0     level 2
    type_attr_set_to_string                  0x21AC0C 0x2AA    level 2
    solution_to_string                       0x219FA6 0xA86    level 2
    solution_kind_of_symbol                  0x216E8A 0x3E     level 2
    similar_solutions                        0x21255A 0x148    level 2
    sign_extend                              0x212E02 0x42     level 2
    side_effect_symbol_fill_in_size          0x21686A 0x3E     level 2
    side_effect_set_var_$address_exposed     0x21675A 0x1E     level 2
    set_isc_is_cse_on_live_range_if_local_cse 0x216736 0x24     level 2
    rlen_code_from_type_node                 0x214CCC 0x248    level 2
    return_value_needs_assign_node           0x214C3E 0x8E     level 2
    relational_to_string                     0x219E3A 0x112    level 2
    process_eval_node                        0x216B04 0x1D2    level 2
    precision_from_il_node                   0x21529C 0x2EC    level 2
    possibly_make_expression_temporary       0x214598 0x56     level 2
    phase_set_to_string                      0x219AB6 0x2AA    level 2
    pc_relative_literal_size_to_bits_trusted 0x2166F8 0x3E     level 2
    pattern_match_error                      0x215660 0x89E    level 2
    number_of_rightmost_zeroes               0x212FC2 0x42     level 2
    number_of_rightmost_ones                 0x213004 0x3E     level 2
    number_of_leftmost_zeroes                0x212F3A 0x46     level 2
    number_of_leftmost_ones                  0x212F80 0x42     level 2
    not_permissible_function                 0x212ED4 0x60     level 2
    make_bit_mask_2                          0x210EA0 0x11E    level 2
    make_bit_mask_1                          0x210CF2 0x138    level 2
    low_half_of_fp_reg_quad                  0x2135D0 0xBE     level 2
    low_half_of_fp_reg_pair                  0x2134DC 0xB8     level 2
    log_2                                    0x216934 0x3A     level 2
    live_range_to_string                     0x219A02 0xA0     level 2
    length_of_sequence_of_zeroes             0x212AF4 0x90     level 2
    length_of_sequence_of_ones               0x212A68 0x8C     level 2
    legal_evaluation_orders                  0x212410 0x40     level 2
    label_to_string                          0x21998C 0x68     level 2
    is_sequence_of_zeroes                    0x2129C8 0xA0     level 2
    is_sequence_of_ones_right_justified      0x21292A 0x9E     level 2
    is_sequence_of_ones                      0x21288C 0x9E     level 2
    is_power_of_2                            0x2168A8 0x30     level 2
    is_device                                0x212D5E 0x8A     level 2
    is_all_zeroes                            0x210B36 0x52     level 2
    is_a_register_solution                   0x2133F4 0x36     level 2
    ip_reg_to_ip_reg_scaled                  0x21342A 0x38     level 2
    ip_reg_scaled_to_ip_reg                  0x213462 0x2E     level 2
    invertible_in_dp                         0x216906 0x2E     level 2
    invertible_in_sp                         0x2168D8 0x2E     level 2
    integer32_from_char_string_ob            0x212E44 0x74     level 2
    in_interval_at_compile_time              0x212C8E 0xD0     level 2
    instruction_to_string                    0x219924 0x40     level 2
    initialize_symbol                        0x2130E8 0x38     level 2
    il_node_to_string                        0x21805C 0x13EA   level 2
    il_node_to_integer_value                 0x212260 0x74     level 2
    il_node_to_empty_string                  0x2170D4 0xF7A    level 2
    il_node_is_literal_sequence_of_zeroes    0x212BFA 0x94     level 2
    il_node_is_literal_sequence_of_ones      0x212B84 0x76     level 2
    il_node_has_integer_value                0x2121E6 0x7A     level 2
    il_node_has_float_value                  0x2121AE 0x38     level 2
    il_kind_function                         0x2144CE 0x1C     level 2
    high_half_of_fp_reg_quad                 0x213594 0x3C     level 2
    high_half_of_fp_reg_pair                 0x213490 0x4C     level 2
    get_uparrow_dot_kind                     0x212EB8 0x1C     level 2
    get_kind_of_home_solution                0x21217C 0x32     level 2
    get_live_range_serialize                 0x214144 0x28     level 2
    get_live_range_register                  0x21411E 0x26     level 2
    get_live_range_no_modify                 0x2140F6 0x28     level 2
    get_live_range_of_imaginary_part         0x21416C 0xAE     level 2
    get_live_range_assigned                  0x2140D0 0x26     level 2
    find_well_known_literal_solution         0x21309E 0x4A     level 2
    fetch_precision_to_bits_trusted          0x210B88 0xCE     level 2
    evaluation_order_function                0x212450 0xD6     level 2
    duplicate_address_mode_adding_byte_offset 0x213CDE 0x44     level 2
    duplicate_address_mode                   0x213CA4 0x3A     level 2
    cs_temp_to_var_name                      0x2123D0 0x40     level 2
    create_solution_for_literal_32_bits      0x213C68 0x3C     level 2
    create_solution_for_ip_reg_scaled        0x213A58 0x32     level 2
    create_solution_for_fp_reg_physical      0x213AB8 0xAA     level 2
    create_solution_for_fp_reg_pair_physical 0x213B90 0xAA     level 2
    create_solution_for_fp_reg_quad          0x213C3A 0x2E     level 2
    create_solution_for_case_jump_base       0x2139EC 0x3E     level 2
    create_solution_for_address_mode         0x2139BE 0x2E     level 2
    compute_number_loaded_bytes              0x213922 0x9C     level 2
    clearly_dominates                        0x2126A2 0x146    level 2
    choose_one_solution                      0x2127E8 0x7C     level 2
    case_index_array_to_string               0x2170BE 0x16     level 2
    block_rec_to_string                      0x217004 0x9A     level 2
    bits_trusted_of_symbol                   0x21213C 0x40     level 2
    bits_trusted_function                    0x211DFA 0x1F8    level 2
    bits_to_alignment                        0x211DC0 0x3A     level 2
    bits_known_function                      0x211014 0x23A    level 2
    basic_block_to_string                    0x216FC8 0x2C     level 2
    available_precision_function             0x210B06 0x30     level 2
    assert_kind_is_label_node                0x2122D4 0x66     level 2
    arithmetic_from_il_node                  0x214F7E 0x290    level 2
    arg_loc_t_to_string                      0x216EC8 0x72     level 2
    alignment_from_il_node                   0x210628 0x3C8    level 2
    address_mode_for_single_value            0x213718 0xB4     level 2
    address_mode_for_integer32_value         0x213878 0xAA     level 2
    address_mode_for_double_value            0x2137CC 0xAC     level 2
    address_mode_for_expression_temporary    0x21368E 0x8A     level 2
    lir_$can_encode_as_immediate_postincrement 0x2105D4 0x54     level 2
    make_expression_temporary                0x2144EA 0xAE     level 2
    create_solution_for_ip_reg               0x213A2A 0x2E     level 2
    create_solution_for_fp_reg_pair          0x213B62 0x2E     level 2
    create_solution_for_fp_reg               0x213A8A 0x2E     level 2
    isc_$get_memory_home                     0x213DE8 0xCE     level 2
    isc_$get_label                           0x2155C2 0x9E     level 2
    isc_$get_home_solution                   0x213D22 0x82     level 2
    isc_$initialize_parameter                0x213158 0x40     level 2
    isc_$initialize_symbol                   0x213120 0x38     level 2
    isc_$init_well_known_ip_reg              0x214296 0xBA     level 2
    isc_$init_well_known_fp_reg_pair         0x214414 0xBA     level 2
    isc_$init_well_known_fp_reg              0x21435A 0xBA     level 2
    isc_$precision_from_rlen_and_size        0x214BF6 0x48     level 2
    isc_$get_il_live_range                   0x213EB6 0x1B2    level 2
    isc_$is_a_register_candidate             0x213198 0x21E    level 2

### `moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_vars.pas`

- include `//lang2/source/isc/isc_var_defines.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`


### `lang2/source/isc/rewrite.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/strl.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/at_lib_dsc.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc.pvt.pas`
- include `//lang2/source/isc/isc_consts.ins.pas`
- include `//lang2/source/isc/isc_types.ins.pas`
- include `//lang2/source/isc/isc_routine_externs.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`
- include `//lang/lang/source/list_tree.ins.pas`
- include `//lang2/source/be_com/m32_prism_and_pa.pas`
- include `//lang2/source/be_com/m16_prism.pas`

    make_call_to_rws_$alloc_temp             0x21D8C2 0x64     level 2
    turn_into_case_statement                 0x21D41A 0x2B4    level 2
    tree_is_a_constant                       0x21D3A0 0x72     level 2
    common_piece_of_tree                     0x21D378 0x28     level 2
    case_displacement                        0x21D30C 0x6C     level 2
    construct_instruction                    0x21CCBA 0x2B2    level 2
    make_tree_node                           0x21CC6C 0x4E     level 2
    correct_opmod                            0x21CC5C 0x10     level 2
    correct_uc                               0x21CBC8 0x94     level 2
    get_home_or_temp                         0x21B618 0x158    level 2
    rewrite_$agg_aop                         0x21DA9A 0x22A    level 2
    rewrite_$entry                           0x21D926 0x174    level 2
    rewrite_$check_for_case_statement        0x21D6CE 0x1F4    level 2
    rewrite_$mul_to_aop                      0x21D272 0x9A     level 2
    rewrite_$const_mul                       0x21CF6C 0x274    level 2
    rewrite_$routine_call                    0x21B770 0x1296   level 2

### `lang2/source/be_com/asm.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_assembly.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_string_length.init`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    asm_$build_dispatch_table                0x21F362 0x216    level 2
    excise_instruction                       0x21F320 0x42     level 2
    complete_entry_sequence                  0x21F0A8 0x23A    level 2
    dump_pass_one_instruction                0x21EF0C 0xD6     level 2
    dump_literal_pool                        0x21E9BC 0x3BC    level 2
    new_instruction                          0x21E938 0x84     level 2
    bump_locations                           0x21E800 0xA8     level 2
    clear_literal_pool                       0x21E768 0x66     level 2
    append_literal_pool__code_cell           0x21E624 0x98     level 2
    insert_literal_pool__instruction         0x21E4E6 0xB8     level 2
    emit_literal_pool                        0x21E418 0xCE     level 2
    combine_literal_pools                    0x21E04A 0x200    level 2
    asm_$operand_in_literal_pool             0x21DFE8 0x62     level 2
    add_literal_to_literal_pool              0x21DE60 0xF8     level 2
    asm_$size_of_direct_literal              0x21DD98 0x8E     level 2
    asm_$size_of_indirect_literal            0x21DCDE 0x7C     level 2
    first_bb_with_instructions               0x21DCC6 0x18     level 2
    asm_$end_compilation                     0x22195C 0xC4     level 2
    asm_$end_routine                         0x21DCC4 0x2      level 2
    asm_$process_routine                     0x21F6D4 0x19A2   level 2
    asm_$begin_compilation                   0x221848 0xA8     level 2

### `lang2/source/be_com/at_backend.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/common/source/exs.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    end_phase                                0x222618 0xF6     level 2
    run_phase                                0x2223A0 0x1B8    level 2
    get_calling_conventions                  0x2222D6 0x84     level 2
    build_source_statement_map               0x221F4C 0x24C    level 2
    query_user                               0x221CAC 0x5C     level 2
    query_user_for_routine_name              0x221C2A 0x48     level 2
    zero                                     0x221A60 0x18     level 2
    phase_instr_bug_check                    0x221B7E 0xAC     level 2
    phase_bug_check                          0x221B18 0x66     level 2
    instr_bug_check                          0x221A78 0xA0     level 2
    at_backend_$can_load_module_db           0x222376 0x2A     level 2
    at_backend_$initialize_ftn_entry         0x22235A 0x1C     level 2
    at_backend_$end_compilation              0x2221BA 0xD8     level 2
    at_backend_$begin_compilation            0x221D3C 0x1B0    level 2
    codegen                                  0x222756 0x3E6    level 2

### `lang2/source/be_com/bin.pas`

- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/coff_dst.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang/lang/source/gen_unwind.ins.pas`
- include `//us/us/sys/ins/unwind.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`

    put_exception_stubs                      0x224240 0xD4     level 2
    put_exception                            0x223FD0 0x270    level 2
    add_unwind_for_exception_stub            0x223FA8 0x28     level 2
    resolve_exception_stub_disp              0x223F3E 0x6A     level 2
    get_exception_info                       0x223EEC 0x52     level 2
    resolve_ap_or_sf_relative_disp           0x223DA6 0x100    level 2
    set_current_routine                      0x223D68 0x3E     level 2
    close_previous_routine                   0x223C8C 0xDC     level 2
    put_procedure_start                      0x223BE0 0xAC     level 2
    add_unwind_rec                           0x22379C 0x212    level 2
    zero                                     0x223786 0x16     level 2
    emit_dot_lines_for_cc                    0x22361A 0x10E    level 2
    emit_a_pc_to_line_correlation            0x22358C 0x8E     level 2
    emit_a_pc_to_exception_correlation       0x22352E 0x5E     level 2
    set_current_block                        0x223494 0x9A     level 2
    set_end_pc                               0x22346A 0x2A     level 2
    initialize_block                         0x22342A 0x40     level 2
    new_code_range                           0x2233CC 0x5E     level 2
    map_statement_to_src_loc_and_offset      0x2232EC 0xE0     level 2
    bin_$emit_table                          0x22326E 0x7E     level 2
    bin_$emit_literal_pool                   0x222FF0 0x1F4    level 2
    bin_$advance_to_location                 0x222F7A 0x38     level 2
    bin_$put_cc_long_to_pure_text            0x222E10 0x11A    level 2
    add_exception_table_entry                0x222D84 0x46     level 2
    bin_$put_long_to_pure_text               0x222CF6 0x40     level 2
    bin_$put_word_to_pure_text               0x222C6C 0x40     level 2
    bin_$put_byte_to_pure_text               0x222C40 0x2C     level 2
    bin_$check_window                        0x222BDA 0x66     level 2
    bin_$unwind_bits                         0x223728 0x5E     level 2
    bin_$end_compilation                     0x222BD8 0x2      level 2
    bin_$begin_compilation                   0x222B3C 0x6A     level 2
    bin_$emit_compilation_pure_text          0x224314 0x7F6    level 2

### `lang2/source/be_com/bv.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`

    bv_$initialize_lifetimes_bit_vectors     0x22572C 0x11A    level 2
    bv_$initialize_availability_bit_vectors  0x2256A4 0x88     level 2
    bv_$allocate_availability_bit_vectors    0x2255F0 0xB4     level 2
    fill_vector                              0x225326 0x4A     level 2
    bv_$enlarge_complex_id_to_lr_map         0x2252A4 0x82     level 2
    bv_$allocate_rws_space                   0x225242 0x2E     level 2
    bv_$release_rws_allocation               0x224CA4 0x34     level 2
    zero                                     0x224C8C 0x18     level 2
    bv_$release_lr_map                       0x225DC4 0x2E     level 2
    bv_$release_availability_bit_vectors     0x225D78 0x4C     level 2
    bv_$release_bit_vectors                  0x225D1C 0x5C     level 2
    bv_$propagate_availability               0x225B18 0x1BE    level 2
    bv_$propagate_lifetimes                  0x22599A 0x17E    level 2
    bv_$initialize_bit_vectors               0x2258EE 0x6E     level 2
    bv_$create_dfa_bit_vectors               0x225846 0xA8     level 2
    bv_$make_live_range_complex              0x225370 0x214    level 2
    bv_$find_next_val                        0x225114 0x88     level 2
    bv_$find_next                            0x22519C 0x78     level 2
    bv_$set1_subsumes_set2                   0x2250B8 0x5C     level 2
    bv_$subtract                             0x225066 0x52     level 2
    bv_$and_to                               0x225012 0x54     level 2
    bv_$and                                  0x224FC2 0x50     level 2
    bv_$or                                   0x224F72 0x50     level 2
    bv_$equal                                0x224F18 0x5A     level 2
    bv_$copy_and_test                        0x224ECC 0x4C     level 2
    bv_$copy                                 0x224E84 0x48     level 2
    bv_$clear                                0x224E4A 0x3A     level 2
    bv_$set_if_not_killed                    0x224E06 0x44     level 2
    bv_$set                                  0x224DCE 0x38     level 2
    bv_$test_and_clear                       0x224D86 0x48     level 2
    bv_$test_and_set                         0x224D40 0x46     level 2
    bv_$test                                 0x224D0E 0x32     level 2

### `lang2/source/be_com/com.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang/lang/source/at_lib_dsc.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    optimize_block                           0x22BEAA 0xD6     level 2
    process_instruction                      0x22B46C 0x888    level 2
    destroy_instr                            0x22AFF0 0x3F4    level 2
    operand_is_trapcc_input                  0x22AFB0 0x40     level 2
    safe_cc_write                            0x22AEFC 0xB4     level 2
    call_cossin                              0x22A760 0x65C    level 2
    connect_physical                         0x22A6B4 0x62     level 2
    maybe_hoist_instr_from_loop              0x22A2F6 0x3BE    level 2
    bb_postdominates                         0x22A2B8 0x3E     level 2
    def_dominates_use                        0x22A276 0x42     level 2
    calc_last_legal_dom_bb                   0x22A224 0x52     level 2
    replace_zero_valued_lrs                  0x22A19A 0x8A     level 2
    move_is_zero                             0x22A0B2 0xE8     level 2
    attempt_do_not_delete_removal            0x22A03C 0x76     level 2
    attempt_store_elimination                0x229D86 0x2B6    level 2
    convert_store_to_seq                     0x229C96 0xF0     level 2
    safe_to_ignore_do_not_delete             0x229BB2 0xE4     level 2
    get_mem_birthpoint                       0x229B3A 0x78     level 2
    store_is_redundant                       0x229A9E 0x9C     level 2
    ltss_on_stores_to_same_addr              0x2299CA 0xD4     level 2
    get_the_right_instr                      0x229968 0x62     level 3
    simple_mmt_seq_input                     0x2298D2 0x96     level 2
    excise_a_store                           0x2297D2 0x100    level 2
    attempt_load_elimination                 0x22960E 0x1C4    level 2
    eliminate_load                           0x22930C 0x28C    level 2
    cvt_short_load_to_32_bits                0x22915E 0x1AE    level 2
    loop_memory_analysis                     0x229074 0xEA     level 2
    exit_blocks_safe                         0x228F8A 0xEA     level 2
    entry_blocks_safe                        0x228F50 0x3A     level 2
    collect_loop_contents                    0x228DF2 0x15E    level 2
    collect_exit_blocks                      0x228D58 0x9A     level 2
    suck_instrs_from_loop                    0x228968 0x3BE    level 2
    lr_value_same_on_loop_exit               0x228836 0x132    level 2
    lr_unconsumed_in_loop                    0x22876C 0xCA     level 2
    find_loop_memory_hoist_candidates        0x22841A 0x352    level 2
    worth_hoisting                           0x2283DC 0x3E     level 2
    is_join_bp                               0x2283A8 0x34     level 2
    partition_memory                         0x2282B8 0xBA     level 2
    consider_mem_dependents                  0x227EDE 0x3DA    level 2
    loop_invariant_addr                      0x227E04 0xA8     level 2
    is_invariant                             0x227D9C 0x68     level 2
    add_lrs_to_ssa_list                      0x227CB8 0xE4     level 2
    add_lr_to_list_uniquely                  0x227C6A 0x4E     level 2
    add_lr_to_list                           0x227C1A 0x50     level 2
    analyze_candidates                       0x227A8C 0x162    level 2
    ip_mem_reference                         0x227A0A 0x58     level 2
    replace_mem_instrs                       0x2274D0 0x53A    level 2
    build_stores                             0x22723E 0x292    level 2
    build_loads                              0x226E62 0x3DC    level 2
    no_reg_like_kinds                        0x226E38 0x2A     level 2
    com_$replace_oprs_value                  0x226898 0x536    level 2
    find_calls_snuggle_move                  0x22676E 0xAE     level 2
    make_entering_lts                        0x22670C 0x62     level 2
    find_exit_writer                         0x226514 0x1F8    level 2
    local_replace_output                     0x225E82 0x612    level 2
    operand_reg_like_kind                    0x225E48 0x3A     level 2
    clean_up_this_mess_right_now_young_man   0x225E16 0x32     level 2
    utils_ins_$operands_instruction          0x225DF4 0x22     level 2
    com_$compute_cses                        0x22BFD2 0x58     level 2
    com_$end_compilation                     0x22C064 0x1C     level 2
    com_$end_routine                         0x22C080 0x2      level 2
    com_$process_routine                     0x22C082 0x33A    level 2
    com_$begin_compilation                   0x22C02A 0x26     level 2

### `lang2/source/be_com/dbg_life.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`

    dbg_life_$mark_ap_relative_vars          0x22E16C 0x150    level 2
    dbg_life_$compact                        0x22DFF8 0x174    level 2
    add_live_range                           0x22DF2A 0xCE     level 3
    dbg_life_$find_symbols                   0x22D7E8 0x742    level 2
    map_physical_to_virtual_lr               0x22D610 0x1D8    level 2
    dbg_life_$open_pc_range                  0x22D470 0x16A    level 2
    dbg_life_$close_all_pc_ranges            0x22D3D0 0xA0     level 2
    dbg_life_$close_spill_pc_range           0x22D38A 0x46     level 2
    dbg_life_$close_pc_range                 0x22D32A 0x60     level 2
    dbg_life_$initialize                     0x22CD24 0x5A2    level 2
    write_register                           0x22CC30 0xF4     level 3
    kill_spilled_var                         0x22CBCC 0x64     level 3
    read_spilled_var                         0x22CB6C 0x60     level 3
    write_spilled_var                        0x22CB0A 0x62     level 3
    fill_not_killed_sets                     0x22C938 0x1D2    level 3
    initialize_not_killed_array              0x22C8D4 0x64     level 3
    interesting_variable                     0x22C894 0x40     level 2
    instr_is_pmove                           0x22C864 0x30     level 2
    loc_after                                0x22C82A 0x3A     level 2
    underlying_spill_location                0x22C804 0x26     level 2
    is_spill_instruction                     0x22C6AE 0x156    level 2
    spill_find_next                          0x22C638 0x76     level 2
    dbg_life_$end_routine                    0x22E562 0x2      level 2
    dbg_life_$process_routine                0x22E2BC 0x25A    level 2

### `lang2/source/be_com/df_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    do_global_walk                           0x22ED46 0x2C0    level 2
    need_all_writes                          0x22ED06 0x40     level 2
    process_marked_instructions              0x22EC28 0xDE     level 2
    rebuild_bb_exposed_and_final_lists       0x22EBB4 0x74     level 2
    df_utils_$canonicalize_lr_lts_lists      0x22E7EE 0x3C6    level 2
    memory_home_is_initialized_fsym          0x22E7BE 0x30     level 2
    special_p                                0x22E778 0x46     level 2
    mark_tail                                0x22E5D6 0x5A     level 2
    mark_lts                                 0x22E630 0xC4     level 2
    enqueue_instruction                      0x22E5A6 0x30     level 2
    utils_ins_$operands_instruction          0x22E564 0x22     level 2
    df_utils_$init_for_routine               0x22E588 0x1A     level 2
    df_utils_$global_walk_with_async_protection 0x22F070 0x36     level 2
    df_utils_$global_walk                    0x22F03A 0x36     level 2
    df_utils_$end_compilation                0x22E5A4 0x2      level 2
    df_utils_$end_routine                    0x22E5A2 0x2      level 2
    df_utils_$begin_compilation              0x22E586 0x2      level 2

### `lang2/source/be_com/dfa.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    dfa_$end_compilation                     0x22F0AC 0x2      level 2
    dfa_$end_routine                         0x22F0AA 0x2      level 2
    dfa_$process_routine                     0x22F0AE 0xDA     level 2
    dfa_$begin_compilation                   0x22F0A8 0x2      level 2

### `lang2/source/be_com/dmp.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/am_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/am_string_length.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/block_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/block_string_length.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_string_length.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_string_length.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_letter.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_letter.init`

    display_ra_info                          0x2336CA 0x1BE    level 2
    print_lts_list                           0x233054 0x444    level 2
    print_properties                         0x232F74 0xC8     level 2
    print_alias_desc                         0x230834 0x112    level 2
    print_register_if_assigned               0x2306D0 0xCC     level 2
    print_memory_home                        0x2304E8 0xD2     level 2
    dmp_$basic_block_header                  0x22FA44 0x550    level 2
    dmp_$bit_vectors_for_basic_block         0x22F87C 0x15A    level 2
    dmp_$basic_block_register_info           0x22F6D8 0xD8     level 2
    dmp_$flow_graph_edge_list                0x22F2DA 0x6E     level 2
    print_jbi_list                           0x22F274 0x52     level 2
    dmp_$operand_kind                        0x22F228 0x42     level 2
    dmp_$memory_usage                        0x23474A 0x188    level 2
    dmp_$whole_routine                       0x23394A 0x718    level 2
    dmp_$all_basic_block_headers             0x2304A8 0x40     level 2
    dmp_$three_char_lr_name_from_lr          0x232010 0x114    level 2
    dmp_$starting_basic_block                0x22F188 0x5E     level 2
    dmp_$reg_set                             0x22F5D8 0xE4     level 2
    dmp_$print_final_lts_list                0x233672 0x58     level 2
    dmp_$print_exposed_lts_list              0x23360C 0x58     level 2
    dmp_$interference_graph_analysis         0x2345FA 0xC8     level 2
    dmp_$note_label                          0x22F1FC 0x22     level 2
    dmp_$instruction                         0x230A2E 0x800    level 2
    dmp_$instr_print_single_line             0x232130 0xB8C    level 2
    dmp_$get_line_number                     0x2309C4 0x6A     level 2
    dmp_$complex_lr_bit_vector               0x22F48C 0x12A    level 2
    dmp_$complex_lr_bit_vector_header        0x22F374 0x2A     level 2

### `lang2/source/be_com/fg_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    compute_reach_of_definition              0x23771C 0x84     level 2
    init_and_compute_exposure                0x2375E6 0x7A     level 2
    mark_active_on_exit_blocks               0x237554 0x92     level 2
    mark_live_on_entry_blocks                0x237514 0x40     level 2
    drop_unconsumed_final_segments           0x237264 0x60     level 2
    drop_unconsumed_exposed_segments         0x237204 0x60     level 2
    drop_jbis_on_exposed_list                0x23715A 0xAA     level 2
    add_join_birthpoint_inputs               0x236BEA 0x60     level 2
    traverse                                 0x236914 0x200    level 2
    replace_exposed_lts                      0x2365CC 0xB8     level 2
    compute_rel                              0x2364EC 0xE0     level 2
    evaldef                                  0x2364C6 0x26     level 2
    eval                                     0x2364A0 0x26     level 2
    compress                                 0x236424 0x7C     level 2
    reverse_depth_first_search               0x236390 0x94     level 2
    make_loops_unconditional                 0x235E5C 0xA8     level 2
    every_interval_block_exits               0x235DC2 0x9A     level 2
    n_instrs                                 0x235D74 0x4E     level 2
    build_loop_header                        0x235B84 0x174    level 2
    copy_bb_contents                         0x235A28 0xF2     level 2
    build_exit                               0x23592E 0xFA     level 2
    an_exit_has_multiple_successors          0x2358B0 0x7E     level 2
    visit_interval_contents                  0x2355E0 0x96     level 2
    loop_entry_is_conditional                0x2355A2 0x3E     level 2
    in_interval                              0x235582 0x20     level 2
    reorder_start_bb_successor_list          0x2353D2 0xA6     level 2
    final_edge_fixup                         0x2352FA 0xD8     level 2
    depth_first_search                       0x235216 0xE4     level 2
    add_final_edges                          0x23519E 0x78     level 2
    order_successor_lists                    0x2350BE 0xE0     level 2
    n_edges                                  0x234A94 0x24     level 2
    utils_ins_$operands_instruction          0x234980 0x22     level 2
    fg_utils_$separate_loop_header_edges     0x235822 0x8E     level 2
    fg_utils_$recompute_ssa_form_for_lr      0x2377A0 0x284    level 2
    fg_utils_$recompute_postnum              0x23743A 0x48     level 2
    fg_utils_$recompute_dominators_and_dfs_lists 0x237482 0x92     level 2
    fg_utils_$make_loops_unconditional       0x235F04 0x30     level 2
    fg_utils_$intervals                      0x235676 0x1AC    level 2
    fg_utils_$insert_join_birthpoint         0x236874 0xA0     level 2
    fg_utils_$init_for_routine               0x234A46 0x2E     level 2
    fg_utils_$generate_join_birthpoint       0x2366F8 0x138    level 2
    fg_utils_$forward_this_block             0x234C3C 0x3C8    level 2
    fg_utils_$forward_empty_blocks           0x235F34 0x238    level 2
    fg_utils_$end_senseless_loops            0x23619E 0x1BC    level 2
    fg_utils_$end_routine                    0x234A74 0x1E     level 2
    fg_utils_$end_compilation                0x234A92 0x2      level 2
    fg_utils_$drop_this_block                0x234AB8 0x184    level 2
    fg_utils_$drop_old_join_birthpoints      0x2372C4 0x124    level 2
    fg_utils_$dominators                     0x236C4A 0x4D6    level 2
    fg_utils_$compute_lr_lifetime            0x237660 0xBC     level 2
    fg_utils_$compute_dfs_lists              0x2354E0 0xA2     level 2
    fg_utils_$begin_compilation              0x2349A2 0x52     level 2
    fg_utils_$add_jbi                        0x236B9C 0x4E     level 2

### `lang2/source/be_com/fga.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    fga_$strip_final_to_entry_fges           0x238112 0x68     level 2
    fga_$compute_asynchronous_paths          0x2380C2 0x50     level 2
    mark_asynchronous_path                   0x23808A 0x38     level 2
    conditionally_asynchronous               0x237CC6 0x3B8    level 2
    analyze_source                           0x237BDC 0xEA     level 2
    fga_$optimize_ap_read_in_return          0x237A88 0xB2     level 2
    utils_ins_$operands_instruction          0x237A60 0x22     level 2
    fga_$end_compilation                     0x237A86 0x2      level 2
    fga_$end_routine                         0x237A84 0x2      level 2
    fga_$process_routine                     0x23817A 0x1B8    level 2
    fga_$begin_compilation                   0x237A82 0x2      level 2

### `lang2/source/be_com/hal.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    hal_$insert_loop_tails                   0x238BD4 0x102    level 2
    bb_is_in_loop                            0x238B9A 0x3A     level 2
    hal_$insert_loop_headers                 0x238B60 0x3A     level 2
    guarantee_header                         0x238A4A 0x116    level 2
    build_basic_block                        0x23899A 0xB0     level 2
    no_path_through_head_in_hammock          0x23879A 0x2C     level 2
    loop_header_safe                         0x238734 0x66     level 2
    bb_inside_loop                           0x238706 0x2E     level 2
    bb_interval                              0x2386EC 0x1A     level 2
    collect_or_test_hammock_contents         0x238616 0xD6     level 2
    build_work_list                          0x238550 0xC6     level 2
    bb_contains_final_call                   0x2384C6 0x8A     level 2
    collect_hammocks                         0x23834C 0x17A    level 2
    zero                                     0x238334 0x18     level 2
    hal_$find_hammocks                       0x2387C6 0x1C2    level 2
    hal_$end_compilation                     0x238D06 0x2      level 2
    hal_$end_routine                         0x238D94 0x1C     level 2
    hal_$process_routine                     0x238D08 0x8C     level 2
    hal_$begin_compilation                   0x238CD6 0x26     level 2

### `lang2/source/be_com/iv.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/iv.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_size.init`
- include `//lang2/source/be_com/utils.ins.pas`

    recompute_for_oli                        0x23FD98 0x1A8    level 2
    get_increment_from_induction             0x23FB60 0x1B4    level 2
    iv_$build_nested_reverse_postorder_lists 0x23FB02 0x5E     level 2
    iv_$locate_induction_variables_at_loop_end 0x23FA6A 0x90     level 2
    iv_$locate_induction_variables_for_basic_block 0x23FA46 0x24     level 2
    iv_$locate_induction_variables_at_loop_start 0x23F9DE 0x68     level 2
    ixt_$process_induction_transformations   0x23F9AC 0x32     level 2
    ixt_$process_primary_induction_variable  0x23F954 0x58     level 2
    ixt_$process_secondary_induction_variable 0x23F5E0 0x374    level 2
    ixt_$instantiate_induction_expr          0x23F054 0x54A    level 2
    ixt_$cleanup_induction_expr              0x23EFD8 0x7C     level 2
    ixt_$cleanup_segment_references          0x23EF5A 0x7E     level 2
    ixt_$replace_induction_expr              0x23EC12 0x348    level 2
    remove_segment_from_operand              0x23EB76 0x9C     level 2
    ixt_$create_increment_instruction        0x23E9FE 0x178    level 2
    ixt_$replace_segment_references          0x23E8B6 0x148    level 2
    ixt_$count_primary_used_fields           0x23E86E 0x48     level 2
    ixt_$mark_primary_used_fields            0x23E7D8 0x96     level 2
    ixt_$clear_primary_used_fields           0x23E7BE 0x1A     level 2
    ixt_$induction_segment_exists            0x23E766 0x58     level 2
    get_secondary_segment                    0x23E754 0x12     level 2
    ixt_$multiply_cost                       0x23E6E6 0x6E     level 2
    ixr_$scan_basic_block_for_induction_expressions 0x23E2B6 0x430    level 2
    ixr_$scan_addressing_mode                0x23E1D0 0xE6     level 2
    ixr_$induction_expression                0x23E14C 0x84     level 2
    ixr_$induction_expr_shifted_loop_invariant 0x23E042 0x10A    level 2
    ixr_$induction_expr_times_loop_invariant 0x23DF3C 0x106    level 2
    ixr_$induction_expr_plus_induction_expr  0x23DD6A 0x1D2    level 2
    ixr_$induction_expr_plus_loop_invariant  0x23DC6E 0xFC     level 2
    operand_is_current_induction_expression  0x23DC0A 0x64     level 2
    ixr_$get_induction_instantiation_from_operand 0x23D9A0 0x216    level 2
    ixr_$create_induction_addr_from_induction_instantiation 0x23D8FE 0xA2     level 2
    ixr_$create_induction_lts_from_induction_instantiation 0x23D852 0xAC     level 2
    ixr_$find_induction_variable             0x23D718 0x13A    level 2
    ixr_$find_induction_expr                 0x23D692 0x86     level 2
    ixr_$find_induction_class                0x23D60C 0x86     level 2
    ixr_$find_current_lts_for_iv             0x23D39A 0x186    level 2
    operand_is_any_induction_expression      0x23D340 0x5A     level 2
    iv_$walk_basic_blocks_in_order           0x23D288 0xB8     level 2
    ivr_$finalize_induction_variables        0x23D238 0x50     level 2
    ivr_$verify_candidate_is_induction_variable 0x23D062 0x1D6    level 2
    ivr_$mark_lifetime_segments_as_induction_variables 0x23CFB2 0x9E     level 2
    apply_to_creating_induction_segments     0x23CEAE 0x104    level 2
    operand_has_same_induction_variable      0x23CE66 0x48     level 2
    ivr_$propagate_induction_into_basic_block 0x23CD10 0x156    level 2
    ivr_$locate_induction_candidates         0x23CBAE 0x162    level 2
    duplicate_increment_information          0x23CB6C 0x42     level 2
    ivr_$propagate_induction_for_lifetime_segment 0x23C850 0x31C    level 2
    propagate_induction_increment            0x23C7AA 0xA6     level 2
    iv_utils_$locate_definition              0x23C3BA 0x90     level 2
    find_definition                          0x23C316 0xA4     level 2
    interval_contains_bb                     0x23C112 0x2E     level 2
    iv_utils_$delete_induction_variable      0x23C028 0xEA     level 2
    iv_utils_$delete_induction_class         0x23BFB0 0x78     level 2
    iv_utils_$delete_induction_expr          0x23BF14 0x9C     level 2
    free_induction_variable                  0x23BF04 0x10     level 2
    create_induction_variable                0x23BE34 0xD0     level 2
    free_induction_class                     0x23BE24 0x10     level 2
    create_induction_class                   0x23BDCC 0x58     level 2
    create_induction_expr                    0x23BD80 0x4C     level 2
    free_induction_expr                      0x23BD70 0x10     level 2
    iv_utils_$delete_induction_addr          0x23BD34 0x3C     level 2
    free_induction_addr                      0x23BD24 0x10     level 2
    iv_utils_$delete_induction_lts           0x23BC64 0xC0     level 2
    free_induction_lts                       0x23BC54 0x10     level 2
    create_induction_lts                     0x23BBE8 0x6C     level 2
    increments_are_equal                     0x23BBAE 0x3A     level 2
    create_operand_from_elaborated_expression 0x23B1F6 0x680    level 2
    add_operand_to_segment                   0x23B16A 0x8C     level 2
    find_last_instruction                    0x23B124 0x46     level 2
    elaborate_expression                     0x23AED4 0x1AA    level 2
    propagate_down_type                      0x23AB78 0x35C    level 2
    first_operand_can_change                 0x23AB0E 0x6A     level 2
    can_encode_as_register                   0x23AACC 0x42     level 2
    propagate_up_cost                        0x23A956 0x176    level 2
    clean_up_additive_canonical_result       0x239828 0x37C    level 2
    operand_offset_difference                0x2397DC 0x4C     level 2
    same_base_operand                        0x239776 0x66     level 2
    create_add_or_sub_expression             0x23974E 0x28     level 2
    iv_utils_$expression_is_zero             0x2396C0 0x1A     level 2
    create_move_expression                   0x2396A0 0x20     level 2
    create_transfer_expression               0x239680 0x20     level 2
    build_multiplier_from_base               0x239438 0xD0     level 2
    canonical_base_node_is_positive          0x23942A 0xE      level 2
    has_canonical_form                       0x239414 0x16     level 2
    get_canonical_remaining_node             0x2393F4 0x20     level 2
    get_canonical_base_node                  0x2393BC 0x38     level 2
    get_canonical_compare_node               0x2392CE 0xEE     level 2
    order_expressions                        0x23916C 0x162    level 2
    free_expression                          0x2390FC 0x14     level 2
    create_induction_addr                    0x2390B0 0x4C     level 2
    alloc_induction_variable                 0x239078 0x38     level 2
    alloc_expression                         0x239040 0x38     level 2
    alloc_induction_class                    0x239008 0x38     level 2
    alloc_induction_expr                     0x238FD0 0x38     level 2
    alloc_induction_addr                     0x238F98 0x38     level 2
    alloc_induction_lts                      0x238F62 0x36     level 2
    zero                                     0x238F3C 0x26     level 2
    operand_is_loop_invariant                0x23C2AC 0x6A     level 2
    lts_is_loop_invariant                    0x23C140 0x16C    level 2
    canonicalize_rsub_expression             0x23A6FA 0x42     level 2
    canonicalize_neg_expression              0x23A5DA 0x120    level 2
    canonicalize_mul_expression              0x23A374 0x266    level 2
    canonicalize_sub_expression              0x239F5C 0x418    level 2
    canonicalize_add_expression              0x239BA4 0x3B8    level 2
    utils_ins_$operands_instruction          0x238DB0 0x22     level 2
    iv_utils_$live_range_from_elaborated_expression 0x23B8EE 0x2C0    level 2
    iv_utils_$elaborate_expression           0x23B07E 0xA6     level 2
    iv_utils_$duplicate_expression           0x23A73C 0xC0     level 2
    iv_utils_$delete_expression              0x239110 0x5C     level 2
    iv_utils_$create_value_expression        0x2395E2 0x30     level 2
    iv_utils_$create_sub_expression          0x239542 0x3A     level 2
    iv_utils_$create_operand_from_expression 0x23B876 0x78     level 2
    iv_utils_$create_operand_expression      0x239642 0x3E     level 2
    iv_utils_$create_neg_expression          0x2395B6 0x2C     level 2
    iv_utils_$create_mul_expression          0x23957C 0x3A     level 2
    iv_utils_$create_lts_expression          0x239612 0x30     level 2
    iv_utils_$create_add_expression          0x239508 0x3A     level 2
    iv_utils_$create_expression_from_lts     0x23C44A 0x278    level 2
    iv_utils_$create_expression_from_operand 0x23C702 0xA8     level 2
    iv_utils_$compare_expressions            0x23A830 0x126    level 2
    iv_utils_$compare_address_expressions    0x23D5A0 0x6C     level 2
    iv_utils_$canonicalize_expression        0x2396DA 0x74     level 2
    iv_$end_compilation                      0x238EE0 0x2      level 2
    iv_$end_routine                          0x238EE2 0x5A     level 2
    iv_$process_routine                      0x23FF80 0x1D2    level 2
    iv_$begin_compilation                    0x238DD2 0xA0     level 2

### `lang2/source/be_com/jbr.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`

    jbr_$end_compilation                     0x240166 0x2      level 2
    jbr_$end_routine                         0x24016A 0x2      level 2
    jbr_$process_routine                     0x240168 0x2      level 2
    jbr_$begin_compilation                   0x240164 0x2      level 2

### `lang2/source/be_com/konst.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/htm.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    update_control_flow_graph                0x241A52 0x11A    level 2
    correct_control_flow_instructions        0x2418EE 0x10C    level 2
    update_constants                         0x241830 0xBE     level 2
    update_constant_operands                 0x2416FE 0x104    level 2
    initialize                               0x2415BA 0x126    level 2
    initialize_queues                        0x24156E 0x4C     level 2
    propagate_constants                      0x2414AA 0xC4     level 2
    bb_with_marked_instrs                    0x241464 0x46     level 2
    propagate_definition                     0x24133A 0xB0     level 2
    mark_reader_instructions                 0x2412BC 0x7E     level 2
    evaluate_instruction                     0x240E0E 0x330    level 2
    can_predict_conditional_branch           0x240CD0 0x13E    level 2
    ip_rel_to_0_ccs_from_dd                  0x240C40 0x90     level 2
    fp_rel_to_0_ccs_from_dd                  0x240C3A 0x6      level 2
    dd_literal_pool_reference                0x240ACC 0x16E    level 2
    dd_from_operand                          0x2409A8 0xBE     level 2
    followable_flow_graph_edge               0x24097A 0x2E     level 2
    newly_reachable_bb                       0x240858 0x122    level 2
    find_fge_operand                         0x2407FA 0x5E     level 2
    evaluate_join_bp                         0x240716 0xBA     level 2
    scan_paths_back_to_jbi_definitions       0x2406AA 0x6C     level 2
    verify_jbis                              0x240642 0x68     level 2
    apply_output_value                       0x2405DE 0x64     level 2
    dd_for_closed_signed_range               0x2405B2 0x2C     level 2
    dd_for_constant                          0x240592 0x20     level 2
    merge_definitions                        0x24044E 0x144    level 2
    enter_dd_in_hash_table                   0x240192 0x270    level 2
    utils_ins_$operands_instruction          0x24016C 0x22     level 2
    konst_$end_compilation                   0x240190 0x2      level 2
    konst_$end_routine                       0x241BC6 0x1E     level 2
    konst_$process_routine                   0x241B6C 0x5A     level 2
    konst_$begin_compilation                 0x24018E 0x2      level 2

### `lang2/source/be_com/life.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    life_$distribute_ltss_to_new_lrs         0x242540 0xCA     level 2
    life_$get_equivalence_class_lr           0x2423A4 0x166    level 2
    life_$union_reg_pair_operands            0x242188 0x188    level 2
    life_$initial_equivalence_classes        0x242080 0x108    level 2
    life_$union_lifetimes                    0x242002 0x7E     level 2
    life_$equivalence_class_parent           0x241FC8 0x3A     level 2
    create_intend_modifies                   0x241F88 0x40     level 2
    create_instrs_intend_modifies            0x241CD6 0x226    level 2
    insert_modifies_for_memory               0x241C0A 0xCC     level 2
    utils_ins_$operands_instruction          0x241BE4 0x22     level 2
    life_$end_compilation                    0x241C08 0x2      level 2
    life_$end_routine                        0x24281C 0x2      level 2
    life_$process_routine                    0x24260A 0x212    level 2
    life_$begin_compilation                  0x241C06 0x2      level 2

### `lang2/source/be_com/lir.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/common/source/exs.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_attributes.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/of_string.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/of_string_length.init`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`
- include `//lang2/source/be_com/lir.pvt.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_size.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/solution_kind.init`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/solution_string.init`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/solution_string_length.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_action.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/build_access.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_arg_loc.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_high_bound.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_kind.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_like_kind.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_low_bound.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_message.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical_lrs.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_physical_ltss.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/lir.pas/h10ed710e.001/lir.dir/build_properties.init`
- include `//lang2/source/be_com/utils.ins.pas`

    add_serialized_lr_operands               0x247D4E 0xAE     level 2
    call_or_svc_argument_register            0x247BDC 0x172    level 2
    prolog_label_for_specific_exception      0x246AFE 0x78     level 2
    create_associated_modify_operand         0x24579C 0x58     level 2
    no_associated_modify_operand             0x245746 0x56     level 2
    note_entry_to_handler_from_runtime       0x245710 0x36     level 2
    convert_to_intend_to_modify              0x244078 0x22     level 2
    build_non_register_reference             0x243F24 0x10A    level 2
    get_lts_in_current_bb                    0x243E2E 0xE0     level 2
    lir_$opt_new_instruction                 0x243C0E 0x184    level 2
    lir_$alloc_live_range                    0x243A1E 0x84     level 2
    add_fge_to_labeled_basic_block           0x2436DE 0xA6     level 2
    get_basic_block                          0x2435AA 0x11E    level 2
    add_instruction_to_basic_block           0x24346A 0x74     level 2
    lir_$get_new_instruction                 0x243398 0x2A     level 2
    copy_build_instruction                   0x24327C 0xBA     level 2
    begin_instruction                        0x242EF4 0x2BA    level 2
    is_volatile_location                     0x242E0C 0x58     level 2
    initialize_physical_solutions            0x242880 0x10E    level 2
    zero                                     0x242868 0x18     level 2
    true_il                                  0x242854 0x14     level 2
    lir_$reinitialize                        0x2482CE 0x6DC    level 2
    lir_$note_target_of_asynchronous_flow    0x243572 0x38     level 2
    lir_$build_operand                       0x24409A 0xF58    level 2
    lir_$complete_top_level_node_inherited_attrs 0x242E7E 0x58     level 2
    lir_$complete_instruction                0x2457F4 0xDCE    level 2
    lir_$get_new_instruction_no_exceptions   0x2433C2 0x40     level 2
    lir_$end_call_or_svc                     0x2482A4 0x2A     level 2
    lir_$emit_call_or_svc                    0x247DFC 0x42C    level 2
    lir_$begin_call_or_svc                   0x247B80 0x5C     level 2
    lir_$common_lhs_rhs_token                0x2474CE 0xA0     level 2
    lir_$disjoint_lhs_and_rhs_tokens         0x2475B2 0x124    level 2
    lir_$begin_fortran_io_sequence           0x247A5E 0xBA     level 2
    lir_$isc_bugcheck                        0x242820 0x1E     level 2
    lir_$mtpr_instruction                    0x247968 0xC8     level 2
    lir_$store_instruction                   0x24771E 0x1D0    level 2
    lir_$mfpr_instruction                    0x2473D8 0xC8     level 2
    lir_$load_instruction                    0x2470EC 0x274    level 2
    lir_$trap_instruction                    0x246C28 0x13A    level 2
    lir_$use_trap_for_exception_raise        0x246BC6 0x62     level 2
    lir_$dispatch_instruction                0x2467B6 0x108    level 2
    lir_$operate_and_branch_instruction      0x2469F4 0xCE     level 2
    lir_$branch_instruction                  0x24691E 0xA6     level 2
    lir_$field_instruction                   0x246FAE 0xDC     level 2
    lir_$simple_instruction                  0x246D90 0x1EE    level 2
    lir_$break_basic_block                   0x243BE8 0x26     level 2
    lir_$label                               0x2437AC 0xF4     level 2
    lir_$end_routine                         0x2489AA 0xB6     level 2
    lir_$optimizer_new_n_opr_instr           0x243DD8 0x2C     level 2
    lir_$strip_may_gen_exception             0x248A60 0x1E     level 2
    lir_$optimizer_new_instruction           0x243E04 0x2A     level 2
    lir_$new_basic_block                     0x2434DE 0x7E     level 2
    lir_$new_instruction                     0x243B8E 0x5A     level 2
    lir_$add_flow_graph_edge                 0x243402 0x68     level 2
    lir_$new_live_range_fp_reg_pair          0x243B0C 0x40     level 2
    lir_$new_live_range_fp_reg               0x243AEC 0x20     level 2
    lir_$new_live_range_ip_reg               0x243ACC 0x20     level 2
    lir_$new_live_range_for_kind             0x243B4C 0x42     level 2
    lir_$new_live_range                      0x243AB0 0x1C     level 2
    lir_$new_lifetime_segment                0x2439B8 0x66     level 2
    lir_$new_label                           0x243784 0x28     level 2
    lir_$free_lifetime_segment               0x2438CE 0x7E     level 2
    lir_$begin_compilation                   0x242994 0x344    level 2

### `lang2/source/be_com/lir_main.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/common/source/exs.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`
- include `//lang2/source/be_com/lir.pvt.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    epilog_load_instruction                  0x24B4BE 0x120    level 2
    epilog_load_pair_instruction             0x24B42E 0x90     level 2
    add_epilog_register_write                0x24B346 0xE8     level 2
    complete_epilog_load                     0x24B298 0xAE     level 2
    prolog_store_instruction                 0x24B0B4 0x1A6    level 2
    add_prolog_register_read                 0x24B03A 0x7A     level 2
    complete_prolog_store                    0x24AF62 0xD8     level 2
    pick_register                            0x24AEE8 0x7A     level 2
    build_fp_reg_pair_odd_operand            0x24A6F8 0x4E     level 2
    by_branch_prologs_for_handler            0x24A508 0x150    level 2
    fix_silly_register_candidates            0x24A1E0 0x2DA    level 2
    make_xsb_a_register_candidate            0x249592 0x7E     level 2
    formal_local_transfer_setup              0x248B1E 0x4BA    level 2
    clean_up_canned_inherited                0x248B00 0x1E     level 2
    top_level_inherited_attributes           0x248AD2 0x2E     level 2
    count_registers                          0x248A98 0x3A     level 2
    zero                                     0x248A80 0x18     level 2
    lir_main_$add_ip_reg_physical_lr         0x249086 0x80     level 2
    lir_main_$add_live_range                 0x249020 0x66     level 2
    lir_main_$reinit_physical_regs           0x249106 0x182    level 2
    lir_main_$handler_reentry                0x24A124 0xBC     level 2
    lir_main_$entry                          0x249610 0xAC4    level 2
    lir_main_$save_and_restore_code          0x24B618 0xA20    level 2
    lir_main_$build_initial_epilog           0x24A746 0x74C    level 2
    lir_main_$begin_routine                  0x249288 0x30A    level 2

### `lang2/source/be_com/lir_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang2/source/isc/isc_var_externs.ins.pas`
- include `//lang2/source/be_com/lir.pvt.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/move_opcode.init`
- include `//lang2/source/be_com/utils.ins.pas`

    nolonger_exposed                         0x24D5DC 0x7E     level 2
    add_new_operand                          0x24D2C4 0x88     level 2
    assign_spill_id                          0x24CFC4 0x30     level 2
    lir_utils_$flesh_out_new_load_or_store   0x24D34C 0x288    level 2
    lir_utils_$create_preference_move        0x24C14E 0xFC     level 2
    lir_utils_$add_memory_home               0x24D0F2 0x18C    level 2
    lir_utils_$add_lts_after_lts             0x24C2A8 0x6A     level 2
    lir_utils_$add_lts_to_lr                 0x24C24A 0x5E     level 2
    lir_utils_$trans_insert_move             0x24C312 0x912    level 2
    lir_utils_$find_mate_operand             0x24E5F8 0x26     level 2
    lir_utils_$get_next_async_exposed_lr     0x24D65A 0xF4     level 2
    lir_utils_$get_new_memory_home           0x24D024 0xCE     level 2
    lir_utils_$fix_store_through_lrs         0x24D808 0xC8E    level 2
    new_db_lts                               0x24D7CC 0x3C     level 3
    lir_utils_$excise_inst                   0x24C0FC 0x52     level 2

### `lang2/source/be_com/lst.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/cvfp.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_mnemonic.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/instr_mnemonic_length.init`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/register_letter.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_suffix.init`

    lst_$prasm_display_code_cell             0x25023E 0x762    level 2
    lst_$prasm_lhs                           0x2501F6 0x48     level 2
    lst_$prasm_add_condition_codes           0x2501B2 0x3C     level 2
    lst_$prasm_add_bitfield                  0x250158 0x5A     level 2
    lst_$prasm_address_mode                  0x24FFEC 0x13C    level 2
    lst_$prasm_address_mode_suffix           0x24FEAE 0x102    level 2
    lst_$prasm_operand_a                     0x24FE1C 0x92     level 2
    lst_$branch_destination                  0x24F866 0x96     level 2
    lst_$address_mode_a_operand              0x24F7F6 0x70     level 2
    lst_$display_operand                     0x24F4E0 0x234    level 2
    lst_$add_register_name                   0x24F370 0x166    level 2
    tab_to_column                            0x24E9FA 0x3C     level 2
    add_hex                                  0x24E992 0x68     level 2
    add_formatted_hex                        0x24E944 0x4E     level 2
    add_offset                               0x24E908 0x3C     level 2
    add_formatted_integer                    0x24E7D2 0x136    level 2
    add_integer                              0x24E776 0x5C     level 2
    add_small_integer                        0x24E720 0x56     level 2
    add_string                               0x24E6CA 0x56     level 2
    add_2_digits                             0x24E676 0x54     level 2
    add_2_chars                              0x24E63A 0x3C     level 2
    add_char                                 0x24E620 0x1A     level 2
    lst_$prtlit                              0x24F8FC 0x490    level 2
    lst_$end_compilation                     0x24EAE4 0x2      level 2
    lst_$new_line                            0x24EAE6 0x22     level 2
    lst_$display_table                       0x251C92 0xD0     level 2
    lst_$display_literal                     0x251796 0x326    level 2
    lst_$display_code_cell                   0x250A0A 0xD28    level 2
    lst_$procedure_entry                     0x24ED94 0x50A    level 2
    lst_$program_section                     0x24EC88 0xF8     level 2
    lst_$set_data_section                    0x24EB98 0xD4     level 2
    lst_$define_data_section                 0x24EB0A 0x84     level 2
    lst_$begin_compilation                   0x24EA36 0xAE     level 2

### `lang2/source/be_com/mmt.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/mmt.pvt.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    mmt_$points_for_good_behavior            0x254DC4 0x154    level 2
    mmt_$allocate_ltss_to_refs               0x254BF6 0x1CE    level 2
    build_real_mmt_seq                       0x254B54 0xA2     level 2
    get_new_lts                              0x254ADC 0x78     level 2
    mmt_$insert_inter_bb_seq                 0x254366 0x6D8    level 2
    update_active_tokens                     0x25430A 0x5C     level 2
    remove_existing_relationship             0x2541F6 0x114    level 2
    mmt_$insert_intra_bb_seq                 0x254148 0xAE     level 2
    mmt_$allocate_tokens                     0x253962 0x40C    level 2
    mmt_seq_is_not_arg_blk_seq               0x25388C 0x60     level 2
    get_single_alias_for_lr                  0x25372A 0x11A    level 2
    fill_in_token_id_map                     0x25361E 0xD6     level 2
    enter_equiv_token                        0x2535EC 0x32     level 3
    enter_token                              0x2535C8 0x24     level 3
    get_token                                0x2534E6 0xBC     level 2
    get_hashed_token                         0x25335A 0x144    level 2
    get_token_for_call                       0x253236 0x124    level 2
    build_related                            0x252CA4 0x55E    level 2
    classes_related_if_async                 0x252C28 0x7C     level 2
    classes_related_if_uplevel_or_ref        0x252BB4 0x74     level 2
    classes_related                          0x252B3E 0x76     level 2
    insert_equiv_in_main_list                0x252AB6 0x88     level 2
    compute_exposure_in_asynchronous_path    0x25293C 0x17A    level 2
    remove_waste                             0x252900 0x3C     level 2
    remove_duplicate_tokens                  0x252788 0x178    level 2
    consider_merging_token                   0x252738 0x50     level 2
    record_routines_memory_usage             0x252438 0x10C    level 2
    allocate_initialize                      0x25233C 0xFC     level 2
    dump_bb_bit_vectors                      0x2521DC 0xFC     level 2
    dump_related_vectors                     0x251E00 0x2BC    level 2
    zero                                     0x251DEA 0x16     level 2
    utils_ins_$operands_instruction          0x251DC8 0x22     level 2
    mmt_$simplify_tokens_in_bb               0x252544 0x1BE    level 2
    mmt_$insert_blocks_intra_bb_seq          0x253DA8 0x3A0    level 2
    mmt_$allocate_scratch_vectors            0x2538EC 0x76     level 2
    mmt_$end_compilation                     0x2551D6 0x2      level 2
    mmt_$end_routine                         0x2551D4 0x2      level 2
    mmt_$process_routine                     0x254FFC 0x1A6    level 2
    mmt_$begin_compilation                   0x254F18 0xB2     level 2

### `lang2/source/be_com/mmt_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/mmt.pvt.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    count_and_bind_complex_lrs               0x257824 0x7A     level 2
    fill_in_ltss                             0x2572C6 0x46E    level 2
    insert_mmt_seqs                          0x256F6A 0x35C    level 2
    bind_new_tokens_to_operands              0x256D10 0x21A    level 2
    free_mmt_seqs_and_ltss                   0x256AB8 0x258    level 2
    discover_relationships                   0x256636 0x40A    level 2
    mark_related_references                  0x256516 0x120    level 2
    inform_about_relationships               0x25642A 0xEC     level 2
    ids_related                              0x2563A0 0x8A     level 2
    compared_already                         0x256300 0xA0     level 2
    allocate_descriptor                      0x256054 0x1AE    level 2
    disp_known                               0x255C68 0x140    level 2
    get_base_and_index                       0x255C04 0x64     level 2
    build_mmt_seq_instr                      0x255534 0x42     level 2
    add_operand                              0x2554A8 0x66     level 2
    mmt_utils_$get_mmt_seq_instruction       0x2553E4 0xC4     level 2
    mmt_utils_$save_mmt_seq_instruction      0x2553BA 0x2A     level 2
    mmt_utils_$mark_lr_for_removal           0x2552E0 0x16     level 2
    mmt_utils_$save_unneeded_lrs             0x25526C 0x74     level 2
    mmt_utils_$save_mem_lr                   0x255252 0x1A     level 2
    zero                                     0x2551FA 0x16     level 2
    utils_ins_$operands_instruction          0x2551D8 0x22     level 2
    mmt_utils_$set_address_comparison_function 0x25601A 0x3A     level 2
    mmt_utils_$init_for_routine              0x255212 0x3C     level 2
    mmt_utils_$end_compilation               0x255250 0x2      level 2
    mmt_utils_$end_routine                   0x25524E 0x2      level 2
    mmt_utils_$begin_compilation             0x255210 0x2      level 2
    mmt_utils_$analyze_blocks                0x257CEC 0x74     level 2
    mmt_utils_$analyze_one_bb                0x25789E 0x3CE    level 2
    mmt_utils_$addr_compare                  0x255DA8 0x272    level 2
    mmt_utils_$mmt_seq_emit                  0x255576 0x34E    level 2
    mmt_utils_$mmt_seq_add_tokens_from_instr 0x255A0C 0x84     level 2
    mmt_utils_$mmt_seq_add_tokens_from_bv    0x255A90 0x74     level 2
    mmt_utils_$mmt_seq_add_token             0x255942 0x98     level 2
    mmt_utils_$lr_is_for_memory              0x255364 0x56     level 2
    mmt_utils_$get_mem_lr                    0x2552F6 0x6E     level 2
    mmt_utils_$can_combine_mmt_seqs          0x255B04 0x100    level 2

### `lang2/source/be_com/oli.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/iv.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    unroll_for_alignment                     0x261170 0x1E     level 2
    mem_refs_good_for_align_unroll           0x26116C 0x4      level 2
    overlap_loop_iterations                  0x261128 0x44     level 2
    init_depend                              0x26111E 0xA      level 2
    software_pipeline                        0x261054 0xCA     level 2
    restore_precedence                       0x261020 0x34     level 2
    decrease_precedence                      0x260F9C 0x84     level 2
    increase_recurrence_precedence           0x260F5E 0x3E     level 2
    increase_precedence                      0x260EE0 0x7E     level 2
    clear_walk_marks                         0x260E6E 0x72     level 2
    recurrence_constraints_ok                0x260DE0 0x8E     level 2
    find_loop_instrs                         0x260CF4 0xEC     level 2
    build_pipelined_loop                     0x260C3C 0xB8     level 2
    adjust_final_induction_vars              0x260C3A 0x2      level 2
    fill_in_tail                             0x260B4A 0xF0     level 2
    move_from_body_to_tail                   0x260AC4 0x86     level 2
    mark_buckets                             0x260A52 0x72     level 2
    build_bbs_and_fges                       0x260850 0x202    level 2
    copy_to_end_of                           0x26061E 0x232    level 2
    add_reduction_partial_sums               0x2603CE 0x250    level 2
    reduce_partial_sums                      0x2600DE 0x2F0    level 2
    materialize_induction_variable_increments 0x25FE74 0x26A    level 2
    restore_induction_vars                   0x25FB04 0x370    level 2
    adjust_induction_vars                    0x25F64A 0x4AC    level 2
    find_other_addend                        0x25F5BA 0x90     level 2
    adds_unscaled_loop_invariant             0x25F4D4 0xE6     level 2
    post_adds_a_loop_invariant_to            0x25F3F4 0xE0     level 2
    modify_operand                           0x25F258 0x19C    level 2
    generate_birthpoints                     0x25EDB6 0x4A2    level 2
    generate_ltss                            0x25ECC6 0xF0     level 2
    generate_control_flow_instructions       0x25E654 0x672    level 2
    generate_jumps                           0x25E57A 0xDA     level 2
    generate_jump                            0x25E4EA 0x90     level 2
    fill_in_live_ranges                      0x25E046 0x466    level 2
    get_write_lr                             0x25DAB8 0x58E    level 2
    find_new_intend_to_modify_operand        0x25D978 0x140    level 2
    get_new_lr_pair                          0x25D954 0x24     level 2
    precedes_in_schedule                     0x25D90E 0x46     level 2
    get_exposed_operand                      0x25D50C 0x402    level 2
    copys_in_prolog                          0x25D496 0x76     level 2
    get_induction_variable_adjustment        0x25CFE2 0x4B4    level 2
    link_final_induction_vars                0x25CECA 0xD2     level 2
    link_lrs                                 0x25CCCC 0x1FE    level 2
    build_final_lr_in_col_list               0x25CC16 0xB6     level 2
    record_final_lr_in_column                0x25CB70 0xA6     level 2
    find_final_lr_in_column                  0x25CB2A 0x46     level 2
    get_live_exposed_lr                      0x25CA4E 0xDC     level 2
    record_live_exposed_lr                   0x25C994 0x82     level 2
    un_five_oppify                           0x25C91E 0x76     level 2
    five_oppify                              0x25C79C 0x182    level 2
    add_instruction_in_sequence              0x25C6BA 0xE2     level 2
    enlist_sorted                            0x25C5CE 0xEC     level 2
    build_fan_out_seq_instrs                 0x25C3F2 0x1DC    level 2
    build_fan_in_seq_instr                   0x25C22A 0x1C8    level 2
    build_bookkeeping_structures             0x25C108 0x122    level 2
    get_materialized_in_re_duction_lr        0x25BE68 0x258    level 2
    consumed_in_downstream_bb                0x25BE02 0x66     level 2
    exposed_at                               0x25BDC0 0x42     level 2
    operand_gets_materialized_value          0x25BC08 0x16E    level 2
    int_const_in_fp_reg                      0x25BA5C 0x1AC    level 2
    excess_register_pressure                 0x25B6B0 0x3AC    level 2
    schedule                                 0x25B3FA 0x2B6    level 2
    ticks_to_most_remote_consumer            0x25B12C 0x2CE    level 2
    find_data_flow_constraints               0x25AEDC 0x250    level 2
    schedule_instr                           0x25ACB8 0x224    level 2
    find_open_slot                           0x25A44A 0x86E    level 2
    swap_inputs                              0x25A35E 0xEC     level 2
    decrement_ienable_count                  0x25A300 0x1E     level 2
    assign_enable_counts                     0x25A18A 0x176    level 2
    iteration_interval                       0x259FB8 0x1D2    level 2
    max_recurrence_slope                     0x259F56 0x62     level 2
    is_5op_candidate                         0x259BDC 0x33C    level 2
    can_join                                 0x259B7A 0x62     level 2
    parity_matches                           0x259B22 0x58     level 2
    modified                                 0x259AFE 0x24     level 2
    analyze_dependencies                     0x259A64 0x9A     level 2
    analyze_memory_references                0x259A48 0x1C     level 2
    recurrence_test                          0x25963C 0xFA     level 2
    banarjees_test                           0x25954E 0xEE     level 2
    constant_trip_count                      0x2594F8 0x56     level 2
    slope_test                               0x259446 0xB2     level 2
    gcd_test                                 0x2593BC 0x8A     level 2
    simple_test                              0x2592D4 0xE8     level 2
    find_data_flow_paths                     0x2592A6 0x2E     level 2
    data_flow_paths                          0x259156 0x150    level 2
    delay_along_data_flow_path               0x2590BE 0x98     level 2
    record_recurrence                        0x259058 0x66     level 2
    iv_expressions_differ_by_const           0x258FEC 0x6C     level 2
    induction_initial_value_of               0x258E90 0x15C    level 2
    induction_increment_of                   0x258D86 0x10A    level 2
    is_exposed_reduction                     0x258CC0 0xC6     level 2
    create_reduction_variable                0x258C26 0x9A     level 2
    reduction_class_of                       0x258A1E 0x208    level 2
    mem_ref_via_non_const_induction_variable 0x258940 0xDE     level 2
    size_and_shape_ok                        0x25885C 0xE4     level 2
    assign_sequence_numbers                  0x25883E 0x1E     level 2
    next_inner_loop                          0x2587EA 0x54     level 2
    first_innermost_loop                     0x2587C8 0x22     level 2
    dequeue_enabled_instruction              0x25876A 0x24     level 2
    enqueue_enabled_instruction              0x2586E4 0x86     level 2
    init_sched                               0x258622 0xC2     level 2
    get_ip_zero                              0x2584D0 0x152    level 2
    get_sp_zero                              0x258362 0x16E    level 2
    get_dp_zero                              0x258184 0x1D6    level 2
    add_instr_end_of_prolog_inits            0x2580BA 0xCA     level 2
    init_software_pipelining                 0x258058 0x62     level 2
    reverse_iteration_numbers                0x258030 0x28     level 2
    build_sched_array                        0x257ED8 0x158    level 2
    new_seq_num                              0x257E7E 0x5A     level 2
    fu_of                                    0x257E0E 0x70     level 2
    is_exposed_or_produced_by_jbi            0x257DC8 0x46     level 2
    gcd                                      0x257D98 0x30     level 2
    zero                                     0x257D82 0x16     level 2
    utils_ins_$operands_instruction          0x257D60 0x22     level 2
    oli_$compare_memory_references           0x259736 0x312    level 2
    decrement_lenable_count                  0x25A31E 0x40     level 2
    oli_$end_compilation                     0x2587C6 0x2      level 2
    oli_$end_routine                         0x2612A0 0x2      level 2
    oli_$process_routine                     0x26118E 0x112    level 2
    oli_$begin_compilation                   0x25878E 0x24     level 2

### `lang2/source/be_com/post.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/common/source/exs.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    post_$fix_mem_ref_then_call_bug          0x266862 0x262    level 2
    mem_ref_then_call_infected_on_exit       0x2667A4 0xBE     level 2
    post_$fix_ldcc_bug                       0x266508 0x272    level 2
    post_$fix_pos_bug                        0x26628C 0x224    level 2
    get_safe_instr                           0x266222 0x6A     level 2
    emergency_nop                            0x2661B0 0x72     level 2
    post_$isolate_unneeded                   0x2660A0 0xFA     level 2
    post_$new_bb_for_shadow_true             0x265D18 0x334    level 2
    post_$sequential_flow                    0x2656B4 0x536    level 2
    post_$branch_shadow_true                 0x2650CE 0x53C    level 2
    post_$split_back_edge_target             0x264D84 0x2D4    level 2
    post_$rotate_loop_header                 0x264C58 0x114    level 2
    post_$forward_empty_block                0x264A3E 0x1BC    level 2
    safe_to_forward_jump_through_ip_reg      0x26499E 0xA0     level 2
    post_$branch_shadow_always               0x264806 0x17E    level 2
    post_$call_shadows                       0x264684 0x158    level 2
    post_$reschedule_spill_loads             0x264114 0x53A    level 2
    post_$sprinkle_mfnextcc                  0x263A7A 0x602    level 2
    find_ip_slot_and_insert_instr            0x263994 0xE6     level 2
    fill_er_up                               0x26392C 0x68     level 2
    block_is_only_const_ip_move              0x26385C 0xD0     level 2
    post_$fill_ipccnop                       0x263668 0x1C8    level 2
    ipccnop_shuffle_trapcc                   0x2633E6 0x26C    level 2
    ipccnop_with_branches                    0x262E90 0x53C    level 2
    instr_can_be_moved_along_all_edges       0x262D96 0xFA     level 2
    need_copy_in_this_bb                     0x262D0C 0x8A     level 2
    get_insertion_point_and_conflicts        0x262B14 0x1F8    level 2
    add_exit_active_conflicts                0x262AA2 0x72     level 2
    copy_instr_to_new_bb                     0x2629D4 0xCE     level 2
    move_bundle_to_new_bb                    0x26291E 0xB6     level 2
    can_steal_bundle_from_bb                 0x26279E 0x180    level 2
    get_full_conflicts                       0x26273A 0x64     level 2
    post_$sprinkle_fpquiesce                 0x262554 0x18E    level 2
    post_$initialize                         0x261CAE 0x6D0    level 2
    instrs_are_identical                     0x261B6A 0x144    level 2
    insert_instruction                       0x261ADE 0x8C     level 2
    delete_instruction                       0x261A5E 0x80     level 2
    interval_of_target_operand               0x261A32 0x2C     level 2
    interval_of_basic_block                  0x261A20 0x12     level 2
    droppable_jump_addr                      0x261990 0x58     level 2
    flush_this_block                         0x2618EA 0x6E     level 2
    rebuild_successor_list                   0x2618BA 0x30     level 2
    delete_successor_list                    0x26185A 0x60     level 2
    swap_bundles                             0x2617E8 0x72     level 2
    next_bundle                              0x2617AA 0x3E     level 2
    pass_bundle                              0x26170C 0x9E     level 2
    check_register_conflicts                 0x261476 0x250    level 2
    clear_conflicts                          0x261452 0x24     level 2
    check_conflicts_for_interaction          0x2613DE 0x74     level 2
    flush_labels                             0x2613A6 0x38     level 2
    get_prev_needed_inst                     0x26138A 0x1C     level 2
    get_needed_inst                          0x26136E 0x1C     level 2
    bit_vector_clear                         0x26132A 0x44     level 2
    bit_vector_set                           0x2612E8 0x42     level 2
    bit_vector_test                          0x2612B2 0x36     level 2
    trace_bit_vectors                        0x2612B0 0x2      level 2
    trace_pass_finish                        0x2612AE 0x2      level 2
    trace_block_exit                         0x2612AC 0x2      level 2
    trace_message                            0x2612AA 0x2      level 2
    trace_instruction                        0x2612A8 0x2      level 2
    trace_block_entry                        0x2612A6 0x2      level 2
    trace_pass_start                         0x2612A4 0x2      level 2
    post_$end_compilation                    0x266C56 0x2      level 2
    post_$end_routine                        0x266C3A 0x1C     level 2
    post_$process_routine                    0x266B34 0x106    level 2
    post_$begin_compilation                  0x266AE8 0x36     level 2

### `lang2/source/be_com/ra.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/be_com/ra.pvt.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    ra_$spill_zero_cost_lrs                  0x26D51C 0xF4     level 2
    ra_$accumulate_true_writes               0x26D380 0x19C    level 2
    ra_$relocate_automatic_storage           0x26D2F8 0x88     level 2
    ra_$assign_registers                     0x26C772 0x982    level 2
    ra_$try_opening_another_register         0x26C640 0x132    level 2
    ra_$pick_spill_lr                        0x26C594 0xAC     level 2
    ra_$spill_lr                             0x26C48A 0x10A    level 2
    ra_$zero_closure_next_fields             0x26C46E 0x1C     level 2
    ra_$close_live_range_preferences         0x26C3D4 0x9A     level 2
    ra_$open_registers                       0x26C162 0x272    level 2
    ra_$combine_with_sf                      0x26C014 0xD2     level 2
    ra_$determine_available_registers        0x26BD72 0x2A2    level 2
    ra_$count_available_registers            0x26BCE4 0x8E     level 2
    ra_$open_another_ip_register             0x26BC60 0x84     level 2
    ra_$open_another_fp_register             0x26B9C8 0x298    level 2
    ra_$extra_registers_needed               0x26B8F2 0xD6     level 2
    ra_$collapse_conflict_graph              0x26AE56 0x760    level 2
    sort_ap_table                            0x26AD22 0x134    level 2
    pick_uwork_victim                        0x26AC88 0x9A     level 2
    pick_uwork_candidate                     0x26AC2E 0x5A     level 2
    ra_$remove_lr_from_graph                 0x26AB4A 0xE4     level 2
    remove_lr_from_current_work_list         0x26AACC 0x7E     level 2
    enter_lr_in_appropriate_work_list        0x26A9CE 0xFE     level 2
    ra_$release_rws_storage                  0x269662 0x2C     level 2
    ra_$create_true_aversions                0x269560 0xB2     level 2
    ra_$possible_aversions                   0x269362 0x174    level 2
    ra_$fill_protected_lr_pipe               0x2692D4 0x8E     level 2
    ra_$protected_final_lrs_this_bb          0x26920C 0xC8     level 2
    ra_$drop_if_now_dead                     0x269016 0x1D6    level 2
    ra_$protect_lr_for_n_ticks               0x268F60 0x8C     level 2
    ra_$unlink_protected_lr                  0x268E1C 0xC2     level 2
    ra_$advance_one_clock_tick               0x268D34 0xB0     level 2
    ra_$call_or_svc_fp_clobbers              0x268C60 0xD4     level 2
    ra_$call_or_svc_ip_clobbers              0x268BFC 0x64     level 2
    process_call_or_svc_clobbers             0x268B98 0x64     level 2
    ra_$enter_architectural_conflict         0x268B66 0x32     level 2
    ra_$enter_conflicts                      0x268AF0 0x76     level 2
    ra_$new_conflict                         0x2689D4 0x11C    level 2
    ra_$enter_preference                     0x268944 0x90     level 2
    ra_$enter_a_p                            0x2687DE 0x10C    level 2
    ra_$lookup_a_p                           0x268748 0x96     level 2
    ra_$lrs_already_conflict                 0x268528 0x220    level 2
    ra_$new_simple_id                        0x268474 0x6C     level 2
    ra_$init_descriptor                      0x268334 0xC8     level 2
    ra_$calc_canonical_desc_bit              0x268298 0x5E     level 2
    ra_$initialize_routine                   0x267C72 0x53E    level 2
    init_complex                             0x267C4C 0x26     level 2
    ra_$db_was_referenced                    0x267B4C 0xD6     level 2
    ra_$allocate_stack_frame                 0x2678D4 0x246    level 2
    ra_$initialize_basic_block               0x2672A2 0x566    level 2
    lr_safely_unconsumed                     0x267000 0x48     level 2
    ra_$process_operand_on_this_pass         0x266F78 0x88     level 2
    get_lr_equivalence_class_parent          0x266EB8 0x84     level 2
    ra_$initialize_lr                        0x266E32 0x86     level 2
    zero                                     0x266C7A 0x16     level 2
    utils_ins_$operands_instruction          0x266C58 0x22     level 2
    ra_$clean_bb_and_init_bit_vectors        0x267048 0x25A    level 2
    ra_$build_conflict_graph                 0x2696C2 0x1000   level 2
    ra_$end_compilation                      0x266E30 0x2      level 2
    ra_$end_routine                          0x26DF22 0x2      level 2
    ra_$process_routine                      0x26D610 0x6D0    level 2
    ra_$begin_compilation                    0x266C90 0x192    level 2

### `lang2/source/be_com/ra_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang2/source/isc/isc_lir.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas`
- include `//lang2/source/isc/isc_attribute_records.ins.pas`
- include `//moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas`
- include `//lang2/source/be_com/lir.pvt.pas`
- include `//lang2/source/be_com/ra.pvt.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    fill_intend_modify                       0x270E6C 0x16     level 2
    no_reg_pair_problem                      0x270E2E 0x3E     level 2
    choose_store_position                    0x270ABE 0x370    level 2
    link_other_readers                       0x2708FC 0x1C2    level 2
    find_modify_opr                          0x270818 0x94     level 2
    rebuild_db_exposed_lts_list              0x2707E4 0x34     level 2
    break_loops_from_spill_victim            0x27033A 0x46A    level 2
    break_one_loop                           0x2701B8 0x182    level 2
    find_best_dom_bb                         0x27013C 0x7C     level 2
    attach_lts_list_to_new_lr                0x27011A 0x22     level 2
    look_for_lts                             0x2700D0 0x4A     level 2
    pick_instruction                         0x26FF5E 0xF2     level 2
    get_new_mate_lts                         0x26FEDC 0x82     level 2
    find_mate_lts                            0x26FE44 0x6E     level 2
    rematerialize_result                     0x26FAA2 0x2EC    level 2
    get_new_spill_lts                        0x26FA82 0x20     level 2
    get_new_spill_lr                         0x26F9D6 0xAC     level 2
    choose_spill_victims                     0x26F3C8 0xC0     level 2
    compute_dominating_definitions           0x26F362 0x66     level 2
    drop_unneeded_stores                     0x26F2D0 0x92     level 2
    coalesce_spill_victims                   0x26F0E8 0x1E8    level 2
    spill_around_hammocks                    0x26EF88 0x160    level 2
    enclosing_intervals_are_hammocks         0x26EF38 0x50     level 2
    spill_something                          0x26EE12 0x126    level 2
    choose_spill_cost                        0x26EC9A 0x178    level 2
    initialize_hammock_data                  0x26EB86 0x114    level 2
    assign_bit_vectors_to_hammocks           0x26EB14 0x72     level 2
    count_hammocks                           0x26EADE 0x36     level 2
    compute_pass_through                     0x26E932 0x14E    level 2
    compute_high_level_pass_through          0x26E764 0x17C    level 2
    spill_the_victims                        0x26E468 0x2B2    level 2
    get_instr_and_build_address_mode         0x26E182 0x2E6    level 2
    get_memory_token                         0x26E042 0x140    level 2
    rws_alloc                                0x26DF68 0x2E     level 2
    init                                     0x26DF4E 0x1A     level 2
    utils_ins_$operands_instruction          0x26DF24 0x22     level 2
    ra_utils_$spill_pass_through_lrs         0x26F488 0x266    level 2
    ra_utils_$init_for_routine               0x26DF48 0x2      level 2
    ra_utils_$end_compilation                0x26DF4C 0x2      level 2
    ra_utils_$end_routine                    0x26DF4A 0x2      level 2
    ra_utils_$begin_compilation              0x26DF46 0x2      level 2
    ra_utils_$rematerialize                  0x26F6EE 0x2E8    level 2
    ra_utils_$compute_complex_lifetimes      0x26DFC0 0x82     level 2
    ra_utils_$add_spill_code                 0x270F0C 0xD5E    level 2
    new_db_lts                               0x270E82 0x4E     level 3

### `lang2/source/be_com/sanity.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    check_lts                                0x271EC4 0x16A    level 2
    utils_ins_$operands_instruction          0x271D30 0x22     level 2
    sanity_$check_entire_routine             0x2721B4 0xD76    level 2
    sanity_$repair_lts_properties            0x271D52 0xF4     level 2
    lir_utils_$sanity_check                  0x273C6A 0x24     level 2
    lir_utils_$repair_lts_properties         0x273C46 0x24     level 2

### `lang2/source/be_com/sched.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/call_conv.ins.pas`
- include `//lang/common/source/exs.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/fp_registers_busy.init`
- include `//lang2/source/be_com/utils.ins.pas`

    drop_unneeded_instructions               0x278F9C 0x6E     level 2
    pass2                                    0x278900 0x5A6    level 2
    select_first_instruction                 0x278606 0x290    level 3
    only_final_call_and_seq                  0x2785BE 0x48     level 3
    final_p2_instr_update                    0x2783F2 0x1CC    level 2
    generate_stall_cycle                     0x2783D8 0x1A     level 2
    fit_instr                                0x277C46 0x5A6    level 2
    make_into_rmw_and_combine_lts            0x277A42 0x18A    level 2
    canonicalize_existing_rmw                0x27792E 0x9E     level 2
    swap_operands                            0x27784E 0xE0     level 3
    fix_even_odd_property                    0x27781C 0x32     level 2
    instr_would_fit                          0x2774F4 0x328    level 2
    can_be_5opified                          0x277262 0x252    level 2
    get_operand_p_p                          0x277132 0xB8     level 2
    can_make_into_rmw_and_combine_lts        0x27704E 0xE4     level 2
    instr_would_stall                        0x276F90 0xBE     level 2
    test_p2_lock                             0x276B3E 0x346    level 2
    test_p2_call_lock                        0x276474 0x5D8    level 2
    all_inputs_available                     0x2763A0 0xD4     level 2
    undo_p2_lock_test                        0x2762DA 0xC6     level 2
    init_p2_instr_update                     0x2761CA 0x110    level 2
    p2_process_lts                           0x275E0A 0x1F6    level 2
    pass1                                    0x27549C 0x642    level 2
    remove_lts_from_final_list               0x27545A 0x42     level 2
    register_pressure                        0x275382 0xD8     level 2
    test_p1_lock                             0x274FA4 0x33C    level 2
    test_p1_call_lock                        0x2749A4 0x468    level 2
    undo_p1_lock_test                        0x274936 0x6E     level 2
    test_p1_trapcc_lock                      0x274824 0xD8     level 2
    instr_ok_as_trapcc_driver                0x274758 0xCC     level 2
    p1_touch_segment                         0x2745B4 0x138    level 2
    p1_initial_touch_instruction             0x274412 0x102    level 2
    p1_setup_lts                             0x274376 0x6C     level 2
    p1_activate                              0x274308 0x34     level 2
    p2_temp_act_instr                        0x2742F0 0x18     level 2
    promote_p2_temp_actives                  0x27425C 0x54     level 2
    exit_active                              0x274234 0x28     level 2
    check_clobbered_registers                0x274152 0xE2     level 2
    enqueue_instruction                      0x274024 0xCE     level 2
    walker_advance_to_next_item              0x274004 0x20     level 2
    walker_excise_current_item               0x273FAE 0x56     level 2
    walker_initialize                        0x273FA0 0xE      level 2
    get_phys_lr_num                          0x273F66 0x3A     level 2
    sched_$collect_memory_and_cc_properties  0x273CE0 0x242    level 2
    fix_instr_prev_ptrs                      0x273CB2 0x2E     level 2
    utils_ins_$operands_instruction          0x273C90 0x22     level 2
    sched_$end_compilation                   0x27900C 0x2      level 2
    sched_$end_routine                       0x27900E 0x2      level 2
    sched_$process_routine                   0x279010 0x152    level 2
    sched_$begin_compilation                 0x27900A 0x2      level 2

### `lang2/source/be_com/sched_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    check_snuggle_reads                      0x27A182 0x190    level 2
    check_snuggle_writes                     0x279D36 0x342    level 2
    test_phys_lr                             0x279D20 0x16     level 2
    calculate_precedence                     0x279AB8 0xCA     level 2
    sched_utils_$kodiak_delay                0x2791E8 0x7E     level 2
    driving_instruction                      0x2791BA 0x2E     level 2
    utils_ins_$operands_instruction          0x279190 0x22     level 2
    sched_utils_$operand_delay               0x279266 0x5E8    level 2
    sched_utils_$insert_snuggle_moves        0x27A398 0x7E     level 2
    sched_utils_$init_for_routine            0x2791B4 0x2      level 2
    sched_utils_$fill_in_operand_delays      0x279A42 0x76     level 2
    sched_utils_$end_compilation             0x2791B8 0x2      level 2
    sched_utils_$end_routine                 0x2791B6 0x2      level 2
    sched_utils_$calculate_precedence        0x279BC4 0x118    level 2
    sched_utils_$begin_compilation           0x2791B2 0x2      level 2

### `lang2/source/be_com/sem_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    contiguous_high_order_one_bits           0x27A44E 0x30     level 2
    contiguous_high_order_zero_bits          0x27A420 0x2E     level 2
    sem_utils_$number_of_relevant_low_order_bits 0x27A47E 0x1B8    level 2
    sem_utils_$init_for_routine              0x27A41A 0x2      level 2
    sem_utils_$end_compilation               0x27A41E 0x2      level 2
    sem_utils_$end_routine                   0x27A41C 0x2      level 2
    sem_utils_$begin_compilation             0x27A418 0x2      level 2

### `lang2/source/be_com/sym.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`

    make_properly_sized_copy                 0x27B41C 0x5E     level 2
    add_arrow                                0x27ABF6 0x2C     level 2
    attach_label                             0x27A680 0xB6     level 2
    sym_$reformat_literal                    0x27B47A 0x1F2    level 2
    sym_$reformat_literal_operand            0x27B66C 0x54     level 2
    sym_$object_with_immediate_disp          0x27AE70 0x58     level 2
    sym_$is_static_vat                       0x27AEC8 0x44     level 2
    sym_$has_print_name                      0x27ADF2 0x62     level 2
    sym_$allocate_static_variable            0x27B2C6 0xE4     level 2
    sym_$allocation_size_in_bytes            0x27B1A0 0xF0     level 2
    sym_$has_displacement                    0x27AF0C 0x32     level 2
    sym_$display_symbol_print_name           0x27AD88 0x66     level 2
    sym_$append_symbol_print_name            0x27AC22 0x13C    level 2
    sym_$fully_qualified_routine_name        0x27AB62 0x94     level 2
    sym_$backend_label_for_case_jump         0x27AB3A 0x28     level 2
    sym_$initialize_this_local_symbol        0x27A770 0x318    level 2
    sym_$initialize_local_symbols            0x27AACA 0x70     level 2
    sym_$displacement_literal_pool           0x27AF3E 0x44     level 2
    sym_$displacement                        0x27AF82 0xEC     level 2

### `lang2/source/be_com/target_at_dummies.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/pgm.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    add_proc_reloc                           0x27B710 0x2      level 2
    reg_alloc                                0x27B70E 0x2      level 2
    outcode                                  0x27B70C 0x2      level 2
    isc_$set_source_language                 0x27B70A 0x2      level 2
    as_info_$stack_size                      0x27B6F0 0x1A     level 2
    finaldriver                              0x27B6EE 0x2      level 2
    f_initialize                             0x27B6EC 0x2      level 2
    reg_save_$registers_preserved_by_statement 0x27B6D6 0x16     level 2
    reg_save                                 0x27B6C0 0x16     level 2

### `lang2/source/be_com/tm_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_forms_mask.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_postmod_immed_high.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_postmod_immed_low.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_premod_immed_high.init`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/amse_premod_immed_low.init`
- include `//lang2/source/be_com/utils.ins.pas`

    tm_utils_$minimum_distance               0x27BED0 0x294    level 2
    tm_utils_$interaction_distance_forward   0x27BE72 0x5E     level 2
    tm_utils_$interaction_distance_backward  0x27BDC8 0xAA     level 2
    tm_utils_$init_for_routine               0x27B716 0x2      level 2
    tm_utils_$end_compilation                0x27B71A 0x2      level 2
    tm_utils_$end_routine                    0x27B718 0x2      level 2
    tm_utils_$can_premodify_base_register_by 0x27BCB6 0xC2     level 2
    tm_utils_$can_postmodify_base_register_by 0x27BBA2 0xC2     level 2
    tm_utils_$can_increase_scale_by          0x27BA8E 0x114    level 2
    tm_utils_$can_encode_as_immediate_operand 0x27B8F2 0x19C    level 2
    tm_utils_$can_convert_to_ip_reg_operand  0x27B838 0xA2     level 2
    tm_utils_$can_convert_to_immediate_operand 0x27B71C 0x11C    level 2
    tm_utils_$begin_compilation              0x27B714 0x2      level 2
    lir_$can_encode_as_immediate_operand     0x27C164 0x26     level 2

### `lang2/source/be_com/tr_utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    move_cc_creations                        0x281440 0x152    level 2
    build_tst_instr                          0x2810C8 0x2FE    level 2
    validate_lts_for_tst                     0x280FC8 0x100    level 2
    ok_to_add_tst                            0x280F28 0xA0     level 2
    tst_elim_within_bb                       0x280E50 0xCC     level 2
    br_consuming_tst_ccs_involves_v_bit      0x280D86 0xCA     level 2
    excise_tst_instr                         0x280CF8 0x8E     level 2
    find_driver_for_tst                      0x280AD4 0x21C    level 2
    n_bit_unconsumed                         0x280A6A 0x6A     level 2
    test_lts_for_n_bit_unconsumed            0x2809F0 0x7A     level 2
    high_bits_safe                           0x280974 0x7C     level 2
    safe_to_move_cc                          0x280856 0x11E    level 2
    find_suitable_driving_lts_for_tst        0x280774 0xE2     level 2
    move_add_to_hammock_tail                 0x280498 0x178    level 2
    move_add_to_hammock_head                 0x2803E4 0xB4     level 2
    move_add_to_new_bb                       0x27FFFE 0x3AE    level 2
    adjust_hammock_contents                  0x27FF36 0xC8     level 2
    could_adjust_hammock_contents            0x27FEA8 0x8E     level 2
    try_autoincrement                        0x27FBBA 0x2B8    level 2
    validate_lts_for_auto                    0x27FB7A 0x40     level 2
    ok_to_add_auto                           0x27FB64 0x16     level 2
    apply_autoincrement_solutions            0x27F8A4 0x20E    level 2
    autoincrement_solutions_acceptable       0x27F5E0 0x2C4    level 2
    autoindex_within_bb                      0x27EFC2 0x598    level 2
    can_adjust_creation_point                0x27EEA0 0x122    level 2
    mem_ref_positioned_for_preincrement      0x27ECF4 0x1AC    level 2
    mem_ref_positioned_for_postincrement     0x27EA74 0x280    level 2
    transform_to_autoindex                   0x27E91C 0x11A    level 2
    is_well_understood_intend_input_to_modify 0x27E424 0xCC     level 2
    preserve_operation                       0x27E2D2 0x11C    level 2
    can_preserve_operation                   0x27E130 0x1A2    level 2
    adjustable_creation_point                0x27DD68 0x3C8    level 2
    convert_move_to_add                      0x27DC9C 0xCC     level 2
    convert_add_to_move                      0x27DBCC 0xD0     level 2
    print_solutions_for_debugging            0x27DBCA 0x2      level 2
    solutions_dont_interfere                 0x27DA9C 0xF8     level 2
    validate                                 0x27DA16 0x86     level 3
    find_complex_driving_ltss                0x27D78A 0x25E    level 2
    bb_interval                              0x27D778 0x12     level 2
    just_join_bp                             0x27D73C 0x3C     level 2
    add_solution                             0x27D6BE 0x7E     level 2
    copy$complex_complex                     0x27D540 0xAE     level 2
    copy$simple_complex                      0x27D2CA 0x276    level 2
    copy$simple_dest                         0x27D02C 0x29E    level 2
    simple_ends_before_next_complex          0x27CF9C 0x90     level 2
    write_cc_or_delete_instr                 0x27CEF4 0xA8     level 2
    maintain_complex_props                   0x27CB98 0xC6     level 2
    tr_utils_$separate_partitions            0x27C930 0x230    level 2
    tr_utils_$mark_dependents                0x27C6F0 0x240    level 2
    tr_utils_$guarantee_operand_order        0x27C614 0xDC     level 2
    find_operand_of_kind                     0x27C4B2 0x6C     level 2
    drop_operand_from_lts                    0x27C468 0x4A     level 2
    make_copy                                0x27C356 0x112    level 2
    move_operand                             0x27C2D6 0x80     level 2
    is_base_operand                          0x27C284 0x52     level 2
    base_operand                             0x27C24A 0x3A     level 2
    index_operand                            0x27C210 0x3A     level 2
    utils_ins_$operands_instruction          0x27C18C 0x22     level 2
    tr_utils_$try_twiddling_disp             0x27E4F0 0x42C    level 2
    tr_utils_$relative_instr_position        0x27C51E 0xBC     level 2
    tr_utils_$merge_lrs                      0x27CC5E 0x23A    level 2
    tr_utils_$init_for_routine               0x27C1F0 0x2      level 2
    tr_utils_$end_compilation                0x27C20E 0x2      level 2
    tr_utils_$end_routine                    0x27C1F2 0x1C     level 2
    tr_utils_$begin_compilation              0x27C1AE 0x24     level 2
    tr_utils_$attempt_test_elimination       0x28163E 0x2C8    level 2
    tr_utils_$attempt_copy_elimination       0x27D5EE 0xD0     level 2
    tr_utils_$attempt_autoincrement          0x280610 0x130    level 2

### `lang2/source/be_com/trans.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    massage_xor_to_tst                       0x2843AE 0xBE     level 2
    attempt_special_zero_branches            0x284148 0x21C    level 2
    get_alpha_candidate                      0x283CE0 0x8C     level 2
    drop_unprecedented_instr                 0x283CA6 0x3A     level 2
    collect_unprecedented_instrs             0x283C12 0x94     level 2
    combine_instr_with_alpha_base            0x283964 0x236    level 2
    move_base_instr_to_tail_of_new_bb        0x283526 0x38C    level 2
    get_omega_candidate                      0x28332A 0x84     level 2
    add_predecessors_to_work_list            0x2832DC 0x4E     level 2
    add_successors_to_work_list              0x283294 0x48     level 2
    combine_instr_with_omega_base            0x283048 0x210    level 2
    move_base_instr_to_head_of_new_bb        0x282B8C 0x3F2    level 2
    merge_mate_lr                            0x282AB6 0xAE     level 2
    instrs_ok_for_motion                     0x282562 0x520    level 2
    other_consumers_same_lr                  0x2824F6 0x6C     level 2
    validate_instr                           0x2822DA 0x21C    level 2
    make_lr_complex                          0x2822A0 0x3A     level 2
    update_attributes                        0x282252 0x4E     level 3
    n_zero_high_bits                         0x2821FC 0x56     level 2
    oprs_high_bits_known                     0x281FF6 0x206    level 2
    trans_branches                           0x281D38 0x2BE    level 2
    convert_compare_to_test                  0x281CE6 0x52     level 2
    immedify                                 0x281B82 0x164    level 2
    make_immediate_operand                   0x281B2A 0x58     level 2
    copy_operand                             0x281A4E 0xB2     level 2
    drop_operand_from_lts                    0x2819D6 0x78     level 2
    reattach_split_lts                       0x2819C2 0x14     level 2
    split_lts_for_merge                      0x28192A 0x98     level 2
    utils_ins_$operands_instruction          0x281908 0x22     level 2
    trans_$kill_silly_extract                0x28446C 0xF4     level 2
    trans_$copy_elimination                  0x284560 0x70     level 2
    trans_$omega_motions                     0x2833AE 0x178    level 2
    trans_$alpha_motions                     0x283D6C 0x3DC    level 2
    trans_$end_compilation                   0x2845D2 0x2      level 2
    trans_$end_routine                       0x2845D4 0x2      level 2
    trans_$process_routine                   0x2845D6 0x2F0    level 2
    trans_$begin_compilation                 0x2845D0 0x2      level 2

### `lang2/source/be_com/utils.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    consider_all_uses                        0x287150 0xBE     level 2
    consider_all_defs                        0x286EB8 0xD2     level 2
    add_use_def                              0x286E4C 0x6C     level 2
    find_definition                          0x286AF8 0x90     level 2
    jbi_input_exists                         0x286930 0x38     level 2
    no_path_through_target_bb                0x2865F0 0x36     level 2
    look_for_path                            0x286564 0x8C     level 2
    get_last_lts_in_bb                       0x2861DA 0x56     level 2
    copy_instr_template_to_bb                0x285F5A 0x1CE    level 2
    unique_input                             0x2859F6 0xC4     level 2
    utils_ins_$operands_instruction          0x28491C 0x22     level 2
    utils_$find_unused_operand_slot          0x2879EE 0x80     level 2
    utils_$strip_may_gen_exception           0x28793E 0xB0     level 2
    utils_$instrs_consume_identical_symbols  0x2877D2 0x16C    level 2
    utils_$instr_is_ref_to_memory_home       0x28763C 0x196    level 2
    utils_$instr_is_ref_to_argument_block    0x287608 0x34     level 2
    utils_$find_mate_operand                 0x28733A 0x182    level 2
    utils_$initialize_lts_hint_pointers      0x2852CE 0x3E     level 2
    utils_$remove_spurious_active_on_exit    0x286626 0xA0     level 2
    utils_$complete_copied_instr_at_bb_head  0x28637E 0x1E6    level 2
    utils_$complete_copied_instr             0x286230 0x14E    level 2
    utils_$copy_instr_template_to_bb_head    0x28618A 0x50     level 2
    utils_$copy_instr_template_to_bb_end     0x286128 0x62     level 2
    utils_$set_instruction_opcode            0x285F16 0x44     level 2
    utils_$strip_extraneous_modifies         0x286700 0x19A    level 2
    utils_$resequence_inserted_instruction   0x285274 0x5A     level 2
    utils_$maybe_merge_source_statements     0x285110 0x10E    level 2
    add_statement_number                     0x285050 0xC0     level 3
    utils_$guarantee_instr_sequence          0x28521E 0x56     level 2
    utils_$get_final_lts                     0x28590A 0x7C     level 2
    utils_$get_exposed_lts                   0x285898 0x72     level 2
    utils_$get_new_lts                       0x2857BE 0xDA     level 2
    utils_$put_lts_on_final_list             0x2855FC 0xDE     level 2
    utils_$put_lts_on_exposed_list           0x2854E0 0xDC     level 2
    utils_$find_last_lts_in_bb               0x285714 0xAA     level 2
    utils_$find_final_lts                    0x2853F6 0xEA     level 2
    utils_$find_exposed_lts                  0x28530C 0xEA     level 2
    utils_$excise_lts_cleanly                0x284F28 0x128    level 2
    utils_$remove_lts_from_final_list        0x284E36 0xB6     level 2
    utils_$remove_lts_from_exposed_list      0x284D3A 0xB6     level 2
    utils_$remove_reader_from_lts            0x284C0E 0xC0     level 2
    utils_$excise_instruction_if_unconsumed  0x284B90 0x7E     level 2
    utils_$excise_instruction_cleanly        0x2849C2 0x18E    level 2
    utils_$apply_func_to_all_uses            0x28720E 0xEA     level 2
    utils_$apply_func_to_all_defs            0x286FDA 0x134    level 2
    utils_$locate_definition                 0x286B88 0xD2     level 2
    utils_$move_definition                   0x286A22 0xD6     level 2
    utils_$get_canonical_birthpoint          0x285ABA 0x400    level 2
    utils_$find_join_bp                      0x286C5A 0x48     level 2
    utils_$drop_jbi_input                    0x286968 0xBA     level 2
    utils_$compare_birthpoints               0x285986 0x70     level 2
    utils_$add_birthpoint                    0x286CA2 0x12A    level 2
    utils_$end_compilation                   0x2849A6 0x1C     level 2
    utils_$begin_compilation                 0x28493E 0x44     level 2

### `lang2/source/be_com/xtp.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//lang2/source/be_com/utils.ins.pas`

    insert_ipccnop                           0x287B22 0x20E    level 2
    cc_mentioned                             0x287ADE 0x44     level 2
    utils_ins_$operands_instruction          0x287ABC 0x22     level 2
    xtp_$end_compilation                     0x287DAA 0x2      level 2
    xtp_$end_routine                         0x287F7E 0x2      level 2
    xtp_$process_routine                     0x287DAC 0x1D2    level 2
    xtp_$begin_compilation                   0x287DA8 0x2      level 2

### `lang2/source/be_com/zzzzz.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/globals.ins.pas`
- include `//ivory/volume_3/lang_pools/lang_68k_pool/dseemgrs/apollo/dervobjs/lang/glob_extern.ins.pas/h5eea9860.001/glob_extern.ins.plb.pas`
- include `//lang/lang/source/glob_extern.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/lang/source/real_externals.ins.pas`
- include `//lang/lang/source/il.ins.pas`
- include `//lang/lang/source/target_properties.ins.pas`
- include `//lang/lang/source/cargs.ins.pas`
- include `//lang/lang/source/gspace.ins.pas`
- include `//lang/lang/source/strings.ins.pas`
- include `//lang/lang/source/token.ins.pas`
- include `//lang/lang/source/il_utils.ins.pas`
- include `//lang/lang/source/inc_list.ins.pas`
- include `//lang/lang/source/error_listing.ins.pas`
- include `//lang/lang/source/gen_utils.ins.pas`
- include `//lang/lang/source/add_node.ins.pas`
- include `//lang/lang/source/debug_sym_dmp.ins.pas`
- include `//lang/lang/source/globals_from_general.ins.pas`
- include `//lang/lang/source/globals_from_backend.ins.pas`
- include `//lang/lang/source/globals_from_frontend.ins.pas`
- include `//us/us/ins/lib.ins.pas`
- include `//lang/lang/source/outbin.ins.pas`
- include `//lang2/source/be_com/at_base.ins.pas`
- include `//lang2/source/be_com/backend.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/be_prism/target.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas`
- include `//idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/code_cell_size.init`

    mark_start_of_epilogue                   0x288164 0xB0     level 2
    basic_block_label                        0x2880E8 0x7C     level 2
    zero                                     0x287F80 0x18     level 2
    zzzzz_$process_routine                   0x288214 0x436    level 2
    zzzzz_$preallocate_case_table            0x288022 0x70     level 2
    zzzzz_$preallocate_label                 0x287FCA 0x58     level 2
    zzzzz_$new_code_cell                     0x288092 0x56     level 2
    zzzzz_$end_compilation                   0x287FC8 0x2      level 2
    zzzzz_$begin_compilation                 0x287F98 0x22     level 2

