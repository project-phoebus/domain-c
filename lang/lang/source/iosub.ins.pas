{ lang/lang/source/iosub.ins.pas - IOSUB, the compilers' input and
  output: the source, listing, object and library files, the terminal,
  ending the run (lang/lang/source/iosub.pas).  c_lex_pp and
  c_macro_read open it before prtsub.ins.pas, and prfpkg and do_report
  without the prelude, so it declares its own types and uses no
  other insert's.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries:
  every routine another unit calls (iosub's own nested and internal
  routines are in iosub.pas), the headings read off iosub.pas's frames
  and its callers.  PUTOBJ is declared in globals_from_general.ins.pas
  (gen_exception calls it and does not open this insert).

  Not known from the original: the parameter names; every type name.
}

type
  { A printed line, as PRTSUB builds it (prtsub_$line_t's layout). }
  iosub_$line_t = varying [256] of char;

  { A name (cargs.ins.pas's cargs_$chars_t, which prfpkg.pas, opening
    this insert, does not open). }
  iosub_$name_t = array [1..1024] of char;

  { A status (base's status_$t, which c_macro_read has not opened when
    it opens this insert). }
  iosub_$status_t = integer32;

  { What is open (+0x935, one byte: element k is bit k): the listing,
    the source, the object file, and whether inlib_init was called.
    Bit 3 is not used. }
  iosub_$state_elt_t = (
    iosub_$listing_open,                { bit 0 }
    iosub_$source_open,                 { bit 1 }
    iosub_$object_open,                 { bit 2 (c_main) }
    iosub_$state_3,
    iosub_$inlib_initialized);          { bit 4 }
  iosub_$state_t = set of iosub_$state_elt_t;

var
  { iosub.pas's data, A5 0x2CD7E4 (cc.m68k), 0x44D968 (cc.a88k): }
  { +0x428: the source file's full pathname, and its length (+0x930;
    c_lex_pp, c_main, coff_syms, debug_sym_dmp, prfpkg). }
  iosub_$source_pathname: extern array [1..1024] of char;
  iosub_$source_pathname_length: extern integer;
  { +0x92E: the source's stream once it is open (c_lex_pp passes it to
    iosub_$get_dtm and iosub_$get_full_path_name). }
  iosub_$source_stream: extern integer;
  { +0x935 (c_main tests iosub_$object_open). }
  iosub_$state: extern iosub_$state_t;
  { +0x936: whether a library is being generated (outputs element 3;
    prfpkg). }
  iosub_$generating_library: extern boolean;

{ ERROR_EXIT - report status (with the len characters of name in
  quotes, when len is not 0) and end the program with severity 5.
  0x0B5024: status and name by address, len a word by value
  (ppio_$lookahead, walk_tree). }
procedure error_exit(
    in status: univ iosub_$status_t;
    in name: univ iosub_$name_t;
    len: integer); options(val_param); extern;

{ IOSUB_$INIT_ALL - start the compilation: the memory pools, GSPACE,
  the options' defaults, the command line (the source name, then the
  options with the four lists c_main passes, and the -USRCH directory
  record as `dot'), the processor's properties, and the files (the
  source name with suffix, e.g. '.c').  0x0B5896: suffix by address,
  then cargs_$parse_command_line_options's parameters but dot. }
procedure iosub_$init_all(
    in suffix: univ iosub_$name_t;
    suffix_len: integer;
    var ndef: integer;
    maxdef: integer;
    deflist: univ_ptr;
    var nidir: integer;
    maxidir: integer;
    idirlist: univ_ptr;
    var ninlib: integer;
    maxinlib: integer;
    inliblist: univ_ptr;
    var nundef: integer;
    maxundef: integer;
    undeflist: univ_ptr); options(val_param); extern;

{ GET_LISTING_STREAM_ID - the listing's stream, -1 when it is not
  open.  0x0B592C: no caller in either binary. }
function get_listing_stream_id: integer; extern;

{ IOSUB_$REDIRECT_SOURCE_INPUT - read the source from the file named by
  the len characters of name (c_main's preprocess, after acpp).
  0x0B5950: name by address, len a word by value. }
procedure iosub_$redirect_source_input(
    in name: univ iosub_$name_t;
    len: integer); options(val_param); extern;

{ IOSUB_$SELECTED_IO_TERM - close the object file (a failure makes
  severity 4 when it was at most 2), and the source and the listing as
  asked; end the -INLIB libraries.  0x0B59CC: severity by address, two
  booleans by value. }
procedure iosub_$selected_io_term(
    in out severity: integer;
    close_source: boolean;
    close_listing: boolean); options(val_param); extern;

{ IO_TERM - iosub_$selected_io_term(severity, true, true) at the end of
  the run.  0x0B5B10: by address (c_error's cgerr passes a frame word
  holding 5, c_main a cell); severity can be changed. }
procedure io_term(
    in out severity: integer); extern;

{ IO_TERM_FORCE - close everything, ignoring failures.  0x0B5B38: no
  caller in either binary. }
procedure io_term_force; extern;

{ WRITE_LN - a line of len characters at buf (at most 513) to stream
  (1 the listing, 3 the library being generated; other streams, or a
  file not open, are ignored).  0x0B5BDA: a word, a pointer and a word,
  by value (c_error's errorlst, put_es_line). }
procedure write_ln(
    stream: integer;
    buf: univ_ptr;
    len: integer); options(val_param); extern;

{ IOSUB_$WRITE - as write_ln, without the newline.  0x0B5C9A: no
  caller in either binary. }
procedure iosub_$write(
    stream: integer;
    buf: univ_ptr;
    len: integer); options(val_param); extern;

{ READ_LN - the next line of stream, at most maxlen characters, into
  buf (its newline dropped) and its length; true at the end of the file
  (or after an error).  0x0B5D4A: stream a word by value, buf by
  address, maxlen a word by value, len by address (ppio_$get_line). }
function read_ln(
    stream: integer;
    out buf: univ iosub_$name_t;
    maxlen: integer;
    out len: integer): boolean; options(val_param); extern;

{ IO_MARK, IO_RELEASE - remember stream's position, and go back to
  it (not for the listing when it is standard output or error output
  or not open).  0x0B5DD6, 0x0B5E4A: a word by value (c_main,
  preprocess, run_backend, unix_obj_gen). }
procedure io_mark(
    stream: integer); options(val_param); extern;

procedure io_release(
    stream: integer); options(val_param); extern;

{ TYPELN - s to error output, unless error_listing_0c is set.
  0x0B5EBA. }
procedure typeln(
    in s: univ iosub_$line_t); extern;

{ TYPEMSG - s to standard output, unless error_listing_0c is set.
  0x0B5F02 (c_main). }
procedure typemsg(
    in s: univ iosub_$line_t); extern;

{ LISTLN - s to the listing.  0x0B5F42 (62 call sites). }
procedure listln(
    in s: univ iosub_$line_t); extern;

{ EJCTLN - a page eject on the listing (ios_$put of a form feed and a
  newline while the listing is open).  0x0B5F6E: no parameters
  (c_sym_map's sym_map and print_addr_cons). }
procedure ejctln; extern;

{ SET_OBJ_LENGTH - add len to the object file's current offset, made
  even.  0x0B5FA8: a longword by value (unix_obj_gen). }
procedure set_obj_length(
    len: integer32); options(val_param); extern;

{ GETOBJ - map len bytes of the object file at offset from its current
  offset, to read.  0x0B6032: two longwords by value, the address in A0
  (coff_syms). }
function getobj(
    offset: integer32;
    len: integer32): univ_ptr; options(val_param); extern;

{ FREEOBJ - give back what putobj or getobj mapped.  0x0B6094: a
  pointer by value (70 call sites). }
procedure freeobj(
    p: univ_ptr); options(val_param); extern;

{ OPEN_INCLUDE_FILE - open the include file named by the len characters
  of name; sid gets its stream.  0x0B60D6 (cc.a88k 0x0B9B9E): name by
  address, len a word by value (its slot is also passed by address to
  strl_$copy), sid a word by address (ios_$open's result), then two
  booleans: when in_first is false the name is first copied by
  strl_$copy (to a 256-character buffer); the last is not read.  The
  result: whether it opened, and on something whose leaf name is not
  `.' (false for five `not found' statuses; another status is reported
  and ends the program).  Callers: inc_list's open_include_list_sub
  (in_first: the name was built on the first directory of its list,
  false for a name taken as it is), c_lex_pp's open_file_to_get_info
  (false). }
function open_include_file(
    in name: univ iosub_$name_t;
    len: integer;
    var sid: integer;
    in_first: boolean;
    unused: boolean): boolean; options(val_param); extern;

{ IOSUB_$GET_DTM - the time stream's file was last modified.
  0x0B61EA: a word by value, the result in D0 (c_lex_pp). }
function iosub_$get_dtm(
    sid: integer): integer32; options(val_param); extern;

{ IOSUB_$GET_FULL_PATH_NAME - a string constant node (strtk) of the
  full pathname of stream's file (for a case_hm file, without the
  residual name).  0x0B6238: a word by value, the node in A0
  (c_lex_pp; an il_$node_ptr_t, univ_ptr here since prfpkg opens this
  insert without il.ins.pas). }
function iosub_$get_full_path_name(
    sid: integer): univ_ptr; options(val_param); extern;

{ CLOSE_INCLUDE_FILE - close stream, ignoring failures.  0x0B6306: a
  word by value (c_lex_pp). }
procedure close_include_file(
    sid: integer); options(val_param); extern;
