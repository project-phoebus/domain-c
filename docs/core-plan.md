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
| token | `lang/lang/source/token.pas` (+ `lang/common/source/token.pas`) | 12 (+8) | 1946 | done (lang/common's: translated, best effort; adds nothing to the core) |
| inc_list | `lang/lang/source/inc_list.pas` | 5 | 916 | done (lists declared) |
| error_listing | `lang/lang/source/error_listing.pas` | 6 | 894 | done (+0x8, +0xC, the saved error) |
| il_utils | `lang/lang/source/il_utils.pas` | 14 | 3412 | done (nodes by offset) |
| gen_utils | `lang/lang/source/gen_utils.pas` | 21 | 4248 | done (nodes by offset) |
| cargs | `lang/lang/source/cargs.pas` | 24 | 9064 | done (best effort; both variants, `%if cc_a88k`) |
| add_node | `lang/lang/source/add_node.pas` | 23 | 18204 | headings (11 called from outside) |
| debug_sym_dmp | `lang/lang/source/debug_sym_dmp.pas` | 56 | 15050 | done (best effort; headings narrowed) |
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
| `lang/c_compiler/source/c_objtype.ins.pas` | type_exp_t (type_exp's result); c_type_t's variants for the kinds c_sym_map prints (integral, floating, subrange, enumeration, pointer, arrays, set, structure, 121, function returning, typedef name); c_sym_t (symbols: variables, constants, labels, typedefs), c_field_t, c_attr_t, c_flags_t, c_vat_t (translator D); kinds 124..126, 133, 135, 136, 210 TODO |
| `lang/c_compiler/source/c_globals.ins.pas` | every front-end cell another unit reaches (both binaries, same offsets), by owner; diagnostics cells named, the identifiers cc makes (id_end_of_for, id_end_of_while, id_at, id_string_constant), the rest by offset; c_data.asm's diagnostic tables; errorlst |
| `lang/c_compiler/source/c_externs.ins.pas` | get_rlen, error_text, warning_text, initdate, sym_map (narrowed); the other cross-unit routines read off frames (TODO) |
| `lang/c_compiler/source/c_pre_proc.ins.pas` | pp_$line_t, CR_, mr_std_include_state |
| `lang/c_compiler/source/general_utl.ins.pas` | done (c_general_utl) |
| `lang/c_compiler/source/macro_read.ins.pas` | done (c_macro_read): MR_ headings, mr_open_quote (was mr_632), mr_date, mr_time |
| `lang/c_compiler/source/macro_utl.ins.pas` | done (c_macro_utl, c_macro_read): text list elements (pos, kind), macros, 64 actuals |
| `lang/c_compiler/source/c_lex_pp.pvt.pas` | done (c_lex_pp, translator H): PPIO_ headings, the file stack (lex_file_t complete, lex_files, lex_depth), lex_listing_line (number field and text), lex_macro_expanded |
| `lang/c_compiler/source/c_expr_syn.ins.pas` | done (c_expr_syn, translator L): the parsing levels' (follow, lab, ctx) |
| `lang/c_compiler/source/c_syntax.ins.pas`, `cppansi.ins.pas` | headings read off frames and call sites (TODO; c_type_name narrowed from c_expr_syn's calls) |
| `lang/lang/source/attributes.ins.pas` | done (attributes, translator M): the type and variable forms of the attributes (attr_tattr_t, attr_vattr_t), a routine's options (attr_rtn_opts_t, a block's +332); every global routine but attr_packed_size; declares its own types (c_main and c_lex_pp open it before c_objtype) |

Translator H (2026-11-11), c_lex_pp: c_globals.ins.pas now has the
token classes (ctk_ constants: k in 0..75 the class of the k-th name
of c_data.asm's table, which c_main's rword_init enters with idntk(k,
...); 76 identifiers, 81/82/85 integer constants, 92/93 strings) and
lex_tokens [-10..236] (the token of class k at [k], the compound
assignments at [-10..-1], the lex_add_assign.. constants); csyn_200 is
token_kind, lex_2ae4 lex_token, lex_49a/lex_14b2 the kw_options and
kw_attribute nodes, lex_2ae0/2af0/2af2/2afe lex_total_lines,
lex_systype_state, lex_inline_state, lex_module_seen; lex_text is
varying [520] (questions 9); cdef_38/3c/54 are cdef_data_sect,
cdef_code_sect and cdef_outer_block; unix_objmod's two cells the front
end sets are uobj_hp_standard and uobj_systype_2.  c_externs: init_lex,
get, clex_$unget, clex_$catstring checked.

Translator H, c_main: c_objtype.ins.pas gets c_name_t (identifier and
line, 8 bytes), c_decl_t (def_blk_skeleton's declaration, by offset),
c_exp_t (an expression stack entry, by offset) and c_kw_node_t;
c_globals.ins.pas names the identifiers cc enters (id_main, the
attribute keywords id_/idu_, idu_options, idu_attribute, c_def_sem's
cdef_id_ names), con_zero and con_minus_one, cexs_stack (was
cexs_390), cst_stack_size, c_rword_table; kw_options and kw_attribute
are c_kw_node_t.  The c_externs headings c_main calls (fnd_name,
def_blk_skeleton, def_blk_params, body_s, body_opr, expr_op, call_s,
body_e, ...) are left as read off the frames: their owners narrow
them.


Translator L (2026-11-11), c_expr_syn: c_objtype.ins.pas names the
expression stack entry (c_exp_t: node, sym, item, disp, typ, line),
adds c_tokset_t (follow sets), c_parlist_t, c_cexp_t, c_blk_t and
c_reglist_t, the pointer type's ptr_reference and the function type's
fn_params and fn_conv; c_decl_t's +12 is flags; c_globals' csyn_60 is
the calling contexts' stack (csyn_202 its top) and cdef_50 the current
block (docs/questions.md 38-42).

Translator L, c_stmt_sem: c_externs.ins.pas's c_stmt_sem headings are
checked against the bodies; c_objtype.ins.pas gets c_top_t,
c_tree_t, c_desc_t, c_case_t and c_caselist_t, c_sym_t's blk_next and
label fields, c_blk_t's labels, return label and frame fields.  dpc
lays out `0..255' in a record as a word and aligns a packed record to
a word: byte fields at odd offsets are written as char or inside a
packed record that starts at an even offset.

Translator O (2026-11-11), c_def_sem: c_externs.ins.pas's c_def_sem
headings are checked against the bodies (names by univ c_name_t where
a caller passes a symbol's +4; lookups return il_$node_ptr_t; def_varn's
declaration is var; def_arr's third argument a node to fill;
def_conn, def_enum_skeleton functions); globals_from_frontend's
type_exp names its parameters t and d.  c_objtype.ins.pas gets
c_dattr_t (a declaration's 20-byte attributes, c_decl_t's variant
attr), c_parm_t (kind 121 parameters), c_tag_t (structure tags),
c_fldlist_t (a structure being laid out), c_dynm_t, c_enumset_t;
c_name_t's +6 and c_sym_t's +10 are the uplevel flag; the
enumeration, pointer, array, set and structure variants and c_blk_t
are named further (the options field at +374 a variant).  c_globals:
cdef_44 is cdef_dynm_inits, cdef_4c cdef_fwd_ptrs.  At the merge with
translator M's attributes.ins.pas (kept), O's provisional headings for
merge_attribs, merge_attribs_natural, attr_tattr_to_vattr, attr_validate,
attr_compute_routine_options and add_attribute gave way to M's; the
record parameters M takes by address became univ (c_dattr_t, c_attr_t
and c_blk_t's ropts name the same bytes as attr_tattr_t and
attr_rtn_opts_t), and c_def_sem and c_syntax pass the records
themselves and cast their node pointers to il_$node_ptr_t.

Translator O, c_syntax (started): cc_walk_it takes the walker as a
routine pointer (c_externs.ins.pas's c_walker_t, `^procedure(var n:
il_$node_ptr_t)'), call_kfold confirmed; kfold and kfold_$general are
declared in c_syntax.pas (no kfold insert is opened); us/us/ins
fpp_errs.ins.pas and peb.ins.pas are new empty stubs.  The other 47
routines are not written yet.
Translator P (2026-11-11), c_expr_sem: c_externs.ins.pas's c_expr_sem
headings are checked against the bodies (init_aux takes `out d:
c_desc_t; in t: type_exp_t', c_stmt_sem's calls fixed; coerce's third
parameter is check; body_opr and expr_op take a c_name_ptr_t, which
the callers' addr(...) passes; push_con, push_fcon, adjust_parm,
adjust_blk_for_db, test_ne_zero confirmed).  c_objtype.ins.pas:
c_exp_t's +12 offset, +16 index, +20 base, the flags at +56/+57 (bits:
force_disp, long_index, is_addr, var_pending), +60 bf_done; c_desc_t's
flags b5..b0 (b2 an array); c_blk_t's +388 exposed; c_name_ptr_t.
add_node.ins.pas: add_dn's and add_sdn's second parameter (a symbol)
and add_sdn's third, add_disp_node's second, are univ_ptr (c_stmt_sem's
add_dn call fixed).

Translator P, kfold: new stubs lang/lang/source/g_opt.ins.pas (opt_main's
table at +0x4009C, opt_4009c), lang2/source/ftn/source/f_hash.ins.pas,
lang2/source/ftn/source/const_op.ins.pas (r8_expon, r8i4_expon), and
us/us/ins/fpp_errs.ins.pas, fpp.ins.pas, peb.ins.pas (empty; c_expr_sem
and kfold open them).
