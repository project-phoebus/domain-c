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
| strings | `lang/lang/source/strings.pas` | 7 | 702 | done |
| prtsub | `lang/lang/source/prtsub.pas` | 7 | 632 | done |
| target_properties | `lang/lang/source/target_properties.pas` | 3 | 294 | done (fields named by offset) |
| il | `lang/lang/source/il.pas` | 1 | 580 | done (globals named by offset) |
| token | `lang/lang/source/token.pas` (+ `lang/common/source/token.pas`) | 12 (+8) | 1946 | headings and tables (lang/common's adds nothing to the core) |
| inc_list | `lang/lang/source/inc_list.pas` | 5 | 916 | headings |
| error_listing | `lang/lang/source/error_listing.pas` | 6 | 894 | headings, +0xC |
| il_utils | `lang/lang/source/il_utils.pas` | 14 | 3412 | headings |
| gen_utils | `lang/lang/source/gen_utils.pas` | 21 | 4248 | headings |
| cargs | `lang/lang/source/cargs.pas` | 24 | 9064 | headings, the options record, shared cells |
| add_node | `lang/lang/source/add_node.pas` | 23 | 18204 | headings (11 called from outside) |
| debug_sym_dmp | `lang/lang/source/debug_sym_dmp.pas` | 56 | 15050 | headings (9) |
| outbin | `lang/lang/source/outbin.pas` (m68k only) | 70 | 24354 | headings (3) |
| globals_from_frontend, _backend, _general, real_externals, lib | (foreign headings and cells) | | | done (placement rule in globals_from_backend.ins.pas) |
| glob_extern, glob_extern.ins.plb, real_globals | | | | nothing required |

**The core is settled (2026-11-10).**  Every routine of a provider that
another unit calls has a heading read off its frame and call sites;
every shared cell of the providers is declared (il, target_properties,
cargs, token, error_listing; the other providers have none); the
foreign routines and cells that units opening the prelude need and no
other insert they open could declare are in globals_from_* (front end:
type_exp, cgerr, cgerr_no_source, advance_listing_to_line, ...; back
ends: the entry points runbackend calls and runbackend's +0x8..+0x16),
real_externals (pas_$new, pas_$dispose, ftn_$dlog10) and
us/us/ins/lib.ins.pas (lib_$cv_fp_in, lib_$cv_dfp_out, lib_$cv_sfp_out,
lib_$data_move).

For the parallel translators:

- A provider's global routines that only its own unit calls are not in
  its insert (listed at the head of add_node, debug_sym_dmp and outbin's
  inserts): declare them in the unit file (module-level, not internal:
  they load A5).  add_node's add_top_node must stay out of the insert:
  c_stmt_sem and c_syntax have internal routines of that name.
- Headings read off frames use univ_ptr for every pointer and p1..pn
  for names; narrow the types (and name the parameters) from the callee's
  body, which is the expected kind of core change.
- cargs_$options (cargs.ins.pas) is one packed record: read the field
  comments for the option behind each bit; the sets' elements are
  numbers.  Rev 8.89 merges consecutive constant stores to packed fields
  (docs/rev889-patterns.md 10): write the separate assignments.  A name
  is the 1026-byte cargs_$name_t (length, body), not a varying string.
- Front-end cells used by add_node, attributes and error_listing come
  from lang/c_compiler/source/c_globals.ins.pas, which those units open;
  unix_objmod's +0x5DD0 and +0x5E16 (c_lex_pp, c_main) and emit's +0x108
  (jmp_br_resolve, outbin, unix_objmod) belong to inserts outside the
  prelude (c_globals or unix_objmod's; codegen or final's).

## Shared global cells (the largest groups)

- `il.pas`'s block, A5 0x169C70: longwords at +0xC4..+0x184 (+0x180 is
  read by 37 units), set up by `initialize_module`.
- `cargs.pas`'s block, A5 0x2C33EC: option bytes and words at
  +0x264..+0x28B (up to 29 units each): the command line's options.
- `c_expr_sem.pas` (+0x2390..+0x23BC) and `c_syntax.pas`: the front end's
  (`lang/c_compiler/source/c_globals.ins.pas`, not the prelude).
- `target_properties.pas` (+0x10, +0x7F), `runbackend.pas` (+0xC, +0x16),
  `spos.pas` (+0x2EFC, a word, 15 units), `error_listing.pas` (+0xC).

## Method change (2026-11-10)

To settle the core sooner, the remaining providers get their **headings,
global cells and types** first (`tools/cc_params.py` gives each routine's
frame slots, A5 load, and whether callers read D0/A0 after the call); their
bodies are translated in the parallel phase like any other unit.  Types the
headings cannot decide are `univ_ptr` (any pointer) or the width's integer;
translators narrow them, which is the one kind of core change expected
later.

## The front end's inserts (translator B, 2026-11-11)

| insert | state |
|--------|-------|
| `lang/c_compiler/source/c_objtype.ins.pas` | type_exp_t (type_exp's result), c_type_t (integral and floating type nodes); the other node kinds TODO |
| `lang/c_compiler/source/c_globals.ins.pas` | every front-end cell another unit reaches (both binaries, same offsets), by owner; diagnostics cells named, the rest by offset; c_data.asm's diagnostic tables; errorlst |
| `lang/c_compiler/source/c_externs.ins.pas` | get_rlen, error_text, warning_text, initdate (narrowed); the other cross-unit routines read off frames (TODO) |
| `lang/c_compiler/source/c_pre_proc.ins.pas` | pp_$line_t, CR_ |
| `lang/c_compiler/source/general_utl.ins.pas` | done (c_general_utl) |
| `lang/c_compiler/source/macro_read.ins.pas` | MR_ headings (frames), mr_632, mr_date, mr_time |
| `lang/c_compiler/source/macro_utl.ins.pas` | done (c_macro_utl): text list elements, macros |
| `lang/c_compiler/source/c_lex_pp.pvt.pas`, `c_syntax.ins.pas`, `c_expr_syn.ins.pas`, `cppansi.ins.pas` | headings read off frames and call sites (TODO) |

