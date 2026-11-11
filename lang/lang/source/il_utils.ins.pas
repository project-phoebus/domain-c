{ lang/lang/source/il_utils.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/il_utils.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ IL_UTILS - IL tree utilities: use counts, substitution, tree search and
  comparison, classifying variables.  il_utils.pas (cc.m68k
  0x07D9A4..0x07E7B2, cc.a88k 0x07F384..0x080192).  Headings from the
  bodies and the call sites; search_point and search_walk are nested in
  il_utils_$search_tree_for_node and read its parameters through its
  frame, which is why its own frame shows only its first.

  Not known from the original: every parameter name. }

type
  { What the front end's type_exp gives for a variable (count_vars and
    opt_main's init_opt_info_for_vars pass a 32-byte local to it and to
    il_utl_$classify_variable). }
  il_utils_$type_info_t = record case integer of
    1: (tp: il_$node_ptr_t);            { +0: the type's node (kinds
                                          123, 130, 134 tested) }
    2: (c: array [0..31] of char);      { +25 bit 6 tested }
  end;

{ IL_UTL_$CLASSIFY_VARIABLE - the class (0..15) of the variable node v
  (kinds 109, 110) of block blk; next gets the variable after it.
  0x07D9A4: info by address, next by address. }
function il_utl_$classify_variable(
    v: il_$node_ptr_t;
    in info: il_utils_$type_info_t;
    blk: il_$node_ptr_t;
    out next: il_$node_ptr_t): integer; options(val_param); extern;

{ IL_UTL_$COUNT_VARS - mark the variables of blk and its kind 172
  successors by class and count those marked (at most 255).
  0x07DBA2. }
function il_utl_$count_vars(
    blk: il_$node_ptr_t): integer; options(val_param); extern;

{ IL_UTILS_$ADJUST_UC, ADJUST_UC - add delta to the use counts of a tree
  (62 and 50 call sites).  0x07DCF8, 0x07E018. }
procedure il_utils_$adjust_uc(
    t: il_$node_ptr_t;
    delta: integer); options(val_param); extern;

procedure adjust_uc(
    t: il_$node_ptr_t;
    delta: integer); options(val_param); extern;

{ IL_UTILS_$SET_UC_WALK_SPINE - add 1 to the use counts along the
  chain (+8) from t, the operands on spine kept from it.  0x07E03A. }
procedure il_utils_$set_uc_walk_spine(
    t: il_$node_ptr_t;
    spine: il_$node_ptr_t); options(val_param); extern;

{ IL_UTILS_$DO_SUBSTITUTION - store new in slot, an operand of old, the
  use counts adjusted, and record the substitution for a strength
  reduction temporary.  0x07E092: slot by address. }
procedure il_utils_$do_substitution(
    old: il_$node_ptr_t;
    var slot: il_$node_ptr_t;
    new: il_$node_ptr_t); options(val_param); extern;

{ IL_UTILS_$TREE_NODE_OPERAND_IS_SPINE - whether operand i of operator op
  is on the spine (operands 2 and 3 of operators 30..32).  0x07E184. }
function il_utils_$tree_node_operand_is_spine(
    op: integer;
    i: integer): boolean; options(val_param); extern;

{ IL_UTILS_$IS_STRENGTH_REDUCTION_TEMP - 0x07E1CA. }
function il_utils_$is_strength_reduction_temp(
    t: il_$node_ptr_t): boolean; options(val_param); extern;

{ IL_UTILS_$SEARCH_TREE_FOR_NODE - the node of tree that has node (or,
  unless same_only, a tree equivalent to it) as an operand, or nil.
  0x07E3D4. }
function il_utils_$search_tree_for_node(
    tree: il_$node_ptr_t;
    node: il_$node_ptr_t;
    same_only: boolean): il_$node_ptr_t; options(val_param); extern;

{ IL_UTILS_$SOURCE_GENERATED_TOP_LEVEL_NODE - the first top-level node
  from t (along +8) with a source position, else t.  0x07E3FE. }
function il_utils_$source_generated_top_level_node(
    t: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ IL_UTILS_$SRC_LINE - the source position of the first top-level node
  from t (along +4) that has one, else 0.  0x07E4CC. }
function il_utils_$src_line(
    t: il_$node_ptr_t): integer; options(val_param); extern;

{ IL_UTILS_$TREES_EQUIVALENT - 0 when a and b are the same tree, else 4.
  0x07E578. }
function il_utils_$trees_equivalent(
    a: il_$node_ptr_t;
    b: il_$node_ptr_t): integer; options(val_param); extern;
