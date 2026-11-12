# Pascal Rev 8.89 code generation (cc.m68k / cc.a88k) vs dpc

The DOMAIN C 6.9 binaries were built with Pascal compiler Rev 8.89 (68K and
PRISM=>68K builds).  dpc models SR10.2's Rev 7.x (the kernel image).  This
translation runs dpc in best-effort mode; this file collects the Rev 8.89
forms met, with evidence, for a later dpc "Rev 8.89" profile.  Addresses are
cc.m68k unless marked.

## Prologue and epilogue

1. **A5 in every global routine of a module with data.**  A routine not
   declared `internal` loads its module's A5 (`lea abs.l,A5`) whether or
   not it uses it; `internal` and nested routines do not (they run on the
   caller's A5).  Over cc.m68k's module-level routines: referenced from
   another unit and loading A5 644, not loading 8; not referenced from
   another unit and not loading 877, loading 248 (taken to be global
   routines nobody outside calls).  `get_rlen` 0x0532D8 (uses no data),
   every `std_$` routine (std's data are 4 bytes no routine reads).
   SR10.2/dpc: A5 only when the routine uses the module's data.
   Consequence for the translation: a module-level routine with no A5 load
   was declared `internal`.
2. **Saves: one push each up to three registers, `movem` from four.**
   `pea (A5)` / `pea (An)` / `move.l Dn,-(SP)`, in the order A5, A4..A2,
   D7..D2 (`def_incomplete_su` 0x45650 `pea (A5); pea (A2); move.l
   D2,-(SP)`; `std_$round_up_to_multiple_of` 0x07333C `pea (A5); move.l
   D3,-(SP); move.l D2,-(SP)`); four or more `movem.l` (`std_$in_range_*`
   `movem.l D2-D4/A5,-(SP)`, `std_$append_integer` `movem.l
   D2-D5/A2/A5,-(SP)`).  The restores mirror it: one `move.l (d,A6),Rn` /
   `movea.l (d,A6),An` each, or `movem.l (d,A6),...`.  The `lea abs.l,A5`
   follows the saves.  SR10.2/dpc: `pea (A5)` only when A5 is the only
   register; otherwise `movem`.
3. **The result slot.**  A function's `link` reserves 4 bytes for the
   result (`link #-4`) though the result stays in D0
   (`std_$in_range_*`, `get_rlen`); a procedure with no locals has `link
   #0`.

## Code

4. **Loop heads aligned to 4 with 0x2048** (`movea.l A0,A0`, Apollo's fill
   word): `std_$append_string` 0x073466, `std_$append_integer` 0x0734C2,
   `def_incomplete_su` 0x04566E.  Not a difference: SR10.2 does the same
   and dpc emits `.balignw 4,0x2048` before a loop head.
5. **Loop-invariant addresses hoisted.**  `std_$append_integer` computes
   `s.body[start]`'s address once (`lea (1,A1,D2.l),A2`, 0x0734B2) before
   the repeat loop and stores each digit through A2.
6. **Value parameters loaded up front.**  Every by-value parameter the
   routine reads is loaded into a register at entry, last parameter first
   (`std_$in_range_*`: (16,A6), (12,A6), (8,A6) to D2, D0, D1;
   `diag_$write` 0x06845A loads all eleven); dpc reads them where used.
7. **Compare operands.**  `lower <= value` is `cmp.l value,lower; sle`
   with both in registers (std); dpc compares against the frame slot.
8. **Argument areas padded to a multiple of 4.**  A call whose arguments
   take 6, 10 or 14 bytes first does `subq.l #2,SP` and pops the rounded
   size: `gspace` 0x07D4F2 calling gspace32... (`subq.l #2,SP; move.w
   #4,-(SP)`, `addq.w #4,SP`), gspace32's `cgerr_no_source(28, 0)`
   0x07D530 (`subq.l #2,SP; clr.l -(SP); move.w #28,-(SP)`, `addq.w
   #8,SP`), compare_bytes 0x0988B4.  SR10.2/dpc push only the arguments.

## Data layout

9. **Module-level byte variables packed.**  il.pas's data has four
   booleans at +0xC0..+0xC3 (each read as a byte by other units), then a
   word at +0xC4; dpc gives each boolean its own word, so every later
   global of the module lies 4 bytes higher in dpc's layout than in the
   image.  The layout is internal to the program, so best effort keeps
   separate variables; a dpc profile would pack them.  (The image also
   leaves +0x142..+0x143 unused, where dpc puts the next word.)
10. **Consecutive stores of one constant to packed fields merged.**
    Statements that store the same constant to fields of one byte, word
    or longword become one `andi` (false, 0) or `ori` (true), the mask
    the union of the fields, adjacent or not:
    cargs_$init_option_defaults (cc.m68k 0x0B4AA8 `andi.w #0xFFE0`
    clears +0x27B bits 4..0, five booleans; cc.a88k, whose default sets
    bit 3, has `bclr #4; bset #3; andi.w #0xFFF8`), 0x0B4ABE `andi.w
    #0xF17F` (+0x27C bits 3..1 and +0x27D bit 7, +0x27C bit 0 not
    stored), 0x0B4A94 `andi.l #0x7FF` (a 6-bit field and 15 booleans);
    parse_options -IMAP `ori.w #0x180` (map and imap), -ANSI `or.w`
    0x34, -NANSI `andi.w #0xFFEB` after a separate `bclr` and `bset` of
    the same word (the run breaks at a store of the other value).  The
    language reference (3.15.3 p. 3-57) documents the merging for whole
    objects (dpc `--merge-constant-stores`), not for packed fields.  dpc
    stores each field.
11. **Calls that pop 2 bytes fewer than they push** (observed, not
    explained): iosub_$init_all 0x0B58F8 pushes 44 bytes for
    cargs_$parse_command_line_options and pops 42 (`lea (42,SP),SP`);
    prtobj_$prtobj_full 0x0AFA04 pushes 20 for lib_$cv_dfp_out and pops
    18; outbin's call of add_proc_reloc pops 14 for a 16-byte frame.
    The frame's `unlk` restores SP, so the drift is harmless.
12. **Trampolines for nested routines passed as parameters.**  Where a
    nested routine is passed as a procedure parameter, the code builds
    `lea abs.l,A0; lea abs.l,A1; jmp abs.l` in the frame (move.w #0x41F9,
    #0x43F9, #0x4EF9 and the addresses) and calls cache_$clear through
    the transfer vector (debug_sym_dmp, reg_color_68k); no source-level
    call, so no unit declares cache_$clear.
## Prologue and epilogue (continued)

13. **An empty global procedure is a lone `rts`**: no `link`, no saves
    and no A5 load, though the module has data and other routines are
    called from outside (fe_cc_hooks_to_backend's dump_namelist 0x067378,
    which unix_objmod calls, and coproc_$suppress_warnings 0x06737A).
    The exception to 1; dpc emits the same `rts`.
14. **No frame for an internal routine without locals or calls.**
    c_macro_utl's end_of_text_chain 0x059C84 reads its parameter at
    (4,SP) and returns in A0 with no `link`; c_cond_read's
    push_current_state 0x0409C0 and pop_current_state 0x0409D2 (no
    parameters) are three instructions and `rts'.  An internal routine
    that calls (c_macro_utl's hash_value) or has locals gets a frame.

## Data layout (records)

15. **A character array after a byte field is not word-aligned.**
    c_macro_utl's macro record (4110 bytes from PAS_$NEW) has a byte
    at +12 and the 4096-character name at +13 (mu_$lookup_name 0x058F76
    `pea (13,A3)'); dpc aligns the array to +14.

16. **Leaf routines without a frame.**  mem.pas's internal
    pool_name_len (0x0690D4, 0x20 bytes) has no `link`/`unlk`: it reads
    its parameter as `movea.l (4,SP),A0`, keeps the count in D0 and
    ends in `rts`; it calls nothing and has no locals in memory.  The
    other routines met so far all `link` (a function with `link #-4`
    for its result slot, item 3).  dpc always links.
17. **A for loop of 32-bit count as `dbf` plus a borrow from the high
    word** (`dbf Dn,top; clr.w Dn; subq.l #1,Dn; bcc top`):
    htm_$create_table 0x06894C, mrh allocate_new_chunk 0x087874.
    Not a difference: dpc emits the same form.
18. **Unsigned compares of lengths and sizes.**  A longword parameter
    compared `bls`/`bcs`/`bcc` (token_$char_string 0x07379A `cmpi.l
    #4096; bls`, ass_$initialise 0x0674AA, htm_$increment_table_entries
    0x0689EE) is a non-negative subrange (base's linteger,
    0..2147483647); a word zero-extended before use (`clr.l; move.w`)
    is 0..65535.  dpc compiles such types the same way, so the
    translation declares them so (not a code-generation difference).

## Real arithmetic

19. **The FPP emulator inline.**  Real arithmetic and conversions are a
    `jsr fpp_$' (through the transfer vector) after the operands'
    addresses are pushed, followed by inline 16-bit operation words
    (and immediate constants) that fpp_$ interprets and skips; it pops
    its operands itself.  token.pas get_reciprocal 0x098E48 (`r := 1.0
    / t^.real_value'): `pea r; pea (12,A2); jsr fpp_$', then 0x0078,
    the double 1.0 (0x3FF00000 00000000), 0x00A4, 0x0080;
    token_$make_real_lit_pair 0x098F2E (a double to a single): `pea
    temp; pea a; jsr fpp_$', then 0x0074, 0x00D4, 0xFF3E.  Comparisons
    leave the condition codes for a following Bcc (0x0074 0x00B4 then
    `bne', `beq', ...; 0x00B8 compares with an immediate double).  The
    most frequent sequences in cc.m68k: 0x0074 0x00B8 <double> (5),
    0x0078 <double> 0x00A4 (3).  The operation words are not decoded
    further here.  Write the arithmetic (`/', assignment); dpc has no
    real arithmetic yet (docs/dpc-gaps.md 2).

## Data layout (large module variables)

20. **A module variable whose extent passes 32K addressed absolutely.**
    spos.pas's regions' database (108044 bytes from A5+0x2F04, cc.m68k
    0x14E778) is reached by its absolute address everywhere, even its
    first words (`move.w 0x14E778,D2', `cmp.l 0x14E77A,D2', `movea.l
    #0x14E778,A0' as the base of the indexed regions; spos_$start_
    include_file 0x071F0E `move.l (12020,A5),0x14E794'), while the
    module's smaller cells around it stay A5-relative.  dpc refuses a
    static variable beyond 32K into the data area; spos.pas declares the
    database after the module's other cells so that dpc can address it
    from A5.
21. **An array of records after a word and a longword starts at +8.**
    In the same database the regions (36-byte records holding
    longwords) follow a word (+0) and a longword (+2) at +8 (+6..+7 not
    used); dpc puts them at +6.  Taken as a record of three fields; the
    image's alignment rule for the array is not known.

## Code (continued)

22. **Unsigned division and remainder for non-negative types.**  `div`,
    `mod` and the multiplication after them call the unsigned helpers
    when the operands' types are non-negative subranges: objio.pas
    obj_$put 0x088CF6 and obj_$get (`(offset div page_size) *
    page_size' of linteger offsets: M$DIU$LLL, M$MIU$LLL), obj_$open_r
    and obj_$open_r_tag 0x089C30 (`(n - 1) mod 100' of a pinteger:
    M$OIU$WLW, then `andi.l #0xFFFF').  SR10.2 (and dpc) call the signed
    ones (M$DIS$LLL, M$OIS$WLW).
23. **Identical tails shared.**  Two branches that end in the same
    statements jump to one copy: objio.pas obj_$open_t 0x089974 (`bmi'
    and `bra' into the other branch's ios_$change_path_name and
    obj_$open, 0x089A3C), obj_$put 0x088D98 (the refs and
    obj_$remove_free of two cases).  dpc compiles each branch's own.
24. **A register known to hold a constant passed for it.**  obj_$put
    0x088D74 pushes `move.b D2' (searching, set true at entry and not
    changed on that path) for map_portion's constant `true'.
## Nested routines

25. **The parent's frame through the dynamic link.**  A nested routine
    that only its parent calls takes the parent's frame from its own
    saved A6 (`movea.l (A6),A2' after the `link') and its caller loads
    no static link: c_sym_map's print_block (0x05FB4A; sym_map's call
    0x0605C0 is `pea (A2); bsr.w') and print_addr_cons (0x0601BE),
    c_macro_read's just_get_the_next_line_please (0x0574CC) and the
    four routines nested in mr_$get_expanded_line (0x058034..0x0581E4).
    A nested routine its siblings call too gets the static link in A1
    (`movea.l A6,A1' or `movea.l A2,A1' before each `bsr'; c_sym_map's
    print_10, print_type).  tools/cc_params.py marks the first kind
    `nested'.  dpc passes the static link in A1 to every nested
    routine.
## Nested routines and literals (translator F, cargs.pas)

26. **The static link.**  A nested routine called only from its parent
    takes the parent's frame from its dynamic link (`movea.l (A6),A2':
    cargs.pas match 0x0B2788, arg_option_parameter_numeric 0x0B2854,
    parse_opt_on_or_off 0x0B29B6); one called from several depths gets
    it in A1 (`movea.l A6,A1; bsr' at each parent call,
    arg_option_parameter 0x0B27AC, called from parse_options and three
    of its nested routines; fill_array_with_args passes the parent's
    frame on).  dpc passes the static link its own way.
27. **String literals sharing a tail.**  cargs.pas build_my_version_string
    passes 'C compiler' (no terminator: its length is passed) at
    0x0B49DE and '(%JUWD)%$' at 0x0B49E8, laid out end to end; 'Illegal
    or missing parameter to "%UA" option.%$' (0x0B2824) is one copy for
    the whole unit, and option patterns are reused across routines.
28. **A by-address constant in a frame word.**  build_my_version_string
    stores 10 in a frame word (`move.w #10,(-10,A6)') to pass it by
    address, while 6 and 9 come from the literal pool as longwords
    (0x0B4A10, 0x0B4A14); gspace_$close's nil is likewise a frame
    temporary.  Which constants go where is not known.
29. **`a or b or c` of calls evaluated whole.**  parse_options
    (0x0B3BDC: match('-NPEB.') or match('-CPUANY.') or ...) or-s the
    results in a frame byte (`move.b D0,(-54,A6); ... or.b (-54,A6),D0')
    and branches once; cc.a88k's -VENDOR/-PRASM (0x0B794A) branches
    after the first (`bmi').
## Constants (translator I, iosub.pas)

30. **By-address constants pooled across a unit's routines.**  A
    constant passed by address is one word or longword after some
    routine, and other routines of the unit point at the same copy
    whatever its type: iosub.pas's word 0 after open_src_file
    (0x0B515C) is the empty open options of ios_$open, the empty
    put/get options of ios_$put and ios_$get and ios_$current of
    ios_$inq_short_key in seven routines; the word 2 at 0x0B55C4 is
    [ios_$write_opt] for ios_$create, `false' (its first byte) for
    ios_$set_obj_flag and stream 2 for typeln's vfmt_$ws2; the word 4
    at 0x0B61E8 is open_include_file's severity and
    iosub_$get_full_path_name's ios_$root_name.  An enumerated or set
    constant is a word.  dpc puts a copy after each routine.
31. **The empty string passed by the next routine's address.**  ''
    with length 0 (stream_error's error_exit(status, '', 0), 0x0B50C4;
    open_binary_file's build_name) is `pea' of the address just after
    the routine's code, the next routine's entry: the literal has no
    bytes.
32. **A function's result left in A0 from a call.**  When the result
    variable holds a callee's A0 and A0 is not reused, the function
    ends without moving it to A0 again: celpkg.pas getlabcell (0x0B648E:
    getcodecell's cell kept in A0 through the stores, no `movea.l' at
    the end; its callers read A0), gen_exception.pas allocate (0x079FC6:
    putobj's address stored in a frame slot and A0 left as it is) and
    gen_exception_$new_exception (mrh_$alloc's).  dpc reloads the
    result.

## Function results and constants

33. **A univ_ptr result in D0, a typed pointer's in A0** (taken so;
    not proven).  pds.pas's public record makers return what they
    allocate in D0 (`move.l A0,D0' before the epilogue: pds_$make_name
    0x069CB4, pds_$make_src_loc 0x069D3A, pds_$make_arg 0x06A630) and
    their callers in debug_sym_dmp read D0 (`movea.l D0,A0'), while
    pds_$make_var_attr and pds_$make_arg_attr (0x06A082, 0x06A524: a
    pointer to a set) and the internal alloc_rec (0x069B40) leave it in
    A0.  pds.ins.pas declares the former univ_ptr; dpc returns every
    pointer in A0.
34. **Identical string constants shared across routines.**
    make_type_ref_from_aux (pds.pas 0x06F86A) passes make_type_ref's
    copy of '\\PDS_\MAKE_TYPE_REF -- Unknown dst_rel_offset tag.%$'
    (`pea 0x06F152', in make_type_ref's constants) instead of a copy of
    its own; every other literal of the unit follows its routine.
    dpc keeps one copy per routine.
## Non-local gotos and module data (translator H, c_lex_pp.pas)

35. **A routine whose nested routines leave it by goto keeps A5 in its
    frame.**  c_lex_pp's get (0x0557EA) saves all of D2-D7/A2-A5, then
    `move.l A5,(-16,A6)' after its `lea abs.l,A5', and at the label the
    nested routines' `jsr pas_$nlg2' (label address, get's frame) reach
    (0x055F20) reloads it (`movea.l (-16,A6),A5').  get_character takes
    get's frame in A1 and keeps it at (-4,A6) for the goto.  dpc refuses
    the goto (docs/dpc-gaps.md 12).
36. **An address constant in the literal pool passed by address.**
    c_lex_pp line_sem's lib_$data_move (0x053962) passes `pea
    (0x053C44,PC)', a longword holding iosub_$source_pathname's
    address (0x2CDC0C), for an `in' univ_ptr parameter given
    addr(iosub_$source_pathname); the other pointer arguments are frame
    temporaries.  Which addresses go to the pool is not known.
37. **A 16K module array addressed absolutely though inside 32K.**
    c_lex_pp's wide characters (4096 longwords at +0x2B54, the end of
    the module's 0x6B54 bytes: `move.l #0x14507C,-(SP)', `movea.l
    #0x14507C,A0') are never reached from A5, while every other cell
    of the module is; item 20's variable passed 32K.  The rule (by
    size?) is not known.
38. **objdump prints index displacements in hexadecimal.**  Not a code
    difference, a reading trap: `move.b (11,A2,D0.w),D3' at 0x0551AC
    is displacement 0x11 (the extension word 0x0011), a string node's
    characters at +18 indexed from 1; `(fffffffffffffffc,A0,D2.l)' is
    -4.  Plain displacements `(9439,A0)' are decimal.  The units
    translated before cc_dis.py's hexindex() were audited for this:
    docs/audit-hexindex.md (seven slips in htm, c_macro_read,
    il_utils and gen_exception, two copied into runbackend and
    commit_top_node).
39. **Varying string constants laid out as varying strings.**  c_main's
    preprocess assigns string constants to a varying [1024] (`arg :=
    '-Dunix''): the pool holds the length word and the characters
    (0x05AD1E: `00 06 -Dunix'), copied whole with `move.l (A0)+,(A1)+'
    (and a final `move.w' or `move.b'), not the 1026 bytes of the
    variable (docs/dpc-gaps.md 16).
40. **A program's routine passed as a parameter loads A5.**  c_main is
    the program cc; its routines run on cc's A5 and do not load it,
    except do_lex_for_listings (0x05A380), whose address cc passes to
    run_backend (`move.l #0x05A380,-(SP)') and which runbackend calls
    with `jsr (A0)'.  The others are written `internal'.
## Sets (translator J, runbackend.pas)

41. **No range check for a set test that spans the node kinds.**  A
    test of a node's kind (+2) against a constant set of 0..207 or
    0..223 checks the range first (`move.w #207,D0; sub.w kind,D0; bcs
    ...; lsr.w #3,D0; btst kind,(set,D0.w)': runbackend
    build_call_graph_walk_il 0x0B0F5E, unconditionally_add_call_graph_
    edge 0x0B0B5E), but normalize_il's set of 0..239 (0x0B17D4) has
    no `bcs': the kinds' type may be 0..239 (a set as large as the
    type needs no check).  Not decided; noted for the node types.

## Data layout (translator K, unix_objmod.pas)

42. **Arrays beyond 32K reached from one anchor address.**  unix_objmod's
    data (1.18 MB) has a 1000000-byte buffer at +0x5E24 (cc.m68k
    0x1A6138, `movea.l #0x1A6138,A0; move.b D2,(-1,A0,D0.l)' for
    element [count], emit_8 0x099B92), then two tables reached from one
    anchor, 0x29F198: the 12-byte names at 0x29A378 (`movea.l
    #0x29F198,A3' then (-20012,A3+12i): get_reloc_symndx 0x0995F0) and
    the string table at 0x29AF78 (`lea (0,A0,D0.l),A1; move.b
    D2,(-16928,A1)': write_byte_to_temp_string_table 0x0993BE;
    unix_obj_gen 0x09F6B8).  Other units reach the names absolutely
    (coff_syms 0x0A68F8: `movea.l #0x29A378,A0').  The anchor is the
    names' start + 20000; why that value is not known.  dpc addresses
    such an array from A5 with an added 32-bit offset (`adda.l
    #off,A0') and refuses a scalar placed after it.
43. **A module variable as a `for' loop's index.**  get_reloc_symndx
    (0x0995EC, 0x099692) and unix_obj_gen (0x09F6B0, from 0) count with
    the A5 longword +0x5CE8 (`move.l D2,(23784,A5)' before the loop,
    `addq.l #1,(23784,A5)' at its end, the trip count in D3/D2 by
    `dbf').  dpc accepts a global index.
44. **A parameter only a nested routine reads.**  unix_objmod's
    dump_data_init_thread (0x09CC02) never reads its parameter; its
    nested sort_data_init_thread takes the parent's frame from its
    dynamic link and reads (8,A2) (0x09C964).  Likewise gen_proc_relocs
    (0x09BED0) is passed a fourth longword (0 or +0x5D78, output_data_info
    0x09EF32, 0x09EF64) it never reads.
## Sets and records (translator L, c_expr_syn.pas)

45. **Set difference with a constant as `and' with its complement.**
    c_expr_syn's unary_expr `&' (0x05187E): `follow + [61, 76..89, 92,
    93, 101] - [77..89, 101]' is formed with `or.l'/`or.w' of the first
    constant, then `and.l'/`and.w' of a 14-byte constant holding the
    complement of the second (0x052230); the default case's `follow +
    [19, 20] + [...]' or-s the two constants in turn (0x052068).
46. **Small constant `in' tests as compare chains in source order.**
    The binary levels' loops (`token_kind in' their operators: multip
    0x05231E `cmpi.w #21; beq; cmpi.w #66; beq; cmpi.w #65; beq') and
    primary_expr's postfix loop compare in turn; sets whose elements
    pass 111 (token or node kinds up to 207) are `btst' on a 26-byte
    constant (docs/dpc-gaps.md 8).  Written here as `or' chains.
47. **A function of a record returns through a hidden address.**
    c_expr_syn's alloc_builtins (0x04FCF0) stores its 10-byte result
    through (8,A6) and the caller passes a frame temporary (`pea
    (-252,A6)' pushed last) and copies it to the table entry; dpc does
    the same.
48. **A record of 62 bytes in a 64-byte array element.**  swap_top
    (0x05047C) copies c_expr_sem's expression stack entries with five
    12-byte `move.l' triples and a `move.w' (62 bytes), while the stack
    is indexed `lsl.w #6' (64 bytes apart): the entry record is 62
    bytes and the array pads its elements to a multiple of 4.
    c_objtype.ins.pas declares the entry as 64 bytes.
## Packed fields (translator M, attributes.pas)

49. **A bit of a byte set or cleared with the word's bit number.**
    attr_check_align (cc.m68k 0x0A4F22) sets a type_exp_t's align_ok
    flag, bit 1 of the byte at +24 (+52 of the expression stack entry,
    tested `btst #1,(-0xc,A0,D3.l)' just before), with `bset
    #9,(-0xc,A0,D3.l)': 9 is the flag's bit in the word at +24, and
    the 68000 takes a memory operand's bit number modulo 8, so the
    byte's bit 1 is set.  Elsewhere the unit uses the byte's own bit
    numbers (`bset #1,(24,A0)' in attr_set_align_dsc 0x0A51E0).  dpc
    emits `bset #1'.

## Data layout (translator M, alias.pas)

50. **Large module arrays start on a multiple of 8.**  alias.pas's
    data (A5 0x168D8C, all initialized): a 340-byte array of names at
    +0, then three 578-byte tables (17 x 17 words) at +0x158, +0x3A0
    and +0x5E8 and a 34-byte one at +0x830: each starts on the next
    multiple of 8, leaving 4 or 6 bytes of zeros between.  (Elsewhere
    module variables follow each other at word alignment: item 9,
    il.pas +0x142.)  dpc lays them out end to end.
## Calls and nested routines (translator N, debug_sym_dmp.pas)

51. **An argument area's pad left on the stack for the next call.**
    After a call of 8 bytes of arguments that another call of 6 bytes
    follows, the first pops only 6 (`addq.l #6,SP') and the 2 bytes
    left stand for the second call's pad (item 8: no `subq.l #2'):
    debug_sym_dmp get_memory_loc 0x0A8B4E (force_add_string, then
    pds_$add_var_attr's word and longword), write_files 0x0ABE5A
    (`addq.l #2' after a 4-byte call, then three arguments of 10
    bytes), debug_sym_dmp_$block_dmp 0x0AC2EA (`lea (10,SP)' between
    two dump_string_table calls of 10 bytes each), get_type_rep
    0x0AA78C.  dpc pops each call's arguments and pads each call.
52. **A nested routine passed as a routine parameter loads A5.**  The
    routines nested in write_files (0x0ABB62, 0x0ABC00, 0x0ABC52) and
    debug_sym_dmp_$init (0x0AC3BC), which spos calls through their
    trampolines (item 12), save A5 and `lea abs.l,A5' after taking the
    parent's frame from A1 (`movea.l A1,A3'); the trampoline also loads
    A0 with the parent's A5, which they do not use.  Nested routines
    called directly run on their parent's A5 (item 1).
53. **A loop-invariant address loaded and not used.**
    get_var_location_rep 0x0A902C loads target_properties' address
    (`move.l #0x2CE528,D7') before its loop, whose tests of the target
    (+0x12) are absolute (`move.w 0x2CE53A,D0').
## Calls (translator P, c_expr_sem.pas)

54. **Two word arguments pushed as one longword.**  Consecutive
    constant word arguments are pushed by one `pea' or `move.l #':
    mult_div_mod_prep (cc.m68k 0x04C624) calls adjust_length(base, 0, 2)
    as `subq.l #2,SP; pea 0x2; move.w (-288,A0),-(SP)' (0 and 2 in one
    longword), and expr_op's adjust_length(k, 1, 4) are `move.l
    #0x10004,-(SP)' (0x04C678, 0x04D8C0, ...).  dpc pushes each word.
55. **A procedure's non-local goto target keeps A5 in the frame.**  As
    item 35: expr_op (0x04CDBA) stores A5 at -488 after loading it and
    reloads it at the label (0x04F856) that its nested do_coerce,
    coerce_as_usual and value_preserve reach through pas_$nlg2
    (0x04BF36, 0x04C0EA, 0x04C3FE).
56. **A bit set or cleared of a merged longword.**  expr_op's address
    of a function (0x04F046) sets two flags of a block, +374 bit 3 and
    +376 bit 4, with one `ori.l #0x08001000,(374,A2)' (item 10 for a
    longword spanning two packed fields).
## Records and statics (translator Q, outbin.pas)

57. **Stores of zero to adjacent record fields merged across field
    boundaries.**  ln_begin (cc.m68k 0x0BCCE8) clears a line entry's
    line (a word at +12) and next (a longword at +14) with `clr.l
    (12,A2); clr.w (16,A2)'; dump_proc_reloc (0x0BF260) stores a
    node's kind (193, +2) and link (nil, +4) with `move.l
    #0x00C10000,(2,A0); clr.w (6,A0)'.  The merged stores do not follow
    the fields' widths (item 10's merging, for unpacked fields).  dpc
    stores each field.

58. **Routines' static tables in the module's data.**  Four identical
    16-entry tables of register names lie in outbin's data (A5 +
    0xCD0, 0xCF0, 0xD10, 0xD40), each read by one routine only
    (prt_int_regs, prtads, dbcod, wr_instr): static variables with
    initializers, laid out in the order of the routines.


## Sets, frames and data (translator R, c_syntax.pas)

59. **A set constant with an element past the follow sets' bound
    widens the test.**  c_syntax's stat (0x065492) and stat_list
    (0x065378) test `token_kind in cases + [... 200]': the 14-byte
    cases is copied into the low end of a 30-byte temporary (16 bytes
    cleared, `move.w #239' for the bound) and the constant (the
    statement starters with 200, a constant node kind) or-ed in.
60. **Initialized data holding addresses.**  c_syntax's table at
    +0x208 of its data (declaration_specifiers 0x0623C4: `lea
    (0x208,A5,D6.w); movea.l (A4),A3; move.l (A3),(A2)') is
    initialized with the addresses of c_expr_sem's basic type cells
    (char_type, uchar_type, short_type, ... double_type twice):
    `array [0..4, 0..1] of ^c_type_ptr_t := [[addr(char_type), ...]]',
    which dpc compiles.
61. **Locals laid out downward in declaration order.**  The first
    local declared is nearest the frame pointer: pp_constant (0x066E54)
    has its constant record at -16 and its follow set at -32; dpc does
    the same, so the declarations follow the image's frame offsets.
62. **A boolean constant passed by address.**  declaration_stmts
    passes avoid_void's `in report: boolean' as `pea' of a byte after
    another routine's constant (0x061E7A, 0xFF true; 0x061E7C, 0x00
    false): constants by address are pooled across routines (item 30).
## Calls (translator T, cg_call.pas)

63. **One pushed longword shared by two calls' arguments.**  gen_call
    (cc.m68k 0x0F81A4) builds address(make_new_addr_con(10, s, v,
    sect, false), 0, op1) as `subq.l #2,SP; pea op1; clr.l -(SP);
    move.l sect; move.l v; move.l s; move.w #10; jsr; lea (16,SP)':
    the `clr.l' is make_new_addr_con's boolean (its high word) and
    address's size 0 (its low word, left on the stack by the 16-byte
    pop).  Item 51 for an argument of the outer call pushed inside the
    inner call's arguments.  dpc pushes each argument.
64. **A record value parameter copied by the callee, its fields put
    back.**  cg_misc's agg_len_loop_start (0x0F9DB8) copies its 20-byte
    descriptor parameter to a local (five `move.l'), changes its mode
    and displacement for one emit and stores the saved ones back after
    it, though the copy is not used again.  (A record value parameter
    without val_param is passed by address and copied, which dpc does
    too; the restore is the source's.)
## Write and data (translator S, add_node.pas)

65. **An enumeration's name table once per unit.**  `write' of an
    enumerated value is PAS_$WRITE code 3877 with the value by address,
    the width (0) and the type's name table: a word (the count, 237)
    and the names as length-prefixed strings in upper case, laid out
    after the first routine that writes the type
    (add_node_$dispose_top_level, cc.m68k 0x0A06A6, 0xAEA bytes with
    the messages' strings) and pointed at by later ones
    (add_node_$new_top_level `pea (0x0A06A6,PC)').  This is how the IL
    node kinds' names survive (END_OB 0 .. UNION_OB 236; cc.a88k has
    the table in several isc units too).  A value parameter written
    this way is first stored back into its frame slot (`move.w
    D2,(8,A6)') to pass it by address.
66. **A module's initialized data not read.**  add_node's data (56
    bytes) holds swap_cc (16 words at +0, read indexed) and four
    longwords 127, 32767, 255, 65535 at +0x28 that no instruction of
    the unit addresses; kept as a module array.

## Loops and nested routines (translator U, cg_top.pas)

67. **A jump to a loop's `until' threaded to the loop's head.**  codegen
    (cc.m68k 0x0FEDF2) leaves its statement loop at a routine's end; when
    the pass does not emit (at_backend_506 false) the `until
    at_backend_506' after the loop is known to fail, and the code jumps
    straight to the pass loop's head (`tst.b (328,A5); bpl.w 0x0FE6EA'),
    leaving the `until''s own test (0x0FEED0) to the emitting path.  dpc
    branches to the `until'.
68. **A nested routine counting with its parent's local.**  initialize
    (0x0FBDDA, nested in codegen) loops `for r := 18 to 23' with r
    codegen's word at -12 (`movew #18,(-12,A2)', A2 the parent's frame
    from the dynamic link; `addq.w #1,(-12,A2)' and `dbf' of the trip
    count); dpc accepts the non-local index.
69. **One argument value pushed twice with `move.l (SP),-(SP)'.**
    emit_a_line_eop (0x0FE61A) and emit_terminating_line_no pass
    cg_null_ads for both of emit_line_eop's descriptors as `move.l
    #0x356600,-(SP); move.l (SP),-(SP)'.  dpc pushes each.
## Data (translator V, the optimizer)

70. **Another unit's cells reached as fields of a record.**  opt_select
    (resetserial 0x0E56E8, select_block_list 0x0E582E, select_loop
    0x0E593A), opt_cse (cse_$cleanup_phase 0x0D4EAA) and kfold
    (node_number 0x0AD156) load the address of il.pas's +0xC0
    (`movea.l #0x169D30,A3') and reach il_11c, il_120 and il_124 as
    (92,A3), (96,A3), (100,A3), as a `with' over a record variable
    compiles; other units reach the same cells absolutely
    (`movea.l 0x169D8C,A0').  il.ins.pas declares separate variables
    (docs/questions.md 79); dpc addresses each absolutely.
71. **A table indexed by two booleans.**  opt_cse's rel_tab (its data
    +0, initialized -1, 1, 2, 0) is read as `seq; lsr.b #7' of each
    test, the first index shifted by 2 and the second doubled
    (cse_$is_cseable 0x0D52DC): `array [boolean, boolean] of integer'
    with false the first element.
## Calls and data (translator W, list_tree.pas)

72. **A register variable passed to a `var' parameter through a frame
    temporary.**  list_tree_$print_whole_il keeps the listing's line
    in D2 and calls advance_and_print(t, line) as `move.l D2,(-16,A6);
    pea (-16,A6); pea (A2); bsr', reloading D2 from the temporary after
    the call (cc.m68k 0x085B96..0x085BAA, three call sites); D2 also
    stands for nil in the same routine (`cmpa.l D2,A2' while it is 0).
    dpc keeps such a variable in memory.
73. **A varying string's initial blanks.**  list_tree's module line
    (+0x18, varying [256] of char) is initialized with length 0 and 256
    blanks in .data, and 24 blanks precede it (the names' padding, +0);
    the module's other initialized cells (+0x11C = 3, +0x120..+0x12B =
    0, the size letters at +0x130) are as declared.  dpc refuses '' as
    a varying string's initializer, so the line is declared without
    one.
## Tails and constants (translator Y, cg_addr.pas)

74. **A shared tail entered with a different constant.**  load_operand
    (cc.m68k 0x0F0F96) tests its register against [0..7] for class 4
    by `move.l #0xFF,D0; bra' into class 5's `btst D1,D0' (whose own
    path loads 0xFF00): item 23's identical tails, the differing set
    constant loaded before the jump.  dpc compiles each branch's test.
75. **A constant reused from a register holding another value.**
    load_result tests -CPU element 8 (0x2C3670 bit 2) with `btst
    D5,0x2C3670' where D5 holds 0x2002, the set [1, 13] it tested
    just before (0x0F25DE): bit numbers of a memory `btst' are taken
    modulo 8 (item 49), so 0x2002 tests bit 2.  dpc loads the bit.
## Packed fields (translator Z, gen_unwind.pas)

76. **A packed field stored from a shifted mask without a mask of its
    own.**  write_unwind_info_rec (cc.m68k 0x07AFF6: `lsr.l #8; lsr.l
    #2; lsl.w #2; or.w' into a 14-bit field after `andi.w #3'; 0x07B280
    `lsr.l #10', the low word into a 12-bit field after `andi.l
    #0xFF000FFF'; 0x07B052 `lsr.l #4; or.b' into a nibble): the bits of
    the value beyond the field are not cleared, as if the value's type
    already fit (a set of 10..21 copied from a set of 0..31?); other
    stores of the same routine mask (`andi.b #15').  The 12-bit field
    then gets registers added as a set: `subi.w #10', a range check
    (`moveq #15; sub.w; bcs'), `bset' in a word temporary and `or.w'
    with the field's old value (0x07B2FC).  dpc masks every store and
    refuses sets not based at 0 in packed records.
77. **A word field read as its low byte.**  The a88k scope's word at
    +34 (the return register, cc.a88k bin.pas `move.w D7,(-22,A6)') and
    +38, +40 are read as the bytes +35, +39, +41 (`move.b (59,A3),D3;
    add.b D3,D3; andi.b #0x3E' for a 5-bit field, 0x07B094) where only
    their low bits are stored.  dpc reads the word.
78. **case arms sharing their code.**  write_unwind_info_rec's SR10.0
    kinds 2 and 3 do their own stores and branch into the code of kinds
    0 and 1 after the allocation (0x07AFE0 `bra' to 0x07AFF6, 0x07B1B4
    to 0x07B1CA); scope_rec_dump's sizes keep 7, 8 and 9 on one arm
    (`moveq #4') but 11, 15 and 16 on arms of their own with the same
    constant (0x07BD62..0x07BD76).  (Item 23 for case arms.)  Written
    here as one arm for 0 and 2 (and 1 and 3) with an `if'.
## Real arithmetic and registers (translator AA, cg_assign.pas)

79. **Integer operands of a real comparison pushed by value.**
    cg_asn_$inline_move_is_best (cc.m68k 0x0F30AE) compares count * 2
    with (body * 2 + 8) * 1.5: the two integers are pushed (`move.l
    D6,-(SP); move.l D7,-(SP)') before `jsr fpp_$', whose operation
    words are 0x002C, the single 1.5 (0x3FC00000) and 0x0048, and the
    condition codes it leaves are tested (`bmi').  Item 19's operands
    are addresses.
80. **A variable set only on a loop's early exit shares the count's
    register.**  gen_clr_set (0x0F4166) looks for a mask's lowest bit
    with a `for' of 32 counted by `dbf D3' and stores the bit's index
    in D3 when it leaves: the result is not set on the other path, so
    the allocator gives it the trip count's register.
## Loops (translator BB, reg_cost_68k.pas, reg_action.pas)

81. **A loop entered past its first statement when that statement's
    test is known.**  compute_costs (cc.m68k 0x0C5D4A) walks a range's
    blocks with `if b = nil then <whole range> ; repeat if b <> nil
    then <the block's bounds> ... until b = nil': when the range has no
    blocks the code jumps from the first `if' straight into the loop
    after the block part (0x0C5F2E `bra 0x0C6018'), and the loop's end
    jumps to the block part's head (0x0C67FE `bne 0x0C5F60'), skipping
    the `if b <> nil' it knows to hold; do_register_actions (0x0C2D30,
    0x0C3644) likewise.  (Item 67's threading, for a test at a loop's
    head.)  dpc tests b each time round.

## Stores of zero (translator CC, opt_reachdef.pas)

82. **Zero stored by `move #0' into an indexed element.**  A nil or 0
    stored into an array element reached by an index register, or into
    a field of a record whose pointer was just read from such an
    element, is `move.l #0' / `move.w #0' / `move.b #0' (opt_reachdef:
    value^[v] := nil 0x0E3964 `move.l #0,(0,A0,D6.w)', 19 such stores;
    last_def^[v].stmt := 0 0x0E2928 `move.w #0,(0,A2,D0.w)';
    defs^[v]^.stmt := 0 0x0E46D6 `move.w #0,(A1)'), while the same
    stores through a pointer variable are `clr' (p^.stmt := 0 0x0E4BE6
    `clr.w (A0)', e^.ud^.next := nil 0x0E27F4 `clr.l (A0)').  dpc emits
    `clr' for both.

## Conditions (translator DD, cg_tree.pas generate)

83. **A dead compare before moves that set the condition codes.**
    generate's scales (cc.m68k 0x105AAC, 0x105D46): `cmpi.w #88,(2,A1)'
    of the constant, then `movea', `lea' and two `move.l' of its double
    to the frame, then `bne': the branch takes the last move's
    condition (the double's low longword zero), not the compare's.
    Written as the test of the low longword the code makes.
84. **A register variable read before any assignment on a path.**
    mul_proc (0x101D38) assigns its routine index (D2) on two of the
    classes' arms only and uses it on all; the conversions of arm 39
    (0x107976) assign the routine on 4 of the 11 entries of a jump
    table.  The registers keep their callers' values; the translation
    leaves the variable unset there too.
85. **A by-address boolean constant at the next routine's first byte.**
    opt_strength's doinsert (0x0E7BDC) and add_assign (0x0E8C8A) pass
    fixupchildren's `in' flag as `pea' of 0x0E7BFC, the entry of
    check_tree_node right after doinsert (byte 0x4E, false to the
    callee's `tst.b; bpl'), as pattern 31 passes the empty string.
    dpc puts the constant after the routine.

## Results and data (translator GG, final.pas)

86. **A function's result assigned to a dead variable is not stored.**
    plab (cc.m68k 0x10BE36) and backtrack (0x1103FA) call makejump and
    final_$unlink_opts and go on without touching A0; the Pascal must
    have assigned the result somewhere (a function cannot be called as a
    procedure), so Rev 8.89 drops the store of a value never read.
87. **A nested function's result left in D0 as its caller's.**
    final_$contiguous_distinct_addresses (0x109A80) assigns
    adjacent_disps's answer to its own result, which stays in D0 from
    the call to the return (no move to a register variable).
88. **Module data addressed by index from A5 with the table's offset as
    the displacement.**  cc_use (0x10AE26) reads the conditions' table
    at +0x88 as `lea (0,A5,D1.w),A1; move.w (136,A1),D0' with D1 the
    op less 138 (or 152), and as `(-112,A1)' and `(-228,A1)' with D1 the
    op itself (ops from 124 and 182): the lower bound folded into the
    displacement, so a table's offset can look negative.

## Sets (translator HH, emit.pas)

89. **Two removals from a register set kept apart.**  fnl_slct (cc.m68k
    0x0B74D0) takes the 68881's features out of its missing set with
    `andi.w #-9; andi.w #-2' (two statements, `- [3]' and `- [0]'),
    not merged into one mask as consecutive constant stores to packed
    fields are (item 10).  dpc does the same.
## Bit fields and nested frames (translator II, opt_main.pas)

90. **Bit numbers beyond 7 on a byte operand.**  opt_main's
    compute_variable_type_descriptors (cc.m68k 0x0DBD58) clears bits of
    the word at +24 of a type with `bclr #10,(24,A1,D4.l)' and `bclr
    #9': memory bit operations take the bit number modulo 8, so these
    are bits 2 and 1 of the byte at +24 (the word's bits 10 and 9); the
    neighbouring fields are written with `andi.b #7' and `ori.w #64'.
    Rev 8.89 numbers a packed word's bits from the word, not the byte.
91. **A nested routine's static link in A1 kept in a data register.**
    g_opt's nested routines take A1 (the parent's frame) and keep it in
    D5 or A2 (add_interior_node_to_postorder_node_list: `move.l A1,D5',
    then `movea.l D5,A1' before each recursive call); recompute_node_lists
    takes it from the dynamic link (`movea.l (A6),A2'), since only g_opt
    calls it.
## Stores, records and FPP words (translator JJ, final.pas)

92. **Constant stores to two adjacent word fields merged into one
    longword store.**  opta (cc.m68k 0x10F910) sets a cell's kind (+8)
    to 5 and its size (+10) to 2 with `move.l #0x50002,(8,A2)'; optmove
    (0x10E2AC) kind 16 and size 4 with `move.l #0x100004'.  Item 10's
    merging, for whole words of a record.  dpc stores each.
93. **More FPP operation words.**  0x0074 0xFF34: the operand (a double
    by address) compared with 0.0, the codes left for `beq'/`bne'
    (final.pas floatop 0x10FDE2; kfold 0x0AE534 before its division by
    zero error); 0x0074 0x00D0: trunc of the double into D0 (floatop
    0x10FE98, kfold 0x0AD898); 0x00C4 0x00B4: a longword pushed by value
    converted and compared with a double by address (floatop 0x10FEBA).
94. **An array of 10-byte records not padded.**  final.pas's table of the
    68881's ROM constants (A5 +0x2E8: a word and a double each) is
    indexed by 10 times the index (floatop 0x10FD4E: `add.l D3,D3' ...
    `(736,A1)'), unlike item 48's 62-byte entries padded to 64.
95. **A function's result not read.**  opttest (0x10D6BA) calls
    final_$collapsed_index_calc and branches to its end without testing
    D0 (item 86's dead assignment, here of a boolean); a procedure's
    caller passing a value its callee never reads: deltest pushes
    fn_ccset (`move.w (40,A5),-(SP)') for cc_change, which reads the
    module cell itself (item 44's unread parameter, at its only call).


## Inliner (translator NN, opt_inline.pas)

96. **A local held in a register also stored to its frame slot.**
    process_opr_ind (cc.m68k 0x091EDC, 0x091F6A) computes a
    displacement in D3 (`neg.l D3; add.l D0,D3'), stores it to a frame
    longword (-56) that nothing reads and pushes D3 for adjust_disp;
    unlike item 86, the dead store is kept (a local, not a function's
    result).
97. **Paths that set a flag branch past its test.**  process_index_opr
    (0x091A1E): the arms that need a's offset subtracted test ctx.sdn
    and branch to the subtraction or past it, while the two arms of an
    address (137 op 26) branch straight past it (0x091BC0, 0x091BEA);
    written with a flag (rebase) tested once, which dpc tests.
## The PRISM back end's leaf units (translator MM, cc.a88k)

98. **An internal routine from an insert dropped where nothing calls
    it.**  be_com utils.ins.pas has utils_ins_$operands_instruction's
    body (0x22 bytes, no frame: the operand at (4,SP), A0 the result):
    each of the 19 units that calls it has a copy at its start (com
    0x225DF4, xtp 0x287ABC, ...); dfa, sem_utils and the other units
    that open the insert without calling it have none.  dpc compiles
    every routine of a unit, so it keeps an extra copy there.
99. **A packed record's 3-bit field passed as a longword by `and.b'.**
    dfa and xtp pass at_backend_switches' level (+0x501 bits 2..0):
    `moveq #7,D0; and.b 0x485D31,D0' then `move.l D0,-(SP)' (or stored
    to a longword); a 1-bit field passed as a boolean by `btst #3;
    sne'.  dpc warns (passing a field that is not a whole byte, word
    or longword) and extends the byte (`ext.l').
100. **A zero-filling helper in each unit.**  zero (at_backend 0x221A60,
    zzzzz 0x287F80; 0x18 bytes, no frame): (n + 3) div 4 longwords
    cleared with `clr.l (A0)+' and `subq.l #1; bne', `beq' on n's move
    for 0 (the flags of `move.l (8,SP),D0' survive `movea.l').  Each
    unit has its own copy (the same name, internal).
## The optimizer's utilities (translator PC, cc.a88k tr_utils)

101. **A routine whose whole body is jumped over.**  tr_utils's
    copy$complex_complex (cc.a88k 0x27D540, 0xAE bytes) branches from
    its saves straight to its epilogue (`bra.w 0x27D5DE'); the code in
    between (a loop over the operands whose `dbf' counter is never set
    up, a merge of the live ranges, write_cc_or_delete_instr) is kept.
    Written as `return' first with the code after it; dpc compiles the
    dead code too.
102. **A constant set stored only from its significant bytes.**
    tst_elim_within_bb (0x280EA6) and validate_lts_for_tst test an
    opcode against [77, 79..83] as `moveq #95,D3; sub.w opc,D3; bcs;
    lsr.w #3,D3; btst opc,(0x280F1C,PC,D3.w); ble': the set's bound is
    95 but the constant after the routine is 4 bytes (00 0F A0 00, the
    elements 95..64 from the top), the bytes for 0..63 (all zero) left
    out.  dpc refuses `in' on such a set (docs/dpc-gaps.md 8).
103. **A parameterless call between another call's pushed arguments.**
    make_copy (0x27C3BA) pushes `pea (-8,A6); move.l (12,A2),-(SP)',
    calls lir_$new_live_range_ip_reg (which reads no parameters) and
    then pushes only its result and a word for
    lir_utils_$add_lts_to_lr, which finds the two earlier longwords as
    its third and fourth arguments (`lea (16,SP),SP' after it): item
    63 for an inner call with no arguments of its own.  tools/cc_params.py
    reads such pushes as the inner callee's parameters (its heading was
    narrowed to none).
104. **Validators passed by address and called through a register.**
    tr_utils_$attempt_autoincrement's and attempt_test_elimination's
    searches pass module-level routines as `move.l #0x27FB7A,-(SP)'
    and call them with `jsr (A0)' (find_complex_driving_ltss 0x27D8BE);
    utils_$apply_func_to_all_uses is given test_lts_for_n_bit_unconsumed
    the same way.  Written as routine pointer types (tr_valid_t) given
    addr(...), as docs/dpc-gaps.md 21's first case.

## The LIR utilities (translator PA, bv, exs, utils; cc.a88k)

105. **Two constant word arguments pushed as one longword.**
    utils_$begin_compilation (0x28494E) passes mrh_$initialize's flags
    and default size (1 and 8, then 1 and 248) as `move.l
    #0x10008,-(SP)' and `move.l #0x100F8,-(SP)': item 92's merging of
    adjacent constant stores, for the argument area.  dpc pushes each
    word.
106. **A shared tail entered at a conditional branch.**
    utils_$complete_copied_instr_at_bb_head (0x28641A) tests the
    operand's live range's +3 bit 6 (`btst #6,(3,A1)') and then `bra'
    to the `beq' after the other path's `btst #6,(3,A3)' of a new
    segment, both followed by utils_$put_lts_on_final_list: item 23's
    shared tails, cut at the branch so that the flags of two different
    tests reach one `beq'.
107. **A boolean module variable set with a longword store.**  exs's
    cache flag (A5 +4, read with `tst.b') is set by `moveq #-1,D0;
    move.l D0,(4,A5)' (0x069B1C) and cleared by `move.l #0,(4,A5)':
    the three bytes after it are not otherwise used (merged stores of
    neighbours never read, or a longword-sized flag).
108. **A redundant nil test kept.**  utils_$get_canonical_birthpoint
    (0x285E44) tests the load's segment (`tst.l (-16,A6)'; beq) and,
    further on, `cmpa.w #0,A1' of the same value before a bug_check,
    an `if ... = nil then bug_check' the earlier test makes dead; Rev
    8.89 does not remove it.
109. **Loops over vectors counted with a word index and an unsigned
    longword limit, tested at the bottom.**  bv's vector operations
    (bv_$copy 0x224E84 ...: `clr.w D1', `addq.w #1,D1', `clr.l D0;
    move.w D1,D0; cmp.l D2,D0; bls') run once even when the limit
    ((n + 31) div 32 - 1, unsigned) would be -1; written as for loops.
## The memory model (translator PC2, cc.a88k mmt, mmt_utils)

110. **A nil test made with a register holding an unrelated constant.**
    mmt_$points_for_good_behavior (cc.a88k 0x254E7C) tests its first
    descriptor pointer A3 for nil with `cmpa.w D1,A3', D1 holding the
    class set 16#210000 (load, store) it tested just before: `cmpa.w'
    sign-extends D1's low word, 0.  Item 75's reuse of a register's
    constant, for a pointer compared with nil.  dpc tests A3 itself.
111. **A pointer test after a store of another pointer's link.**
    mmt_utils' free_mmt_seqs_and_ltss (0x256CE4) and
    mmt_utils_$analyze_one_bb (0x257942) unlink an instruction or live
    range with `move.l A3,(4,A0)' (or `(12,A1)') and branch on the
    flags of that move (`bne') for the following `if next = nil': the
    store of the value tested sets the condition codes, so no `tst' is
    emitted (fill_in_ltss's like unlinking, 0x257342, does `tst.l').
    dpc tests again.


## The flow graph phases (translator PA2, df_utils, fga, hal, life, sanity; cc.a88k)

112. **An `and' with a mask that clears only low-byte bits done as
    `andi.b'.**  hal_$find_hammocks (0x238818) rounds a block count up
    to 32 bits as `addi.l #31,D2; andi.b #0xE0,D2; lsr.l #3,D2': the
    longword's `and' with not 31 narrowed to its low byte, since the
    mask's other bytes are all ones.  dpc does `andi.l'.
113. **Back-to-back identifier constants without a terminator.**  fga's
    conditionally_asynchronous passes 'setjmp' and 'SETJMP' to idntk
    (length 6 each) from 0x23807E and 0x238084: twelve bytes with no
    pad or NUL, so the next routine's `link' (0x4E56, "NV") follows the
    second; the strings of a routine are laid out at their exact
    lengths when they are not messages ending in %$.
114. **A routine's whole failure path as one branch target that also
    finishes the work.**  conditionally_asynchronous (0x237CC6) branches
    from some twenty tests to 0x23806C, a loop marking the block's
    instructions not examined yet, and returns its flag from there:
    written as `goto 99' to a label before that loop (a flag-structured
    version compiled 0x140 bytes longer).

## The assembler (translator PB2, cc.a88k asm)

115. **A 32-bit word built in a local packed record, field by field.**
    asm_$process_routine's encoder fills the frame's longword at -300
    with byte, word and longword `andi'/`or' pairs (`andi.b #-32,
    (-297,A6); or.b D0,(-297,A6)' for bits 4..0, `andi.w #-993,
    (-300,A6)' for 25..21, `andi.l #-262144,(-300,A6)' for 17..0,
    `bset #3,(-300,A6)' for bit 27): a packed record with variants,
    each field's width choosing the access (dpc does the same:
    asm_word_t).  The template is ORed in at the end (`move.l
    (-300,A6),D0; or.l (-188,A6),D0').
116. **A literal passed by reference placed among the routine's
    strings.**  bug_check's last argument 12 (the mnemonic's length
    for %a) is the longword 0x0000000C at 0x2214B8, between two
    messages; zzzzz_$new_code_cell's `in' opcode 204 is the word 0x00CC
    at 0x21E6BC before append_literal_pool__code_cell's message.
117. **A record's leading fields cleared from a code constant.**
    clear_literal_pool (0x21E768) copies 48 bytes (lo and hi -1, the
    rest 0) with `lea (0x21E7D0,PC),A0' and twelve `move.l (A0)+,
    (A1)+' (the last `move.l (A0),(A1)'), then stores the tails one by
    one: a structured constant (or an aggregate) for the first 48 bytes
    of an 80-byte record.  Written as field assignments.
118. **A char value parameter as a word.**  dump_pass_one_instruction's
    mark is pushed `move.w #0x2000,-(SP)' (' '), 0x2B00 ('+'), 0x7800
    ('x'): the character in the word's high byte, printed with %M1ZA
    from (16,A6).


## The dumps (translator PB3, cc.a88k dmp)

119. **String constants overlapped in the pool.**  dmp_$instruction
    (0x230A2E) pads an operand kind's name from a 24-blank constant at
    0x231D72 whose last two blanks are the start of '  fw=%ld%$'
    (0x231D88, used by the width lines): the pool shares a constant's
    head with the tail of another (a suffix of one string the prefix of
    the next).  Likewise 'AVAIL_ON_ENTRY', 'KILLED', 'LIVE_ON_ENTRY'
    (passed with their lengths, no terminator) lie back to back
    (pattern 113), and identical control strings ('%.', ' %$', ' ]%.')
    are one constant for the whole unit, referenced from routines far
    apart.  dpc lays each out on its own.
120. **A test of a pointer just cleared, folded into a jump.**
    display_ra_info (0x2336CA) clears A3 (`suba.l A3,A3') and branches
    straight to its epilogue (`bra.w 0x233878'): the loop over the
    conflicts' displacements and the preferenced set that follow are
    never reached, though their code is there, and the loop's test at
    its bottom is skipped too.  Written as `c := nil; if c <> nil then
    begin repeat ... until c = nil; ... end': Rev 8.89 knows the
    register's value from the clear (pattern 75) and drops the test.
121. **An operand's instruction computed inline.**  print_lts_list
    (0x233054) finds the instruction of a segment's operand as
    `operand - 32 - 12 * operand^.num' (`move.b (A0),D1; lsl.w #2;
    ...; subi.l #32; sub.l D4'), utils_ins_$operands_instruction's
    body, without a call: dmp does not open utils.ins.pas (an inline
    function or a macro in the original; written as the expression).
122. **A record after the object it describes, reached by a negative
    displacement.**  print_alias_desc (0x230834) reads a load's or
    store's alias descriptor (alias_$desc_t, 24 bytes) at the
    instruction's address less 24 (`subi.l #24'): lir allocates it in
    front of the instruction.
## The calling conventions and the LIR checks (translator PA3, call_conv, sanity, lir_utils; cc.a88k)

123. **A boolean register as a `btst' bit number.**  at_call_conv
    (cc.a88k 0x0B49EE) tests a kind 175 callee's byte +76 with
    `btst D3,(76,A2); sne D3', D3 holding nested, false (0) on that
    path: bit 0.  Written `(byte & 1) <> 0'.  Item 75's reuse of a
    register's value, as a bit number.
124. **An address loaded and never used.**  sanity_$check_entire_
    routine's third and fourth walks load lir_main_c86's address into D3
    (`lea 0x48C032,A1; move.l A1,D3', then `tst.w (A1)' through it) and
    `move.l #0x48BFEC,D4' (lir_main_c40's) that nothing reads before D4
    is reloaded.
125. **A word parameter before a longword: frame 8:w, 10:l.**
    make_expression_temporary (isc_user_routines 0x2144EA) is called
    `subq.l #2,SP; pea 0x20; move.w #122,-(SP)' (8 bytes): the word
    first at 8, the longword at 10, then two bytes of pad.
126. **A record array's elements of 26 bytes.**  at_call_conv's argument
    descriptors (call_conv_$arg_t) are indexed by `add.l; move.l; lsl.l
    #2; add.l; add.l; add.l' (26k) and the record allocated as 26(n - 1)
    + 108 bytes; copies move 6 longwords and a word.  dpc lays the
    record out at 26 bytes too (checked with sizeof).
## The common subexpression phase (translator PC4, cc.a88k com)

127. **A small local set kept in a data register.**  com's
    process_instruction (cc.a88k 0x22B46C) keeps a `set of 0..31' of
    the operand numbers whose canonical birthpoints it has cached in
    D6: tested `cmpi.l #31,D5; bgt; moveq #31,D0; cmp.w D5,D0; bcs;
    btst D5,D6; bls' (the range check's carry and btst's Z together),
    an element added by clearing a frame longword, `bset D5,(A0,D0.w)'
    into it and `or.l (-752,A6),D6'.  dpc refuses `in' on a set it
    holds in a register (docs/dpc-gaps.md 30).
128. **A nested routine that uses nothing of its parent called without
    a static link.**  ltss_on_stores_to_same_addr's nested
    get_the_right_instr (0x229968) is called `pea (A0); bsr' with its
    one argument only, and reads no frame of its parent.
## The debugger's lifetimes and the scheduler's utilities (translator PB4, cc.a88k dbg_life, sched_utils)

129. **A for loop's longword limit read as its low word.**  dbg_life's
    fill_not_killed_sets counts its live ranges `for i := 1 to
    rtn^.l192' with an integer index as `move.w (194,A1),D4; subq.w
    #1,D4' (the longword at +192 read at +194), the slots `move.w
    (198,A2)' of rtn +196, and write_register's words `move.w
    (34,A5)' of a longword module variable at +32; write_spilled_var
    computes `slot + words * 32' into an integer in word arithmetic
    from the same low word (`lsl.w #5'), where kill_spilled_var,
    whose result is a longword, reads the whole longword.  dpc reads
    the longword and narrows.
130. **A 2-byte argument pad left on the stack across a call for the
    next call's word.**  find_symbols pops 14 of the 16 bytes pushed
    for dbg_life_$open_pc_range (`lea (14,SP),SP') and pushes the next
    call's word without `subq.l #2,SP'; dbg_life_$process_routine pops
    2 of 4 after dbg_life_$initialize (`addq.l #2,SP') before mrh_$alloc's
    word: pattern 51 for internal routines.

## The LIR utilities, continued (translator PA4, lir_utils; cc.a88k)

131. **utils_ins_$operands_instruction inline in a unit that opens
    utils.ins.pas.**  lir_utils_$trans_insert_move (cc.a88k 0x24C312)
    finds op's instruction as `move.b (A1),D0; lsl.w #2,D0; ...; subi.l
    #32,D2; sub.l D1,D2' (pattern 121's expression) though lir_utils
    opens utils.ins.pas and has no copy of the insert's routine
    (pattern 98): written as the expression.
132. **A call pushing fewer arguments than the callee reads.**
    lir_$get_new_instruction_no_exceptions (0x2433C2) passes its five
    frame longwords (8, 12:w, 14, 18, 22) on to begin_instruction, but
    fix_store_through_lrs pushes three (`subq.l #2,SP; clr.l -(SP);
    move.w (10,A3),-(SP); move.l #0x48AD00,-(SP)') or four (with the
    memory home after `pea 0x2000'): the slots not pushed are read as
    whatever lies above (begin_instruction reads 18 only under flag
    bit 13).  dpc pushes every parameter (nil or 0 here).
## The induction variables (translator PC5, cc.a88k iv)

133. **A function returning a 12-byte record through its caller's
    space.**  ixr_$get_induction_instantiation_from_operand (cc.a88k
    0x23D9A0) is called `pea (-68,A6)' after its arguments, so the
    result's address is at (8) and the parameters start at (12); it
    builds the record in a local and copies it out at the end (`lea
    (-56,A6),A0; movea.l (8,A6),A1' and three `move.l (A0)+,(A1)+');
    the callers copy it again to a local of their own.  dpc does the
    same for a function of a record type (checked in its output).
134. **Routine pointers passed by reference as constants placed after
    the routine.**  iv_$locate_induction_variables_at_loop_end
    (0x23FA6A) calls iv_$walk_basic_blocks_in_order with `pea
    (0x23FAFA,PC)' (a longword 0: nil) for both nil arguments and `pea
    (0x23FAFE,PC)' (the longword 0x0023E2B6, the scanner's address);
    iv_$process_routine's four constants are at 0x240152..0x24015E, and
    its second walk pushes the nil constant's address twice (`move.l
    (SP),-(SP)').  The walk's parameters are `in' (item 116 for routine
    addresses); dpc places and shares the constants the same way.
135. **Stack pops merged across calls with uneven counts.**
    ixt_$replace_induction_expr (0x23EC12) pushes 32 bytes for
    ixt_$create_increment_instruction and pops 30 (`lea (30,SP),SP'),
    then pushes 10 for ixr_$find_induction_expr and pops 12;
    create_operand_from_elaborated_expression leaves
    lir_utils_$add_lts_to_lr's 16 bytes on the stack on its way to the
    epilogue.  The two-byte pads after a longword (item 125's) are
    popped with the next call's arguments.
136. **An argument pushed for a callee that reads none.**
    iv_$locate_induction_variables_at_loop_end pushes the block (`pea
    (A2)'; `addq.w #4,SP' after) for ivr_$finalize_induction_variables,
    which never reads (8,A6): written as an unused parameter (cf. item
    103, where the push belonged to another call).



## The register allocator's utilities (translator PB5, cc.a88k ra_utils)

137. **A real constant stored to a single real field as its bits.**
    choose_spill_cost (cc.a88k 0x26EC9A) stores a live range's spill cost
    (+28, a single) as `clrl (28,A2)' for 0.0 and `move.l #0x3F800000,
    (28,A2)' for 1.0: no FPP call for a constant assignment.  The
    integer-times-real roundings (`round(n * 0.9)') go through fpp_$
    (0x00BC for a word operand pushed by value, 0x00C4 for a longword,
    0x00A0 and the double, 0x0154 0x0068 the round to D0).
138. **A routine passed as a parameter set up at the parent's entry.**
    ra_utils_$add_spill_code (0x270F0C) builds new_db_lts's trampoline
    (item 12) and calls cache_$clear first thing, though the routine is
    passed only deep inside two loops (to lir_utils_$flesh_out_new_load_
    or_store), and on paths that return early too.
139. **A word of flags cleared once per outer iteration, reset per
    operand.**  add_spill_code's reload facts (-106, a byte count and a
    byte of flags) are `clr.w' for each instruction and `move.w #128'
    for each read operand; a write operand that is not also read sees
    the flags its instruction's previous operands left.  Written as a
    variant record (ru_fl_t) with the word's view.
