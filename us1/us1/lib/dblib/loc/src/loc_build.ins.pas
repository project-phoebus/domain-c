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
