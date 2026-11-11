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
    -4.  Plain displacements `(9439,A0)' are decimal.
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
## Packed fields (translator M, attributes.pas)

42. **A bit of a byte set or cleared with the word's bit number.**
    attr_check_align (cc.m68k 0x0A4F22) sets a type_exp_t's align_ok
    flag, bit 1 of the byte at +24 (+52 of the expression stack entry,
    tested `btst #1,(-0xc,A0,D3.l)' just before), with `bset
    #9,(-0xc,A0,D3.l)': 9 is the flag's bit in the word at +24, and
    the 68000 takes a memory operand's bit number modulo 8, so the
    byte's bit 1 is set.  Elsewhere the unit uses the byte's own bit
    numbers (`bset #1,(24,A0)' in attr_set_align_dsc 0x0A51E0).  dpc
    emits `bset #1'.

## Data layout (translator M, alias.pas)

43. **Large module arrays start on a multiple of 8.**  alias.pas's
    data (A5 0x168D8C, all initialized): a 340-byte array of names at
    +0, then three 578-byte tables (17 x 17 words) at +0x158, +0x3A0
    and +0x5E8 and a 34-byte one at +0x830: each starts on the next
    multiple of 8, leaving 4 or 6 bytes of zeros between.  (Elsewhere
    module variables follow each other at word alignment: item 9,
    il.pas +0x142.)  dpc lays them out end to end.
