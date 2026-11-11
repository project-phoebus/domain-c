{ lang/c_compiler/source/c_pre_proc.ins.pas - the C preprocessor's
  common types and the interface of its conditional reader (CR_,
  c_cond_read.pas).  Opened after c_globals.ins.pas (and
  c_externs.ins.pas) by the preprocessor's units (c_cond_read,
  c_general_utl, c_lex_pp, c_macro_read, c_macro_utl) and c_main.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here.
}

{ TODO(pascal) c_pre_proc.ins.pas is incomplete

  The preprocessor's line, token and queue types and CR_'s headings
  are added as c_cond_read, c_lex_pp and c_macro_read are translated. }

const
  { The longest line the preprocessor handles: s_pick_off_name and
    find_id (c_macro_read) clip lengths to 4096. }
  pp_$line_max = 4096;

type
  { The characters of a line; its length is kept apart, a word (the
    general utilities take the length and the characters as separate
    parameters). }
  pp_$line_t = array [1..pp_$line_max] of char;

var
  { c_cond_read.pas's data, A5 0x140000 (cc.m68k), 0x2C0000 (cc.a88k),
    +0x50: set while an #if's expression continues on the next line
    (the line read did not end with a newline); cr_$get_cooked_line
    sets and clears it, c_macro_read's get_decommented_line and
    mr_$get_expanded_line test it. }
  cr_if_continued: extern boolean;

{ CR_$INITIALIZE - start a source file: no conditional is open; flag
  is passed on to mr_$initialize.  c_cond_read.pas 0x0403D8; c_main's
  cc. }
procedure cr_$initialize(
    flag: boolean); options(val_param); extern;

{ CR_$IF_IS_ON - the #if just read is true: take its lines.
  0x040404; c_lex_pp's pp_get_line, after evaluating the expression. }
procedure cr_$if_is_on; extern;

{ CR_$GET_COOKED_LINE - the next line the conditionals let through,
  with its macros expanded (len < 0 at the end): 0 an ordinary line;
  1 a diagnostic put in line in place of a malformed conditional (or
  mr_$get_expanded_line's kind 1); 2 mr_$get_expanded_line's kind 2;
  3 an #if's expression (its identifiers replaced by 0), 4 the
  expression's continuation; 5 the end of the file; 6 an ordinary
  line of mr_$get_expanded_line's kind 3.  0x04041E; c_lex_pp's
  pp_get_line. }
function cr_$get_cooked_line(
    in out len: integer;
    in out line: univ pp_$line_t): integer; extern;
