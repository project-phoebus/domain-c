{ c_lex_pp - the C front end's lexer and the preprocessor's line
  input: get hands the parser the next token (lex_token, its class in
  token_kind), reading lines from the conditional reader (c_cond_read,
  which takes them through c_macro_read and back through PPIO_ here) or,
  when an external preprocessor ran, from the source stream itself; it
  processes the directives the preprocessor leaves (#include, #line,
  #pragma, #module, #section, #systype, #list, #nolist, #eject, #ident,
  #debug, #apollo, #inhibit, #backstop), keeps the stack of open source
  files, lists each line (and its expansion under -EXP), and writes the
  preprocessed text under -ES.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0533E8  0x053668  advance_listing_to_line
    0x053444  0x0536C4  put_es_line
    0x05351A  0x05379A  init_lex
    0x0557EA  0x055A6A  get
    0x053724  0x0539A4  more_data_on_line
    0x0545C0  0x054840  parse_directive
    0x053784  0x053A04  set_ecb_bit
    0x0537E6  0x053A66  open_file_to_get_info
    0x05386C  0x053AEC  line_sem
    0x053C48  0x053EC8  eject_sem
    0x053C68  0x053EE8  list_sem
    0x053C74  0x053EF4  nolist_sem
    0x053C7A  0x053EFA  sect_id
    0x053C86  0x053F06  module_sem
    0x053E56  0x0540D6  section_sem
    0x05404C  0x0542CC  systype_sem
    0x054178  0x0543F8  hp_standard_sem
    0x05420E  0x05448E  do_pragma
    0x05494C  0x054BCC  open_include
    0x054BFE  0x054E7E  pp_get_line
    0x054DBA  0x05503A  get_character
    0x054DFA  0x05507A  get_comment
    0x054E8A  0x05510A  get_backslash_char
    0x055060  0x0552E0  get_string
    0x055124  0x0553A4  get_wstring
    0x0551EE  0x05546E  get_char_const
    0x0552A4  0x055524  get_wchar_const
    0x0552D0  0x055550  peekchar
    0x0552EC  0x05556C  get_wchar_t
    0x055336  0x0555B6  get_identifier
    0x0554C8  0x055748  get_number
    0x0553EE  0x05566E  get_integer
    0x05578E  0x055A0E  check_op_asn
    0x055FB0  0x056230  clex_$unget
    0x055FE4  0x056264  clex_$catstring
    0x0560E8  0x056368  ppio_$error
    0x056138  0x0563B8  ppio_$get_line
    0x0563A4  0x056624  ppio_$lookahead
    A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k): the module's data, 0x6B54
    bytes: the -EXP listing's length (+0x0), the listing's line (+0x2),
    lex_macro_expanded (+0x20A), the including files' texts (+0x20C),
    the stack of files (+0x250), the tokens of #options and #attribute
    (+0x498, +0x14B0), the current line's position and column (+0x24C8,
    +0x24CA), c_error's cells (+0x24CC..+0x24DD) with the #nolist depth
    among them (+0x24CE), the line (+0x24DE), the tokens' table
    (+0x26E8), then the lexer's state (+0x2AC4..+0x2B08), the digits of
    a real constant (+0x2B10), a flag (+0x2B50) and the wide characters
    (+0x2B54, addressed absolutely; it ends the data).  c_initdate.c's
    data has the same address (it has none).

  The global routines (advance_listing_to_line, init_lex, get,
  clex_$unget, clex_$catstring, the PPIO_ routines) load A5; put_es_line
  does not (internal).  The routines nested in get, and those nested in
  parse_directive and get_number, reach their parent's frame through
  their own dynamic link when only the parent calls them and through A1
  otherwise (docs/rev889-patterns.md 25).

  A source line is held in lex_text from character 9 (characters 1..8
  are the listing's line number field), lex_pos the next character;
  ch is the character get_character read last.

  The nested routines leave get for its end at the end of the source
  with a non-local goto (pas_$nlg2; docs/dpc-gaps.md 12); real
  constants and comparisons (get_number) are docs/dpc-gaps.md 7, the
  set of integer constant kinds (hp_standard_sem) docs/dpc-gaps.md 8,
  get_backslash_char's case docs/dpc-gaps.md 2, ppio_$get_line's
  comparison of spos_$region_user_name docs/dpc-gaps.md 13 and
  clex_$catstring's results docs/dpc-gaps.md 14.
}
module c_lex_pp;

%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/loader.ins.pas';
%include 'us/us/ins/ev.ins.pas';
%include 'us/us/ins/pm.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/proc2.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';
%include 'us/us/ins/unix_resource.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include '/sys/ins/pm.ins.pas';
%include 'us/us/ins/acl.ins.pas';
%include 'us/us/ins/c.ins.pas';
%include '/sys/ins/ios.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'us/us/ins/cvfp.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';
%include 'lang/c_compiler/source/macro_read.ins.pas';
%include 'lang/c_compiler/source/c_lex_pp.pvt.pas';
%include 'lang/common/source/spos.ins.pas';
%include 'lang/common/source/token.ins.pas';
%include 'lang/common/source/cail.ins.pas';

define
  lex_listing_line;                     { +0x2 (c_lex_pp.pvt.pas) }
  lex_macro_expanded;                   { +0x20A }
  lex_files;                            { +0x250 }
  kw_options;                           { +0x498 (c_globals.ins.pas) }
  kw_attribute;                         { +0x14B0 }
  lex_line;                             { +0x24C8 }
  lex_text_written;                     { +0x24CC }
  lex_hdr_written;                      { +0x24CD }
  lex_fatal;                            { +0x24D0 }
  lex_fatal_suppressed;                 { +0x24D1 }
  lex_type_errors;                      { +0x24D2 }
  lex_errors;                           { +0x24D4 }
  lex_warnings;                         { +0x24D6 }
  lex_infos;                            { +0x24D8 }
  lex_24da;                             { +0x24DA }
  lex_24dc;                             { +0x24DC }
  lex_text;                             { +0x24DE }
  lex_tokens;                           { +0x26E8 }
  lex_total_lines;                      { +0x2AE0 }
  lex_token;                            { +0x2AE4 }
  lex_depth;                            { +0x2AEE (c_lex_pp.pvt.pas) }
  lex_systype_state;                    { +0x2AF0 (c_globals.ins.pas) }
  lex_inline_state;                     { +0x2AF2 }
  lex_module_seen;                      { +0x2AFE }

type
  { A column of lex_text: compared unsigned with its length (`bhi',
    `bls'). }
  lex_col_t = 0..32767;

  { The name and line of a #module (module_sem copies the 8 bytes into
    the module block). }
  lex_mod_name_t = record
    name: il_$node_ptr_t;               { +0 }
    line: integer;                      { +4 }
    unused_6: integer;                  { +6 }
  end;

  { A block as set_ecb_bit and module_sem see it: a routine's ECB
    flags (#inhibit, #backstop), a module's sections and name. }
  lex_block_ptr_t = ^lex_block_t;
  lex_block_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    unused_4: array [1..46] of integer32;  { +4..+187 }
    code_sect: il_$node_ptr_t;          { +188: a module's code section
                                          (+8 its name) }
    data_sect: il_$node_ptr_t;          { +192 }
    unused_196: array [49..73] of integer32;  { +196..+295 }
    mod_name: lex_mod_name_t;           { +296 }
    unused_304: array [304..375] of char;  { +304..+375 }
    ecb: packed record                  { +376 }
      unused_7: 0..31;                  { .7..3 }
      bits: 0..3;                       { .2..1: bit 0 #inhibit, bit 1
                                          #backstop }
      unused_0: boolean;                { .0 }
    end;
  end;

var
  listed_len: integer;                  { +0x0: under -EXP, the length
                                          of the line just listed }
  saved_texts: array [0..16] of univ_ptr;  { +0x20C: [d] holds the text
                                          of the file that included the
                                          one at depth d (512 bytes from
                                          gspace, made when depth d is
                                          first reached) }
  lex_pos: lex_col_t;                   { +0x24CA: the next character
                                          of lex_text }
  nolist_depth: integer;                { +0x24CE: #nolist less #list:
                                          the listing is off while it is
                                          not 0 }
  unget_token: il_$node_ptr_t;          { +0x2AC4: clex_$unget's token,
                                          the next get's }
  last_es_line: integer32;              { +0x2AC8: put_es_line: the last
                                          line written }
  lines_read: integer32;                { +0x2ACC }
  text_start: univ_ptr;                 { +0x2AD0: lex_text's character
                                          9 (set, not read) }
  source_tok: il_$node_ptr_t;           { +0x2AD4: the source file's
                                          name, a string node }
  line_file_tok: il_$node_ptr_t;        { +0x2AD8: the file the last
                                          #line named }
  std_include_tok: il_$node_ptr_t;      { +0x2ADC:
                                          `/usr/include/apollo_$std.h',
                                          the implicit #include }
  unget_kind: integer;                  { +0x2AE8 }
  cur_stream: integer;                  { +0x2AEA: the stream lines are
                                          read from }
  max_depth: integer;                   { +0x2AEC: the deepest file
                                          (saved_texts made) }
  internal_cpp: boolean;                { +0x2AF4: the lines come
                                          through c_cond_read (no
                                          external preprocessor) }
  have_mbtowc: boolean;                 { +0x2AF6: mbtowc is loaded:
                                          wide strings are converted
                                          with mbstowcs }
  string_delim: char;                   { +0x2AF8: the closing quote of
                                          the last string }
  in_include_directive: boolean;        { +0x2AFA: reading an #include's
                                          name: `<' begins a string, a
                                          backslash is a character }
  line_seen: boolean;                   { +0x2AFC: a #line was seen }
  include_name: il_$node_ptr_t;         { +0x2B00: the name an #include
                                          gave, to be opened }
  tok_start: lex_col_t;                 { +0x2B04: where the token
                                          begins }
  skip_line: boolean;                   { +0x2B06: the rest of the line
                                          is dropped }
  ch: char;                             { +0x2B08 }
  fp_digits: array [1..64] of char;     { +0x2B10: a real constant's
                                          digits for lib_$cv_fp_in }
  line_truncated: boolean;              { +0x2B50: the last line read
                                          filled 512 characters, the
                                          next continues it }
  wide_buf: c_$wchars_t;                { +0x2B54: a wide string's
                                          characters }

{ advance_listing_to_line - read tokens until the line being read is
  line (the listing caught up with it) or the source ends.

  0x0533E8, 0x5C bytes.  Nothing when line is spos_$null_position.  A
  loop (test first): token_kind (0x14AE94 in A2) is ctk_eof or lex_line
  is line ends it; else get, and print_error(lex_line) when
  error_listing_0c is set (`tst.b 0x2C3174').

  Not known from the original:
  - the parameter's name. }

procedure advance_listing_to_line(
    line: integer);
begin
  if line <> spos_$null_position then
    while (token_kind <> ctk_eof) and (lex_line <> line) do begin
      get;
      if error_listing_0c then
        print_error(lex_line);
    end;
end;

{ put_es_line - under -ES, the `# line "file"' line before the text of
  a line not following the last one written (or when force).

  0x053444, 0xD4 bytes, link #-272, no A5 (internal).  Only when es is 1
  (`moveq #3; and.b 0x2C3671; cmpi.w #1').  spos_$decode_source_position
  (position, region (-272), line (-268)); unless force, nothing is
  written when line is last_es_line + 1.  The line (-264, a PRTSUB
  line): '# ' (0x053518), the line number (prtint width 5, no zero
  fill: `move.l #0x50000'), a blank, the region's user name (prtobj);
  write_ln(1, ...).  Then last_es_line := line - 1 with force, else
  line.

  Not known from the original:
  - the names. }

procedure put_es_line(
    position: integer;
    force: boolean); options(val_param); internal;
var
  region: integer32;
  line: integer32;
  s: prtsub_$line_t;
begin
  if cargs_$options.es = 1 then begin
    spos_$decode_source_position(position, region, line);
    if force or (last_es_line + 1 <> line) then begin
      s.length := 0;
      prtcats(s, '# ', 2);
      prtint(s, line, 5, false);
      prtcatc(s, ' ');
      prtobj(s, spos_$region_user_name(region));
      write_ln(1, addr(s.body), s.length);
    end;
    if force then
      last_es_line := line - 1
    else
      last_es_line := line;
  end;
end;

{ init_lex - start reading the source file.

  0x05351A, 0x1E4 bytes, link #-52.  internal_cpp := (not -XANSI or
  -OLDCPP) and not -NOCPP (`btst #5,0x2C3677; seq', `btst #6,0x2C3672;
  sne', `tst.b 0x2C3672; spl': flags_286 elements 19 and 20).  The
  source pathname gets a NUL after it and becomes source_tok (strtk of
  length + 1) and line_file_tok; line_seen cleared;
  spos_$init_source_position(strtk of cargs_$source_name, source_tok,
  the stream's full path name, its dtm, nil).  The implicit include's
  name: a 38-character frame array (-40) assigned the 26-character
  literal (0x0536FE; six longwords and a word copied, three longwords
  of blanks), its 27th character made NUL, strtk(.., 27).  lex_line :=
  spos_$position; lex_text 8 blanks long, lex_pos 9; both written flags
  set, nolist_depth 0; text_start := @lex_text.body[9]; the listing's number
  field blanked (two `move.l #0x20202020'); lex_macro_expanded cleared;
  the 16 files' path and dir_name cleared (a `dbf' loop from +0x272);
  lex_depth, max_depth 0; cur_stream := iosub_$source_stream;
  in_include_directive cleared; file 0's in_comment, continued and
  comment_state cleared; unget_token nil.  have_mbtowc := the
  loader knows `mbtowc' (loader_$kg_lookup('mbtowc', 6, -1,
  [public_only, function_only] (a frame word, 6), addr); `btst #1':
  loader_$sym_known).  last_es_line 0; put_es_line(the next line,
  true).

  Not known from the original:
  - the locals' names and the array's bound (38: the literal and the
    blanks the image stores). }

procedure init_lex;
var
  name: array [1..38] of char;
  opts: loader_$kg_lookup_opts;
  where: univ_ptr;
  i: integer;
begin
  internal_cpp := (not cargs_$options.xansi or
                   (19 in cargs_$options.flags_286)) and
                  not (20 in cargs_$options.flags_286);
  iosub_$source_pathname[iosub_$source_pathname_length + 1] := chr(0);
  source_tok := strtk(iosub_$source_pathname,
                      iosub_$source_pathname_length + 1);
  line_file_tok := source_tok;
  line_seen := false;
  spos_$init_source_position(
      strtk(cargs_$source_name.body, cargs_$source_name.length),
      source_tok,
      iosub_$get_full_path_name(iosub_$source_stream),
      iosub_$get_dtm(iosub_$source_stream),
      nil);
  name := '/usr/include/apollo_$std.h';
  name[27] := chr(0);
  std_include_tok := strtk(name, 27);
  lex_line := spos_$position;
  lex_text.length := 8;
  lex_pos := 9;
  lex_text_written := true;
  lex_hdr_written := true;
  nolist_depth := 0;
  for i := 1 to 8 do
    lex_text.body[i] := ' ';
  text_start := addr(lex_text.body[9]);
  lex_listing_line.number := '        ';
  lex_macro_expanded := false;
  for i := 1 to 16 do begin
    lex_files[i].path := nil;
    lex_files[i].dir_name := nil;
  end;
  lex_depth := 0;
  max_depth := 0;
  cur_stream := iosub_$source_stream;
  in_include_directive := false;
  lex_files[0].in_comment := false;
  lex_files[0].continued := false;
  lex_files[0].comment_state := 0;
  unget_token := nil;
  opts := [loader_$kg_public_only, loader_$kg_function_only];
  have_mbtowc := loader_$sym_known in
                 loader_$kg_lookup('mbtowc', 6, loader_$kg_symbol, opts, where);
  last_es_line := 0;
  put_es_line(spos_$enquire_next_line, true);
end;

{ get - the next token.

  0x0557EA, 0x7A4 bytes, link #-20, all registers saved; A5 is also
  kept at (-16,A6) for the non-local gotos of the nested routines
  (reloaded at 0x055F20).  The locals: (-2) what was being read
  (quote_state: 1 a character constant, 2 a string, 3 a comment) for
  the message at the end of the source, (-4) the column of a
  directive's `#' (hash_col; line_sem and parse_directive want 9, the
  line's first character).

  A token clex_$unget put back is returned first.  Else skip_line,
  lex_token (nil) and quote_state cleared, and a loop until lex_token
  is set (each case ends with `tst.l' or the `move.l' to +0x2AE4 and a
  branch to the `beq' at 0x055F1C):
  - skip_line moves lex_pos past the line's end;
  - blanks, tabs and form feeds are skipped, tok_start the for loop's
    index (+0x2B04), pp_get_line reading on at the end of the line
    (the end of the source ends get);
  - `L' may begin a wide character constant or string (get_wchar_t),
    else an identifier; a letter, `_' or `$' (the set at 0x055F98)
    an identifier; a digit a number;
  - the jump table at 0x055922 (characters 9..126): the operators
    (one lex_tokens entry each; `+=' etc. after check_op_asn, which
    under -NXANSI allows blanks before the `='), `"' a string, `''' a
    character constant, `/*' a comment, `#' a directive: when the line
    has more, get is called again for the directive's name: `attribute'
    or `options' (idntk(76, ...) compared) make the token kw_attribute
    or kw_options, any other is parse_directive's (open_include
    follows when it named a file) and the loop goes on; a lone `#'
    drops the line.  Without -XANSI, `=' followed by an operator is
    the old compound assignment (`=+' is `+=', ...) and is reported
    (error1(8)); a lone `=' leaves get at once.  `..' not followed by
    `.' gives no token (both dots are dropped).  Another character is
    lex_tokens[ctk_other_char] with the character in its name.
  At the end (0x055F20) token_kind := lex_token^.kind; at the end of
  the source an open character constant or string is reported
  (error0(3)), an open comment (error0(1)), and an alignment pushed
  and not popped (error0 of cerr_code_map[80], 0x040D72).

  Not known from the original:
  - the locals' and labels' names; how the loop and its exits were
    written (a repeat loop and gotos here); whether the case's
    otherwise was written (the jump table sends letters and digits,
    already taken, there too). }

procedure get;
label
  1, 2, 99;
var
  quote_state: integer;
  hash_col: integer;

  { more_data_on_line - lex_text has a character other than a blank,
    tab, newline, form feed or return from lex_pos on.

    0x053724, 0x5A bytes, link #-12, no frame access.  The result in
    D0 (false first); a counted loop from lex_pos to the line's length
    tests each character against the set at 0x05377E (6 bytes,
    elements 0..47: 9, 10, 12, 13, ' '). }

  function more_data_on_line: boolean;
  var
    i: integer;
  begin
    more_data_on_line := false;
    for i := lex_pos to lex_text.length do
      if not (lex_text.body[i] in [chr(9), chr(10), chr(12), chr(13), ' ']) then begin
        more_data_on_line := true;
        exit;
      end;
  end;

  { parse_directive - the directive whose name (or line number) is the
    current token.

    0x0545C0, 0x328 bytes, link #-44; get's frame from its dynamic
    link (`movea.l (A6),A2').  Its locals belong to the routines
    nested in it: the #module name (-16, 8 bytes), #section's sections
    (-24 code, -20 data), #module's section names (-32 code, -28
    data), #systype's length and versions (-34, -38, -36).

    A number is a #line (line_sem); else the name (an identifier, else
    error1(47)) is compared (compare_bytes with the literals from
    0x0548E8): `pragma' (do_pragma on the next token), `include' (the
    `#' must begin the line, else error1(50); the next token read with
    in_include_directive set must be a string, error1(48), and becomes
    include_name), `line' (line_sem on the next token), `ident' (the
    line dropped), `list', `nolist', `section', `module', `systype',
    `eject', `apollo' or `apollo_bit' (cargs_$options.b27b_4 set:
    `ori.w #16,0x2C3666'), `debug' (the line dropped unless -COND:
    `tst.b 0x2C3669; spl'), `inhibit' (set_ecb_bit(0)), `backstop'
    (set_ecb_bit(1)); another name error1(50).  A missing argument is
    error1(185).  The errors share a tail that drops the line
    (0x0548D0).

    Not known from the original:
    - the locals' names (and that they are this routine's: no
      instruction of it touches them). }

  procedure parse_directive;
  var
    mod_name: lex_mod_name_t;
    psect, dsect: il_$node_ptr_t;
    code_name, data_name: il_$node_ptr_t;
    sys_len: integer;
    sys_v1, sys_v2: integer;
    p: il_$node_ptr_t;

    { set_ecb_bit - #inhibit (0) or #backstop (1): set bit in the
      current routine's ECB flags.

      0x053784, 0x62 bytes.  il_180 must be a function (108) or a
      procedure (107) (`seq', `seq', `or.b'), else error0(156).  The
      2-bit field at +376 (bits 2..1) is extracted (`moveq #6; and.b;
      lsr.w #1'), or-ed with the bit (`bset'), and put back.

      Not known from the original:
      - the field's type (a 2-bit number here; a set would do the
        same). }

    procedure set_ecb_bit(
        bit: integer); options(val_param);
    var
      b: lex_block_ptr_t;
    begin
      b := il_180;
      if (b = nil) or else not ((b^.kind = 108) or (b^.kind = 107)) then
        error0(156, lex_line)
      else
        b^.ecb.bits := b^.ecb.bits ! lshft(1, bit);
    end;

    { open_file_to_get_info - the full path name and dtm of the file a
      #line names (the name itself and 0 when it does not open).

      0x0537E6, 0x86 bytes, link #-16.  open_include_file(the name, its
      length less the NUL, sid (-10), false, true): the two booleans
      are frame bytes (-14 false, -12 true) set first; then
      iosub_$get_full_path_name, iosub_$get_dtm and close_include_file
      of sid.

      Not known from the original:
      - the names; whether the booleans were variables. }

    procedure open_file_to_get_info(
        name: il_$node_ptr_t;
        out full_path: univ_ptr;
        out dtm: integer32); options(val_param);
    var
      sid: integer;
    begin
      if open_include_file(name^.str_chars, name^.str_len - 1, sid,
                           false, true) then begin
        full_path := iosub_$get_full_path_name(sid);
        dtm := iosub_$get_dtm(sid);
        close_include_file(sid);
      end
      else begin
        full_path := name;
        dtm := 0;
      end;
    end;

    { line_sem - #line n ["file"] (or # n "file" from a preprocessor).

      0x05386C, 0x3D8 bytes, link #-60; get's frame through two dynamic
      links (`movea.l (A6),A0; movea.l (A0),A0').  Only with -ULINE
      or -USRCH (`btst #1,0x2C3673', `btst #5,0x2C3669'), else the
      line is dropped.  The `#' must begin the line (error1(50)); n
      must be a positive integer constant (error1(167), error1(297));
      a file name must be a string (error1(169)): it becomes the
      source pathname (iosub_$source_pathname, lib_$data_move from the
      node, through the literal address at 0x053C44) and, unless this
      is the main file's first line's first #line (first, -32), a
      change of file when it differs from line_file_tok.  #line 1 with
      a new file starts it as an include file (lex_files' next entry,
      as open_include: saved_texts, spos_$start_include_file; a depth
      past 16 is error0(49), spos_$may_start_include_file false
      error0(95)); another line with a new file ends the current
      include file (as ppio_$get_line at its end); otherwise, in the
      main file, spos_$change_file to the named file from line n (its
      path and dtm from open_file_to_get_info for the first #line,
      else the region's), in an include file spos_$skip_lines to n.
      Then lex_line, put_es_line(the next line, true) and the line
      dropped.  The result (-42): true after an error that dropped the
      line; parse_directive does not read it.

      Not known from the original:
      - the names; whether the result was meant to be read. }

    function line_sem: boolean;
    var
      n: integer32;
      is_one, changed, first: boolean;
      push, pop: boolean;
      name: il_$node_ptr_t;
      full_path: univ_ptr;
      dtm: integer32;
      len: integer32;
      src: univ_ptr;
      d: integer;
      next_line: integer32;
    begin
      line_sem := false;
      if not ((6 in cargs_$options.flags_286) or cargs_$options.usrch) then begin
        skip_line := true;
        return;
      end;
      if hash_col <> 9 then
        error1(50, lex_line, lex_token);
      if token_kind <> ctk_int_con then begin
        error1(167, lex_line, lex_token);
        skip_line := true;
        line_sem := true;
        return;
      end;
      n := lex_token^.int_value;
      if n <= 0 then begin
        error1(297, lex_line, lex_token);
        skip_line := true;
        line_sem := true;
        return;
      end;
      is_one := n = 1;
      name := nil;
      changed := false;
      first := not line_seen and (lex_line = 1);
      line_seen := true;
      if more_data_on_line then begin
        get;
        if token_kind <> ctk_string then begin
          error1(169, lex_line, lex_token);
          skip_line := true;
          line_sem := true;
          return;
        end;
        name := lex_token;
        if not first and (name <> line_file_tok) then begin
          line_file_tok := name;
          changed := true;
        end;
        iosub_$source_pathname_length := name^.str_len - 1;
        len := iosub_$source_pathname_length;
        src := addr(name^.str_chars);
        lib_$data_move(src, addr(iosub_$source_pathname), len);
      end;
      push := changed and is_one;
      pop := not is_one and changed and (lex_depth <> 0);
      if push then begin
        if lex_depth >= 16 then begin
          error0(49, lex_line);
          return;
        end;
        if not spos_$may_start_include_file then begin
          error0(95, lex_line);
          return;
        end;
        d := lex_depth + 1;
        if lex_files[d].path = nil then
          lex_files[d].path := gspace(1023);
        open_file_to_get_info(name, full_path, dtm);
        lex_depth := d;
        if d > max_depth then begin
          saved_texts[d] := gspace(512);
          max_depth := lex_depth;
        end;
        with lex_files[lex_depth] do begin
          is_include := false;
          pos := lex_pos;
          text_len := lex_text.length;
          text_written := lex_text_written;
          hdr_written := lex_hdr_written;
          stream := cur_stream;
          region := spos_$region;
          in_comment := false;
          continued := false;
          comment_state := 0;
        end;
        len := lex_text.length;
        src := addr(lex_text.body);
        lib_$data_move(src, saved_texts[lex_depth], len);
        spos_$start_include_file(name, name, full_path, dtm, nil);
        lex_line := spos_$position;
        lex_pos := 1;
        lex_text.length := 0;
        lex_text_written := true;
        lex_hdr_written := true;
      end;
      if pop then begin
        with lex_files[lex_depth] do begin
          cur_stream := stream;
          lex_pos := pos;
          lex_text.length := text_len;
          lex_text_written := text_written;
          lex_hdr_written := hdr_written;
          len := lex_text.length;
          src := addr(lex_text.body);
          lib_$data_move(saved_texts[lex_depth], src, len);
          spos_$resume_file(region);
        end;
        lex_depth := lex_depth - 1;
      end;
      if not push then begin
        if spos_$is_main_source_file(spos_$region) and (name <> nil) then begin
          if first then begin
            open_file_to_get_info(name, full_path, dtm);
            spos_$change_file(name, name, full_path, dtm, nil, n);
            if lex_line = 1 then
              line_seen := false;
          end
          else
            spos_$change_file(name, name,
                              spos_$region_full_path_name(spos_$region),
                              spos_$region_dtm(spos_$region), nil, n);
        end
        else begin
          next_line := spos_$line + 1;
          if next_line <> n then
            spos_$skip_lines(n - next_line);
        end;
        lex_line := spos_$position;
      end;
      put_es_line(spos_$enquire_next_line, true);
      skip_line := true;
    end;

    { eject_sem - #eject: a page eject on the listing while it is on.

      0x053C48, 0x20 bytes, link #-8: unless nolist_depth or es
      (`moveq #3; and.b 0x2C3671'), ejctln. }

    procedure eject_sem;
    begin
      if (nolist_depth = 0) and (cargs_$options.es = 0) then
        ejctln;
    end;

    { list_sem - #list.  0x053C68, 0xC bytes, no frame. }

    procedure list_sem;
    begin
      if nolist_depth <> 0 then
        nolist_depth := nolist_depth - 1;
    end;

    { nolist_sem - #nolist.  0x053C74, 6 bytes, no frame: `addq.w
      #1,(9422,A5)'. }

    procedure nolist_sem;
    begin
      nolist_depth := nolist_depth + 1;
    end;

    { sect_id - the next token, a section's name.  0x053C7A, 0xC bytes,
      link #-8: get. }

    procedure sect_id;
    begin
      get;
    end;

    { module_sem - #module name [, code [, data]].

      0x053C86, 0x1D0 bytes, link #-8; parse_directive's frame in A1
      (kept in A2).  A second #module is error0(186); #module must come
      before the first line (mr_std_include_state 2, else error0(195)).
      The name (an identifier, else error1(5)) and lex_line go to the
      parent's mod_name and, when the outermost block is a module
      (106), into it (+296, two longwords).  The sections' names (after
      `,', ctk_comma) go to the module block's code and data sections'
      names (+188 and +192, then +8) at the end; a missing name or
      comma is error1(185) or error1(184), text after them
      error1(189).  Each error drops the line.

      Not known from the original:
      - how the error exits were written (a shared tail at 0x053E10
        here as gotos to the end). }

    procedure module_sem;
    label
      9, 10;
    var
      b: lex_block_ptr_t;
    begin
      if lex_module_seen then begin
        error0(186, lex_line);
        skip_line := true;
        return;
      end;
      code_name := nil;
      data_name := nil;
      if mr_std_include_state <> 2 then begin
        error0(195, lex_line);
        skip_line := true;
        return;
      end;
      lex_module_seen := true;
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        goto 9;
      end;
      get;
      if token_kind <> ctk_identifier then begin
        error1(5, lex_line, lex_token);
        goto 9;
      end;
      mod_name.name := lex_token;
      mod_name.line := lex_line;
      b := lex_block_ptr_t(cdef_outer_block);
      if b <> nil then
        if b^.kind = 106 then
          b^.mod_name := mod_name;
      if more_data_on_line then begin
        get;
        if token_kind <> ctk_comma then begin
          error1(185, lex_line, lex_token);
          goto 9;
        end;
        if not more_data_on_line then begin
          error1(185, lex_line, lex_token);
          goto 9;
        end;
        sect_id;
        if token_kind = ctk_identifier then begin
          code_name := lex_token;
          if more_data_on_line then begin
            get;
            if token_kind <> ctk_comma then begin
              error1(184, lex_line, lex_token);
              goto 9;
            end;
          end;
        end;
        if token_kind = ctk_comma then begin
          if not more_data_on_line then begin
            error1(185, lex_line, lex_token);
            goto 9;
          end;
          sect_id;
          if token_kind <> ctk_identifier then begin
            error1(184, lex_line, lex_token);
            goto 9;
          end;
          data_name := lex_token;
          if more_data_on_line then begin
            get;
            error1(189, lex_line, lex_token);
            goto 9;
          end;
        end;
      end;
      b := lex_block_ptr_t(cdef_outer_block);
      if code_name <> nil then
        b^.code_sect^.xp[2] := code_name;
      if data_name <> nil then
        b^.data_sect^.xp[2] := data_name;
      goto 10;
    9:
      skip_line := true;
    10:
    end;

    { section_sem - #section (code [, data]): the sections later
      routines and variables go to.

      0x053E56, 0x1F6 bytes, link #-8; parent's frame in A1.  Only at
      the outermost level (il_180 = cdef_outer_block; else error0(196)
      unless cerr_quiet, and the line dropped).  psect and dsect start
      as cdef_code_sect and cdef_data_sect; `(' (error1(165)), the code
      section's name (add_psect; nil is error1(187)) or none, `,' and
      the data section's (add_dsect; nil error1(188), a section of kind
      111 error1(194)); a missing name error1(117), `)' (error1(166)),
      nothing after it (error1(189)).  A missing argument error1(185).
      Each error drops the line; else both are stored.

      Not known from the original:
      - how the error exits were written (a shared tail at 0x054026). }

    procedure section_sem;
    label
      9;
    begin
      if il_180 <> cdef_outer_block then begin
        if not cerr_quiet then
          error0(196, lex_line);
        skip_line := true;
        return;
      end;
      psect := cdef_code_sect;
      dsect := cdef_data_sect;
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        goto 9;
      end;
      get;
      if token_kind <> ctk_lparen then begin
        error1(165, lex_line, lex_token);
        goto 9;
      end;
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        goto 9;
      end;
      sect_id;
      if token_kind = ctk_identifier then begin
        psect := add_psect(lex_token);
        if psect = nil then begin
          error1(187, lex_line, lex_token);
          goto 9;
        end;
        if not more_data_on_line then begin
          error1(185, lex_line, lex_token);
          goto 9;
        end;
        get;
      end
      else if token_kind <> ctk_comma then begin
        error1(117, lex_line, lex_token);
        goto 9;
      end;
      if token_kind = ctk_comma then begin
        if not more_data_on_line then begin
          error1(185, lex_line, lex_token);
          goto 9;
        end;
        sect_id;
        if token_kind <> ctk_identifier then begin
          error1(117, lex_line, lex_token);
          goto 9;
        end;
        dsect := add_dsect(lex_token);
        if dsect = nil then begin
          error1(188, lex_line, lex_token);
          goto 9;
        end;
        if dsect^.kind = 111 then begin
          error1(194, lex_line, lex_token);
          goto 9;
        end;
        if not more_data_on_line then begin
          error1(185, lex_line, lex_token);
          goto 9;
        end;
        get;
      end;
      if token_kind <> ctk_rparen then begin
        error1(166, lex_line, lex_token);
        goto 9;
      end;
      if more_data_on_line then begin
        get;
        error1(189, lex_line, lex_token);
        goto 9;
      end;
      cdef_code_sect := psect;
      cdef_data_sect := dsect;
      return;
    9:
      skip_line := true;
    end;

    { systype_sem - #systype "type".

      0x05404C, 0x112 bytes, link #-8; parent's frame in A1.  The
      argument must be a string (error1(185) missing, error1(169)); a
      second #systype is error0(182), one after the first line
      (mr_std_include_state not 2) error0(183); both drop the line.
      c_$decode_version(the text, its length less the NUL (the parent's
      -34), v1 (-38), v2 (-36)): false is error1(179); v1 = 2 sets
      uobj_systype_2 (`st 0x1A612A'), else the environment variables
      SYSTYPE and COMPILESYSTYPE are set to the text (ev_$set_var, the
      names' lengths from the literals at 0x05415E and 0x05416E);
      lex_systype_state := 2.

      Not known from the original:
      - whether ev_$set_var's results were read (they are not). }

    procedure systype_sem;
    begin
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        skip_line := true;
        return;
      end;
      get;
      if token_kind <> ctk_string then begin
        error1(169, lex_line, lex_token);
        skip_line := true;
        return;
      end;
      if lex_systype_state <> 0 then begin
        error0(182, lex_line);
        skip_line := true;
        return;
      end;
      if mr_std_include_state <> 2 then begin
        error0(183, lex_line);
        skip_line := true;
        return;
      end;
      sys_len := lex_token^.str_len - 1;
      if c_$decode_version(lex_token^.str_chars, sys_len, sys_v1, sys_v2) then begin
        if sys_v1 = 2 then
          uobj_systype_2 := true
        else begin
          discard(ev_$set_var('SYSTYPE', 7, lex_token^.str_chars, sys_len));
          discard(ev_$set_var('COMPILESYSTYPE', 14, lex_token^.str_chars, sys_len));
        end;
        lex_systype_state := 2;
      end
      else
        error1(179, lex_line, lex_token);
    end;

    { hp_standard_sem - #pragma HP_STANDARD n: bit n (0..31) of
      uobj_hp_standard.

      0x054178, 0x7C bytes, link #-16.  The result of the checks in D2
      (true first): the next token must be an integer constant (its
      kind in the set at 0x0541F4: 77..87, 101, 200; docs/dpc-gaps.md
      8) of 0..31 (`bmi', `cmpi.l #31; bgt'); `moveq #1; lsl.l; or.l'
      into 0x1A60E4.  Else error1(310) and the line dropped. }

    procedure hp_standard_sem;
    var
      ok: boolean;
      n: integer32;
    begin
      ok := true;
      if more_data_on_line then
        get
      else
        ok := false;
      if ok then
        if token_kind in [77..87, 101, 200] then begin
          n := lex_token^.int_value;
          if (n >= 0) and (n <= 31) then
            uobj_hp_standard := uobj_hp_standard ! lshft(1, n)
          else
            ok := false;
        end
        else
          ok := false;
      if not ok then begin
        error1(310, lex_line, lex_token);
        skip_line := true;
      end;
    end;

    { do_pragma - #pragma name.

      0x05420E, 0x30E bytes, link #-16; parse_directive's frame from its
      dynamic link (passed on in A1).  The name must be an identifier;
      compared (compare_bytes, the literals from 0x05451C, some sharing
      bytes): natural_alignment, word_alignment (attr_set_align_env 1,
      0), push_alignment, pop_alignment, begin_inline, end_inline,
      begin_noinline, end_noinline (lex_inline_state; out of order
      error0(276)), LIST ON / LIST OFF, HP_SECTION, HP_MODULE,
      HP_SYSTYPE, PAGE, HP_STANDARD.  Anything else, or text after the
      pragma, is error0(253) and the line dropped (bad in D2).

      Not known from the original:
      - the local's name. }

    procedure do_pragma;
    var
      bad: boolean;
      p: il_$node_ptr_t;
    begin
      bad := false;
      if token_kind <> ctk_identifier then
        bad := true
      else begin
        p := lex_token;
        if compare_bytes(p^.idnt_name, p^.idnt_len, 'natural_alignment', 17) = 0 then
          attr_set_align_env(1)
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'word_alignment', 14) = 0 then
          attr_set_align_env(0)
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'push_alignment', 14) = 0 then
          attr_push_align
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'pop_alignment', 13) = 0 then
          attr_pop_align
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'begin_inline', 12) = 0 then begin
          if lex_inline_state <> 0 then
            error0(276, lex_line)
          else
            lex_inline_state := 1;
        end
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'end_inline', 10) = 0 then begin
          if lex_inline_state = 1 then
            lex_inline_state := 0
          else
            error0(276, lex_line);
        end
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'begin_noinline', 14) = 0 then begin
          if lex_inline_state <> 0 then
            error0(276, lex_line)
          else
            lex_inline_state := 2;
        end
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'end_noinline', 12) = 0 then begin
          if lex_inline_state = 2 then
            lex_inline_state := 0
          else
            error0(276, lex_line);
        end
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'LIST', 4) = 0 then begin
          if more_data_on_line then
            get
          else
            bad := true;
          if token_kind <> ctk_identifier then
            bad := true
          else begin
            p := lex_token;
            if compare_bytes(p^.idnt_name, p^.idnt_len, 'ON', 2) = 0 then
              list_sem
            else begin
              p := lex_token;
              if compare_bytes(p^.idnt_name, p^.idnt_len, 'OFF', 3) = 0 then
                nolist_sem
              else
                bad := true;
            end;
          end;
        end
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'HP_SECTION', 10) = 0 then
          section_sem
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'HP_MODULE', 9) = 0 then
          module_sem
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'HP_SYSTYPE', 10) = 0 then
          systype_sem
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'PAGE', 4) = 0 then
          eject_sem
        else if compare_bytes(p^.idnt_name, p^.idnt_len, 'HP_STANDARD', 11) = 0 then
          hp_standard_sem
        else
          bad := true;
      end;
      if bad or else more_data_on_line then begin
        error0(253, lex_line);
        skip_line := true;
      end;
    end;

  begin { parse_directive }
    if token_kind = ctk_int_con then begin
      discard(line_sem);
      return;
    end;
    if token_kind <> ctk_identifier then begin
      error1(47, lex_line, lex_token);
      skip_line := true;
      return;
    end;
    p := lex_token;
    if compare_bytes(p^.idnt_name, p^.idnt_len, 'pragma', 6) = 0 then begin
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        skip_line := true;
        return;
      end;
      get;
      do_pragma;
    end
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'include', 7) = 0 then begin
      if hash_col <> 9 then
        error1(50, lex_line, lex_token);
      in_include_directive := true;
      get;
      in_include_directive := false;
      if token_kind <> ctk_string then begin
        error1(48, lex_line, lex_token);
        skip_line := true;
        return;
      end;
      include_name := lex_token;
    end
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'line', 4) = 0 then begin
      if not more_data_on_line then begin
        error1(185, lex_line, lex_token);
        skip_line := true;
        return;
      end;
      get;
      discard(line_sem);
    end
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'ident', 5) = 0 then
      skip_line := true
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'list', 4) = 0 then
      list_sem
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'nolist', 6) = 0 then
      nolist_sem
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'section', 7) = 0 then
      section_sem
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'module', 6) = 0 then
      module_sem
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'systype', 7) = 0 then
      systype_sem
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'eject', 5) = 0 then
      eject_sem
    else if (compare_bytes(p^.idnt_name, p^.idnt_len, 'apollo', 6) = 0) or else
            (compare_bytes(p^.idnt_name, p^.idnt_len, 'apollo_bit', 10) = 0) then
      cargs_$options.b27b_4 := true
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'debug', 5) = 0 then
      skip_line := not cargs_$options.cond
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'inhibit', 7) = 0 then
      set_ecb_bit(0)
    else if compare_bytes(p^.idnt_name, p^.idnt_len, 'backstop', 8) = 0 then
      set_ecb_bit(1)
    else begin
      error1(50, lex_line, lex_token);
      skip_line := true;
    end;
  end;

  { open_include - open the file include_name names and read on in it.

    0x05494C, 0x2B0 bytes, link #-292.  A depth past 16 is error0(49),
    spos_$may_start_include_file false error0(95).  The next entry of
    lex_files gets its path buffer (gspace(1023)) when it has none;
    open_include_list_sub(include_name, string_delim, sid (-276), the
    path, path_len, in_first (-278)).  When the file opened: the
    including file's text goes to saved_texts (made when the depth is
    new), and with -USRCH (`btst #5,0x2C3669') inc_list_idirs[1] is
    saved and replaced by the new file's directory (dir_name, 1026
    bytes from gspace: the path as c_$map_to_apollo_cond maps it, or as
    it is when it was found in the first directory (a 1024-byte copy),
    less its leaf (name_$strip_leaf_lc, 255 the length allowed)); the
    including file's position, flags, stream and region are saved and
    spos_$start_include_file(include_name, strtk of the path, the
    stream's full path name and dtm, nil); the new file starts empty
    (lex_pos 1, lex_text empty, both written flags set) on its stream;
    put_es_line(the next line, true).  Else error1(51), and when it was
    the implicit #include mr_std_include_state := 0; include_name is
    cleared.

    Not known from the original:
    - the locals' names. }

  procedure open_include;
  var
    sid: integer;
    in_first: boolean;
    d: integer;
    f: ^lex_file_t;
    len: integer;
    leaf: name_$long_name_t;
    leaf_len: integer;
    status: status_$t;
    n: integer32;
    src: univ_ptr;
  begin
    if lex_depth >= 16 then begin
      error0(49, lex_line);
      return;
    end;
    if not spos_$may_start_include_file then begin
      error0(95, lex_line);
      return;
    end;
    d := lex_depth + 1;
    if lex_files[d].path = nil then
      lex_files[d].path := gspace(1023);
    if open_include_list_sub(include_name, string_delim, sid,
                             lex_files[d].path^, lex_files[d].path_len,
                             in_first) then begin
      lex_depth := d;
      if d > max_depth then begin
        saved_texts[d] := gspace(512);
        max_depth := lex_depth;
      end;
      f := addr(lex_files[lex_depth]);
      if cargs_$options.usrch then begin
        f^.saved_idir := inc_list_idirs[1];
        if f^.dir_name = nil then
          f^.dir_name := gspace(1026);
        if not in_first then
          c_$map_to_apollo_cond(f^.path^, f^.path_len, f^.dir_name^.body,
                                f^.dir_name^.length)
        else begin
          f^.dir_name^.body := f^.path^;
          f^.dir_name^.length := f^.path_len;
        end;
        len := f^.dir_name^.length;
        name_$strip_leaf_lc(f^.dir_name^.body, len, 255, f^.dir_name^.length,
                            leaf, leaf_len, status);
        inc_list_idirs[1] := f^.dir_name;
      end;
      f^.is_include := true;
      f^.pos := lex_pos;
      f^.text_len := lex_text.length;
      f^.text_written := lex_text_written;
      f^.hdr_written := lex_hdr_written;
      f^.stream := cur_stream;
      f^.region := spos_$region;
      f^.in_comment := false;
      f^.continued := false;
      f^.comment_state := 0;
      n := lex_text.length;
      src := addr(lex_text.body);
      lib_$data_move(src, saved_texts[lex_depth], n);
      spos_$start_include_file(
          include_name,
          strtk(lex_files[lex_depth].path^, lex_files[lex_depth].path_len),
          iosub_$get_full_path_name(sid),
          iosub_$get_dtm(sid),
          nil);
      lex_line := spos_$position;
      lex_pos := 1;
      lex_text.length := 0;
      lex_text_written := true;
      lex_hdr_written := true;
      cur_stream := sid;
      put_es_line(spos_$enquire_next_line, true);
    end
    else begin
      error1(51, lex_line, include_name);
      if std_include_tok = include_name then
        mr_std_include_state := 0;
      include_name := nil;
    end;
  end;

  { pp_get_line - the next line into lex_text; true at the end of the
    source.

    0x054BFE, 0x1BC bytes, link #-16.  The result in D4.  A loop: the
    line from cr_$get_cooked_line (internal_cpp; its kind in D2) or
    ppio_$get_line (kind 5 at the end, else 0), into lex_text from
    character 9 (+0x24E8); kind 5 ends the source.  lex_text's length
    is len + 8, lex_pos 9, characters 1..8 the listing's number field;
    last (D5) the length less a final newline.  With -ES, a line not
    beginning with `#' after blanks and tabs (and not an #if's
    expression, kinds 3 and 4) is written after put_es_line(lex_line,
    false).  Under -EXP (`btst #1,0x2C3666') with the listing on, an
    ordinary line c_macro_read expanded is listed again with a blank
    number field, and listed_len cleared.  Kind 3 (an #if's
    expression): lex_fatal cleared, get, and cr_$if_is_on when
    pp_constant is not 0; the loop goes on.  Kinds 0, 4 and 6 are the
    line; kind 1 is reported as an error (error_text), kind 2 as a
    warning, and the loop goes on.

    Not known from the original:
    - the locals' names; how the loop's exits were written. }

  function pp_get_line: boolean;
  var
    len: integer;
    kind: integer;
    n: integer;
    last: integer;
    i: integer;
  begin
    pp_get_line := false;
    repeat
      if internal_cpp then begin
        kind := cr_$get_cooked_line(len, lex_text.body[9]);
        n := len;
      end
      else begin
        ppio_$get_line(len, lex_text.body[9]);
        n := len;
        if n < 0 then
          kind := 5
        else
          kind := 0;
      end;
      if kind = 5 then begin
        pp_get_line := true;
        return;
      end;
      lex_text.length := n + 8;
      lex_pos := 9;
      for i := 1 to 8 do
        lex_text.body[i] := lex_listing_line.number[i];
      if lex_text.body[lex_text.length] = chr(10) then
        last := n - 1
      else
        last := n;
      if (kind <> 4) and (cargs_$options.es <> 0) and (kind <> 3) then begin
        i := lex_pos;
        while (lex_text.body[i] = ' ') or (lex_text.body[i] = chr(9)) do
          i := i + 1;
        if lex_text.body[i] <> '#' then begin
          put_es_line(lex_line, false);
          write_ln(1, addr(lex_text.body[9]), last);
        end;
      end;
      if (kind <> 6) and (kind <> 2) and (kind <> 1) and (nolist_depth = 0) and
         cargs_$options.exp then begin
        if lex_macro_expanded then begin
          for i := 1 to 8 do
            lex_text.body[i] := ' ';
          write_ln(1, addr(lex_text.body[1]), last + 8);
        end;
        listed_len := 0;
      end;
      if kind = 3 then begin
        lex_fatal := false;
        get;
        if pp_constant <> 0 then
          cr_$if_is_on;
      end
      else if (kind = 0) or (kind = 6) or (kind = 4) then
        return
      else if kind = 1 then
        error_text(lex_line, lex_text.body[9], n)
      else if kind = 2 then
        warning_text(lex_line, lex_text.body[9], n);
    until false;
  end;

  { get_character - the next character to ch (reading on at the end of
    the line; the end of the source leaves get).

    0x054DBA, 0x40 bytes, link #-4; get's frame in A1, kept at (-4,A6)
    for the goto.  `bhi' (lex_pos past the length, unsigned). }

  procedure get_character;
  begin
    while lex_pos > lex_text.length do
      if pp_get_line then
        goto 99;  { non-local }
    ch := lex_text.body[lex_pos];
    lex_pos := lex_pos + 1;
  end;

  { get_comment - skip a comment to the delim `/' that closes it.

    0x054DFA, 0x90 bytes, link #-12; get's frame from its dynamic link
    (the goto passes (A6)).  The line it began on (-8); a counted loop
    over the rest of each line; at the end of the source error0(1) at
    that line, and when the token is ctk_eof (ppio_$get_line set it)
    get is left.

    Not known from the original:
    - the names. }

  procedure get_comment(
      delim: char); options(val_param);
  var
    start_line: integer;
    i: integer;
  begin
    start_line := lex_line;
    repeat
      for i := lex_pos to lex_text.length do
        if (lex_text.body[i] = delim) and (i < lex_text.length) and
           (lex_text.body[i + 1] = '/') then begin
          lex_pos := i + 2;
          return;
        end;
    until pp_get_line;
    error0(1, start_line);
    if lex_tokens[ctk_eof] = lex_token then
      goto 99;  { non-local }
  end;

  { get_backslash_char - the character an escape sequence (after the
    backslash, ch its first character) stands for.

    0x054E8A, 0x1AE bytes, link #-20; get's frame in A1 (A2).  Up to
    three octal digits (the set at 0x055050, '0'..'7'; `lsl.l #3'),
    lex_pos moved back over the character after them; a hexadecimal
    sequence after `x' (`lsl.l #4'; the sets at 0x055038 'a'..'f',
    0x055046 'A'..'F', 0x055058 '0'..'9'); with -XANSI a value past 255
    is error1(288) of its constant node.  The letters n t b r f v a by
    the jump table at 0x054F38; any other character stands for itself.

    Not known from the original:
    - the locals' names. }

  function get_backslash_char: char;
  var
    v: integer32;
    d: integer;
    i: integer;
    done: boolean;
  begin
    if ch in ['0'..'7'] then begin
      v := 0;
      for i := 1 to 3 do begin
        if not (ch in ['0'..'7']) then
          exit;
        v := lshft(v, 3) + (ord(ch) - 48);
        get_character;
      end;
      lex_pos := lex_pos - 1;
      if cargs_$options.xansi and (v > 255) then
        error1(288, lex_line, smcontk(81, v));
      get_backslash_char := chr(v);
    end
    else
      case ch of
        'n': get_backslash_char := chr(10);
        'x': begin
          v := 0;
          d := 0;
          done := false;
          repeat
            v := lshft(v, 4) + d;
            get_character;
            if ch in ['a'..'f'] then
              d := ord(ch) - 87
            else if ch in ['A'..'F'] then
              d := ord(ch) - 55
            else if ch in ['0'..'9'] then
              d := ord(ch) - 48
            else begin
              lex_pos := lex_pos - 1;
              done := true;
            end;
          until done;
          if cargs_$options.xansi and (v > 255) then
            error1(288, lex_line, smcontk(81, v));
          get_backslash_char := chr(v);
        end;
        't': get_backslash_char := chr(9);
        'b': get_backslash_char := chr(8);
        'r': get_backslash_char := chr(13);
        'f': get_backslash_char := chr(12);
        'v': get_backslash_char := chr(11);
        'a': get_backslash_char := chr(7);
        otherwise get_backslash_char := ch;
      end;
  end;

  { get_string - a string up to delim (`"', or `>' for an #include's
    <name>) to lex_token, a NUL added.

    0x055060, 0xC4 bytes, link #-4112; get's frame in A1 (A2).  The
    characters in a frame array (-4104); the count in D3, compared
    unsigned with 4094 (`bls').  A newline is error0(3) and ends the
    string; a backslash (not in an #include) escapes (a backslash-
    newline is dropped); past 4094 characters error0(6) and the rest
    is skipped to a `;'.  strtk(.., count).

    Not known from the original:
    - the locals' names and the array's bound. }

  procedure get_string(
      delim: char); options(val_param);
  var
    n: 0..4096;
    c: char;
    buf: array [1..4096] of char;
  begin
    string_delim := delim;
    n := 0;
    repeat
      get_character;
      c := ch;
      if (c = delim) or (n > 4094) then
        exit;
      if c = chr(10) then begin
        error0(3, lex_line);
        exit;
      end;
      if not in_include_directive and (c = '\') then begin
        get_character;
        c := ch;
        if c = chr(10) then
          next;
        c := get_backslash_char;
      end;
      n := n + 1;
      buf[n] := c;
    until false;
    if n > 4094 then begin
      error0(6, lex_line);
      while ch <> ';' do
        get_character;
    end;
    n := n + 1;
    buf[n] := chr(0);
    lex_token := strtk(buf, n);
  end;

  { get_wstring - a wide string (L"..."): a string token of kind 93
    whose characters are longwords.

    0x055124, 0xCA bytes, link #-16; get's frame in A1.  get_string,
    then with have_mbtowc mbstowcs(wide_buf, the characters, 4095) (a
    negative count is error0(289) and 1; 4095, error0(6); else one
    more, the NUL), else each character widened (zero-extended).
    strtk(wide_buf, 4 * count), its kind made 93.

    Not known from the original:
    - the locals' names. }

  procedure get_wstring;
  var
    n: integer;
    i: integer;
    p: il_$node_ptr_t;
  begin
    get_string('"');
    p := lex_token;
    if have_mbtowc then begin
      n := mbstowcs(wide_buf, p^.str_chars, 4095);
      if n < 0 then begin
        error0(289, lex_line);
        n := 1;
      end
      else if n = 4095 then
        error0(6, lex_line)
      else
        n := n + 1;
    end
    else begin
      for i := 1 to p^.str_len do
        wide_buf[i] := ord(p^.str_chars[i]);
      n := p^.str_len;
    end;
    lex_token := strtk(wide_buf, n * 4);
    lex_token^.kind := ctk_wstring;
  end;

  { get_char_const - a character constant (up to four characters) to
    lex_token, an integer constant.

    0x0551EE, 0xB6 bytes, link #-12; get's frame in A1 (A2: quote_state
    at (-2,A2)).  The value in D2 (`lsl.l #8; or.l'), the first
    character sign-extended (`tst.b; bpl; ori.l #-256'); the count in
    D3.  A backslash-newline is skipped; no closing quote after four
    characters is error0(3).  smcontk(81, value).

    Not known from the original:
    - the locals' names. }

  procedure get_char_const;
  var
    v: integer32;
    n: integer;
  begin
    quote_state := 1;
    v := 0;
    get_character;
    n := 0;
    while n < 4 do begin
      if ch = '\' then begin
        get_character;
        if ch = chr(10) then begin
          get_character;
          next;
        end;
        ch := get_backslash_char;
      end;
      n := n + 1;
      v := lshft(v, 8) ! ord(ch);
      if (n = 1) and (v >= 128) then
        v := v ! (-256);
      get_character;
      if ch = '''' then
        exit;
    end;
    if ch <> '''' then
      error0(3, lex_line);
    quote_state := 0;
    lex_token := smcontk(ctk_int_con, v);
  end;

  { get_wchar_const - a wide character constant: kind 85.

    0x0552A4, 0x2C bytes, link #-4; get's frame in A1, passed on. }

  procedure get_wchar_const;
  begin
    get_char_const;
    lex_token := smcontk(ctk_unsigned_con, lex_token^.int_value);
  end;

  { peekchar - the next character without taking it (chr(0) past the
    line's end).  0x0552D0, 0x1C bytes, no frame: `bls'. }

  function peekchar: char;
  begin
    if lex_pos > lex_text.length then
      peekchar := chr(0)
    else
      peekchar := lex_text.body[lex_pos];
  end;

  { get_wchar_t - after an `L': a wide string or character constant
    when a quote follows (true), else false (an identifier).

    0x0552EC, 0x4A bytes, link #-8; get's frame from its dynamic link
    (passed in A1).  The character zero-extended and compared (`cmpi.w
    #34', `#39'). }

  function get_wchar_t: boolean;
  begin
    case peekchar of
      '"': begin
        get_character;
        get_wstring;
      end;
      '''': begin
        get_character;
        get_wchar_const;
      end;
      otherwise begin
        get_wchar_t := false;
        return;
      end;
    end;
    get_wchar_t := true;
  end;

  { get_identifier - an identifier (ch its first character) to
    lex_token (idntk(76, ...): a reserved word comes back as its own
    entry, of its class).

    0x055336, 0xA8 bytes, link #-4112; get's frame from its dynamic
    link (for the goto).  The characters in a frame array (-4104), the
    count in D2 (`cmpi.w #4096; bcc'); more than 4096 is error1(197)
    after the token is made.  The next character is read in place
    (pp_get_line at the line's end, `bls'); the set at 0x0553DE
    ('a'..'z', 'A'..'Z', '0'..'9', '_', '$').  lex_pos is moved back
    over the character after it.

    Not known from the original:
    - the locals' names and the array's bound. }

  procedure get_identifier;
  var
    n: 0..4096;
    c: char;
    clipped: boolean;
    buf: array [1..4096] of char;
  begin
    n := 0;
    c := ch;
    clipped := false;
    repeat
      if n < 4096 then begin
        n := n + 1;
        buf[n] := c;
      end
      else
        clipped := true;
      if lex_pos > lex_text.length then
        if pp_get_line then
          goto 99;  { non-local }
      c := lex_text.body[lex_pos];
      lex_pos := lex_pos + 1;
    until not (c in ['a'..'z', 'A'..'Z', '0'..'9', '_', '$']);
    lex_token := idntk(ctk_identifier, buf, n);
    lex_pos := lex_pos - 1;
    if clipped then
      error1(197, lex_line, lex_token);
  end;

  { get_number - a number (ch its first character, or `.' for one
    beginning `.digit') to lex_token.

    0x0554C8, 0x2C6 bytes, link #-40; get's frame from its dynamic
    link.  The locals: the digits kept (-26, in fp_digits), the base
    (-24), the integer's kind (-22), the real's value (-16, a double
    cleared word by word), lib_$cv_fp_in's overflow (-34).  A leading
    0 makes the base 8 (the zeros skipped), 0x or 0X 16.  An integer:
    kind 81, `L' 82, `LU' and `U' (`UL') 85; a value past 32767 is 82,
    a negative one (wrapped) under -XANSI 85; smcontk.  A real (a `.',
    `e' or `E' after the integer part): the fraction's digits (each
    lowering the exponent), the exponent, `F' (single) or `L';
    lib_$cv_fp_in(fp_digits, count, exponent, false, true, value,
    overflow); a hexadecimal real or an overflow is error0(2) and 0.  A
    single is rlcontk, and outside the single's range (the immediate
    doubles 3.402823466e38 and its negative compared by fpp_$, `sgt',
    `slt', `or.b'; docs/dpc-gaps.md 7) error0(2); a double dpcontk.
    Last lex_pos is moved back over the character after the number.

    Not known from the original:
    - the locals' names (D4 holds the base-16 flag and then the
      overflow; here two variables). }

  procedure get_number;
  var
    ndigits: integer;
    base: integer;
    kind: integer;
    r: record case integer of
      1: (d: double);
      2: (w: array [1..4] of integer);
    end;
    overflow: boolean;
    value: integer32;
    exp: integer;
    hex: boolean;
    single: boolean;
    i: integer;

    { get_integer - the digits of base from ch on (a letter or digit
      not a digit of base ends it; 8 and 9 in an octal number are
      error0(177) and taken); with save each digit (up to 64) goes to
      fp_digits.

      0x0553EE, 0xCC bytes, link #-20; get_number's frame from its
      dynamic link, get's from that frame's (passed to get_character).
      The value in D3 (`m$mis$llw': value * base); the digit in D4
      (the set at 0x0554BA: 'a'..'f', 'A'..'F', '0'..'9'; - 48, - 39
      from 'a', - 7 from 'A').

      Not known from the original:
      - the names. }

    function get_integer(
        base: integer;
        save: boolean): integer32; options(val_param);
    var
      v: integer32;
      d: integer;
    begin
      v := 0;
      while ch in ['a'..'f', 'A'..'F', '0'..'9'] do begin
        d := ord(ch) - 48;
        if ch >= 'a' then
          d := d - 39
        else if ch >= 'A' then
          d := d - 7;
        if d >= base then begin
          if base <> 8 then
            exit;
          if d > 9 then
            exit;
          if (base = 8) and ((d = 8) or (d = 9)) then
            error0(177, lex_line);
        end;
        if save and (ndigits < 64) then begin
          ndigits := ndigits + 1;
          fp_digits[ndigits] := ch;
        end;
        v := v * base + d;
        get_character;
      end;
      get_integer := v;
    end;

  begin { get_number }
    ndigits := 0;
    base := 10;
    if ch = '0' then begin
      base := 8;
      while ch = '0' do
        get_character;
      if (ch = 'X') or (ch = 'x') then begin
        base := 16;
        get_character;
      end;
    end;
    if ch = '.' then
      value := 0
    else
      value := get_integer(base, true);
    if (ch = 'e') or (ch = '.') or (ch = 'E') then begin
      exp := 0;
      hex := false;
      if base = 16 then
        hex := true;
      if ch = '.' then begin
        get_character;
        while ch in ['0'..'9'] do begin
          if ndigits < 64 then begin
            ndigits := ndigits + 1;
            fp_digits[ndigits] := ch;
            exp := exp - 1;
          end;
          get_character;
        end;
      end;
      if (ch = 'E') or (ch = 'e') then begin
        get_character;
        if ch = '+' then begin
          get_character;
          exp := exp + get_integer(10, false);
        end
        else if ch = '-' then begin
          get_character;
          exp := exp - get_integer(10, false);
        end
        else
          exp := exp + get_integer(10, false);
      end;
      single := false;
      if (ch = 'F') or (ch = 'f') then begin
        get_character;
        single := true;
      end
      else if (ch = 'L') or (ch = 'l') then
        get_character;
      if hex then
        overflow := true
      else
        lib_$cv_fp_in(fp_digits, ndigits, exp, false, true, r, overflow);
      if overflow then begin
        error0(2, lex_line);
        for i := 1 to 4 do
          r.w[i] := 0;
      end;
      if single then begin
        lex_token := rlcontk(r.d);
        if not overflow then
          if (lex_token^.real_value > 3.402823466e38) or
             (lex_token^.real_value < -3.402823466e38) then
            error0(2, lex_line);
      end
      else
        lex_token := dpcontk(r.d);
    end
    else begin
      kind := ctk_int_con;
      if (ch = 'L') or (ch = 'l') then begin
        get_character;
        kind := ctk_long_con;
        if (ch = 'U') or (ch = 'u') then begin
          get_character;
          kind := ctk_unsigned_con;
        end;
      end
      else if (ch = 'U') or (ch = 'u') then begin
        get_character;
        kind := ctk_unsigned_con;
        if (ch = 'L') or (ch = 'l') then begin
          get_character;
          kind := ctk_unsigned_con;
        end;
      end;
      if value > 32767 then
        kind := ctk_long_con;
      if cargs_$options.xansi and (value < 0) then
        kind := ctk_unsigned_con;
      lex_token := smcontk(kind, value);
    end;
    lex_pos := lex_pos - 1;
  end;

  { check_op_asn - an `=' follows (an operator's assignment form; under
    -NXANSI blanks, tabs, newlines and form feeds may come between),
    taken; else lex_pos moved back and false.

    0x05578E, 0x5C bytes, link #-8; get's frame from its dynamic link
    (passed in A1).  The result in D2 (true first). }

  function check_op_asn: boolean;
  begin
    check_op_asn := true;
    get_character;
    if not cargs_$options.xansi then
      while (ch = chr(9)) or (ch = chr(10)) or (ch = ' ') or (ch = chr(12)) do
        get_character;
    if ch <> '=' then begin
      lex_pos := lex_pos - 1;
      check_op_asn := false;
    end;
  end;

begin { get }
  if unget_token <> nil then begin
    token_kind := unget_kind;
    lex_token := unget_token;
    unget_token := nil;
    return;
  end;
  skip_line := false;
  lex_token := nil;
  quote_state := 0;
  repeat
    if skip_line then begin
      lex_pos := lex_text.length + 1;
      skip_line := false;
    end;
    repeat
      for tok_start := lex_pos to lex_text.length do
        if (lex_text.body[tok_start] <> ' ') and (lex_text.body[tok_start] <> chr(9)) and
           (lex_text.body[tok_start] <> chr(12)) then
          goto 1;
      if pp_get_line then
        goto 99;
    until false;
  1:
    lex_pos := tok_start + 1;
    ch := lex_text.body[tok_start];
    if ch = 'L' then begin
      if not get_wchar_t then
        get_identifier;
      goto 2;
    end;
    if ch in ['a'..'z', 'A'..'Z', '_', '$'] then begin
      get_identifier;
      goto 2;
    end;
    if (ch >= '0') and (ch <= '9') then begin
      get_number;
      goto 2;
    end;
    case ch of
      '.': begin
        get_character;
        if ch = '.' then begin
          get_character;
          if ch = '.' then
            lex_token := lex_tokens[ctk_ellipsis]
          else
            lex_pos := lex_pos - 1;
        end
        else begin
          lex_pos := lex_pos - 1;
          if (ch >= '0') and (ch <= '9') then begin
            ch := '.';
            get_number;
          end
          else
            lex_token := lex_tokens[ctk_dot];
        end;
      end;
      '=': begin
        get_character;
        if ch = '=' then
          lex_token := lex_tokens[ctk_eq]
        else if cargs_$options.xansi then begin
          lex_pos := lex_pos - 1;
          lex_token := lex_tokens[ctk_assign];
        end
        else begin
          case ch of
            '+': lex_token := lex_tokens[lex_add_assign];
            '-': lex_token := lex_tokens[lex_sub_assign];
            '*': lex_token := lex_tokens[lex_mul_assign];
            '/': lex_token := lex_tokens[lex_div_assign];
            '%': lex_token := lex_tokens[lex_mod_assign];
            '&': lex_token := lex_tokens[lex_and_assign];
            '^': lex_token := lex_tokens[lex_xor_assign];
            '|': lex_token := lex_tokens[lex_or_assign];
            '<': begin
              get_character;
              if ch = '<' then
                lex_token := lex_tokens[lex_shl_assign]
              else begin
                lex_token := lex_tokens[ctk_other_char];
                lex_token^.idnt_name[1] := ch;
              end;
            end;
            '>': begin
              get_character;
              if ch = '>' then
                lex_token := lex_tokens[lex_shr_assign]
              else begin
                lex_token := lex_tokens[ctk_other_char];
                lex_token^.idnt_name[1] := ch;
              end;
            end;
            otherwise begin
              lex_pos := lex_pos - 1;
              lex_token := lex_tokens[ctk_assign];
              goto 99;
            end;
          end;
          error1(8, lex_line, lex_token);
        end;
      end;
      '<': begin
        if in_include_directive then
          get_string('>')
        else begin
          get_character;
          if ch = '=' then
            lex_token := lex_tokens[ctk_le]
          else if ch = '<' then begin
            if check_op_asn then
              lex_token := lex_tokens[lex_shl_assign]
            else
              lex_token := lex_tokens[ctk_shl];
          end
          else begin
            lex_pos := lex_pos - 1;
            lex_token := lex_tokens[ctk_lt];
          end;
        end;
      end;
      '>': begin
        get_character;
        if ch = '=' then
          lex_token := lex_tokens[ctk_ge]
        else if ch = '>' then begin
          if check_op_asn then
            lex_token := lex_tokens[lex_shr_assign]
          else
            lex_token := lex_tokens[ctk_shr];
        end
        else begin
          lex_pos := lex_pos - 1;
          lex_token := lex_tokens[ctk_gt];
        end;
      end;
      '"': begin
        quote_state := 2;
        get_string('"');
        quote_state := 0;
      end;
      '''': get_char_const;
      '{': lex_token := lex_tokens[ctk_lbrace];
      '}': lex_token := lex_tokens[ctk_rbrace];
      '(': lex_token := lex_tokens[ctk_lparen];
      ')': lex_token := lex_tokens[ctk_rparen];
      '[': lex_token := lex_tokens[ctk_lbracket];
      ']': lex_token := lex_tokens[ctk_rbracket];
      ',': lex_token := lex_tokens[ctk_comma];
      ':': lex_token := lex_tokens[ctk_colon];
      '~': lex_token := lex_tokens[ctk_tilde];
      ';': lex_token := lex_tokens[ctk_semicolon];
      '?': lex_token := lex_tokens[ctk_question];
      '+': begin
        get_character;
        if ch = '+' then
          lex_token := lex_tokens[ctk_incr]
        else begin
          lex_pos := lex_pos - 1;
          if check_op_asn then
            lex_token := lex_tokens[lex_add_assign]
          else
            lex_token := lex_tokens[ctk_plus];
        end;
      end;
      '-': begin
        get_character;
        if ch = '-' then
          lex_token := lex_tokens[ctk_decr]
        else if ch = '>' then
          lex_token := lex_tokens[ctk_arrow]
        else begin
          lex_pos := lex_pos - 1;
          if check_op_asn then
            lex_token := lex_tokens[lex_sub_assign]
          else
            lex_token := lex_tokens[ctk_minus];
        end;
      end;
      '*': begin
        if check_op_asn then
          lex_token := lex_tokens[lex_mul_assign]
        else
          lex_token := lex_tokens[ctk_star];
      end;
      '/': begin
        get_character;
        if ch = '*' then begin
          quote_state := 3;
          get_comment('*');
          quote_state := 0;
        end
        else begin
          lex_pos := lex_pos - 1;
          if check_op_asn then
            lex_token := lex_tokens[lex_div_assign]
          else
            lex_token := lex_tokens[ctk_slash];
        end;
      end;
      '%': begin
        if check_op_asn then
          lex_token := lex_tokens[lex_mod_assign]
        else
          lex_token := lex_tokens[ctk_percent];
      end;
      '^': begin
        if check_op_asn then
          lex_token := lex_tokens[lex_xor_assign]
        else
          lex_token := lex_tokens[ctk_caret];
      end;
      '&': begin
        get_character;
        if ch = '&' then
          lex_token := lex_tokens[ctk_andand]
        else begin
          lex_pos := lex_pos - 1;
          if check_op_asn then
            lex_token := lex_tokens[lex_and_assign]
          else
            lex_token := lex_tokens[ctk_amp];
        end;
      end;
      '|': begin
        get_character;
        if ch = '|' then
          lex_token := lex_tokens[ctk_oror]
        else begin
          lex_pos := lex_pos - 1;
          if check_op_asn then
            lex_token := lex_tokens[lex_or_assign]
          else
            lex_token := lex_tokens[ctk_bar];
        end;
      end;
      '!': begin
        get_character;
        if ch = '=' then
          lex_token := lex_tokens[ctk_ne]
        else begin
          lex_pos := lex_pos - 1;
          lex_token := lex_tokens[ctk_not];
        end;
      end;
      '#': begin
        include_name := nil;
        hash_col := lex_pos - 1;
        if not more_data_on_line then begin
          skip_line := true;
          lex_token := nil;
        end
        else begin
          get;
          if (token_kind = ctk_identifier) and
             (lex_token = idntk(ctk_identifier, 'attribute', 9)) then
            lex_token := addr(kw_attribute)
          else if (token_kind = ctk_identifier) and
                  (lex_token = idntk(ctk_identifier, 'options', 7)) then
            lex_token := addr(kw_options)
          else begin
            parse_directive;
            if include_name <> nil then
              open_include;
            lex_token := nil;
          end;
        end;
      end;
      chr(9), chr(10), chr(11), chr(12), chr(13), ' ':
        ;
      otherwise begin
        lex_token := lex_tokens[ctk_other_char];
        lex_token^.idnt_name[1] := ch;
      end;
    end;
  2:
  until lex_token <> nil;
99:
  token_kind := lex_token^.kind;
  if token_kind = ctk_eof then begin
    if (quote_state = 1) or (quote_state = 2) then
      error0(3, lex_line)
    else if quote_state = 3 then
      error0(1, lex_line);
    if not attr_al_stk_empty then
      error0(cerr_code_map[80], lex_line);
  end;
end;

{ clex_$unget - make tok (of class kind) the current token; the
  current one comes back from the next get.

  0x055FB0, 0x34 bytes, link #0. }

procedure clex_$unget(
    kind: integer;
    tok: il_$node_ptr_t);
begin
  unget_kind := token_kind;
  unget_token := lex_token;
  token_kind := kind;
  lex_token := tok;
end;

{ clex_$catstring - adjacent string literals: s1's characters (less
  its NUL) then s2's.

  0x055FE4, 0x104 bytes, link #-4108.  s2 nil or not a string (92 or
  93, `seq', `seq', `or.b') is error0(287), s1 the result; s1 nil gives
  s2; s1 not a string error0(287) and s2.  A result longer than 4095
  (the lengths zero-extended to longwords) is error0(6) and s1.  The
  characters are copied into a frame array (-4096); strtk; the result's
  kind is s1's.

  Not known from the original:
  - the names. }

function clex_$catstring(
    s1: il_$node_ptr_t;
    s2: il_$node_ptr_t): il_$node_ptr_t;
var
  buf: array [1..4096] of char;
  i, m: integer;
  t: il_$node_ptr_t;
begin
  if (s2 = nil) or else not ((s2^.kind = ctk_wstring) or (s2^.kind = ctk_string)) then begin
    error0(287, lex_line);
    clex_$catstring := s1;
    return;
  end;
  if s1 = nil then begin
    clex_$catstring := s2;
    return;
  end;
  if not ((s1^.kind = ctk_wstring) or (s1^.kind = ctk_string)) then begin
    error0(287, lex_line);
    clex_$catstring := s2;
    return;
  end;
  if s1^.str_len + s2^.str_len - 1 > 4095 then begin
    error0(6, lex_line);
    clex_$catstring := s1;
    return;
  end;
  m := s1^.str_len - 1;
  for i := 1 to m do
    buf[i] := s1^.str_chars[i];
  for i := 1 to s2^.str_len do
    buf[m + i] := s2^.str_chars[i];
  t := strtk(buf, s1^.str_len + s2^.str_len - 1);
  t^.kind := s1^.kind;
  clex_$catstring := t;
end;

{ ppio_$error - text at the current line, an error (kind 1) or a
  warning (2).

  0x0560E8, 0x50 bytes, link #0. }

procedure ppio_$error(
    kind: integer;
    len: integer;
    in text: univ cerr_text_t);
begin
  if kind = 1 then
    error_text(lex_line, text, len)
  else if kind = 2 then
    warning_text(lex_line, text, len);
end;

{ ppio_$get_line - the next line of the current file.

  0x056138, 0x26C bytes, link #-24.  read_ln(cur_stream, line, 512, n
  (-10)).  A line: lines_read counted; unless the last line was
  truncated (it continues), lex_fatal cleared and the position moved
  (spos_$next_line, lex_line); a line of 512 characters is truncated,
  else a newline is added.  With the listing on and no -ES, the line
  goes to the listing: lex_macro_expanded cleared, the text copied
  after the number field (lib_$data_move; the line's address from its
  parameter slot), the number field made ('(' ')' in the main file, '['
  ']' in an include file; cgu_$make_line_no of the decoded line, 8
  characters), write_ln(1, .., n + 8) (n the length read, without the
  newline), lex_text_written set, under -EXP listed_len := len; else
  lex_text_written cleared.  lex_hdr_written cleared.  At the end of an
  include file (len 0): its stream closed (when it was an #include and
  internal_cpp), mr_std_include_state cleared when it was the implicit
  include, -USRCH's directory restored, the including file's state
  back (lib_$data_move of its text), spos_$resume_file, lex_line, the
  depth less one, put_es_line(the next line, true), and while
  mr_std_include_state is not 0 the next line read at once (the line
  the implicit include displaced).  At the end of the main file:
  lex_total_lines := lines_read the first time, len := -1, lex_token
  the ctk_eof token, both written flags set.

  Not known from the original:
  - the locals' names. }

procedure ppio_$get_line(
    in out len: integer;
    out line: univ pp_$line_t);
var
  n: integer;
  rgn: integer32;
  lineno: integer32;
  m: integer32;
  dst: univ_ptr;
  src: univ_ptr;
begin
  if not read_ln(cur_stream, line, 512, n) then begin
    lines_read := lines_read + 1;
    if not line_truncated then begin
      lex_fatal := false;
      spos_$next_line;
      lex_line := spos_$position;
    end;
    len := n;
    if len = 512 then
      line_truncated := true
    else begin
      line_truncated := false;
      len := len + 1;
      line[len] := chr(10);
    end;
    if (nolist_depth = 0) and (cargs_$options.es = 0) then begin
      lex_macro_expanded := false;
      m := len;
      dst := addr(lex_listing_line.text);
      lib_$data_move(addr(line), dst, m);
      spos_$decode_source_position(lex_line, rgn, lineno);
      if spos_$is_main_source_file(rgn) then
        cgu_$make_line_no(lineno, '(', ')', 8, lex_listing_line)
      else
        cgu_$make_line_no(lineno, '[', ']', 8, lex_listing_line);
      write_ln(1, addr(lex_listing_line), n + 8);
      lex_text_written := true;
      if cargs_$options.exp then
        listed_len := len;
    end
    else
      lex_text_written := false;
    lex_hdr_written := false;
  end
  else begin
    len := 0;
    if lex_depth <> 0 then begin
      if lex_files[lex_depth].is_include and internal_cpp then
        close_include_file(cur_stream);
      if spos_$region_user_name(spos_$region) = std_include_tok then
        mr_std_include_state := 0;
      with lex_files[lex_depth] do begin
        if cargs_$options.usrch then
          inc_list_idirs[1] := saved_idir;
        cur_stream := stream;
        lex_pos := pos;
        lex_text.length := text_len;
        lex_text_written := text_written;
        lex_hdr_written := hdr_written;
        m := lex_text.length;
        src := addr(lex_text.body);
        lib_$data_move(saved_texts[lex_depth], src, m);
        spos_$resume_file(region);
      end;
      lex_line := spos_$position;
      lex_depth := lex_depth - 1;
      put_es_line(spos_$enquire_next_line, true);
      if mr_std_include_state <> 0 then
        ppio_$get_line(len, line);
    end
    else begin
      if lex_total_lines = 0 then
        lex_total_lines := lines_read;
      len := -1;
      lex_token := lex_tokens[ctk_eof];
      lex_hdr_written := true;
      lex_text_written := true;
    end;
  end;
end;

{ ppio_$lookahead - the next character of the current stream, not
  taken.

  0x0563A4, 0x6E bytes, link #-12.  ios_$locate(cur_stream,
  [ios_$preview_opt] (the literal word 2 at 0x056412), p, 1, status):
  a status of 0 or ios_$buffer_too_small gives p^, ios_$end_of_file
  chr(0), another error_exit(status, '', 0).  The result in D2.

  Not known from the original:
  - the locals' names. }

function ppio_$lookahead: char;
var
  c: char;
  p: ^char;
  status: status_$t;
begin
  c := chr(0);
  discard(ios_$locate(cur_stream, [ios_$preview_opt], p, 1, status));
  if (status.all = ios_$buffer_too_small) or (status.all = 0) then
    c := p^
  else if status.all <> ios_$end_of_file then
    error_exit(status, '', 0);
  ppio_$lookahead := c;
end;
