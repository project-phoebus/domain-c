{ lang/lang/source/g_opt.ins.pas - the global optimizer's insert
  (opt_*), opened by kfold.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what kfold, cg_call and cg_top need is declared.

  Not known from the original: every name here.
}

{ TODO(pascal) g_opt.ins.pas is a stub

  Add the optimizer's declarations as its units are translated. }

type
  { An entry of opt_main's table at +0x4009C (kfold's node_number):
    +16 the range of IL node numbers (il_120's indexes) +8..+10. }
  g_opt_range_ptr_t = ^g_opt_range_t;
  g_opt_range_t = record
    unused_0: array [1..4] of integer;  { +0 }
    first: integer;                     { +8 }
    last: integer;                      { +10 }
  end;
  g_opt_ent_ptr_t = ^g_opt_ent_t;
  g_opt_ent_t = record
    unused_0: array [1..4] of integer32;  { +0 }
    range: g_opt_range_ptr_t;           { +16 }
  end;

  { A basic block's record as the code generator reads it (il_11c
    points to the blocks by number, from 1; select_block_list and
    select_loop return lists of them through +92).  cg_top's
    initialize_tree and basicblock. }
  g_opt_loop_ptr_t = ^g_opt_loop_t;
  g_opt_loop_t = record
    unused_0: array [0..40] of integer; { +0 }
    head: integer;                      { +82: select_loop's argument }
  end;
  g_opt_bb_ptr_t = ^g_opt_bb_t;
  g_opt_bb_t = record
    flags: char;                        { +0: bits 3 and 2 tested
                                          (initialize_tree: a block with
                                          bit 2 and not 3 heads a loop) }
    unused_1: array [1..11] of char;    { +1 }
    regs_in: univ_ptr;                  { +12: nil when no register
                                          contents carry into the block
                                          (basicblock) }
    unused_16: array [1..2] of integer32;  { +16 }
    cache_in: univ_ptr;                 { +24: the object cache the
                                          block starts with (basicblock:
                                          cg_addr's entries from +4) }
    unused_28: array [1..16] of integer32;  { +28 }
    next: g_opt_bb_ptr_t;               { +92: the select lists' link }
    unused_96: integer32;               { +96 }
    regs: set of 0..31;                 { +100: the registers free over
                                          the block (initialize_tree) }
    unused_104: integer32;              { +104 }
    loop: ^g_opt_loop_ptr_t;            { +108 }
  end;
  g_opt_bb_list_ptr_t = ^array [1..16383] of g_opt_bb_ptr_t;

var
  { opt_main.pas's data +0x8 (cc.m68k 0x2D2EF8, reached absolutely):
    a memory pool cg_top's codegen empties at the end. }
  opt_main_8: extern univ_ptr;

  { opt_main.pas's data +0x4009C (cc.m68k 0x312F8C, cc.a88k 0x4D3938,
    reached absolutely): kfold's node_number reads entry w (from 1).
    opt_main defines it. }
  opt_4009c: extern array [1..16383] of g_opt_ent_ptr_t;

{ PARAMCLASS - the class of argument k of call n (cg_call's
  kill_any_param_alias tests 1, 3 and 4: the arguments passed by
  reference).  opt_reachdef 0x0E235C: 8 a pointer, 12 a word; D0 a
  word. }
function paramclass(
    n: il_$node_ptr_t;
    k: integer): integer; options(val_param); extern;

{ SELECT_BLOCK_LIST - the blocks from block first back to block last
  (cg_top's initialize_tree passes n + 1 and n), linked through +92.
  opt_select 0x0E57DA: 8 and 10 words; the list in A0. }
function select_block_list(
    first: integer;
    last: integer): g_opt_bb_ptr_t; options(val_param); extern;

{ SELECT_LOOP - the blocks of the loop headed by block head, linked
  through +92.  opt_select 0x0E58FC: a word; the list in A0. }
function select_loop(
    head: integer): g_opt_bb_ptr_t; options(val_param); extern;
