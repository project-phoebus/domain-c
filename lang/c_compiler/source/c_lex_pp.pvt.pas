{ lang/c_compiler/source/c_lex_pp.pvt.pas - what c_lex_pp shares with
  c_macro_read only: the preprocessor's line input (PPIO_), the stack
  of open source files and c_lex_pp's cells c_macro_read reaches
  absolutely.  Opened last by c_lex_pp and c_macro_read (after
  c_pre_proc.ins.pas and c_externs.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here but the routines'.
}

{ TODO(pascal) c_lex_pp.pvt.pas: c_lex_pp's side

  The file record's other fields and ppio_$get_line's and
  ppio_$lookahead's details are settled when c_lex_pp is translated. }

type
  { An open source file: c_lex_pp's +0x250 + 34 * depth (the main file
    is entry 0; open_include refuses a depth past 16; init_lex clears
    entry 0's +18, +28 and +29).  c_macro_read's get_decommented_line
    keeps the comment state of the file being read in it. }
  lex_file_t = record
    unused_0: array [0..8] of integer;  { +0..+17 }
    comment_state: integer;             { +18: get_decommented_line's
                                          state at the end of the last
                                          line read (0 code, 2 and 3 in
                                          a comment, 4 and 5 in a
                                          string, ...) }
    unused_20: array [0..3] of integer; { +20..+27 }
    in_comment: boolean;                { +28: the last line ended in
                                          a comment }
    continued: boolean;                 { +29: the last line read did
                                          not end with a newline }
    unused_30: array [0..1] of integer; { +30..+33 }
  end;

var
  { c_lex_pp.pas's data, A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k). }
  lex_listing_line: extern array [1..520] of char;  { +0x2: the line
                                          being listed: the number field
                                          (cgu_$make_line_no, 8
                                          characters, from
                                          ppio_$get_line and c_macro_read's
                                          just_get_the_next_line_please)
                                          and the text }
  lex_macro_expanded: extern boolean;   { +0x20A: set by c_macro_read's
                                          mr_$get_expanded_line when it
                                          expands a macro }
  lex_files: extern array [0..16] of lex_file_t;  { +0x250 }
  lex_depth: extern integer;            { +0x2AEE: the current entry of
                                          lex_files (0 the main file) }

{ PPIO_$ERROR - report text (len characters) at the current line: kind
  1 an error (error_text), 2 a warning (warning_text), else nothing.
  c_lex_pp.pas 0x0560E8 (cc.a88k 0x056368); c_macro_read's
  get_decommented_line passes 2 with its literals. }
procedure ppio_$error(
    kind: integer;
    len: integer;
    in text: univ cerr_text_t); options(val_param); extern;

{ PPIO_$GET_LINE - the next line of the current source file (len < 0
  at the end).  c_lex_pp.pas 0x056138 (cc.a88k 0x0563B8);
  get_decommented_line passes both by address. }
procedure ppio_$get_line(
    in out len: integer;
    out line: univ pp_$line_t); extern;

{ PPIO_$LOOKAHEAD - the next character of the current source file
  without reading it (ios_$locate).  c_lex_pp.pas 0x0563A4 (cc.a88k
  0x056624). }
function ppio_$lookahead: char; extern;
