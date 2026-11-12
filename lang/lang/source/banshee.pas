{ banshee - the code generator's rewriting of 68881 instructions for
  the FPX (-CPU FPX, cpu element 5): each 68881 cell of a routine's code
  becomes a move of its command word (genfpinst) to the coprocessor's
  command register (CommandCIR) and moves of its memory operand to or
  from the operand register (OperandCIR), by halves for a double, an
  operand through -(An) or (An)+ addressed by hand; after a floating
  comparison, a 68881 branch or set whose path back to the comparison
  only moves registers gets an alignment cell (460) before it.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0EE84C  --------  dobansheefpx
    A5 0x354F44 (cc.m68k): the module's data, 0x74 bytes, set by .rwdi:
    +0x0 an address register operand (its register set from the
    operand's), +0x18 the immediate 8 (its node set at run time), +0x30
    the 68881 cell's memory operand (packed), +0x40 the immediate
    command word (packed: f6 1, a word), +0x50 OperandCIR (mode 12,
    -1008), +0x68 CommandCIR (packed: mode 12, -1014); their x the
    string nodes 'OperandCIR' and 'CommandCIR' (strtk at each call);
    +0x14, +0x2C, +0x3C, +0x4C and +0x64 not addressed.

  dobansheefpx loads A5 (global; final.pas's peepholer calls it, the
  heading in final.ins.pas).  The 68881 operand sizes are opinfo.pas's
  data (opcontext, cc.m68k 0x2D01CE: two characters per instruction,
  the source's and the destination's: B, W, L, F, D, X), declared in
  final.ins.pas (docs/questions.md 148).

  Not known from the original: the names of the module's variables
  and of the locals; why the alignment cell is wanted.
}
module banshee;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/final.ins.pas';

var
  { The module's data (A5 0x354F44). }
  bans_areg: codegen_$uads_t := [f1 := 1, f2 := 31, f3 := 31, f4 := 0,
      f5 := 0, f6 := 1, x := 0, y := 0];       { +0x0 }
  bans_14: integer32 := 0;                    { +0x14 }
  bans_imm8: codegen_$uads_t := [f1 := 3, f2 := 31, f3 := 31, f4 := 0,
      f5 := 0, f6 := 1, x := 0, y := 0];       { +0x18 }
  bans_2c: integer32 := 0;                    { +0x2C }
  bans_opnd: codegen_$ads_t;                  { +0x30 }
  bans_3c: integer32 := 0;                    { +0x3C }
  bans_cmd: codegen_$ads_t := [f1 := 3, f2 := 31, f3 := 0, f4 := 0,
      f5 := 0, f6 := 1, pad := 0, x := 0, y := 0];   { +0x40 }
  bans_4c: integer32 := 0;                    { +0x4C }
  bans_operand_cir: codegen_$uads_t := [f1 := 12, f2 := 31, f3 := 31,
      f4 := 0, f5 := 5, f6 := 1, x := 0, y := -1008];   { +0x50 }
  bans_64: integer32 := 0;                    { +0x64 }
  bans_command_cir: codegen_$ads_t := [f1 := 12, f2 := 31, f3 := 0,
      f4 := 0, f5 := 5, f6 := 1, pad := 0, x := 0, y := -1014];   { +0x68 }

  { celpkg.pas's empty descriptor (its +24, cc.m68k 0x2CE68C,
    absolute). }
  null_ads: extern codegen_$ads_t;

{ dobansheefpx - see final.ins.pas: under -CPU FPX, every 68881 cell
  (kinds 40..42, 44, 50) from first up to last rewritten: its command
  word moved to CommandCIR (the cell made a move, 1, of a word); its
  memory operand (40: the source, 42 and 50: the destination; 41 and
  44 have none) moved to or from OperandCIR by its size (B 1, W 2; L,
  F and D 4, a double twice: y and y + 4, a constant's longwords by
  smcontk; an operand -(An) or (An)+ (mode 9) by a subtraction of 8
  from An before the cell and (An), 4(An)); X none; il_c4's bit 5 set.
  After a comparison (41, 44), the next 68881 branch or set (39, 43)
  gets an alignment cell (34, instruction 460) before it when every
  cell between them is a label, a line, a block's start or end, a
  moveq, instruction 201, or an instruction to a register whose source
  is a register or an immediate (by the instruction's class).

  0x0EE84C, 0x782 bytes, link #-104, A5 loaded: cpu element 5 tested
  `tst.b' of 0x2C3671; the loop from first to last through +0 entered
  at its test; the 68881 kinds `btst' in the set at 0x0EEFEC (0..63,
  no range check), the cells skipped back in the set at 0x0EEFDA
  (0..47: [0, 2, 24, 32, 33]); the size letters compared in turn; a
  jump table of 4 on the form and one of 116 on the instruction (the
  classes: the source register or immediate, the immediate word form,
  any, none); the cell's operands saved at -32 and its instruction at
  -8, not read again; the alignment cell's operands celpkg's empty
  descriptor (0x2CE68C, copied absolutely); the extra cells linked by
  `after' around the 68881 cell (before it through its +4). }

procedure dobansheefpx;
var
  op: integer;
  saved: array [1..2] of codegen_$ads_t;
  last_kind: integer;
  prev_c: codegen_$cell_ptr_t;
  u: codegen_$uads_t;
  q: codegen_$cell_ptr_t;
  sz: integer;
  c: codegen_$cell_ptr_t;
  p: codegen_$cell_ptr_t;
  form: integer;
  access: char;
  ok: boolean;
  k: il_$node_ptr_t;
begin
  if 5 in cargs_$options.cpu then begin
    bans_operand_cir.x := integer32(strtk('OperandCIR', 10));
    bans_command_cir.x := integer32(strtk('CommandCIR', 10));
    last_kind := 24;
    c := first;
    while c <> last do begin
      p := c;
      if c^.kind in [40..42, 44, 50] then begin
        last_kind := c^.kind;
        op := c^.op;
        saved[1] := c^.ads1;
        saved[2] := c^.ads2;
        prev_c := c;
        form := 0;
        access := '-';
        case p^.kind of
          40: begin
            access := opcontext[p^.op][1];
            if (access = 'D') and (c^.ads2.f1 = 9) then
              form := 2
            else
              form := 1;
            bans_opnd := p^.ads1;
          end;
          42: begin
            access := opcontext[p^.op][2];
            if (access = 'D') and (c^.ads2.f1 = 9) then
              form := 4
            else
              form := 3;
            bans_opnd := p^.ads2;
          end;
          50: begin
            access := opcontext[p^.op][2];
            if (access = 'D') and (c^.ads2.f1 = 9) then
              form := 4
            else
              form := 3;
            bans_opnd := p^.ads2;
          end;
          otherwise
            ;
        end;
        if access <> 'X' then begin
          bans_cmd.x := integer32(smcontk(81, genfpinst(p)));
          p^.kind := 1;
          p^.op := 1;
          p^.ads1 := bans_cmd;
          p^.ads2 := bans_command_cir;
          p^.size := ilength(c);
          case access of
            'B':
              sz := 1;
            'W':
              sz := 2;
            'L':
              sz := 4;
            'F':
              sz := 4;
            'D':
              sz := 4;
            otherwise
              ;
          end;
          case form of
            1: begin
              unpack_ads(bans_opnd, u);
              if bans_opnd.f1 = 3 then begin
                k := il_$node_ptr_t(bans_opnd.x);
                case k^.kind of
                  198:
                    if bans_opnd.y = 8 then begin
                      u.y := 0;
                      u.x := integer32(smcontk(81, k^.xl[6]));
                    end
                    else
                      u.x := integer32(smcontk(81, k^.xl[4]));
                  90:
                    if bans_opnd.y = 4 then begin
                      u.y := 0;
                      u.x := integer32(smcontk(81, k^.xl[4]));
                    end
                    else
                      u.x := integer32(smcontk(81, k^.xl[3]));
                  89:
                    u.x := integer32(smcontk(81, k^.xl[4]));
                  otherwise
                    ;
                end;
              end;
              p := fnl_slct(0, sz, 0, bans_operand_cir, u);
              if access = 'D' then begin
                after(c, p);
                if bans_opnd.f1 = 3 then begin
                  k := il_$node_ptr_t(bans_opnd.x);
                  case k^.kind of
                    198:
                      if bans_opnd.y = 8 then
                        u.x := integer32(smcontk(81, k^.xl[5]))
                      else
                        u.x := integer32(smcontk(81, k^.xl[3]));
                    89:
                      u.x := integer32(smcontk(81, k^.xl[3]));
                    otherwise
                      ;
                  end;
                end
                else begin
                  p^.ads1.y := p^.ads1.y + 4;
                  p^.size := ilength(p);
                end;
                p := fnl_slct(0, sz, 0, bans_operand_cir, u);
              end;
              after(c, p);
            end;
            2: begin
              unpack_ads(bans_opnd, u);
              bans_imm8.x := integer32(smcontk(81, 8));
              bans_areg.f2 := u.f2;
              q := fnl_slct(2, 4, 0, bans_areg, bans_imm8);
              after(c^.prev, q);
              u.f1 := 2;
              q := fnl_slct(0, sz, 0, bans_operand_cir, u);
              after(c, q);
              u.y := 4;
              q := fnl_slct(0, sz, 0, bans_operand_cir, u);
              after(c^.next, q);
            end;
            3: begin
              unpack_ads(bans_opnd, u);
              p := fnl_slct(0, sz, 0, u, bans_operand_cir);
              if access = 'D' then begin
                after(c, p);
                p^.ads2.y := p^.ads2.y + 4;
                p^.size := ilength(p);
                p := fnl_slct(0, sz, 0, u, bans_operand_cir);
              end;
              after(c, p);
            end;
            4: begin
              unpack_ads(bans_opnd, u);
              bans_imm8.x := integer32(smcontk(81, 8));
              bans_areg.f2 := u.f2;
              q := fnl_slct(2, 4, 0, bans_areg, bans_imm8);
              after(c^.prev, q);
              u.f1 := 2;
              q := fnl_slct(0, sz, 0, u, bans_operand_cir);
              after(c, q);
              u.y := 4;
              q := fnl_slct(0, sz, 0, u, bans_operand_cir);
              after(c^.next, q);
            end;
            otherwise
              ;
          end;
          il_c4 := il_c4 ! 32;
        end;
      end;
      if ((c^.kind = 39) or (c^.kind = 43)) and
         ((last_kind = 41) or (last_kind = 44)) then begin
        ok := true;
        p := c^.prev;
        while p <> prev_c do begin
          if (p^.kind in [0, 2, 24, 32, 33]) or (p^.op = 201) then
            p := p^.prev
          else if p^.ads2.f1 <> 1 then begin
            ok := false;
            exit;
          end
          else
            case p^.op of
              0, 1, 2, 4, 5, 14, 15, 16, 25, 26, 27, 36, 37, 38, 42, 43, 44,
              64, 65, 66, 102, 103, 104:
                if p^.ads1.f1 in [1, 3] then
                  p := p^.prev
                else begin
                  ok := false;
                  exit;
                end;
              19, 20, 21, 28, 29, 30, 39, 40, 41, 45, 46, 47, 67, 68, 69,
              107, 108, 109:
                if (p^.ads1.f1 = 3) and (p^.ads1.f6 = 1) then
                  p := p^.prev
                else begin
                  ok := false;
                  exit;
                end;
              9, 10, 11, 22, 23, 24, 31, 32, 33, 58, 59, 60, 61, 62, 63,
              113, 114, 115:
                p := p^.prev;
              otherwise begin
                ok := false;
                exit;
              end;
            end;
        end;
        if ok then begin
          q := getcodecell(align_instyp);
          q^.op := 460;
          q^.ads1 := null_ads;
          q^.ads2 := null_ads;
          q^.size := ilength(q);
          after(c^.prev, q);
        end;
      end;
      c := c^.next;
    end;
  end;
end;
