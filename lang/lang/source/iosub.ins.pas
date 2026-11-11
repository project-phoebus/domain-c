{ lang/lang/source/iosub.ins.pas - IOSUB, the compilers' input and
  output: the listing, the terminal, ending the run
  (lang/lang/source/iosub.pas).  c_lex_pp and c_macro_read open it
  before prtsub.ins.pas, so it declares its own line type.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far; the headings
  are read off iosub.pas's frames and its callers.

  Not known from the original: the parameter names.
}

{ TODO(pascal) iosub.ins.pas is incomplete

  The rest of IOSUB's interface is added when iosub.pas and its
  callers are translated. }

type
  { A printed line, as PRTSUB builds it (prtsub_$line_t's layout). }
  iosub_$line_t = varying [256] of char;

  { A name (cargs.ins.pas's cargs_$chars_t, which prfpkg.pas, opening
    this insert, does not open). }
  iosub_$name_t = array [1..1024] of char;

  { A status (status_$t's longword; the units opening this insert need
    not have base's types). }
  iosub_$status_t = integer32;

var
  { iosub.pas's data, A5 0x2CD7E4 (cc.m68k): the source file's full
    pathname (+0x428, its length +0x930) and whether a library is being
    generated (+0x936, outputs element 4: open_plb_file). }
  iosub_$source_pathname: extern array [1..1024] of char;
  iosub_$source_stream: extern integer; { +0x92E: the source file's
                                          stream (c_lex_pp's init_lex) }
  iosub_$source_pathname_length: extern integer;
  iosub_$generating_library: extern boolean;

{ IO_TERM - close the outputs at the end of the run, with severity.
  0x0B5B10: by address (c_error's cgerr passes a frame word holding 5). }
procedure io_term(
    in severity: integer); extern;

{ WRITE_LN - len characters at buf to stream (1: c_error's errorlst
  writes the current source line).  0x0B5BDA: a word, a pointer (whose
  slot the callee passes on by address) and a word, by value. }
procedure write_ln(
    stream: integer;
    buf: univ_ptr;
    len: integer); options(val_param); extern;

{ TYPELN - s to the terminal.  0x0B5EBA. }
procedure typeln(
    in s: univ iosub_$line_t); extern;

{ LISTLN - s to the listing.  0x0B5F42 (62 call sites). }
procedure listln(
    in s: univ iosub_$line_t); extern;

{ EJCTLN - a page eject on the listing (ios_$put of a form feed
  while the listing is open).  0x0B5F6E: no parameters (c_sym_map's
  sym_map and print_addr_cons). }
procedure ejctln; extern;

{ OPEN_INCLUDE_FILE - open the include file named by the len characters
  of name; sid gets its stream.  0x0B60D6 (cc.a88k 0x0B9B9E): name by
  address, len a word by value (its slot is also passed by address to
  strl_$copy), sid a word by address (ios_$open's result), then two
  booleans: when in_first is false the name is first copied by
  strl_$copy; the last is not read.  The result: whether it opened
  (false for five `not found' statuses; another status is reported and
  ends the program).  Callers: inc_list's open_include_list_sub (in_first: the
  name was built on the first directory of its list, false for a name
  taken as it is), c_lex_pp's open_file_to_get_info (false). }
function open_include_file(
    in name: univ iosub_$name_t;
    len: integer;
    var sid: integer;
    in_first: boolean;
    unused: boolean): boolean; options(val_param); extern;

{ ERROR_EXIT - report status (with the len characters of msg after
  error_$std_format's text when len is not 0) and end the run with
  severity 3.  0x0B5024: status and msg by address, len a word by
  value (c_lex_pp's ppio_$lookahead passes an empty text and 0). }
procedure error_exit(
    in status: univ iosub_$status_t;
    in msg: univ iosub_$name_t;
    len: integer); options(val_param); extern;

{ READ_LN - the next line of stream into buf (at most max characters;
  len the number read, a final newline dropped); true at the end of
  the file.  0x0B5D4A: stream and max words by value, buf and len by
  address (c_lex_pp's ppio_$get_line). }
function read_ln(
    stream: integer;
    out buf: univ iosub_$name_t;
    max: integer;
    out len: integer): boolean; options(val_param); extern;

{ IOSUB_$GET_DTM - the date-time modified of stream's object
  (ios_$inq_file_attr).  0x0B61EA: a word by value; c_lex_pp. }
function iosub_$get_dtm(
    stream: integer): integer32; options(val_param); extern;

{ IOSUB_$GET_FULL_PATH_NAME - the full pathname of stream's object
  (a string node).  0x0B6238: a word by value; c_lex_pp reads A0. }
function iosub_$get_full_path_name(
    stream: integer): univ_ptr; options(val_param); extern;

{ IOSUB_$INIT_ALL - open the outputs and parse the command line: the
  source suffix (suffix_len characters), then the four lists the
  options -DEF, -IDIR, -INLIB and -UNDEF add to (count, size, list of
  pointers; cargs_$parse_command_line_options).  0x0B5896: c_main's cc
  passes '.c' and 2, its -DEF list (128), inc_list's -IDIR (64) and
  -INLIB (65) lists and its -UNDEF list (128); the counts and lists by
  address. }
procedure iosub_$init_all(
    in suffix: univ iosub_$name_t;
    suffix_len: integer;
    var ndef: integer;
    maxdef: integer;
    var deflist: univ iosub_$name_t;
    var nidir: integer;
    maxidir: integer;
    var idirlist: univ iosub_$name_t;
    var ninlib: integer;
    maxinlib: integer;
    var inliblist: univ iosub_$name_t;
    var nundef: integer;
    maxundef: integer;
    var undeflist: univ iosub_$name_t); options(val_param); extern;

{ IOSUB_$REDIRECT_SOURCE_INPUT - read the source from the file name
  (len characters) instead (c_main's preprocess: acpp's output).
  0x0B5950: name by address, len a word by value. }
procedure iosub_$redirect_source_input(
    in name: univ iosub_$name_t;
    len: integer); options(val_param); extern;

{ IO_MARK - mark output n (0, 1) at its current position.  0x0B5DD6: a
  word by value (c_main). }
procedure io_mark(
    n: integer); options(val_param); extern;

{ TYPEMSG - s to the terminal, unless error_listing_0c.  0x0B5F02: s by
  address (c_main's summary line). }
procedure typemsg(
    in s: univ iosub_$line_t); extern;

var
  { iosub.pas's data +0x935: flags; c_main tests bit 2 (`btst
    #2,0x2CE119') before printing the compile time and running the back
    end.  Not known from the original: the name and the type. }
  iosub_$flags_935: extern set of 0..7;

{ CLOSE_INCLUDE_FILE - ios_$close of stream.  0x0B6306: a word by
  value; c_lex_pp's open_file_to_get_info and ppio_$get_line. }
procedure close_include_file(
    stream: integer); options(val_param); extern;
