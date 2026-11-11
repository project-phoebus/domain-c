{ arith - ARITH, saturating integer32 arithmetic: sums and products
  that overflow give the largest or smallest integer32; a difference is
  a sum with b negated; a product is formed in 64 bits from four 16-bit
  products; a quotient by 0 is 0.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x075350  0x076D30  arith
    0x07530C  0x076CEC  add_middle (nested in arith)
    A5 0x1695E4 (cc.m68k), 0x2E9654 (cc.a88k): the module's data, 4
    bytes to bug_check's; no routine here reads it.
}
module arith;

%include 'lang2/source/lt_utils/source/arith.ins.pas';

const
  max_integer32 = 16#7FFFFFFF;
  min_integer32 = -16#7FFFFFFF - 1;

{ arith - a op b.

  0x075350, 0x16E bytes: b in D1, a in D3, op in D0.  A subtraction
  (op 1) becomes an addition: b negated unless it is the smallest
  integer32; then a >= 0 gives the largest, else a + 1 and not b (the
  largest).  The case on op (a compare chain 0, 2, 3; no otherwise, D0
  left as it is):
    0  both >= 0: the sum, the largest when it is negative (`bpl');
       both < 0: the smallest when either is the smallest, else the
       negated sum of the negations, the smallest when that is negative;
       else the sum.
    2  the sign (`sge; sge; cmp.b; sne'); a and b made positive; the
       64-bit product (-8,A6) high, (-4,A6) low from the high and low
       halves (`mulu.w') and add_middle of the two cross products; negated
       when the signs differ (`not.l' the high, plus 1 when the low is 0,
       `neg.l' the low); the low when the high is 0 and the low >= 0, or
       the high is -1 and the low < 0; else the largest or the smallest
       by the high's sign.
    3  0 when b = 0, else a div b (M$DIS$LLL).

  Not known from the original:
  - the locals' names, and how the 64-bit product was declared (two
    longwords at (-8,A6) and (-4,A6), read by add_middle as words). }

function arith(
    op: arith_$op_t;
    a: integer32;
    b: integer32): integer32;
var
  product: record                       { (-8,A6) }
    case integer of
      1: (high: integer32;
          low: integer32);
      2: (w: array [0..3] of 0..65535);
  end;
  negative: boolean;
  a_high, a_low, b_high, b_low: integer32;

  { add_middle - m * 65536 added to the product.

    0x07530C, 0x44 bytes, nested: the parent's frame through (A6); m's
    low word added to the low longword's high word (-4), the carry
    (`lsr.l #16') and m's high word (`clr.w; swap') to the high
    longword's low word (-6), that carry to its high word (-8). }

  procedure add_middle(
      m: integer32); options(val_param);
  var
    sum: integer32;
  begin
    sum := (m & 16#FFFF) + product.w[2];
    product.w[2] := sum & 16#FFFF;
    sum := rshft(sum, 16) + rshft(m, 16) + product.w[1];
    product.w[1] := sum & 16#FFFF;
    product.w[0] := (product.w[0] + rshft(sum, 16)) & 16#FFFF;
  end;

begin
  if op = arith_$subtract then begin
    op := arith_$add;
    if b <> min_integer32 then
      b := -b
    else if a >= 0 then begin
      arith := max_integer32;
      return;
    end
    else begin
      a := a + 1;
      b := ~b;
    end;
  end;
  case op of
    arith_$add:
      if (a >= 0) and (b >= 0) then begin
        if a + b < 0 then
          arith := max_integer32
        else
          arith := a + b;
      end
      else if (a < 0) and (b < 0) then begin
        if (a = min_integer32) or (b = min_integer32) then
          arith := min_integer32
        else if (-a) + (-b) < 0 then
          arith := min_integer32
        else
          arith := -((-a) + (-b));
      end
      else
        arith := a + b;
    arith_$multiply: begin
      negative := (a >= 0) <> (b >= 0);
      if a < 0 then
        a := -a;
      if b < 0 then
        b := -b;
      a_high := rshft(a, 16);
      a_low := a & 16#FFFF;
      b_high := rshft(b, 16);
      b_low := b & 16#FFFF;
      product.high := a_high * b_high;
      product.low := a_low * b_low;
      add_middle(a_high * b_low);
      add_middle(a_low * b_high);
      if negative then begin
        product.high := ~product.high;
        if product.low = 0 then
          product.high := product.high + 1;
        product.low := -product.low;
      end;
      if product.high < 0 then begin
        if (product.high = -1) and (product.low < 0) then
          arith := product.low
        else
          arith := min_integer32;
      end
      else if (product.high = 0) and (product.low >= 0) then
        arith := product.low
      else
        arith := max_integer32;
    end;
    arith_$divide:
      if b = 0 then
        arith := 0
      else
        arith := a div b;
  end;
end;
