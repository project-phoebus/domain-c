{ us1/us1/lib/dblib/loc/src/loc_build.ins.pas - LOC_BUILD_, the debugger
  library's location builder (us1/us1/lib/dblib/loc/src/loc_build.c, a
  C unit linked into the compiler: cc.m68k 0x086650..0x0876CC): pools
  of location descriptions, opened by the code generators and dumped
  into the .symbols section.

  No Apollo copy survives; the headings are read off loc_build.c's
  frames and pds.pas's calls.  C routines: arguments by value.  Only
  what pds.pas uses is declared so far (debug_sym_dmp.pas opens it
  too).

  Not known from the original: the type and parameter names.
}

{ LOC_BUILD__POOL_SIZE - the bytes the pool's dump takes.  0x086882. }
function loc_build__pool_size(
    pool: univ_ptr): integer32; options(val_param); extern;

{ LOC_BUILD__DUMP_POOL - the pool written at offset base of the object
  file (p2: pds.pas passes 0).  0x086A3E. }
procedure loc_build__dump_pool(
    pool: univ_ptr;
    p2: integer32;
    base: integer32); options(val_param); extern;

{ What debug_sym_dmp.pas uses (read off its calls and loc_build.c's
  frames: shorts are words, everything else a longword; a pool, a list
  and a location are pointers returned in D0). }

{ LOC_BUILD__INIT - the library set up: the allocator (allocfunc) and
  writer (dumpfunc) it calls, and the kind (debug_sym_dmp passes 2 for
  targets 1..3, else 1; p2 nil).  0x086650. }
procedure loc_build__init(
    alloc_func: univ_ptr;
    p2: univ_ptr;
    dump_func: univ_ptr;
    kind: integer); options(val_param); extern;

{ LOC_BUILD__OPEN_POOL - a new location pool.  0x086868. }
function loc_build__open_pool: univ_ptr; extern;

{ LOC_BUILD__OPEN_LIST - a list of ranged locations in the pool (base
  the routine's start; flag: debug_sym_dmp passes true when the target
  is not 1..3, for statement ranges rather than pc ranges).
  0x0868A8. }
function loc_build__open_list(
    pool: univ_ptr;
    base: integer32;
    flag: boolean): univ_ptr; options(val_param); extern;

{ LOC_BUILD__DEFAULT - the list's default location.  0x086B92. }
procedure loc_build__default(
    list: univ_ptr;
    loc: univ_ptr); options(val_param); extern;

{ LOC_BUILD__PC_RANGE - loc from pc lo to pc hi.  0x086BF6. }
procedure loc_build__pc_range(
    list: univ_ptr;
    loc: univ_ptr;
    lo: integer32;
    hi: integer32); options(val_param); extern;

{ LOC_BUILD__STMT_RANGE - loc from a statement (line, file, the
  position's top byte) to another.  0x086C84. }
procedure loc_build__stmt_range(
    list: univ_ptr;
    loc: univ_ptr;
    line1: integer32;
    file1: integer;
    byte1: integer;
    line2: integer32;
    file2: integer;
    byte2: integer); options(val_param); extern;

{ LOC_BUILD__CLOSE_LIST - the list closed (by address); its offset in
  the pool returned (negative on an error).  0x0871F6. }
function loc_build__close_list(
    var list: univ_ptr): integer32; extern;

{ LOC_BUILD__REGISTER_LOC - the location of a register.  0x087284. }
function loc_build__register_loc(
    reg: integer): univ_ptr; options(val_param); extern;

{ LOC_BUILD__RELATIVE_LOC - kind (1 a section's, 2 a register's, 4,
  5), register or section, offset, then the addresses of the longwords
  to go through (none, one or two), ended by nil: a C routine of a
  variable number of arguments (debug_sym_dmp passes 12, 16 or 20
  bytes), declared with the most and called with fewer.  0x08737C. }
function loc_build__relative_loc(
    kind: integer;
    reg: integer;
    offset: integer32;
    ind1: univ_ptr;
    ind2: univ_ptr;
    ind3: univ_ptr): univ_ptr; options(val_param, variable); extern;
