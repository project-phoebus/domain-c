# The PRISM (a88k, DN10000) machine language as cc.a88k shows it

What the back end's output units (lst, bin, asm) reveal about the
PRISM instruction set: the opcode tables, the assembler syntax the
listings use, and (from bin) the binary encoding.  Each item cites the
unit and address it was read from; nothing here comes from outside the
image.  Translator PB, 2026-11-11; extended unit by unit.

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

## The encoding (asm.pas, read but not yet translated)

asm_$process_routine (0x21F6D4, 0x19A2 bytes) builds each instruction's
word (stored at the instruction's +24, which zzzzz copies to the code
cell's +12) as the OR of a template and the operands' fields.  What
follows is read from its encoder (0x2205A8..0x220FAA); bit 31 is the
most significant.  The translation of asm.pas will check it.

- The template is instruction_assembly's +0 for the register form and
  +4 for the immediate form: an operand that is an immediate switches
  to +4 (0x220742).
- Each operand has a field kind, instruction_assembly's word for it
  (+36 + 2(k-1)) bits 7..3, 0..17 (a jump table at 0x2206BE):

  | kind | field |
  |------|-------|
  | 0 | none |
  | 1 | integer register in bits 20..16 |
  | 2 | integer register in bits 25..21 |
  | 3 | a register pair (its number halved) in bits 25..21 |
  | 4, 5 | an integer register in bits 4..0; otherwise the immediate form, the value by the operand's form (below) |
  | 6 | a single (number times 4) or a 13-bit unsigned immediate in bits 12..0 |
  | 7 | a register in bits 20..16, or a 5-bit immediate there with bit 8 set |
  | 8 | a register in bits 25..21, or a 5-bit immediate there with bit 8 set |
  | 9 | a 4-bit immediate in bits 9..6 |
  | 10 | a single held in a double register: the double's number in bits 25..21; an odd single turns stores into storeso and loads into loadso (their templates) |
  | 11 | a floating register (0..63) in bits 23..18 |
  | 12 | a floating register in bits 29..24 |
  | 13 | a floating register's even part in bits 29..24, its low bit in bit 0 |
  | 14 | a floating register in bits 11..6 and again in bits 5..0 |
  | 15 | a floating register in bits 5..0 (divi wants an odd one) |
  | 16 | a floating register in bits 11..6 |
  | 17 | a floating register in bits 17..12 |

  So the integer registers take 5-bit fields and the floating registers
  6-bit ones (64 singles; a double is an even/odd pair).
- An integer register's scale (the operand's +2 bits 5..4: x1, x2, x4,
  x8) goes into bits 6..5.
- Immediates of kinds 4 and 5, by the operand's form (of$t):
  - a branch target (forms ip_reg_or_long_pc_disp,
    ip_reg_or_basic_block): the word displacement to the target block's
    first instruction, 18 bits in bits 17..0 (a call's is left to bin);
  - ip_compare_a_operand: the value negated, bits 15..0 (a compare with
    an immediate is an add of its negation, hence lst's "ADD");
  - s_immed8 forms: bits 6..0 and the sign in bit 15;
  - the 16-bit immediates and displacements: bits 15..0; for a load or
    store that modifies its base or has a qualifier, an 8-bit signed
    displacement (bits 6..0, sign in bit 15) with the register form's
    template and bit 27 set; argument block, stack frame and literal
    pool displacements left at 0 for bin; XSB displacements biased
    (lir_main's base), at most 32767;
  - ip_reg_or_u_i16_or_hi_i16 (and the and/bic form): a value whose
    high half is zero goes in bits 15..0; one whose low half is zero
    puts its high half there with bit 27 set (a "high" immediate);
    otherwise its complement is tried, AND (opcode 84) becoming BIC
    (214) and back.
- After the operands:
  - a branch's squash mode (the cell's +3 bits 7..6) goes into bits
    19..18 through the constant 57: .SN 1, .ST 2, .SF 3, .SA 0;
  - an insert's or extract's width less one, bits 13..9;
  - a load's or store's addressing mode (am$t) in bits 10..9 and its
    qualifier (lsq$t) in bits 8..7 (register form);
  - load_pair's offset in bits 10..5 with its sign in bit 15;
  - a synch takes a byte of the routine's record (+116's +2) in bits
    20..16;
  - setting the floating condition codes is bit 24; setting the
    integer ones bit 26 for an immediate compare-form operand 1 (forms
    3 and 10) in the immediate form, else bit 14;
  - bit 31 marks an instruction that continues into the next cell (the
    cell's +2 bit 7, or bit 6 outside the two-word floating classes).
- Register operands get their physical register from the live range
  (the segment's +48, its +2) or from lir_main's table of physical
  registers by the operand's number, and the operand's +0 is
  overwritten with it: after asm an operand's +0 is the register
  (zzzzz's test against 31; docs/questions.md 153).
