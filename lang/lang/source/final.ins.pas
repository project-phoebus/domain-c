{ lang/lang/source/final.ins.pas - the insert of the m68k back end's
  final phase (lang/lang/source/final.pas, cc.m68k only).

  No Apollo copy survives.  A stub: lang/lang/source/celpkg.pas opens it
  and uses nothing from it; cg_top calls peepholer and jmp_br_setup
  (jmp_br_resolve.pas, whose units open this insert).

  Not known from the original: everything about its contents.
}

{ TODO(pascal) final.ins.pas is a stub

  Declarations are added as final.pas and its callers are translated. }

{ PEEPHOLER - the peephole pass over a routine's code cells, from first
  (the cell after the one that ended the previous routine) in section
  sect.  final 0x1120A0: 8 a pointer, 12 a longword (cg_top's codegen,
  after the last pass). }
procedure peepholer(
    sect: univ_ptr;
    first: univ_ptr); options(val_param); extern;

{ JMP_BR_RESOLVE - the branches of every section given their sizes
  (jmp_br_resolve.pas 0x0BB57A: no parameters; finaldriver's). }
procedure jmp_br_resolve; extern;

{ JMP_BR_SETUP - the branches of a routine's code cells (from first, in
  section sect) set up for their sizes.  jmp_br_resolve 0x0BA8A6: two
  pointers (cg_top's codegen). }
procedure jmp_br_setup(
    psect: univ_ptr;
    first: univ_ptr); options(val_param); extern;

{ The routines of final.pas that jmp_br_resolve.pas calls, read off
  final's frames (tools/cc_params.py) and jmp_br_resolve's call sites.
  Not known from the original: the parameter names; what detach,
  moverefcell and reversecond return (some callers read D0 or A0). }

{ DETACH - code cell c taken off its list.  0x108A8C: a pointer by
  value. }
procedure detach(
    c: codegen_$cell_ptr_t); options(val_param); extern;

{ NXTCC, NXTLCC - the code cell after c (nxtlcc: the next label or code
  cell).  0x108BEE, 0x108C88: a pointer by value, the cell in A0. }
function nxtcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

function nxtlcc(
    c: codegen_$cell_ptr_t): codegen_$cell_ptr_t; options(val_param); extern;

{ MAKEJUMP - c made a jump to target.  0x10B22E: two by value, a cell
  in A0. }
function makejump(
    c: codegen_$cell_ptr_t;
    target: codegen_$cell_ptr_t): codegen_$cell_ptr_t;
    options(val_param); extern;

{ MOVEREFCELL - reference cell ref moved to label lab's list.
  0x10B466: two by value. }
procedure moverefcell(
    ref: codegen_$cell_ptr_t;
    lab: codegen_$cell_ptr_t); options(val_param); extern;

{ REVERSECOND - conditional branch c's condition reversed.  0x10B890: a
  pointer by value. }
procedure reversecond(
    c: codegen_$cell_ptr_t); options(val_param); extern;

{ The routines of final.pas that instr_reorder.pas calls. }

{ FINAL_$IS_UNMOVEABLE_FP_INST - whether floating-point cell c must stay
  where it is.  0x10905A: a pointer by value, a boolean in D0. }
function final_$is_unmoveable_fp_inst(
    c: codegen_$cell_ptr_t): boolean; options(val_param); extern;

{ SAMEADDR - whether descriptors a and b address the same place.
  0x109304: both by address, a boolean in D0. }
function sameaddr(
    in a: codegen_$ads_t;
    in b: codegen_$ads_t): boolean; extern;

{ INVOLVES - whether descriptor a uses register reg.  0x109548: a by
  address, reg a word by value, a boolean in D0. }
function involves(
    in a: codegen_$ads_t;
    reg: integer): boolean; options(val_param); extern;

{ TESTCC - whether the condition codes cell c sets (of mask) are
  tested before they are set again.  0x10AFD2: a pointer and a word by
  value, a boolean in D0. }
function testcc(
    c: codegen_$cell_ptr_t;
    mask: integer): boolean; options(val_param); extern;

{ INSTR_REORDER - the instructions of section sect from first reordered
  to separate stores and loads of a register (instr_reorder.pas
  0x0BA754): two pointers by value (final's caller). }
procedure instr_reorder(
    first: univ_ptr;
    psect: univ_ptr); options(val_param); extern;

{ DOBANSHEEFPX - the 68881 cells from first up to last rewritten for
  the FPX (banshee.pas 0x0EE84C): two pointers by value (final's
  peepholer passes its first cell and the section's +20). }
procedure dobansheefpx(
    first: codegen_$cell_ptr_t;
    last: codegen_$cell_ptr_t); options(val_param); extern;

{ opinfo.pas's tables (cc.m68k only; data, reached absolutely), under
  the names the unit's .blocks record gives them, in address order.
  Each per-instruction table has an entry for each machine instruction
  0..506 (a code cell's +48, codegen_$cell_t's op); opinfo.pas defines
  them (docs/questions.md 148).  Readers: insind emit (fnl_slct);
  cc_table and class_table final (cc_change, pcondjmp, puncondjmp,
  assert_n_bit_is_modified, deltest); optohex outbin (genfpinst,
  assemble, wr_instr); oprw_table final (reg_mod, deltest) and
  instr_reorder (store_to_memory); opcontext final (final_$sizeof,
  fpx_instruction, deltest, opttest) and banshee (dobansheefpx); opname
  outbin (dbcod, wr_instr).

  Not known from the original: which insert declared them (this one is
  opened by opinfo, last, and by every reader); the types (written
  with the widths of the accesses), the entry's fields and the list
  type's bound (a list ends at the entry whose flags have element 5). }

type
  { An instruction of a generic operation, 12 bytes: the restriction
    codes of the destination and the source (emit's chk_op_restr) and
    of the size (chk_sz_restr), the code cell's kind and the machine
    instruction (the cell's +48), and flags: elements 0..4 the cpu
    features the instruction needs (fnl_slct's missing set), 5 the
    list's last entry. }
  opinfo_entry_t = record
    dst: integer;                       { +0 }
    src: integer;                       { +2 }
    sz: integer;                        { +4 }
    kind: integer;                      { +6 }
    op: integer;                        { +8: the instruction }
    flags: set of 0..15;                { +10 }
  end;
  opinfo_list_t = array [0..63] of opinfo_entry_t;
  opinfo_list_ptr_t = ^opinfo_list_t;

var
  { 0x2CE8D8: generic operation k's (0..77) list of instructions (nil
    for 32 and 33). }
  insind: extern array [0..77] of opinfo_list_ptr_t;
  { 0x2CF4D8: each condition-code class's effect on the codes 0..5
    (0..4; 2 changed). }
  cc_table: extern array [0..22] of array [0..5] of integer;
  { 0x2CF5EC: each instruction's condition-code class. }
  class_table: extern array [0..506] of integer;
  { 0x2CF9E2: each instruction's operation word (unsigned: outbin's
    wr_instr zero-extends it, `clr.l' then `move.w', before adding). }
  optohex: extern packed array [0..506] of 0..16#FFFF;
  { 0x2CFDD8: each instruction's operands' access: R read, W written,
    - none. }
  oprw_table: extern array [0..506] of packed array [1..2] of char;
  { 0x2D01CE: each instruction's operands' sizes: B W L byte, word,
    long, F D X single, double, extended, Q a quick constant, S, A an
    address, - none. }
  opcontext: extern array [0..506] of packed array [1..2] of char;
  { 0x2D05C4: each instruction's mnemonic, blank-padded. }
  opname: extern array [0..506] of packed array [1..9] of char;
