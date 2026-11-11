{ us/us/ins/objutil.ins.pas - OBJUTIL_, the binder's reader of the
  libraries a program is bound against (its "inlibbed" libraries, OBJ or
  COFF), linked into the compiler from lang/bind/source/objutil.pas:
  what gen_utils.pas calls (-inlib), and the error routine it hands
  over (gen_utils's inlib_error).

  No copy survives.  The declarations are the source repository's
  com/bind/objutil.ins.pas reconstruction (read off the SR10.2 /com/bind's
  objutil and its callers); cc's objutil.pas has the same frames.  Three
  parameters are univ here, not in the SR10.2 reconstruction: gen_utils
  passes inlib_error's address (an expression) for the error routine,
  an integer it builds by `!' for the lookups' options (bit n the set's
  element n), and a 280-byte frame area for the kind (cc.m68k
  make_new_addr_con, 0x07C6EE..).

  Include /sys/ins/base.ins.pas (us/us/ins/ubase.ins.pas) before it.

  Not known from the original: every name here but the routines'.
}

const
  { The severity the error routine is given. }
  objutil_$warning = 0;                 { reported, the library is read }
  objutil_$note = 1;                    { reported, the library is read }
  objutil_$skipped = 2;                 { the library is not read }

  { objutil_$lookup_opts_t members. }
  objutil_$lookup_kgt = 0;              { the known global table first }
  objutil_$lookup_data = 1;             { only data symbols there }
  objutil_$lookup_function = 2;         { only functions there }

  { objutil_$inlib_lookup_symbol's kind: what the known global table
    says the symbol is (0: not said). }
  objutil_$kind_data = 1;
  objutil_$kind_function = 2;

type
  objutil_$string_t = array[1..1024] of char;

  { The error routine: the message and the library's name end with a NUL
    (the code is always 0). }
  objutil_$error_proc_t = ^procedure(
      in severity: integer;
      in code: integer;
      in name: univ objutil_$string_t;
      in msg: univ objutil_$string_t);

  objutil_$lookup_opts_t = set of 0..15;

{ OBJUTIL_$INLIB_INIT - start over: no libraries; the error routine and
  the target (an object file magic number, 0 for any). }
procedure objutil_$inlib_init(
    in error_proc: univ objutil_$error_proc_t;
    in target: integer32); extern;

{ OBJUTIL_$INLIB_LIBNAME - add a library to read when a name is looked
  up (once). }
procedure objutil_$inlib_libname(
    in name: univ objutil_$string_t;
    in len: integer); extern;

{ OBJUTIL_$INLIB_FIND_SYMBOL - whether the libraries define a global. }
function objutil_$inlib_find_symbol(
    in name: univ objutil_$string_t;
    in len: integer): boolean; extern;

{ OBJUTIL_$INLIB_LOOKUP_SYMBOL - whether the known global table (with
  objutil_$lookup_kgt) or the libraries define a global. }
function objutil_$inlib_lookup_symbol(
    in name: univ objutil_$string_t;
    in len: integer;
    in opts: univ objutil_$lookup_opts_t;
    out kind: univ integer): boolean; extern;

{ OBJUTIL_$INLIB_FIND_SECTION - whether the libraries define a section
  at least size bytes long. }
function objutil_$inlib_find_section(
    in name: univ objutil_$string_t;
    in len: integer;
    in size: integer32): boolean; extern;

{ OBJUTIL_$INLIB_LOOKUP_SECTION - the same, the known global table first
  with objutil_$lookup_kgt. }
function objutil_$inlib_lookup_section(
    in name: univ objutil_$string_t;
    in len: integer;
    in size: integer32;
    in opts: univ objutil_$lookup_opts_t): boolean; extern;

{ OBJUTIL_$INLIB_TERMINATE - release what the libraries' names took. }
procedure objutil_$inlib_terminate; extern;
