{ lang/c_compiler/source/macro_read.ins.pas - the interface of the
  preprocessor's macro reader (MR_, c_macro_read.pas): raw lines with
  comments removed, lines with macros expanded, #ifdef's test, and the
  search for C identifiers in a line.  Opened after general_utl.ins.pas
  (and macro_utl.ins.pas) by c_cond_read, c_lex_pp, c_macro_read and
  c_macro_utl.

  No Apollo copy survives; the headings are read off c_macro_read's
  routines and their callers (cc.m68k 0x05641C..0x058F00): lengths and
  flags by value (val_param), lines by address.

  Not known from the original: the parameter names; the meaning of the
  flags.
}

{ TODO(pascal) the MR_ headings are read off the frames only

  Narrow the flags and the kind when c_macro_read.pas is translated. }

var
  { c_macro_read.pas's data, A5 0x14907C (cc.m68k), 0x2C907C
    (cc.a88k), +0x632: a byte mr_$initialize clears and
    get_par_cooked_line, mr_$get_expanded_line and str_locate_c_id test
    and set; cr_$get_cooked_line (c_cond_read) returns its lines
    without looking at directives while it is set. }
  mr_632: extern boolean;

  { c_macro_read.pas's data +0x600 and +0x608: the compilation's time
    ('hh:mm:ss') and date ('Mmm dd yyyy'), filled by c_initdate.c's
    initdate (strncpy from asctime) and quoted into __TIME__ and
    __DATE__ by mu_$initialize. }
  mr_time: extern array [1..8] of char;
  mr_date: extern array [1..11] of char;

{ MR_$INITIALIZE - start reading a source file.  0x05641C; called by
  cr_$initialize with its own flag. }
procedure mr_$initialize(
    flag: boolean); options(val_param); extern;

{ MR_$GET_RAW_LINE - the next line without its comments (len < 0 at
  the end).  0x0573A0; cr_$get_cooked_line, while it skips lines. }
procedure mr_$get_raw_line(
    in out len: integer;
    out line: univ pp_$line_t); extern;

{ MR_$GET_EXPANDED_LINE - the next line with its macros expanded, and
  what it is (kind: cr_$get_cooked_line returns at once for 1 and 2, and
  reports 3).  0x058262; cr_$get_cooked_line, mr_$get_q_only. }
procedure mr_$get_expanded_line(
    in out len: integer;
    out line: univ pp_$line_t;
    out kind: integer); extern;

{ MR_$GET_Q_ONLY - 0x057FC6; no caller in either binary. }
procedure mr_$get_q_only(
    in out len: integer;
    out line: univ pp_$line_t); extern;

{ STR_LOCATE_C_ID - the position of the first C identifier in
  line[start..len] (0 if none) and, in n, its length.  0x058BD8;
  cr_$get_cooked_line passes (i, false, continuing, true, ...), find_id
  (c_macro_read) its own flags; c_macro_utl calls it too. }
function str_locate_c_id(
    start: integer;
    flag1: boolean;
    flag2: boolean;
    flag3: boolean;
    len: integer;
    in line: univ pp_$line_t;
    out n: integer): integer; options(val_param); extern;

{ MR_$CHECK_DEFINE - #ifdef's test: the identifier that begins s (n
  characters) is a defined macro; n is left 0 when only the newline
  follows the name (s_pick_off_name consumes it), -1 when there is no
  name (cr_$get_cooked_line reports a malformed predicate unless 0).
  0x058E80. }
function mr_$check_define(
    in out n: integer;
    in s: univ pp_$line_t): boolean; extern;
