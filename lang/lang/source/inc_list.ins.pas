{ lang/lang/source/inc_list.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/inc_list.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ INC_LIST - the include directories (-idir) and the libraries to bind
  with (-inlib), searched in order.  inc_list.pas (cc.m68k
  0x0AC9BC..0x0ACD92).  Headings from the frames and call sites
  (tools/cc_params.py); the routines with no call site
  (find_file_name, open_include_list) are global and kept.

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) inc_list headings are read off the frames only

  Types and modes are the conservative reading (univ_ptr for pointers,
  the width's integer for values, by value); refine them when inc_list.pas and
  its callers are translated. }

procedure find_file_name(
    a: integer32;
    flag: boolean;
    b: integer32;
    p: univ_ptr;
    q: univ_ptr); options(val_param); extern;

procedure open_include_list(
    a: integer32;
    flag: boolean;
    p: univ_ptr;
    b: integer32;
    q: univ_ptr;
    r: univ_ptr); options(val_param); extern;

{ OPEN_INCLUDE_LIST_SUB - 0x0ACA4A; its callers (open_include in
  c_lex_pp) pass the name, its length, ... }
procedure open_include_list_sub(
    p: univ_ptr;
    flag: boolean;
    a: integer32;
    q: univ_ptr;
    r: univ_ptr;
    s: univ_ptr); options(val_param); extern;

procedure open_inlib_list_sub(
    p: univ_ptr); options(val_param); extern;

{ OPEN_INLIB_LIST - open each -inlib library (gen_utils inlib_add).
  0x0ACD52. }
procedure open_inlib_list; extern;
