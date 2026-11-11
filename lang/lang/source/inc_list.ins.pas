{ lang/lang/source/inc_list.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/inc_list.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ INC_LIST - the include directories (-idir) and the libraries to bind
  with (-inlib): opening an include file through the directories, in
  order, and handing each library to inlib_add.  inc_list.pas (cc.m68k
  0x0AC9BC..0x0ACD92, cc.a88k 0x0AE39C..0x0AE772).  Headings from the
  bodies and the call sites (c_lex_pp open_include, iosub_$init_io);
  the routines with no call site (find_file_name, open_include_list)
  are global and kept.

  Not known from the original: every parameter name. }

type
  { An entry of the lists: a -idir or -inlib argument (cargs's
    parse_options), or the including file's directory (c_lex_pp's
    open_include gets 1026 bytes from gspace for it). }
  inc_list_$name_ptr_t = ^cargs_$name_t;

var
  { inc_list.pas's data, A5 0x2C3178 (cc.m68k), 0x4431E8 (cc.a88k).
    c_main's cc passes the lists, their sizes and counts to
    iosub_$init_all, which passes them on to
    cargs_$parse_command_line_options (inlibs: size 65; idirs: size
    64). }
  inc_list_inlibs: extern array [1..65] of inc_list_$name_ptr_t;  { +0x0 }
  inc_list_idirs: extern array [1..65] of inc_list_$name_ptr_t;   { +0x108:
                                          [1] the including file's
                                          directory under -usrch
                                          (c_lex_pp open_include,
                                          ppio_$get_line); c_main's
                                          addincludes passes [2..] to
                                          the preprocessor as -I }
  inc_list_ninlib: extern integer;      { +0x20C (unix_objmod) }
  inc_list_nidir: extern integer;       { +0x20E (c_main) }

{ FIND_FILE_NAME - the path of the include file named by name (closing
  delimiter delim): open_include_list_sub into a stream of its own;
  found is set whatever the outcome.  0x0AC9BC. }
procedure find_file_name(
    name: il_$node_ptr_t;
    delim: char;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out found: boolean); options(val_param); extern;

{ OPEN_INCLUDE_LIST - open_include_list_sub, found set whatever the
  outcome.  0x0ACA0C. }
procedure open_include_list(
    name: il_$node_ptr_t;
    delim: char;
    var sid: integer;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out found: boolean); options(val_param); extern;

{ OPEN_INCLUDE_LIST_SUB - open the include file named by the string
  node name (its characters end in the closing delimiter, delim): a
  name beginning with an absolute prefix is opened as it is, else it is
  looked for in inc_list_idirs from the first (`"') or the second
  (`>'); path and pathlen get the name opened, in_first whether it was
  the first directory's.  The result: whether a file opened.  0x0ACA4A;
  open_include (c_lex_pp) passes the token, its delimiter, its stream
  and the include record's path buffer (1023 bytes) and length. }
function open_include_list_sub(
    name: il_$node_ptr_t;
    delim: char;
    var sid: integer;
    out path: univ cargs_$chars_t;
    out pathlen: integer;
    out in_first: boolean): boolean; options(val_param); extern;

{ OPEN_INLIB_LIST_SUB - pass the i-th -inlib library to inlib_add, a
  relative name made `./name'.  0x0ACC34: i by address (open_inlib_list
  passes a copy of its loop index). }
procedure open_inlib_list_sub(
    in i: integer); extern;

{ OPEN_INLIB_LIST - open each -inlib library.  0x0ACD52 (iosub_$init_io). }
procedure open_inlib_list; extern;
