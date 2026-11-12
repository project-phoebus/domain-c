{ lang2/source/be_com/iv.ins.pas - be_com iv.pas's insert (cc.a88k only): opened by iv and oli, after the
  opcode enumeration (oli before utils.ins.pas, iv before
  opcodes/instr_size.init and utils.ins.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binary
  cc.a88k.  For now only the headings of iv.pas's global routines that oli calls, read off the frames and
  the callers' pushes (a pointer univ_ptr, a longword integer32, a word
  integer, a byte boolean; p1..pn); the units' translators add the
  types and cells the units share (docs/backend-plan.md).

  Not known from the original: every parameter name. }

{ TODO(pascal) iv.ins.pas: the shared types and cells }

{ iv.pas (cc.a88k). }

{ IV_UTILS_$DELETE_EXPRESSION - 0x239110, 0x5C bytes; called from oli.
  Frame 8:a. }
procedure iv_utils_$delete_expression(
    p1: univ_ptr); options(val_param); extern;

{ IV_UTILS_$CREATE_ADD_EXPRESSION - 0x239508, 0x3A bytes; called from oli.
  Frame 8:al; 12:al; 16:al.  Result: read (callers: A035). }
function iv_utils_$create_add_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$CREATE_SUB_EXPRESSION - 0x239542, 0x3A bytes; called from oli.
  Frame 8:al; 12:al; 16:a.  Result: read (callers: A012). }
function iv_utils_$create_sub_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$CREATE_MUL_EXPRESSION - 0x23957C, 0x3A bytes; called from oli.
  Frame 8:al; 12:al; 16:a.  Result: read (callers: A028). }
function iv_utils_$create_mul_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$CREATE_VALUE_EXPRESSION - 0x2395E2, 0x30 bytes; called from
  oli.  Frame 8:al.  Result: read (callers: A024). }
function iv_utils_$create_value_expression(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$CREATE_OPERAND_EXPRESSION - 0x239642, 0x3E bytes; called from
  oli.  Frame 8:a.  Result: read (callers: A02). }
function iv_utils_$create_operand_expression(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$CANONICALIZE_EXPRESSION - 0x2396DA, 0x74 bytes; called from
  oli.  Frame 8:al.  Result: A0 (callers: A056). }
function iv_utils_$canonicalize_expression(
    p1: univ_ptr): univ_ptr; options(val_param); extern;

{ IV_UTILS_$DUPLICATE_EXPRESSION - 0x23A73C, 0xC0 bytes; called from oli.
  Frame 8:al; 12:alw; 14:w; 16:w.  Result: A0 (callers: A046). }
function iv_utils_$duplicate_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: integer;
    p4: integer): univ_ptr; options(val_param); extern;

{ IV_UTILS_$ELABORATE_EXPRESSION - 0x23B07E, 0xA6 bytes; called from oli.
  Frame 8:al; 12:w; 14:w; 16:w.  Result: A0 (callers: A05). }
function iv_utils_$elaborate_expression(
    p1: univ_ptr;
    p2: integer;
    p3: integer;
    p4: integer): univ_ptr; options(val_param); extern;

{ IV_UTILS_$LIVE_RANGE_FROM_ELABORATED_EXPRESSION - 0x23B8EE, 0x2C0 bytes;
  called from oli.  Frame 8:a; 12:al; 16:a; 20:a; 24:a; 28:a. }
procedure iv_utils_$live_range_from_elaborated_expression(
    p1: univ_ptr;
    p2: univ_ptr;
    p3: univ_ptr;
    p4: univ_ptr;
    p5: univ_ptr;
    p6: univ_ptr); options(val_param); extern;

{ IV_UTILS_$COMPARE_ADDRESS_EXPRESSIONS - 0x23D5A0, 0x6C bytes; called
  from oli.  Frame 8:al; 12:al.  Result: D0 (callers: D0b2). }
function iv_utils_$compare_address_expressions(
    p1: univ_ptr;
    p2: univ_ptr): boolean; options(val_param); extern;
