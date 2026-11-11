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

    pop_current_state                        0x0409D2 0x12     level 2
    push_current_state                       0x0409C0 0x12     level 2
    match_keyword                            0x040920 0x90     level 2
    first_token                              0x0407D0 0x134    level 2
    cr_$if_is_on                             0x040404 0x1A     level 2
    cr_$get_cooked_line                      0x04041E 0x346    level 2
    cr_$initialize                           0x0403D8 0x2C     level 2

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

    alloc_on_stk                             0x048F0C 0xD4     level 2
    create_and_link_data_rec                 0x047064 0x116    level 2
    def_sect                                 0x046342 0x9C     level 2
    has_data_init                            0x046334 0xE      level 2
    check_protos                             0x04607E 0xE4     level 2
    check_oldef_proto                        0x045F7C 0x102    level 2
    all_promoted_types                       0x045F22 0x5A     level 2
    promote_type                             0x045E62 0xC0     level 2
    add_incomplete_type                      0x04571C 0x52     level 2
    def_virt_varn                            0x0455DA 0x48     level 2
    lnktbl_def_name                          0x0455B0 0x2A     level 2
    lnktbl_to_modblk                         0x045540 0x42     level 2
    lnktbl_first_name                        0x04552C 0x14     level 2
    lnktbl_del_name                          0x0454AC 0x80     level 2
    lnktbl_init                              0x04548E 0x1E     level 2
    get_constant_size                        0x0451EE 0xB6     level 2
    calc_align                               0x0451B4 0x3A     level 2
    def_alloc_var                            0x048FE0 0x20C    level 2
    def_blk_params                           0x048A96 0x476    level 2
    def_blk_skeleton                         0x0484F8 0x59E    level 2
    def_arr                                  0x0480A4 0x454    level 2
    def_rec                                  0x047FDC 0xC8     level 2
    def_fld                                  0x047956 0x66C    level 2
    def_func                                 0x0478B4 0xA2     level 2
    def_incomplete_su                        0x045650 0xCC     level 2
    def_resolve_incomplete_types             0x04576E 0x10A    level 2
    def_final_res_fwd_ptrs                   0x04780C 0xA8     level 2
    def_resolve_fwd_ptrs                     0x047738 0xD4     level 2
    def_fwd_ptr                              0x0476DC 0x5C     level 2
    def_ptr                                  0x047614 0xC8     level 2
    add_parm                                 0x046EC4 0xB8     level 2
    def_subr                                 0x0475C2 0x52     level 2
    def_enum_list                            0x04734E 0x264    level 2
    def_enum_skeleton                        0x04731A 0x34     level 2
    def_conn                                 0x0472C6 0x54     level 2
    def_typn                                 0x047230 0x96     level 2
    def_dynm_data                            0x0471CE 0x62     level 2
    def_data                                 0x04717A 0x54     level 2
    def_su                                   0x047012 0x52     level 2
    lookup_su                                0x046F7C 0x60     level 2
    add_su                                   0x046FDC 0x36     level 2
    add_reg_var                              0x046E60 0x64     level 2
    add_varn                                 0x046D98 0xC8     level 2
    def_varn                                 0x046742 0x656    level 2
    alloc_bss                                0x0466FC 0x46     level 3
    make_comblk_sect                         0x04666E 0x8E     level 3
    ext2sect_addr_cons                       0x0465F4 0x7A     level 3
    redecl_as_static                         0x0464CC 0x128    level 3
    delete_section                           0x04647E 0x4E     level 3
    update_attr                              0x0463DE 0xA0     level 3
    check_types                              0x046162 0x1D2    level 2
    def_drop_tnames                          0x045622 0x2E     level 2
    def_lnktbl_clear                         0x045582 0x2E     level 2
    def_name                                 0x0453C2 0xCC     level 2
    fnd_name                                 0x045390 0x32     level 2
    blk_fnd_name                             0x045302 0x8E     level 2
    fnd_param                                0x0452A4 0x5E     level 2
    type_exp                                 0x04590A 0x51A    level 2
    fix_array_decl                           0x045878 0x92     level 3

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

    error_hdr                                0x04929C 0x210    level 2
    print_line_number                        0x049212 0x84     level 2
    warning_text                             0x049B2C 0x8A     level 2
    error_text                               0x049AC0 0x6C     level 2
    errorlst                                 0x0495EC 0x410    level 2
    error_not_printed                        0x049508 0xE4     level 3
    cgerr_no_source                          0x0491EC 0x26     level 2
    cgerr                                    0x049A00 0xC0     level 2

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

    swap_top                                 0x04BD74 0x62     level 2
    scl_cmp                                  0x04BB14 0x17C    level 2
    reference_operand                        0x04A9C0 0x69E    level 2
    float_operand                            0x049E70 0x130    level 2
    adjust_length                            0x049D36 0x13A    level 2
    get_oc                                   0x049CAE 0x88     level 2
    adjust_blk_for_db                        0x04FC62 0x8C     level 2
    test_ne_zero                             0x04FA40 0x21A    level 2
    adjust_parm                              0x04F974 0xCC     level 2
    expr_op                                  0x04CDBA 0x2B7A   level 2
    check_for_out_of_bounds                  0x04CD6A 0x50     level 3
    get_number_of_elements                   0x04CCAC 0xBE     level 4
    result_signedness                        0x04CC5A 0x52     level 3
    build_builtin_tree                       0x04C91E 0x33C    level 3
    de_ref                                   0x04C85A 0xC4     level 4
    power_of_two                             0x04C72C 0x12E    level 3
    mult_div_mod_sign                        0x04C6BA 0x72     level 3
    mult_div_mod_prep                        0x04C61A 0xA0     level 3
    double_coerce                            0x04C448 0x1D2    level 3
    value_preserve                           0x04C242 0x206    level 4
    coerce_dominant                          0x04C136 0x10C    level 4
    coerce_as_usual                          0x04C06A 0xCC     level 4
    fixup_bounds                             0x04BFD0 0x9A     level 4
    do_coerce                                0x04BE2E 0x1A2    level 3
    boolean_result                           0x04BDD6 0x4C     level 3
    push_fcon                                0x04BCD0 0xA4     level 2
    push_con                                 0x04BC90 0x40     level 2
    body_opr                                 0x04B5E0 0x534    level 2
    stack_operand                            0x04B462 0x164    level 3
    select_field                             0x04B39C 0xC6     level 3
    exposed_member                           0x04B2F6 0xA6     level 3
    find_field_member                        0x04B19A 0x15C    level 3
    find_field_partial                       0x04B0CA 0xD0     level 4
    find_field                               0x04B078 0x52     level 3
    coerce                                   0x04A678 0x348    level 2
    real_to_real                             0x04A4AA 0x1BE    level 3
    real_to_integer_or_enum                  0x04A3A0 0x10A    level 3
    pointer_to_pointer                       0x04A23E 0x162    level 3
    pointer_and_integer_or_enum              0x04A170 0xCE     level 3
    common_integer_code                      0x04A060 0x110    level 3
    common_enum_code                         0x049FA0 0xA6     level 3
    init_aux                                 0x049C0A 0xA4     level 2
    init_exp_tbl                             0x049BB8 0x34     level 2

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

    log_or_expr                              0x052AC0 0xD2     level 2
    log_and_expr                             0x0529E0 0xD2     level 2
    bit_ior_expr                             0x052904 0xCE     level 2
    bit_eor_expr                             0x052828 0xCE     level 2
    bit_and_expr                             0x05274C 0xCE     level 2
    eq_expr                                  0x05265E 0xE0     level 2
    rel_expr                                 0x05252A 0x126    level 2
    shift_expr                               0x05243A 0xE2     level 2
    addit_expr                               0x05234C 0xE0     level 2
    multip_expr                              0x052248 0xF6     level 2
    unary_expr                               0x051650 0xBAA    level 2
    primary_expr                             0x050DCC 0x826    level 2
    func_call_stat                           0x050962 0x41A    level 2
    do_c_string                              0x0507A2 0x16C    level 2
    test_side_effects                        0x050792 0x10     level 2
    cast_int_const                           0x050526 0x170    level 2
    get_builtin_func                         0x0504E0 0x46     level 2
    swap_top                                 0x05047C 0x64     level 2
    check                                    0x05044A 0x32     level 2
    error                                    0x0503BC 0x80     level 2
    cond_expr                                0x052BA0 0x118    level 2
    asn_expr                                 0x052CD4 0x102    level 2
    not_an_lvalue                            0x0506B0 0xC8     level 2
    identifier                               0x05090E 0x54     level 2
    eval_expr                                0x052EC8 0x40     level 2
    c_expr                                   0x052DE4 0xD6     level 2
    c_expr_syn_$begin_compilation            0x04FDFC 0x4D0    level 2
    alloc_builtins                           0x04FCF0 0x10C    level 3

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

    cgu_$make_line_no                        0x053240 0x96     level 2
    str_locate                               0x05314C 0xF4     level 2
    str_slide                                0x0530D8 0x74     level 2
    str_strip_leading                        0x053080 0x58     level 2
    str_copy                                 0x05304A 0x36     level 2
    str_eql_insensitive                      0x052FDE 0x6C     level 2
    str_eql                                  0x052F8E 0x50     level 2
    min                                      0x052F6C 0x22     level 2
    max                                      0x052F4A 0x22     level 2
    math_mod                                 0x052F08 0x42     level 2

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

    get_rlen                                 0x0532D8 0x7C     level 2

### `lang/c_compiler/source/c_initdate.c`


    initdate                                 0x053354 0x92     level 2

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

    put_es_line                              0x053444 0xD4     level 2
    ppio_$lookahead                          0x0563A4 0x6E     level 2
    ppio_$error                              0x0560E8 0x50     level 2
    ppio_$get_line                           0x056138 0x26C    level 2
    init_lex                                 0x05351A 0x1E4    level 2
    clex_$catstring                          0x055FE4 0x104    level 2
    clex_$unget                              0x055FB0 0x34     level 2
    get                                      0x0557EA 0x7A4    level 2
    check_op_asn                             0x05578E 0x5C     level 3
    get_number                               0x0554C8 0x2C6    level 3
    get_integer                              0x0553EE 0xCC     level 4
    get_identifier                           0x055336 0xA8     level 3
    get_wchar_t                              0x0552EC 0x4A     level 3
    peekchar                                 0x0552D0 0x1C     level 3
    get_wchar_const                          0x0552A4 0x2C     level 3
    get_char_const                           0x0551EE 0xB6     level 3
    get_wstring                              0x055124 0xCA     level 3
    get_string                               0x055060 0xC4     level 3
    get_backslash_char                       0x054E8A 0x1AE    level 3
    get_comment                              0x054DFA 0x90     level 3
    get_character                            0x054DBA 0x40     level 3
    pp_get_line                              0x054BFE 0x1BC    level 3
    open_include                             0x05494C 0x2B0    level 3
    parse_directive                          0x0545C0 0x328    level 3
    do_pragma                                0x05420E 0x30E    level 4
    hp_standard_sem                          0x054178 0x7C     level 4
    systype_sem                              0x05404C 0x112    level 4
    section_sem                              0x053E56 0x1F6    level 4
    module_sem                               0x053C86 0x1D0    level 4
    sect_id                                  0x053C7A 0xC      level 4
    nolist_sem                               0x053C74 0x6      level 4
    list_sem                                 0x053C68 0xC      level 4
    eject_sem                                0x053C48 0x20     level 4
    line_sem                                 0x05386C 0x3D8    level 4
    open_file_to_get_info                    0x0537E6 0x86     level 4
    set_ecb_bit                              0x053784 0x62     level 4
    more_data_on_line                        0x053724 0x5A     level 3
    advance_listing_to_line                  0x0533E8 0x5C     level 2

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

    get_decommented_line                     0x056E94 0x4A4    level 2
    extract_params                           0x056A94 0x400    level 2
    append_actual                            0x0569FA 0x9A     level 2
    process_formals                          0x056988 0x72     level 2
    text_identical                           0x056928 0x60     level 2
    find_id                                  0x0566E2 0x246    level 2
    insert_error_q                           0x056686 0x5C     level 2
    insert_q                                 0x056640 0x46     level 2
    insert_q_tlp                             0x056622 0x1E     level 2
    remove_q                                 0x0565A8 0x7A     level 2
    s_pick_off_name                          0x056472 0x114    level 2
    get_par_cooked_line                      0x057570 0x82E    level 2
    just_get_the_next_line_please            0x0574CC 0xA4     level 3
    str_locate_c_id                          0x058BD8 0x2A0    level 2
    mr_$check_define                         0x058E80 0x80     level 2
    mr_$get_q_only                           0x057FC6 0x6E     level 2
    mr_$get_raw_line                         0x0573A0 0x114    level 2
    mr_$get_expanded_line                    0x058262 0x85E    level 2
    prep_split_id                            0x0581E4 0x7E     level 3
    skip_white_space                         0x0581A0 0x44     level 3
    queue_error                              0x0580C8 0xD8     level 3
    do_special_macro                         0x058034 0x94     level 3
    mr_$initialize                           0x05641C 0x56     level 2

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

    copy_body                                0x059C98 0x70     level 2
    end_of_text_chain                        0x059C84 0x14     level 2
    hash_value                               0x058F00 0x42     level 2
    mu_$find_hash_word                       0x059BB2 0xC0     level 2
    mu_$free_tle_list                        0x059B7A 0x38     level 2
    mu_$free_tle                             0x059A44 0x108    level 2
    mu_$alloc_tle                            0x059812 0x1D0    level 2
    mu_$bind_params                          0x059EDC 0x38     level 2
    bind_backwards                           0x059E14 0xC8     level 3
    mu_$merge_line_tlp                       0x059D36 0xDE     level 2
    mu_$copy_text_list                       0x059D08 0x2E     level 2
    mu_$compress_macro                       0x05973C 0xD6     level 2
    mu_$convert_formal                       0x05968C 0xB0     level 2
    mu_$dump                                 0x059494 0x1AA    level 2
    mu_$initialize                           0x0591C8 0x240    level 2
    mu_$def_macro                            0x059128 0xA0     level 2
    mu_$cancel_name                          0x05909C 0x8C     level 2
    mu_$enter_name                           0x058FB0 0xA8     level 2
    mu_$lookup_name                          0x058F42 0x6E     level 2

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

    cc                                       0x05AF72 0xC90    level 1
    init_basic_types                         0x05ADD2 0x1A0    level 2
    fe_cc_$end_compilation                   0x05ADC4 0xE      level 2
    preprocess                               0x05A934 0x3D4    level 2
    do_ansi_undefs                           0x05A862 0xD2     level 2
    do_ansi_defs                             0x05A6D2 0x190    level 2
    addincludes                              0x05A624 0xAE     level 2
    addarg                                   0x05A5B0 0x74     level 2
    rword_init                               0x05A3C4 0x1BE    level 2
    do_lex_for_listings                      0x05A380 0x44     level 2
    do_cmd_undefs                            0x05A2D8 0xA8     level 2
    do_cmd_defs                              0x05A17A 0x15C    level 2
    make_main_pgm                            0x059F14 0x24A    level 2

### `lang/c_compiler/source/c_run_acpp.c`

- include `//us/us/unix/include/sys5.3/stdio.h`
- include `//us/us/unix/include/sys5.3/sys/types.h`
- include `//us/us/unix/include/sys5.3/sys/stdsyms.h`
- include `//us/us/unix/include/sys5.3/sys/stdtypes.h`
- include `//us/us/unix/include/sys5.3/sys/wait.h`

    c_cpp_present                            0x05BECC 0x2A     level 2
    c_delete_temp                            0x05BEAA 0x22     level 2
    c_run_acpp                               0x05BE38 0x72     level 2

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

    fix_post_id                              0x05E750 0x166    level 2
    add_or_update                            0x05E6D0 0x80     level 2
    find_post_opnd                           0x05E624 0xAC     level 2
    only_logical                             0x05E57E 0x9E     level 2
    build_cond_expr                          0x05E24A 0x324    level 2
    eval_tree_nodes                          0x05E1CE 0x7C     level 3
    build_not_expr                           0x05E02A 0x1A4    level 2
    extend_boolean                           0x05DF6A 0xC0     level 2
    build_assign                             0x05DD02 0x262    level 2
    case_ini                                 0x05C994 0x64     level 2
    pop_lbl                                  0x05C896 0x34     level 2
    push_lbl                                 0x05C86A 0x2C     level 2
    dcl_labl                                 0x05C746 0x6E     level 2
    fnd_labl                                 0x05C6FA 0x4C     level 2
    add_cbrn                                 0x05C6C4 0x36     level 2
    add_cbranch                              0x05C428 0x274    level 2
    add_brn                                  0x05C33C 0xEC     level 2
    add_ldfn                                 0x05C0B6 0x24E    level 2
    add_eval                                 0x05BFFE 0xB8     level 2
    add_be_eval                              0x05BFD4 0x2A     level 2
    add_top_node                             0x05BFA0 0x34     level 2
    temp_alloc                               0x05DB3A 0x1BC    level 2
    walk_tree                                0x05E938 0x92E    level 2
    is_post_incr_candidate                   0x05E8B6 0x82     level 3
    link_top                                 0x05BEF8 0xA8     level 2
    def_def_label                            0x05C304 0x38     level 2
    goto_s                                   0x05DAAC 0x8E     level 2
    return_s                                 0x05DA8A 0x22     level 2
    nxtext_s                                 0x05D9F8 0x92     level 2
    body_e                                   0x05D7CE 0x22A    level 2
    finish_profiling                         0x05D698 0x12E    level 3
    body_s                                   0x05D62C 0x6C     level 2
    do_monstartup                            0x05D42C 0x1EA    level 3
    setup_profiling                          0x05D232 0x1E4    level 3
    call_s                                   0x05D05C 0x1D6    level 2
    repeat_e                                 0x05CFF8 0x64     level 2
    repeat_s                                 0x05CFB4 0x44     level 2
    for_e                                    0x05CF66 0x4E     level 2
    for_next_lab                             0x05CF30 0x36     level 2
    for_s                                    0x05CF00 0x30     level 2
    for_start_lab                            0x05CEBC 0x44     level 2
    while_e                                  0x05CE6E 0x4E     level 2
    while_s                                  0x05CE3E 0x30     level 2
    while_label                              0x05CDFA 0x44     level 2
    case_e                                   0x05CDA4 0x56     level 2
    case_default                             0x05CC7C 0x128    level 2
    case_s                                   0x05CB26 0x156    level 2
    case_con                                 0x05C9F8 0x12E    level 2
    endif_s                                  0x05C94A 0x4A     level 2
    else_s                                   0x05C900 0x4A     level 2
    if_s                                     0x05C8CA 0x36     level 2
    def_labl                                 0x05C7B4 0xB6     level 2

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

    sym_map                                  0x060584 0x42C    level 2
    print_addr_cons                          0x0601BE 0x374    level 3
    print_ac_ref                             0x0600B8 0xCA     level 3
    print_ac_key                             0x05FF4C 0xF8     level 3
    print_vat                                0x05FDD6 0xF8     level 3
    print_block                              0x05FB4A 0x24C    level 3
    print_type                               0x05F59C 0x52A    level 3
    print_attr                               0x05F39E 0x190    level 3
    tattr_to_vattr                           0x05F37A 0x24     level 3
    print_con                                0x05F2C0 0xBA     level 3
    print_10                                 0x05F294 0x2C     level 3

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

    abstract_decl                            0x066F12 0x374    level 2
    call_kfold_fold_addrs                    0x066190 0x2C     level 2
    int_ob_kind_from_integer_type            0x063A00 0x88     level 2
    type_qualifiers                          0x061FBE 0xAA     level 2
    storage_class                            0x061EA8 0x110    level 2
    add_top_node                             0x061560 0x36     level 2
    get_options                              0x061394 0x1BE    level 2
    avoid_void                               0x0612DE 0xB6     level 2
    parse_attributes                         0x060E88 0x414    level 2
    check                                    0x060C38 0x30     level 2
    warning                                  0x060C20 0x18     level 2
    error                                    0x060B96 0x7C     level 2
    initialize_legal_specs                   0x060B38 0x5E     level 2
    init_refvar                              0x066C7A 0x1DA    level 2
    clear_operands                           0x066B52 0x128    level 2
    constant_expr                            0x0665DC 0x3AA    level 2
    return_stat                              0x0669B4 0x146    level 2
    continue_break                           0x0669A0 0x14     level 2
    goto_stat                                0x066AFA 0x58     level 2
    for_stat                                 0x065F5E 0x1F6    level 2
    do_while_stat                            0x065E02 0x140    level 2
    while_stat                               0x065D0C 0xE8     level 2
    case_or_default_stat                     0x065884 0x102    level 2
    switch_stat                              0x065A26 0x2BC    level 2
    pop_switch                               0x065A0A 0x1C     level 3
    push_switch                              0x065994 0x76     level 3
    if_stat                                  0x065774 0x102    level 2
    compound_stat                            0x065668 0x10C    level 2
    stat                                     0x0653D4 0x278    level 2
    stat_list                                0x0652A4 0xF6     level 2
    body                                     0x06508E 0x1FA    level 2
    get_constant                             0x064BEA 0x494    level 2
    check_addr_init                          0x064B3C 0xAE     level 3
    varn_from_addr_con                       0x064AE0 0x5C     level 3
    address_exposed                          0x064AB4 0x2C     level 3
    init_with_string                         0x0649E2 0xD2     level 2
    struct_init                              0x06456E 0x474    level 2
    array_dim_init                           0x064286 0x2E8    level 2
    array_init                               0x0640AE 0x1D8    level 2
    dynm_init                                0x063E08 0x298    level 2
    enum_list                                0x063AB2 0x19E    level 2
    enum__type                               0x063784 0x27C    level 2
    member_list                              0x0633CE 0x370    level 2
    struct_union_type                        0x063098 0x336    level 2
    function_def                             0x062E88 0x34     level 2
    declaration                              0x0623EC 0x70C    level 2
    declaration_stmts                        0x061596 0x8BC    level 2
    program_                                 0x060C68 0x1D4    level 2
    function_prototype                       0x062B38 0x350    level 2
    array_decl                               0x062ECA 0x1C0    level 2
    declaration_specifiers                   0x06228E 0x15E    level 2
    type_specifier                           0x0620AC 0x1D4    level 3
    check_add_spec                           0x062068 0x44     level 4
    c_type_name                              0x067286 0xF2     level 2
    data_init                                0x063C6C 0x19C    level 2
    call_kfold                               0x066162 0x2A     level 2
    cc_walk_it                               0x0661BC 0x420    level 2
    pp_constant                              0x066E54 0x96     level 2
    syntax                                   0x0609D8 0x110    level 2

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

    coproc_$suppress_warnings                0x06737A 0x2      level 2
    dump_namelist                            0x067378 0x2      level 2
    isc_$init_well_known_types               0x06737C 0x38     level 2

### `lang/c_compiler/source/frontend_cc_dummies.pas`


    pass_char_len_diff                       0x067408 0x16     level 2
    modify_m2_native_external_name           0x0673EC 0x1C     level 2
    create_m2_native_external_name           0x0673D0 0x1C     level 2
    get_alignment                            0x0673B4 0x1C     level 2

### `lang/common/source/ass.pas`

- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`

    show_context                             0x067420 0x40     level 2
    ass_$disable_context_call_back           0x067996 0x1E     level 2
    ass_$enable_context_call_back            0x067924 0x38     level 2
    ass_$describe                            0x0678C4 0x60     level 2
    ass_$warning                             0x06781C 0xA2     level 2
    ass_$os_error                            0x067784 0x72     level 2
    ass_$not_implemented                     0x067724 0x60     level 2
    ass_$invariant_fail                      0x0676C4 0x60     level 2
    ass_$postcondition_fail                  0x067664 0x60     level 2
    ass_$precondition_fail                   0x067604 0x60     level 2
    ass_$restriction                         0x0675A4 0x60     level 2
    ass_$external_resource_error             0x067544 0x60     level 2
    ass_$external_data_error                 0x0674E4 0x60     level 2
    ass_$initialise                          0x067460 0x80     level 2

### `lang/common/source/bvs.pas`

- include `//lang/common/source/bvs.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    check2_same_size                         0x067B98 0x90     level 2
    check_same_size                          0x067A70 0x74     level 2
    check                                    0x0679B4 0x58     level 2
    bvs_$find_next                           0x068362 0xB0     level 2
    bvs_$set1_subsumes_set2                  0x068316 0x4C     level 2
    bvs_$subtract                            0x0682D2 0x44     level 2
    bvs_$and_to                              0x068282 0x50     level 2
    bvs_$and_and_test                        0x068230 0x52     level 2
    bvs_$or_and_test                         0x0681E4 0x4C     level 2
    bvs_$and                                 0x0681A0 0x44     level 2
    bvs_$or                                  0x06815C 0x44     level 2
    bvs_$equal                               0x068112 0x4A     level 2
    bvs_$copy_and_test                       0x0680CC 0x46     level 2
    bvs_$copy                                0x068082 0x4A     level 2
    bvs_$clear                               0x068042 0x40     level 2
    bvs_$set                                 0x068004 0x3E     level 2
    bvs_$test_and_clear                      0x067FBC 0x48     level 2
    bvs_$test_and_set                        0x067F76 0x46     level 2
    bvs_$test                                0x067F38 0x3E     level 2
    bvs_$test_bit_vector                     0x067EAC 0x62     level 2
    bvs_$reset_bit_vector                    0x067E28 0x5A     level 2
    bvs_$bit_vector_bit_count                0x067DC4 0x36     level 2
    bvs_$dispose_bit_vector                  0x067D5C 0x3A     level 2
    bvs_$create_bit_vector                   0x067CF4 0x68     level 2

### `lang/common/source/diag.pas`

- include `//lang/common/source/diag.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`

    about_to_write_to_line                   0x068438 0x22     level 2
    diag_$banner                             0x0687BE 0x46     level 2
    diag_$indent                             0x068754 0x6A     level 2
    diag_$drop_and_yield_prefix              0x0686F8 0x5C     level 2
    diag_$drop_prefix                        0x0686DC 0x1C     level 2
    diag_$set_prefix                         0x068676 0x66     level 2
    diag_$current_column                     0x06865E 0x18     level 2
    diag_$tab_to_with_fill                   0x0685DE 0x60     level 2
    diag_$tab_to                             0x06863E 0x20     level 2
    diag_$assure_fresh_line                  0x0685C2 0x1C     level 2
    diag_$new_line                           0x06855A 0x60     level 2
    diag_$writeln                            0x0684FA 0x60     level 2
    diag_$write                              0x06845A 0xA0     level 2

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

    ecb_$allocate_ecb                        0x068808 0xB2     level 2

### `lang/common/source/htm.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/common/source/htm.ins.pas`

    htm_$hash_running_byte_multiple          0x06907A 0x5A     level 2
    htm_$hash_running_quad_multiple          0x068F08 0x172    level 2
    htm_$hash_upcased_name                   0x068E50 0xB8     level 2
    htm_$hash_string                         0x068DE0 0x70     level 2
    htm_$hash_quad                           0x068C76 0x16A    level 2
    htm_$hash_long                           0x068BAC 0xCA     level 2
    htm_$hash_word                           0x068B2E 0x7E     level 2
    htm_$hash_byte                           0x068ADE 0x50     level 2
    htm_$increment_table_entries             0x0689C8 0xF6     level 2
    htm_$bucket                              0x068ABE 0x20     level 2
    htm_$release_table                       0x06896C 0x3A     level 2
    htm_$create_table                        0x068908 0x64     level 2

### `lang/common/source/mem.pas`

- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    mrh_release                              0x069642 0x38     level 2
    mrh_mark                                 0x069610 0x32     level 2
    mrh_empty_pool                           0x0695EA 0x26     level 2
    mrh_alloc                                0x06951C 0x6C     level 2
    rws_release                              0x069454 0x8A     level 2
    rws_empty_pool                           0x06941C 0x38     level 2
    rws_dispose                              0x069352 0x8A     level 2
    rws_alloc                                0x0692F2 0x60     level 2
    rws_dispose_chunk                        0x0691FE 0x6A     level 2
    rws_alloc_chunk                          0x0690F4 0xAC     level 2
    pool_name_len                            0x0690D4 0x20     level 2
    mem_$reset                               0x0696C2 0x80     level 2
    mem_$release                             0x069A6A 0x82     level 2
    mem_$mark                                0x0699C6 0x82     level 2
    mem_$dispose                             0x06990C 0x5A     level 2
    mem_$empty_pool                          0x069888 0x5C     level 2
    mem_$alloc                               0x0697DE 0x84     level 2
    mem_$open_pool                           0x069754 0x8A     level 2
    mem_$initialise                          0x06967A 0x48     level 2

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

    construct_ordered_rec_list               0x07192A 0x3C     level 2
    order_this_rec                           0x07172A 0x1D4    level 2
    append_ordered_rec_to_bucket             0x0716DE 0x4C     level 2
    dump_local_file_table                    0x0715CA 0xE4     level 2
    dump_section_header                      0x07158C 0x3E     level 2
    pool_local_file_table_entries            0x07147C 0xD4     level 2
    add_local_file_entry                     0x071346 0x100    level 2
    calculate_crc                            0x0711B2 0x134    level 2
    construct_a_dag                          0x070F4A 0x62     level 2
    build_dependency_graph                   0x070E8E 0xBC     level 2
    dag_visit                                0x070D42 0x14C    level 2
    add_to_dag                               0x070D0A 0x38     level 2
    append_to_merge_list                     0x070BA6 0xF2     level 2
    do_merge                                 0x070A74 0x132    level 2
    do_dfs_ordering                          0x07096C 0x9E     level 2
    sprinkle_incl_end_scope_recs             0x07090E 0x5E     level 2
    dump_incl_table                          0x0707C2 0xEC     level 2
    add_references                           0x06FC9C 0xA14    level 2
    add_aux_references                       0x06F9EE 0x1BE    level 2
    make_type_ref_from_aux                   0x06F79A 0x11A    level 2
    make_rec_ref_from_aux                    0x06F5A4 0xB0     level 2
    make_name_ref_from_aux                   0x06F4CC 0x5E     level 2
    make_loc_ref_from_aux                    0x06F3EA 0x6A     level 2
    make_loc_ref                             0x06F31A 0x6A     level 2
    make_name_ref                            0x06F254 0x5E     level 2
    make_type_ref                            0x06EFF6 0x11A    level 2
    make_rec_ref                             0x06EE74 0xAE     level 2
    make_relative_ref                        0x06EE2E 0x46     level 2
    make_include_rec_ref                     0x06ECC2 0xB6     level 2
    get_var_attrs                            0x06EBEA 0x7E     level 2
    get_arg_attrs                            0x06EB0C 0x84     level 2
    get_dtc                                  0x06EA3A 0xAE     level 2
    dump_rec                                 0x06E606 0x396    level 2
    dump_aux_recs                            0x06E386 0x214    level 2
    dump_loc_pool                            0x06E310 0x76     level 2
    dump_string_table                        0x06E16C 0x14E    level 2
    pool_crc_entries                         0x06DF50 0x1A4    level 2
    add_crc_entry_for_type_ref               0x06DE06 0x86     level 2
    add_crc_entry                            0x06DDCE 0x38     level 2
    get_include_table_index                  0x06DD52 0x7C     level 2
    create_new_crc_table_entry               0x06DC7C 0x78     level 2
    pool_strings                             0x06DADE 0x174    level 2
    add_file_string                          0x06DABE 0x20     level 2
    add_string                               0x06DA9C 0x22     level 2
    add_str                                  0x06D9EA 0xB2     level 2
    downcase_string                          0x06D9A6 0x44     level 2
    hash_it                                  0x06D97C 0x2A     level 2
    allocate_dst_rec                         0x06D892 0x76     level 2
    process_symbols_rec                      0x06D1B0 0x2D2    level 2
    order_root_rec_in_bucket                 0x06CFBC 0x106    level 2
    append_root_rec_to_bucket                0x06CF68 0x54     level 2
    compare_bytes_case                       0x06CE6A 0xEC     level 2
    memcmp                                   0x06CE2C 0x3E     level 2
    get_name_p                               0x06CD08 0xD4     level 2
    get_bucket_index                         0x06CC64 0x72     level 2
    make_end_scope_rec                       0x06C986 0x1A     level 2
    make_incl_end_scope_rec                  0x06C96C 0x1A     level 2
    make_incl_start_scope_rec                0x06C8AE 0x50     level 2
    get_bucket                               0x06C834 0x7A     level 2
    get_offset_within_section                0x06C6B4 0x66     level 2
    make_aux_field_off_rec                   0x069BEC 0x3E     level 2
    alloc_aux_rec                            0x069B78 0x4A     level 2
    alloc_rec                                0x069B08 0x4A     level 2
    pds_$get_scope_offset_within_section     0x06C4AC 0x88     level 2
    pds_$dump_symbols_section                0x071966 0x212    level 2
    pds_$create_symbols_sections             0x070FD8 0xC0     level 2
    pds_$end_scope                           0x06D790 0xD8     level 2
    pds_$enter_named_record_current_scope    0x06D68C 0x82     level 2
    pds_$begin_scope                         0x06CC1E 0x46     level 2
    pds_$finalize                            0x06CBE8 0x36     level 2
    pds_$enter_main_file_table               0x06CADC 0x82     level 2
    pds_$initialize                          0x06C9A0 0x92     level 2
    pds_$add_aux_rec                         0x06C400 0x64     level 2
    pds_$make_aux_ptr_base_rec               0x06C346 0x52     level 2
    pds_$make_aux_lifetime_rec               0x06C2D8 0x40     level 2
    pds_$make_aux_type_deriv_rec             0x06C24A 0x50     level 2
    pds_$make_aux_var_bound_rec              0x06C20C 0x3E     level 2
    pds_$make_aux_field_align_rec            0x06C18A 0x4C     level 2
    pds_$make_aux_align_rec                  0x06C15C 0x2E     level 2
    pds_$make_aux_field_size_rec             0x06C0DC 0x4C     level 2
    pds_$make_aux_size_rec                   0x06C0B0 0x2C     level 2
    pds_$make_aux_reg_val_rec                0x06C02E 0x50     level 2
    pds_$make_string_rec                     0x06BF2E 0x9C     level 2
    pds_$make_array_rec                      0x06BE00 0xCA     level 2
    pds_$add_field                           0x06BC7C 0xC6     level 2
    pds_$make_field                          0x06BADC 0xBE     level 2
    pds_$make_record_rec                     0x06BA4C 0x90     level 2
    pds_$add_short_field                     0x06B8CA 0xA2     level 2
    pds_$make_short_field                    0x06B810 0x62     level 2
    pds_$make_short_record_rec               0x06B780 0x90     level 2
    pds_$add_explicit_enum_element           0x06B600 0x78     level 2
    pds_$make_explicit_enum_element          0x06B57C 0x50     level 2
    pds_$make_explicit_enum_rec              0x06B510 0x6C     level 2
    pds_$add_implicit_enum_element           0x06B390 0x78     level 2
    pds_$make_implicit_enum_rec              0x06B2A8 0x88     level 2
    pds_$make_offset_rec                     0x06B154 0xBA     level 2
    pds_$make_file_rec                       0x06B0B4 0x6C     level 2
    pds_$make_subrange_rec                   0x06AFC0 0x94     level 2
    pds_$make_set_rec                        0x06AEA8 0x9C     level 2
    pds_$make_constant_rec                   0x06AD80 0x92     level 2
    pds_$make_constant_value                 0x06AD2C 0x54     level 2
    pds_$add_label_loc                       0x06AC84 0x4E     level 2
    pds_$make_label_rec                      0x06ABF4 0x6A     level 2
    pds_$add_file_entry                      0x06AA7C 0x80     level 2
    pds_$make_file_table                     0x06AA0C 0x4C     level 2
    pds_$make_file_entry                     0x06A994 0x50     level 2
    pds_$add_dependent_type_to_alias_rec     0x06A864 0x60     level 2
    pds_$make_alias_rec                      0x06A7D4 0x6A     level 2
    pds_$add_arg_to_signature                0x06A66C 0x74     level 2
    pds_$make_arg                            0x06A5EA 0x54     level 2
    pds_$add_arg_attr                        0x06A546 0x50     level 2
    pds_$make_arg_attr                       0x06A524 0x22     level 2
    pds_$make_signature_rec                  0x06A4B8 0x6C     level 2
    pds_$add_entry_point_loc                 0x06A410 0x4E     level 2
    pds_$make_entry_rec                      0x06A324 0x8A     level 2
    pds_$add_var_loc                         0x06A284 0x4E     level 2
    pds_$make_variable_rec                   0x06A18C 0x8A     level 2
    pds_$add_var_attr                        0x06A0A4 0x66     level 2
    pds_$make_var_attr                       0x06A082 0x22     level 2
    pds_$make_pointer_rec                    0x069FE2 0x6A     level 2
    pds_$make_type                           0x069EB4 0x80     level 2
    pds_$make_loc                            0x069DB4 0x80     level 2
    pds_$make_src_loc                        0x069CE8 0x64     level 2
    pds_$make_name                           0x069C60 0x60     level 2

### `lang/common/source/spos.pas`

- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/common/source/spos.pvt.pas`
- include `//lang/common/source/ass.ins.pas`
- include `//lang/common/source/diag.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`

    calculate_source_position                0x071DA0 0x92     level 2
    spos_$capture_file_marks                 0x072D68 0x52     level 2
    spos_$apply_over_marked_source_files     0x072D14 0x54     level 2
    spos_$apply_over_source_files            0x072CC2 0x52     level 2
    spos_$number_of_marked_source_files      0x072CAA 0x18     level 2
    spos_$lock_source_file_marks             0x072C90 0x1A     level 2
    spos_$number_of_source_files             0x072C76 0x1A     level 2
    spos_$region_is_marked                   0x072DBA 0x72     level 2
    spos_$mark_main_source_file              0x072C54 0x22     level 2
    spos_$mark_source_file                   0x072B1C 0x86     level 2
    spos_$diag_dump_source_position_database 0x073164 0xAE     level 2
    spos_$diag_dump_source_position          0x0730DC 0x62     level 2
    spos_$diag_dump_source_region            0x072E8E 0x14C    level 2
    spos_$region_unit_name                   0x072A6C 0x4E     level 2
    spos_$region_dtm                         0x0729C2 0x4E     level 2
    spos_$region_full_path_name              0x07290E 0x4E     level 2
    spos_$region_name_used_to_open           0x072856 0x4E     level 2
    spos_$region_user_name                   0x0727A6 0x4E     level 2
    spos_$last_source_region                 0x07278C 0x1A     level 2
    spos_$encode_source_position             0x0725C4 0x116    level 2
    spos_$decode_source_position             0x072544 0x80     level 2
    spos_$line_is_in_main_source_file        0x072528 0x1C     level 2
    spos_$is_main_source_file                0x07250C 0x1C     level 2
    spos_$change_file                        0x072378 0xAE     level 2
    spos_$resume_file                        0x07204A 0x164    level 2
    spos_$may_start_include_file             0x072024 0x26     level 2
    spos_$start_include_file                 0x071EAE 0xE2     level 2
    spos_$skip_lines                         0x071E86 0x28     level 2
    spos_$enquire_next_line                  0x071E5A 0x2C     level 2
    spos_$next_line                          0x071E32 0x28     level 2
    spos_$init_source_position               0x071C70 0xCC     level 2

### `lang/common/source/std.pas`

- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/diag.ins.pas`

    std_$diag_dump_var_string                0x07350A 0x32     level 2
    std_$append_integer                      0x073484 0x86     level 2
    std_$append_string                       0x073448 0x3C     level 2
    std_$append_char                         0x073424 0x24     level 2
    std_$diag_dump_any_string                0x0733C4 0x58     level 2
    std_$diag_dump_boolean                   0x07338A 0x2A     level 2
    std_$round_up_to_multiple_of             0x07333C 0x4E     level 2
    std_$in_range_lower_minus_1_to_upper_plus_1 0x07330C 0x30     level 2
    std_$in_range_lower_minus_1_to_upper     0x0732DC 0x30     level 2
    std_$in_range_lower_to_upper_plus_1      0x0732AC 0x30     level 2
    std_$in_range_lower_to_upper             0x07327C 0x30     level 2

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

    token_$identifier                        0x073804 0x76     level 2
    token_$diag_dump_char_string             0x073902 0x8E     level 2
    token_$char_string                       0x073782 0x4C     level 2
    token_$double_float_to_constant          0x073756 0x2C     level 2
    token_$single_float_to_constant          0x073716 0x40     level 2
    token_$discrete_scalar_to_constant       0x0736FE 0x18     level 2
    token_$discrete_scalar                   0x073688 0x76     level 2
    token_$constant_byte_size                0x07353C 0xEC     level 2

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

    merge_assignments                        0x0D3984 0x1E2    level 2
    assert_merge_would_produce_misleading_aliasing 0x0D393C 0x48     level 2
    assign_opt                               0x0D4046 0x6E8    level 2
    at_offset                                0x0D3F62 0xE4     level 3
    ok_node                                  0x0D3D6E 0x1DA    level 3
    var_is_ok                                0x0D3C22 0x14C    level 3
    cplong                                   0x0D3BF2 0x30     level 3
    cpword                                   0x0D3BC4 0x2E     level 3
    cpbyte                                   0x0D3BAC 0x18     level 3

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

    cse_$cse_two_nodes                       0x0D5838 0xA4     level 2
    assert_zombie_tree                       0x0D5812 0x26     level 2
    cse_$is_cseable                          0x0D50F8 0x710    level 2
    cse_$set_hoistability                    0x0D50AE 0x4A     level 2
    assert_disp_over_ptr                     0x0D5082 0x2C     level 2
    cse_$next_cse_serial                     0x0D5024 0x5E     level 2
    cse_$cleanup_phase                       0x0D4E80 0x1A4    level 2
    check_uplevel_and_moved_check            0x0D4E32 0x4E     level 2
    walkopr                                  0x0D49FC 0x1F6    level 2
    saveparent_and_patch                     0x0D49C6 0x36     level 2
    patch                                    0x0D4906 0xC0     level 2
    make_cse_parent                          0x0D482E 0xD8     level 2
    moved_check                              0x0D4DE0 0x52     level 2
    make_cse_use                             0x0D4748 0xE6     level 2
    csecleanup                               0x0D4C12 0x1CE    level 2
    cse                                      0x0D58DC 0x97E    level 2

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

    squash_this_eval_operand                 0x0D6334 0x22     level 2
    assert_is_useless_under_eval             0x0D6312 0x22     level 2
    assert_is_explicitly_useless_object      0x0D62CA 0x2E     level 2
    assert_is_scrutable_tree_not_used_elsewhere 0x0D6296 0x34     level 2
    assert_is_a_variable                     0x0D6274 0x22     level 2
    opt_gen_$prune_eval_operands             0x0D6356 0x7E     level 2
    general_opts                             0x0D64F2 0x4CA    level 2
    find_var                                 0x0D6A0E 0x7C     level 2
    is_scale_candidate                       0x0D63D4 0x11E    level 2

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

    for_check                                0x0D8240 0x16E    level 2
    lvanalyze                                0x0D80AE 0x192    level 2
    buildsets                                0x0D7E8A 0x224    level 2
    varcheck                                 0x0D7ACE 0x39A    level 2
    addvaruse                                0x0D7A2C 0xA2     level 2
    assign_elim                              0x0D7302 0x72A    level 2
    stmtwalk                                 0x0D71BC 0x12C    level 2
    elim_chains                              0x0D70BA 0x102    level 2
    build_du_chains                          0x0D6ED0 0x1EA    level 2
    check_cse_uses                           0x0D6E24 0xAC     level 2
    remove_bad_parents                       0x0D6D1E 0x106    level 2
    pwalk                                    0x0D6C08 0x116    level 2
    ensure_parental_correctness              0x0D6BD0 0x38     level 2
    bad_parent                               0x0D6BA6 0x2A     level 2
    opt_livevar_$report_removal              0x0D6B46 0x60     level 2
    opt_livevar_$store_to_stack_temp         0x0D6B10 0x36     level 2
    opt_livevar_$formal_value_param_copy     0x0D6AC2 0x4E     level 2
    opt_livevar_$find_nearest_spos_node      0x0D6A8C 0x36     level 2
    liveanalysis                             0x0D83AE 0x5B2    level 2

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

    findlooptail                             0x0DA402 0x4C     level 2
    moveinvariants                           0x0D9A22 0x9DA    level 2
    movenode                                 0x0D9814 0x20C    level 2
    notalreadymoved                          0x0D96CE 0x146    level 2
    checkcses                                0x0D8C0E 0x702    level 2
    do_move_check                            0x0D8AE0 0x12E    level 2
    assert_contains_ref_to_sr_temp           0x0D8960 0x180    level 2
    motion_constants                         0x0DAA8C 0x1FC    level 2
    walkt                                    0x0DA874 0x208    level 3
    loopopt                                  0x0DA44E 0x426    level 2
    fixupchildren                            0x0D93E4 0x2EA    level 2
    add_constant                             0x0D935E 0x86     level 2

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

    init_opt_info_for_vars                   0x0DEF32 0x384    level 2
    use_def_proc                             0x0DED62 0x184    level 2
    add_def_for_params_at_routine_entry      0x0DED0C 0x56     level 2
    add_use_defs_for_statics_and_params      0x0DEB72 0x19A    level 2
    assert_defined_on_entry                  0x0DEA34 0x13E    level 2
    opt_main_$var_is_param_of_routine        0x0DE9DA 0x5A     level 2
    add_use_defs_for_call_site               0x0DE848 0x192    level 2
    create_use_def_ob                        0x0DE6D4 0x174    level 2
    opt_main_$strip_all_use_def_obs          0x0DE598 0x98     level 2
    reviseuses                               0x0DE402 0x196    level 2
    distribute                               0x0DE32E 0xD4     level 2
    dwalk                                    0x0DE1C0 0x16E    level 2
    convert_exponentiation                   0x0DDFB2 0x1F4    level 2
    distrib_mul                              0x0DDA32 0x56C    level 2
    fixup_rlen_of_mul                        0x0DD8F2 0x116    level 3
    crush_disp_2                             0x0DD868 0x8A     level 3
    possible_rlens_of_operand                0x0DD7B0 0xB8     level 3
    convert_lshf_to_mul                      0x0DD75A 0x56     level 3
    no_enforce_parens_and_ucs_eq_1           0x0DD6CE 0x8C     level 3
    recover_scaled                           0x0DD5BA 0x114    level 2
    recover                                  0x0DD230 0x38A    level 2
    makedindex                               0x0DD118 0x118    level 2
    coalesce_adjacent_and_eliminate_dead_assignments 0x0DD070 0xA8     level 2
    eliminate_dead_code_and_count_basic_blocks 0x0DCEA2 0x1CE    level 2
    recompute_usedef_for_uplevel_addressing  0x0DCCC4 0x1DE    level 2
    recompute_usedef_for_strength_reduction  0x0DCB9C 0x128    level 2
    compute_basic_block_dominance_relationships 0x0DCAD2 0xCA     level 2
    compute_preds_and_succs_for_dominance    0x0DC994 0x13E    level 2
    compute_dominator_matrix                 0x0DC8C6 0xCE     level 2
    compute_depth_first_order_of_basic_blocks 0x0DC7F6 0xD0     level 2
    compute_basic_block_relationships        0x0DC708 0xEE     level 2
    compute_abnormality_due_to_proc_calls    0x0DC47C 0x234    level 2
    assert_is_call_to_abnormal_routine       0x0DC3C6 0xB6     level 2
    assert_is_pointer_deref_of_volatile_object 0x0DC3A6 0x20     level 2
    assert_cleanup_body                      0x0DC354 0x26     level 2
    compute_successors                       0x0DC212 0xDC     level 2
    resolve_nlbranch_targets                 0x0DC146 0x9A     level 2
    killvisited                              0x0DC0C2 0x6A     level 2
    recompute_stmt_nodes                     0x0DC054 0x6E     level 2
    initialize_stmt_nodes                    0x0DBFA2 0xA6     level 2
    check_dominators                         0x0DBE74 0x12E    level 2
    compute_variable_type_descriptors        0x0DBD58 0x11C    level 2
    compute_label_backward_refs_due_to_assigned_goto 0x0DBCCC 0x8C     level 2
    assert_is_lexically_earlier_statement    0x0DBC7C 0x50     level 2
    assert_is_fortran_assigned_goto          0x0DBC42 0x3A     level 2
    assert_is_nonlocal_branch                0x0DBC2A 0x18     level 2
    add_successor                            0x0DBB78 0x8A     level 2
    add_predecessor                          0x0DBB2A 0x4E     level 2
    new_successor_list                       0x0DBA62 0x60     level 2
    new_basic_block                          0x0DB98E 0xA2     level 2
    mark_begins_basic_block                  0x0DB918 0x2E     level 2
    mark_if_begins_basic_block               0x0DB872 0x5C     level 2
    assert_reached_by_linear_flow_from_previous_basic_block 0x0DB818 0x5A     level 2
    assert_is_unsafe_abnormal_label          0x0DB7F2 0x26     level 2
    assert_is_assigned_goto_label            0x0DB7B0 0x42     level 2
    assert_is_abnormal_label                 0x0DB78A 0x26     level 2
    assert_is_entry_label                    0x0DB754 0x36     level 2
    assert_is_entry_block_entry              0x0DB72A 0x2A     level 2
    assert_is_entry_block                    0x0DB712 0x18     level 2
    assert_is_predecessor                    0x0DB68C 0x86     level 2
    opt_main_$collapse_fortran_complex_assigns 0x0DB558 0x134    level 2
    opt_main_$complex_intrinsic_decomposition 0x0DB4A4 0xB4     level 2
    opt_main_$complex_decomposition          0x0DB2F8 0x1AC    level 2
    assert_is_call_tree                      0x0DB294 0x32     level 2
    assert_is_fortran_temp                   0x0DB26A 0x2A     level 2
    assert_is_fortran_symbol                 0x0DB252 0x18     level 2
    assert_is_var_name                       0x0DB23A 0x18     level 2
    assert_is_a_variable                     0x0DB218 0x22     level 2
    assert_statement_is_interesting_in_postorder_node_list 0x0DB1E0 0x38     level 2
    new_postorder_node_list_entry            0x0DB1A4 0x3C     level 2
    realloc_postorder_node_list              0x0DB07C 0xA2     level 2
    assert_is_artificial_statement           0x0DB03C 0x40     level 2
    assert_is_branch_to_artificial_label     0x0DB01C 0x20     level 2
    assert_is_conditional_branch_to_artificial_label 0x0DAFDA 0x42     level 2
    assert_is_unconditional_branch_to_artificial_label 0x0DAF9A 0x40     level 2
    assert_is_artificial_label               0x0DAF68 0x32     level 2
    assert_is_childless_eval                 0x0DAF50 0x18     level 2
    assert_is_label                          0x0DAF38 0x18     level 2
    assert_is_branch                         0x0DAF1A 0x1E     level 2
    assert_is_unconditional_branch           0x0DAEF8 0x22     level 2
    assert_is_conditional_branch             0x0DAEE0 0x18     level 2
    assert_is_top_level_statement            0x0DAE9C 0x26     level 2
    assert_is_defined_spos                   0x0DAE8C 0x10     level 2
    dispose_postorder_node_list              0x0DAE7A 0x12     level 2
    alloc_postorder_node_list                0x0DAE54 0x26     level 2
    dispose_hoist                            0x0DAE3A 0x1A     level 2
    alloc_hoist                              0x0DAE1E 0x1C     level 2
    alloc_block_list                         0x0DADF8 0x26     level 2
    zero_bytes                               0x0DADA2 0x56     level 2
    zero_longwords                           0x0DAD8E 0x14     level 2
    estimate_register_consumption_of_all_statements 0x0DAD42 0x4C     level 2
    limit_of_cse_backwards_reach             0x0DAD1E 0x24     level 2
    assert_language_on_il_spine_is_ada       0x0DACD8 0x46     level 2
    assert_common_subexpression_phase_is_enabled 0x0DACC0 0x18     level 2
    assert_optimizer_is_enabled              0x0DAC88 0x38     level 2
    opt_main_$symidx_of_varn_or_fsym         0x0DE630 0x5C     level 2
    opt_main_$is_fortran_asf                 0x0DEEE6 0x4C     level 2
    opt_main_$ensure_var_set                 0x0DB2C6 0x32     level 2
    fixup_blocks                             0x0DF2B6 0x1A2    level 2
    g_opt                                    0x0E0D46 0x9FA    level 2
    recompute_node_lists                     0x0E0CD0 0x76     level 3
    make_new_postorder_node_list             0x0E04B0 0x820    level 3
    add_interior_node_to_postorder_node_list 0x0DFFE2 0x4CE    level 3
    note_variable_use                        0x0DFF7C 0x66     level 3
    count_for_postorder_node_list            0x0DFCE6 0x296    level 3
    count_interior_nodes_for_postorder_node_list 0x0DF4E4 0x7FC    level 3
    crush_undesired_extend                   0x0DF48E 0x56     level 4
    find_eval                                0x0DF458 0x36     level 3
    opt_main_$initialize                     0x0E1740 0xD8     level 2

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

    statement_contained_by_unreachable_basic_block 0x0E4158 0x84     level 2
    assert_is_dominated_by_some_entrypoint   0x0E4120 0x38     level 2
    assert_block_is_entrypoint               0x0E4102 0x1E     level 2
    assert_predecessor_is_me                 0x0E40E4 0x1E     level 2
    assert_no_predecessors                   0x0E40CE 0x16     level 2
    evalforeffect                            0x0E328C 0xE28    level 2
    propagate                                0x0E308E 0x1FE    level 3
    build_ud_chains                          0x0E28B0 0x1D2    level 2
    make_ud_chain                            0x0E26E6 0x182    level 2
    compute_rd                               0x0E24D4 0x212    level 2
    genkill                                  0x0E22A4 0xB8     level 2
    add_def_stmt                             0x0E21E0 0xC4     level 2
    bclr                                     0x0E1EC8 0x4A     level 2
    bset                                     0x0E1E80 0x48     level 2
    zero_bytes                               0x0E1E2A 0x56     level 2
    zero_longwords                           0x0E1E16 0x14     level 2
    dumprd                                   0x0E1CC8 0xF4     level 2
    dumprdset                                0x0E1BF0 0xD4     level 2
    dbs                                      0x0E1B26 0xC6     level 2
    pt                                       0x0E1AF4 0x32     level 2
    assert_this_definition_on_ud_chain       0x0E1AB6 0x3E     level 2
    assert_nonempty_var_use_set              0x0E1A98 0x1E     level 2
    assert_uninitialized_value_can_reach     0x0E1980 0x118    level 2
    assert_def_dominates_use                 0x0E193E 0x42     level 2
    basic_block_of_def                       0x0E1908 0x36     level 2
    stmt_index_from_rdset                    0x0E18E0 0x28     level 2
    releaserd                                0x0E1F12 0x54     level 2
    reachingdefinitions                      0x0E462C 0x10A8   level 2
    init_block                               0x0E4316 0x316    level 3
    ftn_data_init                            0x0E4250 0xC6     level 3
    paramclass                               0x0E235C 0x178    level 2
    markuses                                 0x0E2E94 0x1FA    level 2
    walk_tree                                0x0E2A82 0x3C4    level 3
    make_motioned_ud_chain                   0x0E2868 0x48     level 2
    initrd                                   0x0E2020 0x1C0    level 2
    alloc_rdset                              0x0E1F66 0xBA     level 3
    adjust_ptr                               0x0E1DDC 0x3A     level 2

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

    eval                                     0x0E575E 0x24     level 2
    compress                                 0x0E5712 0x4C     level 2
    resetserial                              0x0E56D4 0x3E     level 2
    select_loop                              0x0E58FC 0xA2     level 2
    find_loops                               0x0E5D0A 0x182    level 2
    dfs                                      0x0E59F8 0x74     level 2
    dominators                               0x0E5B70 0x19A    level 2
    dom                                      0x0E5782 0x58     level 2
    depth_first_dom                          0x0E5A6C 0x104    level 2
    new_block                                0x0E599E 0x5A     level 2
    select_block_list                        0x0E57DA 0x122    level 2

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

    reduce                                   0x0EACC8 0xE28    level 2
    minimally_size_sr_temp                   0x0EAC16 0xB2     level 2
    dump_induction_variables                 0x0EA96E 0x23E    level 2
    recognize_induction_variables            0x0EA71E 0x250    level 2
    newindvar                                0x0EA674 0xAA     level 2
    cand_exprs                               0x0EA562 0x112    level 2
    testexits                                0x0EA3A0 0x1C2    level 2
    exitwalk                                 0x0EA292 0x10E    level 3
    fetch_uc                                 0x0EA248 0x4A     level 3
    disqualify                               0x0EA0D8 0x156    level 2
    walkexpr                                 0x0E9FAA 0x12E    level 2
    removeexpr                               0x0E9F58 0x52     level 2
    newexpr                                  0x0E9EB4 0xA4     level 2
    removeflag                               0x0E9E74 0x40     level 2
    setflag                                  0x0E9E34 0x40     level 2
    create_sr_temp_var                       0x0E9CBA 0x17A    level 2
    opt_str_$make_name                       0x0E9C50 0x66     level 2
    findvalues                               0x0E90F6 0xB5A    level 2
    noincfound                               0x0E9062 0x94     level 3
    not_on_ud_chain                          0x0E8FFC 0x66     level 3
    getval                                   0x0E8E18 0x1CA    level 2
    add_assign                               0x0E8912 0x506    level 2
    elimuses                                 0x0E8798 0x17A    level 2
    autoinc                                  0x0E8176 0x39A    level 2
    checkauto                                0x0E7F74 0x202    level 2
    find_assigns                             0x0E7EA8 0xCC     level 2
    check_dindex                             0x0E7DB4 0xF4     level 2
    opt_str_$is_loop_invariant               0x0E7CEA 0xB0     level 2
    check_tree_node                          0x0E7BFE 0xD2     level 2
    doinsert                                 0x0E79FC 0x200    level 2
    match_rlens_srtemp_and_assign            0x0E790A 0xF2     level 2
    ptrsub                                   0x0E776A 0xFA     level 2
    substitute_ptr_for_target                0x0E7564 0x104    level 2
    subwalk                                  0x0E7668 0x102    level 2
    used_outside_loop                        0x0E73BE 0x1A6    level 2
    usewalk                                  0x0E729C 0x122    level 3
    combine_temps                            0x0E70A6 0x1F6    level 2
    opt_str_$trees_equivalent                0x0E6F30 0x176    level 2
    verify_increments                        0x0E6D7E 0x1B2    level 2
    stmtfound                                0x0E6C6E 0x110    level 2
    substitute                               0x0E6AA4 0x1CA    level 2
    unlinkstmts                              0x0E69A0 0x104    level 2
    multidim                                 0x0E689C 0x104    level 2
    is_invariant_srtemp                      0x0E6840 0x5C     level 2
    transformtemps                           0x0E676A 0xD6     level 2
    opt_str_$opmod1_of_multiplier            0x0E61D6 0x24     level 2
    opt_str_$is_loop_constant_integer        0x0E5E8C 0xC2     level 2
    walkuses                                 0x0E852A 0x26E    level 2
    strengthreduce                           0x0EBAF0 0x35C    level 2
    opt_str_$product_of_consts               0x0E5F74 0xC2     level 2
    opt_str_$product_of                      0x0E63D2 0x25E    level 2
    smuggle_constants                        0x0E6290 0x142    level 3
    identity_mul                             0x0E61FA 0x96     level 3
    opt_str_$opmod_of_operand                0x0E606C 0x132    level 2
    sizeof_dataclass                         0x0E6036 0x36     level 3
    delparent                                0x0E78B8 0x52     level 2
    deluse                                   0x0E7864 0x54     level 2
    opt_str_$add_substitution_point          0x0E66B6 0xB4     level 2
    opt_str_$set_substitution_point          0x0E6656 0x60     level 2

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

    formal_may_alias_actual                  0x0747C8 0x110    level 2
    assert_is_fortran_external_routine_parameter 0x074792 0x36     level 2
    build_alias_desc                         0x0744D0 0xD4     level 2
    check_the_ind                            0x073CAE 0x8A     level 2
    alias_ptr_node                           0x073A22 0x248    level 2
    is_display_ptr                           0x0739E4 0x3E     level 2
    get_alias_desc                           0x073D38 0x758    level 2
    alias_$related_call                      0x074F46 0x3C4    level 2
    alias_$descriptors_are_identical         0x074E7A 0xCC     level 2
    alias_$classes_may_be_related            0x074D50 0xB2     level 2
    alias_$unrelated_or_exact                0x074D1A 0x36     level 2
    alias_$related                           0x074CE6 0x34     level 2
    alias_$relationship                      0x074964 0x322    level 2
    alias_$ref_may_generate_exception        0x074E34 0x46     level 2
    alias_$add_disp                          0x0746E2 0x2E     level 2
    alias_$alias_desc_with_size              0x074688 0x2C     level 2
    alias_$basic_alias_desc                  0x0746B4 0x2E     level 2
    alias_$ind_for_captured_lvalue           0x074710 0x82     level 2
    alias_$get_alias_desc                    0x0745A4 0xE4     level 2

### `lang2/source/lt_utils/source/arith.pas`

- include `//lang2/source/lt_utils/source/arith.ins.pas`

    arith                                    0x075350 0x16E    level 2
    add_middle                               0x07530C 0x44     level 3

### `lang2/source/lt_utils/source/bug_check.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`
- include `//us/us/sys/ins/pfm.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    unimplemented                            0x0755AA 0x6E     level 2
    ok_or_bug_check                          0x075538 0x72     level 2
    bug_check                                0x0754C0 0x6E     level 2

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

    implicit_atomicness                      0x075F18 0x58     level 2
    user_atomicness                          0x075E7A 0x5C     level 2
    contains_same_lvalue                     0x075D8E 0xD2     level 2
    aop_to_mem                               0x075AAC 0x29E    level 2
    aop_pattern_search                       0x07593A 0x158    level 2
    pack_aop_to_mem                          0x07561C 0x280    level 2
    commit_top_$convert_aops_to__aop_to_mem  0x075FB8 0x134    level 2

### `lang2/source/ftn/source/const_op.ftn`


    c16_neg                                  0x07661A 0x3E     level 1
    c16_div                                  0x0765D8 0x42     level 1
    c16_mul                                  0x076596 0x42     level 1
    c16_sub                                  0x076554 0x42     level 1
    c16_add                                  0x076512 0x42     level 1
    r8i4_expon                               0x0764CE 0x44     level 1
    r8_expon                                 0x07648C 0x42     level 1
    c8_neg                                   0x076452 0x3A     level 1
    c8_div                                   0x076414 0x3E     level 1
    c8_mul                                   0x0763D6 0x3E     level 1
    c8_sub                                   0x076398 0x3E     level 1
    c8_add                                   0x07635A 0x3E     level 1
    r8_math                                  0x0761DA 0x180    level 1
    long_expon                               0x0761A4 0x36     level 1

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

    delay_$shrink_tree_node                  0x077A20 0x102A   level 2
    delay_$propagate_index_long              0x077968 0xB8     level 2
    is_indexer                               0x077946 0x22     level 3
    shrink_divide_operand                    0x07782E 0x118    level 2
    delay_sets                               0x0775EC 0x238    level 2
    resize_set                               0x077558 0x94     level 3
    paramrlen                                0x077250 0x308    level 2
    delay_$tailor_operands_to_hardware       0x076ECA 0x258    level 2
    delay_$find_size_and_signed              0x0766D8 0x158    level 2
    delay                                    0x078A64 0x61A    level 2
    delay_$value_guaranteed_between          0x076658 0x66     level 2
    delay_$splice                            0x077158 0xDE     level 2
    delay_$divide_attributes                 0x0769AA 0x4F4    level 2
    delay_$divide_table_dimension            0x07683C 0x13E    level 3
    delay_$shrink_top_level_node             0x07907E 0xEE     level 2

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

    do_report                                0x07916C 0x168    level 2

### `lang/lang/source/gen_debug.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/dst.ins.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/lang/source/real_globals.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`

    emit_line_pc_packet                      0x07986A 0x102    level 2
    sum_sect_buffers                         0x079756 0x44     level 2
    gen_debug_$copy_buffer                   0x0794D8 0x52     level 2
    gen_debug_$emit_bytes                    0x07944C 0x8C     level 2
    page_is_full                             0x0793F6 0x56     level 3
    gen_debug_$flush_buffer                  0x079384 0x72     level 2
    gen_debug_$flush_one_block               0x079328 0x5C     level 2
    current_sect_offset_of_buf               0x0792FE 0x2A     level 2
    current_coff_offset_of_buf               0x0792D4 0x2A     level 2
    gen_debug_$set_active_buffer             0x079C26 0x44     level 2
    gen_debug_$lines_return                  0x079F76 0x38     level 2
    gen_debug_$lines_entry                   0x079F2C 0x4A     level 2
    gen_debug_$lines_stmt_end                0x079EEA 0x42     level 2
    gen_debug_$lines_def                     0x079E34 0xB6     level 2
    statement_switch                         0x079DF0 0x44     level 3
    file_switch                              0x079D86 0x6A     level 3
    gen_debug_$exception_site                0x079D0A 0x7C     level 2
    gen_debug_$exception_table_close         0x079C82 0x88     level 2
    gen_debug_$exception_table_size          0x079C6A 0x18     level 2
    gen_debug_$range_close                   0x079B44 0xE2     level 2
    gen_debug_$range_open                    0x07996C 0x1D8    level 2
    gen_debug_$end_compilation               0x07981C 0x4E     level 2
    gen_debug_$ready_output                  0x079714 0x42     level 2
    gen_debug_$end_pass                      0x0797DC 0x40     level 2
    even_buffer                              0x07979A 0x42     level 3
    gen_debug_$begin_pass                    0x0796C2 0x52     level 2
    gen_debug_$begin_compilation             0x07961A 0x74     level 2
    init_buffers                             0x079594 0x86     level 3
    buffers_ala_mode                         0x079570 0x24     level 3
    gen_debug_$set_file_index                0x079550 0x20     level 2
    gen_debug_$read_file_index               0x07952A 0x26     level 2

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

    do_patches                               0x07A04E 0x60     level 2
    make_sure_frame_is_written               0x07A008 0x46     level 3
    allocate                                 0x079FC6 0x42     level 2
    gen_exception_$new_exception             0x079FB0 0x16     level 2
    gen_exception_$end_table                 0x07A7FE 0x84     level 2
    gen_exception_$write_frame_and_handler_records 0x07A1AE 0x4DC    level 2
    add_to_patch_list                        0x07A178 0x36     level 3
    gen_exception_$begin_exception_compilation 0x07A0AE 0x5A     level 2

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

    reg_mask_is_contiguous                   0x07AA42 0x9E     level 2
    gen_unwind_$dispose_all_unwind           0x07A910 0x10     level 2
    gen_unwind_$new_exception                0x07A8FA 0x16     level 2
    gen_unwind_$new_unwind                   0x07A8E4 0x16     level 2
    gen_unwind_$end_compilation              0x07C392 0x32     level 2
    gen_unwind_$add_exception_table_entry    0x07C12E 0xA6     level 2
    gen_unwind_$dump_exception_table         0x07C2D2 0x78     level 2
    sub_one                                  0x07C24C 0x86     level 3
    gen_unwind_$add_scope                    0x07A920 0x122    level 2
    gen_unwind_$dump_unwind_table            0x07C0AE 0x80     level 2
    psect_rec_dump                           0x07BFA0 0xD4     level 3
    write_unwind_header_recs                 0x07BE44 0x15C    level 4
    scope_rec_dump                           0x07BBCA 0x24E    level 3
    write_padding                            0x07BB04 0x7C     level 3
    write_range_rec                          0x07B9CA 0x13A    level 3
    write_unwind_info_rec                    0x07AF6C 0x960    level 3
    unwind_record_kind_sr10_3                0x07AD34 0x1C0    level 3
    unwind_record_kind_sr10_0                0x07ABDE 0x94     level 3
    allocate                                 0x07AB88 0x56     level 3
    add_skips                                0x07AAE0 0xA8     level 3
    gen_unwind_$begin_compilation            0x07A884 0x46     level 2

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

    change_name_lower_case                   0x07C966 0x92     level 2
    inlib_error                              0x07C3C4 0x17A    level 2
    gen_utils_$alloc_new_addr_con            0x07D414 0xB2     level 2
    add_dsect                                0x07D1D4 0x7A     level 2
    add_psect                                0x07D15C 0x78     level 2
    check_section_name                       0x07D0C4 0x98     level 2
    name_match                               0x07D022 0xA2     level 3
    get_external_ref                         0x07D3B6 0x5E     level 2
    get_transfer_vector                      0x07D2EE 0xC8     level 2
    get_id_name                              0x07D24E 0x7E     level 3
    make_xdynm_ptr                           0x07CF2E 0xF4     level 2
    get_xdynm_ptr                            0x07CECE 0x60     level 2
    find_ac_dsect                            0x07CE7A 0x54     level 2
    get_proc_addr_con                        0x07CD52 0x10E    level 2
    make_abs_addr_con                        0x07C5C6 0x78     level 2
    make_new_addr_con                        0x07C9F8 0x344    level 2
    check_for_addr_con                       0x07C63E 0x2AE    level 2
    get_addr_con                             0x07C8EC 0x7A     level 2
    inlib_add                                0x07C59C 0x2A     level 2
    inlib_term                               0x07C582 0x1A     level 2
    inlib_init                               0x07C552 0x2C     level 2

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

    gspace_$close                            0x07D72C 0x20     level 2
    gspace_$open                             0x07D4C8 0x2A     level 2
    gspace_$release                          0x07D66C 0xC0     level 2
    gspace_$mark                             0x07D64E 0x1E     level 2
    gspace32                                 0x07D51C 0x132    level 2
    gspace                                   0x07D4F2 0x2A     level 2

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

    initialize_module                        0x07D74C 0x244    level 2

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

    il_utils_$search_tree_for_node           0x07E3D4 0x2A     level 2
    search_point                             0x07E206 0x4C     level 3
    search_walk                              0x07E252 0x182    level 3
    il_utils_$trees_equivalent               0x07E578 0x23C    level 2
    il_utils_$src_line                       0x07E4CC 0x70     level 2
    il_utils_$source_generated_top_level_node 0x07E3FE 0x68     level 2
    il_utils_$is_strength_reduction_temp     0x07E1CA 0x3C     level 2
    il_utils_$tree_node_operand_is_spine     0x07E184 0x46     level 2
    il_utils_$do_substitution                0x07E092 0xD8     level 2
    il_utl_$count_vars                       0x07DBA2 0x156    level 2
    il_utl_$classify_variable                0x07D9A4 0x1FE    level 2
    il_utils_$set_uc_walk_spine              0x07E03A 0x58     level 2
    il_utils_$adjust_uc                      0x07DCF8 0x320    level 2
    adjust_uc                                0x07E018 0x22     level 2

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

    print_basic_block                        0x085694 0x384    level 2
    advance_and_print                        0x085616 0x7E     level 2
    begins_inline_block                      0x0855B0 0x66     level 2
    print_data_node                          0x0851FA 0x310    level 2
    print_top_node                           0x083462 0x167E   level 2
    write_68k_register_name                  0x0833EA 0x72     level 2
    print_routine_block                      0x082560 0xA30    level 2
    print_exception_frame                    0x08227E 0x218    level 2
    print_variable                           0x080F80 0xB46    level 2
    print_tree_exp                           0x07FD94 0xDAC    level 2
    print_spine                              0x0851C4 0x36     level 2
    print_tree_ref                           0x07F8EE 0x434    level 2
    print_known_aux                          0x07F76E 0x128    level 2
    print_opmod_use                          0x07F43A 0x29E    level 2
    print_math                               0x07F1CE 0x1F0    level 2
    print_relational                         0x07F04E 0x160    level 2
    print_rlen                               0x07EECC 0x122    level 2
    print_uc_and_phase                       0x07EE44 0x80     level 2
    prtphasebits                             0x07EB20 0x292    level 2
    print_object_ptr                         0x07EAF0 0x30     level 2
    print_comma                              0x07EABA 0x36     level 2
    print_bool                               0x07EA9A 0x20     level 2
    print_hex                                0x07EA6A 0x30     level 2
    print_integer                            0x07EA38 0x32     level 2
    print_string                             0x07E9DC 0x5C     level 2
    print_3_chars                            0x07E97E 0x5E     level 2
    print_2_chars                            0x07E936 0x48     level 2
    print_char                               0x07E906 0x30     level 2
    break_line                               0x07E8CA 0x3C     level 2
    print_ln                                 0x07E890 0x3A     level 2
    finialise_list_tree                      0x07E878 0x18     level 2
    fresh_ln                                 0x07E7E8 0x8C     level 2
    initialise_list_tree                     0x07E7C0 0x28     level 2
    list_tree_$sanity_check                  0x0865E8 0x68     level 2
    sanity_check_walk                        0x086072 0x27A    level 3
    sanity_check_walk_spine                  0x086340 0x250    level 3
    sanity_check_bad_uc                      0x085F42 0xBC     level 3
    sanity_check_countdown                   0x085DAC 0xFA     level 3
    list_tree_$print_tree                    0x085CDA 0xB4     level 2
    list_tree_$print_whole_il                0x085ABA 0x220    level 2
    list_tree_$print_aux                     0x07F8B4 0x3A     level 2
    list_tree_$print_rlen                    0x07F024 0x2A     level 2

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

    loc_build__unknown_loc                   0x0876B2 0x1A     level 2
    loc_build__prism_mode_loc                0x0875D6 0xDC     level 2
    loc_build__m68k_indirect_loc             0x08749C 0x13A    level 2
    loc_build__relative_loc                  0x08737C 0x120    level 2
    loc_build__register_loc                  0x087284 0xF8     level 2
    loc_build__close_list                    0x0871F6 0x8E     level 2
    terminate_list                           0x0871BC 0x3A     level 2
    close_all_locs                           0x08714A 0x72     level 2
    close_all_ranges                         0x087100 0x4A     level 2
    close_range                              0x086FFA 0x106    level 2
    fix_stmt_based_list                      0x086F58 0xA2     level 2
    loc_put_clan_op                          0x086F28 0x30     level 2
    loc_put_family_op                        0x086DAA 0x17E    level 2
    nybble_pack                              0x086D3A 0x70     level 2
    loc_build__stmt_range                    0x086C84 0xB6     level 2
    loc_build__pc_range                      0x086BF6 0x8E     level 2
    loc_build__default                       0x086B92 0x64     level 2
    range_insert                             0x086B5E 0x34     level 2
    loc_build__close_pool                    0x086AD6 0x88     level 2
    loc_build__dump_pool                     0x086A3E 0x98     level 2
    fill_buffer                              0x0869AE 0x90     level 2
    next_dump_position                       0x086940 0x6E     level 2
    next_dump_string                         0x086902 0x3E     level 2
    loc_build__open_list                     0x0868A8 0x5A     level 2
    loc_build__pool_size                     0x086882 0x26     level 2
    loc_build__open_pool                     0x086868 0x1A     level 2
    loc_holder_dispose                       0x086800 0x68     level 2
    scrap                                    0x0867D4 0x2C     level 2
    loc_node_alloc                           0x086782 0x52     level 2
    loc_holder_alloc                         0x0866D4 0xAE     level 2
    pop_scrap                                0x0866BC 0x18     level 2
    push_scrap                               0x0866A8 0x14     level 2
    loc_build__init                          0x086650 0x58     level 2

### `lang2/source/lt_utils/source/mrh.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/ms.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang2/source/lt_utils/source/mrh.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`

    release_chunk_list                       0x087A7C 0x90     level 2
    allocate_new_chunk                       0x0877A8 0x252    level 2
    mrh_$release_all                         0x087EF0 0x3A     level 2
    mrh_$release_to_mark                     0x087F2A 0xCC     level 2
    mrh_$get_map                             0x087E3C 0x20     level 2
    mrh_$reset_chunks_in_use_max             0x087EA6 0x1C     level 2
    mrh_$chunks_in_use_max                   0x087E8E 0x18     level 2
    mrh_$chunks_in_use                       0x087E76 0x18     level 2
    mrh_$chunks_total                        0x087E5C 0x1A     level 2
    mrh_$bytes_used                          0x087DF2 0x4A     level 2
    mrh_$mark                                0x087EC2 0x2E     level 2
    mrh_$alloc_fixed                         0x087D94 0x5E     level 2
    mrh_$alloc                               0x087CD8 0x82     level 2
    mrh_$initialize                          0x087B7C 0xE8     level 2
    mrh_$initialize_module                   0x0876CC 0xCA     level 2

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

    copy_back                                0x089332 0x9E     level 2
    copy_the_sucker                          0x089270 0xC2     level 2
    create_temp_file                         0x089198 0xC2     level 2
    num_to_hex                               0x089178 0x20     level 3
    obj_$open                                0x089010 0x162    level 2
    make_bak_name                            0x088B50 0x84     level 2
    map_portion                              0x0889DE 0x172    level 2
    find_chan                                0x088966 0x78     level 2
    make_chan                                0x08888C 0xD6     level 2
    obj_$add_free                            0x08816C 0x58     level 2
    delete_free_list_entry                   0x088122 0x4A     level 2
    obj_$remove_free                         0x0880A8 0x7A     level 2
    check_init                               0x088028 0x52     level 2
    objio_cleanup_handler                    0x08A8F0 0xF6     level 2
    search_apollo_section_tables             0x08A59A 0x1A0    level 2
    search_apollo_global_tables              0x08A746 0x1A6    level 2
    obj_$inq_unix_ts                         0x088F2A 0xE6     level 2
    obj_$inq_ts                              0x088E3E 0xE4     level 2
    obj_$inq_type_uid                        0x088DFC 0x42     level 2
    obj_$set_length                          0x08A550 0x4A     level 2
    obj_$get_name                            0x08A3BC 0xB0     level 2
    obj_$map                                 0x08A46E 0xE2     level 2
    obj_$free                                0x08A11E 0xAC     level 2
    obj_$get                                 0x08A1CA 0x1F2    level 2
    obj_$put                                 0x088BD4 0x228    level 2
    obj_$close                               0x089E96 0x288    level 2
    obj_$open_r_tag                          0x089AB4 0x1C8    level 2
    obj_$open_r                              0x089C7E 0x218    level 2
    obj_$open_t                              0x08966E 0x444    level 2
    obj_$open_wl                             0x0894C8 0x1A6    level 2
    obj_$open_w                              0x0893D2 0xF4     level 2
    obj_$get_my_obj_info                     0x0883EA 0x474    level 2
    obj_$validate_object_module              0x0882A4 0x13E    level 2
    obj_$init_io                             0x0881C4 0xD8     level 2

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

    inlib_read_inlib                         0x08E310 0x11E    level 2
    inlib_read_obj_inlib                     0x08C6C6 0x41A    level 2
    inlib_read_coff_inlib                    0x08AD2A 0x57E    level 2
    extended_name_to_string                  0x08AC62 0xC4     level 2
    free_string                              0x08AC40 0x22     level 2
    get_string                               0x08AB78 0xC8     level 2
    get_coff_stringtab_info                  0x08AB08 0x6C     level 2
    object_target                            0x08AAC0 0x48     level 2
    inlib_list_add                           0x08A9E8 0xD0     level 2
    objutil_$inlib_find_symbol               0x08E8E0 0x36     level 2
    objutil_$inlib_find_section              0x08EA4A 0x30     level 2
    objutil_$inlib_terminate                 0x08EB74 0xC2     level 2
    objutil_$inlib_lookup_section            0x08EADC 0x98     level 2
    inlib_checklist                          0x08EA7A 0x62     level 3
    objutil_$inlib_lookup_symbol             0x08E976 0xD0     level 2
    inlib_checklist                          0x08E916 0x60     level 3
    objutil_$inlib_libname                   0x08E8B6 0x2A     level 2
    objutil_$inlib_init                      0x08E83A 0x7C     level 2

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

    anything_to_expand                       0x093F76 0xF0     level 2
    callee_status                            0x093C5E 0x318    level 2
    assert_routine_contains_symbolically_opaque_addressing 0x093BAE 0x54     level 2
    assert_statement_contains_symbolically_opaque_addressing 0x093AC4 0xEA     level 2
    assert_contains_symbolically_opaque_addressing 0x093968 0x15C    level 2
    assert_is_symbolically_opaque_address    0x0938F0 0x78     level 2
    check_call_sites_and_expand              0x093836 0xAE     level 2
    dfs_walk                                 0x09365C 0x1BE    level 2
    remove_call_graph_edge                   0x0935F8 0x64     level 2
    call_status                              0x093266 0x392    level 2
    cleanup_expansion                        0x0931FA 0x6C     level 2
    process_blocks                           0x092EEC 0x30E    level 2
    process_statements                       0x092E20 0xB0     level 2
    process_operand                          0x092228 0xBD8    level 2
    process_opr_ind                          0x091CAE 0x576    level 3
    process_index_opr                        0x091A1E 0x290    level 3
    apply_disp                               0x09196A 0xB4     level 3
    disp_offset                              0x091956 0x14     level 3
    adjust_disp                              0x09192E 0x28     level 3
    get_sym_ind_info                         0x0918BA 0x74     level 3
    substitutee_sym_ind                      0x091822 0x98     level 4
    process_labels                           0x09179A 0x84     level 2
    process_variables                        0x09143E 0x35C    level 2
    process_display_ptrs                     0x0912AA 0x194    level 2
    process_parameters                       0x090BBA 0x6F0    level 2
    ptr_variable                             0x090A10 0x1AA    level 3
    assign_name                              0x090968 0x98     level 4
    assign                                   0x090862 0x106    level 3
    inliner_actual                           0x090848 0x1A     level 2
    set_address_exposed                      0x09077A 0x9E     level 2
    allocate_local_var                       0x09055C 0x1E6    level 2
    allocate_space                           0x0903F2 0x16A    level 2
    align                                    0x0903B8 0x3A     level 2
    copy_var                                 0x090278 0x140    level 2
    copy_const                               0x09023E 0x36     level 2
    put_on_bct                               0x0901BC 0x82     level 2
    pass_method                              0x090012 0x15E    level 2
    actual_actual                            0x08FF90 0x82     level 2
    put_on_il_stream                         0x08FF6E 0x22     level 2
    patch_il                                 0x08FD10 0x25E    level 2
    inline_$compatible_types                 0x08FCDA 0x36     level 2
    start_il_stream                          0x08FC5C 0x7E     level 2
    coerce                                   0x08FA6C 0x1F0    level 2
    extend                                   0x08F95A 0x112    level 3
    put_hash_info                            0x08F86A 0xF0     level 2
    get_hash_info                            0x08F79C 0xCE     level 2
    cleanup_hash                             0x08F756 0x46     level 2
    current_ln                               0x08F73C 0x1A     level 2
    function_return                          0x08F674 0xC8     level 2
    get_size_rlen                            0x08EF54 0x486    level 2
    find_varn                                0x08EE28 0x12C    level 2
    find_block                               0x08EDCE 0x40     level 2
    next_contained_block                     0x08ED36 0x98     level 2
    nil_out_dispinfo                         0x08ED22 0x14     level 2
    assert_routine_returns_void              0x08ECD4 0x4E     level 2
    assert_is_void_type                      0x08ECBC 0x18     level 2
    assert_is_a_routine_block                0x08EC90 0x2C     level 2
    assert_is_nonleaf_lvalue                 0x08EC5A 0x36     level 2
    inline_$is_fortran_asf                   0x08EC38 0x22     level 2
    inline_$inline_expand                    0x094066 0x1A0    level 2
    inline_$mark_reference_params            0x08F49A 0x1C4    level 2
    get_referenced_symbol                    0x08F3DA 0xC0     level 3

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

    process_candidate                        0x0956B8 0x1108   level 2
    compare_dindex                           0x095612 0xA6     level 2
    compare_disp                             0x09556C 0xA6     level 2
    bad_dindex                               0x095390 0x1C2    level 2
    subvector                                0x095268 0x128    level 2
    addvector                                0x095140 0x128    level 2
    mult_constant                            0x094FDE 0x162    level 2
    addconst                                 0x094E7C 0x162    level 2
    mult_add                                 0x094C70 0x20C    level 2
    dot                                      0x094AC4 0x1AC    level 2
    sum                                      0x094898 0x22C    level 2
    opt_vec_$zero_vector                     0x094780 0x118    level 2
    opt_vec_$init_vector                     0x094662 0x11E    level 2
    opt_vec_$copy_vector                     0x094544 0x11E    level 2
    epilog                                   0x094322 0x1BC    level 2
    prolog                                   0x0942B0 0x72     level 2
    get_increment                            0x09423E 0x72     level 2
    opt_vec_$obj_is_float_const              0x094208 0x36     level 2
    opt_vec_$process_routine                 0x096854 0x7E     level 2
    opt_vec_$process_loop                    0x0967C0 0x94     level 2

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

    prt_section_stats                        0x096CA8 0x11C    level 2
    prtsection                               0x096C58 0x50     level 3
    hhmmss                                   0x096B58 0x100    level 2
    perfsummary                              0x097648 0x982    level 2
    print_meter_results                      0x096E64 0x744    level 3
    convert_time_$clock_t_to_hh_mm_ss        0x096E28 0x3C     level 3
    prfpkg_$stop_active_phase                0x096B32 0x26     level 2
    prfpkg_$activate_phase                   0x096B00 0x32     level 2
    perfstop                                 0x0969FA 0x106    level 2
    perfstart                                0x096960 0x98     level 2
    perfinit                                 0x0968D4 0x8C     level 2

### `lang/lang/source/prtsub.pas`

- include `//lang/lang/source/prtsub.ins.pas`

    prtsub_$equal                            0x0984E2 0x48     level 2
    prttab                                   0x0984A8 0x3A     level 2
    prthex                                   0x098456 0x52     level 2
    prtint                                   0x098378 0xD4     level 2
    prtcatb                                  0x09832C 0x40     level 2
    prtcats                                  0x0982C6 0x66     level 2
    prtcatc                                  0x09829C 0x2A     level 2

### `lang2/source/lt_utils/source/seg_size.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/loader.ins.pas`
- include `//us/us/sys/ins/loader.ins.pas`
- include `//us/us/ins/fault.ins.pas`
- include `//us/us/sys/ins/fault.ins.pas`
- include `//us/us/ins/unix_sig.ins.pas`

    seg_size                                 0x09852C 0x5A     level 2

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

    sort                                     0x0986D8 0x26     level 2
    qsort                                    0x098598 0x140    level 3
    sortidentifiers                          0x0986FE 0xBE     level 2

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

    compare_bytes_case                       0x0987BC 0xD2     level 2
    strings_$compare_bytes_nocase            0x0988DC 0x3C     level 2
    strings_$memmove                         0x098970 0x34     level 2
    strings_$memcpy                          0x0989A4 0x32     level 2
    strings_$memcmp                          0x098918 0x58     level 2
    compare_bytes                            0x0988A0 0x3C     level 2
    idntk                                    0x0989D6 0xB6     level 2

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

    cat_time_info                            0x098AAE 0xD2     level 2
    get_time_stamp                           0x098A8C 0x22     level 2

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

    floating_token                           0x098C82 0x100    level 2
    setcontk                                 0x0991D0 0x13E    level 2
    strtk                                    0x0990F0 0xB6     level 2
    token_$make_string_token                 0x0991A6 0x2A     level 2
    dpcmplxtk                                0x099020 0xD0     level 2
    token_$make_real_lit_pair                0x098F2E 0xF2     level 2
    cmplxtk                                  0x098E8E 0xA0     level 2
    get_reciprocal                           0x098E48 0x46     level 2
    dpcontk                                  0x098E1E 0x2A     level 2
    rlcontk                                  0x098D82 0x9C     level 2
    smcontk                                  0x098BD4 0xAE     level 2
    set_is_nil                               0x09930E 0x60     level 2

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

    emit_32                                  0x099C46 0x58     level 2
    emit_8                                   0x099B62 0xA2     level 2
    store_rel_info                           0x09988A 0x92     level 2
    store_fixup_info                         0x09975A 0x84     level 2
    get_reloc_symndx                         0x0994EC 0x252    level 2
    write_byte_to_temp_string_table          0x099388 0x50     level 2
    has_ecb                                  0x099456 0x44     level 2
    unix_obj_init                            0x09F952 0x50     level 2
    dump_data                                0x09998A 0x1D8    level 2
    unix_obj_gen                             0x09F128 0x76E    level 2
    add_exception_addr_con_tuple             0x09F0DA 0x4E     level 3
    output_data_info                         0x09DDFE 0x1224   level 3
    create_tv_reloc_recs                     0x09DD42 0xBC     level 3
    output_misc_sections                     0x09D598 0x722    level 3
    change_name_lower_case                   0x09D520 0x78     level 3
    line_numbers                             0x09D4A8 0x78     level 3
    emit_rel                                 0x09D426 0x82     level 3
    data_sections                            0x09CED8 0x548    level 3
    align_data_position                      0x09CE9E 0x3A     level 4
    dump_data_init_thread                    0x09CC02 0x260    level 4
    sort_data_init_thread                    0x09C95A 0x2A8    level 5
    link_and_update_offset                   0x09C8D6 0x84     level 6
    adjust_head_and_tail                     0x09C8AC 0x2A     level 6
    ddisp                                    0x09C7CE 0xDE     level 6
    qsort                                    0x09C614 0x1BA    level 6
    determine_section_headers_size           0x09C51E 0xF6     level 3
    gen_proc_relocs                          0x09BED0 0x640    level 3
    gen_data_relocs                          0x09BE1E 0xB2     level 3
    get_section_id                           0x09BD6C 0xB2     level 3
    get_load_addr                            0x09BD26 0x46     level 3
    write_transfer_vectors                   0x09BB40 0x1D0    level 3
    create_global_reference                  0x09B972 0x1BA    level 3
    emit_ecb                                 0x09B306 0x620    level 3
    find_global_id                           0x09A60C 0x5C     level 3
    emit_constant                            0x09A348 0x2AC    level 3
    emit_data                                0x09A27C 0xCC     level 3
    emit_tree_node_const                     0x099EB6 0x3AC    level 3
    init_data                                0x099E50 0x66     level 3
    emit_abs_addr_con                        0x09A668 0x416    level 3
    emit_addr_con                            0x09AA82 0x840    level 3
    add_to_section_header                    0x09991C 0x6E     level 2
    add_reloc                                0x0997DE 0xAC     level 2
    emit_16                                  0x099C04 0x42     level 2
    unix_put_obj_name                        0x099D06 0x14A    level 2
    string_table                             0x099C9E 0x68     level 2
    target_magic                             0x09949A 0x52     level 2

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

    invariant_sizeof_top_level               0x0A04E4 0xEC     level 2
    phasefromvatt                            0x09FA6E 0x66     level 2
    push                                     0x09FA3E 0x30     level 2
    add_top_node                             0x09F9F2 0x4C     level 2
    get_next_symbol                          0x09F9A4 0x2      level 2
    init_aux_ftn                             0x09F9F0 0x2      level 2
    make_char_temp                           0x09F9D6 0x1A     level 2
    make_temp                                0x09F9BC 0x1A     level 2
    char_maxlen                              0x09F9A6 0x16     level 2
    buildtreenode                            0x0A4C54 0xF4     level 2
    add_tn                                   0x0A1ABC 0x30AE   level 2
    distribute                               0x0A18C2 0x1FA    level 3
    add_routine_reference                    0x0A1262 0x9E     level 2
    getphase                                 0x09FAD4 0xC0     level 2
    add_pn                                   0x0A1652 0x228    level 2
    add_sdn                                  0x0A13FE 0xFA     level 2
    add_disp_node                            0x0A1300 0xD6     level 2
    add_dn                                   0x0A13D6 0x28     level 2
    add_dindexn                              0x0A14F8 0x15A    level 2
    add_node_$new_top_level                  0x0A1190 0xD2     level 2
    add_node_$dispose_top_level              0x0A05EE 0xB8     level 2
    copy_tree                                0x09FF08 0x5A8    level 2
    walk_it                                  0x09FBAE 0x35A    level 2

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

    attr_calc_align                          0x0A4F62 0xBE     level 2
    find_conflict                            0x0A4D48 0x120    level 2
    attr_compute_routine_options             0x0A6412 0x1DE    level 2
    attr_natural_align_from_bytes            0x0A4F38 0x2A     level 2
    attr_tattr_to_vattr                      0x0A59F0 0x36     level 2
    attr_validate                            0x0A564E 0x394    level 2
    attr_align_messages                      0x0A4E84 0x1A     level 2
    attr_check_align                         0x0A4E9E 0x9A     level 2
    attr_set_align_dsc                       0x0A503C 0x2AA    level 2
    attr_packed_size                         0x0A5300 0x124    level 2
    merge_attribs_natural                    0x0A5A26 0x866    level 2
    merge_attribs                            0x0A628C 0x6E     level 2
    add_attribute                            0x0A5466 0x1DE    level 2
    volatile_check                           0x0A5424 0x42     level 3
    attr_curr_align_env                      0x0A63F6 0x1C     level 2
    attr_set_align_env                       0x0A63C4 0x32     level 2
    attr_al_stk_empty                        0x0A63A8 0x1C     level 2
    attr_pop_align                           0x0A634C 0x5C     level 2
    attr_push_align                          0x0A62FA 0x52     level 2

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

    flush_externs                            0x0A676E 0x46     level 2
    find_extern                              0x0A65F0 0x17E    level 2
    coff_sym_dmp                             0x0A7CA4 0x66C    level 2
    put_func_def                             0x0A7A5A 0x24A    level 3
    put_tvs                                  0x0A79D2 0x88     level 3
    put_global_sym                           0x0A721C 0x79A    level 3
    put_sect_sym                             0x0A7154 0xC8     level 3
    put_name                                 0x0A70F8 0x5C     level 3
    map_name                                 0x0A70BA 0x3E     level 3
    get_section_hdr                          0x0A708E 0x2C     level 3
    get_section_no                           0x0A7036 0x58     level 3
    get_lnno_ptr                             0x0A6FB6 0x80     level 3
    get_coff_type                            0x0A6F52 0x46     level 3
    number_coff_syms                         0x0A6AC2 0x48C    level 2
    count_tvs                                0x0A6A48 0x7A     level 3
    count_global_sym                         0x0A67B4 0x244    level 3

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

    build_block_list                         0x0AC156 0xB4     level 2
    gen_section_table                        0x0ABF66 0x1F0    level 2
    write_files                              0x0ABCAA 0x2BA    level 2
    add_unit_table_entry                     0x0ABC52 0x58     level 3
    write_string_for_file_table_entry        0x0ABC00 0x52     level 3
    add_file_table_entry                     0x0ABB62 0x9E     level 3
    write_blocks                             0x0AB78A 0x36C    level 2
    make_relative_ref                        0x0AB742 0x48     level 2
    get_src_loc                              0x0AB6E2 0x60     level 2
    get_debug_offset                         0x0AB6AA 0x38     level 2
    add_string                               0x0AB656 0x54     level 2
    clear_emitted_marker                     0x0AB55E 0x64     level 2
    dump_string_table                        0x0AB45C 0x102    level 2
    create_string_table                      0x0AB440 0x1C     level 2
    process_debug_symbols                    0x0AB344 0x74     level 2
    process_named_objects                    0x0AAFB6 0x30A    level 2
    skip_unreferenced_include_object         0x0AAF30 0x86     level 2
    get_entry_rep                            0x0AAE5E 0x9A     level 2
    get_const_rep                            0x0AAB30 0x2DE    level 2
    get_label_rep                            0x0AAA88 0x6C     level 2
    get_enum_rep                             0x0AA2B6 0x132    level 2
    get_record_rep                           0x0A9FBC 0x2BE    level 2
    get_tag                                  0x0A9F52 0x6A     level 2
    get_signature_rep                        0x0A9DA2 0x15E    level 2
    get_variable_rep                         0x0A9BF8 0x16E    level 2
    get_alias_rep                            0x0A9B80 0x78     level 2
    get_src_loc_rep                          0x0A9B44 0x3C     level 2
    get_name_rep                             0x0A9A6E 0x8A     level 2
    is_simple_type                           0x0A99B6 0x9A     level 2
    may_need_common_aux                      0x0A9700 0x1B4    level 2
    get_sect_rel_location_rep                0x0A937C 0x7A     level 2
    get_var_location_rep                     0x0A8FD8 0x306    level 2
    get_memory_loc                           0x0A8B0C 0x44E    level 2
    reg_translate_68k                        0x0A8AD4 0x38     level 2
    reg_translate_at                         0x0A8A50 0x4A     level 2
    add_obj_to_loc_fixup_list                0x0A8A14 0x3C     level 2
    prep_sections                            0x0A8984 0x90     level 2
    add_to_reloc_obj_list                    0x0A8864 0xCA     level 2
    label_from_fortran_symbol                0x0A8764 0x90     level 2
    add_name_to_symbols_section              0x0A8554 0x7C     level 2
    add_symbols_section                      0x0A84C0 0x7E     level 2
    obj_alloc                                0x0A847A 0x46     level 2
    dumpfunc                                 0x0A8428 0x52     level 2
    allocfunc                                0x0A83B0 0x4A     level 2
    get_type_rep                             0x0AA422 0x636    level 2
    force_add_string                         0x0AB5C2 0x94     level 2
    sz_fsym                                  0x0A8350 0x20     level 2
    varn_from_fortran_symbol                 0x0A8664 0x100    level 2
    debug_sym_dmp_$block_dmp                 0x0AC20A 0x1B2    level 2
    debug_sym_dmp_$dump_symbols_section      0x0AB400 0x40     level 2
    debug_sym_dmp_$add_loc_info              0x0A9458 0x266    level 2
    debug_sym_dmp_$create_symbols_sections   0x0AB3B8 0x48     level 2
    debug_sym_dmp_$finalize                  0x0AC5E4 0x50     level 2
    debug_sym_dmp_$init                      0x0AC44A 0x13E    level 2
    add_file_entry                           0x0AC3BC 0x8E     level 3
    get_include_file_index                   0x0A87F4 0x70     level 2

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

    error3                                   0x0AC862 0x7C     level 2
    error2                                   0x0AC7F2 0x6E     level 2
    error1                                   0x0AC78A 0x66     level 2
    error0                                   0x0AC728 0x5E     level 2
    save_errors                              0x0AC634 0xF4     level 2
    print_error                              0x0AC8E0 0xDC     level 2

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

    open_inlib_list_sub                      0x0ACC34 0x11E    level 2
    open_inlib_list                          0x0ACD52 0x40     level 2
    open_include_list_sub                    0x0ACA4A 0x1A8    level 2
    open_include_list                        0x0ACA0C 0x3E     level 2
    find_file_name                           0x0AC9BC 0x50     level 2

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

    assert_is_shift_with_negative_count      0x0AD0A0 0x3A     level 2
    assert_and_over_left_shift_produces_zero 0x0ACFEC 0xB4     level 2
    assert_is_shift                          0x0ACFA4 0x48     level 2
    assert_is_left_shift                     0x0ACF70 0x34     level 2
    assert_is_integer_and                    0x0ACF48 0x28     level 2
    assert_is_integer_constant               0x0ACF06 0x28     level 2
    assert_is_shared_tree                    0x0ACEF8 0xE      level 2
    assert_is_tree                           0x0ACEE0 0x18     level 2
    report_failure_once                      0x0ACD94 0x2E     level 2
    kfold                                    0x0AF444 0x34     level 2
    kfold_$general                           0x0AD1A0 0x223C   level 2
    node_number                              0x0AD0DA 0xAC     level 3
    dfetch                                   0x0ACE8C 0x54     level 2
    dbl_to_real                              0x0ACDC2 0xBA     level 2

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

    prtobj_$prtobj_full                      0x0AF55A 0xFA4    level 2
    add_kind_if_full                         0x0AF514 0x46     level 3
    prt_logical                              0x0AF478 0x8C     level 3
    prtobj                                   0x0B08B0 0x2C     level 2

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

    adjust_disps_of_formals_for_fcw          0x0B21FE 0xCE     level 2
    set_local_call_bits                      0x0B213E 0xC0     level 2
    optimize_and_code_depth_first            0x0B20BE 0x80     level 2
    optimize_and_code                        0x0B1E70 0x20C    level 2
    normalize_il                             0x0B17BA 0x55E    level 2
    assert_is_useless_disp                   0x0B174A 0x56     level 2
    delete_unreferenced_blocks               0x0B1644 0x106    level 2
    assert_is_inlineable_utility_routine_in_include_file 0x0B15FC 0x48     level 2
    build_call_graph                         0x0B1582 0x7A     level 2
    build_call_graph_walk_il                 0x0B0F48 0x3F0    level 2
    analyze_call_site_for_call_graph         0x0B0E50 0xF8     level 2
    detect_fortran_param_scalarity_mismatches 0x0B0CB6 0xEA     level 2
    add_call_graph_edge                      0x0B0BD8 0xDE     level 2
    build_call_graph_walk_block              0x0B14E8 0x9A     level 2
    unconditionally_add_call_graph_edge      0x0B0B42 0x78     level 2
    check_static_initializations             0x0B0AFC 0x46     level 2
    check_fdata                              0x0B0AD4 0x28     level 2
    is_routine_reference_addr_con            0x0B0A5A 0x7A     level 2
    routine_reference_class                  0x0B0984 0xD6     level 2
    assert_is_fortran_array                  0x0B0966 0x1E     level 2
    assert_is_a_callable_block               0x0B0930 0x36     level 2
    assert_is_a_call_node                    0x0B08FE 0x32     level 2
    assert_is_a_tree_node                    0x0B08DC 0x22     level 2
    run_backend                              0x0B22CC 0x254    level 2

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

    parse_options                            0x0B2A50 0x16FE   level 2
    parse_opt_on_or_off                      0x0B29B6 0x9A     level 3
    fill_array_with_args                     0x0B296C 0x4A     level 3
    arg_option_parameter_numeric             0x0B2854 0xB2     level 3
    arg_option_parameter                     0x0B27AC 0x78     level 3
    match                                    0x0B2788 0x24     level 3
    option_error                             0x0B277C 0xC      level 3
    match_arg                                0x0B26E0 0x9C     level 2
    push_kap                                 0x0B2652 0x8E     level 2
    set_name                                 0x0B25E8 0x6A     level 2
    print_version                            0x0B2584 0x42     level 2
    argument_error                           0x0B2568 0x1A     level 2
    cargs_$parse_line_options                0x0B4F0E 0x114    level 2
    cargs_$parse_command_line_options        0x0B4E9A 0x74     level 2
    cargs_$parse_command_line_fixed_arguments 0x0B4D94 0xE4     level 2
    no_source_file                           0x0B4D16 0x2A     level 3
    match                                    0x0B4CF2 0x24     level 3
    cargs_$init_option_defaults              0x0B4A86 0x26C    level 2
    get_little_version                       0x0B4A54 0x32     level 2
    cargs_$identify_self                     0x0B4A18 0x3C     level 2
    build_my_version_string                  0x0B496E 0x70     level 3
    encode_it                                0x0B4906 0x68     level 4
    get_compiler_image_timestamp_and_edit_number 0x0B48D0 0x34     level 3
    build_my_name_string                     0x0B4732 0x19C    level 3

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

    open_src_file                            0x0B50D4 0x88     level 2
    stream_error                             0x0B5090 0x44     level 2
    error_exit                               0x0B5024 0x62     level 2
    set_obj_length                           0x0B5FA8 0x28     level 2
    freeobj                                  0x0B6094 0x42     level 2
    getobj                                   0x0B6032 0x62     level 2
    putobj                                   0x0B5FD0 0x62     level 2
    ejctln                                   0x0B5F6E 0x36     level 2
    listln                                   0x0B5F42 0x2C     level 2
    iosub_$write                             0x0B5C9A 0xB0     level 2
    write_ln                                 0x0B5BDA 0xC0     level 2
    io_term_force                            0x0B5B38 0xA2     level 2
    iosub_$selected_io_term                  0x0B59CC 0x12C    level 2
    io_term                                  0x0B5B10 0x28     level 2
    iosub_$redirect_source_input             0x0B5950 0x7C     level 2
    close_include_file                       0x0B6306 0x22     level 2
    iosub_$get_full_path_name                0x0B6238 0xCA     level 2
    iosub_$get_dtm                           0x0B61EA 0x4E     level 2
    open_include_file                        0x0B60D6 0x110    level 2
    io_release                               0x0B5E4A 0x70     level 2
    io_mark                                  0x0B5DD6 0x74     level 2
    get_listing_stream_id                    0x0B592C 0x24     level 2
    typemsg                                  0x0B5F02 0x40     level 2
    typeln                                   0x0B5EBA 0x44     level 2
    read_ln                                  0x0B5D4A 0x8C     level 2
    iosub_$init_io                           0x0B5790 0x106    level 2
    open_plb_file                            0x0B5684 0xF4     level 3
    open_binary_file                         0x0B5624 0x5A     level 3
    open_bin_file                            0x0B55CC 0x58     level 4
    open_listing_file                        0x0B54A4 0x11C    level 3
    open_source_file                         0x0B53F4 0xB0     level 3
    build_name                               0x0B5272 0x180    level 3
    append_string                            0x0B524C 0x26     level 3
    match_suffix                             0x0B51B8 0x94     level 3
    iosub_$init_default_properties           0x0B518C 0x2C     level 2
    iosub_$init_all                          0x0B5896 0x96     level 2

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

    target_properties$cpu_rev_specific       0x0B63B2 0x9C     level 2
    target_properties$kernel_mode_code       0x0B637E 0x34     level 2
    target_properties$begin_compilation      0x0B6328 0x56     level 2

### `lang/lang/source/empty.pas`



### `lang/lang/source/banshee.pas`

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
- include `//lang/lang/source/final.ins.pas`

    dobansheefpx                             0x0EE84C 0x782    level 2

### `lang/lang/source/celpkg.pas`

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
- include `//lang/lang/source/final.ins.pas`

    unpack_ads                               0x0B6838 0x72     level 2
    pack_ads                                 0x0B670A 0x114    level 2
    join                                     0x0B66AE 0x40     level 2
    init_celpkg                              0x0B645C 0x32     level 2
    getrefcell                               0x0B650A 0x78     level 2
    getlabcell                               0x0B648E 0x7A     level 2
    getcodecell                              0x0B6582 0xCA     level 2
    empty                                    0x0B66EE 0x1C     level 2
    delink                                   0x0B6682 0x2C     level 2
    after                                    0x0B6652 0x30     level 2
    create_temp_label                        0x0B68AA 0x5E     level 2

### `lang/lang/source/cg_addr.pas`

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
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`

    load_dindex                              0x0F1526 0x312    level 2
    load_dereference                         0x0F13FC 0x12A    level 2
    load_indexreg                            0x0F13B8 0x44     level 2
    peekdisp                                 0x0EF93C 0x86     level 2
    dfree                                    0x0EF58C 0x24     level 2
    assert_is_nlbranch                       0x0EF038 0x18     level 2
    assert_is_label_node                     0x0EF020 0x18     level 2
    assert_optimizer_is_enabled              0x0EEFF4 0x2C     level 2
    load_modifiable                          0x0F11A8 0x1F8    level 2
    get_childs_agg_temp                      0x0F09E4 0x72     level 2
    get_agg_temp                             0x0F09B6 0x2E     level 2
    weight                                   0x0EF42A 0x148    level 2
    getobjcache                              0x0EF1F2 0xCA     level 2
    setobjcache                              0x0EF112 0xE0     level 2
    forceobjcache                            0x0EF050 0xA8     level 2
    check_use                                0x0EF3BA 0x70     level 2
    register_tickle                          0x0EF7D2 0x150    level 2
    anyconst                                 0x0F26BA 0xC6     level 2
    cg_addr_$remove_temp_from_free_list      0x0F06F2 0x4E     level 2
    cg_addr_$load_addr_of_cse                0x0F051A 0x1D8    level 2
    cg_addr_$addr_of_cse                     0x0F04C6 0x54     level 2
    cg_addr_$free_alloc_temp                 0x0F0A60 0x8A     level 2
    get_temp                                 0x0F0740 0x262    level 2
    allocate_temp                            0x0F0390 0x136    level 2
    init_temp                                0x0F00F4 0x28     level 2
    edit_register                            0x0F2F6C 0xE0     level 2
    cg_addr_$merge_state_of_assigned_goto_targets 0x0F2D50 0xBA     level 2
    merge_state                              0x0F2BA8 0x1A8    level 2
    merge_register                           0x0F2AAC 0xFC     level 3
    chk_assign                               0x0EF6F8 0xDA     level 2
    makedeferred                             0x0F183A 0xBA     level 2
    load_live_registers                      0x0EFD68 0x116    level 2
    chk_addr                                 0x0F18F4 0x8A     level 2
    peek                                     0x0EF9C2 0x314    level 2
    load_fp_result                           0x0F2780 0x32C    level 2
    setresult                                0x0EF2BC 0xFE     level 2
    load_result                              0x0F226C 0x44E    level 2
    load_address                             0x0F1050 0x158    level 2
    load_operand                             0x0F0EA4 0x1AC    level 2
    get_temp_register                        0x0F0E42 0x62     level 2
    get_register                             0x0F0C5A 0x1E8    level 2
    release                                  0x0F0AEA 0x170    level 2
    invalidate                               0x0F011C 0x274    level 2
    kill_register                            0x0F00B6 0x3E     level 2
    cg_addr_$init_regs                       0x0F2EAA 0xC2     level 2
    inquire                                  0x0EFE7E 0x238    level 2
    unlock                                   0x0EF600 0xDA     level 2
    cg_addr_$operand_in_reg_any_rlen         0x0EFCD6 0x92     level 2
    address_reg                              0x0EF5B0 0x50     level 2
    address                                  0x0F197E 0x8EE    level 2

### `lang/lang/source/cg_assign.pas`

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
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`

    pack_assign_proc                         0x0F4290 0x3D2    level 2
    gen_clr_set                              0x0F4166 0x12A    level 2
    set_aops                                 0x0F3FBC 0x1AA    level 2
    agg_assign_proc                          0x0F3826 0x6E8    level 2
    remove_postincrement                     0x0F3816 0x10     level 3
    agg_len_assign_proc                      0x0F3740 0xD6     level 2
    tleftright                               0x0F34D8 0x216    level 2
    target                                   0x0F31B8 0x306    level 2
    cg_asn_$block_move_body_size             0x0F3068 0x46     level 2
    fault_free_assign                        0x0F36F4 0x4C     level 2
    assign_proc                              0x0F469E 0x2224   level 2
    cspe                                     0x0F467E 0x20     level 3
    multi_assign_proc                        0x0F3F28 0x94     level 2
    cg_asn_$inline_move_is_best              0x0F30AE 0x4C     level 2
    cg_asn_$block_move                       0x0F30FA 0xBE     level 2

### `lang/lang/source/cg_call.pas`

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
- include `//lang/lang/source/alias.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    cg_call_$kill_any_param_alias            0x0F6B5A 0xA0     level 2
    cg_call_$obj_is_modifiable_by_param      0x0F6B18 0x28     level 2
    cg_call_$alias_size_expand               0x0F6A46 0xD2     level 2
    cg_call_$att_in_any_entry                0x0F6A02 0x44     level 2
    get_atts                                 0x0F69AC 0x56     level 2
    cg_call_$is_a_nint                       0x0F68E8 0x2A     level 2
    gen_call                                 0x0F720A 0x15D2   level 2
    varargs_moveq_d0                         0x0F715C 0xAE     level 3
    copy_to_stack                            0x0F6BFA 0x548    level 3
    cg_call_$is_proc_var_call                0x0F6912 0x84     level 2

### `lang/lang/source/cg_fp.pas`

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
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`

    cg_fp_$push_fop                          0x0F882E 0x80     level 2
    skip_zero_disps                          0x0F87FC 0x32     level 2
    test_peb_busy                            0x0F8976 0x98     level 2
    fp_rlen                                  0x0F8926 0x50     level 2
    fp_temp                                  0x0F955E 0x9C     level 2
    init_peb                                 0x0F8904 0x22     level 2
    purge_fp                                 0x0F8A0E 0x69C    level 2
    fop_proc                                 0x0F95FA 0x140    level 2
    stack_fp                                 0x0F90EE 0x44E    level 2

### `lang/lang/source/cg_misc.pas`

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
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/cg.ins.pas`

    cg_misc_$strcmp_by_longs                 0x0FAFCC 0x460    level 2
    compare_two_bytes                        0x0FAF2A 0xA2     level 3
    cbuiltin_strncmp                         0x0FB7D6 0x476    level 2
    cbuiltin_strcmp                          0x0FB42C 0x3AA    level 2
    cbuiltin_strlen                          0x0FAD8A 0x166    level 2
    cbuiltin_strcat                          0x0FA95A 0x1A2    level 2
    cbuiltin_strncat                         0x0FAAFC 0x28E    level 2
    cbuiltin_strncpy                         0x0FA67C 0x2DC    level 2
    cbuiltin_strcpy                          0x0FA580 0xFA     level 2
    cg_misc_$strcmp_can_use_longs            0x0FAEF0 0x3A     level 2
    show_label                               0x0F99EC 0x1DC    level 2
    show_state                               0x0F973C 0x24E    level 2
    zero_check                               0x0F9CD0 0x3A     level 2
    fill                                     0x0FA410 0x170    level 2
    agg_loop_end                             0x0F9F4A 0xC8     level 2
    agg_loop_start                           0x0F9EB2 0x98     level 2
    agg_len_loop_start                       0x0F9DB8 0xFA     level 2
    agg_opr                                  0x0FA27E 0x192    level 2
    unaligned                                0x0F9C16 0xBA     level 2
    genmask                                  0x0FA012 0x3E     level 2
    s_extend                                 0x0F9D24 0x94     level 2
    reverse_cc                               0x0F9BEE 0x28     level 2
    shift                                    0x0FA050 0x22E    level 2
    templabel                                0x0F9BC8 0x26     level 2

### `lang/lang/source/cg_top.pas`

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
- include `//lang/lang/source/final.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`

    updateregassign                          0x0FBC5E 0x4A     level 2
    skip_reg_list                            0x0FBC4C 0x12     level 2
    codegen                                  0x0FE62A 0x972    level 2
    emit_a_line_eop                          0x0FE5B2 0x78     level 3
    label_proc                               0x0FE168 0x44A    level 3
    return_proc                              0x0FD9D8 0x790    level 3
    emit_terminating_line_no                 0x0FD968 0x70     level 3
    updatestacksize                          0x0FD7C0 0x1A8    level 3
    block_entry_proc                         0x0FCE84 0x93C    level 3
    cbranch_proc                             0x0FCBCE 0x29C    level 3
    case_proc                                0x0FC734 0x49A    level 3
    csetotree                                0x0FC70C 0x28     level 3
    reg_list_proc                            0x0FC47E 0x28E    level 3
    basicblock                               0x0FC348 0x136    level 3
    initialize_tree                          0x0FC07E 0x29A    level 3
    initialize_node                          0x0FBE64 0x21A    level 3
    initialize                               0x0FBDDA 0x88     level 3
    f_initialize                             0x0FBCA8 0x130    level 2

### `lang/lang/source/cg_tree.pas`

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
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/lang/source/delay.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    generate                                 0x10484E 0x3B38   level 2
    restore_alloc_temps                      0x1047CA 0x84     level 3
    ld_addr                                  0x104640 0x18A    level 3
    f_compare_proc                           0x103F8E 0x6B2    level 3
    switch                                   0x103EE6 0xA8     level 4
    round_fp_to_ieee                         0x103E14 0xD2     level 3
    compare_proc                             0x10386E 0x572    level 3
    set_ops                                  0x10370A 0x164    level 3
    proto_set                                0x103678 0x92     level 4
    set_bit_in_set_proc                      0x1033E0 0x298    level 3
    set_range_in_set_proc                    0x102E94 0x54A    level 3
    copy_set_aggregate                       0x102CAA 0x1EA    level 3
    div_proc                                 0x102556 0x728    level 3
    extend_div_proc_result                   0x10247E 0xD8     level 4
    mul_proc                                 0x101D38 0x732    level 3
    ldsqr                                    0x101CC8 0x70     level 4
    mdmcase                                  0x101C8A 0x3E     level 4
    agg_compare_proc                         0x101674 0x5FA    level 3
    shift_proc                               0x1015BE 0xB6     level 3
    unpack_proc                              0x1011D8 0x3E6    level 3
    bit_set_proc                             0x100DBC 0x41C    level 3
    bit_test_proc                            0x100660 0x75C    level 3
    do_const_mul                             0x1005AC 0x72     level 2
    genmul                                   0x100148 0x464    level 3
    doshft                                   0x10002A 0x11E    level 4
    const_mul                                0x0FFF22 0x108    level 3
    consecutivebits                          0x0FFEDA 0x48     level 4
    push                                     0x0FFEA2 0x38     level 3
    stkinit                                  0x0FFE66 0x3C     level 3
    movewlx                                  0x0FFC56 0x1F6    level 2
    assert_const_mul_candidate               0x0FFC2A 0x2C     level 2
    cg_tree_$call_fast_math_lib              0x0FF84C 0x3DE    level 2
    cg_tree_$adjust_before_round             0x0FF5B2 0x254    level 2
    cg_tree_$spill_fp_reg_contents_before_fpp 0x0FF4EC 0xAC     level 2
    cg_tree_$prefers_inline_float            0x0FF3F4 0xF8     level 2
    cg_tree_$fpa1_expon_inquire              0x0FF034 0x76     level 2
    assert_is_f_math_op                      0x0FEFFC 0x38     level 2
    assert_is_a_tree                         0x0FEFD0 0x2C     level 2
    tree_walk                                0x1085B4 0x376    level 2
    loadcse                                  0x108524 0x90     level 3
    walker                                   0x108484 0x9A     level 2
    evaluate_subtree                         0x10838E 0xF6     level 3
    cg_tree_$is_decomposable_const_mul       0x10061E 0x42     level 2
    cg_tree_$needs_lib_support               0x0FF0AA 0x340    level 2

### `lang/lang/source/emit.pas`

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
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang/lang/source/final.ins.pas`

    sz_case                                  0x0B7066 0x3A     level 2
    adrlen                                   0x0B6F78 0xEE     level 2
    chk_imd                                  0x0B6E14 0x164    level 2
    defer_constant                           0x0B6D26 0xEE     level 2
    chk_op_restr                             0x0B6A1E 0x2EE    level 2
    tst_imd                                  0x0B69BC 0x48     level 2
    chk_sz_restr                             0x0B6908 0xB4     level 2
    ilength                                  0x0B70A0 0x2EE    level 2
    fnl_slct                                 0x0B738E 0x4E4    level 2
    emit_line_eop                            0x0B79DE 0xA6     level 2
    emit                                     0x0B78C0 0x11E    level 2

### `lang/lang/source/final.pas`

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
- include `//lang/lang/source/final.ins.pas`
- include `//lang/lang/source/prfpkg.ins.pas`
- include `//lang/lang/source/alias.ins.pas`
- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/pfm.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/peb.ins.pas`
- include `//us/us/ins/error.ins.pas`
- include `//us/us/sys/ins/error.ins.pas`

    final_$unlink_opts                       0x110412 0x172    level 2
    backtrack                                0x1103D0 0x42     level 3
    final_$link_opts                         0x1103C0 0x10     level 2
    final_$try_to_suppress_stack_frame       0x11029A 0x126    level 2
    final_$remove_sb_rel                     0x110252 0x48     level 2
    remove_sb_rel                            0x11021E 0x34     level 3
    final_$local_var_refs                    0x1101C0 0x5E     level 2
    local_var_ref                            0x11018A 0x36     level 3
    final_$stack_is_altered                  0x11010C 0x7E     level 2
    final_$logicize_opts                     0x10FFA4 0x168    level 2
    floatop                                  0x10FB84 0x3D4    level 2
    opta                                     0x10F6C4 0x4C0    level 2
    try_post_incr                            0x10F30C 0x3B8    level 2
    try_pre_dec                              0x10EF30 0x3BA    level 2
    merge_stack_adjusts                      0x10EE1E 0x112    level 2
    final_$merge_movea_adjust                0x10ECFA 0x124    level 2
    merge_move_sub                           0x10EC22 0xD8     level 2
    merge_add_sub                            0x10E8EA 0x332    level 2
    final_$addr_adjust_value                 0x10E894 0x50     level 2
    is_stack_adjuster                        0x10E7EC 0xA2     level 2
    test_add_sub                             0x10E734 0xB8     level 2
    optmove                                  0x10DF52 0x7E2    level 2
    transform_ptr_in_d_use                   0x10DD5A 0x1DC    level 2
    opttest                                  0x10D600 0x75A    level 2
    final_$cmp_branch_becomes_eor            0x10D28A 0x372    level 2
    final_$unity_compare_and_branch          0x10D174 0xEA     level 2
    final_$redundant_movea                   0x10D094 0xE0     level 2
    final_$redundant_lea                     0x10CD7E 0x316    level 2
    final_$redundant_compare                 0x10CC98 0xE6     level 2
    opt_btst                                 0x10CBDA 0xBE     level 2
    deltest                                  0x10C5CE 0x60C    level 2
    backov                                   0x10C51C 0xB2     level 3
    bit_field_inst_which_obviates_test       0x10C466 0xB6     level 2
    assert_bfextu_requires_test              0x10C3BA 0x92     level 2
    assert_n_bit_is_modified                 0x10C384 0x36     level 2
    puncondjmp                               0x10C0D2 0x2B2    level 2
    f_pcondjmp                               0x10BF46 0x18C    level 2
    f_brimply                                0x10BED4 0x72     level 2
    correct_cc_set                           0x10BE5E 0x76     level 2
    plab                                     0x10BD9E 0xC0     level 2
    reg_mod                                  0x10BCCC 0xD2     level 2
    pcondjmp                                 0x10B972 0x240    level 2
    change_br_value                          0x10B924 0x4E     level 2
    brimply                                  0x10B810 0x80     level 2
    crossjump                                0x10B5D2 0x226    level 2
    eqlbitfield                              0x10B536 0x9C     level 2
    isbranch                                 0x10B514 0x22     level 2
    movejump                                 0x10B4DC 0x38     level 2
    makecbr                                  0x10B3DA 0x8C     level 2
    lines_equiv                              0x10B17C 0xB2     level 2
    setlabel                                 0x10B12E 0x4E     level 2
    label_merge                              0x10B014 0x11A    level 2
    scancc                                   0x10AEC8 0x10A    level 2
    cc_use                                   0x10AE26 0xA2     level 2
    cc_change                                0x10ACDA 0x14C    level 2
    br_target                                0x10ACBC 0x1E     level 2
    fpx_instruction                          0x10AC58 0x64     level 2
    final_$try_reducing_literal              0x10A492 0x7C4    level 2
    final_$collapsed_index_calc              0x109BB6 0x8DA    level 2
    final_$contiguous_distinct_addresses     0x109A80 0x136    level 2
    adjacent_disps                           0x109A42 0x3E     level 3
    final_$reg_is_dead_henceforth            0x109912 0x12A    level 2
    final_$reg_implicitly_used_by_inst       0x109874 0x64     level 2
    final_$reg_is_used                       0x1097DA 0x9A     level 2
    final_$fp_reg_is_killed                  0x1096DA 0xD2     level 2
    final_$reg_is_killed                     0x1095C8 0x112    level 2
    assert_is_direct_use_of_address_reg      0x10959E 0x2A     level 2
    final_$reg_is_index                      0x10950E 0x3A     level 2
    final_$reg_is_simple_deferred            0x1094E4 0x2A     level 2
    final_$is_int_load                       0x1091FE 0x106    level 2
    final_$is_int                            0x109188 0x5C     level 2
    has_xcrement_addressing                  0x109170 0x18     level 2
    has_untouchable_mem_attrs                0x109144 0x2C     level 2
    final_$is_unmoveable_ftest               0x1090B2 0x92     level 2
    assert_is_pic_fp040_libcall              0x109032 0x28     level 2
    assert_is_pic_routine_address_load       0x108FBE 0x74     level 2
    assert_is_addr_con_ref                   0x108F9C 0x22     level 2
    assert_is_fp040_libname                  0x108EB0 0x6C     level 2
    final_$sets_m881_codes_for_fp0           0x108E40 0x48     level 2
    final_$is_call_or_branch                 0x108E12 0x2E     level 2
    final_$is_branch                         0x108DCA 0x42     level 2
    final_$is_call                           0x108D94 0x36     level 2
    final_$sizeof                            0x108CF4 0x98     level 2
    final_$in_15bit_range                    0x108CDA 0x1A     level 2
    prvlcc                                   0x108C3E 0x4A     level 2
    prvcc                                    0x108B9E 0x4A     level 2
    get_line                                 0x108B7C 0x22     level 2
    deltolab                                 0x108B0E 0x6E     level 2
    final_$is_sole_label_consumer            0x108A26 0x66     level 2
    assert_modifies_object                   0x10894C 0x70     level 2
    assert_is_lea                            0x10892C 0x20     level 2
    cc_mod                                   0x10BBB2 0x11A    level 2
    uncondjmpp                               0x10B7F8 0x18     level 2
    testcc                                   0x10AFD2 0x42     level 2
    sameaddr                                 0x109304 0x1E0    level 2
    reversecond                              0x10B890 0x94     level 2
    peepholer                                0x1120A0 0x76     level 2
    damn_the_040s_hide_anyway                0x112042 0x5E     level 3
    insert_integer_nop                       0x111FE4 0x5C     level 4
    peepholer_ops                            0x111950 0x638    level 3
    try_widening_clr                         0x111856 0xFA     level 4
    try_removing_previous_clr                0x111666 0x1F0    level 4
    try_reducing_fabs_op                     0x111452 0x214    level 4
    try_long_extend_opts                     0x111130 0x322    level 4
    try_loading_monadic_src_here             0x110F14 0x21C    level 4
    try_loading_from_fp_reg                  0x110CB4 0x242    level 4
    peepholer_cleanup                        0x110982 0x32A    level 3
    peepholer_init                           0x110704 0x27E    level 3
    fix_labeluse                             0x110684 0x80     level 3
    constcheck                               0x110584 0xFE     level 3
    nxtlcc                                   0x108C88 0x52     level 2
    nxtcc                                    0x108BEE 0x50     level 2
    moverefcell                              0x10B466 0x76     level 2
    makejump                                 0x10B22E 0x1A6    level 2
    involves                                 0x109548 0x56     level 2
    final_$is_unmoveable_fp_inst             0x10905A 0x58     level 2
    final_$is_fp040_libcall                  0x108F26 0x76     level 2
    detref                                   0x1089C4 0x62     level 2
    detach                                   0x108A8C 0x82     level 2
    finaldriver                              0x112116 0x34     level 2

### `lang/lang/source/fpa.pas`

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
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/fpa.ins.pas`
- include `//lang/lang/source/fop.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    load_c16_part                            0x0B9314 0x15E    level 2
    emit_mem_reg                             0x0B805A 0x1EC    level 2
    emit_reg_reg                             0x0B7B58 0x136    level 2
    check_ads                                0x0B7AEC 0x6C     level 2
    check_postincr                           0x0B7ACA 0x22     level 2
    rb_fpreg                                 0x0B7AAC 0x1E     level 2
    ra_fpreg                                 0x0B7A8C 0x20     level 2
    fpa_temp                                 0x0B9BBC 0x94     level 2
    emit_clr_fp1                             0x0B996E 0x96     level 2
    emit_jsr                                 0x0B8E0A 0x4FE    level 2
    push_fpa_opr                             0x0B9472 0x4FC    level 2
    fpa_fop_proc                             0x0B9A0C 0x1B0    level 2
    emit_compare                             0x0B8B7E 0x262    level 2
    emit_load_store                          0x0B7C8E 0x298    level 2
    emit_extend                              0x0B8864 0x2EC    level 2
    emit_neg                                 0x0B849C 0x182    level 2
    emit_fmath_top                           0x0B8652 0x1E6    level 2
    emit_div_sub                             0x0B831C 0x180    level 2
    emit_mul_add                             0x0B8246 0xD4     level 2
    emit_assign                              0x0B7F54 0x100    level 2

### `lang/lang/source/instr_reorder.pas`

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
- include `//lang/lang/source/final.ins.pas`

    instr_reorder                            0x0BA754 0xD4     level 2
    reorder_m68881                           0x0BA56A 0x1EA    level 3
    reorder_dest_reg                         0x0BA2BA 0x2B0    level 3
    reorder_dest_mem                         0x0BA104 0x1B6    level 3
    cannot_move                              0x0BA062 0xA2     level 3
    adjust_links                             0x0B9FEE 0x74     level 3
    get_mask                                 0x0B9FD2 0x1C     level 3
    test_operands                            0x0B9EE0 0xF2     level 3
    no_src_ads                               0x0B9EBE 0x18     level 3
    is_same                                  0x0B9E2E 0x90     level 3
    store_to_memory                          0x0B9DB0 0x7E     level 3
    not_ok_to_move                           0x0B9C98 0x10A    level 3
    is_fp_instr                              0x0B9C74 0x1A     level 3
    is_fpa_instr                             0x0B9C50 0x1A     level 3

### `lang/lang/source/jmp_br_resolve.pas`

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
- include `//lang/lang/source/final.ins.pas`

    assert_is_forward_of                     0x0BA88A 0x1C     level 2
    assert_word_reach_is_possible            0x0BA86E 0x1C     level 2
    assert_byte_reach_is_possible            0x0BA852 0x1C     level 2
    observe_that_offset_is_positive          0x0BA842 0x10     level 2
    observe_that_offset_is_negative          0x0BA830 0x12     level 2
    jmp_br_setup                             0x0BA8A6 0x20E    level 2
    jmp_br_resolve                           0x0BB57A 0x8AA    level 2
    calc_psect_size                          0x0BB4E8 0x92     level 3
    resolve_inline_const_addrs               0x0BB470 0x78     level 3
    ensure_inline_consts_are_reachable       0x0BB1C0 0x2AE    level 3
    assert_available_hole                    0x0BB18A 0x36     level 4
    update_refs_from_here_forward            0x0BB0F4 0x96     level 3
    check_for_deferred_ref                   0x0BB054 0xA0     level 3
    calc_const_approximate_pcs               0x0BB03E 0x16     level 3
    update_const_approximate_pcs             0x0BAFD0 0x6E     level 3
    add_size_of_inst_to_pc                   0x0BAF40 0x90     level 3
    make_long_casejmp                        0x0BAE66 0xDA     level 3
    make_long_dbcc                           0x0BAD38 0x12E    level 3
    make_long_cbr                            0x0BAC28 0x110    level 3
    make_long_jmp                            0x0BAB10 0x10A    level 3
    drop_update                              0x0BAAB4 0x5C     level 3

### `lang/lang/source/opinfo.pas`

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
- include `//lang/lang/source/final.ins.pas`


### `lang/lang/source/outbin.pas`

- include `//us/us/ins/ubase.ins.pas`
- include `//us/us/ins/vfmt.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
- include `//us/us/ins/fpp_errs.ins.pas`
- include `//us/us/ins/peb.ins.pas`
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
- include `//lang/lang/source/prtobj.ins.pas`
- include `//lang/lang/source/iosub.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/final.ins.pas`
- include `//us/us/ins/fpp.ins.pas`
- include `//us/us/sys/ins/fpp.ins.pas`
- include `//us/us/ins/objmod.ins.pas`
- include `//us/us/ins/objio.ins.pas`
- include `//lang/lang/source/unix_objmod.ins.pas`
- include `//lang/lang/source/gen_unwind.ins.pas`
- include `//us/us/sys/ins/unwind.ins.pas`
- include `//lang/lang/source/gen_debug.ins.pas`
- include `//lang/lang/source/fop.ins.pas`

    get_reloc_symndx                         0x0BF2D2 0x184    level 2
    fardisp                                  0x0BF1A8 0x74     level 2
    assemble                                 0x0BED92 0x416    level 2
    areg                                     0x0BED86 0xC      level 2
    gen_ea_bits                              0x0BEA06 0x10C    level 2
    pc_disp_ok                               0x0BE9D0 0x36     level 2
    br_distance                              0x0BE96A 0x66     level 2
    dbcod                                    0x0BDFEC 0x52E    level 2
    prt_fp_regs                              0x0BD88C 0x226    level 2
    fp_get_sin_regname                       0x0BD85E 0x2E     level 2
    prt_int_regs                             0x0BD696 0x1C8    level 2
    dump_expr_bit_field                      0x0BD56C 0x100    level 2
    dump_bit_field                           0x0BD2EA 0x1E2    level 2
    prt_expr_bit_field                       0x0BD212 0xD8     level 2
    prt_bit_field                            0x0BD0BC 0x154    level 2
    prtlabel                                 0x0BD00C 0xAC     level 2
    write_proc                               0x0BCFA2 0x6A     level 2
    ln_end                                   0x0BCE62 0x140    level 2
    ln_number                                0x0BCD34 0x12E    level 2
    ln_begin                                 0x0BCB92 0x1A2    level 2
    put_ln_index                             0x0BCB46 0x4C     level 2
    sort_ln_bb                               0x0BCA98 0xAE     level 2
    show_assign                              0x0BC7EA 0x290    level 2
    bit_fld_op                               0x0BC7AE 0x3C     level 2
    end_unwind_scope                         0x0BC76A 0x44     level 2
    begin_unwind_scope                       0x0BC688 0xE2     level 2
    stack_debug_$range_close                 0x0BC64E 0x3A     level 2
    stack_debug_$lines_return                0x0BC63E 0x10     level 2
    stack_debug_$lines_entry                 0x0BC62E 0x10     level 2
    stack_debug_$lines_def                   0x0BC5F4 0x3A     level 2
    stack_debug_$range_open                  0x0BC522 0xD2     level 2
    stack_debug_$lines_stmt_end              0x0BC504 0x1E     level 2
    next_put_element                         0x0BC484 0x80     level 2
    purge_stack                              0x0BC350 0x134    level 2
    emit_hint_for_inlined_routine_line_no_instyp 0x0BC29A 0xA8     level 2
    emit_hint_for_line_number                0x0BC27C 0x1E     level 2
    format_hint_for_line_number              0x0BC22C 0x4A     level 2
    assert_is_interesting_line_no_instyp     0x0BC1F2 0x3A     level 2
    assert_inline_block_start_follows        0x0BC1CC 0x26     level 2
    assert_is_inline_block_end               0x0BC1A2 0x2A     level 2
    assert_is_inline_block_start             0x0BC178 0x2A     level 2
    assert_is_inlined_block                  0x0BC158 0x20     level 2
    assert_is_line_no_instyp                 0x0BC140 0x18     level 2
    assert_are_producing_68k_expanded_listing 0x0BC128 0x18     level 2
    attempt_fpx_command_opcode_disassembly   0x0BBEF0 0x218    level 2
    assert_is_an_fpx_command_instr           0x0BBE28 0xBA     level 2
    outcode                                  0x0C1FC6 0x444    level 2
    reset_section_info                       0x0C1E58 0x16E    level 3
    init_section_info                        0x0C1DBA 0x9E     level 3
    next_section                             0x0C1D5C 0x5E     level 3
    outbin_$firstln                          0x0C1CFC 0x60     level 3
    wr_section                               0x0C1B94 0x144    level 3
    wr_instr                                 0x0C0464 0x171A   level 3
    executable_insts_follow_prev_lineno      0x0C0420 0x3E     level 4
    coff_equiv_lines                         0x0C02EC 0x5A     level 4
    coff_lines_instruction                   0x0C0346 0xDA     level 4
    coff_lines_proc_end                      0x0C01D4 0x118    level 4
    coff_lines_proc_start                    0x0C0016 0x1BE    level 4
    wr_addr_ext                              0x0BFB06 0x4F2    level 4
    check_addressing_mode                    0x0BFA5C 0x64     level 4
    define_constant                          0x0BF606 0x44C    level 3
    reloc_proc_addr                          0x0BF506 0xE0     level 3
    genfpinst                                0x0BEB32 0x254    level 2
    fpreg                                    0x0BEB1C 0x16     level 3
    fpreg_ord                                0x0BEB12 0xA      level 3
    prtsiz                                   0x0BDF34 0xB8     level 2
    prtads                                   0x0BDAE0 0x42C    level 2
    add_proc_reloc                           0x0BF472 0x94     level 2
    dump_proc_reloc                          0x0BF23E 0x94     level 2
    init_proc_reloc                          0x0BF21C 0x22     level 2

### `lang/lang/source/reg_action.pas`

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
- include `//lang/lang/source/reg_alloc.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`

    mechanism                                0x0C28DC 0x144    level 2
    act                                      0x0C283E 0x9E     level 2
    add_actions                              0x0C26C4 0x17A    level 2
    alloc_stmt                               0x0C261E 0x9A     level 2
    insert_stmt                              0x0C254E 0xD0     level 2
    nextrealstmt                             0x0C24FC 0x52     level 2
    replace_parent_with_use                  0x0C246A 0x92     level 2
    assert_fortran_lvalue_not_in_areg        0x0C241C 0x4E     level 2
    insert_reg_stmts                         0x0C369A 0x2D2    level 2
    do_register_actions                      0x0C2BC0 0xA92    level 3
    killonpath                               0x0C2A20 0x1A0    level 4

### `lang/lang/source/reg_alloc.pas`

- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/vfmt.ins.pas`
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
- include `//lang/lang/source/reg_alloc.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    find_prev                                0x0C45B6 0x42     level 2
    compress_graph                           0x0C44C4 0xF2     level 2
    alloc_ftn_vars                           0x0C41C4 0x2B2    level 2
    alloc_comp_vars                          0x0C3E78 0x338    level 2
    align                                    0x0C3E3E 0x3A     level 2
    release_space                            0x0C3DF6 0x14     level 2
    freepools                                0x0C3DE2 0x14     level 2
    dump_lifetimes                           0x0C3A00 0x2E6    level 2
    dump_lifetime_endpoint                   0x0C39A0 0x54     level 2
    reg_alloc                                0x0C4A62 0x5F8    level 2
    editregassign                            0x0C487E 0x1CA    level 3
    defined_var                              0x0C45F8 0x286    level 3
    test_stmt                                0x0C4476 0x4E     level 2
    newconflict                              0x0C3E0A 0x34     level 2
    initpool                                 0x0C3D90 0x52     level 2

### `lang/lang/source/reg_color_68k.pas`

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
- include `//lang/lang/source/reg_alloc.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    conflictfree                             0x0C5216 0x28     level 2
    walkconflicts                            0x0C51C0 0x56     level 2
    removeconflict                           0x0C5156 0x6A     level 2
    color_graph                              0x0C5772 0x4E8    level 2
    setcommonregs                            0x0C5752 0x20     level 3
    computecommonregs                        0x0C572A 0x28     level 3
    targetfunctionresult                     0x0C570A 0x20     level 3
    pickcolor                                0x0C5674 0x96     level 3
    paint                                    0x0C54F6 0x17E    level 3
    checkout                                 0x0C5496 0x60     level 4
    availcolors                              0x0C53AA 0xEC     level 3
    available                                0x0C5350 0x5A     level 3
    reduce_temp_regs                         0x0C52F6 0x5A     level 3
    reduce                                   0x0C527E 0x78     level 4
    count_regs                               0x0C523E 0x40     level 3
    add_conflict                             0x0C50AC 0xAA     level 2

### `lang/lang/source/reg_cost_68k.pas`

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
- include `//lang/lang/source/reg_alloc.ins.pas`
- include `//lang/lang/source/codegen.ins.pas`
- include `//lang/lang/source/prtsub.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`

    reg_cost_$wasteful_param_load            0x0C5CC8 0x82     level 2
    reg_cost_$compute_max_loop_depth         0x0C5C5C 0x6C     level 2
    compute_costs                            0x0C5D4A 0xF3C    level 2

### `lang/lang/source/reg_life.pas`

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
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/reg_alloc.ins.pas`

    reg_life_$bnum_of_head_for_prehead       0x0C852E 0xE6     level 2
    csepath                                  0x0C7584 0x104    level 2
    find_prev_numbered_stmt                  0x0C7544 0x40     level 2
    find_next_numbered_stmt                  0x0C7504 0x40     level 2
    get_more_ranges                          0x0C74E2 0x22     level 2
    init_graph                               0x0C73FE 0xD0     level 2
    add_block                                0x0C6D08 0x76     level 2
    assert_block_on_list                     0x0C6CF2 0x16     level 2
    assert_is_use_def_at_call_site           0x0C6CD4 0x1E     level 2
    run_interference                         0x0C72FA 0x104    level 2
    ranges_intersect                         0x0C7074 0x9C     level 2
    mark_stmts                               0x0C6F3E 0x136    level 2
    find_paths                               0x0C6D7E 0x1C0    level 2
    combine_ranges                           0x0C7110 0x1EA    level 2
    add_range                                0x0C7EC2 0x66C    level 2
    add_cse_ranges                           0x0C7688 0x83A    level 2
    add_con_range                            0x0C8628 0x500    level 2

### `lang/lang/source/reg_save.pas`

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
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/lang/source/cg.ins.pas`
- include `//lang/lang/source/delay.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//lang2/source/lt_utils/source/bug_check.ins.pas`

    registers_preserved_by_statement         0x0ED178 0x1DC    level 2
    assert_tree_result_depends_on_operands   0x0ECEB6 0x48     level 2
    registers_consumed_by_assign_operator    0x0ECD06 0x16A    level 2
    registers_consumed_by_agg_aop            0x0ECB64 0x160    level 2
    registers_consumed_by_tree_operator      0x0EC3CE 0x6F0    level 2
    registers_consumed_by_cc_call            0x0EC326 0x6E     level 2
    registers_consumed_by_pf_call            0x0EC28C 0x60     level 2
    registers_consumed_by_routine_type       0x0EC1D2 0x68     level 2
    registers_consumed_by_routine_block      0x0EC0F0 0x8C     level 2
    registers_consumed_by_fortran_symbol     0x0EC07C 0x74     level 2
    resolve_temp_reg_consumption_overlap     0x0EC024 0x58     level 2
    get_extra_temp_regs                      0x0EBFBC 0x68     level 2
    tally_extra_temp_regs_needed             0x0EBF4E 0x6E     level 2
    get_extra_regs_from_set                  0x0EBF04 0x4A     level 2
    assert_is_tree_node                      0x0EBEE2 0x22     level 2
    assert_is_ptr_over_fortran_routine       0x0EBEB8 0x2A     level 2
    assert_is_fortran_routine                0x0EBE90 0x28     level 2
    assert_is_top_level_object               0x0EBE4C 0x26     level 2
    registers_consumed_by_object             0x0ECEFE 0x22A    level 2
    reg_save                                 0x0ED478 0x48     level 2
    reg_save_$registers_preserved_by_statement 0x0ED458 0x20     level 2
    reg_save_$unaffected_by_routine          0x0ED398 0x66     level 2
    reg_save_$killed_by_routine              0x0ED438 0x20     level 2

### `lang/lang/source/reg_vars.pas`

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
- include `//lang/lang/source/reg_alloc.ins.pas`
- include `//lang/lang/source/g_opt.ins.pas`
- include `//lang2/source/ftn/source/f_hash.ins.pas`
- include `//lang/common/source/mem.ins.pas`
- include `//lang/common/source/std.ins.pas`
- include `//lang/common/source/spos.ins.pas`
- include `//lang/common/source/token.ins.pas`
- include `//lang/common/source/cail.ins.pas`
- include `//us/us/sys/ins/base.ins.pas`
- include `//us/us/sys/ins/rws.ins.pas`

    calculate_memory_ranges                  0x0C90DE 0x40C    level 2
    find_next                                0x0C905A 0x84     level 2
    bit_range_set                            0x0C8EEE 0x16C    level 2
    bit_clear                                0x0C8EA8 0x46     level 2
    bit_set                                  0x0C8E64 0x44     level 2
    initialize_4_bit_vectors                 0x0C8D24 0x140    level 2
    propagate_availability                   0x0C8B28 0x1FC    level 2
    store_debug_info                         0x0C9E58 0x3C6    level 2
    need_lr_for_fvar                         0x0C9BFE 0x25A    level 3
    is_reg_candidate                         0x0C9A6E 0x190    level 3
    fill_avail_heap                          0x0C999A 0xD4     level 3
    get_range                                0x0C9668 0x332    level 3
    calc_ln                                  0x0C94EA 0x17E    level 3

### `lang/lang/source/target_68k_dummies.pas`


    sym_$displacement_literal_pool           0x0CA256 0x16     level 2
    sym_$displacement                        0x0CA240 0x16     level 2
    isc_$set_source_language                 0x0CA23E 0x2      level 2
    bin_$emit_compilation_pure_text          0x0CA23C 0x2      level 2
    at_backend_$end_compilation              0x0CA23A 0x2      level 2
    at_backend_$begin_compilation            0x0CA238 0x2      level 2
    at_backend_$initialize_ftn_entry         0x0CA236 0x2      level 2
    at_backend_$can_load_module_db           0x0CA220 0x16     level 2

