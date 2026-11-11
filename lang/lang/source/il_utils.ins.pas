{ lang/lang/source/il_utils.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/il_utils.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ IL_UTILS - IL tree utilities: use counts, substitution, tree search and
  comparison, classifying variables.  il_utils.pas (cc.m68k
  0x07D9A4..0x07E7B4).  Headings from the frames and call sites
  (tools/cc_params.py); search_point and search_walk are nested in
  il_utils_$search_tree_for_node, which is why its own frame shows only
  its first parameter (its callers push three).

  Not known from the original: every parameter name and most types. }

{ TODO(pascal) il_utils headings are read off the frames only

  Types and modes are the conservative reading (univ_ptr for pointers,
  the width's integer for values, by value); refine them when il_utils.pas and
  its callers are translated. }

{ IL_UTL_$CLASSIFY_VARIABLE - a word result.  0x07D9A4. }
function il_utl_$classify_variable(
    p: univ_ptr;
    q: univ_ptr;
    v: integer32;
    r: univ_ptr): integer; options(val_param); extern;

{ IL_UTL_$COUNT_VARS - 0x07DBA2. }
function il_utl_$count_vars(
    p: univ_ptr): integer; options(val_param); extern;

{ IL_UTILS_$ADJUST_UC, ADJUST_UC - add delta to the use counts of a tree
  (62 and 50 call sites).  0x07DCF8, 0x07E018. }
procedure il_utils_$adjust_uc(
    p: univ_ptr;
    delta: integer); options(val_param); extern;

procedure adjust_uc(
    p: univ_ptr;
    delta: integer); options(val_param); extern;

procedure il_utils_$set_uc_walk_spine(
    p: univ_ptr;
    q: univ_ptr); options(val_param); extern;

procedure il_utils_$do_substitution(
    p: univ_ptr;
    v: integer32;
    q: univ_ptr); options(val_param); extern;

function il_utils_$tree_node_operand_is_spine(
    a: integer;
    b: integer): boolean; options(val_param); extern;

function il_utils_$is_strength_reduction_temp(
    p: univ_ptr): boolean; options(val_param); extern;

function il_utils_$search_tree_for_node(
    tree: univ_ptr;
    node: univ_ptr;
    flag: boolean): univ_ptr; options(val_param); extern;

function il_utils_$source_generated_top_level_node(
    p: univ_ptr): univ_ptr; options(val_param); extern;

{ IL_UTILS_$SRC_LINE - a node's source line (a word).  0x07E4CC. }
function il_utils_$src_line(
    p: univ_ptr): integer; options(val_param); extern;

{ IL_UTILS_$TREES_EQUIVALENT - a word result (callers compare it with
  1).  0x07E578. }
function il_utils_$trees_equivalent(
    p: univ_ptr;
    q: univ_ptr): integer; options(val_param); extern;
