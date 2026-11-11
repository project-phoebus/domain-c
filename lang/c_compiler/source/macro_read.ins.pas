{ lang/c_compiler/source/macro_read.ins.pas - the interface of the
  preprocessor's macro reader (MR_, c_macro_read.pas): raw lines with
  comments removed, lines with macros expanded, #ifdef's test, and the
  search for C identifiers in a line.  Opened after general_utl.ins.pas
  (and macro_utl.ins.pas) by c_cond_read, c_lex_pp, c_macro_read and
  c_macro_utl.

  No Apollo copy survives; the headings are read off c_macro_read's
  routines (translated) and their callers (cc.m68k 0x05641C..0x058F00):
  lengths and flags by value (val_param), lines by address.

  Not known from the original: the parameter names.
}

var
  { c_macro_read.pas's data, A5 0x14907C (cc.m68k), 0x2C907C
    (cc.a88k), +0x632: the quote that opened a string or character
    constant str_locate_c_id left open at the end of the line being
    decommented (chr(0) when none; '>' for an #include's '<').  The
    lines of a continued string are not looked at for #define, #undef
    and macros (get_par_cooked_line, mr_$get_expanded_line), nor for
    directives (cr_$get_cooked_line, c_cond_read: `tst.b; sne').
    mr_$initialize clears it. }
  mr_open_quote: extern char;

  { c_macro_read.pas's data +0x600 and +0x608: the compilation's time
    ('hh:mm:ss') and date ('Mmm dd yyyy'), filled by c_initdate.c's
    initdate (strncpy from asctime) and quoted into __TIME__ and
    __DATE__ by mu_$initialize. }
  mr_time: extern array [1..8] of char;
  mr_date: extern array [1..11] of char;

{ MR_$INITIALIZE - start reading a source file: the queues and the
  actual parameters empty; free_blocks is passed on to mu_$initialize.
  0x05641C; called by cr_$initialize with its own flag. }
procedure mr_$initialize(
    free_blocks: boolean); options(val_param); extern;

{ MR_$GET_RAW_LINE - the next line without its comments (len < 0 at
  the end), passing over lines other than conditional directives (and
  their continuations).  0x0573A0; cr_$get_cooked_line, while it skips
  lines. }
procedure mr_$get_raw_line(
    in out len: integer;
    in out line: univ pp_$line_t); extern;

{ MR_$GET_EXPANDED_LINE - the next line with its macros expanded, and
  what it is (kind: 0 an ordinary line, 1 a diagnostic in line (an
  error), 2 a diagnostic (a warning), 3 a line to take as it is (the
  #include put in before the first line, and the line it displaced),
  4 and 5 pieces of a line split by a continued identifier).
  0x058262; cr_$get_cooked_line, mr_$get_q_only. }
procedure mr_$get_expanded_line(
    in out len: integer;
    in out line: univ pp_$line_t;
    in out kind: integer); extern;

{ MR_$GET_Q_ONLY - the next line of the queue, expanded (true for
  kinds 0 and 3; diagnostics met on the way go to the diagnostics'
  queue); at the queue's end the diagnostics' queue takes its place
  and len is 0 (false).  0x057FC6; no caller in either binary. }
function mr_$get_q_only(
    in out len: integer;
    in out line: univ pp_$line_t): boolean; extern;

{ STR_LOCATE_C_ID - the position of the first C identifier in
  line[start..len] (0 if none) and, in n, its length.  Identifiers in
  comments, after a backslash, (with quotes) in strings and character
  constants and (with angles) between an #include's '<' and '>' are
  passed over; with continuing, an identifier may begin with a digit.
  When line is the line being decommented, an open quote is carried
  over in mr_open_quote.  0x058BD8; cr_$get_cooked_line passes (i,
  false, continuing, true, ...), find_id (c_macro_read) its own flags,
  c_macro_utl (i, false, false, false, ...). }
function str_locate_c_id(
    start: integer;
    angles: boolean;
    continuing: boolean;
    quotes: boolean;
    len: integer;
    in line: univ pp_$line_t;
    out n: integer): integer; options(val_param); extern;

{ MR_$CHECK_DEFINE - #ifdef's test: the identifier that begins s (n
  characters) is a defined macro; the name is taken off s
  (s_pick_off_name); n is left 0 when only the newline follows it, -1
  when there is no name (cr_$get_cooked_line reports a malformed
  predicate unless 0).  0x058E80. }
function mr_$check_define(
    in out n: integer;
    in out s: univ pp_$line_t): boolean; extern;
