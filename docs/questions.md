# Deferred questions for the owner

Decisions taken conservatively while working unattended; each can be
revisited.

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
157. Translator PB, lst.pas: the named sections' initializers.  lst
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
158. Translator PB, lst.pas: the -PRASM listing writes the integer
   registers as ".n" (`move.w #0x2E00' before the number), the singles
   ".FSn", the doubles ".FDn", and register 30 of kind ip_reg_like as
   ".PC" (classic "PC"); taken from the image as they are, though
   ".n" for a register looks odd (the PRISM assembler's syntax is not
   known here).
159. Translator PB, bin.pas: bin opens bug_check.ins.pas after
   coff_dst.ins.pas (its .blocks list), but backend.ins.pas, opened
   earlier, declares instr_bug_check and the phase_ routines with
   bug_check.ins.pas's types (bug_check_$string_t, bug_check_$arg_t), so
   dpc cannot compile the unit in that order; bin.pas opens bug_check
   before at_base.ins.pas.  Apollo's backend.ins.pas must have declared
   those headings without bug_check's types (or bin did not see them):
   should backend.ins.pas's three headings use types of their own
   (univ base types) so that the include order can be the image's?

