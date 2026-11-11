{ lang2/source/lt_utils/source/mrh.ins.pas - MRH, mapped region heaps:
  heaps of 4096-byte chunks taken from a temporary object mapped in
  pieces of the system's segment size (MS_$CRTEMP, MS_$ADDMAP); a heap
  hands out its current chunk's bytes, and gives its chunks back all at
  once or back to a mark.

  No Apollo copy survives; the headings are read off mrh.pas (cc.m68k
  0x0876CC..0x087FF6) and its callers (mem.pas, gen_debug.pas,
  gen_exception.pas, gen_unwind.pas, debug_sym_dmp.pas, opt_inline.pas,
  ...).  Counts and sizes by value (val_param), the heap by address.
  It is opened after /us/ins/ubase.ins.pas or /sys/ins/base.ins.pas.

  Not known from the original: every type, field and parameter name
  here.
}

const
  mrh_$chunk_size = 4096;               { the messages' mrh_chunk_size }
  mrh_$no_chunk = 65535;                { -1 as a word: no chunk }

type
  { A chunk's number: an unsigned word (compared `bcs'/`bls'). }
  mrh_$chunk_t = 0..65535;

  { The next free byte: a pointer, whose low word is the offset in its
    32K segment (the routines add to the low word only). }
  mrh_$address_t = record
    case integer of
      1: (ptr: univ_ptr);
      2: (address: integer32);
      3: (segment: integer;
          offset: integer);
  end;

  { A heap: 20 bytes, kept by the caller. }
  mrh_$heap_t = record
    next: mrh_$address_t;               { +0 }
    free: integer;                      { +4: bytes left in the chunk }
    default_size: integer;              { +6: mrh_$alloc_fixed's size,
                                          a multiple of 4 }
    first_chunk: mrh_$chunk_t;          { +8 }
    current_chunk: mrh_$chunk_t;        { +10 }
    flags: integer;                     { +12: bit 0, clear what is
                                          handed out }
    chunks_in_use: mrh_$chunk_t;        { +14 }
    chunks_max: mrh_$chunk_t;           { +16 }
    heap_index: mrh_$chunk_t;           { +18: 1..256 }
  end;

  { A mark: the current chunk and the offset in it. }
  mrh_$mark_t = record
    chunk: mrh_$chunk_t;
    offset: integer;
  end;

  { A heap's name, as given (by address) to MRH_$INITIALIZE. }
  mrh_$name_t = array [1..256] of char;

{ MRH_$INITIALIZE_MODULE - forget every heap: the mapped object is
  unmapped when there is one, else the sizes set up from the segment
  size.  0x0876CC. }
procedure mrh_$initialize_module; extern;

{ MRH_$INITIALIZE - heap empty (its chunks given back when it is known
  already), with flags and a default size of at most 4096; a new heap
  is entered under name.  0x087B7C: heap at (8,A6), flags and
  default_size words at (12,A6) and (14,A6), name's address at
  (16,A6). }
procedure mrh_$initialize(
    in out heap: mrh_$heap_t;
    flags: integer;
    default_size: mrh_$chunk_t;
    in name: univ mrh_$name_t); options(val_param); extern;

{ MRH_$ALLOC - size bytes (at most 4096, rounded up to 4) from the heap.
  0x087CD8: size a word at (12,A6). }
function mrh_$alloc(
    in out heap: mrh_$heap_t;
    size: mrh_$chunk_t): univ_ptr; options(val_param); extern;

{ MRH_$ALLOC_FIXED - the heap's default size from it.  0x087D94. }
function mrh_$alloc_fixed(
    in out heap: mrh_$heap_t): univ_ptr; extern;

{ MRH_$BYTES_USED - the bytes of the heap's chunks less what is left in
  the current one.  0x087DF2. }
function mrh_$bytes_used(
    in heap: mrh_$heap_t): integer32; extern;

{ MRH_$GET_MAP - the chunk table's address.  0x087E3C. }
function mrh_$get_map: univ_ptr; extern;

{ MRH_$CHUNKS_TOTAL, MRH_$CHUNKS_IN_USE, MRH_$CHUNKS_IN_USE_MAX,
  MRH_$RESET_CHUNKS_IN_USE_MAX - the chunk counts.  0x087E5C..0x087EA6. }
function mrh_$chunks_total: integer32; extern;
function mrh_$chunks_in_use: integer32; extern;
function mrh_$chunks_in_use_max: integer32; extern;
procedure mrh_$reset_chunks_in_use_max; extern;

{ MRH_$MARK - the heap's current chunk and offset (in D0).  0x087EC2. }
function mrh_$mark(
    in heap: mrh_$heap_t): mrh_$mark_t; extern;

{ MRH_$RELEASE_ALL - MRH_$INITIALIZE again with the heap's own flags,
  default size and name.  0x087EF0. }
procedure mrh_$release_all(
    in out heap: mrh_$heap_t); extern;

{ MRH_$RELEASE_TO_MARK - the heap back to the mark (by value: chunk and
  offset words at (12,A6), (14,A6)).  0x087F2A. }
procedure mrh_$release_to_mark(
    in out heap: mrh_$heap_t;
    mark: mrh_$mark_t); options(val_param); extern;
