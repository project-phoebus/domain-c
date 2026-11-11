{ us/us/ins/objutil.ins.pas - Apollo's internal OBJUTIL_ insert
  (//us/us/ins): the binder's object utilities, linked into the compiler
  from lang/bind/source/objutil.pas.  No copy survives.  Only what the
  translated units use is declared so far, read off gen_utils's calls.

  Not known from the original: everything about its contents.
}

{ TODO(pascal) objutil.ins.pas is incomplete

  Declarations are added as the units that use them are translated. }

{ OBJUTIL_$INLIB_INIT - start reading -inlib libraries: errproc (the
  routine errors are reported through; gen_utils passes inlib_error's
  address, a constant in its code) and the target's magic number, both
  by address.  objutil.pas 0x08E83A (cc.m68k). }
procedure objutil_$inlib_init(
    in errproc: univ_ptr;
    in magic: integer32); extern;

{ OBJUTIL_$INLIB_LIBNAME - a library to read (its name and the name's
  length, by address).  0x08E8B6. }
procedure objutil_$inlib_libname(
    in name: univ cargs_$chars_t;
    in len: integer); extern;

{ OBJUTIL_$INLIB_TERMINATE - 0x08EB74. }
procedure objutil_$inlib_terminate; extern;

{ OBJUTIL_$INLIB_LOOKUP_SYMBOL - whether a library defines the symbol
  named by the len characters of name, of the kinds in flags; info gets
  what is known of it.  0x08E976: every parameter by address. }
function objutil_$inlib_lookup_symbol(
    in name: univ cargs_$chars_t;
    in len: integer;
    in flags: integer;
    out info: univ cargs_$chars_t): boolean; extern;

{ OBJUTIL_$INLIB_LOOKUP_SECTION - whether a library defines the section
  named by the len characters of name.  0x08EADC: every parameter by
  address; gen_utils passes a kind 111 node's +20 third. }
function objutil_$inlib_lookup_section(
    in name: univ cargs_$chars_t;
    in len: integer;
    in sect: integer32;
    in flags: integer): boolean; extern;
