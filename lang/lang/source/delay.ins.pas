{ lang/lang/source/delay.ins.pas - the interface of
  lang/lang/source/delay.pas (DELAY: narrowing the IL trees' operations
  to the registers' widths the target needs, and the division
  strategies).  Opened by delay.pas; the back end's division code (cg_*
  div_proc, reg_cost's registers_consumed_by_tree_operator) and the
  optimizer's vector units call delay_$divide_attributes and
  delay_$splice.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries.
  delay_$shrink_top_level_node is declared in the prelude
  (globals_from_general.ins.pas: c_stmt_sem calls it without opening
  this insert).

  Not known from the original: the parameter names. }

{ DELAY_$VALUE_GUARANTEED_BETWEEN - whether n is an integer constant
  between lo and hi (compared signed or unsigned).  0x076658, cc.a88k
  0x078038; result in D0. }
function delay_$value_guaranteed_between(
    n: il_$node_ptr_t;
    lo: integer32;
    hi: integer32;
    sgn: boolean): boolean; options(val_param); extern;

{ DELAY_$FIND_SIZE_AND_SIGNED - the tree n (by address) followed down
  its conversions: leaf the tree reached, size its register class (the
  least of size and the conversions' when narrow), sgn its signedness.
  0x0766D8, cc.a88k 0x0780B8. }
procedure delay_$find_size_and_signed(
    var n: il_$node_ptr_t;
    in narrow: boolean;
    var leaf: il_$node_ptr_t;
    var size: integer;
    var sgn: boolean); extern;

{ DELAY_$DIVIDE_ATTRIBUTES - how the division or remainder n is done:
  the strategy (1..13, delay.pas's div_strategies) chosen by the
  operands' sizes and signedness and the target, and the strategy's
  fields for the operation (the operand and result classes, ...);
  narrow allows a narrower operation.  0x0769AA, cc.a88k 0x07838A; the
  back end's div_proc and registers_consumed_by_tree_operator call it
  with frame variables. }
procedure delay_$divide_attributes(
    n: il_$node_ptr_t;
    narrow: boolean;
    var strategy: integer32;
    var w18: integer;
    var lsize: integer32;
    var w26: integer;
    var rsize: integer32;
    var w34: integer;
    var w38: integer;
    var w42: integer;
    var w46: integer;
    var shift: integer32;
    var b54: boolean;
    var b58: boolean;
    var w62: integer;
    var w66: integer;
    var w70: integer); options(val_param); extern;

{ DELAY_$TAILOR_OPERANDS_TO_HARDWARE - convert the operands of the
  division, remainder or multiplication n (or of the one a conversion
  n converts) to the classes the hardware takes; the class of the
  result.  0x076ECA, cc.a88k 0x0788AA; result in D0. }
function delay_$tailor_operands_to_hardware(
    n: il_$node_ptr_t): integer; options(val_param); extern;

{ DELAY_$SPLICE - n converted to the class size (a conversion node,
  operator 18, of srcsize, signed by sgn), or n itself when its class
  is size and force is not set.  0x077158, cc.a88k 0x078B38; 18 call
  sites (delay, opt_vector, ...); result in A0. }
function delay_$splice(
    n: il_$node_ptr_t;
    size: integer;
    sgn: boolean;
    srcsize: integer;
    force: boolean): il_$node_ptr_t; options(val_param); extern;
