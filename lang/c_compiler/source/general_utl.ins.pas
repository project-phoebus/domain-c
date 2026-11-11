{ lang/c_compiler/source/general_utl.ins.pas - the interface of the
  preprocessor's general utilities (c_general_utl.pas): integer helpers,
  operations on a line held as a length and its characters, and the
  line number prefix of a listing line.  Opened after c_pre_proc.ins.pas
  by c_cond_read, c_general_utl, c_lex_pp, c_macro_read and
  c_macro_utl.

  No Apollo copy survives; the headings are read off c_general_utl's
  routines (cc.m68k 0x052F08..0x0532D6) and their callers: lengths and
  integers are words by value, the characters are passed by address
  (callers `pea' frame buffers, module buffers and string literals).

  Not known from the original: the parameter names.
}

{ MATH_MOD - a mod b, made non-negative by adding b.  0x052F08; called
  by c_macro_utl's hash_value (b 128). }
function math_mod(
    a: integer;
    b: integer): integer; options(val_param); extern;

{ MAX, MIN - the greater and the lesser of a and b.  0x052F4A,
  0x052F6C. }
function max(
    a: integer;
    b: integer): integer; options(val_param); extern;

function min(
    a: integer;
    b: integer): integer; options(val_param); extern;

{ STR_EQL - s1 (len1 characters) and s2 (len2) are the same string.
  0x052F8E. }
function str_eql(
    len1: integer;
    in s1: univ pp_$line_t;
    len2: integer;
    in s2: univ pp_$line_t): boolean; options(val_param); extern;

{ STR_EQL_INSENSITIVE - as STR_EQL, ignoring the case of letters.
  0x052FDE; no caller. }
function str_eql_insensitive(
    len1: integer;
    in s1: univ pp_$line_t;
    len2: integer;
    in s2: univ pp_$line_t): boolean; options(val_param); extern;

{ STR_COPY - the first len characters of src to dst.  0x05304A (55
  call sites; src is often a literal). }
procedure str_copy(
    len: integer;
    in src: univ pp_$line_t;
    out dst: univ pp_$line_t); options(val_param); extern;

{ STR_STRIP_LEADING - remove the blanks and tabs that begin s (len
  characters; len is updated).  0x053080; no caller. }
procedure str_strip_leading(
    in out len: integer;
    in out s: univ pp_$line_t); options(val_param); extern;

{ STR_SLIDE - move s's characters from position from to the end to
  position dest; len grows by dest - from.  0x0530D8. }
procedure str_slide(
    in out len: integer;
    in out s: univ pp_$line_t;
    from: integer;
    dest: integer); options(val_param); extern;

{ STR_LOCATE - the first position, at start or after, at which pattern
  (pattern_len characters) occurs in text (text_len), ignoring case
  when insensitive; 0 if none.  0x05314C; no caller. }
function str_locate(
    insensitive: boolean;
    start: integer;
    text_len: integer;
    in text: univ pp_$line_t;
    pattern_len: integer;
    in pattern: univ pp_$line_t): integer; options(val_param); extern;

{ CGU_$MAKE_LINE_NO - a listing line's number field: width characters
  of buf, a blank, open, the line number right-justified (4 digits, 5
  above 9999, fewer when width is short), close, then blanks.
  0x053240; ppio_$get_line and just_get_the_next_line_please (c_lex_pp,
  c_macro_read) pass '[' ']' or '(' ')' and 8. }
procedure cgu_$make_line_no(
    line: integer;
    open: char;
    close: char;
    width: integer;
    out buf: univ pp_$line_t); options(val_param); extern;
