# The core inserts - plan

About 126 of the 156 units open the same prelude of `lang/lang` inserts,
starting from `globals.ins.pas` (`docs/routines-cc.*.md` gives each unit's
list in the order opened; il.pas's is typical):

    /us/ins/ubase, /sys/ins/fpp, globals, glob_extern.ins.plb (a DSEE
    derived object of glob_extern), glob_extern, real_globals,
    real_externals, il, target_properties, cargs, gspace, strings, token,
    il_utils, inc_list, error_listing, gen_utils, add_node, debug_sym_dmp,
    globals_from_general, globals_from_backend, globals_from_frontend,
    /us/ins/lib, outbin

Parallel translation (at most 3 subagents) starts when these are
**settled**: every routine they declare has a heading checked against its
callee and callers, every shared global cell (`docs/globals-cc.*.md`) is
declared with its owner, offset and width, and the IL node and block types
have the fields the provider units use.  Fields found later are added by
the translators; headings and cells should not need to change.

## Providers (cc.m68k)

| insert | unit | routines | bytes | state |
|--------|------|----------|-------|-------|
| gspace | `lang/lang/source/gspace.pas` | 6 | 644 | done |
| strings | `lang/lang/source/strings.pas` | 7 | 702 | |
| prtsub | `lang/lang/source/prtsub.pas` | 7 | 632 | |
| target_properties | `lang/lang/source/target_properties.pas` | 3 | 294 | |
| il | `lang/lang/source/il.pas` | 1 | 580 | |
| token | `lang/lang/source/token.pas` (+ `lang/common/source/token.pas`) | 12 (+8) | 1946 | |
| inc_list | `lang/lang/source/inc_list.pas` | 5 | 916 | |
| error_listing | `lang/lang/source/error_listing.pas` | 6 | 894 | |
| il_utils | `lang/lang/source/il_utils.pas` | 14 | 3412 | |
| gen_utils | `lang/lang/source/gen_utils.pas` | 21 | 4248 | |
| cargs | `lang/lang/source/cargs.pas` | 24 | 9064 | |
| add_node | `lang/lang/source/add_node.pas` | 23 | 18204 | headings first |
| debug_sym_dmp | `lang/lang/source/debug_sym_dmp.pas` | 56 | 15050 | headings first |
| outbin | `lang/lang/source/outbin.pas` (m68k only) | 70 | 24354 | headings first |
| globals, glob_extern, real_globals, real_externals, globals_from_*, lib | (variables and foreign headings) | | | from the globals catalogue |

## Shared global cells (the largest groups)

- `il.pas`'s block, A5 0x169C70: longwords at +0xC4..+0x184 (+0x180 is
  read by 37 units), set up by `initialize_module`.
- `cargs.pas`'s block, A5 0x2C33EC: option bytes and words at
  +0x264..+0x28B (up to 29 units each): the command line's options.
- `c_expr_sem.pas` (+0x2390..+0x23BC) and `c_syntax.pas`: the front end's
  (`lang/c_compiler/source/c_globals.ins.pas`, not the prelude).
- `target_properties.pas` (+0x10, +0x7F), `runbackend.pas` (+0xC, +0x16),
  `spos.pas` (+0x2EFC, a word, 15 units), `error_listing.pas` (+0xC).
