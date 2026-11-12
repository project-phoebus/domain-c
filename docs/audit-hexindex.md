# Audit: indexed displacements read as decimal

objdump prints a plain displacement in decimal (`%fp@(12)`) but an
indexed one, `(d,An,Xn)`, in hex without a prefix (`%a0@(12,%d0:l)` is
0x12).  `tools/cc_dis.py` has rewritten the indexed ones as `0x12` since
797910a (2026-11-11 09:55, `hexindex()`); units translated before then
could have read them as decimal (docs/rev889-patterns.md 38).  Translator
OO, 2026-11-11.

## Method

Every unit in the tree (the gate's unit files, both binaries where the unit is
in both; lang/common's and lang/lang's token.pas each against its own
unit) was compiled by dpc as the gate compiles it (the gap rewrites
applied, the objects kept), and for each routine the indexed
displacements of dpc's object (`m68k-elf-objdump -d`) were collected and
compared with the image's (cc_dis.py's form), both through `hexindex()`.
A displacement H of the image whose hex digits are all decimal digits (H
of 0x10 or more) is flagged when dpc has int(hex(H), 10) instead (the
image's `(0x24,A2,D2.l)` where dpc has `(24,...)`, 0x18), or has fewer
H's and more of the decimal reading than the image.  Every other image
displacement of that form that dpc lacks was looked at by hand in the
early units (lang/common, lt_utils, lang/bind, the lang/c_compiler units
and lang/lang units committed before 797910a, do_report).  The script is
the session scratchpad's transOO/hexaudit.py (not kept in the tree).

## Fixes

| unit | routine (cc.m68k) | image | was | now |
|------|-------------------|-------|-----|-----|
| lang/common htm.ins.pas (htm.pas) | htm_$create_table 0x068908, htm_$increment_table_entries 0x0689C8 | `(0x10,A0,D1.l)`: bucket i at +16 + 4i | buckets at +10 (`unused_0: array [0..4] of integer`), the first overlapping size and mask | buckets at +16 (`unused_0: array [0..3] of integer32`) |
| lang/c_compiler c_macro_read.pas | get_par_cooked_line 0x057570 | `pea (0x17,A1,D0.l)` | `line[n + 18]` (+17 + n) | `line[n + 24]` (+23 + n, after the 23-character piece) |
| lang/c_compiler c_macro_read.pas | get_par_cooked_line 0x057570 | `pea (0x21,A1,D3.l)` | `line[n + 22]` (+21 + n) | `line[n + 34]` (+33 + n, after the 33-character piece) |
| lang/lang il_utils.pas | il_utils_$adjust_uc 0x07DCF8, search_walk 0x07E252 | 139's operands `(0x30,A2,D4.l)`, i from 1: +52 + 4(i-1) | `xp2[7 + i]` (+30 + 4i: "from +34") | `xp[12 + i]` (+48 + 4i: from +52) |
| lang/lang il_utils.pas | il_utils_$adjust_uc (3), search_walk, il_utils_$trees_equivalent (2) 0x07E578 | 137/138/143's operands `(0x24,A2,D2.l)`: +40 + 4(i-1) | `xp[6 + i]` (+24 + 4i: "from +28") | `xp[9 + i]` (+36 + 4i: from +40) |
| lang/lang gen_exception.pas | gen_exception_$write_frame_and_handler_records 0x07A1AE | a handler's variables `(0x48,A2,D2.l)`, j from 1: +76 + 4(j-1) | `h^.xp[12 + j]` (+48 + 4j) | `h^.xp[18 + j]` (+72 + 4j) |
| lang/lang runbackend.pas (later; il_utils's offsets copied) | detect_fortran_param_scalarity_mismatches 0x0B0CB6, build_call_graph_walk_il 0x0B0F48 (2), normalize_il 0x0B17BA | `(0x24,...)`, `(0x30,...)` as above | `xp[6 + i]` (4), `xp2[i + 7]` (2) | `xp[9 + i]`, `xp[i + 12]` |
| lang/lang commit_top_node.pas (later) | contains_same_lvalue 0x075D8E | `(0x24,A3,D4.l)` | `xp[6 + i]` | `xp[9 + i]` |

The same code in cc.a88k (htm 0x06A2E8.., c_macro_read 0x0577F0, il_utils
0x07F6D8.., gen_exception 0x07BB8E, runbackend 0x0B2696.., commit_top_node
0x07776E) had the same slips.  The tree nodes' operand offsets (+40 for
137/138/143, +52 for 139) agree with add_node.pas and commit_top_node's
own header, which were read correctly.  c_macro_read's #undef message is
copied to line[n + 34] for 23 characters but its length is set to n + 51
(`addi.w #51'), 5 short: the image's, kept (docs/questions.md).

## Units with nothing misread

objio, objutil, do_report; c_cond_read, c_error, c_general_utl,
c_get_rlen, c_lex_pp, c_macro_utl, c_sym_map, fe_cc_hooks_to_backend,
frontend_cc_dummies; ass, bvs, diag, ecb, mem, pds, spos, std, token
(lang/common, with its insert token.low.pas); cargs, celpkg, error_listing, gen_debug,
gen_utils, gspace, il, inc_list, iosub, prfpkg, prtobj, prtsub,
sortidntk, strings, target_68k_dummies, target_properties, time, token
(lang/lang); arith, bug_check, mrh, seg_size.  The later units showed
nothing either, but for runbackend and commit_top_node above.

The image displacements left unmatched in those units were all checked:
jump tables disassembled as code (c_cond_read's cr_$get_cooked_line
0x34, pds's add_aux_references 0x56 and pool_local_file_table_entries
0x34, prtobj_$prtobj_full 0x64); absolute bases that dpc reaches through
the symbol instead (c_error's error_hdr 0x17: lex_text's body from
0x1449F0, lex_text at c_lex_pp +0x24DE; spos's region fields 0x10,
0x14, 0x18, 0x24 from db at 0x14E778, regions at +8); a record whose
elements dpc reaches from the record's address (pds's +44 lists,
`(0x28,An,Dn.l)` with Dn from 4); and frame arrays that dpc places
elsewhere in the frame (objio's and objutil's `(-0x21,A6,D1.w)`, a
32-character name at -0x20).
