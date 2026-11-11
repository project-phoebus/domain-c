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
