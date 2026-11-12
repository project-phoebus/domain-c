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
