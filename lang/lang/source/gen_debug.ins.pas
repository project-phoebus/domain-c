{ lang/lang/source/gen_debug.ins.pas - GEN_DEBUG_, the debugging tables'
  buffers: the .lines section's line and pc packets and the exception
  tables, collected per range (a routine's code) in pages and written
  to the object file at the end of the pass (lang/lang/source/
  gen_debug.pas).

  No Apollo copy survives; the headings are read off gen_debug.pas
  (cc.m68k 0x0792D4..0x079FB0, the same in cc.a88k) and its callers
  (unix_objmod's output_data_info, coff's purge_stack,
  coff_lines_proc_start, coff_lines_instruction, coff_lines_proc_end,
  wr_instr, debug_sym_dmp's write_blocks).  Values by value
  (val_param).

  Not known from the original: every type and parameter name here.
}

type
  { The tables' mode (gen_debug_$begin_compilation): 0 and 1 the
    ranges' tables kept (1 the .lines packets), 3 the ranges share the
    module's buffers, 7 the pc counted in 2-byte units (else 4), 15
    every page kept until the end (else each written when full).  The
    unix objmod passes [1, 15] (16#8002) or [1, 7, 15] (16#8082). }
  gen_debug_$mode_t = set of 0..15;

  { A range (gen_debug_$range_open's result). }
  gen_debug_$range_ptr_t = univ_ptr;

{ GEN_DEBUG_$READ_FILE_INDEX - the current range's file (1 with none).
  0x07952A. }
function gen_debug_$read_file_index: integer32; extern;

{ GEN_DEBUG_$SET_FILE_INDEX - 0x079550. }
procedure gen_debug_$set_file_index(
    file_index: integer32); options(val_param); extern;

{ GEN_DEBUG_$BEGIN_COMPILATION - the heaps and buffers set up.
  0x07961A. }
procedure gen_debug_$begin_compilation(
    mode: gen_debug_$mode_t); options(val_param); extern;

{ GEN_DEBUG_$BEGIN_PASS - 0x0796C2. }
procedure gen_debug_$begin_pass; extern;

{ GEN_DEBUG_$READY_OUTPUT - the exception tables' offset in the object
  file (the .lines section's follows them); p1 and p3 not read.
  0x079714. }
procedure gen_debug_$ready_output(
    p1: integer32;
    exc_offset: integer32;
    p3: integer32); options(val_param); extern;

{ GEN_DEBUG_$END_PASS - the .lines section evened; its size (with the
  exception tables') returned; p1 and p3 not read.  0x0797DC. }
procedure gen_debug_$end_pass(
    in p1: integer32;
    out size: integer32;
    in p3: integer32); extern;

{ GEN_DEBUG_$END_COMPILATION - the buffers written.  0x07981C. }
procedure gen_debug_$end_compilation; extern;

{ GEN_DEBUG_$RANGE_OPEN - a new range starting at pc (the current one's
  statement ended first); p1 and p2 not read.  0x07996C. }
function gen_debug_$range_open(
    p1: integer32;
    p2: integer32;
    pc: integer32): gen_debug_$range_ptr_t; options(val_param); extern;

{ GEN_DEBUG_$RANGE_CLOSE - the range ended at pc (0: its last pc); its
  .lines offset returned.  0x079B44. }
function gen_debug_$range_close(
    range: gen_debug_$range_ptr_t;
    pc: integer32): integer32; options(val_param); extern;

{ GEN_DEBUG_$SET_ACTIVE_BUFFER - another range made current (the
  current one's statement ended at pc - 1).  0x079C26. }
procedure gen_debug_$set_active_buffer(
    range: gen_debug_$range_ptr_t;
    pc: integer32); options(val_param); extern;

{ GEN_DEBUG_$EXCEPTION_TABLE_SIZE - the exception tables' bytes.
  0x079C6A. }
function gen_debug_$exception_table_size: integer32; extern;

{ GEN_DEBUG_$EXCEPTION_TABLE_CLOSE - the range's exception table ended;
  its offset returned (-1 when empty).  0x079C82. }
function gen_debug_$exception_table_close(
    range: gen_debug_$range_ptr_t): integer32; options(val_param);
    extern;

{ GEN_DEBUG_$EXCEPTION_SITE - an exception table entry at pc (none when
  both values are 0).  0x079D0A. }
procedure gen_debug_$exception_site(
    pc: integer32;
    w: integer;
    b: integer); options(val_param); extern;

{ GEN_DEBUG_$LINES_DEF - a statement at line of file starts at pc.
  0x079E34. }
procedure gen_debug_$lines_def(
    file_index: integer32;
    line: integer32;
    stmt: integer32;
    pc: integer32); options(val_param); extern;

{ GEN_DEBUG_$LINES_STMT_END - the statement ends at pc.  0x079EEA. }
procedure gen_debug_$lines_stmt_end(
    pc: integer32); options(val_param); extern;

{ GEN_DEBUG_$LINES_ENTRY, GEN_DEBUG_$LINES_RETURN - an entry and a
  return marked.  0x079F2C, 0x079F76. }
procedure gen_debug_$lines_entry; extern;
procedure gen_debug_$lines_return; extern;
