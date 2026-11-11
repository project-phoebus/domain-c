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

{ The headings were read off the frames and call sites, and narrowed
  from debug_sym_dmp.pas (translated): a routine with no call site in
  this tree (sz_fsym, varn_from_fortran_symbol: alias, list_tree and
  opt_inline call them) keeps the image's slots. }

{ The unit's other global routines are called only within it (or
  through PDS_'s and LOC_BUILD_'s routine pointers) and are declared in
  the unit file: allocfunc 0x0A83B0, dumpfunc 0x0A8428, obj_alloc
  0x0A847A, add_symbols_section 0x0A84C0, add_name_to_symbols_section
  0x0A8554, get_record_rep 0x0A9FBC, get_enum_rep 0x0AA2B6. }

{ SZ_FSYM - a Fortran symbol's size: a stub that reports a bug.
  0x0A8350, cc.a88k 0x0A9D30; frame 8:p (not read); 5 call sites
  (alias, list_tree, opt_inline); result in D0. }
function sz_fsym(
    sym: il_$node_ptr_t): integer32; options(val_param); extern;

{ VARN_FROM_FORTRAN_SYMBOL - a variable node standing for Fortran
  symbol sym of block blk (a fresh one when fresh, else the unit's
  own).  0x0A8664, cc.a88k 0x0AA044; frame 8:p/a 12:l (not read)
  16:w/b; 4 call sites (alias, list_tree); result in A0. }
function varn_from_fortran_symbol(
    sym: il_$node_ptr_t;
    blk: il_$node_ptr_t;
    fresh: boolean): il_$node_ptr_t; options(val_param); extern;

{ GET_INCLUDE_FILE_INDEX - the file (its source file mark) and line of
  a source position.  0x0A87F4, cc.a88k 0x0AA1D4; frame 8:w 10:a 14:a;
  7 call sites (outbin). }
procedure get_include_file_index(
    position: integer;
    out file_index: integer;
    out line: integer); options(val_param); extern;

{ DEBUG_SYM_DMP_$ADD_LOC_INFO - the objects' locations, once the code
  is placed.  0x0A9458, cc.a88k 0x0AAE38; 1 call site (unix_objmod). }
procedure debug_sym_dmp_$add_loc_info; extern;

{ DEBUG_SYM_DMP_$CREATE_SYMBOLS_SECTIONS - the .symbols sections made;
  the first and the last returned.  0x0AB3B8, cc.a88k 0x0ACD98; frame
  8:a 12:a; 1 call site (unix_objmod: its +0x5C30, +0x5C2C). }
procedure debug_sym_dmp_$create_symbols_sections(
    out first: il_$node_ptr_t;
    out last: il_$node_ptr_t); extern;

{ DEBUG_SYM_DMP_$DUMP_SYMBOLS_SECTION - section written at
  start_offset; its end returned.  0x0AB400, cc.a88k 0x0ACDE0; frame
  8:p/l 12:l/l 16:a; 1 call site (unix_objmod). }
procedure debug_sym_dmp_$dump_symbols_section(
    section: il_$node_ptr_t;
    start_offset: integer32;
    out end_offset: integer32); options(val_param); extern;

{ DEBUG_SYM_DMP_$BLOCK_DMP - the .blocks section written at offset
  (moved past it).  0x0AC20A, cc.a88k 0x0ADBEA; frame 8:l (not read)
  12:p/l; 1 call site (unix_objmod: the offset by value, then its
  address). }
procedure debug_sym_dmp_$block_dmp(
    start: integer32;
    in out offset: integer32); options(val_param); extern;

{ DEBUG_SYM_DMP_$INIT - 0x0AC44A, cc.a88k 0x0ADE2A; 1 call site
  (unix_objmod). }
procedure debug_sym_dmp_$init; extern;

{ DEBUG_SYM_DMP_$FINALIZE - 0x0AC5E4, cc.a88k 0x0ADFC4; 1 call site
  (unix_objmod). }
procedure debug_sym_dmp_$finalize; extern;

var
  { debug_sym_dmp.pas's data (A5 0x2C20CC cc.m68k) + 0x1090: a boolean
    gen_utils's make_new_addr_con clears and sets when OBJUTIL_ finds a
    symbol or section in an -inlib library.  debug_sym_dmp.pas does not
    read it. }
  debug_sym_dmp_1090: extern boolean;
