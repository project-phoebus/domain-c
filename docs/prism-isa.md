# The PRISM (a88k, DN10000) machine language as cc.a88k shows it

What the back end's output units (lst, bin, asm) reveal about the
PRISM instruction set: the opcode tables, the assembler syntax the
listings use, and (from bin) the binary encoding.  Each item cites the
unit and address it was read from; nothing here comes from outside the
image.  Translator PB, 2026-11-11; extended unit by unit (asm:
translator PB2).

## Processor revisions (-CPU; cargs.pas)

cc.a88k's -CPU option takes two groups of synonyms (cargs.pas, the a88k
branch of the -CPU parser):

- `10000`, `PRISM`, `A88K`, `AT` (and `ANY`, `ALL`): the DN10000,
  cpu set [6];
- `10000TX`, `TX`, `KODIAK`: cpu set [6, 7].  **KODIAK is the code name
  of the DN10000TX**, a PRISM revision that was never released (delayed,
  then cancelled after HP's acquisition of Apollo).  Bit 7 changes only
  the scheduler's floating-unit latencies (sched_utils_$kodiak_delay:
  DIVI 9, SQRTS 8, DIVS 4, SQRTD 15, DIVD 8 cycles, other floating
  operations 0), so the TX kept the instruction set and reworked the
  floating unit's divide and square root.  `AT`'s meaning is not in the
  image.

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
  characters: "BGT", "-", "|", ...), +19 the assembler name (16
  characters: "BNEVER", "ADD", "LOAD", "STORE", "EXTEND", "COPY.FS";
  move is listed as "ADD", a compare with an immediate too; **corrected
  (translator PX):** it is the -PRASM listing that prints this name in
  its opcode column, after the assignment form; the classic listing
  prints instruction_mnemonic, below: lst_$display_code_cell's
  `if 16 in cargs_$options.flags_286'), +36 a
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
  7..6 of a branch's cell).  **Corrected (translator PX, from the
  SR10.4 binaries; "Validated against SR10.4 binaries" below):** the
  suffix names when the slot instruction is *executed*, not when it is
  squashed: .SN never, .ST only when the branch is taken, .SF only when
  it falls through, .SA always (bit 7 of the mode: the slot runs on
  the fall-through, bit 6: it runs on the transfer).  "BNEVER.SA"
  opens the enable/disable layout.
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
  stub.  (The SR10.4 binaries, built by a later compiler, place the
  stub inside the routine after an unconditional jump, its literal
  0x00120003 in the routine's own pool: below.)
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
  | 6 | a single (number times 4) or a 13-bit unsigned value (MFPR/MTPR's special register) in bits 12..0; MFFP's and MTFP's templates carry bit 8 (0x100) inside the field, or-ed with the single's number times 4: 0x100 + 4n (validated: MTFP R10,S10 is FD5F0128) |
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
    (Validated: field 0 runs the delay slot always, 1 never, 2 when
    the branch is taken, 3 when it falls through; the suffix names
    when the slot runs: "Branches", corrected.)
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
  in the immediate form, else bit 14.  (Validated.  In the floating
  classes bit 14 lies in the register field 17..12: their condition
  codes are the floating ones, bit 24, seen on ADDD, SUBD, MOVED (the
  TSTD of asm) and CVTID.)
- **Confirmed.** Bit 31 marks an instruction that continues into the
  next word: the instruction's +2 bit 7 (pass 1 sets it when a
  floating instruction, or in an atomic block a load, is grouped after
  it: "companion"), or +2 bit 6 (a NOP word before it) outside the
  two-word floating classes.  (Validated: an integer word with bit 31
  is issued with the next word, which is always a floating-unit word
  in the binaries: a floating operation, an FNOP, or a floating control
  transfer's second word; the templates with bit 31 set, MFFP, MTFP,
  MFFPCC, FPQUIESCE, are such pairs' first words.)
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
  bit 7 (s_seq) and bit 6 (s_xfer): **corrected (translator PX):** bit
  7 lets the delay slot run on sequential flow (the fall-through) and
  bit 6 on the transfer; a slot with neither is squashed both ways
  (the SR10.4 binaries: "Validated against SR10.4 binaries").  dmp's
  ".sn", ".st", ".ss" (slot on sequential flow), ".sa" are lst's
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
docs/questions.md 161): for each PRISM opcode, the +19 name (the
column says "classic"; it is the name the -PRASM listing prints in its
opcode column, the classic listing printing the first column's
instruction_mnemonic: corrected, translator PX), the -PRASM operator
(+11), the register form's (+0) and the immediate form's
(+4) templates, and the field kind and operand form of each operand
the listing shows (instruction_attributes +11).  Opcodes 0 and
212..383 have no entry.  Some readings: the integer ALU's register
form is 0x1000xxxx with the operation in bits 14..11 (ADD 0x2000, SUB
0x2800, AND 0x0800, OR 0x0000, XOR 0x1000) and its immediate forms
0x14000000/0x18000000; MOVE is ADD with R31 (`101F2000'), CMP SUB
into R31 with the condition codes (0x6800: bit 14 and SUB's 0x2800),
TST R31 := R31 + Rn with them (0x6000: bit 14 and ADD's 0x2000;
corrected, translator PX: its +19 name says SUB, its template is
ADD's), NOP `OR R31,R31,R31' (0x13FF001F); the conditional
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
itself, sched.pas, translated by PB7: below).  sched calls only
fill_in_operand_delays; its pass 1 computes its own heights, in
quarter cycles (sched_utils_$calculate_precedence is oli's).

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

## Register classes and conventions (ra, ra_utils, call_conv, target_properties; new)

Translator PB5.  The register files as the allocator sees them come
from target_properties' PRISM entry (the fourth of the section
target_properties_read_only, cc.a88k 0x2B6800 + 3 x 328; its +0x10 is
3) and from call_conv's presets (call_conv.pas preset_0 .. preset_3).

- **Integer registers (32).**  ra_$begin_compilation (0x266C90) makes
  the allocatable set from target_properties +0x1C (the first, 0) and
  +0x24 (how many, 24): R0..R23; R24..R31 are never allocated (ra
  +0x5C8 holds the complement).  Two are named reserved (ra +0x5B4): the
  zero register (+0x14: R31, reads as zero) and the PC-like register
  (+0x18: R30, lst's "PC"); target_properties +0x34 (0xC0000000) is the
  same pair as a mask.
- **Floating registers (64 singles).**  F0..F63 are all allocatable
  (target_properties +0x3C first 0, +0x44 how many 64); there is no
  floating zero register (+0x38 = -1).  A double is an even/odd pair (a
  live range and its mate: operand kind fp_reg_pair, the halves' rrp
  fp_reg_even_only / fp_reg_odd_only); the spill code loads and stores
  the halves separately (LOADS/STORES, +4 for the odd half) or
  together (LOADD/STORED).  The allocator runs once for each class (ra
  +0x660: 1 integer, 2 floating singles, 3 pairs; ra's dumps' "IP
  REGISTERS", "FP REGISTERS", "FP REGISTER PAIRS").
- **Condition codes as registers.**  The integer and floating condition
  codes are allocated as registers 30 and 31 of the live range
  numbering (dmp, above); XTP inserts an IPCCNOP where a value of the
  condition codes must survive an instruction that sets them.
- **The ordinary conventions** (preset_1; preset_2 and _3, ftn_$stop's
  and the run-time library's, have the same register sets):
  - caller-saved (clobbered by a call): R0..R9, R22, R23 (0x00C003FF);
    F0..F3, F8..F51 (0xFFFFFF0F of 0..31, 0x000FFFFF of 32..63);
  - callee-saved (preserved): R10..R21 (0x003FFC00); F4..F7 and F52..F63
    (0xF0, and 0xFFF00000 of 32..63);
  - reserved, never modified: R24..R31 (0xFF000000);
  - arguments: integers and addresses in R4..R9 (a result returned by
    reference takes R4 first), floating singles in F8..F19 and doubles
    in even-aligned pairs there (a double also uses up two integer
    argument registers), the rest in memory (at_call_conv's part 4:
    nint from 4 to 9, nfp from 8 to 19);
  - R22 is the return address (call_conv_$t w14, bin_$unwind_bits); R23
    is read by every call (w20, the preset's reg40); the conventions
    also name R21 (w18), R2 or R21 (w16: R21 for a nested callee whose
    block needs its static link) and R3 (w12): the static link and
    frame registers, most likely.  (The SR10.4 binaries, below: R23 is
    the stack pointer, R2 the unit's data base as a routine descriptor
    sets it, R21 a callee's copy of it kept across calls, R0 the
    integer result, R1 the caller's stack pointer at entry.)
  - The C conventions under cargs flags_286 element 15 (preset_0): only
    R0..R9, R22, R26 (0x044003FF) and F0..F3 clobbered; R23..R25 and
    R27..R31 reserved (0xFB800000); F4..F63 in the preset's third set
    (fp16); reg40 R26.
- A routine's own sets: the registers it writes (rtn +148, +152), those
  RA saves in the prologue (+160, +164), and the calls' and SVCs'
  clobbers accumulated by ra_$initialize_basic_block (ra +0x614 ..
  +0x61C) less the reserved sets.

## The spill model (ra_utils, ra; new)

Translator PB5 (ra_utils.pas; ra.pas read in part, not translated).

- **Live ranges, not variables, are spilled.**  A live range's spill
  cost is a single real (lr +28) that ra_$initialize_basic_block adds
  to for each reference, weighted by the block's loop depth: **16 to
  the depth, the depth capped at 24 (confirmed, translator PB6:
  `2.0 ** (depth * 4.0)'; FPP words 0x00C4 the depth, 0x00A0 4.0 the
  multiply, 0x007C the product stored to a temporary, 0x0078 2.0
  loaded, 0x0148 the power by the temporary; rev889-patterns 149)**.
  A read or write adds the weight, a modify twice it; a write not read
  subtracts twice the weight from the reload cost (lr +44); a read a
  reload absorbs (TSTB, TSTW, EXTEND7/15 setting the condition codes
  with an unconsumed or zero result, EXTRACTU of the low byte or
  halfword: the forms ra_utils narrows to byte and halfword loads)
  adds it to the reload cost; a floating control instruction's read
  moves it from the cost to twice the reload cost (FPP 0x000C is
  subtract, 0x0018 reverse subtract: corrected from "counting
  differently").  A register move that sets no condition codes, and a
  TST, cost nothing.  A rematerializable live range's reload cost is
  added to its cost (ra_$initialize_routine); not "costs nothing" in
  ra (ra_utils' pass-through spilling sets 0.0 for its own choice).
- **Cost over live time (confirmed, PB6).**  After the conflict graph
  each live range's cost is divided by its weighted live time (the
  instructions it was live, each block's weight 8 to the depth capped
  at 32, `2.0 ** (depth * 3.0)'; FPP 0x0030 divide) when that exceeds
  1.0 (ra_$build_conflict_graph's end).
- **Spill choice (confirmed, PB6): Chaitin's cost per conflict.**
  ra_$collapse_conflict_graph removes live ranges whose conflicts are
  below the registers (the costliest first among those without active
  aversions or preferences); when none is left it picks the live range
  of least cost / conflicts (FPP 0x003C) that may be spilled (not
  life_mark), marking it rrp spare_1 ("spill candidate"), and goes on;
  ra_$assign_registers then gives registers in the reverse order and
  spills (lr +3 bit 0) a live range left without one, or, if that one
  may not be spilled, the conflict ra_$pick_spill_lr prefers (an
  assigned spill candidate, then the cheaper).  A failed pass undoes
  the assignment and calls ra_utils_$add_spill_code (mode 0 up to the
  fifth pass, 1 to the seventh, 2 after; at most 15 passes).
- **Never spilled:** the routine's argument pointer, DB register, +112
  and +120 live ranges (rrp life_mark), physical registers; a user
  declared register (lr +3 bit 5, "spill victim is user declared
  register") or a no_modify one (bit 6) chosen as a victim is a bug
  check.
- **Rematerialization** (ra_utils_$rematerialize): a live range with one
  definition (a pair's halves each one, by a double access), not
  modified, is recomputed instead of reloaded when its defining
  instruction reads only complex unique values that are never spilled,
  writes nothing else, is no slower than a load (its operand delay
  against LOADL's, LOADS's or LOADD's), and, for a load, reads constant
  memory (an immediate's, alias class 0 or 11) and is not grouped or
  continued; a move is followed to its source (at most 20 deep).  The
  copy is put before each reader (rematerialize_result; a LOADD
  narrowed to LOADS, a COPYD to COPYS, for one half of a pair).
- **Spill code** (ra_utils_$add_spill_code, after a colouring that left
  spill victims, lr +3 bit 0): each read of a victim gets a reload into
  a new live range just before it; later readers share the reload while
  they are within 20 instructions (0.6 of the readers' span; unbounded
  in the first pass) and no instruction in between has more registers
  live than three quarters of the block's peak (at least the registers
  there less 2).  Each write gets a store to the victim's memory home
  just after it, moved later by the store's latency (the definition's
  and the store's operand delays, less the instructions between) while
  nothing in the way touches the value, its home or memory slot, or
  transfers control, or (with latency left) has more than the live
  registers before it plus 4.  A move whose only purpose was the victim
  becomes a TST (TSTS, TSTD) or is deleted; a byte or halfword
  EXTRACTU, EXTEND or TST of a reloaded word becomes a byte or halfword
  load (displacement +3 or +2: big-endian).  Before the first pass a
  victim with one definition has its segments inside loops below the
  definition split off into live ranges of their own, joined to it by
  preference moves at the dominator one loop level out, so that only
  the loops' entries reload.
- **The memory home** is a stack-frame temporary made for the live
  range (lir_utils_$add_memory_home) or its variable's own slot (a
  VAR_NAME or FORTRAN symbol): the reload's displacement operand is a
  stack-frame displacement from the frame register's segment
  (asm_658).  ra_$allocate_stack_frame packs the frame's objects by
  alignment, 8 bytes first (sizes 1, 2, 4, 8 by the access), into rtn
  +48; a frame of more than 24 bytes sets the routine's needs_frame
  (+226 bit 0).
- **Pass-through spilling before scheduling** (XTP, ra_utils_$spill_
  pass_through_lrs): when the routine's peak demand (lir_main +0xC89,
  +0xC88) exceeds the registers (24 integer, 64 floating; a tenth
  fewer with lir_main_da4), live ranges that pass untouched through a
  hammock (a single-entry single-exit region) needing too many
  registers are stored before it and reloaded after it:
  rematerializable ones first (no store), then those with one
  definition, then the rest; adjacent hammocks' reloads and stores are
  coalesced and stores a dominator already made are dropped.

## Register allocation as ra does it (ra.pas; confirmed, translator PB6)

- **Classes in order pairs, singles, integers** (ra_class 3, 2, 1; the
  integer pass last, when the frame is laid out); each class passes
  until an assignment succeeds.
- **Registers opened from the conventions.**  The allowed set starts
  from the registers already written and not reserved by the
  conventions (fp60 / ip76) or never allocated; registers are added
  ("opened") as the chromatic number needs: clobbered ones first (no
  save), then preserved ones (4 bytes of save each, 8 a pair; a pair
  whose other half is open first); more than 24 bytes of saves and
  frame make the routine need a frame.  The floating class keeps three
  eighths of the clobbered registers' openings (at least min(n, 6)) out
  of the pair class's reach, which also never uses odd registers
  (0xAAAAAAAA).  The return address register (w14) goes to the +112
  live range, or the zero register (save_rpc) when the routine calls,
  has no return block, writes the register, or needs fewer colours
  than registers.
- **Aversions and the protection pipe.**  While the conflict graph is
  built a clock ticks per instruction (or group), with extra ticks for
  SCHED's stalls (+2 bits 3..0); a live range just read for the last
  time stays "protected" for 4 ticks after a floating operation, 2
  after a store's operand 1, and its predecessors' final reads (3
  ticks, 1 in the integer pass) at a block's entry: a live range
  written while another is protected gets an aversion to sharing its
  register (in-block, or between complex live ranges by loop depth),
  weighed against preferences (a move's delay plus one) when
  registers are chosen.  So the allocator keeps a value's register
  free until the pipeline has read it.
- **Preferences** (moves, by the move's delay plus one; complex moves
  after all blocks): a register given to a live range is preferred by
  everything its preferences reach (the closure through unassigned,
  non-conflicting live ranges).
- Instructions' +28..+31: floating live after, floating peak, integer
  after, integer peak (dmp's four counts); a block's +0..+7 its
  counts; lir_main_c88/c89 the routine's floating and integer peaks
  (ra_utils' pass-through spilling reads them).

## The scheduler's pipeline model (sched.pas; confirmed, translator PB7)

Translator PB5 read sched's routines (before translation) with
sched_utils and asm's pass 1; translator PB7 translated sched.pas
(0x273C90..0x279162, 50 routines) and checked each item.  **C**
marks what the translation confirmed, **corrected** what it changed.

- **Two issue slots a cycle (C, with corrections).**  SCHED (phase 12,
  before RA, block by block in rtn +72's order; the whole phase off
  with debug switch sw15) builds each cycle from an integer slot (sched
  +0x3118) and a floating slot (+0x3128), plus three side slots: the
  second of a load/store pair (+0x3114), an IPCCNOP (+0x3110) and a SEQ
  or join birthpoint (+0x310C).  instr_would_fit (0x2774F4):
  - a floating operation (classes fp_double, fp_single) goes with
    anything but a call in the integer slot, into an empty floating
    slot or beside a multiply it fuses with (both ways round; neither
    may set the floating condition codes); a FP-immediate class
    instruction only into an empty floating slot (it never fuses);
  - calls, floating control instructions and **floating preference
    moves that set no condition codes** need the whole cycle (both
    slots empty); ENTRY, LIMIT and SVC need it with no IPCCNOP either;
  - **an IPCCNOP fits beside anything but an instruction of a class
    that takes no slot** (ENTRY, SEQ, LIMIT, PMOVE, label, join
    birthpoint), one a cycle (corrected: PB5 had it with the
    whole-cycle group);
  - **once a SEQ or join birthpoint is in a cycle nothing else fits**
    (corrected: "take no slot" holds only for the ring and the stall
    count, final_p2_instr_update);
  - other (integer) instructions take the integer slot, or pair (next
    item).  With debug switch sw14 a floating operation needs an empty
    cycle and an integer one an empty floating slot (nothing shares).
  Skipped blocks: **atomic blocks and those with +17 bit 5** (xtp's
  b17_5) only lose their SEQs and join birthpoints
  (drop_unneeded_instructions; corrected: not "forwarded" blocks, +17
  bit 1).
- **MUL+ADD fusing (C).**  can_be_5opified (0x277262), fit_instr
  (0x277C46): MULS fuses with ADDS, SUBS, TRUNCSI; MULD with ADDD,
  SUBD, TRUNCDI.  The multiply stays in the floating slot, the add
  (+0x3124) takes the five-operand opcode (adds5 186, subs5 187,
  truncsi5 188, addd5 189, subd5 190, truncdi5 191).  An add that
  already modifies its result in place (operand 3, 6 for a double) is
  only canonicalized (the modified input second); otherwise one of its
  inputs (operand 2 first, then 1; a subtract only 2; a double's odd
  halves are operands k + 3) must be non-final, non-physical, read by
  no other instruction still to issue or meaning to modify it, and its
  live range must be one the result's can absorb (or be absorbed by:
  can_make_into_rmw_and_combine_lts); the input's reader is moved last
  in its chain, the add made read-modify-write and the two live ranges
  merged.  After the cycle's first instruction, pass 2 keeps adding
  floating operations only while the floating slot holds no fused add
  and an opcode with instruction_attributes +6 bit 1 (the add and
  multiply group: truncsi, adds, subs, mins, maxs, truncdi, addd, subd,
  mind, maxd, muls, muld and the five-operand forms).
- **Load/store pairing (corrected).**  Two integer instructions share
  a cycle only as two **LOADS or two STORES** (single-precision
  floating loads and stores) with the same memory operand kind and the
  same base segment, debug switch sw11 set: two literal-pool loads of
  single literals (literal kind 12; no adjacency test: fit_instr makes
  the two literals one pair literal with token_$make_real_lit_pair,
  whose found_swapped decides the order), or two stack-frame accesses
  to one VAR_NAME 4 bytes apart.  They become **LOADSE and LOADSO
  (STORESE and STORESO)**, the lower word's first (fitter +40), two
  single accesses of the even and odd word, not one double access.
- **Floating register traffic per cycle is limited (C).**
  fp_registers_busy (sched_readonly_tables 0x2BE108, two bytes by
  opcode: reads, writes, in singles; values as PB5 listed, and copys,
  movei, cvtis 1/1, muli 2/1, the five-operand forms as their adds,
  mffp 1/0, mtfp 0/1, a call 0/0): an instruction fits when the
  cycle's reads plus its own stay within sched_3158 and the cycle's
  writes plus its own and its +41 too; fit_instr adds its counts (a
  call also its +41 to the writes).  sched_3158 is lir_main's count of
  the floating register pairs the conventions do not reserve (fp60).
- **Latencies as a 16-cycle ring (C, refined).**  sched +0 .. +0x2080
  (16 lists of 130 segments, no overflow test), counts at +0x2080.
  When a cycle closes, each register result of its instructions that
  has a reader (not memory, not of a class that takes no slot) is
  entered in the list of cycle (delay + clock + 1) mod 16; the clock
  advances on a used cycle or a stall cycle (generate_stall_cycle) and
  the new cycle's list is emptied.  instr_would_stall (0x276F90)
  refuses an instruction reading any register or memory segment on any
  of the 16 lists (ENTRY, SEQ, LIMIT, PMOVE, labels and join
  birthpoints never stall).  The delays are sched_utils_$operand_delay's
  (fill_in_operand_delays with [1] and sw9 at pass 1's start).
- **The stall counts (C).**  final_p2_instr_update writes each issued
  instruction's +2 bits 3..0 as (clock - the clock when the previous
  cycle closed) mod 16: the stall cycles before its cycle.  Stalls come
  only from select_first_instruction (nothing ready can issue without
  stalling, or a ready call, SEQ, SVC or join birthpoint would stall)
  and from waiting for a high instruction (pass 2's third pass).
- **Two passes (C, refined).**  Pass 1 (0x27549C) takes the block
  apart: labels first on the new list, the closing branches and RETURN
  aside (squash mode set to 2, .SF; the conditional branch's condition
  code operand cut from its chain and made kind none), a final call
  (+3 bit 3 or 5) held back so that only SEQs can be placed before it.
  Walking back from the branches' inputs and the final segments, an
  instruction is placed when all its readers are and test_p1_lock frees
  it; its height is the largest (reader's height, its low bits cleared)
  + 4 x delay over its results, + 4 x (delay + 1) for a result whose
  segment height its readers set (p1_touch_segment), an ENTRY 30000,
  the branch's condition codes 8, plus register_pressure's bonus.
  Pass 2 (0x278900) issues by height: the first instruction
  (select_first_instruction: the final call when only SEQs follow it,
  in an entry block the ENTRY or LIMIT, else a call/SEQ/SVC/join
  birthpoint, else the highest that can issue, a later one of the same
  quarter preferred when its low bits are higher, the search ending 100
  quarters below the best), then the floating operations that fit, the
  others that fit, and an instruction at least as high that must wait
  a few cycles while nothing else can go.  The closing branches issue
  last, a cycle each.
- **register_pressure (0x275382; corrected).**  From a base of 2,
  each register operand (ip_reg .. fp_reg_pair_physical) read adds one
  and each written takes one off, for alu, call, fp_double, immediate,
  fp_control, fp_single and svc; a load or MFPR gives 0, a store or
  MTPR 1, every other class 2; the result clamped below at 0 and, above
  4, set to 3.  It is added to the placed instruction's height (the
  quarter-cycle fraction).
- After RA, ASM's pass 1 applies the last pipeline rules (its state
  machine, above): NOPs for a squashing call's delay slot and the
  floating unit's two-word instructions.

## Validated against SR10.4 binaries (tools/prism_dis.py; translator PX)

`tools/prism_dis.py` disassembles the text of an Apollo a88k COFF file
(magic 0x194; the reader is coff_compare.py's, .data's initial bytes
through cc_data.py's .rwdi rules) with a decoder generated from the
image's own tables: instruction_assembly, instruction_attributes,
instruction_mnemonic and of_string, read from cc.a88k's sections.  It
inverts asm.pas's pass 2: each opcode's register form (+0), immediate
form (+4) and, for loads and stores, the modified form (+0 with bit 27),
with the operand fields of the table above and the opcode's own fields
(squash, width, mode and qualifier, load_pair's offset, the condition
code bits) free.  Opcodes with one encoding are folded (move/pmove,
copys/movei/pcopys, mfnextcc/mfippsw, jump/return, svc/svc2; the
conditional traps are their branches, as asm encodes them).  `--stats`
walks each routine from its entry (routines from .blocks, or from
.unwind where .blocks does not describe them) and checks the result;
`--prasm` lists in lst's -PRASM form.  Run
`tools/prism_dis.py FILE --stats -v`, `tools/prism_dis.py FILE --routine
NAME`, `tools/prism_dis.py --table`.

The corpus: every a88k COFF text of
`domainos-archeology/sr10.4-install/install` (`file` finds 54 files;
48 distinct texts, the crt0/gcrt0/mcrt0 copies counted once): the
tools (install, config, rgy_create, cfgsa, xar, ctnode, uctnode, inprot,
distaa, minst, mrgcfg, mrgri, acl, rbak_sr10), install_utils (chn, cpf,
ld, crty, crd, edacl, sh, cpboot, crpty, bin/date, bin/sh, bin/ksh), the
network managers (sys/mgrs/net_*), the debugger target
tgt_apollo_prism.dbgk, the hardcopy trait examples and the crt0 objects.
They are C, Pascal and assembly built by the SR10.4 compilers, not by
DOMAIN C 6.9 itself: what they show is the machine's encoding and the
later compilers' habits, against which the 6.9 tables are checked.

### Decode statistics

"Executed" words are those some path from a routine's entry reaches
(the delay slots by their squash mode, a pair's floating word with its
integer one, case dispatches through their tables).  "Specialized": a
word several table entries match, one of which fixes every bit the
others fix (MOVE over ADD, TST over ADD, CMP over SUB, NEG over SUB,
TSTB over EXTEND7, COM over XOR, NOP over OR, SVC within CALL's
space...): taken as that most specific opcode.  "Equivalent": special
cases that overlap without nesting but share a general entry (19 words,
1FFF0000 and 1FFF0001: CMP #0/#-1,R31 is MOVE.CC #0/#1,R31 is ADD.CC
#0/#1,R31,R31).  "Ambiguous" (two unrelated entries): none.  "None":
no entry matches.  Calls on a start: displacement calls landing on a
routine's first word; branches inside: displacement branches and jumps
landing inside their own routine; pool refs on data: loads and stores
off PC (R30) landing on text words no path executes; returns
restoring: B [R22] reloading exactly the callee-saved registers its
prologue stored; .unwind masks: routines whose .unwind record's saved
register mask is the prologue's.

| binary | words | routines | executed | unique | specialized | equivalent | ambiguous | none (executed) | calls on a start | branches inside | pool refs on data | returns restoring | .unwind masks |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| tools/install | 35360 | 217 (blocks) | 34715 | 27594 | 7643 | 3 | 0 | 120 (0) | 476/476 | 3609/3609 | 61/61 | 221/221 | 217/217 |
| tools/config | 29822 | 157 (blocks) | 27025 | 24018 | 5783 | 0 | 0 | 21 (0) | 358/358 | 4348/4348 | 26/26 | 157/157 | 157/157 |
| tools/rgy_create | 15450 | 281 (blocks) | 15125 | 11574 | 3867 | 2 | 0 | 7 (0) | 297/297 | 1327/1327 | 130/130 | 285/285 | 281/281 |
| tools/cfgsa | 13740 | 52 (blocks) | 13641 | 10542 | 3178 | 0 | 0 | 20 (0) | 172/172 | 1166/1166 | 37/37 | 52/52 | 52/52 |
| tools/xar | 3338 | 37 (blocks) | 3281 | 2596 | 736 | 0 | 0 | 6 (0) | 44/44 | 339/339 | 26/26 | 44/44 | 37/37 |
| tools/ctnode | 5594 | 45 (blocks+unwind) | 4602 | 4545 | 808 | 0 | 0 | 241 (0) | 74/74 | 464/464 | 52/52 | 45/45 | 45/45 |
| tools/uctnode | 2284 | 34 (blocks+unwind) | 2010 | 1813 | 422 | 0 | 0 | 49 (0) | 22/22 | 141/141 | 32/32 | 34/34 | 34/34 |
| tools/inprot | 6948 | 33 (blocks) | 5709 | 5016 | 1584 | 0 | 0 | 348 (0) | 125/125 | 832/832 | 11/11 | 33/33 | 33/33 |
| tools/distaa | 15740 | 167 (unwind) | 15436 | 11719 | 4002 | 5 | 0 | 14 (0) | 288/288 | 1537/1537 | 32/32 | 167/167 | 167/167 |
| tools/minst | 21530 | 179 (blocks) | 19669 | 17281 | 4232 | 0 | 0 | 17 (0) | 587/587 | 3197/3197 | 37/37 | 179/179 | 179/179 |
| tools/mrgcfg | 2432 | 30 (blocks) | 2302 | 1851 | 581 | 0 | 0 | 0 (0) | 60/60 | 289/289 | 1/1 | 30/30 | 30/30 |
| tools/mrgri | 19818 | 96 (blocks) | 18703 | 16067 | 3746 | 0 | 0 | 5 (0) | 169/169 | 2591/2591 | 28/28 | 96/96 | 96/96 |
| tools/acl | 2742 | 8 (blocks) | 2154 | 2189 | 323 | 0 | 0 | 230 (0) | 34/34 | 229/229 | 40/40 | 8/8 | 8/8 |
| tools/rbak_sr10 | 20618 | 115 (unwind) | 16323 | 16809 | 2745 | 0 | 0 | 1064 (0) | 573/573 | 1896/1896 | 202/202 | 126/126 | 115/115 |
| install_utils/chn | 908 | 4 (blocks) | 770 | 734 | 133 | 0 | 0 | 41 (0) | 10/10 | 69/69 | 6/6 | 6/6 | 4/4 |
| install_utils/cpf | 644 | 2 (blocks) | 495 | 518 | 90 | 0 | 0 | 36 (0) | 7/7 | 52/52 | 5/5 | 2/2 | 2/2 |
| install_utils/ld | 6244 | 40 (unwind) | 5334 | 5242 | 737 | 0 | 0 | 265 (0) | 168/168 | 712/712 | 26/26 | 48/48 | 40/40 |
| install_utils/crty | 980 | 4 (blocks+unwind) | 771 | 796 | 117 | 0 | 0 | 67 (0) | 1/1 | 69/69 | 3/3 | 4/4 | 4/4 |
| install_utils/crd | 286 | 2 (blocks) | 209 | 243 | 29 | 0 | 0 | 14 (0) | 4/4 | 16/16 | 1/1 | 2/2 | 2/2 |
| install_utils/edacl | 4466 | 23 (unwind) | 3847 | 3476 | 824 | 0 | 0 | 166 (0) | 120/120 | 369/369 | 22/22 | 23/23 | 23/23 |
| install_utils/sh | 10 | 1 (blocks) | 9 | 9 | 1 | 0 | 0 | 0 (0) | 0/0 | 0/0 | 0/0 | 1/1 | 1/1 |
| install_utils/cpboot | 1226 | 7 (blocks) | 1035 | 1001 | 183 | 0 | 0 | 42 (0) | 19/19 | 120/120 | 6/6 | 6/6 | 7/7 |
| install_utils/crpty | 470 | 1 (unwind) | 374 | 389 | 58 | 0 | 0 | 23 (0) | 0/0 | 20/20 | 1/1 | 1/1 | 1/1 |
| install_utils/bin/date | 568 | 7 (unwind) | 550 | 431 | 137 | 0 | 0 | 0 (0) | 2/2 | 52/52 | 4/4 | 7/7 | 7/7 |
| install_utils/bin/sh | 14812 | 202 (blocks) | 14532 | 10383 | 4426 | 0 | 0 | 3 (0) | 335/335 | 1740/1740 | 41/41 | 196/196 | 202/202 |
| install_utils/bin/ksh | 37956 | 392 (unwind) | 36836 | 28195 | 9697 | 9 | 0 | 55 (0) | 639/639 | 4969/4969 | 84/84 | 395/396 | 392/392 |
| sys/mgrs/net_nil | 72 | 8 (unwind) | 62 | 65 | 5 | 0 | 0 | 2 (0) | 0/0 | 3/3 | 5/5 | 8/8 | 8/8 |
| sys/mgrs/net_chat | 396 | 9 (unwind) | 370 | 347 | 46 | 0 | 0 | 3 (0) | 2/2 | 23/23 | 2/2 | 20/20 | 9/9 |
| sys/mgrs/net_iic | 340 | 9 (unwind) | 311 | 294 | 41 | 0 | 0 | 5 (0) | 2/2 | 23/23 | 7/7 | 23/23 | 9/9 |
| sys/mgrs/net_user | 312 | 9 (unwind) | 273 | 265 | 42 | 0 | 0 | 5 (0) | 3/3 | 28/28 | 8/8 | 14/14 | 9/9 |
| sys/mgrs/net_ether_vme | 416 | 9 (unwind) | 385 | 371 | 41 | 0 | 0 | 4 (0) | 2/2 | 23/23 | 7/7 | 21/21 | 9/9 |
| sys/mgrs/net_dio_ethernet | 418 | 9 (unwind) | 387 | 367 | 46 | 0 | 0 | 5 (0) | 2/2 | 24/24 | 8/8 | 21/21 | 9/9 |
| sys/mgrs/net_ethernet | 416 | 9 (unwind) | 387 | 366 | 46 | 0 | 0 | 4 (0) | 2/2 | 24/24 | 8/8 | 21/21 | 9/9 |
| sys/mgrs/net_unknown | 72 | 8 (unwind) | 61 | 65 | 5 | 0 | 0 | 2 (0) | 0/0 | 3/3 | 5/5 | 8/8 | 8/8 |
| sys/mgrs/net_domain_ring | 414 | 9 (unwind) | 383 | 368 | 41 | 0 | 0 | 5 (0) | 2/2 | 23/23 | 7/7 | 29/29 | 9/9 |
| sys/mgrs/net_ring_8025 | 574 | 9 (unwind) | 537 | 513 | 47 | 0 | 0 | 14 (0) | 2/2 | 25/25 | 2/2 | 32/32 | 9/9 |
| hardcopy/driver/prsvr_driver_trait.a88k | 6 | 1 (blocks) | 4 | 4 | 1 | 0 | 0 | 1 (0) | 0/0 | 0/0 | 1/1 | 1/1 | 1/1 |
| hardcopy/filter/prsvr_filter_trait.a88k | 10 | 2 (blocks) | 8 | 7 | 2 | 0 | 0 | 1 (0) | 0/0 | 0/0 | 2/2 | 2/2 | 2/2 |
| sys5.3/usr/lib/isp_a88k/gcrt0.o | 652 | 10 (unwind) | 597 | 482 | 169 | 0 | 0 | 1 (0) | 4/4 | 42/42 | 11/11 | 10/10 | 10/10 |
| sys5.3/usr/lib/isp_a88k/mcrt0.o | 396 | 9 (unwind) | 358 | 281 | 114 | 0 | 0 | 1 (0) | 3/3 | 18/18 | 5/5 | 9/9 | 9/9 |
| sys5.3/usr/lib/isp_a88k/crt0.o | 110 | 3 (unwind) | 100 | 85 | 25 | 0 | 0 | 0 (0) | 0/0 | 2/2 | 1/1 | 3/3 | 3/3 |
| sys/debug/tgt/tgt_apollo_prism.dbgk | 13636 | 190 (unwind) | 13377 | 10751 | 2875 | 0 | 0 | 10 (0) | 105/105 | 1139/1139 | 71/71 | 194/194 | 190/190 |
| usr/apollo/lib/isp_a88k/gcrt0.o | 654 | 10 (unwind) | 600 | 482 | 171 | 0 | 0 | 1 (0) | 4/4 | 42/42 | 11/11 | 10/10 | 10/10 |
| usr/apollo/lib/isp_a88k/mcrt0.o | 398 | 9 (unwind) | 361 | 281 | 116 | 0 | 0 | 1 (0) | 3/3 | 18/18 | 5/5 | 9/9 | 9/9 |
| usr/apollo/lib/isp_a88k/crt0.o | 112 | 3 (unwind) | 103 | 85 | 27 | 0 | 0 | 0 (0) | 0/0 | 2/2 | 1/1 | 3/3 | 3/3 |
| usr/apollo/lib/svid/isp_a88k/gcrt0.o | 654 | 10 (unwind) | 600 | 483 | 170 | 0 | 0 | 1 (0) | 4/4 | 42/42 | 11/11 | 10/10 | 10/10 |
| usr/apollo/lib/svid/isp_a88k/mcrt0.o | 398 | 9 (unwind) | 361 | 282 | 115 | 0 | 0 | 1 (0) | 3/3 | 18/18 | 5/5 | 9/9 | 9/9 |
| usr/apollo/lib/svid/isp_a88k/crt0.o | 112 | 3 (unwind) | 103 | 86 | 26 | 0 | 0 | 0 (0) | 0/0 | 2/2 | 1/1 | 3/3 | 3/3 |
| **all 48 texts** | 284554 | 2483 | 265185 | 221361 | 60253 | 19 | 0 | 2921 (0) | 4727/4727 | 31677/31677 | 1098/1098 | 2628/2629 | 2483/2483 |

(The ksh return that does not restore exactly reloads R22 and R11
before a jump, where the check's backward walk stops.)  The counts
below marked "54 files" include the six duplicate crt0 texts; the
others are over the 48 distinct texts.

**Every executed word matches the table.**  The 2,921 words that match
nothing are all off the executed paths, and all are data (counted over
the 54 files): 2,360 text (Pascal string constants placed in the text
after the routines, reached by ADD Rx := PC + d), 234 literal pool
entries (PC-relative loads land on them), 211 case table entries (the
dispatches below), 95 between routines (zero padding to 8 bytes, data
after a unit's last routine) and 23 inside routines on case arms whose
dispatch the walk does not resolve (54 files).

### Confirmed

- **The templates and the field kinds** (the table above; "The
  encoding"): every executed word decodes, and the decoded operands
  make sense (stack and data offsets, string addresses, registers used
  by the conventions).  Integer registers 5-bit fields (kinds 0, 1, 2),
  pairs halved (kind 3: LOADD [..],D2 is 6C3E1E7C, r21 = 1), singles in
  doubles (kind 10, LOADS/STORES and the odd LOADSO/STORESO: 108 and 21
  executed), floating registers 6-bit (kinds 14..17).
- **Branch and call displacements**: 18-bit signed word displacements
  from the instruction's own address (bits 17..0): all 31,677
  displacement branches and jumps land inside their routine, all 4,727
  displacement calls on a routine's first word (none on a start + 8:
  the descriptors alone use that entry).
- **Literal pool references**: loads and stores off R30, the PC: a
  signed 16-bit byte displacement from the instruction's own address.
  All 1,098 land on text words no path executes, typically in the pool
  after the routine's code (e.g. 0x41F00000, 0x41E00000: 2^32, 2^31 as
  doubles; 0x040B000F, status codes).  ADD Rx := PC + d (3,292, Pascal's
  string constants) likewise all off the code.  R30 *is* the PC (the
  "like" register lst prints as PC).
- **ip_compare_a_operand negated**: CMP #256,R0 is 1FE0FF00.
- **The s_immed8 forms**: bits 6..0 and the sign in bit 15 (COM is XOR
  #-1: 1400907F).
- **The modified loads and stores**: +0's template with bit 27, an
  8-bit displacement (6..0, sign 15), the mode in 10..9 (1 post, 2 pre)
  and the qualifier in 8..7: STOREL R1,[56,--R23] is 38379448, LOADBU
  [R11++] 3D4B0201 (the displacement 1, the access size, implied in the
  listing).  The register form takes the mode too, with a scaled index:
  STOREL R1,[R0*8,++R23] (30371460), the large frames' push.  No
  qualifier (.LOCK/.UNLOCK/.PHYS) was seen.
- **The scale** in bits 6..5: LOADL [R21*4,R19],R4 (34931055), LOADWU
  [R22*2,R14] (35CE0836), LOADL [R11*8,R10] (35AA506B).
- **The field width** less one in bits 13..9 and the 5-bit immediates
  of kinds 7/8 with bit 8: EXTRACTU.CC R21,#4,#1,R31 (13E4C115), LSL
  R10,#5,R11 (10ABBFCA).
- **load_pair's offset**, in bytes, bits 5..0 in 10..5, bit 6 in 14,
  sign in 15: LOAD_PAIR [8,R23],R22,R11 (36D7190B), [40,R23],R12,R13
  (35971D0D): the frame's +8/+12 and +40/+44 where the prologue stored
  R22, R11, R12, R13.
- **The condition-code bits**: bit 14 (register forms and the s_immed8
  immediate forms: MOVE.CC, INSERT.CC, EXTRACTU.CC), bit 26 for the
  immediate forms of compare-form operands (LOADL.CC [16,R10],R5 is
  64AA0010, ADD.CC #-256,R0,R13 1DA0FF00; loads set the condition codes
  from the value loaded: 5,472 executed), bit 24 for the floating ones.
- **asm's TSTS/TSTD as MOVES/MOVED with the operand copied**: MOVED.CC
  D8,D8 (336C8208).  No CMPS/CMPD/TSTS template was executed: floating
  compares are SUBD.CC/ADDD.CC (bit 24) and the FBxx branches.
- **The pairing** (bit 31): 1,567 executed integer words carry bit 31;
  every following word decodes as a floating-unit word and none as an
  integer one: NOP with bit 31 (93FF001F) before a lone floating
  instruction, FNOP (04C40000, 268) after a continued integer one, the
  floating control's second word (word & 0xFFF) | 0xE40000 (421) after
  each MFFP (236) and MTFP (185), a floating operation after the rest.
  A branch can be paired too (BHS.SF with bit 31 and an FNOP): its
  delay slot is then the next pair.
- **The registers and the frame**: R22 the return address (every
  return is B [R22], every .unwind record names R22); R23 the stack
  pointer; R31 zero; R30 the PC; callee-saved R10..R21 (the only
  integer registers stored to the frame on entry besides R22 and
  argument homes); F4..F7/F52..F63 (the only floating ones saved: F4,
  F54, F55); arguments in R4..R9 (read before written on entry, 54
  files: R4 1,801, R5 1,077, R6 561, R7 402, R8 252, R9 160 times;
  others only R3 and R0, 4 and 2 times) and F8..F19 (F8..F17; F0, F3,
  F4, F20 in 11 routines).
- **The exception stub's SVC**: asm's SVC word less bits 9..8 plus
  0x380 (23E0239F, SVC #14), after LOADL R4 of the literal 0x00120003
  (16 stubs).
- **Case tables**: asm_$build_dispatch_table's displacements from the
  dispatch ADD, as bytes (TABLEB) or halfwords (TABLEW): CMP #n,Ri; BHI
  out; LOADBU [Ri,Rt],Rj or LOADWU [Ri*2,Rt],Rj; ADD Rj,PC,Rk; JUMP.SN
  [Rk] (or the same through R22, a RETURN-shaped word).  60 dispatches,
  their 760 cases all inside their routines.

### Corrected

- **The squash suffix names when the delay slot runs, not when it is
  squashed** ("Branches", dmp's s_seq/s_xfer above).  Hardware field 0
  runs the slot always, 1 never, 2 when the branch is taken, 3 when it
  falls through; with asm's (57 >> 2 * mode) & 3 that makes .SN never,
  .ST taken, .SF falling through, .SA always, and the cell's +3 bit 7
  "run on the fall-through", bit 6 "run on the transfer".  The
  evidence: the returns are B.SA [R22] whose slot pops the frame (54
  files: of 2,651, LOAD_PAIR [R23],R23,R10 1,845 times, LOADL [R23],R23
  399); CALL.SA (12,666 executed) has its last argument set in the
  slot (CALL.SA [R2],R22; MOVE R10,R4); the descriptors' B.SA [R0] pushes the frame
  in its slot and enters the routine past its own push; BEQ.SF puts in
  its slot the compare the next branch on the fall-through tests;
  BLT.ST at a loop's bottom puts the loop head's first load in its slot
  and jumps past it; JUMP.SN closing a loop has the loop exit's first
  instruction in its slot, reached by the exit branch (install's
  FreeTOC 0x80960).  Every CALL.SN (7,253) is followed by a NOP that
  never runs (asm's NOP for "a squashing call").  asm.pas and lst.pas only
  copy the mode, so their code is unaffected; the comments that read
  the bits as squashing are inverted (asm.pas's pass 1 summary,
  "squashing on bit 6"; dbg_life.pas's "its delay slot squashed on
  sequential flow", which its code uses the right way: a call with bit
  7 takes effect after the slot instruction).
- **+19 is the -PRASM listing's opcode name** ("The opcode tables",
  the table's "classic" column): lst_$display_code_cell prints
  instruction_assembly +19 under -PRASM and instruction_mnemonic in the
  classic listing.
- **TST is ADD into R31** with the condition codes (0x6000 = bit 14
  and ADD's 0x2000), not SUB as its +19 name says (CMP is SUB, 0x6800).
- **Kind 6's single** (MFFP, MTFP): the template's bit 8 lies inside
  the field, so the field is 0x100 + 4n (FD5F0128 is MTFP R10,S10, its
  second word 00E40128).
- **The floating condition codes** are bit 24 in the floating classes;
  bit 14 there is a register field's (17..12), never the integer
  condition codes.
- **The exception stub** of these later compilers sits inside the
  routine after an unconditional jump, its literal in the routine's
  pool (not at PC+8), 0x00120003 (not 0x00120004).  This is a
  difference of the SR10.4 compilers, not a misreading of bin.pas.

### New: seen in the binaries, absent from the compiler's table or this document

- **No opcode outside the table.**  No executed word fails to decode
  (the non-decoding words are data: above);
  no privileged or OS instruction is executed anywhere (ENABLE,
  DISABLE, MTPR, MFPR, the SYNCHs, FPQUIESCE and MFFPCC never appear; the
  only SVC is the stub's).  Table entries never executed, so
  unconfirmed: BNEVER, BNL2V, BL2V, BNL2, BL2, BNZ3, BZ3, BNV, BV,
  FBGT, FBLE, SUBC, the SYNCHs, MFFPCC, MFPR, FPQUIESCE, MTPR, ENABLE,
  DISABLE, the single-precision floating operations (COPYS, MOVES,
  NEGS, ABSS, ROUNDS..., ADDS, SUBS, MINS, MAXS, CMPS, CLASSS, TSTS,
  SQRTS), the FP-immediate NEGI, COMI, ANDI, ORI, XORI, DIVI, and NEGD,
  ABSD, CVTSD, CVTDS, ROUNDDI, ROUNDD, TRUNCD, CMPD, CLASSD, TSTD,
  MIND, MAXD, SQRTD, MULD and the five-operand forms.  Executed (with
  counts in the decoder's histogram, scratch): the integer ALU and
  shifts, every load and store size in all three forms, LOAD_PAIR, the
  conditional branches (also by register), FBEQ, FBNE, FBGE, FBLT,
  JUMP, CALL, SVC, MFNEXTCC (120: the next condition codes into a
  register), MFFP, MTFP, FNOP, COPYD, MOVED, ADDD, SUBD, DIVD, CVTID,
  CVTIS, TRUNCDI, TRUNCSI, MULS, DIVS, ADDI, SUBI, MULI.
- **Routine descriptors** (in .data, made at link time or by the
  compiler's complete_entry_sequence; asm.pas names the latter):
  six words, `601E0014` LOADL R0,[PC,0x14]; `185Exxxx` ADD R2 := PC +
  d, the unit's data base (cc.a88k's A5 of the unit, .blocks' a5);
  `103F2017` MOVE R23,R1; `24300000` B.SA [R0]; in the slot the
  routine's push (STOREL R1,[n,--R23]) or R0 := -frame/8; the code
  address, the routine's start + 8 when the routine has its own push
  (it is also called directly) and its start when not.  A call by
  register is a call of a descriptor: LOADL [d,R2],Rx; CALL.SA [Rx],R22
  (15,192 such calls, 1,079 of them through R22 itself; the
  displacement calls are the unit's own).
- **The prologue** (54 files, 2,505 routines): MOVE R23,R1; STOREL R1,[n,--R23]
  (1,040); MOVE R23,R1; MOVE #-k,R0; STOREL R1,[R0*8,++R23] for a frame
  over 128 bytes (327); entered from a descriptor that pushes in its
  slot (635) or sets R0 := -k for the routine's STOREL R1,[R0*8,++R23]
  (225); no frame (278).  The frame: +0 the caller's R23, +4 R10 (or
  R21 when R21 is the only one), +8 R22, +12 R11, +40.. R12..R21 in
  order; the epilogue LOAD_PAIRs them back and pops +0/+4 in the
  return's slot.  A routine that needs the data base after calls saves
  R21 and copies R2 into it (MOVE R2,R21); R21 is read after calls
  5,048 times (54 files), R0 (the integer result) 6,498, R23 6,101: R23
  survives calls, though the conventions' clobbered set (0x00C003FF)
  names it.
- **.unwind**: groups of 16-byte records (a header: start, length << 7
  | 4, the group's bytes, 0; then one record per routine: start, length
  << 7, and two words: the third's bits 29..20 the saved R21..R12, the
  fourth's 31..27 the register at +4, 26..22 the one at +12, 21..17 the
  return address's, R22).  All 2,483 records agree with the
  prologues (the saved mask, and the registers at +4 and +12 with the
  stores before the first transfer).
- **The condition codes are read one instruction late**: of 19,255
  conditional branches, 16,506 have a setter two words before and none
  in the word just before (9,969 of them CMP; NOP; Bcc), 1,231 both
  (CMP a; CMP b; Bcc; Bcc, each branch testing the compare two before
  it, the second in the first's .SF slot), 160 only in the word before
  (a branch target between), 1,358 neither (set earlier).  So a branch
  tests the condition codes as they were two instructions before it
  (sched's extra cycle for a read of the condition codes; xtp's
  IPCCNOP).  The 19 "equivalent" words (1FFF0000, 1FFF0001: MOVE.CC
  #0/#1,R31) sit between a setter and its branch (install 0x983E4:
  EXTRACTU.CC; 1FFF0001; BNE.SF): docs/questions.md 308.
- **Transfers in a delay slot that runs on the fall-through** (54
  files): a second branch (4,581, many of them unoptimized code's JUMP.SN
  to the next word), and calls (1,047), 341 of which return to the
  branch's target (`if (p) f(p)` in two words: BEQ.SF over; CALL.SN
  f).  Conditional returns: Bcc [R22] (234).
- **Calls that do not return** end a routine without a return (3
  routines run off their end into the next after such a call;
  pfm_$error_trap, exit).

### Sample: install's reverse (load_toc.c, the K&R string reversal)

```
reverse:
08ED68: 103F2017   MOVE       R23,R1
08ED6C: 38379458   STOREL     R1,[40,--R23]        push a 40-byte frame
08ED70: 69570004   STOREL     R10,[4,R23]
08ED74: 6AD70008   STOREL     R22,[8,R23]
08ED78: 6977000C   STOREL     R11,[12,R23]
08ED7C: 115F2004   MOVE       R4,R10               s
08ED80: 6042FDF8   LOADL      [-520,R2],R2         strlen's descriptor
08ED84: 22C00002   CALL.SA    [R2],R22
08ED88: 109F200A   MOVE       R10,R4               (slot) the argument
08ED8C: 14202801   SUB        #1,R0,R1             j = strlen(s) - 1
08ED90: 2C300008   JUMP.SA    h'8EDB0
08ED94: 181F0000   MOVE       #0,R0                (slot) i = 0
08ED98: 36C1000A   LOADBU     [R10,R1],R22         s[j]
08ED9C: 11608F6B   EXTEND7    R11,R11              c (a signed char)
08EDA0: 32C0000A   STOREB     R22,[R10,R0]         s[i] = s[j]
08EDA4: 3161000A   STOREB     R11,[R10,R1]         s[j] = c
08EDA8: 14212801   SUB        #1,R1,R1
08EDAC: 18000001   ADD        #1,R0,R0
08EDB0: 13E06801   CMP.CC     R1,R0
08EDB4: 13FF001F   NOP
08EDB8: 2CBBFFF8   BLT.ST     h'8ED98              i < j
08EDBC: 3560000A   LOADBU     [R10,R0],R11         (slot, when taken) c = s[i]
08EDC0: 36D7190B   LOAD_PAIR  [8,R23],R22,R11
08EDC4: 24300016   RETURN.SA  [R22]
08EDC8: 36F7180A   LOAD_PAIR  [R23],R23,R10        (slot) pop the frame
```
