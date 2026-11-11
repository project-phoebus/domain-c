{ lang/common/source/std.ins.pas - STD_, the compilers' small standard
  helpers: range tests, rounding, appending to a varying string and
  dumping strings and booleans through DIAG_.

  No Apollo copy survives; the headings are read off the std module
  (lang/common/source/std.pas) and its callers in cc.m68k and cc.a88k of
  DOMAIN C 6.9.  Every parameter but a string is passed by value (read
  from the frame, pushed by value by the callers): the routines are
  val_param.

  It stands alone (std.pas opens it first, then diag.ins.pas).
}

{ TODO(pascal) std_$string_t's capacity

  No STD_ routine checks a bound, so the image does not give the
  capacity of the varying string the append routines grow; read it off
  a caller's frame or data. }

type
  { The varying string the append routines grow: a length word, then
    the characters from +2. }
  std_$string_t = varying [256] of char;

{ STD_$IN_RANGE_LOWER_TO_UPPER - lower <= value <= upper. }
function std_$in_range_lower_to_upper(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean; options(val_param); extern;

{ STD_$IN_RANGE_LOWER_TO_UPPER_PLUS_1 - lower <= value < upper. }
function std_$in_range_lower_to_upper_plus_1(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean; options(val_param); extern;

{ STD_$IN_RANGE_LOWER_MINUS_1_TO_UPPER - lower < value <= upper. }
function std_$in_range_lower_minus_1_to_upper(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean; options(val_param); extern;

{ STD_$IN_RANGE_LOWER_MINUS_1_TO_UPPER_PLUS_1 - lower < value < upper. }
function std_$in_range_lower_minus_1_to_upper_plus_1(
    value: integer32;
    lower: integer32;
    upper: integer32): boolean; options(val_param); extern;

{ STD_$ROUND_UP_TO_MULTIPLE_OF - value rounded up to a multiple of
  multiple (value itself when multiple is 0). }
function std_$round_up_to_multiple_of(
    value: integer32;
    multiple: integer32): integer32; options(val_param); extern;

{ STD_$DIAG_DUMP_BOOLEAN - `true' or `false' to the diagnostic output. }
procedure std_$diag_dump_boolean(
    b: boolean); options(val_param); extern;

{ STD_$DIAG_DUMP_ANY_STRING - len characters of s to the diagnostic
  output, in double quotes when quoted. }
procedure std_$diag_dump_any_string(
    in s: univ std_$string_t;
    len: integer32;
    quoted: boolean); options(val_param); extern;

{ STD_$APPEND_CHAR - c to the end of s. }
procedure std_$append_char(
    in out s: std_$string_t;
    c: char); options(val_param); extern;

{ STD_$APPEND_STRING - src's characters to the end of dst. }
procedure std_$append_string(
    in out dst: std_$string_t;
    in src: univ std_$string_t); options(val_param); extern;

{ STD_$APPEND_INTEGER - n in decimal (a `-' first when negative) to the
  end of s. }
procedure std_$append_integer(
    in out s: std_$string_t;
    n: integer32); options(val_param); extern;

{ STD_$DIAG_DUMP_VAR_STRING - s's characters to the diagnostic output,
  in double quotes when quoted. }
procedure std_$diag_dump_var_string(
    in s: std_$string_t;
    quoted: boolean); options(val_param); extern;
