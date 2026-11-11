{ lang/c_compiler/source/c_lex_pp.pvt.pas - what c_lex_pp shares with
  c_macro_read only: the preprocessor's line input (PPIO_) and c_lex_pp's
  cells c_macro_read reaches absolutely.  Opened last by c_lex_pp and
  c_macro_read.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here but the routines'.
}

{ TODO(pascal) read off the frames only (see c_externs.ins.pas)

  Name and type the cells, and narrow the headings, when c_lex_pp and
  c_macro_read are translated. }

var
  { c_lex_pp.pas's data, A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k). }
  lex_listing_line: extern array [1..520] of char;  { +0x2: the line
                                          being listed: the number field
                                          (cgu_$make_line_no, 8
                                          characters, from
                                          ppio_$get_line and c_macro_read's
                                          just_get_the_next_line_please)
                                          and the text }
  lex_20a: extern boolean;              { +0x20A: c_macro_read's
                                          mr_$get_expanded_line }
  lex_26c: extern boolean;              { +0x26C: mr_$initialize }
  lex_2aee: extern integer;             { +0x2AEE: get_decommented_line }

{ PPIO_$ERROR - c_lex_pp.pas 0x0560E8 (cc.a88k 0x056368). }
procedure ppio_$error(
    p8: integer;
    p10: integer;
    p12: univ_ptr); options(val_param); extern;

{ PPIO_$GET_LINE - c_lex_pp.pas 0x056138 (cc.a88k 0x0563B8). }
procedure ppio_$get_line(
    p8: univ_ptr;
    p12: univ_ptr); options(val_param); extern;

{ PPIO_$LOOKAHEAD - c_lex_pp.pas 0x0563A4 (cc.a88k 0x056624). }
function ppio_$lookahead: char; extern;
