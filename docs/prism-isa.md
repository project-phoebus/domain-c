# The PRISM (a88k, DN10000) machine language as cc.a88k shows it

What the back end's output units (lst, bin, asm) reveal about the
PRISM instruction set: the opcode tables, the assembler syntax the
listings use, and (from bin) the binary encoding.  Each item cites the
unit and address it was read from; nothing here comes from outside the
image.  Translator PB, 2026-11-11; extended unit by unit (asm:
translator PB2).

## The opcode tables

- 384 opcodes (`opcode_enumeration.ins.pas`); 0..211 are PRISM opcodes
  and the back end's pseudo-instructions (nop at 192 .. adj_move at
  211), 212..383 HP Precision Architecture ones the PRISM back end does
  not make.
- `instruction_attributes` (0x2B8C3C, 20 bytes an opcode): two words,
  then one longword per operand (operands 1..4): the operand's form
  (of$t: which registers or immediates it accepts, e.g.
  `ip_reg_or_s_immed16`, `0_mod_4_s_immed16`, `u_immed5`), its number
  (1..4, always so in the table), and two bytes (operand 1's second is
  the opcode's class, +7: load, store, branch, ...).  +11 bits 2..0 the
  number of operands the listing shows; +19 bits 2..0 the log2 of a
  memory access's size.
- `instruction_assembly` (0x2B9CCC, 44 bytes an opcode): +0 and +4 two
  longwords (the encoding templates; see bin), +8 flags (bit 5 the
  branch takes a squash suffix, bit 4 no instruction word is shown,
  bits 3..0 the -PRASM operator's length), +9 (bits 7..4 the
  mnemonic's length, bits 3..1 which operands name half of a double),
  +10 the -PRASM layout (0..26), +11 the -PRASM operator (8
  characters: "BGT", "-", "|", ...), +19 the classic mnemonic (16
  characters: "BNEVER", "ADD", "LOAD", "STORE", "EXTEND", "COPY.FS";
  move is listed as "ADD", a compare with an immediate too), +36 a
  word per operand (bits 2..1 the display format: 0 decimal, 2
  hexadecimal).
- `instruction_mnemonic` (0x2B7A3C, 12 characters) and
  `instruction_mnemonic_length` (0x2B773C): the opcode names the
  classic listing prints.

## Registers

- 32 integer registers; the classic listing writes "Rn", -PRASM ".n"
  (lst_$add_register_name 0x24F370).  Register 31 reads as zero: the
  -PRASM forms of cmp, tst and nop name it (",.31", ".31,.31,.31",
  lst_$display_code_cell 0x2515B0; "[.31]" in the enable/disable
  layout), and zzzzz lists an instruction whose result is register 31
  as a TST or CMP.  Register 30 of the "like" kind prints as "PC".
- 64 floating registers as singles, paired as doubles: classic "Sn" and
  "Dn", -PRASM ".FSn" and ".FDn"; ".H" after a single that is half of
  a pair when the opcode says so.  A routine's entry saves floating
  registers by pairs of bits (1 the even single, 2 the odd one, 3 the
  double; lst_$procedure_entry 0x24F0E0).
- An integer register operand can carry a scale (+2 bits 5..4 of the
  operand): `*2`, `*4`, `*8` (scaled index).
- Condition codes: an instruction may set the integer condition codes
  (".CC") or the floating ones (".FCC").

## Memory operands

- Loads and stores have a size suffix: .B (byte), .S (short, 16 bits),
  .L (long), .FS (single), .FD (double), .Q (load_pair: a quadword);
  the signed forms loadse/loadso have no -PRASM spelling (a bug check
  in lst_$prasm_address_mode_suffix 0x24FEAE).
- A qualifier: .LOCK, .UNLOCK, .PHYS (physical address); the classic
  listing writes ".L", ".U", ".P".
- Addressing: base register plus displacement, with no modification,
  post-modification or pre-modification of the base (the code cell's
  +3 bits 7..6): -PRASM "[base,disp]", "[base++,disp]", "[++base,disp]"
  (`--' for a negative displacement).  A displacement equal to the
  access size (or 0) under modification is implied and not printed.
- Field instructions (insert, extract) carry a width (the cell's +3):
  "<offset,width>".

## Branches

- Branches have a squash (annul) mode for their delay slot (+3 bits
  7..6 of a branch's cell): .SN (never), .ST (if taken), .SF (if it
  falls through), .SA (always); "BNEVER.SA" opens the enable/disable
  layout.
- Branch targets are labels, a register ("[Rn]") or numbered local
  labels ("n$").
- An instruction can continue on the next code cell (the cell's +2 bit
  6; ", ..." in -PRASM, " R" classic): long immediates and the like.
- The classic listing shows, for each instruction, a cycle column (the
  cell's +2 bits 3..0), the location and the 32-bit instruction word.

## The binary (bin.pas)

- Every instruction is one 32-bit word, already in the code cell (+12)
  when bin runs: bin does not encode; it writes the words in order
  (longword-aligned, a bug check otherwise) and pads each section to 8
  bytes.  The encoding templates are instruction_assembly's +0/+4
  (asm.pas fills the operands in).
- Displacements known only at output time are added into the word's
  low bits: 18 bits for the branch-like classes (branch, call,
  fp_branch, jump, immediate, seq, trap, svc, return: the class mask
  0x1104366), 16 bits for the others (bin_$emit_compilation_pure_text
  0x2248CA).  Operand forms that require alignment (0_mod_2, 0_mod_4,
  0_mod_8, 0_mod_16 `s_immed16`) are checked against the section
  operand_forms_mask (0x2B6DA0: 1, 3, 7, 15).
  - A literal pool reference is a byte displacement from the
    instruction's own address, signed 16 bits.
  - A call to a routine is a word displacement (bytes / 4) from the
    instruction, signed 18 bits (+-131071 words, "illegal 20 bit
    displacement", i.e. +-512 KB); across sections the target
    section's offset is added.
  - Argument block and stack frame references are the symbol's
    displacement plus the operand's value, signed 16 bits.
- Floating instructions of the classes fp_double, immediate and
  fp_single take two words: a cell that continues (+2 bit 6) is
  written with a NOP word in front (asm's NOP word with bit 31
  flipped), any other continued cell with an FNOP word after it; such
  instructions count 8 bytes in the line table.  An fp_control
  instruction is followed by a second word, its own with the high bits
  replaced: (word & 0xFFF) | 0xE40000.
- Exception stubs (the trap class): after the section's code, either
  two words and a literal (LOADL R4 from the pool at PC+8, the literal
  0x00120004, then SVC: asm's SVC word less bits 9..8, plus 0x380) or,
  with -NEW_UNWIND, one SVC2 word (plus 0x2C0 and the trap number); the
  trap instruction itself is patched with the word displacement to its
  stub.
- The return address register is register 22 (bin_$unwind_bits); a
  frame register above 23 is noted in the unwind scope; a pushed frame
  of at most 128 bytes uses an ECB.

## The encoding (asm.pas; confirmed by its translation)

asm_$process_routine (0x21F6D4, 0x19A2 bytes; lang2/source/be_com/asm.pas,
translator PB2) builds each instruction's word (stored at the
instruction's +24, which zzzzz copies to the code cell's +12) as the OR
of a template and the operands' fields.  Its encoder is
0x2205A8..0x220FAA; bit 31 is the most significant.  The word is a
local packed record that the code fills field by field (byte, word and
longword `and'/`or' of the frame's longword at -300): the fields below
are its views (asm.pas's asm_word_t).  **Confirmed** marks what PB
read before the translation and the translation agrees with;
**corrected** and **new** what it changed or added.

- **Confirmed.** The template is instruction_assembly's +0 for the
  register form and +4 for the immediate form: an operand that is not
  a register in a field of kind 4 or 5 switches to +4 (0x220742).  The
  templates of every opcode are in the table at the end.
- **New.** Before the operands: an IPCCNOP is encoded as a NOP; TSTS
  and TSTD as MOVES and MOVED with operand 1 copied to operand 2; a
  conditional trap (trap_gt .. trap_flt, trapd_gt .. trapd_flt, class
  27) as the conditional branch of the same condition (opcode - 20;
  the double-register trapd_ forms - 40), +3 bit 7 set, its operand 3
  (5 for a register pair) moved to operand 1 as kind spare_3 (the
  exception stub, bin's).  Labels and tables (classes 19, 25) have no
  word.  Pass 1 has already turned WIDENB/WIDENW into TSTB/TSTW
  (EXTEND 7 / 15).
- **New.** "5op": an opcode with instruction_assembly +8 bit 4 (the
  five-operand multiply-and-add forms adds5, subs5, truncsi5, addd5,
  subd5, truncdi5: classic "mul_ADD.FS" ...) does not clear the word:
  its word keeps the fields of the instruction before it (the MUL) and
  adds its own (field kinds 11, 12, 13).  (PB named this bit no_hex:
  lst shows no word for such a cell.)
- **Corrected.** Each operand the listing shows (instruction_attributes
  +11 bits 2..0) has a field kind, instruction_assembly's word for it
  (+36 + 2(k-1)) bits 7..3, 0..17 (the jump table at 0x2206BE).
  Register operands are turned into the register first (below); `reg'
  is that register, `v' the operand's value:

  | kind | field |
  |------|-------|
  | 0 | the integer register in bits 4..0 (PB read "none"; e.g. EXTEND's, the shifts' source, NEG's operand 1, RETURN's register) |
  | 1 | integer register in bits 20..16 |
  | 2 | integer register in bits 25..21 |
  | 3 | a register pair (its number halved) in bits 25..21 |
  | 4, 5 | an integer register (kinds ip_reg, ip_reg_physical, ip_reg_like, case_jump_base) in bits 4..0; otherwise the immediate form, the value by the operand's form (below) |
  | 6 | a single (number times 4) or a 13-bit unsigned value (MFPR/MTPR's special register) in bits 12..0 |
  | 7 | a register in bits 20..16, or a 5-bit immediate there with bit 8 set |
  | 8 | a register in bits 25..21, or a 5-bit immediate there with bit 8 set |
  | 9 | a 4-bit immediate in bits 9..6 (SVC's) |
  | 10 | a single held in a double register: the double's number in bits 25..21; an odd single turns STORES into STORESO and the loads into LOADSO (their templates, register or immediate form) |
  | 11 | a floating register (0..63) in bits 23..18 |
  | 12 | a floating register in bits 29..24 |
  | 13 | a floating register's even part in bits 29..24, its low bit in bit 0 |
  | 14 | a floating register in bits 11..6 and again in bits 5..0 |
  | 15 | a floating register in bits 5..0 (DIVI wants an odd one: "even divisor in DIVI") |
  | 16 | a floating register in bits 11..6 |
  | 17 | a floating register in bits 17..12 |

  **Confirmed:** the integer registers take 5-bit fields and the
  floating registers 6-bit ones (64 singles; a double an even/odd
  pair).
- **Confirmed.** An integer register's scale (the operand's +2 bits
  5..4: x1, x2, x4, x8) goes into bits 6..5.
- **Corrected.** Register operands get their physical register from
  their live range's +2 byte: the live range is the segment's (+8) +48,
  or, for an operand without a segment, lir.pas's table of physical
  live ranges by register number (lir +0x4090, 0x48B210; PB read
  lir_main's).  The operand's +0 is overwritten with the register, its
  +4 with the live range's +20 and its +8 with the live range: after
  asm an operand's +0 is the register (zzzzz's test against 31;
  docs/questions.md 153).
- Immediates of kinds 4 and 5, by the operand's form (of$t):
  - **Confirmed.** A branch target (forms ip_reg_or_long_pc_disp,
    ip_reg_or_basic_block, operand kind flow_graph_edge): the word
    displacement to the target block's first instruction, 18 bits in
    bits 17..0 (a target block that was forwarded is a bug check); a
    call's (kind displacement_routine) and a trap's stub (kind
    spare_3) are left to bin.
  - **Confirmed.** ip_compare_a_operand: the value negated, bits 15..0
    (a compare with an immediate is CMP's immediate form, 0x1FE00000,
    an ADD into R31 of the negated value: lst's "ADD").
  - **Confirmed.** The s_immed8 forms (ip_reg_scaled_or_s_immed8,
    ip_reg_or_s_immed8): bits 6..0 and the sign in bit 15.
  - **New.** ip_reg_or_s_immed11 cannot be encoded ("unexpected
    operand form"), short_pc_disp is "not yet supported".
  - **Confirmed.** The 16-bit immediates and displacements (s_immed16,
    the scaled_or_s_immed16 and 0_mod_n forms, u_immed5, u_immed4):
    bits 15..0, the operand's register byte cleared; for a load or
    store that modifies its base or has a qualifier (+3 bits 7..6 or
    5..4 not 0) an 8-bit signed displacement (bits 6..0, sign in bit
    15) with the register form's template and bit 27 set (a bug check
    beyond -128..127 and for the displacement kinds); argument block,
    stack frame and literal pool displacements are left 0 for bin (the
    operand's register byte gets bit 7 when the next operand's value is
    asm_658, except in an ADD); XSB displacements are biased by
    lir_main +0xC40 and must be at most 32767 (the operand becomes an
    immediate).  **New:** the value must be a multiple of the form's
    alignment (operand_forms_mask), and a nonzero displacement from
    asm_658 (the stack frame's base, most likely) plus the access's
    size (instruction_attributes +19 bits 2..0, log2) must stay
    within the register save area (lir_main +0xC6C) when the frame is
    pushed (rtn +226 bit 0), else within the argument block (rtn
    +176).
  - **Confirmed.** ip_reg_or_u_i16_or_hi_i16 and the and/bic form: a
    value whose high half is zero goes in bits 15..0; one whose low
    half is zero puts its high half there with bit 27 set (a "high"
    immediate); otherwise, for the and/bic form only, its complement
    is tried, AND (84) becoming BIC (214, a PA opcode number) and back
    (the bug check calls the rest "i860 logical").  **New:**
    ip_reg_or_s_u_hi_immed16: a negative value of 16 bits (high half
    all ones) is encoded with ADD's immediate template.
- After the operands (one of, in this order):
  - **Confirmed.** A branch's squash mode (+3 bits 7..6) goes into
    bits 19..18 as (57 >> 2 * mode) & 3: .SN 1, .ST 2, .SF 3, .SA 0.
  - **Confirmed.** An insert's or extract's width less one, bits 13..9
    (opcodes with instruction_attributes +14 bit 1).
  - **Confirmed.** A load's or store's addressing mode (am$t) in bits
    10..9 and its qualifier (lsq$t) in bits 8..7, register form only.
  - **Corrected.** load_pair's offset (+3, signed): its bits 5..0 in
    bits 10..5, its bit 6 in bit 14 and its sign in bit 15.
  - **Confirmed.** A SYNCH takes a byte of the routine's record (+116's
    +2) in bits 20..16.
- **Confirmed.** Setting the floating condition codes (the
  instruction's +0 bit 3) is bit 24; setting the integer ones (+0 bit
  4) bit 26 for an immediate compare-form operand 1 (forms 3 and 10)
  in the immediate form, else bit 14.
- **Confirmed.** Bit 31 marks an instruction that continues into the
  next word: the instruction's +2 bit 7 (pass 1 sets it when a
  floating instruction, or in an atomic block a load, is grouped after
  it: "companion"), or +2 bit 6 (a NOP word before it) outside the
  two-word floating classes.
- **New.** Case tables (asm_$build_dispatch_table, 0x21F362): the
  table's entries become displacements from the dispatch; when the
  dispatch is an ADD and they fit 0..32767, the LOADL x4 that read the
  entry becomes a LOADBU x1 (TABLEB, displacements up to 255) or
  LOADWU x2 (TABLEW), the encoded word's template exchanged (the
  scale field 6..5 of the templates set to match).

## The layout (asm.pas pass 1; new)

- Every instruction is 4 bytes; a floating instruction that continues
  (+2 bit 6, classes fp_double, immediate, fp_single) or the state
  table's bit 5 make 8.  Entries, PMOVEs, labels and join birthpoints
  take a location but no space.
- The pipeline's rules are a state machine (asm's data +0x470: 8
  states by 10 instruction kinds, each entry a flags word and the next
  state).  The kinds: 0 other (fp_control, or an instruction followed
  in its group by a floating one), 1/2 integer (2 with +0 bit 5), 3 a
  two-word floating class, 4/5 and 7/8 calls by the squash mode's high
  bit (.SF/.SA vs .SN/.ST), 6/9 calls followed by a floating one.  The
  flags insert NOP words or NOP instructions before or after (the
  delay slot of a call that squashes; "FP operation scheduled in
  shadow of CALL.SA" is a bug check).
- The routine's last instruction, when branch-like, gets a NOP after
  it (its delay slot).  JUMP, TRAP and RETURN squash .SN or .SA only
  (bit 6 of the mode copied to bit 7).
- The literal pool is reached by 16-bit byte displacements from the
  instruction (target_properties +0x5C, 32767): asm collects each
  routine's literals, and dumps the pool after an unconditional
  transfer (or with a JUMP around it) where the pool would otherwise
  fall out of reach (a margin of 40 bytes; at the end of a block when
  15/16 of the range is used), preferring blocks outside loops (the
  candidates by loop depth), splitting a block when it must.  Entries
  are shared by object and size, aligned by size (1, 2, 4, 8),
  largest first.
- With target_properties +0xBE set (the other CPU revisions' form: lst
  prints such a displacement as a number) the routine's literals go
  in one pool before its second block, and LOADL immediates of
  literals get a pool of their own.

## Registers and allocation as the dumps show them (dmp.pas; new)

Translator PB3 (dmp.pas, the phases' dumps, 0x22F188..0x2348D0).

- A live range's register is its +2 byte once one is assigned (+3
  bit 7); rrp's ip_reg (bit 15) and fp_reg (bit 14) say which file.
  Without either, register 30 is the integer condition codes and 31
  the floating ones: the condition codes are allocated as registers
  ("icc", "fcc"; print_register_if_assigned 0x2306D0, ", IP CONDITION
  CODES").  So in a live range's numbering R30/R31 double as the two
  condition code registers; in the encoding R31 reads as zero (above).
- dmp names three registers specially (0x232010): the one
  target_properties +0x18 holds ("pc_", the PC-like register lst
  prints as "PC"), the stack frame's live range (the conventions'
  record, at_backend_4fc, +116: "sf_"), and otherwise "rN"/"fN".
- Register sets: integer registers a longword (bit k is Rk); floating
  registers 64 bits, as two longwords with 32..63 first (the 64
  singles; a double an even/odd pair).  Each routine has, from its
  calling conventions (the routine's IL node +332..+364), the floating
  and integer registers to preserve, not to preserve and not to modify;
  the registers written (rtn +148, +152) and, from RA, saved (+160,
  +164: lst's pe_info_t, the entry mask).  Each block has its written
  registers (+122, +126) and the allocator's counts (+0..+7): live on
  entry and exit, the most live at once, and those that pass through,
  for each file.  A call or SVC carries after its operands the sets it
  clobbers (floating +44 + 12n, integer +52 + 12n).
- The frame: rtn +208 the stack frame's register ("SF = Rn"); +222 and
  +224 two registers saved at [04,SF] and [12,SF] (31 or -1 for none;
  the flags "save rpc" and "save sl", +226 bits 6 and 7, the return
  address and the static link most likely); +218/+220 the registers'
  save area ("regs saved from [n,SF] to [m,SF]"); from ASM the
  prologue's offsets: from the ECB (+214), with a different DB (+212),
  after the stack is pushed (+216), after all registers are saved
  (+210); +176 the supplied argument block's end.  Flags at +226..+228:
  contains call, needs frame, needs_db, internal db, db never
  referenced, quad aligned, no return block, asynchronous return,
  shares frame with lexical parent, no_memory_read/_write,
  no_arg_block_read/_write, no_pointer_dereference, no_fp_cc_write,
  no_ip_cc_write, common/static/uplevel-dynamic storage untouched.
- The allocator (RA, during its dumps): a live range's conflicts are
  records on both live ranges' lists (+44; the next pointers tagged in
  their two low bits); +56 its remaining conflicts; rrp's life_mark
  element means "never spill", +3 bit 0 "spill victim"; +80 the
  conflicting register set, +64 the preferenced one; the allocation
  order is chained at +52 ("CHROMATIC NUMBER", "ALLOCATION ORDER AND
  CONFLICTS").  An instruction's +28..+31 are four counts during RA.
- The scheduler: an instruction's +2 bits 3..0 (signed) are its stalls
  from the SCHED phase (lst's cycle column).  From ASM, +2 bit 7 marks
  an instruction with a floating companion and bit 6 one paired with
  a companion NOP.
- Branches and calls (opcodes with instruction_assembly +8 bit 5): +3
  bit 7 squashes the delay slot on sequential flow (s_seq) and bit 6
  on transfer (s_xfer): dmp's ".sn", ".st", ".ss", ".sa" are lst's
  .SN, .ST, .SF, .SA; +3 bit 5 possible_nonlocal_return, bit 4
  no_return, bit 3 final_call, bits 1..0 a function key (1 cos, 2 sin,
  3 cos and sin together: "cssn").  Opcodes with instruction_attributes
  +14 bit 0 that set the condition codes take a suffix by +3 bits 5..4:
  .cc, .ucc, .scc, .zcc.  Loads and stores: +3 bits 7..6 the
  modification (" []++" post, " ++[]" pre), bits 5..4 the qualifier
  (lock, unlock, physical).  An instruction's +41 counts the floating
  registers it writes.
- Each phase's place (at_backend_phase, backend.ins.pas's phase$
  constants): ISC 0, FGA, MMT, DFA, KONST, HAL, TRANS, LIFE, COM, IV,
  OLI, XTP, SCHED 12, RA 13, POST, JBR, ASM 16, DBG_LIFE, ZZZZZ, BIN 19;
  so the scheduler runs before register allocation, and again (as
  pass 1 of ASM's pipeline rules) after it.

## The opcodes' encodings (instruction_assembly; new)

From the section's data (asm.pas includes it as instr_assembly.init;
docs/questions.md 161): for each PRISM opcode, the classic mnemonic,
the -PRASM operator, the register form's (+0) and the immediate form's
(+4) templates, and the field kind and operand form of each operand
the listing shows (instruction_attributes +11).  Opcodes 0 and
212..383 have no entry.  Some readings: the integer ALU's register
form is 0x1000xxxx with the operation in bits 14..11 (ADD 0x2000, SUB
0x2800, AND 0x0800, OR 0x0000, XOR 0x1000) and its immediate forms
0x14000000/0x18000000; MOVE is ADD with R31 (`101F2000'), CMP and TST
SUB into R31, NOP `OR R31,R31,R31' (0x13FF001F); the conditional
branches 0x24..0x27 (register) / 0x2C..0x2F (displacement) with the
condition in bits 25..20 (the conditional traps share them), the floating branches and CALL 0x20/0x28; loads 0x34 (register
index) and 0x40 .. 0x74 (displacement), stores 0x30 and 0x48 .. 0x78;
the floating operations 0x30..0x3E; the floating control 0xFC.

| # | opcode | classic | -PRASM | +0 (register form) | +4 (immediate form) | operands: field kind/form |
|---|--------|---------|--------|------|------|------|
| 1 | bnever | bnever | BNEVER | 00000000 | 00000000 | 4/ip_reg_or_basic_block (squash) |
| 2 | bnl2v | BNL | BNL2V | 27300000 | 2F300000 | 4/ip_reg_or_basic_block (squash) |
| 3 | bl2v | BL | BL2V | 27100000 | 2F100000 | 4/ip_reg_or_basic_block (squash) |
| 4 | bnl2 | BNL | BNL2 | 27700000 | 2F700000 | 4/ip_reg_or_basic_block (squash) |
| 5 | bl2 | BL | BL2 | 27500000 | 2F500000 | 4/ip_reg_or_basic_block (squash) |
| 6 | bnz3 | BNZ | BNZ3 | 27B00000 | 2FB00000 | 4/ip_reg_or_basic_block (squash) |
| 7 | bz3 | BZ | BZ3 | 27900000 | 2F900000 | 4/ip_reg_or_basic_block (squash) |
| 8 | bgt | BGT | BGT | 24500000 | 2C500000 | 4/ip_reg_or_basic_block (squash) |
| 9 | ble | BLE | BLE | 24700000 | 2C700000 | 4/ip_reg_or_basic_block (squash) |
| 10 | bge | BGE | BGE | 24900000 | 2C900000 | 4/ip_reg_or_basic_block (squash) |
| 11 | blt | BLT | BLT | 24B00000 | 2CB00000 | 4/ip_reg_or_basic_block (squash) |
| 12 | bhi | BHI | BHI | 24D00000 | 2CD00000 | 4/ip_reg_or_basic_block (squash) |
| 13 | bls | BLS | BLS | 24F00000 | 2CF00000 | 4/ip_reg_or_basic_block (squash) |
| 14 | blo | BLO | BLO | 25100000 | 2D100000 | 4/ip_reg_or_basic_block (squash) |
| 15 | bhs | BHS | BHS | 25300000 | 2D300000 | 4/ip_reg_or_basic_block (squash) |
| 16 | bnn | BNN | BNN | 25500000 | 2D500000 | 4/ip_reg_or_basic_block (squash) |
| 17 | bn | BN | BN | 25700000 | 2D700000 | 4/ip_reg_or_basic_block (squash) |
| 18 | bne | BNE | BNE | 25900000 | 2D900000 | 4/ip_reg_or_basic_block (squash) |
| 19 | beq | BEQ | BEQ | 25B00000 | 2DB00000 | 4/ip_reg_or_basic_block (squash) |
| 20 | bnv | BNV | BNV | 25D00000 | 2DD00000 | 4/ip_reg_or_basic_block (squash) |
| 21 | bv | BV | BV | 25F00000 | 2DF00000 | 4/ip_reg_or_basic_block (squash) |
| 22 | fbeq | BFEQ | BFEQ | 20500000 | 28500000 | 4/ip_reg_or_basic_block (squash) |
| 23 | fbne | BFNE | BFNE | 20700000 | 28700000 | 4/ip_reg_or_basic_block (squash) |
| 24 | fbgt | BFOGT | BFOGT | 20900000 | 28900000 | 4/ip_reg_or_basic_block (squash) |
| 25 | fble | BFOLE | BFOLE | 21500000 | 29500000 | 4/ip_reg_or_basic_block (squash) |
| 26 | fbge | BFOGE | BFOGE | 20D00000 | 28D00000 | 4/ip_reg_or_basic_block (squash) |
| 27 | fblt | BFOLT | BFOLT | 21100000 | 29100000 | 4/ip_reg_or_basic_block (squash) |
| 28 | trap_gt | BGT | BGT | 24500000 | 2C500000 | 0/trap_serialize_register |
| 29 | trap_le | BLE | BLE | 24700000 | 2C700000 | 0/trap_serialize_register |
| 30 | trap_ge | BGE | BGE | 24900000 | 2C900000 | 0/trap_serialize_register |
| 31 | trap_lt | BLT | BLT | 24B00000 | 2CB00000 | 0/trap_serialize_register |
| 32 | trap_hi | BHI | BHI | 24D00000 | 2CD00000 | 0/trap_serialize_register |
| 33 | trap_ls | BLS | BLS | 24F00000 | 2CF00000 | 0/trap_serialize_register |
| 34 | trap_lo | BLO | BLO | 25100000 | 2D100000 | 0/trap_serialize_register |
| 35 | trap_hs | BHS | BHS | 25300000 | 2D300000 | 0/trap_serialize_register |
| 36 | trap_nn | BNN | BNN | 25500000 | 2D500000 | 0/trap_serialize_register |
| 37 | trap_n | BN | BN | 25700000 | 2D700000 | 0/trap_serialize_register |
| 38 | trap_ne | BNE | BNE | 25900000 | 2D900000 | 0/trap_serialize_register |
| 39 | trap_eq | BEQ | BEQ | 25B00000 | 2DB00000 | 0/trap_serialize_register |
| 40 | trap_nv | BNV | BNV | 25D00000 | 2DD00000 | 0/trap_serialize_register |
| 41 | trap_v | BV | BV | 25F00000 | 2DF00000 | 0/trap_serialize_register |
| 42 | trap_feq | BFEQ | BFEQ | 20500000 | 28500000 | 15/trap_serialize_register |
| 43 | trap_fne | BFNE | BFNE | 20700000 | 28700000 | 15/trap_serialize_register |
| 44 | trap_fgt | BFOGT | BFOGT | 20900000 | 28900000 | 15/trap_serialize_register |
| 45 | trap_fle | BFOLE | BFOLE | 21500000 | 29500000 | 15/trap_serialize_register |
| 46 | trap_fge | BFOGE | BFOGE | 20D00000 | 28D00000 | 15/trap_serialize_register |
| 47 | trap_flt | BFOLT | BFOLT | 21100000 | 29100000 | 15/trap_serialize_register |
| 48 | trapd_gt | BGT | BGT | 24500000 | 2C500000 | 0/fp_reg_pair |
| 49 | trapd_le | BLE | BLE | 24700000 | 2C700000 | 0/fp_reg_pair |
| 50 | trapd_ge | BGE | BGE | 24900000 | 2C900000 | 0/fp_reg_pair |
| 51 | trapd_lt | BLT | BLT | 24B00000 | 2CB00000 | 0/fp_reg_pair |
| 52 | trapd_hi | BHI | BHI | 24D00000 | 2CD00000 | 0/fp_reg_pair |
| 53 | trapd_ls | BLS | BLS | 24F00000 | 2CF00000 | 0/fp_reg_pair |
| 54 | trapd_lo | BLO | BLO | 25100000 | 2D100000 | 0/fp_reg_pair |
| 55 | trapd_hs | BHS | BHS | 25300000 | 2D300000 | 0/fp_reg_pair |
| 56 | trapd_nn | BNN | BNN | 25500000 | 2D500000 | 0/fp_reg_pair |
| 57 | trapd_n | BN | BN | 25700000 | 2D700000 | 0/fp_reg_pair |
| 58 | trapd_ne | BNE | BNE | 25900000 | 2D900000 | 0/fp_reg_pair |
| 59 | trapd_eq | BEQ | BEQ | 25B00000 | 2DB00000 | 0/fp_reg_pair |
| 60 | trapd_nv | BNV | BNV | 25D00000 | 2DD00000 | 0/fp_reg_pair |
| 61 | trapd_v | BV | BV | 25F00000 | 2DF00000 | 0/fp_reg_pair |
| 62 | trapd_feq | BFEQ | BFEQ | 20500000 | 28500000 | 15/fp_reg_pair |
| 63 | trapd_fne | BFNE | BFNE | 20700000 | 28700000 | 15/fp_reg_pair |
| 64 | trapd_fgt | BFOGT | BFOGT | 20900000 | 28900000 | 15/fp_reg_pair |
| 65 | trapd_fle | BFOLE | BFOLE | 21500000 | 29500000 | 15/fp_reg_pair |
| 66 | trapd_fge | BFOGE | BFOGE | 20D00000 | 28D00000 | 15/fp_reg_pair |
| 67 | trapd_flt | BFOLT | BFOLT | 21100000 | 29100000 | 15/fp_reg_pair |
| 68 | trap | BZ | BZ3 | 00000000 | 00000000 | - |
| 69 | jump | B | B | 24300000 | 2C300000 | 4/ip_reg_or_long_pc_disp (squash) |
| 70 | dispatch | dispatch |  | 00000000 | 00000000 | 4/ip_reg_or_long_pc_disp (squash) |
| 71 | tstb | EXTEND | 7 | 13E0CF60 | 13E0CF60 | 0/ip_reg |
| 72 | tstw | EXTEND | 15 | 13E0DF60 | 13E0DF60 | 0/ip_reg |
| 73 | tst | SUB | ? | 13FF6000 | 13FF6000 | 0/ip_reg |
| 74 | cmp | SUB | ? | 13E06800 | 1FE00000 | 4/ip_compare_a_operand, 1/ip_reg |
| 75 | move | ADD | ? | 101F2000 | 181F0000 | 4/ip_reg_scaled_or_s_immed16, 2/ip_reg |
| 76 | pmove | ADD | ? | 101F2000 | 181F0000 | 4/ip_reg, 2/ip_reg |
| 77 | neg | SUB | - | 101F2800 | 101F2800 | 0/ip_reg, 2/ip_reg |
| 78 | com | XOR | ~ | 1400907F | 1400907F | 1/ip_reg, 2/ip_reg |
| 79 | add | ADD | + | 10002000 | 18000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 2/ip_reg |
| 80 | addc | ADDC | + | 10001800 | 14001800 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 81 | sub | SUB | - | 10002800 | 14002800 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 82 | subc | SUBC | - | 10003800 | 14003800 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 83 | rsub | SUBR | - | 10003000 | 14003000 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 84 | and | AND | & | 10000800 | 14000800 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 85 | or | OR | \| | 10000000 | 14000000 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 86 | xor | XOR | ^ | 10001000 | 14001000 | 4/ip_reg_scaled_or_s_immed8, 1/ip_reg, 2/ip_reg |
| 87 | extend0 | EXTEND | 0 | 10008160 | 10008160 | 0/ip_reg, 2/ip_reg |
| 88 | extend7 | EXTEND | 7 | 10008F60 | 10008F60 | 0/ip_reg, 2/ip_reg |
| 89 | extend15 | EXTEND | 15 | 10009F60 | 10009F60 | 0/ip_reg, 2/ip_reg |
| 90 | asr | SHRA | SHRA | 1000BE40 | 1000BE40 | 0/ip_reg, 7/ip_reg_or_u_immed5, 2/ip_reg |
| 91 | lsr | SHRL | >> | 1000BE00 | 1000BE00 | 0/ip_reg, 7/ip_reg_or_u_immed5, 2/ip_reg |
| 92 | lsl | SHLL | << | 1000BEC0 | 1000BEC0 | 0/ip_reg, 8/ip_reg_or_u_immed5, 1/ip_reg |
| 93 | isolate | ISOLATE | ISOLATE | 100080E0 | 100080E0 | 0/ip_reg, 8/ip_reg_or_u_immed5, 1/ip_reg |
| 94 | clrins | CLRINS | CLRINS | 100080C0 | 100080C0 | 0/ip_reg, 8/ip_reg_or_u_immed5, 1/ip_reg |
| 95 | transfer | TRANSFER | ? | 100080A0 | 100080A0 | 0/ip_reg, 8/ip_reg_or_u_immed5, 1/ip_reg |
| 96 | insert | INSERT | INSERT | 10008080 | 14000080 | 4/ip_reg_or_s_immed8, 8/ip_reg_or_u_immed5, 1/ip_reg |
| 97 | extractu | EXTRACT | ? | 10008000 | 10008000 | 4/ip_reg, 7/ip_reg_or_u_immed5, 2/ip_reg |
| 98 | widenb | WIDENB | ? | 00000000 | 00000000 | 4/ip_reg, 7/ip_reg_or_u_immed5, 2/ip_reg |
| 99 | widenw | WIDENW | ? | 00000000 | 00000000 | 4/ip_reg, 7/ip_reg_or_u_immed5, 2/ip_reg |
| 100 | synchb | synchb |  | 3FE00100 | 3FE00100 | - |
| 101 | synchw | synchw |  | 3FE00900 | 3FE00900 | - |
| 102 | synch | synch |  | 3FE01100 | 3FE01100 | - |
| 103 | loadbu | LOAD | _ | 34000000 | 40000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 2/ip_reg |
| 104 | loadwu | LOAD | _ | 34000800 | 50000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 2/ip_reg |
| 105 | loadl | LOAD | _ | 34001000 | 60000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 2/ip_reg |
| 106 | loads | LOAD | _ | 34002800 | 74000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 10/fp_reg |
| 107 | loadse | LOAD | _ | 00000000 | 00000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 3/fp_reg |
| 108 | loadso | LOAD | _ | 34002000 | 70000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 3/fp_reg |
| 109 | loadd | LOAD | _ | 34003800 | 6C000000 | 4/ip_reg_scaled_or_s_immed16, 1/ip_reg, 3/fp_reg_pair |
| 110 | load_pair | LOADQ | _ | 34001800 | 34001800 | 1/ip_reg, 2/ip_reg, 0/ip_reg |
| 111 | mfnextcc | mfcc | _ | 7C002000 | 7C002000 | 2/ip_reg |
| 112 | mfippsw | mfcc | _ | 7C002000 | 7C002000 | 2/ip_reg |
| 113 | mffpcc | MFPR | _ | FC1F0200 | FC1F0200 | 2/ip_reg |
| 114 | mffppsw | MFPR | _ | FC1F0200 | FC1F0200 | 2/ip_reg |
| 115 | mfpr | MFPR | _ | 7C002000 | 7C002000 | 6/u_immed13, 1/ip_reg, 2/ip_reg |
| 116 | mffp | MFPR | _ | FC1F2100 | FC1F2100 | 6/fp_reg, 2/ip_reg |
| 117 | fpquiesce | MFPR | _ | FFFF2204 | FFFF2204 | - |
| 118 | storeb | STORE | _ | 30000000 | 48000000 | 2/ip_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 119 | storew | STORE | _ | 30000800 | 58000000 | 2/ip_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 120 | storel | STORE | _ | 30001000 | 68000000 | 2/ip_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 121 | stores | STORE | _ | 30002800 | 5C000000 | 10/fp_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 122 | storese | STORE | _ | 00000000 | 00000000 | 3/fp_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 123 | storeso | STORE | _ | 30002000 | 78000000 | 3/fp_reg, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 124 | stored | STORE | _ | 30003800 | 4C000000 | 3/fp_reg_pair, 4/ip_reg_scaled_or_s_immed16, 1/ip_reg |
| 125 | mtpr | MTPR | _ | 7C000000 | 7C000000 | 2/ip_reg, 6/u_immed13, 1/ip_reg |
| 126 | mtfp | MTPR | _ | FC1F0100 | FC1F0100 | 2/ip_reg, 6/fp_reg |
| 127 | enable | B priv | ENABLE | 2400F01F | 2400F01F | - |
| 128 | disable | B priv | DISABLE | 2400701F | 2400701F | - |
| 129 | call | CALL | CALL | 20000000 | 28000000 | 4/ip_reg_or_long_pc_disp, 2/ip_reg (squash) |
| 130 | svc | SVC | SVC | 23E0201F | 23E0201F | 9/u_immed4 |
| 131 | svc2 | SVC | SVC | 23E0201F | 23E0201F | 9/u_immed4, 9/u_immed4 |
| 132 | return | B | B | 24300000 | 24300000 | 0/ip_reg (squash) |
| 133 | movei | COPY.FS | I | 3CD40000 | 3CD40000 | 14/fp_reg, 17/fp_reg |
| 134 | pmovei | COPY.FS | I | 3CD40000 | 3CD40000 | 14/fp_reg, 17/fp_reg |
| 135 | negi | NEG.I | - | 3E3C0000 | 3E3C0000 | 14/fp_reg, 17/fp_reg |
| 136 | comi | COM.I | ~ | 3CCC0000 | 3CCC0000 | 14/fp_reg, 17/fp_reg |
| 137 | addi | ADD.I | + | 3E040000 | 3E040000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 138 | subi | SUB.I | - | 3E2C0000 | 3E2C0000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 139 | andi | AND.I | & | 3CAC0000 | 3CAC0000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 140 | ori | OR.I | \| | 3C9C0000 | 3C9C0000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 141 | xori | XOR.I | ^ | 3CFC0000 | 3CFC0000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 142 | cvtis | FLOAT.FS | FLOAT | 36340000 | 36340000 | 14/fp_reg, 17/fp_reg |
| 143 | cvtid | FLOAT.FD | FLOAT | 363C0000 | 363C0000 | 14/fp_reg, 17/fp_reg_pair |
| 144 | copys | COPY.FS | _ | 3CD40000 | 3CD40000 | 14/fp_reg, 17/fp_reg |
| 145 | pcopys | COPY.FS | _ | 3CD40000 | 3CD40000 | 14/fp_reg, 17/fp_reg |
| 146 | moves | MOVE.FS | _ | 32640000 | 32640000 | 14/fp_reg, 17/fp_reg |
| 147 | negs | NEG.FS | - | 32540000 | 32540000 | 14/fp_reg, 17/fp_reg |
| 148 | abss | ABS.FS | ABS | 32440000 | 32440000 | 14/fp_reg, 17/fp_reg |
| 149 | cvtsd | DBLE.FD | DBLE | 36B40000 | 36B40000 | 14/fp_reg, 17/fp_reg_pair |
| 150 | roundsi | ROUNDI.FS | ROUND | 36140000 | 36140000 | 14/fp_reg, 17/fp_reg |
| 151 | rounds | ROUND.FS | ROUND | 36E40000 | 36E40000 | 14/fp_reg, 17/fp_reg |
| 152 | truncsi | TRUNCI.FS | TRUNC | 36940000 | 36940000 | 14/fp_reg, 17/fp_reg |
| 153 | truncs | TRUNC.FS | TRUNC | 36F40000 | 36F40000 | 14/fp_reg, 17/fp_reg |
| 154 | adds | ADD.FS | + | 32840000 | 32840000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 155 | subs | SUB.FS | - | 32940000 | 32940000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 156 | cmps | CMP.FS | ? | 13B40000 | 13B40000 | 15/fp_reg, 16/fp_reg |
| 157 | classs | CLASS.FS | _ | 13640000 | 13640000 | 14/fp_reg |
| 158 | tsts | TST.FS | ? | 13240000 | 13240000 | 14/fp_reg |
| 159 | mins | MIN.FS | - | 32240000 | 32240000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 160 | maxs | MAX.FS | - | 32340000 | 32340000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 161 | copyd | COPY.FD | COPY | 38DC0000 | 38DC0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 162 | pcopyd | COPY.FD | COPY | 38DC0000 | 38DC0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 163 | moved | MOVE.FD | MOVE | 326C0000 | 326C0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 164 | negd | NEG.FD | - | 325C0000 | 325C0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 165 | absd | ABS.FD | ABS | 324C0000 | 324C0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 166 | cvtds | SNGL.FS | SNGL | 36BC0000 | 36BC0000 | 14/fp_reg_pair, 17/fp_reg |
| 167 | rounddi | ROUNDI.FD | ROUND | 361C0000 | 361C0000 | 14/fp_reg_pair, 17/fp_reg |
| 168 | roundd | ROUND.FD | ROUND | 36EC0000 | 36EC0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 169 | truncdi | TRUNCI.FD | TRUNC | 369C0000 | 369C0000 | 14/fp_reg_pair, 17/fp_reg |
| 170 | truncd | TRUNC.FD | TRUNC | 36FC0000 | 36FC0000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 171 | addd | ADD.FD | + | 328C0000 | 328C0000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 172 | subd | SUB.FD | - | 329C0000 | 329C0000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 173 | cmpd | CMP.FD | ? | 13BC0000 | 13BC0000 | 15/fp_reg_pair, 16/fp_reg_pair |
| 174 | classd | CLASSD.FD | _ | 136C0000 | 136C0000 | 14/fp_reg_pair |
| 175 | tstd | TST.FD | ? | 132C0000 | 132C0000 | 14/fp_reg_pair |
| 176 | mind | MIN.FD | - | 322C0000 | 322C0000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 177 | maxd | MAX.FD | - | 323C0000 | 323C0000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 178 | muli | MUL.I | * | 3EFC0000 | 3EFC0000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 179 | divi | DIV.I | / | 3E840000 | 00000000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 180 | sqrts | SQRT.FS | SQRT | 30140000 | 00000000 | 14/fp_reg, 17/fp_reg |
| 181 | muls | MUL.FS | * | 30440000 | 30440000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 182 | divs | DIVS.FS | / | 30040000 | 30040000 | 15/fp_reg, 16/fp_reg, 17/fp_reg |
| 183 | sqrtd | SQRT.FD | SQRT | 301C0000 | 00000000 | 14/fp_reg_pair, 17/fp_reg_pair |
| 184 | muld | MUL.FD | * | 304C0000 | 304C0000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 185 | divd | DIV.FD | / | 300C0000 | 00000000 | 15/fp_reg_pair, 16/fp_reg_pair, 17/fp_reg_pair |
| 186 | adds5 | mul_ADD.FS | + | 80000000 | 80000000 | 11/fp_reg, 12/fp_reg (5op) |
| 187 | subs5 | mul_SUB.FS | - | C0000000 | C0000000 | 11/fp_reg, 12/fp_reg (5op) |
| 188 | truncsi5 | mul_TRUNCI.FS | TRUNC | 40000000 | 40000000 | 11/fp_reg, 12/fp_reg (5op) |
| 189 | addd5 | mul_ADD.FD | + | 00000040 | 00000040 | 11/fp_reg_pair, 12/fp_reg_pair (5op) |
| 190 | subd5 | mul_SUB.FD | - | 00000041 | 00000041 | 11/fp_reg_pair, 12/fp_reg_pair (5op) |
| 191 | truncdi5 | mul_TRUNCI.FD | TRUNC | 00000000 | 00000000 | 11/fp_reg_pair, 13/fp_reg (5op) |
| 192 | nop | OR | NOP | 13FF001F | 13FF001F | - |
| 193 | fnop | FNOP | FNOP | 04C40000 | 04C40000 | - |
| 194 | ipccnop | OR | NOP | 00000000 | 00000000 | - |
| 195 | shiftnop | shiftnop | ? | 101F0000 | 101F0000 | 4/ip_reg, 2/ip_reg |
| 196 | entry | entry | ENTRY | 00000000 | 00000000 | 0/none |
| 197 | limit | limit |  | 00000000 | 00000000 | - |
| 198 | epilogue | label$ |  | 00000000 | 00000000 | - |
| 199 | label | label |  | 00000000 | 00000000 | - |
| 200 | label$ | label$ |  | 00000000 | 00000000 | - |
| 201 | seq | seq |  | 00000000 | 00000000 | - |
| 202 | mmt_seq | mem_seq |  | 00000000 | 00000000 | - |
| 203 | join_bp | join_bp |  | 00000000 | 00000000 | - |
| 204 | ltorg | ltorg | LTORG | 00000000 | 00000000 | 0/none |
| 205 | tableb | ltorg | LTORG | 00000000 | 00000000 | 0/none |
| 206 | tablew | ltorg | LTORG | 00000000 | 00000000 | 0/none |
| 207 | tablel | ltorg | LTORG | 00000000 | 00000000 | 0/none |
| 208 | costly | costly |  | 00000000 | 00000000 | - |
| 209 | bugcheck | bugcheck |  | 00000000 | 00000000 | - |
| 210 | none | none |  | 00000000 | 00000000 | - |
| 211 | adj_move | ADD | ? | 00000000 | 00000000 | - |

## Latencies and the scheduler's pipeline model (sched_utils.pas; new)

Translator PB4 (sched_utils.pas, 0x279190..0x27A416; the SCHED phase
itself, sched.pas, is not translated yet).

- **Operand delays come from the opcode table.**  Each operand
  description in `instruction_attributes` (+4k, four bytes) carries in
  its third byte (+4k+2) a delay in bits 5..2 (0..15 cycles) and in
  bits 7..6 a code: 1 or 2 mean the operand has no delay of its own.
  The condition codes an opcode sets have their delay in the opcode's
  +15 bits 7..4.  sched_utils_$operand_delay (0x279266) reads these;
  sched_utils_$fill_in_operand_delays stores each operand's delay in
  the operand's +2 bits 3..0, which lst later prints as the cycle
  column.
- **Implicit operands.**  An operand the listing does not show (number
  above the opcode's shown count) takes the delay of the
  intend_to_modify read of the same live range before it (the
  read-modify-write pairs); a double's odd half takes its mate's.
  Calls, the entry, SEQ, LIMIT, SVC and RETURN have no delays on their
  implicit operands.
- **One extra cycle**, taken in one of two directions (the flags'
  element 1 says which; sched's pass 1 asks from the definition, oli
  from the reader):
  - an integer result read as operand 1 of a branch-like instruction
    (branch, call, floating branch, jump, the FP-immediate class, SEQ,
    trap, SVC, RETURN: bin's class mask 0x1104366) costs one more;
  - an integer result of a load (load, load_pair, MFPR, floating
    control: 0x419000) read by a reader with a count (operand +2 bits
    5..4) costs one more: the load-use interlock;
  - a floating result (floating double, single and FP-immediate
    classes) read by a store or a floating control instruction costs
    one more: the floating unit's result reaches the integer side
    late;
  - with the flags' element 0, a read of the integer condition codes
    costs one more than the setter's delay.
- **-CPU KODIAK** (cargs' cpu element 7) replaces the floating
  operations' latencies: DIVI 9, SQRTS 8, DIVS 4, SQRTD 15, DIVD 8,
  every other floating operation 0 (sched_utils_$kodiak_delay
  0x2791E8); the table's values are the default CPU's.
- **Precedence heights** (sched_utils_$calculate_precedence 0x279BC4):
  during SCHED an instruction's +28 word is the longest chain of delays
  from it to the end of its block (the segments final in the block and
  the reads of the closing branches are the roots); an instruction's
  height is at least 1.  A cycle among a block's definitions is a bug
  check ("deadlocked"); every instruction but branches and labels must
  get a height.  This is the list scheduler's priority: SCHED runs
  before register allocation (phase 12, RA 13), on virtual registers.
- **Snuggle moves** (sched_utils_$insert_snuggle_moves 0x27A398, from
  com and xtp): a write or read of a physical register (an argument or
  result register: its live range has +3 bit 7) gets a copy right next
  to the instruction (lir_utils_$trans_insert_move) when the
  instruction does more than move it, so that the physical register is
  live only between the copy and the call, entry, SVC or RETURN that
  needs it; the allocator can then use the register elsewhere.  A
  physical result with two readers, or a modify of a physical register,
  is a bug check.
