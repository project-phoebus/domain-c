{ delay - DELAY, narrowing the IL trees' operations to the register
  widths the m68k needs (shrinking a tree's operations to the narrowest
  class that gives the same result, with conversions spliced in where
  the classes change), the strategies for division and remainder by the
  operands' sizes, signedness and the target, and the set constants
  resized to the set they are used as.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x076658  0x078038  delay_$value_guaranteed_between
    0x0766D8  0x0780B8  delay_$find_size_and_signed
    0x07683C  0x07821C  delay_$divide_table_dimension (in delay_$divide_attributes)
    0x0769AA  0x07838A  delay_$divide_attributes
    0x076ECA  0x0788AA  delay_$tailor_operands_to_hardware
    0x077158  0x078B38  delay_$splice
    0x077250  0x078C30  paramrlen
    0x077558  0x078F38  resize_set (in delay_sets)
    0x0775EC  0x078FCC  delay_sets
    0x07782E  0x07920E  shrink_divide_operand
    0x077946  0x079326  is_indexer (in delay_$propagate_index_long)
    0x077968  0x079348  delay_$propagate_index_long
    0x077A20  0x079400  delay_$shrink_tree_node
    0x078A64  0x07A444  delay
    0x07907E  0x07AA5E  delay_$shrink_top_level_node
    A5 0x1695F0 (cc.m68k), 0x2E9660 (cc.a88k; const_op.ftn's A5 too,
    which has no data): the module's data, 1164 bytes, all
    initialized: +0 div_strategies (13 records of 68 bytes), +888
    class_size (13 words), +920 type_class (12 words), +944 div_table
    (6 x 6 entries of three words); +884, +914..+919 and +1160..+1163
    unused (each table starts on a multiple of 8, docs/rev889-
    patterns.md 50).

  The global routines load A5; paramrlen, delay_sets,
  shrink_divide_operand, delay_$propagate_index_long,
  delay_$shrink_tree_node and delay do not (internal);
  delay_$divide_table_dimension, resize_set and is_indexer are nested
  (is_indexer a leaf without a frame).  delay and
  delay_$shrink_tree_node call each other (delay forward).

  The nodes are read through the unit's dl_node_t.  The register
  classes (rlen) are 1, 2 and 4 bytes of integer, 5 an address, 6 and 7
  single and double reals, 12 the largest; delay(t, want, maxw, doit)
  asks the tree t computed in class want whether it can be done in
  maxw and returns the class it can be done in, and with doit set
  changes it to that class.

  dfetch (kfold.pas) is declared here: delay opens no insert of
  kfold's.  The calls whose result the image does not use (most of
  delay's and delay_sets's) are written discard(...) (reference 4,
  DISCARD): Rev 8.89 compiles them as plain calls.  dpc gaps
  (docs/dpc-gaps.md): 2 (delay_$shrink_top_level_node's case of 4
  labels), 8 (`in' on the node kind and operator sets), 15
  (delay_$splice's result).

  Not known from the original: the names of the module's variables,
  the locals and dl_node_t's; what the division strategies' fields
  mean.
}
module delay;

%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/delay.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';

type
  { A node as this unit reads it. }
  dl_ptr_t = ^dl_node_t;
  dl_node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { A tree node (137 TREE_NODE, 138, 143). }
      1: (phase: add_node_$phase_t;     { +4 }
          w8: integer;                  { +8 }
          regs: integer;                { +10: its class once delayed }
          l12: integer32;               { +12 }
          uses: integer;                { +16 }
          w18: integer;                 { +18 }
          desc: add_node_$desc_t;       { +20 }
          op: integer;                  { +36 }
          count: integer;               { +38 }
          opnd: array [1..64] of il_$node_ptr_t);  { +40 }
      { A reference: 145, 146, 147, 205. }
      2: (rf_phase: add_node_$phase_t;  { +4 }
          rf_unused_8: array [1..4] of integer32;  { +8..+23 }
          base: il_$node_ptr_t;         { +24 }
          sym: il_$node_ptr_t;          { +28 }
          disp: integer32;              { +32 }
          index: il_$node_ptr_t;        { +36 }
          rf_w40: integer;              { +40 }
          len: integer);                { +42: an index's class }
      { An integer constant. }
      3: (ic_next: il_$node_ptr_t;      { +4 }
          int_value: integer32);        { +8 }
      { A set constant (156). }
      4: (sc_unused: array [1..3] of integer32;  { +4 }
          set_len: integer;             { +16 }
          set_words: array [1..2048] of integer);  { +18 }
      { A variable (109): its attributes at +32. }
      5: (va_unused: array [1..7] of integer32;  { +4 }
          vattr: add_node_$phase_t);    { +32 }
      { By offset. }
      9: (xp: array [1..120] of il_$node_ptr_t);    { +4 }
      13: (xw: array [2..240] of integer);          { +4 }
      14: (xc: array [4..479] of char);             { +4 }
  end;

  { A division strategy (68 bytes): 33 words and two flags. }
  dl_strategy_t = record
    w: array [0..32] of integer;        { +0 }
    b66: boolean;                       { +66 }
    b67: boolean;                       { +67 }
  end;

  { An entry of the division table by the operands' dimensions: the
    strategy signed and unsigned, and +4. }
  dl_entry_t = record
    sgn: integer;                       { +0 }
    uns: integer;                       { +2 }
    w4: integer;                        { +4 }
  end;

{ DFETCH - kfold.pas 0x0ACE8C (cc.a88k 0x0AD10C): v as a value of len
  bytes, masked or sign-extended. }
function dfetch(
    v: integer32;
    len: integer;
    sgn: boolean): integer32; options(val_param); extern;

var
  div_strategies: array [1..13] of dl_strategy_t := [
    [[8, 8, 4, 3, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 5, 4, 3, 2, 0, 2, 2, 2,
      2, 3, 2, 2, 2, 2, 5, 4, 8, 23], false, true],
    [[8, 10, 4, 3, 2, 3, 0, 4, 2, 4, 0, 0, 2, 2, 2, 3, 4, 3, 4, 3, 3, 4,
      2, 4, 0, 4, 4, 2, 4, 0, 4, 8, 23], false, true],
    [[8, 8, 4, 2, 2, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 5, 4, 2, 2, 0, 2, 2, 2,
      2, 3, 2, 2, 2, 2, 5, 4, 8, 23], false, true],
    [[8, 10, 4, 2, 2, 3, 0, 4, 4, 4, 0, 0, 2, 2, 2, 3, 4, 2, 4, 3, 3, 4,
      4, 4, 0, 4, 4, 2, 4, 0, 4, 8, 23], false, true],
    [[9, 62, 4, 3, 4, 3, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 4, 3, 4, 3, 7, 4,
      4, 4, 0, 8, 4, 4, 4, 0, 7, 11, 11], true, false],
    [[8, 8, 4, 3, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 5, 4, 3, 2, 0, 2, 2, 2,
      2, 3, 2, 2, 2, 2, 5, 4, 8, 23], false, true],
    [[8, 10, 4, 3, 4, 2, 0, 4, 2, 4, 0, 0, 4, 2, 4, 0, 4, 3, 4, 2, 3, 4,
      2, 4, 0, 4, 4, 2, 4, 0, 5, 9, 25], false, true],
    [[9, 9, 4, 2, 2, 2, 6, 2, 2, 2, 2, 6, 2, 2, 2, 4, 4, 2, 2, 0, 6, 2, 2,
      2, 2, 6, 2, 2, 2, 4, 6, 10, 10], true, false],
    [[8, 10, 4, 2, 4, 2, 0, 4, 4, 4, 0, 0, 4, 4, 4, 0, 4, 2, 4, 2, 3, 4,
      4, 4, 0, 4, 4, 4, 4, 0, 5, 9, 25], false, true],
    [[9, 62, 4, 3, 2, 2, 0, 4, 4, 4, 0, 0, 2, 2, 2, 2, 4, 3, 4, 2, 7, 4,
      4, 4, 0, 8, 4, 2, 4, 0, 6, 10, 10], true, false],
    [[8, 10, 2, 3, 4, 0, 0, 2, 2, 2, 3, 0, 2, 2, 2, 3, 4, 3, 4, 0, 3, 4,
      2, 4, 0, 4, 4, 4, 4, 0, 12, 13, 24], false, true],
    [[9, 62, 4, 2, 4, 3, 0, 4, 2, 4, 0, 0, 4, 4, 4, 0, 4, 2, 4, 0, 7, 4,
      2, 4, 0, 8, 4, 4, 4, 0, 7, 11, 11], true, false],
    [[9, 62, 4, 2, 4, 3, 0, 4, 2, 4, 0, 0, 4, 2, 4, 0, 4, 2, 4, 3, 7, 4,
      2, 4, 0, 8, 4, 2, 4, 0, 7, 11, 11], true, false]];
  { +888: the bytes of a register class. }
  class_size: array [0..12] of integer := [0, 1, 2, 0, 4, 4, 4, 8, 8, 0,
                                           0, 0, 16];
  { +920: the register class of a parameter's type class (paramrlen). }
  type_class: array [0..11] of integer := [1, 2, 4, 5, 6, 7, 11, 1, 2, 4,
                                           4, 4];
  { +944: the division strategies by the divisor's and the dividend's
    dimension (delay_$divide_table_dimension: 0..5). }
  div_table: array [0..5, 0..5] of dl_entry_t := [
    [[1, 1, 0], [4, 13, 0], [2, 2, 0], [4, 13, 0], [4, 4, 0], [5, 5, 0]],
    [[6, 10, 0], [9, 8, 8], [6, 10, 0], [8, 8, 9], [4, 10, 0],
     [10, 10, 0]],
    [[2, 2, 0], [4, 13, 0], [2, 2, 0], [4, 13, 0], [4, 4, 0], [5, 5, 0]],
    [[7, 10, 0], [8, 8, 9], [7, 10, 0], [8, 8, 9], [9, 10, 0],
     [10, 10, 0]],
    [[11, 11, 0], [9, 12, 0], [11, 11, 0], [9, 12, 0], [9, 9, 0],
     [9, 5, 0]],
    [[11, 5, 0], [9, 13, 0], [11, 5, 0], [9, 13, 0], [9, 5, 0],
     [5, 5, 0]]];

{ delay_$value_guaranteed_between - see delay.ins.pas.

  0x076658, 0x66 bytes, link #-4: the constant kinds (the set at
  0x0766BE, 77..87, 101, 200); hi >= value and lo <= value (`sge',
  `sle'; unsigned `scc', `sls'), and-ed; else false.

  Not known from the original:
  - the names. }

function delay_$value_guaranteed_between;
var
  v, ulo, uhi: linteger;
begin
  if n^.kind in [77..87, 101, 200] then
    if sgn then
      delay_$value_guaranteed_between :=
          (hi >= dl_ptr_t(n)^.int_value) and (lo <= dl_ptr_t(n)^.int_value)
    else begin
      v := dl_ptr_t(n)^.int_value;
      ulo := lo;
      uhi := hi;
      delay_$value_guaranteed_between := (uhi >= v) and (ulo <= v);
    end
  else
    delay_$value_guaranteed_between := false;
end;

{ delay_$find_size_and_signed - see delay.ins.pas.

  0x0766D8, 0x158 bytes, link #-4: a constant is its own leaf; 190
  follows +4, 189 +20, 152 +16; a tree (137, 138) is the leaf, and for
  a conversion (18) with narrow the size the least of its source class
  (+26) and size (`bls'), then its operand followed, else size its
  class (+24); 0, 17 (and 18) likewise from its class; sgn its +30 bit
  6 (the descriptor's signed) for those and for the operators in the
  set at 0x076830 (0, 3, 4, 6, 14, 17, 18, 41, 43, 45, 46, 86; of
  0..95 without a range check).

  Not known from the original:
  - the names. }

procedure delay_$find_size_and_signed;
var
  t: dl_ptr_t;
begin
  t := dl_ptr_t(n);
  if t^.kind in [77..87, 101, 200] then
    leaf := n
  else
    case t^.kind of
      190: delay_$find_size_and_signed(t^.xp[1], narrow, leaf, size, sgn);
      189: delay_$find_size_and_signed(t^.xp[5], narrow, leaf, size, sgn);
      152: delay_$find_size_and_signed(t^.xp[4], narrow, leaf, size, sgn);
      138, 137: begin
        leaf := n;
        if t^.op = 18 then begin
          if narrow then begin
            if t^.desc.w6 <= size then
              size := t^.desc.w6;
            delay_$find_size_and_signed(t^.opnd[1], narrow, leaf, size, sgn);
          end
          else
            size := t^.desc.rlen;
          sgn := t^.desc.flags.signed;
        end
        else if (t^.op = 0) or (t^.op = 18) or (t^.op = 17) then begin
          if narrow then begin
            if t^.desc.rlen <= size then
              size := t^.desc.rlen;
            delay_$find_size_and_signed(t^.opnd[1], narrow, leaf, size, sgn);
          end
          else
            size := t^.desc.rlen;
          sgn := t^.desc.flags.signed;
        end
        else begin
          if narrow then begin
            if t^.desc.rlen <= size then
              size := t^.desc.rlen;
          end
          else
            size := t^.desc.rlen;
          if t^.op in [0, 3, 4, 6, 14, 17, 18, 41, 43, 45, 46, 86] then
            sgn := t^.desc.flags.signed;
        end;
      end;
      otherwise ;
    end;
end;

{ delay_$divide_attributes - see delay.ins.pas.

  0x0769AA, 0x4F4 bytes, link #-20: the dividend's and the divisor's
  dimensions (delay_$divide_table_dimension of +40 by +26, of +44 by
  +28); the strategy div_table's signed or unsigned entry (by the
  descriptor's signed; 0 or less is a bug_check), the unsigned one for
  a signed division with +4 set under narrow (the signed flag cleared);
  for the dimensions 0, 2 by 0..3 and a strategy 4 or 2, one less when
  the result is narrow (class 2 or less) for 4, or the dividend is
  within +-32767, the divisor in -32768..-2 or 1..32767; without narrow
  and both operands of class 2 and no cpu 2, 3: 1 or 3.  With cpu 3 (or
  cpu 2 for strategy 8's division) the fields come from the strategy's
  words 0 or 1, 16..19 and 20..24 or 25..29; with target_properties.p_85
  set some are fixed at 4; otherwise words 2..15 and 30..32 (32 for
  the remainder under cargs +0x27C bit 1).  Without narrow, an operand
  of class 4 the strategy narrows looks the table up again at
  dimension 4 or 5 (a `bra' back).  A source class below 4 makes w42 0
  or 1; b54, b58 the strategy's flags; a division by a power of two
  gives w38 1, w18 13 and the shift.

  Not known from the original:
  - the names; what the fields mean. }

procedure delay_$divide_attributes;
label
  10;
var
  dd, dr: integer;                      { D5, D3 }
  k: integer32;                         { D2 }
  v: integer32;
  sh: integer32;

{ delay_$divide_table_dimension - the row or column of div_table for
  the operand n of class size: 0..5 by the class and whether the
  value fits 15 or 16 bits (a constant's), signed or not; with
  -OPT 6 (cargs opt_on 6) size and sgn from delay_$find_size_and_signed
  first.

  0x07683C, 0x13E bytes, link #-16, nested; n kept in a frame longword
  (-8), the size and sgn in frame temporaries; the classes 1, 2, 4,
  else bug_check('delay_$divide_table_entry: bad table lookup%$').

  Not known from the original:
  - the names; what the parameters at +12 and +16 were. }

  function delay_$divide_table_dimension(
      n: il_$node_ptr_t;
      p12: boolean;
      size: integer;
      p16: boolean;
      sgn: boolean): integer; options(val_param);
  var
    leaf: il_$node_ptr_t;               { -8 }
    sz: integer;                        { -10 }
    sg: boolean;                        { -14 }
  begin
    leaf := n;
    sz := size;
    sg := sgn;
    if 6 in cargs_$options.opt_on then
      delay_$find_size_and_signed(n, true, leaf, sz, sg);
    case sz of
      1:
        if sg then
          delay_$divide_table_dimension := 2
        else
          delay_$divide_table_dimension := 1;
      2:
        if delay_$value_guaranteed_between(leaf, 0, 32767, false) then
          if sg then
            delay_$divide_table_dimension := 0
          else
            delay_$divide_table_dimension := 1
        else if sg then
          delay_$divide_table_dimension := 2
        else
          delay_$divide_table_dimension := 3;
      4:
        if delay_$value_guaranteed_between(leaf, 0, 32767, false) then
          if sg then
            delay_$divide_table_dimension := 0
          else
            delay_$divide_table_dimension := 1
        else if delay_$value_guaranteed_between(leaf, -32768, 32767, true)
        then
          delay_$divide_table_dimension := 2
        else if delay_$value_guaranteed_between(leaf, 0, 65535, false) then
          delay_$divide_table_dimension := 3
        else if sg then
          delay_$divide_table_dimension := 4
        else
          delay_$divide_table_dimension := 5;
      otherwise
        bug_check('delay_$divide_table_entry: bad table lookup%$');
    end;
  end;

begin { delay_$divide_attributes }
  dd := delay_$divide_table_dimension(dl_ptr_t(n)^.opnd[1], narrow,
                                      dl_ptr_t(n)^.desc.w6, false,
                                      dl_ptr_t(n)^.desc.flags.signed);
  dr := delay_$divide_table_dimension(dl_ptr_t(n)^.opnd[2], narrow,
                                      dl_ptr_t(n)^.desc.w8, true,
                                      dl_ptr_t(n)^.desc.flags.signed);
10:
  with dl_ptr_t(n)^ do begin
    if desc.flags.signed then
      k := div_table[dr, dd].sgn
    else
      k := div_table[dr, dd].uns;
    if k <= 0 then
      bug_check('delay_$divide_attributes: bad table lookup%$');
    if (div_table[dr, dd].w4 > 0) and desc.flags.signed and narrow then begin
      desc.flags.signed := false;
      k := div_table[dr, dd].uns;
    end;
    if (dr in [0, 2]) and (dd in [0..3]) and ((k = 4) or (k = 2)) then
      if (desc.rlen <= 2) and (op = 4) then
        k := k - 1
      else if delay_$value_guaranteed_between(opnd[1], -32767, 32767, true)
      then
        k := k - 1
      else if delay_$value_guaranteed_between(opnd[2], -32768, -2, true) then
        k := k - 1
      else if delay_$value_guaranteed_between(opnd[2], 1, 32767, true) then
        k := k - 1;
    if not narrow and (desc.w6 = 2) and (desc.w8 = 2) and
       (cargs_$options.cpu * [2, 3] = []) then
      if desc.flags.signed then
        k := 1
      else
        k := 3;
    with div_strategies[k] do
      if (3 in cargs_$options.cpu) or
         ((w[0] = 8) and (2 in cargs_$options.cpu) and (op = 4)) then begin
        if op = 4 then begin
          w18 := w[0];
          w38 := w[20];
          w42 := w[24];
          w62 := w[21];
          w66 := w[22];
          w70 := w[23];
        end
        else begin
          w18 := w[1];
          w38 := w[25];
          w42 := w[29];
          w62 := w[26];
          w66 := w[27];
          w70 := w[28];
        end;
        lsize := w[16];
        w26 := w[17];
        rsize := w[18];
        w34 := w[19];
      end
      else if target_properties.p_85 >= chr(128) then begin
        if op = 4 then begin
          w66 := w[22];
          w70 := w[23];
        end
        else begin
          w66 := w[27];
          w70 := w[28];
        end;
        lsize := 4;
        w26 := w[17];
        rsize := 4;
        w34 := w[19];
        w62 := 4;
        w42 := w[29];
      end
      else begin
        if op = 4 then begin
          w18 := w[0];
          w38 := w[6];
          w46 := w[30];
          w42 := w[10];
          w62 := w[7];
          w66 := w[8];
          w70 := w[9];
        end
        else begin
          w18 := w[1];
          w38 := w[11];
          w46 := w[31];
          if cargs_$options.b27c_1 then
            w46 := w[32];
          w42 := w[15];
          w62 := w[12];
          w66 := w[13];
          w70 := w[14];
        end;
        lsize := w[2];
        w26 := w[3];
        rsize := w[4];
        w34 := w[5];
      end;
    if not narrow then begin
      if (desc.w6 = 4) and (lsize < 4) then
        case dd of
          0, 2: begin
            dd := 4;
            goto 10;
          end;
          1, 3: begin
            dd := 5;
            goto 10;
          end;
          4, 5: bug_check('delay_$divide_attributes: bad table lookup%$');
          otherwise ;
        end;
      if (desc.w8 = 4) and (rsize < 4) then
        case dr of
          0, 2: begin
            dr := 4;
            goto 10;
          end;
          1, 3: begin
            dr := 5;
            goto 10;
          end;
          4, 5: bug_check('delay_$divide_attributes: bad table lookup%$');
          otherwise ;
        end;
    end;
    if desc.w6 < 4 then
      case w42 of
        2, 3: w42 := 0;
        4, 5: w42 := 1;
        otherwise ;
      end;
    b54 := div_strategies[k].b66;
    b58 := div_strategies[k].b67;
    strategy := k;
    if op = 4 then
      if opnd[2]^.kind in [77..87, 101, 200] then begin
        v := dl_ptr_t(opnd[2])^.int_value;
        if v > 0 then
          if ((v - 1) & v) = 0 then begin
            sh := 0;
            v := rshft(v, 1);
            while v <> 0 do begin
              sh := sh + 1;
              v := rshft(v, 1);
            end;
            w38 := 1;
            w18 := 13;
            shift := sh;
          end;
      end;
  end;
end;

{ delay_$tailor_operands_to_hardware - see delay.ins.pas.

  0x076ECA, 0x258 bytes, link #-52: 6 and 4 (remainder, division):
  delay_$divide_attributes(n, true, ...) into frame variables, then
  each operand that is a conversion (or 0, 17) made a conversion (18)
  to lsize and rsize (its +20, +24) and the source classes +26, +28
  set; the result w66.  3 (multiplication): the greater of the
  operands' classes (`bhi'; 4 under target_properties.p_85), each
  narrower operand of those operators widened to it; the result 4.  18:
  of a division or remainder w70, of a multiplication its tailoring,
  set as the conversion's source class and its operand's class and
  size; the result that class.  Others: bug_check.

  Not known from the original:
  - the names; the result for a conversion of something else than a
    tree (what is left in D0). }

function delay_$tailor_operands_to_hardware;
var
  t, o: dl_ptr_t;
  strategy: integer32;                  { -4 }
  w18: integer;                         { -32 }
  lsize: integer32;                     { -16 }
  w26: integer;                         { -28 }
  rsize: integer32;                     { -8 }
  w34, w38, w42, w46: integer;          { -26, -36, -24, -34 }
  shift: integer32;                     { -12 }
  b54, b58: boolean;                    { -42, -40 }
  w62, w66, w70: integer;               { -30, -20, -18 }
  w: integer;
begin
  t := dl_ptr_t(n);
  case t^.op of
    6, 4: begin
      delay_$divide_attributes(n, true, strategy, w18, lsize, w26, rsize,
                               w34, w38, w42, w46, shift, b54, b58, w62,
                               w66, w70);
      o := dl_ptr_t(t^.opnd[1]);
      if o^.kind = 137 then
        if (o^.op = 0) or (o^.op = 18) or (o^.op = 17) then begin
          o^.desc.size := lsize;
          o^.desc.rlen := lsize;
          o^.op := 18;
          t^.desc.w6 := lsize;
        end;
      o := dl_ptr_t(t^.opnd[2]);
      if o^.kind = 137 then
        if (o^.op = 0) or (o^.op = 18) or (o^.op = 17) then begin
          o^.desc.size := rsize;
          o^.desc.rlen := rsize;
          o^.op := 18;
          t^.desc.w8 := rsize;
        end;
      delay_$tailor_operands_to_hardware := w66;
    end;
    3: begin
      w := t^.desc.w6;
      if w <= t^.desc.w8 then
        w := t^.desc.w8;
      if target_properties.p_85 >= chr(128) then
        w := 4;
      o := dl_ptr_t(t^.opnd[1]);
      if w > t^.desc.w6 then
        if o^.kind = 137 then
          if (o^.op = 0) or (o^.op = 18) or (o^.op = 17) then begin
            o^.desc.size := w;
            o^.desc.rlen := w;
            o^.op := 18;
            t^.desc.w6 := w;
          end;
      o := dl_ptr_t(t^.opnd[2]);
      if t^.desc.w8 < w then
        if o^.kind = 137 then
          if (o^.op = 0) or (o^.op = 18) or (o^.op = 17) then begin
            o^.desc.size := w;
            o^.desc.rlen := w;
            o^.op := 18;
            t^.desc.w8 := w;
          end;
      delay_$tailor_operands_to_hardware := 4;
    end;
    18: begin
      o := dl_ptr_t(t^.opnd[1]);
      if o^.kind = 137 then begin
        if (o^.op = 6) or (o^.op = 4) then begin
          delay_$divide_attributes(il_$node_ptr_t(o), true, strategy, w18,
                                   lsize, w26, rsize, w34, w38, w42, w46,
                                   shift, b54, b58, w62, w66, w70);
          w := w70;
        end
        else if o^.op = 3 then
          w := delay_$tailor_operands_to_hardware(il_$node_ptr_t(o))
        else
          bug_check('delay_$tailor_operand_to_hardware: bad tree node op%$');
        t^.desc.w6 := w;
        o^.desc.rlen := w;
        o^.desc.size := w;
        delay_$tailor_operands_to_hardware := w;
      end;
    end;
    otherwise
      bug_check('delay_$tailor_operand_to_hardware: bad tree node op%$');
  end;
end;

{ delay_$splice - see delay.ins.pas.

  0x077158, 0xDE bytes, link #-8: a tree (138, 137) gives sgn and
  srcsize from its descriptor; unless force, n when srcsize = size;
  gspace(44): 137, operator 18, +24 size, +26 srcsize, +28 cleared, +30
  bit 6 sgn, +20 class_size[size], +10 size, +16 cleared, +38 1, +40 n;
  the phase n's without 5 and 8 (`andi.w #0xFEDF') for the nodes with
  one, else cleared.

  Not known from the original:
  - the names. }

function delay_$splice;
var
  x: dl_ptr_t;
begin
  if (n^.kind = 138) or (n^.kind = 137) then begin
    sgn := dl_ptr_t(n)^.desc.flags.signed;
    srcsize := dl_ptr_t(n)^.desc.rlen;
  end;
  if not force and (size = srcsize) then begin
    delay_$splice := n;
    return;
  end;
  x := gspace(44);
  x^.kind := 137;
  x^.op := 18;
  x^.desc.rlen := size;
  x^.desc.w6 := srcsize;
  x^.desc.w8 := 0;
  x^.desc.flags.signed := sgn;
  x^.desc.size := class_size[size];
  x^.regs := size;
  x^.uses := 0;
  x^.count := 1;
  x^.opnd[1] := n;
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    x^.phase := dl_ptr_t(n)^.phase - [5, 8]
  else
    x^.phase := [];
  delay_$splice := il_$node_ptr_t(x);
end;

{ paramrlen - the register class argument i of the call n is passed
  in; sg cleared for an unsigned parameter of a routine of calling
  convention 1 or 6.

  0x077250, 0x308 bytes, link #-44, no A5: the routine called (+40,
  through a reference's +28 or a 175's +20); a 171 CC_CALL: a tree
  argument its class, a reference 0, a double 7, else by the call's
  word for it (+12 + 4i, rounded up to even: 2, 4, 8 give 2, 4, 7, else
  11).  Otherwise, from the last argument down to i: arguments beyond
  the count less the source class (+26) are type class 8; by the
  routine: a 159 LIB_DSC its parameter types (+11 + 2k, low nibble; the
  count +10), 167, 108, 107 their +392 + 2j (+390 + 2j for class 9 and
  11 for argument 2) unless convention 4, 174, 173 their +76 + 2j; else
  by the argument's kind (86, 87, 200 7; 80, 83 8; 82, 85 9; 81 8 for
  convention 4 or -I*2, else 9; a tree its own class); type_class of
  that, 5 for a real class unless the argument is a dereference (146).
  A routine of convention 1 or 6 with fewer parameters (+293) gives the
  count; with enough, the i-th parameter's +46 bit 7 clears sg.

  Not known from the original:
  - the names; what the classes and the routine's fields are. }

function paramrlen(
    n: il_$node_ptr_t;
    i: integer;
    var sg: boolean): integer; options(val_param); internal;
var
  f: dl_ptr_t;                          { A1 }
  o: dl_ptr_t;                          { A0 }
  c: integer;                           { D3 }
  r: integer;
  w: integer;
  m: integer;                           { D0 }
  j, k, cnt, q: integer;
  p: dl_ptr_t;
begin
  sg := true;
  f := dl_ptr_t(dl_ptr_t(n)^.opnd[1]);
  c := dl_ptr_t(n)^.count;
  case f^.kind of
    205, 147, 146: f := dl_ptr_t(f^.sym);
    171, 108, 107: ;
    175: f := dl_ptr_t(f^.xp[5]);
    otherwise ;
  end;
  if f^.kind = 171 then begin
    o := dl_ptr_t(dl_ptr_t(n)^.opnd[i]);
    case o^.kind of
      143, 137: paramrlen := o^.desc.rlen;
      145, 205, 147, 146: paramrlen := 0;
      89: paramrlen := 7;
      otherwise begin
        w := f^.xw[6 + 2 * i];
        if odd(w) then
          w := w + 1;
        if w = 2 then
          paramrlen := 2
        else if w = 4 then
          paramrlen := 4
        else if w = 8 then
          paramrlen := 7
        else
          paramrlen := 11;
      end;
    end;
    return;
  end;
  if f^.kind = 159 then begin
    if c - 1 > f^.xw[5] then
      m := f^.xw[5]
    else
      m := c - 1;
  end
  else if (f^.kind = 108) or (f^.kind = 107) then
    if (rshft(ord(f^.xc[377]) & 16#70, 4) = 1) or
       (rshft(ord(f^.xc[377]) & 16#70, 4) = 6) then
      if ord(f^.xc[293]) >= i - 1 then begin
        p := dl_ptr_t(f^.xp[3]);
        for q := 3 to i do
          p := dl_ptr_t(p^.xp[1]);
        if ord(p^.xc[46]) >= 128 then
          sg := false;
      end
      else
        c := ord(f^.xc[293]) + 1;
  r := c;
  j := c;
  for cnt := 0 to c - i do begin
    o := dl_ptr_t(dl_ptr_t(n)^.opnd[j]);
    if r - dl_ptr_t(n)^.desc.w6 < j then
      k := 8
    else
      case f^.kind of
        159: begin
          if m < j - 1 then
            if ord(f^.xc[10 + 2 * m]) < 128 then
              m := f^.xw[5];
          k := ord(f^.xc[11 + 2 * m]) & 15;
          m := m - 1;
        end;
        167, 108, 107:
          if rshft(ord(f^.xc[377]) & 16#70, 4) = 4 then
            k := -1
          else if dl_ptr_t(n)^.desc.rlen = 9 then
            if j = 2 then
              k := 11
            else
              k := f^.xw[195 + j]
          else
            k := f^.xw[196 + j];
        174, 173: k := f^.xw[38 + j];
        otherwise
          k := -1;
      end;
    if k = -1 then
      case o^.kind of
        86, 87, 200: k := 7;
        80, 83: k := 8;
        82, 85: k := 9;
        81:
          if ((f^.kind = 107) or (f^.kind = 167) or (f^.kind = 108)) and
             (rshft(ord(f^.xc[377]) & 16#70, 4) = 4) then
            k := 8
          else if cargs_$options.i_star_2 then
            k := 8
          else
            k := 9;
        137: k := -2;
        otherwise
          k := 9;
      end;
    if k = -2 then begin
      c := o^.desc.rlen;
      if c >= 6 then
        c := 5;
    end
    else begin
      c := type_class[k];
      if (k >= 6) and (o^.kind <> 146) and (c >= 6) then
        c := 5;
    end;
    j := j - 1;
  end;
  paramrlen := c;
end;

{ delay_sets - the bytes the set expression t (by address) can be done
  in, of want bytes, wanted n: a set constant (156) n (resized to n
  under doit); a variable (109 whose +35 bit 0 is clear), a
  displacement (147 without phase 1) or a dereference (146 without 1,
  2) narrower n (add_dn of want - n under doit, from its +28 for a 147);
  the set operators (19..22, 72, 73: the set at 0x077824, of 0..79) of
  operands that can be: 72, 73 the first operand's (the size n and +30
  bit 2 set when narrower, also without doit), 22 n, 19..21 both
  operands'; else want.

  0x0775EC, 0x238 bytes, link #-16, no A5: the use counts adjusted
  around each replacement (adjust_uc -1, +1); the result in D0.

  Not known from the original:
  - the names. }

function delay_sets(
    var t: il_$node_ptr_t;
    want: integer32;
    n: integer32;
    doit: boolean): integer32; options(val_param); internal;
var
  res: integer32;                       { D5 }
  x: dl_ptr_t;
  sz: integer32;                        { -8 }
  ok: boolean;

{ resize_set - the set constant s as n bytes: its last n bytes when
  longer; else its words placed in a cleared 128-byte set (the image
  stores every word at one index, the address hoisted out of the loop,
  `move.w (16,A2,D5.l),(A0)') and its last n bytes.

  0x077558, 0x94 bytes, link #-156, nested; setcontk's node in A0.

  Not known from the original:
  - the names; whether the index was meant to advance. }

  function resize_set(
      s: il_$node_ptr_t;
      n: integer32): il_$node_ptr_t; options(val_param);
  var
    words: array [1..64] of integer;    { -136 }
    i, j: integer32;
  begin
    if dl_ptr_t(s)^.set_len > n then
      resize_set := setcontk(dl_ptr_t(s)^.set_words,
                             dl_ptr_t(s)^.set_len - n, n)
    else begin
      for i := 1 to 64 do
        words[i] := 0;
      j := rshft(128 - dl_ptr_t(s)^.set_len, 1) + 1;
      for i := 1 to rshft(dl_ptr_t(s)^.set_len, 1) do
        words[j] := dl_ptr_t(s)^.set_words[i];
      resize_set := setcontk(words, 128 - n, n);
    end;
  end;

begin { delay_sets }
  res := want;
  x := dl_ptr_t(t);
  if x^.kind = 156 then begin
    res := n;
    if doit then
      if x^.set_len <> n then begin
        il_utils_$adjust_uc(t, -1);
        t := resize_set(t, n);
        il_utils_$adjust_uc(t, 1);
      end;
  end
  else if (n < want) and
          ((x^.kind = 109) or (x^.kind = 147) or (x^.kind = 146)) then begin
    if x^.kind = 109 then
      ok := not (0 in x^.vattr)
    else if x^.kind = 147 then
      ok := not (1 in x^.rf_phase)
    else
      ok := not (1 in x^.rf_phase) and not (2 in x^.rf_phase);
    if ok then begin
      res := n;
      if doit then begin
        il_utils_$adjust_uc(t, -1);
        if t^.kind <> 147 then
          t := add_dn(t, t, want - n)
        else
          t := add_dn(t, dl_ptr_t(t)^.sym, want - n);
        il_utils_$adjust_uc(t, 1);
      end;
    end;
  end
  else if x^.kind = 137 then
    if x^.op in [19..22, 72, 73] then begin
      sz := x^.desc.size;
      case x^.op of
        73, 72:
          if delay_sets(x^.opnd[1], sz, n, false) = n then begin
            res := n;
            if doit then
              discard(delay_sets(dl_ptr_t(t)^.opnd[1], sz, n, true));
            dl_ptr_t(t)^.desc.size := n;
            if n < want then
              dl_ptr_t(t)^.desc.flags.b2 := true;
          end;
        22: begin
          res := n;
          if doit then
            x^.desc.size := n;
        end;
        20, 19, 21:
          if delay_sets(x^.opnd[1], sz, n, false) = n then
            if delay_sets(x^.opnd[2], sz, n, false) = n then begin
              res := n;
              if doit then begin
                discard(delay_sets(dl_ptr_t(t)^.opnd[1], sz, n, true));
                discard(delay_sets(dl_ptr_t(t)^.opnd[2], sz, n, true));
                dl_ptr_t(t)^.desc.size := n;
              end;
            end;
        otherwise ;
      end;
    end;
  delay_sets := res;
end;

function delay(
    var t: il_$node_ptr_t;
    want: integer;
    maxw: integer;
    doit: boolean): integer; options(val_param); internal; forward;

{ shrink_divide_operand - delay the operand o (by address) of the
  division n, of class w (by address), to size: the class
  delay_$find_size_and_signed finds; under doit a conversion to size
  spliced in (forced) unless o already is one that can be widened, and
  w set to size.  Nothing for a shared tree.

  0x07782E, 0x118 bytes, link #-20, no A5: the leaf, size and sign in
  frame variables (-12, -16, -18; narrow the constant true at
  0x07697A).

  Not known from the original:
  - the names. }

procedure shrink_divide_operand(
    n: il_$node_ptr_t;
    var o: il_$node_ptr_t;
    var w: integer;
    size: integer;
    doit: boolean); options(val_param); internal;
var
  leaf: il_$node_ptr_t;                 { -12 }
  sz: integer;                          { -16 }
  sg: boolean;                          { -18 }
  m: integer;
  r: integer;                           { D4 }
begin
  if o^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if dl_ptr_t(o)^.uses > 1 then
      return;
  sz := w;
  sg := dl_ptr_t(n)^.desc.flags.signed;
  delay_$find_size_and_signed(o, true, leaf, sz, sg);
  r := sz;
  m := size;
  if m > w then
    m := w;
  if m > r then
    m := r;
  r := delay(o, w, m, doit);
  if not doit then
    return;
  if (r = w) and (size = r) and (o^.kind = 137) then
    return;
  if (o^.kind = 137) and (dl_ptr_t(o)^.op = 18) and
     (dl_ptr_t(o)^.desc.w6 <= dl_ptr_t(o)^.desc.rlen) and
     (dl_ptr_t(o)^.desc.w6 <= size) then begin
    dl_ptr_t(o)^.desc.rlen := size;
    dl_ptr_t(o)^.desc.size := size;
  end
  else begin
    il_utils_$adjust_uc(o, -1);
    o := delay_$splice(o, size, sg, r, true);
    il_utils_$adjust_uc(o, 1);
  end;
  w := size;
end;

{ delay_$propagate_index_long - mark the indexed references below the
  index n (145, or an address sum 13) long (+6 bit 0, phase 8) when n
  is: its base and index, or a sum's operands.

  0x077968, 0xB8 bytes, link #-8, no A5.

  Not known from the original:
  - the names. }

procedure delay_$propagate_index_long(
    n: il_$node_ptr_t); options(val_param); internal;
var
  i: integer;

{ is_indexer - whether n is an indexed reference (145) or an address
  sum (137, operator 13).

  0x077946, 0x22 bytes, nested, no frame (n at (4,SP), the result in
  D0, `st'). }

  function is_indexer(
      n: il_$node_ptr_t): boolean; options(val_param);
  begin
    is_indexer := (n^.kind = 145) or
                  ((n^.kind = 137) and (dl_ptr_t(n)^.op = 13));
  end;

begin { delay_$propagate_index_long }
  if is_indexer(n) then
    if 8 in getphase(n) then
      if n^.kind = 145 then begin
        if is_indexer(dl_ptr_t(n)^.base) then
          dl_ptr_t(dl_ptr_t(n)^.base)^.phase :=
              dl_ptr_t(dl_ptr_t(n)^.base)^.phase + [8];
        if is_indexer(dl_ptr_t(n)^.index) then
          dl_ptr_t(dl_ptr_t(n)^.index)^.phase :=
              dl_ptr_t(dl_ptr_t(n)^.index)^.phase + [8];
      end
      else if n^.kind = 137 then
        if dl_ptr_t(n)^.op = 13 then
          for i := 1 to dl_ptr_t(n)^.count do
            if is_indexer(dl_ptr_t(n)^.opnd[i]) then
              dl_ptr_t(dl_ptr_t(n)^.opnd[i])^.phase :=
                  dl_ptr_t(dl_ptr_t(n)^.opnd[i])^.phase + [8];
end;

{ delay_$shrink_tree_node - delay for a tree node: the class the
  operator over t (by address) can be done in when want is wanted and
  maxw allowed, the operands delayed, and under doit the tree changed.
  A class above 4 is taken as the tree's own (+24) for want and maxw
  of 5.  By operator (a jump table over 0..73):
  - 1, 2, 9, 10, 44: both operands at the tree's class and maxw; when
    they differ maxw widens (1 to 2 to 4) up to the class; under doit
    each operand delayed and converted (delay_$splice) to the second's
    class, the tree's class and size that;
  - 12 (comparison): of two bit fields at byte offsets, or a field and
    a constant in its range, the operands at class 1; else at the
    source class;
  - 27, 49 (shifts left): the first operand at maxw (5 as 4), the count
    at that class or its own, the tree's classes the result;
  - 28, 50 (shifts right): a logical shift of a zero-extended operand
    narrowed while the operand fits, the count as for 27;
  - 18 (conversion): the operand at the narrower class, the conversion
    dropped when it is not needed;
  - 15, 16 (calls): each argument at paramrlen's class; a function's
    result narrowed to maxw;
  - 0, 7, 8, 63, 17, 29, 26, 13, 3, 4, 6, 43, 72, 73, 19..21, 23..25,
    11, 14, 39, 22, 42, 40, 34..38, 41, 45, 46, 48: their operands (4,
    6 by delay_$divide_attributes and shrink_divide_operand; 43 the
    power; 14 a bit offset in bytes; 22 the sets);
  - others nothing.
  The result in D0 (a frame word kept in D6).

  0x077A20, 0x102A bytes, link #-84, no A5: the frame variables of
  delay_$divide_attributes at -8..-66; delay's calls push doit as the
  caller's or a constant.

  Not known from the original:
  - the names; the operator codes' meaning (kfold.pas folds the same
    ones). }

function delay_$shrink_tree_node(
    var t: il_$node_ptr_t;
    want: integer;
    maxw: integer;
    doit: boolean): integer; options(val_param); internal;
label
  10, 30, 99;
var
  n: dl_ptr_t;                          { A2 }
  res: integer;                         { D6 }
  a, b: integer;                        { D4, D3 }
  i, w, x: integer;
  v: integer32;
  sg: boolean;                          { -70 }
  o: dl_ptr_t;
  strategy: integer32;                  { -8 }
  w18: integer;                         { -46 }
  lsize: integer32;                     { -20 }
  w26: integer;                         { -44 }
  rsize: integer32;                     { -12 }
  w34, w38, w42, w46: integer;          { -42, -50, -40, -48 }
  shift: integer32;                     { -16 }
  b54, b58: boolean;                    { -66, -64 }
  w62, w66, w70: integer;               { -38, -36, -34 }
begin
  n := dl_ptr_t(t);
  res := n^.desc.rlen;
  if res <= 4 then begin
    if want = 5 then
      want := res;
    if maxw = 5 then
      maxw := res;
  end;
  case n^.op of
    1, 2, 9, 10, 44: begin
10:
      a := delay(n^.opnd[1], n^.desc.rlen, maxw, false);
      b := delay(n^.opnd[2], n^.desc.rlen, maxw, false);
      if a <> b then begin
        if maxw >= n^.desc.rlen then begin
          for i := 1 to n^.count do
            discard(delay(n^.opnd[i], n^.desc.rlen, n^.desc.rlen, doit));
          goto 99;
        end;
        if maxw = 1 then
          maxw := 2
        else if maxw = 2 then
          maxw := 4
        else begin
          for i := 1 to n^.count do
            discard(delay(n^.opnd[i], n^.desc.rlen, n^.desc.rlen, doit));
          goto 99;
        end;
        if maxw <= n^.desc.rlen then
          goto 10;
      end
      else if a > n^.desc.rlen then begin
        for i := 1 to n^.count do
          discard(delay(n^.opnd[i], n^.desc.rlen, n^.desc.rlen, doit));
        goto 99;
      end;
      res := a;
      if not doit then
        goto 99;
      for i := 1 to 2 do begin
        x := delay(n^.opnd[i], n^.desc.rlen, maxw, true);
        if x <> b then begin
          il_utils_$adjust_uc(n^.opnd[i], -1);
          n^.opnd[i] := delay_$splice(n^.opnd[i], b,
                            dl_ptr_t(n^.opnd[i])^.desc.flags.signed,
                            dl_ptr_t(n^.opnd[i])^.desc.rlen, false);
          il_utils_$adjust_uc(n^.opnd[i], 1);
        end;
      end;
      n^.desc.rlen := b;
      n^.desc.size := class_size[n^.desc.rlen];
      res := b;
    end;
    12: begin
      o := dl_ptr_t(n^.opnd[1]);
      if (o^.kind = 137) and (o^.op = 14) and
         (o^.opnd[2]^.kind in [77..87, 101, 200]) then
        if (dl_ptr_t(o^.opnd[2])^.int_value mod 8 = 0) and
           (o^.desc.w8 = 8) and
           ((o^.desc.flags.signed = ((n^.desc.w8 >= 0) and
                                     (n^.desc.w8 <= 31) and
                                     (n^.desc.w8 in [10..15]))) or
            (n^.desc.w8 = 7) or (n^.desc.w8 = 6)) then
          if delay(n^.opnd[1], n^.desc.w6, 1, false) = 1 then begin
            o := dl_ptr_t(n^.opnd[2]);
            if (o^.kind = 137) and (o^.op = 14) and
               (o^.opnd[2]^.kind in [77..87, 101, 200]) and
               (dl_ptr_t(o^.opnd[2])^.int_value mod 8 = 0) and
               (o^.desc.w8 = 8) and
               (o^.desc.flags.signed =
                dl_ptr_t(n^.opnd[1])^.desc.flags.signed) then begin
              if delay(n^.opnd[1], n^.desc.w6, 1, false) = 1 then
                if doit then begin
                  discard(delay(n^.opnd[1], n^.desc.w6, 1, true));
                  n^.desc.w6 := delay(n^.opnd[2], n^.desc.w6, 1, true);
                  goto 99;
                end;
            end
            else if o^.kind in [77..87, 101, 200] then
              if dl_ptr_t(n^.opnd[1])^.desc.flags.signed then begin
                if (o^.int_value >= -128) and (o^.int_value <= 127) then
                begin
                  n^.desc.w6 := delay(n^.opnd[1], n^.desc.w6, 1, true);
                  goto 99;
                end;
              end
              else if (o^.int_value >= 0) and (o^.int_value <= 255) then
              begin
                n^.desc.w6 := delay(n^.opnd[1], n^.desc.w6, 1, true);
                goto 99;
              end;
          end;
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, true));
      discard(delay(n^.opnd[2], n^.desc.w6, n^.desc.w6, true));
    end;
    27, 49: begin
      x := maxw;
      if maxw = 5 then
        x := 4;
      x := delay(n^.opnd[1], n^.desc.rlen, x, doit);
      if x = 5 then
        x := 4;
      if n^.opnd[2]^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
        if doit then
          n^.desc.w8 := delay(n^.opnd[2], x, x, true)
        else
          discard(delay(n^.opnd[2], x, x, false))
      else
        discard(delay(n^.opnd[2], n^.desc.w8, n^.desc.w8, doit));
      res := x;
      if doit then begin
        n^.desc.rlen := x;
        n^.desc.w6 := x;
        n^.desc.size := x;
      end;
    end;
    28, 50: begin
      repeat
        x := delay(n^.opnd[1], n^.desc.rlen, maxw, false);
        o := dl_ptr_t(n^.opnd[1]);
        if (x >= maxw) and (x < n^.desc.rlen) and (n^.op = 28) and
           (o^.kind = 137) and (o^.op = 18) and (x >= o^.desc.w6) and
           not o^.desc.flags.signed then begin
          res := x;
          if doit then begin
            x := delay(n^.opnd[1], n^.desc.rlen, maxw, true);
            n^.desc.rlen := x;
            n^.desc.w6 := x;
          end;
          goto 30;
        end;
        maxw := maxw * 2;
      until maxw >= n^.desc.rlen;
      if doit then
        n^.desc.w6 := delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, doit);
30:
      if n^.opnd[2]^.kind in [77..90, 92, 93, 101, 156, 176, 198, 200] then
        if doit then
          n^.desc.w8 := delay(n^.opnd[2], n^.desc.w6, n^.desc.w6, true)
        else
          discard(delay(n^.opnd[2], n^.desc.w6, n^.desc.w6, false))
      else
        discard(delay(n^.opnd[2], n^.desc.w8, n^.desc.w8, doit));
    end;
    18: begin
      if n^.desc.rlen < n^.desc.w6 then
        b := n^.desc.rlen
      else if maxw < n^.desc.w6 then
        b := maxw
      else begin
        b := n^.desc.w6;
        if b = 5 then
          b := 4;
      end;
      x := delay(n^.opnd[1], n^.desc.w6, b, false);
      res := maxw;
      if not doit then
        goto 99;
      if maxw = 5 then
        maxw := 4;
      if maxw = x then begin
        il_utils_$adjust_uc(t, -1);
        t := n^.opnd[1];
        il_utils_$adjust_uc(t, 1);
        res := delay(t, n^.desc.w6, b, true);
      end
      else begin
        n^.desc.w6 := delay(n^.opnd[1], n^.desc.w6, b, true);
        if maxw <> n^.desc.w6 then begin
          n^.desc.rlen := maxw;
          n^.desc.size := maxw;
        end;
      end;
    end;
    15, 16: begin
      for i := 2 to n^.count do begin
        w := paramrlen(t, i, sg);
        o := dl_ptr_t(n^.opnd[i]);
        if o^.kind = 137 then begin
          w := o^.desc.rlen;
          sg := true;
          if o^.op = 63 then
            o^.desc.w8 := 1;
        end
        else if (o^.kind = 146) or (o^.kind = 205) or (o^.kind = 147) or
                (o^.kind = 145) then
          if not sg then begin
            w := 5;
            sg := true;
          end;
        discard(delay(n^.opnd[i], w, w, doit and sg));
      end;
      if n^.op = 16 then begin
        res := n^.desc.rlen;
        if (maxw < res) and (res <= 4) then begin
          res := maxw;
          if doit then
            n^.desc.rlen := maxw;
        end;
      end
      else
        res := 0;
    end;
    17, 29: begin
      discard(delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, doit));
      res := want;
    end;
    0, 7, 8: begin
      x := delay(n^.opnd[1], n^.desc.rlen, maxw, false);
      if doit then
        if maxw = x then begin
          x := delay(n^.opnd[1], n^.desc.rlen, maxw, doit);
          n^.desc.rlen := x;
          n^.desc.size := x;
        end
        else
          x := delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, doit);
      res := x;
    end;
    63:
      if (target_properties.p_84 >= chr(128)) or (n^.desc.w8 = 0) then begin
        il_utils_$adjust_uc(il_$node_ptr_t(n), -1);
        t := n^.opnd[1];
        il_utils_$adjust_uc(t, 1);
        res := delay(t, n^.desc.rlen, n^.desc.rlen, doit);
      end
      else begin
        x := delay(n^.opnd[1], n^.desc.rlen, maxw, false);
        if doit then
          if maxw = x then begin
            x := delay(n^.opnd[1], n^.desc.rlen, maxw, doit);
            n^.desc.rlen := x;
            n^.desc.size := x;
          end
          else
            x := delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, doit);
        res := x;
      end;
    26: begin
      w := n^.desc.rlen;
      o := dl_ptr_t(n^.opnd[1]);
      if (o^.kind = 143) or (o^.kind = 137) then begin
        w := o^.desc.rlen;
        if o^.op = 63 then
          o^.desc.w8 := 1;
      end;
      discard(delay(n^.opnd[1], w, w, doit));
      res := want;
    end;
    13: begin
      delay_$propagate_index_long(il_$node_ptr_t(n));
      discard(delay(n^.opnd[1], 5, 5, true));
      if 8 in n^.phase then
        w := n^.desc.w6
      else if not (n^.opnd[2]^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) then
        w := n^.desc.w6
      else if 8 in (getphase(n^.opnd[1]) + getphase(n^.opnd[2])) then
        w := n^.desc.w6
      else
        w := 2;
      x := delay(n^.opnd[2], n^.desc.w6, w, doit);
      if doit then
        n^.desc.w6 := x;
      res := want;
    end;
    3: begin
      b := delay(n^.opnd[1], n^.desc.w6, maxw, false);
      o := dl_ptr_t(n^.opnd[2]);
      if (o^.kind in [77..87, 101, 200]) and (n^.desc.w8 = 4) then begin
        if n^.desc.flags.signed then begin
          if (o^.int_value <= 32767) and (o^.int_value >= -32768) then
            n^.desc.w8 := 2;
        end
        else if (o^.int_value <= 65535) and (o^.int_value >= 0) then
          n^.desc.w8 := 2;
        a := n^.desc.w8;
      end
      else
        a := delay(n^.opnd[2], n^.desc.w8, maxw, false);
      if maxw = 2 then begin
        res := 2;
        if not doit then
          goto 99;
        if b = 2 then
          n^.desc.w6 := delay(n^.opnd[1], n^.desc.w6, 2, true);
        if a = res then
          n^.desc.w8 := delay(n^.opnd[2], n^.desc.w8, res, true);
        n^.desc.size := 2;
        n^.desc.rlen := res;
      end
      else if doit then begin
        discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, true));
        discard(delay(n^.opnd[2], n^.desc.w8, n^.desc.w8, true));
      end;
    end;
    4, 6:
      if n^.desc.rlen <= 4 then begin
        if doit then begin
          if maxw < n^.desc.rlen then begin
            n^.desc.rlen := maxw;
            n^.desc.size := maxw;
          end;
          res := n^.desc.rlen;
        end;
        delay_$divide_attributes(t, true, strategy, w18, lsize, w26, rsize,
                                 w34, w38, w42, w46, shift, b54, b58, w62,
                                 w66, w70);
        shrink_divide_operand(t, n^.opnd[1], n^.desc.w6, lsize, doit);
        shrink_divide_operand(t, n^.opnd[2], n^.desc.w8, rsize, doit);
        if not doit then
          res := w66;
      end;
    43: begin
      a := delay(n^.opnd[1], n^.desc.w6, maxw, false);
      if target_properties.p_10 = 0 then begin
        x := delay(n^.opnd[2], n^.desc.w8, maxw, false);
        if (x < 4) and (maxw < 4) and (a < 4) then begin
          res := 2;
          if not doit then
            goto 99;
          n^.desc.w6 := delay(n^.opnd[1], n^.desc.w6, res, true);
          n^.desc.w8 := delay(n^.opnd[2], n^.desc.w8, res, true);
          n^.desc.size := 2;
          n^.desc.rlen := res;
        end
        else begin
          discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
          discard(delay(n^.opnd[2], n^.desc.w8, n^.desc.w8, doit));
        end;
      end
      else begin
        b := delay(n^.opnd[2], 4, maxw, false);
        if maxw >= 4 then
          goto 99;
        if (a >= 4) and (b >= 4) then
          goto 99;
        if doit then begin
          if a < 4 then begin
            if maxw < 2 then
              w := 2
            else
              w := maxw;
            discard(delay(n^.opnd[1], 4, w, true));
            il_utils_$do_substitution(t, n^.opnd[1],
                delay_$splice(n^.opnd[1], 4, n^.desc.flags.signed, b,
                              false));
          end;
          if b < 4 then begin
            if maxw < 2 then
              w := 2
            else
              w := maxw;
            x := delay(n^.opnd[2], 4, w, true);
            il_utils_$do_substitution(t, n^.opnd[2],
                delay_$splice(n^.opnd[2], 4, n^.desc.flags.signed, x,
                              false));
          end;
          n^.desc.size := 2;
          n^.desc.rlen := 2;
        end;
        res := 2;
      end;
    end;
    72, 73: begin
      discard(delay(n^.opnd[1], 4, 4, doit));
      for i := 2 to n^.count do
        discard(delay(n^.opnd[i], n^.desc.w6, n^.desc.w6, doit));
    end;
    19, 20, 21, 23, 24:
      for i := 1 to n^.count do
        discard(delay(n^.opnd[i], 4, 4, doit));
    25: begin
      discard(delay(n^.opnd[2], n^.desc.w6, n^.desc.w6, doit));
      if n^.count = 3 then
        discard(delay(n^.opnd[3], n^.desc.w6, n^.desc.w6, doit));
      discard(delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, doit));
      res := n^.desc.rlen;
    end;
    11: begin
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
      if n^.xw[11] > 4 then
        discard(delay(n^.opnd[2], 5, 5, doit))
      else if n^.opnd[1]^.kind in [77..87, 101, 200] then begin
        v := dl_ptr_t(n^.opnd[1])^.int_value;
        if (v >= 0) and (v <= 7) then
          w := 1
        else if (v >= 8) and (v <= 15) then
          w := 2
        else
          w := 4;
        x := delay(n^.opnd[2], n^.xw[11], w, doit);
        if doit then
          n^.desc.size := x;
      end
      else begin
        x := delay(n^.opnd[2], n^.xw[11], n^.xw[11], false);
        if x = n^.desc.size then
          if doit then
            discard(delay(n^.opnd[2], n^.xw[11], n^.xw[11], true));
      end;
    end;
    14: begin
      discard(delay(n^.opnd[1], n^.desc.rlen, n^.desc.rlen, true));
      if (3 in cargs_$options.cpu) and
         not (n^.opnd[2]^.kind in [77..87, 101, 200]) then
        w := 4
      else
        w := 1;
      discard(delay(n^.opnd[2], w, w, true));
      o := dl_ptr_t(n^.opnd[2]);
      if (o^.kind in [77..87, 101, 200]) and (o^.int_value mod 8 = 0) and
         (n^.desc.w8 = 8) then begin
        if maxw = 1 then begin
          if doit then begin
            il_utils_$adjust_uc(n^.opnd[1], -1);
            t := add_dn(n^.opnd[1], n^.opnd[1], o^.int_value div 8);
            il_utils_$adjust_uc(t, 1);
          end;
          res := 1;
        end
        else if maxw = 2 then begin
          if doit then
            n^.desc.rlen := maxw;
          res := maxw;
        end;
      end
      else begin
        w := n^.desc.rlen;
        if o^.kind in [77..87, 101, 200] then begin
          if maxw = 1 then begin
            if n^.desc.w6 <= 8 then
              w := maxw;
          end
          else if maxw = 2 then
            if n^.desc.w6 <= 16 then
              w := maxw;
        end
        else
          w := maxw;
        if doit then
          n^.desc.rlen := w;
        res := w;
      end;
    end;
    39: begin
      o := dl_ptr_t(n^.opnd[1]);
      if (n^.desc.w6 = 4) and not n^.desc.flags.signed and
         (o^.kind = 137) and (o^.op = 18) and
         (o^.desc.rlen > o^.desc.w6) and not o^.desc.flags.signed then
        n^.desc.flags.signed := true;
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
    end;
    22: begin
      if doit then
        if delay_sets(n^.opnd[1], n^.desc.w6, n^.desc.size, false) =
           n^.desc.size then begin
          discard(delay_sets(n^.opnd[1], n^.desc.w6, n^.desc.size, true));
          il_utils_$adjust_uc(t, -1);
          t := n^.opnd[1];
          il_utils_$adjust_uc(t, 1);
        end;
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
    end;
    42: begin
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
      discard(delay(n^.opnd[2], n^.desc.w8, n^.desc.w8, doit));
    end;
    34, 35, 36, 37, 38, 41, 45, 46, 48:
      for i := 1 to n^.count do
        discard(delay(n^.opnd[i], n^.desc.rlen, n^.desc.rlen, doit));
    40: begin
      discard(delay(n^.opnd[1], n^.desc.w6, n^.desc.w6, doit));
      discard(delay(n^.opnd[2], n^.desc.w6, n^.desc.w6, doit));
    end;
    otherwise ;
  end;
99:
  delay_$shrink_tree_node := res;
end;

{ delay - see the header.  The kinds with a phase whose +6 bit 1 (phase
  9) shows them delayed already (but not references) keep their class,
  an indexed reference want, or are converted to want (delay_$splice)
  under doit when it differs and both classes are integers (5 and 4
  taken as one); tree nodes and calls (137, 143) used once go to
  delay_$shrink_tree_node; a displacement (147), a symbolic one (205),
  a dereference (146) or a variable (109) narrowed by add_dn of want -
  maxw bytes when it may be (not for phases 1, 2, or a 109's +35 bit
  0); an indexed reference's index delayed at its class (+42: 2 for a
  short index) and its base at 4; an integer constant remade at maxw
  (1, 2, 4: kinds 200/80/82 signed, 86/83/85 unsigned, 81 by its value,
  dfetch).  The result is want unless the class may stay narrower
  (class_size), 5, 6 and 4 kept only when maxw is that class; under
  doit a node with a phase gets +10 the result and +6 bit 1 set.

  0x078A64, 0x61A bytes, link #-72, no A5: 64 call sites, all in this
  unit; the result in D0 (D5).

  Not known from the original:
  - the names. }

function delay;
label
  99;
var
  n: dl_ptr_t;
  res: integer;                         { D5 }
  w: integer;
  ph: add_node_$phase_t;
  sg: boolean;                          { -48 }
  k: integer;                           { -40 }
begin
  res := want;
  n := dl_ptr_t(t);
  if n^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then begin
    if 1 in n^.phase then
      maxw := want;
    if (9 in n^.phase) and (n^.kind <> 146) and (n^.kind <> 147) and
       (n^.kind <> 205) then begin
      if n^.kind = 145 then begin
        delay := want;
        return;
      end;
      if maxw = n^.regs then begin
        delay := maxw;
        return;
      end;
      if (want <> n^.regs) and (want <= 5) and (n^.regs <= 5) and
         not (((want = 5) or (want = 4)) and
              ((n^.regs = 5) or (n^.regs = 4))) then
        if doit then begin
          il_utils_$adjust_uc(t, -1);
          t := delay_$splice(t, want, dl_ptr_t(t)^.desc.flags.signed,
                             dl_ptr_t(t)^.desc.rlen, false);
          il_utils_$adjust_uc(t, 1);
          delay := want;
          return;
        end
        else begin
          delay := n^.regs;
          return;
        end;
      if ((want = 4) or (want = 6) or (want = 5)) and
         ((n^.regs = 4) or (n^.regs = 6) or (n^.regs = 5)) then
        delay := want
      else
        delay := n^.regs;
      return;
    end;
  end;
  case n^.kind of
    137, 143: begin
      if n^.uses > 1 then begin
        delay := res;
        return;
      end;
      res := delay_$shrink_tree_node(t, want, maxw, doit);
    end;
    147, 205, 146: begin
      if n^.uses > 1 then begin
        delay := res;
        return;
      end;
      if (n^.kind = 147) and (n^.base^.kind = 137) then
        discard(delay(n^.base, dl_ptr_t(n^.base)^.desc.rlen,
              dl_ptr_t(n^.base)^.desc.rlen, doit))
      else
        discard(delay(n^.base, 4, 4, doit));
      if (want > maxw) and (want < 5) and not (1 in n^.rf_phase) and
         not (2 in n^.rf_phase) then begin
        if doit then begin
          il_utils_$adjust_uc(t, -1);
          if n^.kind = 146 then
            t := add_dn(t, t, want - maxw)
          else
            t := add_dn(t, n^.sym, want - maxw);
          il_utils_$adjust_uc(t, 1);
        end;
        res := maxw;
      end;
    end;
    109:
      if (want > maxw) and (want < 5) and not (0 in n^.vattr) then begin
        if doit then begin
          il_utils_$adjust_uc(t, -1);
          t := add_dn(t, t, want - maxw);
          il_utils_$adjust_uc(t, 1);
        end;
        res := maxw;
      end;
    145: begin
      if n^.uses > 1 then begin
        delay := res;
        return;
      end;
      delay_$propagate_index_long(t);
      if (8 in n^.rf_phase) then
        w := n^.len
      else begin
        ph := getphase(n^.index) + getphase(n^.base);
        if (8 in ph) or
           not (n^.index^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205]) then
          w := n^.len
        else
          w := 2;
      end;
      w := delay(n^.index, n^.len, w, doit);
      if doit then
        n^.len := w;
      discard(delay(n^.base, 4, 4, doit));
    end;
    80, 81, 82, 83, 84, 85, 86, 200:
      if (maxw = 1) or (maxw = 4) or (maxw = 2) then begin
        res := maxw;
        if doit then begin
          if (n^.kind = 80) or (n^.kind = 200) or (n^.kind = 82) then begin
            sg := true;
            if maxw = 1 then
              k := 200
            else if maxw = 2 then
              k := 80
            else
              k := 82;
          end
          else if (n^.kind = 83) or (n^.kind = 84) or (n^.kind = 86) or
                  (n^.kind = 85) then begin
            sg := false;
            if maxw = 1 then
              k := 86
            else if maxw = 2 then
              k := 83
            else
              k := 85;
          end
          else begin
            if maxw = 1 then
              sg := (n^.int_value < 0) or (n^.int_value > 255)
            else if maxw = 2 then
              sg := (n^.int_value < 0) or (n^.int_value > 65535)
            else
              sg := true;
            k := 81;
          end;
          t := smcontk(k, dfetch(n^.int_value, maxw, sg));
        end;
      end;
    otherwise ;
  end;
  if (class_size[res] < class_size[maxw]) and not doit then
    res := want;
  if (res = 5) and (maxw <> 5) then
    res := want;
  if (res = 6) and (maxw <> 6) then
    res := want;
  if (res = 4) and (maxw <> 4) then
    res := want;
  if t^.kind in [137, 138, 143, 145..147, 164, 171, 175, 189, 205] then
    if doit then begin
      dl_ptr_t(t)^.regs := res;
      dl_ptr_t(t)^.phase := dl_ptr_t(t)^.phase + [9];
    end;
  delay := res;
end;

{ delay_$shrink_top_level_node - delay the trees of the top-level node
  n under -OPT 6 (cargs opt_on 6): an assignment's (140) left and right
  sides at the assignment's class (+52), an evaluation's (139) operands
  at their own class (4 for other nodes, not changed), a conditional
  branch's (142) condition at 1, a return's (151) value at its class.

  0x07907E, 0xEE bytes, link #-8: the trees by address.

  Not known from the original:
  - the names. }

procedure delay_$shrink_top_level_node;
var
  i: integer;
  w: integer;                           { -4 }
begin
  if 6 in cargs_$options.opt_on then
    case n^.kind of
      140: begin
        discard(delay(n^.xp[16], n^.xw[26], n^.xw[26], true));
        discard(delay(n^.xp[17], n^.xw[26], n^.xw[26], true));
      end;
      139:
        for i := 1 to n^.xw[25] do
          if (n^.xp[12 + i]^.kind = 137) or (n^.xp[12 + i]^.kind = 143) then
          begin
            w := dl_ptr_t(n^.xp[12 + i])^.desc.rlen;
            discard(delay(n^.xp[12 + i], w, w, true));
          end
          else
            discard(delay(n^.xp[12 + i], 4, 4, false));
      142: discard(delay(n^.xp[14], 1, 1, true));
      151:
        if n^.xp[12] <> nil then
          discard(delay(n^.xp[12], n^.xw[26], n^.xw[26], true));
      otherwise ;
    end;
end;
