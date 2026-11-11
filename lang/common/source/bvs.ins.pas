{ lang/common/source/bvs.ins.pas - BVS_, bit vectors: sets of bit
  numbers from 0, allocated from a MEM_ pool in whole longwords, with
  the set operations between vectors of the same size.

  No Apollo copy survives; the headings are read off bvs.pas (cc.m68k
  0x0679B4..0x068412).  No unit of DOMAIN C calls BVS_.  It stands
  alone (bvs.pas opens it first, before mem.ins.pas, so the pool is a
  univ_ptr here).  Values by value (val_param), a vector variable by
  address.

  Not known from the original: every type, field and parameter name
  here.
}

const
  bvs_$none = 32769;                    { BVS_$FIND_NEXT: no further bit }

type
  { A bit number: an unsigned word. }
  bvs_$bit_t = 0..65535;

  bvs_$word_t = set of 0..31;

  { A vector: the last longword's index and the last bit's number, then
    the longwords (bit b in longword b div 32 as element b mod 32). }
  bvs_$t = ^bvs_$rec_t;
  bvs_$rec_t = record
    last_word: integer;                 { +0 }
    last_bit: bvs_$bit_t;               { +2 }
    words: array [0..2047] of bvs_$word_t;      { +4 }
  end;

{ BVS_$CREATE_BIT_VECTOR - a vector of at least nbits bits (at least
  32, whole longwords) from the pool, every bit initial.  0x067CF4: pool
  at (8,A6), nbits a word at (12,A6), initial a byte at (14,A6). }
function bvs_$create_bit_vector(
    pool: univ_ptr;
    nbits: bvs_$bit_t;
    initial: boolean): bvs_$t; options(val_param); extern;

{ BVS_$DISPOSE_BIT_VECTOR - the vector back to the pool (MEM_$DISPOSE);
  v := nil.  0x067D5C. }
procedure bvs_$dispose_bit_vector(
    pool: univ_ptr;
    in out v: bvs_$t); options(val_param); extern;

{ BVS_$BIT_VECTOR_BIT_COUNT - the vector's bits.  0x067DC4. }
function bvs_$bit_vector_bit_count(
    v: bvs_$t): integer; options(val_param); extern;

{ BVS_$RESET_BIT_VECTOR - every bit value.  0x067E28. }
procedure bvs_$reset_bit_vector(
    v: bvs_$t;
    value: boolean); options(val_param); extern;

{ BVS_$TEST_BIT_VECTOR - whether every bit is value.  0x067EAC. }
function bvs_$test_bit_vector(
    v: bvs_$t;
    value: boolean): boolean; options(val_param); extern;

{ BVS_$TEST, BVS_$TEST_AND_SET, BVS_$TEST_AND_CLEAR, BVS_$SET,
  BVS_$CLEAR - one bit (checked against the vector's size); the test
  forms give the bit's value before.  0x067F38..0x068042. }
function bvs_$test(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean; options(val_param); extern;

function bvs_$test_and_set(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean; options(val_param); extern;

function bvs_$test_and_clear(
    v: bvs_$t;
    bit: bvs_$bit_t): boolean; options(val_param); extern;

procedure bvs_$set(
    v: bvs_$t;
    bit: bvs_$bit_t); options(val_param); extern;

procedure bvs_$clear(
    v: bvs_$t;
    bit: bvs_$bit_t); options(val_param); extern;

{ Between two vectors of the same size: dst := src, dst := dst + src,
  dst := dst * src, dst := dst - src; the _and_test forms say whether
  src has a bit set; BVS_$EQUAL, BVS_$SET1_SUBSUMES_SET2 (set2 <= set1).
  0x068082..0x068316. }
procedure bvs_$copy(
    src: bvs_$t;
    dst: bvs_$t); options(val_param); extern;

function bvs_$copy_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean; options(val_param); extern;

function bvs_$equal(
    a: bvs_$t;
    b: bvs_$t): boolean; options(val_param); extern;

procedure bvs_$or(
    src: bvs_$t;
    dst: bvs_$t); options(val_param); extern;

procedure bvs_$and(
    src: bvs_$t;
    dst: bvs_$t); options(val_param); extern;

function bvs_$or_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean; options(val_param); extern;

function bvs_$and_and_test(
    src: bvs_$t;
    dst: bvs_$t): boolean; options(val_param); extern;

{ BVS_$AND_TO - dst := src1 * src2.  0x068282. }
procedure bvs_$and_to(
    src1: bvs_$t;
    src2: bvs_$t;
    dst: bvs_$t); options(val_param); extern;

procedure bvs_$subtract(
    src: bvs_$t;
    dst: bvs_$t); options(val_param); extern;

function bvs_$set1_subsumes_set2(
    set1: bvs_$t;
    set2: bvs_$t): boolean; options(val_param); extern;

{ BVS_$FIND_NEXT - the first set bit after bit (-1 to look from bit 0):
  bvs_$none (32769) for none, and when bit is bvs_$none.  0x068362. }
function bvs_$find_next(
    v: bvs_$t;
    bit: integer32): integer32; options(val_param); extern;
