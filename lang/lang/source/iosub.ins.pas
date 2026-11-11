{ lang/lang/source/iosub.ins.pas - IOSUB, the compilers' input and
  output: the listing, the terminal, ending the run
  (lang/lang/source/iosub.pas).  Opened after prtsub.ins.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  Only what the translated units use is declared so far; the headings
  are read off iosub.pas's frames and its callers.

  Not known from the original: the parameter names.
}

{ TODO(pascal) iosub.ins.pas is incomplete

  The rest of IOSUB's interface is added when iosub.pas and its
  callers are translated. }

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
    in s: prtsub_$line_t); extern;

{ LISTLN - s to the listing.  0x0B5F42 (62 call sites). }
procedure listln(
    in s: prtsub_$line_t); extern;
