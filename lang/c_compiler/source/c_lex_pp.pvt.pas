{ lang/c_compiler/source/c_lex_pp.pvt.pas - what c_lex_pp shares with
  c_macro_read only: the preprocessor's line input (PPIO_), the stack
  of open source files and c_lex_pp's cells c_macro_read reaches
  absolutely.  Opened last by c_macro_read, and by c_lex_pp after
  c_pre_proc.ins.pas and c_externs.ins.pas (and inc_list.ins.pas,
  through the prelude).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.

  Not known from the original: every name here but the routines'.
}

type
  { A source file being read, kept while an include file (or a #line
    naming another file) is read: c_lex_pp's +0x250 + 34 * depth (the
    main file is entry 0; open_include and line_sem refuse a depth
    past 16).  open_include and line_sem fill an entry when they start
    a file, ppio_$get_line (and line_sem) take it back when it ends;
    c_macro_read's get_decommented_line keeps the comment state of the
    file being read in it. }
  lex_file_t = record
    saved_idir: inc_list_$name_ptr_t;   { +0: inc_list_idirs[1] before
                                          the file (-USRCH) }
    dir_name: inc_list_$name_ptr_t;     { +4: the file's directory,
                                          inc_list_idirs[1] while it is
                                          read (-USRCH; 1026 bytes from
                                          gspace) }
    path: ^cargs_$chars_t;              { +8: the name the file was
                                          opened by (1023 bytes from
                                          gspace) }
    path_len: integer;                  { +12 }
    pos: integer;                       { +14: the including file's
                                          lex_pos }
    text_len: integer;                  { +16: and its lex_text.length
                                          (the text is kept in
                                          lex_saved_texts) }
    comment_state: integer;             { +18: get_decommented_line's
                                          state at the end of the last
                                          line read (0 code, 2 and 3 in
                                          a comment, 4 and 5 in a
                                          string, ...) }
    stream: integer;                    { +20: the including file's
                                          stream }
    region: integer32;                  { +22: and its spos region }
    hdr_written: boolean;               { +26: its lex_hdr_written }
    text_written: boolean;              { +27: its lex_text_written }
    in_comment: boolean;                { +28: the last line ended in
                                          a comment }
    continued: boolean;                 { +29: the last line read did
                                          not end with a newline }
    is_include: boolean;                { +30: an #include (its stream
                                          is closed at its end), not a
                                          #line }
    unused_31: char;                    { +31 }
    unused_32: integer;                 { +32 }
  end;

  { The listing's line: the number field (cgu_$make_line_no) and the
    text, written together (ppio_$get_line). }
  lex_listing_t = record
    number: array [1..8] of char;       { +0 }
    text: array [1..512] of char;       { +8 }
  end;

var
  { c_lex_pp.pas's data, A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k). }
  lex_listing_line: extern lex_listing_t;  { +0x2: the line being
                                          listed: ppio_$get_line and
                                          c_macro_read's
                                          just_get_the_next_line_please
                                          make its number field }
  lex_macro_expanded: extern boolean;   { +0x20A: set by c_macro_read's
                                          mr_$get_expanded_line when it
                                          expands a macro (-EXP lists
                                          the line again expanded) }
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

{ PPIO_$GET_LINE - the next line of the current source file, a newline
  added unless it filled 512 characters (len < 0 at the end of the main
  file; at the end of an include file len 0, or the including file's
  next line while the implicit #include is pending).  c_lex_pp.pas
  0x056138 (cc.a88k 0x0563B8); c_lex_pp's pp_get_line and
  get_decommented_line pass both by address. }
procedure ppio_$get_line(
    in out len: integer;
    out line: univ pp_$line_t); extern;

{ PPIO_$LOOKAHEAD - the next character of the current source file
  without reading it (ios_$locate; chr(0) at its end).  c_lex_pp.pas
  0x0563A4 (cc.a88k 0x056624). }
function ppio_$lookahead: char; extern;
