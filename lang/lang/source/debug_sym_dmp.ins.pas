{ lang/lang/source/debug_sym_dmp.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/debug_sym_dmp.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ DEBUG_SYM_DMP - the debugger's symbol sections of the object
  module (debug_sym_dmp_$init, _$create_symbols_sections,
  _$dump_symbols_section, _$block_dmp, _$finalize, all called by
  unix_objmod) and the symbol helpers other units use.
  debug_sym_dmp.pas (cc.m68k 0x0A8350, A5 0x2C20CC; cc.a88k 0x0A9D30,
  A5 0x44213C).

  The headings of the 9 routines of the unit other units call (of its 56
  routines), read off the frames and the call sites (docs/core-plan.md,
  method change): the frame slots are given as offset:push/use, the push
  at the call sites (p an address, l a longword, w a word, b a byte in a
  word) and the routine's own use of the slot (a moved to an address
  register, l, w or b read as a value, p its address taken); a pointer
  is univ_ptr until its target is known, every slot is a value
  (val_param); a function is one whose callers read D0 or A0 after the
  call (A0 a pointer).

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) debug_sym_dmp headings are read off the frames only

  Narrow the univ_ptr parameters and results to the node types, and name
  the parameters, when debug_sym_dmp.pas and its callers are translated.  A
  routine with no call site (0 call sites) is reached through a
  procedure pointer or not at all; its result is read off its epilogue. }

{ The unit's other global routines are called only within it (or not at
  all) and are left to the unit file: allocfunc 0x0A83B0, dumpfunc
  0x0A8428, obj_alloc 0x0A847A, add_symbols_section 0x0A84C0,
  add_name_to_symbols_section 0x0A8554, get_record_rep 0x0A9FBC,
  get_enum_rep 0x0AA2B6. }

{ SZ_FSYM - 0x0A8350, cc.a88k 0x0A9D30; frame 8:p; 5 call sites (alias,
  list_tree, opt_inline); result in D0. }
function sz_fsym(
    p1: univ_ptr): integer32; options(val_param); extern;

{ VARN_FROM_FORTRAN_SYMBOL - 0x0A8664, cc.a88k 0x0AA044; frame 8:p/a
  12:l 16:w/b; 4 call sites (alias, list_tree); result in A0. }
function varn_from_fortran_symbol(
    p1: univ_ptr;
    p2: integer32;
    p3: integer): univ_ptr; options(val_param); extern;

{ GET_INCLUDE_FILE_INDEX - 0x0A87F4, cc.a88k 0x0AA1D4; frame 8:w/w
  10:p/a 14:p/a; 7 call sites (outbin). }
procedure get_include_file_index(
    p1: integer;
    p2: univ_ptr;
    p3: univ_ptr); options(val_param); extern;

{ DEBUG_SYM_DMP_$ADD_LOC_INFO - 0x0A9458, cc.a88k 0x0AAE38; 1 call site
  (unix_objmod). }
procedure debug_sym_dmp_$add_loc_info; extern;

{ DEBUG_SYM_DMP_$CREATE_SYMBOLS_SECTIONS - 0x0AB3B8, cc.a88k 0x0ACD98;
  frame 8:p/a 12:p/a; 1 call site (unix_objmod). }
procedure debug_sym_dmp_$create_symbols_sections(
    p1: univ_ptr;
    p2: univ_ptr); options(val_param); extern;

{ DEBUG_SYM_DMP_$DUMP_SYMBOLS_SECTION - 0x0AB400, cc.a88k 0x0ACDE0;
  frame 8:p/l 12:l/l 16:p/a; 1 call site (unix_objmod). }
procedure debug_sym_dmp_$dump_symbols_section(
    p1: univ_ptr;
    p2: integer32;
    p3: univ_ptr); options(val_param); extern;

{ DEBUG_SYM_DMP_$BLOCK_DMP - 0x0AC20A, cc.a88k 0x0ADBEA; frame 8:l
  12:p/l; 1 call site (unix_objmod). }
procedure debug_sym_dmp_$block_dmp(
    p1: integer32;
    p2: univ_ptr); options(val_param); extern;

{ DEBUG_SYM_DMP_$INIT - 0x0AC44A, cc.a88k 0x0ADE2A; 1 call site
  (unix_objmod). }
procedure debug_sym_dmp_$init; extern;

{ DEBUG_SYM_DMP_$FINALIZE - 0x0AC5E4, cc.a88k 0x0ADFC4; 1 call site
  (unix_objmod). }
procedure debug_sym_dmp_$finalize; extern;
