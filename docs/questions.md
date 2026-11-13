# Deferred questions for the owner

Decisions taken conservatively while working unattended; each can be
revisited.

**Policy (the owner, 2026-11-12): "keep as found".**  While the project
is in archaeology mode, apparent slips in the original (dead tests,
unset results, wrong indices, misspelt messages, inverted comparisons)
are reproduced as the image has them and noted, never fixed.  Every
question below that only asks "a slip, kept as the image has it?" is
answered by this policy and needs no reply.

1. Commit trailers: commits end with a `Co-Authored-By: Claude` line.
   Keep or drop?
2. Placement of the prelude's foreign declarations (2026-11-10): no
   copy of glob_extern, real_globals, real_externals or the
   globals_from_* inserts survives, so each routine or cell a prelude
   unit needs and no other insert it opens could declare was placed by
   origin (front end, back end, other lang/lang units; real-arithmetic
   externals in real_externals; lib_ in us/us/ins/lib.ins.pas);
   glob_extern, its derived object and real_globals are left empty.
   The rule is in globals_from_backend.ins.pas.  Revisit if a listing or
   an insert turns up.
3. cargs_$options_t (cargs.ins.pas): four groups are sets and the rest
   booleans and subranges, on the evidence of Rev 8.89 merging
   consecutive constant stores (docs/rev889-patterns.md 10).  If the
   original used more sets (for example for the +0x27A..+0x27B and
   +0x28A..+0x28B flags), only the declarations change, not the layout.
4. get_rlen (c_get_rlen.pas) is called by reg_life, which opens
   neither c_externs nor c_globals: its heading (c_externs.ins.pas,
   taking a type_exp_t) is not visible there.  Add a univ heading to
   globals_from_frontend.ins.pas (as for type_exp), or have reg_life
   declare it?  Left to the lead (translator B, 2026-11-11).
5. c_externs.ins.pas now declares about 85 front-end routines (headings
   read off frames, TODO(pascal)), and add_node, attributes and
   runbackend open it: their translators should check for clashes with
   their own internal names (add_node's add_top_node is not among
   them; `get', `identifier', `syntax' are).
6. c_data.asm's diagnostic tables are declared in c_globals.ins.pas as
   cerr_code_map (0x040CD2), cerr_messages (0x040D7E) and cerr_texts
   (0x0412A6), names and bounds chosen by c_error's translator; the
   c_data.asm translator should keep or rename them.
7. errorlst's heading is in c_globals.ins.pas, not c_externs: its only
   callers (error_listing's error0..error3) open c_objtype and
   c_globals but not c_externs.
8. frontend_cc_dummies opens no insert; its dummies return in D0 though
   the prelude declares modify_m2_native_external_name as returning a
   pointer (coff_syms reads A0).  The unit keeps the image's form.
9. c_lex_pp's +0x24DE (lex_text, the current line's text) is declared
   varying [256] of char; the space to the next known cell (+0x26E8) is
   522 bytes.  Settle when c_lex_pp is translated.

10. Translator A (2026-11-11): lang/common/source/token.pas does not
   open il.ins.pas, yet lang/lang/source/token.ins.pas (which it opens)
   names il_$node_ptr_t; token.low.pas (private to token.pas) declares
   il_$node_ptr_t and the node fields token.pas uses, at il.ins.pas's
   offsets.  Likewise st.ins.pas declares only the block fields ecb.pas
   uses.  If the original il_$node_t is ever reconstructed in one
   shared insert, token.low.pas should become its private view.
11. Probable bugs of the original, reproduced as the image has them:
   mem.pas rws_release leaves the chain's head on a disposed chunk when
   older chunks remain; htm.pas addresses bucket i at +10 + 4 * i (bucket
   0 overlaps the header); bvs.pas check2_same_size never compares
   source 2's size; bvs_$and_and_test tests the source's longword.
   Keep as is?
12. tools/coff_compare.py's --unit now also takes a tree path less .pas
   (two units are named token), and tools/cc_check.sh passes each
   file's; lang/lang/source/list_tree.ins.pas is new (a stub with
   list_tree_$print_tree only) and us/us/ins/{loader,fault,unix_sig,ms}
   are new stand-ins.
13. IL nodes read by offset (translator C, 2026-11-10): il_utils and
   gen_utils read many node kinds (tree nodes 137..233, variables 109
   and 110, blocks 105 and 172, sections 182 and 183, address constants
   163 and 195, ...) whose variants nobody has named yet.  Rather than
   invent per-kind variants, il.ins.pas got generic views by offset
   (xp[k], xl[k] at +4k; xp2[k], xl2[k] at +4k+2; xw[k] at +2k; xc[k] at
   +k), the convention of IL's globals.  Replace them with named
   variants as the kinds are identified, or prefer per-kind variants
   now?
14. tools/coff_compare.py and tools/cc_check.sh pick a binary's unit by
   its path (--unit lang/lang/source/token): two units are named
   token.pas, and the gate skipped lang/lang/source/token.pas silently
   (`no single unit').  The change belongs in the source repository's
   coff_compare.py too when it is merged back.

15. Translator E (2026-11-11): pds.pas opens //us/us/sys/ins/dst.ins.pas
   (`/sys/ins/dst.ins.pas' by the include rule), which the install's
   sys/ins does not have, so pds.pas cannot be compiled until a
   stand-in exists.  Where should it go (us/us/sys/ins/dst.ins.pas in
   the tree, included by path, or a rewrite rule)?
   Lead's provisional decision (2026-11-11): no dst.ins.pas exists in any
   of the SR10.x installs or elsewhere in the archives (an internal
   insert, the debug symbol table's, not shipped to customers).  A
   customer-path insert the install lacks is reconstructed in the tree
   at its //us path, us/us/sys/ins/<name>, and included by that path,
   with a header note that the original is /sys/ins/<name>.
16. objio.ins.pas and objmod.ins.pas: the source repository's
   com/bind/objio.ins.pas was split, its OBJ records going to
   us/us/ins/objmod.ins.pas (cc's units open objmod first) and its
   status codes and routines staying in objio.ins.pas.  The com/ins
   inserts objio uses were copied into the us/us/ins stand-ins (strl,
   mst, file, cmpexe, pfm and name, the last two including the customer
   insert first) and misc_server/clib/ins/unix_time.ins.pas;
   us/us/ins/ios.ins.pas declares ios_$inq_obj_uid with an integer
   stream id since /sys/ins/ios.ins.pas comes after it.  Keep, or
   revisit when the source repository's com/ins inserts change?
17. us/us/ins/objutil.ins.pas makes three parameters univ (the error
   routine, the lookups' options, the kind) because gen_utils.pas passes
   inlib_error's address, an integer built with `!', and a 280-byte
   frame area; objutil's own bodies take the set and an integer kind.
   gen_utils could instead pass a objutil_$lookup_opts_t and an integer
   kind (its 280-byte `info' is only the callee's word); left to the
   lead.
18. spos.pas: the regions' database is taken to be one record (next
   position, last region, 3001 regions) because Rev 8.89 addresses all
   of it absolutely; the image puts the regions at +8 where dpc puts
   them at +6 (docs/rev889-patterns.md 21).

19. Translator D (2026-11-11): probable slips of the original in the
   front end, reproduced as the image has them: c_macro_read's
   get_par_cooked_line copies the tail of two messages to positions
   that do not follow the text before them (`Formals list of macro
   "' name: the closing text at line[n + 18] instead of n + 24; `Text
   follows the valid #undef of ' name: at line[n + 22] with the length
   n + 51, instead of n + 34 and n + 56); mr_$get_expanded_line leaves
   its `#if' flag unset when it resumes a kind 5 piece (the register
   holds remove_q's position, whose low byte the image tests);
   c_sym_map's print_addr_cons passes 4 for its 3-blank literal.  Keep
   as is?
20. Translator D: c_objtype.ins.pas now has front-end records for
   symbols (c_sym_t), structure fields (c_field_t) and attributes
   (c_attr_t), and c_type_t variants by kind; blocks and sections
   (IL kinds 105..108, 172, 182, 183) stay il.ins.pas views by offset
   (question 13).  The symbol chain hangs from an identifier's +8,
   which il.ins.pas calls idnt_unused_8 (an integer32): c_sym_map
   reads it as xp[2] and transfers it to c_sym_ptr_t.  Narrow it in
   il.ins.pas (a core change) when the lead prefers.
21. Translator D: mr_632 (macro_read.ins.pas) is a char, not a
   boolean: str_locate_c_id stores the open quote in it ('"', '''' or
   '>'), and cr_$get_cooked_line tests it with `tst.b; sne'.  It is
   now mr_open_quote: char, and c_cond_read reads mr_open_quote <>
   chr(0).
22. Translator F (2026-11-11): cargs.pas and iosub.pas differ between
   the binaries.  One source tests a conditional variable, `%var
   cc_a88k;' declared in the unit, and tools/cc_check.sh passes
   `-config cc_a88k' for cc.a88k.  The original's mechanism (a
   conditional variable, a different insert, separate files) is not
   known; rename or move the variable (e.g. into globals.ins.pas) if a
   convention emerges.
23. cargs.pas cargs_$init_option_defaults clears l_name's length but
   blanks name_e92's characters (0x0B4C42: `clr.w (2704,A5); lea
   (3732,A5),A0'), and build_my_name_string blanks the compiler's name
   right after name_$strip_leaf_lc filled it (0x0B4872).  Both are kept
   as the image has them (probable bugs of the original).
24. cargs.pas: the cargs.ins.pas fields named by position are not set
   by parse_options (only by the defaults), so none could be renamed
   from it; parse_options confirms every named field's option.
25. prfpkg.pas reads cargs_$options (meter, -STAT, the code-generation
   options, -SYSTYPE) and IL's globals +0x10C, +0x110, +0x118 by
   absolute address, but its include list (docs/routines-cc.*.md) has
   neither cargs.ins.pas nor il.ins.pas nor anything that includes them.
   The unit keeps the list and declares what it reads itself (a copy of
   cargs.ins.pas's options record; the three IL cells by use).  Perhaps
   one of its inserts (prfpkg.ins.pas, prtobj.ins.pas) declared them in
   the original.  Its print_meter_results also reads perfsummary's
   parameter, the source line count, which perfsummary itself never
   reads (c_main passes it).
26. Translator I (2026-11-11): iosub.pas open_listing_file, with -USRCH
   and no -L name, splits the -B name's leaf (strl_$copy of b_name,
   name_$strip_leaf_lc) and takes two characters off the name and the
   leaf before naming the listing from the leaf (cc.m68k 0x0B54BA).
   Kept as the image has it; the -B name may be intended (the listing
   beside the object file) or a slip for the source name.
27. Translator I: ios_$inq_name (iosub's stream_error) is not in the
   customer /sys/ins/ios.ins.pas; it is declared in
   us/us/ins/ios_nr.ins.pas, one of the internal inserts iosub opens.
   Move it if a better home is known.
28. Translator G (2026-11-11): putobj is declared in
   globals_from_general.ins.pas (the prelude), but gen_debug.pas opens
   no prelude insert, only iosub.ins.pas (putobj's own unit's insert),
   and dpc refuses a second declaration of a routine (so iosub.ins.pas
   cannot also declare it for gen_debug while inc_list and c_error open
   both).  gen_debug.pas declares putobj itself for now.  Move putobj
   from globals_from_general to iosub.ins.pas (and add iosub.ins.pas to
   the prelude's users that call putobj without opening it:
   gen_exception), or keep the local declaration?  Also, putobj's
   second parameter is a size (the bytes mapped: gen_debug's
   flush_one_block, debug_sym_dmp's obj_alloc pass a count), not a
   pointer: the heading in globals_from_general.ins.pas (`p:
   univ_ptr') could be `size: integer32'.
29. Translator G: pds.ins.pas returns every record made as univ_ptr
   (the image returns them in D0, the two attribute sets, typed, in A0:
   docs/rev889-patterns.md 25).  The core's rule is a longword for a D0
   result; univ_ptr was taken because the records are pointers in
   every use (debug_sym_dmp passes them back and pds.pas dereferences
   them) and it spares a type transfer at each call.  Keep, or make
   them integer32?

30. Translator H (2026-11-11): question 9 settled: lex_text is varying
   [520] of char (8 characters of the listing's number field and 512
   of text, as lex_listing_line), c_globals.ins.pas changed.
31. unix_objmod's +0x5DD0 and +0x5E16, which c_lex_pp and c_main set,
   are declared in c_globals.ins.pas (uobj_hp_standard,
   uobj_systype_2) because neither unit opens unix_objmod.ins.pas;
   unix_objmod.pas must `define' them under these names (or the
   declarations move to an insert all three open).
32. The tokens' table (c_lex_pp +0x26E8) is declared lex_tokens:
   array [-10..236] so that lex_tokens[k] is the token of class k
   (c_main's rword_init fills [0..75] from +0x2710, [-10..-1] are the
   compound assignments); the original may have had two arrays or an
   offset index.  The upper bound comes only from the next cell
   (+0x2AC4).  The ctk_ class names are the spellings of c_data.asm's
   table.  Rename if the original's names turn up.
33. c_lex_pp's parse_directive has locals no instruction of its own
   touches: they are used only by the routines nested in it
   (module_sem, section_sem, systype_sem reach them through A1), and
   line_sem is a function whose result its two callers drop (written
   discard(line_sem)).  Kept as the image has them.
34. us/us/ins/c.ins.pas declares mbstowcs (the C library's, called by
   c_lex_pp's get_wstring through the transfer vector) and
   c_$map_to_apollo_cond; c.ins.pas now declares its own c_$chars_t
   (c_lex_pp opens it before the prelude) instead of cargs_$chars_t.
   iosub.ins.pas's error_exit takes a univ iosub_$status_t for the
   same reason (c_error and c_sym_map open it without base's types).
35. c_main: cc enters `_longjmp', `longjmp' and `sigsetjmp' with the
   lengths 7, 6 and 6 (copied from `_setjmp' and `setjmp', it seems),
   so c_def_sem's special names are the prefixes `_longjm', `longjm'
   and `sigset'.  Kept as the image has it (a probable slip of the
   original).
36. c_main calls pas_$ctov through the transfer vector (preprocess:
   the C string cpp_path into a varying string, three arguments); the
   reference documents ptoc and ctop but no ctov, so it is written as
   a call of an extern declared in c_main.  do_report's heading is in
   c_main too (report.ins.pas would clash with do_report.pas's own
   report_$word_t parameter).
37. time.ins.pas's cat_time_info now takes `in out s: univ
   time_$line_t' (and time.pas's definition the same), so that c_main
   can pass its PRTSUB line (dpc refuses a type transfer of a
   variable passed by reference).
38. Translator J (2026-11-11): runbackend.pas run_backend's frame has
   8 (the language), 16 (a line) and 20 (a hook routine pointer) by
   address and 12 (c_main's do_lex_for_listings, `move.l #addr,-(SP)')
   by value; c_main passes constants for 8 and 20.  That is what a
   routine parameter gives (ref 5.4: `procedure do_lex' in a routine
   without options), which dpc refuses ("a routine parameter (ref 5.4)
   is not supported yet"); unix_obj_gen, which run_backend passes it to,
   would then take one too.  Written as val_param with a routine pointer
   (unix_objmod_$lex_proc_t) by value and the others `in ... univ'
   (Table 5-1: univ cancels val_param), which compiles to the same
   frame.  If routine parameters are wanted, dpc needs them first
   (reproducer: `procedure p(procedure q); begin q; end;').
39. Translator J: runbackend's data has fourteen words at +0x18..+0x33
   that .rwdi initializes (0, 1, 2, 4, 6, 7, 8, 9, 1, 2, 4, 5, 0, 12)
   and no routine of either binary reaches; declared as an initialized
   array (table_18) so the values are kept.  The original may have been
   two tables or a constant record.
40. Translator K (2026-11-11): unix_objmod.pas calls five foreign
   things none of its inserts declares, so the unit declares them
   itself: dump_namelist (fe_cc_hooks_to_backend), dbl_to_real (kfold;
   no kfold insert is opened), time (the C library's, through the
   transfer vector), kg_$lookup (the loader's) and emit.pas's cells
   +0x108..+0x118 (emit_108; jmp_br_resolve and outbin read them too).
   Better homes: globals_from_frontend (dump_namelist), an emit or
   codegen insert (emit_108), us/us/ins/loader.ins.pas (kg_$lookup)?
41. Translator K: unix_objmod's units (coff_syms, debug_sym_dmp,
   gen_utils, outbin) do not open us/us/ins/coff.ins.pas, so
   unix_objmod.ins.pas declares its own COFF records
   (unix_objmod_$scnhdr_t, ...: coff.ins.pas's layout) and coff_syms's
   two routines (coff_syms has no insert).  Its cells are prefixed
   uobj_ (after c_globals.ins.pas's uobj_hp_standard and
   uobj_systype_2).  Those two cannot be in unix_objmod.ins.pas
   (runbackend opens it with c_globals.ins.pas), so unix_objmod.pas,
   which opens neither c_globals nor anything else that could declare
   them, declares them itself before defining them.  The order of the cells in the insert matters
   to dpc (the defined ones are laid out first, in declaration order;
   a scalar beyond 32K is refused): uobj_global_names must stay last.
42. Translator K: unix_objmod's get_reloc_symndx and get_section_id
   leave their result unset for kinds they do not know (after
   reporting, or silently), and emit_tree_node_const goes on with a nil
   section after reporting an unknown address constant; kept as the
   image has them.

43. Translator L (2026-11-11), c_expr_syn: probable slip of the
   original kept: unary_expr's increment (`++', `--', cc.m68k
   0x05215E) tests the operand's node (+0 of the stack entry) for kind
   130 and then type_exp's the node's +4 into the entry's own type, as
   if the node were the pointer type (the type is at +28).  Keep as is?
44. c_objtype.ins.pas: the expression stack entry (c_exp_t) is now
   named (node +0, sym +4, item +8, disp +24, typ +28 a type_exp_t,
   line +58, flag_61), c_main's make_main_pgm reads typ.base (was sym);
   c_decl_t's +12 is flags (a set; c_main's `:= 0' became `:= []') and
   +16..+31 size_bits, align and unused words; c_type_t's pointer and
   function variants got their further fields (ptr_reference at +34,
   fn_params, fn_conv); new: c_tokset_t (the follow sets), c_parlist_t
   (parameter type lists), c_cexp_t (a constant expression), c_blk_t
   and c_reglist_t (a block by offset; il.ins.pas's xp/xw views name the
   same words, question 13).  c_globals.ins.pas: csyn_60 is an array
   [1..128] (c_main's `csyn_60 := 3' became csyn_60[1] := 3) and
   cdef_50 a c_blk_ptr_t.  The cells keep their offset names.
45. c_externs.ins.pas headings of routines c_expr_syn calls but other
   units define were narrowed from the call sites (their owners should
   check them): c_expr_sem's coerce (a function of a type_exp_t by
   address, a word and a byte; the frame reading was wrong), push_fcon
   (a double by address), adjust_parm (a boolean by address),
   adjust_blk_for_db (a block pointer by address); c_syntax's
   c_type_name (c_syntax.ins.pas: a procedure, the follow set, a
   c_decl_t and a boolean, all by address); c_def_sem's def_subr,
   def_arr (a function), add_varn, blk_fnd_name (p16 a block) and
   def_blk_skeleton (p24 a parameter list; c_main passes nil);
   attributes.ins.pas got attr_set_align_dsc, attr_check_align and
   attr_curr_align_env.
46. do_c_string stores int_type and char_type (uint_type) in the
   declarations' +4, which c_main and alloc_builtins fill with an
   identifier or il_178 (c_decl_t's `name'): the field's meaning is
   unsettled.
47. lang/lang/source/externals.ins.pas and fop.ins.pas are new empty
   stubs (c_expr_syn opens them; so do c_def_sem, c_expr_sem,
   c_stmt_sem, c_syntax and code generator units).
48. Translator L, c_stmt_sem: case_default pushes the selector back
   (cexs_stack[top] := c.sel) and then stores c.sel's typ.size at
   -0x54 from the new top entry's end (cc.m68k 0x05CD24), the entry
   below's typ.size; kept as the image has it (a probable slip of the
   original, perhaps meant for the new entry).  The 68..70 operators
   in walk_tree evaluate the stack's first entry (`move.l 0x140440'),
   also kept.
49. c_stmt_sem: c_objtype.ins.pas gets views of IL nodes the front end
   builds (c_top_t top-level nodes, c_tree_t tree nodes, c_desc_t, the
   switch record c_case_t); c_stmt_sem reaches them by type transfer
   from il_$node_ptr_t.  If the lead prefers the il.ins.pas views by
   offset (question 13), the records can move there as variants.
   csyn_1e8 (c_syntax's +0x1E8) is tested at its +120 (a byte, `tst.b;
   bpl'); what it points to is not known, so add_ldfn reads it through
   il.ins.pas's xc view.  cc_walk_it's routine parameter is written
   addr(call_kfold) (docs/dpc-gaps.md 21); call_kfold is declared in
   c_externs.ins.pas.
50. The scratchpad directory is shared between the parallel
   translators' sessions: helper files of one translator were
   overwritten by another's (keep.sh, rt.py).  Translators should use
   a subdirectory of their own.
51. Translator M (2026-11-11), attributes.pas: the alignment
   environment, cargs_$options.b28b_0 (+0x28B bit 0), is handled by the
   image as a one-bit enumeration or 0..1 field (attr_set_align_env
   stores its word parameter's low byte without a test; merge_attribs
   compares the field's value `tst.w', merge_attribs_natural `cmpi.w
   #1'; attr_curr_align_env returns it as a word), while cargs.pas
   assigns it false, true and the boolean `natural'.  It is kept a
   boolean (attributes writes `env <> 0', `ord(...)' (docs/dpc-gaps.md
   19) and boolean tests).  Typing it as an enumeration (word,
   natural) would change cargs.ins.pas, cargs.pas (three assignments)
   and attributes; proposed, not done.
52. Translator M: c_objtype's c_attr_t names its +0 `other_bits' (a
   set), but +0 of the variable form is the size in bits
   (attr_tattr_to_vattr copies the type form's size there;
   attr_packed_size reads a structure's +12 and kind 197's +16 as bit
   counts; type_exp rounds a structure's +12 to bytes).  attributes
   declares its own attr_vattr_t (size, bits, align, natural,
   min_align) and passes c_attr_t to it as univ; c_sym_map's own
   tattr_to_vattr keeps c_attr_t's names.  Proposed: rename c_attr_t's
   fields to attr_vattr_t's (other_bits -> size: integer32, unused_10
   -> natural, unused_12 -> min_align) and fix c_sym_map's two uses.
   Also c_type_t's set variant gives set_size at +12 (integer32), but
   type_exp takes a set's size from +8 and attributes reads a word at
   +12 (the element count); not changed (no translated user).
53. Translator N: debug_sym_dmp's nested routines are passed to
   spos_$apply_over_* as routine parameters, so spos.ins.pas's headings
   now take routine parameters (core change) and tools/cc_check.sh
   rewrites an insert's scratch copy for a rule naming an insert
   (tools/cc_gap_rewrites.txt; docs/dpc-gaps.md, the note at the end of the file, with gap 21).  Is the
   tool change acceptable, or should such a heading be kept behind a
   conditional (`%if')?  And how did the original declare the passed
   routines' val_param (the reference gives no options syntax for a
   routine parameter)?
   Lead's provisional decision (2026-11-11): accepted.  An insert rule in
   tools/cc_gap_rewrites.txt rewrites a scratch copy that shadows the
   tree's insert (dpc searches the working directory first); the tree
   keeps the reference's construct, as for units.  The gate's results are
   otherwise unchanged.
54. Translator N: get_memory_loc (debug_sym_dmp) returns its location
   unset when the variable has none (failed), and get_name_rep, the
   records' makers after a bug_check of an unknown kind likewise; kept
   as the image has them.  debug_sym_dmp's two string tables (+4176,
   written as kind 27; +4192, kind 28 and "local") are named by their
   record kinds (strings_27, strings_28); which holds what (the names
   of nested or exported routines in 27, the static variables' and the
   other routines' in 28) is read off block_dmp and get_memory_loc, the
   meaning of the kinds is not known.
55. Translator O (2026-11-11), c_def_sem: c_field_t's bit-field names
   are the wrong way round: def_fld stores the bit offset in +48's low
   6 bits (`width') and the width in +49 (`at'); type_exp adds the two.
   c_sym_map prints them in that order.  Rename (c_objtype.ins.pas and
   c_sym_map's two uses) or keep?
56. c_def_sem: probable slips of the original kept: add_parm and def_fld
   set the earlier parameter's or field's type to il_178 when a name
   comes twice (as well as the new one's name); def_virt_varn allocates
   28 bytes and stores at +28; redecl_as_static does not step past an
   address constant it redirected when the variable's type has no
   size (it would loop); def_blk_params' frame offset is 8 on both arms
   of its test of the block's +376 bit 4; check_oldef_proto never reads
   its first parameter (the routine's name).  Keep as is?
57. c_def_sem: def_blk_skeleton stores its `prototyped' boolean (0 or
   0xFF) in the block's byte +293, which def_blk_params then sets to the
   count of parameters by name and check_oldef_proto reads as that
   count; c_blk_t declares it a 0..255 (nparms) and the translation
   stores 255 for true.  Two meanings, or a variant in the original?
58. c_def_sem's def_enum_list compares the enumeration's unsigned
   extremes (+36, +40) unsigned; Domain Pascal has no unsigned 32-bit
   type, so they are integer32 and the comparisons signed (a TODO in
   the body).  A dpc profile or a linteger declaration (which cannot
   hold the 16#FFFFFFFF starting value) would be needed.
59. c_def_sem's blk_fnd_name and fnd_name take the name as `in univ
   c_name_t' (runbackend passes a parameter node's +8, c_main id_main's
   cell, c_def_sem a symbol's +4) and return il_$node_ptr_t (a symbol
   or il_178); c_stmt_sem's two comparisons of fnd_name's result with
   il_178 are now dpc gap 12 (a rewrite in tools/cc_gap_rewrites.txt).
60. Translator P (2026-11-11), c_expr_sem.pas: probable slips of the
   original kept as the image has them: expr_op's `?:' (op 24) takes
   the result's bounds from entries ib and ib + 1 (`(952,A3)' and
   `(948,A3)' with A3 = A5 + 64 ib), the entry above the stack's top
   unless the operands were exchanged (ia + 1 = ib was probably meant);
   check_for_out_of_bounds sets the array variable's flag 22 when the
   constant subscript is at or past the end (c_expr_syn's comment calls
   22 `within bounds'); reference_operand compiles vat_stat and
   vat_extdef with the same code twice.
61. Translator P: c_objtype's c_field_t names +48's low six bits
   `width' and +49 `at', but expr_op's bit-field code uses +49 as the
   width (the mask `(1 lsl +49) - 1') and +48 as the position (the
   shift `32 - +48 - +49', the extraction pushing +48 then giving +49
   as the descriptor's +8): the two names are probably exchanged.
   c_sym_map prints them as named; not renamed (c_sym_map's output
   order would have to be checked).
62. Translator P: c_expr_sem's operator table (op_tab, +0x172, 8 bytes
   an operator) has 59 initialized entries and ends at +0x34A; expr_op
   indexes it by every operator code up to 65 (the builtins 60..61 and
   the internal 62..65), reading into +0x350.., the expression stack's
   unused entry 0 (zeros).  Declared [0..65] in the unit (best effort;
   the stack then lies elsewhere in dpc's layout).
63. Translator P: arith (lang2/source/lt_utils/source/arith.pas) is
   called by c_expr_sem, whose inserts (routines-cc.*.md) do not include
   arith.ins.pas: the unit declares it itself with a word operation.
   If an insert of c_expr_sem's list declared it originally (fop.ins.pas
   is a stub), move it there.
64. Translator P (2026-11-11), kfold.pas: kfold (22 call sites: c_syntax's
   call_kfold, the optimizer) and kfold_$general are declared in the unit
   (kfold forward); which insert gave the callers kfold's heading is not
   known (g_opt.ins.pas, which kfold opens, is a likely place; created as
   a stub holding opt_main's +0x4009C table that node_number reads).
   kfold takes the statement by address and passes its value on.
65. Translator P: kfold_$general's FPP operations 0x0178 and 0x0180
   (builtin functions 13 and 12, two operands) are not identified; they
   are written as Fortran's MOD and SIGN (kfold is shared with the
   FORTRAN compiler: const_op.ftn's r8_expon and r8i4_expon do its
   powers).  Its x * 0.0 identity branches (`beq') into the smcontk
   tail with A0 as fpp_$ leaves it; written as the constant operand.
   The constant node's +10 word is replaced by a node number when the
   node il_120[+10] names is an unused tree (the end of kfold_$general):
   +10 of an integer constant is the low half of its value, so either
   the constants kfold sees there are not smcontk's or the field means
   something else; kept as the image has it.

66. Translator Q: outbin.pas declares other units' cells it reaches
   absolutely, as unix_objmod.pas did with emit's: emit_108 (emit.pas
   +0x108..+0x11B; +0x110 here a count_t for its low word),
   cg_top_130 (cg_top.pas +0x130, the block's line table), delay_378
   and delay_398 (delay.pas +0x378, +0x398: two word tables ln_end
   indexes), opinfo_opword and opinfo_names (opinfo.pas, the unit with
   no code: 0x2CF9E2 and 0x2D05C4) and dbl_to_real (kfold).  The names
   are by offset; the owners' units (or a back-end insert, codegen or
   final) should declare them, and the names here be changed to match.
   (opinfo's two: done, optohex and opname in final.ins.pas, question
   148.)

67. Translator Q: the code cells' kinds are an enumerated type in the
   original (dbcod writes them with the names DEF_LBL_INSTYP ..
   FPA_CMP_INSTYP); codegen.ins.pas has them as integer constants since
   celpkg and the cells treat the kind as a number.  Should the kind
   field become the enumerated type when cg_* are translated?

68. Translator Q: outbin's module data has four identical tables of the
   integer registers' names (A5 + 0xCD0, 0xCF0, 0xD10, 0xD40), taken to
   be static variables of prt_int_regs, prtads, dbcod and wr_instr in
   that order (each routine reads only its own); and an initialized
   table of eight bit masks (+0xC50) and a byte (+0xCC8) that no
   routine reads.
   Lead's note (2026-11-11): three of outbin.pas's FPA name entries are
   written as six raw NUL bytes (the image's), so text tools (grep) treat
   the source as binary.  Kept as written; blanks or a chr(0) form would
   read better but change the data or need another initializer form.
69. Translator R (2026-11-11), c_syntax: question 55 holds for c_syntax
   too: struct_init reads c_field_t's +48 low 6 bits (`width') as the
   bit field's position and +49 (`at') as its width; c_syntax uses the
   names by offset and says so.  A rename would touch c_objtype,
   c_def_sem's def_fld and c_sym_map.
70. c_syntax: def_func's x4, x16 and x20 (c_externs.ins.pas) are the
   routine options (get_options), the parameters by name (c_parm_ptr_t)
   and the prototype's scope block (function_prototype's, c_blk_ptr_t;
   declaration_stmts copies its tags into the block def_blk_skeleton
   fills).  c_type_t's fn_unused_4/16/20 hold them.  c_syntax passes
   integer32(...) and casts back; narrowing the heading (and c_def_sem's
   def_func, c_expr_sem's call) would be cleaner but c_expr_sem is
   being translated in parallel.  Narrow at the merge?
71. c_syntax: id_at and csyn_54 (+0x50, +0x54) are one c_name_t in the
   original (member_list copies 8 bytes from +0x50 for an unnamed bit
   field), as id_main and csyn_4c (+0x48; body passes its address to
   body_opr).  c_globals declares the pointer and a word; member_list
   assigns the two fields.  Retype as c_name_t (c_def_sem, c_main and
   c_sym_map compare id_at as a pointer)?
72. c_syntax: probable slips of the original kept: constant_expr's
   address loop never ends for an index (op 13) of a constant whose
   operand is not a variable's address (154); abstract_decl passes an
   unset parameter list to def_func when no prototype is read;
   dynm_init gives its static's declaration the line of a name record
   not yet set; get_options loops for ever on `(' or `,' that is not
   followed by an identifier or `)'; function_prototype returns without
   restoring il_180 after diagnostic 210; get_constant's check_addr_init
   is passed name but reads the parent's.  Keep as is?
73. c_syntax: body_opr and expr_op (c_expr_sem) take their names as
   univ_ptr in c_externs.ins.pas; c_syntax passes addr() of c_name_t
   records (body: addr(id_main), the cell pair).  If translator P
   narrows them to `in [univ] c_name_t', c_syntax's 11 calls lose the
   addr( ).

74. Translator T: codegen.ins.pas's address descriptor fields are still
   f1..f6 (not renamed: a shared declaration).  From prtads, gen_ea_bits
   and the cg_ units they are: f1 the mode (0 none, 1 register, 2 d(An),
   3 immediate, 4/6 indexed, 7 label, 8 (An)+, 9 -(An), 10 SR, 11 a PEB
   or FPA operation, 12/16 absolute, 13 a floating register, 14 a pair,
   15 the object), f2 the register (31 none), f3 the index register, f4
   the scale, f5 flags (bit 1 a long index; 5 for the PEB's operations),
   f6 the immediate's or absolute's form; x the node, y the displacement
   (or the PEB/FPA operation, or a label's reference cell).  Rename them
   (mode, reg, xreg, scale, flags, form) at the merge?

75. Translator T: the named section std_lib (cc.m68k 0x2D2B68, 183
   longwords) is declared in globals_from_backend.ins.pas as one array
   std_lib_rtns of node pointers (std_lib.pas opens only the prelude).
   cg_fp's purge_fp calls gen_call with elements 18..22 (+0x48 the
   general floating routine with inline operation words, +0x4C for
   operation 0, +0x50 for 1, +0x54 the extended one, +0x58 for 2); the
   original probably had one variable per library routine.  Which
   routine each is is not known (opt_vector and cg_tree read others).

76. Translator T: delay.pas's word tables at +0x378 and +0x398 (delay_378,
   delay_398) are declared again in cg_fp.pas and cg_call.pas, as
   outbin.pas does (question 66).  cg_tree opens
   lang/lang/source/delay.ins.pas, the likely home; it does not exist yet.

77. Translator T: cg.ins.pas names cg_top's +0x144 cg_line (cgerr's line,
   read by cg_addr, cg_assign, cg_call, cg_fp, cg_misc, cg_tree) and
   declares cg_top_142, cg_tree's +0x188 (cg_tree_188), +0x1A0
   (cg_null_ads: .rwdi gives f2 = f3 = 31) and +0x1B4 (cg_tree_1b4),
   cg_misc's +0 (cg_misc_label), and cg_addr's tables (+0 the object
   cache, +0xC0, +0xE0 the locks, +0x120 the register records, +0x2B6).
   cg_top.pas, cg_tree.pas and cg_addr.pas must `define' them under
   these names (or the names change with them).  emit's generic
   instructions (emit's first parameter: 0 move, 1 add, 2 subtract, 4,
   18, 20, 22, 23 push an address, 24 jsr, 28 dbf, 30 ext, 31 bsr, 32
   lea of a label, 36, 39, 61 extb) are numbers here; fnl_slct maps them
   with the size to opinfo's instructions.
78. Translator S (2026-11-11), add_node.pas: **the IL node kinds' original
   names are in the image** (question 13's discussion).  add_node writes
   a kind as an enumerated value (PAS_$WRITE code 3877), and the run
   time's name table follows add_node_$dispose_top_level (cc.m68k
   0x0A06A6, cc.a88k 0x0A2086; docs/rev889-patterns.md 57): 237 names,
   0 END_OB .. 104 SIGNED_COB (the tokens), 105 PROGRAM_BLK, 106
   MODULE_BLK, 107 PROCEDURE_BLK, 108 FUNCTION_BLK, 109 VAR_NAME, 110
   FORTRAN_SYMBOL, ..., 137 TREE_NODE, 139 EVAL_NODE, 140 ASSIGN_NODE,
   144 LABEL_NODE, 145 DINDEX_NODE, 146 PTR_NODE, 147 DISP_NODE, 163
   ADDR_CON, 171 CC_CALL, 172 INNER_BLK, 205 SYM_DISP_NODE, ..., 236
   UNION_OB (the whole list is add_node.pas's an_kind_t).  add_node
   declares the enumeration for its writes and keeps numbers elsewhere.
   Proposal: declare it once in il.ins.pas (il_$node_t's kind as that
   type, or the names as constants), so that every unit can write
   `tree_node' for 137.  Two names collide with cells c_globals.ins.pas
   named by use, char_type (+0x2390) and void_type (+0x23B0); add_node
   writes them kind_char_type and kind_void_type (so the name the run
   time would print differs).  Renaming the two cells (char_ptype,
   void_ptype, or by the front end's names when found) would let the
   table be declared as the image has it.
   **Owner (2026-11-12):** yes.  **Done (translator RN1):** il.ins.pas
   declares il_$kind_t, the 237 names in order; the nodes' kind fields
   (il_$node_t and the units' views at +2) are of the type and the units
   compare names; the cells are char_ptype and void_ptype.  Where a kind
   stays an integer, and il$t: questions 314..318.
79. Translator S: add_tn takes its descriptor as `var d: univ
   add_node_$desc_t' (distribute writes it) and buildtreenode `in d:
   univ add_node_$desc_t; in ops: univ add_node_$opnds_t' (add_node.ins.pas
   declares both types; same frames as the univ_ptr headings); every
   caller's addr(x) became x (c_expr_sem, c_stmt_sem, kfold,
   commit_top_node).  copy_tree and add_node_$dispose_top_level take the
   node by address (var); add_dn's, add_disp_node's, add_pn's and
   add_dindexn's base is il_$node_ptr_t.
80. Translator S: add_node calls reg_save (cc.m68k reg_save.pas; cc.a88k's
   target_at_dummies.pas has an empty one) and kfold (with a nil parent
   passed as a constant by address, so `in parent' as c_syntax declares
   it); both are declared in add_node.pas, as no insert add_node opens
   declares them.  If reg_save's insert (or g_opt.ins.pas, which add_node
   and kfold open) held them originally, move them there.
81. Translator S: copy_tree reads a word of the section std_lib
   (cc.m68k 0x2D2B68, the data-only unit lang/dervobjs std_lib.pas) at
   +706 + 2 * the call's result class; declared in add_node.pas as an
   extern array named after the section until std_lib's contents are
   reconstructed (best effort: the name does not bind to the section).
82. Translator S, delay.pas: the image calls delay (and delay_sets)
   for their side effects 49 times without using the result; Domain
   Pascal has no function call statement, so these are written
   discard(...) (reference ch. 4, DISCARD), which dpc accepts.  Is
   that how the house style should write such calls elsewhere?
   delay.ins.pas is new (delay_$splice, delay_$divide_attributes, which
   the back end calls, and the unit's other global delay_$ routines);
   delay_$propagate_index_long and delay_$shrink_tree_node do not load
   A5 and are internal despite their names.  dfetch (kfold.pas) is
   declared in delay.pas.  The operators' `in' tests in delay use sets
   of 0..95 and 0..79 without a range check (docs/rev889-patterns.md
   41): the operator codes may be an enumeration of 96 values, as the
   node kinds are of 237.

83. Translator U (2026-11-11), cg_misc: cg.ins.pas's cg_tree_188 is
   renamed cg_zero_ads (cg_tree's +0x188, the immediate 0 operand):
   agg_opr gives it (a 20-byte copy) for a constant of zero bytes,
   strncpy and strncat store it to pad (`clr.b (An)+'), shift `and's a
   word with it to clear it, and the tests compare with it (18);
   cg_fp's two uses follow.  cg_tree.pas must `define' it under the new
   name.  emit's generic instructions read in cg_misc add to question
   77's list: 3 and, 12 not, 13 a shift (x its kind: 0 arithmetic
   right, 2 logical right, 1 and 3 left), 18 compare or test, 20 a
   conditional branch whose x is the 68000's condition code (6 NE, 7
   EQ, 11 MI, 15 LE: reverse_cc pairs them), 21 branch, 29 swap.
   Rename the generic instructions as constants when emit or fnl_slct
   is translated?

84. cg_misc: cg.ins.pas's new cg_count_t (0..65535) types shift's count
   and how and fill's len: the image zero-extends them to longwords
   and compares them unsigned.  A parameter's type must be a type name
   in dpc (and the reference), so the subrange is named.  Keep, or
   use a base type of the original's (linteger-like)?

85. Translator U, cg_top: cg.ins.pas names cg_top's cells other units
   read: cg_stmt (+0x12C, the statement compiled), cg_code_bytes
   (+0x134, emit's fnl_slct adds to it), cg_top_13a (+0x13A), cg_data_reg
   (+0x140: 13, or 8 when the data is reached through A0), cg_pass
   (+0x142, was cg_top_142: show_state prints it as PASS), cg_line,
   cg_settled (+0x146: cg_addr's merge_register clears it; at_backend_506
   at +0x148 is the last, emitting pass).  cg_addr.pas must define
   cg_addr_2a8 .. cg_addr_2ba (new), cg_tree.pas cg_zero_ads and
   cg_tree_1b4.  outbin.pas's cg_top_130 is defined by cg_top with a
   type of its own (top_line_ptr_t, the same layout as outbin's
   outbin_ln_bb_ptr_t): move the type to an insert both open?

86. cg_top: codegen passes the statement routines the address of the
   node's +4 (`pea (4,A0)': assign_proc, cbranch_proc, block_entry_proc,
   return_proc), so the original's routines probably took the node's
   variant part by reference.  cg_top's take univ records laid out from
   +4 (top_cbranch_t, ...); cg.ins.pas's assign_proc takes `in out s:
   univ cg_stmt_t' (a view by offset from +4).  Keep, or give the IL
   node type named statement variants?

87. cg_top: the routine block's flags at +374..+377 are tested as a
   longword (`(+374 >> 11) & 258 = 258': +375 bit 3 and +376 bit 4,
   both set: the block keeps A5 in a register of its own) and written
   as bytes (cg_call's +375 bit 3); cg_top writes the longword test with
   il_$node_t's xl2[93].  The two flags' names are not known.

88. Translator V: kfold's first parameter.  kfold.pas declares kfold
   `(var stmt; var n)'; c_syntax and the optimizer's units (opt_general)
   declare it `(in stmt; var n)': general_opts copies a statement held
   in a register to a frame temporary before each call (cc.m68k
   0x0D6614, `move.l A3,(-300,A6); pea (-300,A6)'), the copy an `in'
   (or value-by-address) parameter needs.  kfold.pas's heading should
   probably become `in'.  kfold, kfold_$general and dbl_to_real are
   declared in each unit that calls them (c_syntax, opt_general,
   opt_assign); the original's insert for them is not known (perhaps
   g_opt.ins.pas, but kfold.pas opens it, so a heading there would
   clash with kfold.pas's own forward declaration).

89. Translator V: il.pas's +0xC0.. as a record.  opt_select, opt_cse and
   kfold reach il_11c (+0x11C), il_120 (+0x120) and il_124 (+0x124) as
   fields of a record at il.pas's +0xC0 (`movea.l #0x169D30,A0', then
   (92,A0), (96,A0), (100,A0)); il.ins.pas declares separate variables
   (il_c0 .. il_184).  Perhaps il.pas's globals from +0xC0 were one
   record variable; the translations use the separate cells.

90. Translator V: opt_cse's operand descriptors lie 24 bytes apart
   (+16, +40, +64, +88 of its data; assign_opt's frame records likewise
   at -24 and -48) while alias.ins.pas's alias_$desc_t is 20 bytes;
   opt_cse.pas declares an element of a descriptor and 4 unused bytes.
   Is the descriptor 24 bytes (a field at +20 nobody reads)?

91. Translator V: g_opt.ins.pas names opt_main's cells by use
   (opt_dfs_number +0x50, opt_dfs_block +0x54, opt_region +0x5E,
   opt_last_block +0x68, opt_first_block +0x6A, opt_track_lines +0x6C,
   opt_dom +0x9C, opt_4009c), opt_loop's +4 (opt_loop_hoist) and
   opt_cse's +0x88 (cse_limit, opt_cse.pas defines it).  opt_main.pas
   and opt_loop.pas must `define' them under these names.  opt_4009c is
   now indexed from 0 (the image's `lea (0,A1,D3.l)', find_var and
   kfold's node_number); its entries (g_opt_ent_t) hold a region's
   block (+16) and variables (+22); +0x9C is 65536 row pointers and
   +0x4009C 65536 entries, which fills opt_main's 0x8009C bytes.
92. Translator W, list_tree.pas: the dumps print several enumerations
   and sets by name (string literals in `case' arms and bit tests, not
   name tables): the tree operators (+36 of a tree node, 0 NOP .. 89
   ILLEGAL; question 82's operator codes: the 0..95 sets agree), the
   assignment operators (+76 of 140: 0 SCALAR .. 37 ILLEGAL), the phase
   bits (add_node_$phase_t: 0 ATM .. 22 lcl_cse), a variable's
   attributes (+32 of 109: 0 var_$volatile .. 31 var_$withrecord, the
   var_$ prefix the original's), the register classes (print_rlen: 0
   null, 1 byte, 2 word, 4 long, 5 addr, 6 r4, 7 r8, 8 c8, 9 cs, 10
   vcs, 11 agg, 12 c16), the condition codes, the math functions, a
   block's attributes (+374..+379), allocation (local_bat ..) and
   calling convention (call_unk, call_pas, call_ftn, call_c,
   call_c_std, call_ada), the label classes and a statement's flags.
   The lists are in list_tree.pas's routine headers.  Should they name
   the shared types' elements (an enumeration for the operators and
   rlen, set elements as constants), as question 78 proposes for the
   kinds?  Also: list_tree_$print_tree's second parameter is the
   routine the lines go to (univ_ptr in list_tree.ins.pas, since
   iosub's line type is not declared where the insert is opened).
   **Owner (2026-11-12):** adopt Apollo's names everywhere.  **Done
   (translator RN4):** the tree and assignment operators, a variable's
   and a block's allocation have the run time's name tables in cc.a88k
   (the ISC's printers write them as enumerated values:
   tools/cc_enumnames.py, 0x0C69A4 .. 0x217BB4), so their names are the
   identifiers, not the dump's display forms: il.ins.pas's il_$top_t (0
   nop_top .. 89 illegal_top), il_$aop_t (0 scalar_aop .. 37
   illegal_aop), il_$vat_t, il_$bat_t; the operator fields at +36 and +76
   of every view and add_tn's and buildtreenode's operator are of the
   types (the ISC units' local copies are gone).  The register classes
   are il.ins.pas's constants rlen_null .. rlen_c16 (the gap at 3 kept),
   the variable attributes il_$var_attr_t (var_$volatile ..
   var_$withrecord) and set il_$var_attrs_t, the phase bits
   add_node.ins.pas's add_node_$phase_bit_t (phase_atm .. phase_lcl_cse,
   phase_23) with add_node_$phase_t a set of them, the condition codes,
   math functions and calling conventions constants (cond_t .., math_abs
   .., call_unk ..).  The ISC generator writes the classes and operators
   by name.  Not done: the block's attributes, the label classes and a
   statement's flags (bit fields the units read by mask: a re-layout of
   the node views, not a renaming).  list_tree_$print_tree's emit stays
   univ_ptr: token.low.pas still opens the insert without iosub.ins.pas.
   Questions 322..327.

93. Translator Y (2026-11-11), cg_addr: cg_reg_t's w8, w12 and w14 are
   named by offset though their use is known: w12 the stamp
   (cg_addr_2ba) at which obj was set, w8 obj2's, w14 the value's
   state (0 loaded; 2 not loaded yet: inquire emits the load, makes
   the home live; 1 edit_register's mark when a label's register has
   no home variable).  Rename (obj_stamp, obj2_stamp, state) when
   cg_tree is translated?  cg_state_t's b4, b6 and w266 hold
   cg_addr_next_dreg's and _next_areg's low bytes and
   cg_addr_next_freg.

94. cg_addr: registers and classes are compared unsigned in places
   (kill_register `cmpi.w #23; bhi', peek's `cmpi.w #4; bcc' of the
   size and its zero-extension before `size + 10 * disp',
   load_operand's `1 <= size <= 5' as `scc'/`sls', address's `cmpi.w
   #7,(2,A2); bls' and `cmpi.w #8; bls' of the size), while
   load_result is passed -1 and -2 as its operand count.  The
   original's register and class types were perhaps subranges
   (0..31, 0..15); cg.ins.pas keeps integer, and cg_addr.pas writes
   kill_register's test as `(r >= 0) and (r <= 23)' and the others
   as signed compares (the values are never negative there).

95. cg_addr: assert_optimizer_is_enabled is an internal routine of both
   cg_addr (0x0EEFF4: not -DBA and -OPT above 2) and opt_main
   (0x0DAC88: the same with a test of 0x2CE5A7 first);
   tools/cc_dis.py picks opt_main's unless given `--unit cg_addr'.

96. cg_addr: load_result tests `best <> 0' a second time under the
   constant's branch (0x0F243A), where it is always false; the dead
   code is kept as the image has it.  cg_addr_$merge_state_of_
   assigned_goto_targets goes on with a nil block after its cgerr 28
   (the image's).  unlock's test of the index register compares the
   base register with the data register (kept).

97. Translator Z, gen_unwind.pas: the unit opens none of the prelude but
   opens unix_objmod.ins.pas, whose records and headings name the
   prelude's il_$node_ptr_t and runbackend_$lex_proc_t (dpc stops on
   them).  The original insert evidently did not need them.
   gen_unwind.pas declares the two (il_$node_ptr_t as univ_ptr) between
   objmod.ins.pas and unix_objmod.ins.pas, as gen_debug
   declares putobj itself.  Alternatively unix_objmod.ins.pas could
   use univ_ptr for the nodes it only passes on (add_reloc's sect and
   target, the reloc and lnno records' sect, ...).
98. Translator Z, gen_unwind.pas: several unwind record fields are
   stored from a shifted register mask with no mask of their own
   (`lsr.l #10' into 12 or 14 bits, the second a88k FP mask `lsr.l #4'
   into 4 bits, PA floating registers 24..39 from the 64-bit mask), and
   registers are added to the 12-bit field with `bset' in a word
   temporary after subtracting 10: the original probably used sets of
   10..21, 10..23 and 24..39 in the packed records (copied from a set of
   0..31 or 0..63).  dpc refuses a set not based at 0 in a packed
   record, so the fields are integer subranges assigned with rshft and
   `!' (the stores masked).  gen_unwind.ins.pas's scope has the m68k
   fields as they were (outbin's names) and new PA and a88k arms named
   from cc.a88k bin.pas's prints; gen_unwind_$add_scope's second
   parameter is the base's address (univ_ptr; outbin passes nil).
99. Translator Z, jmp_br_resolve.pas: its module data (A5 0x2CE8BC,
   +0..+24: the branch's reference cell and label, the cell at hand, the
   pass count, the label being numbered, the section) is also
   instr_reorder.pas's A5; instr_reorder has no data and reads none
   of it (cc_globals' +0 for instr_reorder is its A5 load), so the
   block is jmp_br_resolve's (Rev 8.89 gives a module without data the
   next module's A5, as do_report has gen_debug's).  It also copies celpkg.pas's empty
   address descriptor (celpkg +24, 0x2CE68C), which celpkg does not
   export: jmp_br_resolve keeps a copy of its own rather than moving
   celpkg's variables (`define' would reorder celpkg's data).  Should
   codegen.ins.pas export celpkg's descriptors?

100. Translator X: a statement's flags at +41..+42 (g_opt.ins.pas's hdr:
   b7..deleted, then kills, last, first) are written by assign_elim as
   one 16-bit field (`andi.l #0xFF0000FF; ori.l #0x10000' of the
   longword at +40 for deleted alone; `(+40 & 0xFFFF00) >> 8 | 2' and
   `| 8' stored back for first and last of another statement), while
   other sites `bset'/`btst' single bits.  Perhaps a `set of 0..15' in
   the original (deleted element 8, no_prune 9, first 1, last 3); the
   translations keep V's booleans and store all sixteen for the former.
   Rename to a set when opt_main or opt_reachdef settle it?

101. Translator X: opt_4009c's entries are the region statements (the
   entry of region r is the statement whose +43 is r: opt_livevar's
   assign_elim reads its kind, operator and operands); g_opt_ent_t and
   g_opt_range_t were removed (kfold's node_number now reads the
   statement's block).  The table's element type is g_opt_stmt_ptr_t.

102. Translator X: opt_loop's data has opt_loop_hoist at +4 and the
   current region at +8; dpc lays defined cells out after the module's
   own, so the translation has them the other way round (internal to
   the program).  delparent (opt_strength) is declared `in p' and
   add_constant `in t; in b' after the callers' frame copies; the
   owners should confirm when opt_strength is translated.

103. Translator X: opt_vec_$process_routine (cc.m68k 0x096854, a global
   routine) has no caller in cc.m68k and its address is not taken by
   an instruction; process_candidate reaches its transforms' dispatch
   with a tree's kind when an accumulation's other operand is not a
   scalar (nothing happens: the kind is out of the jump table's 11
   entries; written as kind 0).  Is process_routine called from the
   a88k back end or through a table not found?
104. Translator AA (2026-11-11), cg_assign: assign_proc passes the
   string builtins (cbuiltin_strcpy, _strncpy, _strcat, _strncat) the
   address of its statement (`pea (A2)', the node's +4), not a node:
   cg_misc reads their operands at +60, +64, +68 of it, which are
   cg_asn_t's left, right and extra.  cg.ins.pas declares them
   `n: il_$node_ptr_t' by value, so cg_assign passes
   il_$node_ptr_t(addr(s)).  Retype them `in out s: univ cg_asn_t'
   (and cg_misc's bodies through it)?
105. cg_assign: emit_assign (0x0B7F54) lies in fpa.pas's range
   (0x0B7A8C..), not emit's, though cg.ins.pas declares it under emit;
   emit_mul_add, emit_div_sub and push_fpa_opr are fpa's too and are
   in fpa.ins.pas.  Move emit_assign there?
   Translator HH (2026-11-11): moved to fpa.ins.pas with `in' modes
   (emit_assign only reads them; emit, whose descriptors are `in',
   passes them on).
106. cg_assign: its module data has +0 and +24 two operand descriptors
   (opa, opb) 24 bytes apart (20 used), the operators' instruction
   table at +0x30 and the target at +0x7C, with +0x62..+0x7B and
   +0x80..+0x83 never addressed: perhaps unused variables, or the
   descriptors' type is 24 bytes (questions 90's opt_cse also spaces
   descriptors 24 apart).
107. Translator AA, cg_tree: probable slips of the original kept:
   assert_const_mul_candidate forms -c for a negative constant but
   tests c again (`tst.l (A0); bpl'), so negative multipliers are
   never done by shifts and adds; cg_tree_$adjust_before_round's
   bug_check message ends `support!%.' (not `%$').  cg_tree's operands
   at +0x1B8 .. +0x230 lie 24 bytes apart, as cg_assign's (question
   99) and do_const_mul's frame operands (-432, -456).

108. Translator BB: reg_action's alloc_stmt (cc.m68k 0x0C261E) asks
   gspace for n * 336 + 50 bytes for a 191 statement of n actions,
   while the actions it initializes (and add_actions fills) are 12
   bytes from +52.  Was the original's action record declared larger
   (336 = 28 * 12), or the size computed from another type?

109. Translator BB: reg_action's insert_reg_stmts (0x0C36D2..0x0C3924)
   replaces a Fortran constant's range node with buildtreenode(26, ...)
   and then copies the new tree's +4..+15 onto themselves (`lea
   (4,A0),A1; lea (4,A0),A4' and three `move.l').  Written as such
   (a cse view's u_hdr assigned to itself); the source probably meant
   to copy them from the constant replaced.

110. Translator BB: reg_alloc.ins.pas's reg_range_t words +6, +16,
   +24, +26 and longwords +12, +56 are named by position: compress_graph
   clears them and reg_action copies +24 into an action, but the units
   that set them (reg_life, reg_color_68k, reg_alloc) are not
   translated yet.  Name them when they are.


111. Translator CC (2026-11-11), opt_reachdef: g_opt.ins.pas names
   opt_main's cells the unit reads by use: opt_main_14 (+0x14, the pool
   of opt_reachdef's tables), opt_var_types (+0x4C, the variables' types
   from compute_variable_type_descriptors: type_exp_t's layout as
   g_opt_vtype_t, since g_opt.ins.pas cannot name c_objtype's type),
   opt_nblocks (+0x5A), opt_max_stmts (+0x60), opt_max_vars (+0x62).
   opt_main.pas must `define' them.  A 188 statement gets a variant of
   its own (arg_call +56, arg_num +60: a variable passed to argument
   arg_num of the call tree arg_call, paramclass's first parameter).
112. Translator CC, opt_reachdef: ftn_data_init (nested in
   reachingdefinitions) sets seen^[v] and value^[v] for
   reachingdefinitions' own local v (frame -32).  reachingdefinitions
   calls it with v the definition's variable, but init_block calls it
   (with the static link) for a definition of its own variable (D3)
   while v still holds whatever reachingdefinitions' previous loop
   left (nvars + 1 after the clearing loop).  Kept as the image has it;
   an original slip?
113. Translator CC, opt_reachdef: when opt_track_lines (opt_main +0x6C)
   is set, reachingdefinitions clears il_d0 and returns before the
   uninitialized-use warnings (and without putting il_d0 back).  The
   cell's name (translator V's, from opt_general) may not say what it
   is.  The rd sets are allocated for opt_max_stmts + opt_max_vars + 1
   bits (rd_words) and used for runbackend_16 - opt_region + nvars + 34
   (rd_used), though only region numbers are ever set.
114. Translator CC, opt_reachdef: the gap 8 rewrites for this unit
   replace each kind set by a range holding it (`>= 137 and <= 205'):
   the full comparison chains exhaust dpc's virtual registers in
   evalforeffect (gap 25) even with a call's operands left out.  The
   check of the unit is thus looser than the other units' (only the
   scratch copy; the tree keeps the sets).
115. Translator CC, opt_strength: opt_str_$opmod_of_operand,
   opt_str_$opmod1_of_multiplier and opt_str_$product_of read delay.pas's
   class_size (its +888, cc.m68k 0x169968, cc.a88k 0x2E99D8) absolutely;
   opt_strength.pas declares it extern, and delay.pas (which declares it
   as a module variable with its initializer) must `define' it.
   delparent only reads its parameter: g_opt.ins.pas's `in p' stays
   (question 102).
116. Translator CC, opt_strength: cc.a88k's unit holds 12 routines (the
   products, the substitution points, deluse, delparent, walkuses and an
   empty strengthreduce, 2 bytes); opt_strength.pas leaves the others to
   `%if cc_a88k'.  It also holds usewalk's code (0x2B3868, 0x10E bytes:
   the routine nested in cc.m68k's used_outside_loop, here taking its
   parent's frame from the dynamic link) with no .blocks entry and no
   caller, and 0x24A bytes between walkuses' end (0x2B3C8A) and
   strengthreduce (0x2B3ED4) not looked at.  How the original's
   conditional compilation left them is not known.
117. Translator CC: tools/cc_typecheck.sh's `-config cc_a88k' pass
   fails for every unit with `%var cc_a88k' (dpc: "-config: `FILE' is
   not a conditional variable name"): the option seems to need its
   value placed differently (iosub.pas shows the same).
   Lead (2026-11-11): fixed; the -config pass now ends the variable list
   with `--' before the file (dpc read the file as another variable).
   iosub and opt_strength type-check clean under -config cc_a88k.
118. Translator DD, cg_tree's generate: probable slips of the original
   kept: mul_proc leaves its routine index (D2) unset for a signed long
   by long multiplication (mdmcase 3 or 5 with the signed flag), which
   the PEB path and gen_call then use; the floating conversions (arm
   39) leave the routine (D2) unset for classes 3, 5, 9..11;
   unpack_proc's 68020 bit field size is unset for a variable offset;
   bit_test_proc's `bftst' offset for a constant element is the set's
   last bit less the element's complement (`not.l'), and its range
   check then compares the complement.  generate's scales test `cmpi.w
   #88' of the constant and then branch on the condition codes of the
   double's moves.  The three word tables at +0x70, +0xA0, +0x158 have
   holes in .rwdi (their zero words left out): the declarations write
   zeros there.  Is +0xA0 a table of its own (92 words, by operator)
   or the end of +0x70's (generate indexes it from +0xA0)?
119. Translator EE: reg_alloc's compress_graph (cc.m68k 0x0C44C4)
   clears the moved range's depth (+44, `clr.l (-0x14,A1,D3.l)' with
   D3 the slot it moved to) among the stores that clear the slot it
   left (D0): the moved range loses its loop depth, the emptied slot
   keeps it.  Written as the image does (`r^[i].depth := 0'); probably
   a slip of the original for `r^[j].depth'.

120. Translator EE: reg_alloc's alloc_ftn_vars (0x0C41C4) sets a
   strength reduction temporary's class (+11 high nibble) to 6 and then
   tests it against the static classes 1, 4, 7, 8, 11: the static
   branch can never be taken.  Written as the image does.

121. Translator EE: reg_color_68k's pickcolor (cc.m68k 0x0C5674) sets
   its result to 31 and then searches lo..hi with the loop's index in
   D0, the result's register: when no register is found the image
   returns hi + 1, not 31 (docs/rev889-patterns.md 80's sharing, here
   for a result set before the loop).  Not met (color_graph calls it
   after availcolors found one); written as returning 31.

122. Translator EE: reg_save's registers_consumed_by_fortran_symbol
   (cc.m68k 0x0EC0B0) compares a Fortran routine with the longword at
   0x2D2ED8, opt_livevar's data +0, which opt_livevar.pas declares as
   unused_0 (opt_livevar never addresses it) but opt_general and
   opt_main (assert_is_call_to_abnormal_routine 0x0DC462, ...) reach
   absolutely: a routine whose calls disturb every register but
   FP2..FP7 ([0..17]).  reg_save.pas declares it `opt_abnormal_routine:
   extern il_$node_ptr_t' until opt_main (or whichever unit owns it) is
   translated; opt_livevar's cell should then be defined by name.

123. Translator EE: reg_save's heading is now the prelude's
   (globals_from_backend.ins.pas, reg_save_$regs_t = set of 0..31):
   add_node calls it and opens no back-end insert, and cc.a88k's
   target_at_dummies has the routine too.  cg_call's local integer32
   `regs' takes it through a type transfer; a set type there would
   read better.

124. Translator FF, opt_strength: substitute (0x0E6AA4), for a 109
   temporary, joins the moved substitution points onto old's own list
   (+52 of old, then stores into new's: `movea.l (52,A2),A1' with A2 old)
   where the 110 case uses new's; the joined list then loops back on
   itself.  The last point is also stored to unset when old has none.
   Kept as the image has it: original slips?
125. Translator FF, opt_strength: doinsert (0x0E7BDC) and add_assign
   (0x0E8C8A) pass fixupchildren's `in f' flag as `pea' of 0x0E7BFC, the
   first byte of the next routine (0x4E, `link'): false to fixupchildren's
   `tst.b; bpl'.  Written as false.  Which constant the original passed
   (and why it was pooled there) is not known.
126. Translator FF, opt_strength: other kept oddities of the image:
   strengthreduce or-s each routine's excluded variables into a module
   set it never clears (the exclusions accumulate over the compilation);
   findvalues' search of the header's predecessors for one in the loop
   leaves k one past them when none is (then reads pred[npreds + 1]);
   reduce's 145 case takes the index product's first operand as the
   variable when only the second qualifies; ivs' cells are never
   disposed (exprs' are).  The headings of opt_loop's fixupchildren and
   opt_main's fixup_blocks and opt_main_$symidx_of_varn_or_fsym are
   declared extern in opt_strength.pas (no insert has them): move them
   to g_opt.ins.pas when opt_main is translated?
   Translator II (2026-11-11): decided.  fixup_blocks and
   opt_main_$symidx_of_varn_or_fsym moved to g_opt.ins.pas (opt_main
   defines them; opt_strength.pas's declarations removed).  kfold stays
   declared in the units that call it: kfold.pas opens g_opt.ins.pas and
   declares kfold `forward' with `var stmt', which a heading in the
   insert (the first declaration, which dpc follows) would contradict;
   a kfold insert would be the place.  opt_loop's fixupchildren stays in
   opt_strength.pas until opt_loop's own insert heading is decided.

127. Translator GG, final: probable slips of the original kept:
   merge_stack_adjusts (cc.m68k 0x10EE1E) makes a lea of the merged
   adjustment's magnitude (`neg.l D2' before `move.l D2,(32,A0)'), so a
   net downward adjustment of more than 8 becomes an upward one;
   assert_bfextu_requires_test (0x10C3BA) answers true whatever ends
   its scan (`st D0' after the loop), so bit_field_inst_which_obviates_
   test never keeps a bfextu's test.  Is either a misreading?
128. final: the module data's +0..+15, +36, +42 and the initialized
   tables from +0x60 to +0x87 and beyond +0x2A4 (to about +0x6AC: more
   descriptor-like 20-byte entries, and from about +0x2EC doubles each
   after a word tag: pi, 0x0B..0x0F, 0x30..0x3B; their user not identified)
   belong to the routines not yet translated; fn_0, fn_32/fn_36 names
   and fn_60's initializer are placeholders.  brimply's table at +0xA8
   (14 by 14 words) has 133 entries .rwdi leaves unset, written as 0:
   is a partial initializer intended (dpc has no syntax for one)?
129. final: plab and backtrack call makejump and final_$unlink_opts and
   ignore the cell they return (no store of A0); written as dead
   assignments (nx := makejump(...), j := final_$unlink_opts(j)).
   merge_move_sub's boolean is likewise never read by its caller.
130. Translator HH: emit's fnl_slct (cc.m68k 0x0B738E), on its error
   path (no instruction of the operation fits, or a condition out of
   range: cgerr 5, then the inline 39's cell from a recursive call),
   adds the length of its cell variable (A3) to cg_code_bytes after
   the call: that variable was not set on the path when no entry
   matched (A3 as the caller left it), and the recursive call has
   already counted its own cell.  Written as the image does; a slip of
   the original?  Likewise chk_op_restr (a code above 24), adrlen (an
   immediate form 6 or 7) and sz_case (a size of 3, 5 or above 7)
   leave their results unset (D0 holds the selector).

131. Translator HH: fpa.pas, probable slips of the original kept:
   load_c16_part (cc.m68k 0x0B9314) takes a 16-byte constant's second
   and fourth longwords from the node smcontk made for the first (its
   +16, +24: `movea.l (-36,A6),A0' after s.x was replaced), not from the
   constant; emit_fmath_top (0x0B8652) reuses its operation variable
   for 76's move from another FPA register (500, 501), so the
   operation then emitted is the move, not 466/465; emit_jsr leaves the
   routine unset for a comparison (86) with a condition 8..11.  The
   three descriptors of fpa's data lie 24 bytes apart (20 used), as
   cg_assign's and cg_tree's (questions 106, 107): perhaps the
   descriptor type is 24 bytes.
132. Translator II, opt_main: question 122 settled as proposed:
   opt_livevar's +0 is g_opt.ins.pas's opt_abnormal_routine, defined by
   opt_livevar (its two other cells became lv_cur and lv_depth, defined
   after it in the image's order).  Nothing in either binary stores to
   it, so assert_is_call_to_abnormal_routine's and reg_save's tests
   never match: the original's setter (a Fortran pragma or a name
   lookup) may have been left out of these compilers.

133. Translator II, opt_main: opt_track_lines (+0x6C, translator V's name
   from opt_general) is cleared at g_opt's start and set after reaching
   definitions (g_opt, recompute_node_lists): when set, the passes over
   the statements take the blocks as they are (no new block starts, no
   use and definition statements, no new tables).  A name like
   opt_recomputing would say more; rename?  The statement header bits
   opt_main sets are still named by position: +42 bit 2 (b42_2) the
   routine's end (149) in its region, +42 bit 4 (b42_4) a statement
   with a call, +41 bit 4 (b4) a statement with real trees, +42 bit 6
   (b42_6) a conditional branch whose condition gets its own
   evaluation.  Name them in g_opt.ins.pas?

134. Translator II, opt_main: kept oddities of the image (original
   slips?): distrib_mul's second form (shifts of sums) returns t
   unchanged when no_enforce_parens_and_ucs_eq_1 is true, the first form
   when it is false; init_opt_info_for_vars' two walks over a routine's
   variables do not advance past a 109 in Fortran (the language tested
   before the step; endless if one is met); recompute_usedef_for_
   uplevel_addressing uses the previous call's variable number (D3)
   when the chain does not end at a variable's name;
   add_use_defs_for_call_site indexes om_param_conflicts with the
   argument class left unset when num is 0; create_use_def_ob places the
   statement after an unset pointer for a mode outside 0..3;
   eliminate_dead_code_and_count_basic_blocks leaves the dead statements
   linked when it stops at a routine's start or end; g_opt's -TREE 8, 9
   and 12 exits skip the clean-up (pools, tables).

135. Translator II, opt_main: om_class_bytes (+0x70, a data class's
   bytes) has .rwdi words for 0..9 only, but the index is a nibble and
   the table runs to +0x8F (om_param_conflicts follows): written as
   [0..15] with zeros for 10..15.  Was the original a 10-element array
   with 12 bytes of something unreferenced after it?
136. Translator JJ, final: probable slips of the original kept:
   try_loading_monadic_src_here (cc.m68k 0x110F14) tests that the move's
   source is an FP register (mode 13) and then, for a source that is
   not one, makes the operation kind 40 with its op advanced (dead
   code), and clears D0 before giving up on op 430 (a procedure: its
   caller reads nothing); floatop (0x10FB84) takes a double's exponent
   as the high word and 0x7FFF less 1023 (an extended's layout), so the
   range test of its single conversion never holds but for 0.0; the ROM
   table's 1e4 (offset 0x35, A5 +0x356) is 0.0 in .rwdi;
   final_$collapsed_index_calc's fourth case gives the lea it makes c's
   length (`ilength' of c, 0x10A448).  Are any of these misreadings?
137. final: deltest (0x10C5CE) tests the six condition codes of fn_ccset
   with six copies of the same code (`btst #0' .. `btst #5' of +41):
   written as a `for' loop; did the original have six `if's (Rev 8.89 is
   not known to unroll loops)?  cc_change's second parameter (fn_ccset,
   passed by deltest and not read) is added to its heading.
138. final: the module data's words at +0x2C8 (1, 2, 4, .. 128) and
   +0x2D8 (358..363) and the longwords +12 and +0x84 have no user in
   final.pas; another unit's absolute references (or a slip) not
   found.  They are not declared (the layout is dpc's in any case).
139. final: peepholer_ops was a module-level extern stand-in (GG); it is
   now nested in peepholer as in the image.  Its first pass keeps the
   same cell when try_reducing_fabs_op succeeds (`bpl' to the loop's
   test with A2 unchanged): the cell, now the pattern's operation, is
   visited again under its new kind.

140. Translator KK: opt_inline.pas uses a call graph edge's +12
   (runbackend.pas's rb_edge_t ref_stmt, "module +0x4") as a block:
   put_on_bct adds variables to its +16/+20 list, find_varn searches
   it and process_blocks links the copied blocks after it and moves
   levels from its +294.  opt_inline names the field scope; is
   runbackend's module +0x4 the current block rather than a
   statement?
141. Translator KK: opt_inline.pas, probable slips of the original
   kept: allocate_local_var passes strtk the length 66 for 'Bad rlen
   encountered in \\opt_inline\allocate_local_var' (55 characters);
   ptr_variable's identifier node for a language 1 name is 29 bytes
   from gspace, room for 11 characters, while assign_name writes
   '<OI$nnnnn$' plus the name plus '>'; process_display_ptrs sets its
   cursor to the new pointer's successor (`prev := v^.next') after
   inserting it; call_status has a `btst #3' of the callee's +374
   whose result no instruction reads (0x0935AE).  get_size_rlen's
   and callee_status's comparisons of a word count with 65535 (`cmpi.w
   #-1; bhi') can never hold.
142. Translator KK: opt_inline's module data has an initialized table
   of the bytes of each register class at +0x5ED8 ([0..12]: 0, 1, 2, 0,
   4, 4, 4, 8, 8, 0, 0, 0, 16) like delay.pas's class_size; and the
   names' serial at +0x5EF4 is a longword whose low word assign_name
   reads (+0x5EF6, an integer32 assigned to an integer).

143. Translator LL, loc_build.c: the C unit's six headers (loc.h,
   loc_private.h, the derived loc_codes.h and loc_sets.h, loc_build.h,
   loc_pack.h) are not in the tree; loc_private.h (the holder and the
   30-byte node, as one union) and loc_build.h (the prototypes) are
   written from the code, the other four are stubs with a TODO, and the
   location codes appear in loc_build.c as numbers.  The families are
   written as unsigned char arrays of the bytes .rwdi records, because
   the one at A5+80 has room for at most 4 bytes; was there a family
   structure (and the +80 object something else)?
144. Translator LL, loc_build.c: kept slips of the image: close_pool
   scraps each range's successor rather than the range (and reads the
   scrapped node's link; cc never calls close_pool); stmt_range with
   line1 > line2 makes the range (start, start) where an exchange
   seems meant; dump_pool's total adds the piece's count after the
   write loop has brought it to 0 (it always returns 0 on success);
   loc_holder_alloc allocates one byte short for the NUL of a 13- or
   37-byte holder, and loc_holder_dispose files a 14-byte holder on
   the small list.  Were these in the original source?
145. Translator LL, const_op.ftn: r8_math's operations 9, 11 and 12 are
   the FPP emulator's words 0x0158 (one operand), 0x0180 and 0x0178
   (two), written LOG10, SIGN and MOD (kfold.pas's builtins 12 and 13
   use the last two and fold them as sign transfer and a truncating
   remainder); operation 10 (0x0154 0x0068, a round to a longword, then
   the longword loaded) is written IDNINT.  r8i4_expon pushes the low
   word of its INTEGER*4 exponent for 0x0138 (a power by an
   integer*2): written A ** INT2(E).  Confirm from an FPP operation
   list if one turns up.
146. Translator LL, empty.pas: the unit has no routines, no data and no
   insert in either binary (its .blocks record is the module block
   alone); its recorded code start lies inside other code (cc.m68k
   cg_top's return_proc; cc.a88k the ISC routines without records), so
   the survey's 4396 and 293168 bytes are spans to the next unit, not
   its contents (the a88k span is not the ISC tables: those are the
   named sections operand_string .. zzzzz_readonly_tables and the ISC
   units' data).  Written as `module empty;' alone.  The ISC code
   without records remains open item 1 of docs/survey.md.
147. Translator LL, std_lib.pas: the derived unit's two sections are
   decoded: libdsc holds 176 LIB_DSC descriptors (kind 159; register
   bits, argument sizes, the name: m$mis$llw .. monexit, the table in
   std_lib.pas's header), and std_lib's longword k points at
   descriptor k (so std_lib_rtns[17] is pas_$nlg2, [18] and [21]
   fpp_$, [19] fpp_$eslv, [20] fpp_$esla, [22] fpp_$eslc: question
   75's cg_fp elements).  std_lib.pas writes libdsc's bytes as one
   word array (std_lib_dsc, a name of ours); the std_lib pointers are
   not initialized because the prelude's globals_from_backend.ins.pas
   declares the section (std_lib_rtns) without initializers, and
   std_lib.pas opens the prelude.  Should the section's declaration
   move out of the prelude into std_lib.pas (one variable per routine,
   named after it, initialized with addr() of its descriptor), the
   other units declaring what they use?  The .blocks record also names
   `stdlib_dummy', not a routine: what was it?
148. Translator LL, opinfo.pas: the unit's .blocks record names its
   public tables: insind (0x2CE8D8, the generic operations' lists),
   cc_table (0x2CF4D8), class_table (0x2CF5EC), optohex (0x2CF9E2),
   oprw_table (0x2CFDD8), opcontext (0x2D01CE) and opname (0x2D05C4);
   the users declare them extern under other names (emit.pas
   opinfo_insts; final.pas opinfo_cc, opinfo_cc_class, opinfo_access,
   opinfo_size; banshee.pas opinfo_sizes; instr_reorder.pas's access
   table; outbin.pas opinfo_opword, opinfo_names) and with bounds
   [0..367] where the tables run to 506.  Rename the users' externs to
   the original names and bounds at the merge (left alone here: final
   is still being finished)?  opinfo.pas declares the lists
   (ins_lists, our name) before insind because insind's initializer
   names them; the image has insind first and the lists in reverse
   order of their operations.

   Resolved (translator OO): every absolute reference into
   0x2CE8D8..0x2D1797 (tools/cc_globals.py --refs) is to a table's
   first byte, and the readers map one to one: insind is emit's
   opinfo_insts (fnl_slct); cc_table final's opinfo_cc and class_table
   its opinfo_cc_class (cc_change, pcondjmp, puncondjmp,
   assert_n_bit_is_modified, deltest); optohex outbin's opinfo_opword
   (genfpinst, assemble, wr_instr); oprw_table final's and
   instr_reorder's opinfo_access (reg_mod, deltest, store_to_memory);
   opcontext final's opinfo_size and banshee's opinfo_sizes
   (final_$sizeof, fpx_instruction, deltest, opttest, dobansheefpx);
   opname outbin's opinfo_names (dbcod, wr_instr).  No other unit
   reaches them.  The single declaration is in
   lang/lang/source/final.ins.pas (the original names, bounds 0..506
   and 0..77, the entry type opinfo_entry_t and opinfo_list_ptr_t moved
   there from emit's em_entry_t), as other shared cells are declared
   in an insert and defined by their owner (g_opt.ins.pas and
   opt_main, cg.ins.pas and cg_tree): final.ins.pas is the last insert
   opinfo opens and every reader opens it (codegen.ins.pas would do as
   well; which one the original used is not known).  opinfo.pas now
   defines them by the define statement with their initializers (the
   reference's method 2) in address order, after ins_lists (still an
   own variable, so still first in dpc's layout); the users' externs
   are gone and the users renamed.  dpc's module data is unchanged,
   byte for byte (transLL's cmp_opinfo.py), and the seven tables are
   now global symbols of dpc's object: LL's form (`define' naming
   variables then declared without `extern') made them local to the
   module in dpc's output.  The readers' code is unchanged but for
   the symbols and two places in wr_instr, where optohex's 0..16#FFFF
   is now zero-extended before the add (`clr.l; move.w'), as the image
   does (outbin's integer had sign-extended).
149. Translator NN: opt_inline.pas process_operand and its nested
   routines, oddities of the image kept: (a) the call record's +0
   (oi_call_t.blk, dfs_walk's frame -16) is never set before
   process_statements; process_operand sets it at a 148 and reads it
   at a 149 and in get_sym_ind_info (find_varn), so it relies on the
   callee's first statement being a 148; (b) an evaluation (139) of
   no operands is allocated 92 bytes but 52 are moved (0x0925CA);
   (c) a displacement (147) merges a chain of displacements into the
   callee's own node before copying it (0x092A94), changing the
   callee; (d) process_opr_ind tests the class of the symbolic
   displacement's variable against 2 and 5 (`btst' of #36, 0x092004,
   0x092096), where allocate_space's classes are 1, 2, 6 and 7 and
   process_index_opr tests 1/7 and 2/6: is 5 a slip for 6?  (e)
   process_opr_ind stores its displacement to a frame longword it
   never reads (0x091EDC, 0x091F6A).
150. Translator OO, c_macro_read.pas (the hexindex audit,
   docs/audit-hexindex.md): get_par_cooked_line's #undef diagnostic
   (`Text follows the valid #undef of ' name `", it has been
   ignored.'') is 33 + n + 23 = n + 56 characters, but the image sets
   its length to n + 51 (cc.m68k 0x057D62 `addi.w #51,D2'), so the last
   five characters (`ored.') are not shown; the #define one's n + 55 is
   exact.  Kept as the image has it (a slip of the original?).
151. Translator MM, the PRISM back end's core: **the generated ISC
   (moon_unit/.../iscg_input/*: isc_pass_1_main, isc_pass_2_main,
   isc_vars, isc_pattern_matcher, isc_debug, isc_main; about 1.05 MB of
   cc.a88k's 1.17 MB of a88k-only code).  Hand translation or tables /
   generator input?**  What the image shows: the units are DSEE
   derived objects of an ISC generator's input (iscg_input); 0xF0B02..
   0x18C588 and 0x18C7A0..0x20042C hold about 1080 routines that no
   .blocks record names (isc_pass_2_main has one named routine of 536
   bytes in a span of 474,788; isc_vars none in 277,188, its "code
   start" falling inside that code); they are tiny pattern actions,
   many byte-identical (e.g. 0x18C7C4, 0x18C7F0: `link; lea
   0x480058,A5; (8..16,A6); move.l (116,A1),(4,A0); move.l
   0x48111C,(8,A0); clr.l (A0)'), with string constants like "ERROR:
   unknown evaluation order"; isc_pattern_matcher (32 KB) and isc_debug
   (92 KB) are each one generated routine; the generator's
   tables are the sections isc_tool_generated_readonly_tables
   (0x2BC13C) and isc_readonly_tables (0x2BCDFC); the opcode, solution
   (SOLUTION$...) and IL kind enumerations appear as Pascal identifier
   tables (tools/cc_enumnames.py).  My assessment: not sensibly
   hand-translatable routine by routine (no names, ~1000 near-duplicate
   bodies whose identity is the pattern they implement); the faithful
   reconstruction is the generator's input (the pattern description,
   recovered from the action bodies and the matcher's tables) plus, if
   wanted, a small generator that emits Pascal of the image's shape, or
   at least the actions as data tables.  The hand-written ISC units
   (lang2/source/isc: isc_to_lir, isc_user_routines, isc_cse_handling,
   isc_call_handling, rewrite) are ordinary translations.  Which do you
   want: (a) hand translation, routine by routine, named by address;
   (b) a reconstructed pattern description and generator; (c) the
   generated units left as data (not translated)?  Not decided here.
   **Decided by the owner (2026-11-11): (b).**  "We don't want 1080
   unnamed near-duplicate routines; this is classic codegen."  The
   generated units are reconstructed as the ISC generator's input (the
   pattern description, recovered from the action bodies and the
   matcher's tables) plus a generator (tools/) that emits Pascal of the
   image's shape, checked against cc.a88k by the gate; no routine-by-
   routine hand translation of the unnamed actions.  Named routines
   that are ordinary code (isc_main, the named routine of
   isc_pass_2_main, any others with .blocks records) and the
   hand-written lang2/source/isc units are translated as usual.
152. Translator MM: the opcode enumeration's type name is not in the
   image (OPC$ is its elements' prefix): opcode_enumeration.ins.pas
   calls it opc$t (after the ISC's ARITH$T_MAX, a `<prefix>$t' usage);
   the back end's other enumerations follow the same pattern with the
   prefixes of their string tables (operand$t, of$t, am$t, lsq$t,
   block$t, rrp$t) though the generator stripped the prefixes there (of
   "0_mod_2_s_immed16" proves one existed).  arg_loc_t is the ISC
   routine arg_loc_t_to_string's.  Rename if you know Apollo's
   conventions.
153. Translator MM: backend.ins.pas's records (instr_t, opnd_t, bb_t,
   lr_t, lts_t, rtn_t, cell_t) are read from the leaf units and the
   allocators (lir_$opt_new_instruction, zzzzz); most fields are named
   by offset.  Two readings to confirm when lir and utils are
   translated: an operand's +1 is taken as rrp$set_t's low byte (xtp
   copies its bits 3..2 into a segment's rrp and sets 0x30 = read and
   intend_to_modify, matching dpc's set layout for the masks the image
   uses), and the instruction's +0 bit 4 as "sets the condition codes"
   (xtp puts an IPCCNOP after such an instruction; zzzzz lists one whose
   result is register 31 as a TST/CMP).  zzzzz compares an operand's
   +0 (otherwise its number k) with 31: register operands may hold the
   register there after allocation.
154. Translator MM: utils.ins.pas holds utils_ins_$operands_instruction's
   body (19 units have a copy at their start; those that open the insert
   without calling it have none, sem_utils computes the same address
   inline).  dpc keeps the unused internal copy (dfa, sem_utils), which
   the gate shows as an extra routine.  Was it a Rev 8.89 dead-routine
   elimination, or an `%if' in the insert?
155. Translator MM: contiguous_high_order_zero_bits (sem_utils 0x27A420)
   counts the leading one bits and contiguous_high_order_one_bits
   (0x27A44E) the leading zero bits (each stops at the first bit of the
   other value); the names are kept, the behaviour is the image's.
   number_of_relevant_low_order_bits uses ..._zero_bits for AND masks
   and ..._one_bits for OR/BIC: consistent with "how many high bits the
   mask clears/sets".
156. Translator MM: basic_block_label (zzzzz 0x2880E8) reads the old
   first instruction's +28 even when the block is empty (nil^ in the
   image); kept.
157. Translator PC, tr_utils: three bug_check messages have characters
   missing from their middle in the image: 'TR_UTILS_$relative_instr_
   positnstrs not in same bb%$' (0x27C5DA; "position: i" expected),
   'TR_UTILS_$separate_partis: LTS was aon exit%$' (0x27CB60) and
   'TR_UTILS_$move_add_to_nebb: prev_instr not in new_bb%$' (0x2803AC).
   The translation keeps the image's bytes.  Typos in the source, or a
   compiler or editor artifact (a line break inside a literal)?
158. Translator PC, tr_utils: copy$complex_complex is jumped over
   entirely (docs/rev889-patterns.md 101), so a copy between two
   complex live ranges is never eliminated.  Written as `return' first;
   was it an `%if' or a disabled transformation in the source?
159. Translator PC: an operand's +1 byte is stored and masked whole by
   the optimizer (8 write, 16 read, `and.b #0xD3'; find_operand_of_kind
   ands it with a mask parameter), which suggests a set field (`set of
   rrp$fp_reg_even_only..rrp$spare_1') in the original operand record
   rather than MM's eight booleans; backend.ins.pas now has
   opnd_bytes_t, a view of the first longword as four bytes, for those
   stores.  Re-lay opnd_hdr_t's +1 as a set?
160. Translator PC: the operands' roles as the optimizer uses them: a
   MOVE's operand 1 is its source and operand 2 its destination; an ADD
   or SUB's operand 1 the immediate (or a register), 2 the source, 3
   the result; condition codes the last operand.  backend.ins.pas
   documents none of this yet (to confirm against lir when translated).
161. Translator PB, lst.pas: the named sections' initializers.  lst
   includes the generated instr_mnemonic.init and
   instr_mnemonic_length.init (and asm instr_assembly.init, lir
   instr_attributes.init), but backend.ins.pas declares the sections'
   variables (`var (instruction_mnemonic) instruction_mnemonic: ...')
   for every unit, and dpc refuses a second declaration with the
   initializer.  The .init files hold a TODO; the data are recoverable
   (the opcode enumeration's identifiers, the sections' bytes).  How
   should the sections be shared: (a) the .init files declare the
   initialized variables and backend.ins.pas's declarations move behind
   an `%if' the including units set, (b) backend.ins.pas declares them
   `extern' and the including units `define' them with the
   initializers (if dpc accepts an initializer on a defined variable),
   or (c) leave them uninitialized in the translation?
   **Settled by translator PB2 (asm.pas):** (b) without the extern:
   backend.ins.pas keeps its declarations; each .init file holds a
   `define <section> := [...]' statement (the reference's section
   7.2.2, method 2, which it recommends for %include files), which
   dpc accepts after the var declaration.  instr_assembly.init,
   operand_string*.init (asm) and instr_mnemonic*.init (lst) are
   filled from the sections' bytes.  dpc does not yet lay out such an
   initialized section whose variable has the section's name
   (docs/dpc-gaps.md 32): the gate renames the sections.
   **Translator PA3:** the amse_ sections (amse_premod_immed_low/_high,
   amse_postmod_immed_low/_high, 8 longwords each), which sanity reads,
   are now declared in backend.ins.pas with the others, for tm_utils'
   amse_*.init to `define' (PB2's scheme; tm_utils not reached).
162. Translator PB, lst.pas: the -PRASM listing writes the integer
   registers as ".n" (`move.w #0x2E00' before the number), the singles
   ".FSn", the doubles ".FDn", and register 30 of kind ip_reg_like as
   ".PC" (classic "PC"); taken from the image as they are, though
   ".n" for a register looks odd (the PRISM assembler's syntax is not
   known here).
163. Translator PB, bin.pas: bin opens bug_check.ins.pas after
   coff_dst.ins.pas (its .blocks list), but backend.ins.pas, opened
   earlier, declares instr_bug_check and the phase_ routines with
   bug_check.ins.pas's types (bug_check_$string_t, bug_check_$arg_t), so
   dpc cannot compile the unit in that order; bin.pas opens bug_check
   before at_base.ins.pas.  Apollo's backend.ins.pas must have declared
   those headings without bug_check's types (or bin did not see them):
   should backend.ins.pas's three headings use types of their own
   (univ base types) so that the include order can be the image's?
164. Translator PA, utils.pas: look_for_path (cc.a88k 0x286564) answers
   from target_bb's mark146 (`movea.l (44,A5),A0; move.l (146,A0),D0;
   cmp.l (56,A5),D0'), not from the block it is asked about, though
   it marks the blocks it visits; it looks like a slip in the
   original (the memo never hits), kept as the image has it.
165. Translator PA, utils.pas: utils_$put_lts_on_final_list sets the
   segment's first_in_bb (+3 bit 6) with final (`or.w #0x50,(2,A2)'),
   while utils_$get_new_lts and utils_$excise_lts_cleanly keep bit 6
   as "the live range's first segment in its block" (complex live
   ranges only).  The name first_in_bb may be wrong; kept by offset
   otherwise.
166. Translator PA, backend.ins.pas: an lts's +4 (MM's def) is the
   head of the operands that refer to the segment (the definition
   first, then the readers, chained through the operands' link):
   renamed refs, and xtp's uses follow.  Its +44 holds either the
   final segment that reaches an exposed segment or (for a join
   birthpoint's segment) the list of the join's inputs; it is a
   univ_ptr, cast where used.
167. Translator PA: call_conv.pas (batch A's third unit) was skipped for
   utils.pas, whose 40 cross-unit headings batches B and C call;
   at_call_conv (0x1B3C bytes) needs the conventions record and the
   IL type nodes' layouts.  It remains, with lir_utils and the rest of
   batch A.
168. Translator PC2: **question 157 is answered: not the source's.**  The
   three tr_utils messages are whole in the image ('TR_UTILS_$relative_
   instr_position: instrs not in same bb%$', 'TR_UTILS_$separate_
   partitions: LTS was active on exit%$', 'TR_UTILS_$move_add_to_new_bb:
   prev_instr not in new_bb%$'); the missing characters were the
   extension words objdump prints on a line of their own when it decodes
   constant bytes as a long instruction, which the scratch helper that
   compacted the disassembly dropped.  tr_utils.pas now has the image's
   text; every '...%$' literal under lang2/source/be_com was checked
   against the binary's bytes.  (Worth a check elsewhere: any translator
   who read constants from a compacted disassembly.)
169. Translator PC2, mmt_utils and mmt: the memory model keeps its
   own data in fields other phases use for something else or batch A
   has not named: a live range's +8 (a byte: kind 28 made 27), +44 (the
   memory operands referring to it), +52 (its token, or the segment
   being filled in); a segment's +40 (its last reader, lts_t.l40); the
   routine's +140, +144 (the memory live ranges) and +227 bits 6, 0; an
   instruction's +16 (its descriptor, instr_t.l16).  mmt.pvt.pas reads
   them through unit-local views (mmt_lr_v_t, mmt_rtn_v_t) rather than
   naming them in backend.ins.pas: for batch A to name.
   **Translator PA3:** named rtn +148 (ip_clobbered), +152 (fp_clobbered,
   two longwords) and the memory properties at +227 bits 4..0 and +228
   bits 7..5 (no_reads, no_writes, no_reads_16, no_writes_16,
   no_class_1, no_static, own_only, no_dynamic: call_conv copies them
   from a callee's rtn_t, its block's +124, into a later call's
   conventions; mmt.pas follows).  rtn +80, +140, +144 were PA2's (bb80,
   lr140, memory_lr).  lr +8, +44, +52 and rtn +227 bit 6 are still
   unnamed: none of PA3's units reads them.
170. Translator PC2, mmt: dump_related_vectors prints an alias class's
   name from alias.pas's table (its data +0, A5 0x2E8DFC: `class_names',
   a module variable alias.pas declares without `define'); dmp reads it
   too.  mmt.pas declares `class_names: extern' locally.  For a link
   alias.pas would need `define class_names' (or the table moved to
   alias.ins.pas as an extern with a name of its own): which?  mmt's
   data also holds 'touched  '/'untouched' (+456, 2 x 9 characters)
   that no instruction reads (as add_node's +0x28, pattern 66), kept as
   an initialized module array.
171. Translator PC2, mmt: a call instruction carries a pointer after its
   operand slots (+56 + 12 nopnds) to the call's properties, whose bytes
   +31, +33..+40 the memory model tests (asynchronous, no reads, no
   writes, class 16, only what is passed, class 1, static, dynamic
   classes); mmt.pas reads them through a view (mmt_call_info_t) until
   call_conv.ins.pas declares the record.

   **Translator PA3:** call_conv.ins.pas now declares the record
   (call_conv_$t, with the memory model's names for +31, +33..+40) and
   its argument descriptors (call_conv_$arg_t, 26 bytes from +80);
   mmt.pas still reads it through mmt_call_info_t (batch C may switch).
172. Translator PA2, backend.ins.pas rtn_t +112: zzzzz compares a
   returning jump's operand 1 segment with it (`cmpa.l (112,A0),A2'
   with the operand's +8), but df_utils and life pass it to
   bv_$make_live_range_complex and compare live ranges with it, as
   with the routine's +100 (the argument pointer's live range, fga's
   messages), +108, +140 and +144 (the memory live range).  Kept as
   l112: lts_ptr_t (cast to lr_ptr_t in df_utils and life) so zzzzz is
   unchanged.  Is it a live range (the return address's, most likely),
   and zzzzz's comparison a slip of the original or a reading of
   operand +8 after register allocation?
173. Translator PA2, fga.pas: conditionally_asynchronous tries the
   identifier SETJMP (upper case) unless cargs +0x288 bit 3 is set
   (cargs.ins.pas: flags_286's element 0, -MGBL by perfsummary's
   printout).  An upper-case setjmp seems tied to case folding rather
   than to -MGBL; is flags_286's element 0 named right?
174. Translator PA2: fga, hal, life, sanity, sym and tm_utils open
   backend.ins.pas without the lang prelude (their .blocks include
   lists), yet fga reads il.pas's +0x180 and cargs' options and calls
   idntk, and backend.ins.pas used il_$node_ptr_t (now univ_ptr).  fga
   declares the three through views of its own (il_180: extern
   fga_node_ptr_t, cargs_$options: extern array of char, idntk with a
   univ string).  Apollo's units must have seen them through an insert
   they open (be_prism/target.ins.pas or at_base.ins.pas, both stubs
   here) or through declarations in the unit; should a small insert of
   the prelude's cells for the back end be made instead?
   **Answered by translator PA3: the premise is wrong.**  The .blocks
   include lists of fga, hal, life, sanity, sym and tm_utils (and every
   other unit that opens backend.ins.pas) have lang/lang/source/
   globals.ins.pas and its members after bug_check.ins.pas
   (docs/routines-cc.a88k.md); the translated files had left it out.
   fga, hal, life and sanity now open the prelude in the image's order,
   and fga's views (il_180, cargs_$options as bytes, idntk's heading)
   are gone.  No new insert is needed; rtn_t.node could be narrowed to
   il_$node_ptr_t (kept univ_ptr).
175. Translator PA2, fga_$process_routine: the instructions chained
   from lir_main_c44 at their +32 are unchained (+32 cleared) but
   lir_main_c44 itself is left pointing to the first; df_utils's async
   walk (do_global_walk) clears it.  Kept as the image has it; a slip?
176. Translator PA2, backend.ins.pas bb_t +110: batch A named it
   transparent (bv: all ones initially, "not written in the block"),
   batch C written; df_utils's process_marked_instructions sets a live
   range's bit there for each write it reaches (bv_$set), which fits
   batch C's reading for the dfa vectors (bv_$create_dfa_bit_vectors)
   and batch A's for the availability ones.  The field keeps its name;
   the two vector sets may lay out +86..+130 differently.
177. Translator PB2, asm.pas: asm_658 (asm +0x658, set by lir and
   ra_utils) is compared with the value (+8) of the operand after a
   displacement operand: equal, the displacement is a stack-frame
   access (bounds-checked against the register save area or the
   argument block, the access size added) and an arg-block/frame/
   literal-pool displacement's register byte gets bit 7.  It looks
   like the frame base register's segment or live range; batch A
   (lir) should name it.
178. Translator PB2, asm.pas: in asm an instruction's +28 is its
   location (bump_locations adds to it, build_dispatch_table and the
   branch displacements subtract them, the code base's +56 is set
   from it), while backend.ins.pas calls +28 a source position zzzzz
   copies to a cell's +8 (which bin indeed reads as the location).
   The reading "location" fits both; batch A owns instr_t's l28.
179. Translator PB2, asm.pas: the pipeline's state table (asm +0x470:
   8 states x 10 instruction kinds, flags and next state) is kept as
   numbers; the states' and kinds' meanings (which PRISM pipeline
   hazards they model: the delay slot of squashing calls, the
   floating unit's two-word instructions) are read only from what
   pass 1 does with the flags.  Names, if the owner knows the DN10000
   pipeline rules.
180. Translator PB2, asm.pas: three traces are wrong in the image and
   kept: add_literal_to_literal_pool prints the literal's kind with
   %6ld (the kind and length words as one longword), dump_literal_pool's
   this_bb line has five arguments for six conversions, bump_locations
   reads the end block's number when it is nil (process_routine's
   calls).  Slips of the original?

181. Translator PB3, dmp.pas: dmp reaches mrh.pas's heap_names, heaps
   and heap_count (mrh's data +0x4000, +0x4400, +0x481C: 0x2EDFB8,
   0x2EE3B8, 0x2EE7D4) absolutely, as mmt and dmp reach alias.pas's
   class_names (question 170).  dmp.pas declares them `extern' with
   mrh.pas's names; mrh.pas declares them as plain module variables.
   For a link mrh.pas would `define' them (and mrh.ins.pas declare
   them extern): which?
182. Translator PB3, dmp.pas: dmp_$get_line_number and dmp_$instruction
   read one parameter (fp+8), while the frames the headings were read
   from suggested two and three (fg_utils', lir's pushes).  The headings
   are narrowed to the one parameter; whoever translates fg_utils and
   lir should check their calls (an argument pushed for nothing, or a
   different routine).
183. Translator PB3, dmp.pas: two slips kept as the image has them:
   dmp_$instr_print_single_line's "Bad operand numbers" passes the
   operand's number zero-extended to a longword for `%WD' (vfmt reads
   the high word: 0); display_ra_info never reaches its displacement
   loop and "PREFERENCED SET" (pattern 120).  Slips of the original?
184. Translator PB3, dmp.pas: the IL node kinds' enumeration (an_kind_t,
   237 names) is written by dmp_$instruction as add_node.pas writes it;
   both units declare it locally (dmp.pas copies add_node.pas's
   declaration).  Should it move to il.ins.pas (or an insert of its
   own)?
   **Done (translator RN1):** il.ins.pas's il_$kind_t (question 78).
185. Translator PA3, call_conv: pfm_cleanup_check answers true for a name
   that is not 'PFM_$CLEANUP' when cargs flags_286's element 0 is set
   (`st D0' before the flag's test, 0x0B42F2); the lower-case name is
   compared only without it.  A slip (the result meant false there)?
   Kept as the image has it.
186. Translator PA3, call_conv: at_call_conv reads a local it never sets
   (-396) as the result's symbol and node when a routine's parameters
   are a prototype's entries (kind 168) and its result is a string
   (rlen 9), and reads the prototype pointer (-392) uninitialized when
   only the preset's flag 6 asks for placement by prototype; strtk is
   given 31 and 42 for 'call_conv cannot handle call' (28 characters)
   and 'unrecognized argument kind in call_conv' (39).  Kept (unset396,
   pt); slips of the original?
187. Translator PA3, sanity: sanity_$check_entire_routine's messages read
   "[%M12A]_$CHECK_ENTIRE_ROUTINE: ..." (no "\SANITY"), but the four
   fp_reg_pair messages "[%M12A]\SANITY_$CHECK_ENTIRE_ROUTINE"; one has
   "wrtie".  Taken from the bytes.  The literal pool check prints an
   operand's .bytes as a signed 3-bit field (`asr.b #5') after testing
   it unsigned.
188. Translator PA3: at_backend_4fc (at_backend +0x4FC) is described as
   get_calling_conventions' record, but lir_utils_$flesh_out_new_load_
   or_store sets its +226 bit 1 (rtn_t.f226.b226_1) and utils reads
   its +108 and +116 as live ranges (rtn_t's lr108 and +116): it looks
   like the routine being compiled (rtn_ptr_t).  To settle when
   at_backend is translated; backend.ins.pas keeps univ_ptr.
189. Translator PA3, call_conv: names by offset only for most of
   call_conv_$t (w12..w24, b27..b30, b41, b42) and the presets
   (preset_0 .. preset_3: the C conventions under flags_286 element 15,
   the ordinary ones, ftn_$stop's, the run-time library's).  The
   registers w14 (22) and reg40 (26, 23) look like the static link and
   the return address; ip76 the registers a call reads.  Names if the
   PRISM calling standard is known.
190. Translator PC4, com.pas: excise_a_store (cc.a88k 0x2297D2) gives
   the readers of the memory segment a store writes to that segment's
   +8 (the next segment on its live range's list: `movea.l (8,A1),A3;
   movea.l (8,A3),A2'), not to the segment the store's read memory
   operand (the operand before it, whose link it rewires) holds;
   replace_mem_instrs, doing the same job, uses the read operand's
   segment.  The two agree only if a live range's list puts the read
   segment right after the written one.  Kept as the image has it;
   is lts_t +8 here the segment before it in the block (a list kept
   newest first), or a slip?
191. Translator PC4, com.pas: build_loads's MMT_SEQs (0x226E62) cut a
   long list of memory live ranges at 255 operands and resume the next
   MMT_SEQ at the chunk index after the last one taken, but that index
   is not reset to 1 when the walk moves to the next chunk of the list
   (com_lrs_t, 126 live ranges each), so after a cut the following
   chunks start mid-way.  Kept; a slip of the original?
192. Translator PC4, com.pas: destroy_instr (0x22AFF0) clears modify
   and intend_to_modify from a live range (`andi.w #-37' through
   (-20,A6)) whenever no segment modifies it, but the slot is set only
   when the live range has exactly one writer (`move.l
   (48,A2),(-20,A6)' on that path); on the other path it holds the
   value of an earlier operand's iteration or nothing.  Translated
   with the variable assigned on that path only.  A slip of the
   original?

193. Translator PB4, dbg_life.pas: dbg_life_$find_symbols' test of
   whether the call before an instruction clobbered a floating register
   reads register r above 31 in the call's set of 0..31 (+48 after the
   operands: never true) and r up to 31 in the set of 32..63 (+44),
   while dbg_life_$initialize and find_symbols' own closing loops use
   +48 for 0..31 and +44 for 32..63; and find_symbols tests for a call
   inside its loop over the operands (an instruction without operands
   is never taken for a call), where initialize tests after it.  Both
   kept as the image has them.  Slips of the original?
194. Translator PB4, dbg_life.pas: fields batch A owns that the phase
   uses, read through views (for the owner to name): lr_t +8 a byte,
   the operand kind of the live range's register (set on the live
   ranges map_physical_to_virtual_lr makes; mmt's "kind 28 made 27"
   is the same byte), +44 and +48 the first and the current of its pc
   ranges, +72 their count (lr_t's l44, l48, exposed); rtn_t +16 the
   routine's calling conventions (nargs at +22, 26-byte argument
   records from +60 + 26: sym +6, arg_loc_t byte +12, register +17,
   a flag +18; the routine's IL node's +128 has the same record), +116
   the stack frame's live range (compared with a load's or store's
   base operand), +208 the stack frame's register.  The IL nodes:
   VAR_NAME +28 (the variable a spill slot was made for), +32 flags
   (bit 29 a spill slot, bit 14 not for the debugger), +56 offset, +60
   the block last written in (dbg_life's), +64 spill records, +68
   debug records, +72 storage class, +74 spill slot number; FORTRAN
   symbol (110) +11 bits 7..4 storage class, +12 offset, +16 slot,
   +24 flags, +36, +50, +54 as +60, +64, +68.  Where should the debug
   records' type (dbg_life's dbg_rec_t, read by whoever writes the
   .dst: bin or debug_sym_dmp) live?
195. Translator PB4, dbg_life.pas: map_physical_to_virtual_lr loads A5
   (a global routine, its parameters by address: no val_param) while
   every other routine of the unit but the two entry points is
   internal; nothing outside the unit calls it.  Was it declared in an
   insert (dbg_life's own, lost), or simply left global?
196. Translator PB4, sched_utils.pas: the snuggle checks' messages
   name COM_$PRESCAN_INST, and the operand delays' word parameter has
   two flags (element 0: a condition code read costs a cycle more;
   element 1: delays taken from the definition to its reader rather
   than from the reader back) whose names are not known:
   sched_utils_$flags_t = set of 0..15 in backend.ins.pas.  sched's
   pass 1 passes [1] and the switches' sw9, oli [0] and false (one
   longword, 0x10000).  Rename if the original's names are known.
197. Translator PA4, lir_utils: lir_utils_$trans_insert_move's write
   path bug-checks "Multiple physical outputs" with the frame slot of
   the pair's move (-48) as the instruction (its +42 and its block's
   +10 printed), which that path never sets: kept (a local `mi' read
   uninitialized).  A slip of the original (op's instruction meant)?
198. Translator PA4: lir_$get_new_instruction_no_exceptions reads five
   frame longwords, but lir_utils pushes three or four
   (docs/rev889-patterns.md 132): was its heading `options(variable)'
   in the original, or were the callers compiled against an older
   heading?  The translation's heading has five parameters (node, opc,
   flags, home, p5) and the calls pass nil for the rest.
199. Translator PA4: the section spill_instr_forms (cc.a88k 0x513E30, 264
   bytes, initialized from .rwdi, read and written by lir_utils and
   ra_utils) is declared in lir.pvt.pas and defined with its data in
   lir_utils.pas; which unit held the initializer is not known (ra_utils
   could; nothing in the image decides).  Its pointers (load_ptrs,
   store_ptrs) are written addr(spill_instr_forms.loads[k]).
200. Translator PA4, lir_utils_$fix_store_through_lrs: an exposed segment
   of the memory (lir_3ba8) or the DB register found in a block is put
   at the head of its live range's list (`move.l head,(8,A1); move.l
   A1,(36,A4); addq.w #1,(56,A4)') without being unlinked from where it
   is, and its count bumped; a slip, or the lists were emptied just
   before (step 2 clears every live range's list, so a found segment is
   one this walk added)?  Kept.
201. Translator PA4, sym: sym_$allocate_static_variable places a variable
   at (next free + mask - 1) and not mask (`add.l (20,A2),D4; subq.l
   #1,D4; and.l' with the complement), so a 4-byte variable after an odd
   free byte overlaps its predecessor's last byte unless the routine
   block's +20 is "last used" rather than "next free"; kept.  And
   sym_$displacement's "unknown object type" message ends in '%.' (the
   bytes), unlike the others' '%$'.
202. Translator PA4: isc_$get_il_live_range's heading is in backend.ins.pas
   (sym calls it and opens no ISC insert; the original must have
   declared it in an insert sym opens, or in sym itself).  Whoever fills
   isc_lir.ins.pas must not declare it a second time.
203. Translator PC5, iv.pas: iv_utils_$live_range_from_elaborated_expression
   (cc.a88k 0x23B8EE) copies an operand child into the instruction's
   slot pos (iv_opnd_pos) but numbers it k, the child's index (`move.b
   D5,(32,A2)'), not pos: for an add or sub (children 1, 2 in slots 2,
   1) the copied operand's number names the other slot.
   create_operand_from_elaborated_expression keeps the slot's number.
   Kept as the image has it; a slip of the original?
204. Translator PC5, iv.pas: ixr_$find_current_lts_for_iv (0x23D39A), in a
   block with an exposed segment of the variable, returns the first of
   the variable's segments in the block whose definition precedes the
   operand, but when none does it returns the last one it examined
   (whose definition follows the operand) rather than failing; and
   ixt_$instantiate_induction_expr (0x23F054) passes
   lir_utils_$add_lts_after_lts the previous run's new segment, which
   is not set when the first run's segment is neither exposed nor
   final in a new block.  Both kept; slips of the original?
205. Translator PC5, iv.pas: instr_size.init (iv's data +0) and
   iv_opc_kind (+0x330) are declared for opc$undefined..opc$adj_move
   (212 entries), but the image's tables are 384 words each (+0 ..
   +0x300 and +0x330 .. +0x630; iv_opc_set sits between at +0x300),
   the words past 211 zero (no .rwdi record).  Should both be indexed
   0..383 (the opcode enumeration's range)?

206. Translator PB5, ra_utils_$add_spill_code: its two bug checks on a
   spill victim read the live range's +3 bit 5 as "spill victim is user
   declared register" and bit 6 as "no_modify register"; batch A named
   bit 5 serialize (dmp's SERIALIZE) and bit 6 no_modify.  Is SERIALIZE
   the mark of a register the user declared (a `register' variable the
   allocator must not spill)?
207. Translator PB5, ra_utils (slips kept as the image has them?):
   spill_the_victims passes the reloads' at_head as D2, the "any spilled"
   flag it has just set (always true there; written true);
   add_spill_code passes break_loops_from_spill_victim a trace flag from
   a local it never sets (-110: the splitting trace can never print);
   break_loops_from_spill_victim tests its second list twice;
   find_best_dom_bb's last test (the routine's start block) is reached
   only with no block; rematerialize_result leaves its copy unset after
   the "unexpected DP instruction" bug check, pick_instruction its result
   after the FP_REG_PAIR one, and the even/odd one tests whatever D0
   bug_check left (written false).
208. Translator PB5: backend.ins.pas's post_6b8 (PA4) is ra_utils' +0x10
   (0x48FB04 is in ra_utils' data, A5 0x48FAF4; post's A5 is 0x48F438,
   ra's 0x48F488; tools/cc_globals.py lists the cell under ra_utils):
   renamed ra_utils_10 and defined in ra_utils.pas.  lir_$begin_
   compilation clears 0x1B0 bytes there and at lir_main +0x250 and
   +0x400 (0x400 - 0x250 = 0x1B0; +0x760 is three such records on), so
   solution_t is 432 bytes, not 112: batch A should pad it.
209. Translator PB5, ra_utils' data: +0x204 holds three initialized
   characters, 'ISD', that no instruction reads (kept as ru_204), and
   +12 is not referenced.  A leftover initialized variable, as
   add_node's +0x28 (pattern 66)?
210. Translator PB5: during RA a live range's +72 is its first
   definition segment, the others chained at the segments' +36
   (ra_utils_$rematerialize, choose_spill_cost, break_loops_from_spill_
   victim), while batch A's lr_t calls +72 exposed (the exposed list,
   chained at +16, which ra_utils' rebuild_db_exposed_lts_list restores
   for the DB register before add_spill_code).  Likewise lr +28 is the
   spill cost (a single real), lr +60 the rematerializing instruction,
   an instruction's +29 and +31 the floating and integer registers live
   at it, a block's +2 and +6 the most of each live in it.  For batch A
   to name (ra_utils reads them through views).
211. Translator PB5: **question 188 is answered (read, not translated):**
   at_backend's get_calling_conventions (0x2222D6) allocates the record
   at +0x4FC from the routine heap (+1248) and fills it as an rtn_t (+0
   the IL node, +16 the conventions, +148 and +152 their integer and
   floating clobbers, +226 bit 1 needs_db); at_backend_4fc can be
   narrowed to rtn_ptr_t when at_backend is translated
   (docs/backend-plan.md has the phase table's layout).
212. Translator PC6, oli.pas: find_open_slot (cc.a88k 0x25A44A)'s last
   search for a truncdi (0x25AC12 .. 0x25AC3E) tests the cycle and wraps
   without stepping to the previous cycle (no `subq.l #1,D2' before
   `tst.l D2'), so after a full first cycle it gives up at once; every
   other search steps.  Kept; a statement lost from the original?
213. Translator PC6, oli.pas: data_flow_paths (0x259156) puts the paths
   found from a reader in front of those found so far by setting the
   first returned cell's link to them, then walks on through the old
   ones too when prefixing the writer's step, so earlier paths get the
   step again and paths from the same reader after the first are
   dropped.  Kept; a slip of the original (an append meant)?
214. Translator PC6, oli.pas: get_dp_zero (0x258184), when a 0.0 pair
   exists, copies it into a new pair and stores the new live range in
   the single-precision zero's cell (+0x2DC0), not the pair's; and
   is_5op_candidate's addd branch tests can_join twice with the same
   operands and keeps searching after a match.  Both kept; slips?
215. Translator PC6, oli.pas: swap_inputs (0x25A35E) exchanges an
   instruction's operands 1 and 2 without relinking their segments'
   operand chains (it relinks 4 and 5 for an addd).  Kept as the image
   has it; are the chains rebuilt later (generate_ltss), or a slip?
216. Translator PC6, oli.pas: build_bookkeeping_structures' and
   excess_register_pressure's table sizes use the counts' low words
   (pattern 140), and the cells +0x2DA4 .. +0x2E72 are named only where
   their use was read (oli_2e14 .. oli_2e20 count the floating
   instructions placed with and without a multiply partner; oli_2e24,
   oli_2e2c, oli_2e30 and oli_2e00 are set or compared in routines not
   translated yet).  Rename when the remaining routines are read.
217. Translator PA5, lir_main_$entry: after formal_local_transfer_setup's
   case 8 (a register formal moved into an integer register home of a
   pair's kind) the test of a by-value double's next slot reads
   `cmpi.b #4,(0x62,A1,D4.l)' with D4 still 26 times the formal's
   number (the index register of its descriptor), i.e. the next
   formal's loc (conv^.args[j + 1].f18.loc), not this one's.  Written
   so; a slip of the original (this formal's loc meant), or the next
   formal (the pair's other half) intended?
218. Translator PA5, formal_local_transfer_setup: for a memory formal
   without a home (results 0 and 1) the load/store opcode it returns
   (xfer +6) is the variable's size in bits, the register both live
   in (D1): written as one variable used for both.  And the
   bug_check message names LOCAL_FORMAL_TRANSFER_SETUP (the routine's
   .blocks name is formal_local_transfer_setup); entry's and
   build_initial_epilog's messages name LIR_MAIN_$BEGIN_ROUTINE and
   ...BUILD_INITIAL_EPILOG.  Taken from the bytes.
219. Translator PA5, lir_main: dpc gives each byte module variable two
   bytes (docs/dpc-gaps.md 37), so backend.ins.pas's booleans
   lir_main_c89 and lir_main_c8b..c8e cannot sit at their addresses
   (they are 0xC8A, 0xC8C..0xC92 in the translation; every other cell
   of the 0xDB8 bytes is at its address).  Fix in dpc, or declare the
   byte cells as one packed record (renaming their users)?
220. Translator PA5, lir_main_$save_and_restore_code: the singles'
   loop tests the register it computed (0/1 plus an even number)
   against -1 (`cmpi.l #-1,D5'), never true; and with no RETURN block
   the RETURN's block slot (-120) is read unset only by the code the
   no_return_block test skips.  Kept.
221. Translator PA5: instr_size.init (question 205) is not confirmed
   against lir's copy: lir was not reached.  lir's data (A5 0x487180)
   holds no run of instr_size's words at its start (its +0 .. +0x320
   are other tables), so lir's copy, if it has one, lies further in.
   **Answered by translator PA6 (questions 205 and 221): 384 entries.**
   lir's copy is the first table of the section lir_readonly_tables
   (0x2BDA2C; lir_$opt_new_instruction reads it for an instruction of
   default size): the same 212 words as iv's, then zero words to word
   383, the next table (solution_kind) at +0x300, as iv_opc_set follows
   iv's at +0x300.  instr_size.init now declares 0..383 (`172 of 0'
   after opc$adj_move) and holds the declaration only: iv.pas opens a
   plain `var' before including it, lir will open `var
   (lir_readonly_tables)'; iv's data now matches the image at +0x300
   (iv_opc_set) and after.  iv_opc_kind (iv +0x330) is likewise 384
   words in the image (question 205) but is iv.pas's own table, left
   at 212 (batch C's).


222. Translator PA5, fg_utils: reverse_depth_first_search (cc.a88k
   0x236390) remembers the previous edge only after recursing through
   it (`move.l A2,D0' after the call), not for an edge from a block
   already visited, so dropping a later edge from a block with l150 nil
   unlinks it from the wrong predecessor; reorder_start_bb_successor_
   list (0x2353D2), when no ENTRY outside an ENTRY statement is found,
   falls out of its loop into the append with A0 holding the last
   block or node it loaded (translated as moving nothing); and
   fg_utils_$recompute_ssa_form_for_lr returns with lir_main_c8d still
   set when excising the old join birthpoints leaves the live range no
   segments.  Slips of the original?  The first and third are kept as
   the image has them.
223. Translator PA5, fg_utils: traverse (0x236914) gives a live range a
   join birthpoint in bb when its reaching definition is bb itself
   (avail_out has its bit) or a block that does not pass it through and
   is not the first block; the first case reads oddly (a block that
   defines the live range gets a join for its live-in value).  Kept as
   the image has it.
224. Lead (2026-11-11), for the owner: **should dpc get a Rev 8.89
   module-data layout mode?**  The DOMAIN C 6.9 binaries were built
   with Pascal Rev 8.89, which packs byte-sized module variables one
   per byte (be_com lir_main's booleans at +0xC88, +0xC89,
   +0xC8B..+0xC8E, reached absolutely by other units).  dpc gives each
   a word, the SR10.2 kernel compiler's rule, which domain-pascal
   verified against the kernel image (343 module variables, none at an
   odd address), so its default cannot change.  A mode (e.g. selected
   by a flag or a `-config') would let these units' data lay out as
   the image's; without it the gate still passes, but the cells after
   such booleans sit at other offsets (docs/dpc-gaps.md 37).  This is
   the domain-pascal owner's call; recorded in its bead
   domain-pascal-338r.

225. Translator PC7, oli.pas: add_reduction_partial_sums (cc.a88k
   0x2603CE), with an odd number of iterations, carries the last
   partial sum as `sums[j * niters + n]' (`addl d4,d0', n the count of
   sums made so far) where every other read of the sums is `sums[j *
   niters + c]' (c the tail's column, d6).  Kept as the image has it;
   a slip of the original?
226. Translator PC7, oli.pas: increase_recurrence_precedence raises a
   violated recurrence's later instruction (+8, upto), but
   restore_precedence lowers its first one (+4, from) by the same count
   (`move.l (4,A2),-(SP)' at 0x261036), so the heights are not put back
   as they were.  Kept; a slip of the original?
227. Translator PC7, oli.pas: find_new_intend_to_modify_operand copies
   the alias descriptor in front of an instruction (+2 bit 7) as five
   longwords (20 bytes) into a 24-byte gap (`movel (a3)+,(a4)+' four
   times and `movel (a3),(a4)', then `lea (24,a2),a2'), and
   get_induction_variable_adjustment returns its result unset when the
   adjustment record has neither an add nor modified operands.  Both
   kept; slips?
228. Translator PC7, oli.pas: get_new_lr_pair's only caller (get_write_lr)
   passes an operand, and the routine tests +1 bit 1 of what it is
   given (an operand's fp_reg_odd_only, the same bit as a live range's
   rrp$fp_reg_odd_only): narrowed to `o: opnd_ptr_t' (PC6 had a live
   range).  oli_$compare_memory_references reads its parameters by
   value (it is called through mmt_compare_t) but was declared without
   options(val_param): added.  Confirm.
229. Translator PB6, ra: ra's +0x65C and ra_utils' +0x204 hold the same
   three initialized characters 'ISD', and only these two units open
   ra.pvt.pas: an initialized variable of that insert (the register
   classes' letters, which ra_$process_routine's failure message reads
   as A5 + 0x65B + class).  Both units declare it (ra_letters, ru_204);
   should ra.pvt.pas declare it instead (dpc gap 32's way, or a
   `define' in one unit)?
230. Translator PB6, ra (slips kept as the image has them?):
   ra_$remove_lr_from_graph's `if active > 1 then dec else if active >
   1 then ...' (the second arm, which would move a live range whose
   active aversions reach 0, is dead: pattern 150); the conflict heaps'
   names are in the reverse of their use (heap 0, "ra cc conflict
   heap", holds the simple x simple records; the A/P heaps' names
   match); the *UCAND* trace passes the address of the word +58 for a
   %4LD; ra_$spill_zero_cost_lrs returns false before its body
   (pattern 151); ra_$open_another_fp_register's pair search returns
   the odd register of the pair whose even half it opened.
231. Translator PB6, ra (for batch A): fields ra reads through views
   during RA, which batch A's records name otherwise: instr_t +2 bits
   3..0 the stall cycles SCHED left (instr_hdr_t names bit 3
   do_not_delete), +24 the next move on ra's preference lists, +28..+31
   the live counts (floating after, floating peak, integer after,
   integer peak); lr_t +3 bit 3 on the live list, bit 0 spill victim,
   +10 bit 6 protected (the pipe), bit 5 a collapse candidate, +28 the
   spill cost and +44 the reload cost (singles; +44 later the conflict
   list, its pointers tagged), +40 the block of a simple live range's
   index (+58: the complex serial number, or the simple index, or the
   active aversion count during the collapse), +48/+52 the live list's
   or pipe slot's links (+52 first the segment last seen), +56 the
   conflict count, +60 the aversion/preference list, +64 the clock its
   protection ends or it went live (then the preferred registers'
   32..63), +68 its weighted live time (then preferred 0..31), +72 its
   first definition (chained at the segments' +36), +76 its dead
   segments (chained at their +40), +80/+84 the conflicting registers
   (32..63, 0..31); lts_t +32 the number of the instruction last
   referring to it (a word), +34 that of its definition's, +36 the next
   definition, +40 its last reference (an operand), then the next dead
   segment; bb_t +0..+7 the live counts, +122/+126/+130 the registers
   written (integer, floating 32..63, 0..31); rtn_t +116 the stack
   frame's live range, +120 another frame register live range (the
   conventions' b30); the routine node's +240 a common member, +374
   bit 19 needs_db, +378 bit 4 (forces a frame) and bit 2 (has one).
   rtn_t's conv and frame_size (PA5) agree with ra's view.
232. Translator PB6, konst (for batch A): fields KONST uses through views:
   lts_t +28 the exposed segments a definition reaches (chained at
   their +28: lts_t.l28), +32 the next on konst's queue (-1 the last),
   +40 the definition descriptor, +44 a definition's join inputs (the
   ut_jbi_t records chained at +0); a flow graph edge's next_pred low
   bit (+15 bit 0) the mark that konst followed it (masked `andi.l
   #-2' while set); ut_jbi_t's instr low bit (+15 bit 0) an input
   reached along an executable path; bb_t +130 a join input, +146 the
   walk number, +150 konst's block queue (-1 the last); instr_t +28 a
   word, marked for evaluation; a join birthpoint's operand 3's link
   (+72) its inputs (chained at +4).  And: KONST runs only when its
   debug level (at_backend_switches.level) is nonzero; the reached-
   block queue (+92/+80) is emptied but nothing fills it, and +96/+84
   are set and never read.  Is the level test the original's (KONST
   off by default)?
233. Translator PB6, at_backend: the phase table's +3 byte is 255 exactly
   where +2 (turned off at low optimization) is 0, and nothing reads
   it (kept as b3); get_calling_conventions looks an entry's record up
   at its block's +124 but stores a new one at the entry node's own
   +124 (kept); build_source_statement_map sizes its tables by
   runbackend_16 (the statements opt_main counted) and lir_$end_routine
   is called with no argument (pattern 132; the translation passes the
   routine).  at_backend_$begin_compilation passes its word p to
   exs_$initialise as `p in [5]' twice (both arguments the same: a
   slip, or two flags that coincide for C?).
234. Translator PA6, post: post_$reschedule_spill_loads (cc.a88k 0x264114),
   making the alias descriptor of the store before a spill load, sets
   the load's descriptor's inexact flag (`bset #7,(-133,A6)`, the
   load's at -152) instead of the store's (-64), and passes
   alias_$get_alias_desc the store's first operand's link while it
   tests the kind of its second.  Kept as the image has it; slips of
   the original?
235. Translator PA6, post: post_$sprinkle_mfnextcc (0x263A7A) passes the
   MOVE block (D6), not the branch's block, as fill_er_up's block, so
   move_bundle_to_new_bb updates that block's first/last when the
   stolen bundle lands at an end of the branch's block.  Kept; a slip?
236. Translator PA6, post: droppable_jump_addr (0x261990) returns whatever
   D0 holds after its bug check, and ipccnop_shuffle_trapcc (0x2633E6)
   an unset D5 when its argument is not an ungrouped IPCCNOP (pattern
   142); post_$sprinkle_fpquiesce inserts its FPQUIESCE with an unset
   anchor after its bug check.  Kept.
237. Translator PA6, post: the seven trace_ routines (0x2612A4 ..
   0x2612B0) are bare `rts' though post calls them some 120 times with
   names, messages, blocks and instructions: debugging bodies compiled
   out (an `%if' in the source), most likely.  Written as empty
   procedures with the parameters the calls pass.

238. Translator PD, tools/cc_data.py: **it ignored the .rwdi repeat
   records** (kind 1: the previous record's bytes count-1 more times),
   printing the bytes they set as unset (`..').  rewrite's word tables
   (a value and a repeat count) showed it; cc_data.py now applies them.
   Initial data reconstructed with the old tool (the .init files, the
   defined tables of lir_main, iv, oli, asm, ...) may have zeros where
   the image repeats a value: worth re-running against the new tool.
239. Translator PD, at_lib_dsc.ins.pas: the section at_lib_dsc_ptr
   (cc.a88k 0x513D40, 60 pointers, cc.m68k 0x353398) is declared there
   as an extern array of il_$node_ptr_t (rewrite reads it); the m68k
   side's users, if any, read it otherwise.  Keep it there?
240. Translator PD, rewrite.pas: the image's two bug check messages
   'REWRITE: Wrong number of bit_field_assign arguments.' and
   'REWRITE_$CONST_MUL: Unexpected multiplier ' have no `%.'/`%$'
   terminator (the first runs into the next message in the image); the
   translation writes the literals as the bytes give them.  Slips of
   the original?
241. Translator PD, rewrite.pas: rewrite_$routine_call stores the hidden
   temporary in the call node's first operand (`move.l D2,(40,A3)': the
   routine operand, already copied to the new call tree) and
   rewrite_$agg_aop returns the source's assignment without linking it
   (node's next becomes the ISC_AGG; the caller must link the returned
   node).  Both kept as the image has them.
242. Translator PD, isc_solution_fields.ins.pas: backend.ins.pas's
   solution_t (batch A) and the ISC's isc_solution_t describe the same
   432-byte record; the ISC units cast between them.  Should the record
   move to isc_solution_fields.ins.pas (which lir, lir_main, lir_utils,
   ra_utils open) with the CSE accessors' field names (base_reg,
   index_reg, live_range, bits_known, ..., memory_refs), and
   backend.ins.pas keep only the pointer type?  (sym opens no ISC insert:
   it would need solution_ptr_t only.)
243. Translator PD, backend.ins.pas: the bug check reporters'
   headings (instr_bug_check, phase_bug_check, phase_instr_bug_check)
   now take backend_$bug_string_t and backend_$bug_arg_t (the same
   shapes as bug_check.ins.pas's): rewrite opens backend.ins.pas before
   bug_check.ins.pas.  Did the original declare them in at_base.ins.pas
   or elsewhere?


244. Translator PB7, sched: register_pressure (cc.a88k 0x275382) starts
   its count from 2 and returns 2 for the classes it does not count:
   the only 2 in the routine is `moveq #2,D1', which also serves as
   the shift count of the opcode's index (`lsl.w D1,D0', where every
   other index in the unit uses `lsl.w #2'), and the loop adds to D1
   without clearing it.  Translated as `p := 2' first (the compiler
   reusing a constant's register, rev889-patterns 155); if the source
   left p unset, the 2 is an accident of register allocation.  Which?
245. Translator PB7, sched (slips kept as the image has them?):
   select_first_instruction's search tests `(h and not 3) = 3' (`moveq
   #-4; and.l D3,D0; cmpi.l #3'), never true, before its other stop;
   only_final_call_and_seq never looks at the queue's last item; and
   p2_process_lts's "LTS doesn't go anywhere" names the last reader's
   instruction, which is unset when there is no reader (the case the
   message reports).
246. Translator PB7, sched: fp_registers_busy.init is written as a
   variable of its own in the section sched_readonly_tables (as
   zzzzz's code_cell_size and lir_main's tables): the section takes the
   unit's name, so the generated file must have held the declaration
   (sched includes it after exs.ins.pas and before utils.ins.pas)
   rather than a `define' of a backend.ins.pas variable.  Its name and
   layout (768 bytes, reads at 2 opc, writes at 2 opc + 1) are ours.
247. Translator PB7, sched (for batch A): fields SCHED uses through
   views (sched.pas sc_instr_t, sc_lts_t, sc_lr_t, sc_bb_t,
   sc_rtn_v_t): instr_t +2 bits 3..0 the stall cycles before it issued
   (batch A's do_not_delete and b2_2..b2_0; ra's question 231 and lst's
   cycle column read the same nibble), +2 bit 6 live (a deleted
   instruction has it clear), +0 bit 2 grouped (set on every
   instruction followed by another in its cycle), +3 of a branch its
   squash mode (pass 1 sets 2), of a call bits 3 and 5 a final call,
   +16 the routine's marks when first touched in the block, its low two
   bits the state (set when pass 1 places it; bit 0 cleared on issue,
   bit 1 when put back in the block), +24 cleared, +28 the height
   (word, quarter cycles) and +30 the enable count (word);
   the slot after a call's operands +56 + 12n its conventions (mmt's
   mmt_call_info_t: SCHED reads uplevel_dynamic_storage_untouched,
   +40); lts_t +3 bit 3 set up for the block, bit 2 the lock bit, +3
   bit 4 (final) cleared by the setup and set on the block's finals,
   +28 the touched chain (lts_t.l28), +32 the height its readers set
   (word), +34 its enable count (word, "EC"); lr_t +3 bit 2 the lock
   bit, +3 bit 1 cleared when two live ranges are merged, +56 the
   segment count (the merged segments renumbered from it); rtn_t +132,
   +136 the floating and integer condition codes' live ranges (oli's
   reading); bb_t +17 bit 5 (b17_5) makes SCHED skip the block like
   atomic.  Should b17_5 be named (xtp sets it)?
248. Translator PA7, lir: call_or_svc_argument_register (cc.a88k
   0x247BDC), taking a written floating register out of a call's
   clobbered sets, computes the register's and its pair's bits in two
   frame longwords and then stores `regs.s8 - [r2]' into regs.s4 (for
   0..31) or `regs.s4 - [r2]' into regs.s0 (32..63): an eight-byte set
   difference stored from its second longword, the register's own bit
   never used and the next set's bits copied over the floating set.
   Translated as the image does it; a Rev 8.89 miscompilation of a
   set difference on the conventions' two-longword floating sets, or a
   slip of the original?
249. Translator PA7, lir: backend.ins.pas declares lir_3f94, lir_3f98 and
   lir_3f9c (com's) as cells of their own, but they are lir_3f90's
   elements 1..3 (the floating registers' physical live ranges, a
   64-entry array lir defines at +0x3F90): lir.pas does not define them.
   Should com read lir_3f90[1..3] instead?
250. Translator PA7, lir_$build_operand's dump (dpc gap 4) prints the
   solution's kind through the SOLUTION$ identifier table (0x24526E), so
   solution_t.kind (+108) is an enumerated type in the original
   (solution$t?, solution_string.init's 25 names), and the dump's
   headings give the original names of four fields: solution_t +78
   physical_register_number, +83 bit 3 physical_register, bit 1
   physical_register_is_no_modify, bit 0 physical_register_user_declared
   (batch A's f78.reg, physical, no_modify, serialize), +20
   live_range (lr), and lr_t's the same names for +2, +3 bits 7, 6, 5.
   Kept by the existing names (kind an integer, its users compare
   numbers); rename to the original's?
251. Translator PA7, lir: three slips kept as the image has them?
   lir_$complete_instruction's 'set CCs request on %a' names the build
   area's opcode (lir_2f58), not the instruction's; its combined pre- and
   postmodify test has a dead first arm; lir_$build_operand's scale
   factor messages pass the byte's address to %wd (the next byte read
   with it).  And the messages' routine names 'LIR_ BEGIN_INSTRUCTION',
   'LIR_\COPY_BUILD_INSTRUCTION', 'LIR_ \PROLOG_LABEL_FOR_SPECIFIC_
   EXCEPTION' are the bytes.
252. Translator PA7: question 198 more broadly: lir's own calls of
   lir_$get_new_instruction(_no_exceptions) and begin_instruction push
   three or four of the five longwords too (get_basic_block's JUMP,
   lir_$dispatch_instruction, lir_$trap_instruction, lir_$simple_
   instruction), and copy_build_instruction is called with an argument
   it does not read; the translation passes nil and 0.  So the heading
   was most likely `options(variable)' (or the trailing parameters
   optional) in the original.
253. Translator PA7: lir_$end_routine reads the routine from lir_41e0,
   not from a parameter (at_backend passes none: pattern 132, question
   233), and lir_$complete_instruction leaves D0 unset (lir_main read it
   as a function's result: now a procedure, lir_main's discards gone).
   lir_$begin_call_or_svc's second and lir_$end_call_or_svc's first
   parameter are not read (kept as p2, p1 for the ISC's calls).

254. Translator QA (data check), tools/cc_data.py: the repeat-record fix
   of 238 repeated the last copy record after a `zero' record (kind 2),
   so .data showed bytes no record sets (lir_main's block a 16-byte
   pattern).  The loader (lib/pmlib/loader.pas process_rwdi) repeats
   the record just before and copies nothing after a zero record; zero
   records describe sections with file bytes (libdsc, cc.a88k's
   read-only tables), whose bytes cc_data.py now prints too.  Any
   initial data read with cc_data.py between 4a19a88 and this fix is
   worth reading again (tools/cc_datacheck.py finds it).
255. Translator QA, opt_strength (cc.m68k A5 0x3530D8): the image
   initializes a descriptor at +0xA8 (size 4, rlen 4, w8 2), past the
   cells the code addresses (+0 .. +161; no instruction reads +0xA8).
   Not declared: whose variable is it?
256. Translator QA, outbin's fpx_names (+0x8C8): the image has each
   name followed by a NUL and the rest of its 12 characters unset, as
   an initialized varying [12] of char gives it (dpc gap 43); the
   translation's record has blanks there.  Declare them varying once
   dpc can?  (list_tree's line, +0x18, is the same: length 0 and 256
   blanks in the image.)
257. Translator QA, dmp: the image's .init tables are longer than
   dpc's: lsq_string_length +0x240 and lsq_string +0x260 (0x20 and 0x80
   bytes, four entries set), am_string_length +0x300 and am_string
   +0x320 (0x20 and 0xA0 bytes, three set), so dpc's block is 0x2E0
   bytes for the image's 0x3F8.  Are the index types of
   backend.ins.pas (batch A) narrower than the original's?
258. Translator QA, c_main: dpc's module data is 0xF8C bytes; the
   image's ends at +0xDBC (c_run_acpp.c's data follows at +0xDC0).
   jmp_br_resolve likewise (dpc 0x28, the image 0x1C, opinfo's tables
   after it).  Some declared size is larger than the original's.
259. Translator QA, list_tree's size_letters (+0x130): .rwdi sets 12
   pairs (the last four `**' by a repeat record) and leaves the
   block's last 4 bytes (to +0x14C) unset: 12 entries (written so) or
   14 with two zero ones?
260. Translator PD2, isc_user_routines (slips kept as the image has
   them?): alignment_from_sr_info compares each literal increment's
   alignment with D2 before anything sets it (the step alignment
   uninitialized for the first literal step); local_initialize_symbol
   tests cargs' db = 3 twice (once only when attribute bit 14 is clear,
   `and.l #16#18000' of +0x282 both times); low_half_of_fp_reg_quad's
   nil test guards only the copy, then reads sol^.lr2 and writes the
   nil copy; log_2 (x not a power of two), invertible_in_sp/_dp (a node
   not of kind 89) leave the result unset; expression_has_side_effects
   tests the reference kinds and 110, 109 but every path returns true;
   verify_any_bits shifts its mask as a halfword (`lsl.w') and compares
   the masked bit with expected itself.
261. Translator PD2, isc_types.ins.pas: the section isc_readonly_tables
   (cc.a88k 0x2BCDFC, 3120 bytes, file bytes) has no unit of its name;
   isc_user_routines reads it at +0x140, +0x174 and +0xAA8 and the
   generated units probably more.  Declared as an extern view (no
   initial value).  Was it an insert's `var (isc_readonly_tables)' with
   initial values, overlaid in each ISC unit?  If so the insert should
   carry the image's 3120 bytes (like lir_main_readonly_tables).
   **Settled by translator GB (2026-11-12):** isc_vars defines it (its
   .blocks record names the section, and isc_tool_generated_readonly_
   tables); isc_types.ins.pas now declares the section's variable (`var
   (isc_readonly_tables)', its view extended to the section's 3120
   bytes) and the generated isc_vars gives the image's bytes with
   `define' (the scheme of question 161; dpc gap 32 renames it for the
   gate).  isc_vars opens isc_var_defines.ins.pas first: perhaps a
   switch that made the inserts define what they otherwise declare; its
   contents are not in the image (a stub).  docs/iscg-design.md 9.3.
262. Translator PD2, isc_solution_fields.ins.pas: isc_solution_t's
   base_reg (+4) and index_reg (+8) are typed lr_ptr_t (the CSE
   accessors' types), but every writer stores a solution there
   (isc_user_routines_31c for none, +0x340 the frame, literal_base_
   register for literals) and solution_to_string prints index_reg as a
   solution.  Retype them isc_solution_ptr_t (and the accessors
   pass_2_cse_*_base_reg/_index_reg)?  isc_user_routines casts for now.
263. Translator PD2, isc_main: new_solution and duplicate_solution count
   a solution made from the ISC heap by comparing the heap record with
   isc_heap by contents (five longwords, `cmpm.l'/`dbne'), not by
   address.  Written as an internal helper same_heap; was the source
   `heap = isc_heap' on records (a Domain Pascal extension?) or a
   comparison of a 20-byte field?
264. Translator PD2, isc_var_externs.ins.pas: isc_main's metering names
   the cells +0x2DC .. +0x304 and +0x350 (calls_to_pass_1,
   max_solutions_for_one_il_node, ...).  They keep the offset names
   (isc_user_routines_2dc ...) with the printed names in comments, as
   the insert's other cells; rename them after the printout?
265. Translator PD2, solution_to_string: a literal's value is written
   twice, the second with PAS_$WRITE code 4214 (the plain integer32 is
   2673): perhaps a hexadecimal or unsigned form.  Written as `:1'
   both times; which format?

266. Translator GA, the ISC generator (docs/iscg-design.md): **names of
   the generated action modules.**  The pass-1 and pass-2 actions are 25
   + 25 separately compiled modules (one A5 each, rules in runs: section
   1.2) with no .blocks unit, so neither the files' nor the routines'
   names survive.  The ISC's named objects lie in alphabetical order, so
   the pass-1 modules' names sort between isc_pass_1_main and
   isc_pass_2_main and the pass-2 ones between isc_pass_2_main and
   isc_pattern_matcher.  Proposed: `iscg_input/isc_pass_1_<nn>_<topic>.pas`
   and `isc_pass_2_<nn>_<topic>.pas`, nn 01..25 in address order (so the
   alphabetical order is the image's), topics from the operators
   (address_modes, assignments, ..., compares); routines
   `transform_<r>_pass_1` / `transform_<r>_pass_2`, r the rule
   (which_transform).  Other names?
   **Lead, provisional (2026-11-12, until the owner answers):** GA's
   proposal is adopted: isc_pass_1_<nn>_<topic>.pas / isc_pass_2_<nn>_<topic>.pas
   and transform_<r>_pass_1 / _pass_2.
267. Translator GA: **isc_solution_fields.ins.pas's field names.**  The
   insert is a derived object of the generator's input, and the image
   keeps the input's attribute names: dump_solution prints each field
   after its name (`tools/cc_isc_inventory.py BINARY fields`:
   which_transform +112, before_transform +88, memory_references,
   evaluation_order, object_with_name, has_a_symbolic_displacement,
   uses_the_displacement, uses_the_index_register,
   embedded_strength_reduction_temporary, already_preserved +115.7,
   builtin_could_deadlock_sched .6, builtin_is_local_cse .5,
   builtin_local_cse_has_been_preserved .4, already_through_pass_2 .3,
   and 50 more).  The current insert (translator PD) uses abbreviations
   from the CSE accessors' names (memory_refs, eval_order, obj_w_name,
   has_sym_disp, uses_disp, embedded_sr_temp) and calls +88 `chain' and
   +112 `rule'.  Rename to the image's names when the generator emits
   the insert (touches PD's and PD2's ISC units; batch A's solution_t
   view is separate)?
   **Lead, provisional:** no rename yet.  The rule file uses the image's
   attribute names; the generator maps them to the insert's current
   field names, so PD's and PD2's units are untouched.  A rename can
   follow the owner's answer as one mechanical change.
   **Done (translator RN3, 2026-11-12; the owner approved the image's
   names):** isc_solution_t's fields carry dump_solution's names
   (offsets, sizes and packing unchanged; b81_7_2 and b83_7_4 split into
   their six and four booleans).  Batch A's solution_t stays a separate
   view (backend.ins.pas is opened by units that open no ISC insert, and
   its packed groups f78/f84 differ from f76), with the image's names on
   the fields it names (question 242's merge not done).  The generator
   reads every attribute through the field of its name (FIELD_MAP gone);
   the ISC units, lir, lir_main and lir_utils follow.
268. Translator GA: **the gate for units without a .blocks record.**
   coff_compare picks a unit by its .blocks source path, so the 50
   action modules cannot be compared as they are.  Proposed for phase 2:
   the generator writes a manifest (file, A5, code range, routine name ->
   address from the action tables) and coff_compare gains `--anon START
   END A5 --names FILE`; cc_check.sh and cc_addrcheck.py use the manifest
   for those files.  coff_compare.py is a shared tool (a local patched
   copy of the source repository's): may phase 2 change it, or should
   the comparison be a separate tool?
   **Lead, provisional:** a separate tool (tools/cc_isc_check.py, driven
   by the manifest) that reuses coff_compare as a library; the shared
   coff_compare.py, cc_check.sh and cc_addrcheck.py are not changed
   except to call it for the manifest's files.
269. Translator GA: **how far the rule file goes.**  The patterns,
   result kinds, flags, opcode maps, attribute declarations and the
   actions' skeleton come out of the image mechanically.  The actions'
   bodies (pass 1 about 31% rule-specific code, pass 2 nearly all of
   it) need a decompiler to a statement language, with a residue written
   by hand.  Proposed: a Pascal-flavoured language with `<-` (the image
   keeps `let result <- ...;' from the original), attribute paths
   ($k.f, result.f) and macros for the repeated statements; one file
   per section in rule order.  Acceptable, or should bodies be Pascal
   text pasted by the generator (less to design, more like hand
   translation)?
   **Lead, provisional:** the statement language, as proposed: it is
   what "classic codegen" (question 151) implies, and the image keeps
   the original's `let result <- ...;'.  Residue the decompiler cannot
   lift is written by hand in the same language.
   **Owner (2026-11-12), on the result:** the .isc files buy boilerplate
   removal but not a compact syntax, and little of it has evidence.  The
   evidence: nine pass-2 messages quote `let result <- ...;' with the
   input line number (patterns 358 at 31,146 .. 422 at 34,259): about 49
   input lines per rule over 358..422, 24-27 for small ones; ours take
   107 for the same rules (124 over all 563), about twice as long.  Only
   `<-', `let result <- ...;', `;', "pattern N", the attribute, operator
   and solution-kind names and the 25 sections are attested; the rest of
   the syntax is ours.  The owner's reading: the original probably had
   more abstract, semantic operations that each encode several
   assignments (the full-copy pass-2 actions and the copy/sum runs point
   that way).  To be revisited later; no rewrite now.
270. Translator GA: **isc_main and isc_debug.**  Both are derived objects
   of the input but mostly ordinary code.  The generated parts found:
   preserve_solution's per-rule byte table and switch (isc_main) and
   dump_solution's field list (isc_debug); isc_print_il_node (92 KB) may
   be generated or the generator's fixed text.  Proposed: translate them
   by hand as question 151 says, with the generator emitting only those
   generated parts (as include files or by rewriting marked regions).
   Agreed?
   **Lead, provisional:** agreed: isc_main is done (PD2); isc_debug is
   translated by hand, with the generator emitting only its generated
   parts (dump_solution's field list) into a marked include.
271. Translator PE, isc_debug: **inherited_attributes_t's field names.**
   isc_print_il_node prints every inherited attribute under the
   generator's name (isc_attribute_records.ins.pas's names first):
   node +0 `il', top +4 `exception_frame', stmt +12 `original_il', l16
   +16 `conditional_target' (a label: label_to_string), call +20
   `call_instruction_ptr', precision +24 `fetch_precision', available
   +28 `required_precision', pos.line +32 `source_line_number',
   pos.stmt +34 `stmt_number', b36 `parent_il_kind' (an il$t), f38.arith
   +38 `required_arithmetic', +39 b7 `conditional_sense', b6
   `immediate_parent_has_signed', b5 `immediate_parent_wants_lvalue', b4
   `immediate_parent_wants_set_temporary', b3
   `immediate_parent_wants_signed', preserve (b2) `inside_a_cse'.  The
   insert is a derived object of the generator's input like
   isc_solution_fields.ins.pas.  Rename with question 267's rename (one
   mechanical change over the ISC units and lir's lir_3b80 view), or
   keep?  Not decided here: isc_debug uses the insert's names, with the
   image's in its comment.
   **Done (translator RN3, 2026-11-12):** inherited_attributes_t's
   fields carry isc_print_il_node's names (pos keeps its record, its
   fields source_line_number and stmt_number: the two words are copied
   as one longword and bug_check prints the record), and lir.pvt.pas's
   lir_inherited_t (lir_3b80) takes the same names for the fields it
   names.  parent_il_kind keeps the type char (question 284's 0..255 not
   done: the generated pass 1 still writes it through p1_inh_view_t).
272. Translator PE, isc_debug: **the IL description in the generator's
   input.**  isc_print_il_node is generated (docs/iscg-design.md 9): one
   arm per IL node kind of il$t writing that kind's static attributes
   (name, type, node offset), nested arms per operator for assign_node,
   tree_node and cmp_tree_node.  isc_debug.pas carries them as 54 view
   records (pin_<kind>_t, named as printed) and the arms, in marked
   regions.  Should the generator's input declare the IL node kinds'
   static attributes, so the generator emits the views and the arms
   (and could emit isc_types.ins.pas's isc_node_t variants from the same
   description), or should these regions stay hand-maintained text that
   the generator copies?  Not decided here.
273. Translator GB, the generated pattern_matcher (docs/iscg-design.md
   9.3): a try is written as one `if' per test, nested (`if $1 is ip_reg
   then if $2 is address_mode then hard_work(..., 150)'), because dpc
   evaluates `and' whole and a nested pattern's tests read children of
   children that exist only when the tests before them hold.  The image
   leaves at the first failing test either way; Apollo's generator
   probably wrote one `if' with `and's (Rev 8.89 short-circuits them).
   Keep the nested form, or emit `and' (or `and then', if Rev 8.89 had
   it) and log the evaluation as a dpc gap?
274. Translator GB, the rule file's names that are ours: the flags
   `check_permissible' and `no_could_deadlock_child' (the launch brief
   said "at_most_no_could_deadlock_child": set, the rule allows no
   could-deadlock child; clear, at most one), the opcode maps
   (opcode_rr_reversed, opcode_rr, opcode_immediate, opcode_double,
   opcode_immediate_negated, opcode_single), the section topics, and
   the module data (pm_pass_1_action, pm_check_permissible,
   pm_no_could_deadlock_child, pm_proper_subtree_seen,
   p2_pass_2_action).  Other names?
275. Translator GB, isc_pattern_matcher's data: four bytes at +0x8CC,
   between the pass-1 action table (+0x000, 563 longwords) and the
   check_permissible flags (+0x8D0), that nothing sets or reads (kept
   as pm_unused_8cc).  A 564th table entry (the tables sized by the
   rules' count plus one) or an unused variable?
276. Translator GB, slips kept as the image has them: pass_2 clears
   already_through_pass_2 (+115 bit 3) just before the pass-2 action and
   sets it after (`bclr #3' at 0x18C75C, `bset #3' at 0x18C790); hard_work
   reads `appended' and `wanted' (D4, D3) uninitialized when the pass-1
   action gives a work solution but no result (0x200966).
277. Translator QB, outbin.pas: fpx_names are `varying [8]' or `[9]' of
   char?  Both take 14 bytes (n + 5 or 6, rounded to even), which is the
   image's spacing; no read tells them apart.  [8] chosen.
278. Translator QB, list_tree.pas: the image's line is a record of a
   length and 256 characters (258 bytes, blank-padded, no NUL), not a
   varying [256] (262 bytes).  Declared as a unit-local lt_line_t,
   passed to listln and emit as univ iosub_$line_t.  Did the original
   declare its own type?  (outbin's prtsub_$line_t takes 262 bytes, so
   iosub_$line_t cannot itself be such a record.)
279. Translator QB, com.pas (cc.a88k): com_name (+24) is followed by
   +284, so it takes 260 bytes, less than a varying [256]'s 262; is it a
   record like list_tree's line?  Worth the same check: lst_line_t,
   std_$string_t, time_$line_t, prtobj_$line_t.
   **Answered by translator QC: yes; four more cells are records, the
   rest fit.**  Every cell of a varying type (or of a type built on one)
   laid out in module data, measured from the next cell the image's
   code addresses (A5 displacements) or .rwdi sets:
   - Not a varying [256] (the next cell 260 bytes on, under the 262 a
     varying [256] takes): com_name (com, +24, com_284 at +284),
     lst's line (+0x10, the scale letters at +0x114 in .rwdi, read at
     (276,A0)), prfpkg's line (+0x7D0, start_faults at +0x8D4, both
     binaries), opt_reachdef's line (+0, the tables from +260, both
     binaries), as list_tree's (+0x18, countdown at +0x11C).  Each is
     filled to 256 characters (add_char's `cmpi.w #256',
     sym_$fully_qualified_routine_name's `n < 256', PRTSUB's bound), so
     a smaller varying ([254] or [255], 260 bytes) would not hold what
     the code writes: each is now a unit-local record of a length word
     and 256 characters (com_name_t, lst_text_line_t, prf_line_t,
     rd_line_t, as list_tree's lt_line_t).  dpc lays them so that
     opt_reachdef's and com's later cells sit where the image has them;
     lst's +0x112..+0x113 and opt_reachdef's +258 are bytes no
     instruction reads.
   - Not a varying [520]: c_lex_pp's lex_text (c_globals.ins.pas,
     +0x24DE, lex_tokens at +0x26E8: 522 bytes, under 526); the text is
     read in at character 9 up to 512 characters (520 in all), so a
     record of a length and 520 characters (lex_text_t).
   - PRTSUB's routines (prtcatc, prtcats, prtcatb, prtint, prthex,
     prttab) now take the line `in out s: univ prtsub_$line_t', so
     that prfpkg's and opt_reachdef's 258-byte lines can be passed
     (same code; core change).
   - Consistent with a varying (left as they are): outbin's line
     (+0xE8, shown at +0x1F0: 264), dmp_line (+0, dmp_scale at +0x108:
     264), at_backend's at_name and at_query_name (+720, +984, at_heap
     +1248: 264 each), sym_line (sym's whole block, 264 bytes), diag's
     line, line_prefix and prefix (varying [200], 208 apart, the last
     ending at +622: 206), ass's prefix_before (+2, column_before at
     +208: 206 exactly) and program_name (varying [80], +216, the
     call-back at +304: 88 for 86).  A 264-byte gap does not tell a
     varying [256] (262, then 2 bytes) from a varying [257] or [258];
     [256] kept.
   - Never laid out in data, so the image does not size them (used
     only as univ or by-address parameter types, or for frame locals):
     lst_line_t, std_$string_t (its append routines have no callers in
     either image), time_$line_t, prtobj_$line_t, iosub_$line_t,
     token_$vstring_t, ass_$description_t, c_main's arg_t and bin's
     name_t (frame locals).  Left as they are.
   The original's line type is open: two sizes coexist (258 and 262)
   among units that all pass their line to PRTSUB, so PRTSUB's
   parameter was presumably univ or the units declared their own types
   (question 278).
280. Translator QB, list_tree's size_letters (question 259): array
   [0..12] with 12 values, array [0..13], or padding before mrh's
   8-aligned data?  No instruction reads +0x148..+0x14B; the gate passes
   either way.
281. Translator GD, isc_pass_1_main (docs/iscg-design.md 10.5): **the
   operator routines' parameters and the module data are unnamed in the
   image.**  The generated unit calls them il, inh, depth, permissible,
   var il_kind, number_of_children, solutions, children,
   solutions_made, no_solutions (the type p1_operator_t), and the four
   dispatch tables p1_tree_op (+0), p1_cmp_op (+360), p1_assign_op
   (+720), p1_kind (+872).  The rule file's statement names (child,
   permissible, copy_all, trace rewrite, let, solutions_made, if/else/
   endif) are ours too.  Other names?
282. Translator GD: **process_eval_node's second parameter.**
   isc_routine_externs.ins.pas declares process_eval_node(eval, parent:
   isc_node_ptr_t); isc_eval_node (0x0E4280) passes (il, inh): the
   node's inherited attributes.  The generated call casts inh to
   isc_node_ptr_t.  Should the heading (and isc_user_routines'
   definition, a hand-written unit) say inh: inherited_attributes_ptr_t?
283. Translator GD: **isc_readonly_tables at +0x140.**  The operator
   routines read a word table by rlen there (its low byte, the child's
   required_arithmetic); isc_types.ins.pas's isc_readonly_tables_t has
   the range inside x0d4.  isc_pass_1_main reads it through a view of
   its own (p1_readonly_view_t.rlen_arith).  Split x0d4 in the shared
   insert (x0d4 [0..107], rlen_arith [0..25]: isc_vars' define would be
   regenerated, the bytes unchanged)?
284. Translator GD: **parent_il_kind is a byte.**  The operator routines
   store it with `move.b #67,(36,A0)' (isc_disp_node): the
   inherited_attributes_t byte b36 (isc_attribute_records.ins.pas),
   written through a view (p1_inh_view_t) as an il$t ordinal.  Rename
   b36 to parent_il_kind (0..255) with question 271's rename?
285. Translator GC, the pass-2 actions: **two procedures whose callers
   read A0 after the call.**  22 actions (435..440, 442..444, 471..473,
   489..492, 534, 539, 542, 543, 545, 547) use A0 after `jsr
   set_isc_is_cse_on_live_range_if_local_cse' (into live_range) or
   `side_effect_set_var_$address_exposed' (into a frame temporary):
   the value is the pointer argument each loads into A0 (lr, sym:
   isc_user_routines 0x216742, 0x216766).  In the original these were
   probably functions returning their argument (`result.live_range <-
   set_isc_is_cse_on_live_range_if_local_cse(...)`) whose body never
   assigns the result (Rev 8.89 returns whatever A0 holds).
   isc_routine_externs.ins.pas declares procedures; the lifter writes
   the argument again after the call (rev889-patterns 185).  Make them
   functions (and isc_user_routines' bodies assign the argument)?
286. Translator GC: **the actions' temporaries.**  The lifter makes a
   `temp t<n>' of a register value the code keeps across a statement
   that may have changed it (a function's value used twice or after
   another statement, a value that differs between an if's arms, a
   loop variable, a field stored meanwhile): 3,948 in 297 actions,
   most of them function values (labels, new solutions) and the
   requests words built by conditions.  Rev 8.89 keeps them in
   registers and frame temporaries; whether the input named them
   (locals of the action) or the compiler made them is not known.
   Names (and fewer of them: macros for the requests words)?
287. Translator GC: **IL node fields read by offset.**  44 actions read
   their node's fields (`self.il.l4 & 16#400000', `subject.il.b11',
   `self.il.b14' bit 7): the language writes them by offset and the
   modules read them through a view (p2_node_t).  Named by the node's
   kind, with isc_print_il_node's static attribute names (question
   272), the generator would need the IL description and each action
   the kind of its node (the rule's operator gives it for subject.il,
   not for a child's).  Worth it?
288. Translator GC: **isc_readonly_tables' unnamed word tables.**
   Eight actions index words of isc_readonly_tables at +16, +128 and
   +2986 (rules 121, 129, 130, 309, 310, 316, 442, 471) by an il$t or a
   precision; isc_types.ins.pas's view has fillers there (x0, xb2c).
   The language calls them `readonly_w<offset>' and the modules read
   them through a view.  Names (and fields in the view)?
289. Translator GC: **self and result.**  pass_2 passes the same
   solution as both var parameters; the actions read some fields
   through self (fp+8: `result.object_with_name <- self.il') and set
   them through result (fp+16), and `let result' through the fourth
   parameter.  The language keeps which parameter the code uses (the
   image's loads differ); one name would read better.  Merge?
290. Translator GC: **the pass-1 modules in cc_isc_check.**  The
   manifest has `module' lines for the pass-2 modules only; the pass-1
   modules' data (cc_datacheck_known.txt's isc_pass_1_main entry,
   +0x720..+0x30BA0) would move to cc_isc_check once the pass-1 action
   modules are generated and the generator writes their lines.  Agreed
   as the plan?
291. Translator GD2, isc_pass_1_main (docs/iscg-design.md 10.5): **the
   rule file's new operator statements are named by us**: `child K NODE
   solution KIND' (a child's list of one solution made in the routine:
   irrelevant for a label, void for a missing operand), `nK.index' (a
   statement's index, the 16 bits at bit 8 of +42), `rlen_bits(X)'
   beside `rlen_arith(X)', the roots `il_180' and
   `target_properties.p_be' / `target_properties.l180' (+0xB4, which
   target_properties.ins.pas leaves inside p_b0).  Other names?
292. Translator GD2: **isc_readonly_tables and target_properties read
   through isc_pass_1_main's views.**  The fixed text reads a word table
   by rlen at isc_readonly_tables +346 (return_node: the assignment
   operator of a return value), a word table at +0x30 by a relation's
   absolute value (compare_top: its converse) and a boolean byte table
   at +424 by opmod1 (f_math_top: the functions done in line), through
   p1_readonly_words_t / p1_readonly_bytes_t; target_properties +0xB4
   (a longword, the literal-pool size limit of char_string_ob and its
   siblings) through p1_target_view_t.  With question 288's tables:
   name them in isc_types.ins.pas and target_properties.ins.pas (p_b0
   split), or keep the unit-local views?
293. Translator GD2: **zero-extended words.**  The image pushes some
   node words zero-extended (`clr.l d0; move.w (26,a0),d0; move.l
   d0,-(sp)': set_extend_top's and isc_addr_top's size, mod_top's
   value_top_over size) and compares char_string_ob's +16 zero-extended
   with target_properties +0xB4; the rule file and the fixed text write
   il.wN (an `integer', sign-extended by dpc).  The same for values
   below 32768.  Mark unsigned words in the language (il.uwN, emitted
   as `& 16#FFFF') or leave it?
294. Translator GD2: **the large rewrites' conditions as written.**
   mul_top, isc_mul_top, isc_mul_to_aop, div_by_aop, div_top and
   mod_top test whether the multiplication or division can be done in
   line as `c or not (X or (not X and Y))' (isc_mul_to_aop: `(not X and
   Y) or c or not X'), X il_180's bit 4 of +374 or -NO_FP, Y -SOME_FP;
   entry_blk and its two siblings give each branch its own trace.  The
   fixed text keeps the image's evaluation order; the original may have
   had a macro (the trace with every rewrite) and a simpler condition.
   Acceptable as fixed text, or should the language grow `rewrite'
   blocks with nested conditions so these are generated too?
295. Translator GE, the pass-1 actions (docs/iscg-design.md 10.7):
   **the language's pass-1 names are ours**: the clause words `condition',
   `cycle_guard', `cycle_mark', `rewrite', `dropped', the macros `copy
   ... from' and `sum ... of', `trace', the inline cost tables `bytes(..)
   [e]' / `words(..)[e]' and `@k' places, the modules' tables
   `cost_<rule>_<k>' (k the place in the rule's layout), the local
   `solution' for the language's `result', and the views p1_already_t,
   p1_int_fields_t, p1_snode_t, p1_readonly_t.  Only "Pattern N matched
   the semantics." and "Infinite cycle prevented by NOT adding this to
   the work list." survive.  Other names?
296. Translator GE: **are the cost tables the generator's or the
   input's?**  Every table has 17 entries (0..16), entry 0 always 0, no
   non-zero entry past 11; each is read once; a rule's tables lie in the
   reverse of their order of use, 8 of 548 rules otherwise (the clause
   writes their places).  The rule file writes each table's contents
   inline where it is used.  The input probably described instructions
   (sizes, memory references, delays) and the generator built the
   tables from them (iscg-design 2.6), so the contents should derive
   from instruction descriptions we have not recovered.  Worth decoding
   (the values are few: code_bytes 0/4/8/12/16..., memory_references
   and delay 0..3), or are inline tables enough?
297. Translator GE: **the cost tables past 32 KB (module 02).**  Rev
   8.89 laid rule 170's tables up to +0x7F78, put rule 171's first two
   byte tables in the room below 32 KB (+0x7FA0, +0x7FB8), and the rest
   of rule 170's from +0x7FCC (not 8-aligned), read through an absolute
   base (`movea.l #0x45732C,A0', A5 + 0x7FCC).  The generator lays the
   tables in rule order on 8 bytes, so module 02's data differ past
   +0x7FA0 (a cc_datacheck_known.txt entry; every byte is present).
   Module 24 (56 KB, not generated: one residue rule) will meet the same.
   Should the generator learn Rev 8.89's near/far allocation (it needs
   the rule of which variables go far), or the rule file carry module
   offsets for those tables?
298. Translator GE: **the action's frame.**  Every pass-1 action links
   -32 or more (349 of 563 exactly -32) though most use no frame
   temporary: the original declared locals (eight longwords?) in every
   action, or the skeleton had a fixed frame.  dpc links what the body
   needs (best effort).  Known?
299. Translator GE: **rules 399 and 402.**  The image clears result and
   work, tests the subject's inherited immediate_parent_wants_lvalue
   (btst #5 of +39) and returns: no branch, no trace (the only two
   actions without one), no solution.  Read as a condition whose arm
   Rev 8.89 removed (a constant false conjunct?).  The rule file writes
   them by hand as `hand dropped' clauses with the test's sense guessed
   from rule 397 (`not ...'); the modules write the test with an empty
   arm (dpc refuses an `if' with a constant condition).  Better reading?
300. Translator GE: **the 5 pass-1 residue actions.**  Rules 9 and 10
   compare the node's double at +12 with zero through the FPP emulation
   (`pea (12,A1); jsr fpp_$...' with inline operand words: a real
   comparison, dpc gap 7's ground); rule 20 reads a longword of
   target_properties at +0x9C (inside target_properties.ins.pas's p_94:
   name it?); rule 211 tests a value joined from two arms after a call
   (the lifter loses the flags); rule 177 tests a bit given by a register
   (btst Dn,(81,A0)).  They keep sections 07, 12, 23, 24 from being
   generated.  A real-valued node field in the language (and a gap-7
   rewrite) for 9 and 10, a name for target_properties +0x9C?
301. Translator GF, the pass-1 actions (docs/iscg-design.md 10.8):
   **Rev 8.89's near/far allocation of module data.**  Question 297's
   layout is reproduced, table for table, in both modules that pass
   32 KB (02 and 24, 2990 tables) by: lay the tables out in order,
   each on 8 bytes; a table stays near while its start plus three times
   its 8-rounded size (24, 40) is within 32 KB; the rest follow, in
   order, from the near tables' end rounded to 4, each on 8 bytes from
   there.  tools/iscg_p1gen.py's place_tables does this (module 02's
   cc_datacheck_known.txt entry is gone).  The data do not tell this
   form from `start + 4 x the unrounded size' (17, 34); each reaches the
   limit exactly once in module 02 (rule 171's second byte table at
   +0x7FB8, rule 170's word table at +0x7F78), and factors 2 or 5 fail.  Is the compiler's real rule known (a reserve
   for later small variables?), and does it apply to other big modules
   (spos.pas, pattern 20)?
302. Translator GF: **rules 9 and 10 by hand.**  They test or convert
   the node's double through the FPP emulation (0x0074 0xFF34 then
   `seq', read as a comparison with zero; 0x0074 0x00D4 0xFF3E, the
   double stored as a single and its bits read).  The rule file writes
   `result.literal_64_bits_value_is_zero <- subject.il.real_value =
   0.0' and `temp f: single; f.value <- subject.il.real_value; ...
   f.bits'; the selector real_value (il.ins.pas's) and the temp type
   `single' (a view p1_single_t) are ours.  (0xFF34 is `= 0.0' as in
   final.pas floatop, 0x00D4 0xFF3E the conversion as in lst.pas:
   docs/dpc-gaps.md 7.)  Should the language name a real constant's
   value otherwise (question 287), or the statement language have real
   expressions so the lifter could follow fpp_$?
303. Translator GF: **target_properties +0x9C.**  Named p_9c in
   target_properties.ins.pas (split from p_94): rule 20 adds it to an
   argument block location's offset; the four entries hold -1, 16, 16,
   16 (read at 0x2B6800 + 328k + 0x9C).  Nothing else reads it.  A
   better name (the argument block's displacement bias)?
304. Translator GF: **pure functions written at each use, and called
   before the first test.**  The lifter writes a function's value where
   it is used, so `if number_of_rightmost_zeroes(x) > 3 then t <- 3
   else t <- number_of_rightmost_zeroes(x)' calls it twice where the
   image calls once (rule 20 and nine earlier clauses); and a call
   whose value a condition's later conjunct uses becomes a temp set
   before the `condition' (rules 177, 211: lir_$can_encode_as_
   immediate_postincrement, called by the image only after the il.w52
   tests pass).  Both are harmless for pure functions.  Should the
   lifter keep the image's call count and order (a temp, a second
   `condition')?
305. Translator PX: **R23 survives calls.**  call_conv's ordinary
   preset counts R23 among the registers a call clobbers (0x00C003FF),
   but in the SR10.4 binaries R23 is the stack pointer, popped back by
   every return's slot (LOAD_PAIR [R23],R23,R10) and read right after
   6,101 calls without a write (docs/prism-isa.md, "Validated against
   SR10.4 binaries").  Does "clobbered" there mean "used by the call
   sequence" (the callee pushes and pops it), or is the set misread?
306. Translator PX: **.unwind's fourth word, bits 16..0.**  Bits
   31..27, 26..22, 21..17 are the registers at the frame's +4, +12 and
   the return address's (agreeing with all 2,483 prologues), the third
   word's bits 29..20 the saved R21..R12; the low bits (FreeTOC, a
   56-byte frame: 0x8490; ReadTOC, 2,408 bytes: 0x0708; CheckStatus,
   48: 0x8390; reverse, 40: 0x8290; my_itoa, no frame: 0x8100) are not
   decoded.  Which unit of cc.a88k writes .unwind (bin_$unwind_bits?),
   and is the frame size there?
307. Translator PX: **the condition codes are read one instruction
   late.**  16,506 of 19,255 conditional branches have their setter two
   words before them and none just before; CMP a; CMP b; Bcc; Bcc tests
   a then b.  The opcodes BNL2V, BL2V, BNL2, BL2, BNZ3, BZ3 (templates
   0x27xx/0x2Fxx) never occur in the binaries: do the 2 and 3 name a
   different distance (the condition codes two or three instructions
   back), so that sched's and xtp's rules could be read against them?
308. Translator PX: **1FFF0000 and 1FFF0001.**  19 executed words,
   CMP #0/#-1,R31 (= MOVE.CC #0/#1,R31 = ADD.CC #0/#1,R31,R31), stand
   between a condition-code setter and the branch that tests it
   (install 0x983E4: EXTRACTU.CC; 1FFF0001; BNE.SF).  The SR10.4
   compilers' form of an IPCCNOP (asm 6.9 encodes it as NOP), or
   something else?
309. Translator PX: **.blocks version 3.**  Several a88k binaries
   (ld, ksh, net_*, the crt0 objects) have units `01 00 01 03', which
   coff_compare.py's reader refuses; prism_dis.py takes their routines
   from .unwind instead.  Worth teaching the reader version 3 (names of
   static routines would come with it)?
310. Translator PX: **squash comments.**  The delay-slot modes name when
   the slot runs (.SN never, .ST taken, .SF falling through, .SA
   always; +3 bit 7 runs it on the fall-through, bit 6 on the
   transfer), the reverse of "squashes"; asm.pas's and lst.pas's code
   only copy the mode, but comments in asm.pas (pass 1's "squashing on
   bit 6"), dbg_life.pas ("its delay slot squashed on sequential
   flow"), dmp.pas and backend.ins.pas use the squash reading.  Should
   their owners reword them (no code change)?
   **Lead (2026-11-12):** done: the comments in asm.pas, dbg_life.pas,
   dmp.pas and backend.ins.pas now say when the delay slot runs (no code
   change).
311. Translator RN3: **lr_t's register fields.**  lir_$build_operand's
   dump (lir.pas, gap 4) compares a solution's physical_register,
   physical_register_is_no_modify, physical_register_user_declared and
   physical_register_number with its live range's under the heading
   `sol^.live_range^.' and the same names (question 250): lr_t's f2.reg
   (+2), f2.physical, f2.no_modify and f2.serialize (+3 bits 7, 6, 5)
   are the original's physical_register_number, physical_register,
   physical_register_is_no_modify and physical_register_user_declared.
   lr_t is batch A's and read by most of the back end; rename it too?
   **Done (RN2, 2026-11-12, the owner's ruling: Apollo's names
   everywhere):** lr_t's f2 keeps its layout and takes the four names;
   every user in 24 units follows, and the allocator's and SCHED's
   views (ra_lr_t, whose +3 bit 7 was `assigned', and sc_lr_t) take
   the same names.  dpc's assembly is unchanged.
312. Translator RN3: **isc_solution_t's types.**  The rename kept the
   types: base_register and index_register lr_ptr_t (they hold
   solutions: question 262), false_label integer32 (isc_debug prints it
   with label_to_string: a label pointer), il_kind and kind integer
   (il$t's and solution$t's ordinals: question 250).  Retype them
   (isc_debug's ds_solution_t would then be the same record but for the
   rules' locals, and could go)?
   **Done (RN2, 2026-11-12):** isc_solution_t's base_register and
   index_register are isc_solution_ptr_t (and the four CSE accessors
   pass_2_cse_{parent,use}_{base,index}_reg return one), false_label
   univ_ptr (the LIR's labels have no type of their own: lir_$new_label
   returns univ_ptr, label_to_string takes one), il_kind il$t
   (isc_enumeration.ins.pas, opened before the insert in every unit;
   il$t is not il_$kind_t: question 314) and kind solution$t.  The
   generator (iscg_p2lang's field classes, iscg_gen's matcher,
   iscg_text's fixed text) writes the elements' names where the rule file
   has numbers and drops the casts; the rule file is unchanged and
   re-extraction reproduces it.  The hand-written ISC units name the
   kinds (case labels, compares) and keep new_solution's integer
   parameters (cast there).  dpc's code is unchanged but for three
   `write' of a kind (isc_to_lir's guarantee_has_live_range,
   isc_user_routines' local_initialize_symbol and
   isc_$is_a_register_candidate): without the cast dpc passes the
   field's address as the image does (`pea (108,An)', cc.a88k
   0x208944, 0x20E358, 0x2132F6) instead of a copy's.  solution_t
   (backend.ins.pas: the LIR's view) keeps its integer kind and
   registers (solution$t is not visible there).  ds_solution_t stays:
   it still differs in the words it prints unsigned (bytes ..
   n_bytes_to_back_up, evaluation_order, which_transform), +86, and
   its pointer types (see its comment).
313. Translator RN3: **the rules' locals in isc_solution_t.**
   dump_solution prints case_value (+136) and already_address_mode ..
   already_processor_reg (+342..+348) as attributes;
   isc_solution_t leaves them in space136 (the generated pass 1 reads
   the already_ flags through its view p1_already_t, case_value through
   space136), ds_solution_t names them.  Declare them in the insert
   (case_value's type, isc_case_index_array_t, is in
   isc_routine_externs.ins.pas, which is opened after it)?
   **Done (RN2, 2026-11-12):** isc_solution_t declares case_value
   (+136, isc_case_index_array_t), already_address_mode ..
   already_processor_reg (+342 .. +348) and x349; space136 is gone.
   isc_case_index_array_t moved to isc_solution_fields.ins.pas (a
   non-pointer type cannot be declared forward, and every unit that
   opens isc_routine_externs.ins.pas opens it first); its printer's
   heading stays, with a comment pointing there.  The type is now a
   packed array: dpc gives an element of an unpacked `array of 0..255'
   a word, so the record grew to 640 bytes (the flags at +548).
   isc_debug's ds_solution_t, which used the same type and an `array
   [349..351] of char' (after which dpc puts the next field at +354),
   had both slips of ours, unseen because gap 4's rule removes
   dump_solution's writes; it now lays out as the image (x349 a char,
   x350 a word, as isc_solution_t).  The generator reads a
   rule's byte local cN as case_value[N] (a byte number where it was a
   char: the chr() and ord() go) and cN for N in 342..348 as the flag
   of its name; pass 1's view p1_already_t is retired.  dpc's code is
   unchanged and the rule file is reproduced by re-extraction.
   ds_solution_t is not folded in: it still differs from isc_solution_t
   in the words it prints unsigned (0..65535 for isc_solution_t's
   integers: bytes .. n_bytes_to_back_up, evaluation_order,
   which_transform), +86 as one word, and its pointer types.
314. Translator RN1 (2026-11-12), the IL node kinds (question 78):
   **il.ins.pas's il_$kind_t and the ISC's il$t.**  il_$kind_t is the
   237-name table after add_node_$dispose_top_level, in order (0 end_ob
   .. 104 signed_cob the tokens, 105 program_blk .. 236 union_ob).  il$t
   (isc_enumeration.ins.pas, 178 names) is not a subset numbering: it is
   the ISC generator's own classification, il_none, then 64 of the kinds
   (with il_ before the name) and il_isc_fio_init (no kind of that name),
   each assignment and tree node kind followed by its operators (111
   _aop and _top names), il$k_max last; alphabetical but for the
   signed/unsigned pairs (il_binteger_ob before il_ubinteger_ob,
   il_integer_ob before il_uinteger_ob, ...).  Its kinds: 15 tokens
   (the constants' kinds, 77 blogical_ob .. 200 binteger_ob) and nodes
   from 105 to 229.  isc_user_routines' il_kind_function maps a node to
   its il$t.  Not known from the original: il_$kind_t's name (the run
   time's table has only the elements).
315. Translator RN1: **an ordering compare of kinds is unsigned in the
   image.**  dpc compares an enumeration unsigned (scs, shi, bls) and an
   integer signed (slt, sgt, ble); the code is otherwise the same for
   `=', `<>', `in', `case' and assignment.  prtobj_$prtobj_full's
   `kind <= 76' is `cmpi.w #76,D2; bls' in the image (cc.m68k 0x0AF5C6),
   so its kind local is now an il_$kind_t (`kind <= id_ob', dpc's sls
   where it had sle): evidence that the original's kinds were the
   enumeration.  No other ordering compare of a kind was found
   (cg_addr's `kind > 0' tests are of other records).  (Lead, at the
   merge: two more, in regions a gap rewrite removed until dpc fixed
   gaps 4, 7 and 25: kfold_$general's and add_tn's `if k2 > k1' are
   `bls' in the image (cc.m68k 0x0ADF7A, 0x0A2B4A), and dpc now gives
   `bls' from the il_$kind_t operands; more evidence for the same
   answer.)
316. Translator RN1: **ord() of a kind into a longword.**  dpc extends
   ord(e) of an il_$kind_t with ext.l; lang/common/source/token.pas
   token_$identifier passes the kind on as a longword after `clr.l'
   (token.low.pas's kind is 0..65535 for that reason).  So token.low.pas
   keeps the 0..65535 field and token.pas compares its kinds as numbers;
   it has a copy of il_$kind_t (the unit does not open il.ins.pas) for
   the kinds it passes to smcontk and idntk.  Elsewhere a kind stored
   into an integer is written ord(...) where the code is the same
   (exs, list_tree's print_integer, isc_user_routines'
   get_uparrow_dot_kind and il_kind_function, prtobj's w).  Kinds left
   integers: opt_vector's k (one local is also a byte field's value),
   c_main rword_init's loop over the classes (it indexes lex_tokens;
   idntk(il_$kind_t(k), ...)), the ISC's possibly_make_expression_
   temporary skind and tkind (122..124, as isc_lir's heading has them),
   the generated p1_kind table's indices, and oli's mval kinds (1..3,
   not IL kinds; oli_mval_t's kind is an integer again).  Is Rev 8.89's
   ord() of an enumeration zero-extended (a dpc difference to log as a
   gap), or did token.pas read the kind some other way?
317. Translator RN1: **the C front end's token classes are kinds.**
   c_globals' ctk_* (0 `}' .. 75, 76 identifier, 81/82/85 constants,
   92/93 strings) are the Pascal front end's token kinds reused: 0
   end_ob for the closing brace, 50 bus_ob and 60 sub_ob for the
   brackets, 49 up_to_ob for `..', the keyword slots for C's keywords (6
   with_ob is `enum', 16 array_ob `union', 17 record_ob `struct', 31
   label_ob the `...' of a prototype's parameter list).  The parser keeps
   a class in integers (token_kind, lex_tokens[...], its follow sets),
   so ctk_* stay integer constants, and c_objtype's c_tag_t and
   c_kw_node_t keep an integer kind; where a token node's kind meets a
   ctk_ constant the front end writes the kind's name
   (char_string_ob, char32_string_ob) or ord(...).  debug_sym_dmp's
   `with_ob, array_ob, record_ob' arm is a C tag's kind (enum, union,
   struct).  Would the original have declared the C classes as the
   enumeration's constants (ctk_enum = with_ob), with the follow sets as
   sets of the enumeration?  The sets would be 30 bytes instead of the
   image's sizes, so not without evidence.
318. Translator RN1: **names taken for the enumeration.**  c_globals'
   cells char_type and void_type are char_ptype and void_ptype (kinds
   125 CHAR_TYPE and 210 VOID_TYPE; question 78's proposal); unix_objmod's
   data_section cell is data_section_node; the section at_lib_dsc is
   declared `var (at_lib_dsc) at_lib_dsc_bytes' as std_lib and
   mem_$data$ are (AT_LIB_DSC is kind 208): every unit that opens
   at_lib_dsc.ins.pas now has the section as a .comm, as the other
   shared sections do.  Better names when the front end's are found?
319. Translator RN2 (2026-11-12), after 312: **the kind parameters and
   results that stay integers.**  new_solution takes its kind and
   il_kind as integers (a word each, at 12 and 24): the generated pass
   1 passes `ord(solution$...)', isc_pass_1_main's operator routines
   an integer local il_kind set from `ord(il_...)', and new_solution
   casts both into the record.  solution_kind_of_cse,
   solution_kind_of_symbol and get_kind_of_home_solution return a
   kind as an integer (`ord(s^.kind)'), and isc_tool_generated_
   readonly_tables' result_kind table holds integers.  The words would
   be the same as solution$t and il$t; retype the headings (and the
   generator's calls) to the enumerations?
   **Done (RN6, 2026-11-12):** new_solution takes kind: solution$t and
   il_kind: il$t; solution_kind_of_cse, solution_kind_of_symbol and
   get_kind_of_home_solution return a solution$t (solution$none where
   they gave 0); result_kind is an array of solution$t; the operator
   routines' var il_kind (p1_operator_t), pass_1's local and
   cross_product_to_solutions_of_parent's parameter are il$t.  The
   generator writes the names (solution$ip_reg, il_add_to_aop, il_none
   for the 0 every action passes) without ord(), and a pass-1 action's
   compare of a kind function's result with a number is the element's
   name (iscg_p2lang's coerce, from the heading's class); the
   hand-written callers (isc_main, isc_to_lir, isc_user_routines) name
   theirs too (il_integer_ob, il_real_ob, il_dpreal_ob, il_var_name for
   78, 93, 70, 176).  dpc's code is unchanged in all 277 objects
   (pass_1's `move.l #16#160002' too: dpc still pushes kind and
   nchildren as one longword), the rule file is unchanged and
   re-extraction reproduces it.  il_kind_function still returns an
   integer: it gives the node's il_$kind_t (ord(node^.kind)), not an
   il$t, and pass 1 compares it with 117 (label_name).
320. Translator RN2: **backend.ins.pas's solution_t keeps integers.**
   The LIR's view of the solution (solution_t) has kind an integer
   (+108), base_register, index_register and false_label integer32:
   solution$t is declared in isc_solution_fields.ins.pas, which units
   that read solution_t without the ISC (sym, lir_utils' callers) do
   not open.  Move solution$t (and il$t?) into backend.ins.pas so both
   views share the types, or keep the LIR's view numeric?
   (Lead, 2026-11-12: keep the LIR's view numeric.  Each unit's
   include list is the original's, taken from the binary, and the
   units that read solution_t without the ISC's inserts could not have
   seen solution$t either; moving the type would invent an insert
   layout the binaries do not show.)
321. Translator RN2: **signed or unsigned words in the solution.**
   isc_solution_t's bytes .. n_bytes_to_back_up, evaluation_order and
   which_transform are integer, ds_solution_t's 0..65535 (dump_solution
   writes them zero-extended).  Which was the original's type?  With
   one answer ds_solution_t could be folded into isc_solution_t (its
   remaining differences, +86 as a word and its pointer types, are
   views).
   **Done (RN6, 2026-11-12): unsigned, but for which_transform.**  The
   image's ISC (cc.a88k 0x0B9F24 .. 0x21DC44) loads these words into a
   data register 690 times and never sign-extends one; the evidence:
   (a) the register maxima and results are compared unsigned, as the
   unsigned code_bytes, delay and memory_references beside them:
   clearly_dominates `cmp.w; bhi' for +64, +62, +60, +58, +70, +72
   (0x2126D8 .. 0x212712), and the pass-1 actions' max idiom (`t2 <-
   $1.fp_reg_max; t2 = $2.fp_reg_max; t2 u<= $2.fp_reg_max' in the
   rule file, 144 times) `cmp.w; bhi' (rule 306 0x107BB4, rule 64
   0x0F115A; ip_reg_max 110 such compares, fp_reg_max 18,
   fp_reg_pair_max 13, fp_reg_quad_max 9), no signed branch on any of
   them; (b) n_bytes_to_back_up is zero-extended for `* 8' (`clr.l D0;
   move.w (74,A2),D0; lsl.l #3': rules 248 and 250, 0x14E80E,
   0x14E8DC, 0x14EE48); (c) pass_2 writes evaluation_order as an
   unsigned word (16#0A28, 0x18C70C), and dump_solution writes all of
   bytes .. n_bytes_to_back_up, evaluation_order and which_transform
   with 16#0A68 (0..65535, as code_bytes; 0x0D67B2 .. 0x0D7BA8).
   bytes and fp_reg_quad_result are only copied and printed (no compare
   or widening): typed with their neighbours.  which_transform is the
   exception: pass_2 indexes the pass-2 actions by it with `move.w
   (112,A2),D2; ...; ext.l D0; lsl.l #2' (0x18C770 .. 0x18C786) and
   preserve_solution with a word index (`tst.b (-1,A5,D0.w)', 0x0D9530),
   a signed integer's code (an unsigned word is widened `clr.l; move.w'
   by Rev 8.89: (b), list_tree 0x080572), against dump_solution's
   unsigned print: mixed, so it stays integer.  isc_solution_t's bytes
   .. n_bytes_to_back_up and evaluation_order are 0..65535 now; the
   generator's classes follow (iscg_p2lang SOL_FIELDS u16) and a
   rule's integer temporaries that only take those words (the max
   idiom's t2, t3 ...) are declared 0..65535 (iscg_p2lang.word_temps:
   the rule file gives only `integer', the width).  dpc's code changes
   in 13 units, each toward the image: 144 `bgt' to `bhi' (the max
   idiom), clearly_dominates' six `sle' to `sls', six `ext.l' to `clr.l'
   for n_bytes_to_back_up * 8 (isc_pass_1_15), pass_2's write 16#0A20
   to 16#0A28 (as 0x18C70C), and ten `ext.l' to `clr.l' widening a
   word temporary into a longword temporary the lifter keeps but no
   code reads (rule 64's t6 and its like in isc_pass_1_01: no image
   counterpart).  The rule file is unchanged and re-extraction
   reproduces it.  ds_solution_t is not folded in: it still differs in
   which_transform (0..65535 there), +86 and its pointer types.
322. Translator RN4 (2026-11-12), the dumps' names (question 92):
   **the identifiers are the run time's, not list_tree's strings, where
   the image has a name table.**  cc.a88k's ISC printers write the tree
   and assignment operators, a variable's and a block's allocation as
   enumerated values (PAS_$WRITE), and the run time's tables give the
   identifiers (tools/cc_enumnames.py: 90 names after isc_print_il_node
   0x0C69A4, isc_unrecognized_il_node 0x0DC290, alignment_from_sr_info
   0x20FD9A ...: nop_top .. illegal_top; 38 at 0x0BE472, 0x0DC7B0:
   scalar_aop .. illegal_aop; 12 at 0x0C7A7C: local_vat ..; 4 at
   0x0C8500: local_bat ..).  list_tree prints most operators without the
   suffix ('ADD'), some in forms of its own ('LSHFT' for lshf_top,
   'AGG_CMP' for agg_compare_top, 'p_C3EXPR' for cc_c3expr_ptop,
   'ALLOC_DYNM' for allocate_dynamic_space_top); its fallbacks print
   '<ORD(TOP)=' and 'ORD(AOP)=', the types' or fields' names perhaps
   (TOP, AOP).  il.ins.pas names the types il_$top_t, il_$aop_t,
   il_$vat_t, il_$bat_t (the names not known).  isc_print_il_node's
   other tables (the Fortran symbol kinds and data classes, the address
   constants' keys: isc_debug's pin_fsym_kind_t, pin_fdtype_t, pin_ac_t)
   stay local: their names (none, routine, variable, common) would
   clash in the prelude.
323. Translator RN4: **names chosen where the dump's are display
   forms.**  The register classes are constants rlen_null .. rlen_c16
   (0, 1, 2, 4 .. 12; the dump's 'byte', 'word', 'long' would clash),
   the condition codes cond_t .. cond_le ('T', 'HI', ...), the math
   functions math_abs .. math_ff_expon ('ABS': Pascal's own names), the
   phase bits phase_atm .. phase_lcl_cse (the bare cse is opt_cse's
   routine; invar and phys are back-end locals).  The calling
   conventions keep the dump's names (call_unk .. call_ada).  Constants,
   not enumerations, where the units keep the value in integer words,
   index tables by it or compare it as a number (rlen, the condition
   codes, the math functions, the calling conventions); enumerations
   where the code treats the value as one (the operators: `case', sets,
   the ISC's enumerated writes) and sets of them (the variable
   attributes, the phase bits: 32 and 24 elements, a longword as set of
   0..31 is).  Better prefixes, or Apollo's, if a listing turns up?
324. Translator RN4: **phase bit 23 has no name.**  The ISC's rewrite
   (rewrite.pas) adds bit 23 to a node's phase; prtphasebits prints bits
   0..22 only, and isc_user_routines' own printer (its display forms:
   'atomic_address', 'voladdr', 'volexpr', 'devread', 'devwrite',
   'visited', 'iscse', ..., 'local_cse') has none for it either.
   add_node_$phase_bit_t ends with a placeholder phase_23.  Also: the
   variable attributes were typed as phases in add_node (phasefromvatt's
   parameter, its at_20 .. at_36) and delay (vattr): phasefromvatt maps
   attributes to phases (var_$volatile to phase_vol and phase_voldecl,
   var_$atomic to phase_atm, var_$physical to phase_phys, ...), so those
   are il_$var_attrs_t now.
325. Translator RN4: **dpc gap 48** (docs/dpc-gaps.md 48: `in' on a
   longword constant set with an enumerated element; list_tree's
   print_top_node, rewritten for the check): for the domain-pascal
   session.
326. Translator RN4: **what question 92 leaves.**  (a) A block's
   attributes (+374..+379: local_name_only .. visited_set_local_call_
   bits), the label classes (+72 bits 5..1) and a statement's flags
   (+41..+42) are bit fields the units read by mask through the offset
   views (xw, xc, xl): naming them needs record views of the block and
   statement nodes, a re-layout rather than a renaming.  (b) The
   operators, register classes and attributes read through the offset
   views (xw[18], xw[12], xl[8] masks) are still numbers; il_utils'
   tree_node_operand_is_spine call casts xw[18].  (c) opt_vector's tree
   view keeps its phase at +4 as set of 0..31.  (d) The ISC's pass-1
   actions read the operand modifiers (+26, +28: a class or a math
   function, by operator) as numbers.  (e) The condition codes and math
   functions are named only in list_tree; the code generator's uses
   (emit's x, reverse_cc, tree_fn_inst) are numbers.
   **(d) done (RN6, 2026-11-12):** the generator names a number compared
   with a tree's opmod1 or opmod2 (subject.il.w26, w28, or a child's
   whose operator the pattern names) when list_tree's print_tree_exp
   gives that opmod one use for every operator the pattern allows
   there: a register class (rlen_byte .. rlen_c16: the extends, shifts,
   multiplications and divisions, compares' opmod1, F_EXTEND, F_MATH's
   opmod2) or F_MATH's function (math_nint .. math_aimag)
   (iscg_p2lang.opmod_operand; the rule file keeps the numbers); the
   fixed text names F_MATH's in-line functions and the rlen_long of the
   div/mod/isc_mul rewrites.  Left numbers: a comparison's condition at
   +28 (the ISC tests it `< 0' and indexes by `24 + abs(...)': a signed
   number to the ISC), bit_test's (`$1.il.w28 <> 6' under rshf_top),
   field widths (unpack, extract_bit_field), bytes, EXTEND's opmod2
   (0, 1: no use in list_tree), and an assignment's class at +52.
   **(e) done (RN6):** the code generator names the condition codes
   (cond_t .. cond_le) where they are emit's x for the conditional
   operations (19 scc, 20 bcc, 28 dbcc, 42 the 68881's fbcc, 48 its
   fscc: opinfo's lists whose kinds 18, 19, 23, 39, 43 fnl_slct makes
   exact by x), the cc and inst locals that feed them (cg_top's
   cbranch_proc, cg_tree's bit_test_proc, f_compare_top, max/min,
   F_MATH's max/min), the comparisons' desc.w8 tests, fnl_slct's ranges
   and emit_compare's case (fpa); the math functions where desc.w6 is
   an F_MATH tree's function (cg_tree_$needs_lib_support,
   assert_is_f_math_op's callers, generate's F_MATH arm) and the
   literal indices of tree_fn_rtn (14 math_conjg, 15 math_aimag);
   tree_math, tree_fn_inst and tree_fn_rtn are indexed by
   math_abs..math_round / math_fi_expon.  Constants, not an
   enumeration: reverse_cc computes on the codes (odd, plus or minus
   1), cbranch_proc and bit_test_proc negate them and take abs, emit's
   x is a size or an operation for the other kinds, and the tables are
   indexed by the word as it is.  dpc's code is unchanged.  See the new
   question on what stays numeric.
327. Translator RN4: **the assembly comparison** (every unit compiled as
   the gate compiles it, main 3679840 against the branch, dpc acea73f:
   274 of 277 objects identical).  opt_main's
   coalesce_adjacent_and_eliminate_dead_assignments tests `asg_op <=
   isc_agg_aop' with sls where it had sle: the image's test is unsigned
   (`moveq #31,D2; cmp.w D1,D2; bcs', cc.m68k 0x0DD0EA).  The generated
   isc_pass_1_main's isc_unrecognized_il_node writes the operator fields
   by address (`pea (76,A2)', `pea (36,A2)') as the image does (cc.a88k
   0x0DB59A, 0x0DB5EE), and its arms share their tail.  list_tree's
   fallback prints of an operator zero-extend it (`clr.l; move.w',
   0x080572, 0x083F02): written as a transfer to a word (lt_word_t), as
   ord() gives ext.l (question 316: more evidence that Rev 8.89's ord()
   of an enumeration, if the original wrote one, zero-extends).
