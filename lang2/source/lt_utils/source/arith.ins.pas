{ lang2/source/lt_utils/source/arith.ins.pas - ARITH, saturating
  integer32 arithmetic for constant folding.

  No Apollo copy survives; the heading is read off arith.pas (cc.m68k
  0x075350) and its callers (c_expr_sem.pas's expr_op, which passes the
  operations 0 and 2).  It stands alone (arith.pas opens nothing else).

  Not known from the original: the type, constant and parameter names.
}

type
  { The operation, a word: 0 add, 1 subtract, 2 multiply, 3 divide. }
  arith_$op_t = (arith_$add, arith_$subtract, arith_$multiply, arith_$divide);

{ ARITH - a op b, held to 16#7FFFFFFF and -16#80000000 on overflow; a
  division by 0 gives 0.  0x075350: op a word at (8,A6), a at (10,A6),
  b at (14,A6). }
function arith(
    op: arith_$op_t;
    a: integer32;
    b: integer32): integer32; options(val_param); extern;
