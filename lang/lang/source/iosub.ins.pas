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

var
  { iosub.pas's data, A5 0x2CD7E4 (cc.m68k): the source file's full
    pathname (+0x428, its length +0x930) and whether a library is being
    generated (+0x936, outputs element 4: open_plb_file). }
  iosub_$source_pathname: extern array [1..1024] of char;
  iosub_$source_pathname_length: extern integer;
  iosub_$generating_library: extern boolean;

{ EJCTLN - start a new listing page.  0x0B5F6E. }
procedure ejctln; extern;

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
