{ lang/lang/source/cargs.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/cargs.pas (the command line and its options).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ CARGS - the command line: cargs_$init_option_defaults sets the options'
  defaults, cargs_$parse_command_line_fixed_arguments takes the source
  file name (and -USAGE, -HELP, -VERSION), cargs_$parse_command_line_options
  the options (through the internal parse_options, which is passed the
  options record's address and sets every field relative to it).
  cargs.pas: cc.m68k 0x0B2568..0x0B5021, A5 0x2C33EC; cc.a88k
  0x0B6228..0x0B88DB, A5 0x443570.  The data are laid out the same in
  both binaries:

    +0x0     the -NATURAL/-TYPE/... arguments push_kap passes on (an
             array of 128 pointers; cargs only)
    +0x200   cargs_$debug_switches (below)
    +0x278   cargs_$options (below), to +0x26A2
    +0x26A8  cargs_$source_name
    +0x2AB0  cargs_$version_string
    +0x2BB0  the compiler's name (cargs only, its length the word at
             +0x2BE0)
    +0x2BD0  a word (cargs only), cargs_$2bd2, cargs_$timestamp, the
             edit number (+0x2BD8, get_little_version), the compiler
             (+0x2BDA, cargs_$identify_self), push_kap's count (+0x2BDC),
             cargs_$version_length (+0x2BDE), +0x2BE0, -P (+0x2BE2)
    +0x2BE8  the names -OPT_ON and -OPT_OFF take (1024-byte entries,
             parse_opt_on_or_off; cargs only)

  Large variables start at multiples of 8 from the data's start (+0x278
  after the 116 bytes at +0x200, +0x26A8 after +0x26A2, +0x2AB0 after
  +0x2AAA).

  Not known from the original: every name here but the routines'. }

{ The options record.  Field widths and positions are those cargs.pas
  writes (cargs_$init_option_defaults through A5, parse_options through
  A2 = the record; evidence in docs/evidence/parse_options.cc.m68k.dis);
  the other units only read them (docs/globals-cc.*.md; a unit that loads
  the record's address into a register reads more fields than the
  catalogue shows).  The flags are one packed record (Domain packing:
  first field in the high-order bits of the first byte); positions in
  the comments are byte.bit, bit 7 the high-order one.

  Four groups are sets (element k is the field's k-th bit from its
  low-order end, checked with dpc): opt_on (-OPT n stores 30-bit
  constants, -OPT_ON/-OPT_OFF add and remove elements by number, the
  optimizer tests `<> []' with and.l #0x7FFFFFFE), cpu, flags_286 (-ABS
  extracts the 21 bits, removes element 8, adds element 7 and puts them
  back) and outputs (parse_options tests outputs * [0, 2] and removes
  [0, 1, 2]).  Everything else is a boolean or a subrange: Rev 8.89
  merges consecutive stores of the same constant into one and/or of a
  byte, word or longword (docs/rev889-patterns.md, pattern 10), so the
  multi-bit clears of cargs_$init_option_defaults and the -IMAP, -ANSI,
  -NANSI, -NTYPE and -NATURAL masks are runs of booleans (cc.m68k clears
  +0x27B bits 4..0 in one andi.w; cc.a88k, whose default sets indexl,
  clears bit 4, sets bit 3 and clears bits 2..0).

  Field names: the command-line option that sets the field where there is
  one (an option beginning with N clears the field of the same name);
  else the field's position. }

{ TODO(pascal) cargs_$options_t fields named by position

  The fields named b<offset>_<bit> or x<offset>_<bit> are set only by
  cargs_$init_option_defaults (or nothing in cargs) and read by the units
  listed; name them when those units are translated.  The sets' elements
  are numbers; the options that set each element are in the comments. }

type
  { A name: 1026 bytes (the names are 0x402 apart; set_name stores at
    most 1024 characters and a null after a shorter name).  Not a
    `varying [1024] of char', which takes 1030 bytes (language reference
    3.11.4.1, and dpc). }
  cargs_$chars_t = array [1..1024] of char;
  cargs_$name_t = record
    length: integer;
    body: cargs_$chars_t;
  end;

  cargs_$options_t = packed record
    { +0x278 }
    tree: 0..63;                { .7..2: -TREE [point]: the dump point
                                  (AF 1, AI 2, BDIST 8, ..., EXP 50; -TREE
                                  alone 47, AO); read as a number by
                                  c_main, opt_main, opt_strength,
                                  runbackend }
    b278_1: boolean;            { .1 }
    b278_0: boolean;            { .0 }
    { +0x279 }
    b279_7: boolean;
    b279_6: boolean;
    b279_5: boolean;
    bct: boolean;               { .4: -TREE ... BCT }
    addr: boolean;              { .3: -TREE ... ADDR (list_tree, prtobj) }
    na: boolean;                { .2: -TREE ... NA (list_tree) }
    nn: boolean;                { .1: -TREE ... NN }
    ra: boolean;                { .0: -DUMP68 RA (reg_alloc); cc.m68k }
    { +0x27A }
    b27a_7: boolean;
    b27a_6: boolean;
    sri: boolean;               { .5: -DUMP68 SRI (opt_strength) }
    b27a_4: boolean;
    rd: boolean;                { .3: -DUMP68 RD (opt_reachdef) }
    force_inline: boolean;      { .2: adds opt_on 24..26 }
    exp: boolean;               { .1: -EXP (with outputs 0) }
    map: boolean;               { .0: -MAP, -IMAP, -ACMAP (with outputs 0) }
    { +0x27B }
    imap: boolean;              { .7 }
    acmap: boolean;             { .6: c_sym_map }
    type_opt: boolean;          { .5: -TYPE, -ANSI, -XANSI; -NTYPE, -NANSI
                                  clear it; default true }
    b27b_4: boolean;            { .4: c_lex_pp sets it }
    indexl: boolean;            { .3: -INDEXL (default true in cc.a88k) }
    subchk: boolean;            { .2: -SUBCHK }
    b27b_1: boolean;            { .1: cg_call, delay, opt_inline }
    b27b_0: boolean;            { .0 }
    { +0x27C }
    x27c_7: 0..15;              { .7..4: default 10 }
    b27c_3: boolean;            { .3 }
    std: boolean;               { .2: -STD, -ANSI; -NANSI clears it }
    b27c_1: boolean;            { .1: add_node, cg_tree, delay, kfold }
    b27c_0: boolean;            { .0: not set by cargs }
    { +0x27D }
    cond: boolean;              { .7: -COND }
    warn: boolean;              { .6: -WARN (default true) }
    usrch: boolean;             { .5: -USRCH }
    comchk: boolean;            { .4: -COMCHK }
    xrs: boolean;               { .3: -XRS (default true) }
    c: 0..3;                    { .2..1: -NC 0, -CC 1 (default), -C 2
                                  (cg_addr, cg_top) }
    x27d_0: 0..3;               { .0 to +0x27E.7: default 2 (alias) }
    { +0x27E }
    x27e_6: 0..3;               { .6..5: default 2 (alias) }
    b27e_4: boolean;            { .4 }
    b27e_3: boolean;            { .3: default true (alias) }
    b27e_2: boolean;            { .2 }
    b27e_1: boolean;            { .1 }
    fpra: boolean;              { .0: the highest -OPT level sets it,
                                  -NFPRA clears it after the options
                                  (commit_top_node) }
    { +0x27F }
    b27f_7: boolean;            { .7 }
    frnd: boolean;              { .6: -FRND (token: round real constants
                                  to single precision) }
    opt: 0..15;                 { .5..2: -OPT [n], -NOPT 1, -OPTALL 6,
                                  default 6 }
    info: 0..7;                 { .1 to +0x280.7: -INFO [n], 2 without n;
                                  -NINFO 0 }
    { +0x280 }
    opt_on: set of 0..29;       { .6 to +0x283.1: the optimizations on
                                  (-OPT n, -NOPT, -OPTALL store constants;
                                  -OPT_ON, -OPT_OFF elements by name;
                                  -FORCE_INLINE adds 24..26; -DBA stores
                                  a constant); opt_inline, opt_loop,
                                  opt_main, ... }
    { +0x283 }
    db: 0..3;                   { .0 to +0x284.7: -NDB 0, -DB 1 (default),
                                  -DBS 2, -DBA 3 (17 units) }
    { +0x284 }
    dbh: boolean;               { .6: -DBH (debug_sym_dmp) }
    cpu: set of 0..11;          { .5 to +0x285.2: -CPU: 0 ANY/ALL/68000,
                                  1 PEB, 2 160, 3 M020 (and with 4: 5700,
                                  MATHLIB...), 5 FPX, 6 cc.a88k's
                                  ALL/10000, 7 KODIAK, 8 FPA1, 9 MATHLIB,
                                  10 MATHLIB_SR10; default [3, 4, 10]
                                  (cc.a88k [6]); iosub passes it to
                                  target_properties$cpu_rev_specific as
                                  a word (18 units) }
    { +0x285 }
    es: 0..3;                   { .1..0: -ES 1, -ESF 2 (c_error, c_lex_pp,
                                  c_main, iosub) }
    { +0x286 }
    flags_286: set of 0..20;    { .7 to +0x288.3: 20 -NOCPP, 19 -OLDCPP,
                                  16 cc.a88k's -PRASM (default),
                                  15 -AEGIS10 (cc.m68k), 14 -SOME_FP and
                                  13 -NO_FP (cc.a88k), 12 -UMSG, 11 -BSS,
                                  10 -PROF, 9 -STAT (default), 8 and 7
                                  -AC (default), -ABS 7, -PIC neither,
                                  6 -ULINE (default for compiler 1),
                                  5 -VARARGS, 4 -ALIGN (default; -PEB
                                  removes it), 3 -NMSGS, 2 (compiler 1),
                                  1 -EXTRA, 0 (compilers 1, 3, 5) }
    { +0x288 }
    b288_2: boolean;            { .2 }
    b288_1: boolean;            { .1 }
    b288_0: boolean;            { .0 }
    { +0x289 }
    x289: 0..255;               { default 123 }
    { +0x28A }
    b28a_7: boolean;            { .7: coff_syms, unix_objmod }
    b28a_6: boolean;            { .6: default true for compilers 1, 3, 5
                                  (coff_syms, debug_sym_dmp, gen_utils,
                                  unix_objmod) }
    b28a_5: boolean;            { .5 }
    b28a_4: boolean;            { .4 }
    b28a_3: boolean;            { .3 }
    alnchk: boolean;            { .2: -ALNCHK: not cpu 6 (attributes,
                                  c_def_sem, c_expr_sem) }
    b28a_1: boolean;            { .1 }
    compress: boolean;          { .0: -COMPRESS }
    { +0x28B }
    ncompress: boolean;         { .7: -NCOMPRESS, -PROF }
    cd: boolean;                { .6: -CD }
    xansi: boolean;             { .5: -XANSI, -ANSI; -NANSI, -NTYPE clear
                                  it (9 units) }
    ansi: boolean;              { .4: -ANSI }
    nansi: boolean;             { .3: -NANSI }
    stdc: boolean;              { .2: -NSTDC, -NANSI, -NTYPE clear it,
                                  -ANSI sets it; default true }
    natural: boolean;           { .1: -NATURAL }
    b28b_0: boolean;            { .0: -NATURAL; set from natural by
                                  the defaults; attributes changes it }
    { +0x28C }
    systype: cargs_$name_t;     { -SYSTYPE (c_main, prfpkg) }
    runtype: cargs_$name_t;     { +0x68E: -RUNTYPE (c_main, unix_objmod) }
    l_name: cargs_$name_t;      { +0xA90: -L name (iosub) }
    name_e92: cargs_$name_t;    { +0xE92: iosub }
    b_name: cargs_$name_t;      { +0x1294: -B, -BX name (iosub) }
    esf_name: cargs_$name_t;    { +0x1696: -ESF name (iosub) }
    cpp_name: cargs_$name_t;    { +0x1A98: -CPP name (c_main) }
    { +0x1E9A }
    outputs: set of 0..6;       { .7..1: 0 listing (-L, -MAP, -EXP, -C),
                                  1 binary (default; -B, -BX; -NB
                                  removes it), 2 -B, -BX, 3, 4 (iosub
                                  open_plb_file), 5 -BX, 6 -INLIB }
    meter: boolean;             { .0: -METER (prfpkg) }
    { +0x1E9B }
    nclines: boolean;           { .7: -NCLINES (unix_objmod) }
    unwind: 0..1;               { .6: -OLD_UNWIND 0, -NEW_UNWIND 1 (read
                                  as a number by unix_objmod, cc.a88k's
                                  bin) }
    { +0x1E9C }
    name_1e9c: cargs_$name_t;   { the defaults clear its length }
    { +0x229E }
    b229e_7: boolean;           { .7: false by default }
    { +0x22A0 }
    name_22a0: cargs_$name_t;   { the defaults clear its length }
  end;

var
  { +0x200: a word for each letter 'A'..'z', cleared by the defaults
    and set by nothing in cargs; the back ends test bits of some
    (runbackend 'X' and 'i'; cc.a88k's at_backend, bin, com, dmp, lir,
    xtp). }
  cargs_$debug_switches: extern array ['A'..'z'] of integer;

  { +0x278 }
  cargs_$options: extern cargs_$options_t;

  { +0x26A8: the source file name, the first argument (c_lex_pp,
    iosub). }
  cargs_$source_name: extern cargs_$name_t;

  { +0x2AB0: the compiler's version string, built by
    cargs_$identify_self, and its length (+0x2BDE) (c_main,
    unix_objmod). }
  cargs_$version_string: extern array [1..256] of char;

  { +0x2BD2 and +0x2BD4: the compiler image's timestamp and the word
    cleared with the word at +0x2BD0 when it is not known
    (get_compiler_image_timestamp_and_edit_number; unix_objmod). }
  cargs_$2bd2: extern integer;
  cargs_$timestamp: extern integer32;

  { +0x2BDE }
  cargs_$version_length: extern integer;

{ PRINT_VERSION - print the version string (-VERSION).  0x0B2584: no
  parameters. }
procedure print_version; extern;

{ PUSH_KAP - keep an argument for the KAP preprocessor: `-mp' and the
  len characters of s (-NATURAL, -TYPE, -COND, -NWARN ...; at most 128).
  0x0B2652: both by address (callers `pea' two constants; len's slot is
  dereferenced as a word). }
procedure push_kap(
    in s: univ cargs_$chars_t;
    in len: integer); extern;

{ CARGS_$IDENTIFY_SELF - record which compiler this is (c_main passes 1)
  and build the compiler's name and version strings.  0x0B4A18: a word
  by value. }
procedure cargs_$identify_self(
    compiler: integer); options(val_param); extern;

{ GET_LITTLE_VERSION - the version: 6, 9 and the image's edit number.
  0x0B4A54: three words by address (do_report). }
procedure get_little_version(
    out major: integer;
    out minor: integer;
    out edit: integer); extern;

{ CARGS_$INIT_OPTION_DEFAULTS - the options' defaults.  0x0B4A86
  (iosub_$init_default_properties). }
procedure cargs_$init_option_defaults; extern;

{ CARGS_$PARSE_COMMAND_LINE_FIXED_ARGUMENTS - the source file name (or
  -USAGE, -HELP, -VERSION and exit).  0x0B4D94 (iosub_$init_all). }
procedure cargs_$parse_command_line_fixed_arguments; extern;

{ CARGS_$PARSE_COMMAND_LINE_OPTIONS - the options, into cargs_$options;
  the arguments of -DEF, -IDIR, -INLIB and -UNDEF are added to four
  lists (count, the list's size, the list: an array of pointers to the
  arguments).  dot, when not nil, is the string made `.' and entered as
  the first -IDIR directory.  0x0B4E9A: 8 count by address, 12 a word,
  14 a pointer, ... (iosub_$init_all passes its own parameters on; the
  last list is iosub's data). }
procedure cargs_$parse_command_line_options(
    var ndef: integer;
    maxdef: integer;
    deflist: univ_ptr;
    var nidir: integer;
    maxidir: integer;
    idirlist: univ_ptr;
    dot: univ_ptr;
    var ninlib: integer;
    maxinlib: integer;
    inliblist: univ_ptr;
    var nundef: integer;
    maxundef: integer;
    undeflist: univ_ptr); options(val_param); extern;

{ CARGS_$PARSE_LINE_OPTIONS - the options in the len characters of line
  into opts.  0x0B4F0E: line by address, len a longword, opts's address
  passed to parse_options; no caller in either binary. }
procedure cargs_$parse_line_options(
    in line: univ cargs_$chars_t;
    len: integer32;
    var opts: cargs_$options_t); options(val_param); extern;
