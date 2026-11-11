{ lang/lang/source/g_opt.ins.pas - the global optimizer's insert
  (opt_*), opened by kfold.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  A stub: only what kfold and cg_call need is declared.

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

var
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
