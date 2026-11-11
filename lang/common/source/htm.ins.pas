{ lang/common/source/htm.ins.pas - HTM_, hash tables and hashing: a
  table of chained buckets that doubles as it fills, and CRC-32 hashes
  of bytes, words, longwords, quadwords, strings and names (upcased).

  No Apollo copy survives; the headings are read off htm.pas (cc.m68k
  0x068908..0x0690D2) and its callers (pds.pas's calculate_crc).
  Values by value (val_param), the strings and the table variable by
  address.  It stands alone (htm.pas opens it last, pds.pas after its
  other inserts).

  Not known from the original: every type, field and parameter name
  here.
}

type
  { A bucket's entry: the chain, then the key the bucket was taken
    from (HTM_$INCREMENT_TABLE_ENTRIES rehashes by it). }
  htm_$entry_ptr_t = ^htm_$entry_t;
  htm_$entry_t = record
    next: htm_$entry_ptr_t;             { +0 }
    key: integer32;                     { +4 }
  end;

  { A table: a header of four longwords, and the buckets, which the
    code addresses from +10 (bucket i at +10 + 4 * i: the first overlaps
    the size's low word and the mask's high word). }
  htm_$table_ptr_t = ^htm_$table_t;
  htm_$table_t = record
    case integer of
      1: (mask_copy: integer32;         { +0: set to the mask }
          count: integer32;             { +4: the entries }
          size: 0..2147483647;          { +8: the buckets (compared
                                          unsigned, `bcc') }
          mask: integer32);             { +12: size - 1 }
      2: (unused_0: array [0..4] of integer;    { +0 }
          buckets: array [0..32767] of htm_$entry_ptr_t);  { +10 }
  end;

  { The characters hashed. }
  htm_$string_t = array [1..32767] of char;

{ HTM_$CREATE_TABLE - a table of size buckets (a power of 2), from the
  RWS heap, empty.  0x068908. }
function htm_$create_table(
    size: integer32): htm_$table_ptr_t; options(val_param); extern;

{ HTM_$RELEASE_TABLE - the table back to the RWS heap.  0x06896C. }
procedure htm_$release_table(
    in table: htm_$table_ptr_t); extern;

{ HTM_$INCREMENT_TABLE_ENTRIES - one more entry: a table of fewer than
  32768 buckets with more entries than twice its buckets is replaced by
  one twice as large (its entries rehashed), and bucket set to key's
  bucket in it.  0x0689C8. }
procedure htm_$increment_table_entries(
    in out table: htm_$table_ptr_t;
    key: integer32;
    out bucket: integer32); options(val_param); extern;

{ HTM_$BUCKET - key's bucket in the table.  0x068ABE. }
function htm_$bucket(
    table: htm_$table_ptr_t;
    key: integer32): integer32; options(val_param); extern;

{ The CRC-32 hashes (initial value -1, the bytes least significant
  first, the result's words exchanged).  0x068ADE..0x068E50. }
function htm_$hash_byte(
    b: char): integer32; options(val_param); extern;

function htm_$hash_word(
    w: integer): integer32; options(val_param); extern;

function htm_$hash_long(
    l: integer32): integer32; options(val_param); extern;

function htm_$hash_quad(
    high: integer32;
    low: integer32): integer32; options(val_param); extern;

function htm_$hash_string(
    in s: univ htm_$string_t;
    len: integer): integer32; options(val_param); extern;

{ HTM_$HASH_UPCASED_NAME - the hash of the name upcased; upcased gets
  the upcased characters and zeros to a multiple of 4.  0x068E50. }
function htm_$hash_upcased_name(
    in name: univ htm_$string_t;
    out upcased: univ htm_$string_t;
    len: integer): integer32; options(val_param); extern;

{ HTM_$HASH_RUNNING_QUAD_MULTIPLE, HTM_$HASH_RUNNING_BYTE_MULTIPLE - crc
  carried on over a quadword (high, low) or a byte.  0x068F08,
  0x06907A. }
function htm_$hash_running_quad_multiple(
    crc: integer32;
    high: integer32;
    low: integer32): integer32; options(val_param); extern;

function htm_$hash_running_byte_multiple(
    crc: integer32;
    b: char): integer32; options(val_param); extern;
