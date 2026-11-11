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
