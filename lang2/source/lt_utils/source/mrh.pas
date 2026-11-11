{ mrh - MRH, mapped region heaps.  A temporary object is created and
  mapped (MS_$CRTEMP) the first time a chunk is needed and mapped
  further (MS_$ADDMAP) a segment-size piece at a time; each piece gives
  segment-size / 32768 32K segments of 8 chunks of 4096 bytes.  The
  chunk table chains each heap's chunks (next, -1 at the end; 0 a free
  chunk) and records their owner (the heap's index; negated when
  freed).  At most 256 heaps, each entered with its name.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0876CC  0x0890AC  mrh_$initialize_module
    0x0877A8  0x089188  allocate_new_chunk (internal)
    0x087A7C  0x08945C  release_chunk_list (internal)
    0x087B7C  0x08955C  mrh_$initialize
    0x087CD8  0x0896B8  mrh_$alloc
    0x087D94  0x089774  mrh_$alloc_fixed
    0x087DF2  0x0897D2  mrh_$bytes_used
    0x087E3C  0x08981C  mrh_$get_map
    0x087E5C  0x08983C  mrh_$chunks_total
    0x087E76  0x089856  mrh_$chunks_in_use
    0x087E8E  0x08986E  mrh_$chunks_in_use_max
    0x087EA6  0x089886  mrh_$reset_chunks_in_use_max
    0x087EC2  0x0898A2  mrh_$mark
    0x087EF0  0x0898D0  mrh_$release_all
    0x087F2A  0x08990A  mrh_$release_to_mark
    A5 0x169F48 (cc.m68k), 0x2E9FB8 (cc.a88k): the module's data,
    0x24840 bytes to objio's.

  Module data as the image uses it: +0 the segments' addresses (4096
  longwords, by chunk div 8); +16384 the heaps' names and +17408 the
  heaps (256 pointers each, from index 1); +18432 the length ADDMAP
  mapped; +18436 the length of a piece (the segment size); +18440 the
  32K segments in a piece; +18444 the mapped object's address; +18448
  the chunks in a piece (its low word read as a word); +18452 the most
  chunks in use; +18456 the chunks in use; +18460 the heaps entered
  (its low word stored as a heap's index); words: +18464 the segments
  entered, +18466 the free chunks, +18468 where the search for a free
  chunk starts, +18470 the chunks; +18472 (0x16E770, addressed
  absolutely) the chunk table, 32768 entries of two words.

  The global routines load A5; allocate_new_chunk and
  release_chunk_list, which do not (they run on their callers' A5), are
  internal.
}
module mrh;

%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/ms.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';

{ SEG_SIZE (lang2/source/lt_utils/source/seg_size.pas, which has no
  insert): the system's segment size. }
function seg_size: integer32; extern;

const
  max_heaps = 256;
  max_segments = 4096;
  segment_bytes = 32768;                { 8 chunks }

type
  heap_ptr_t = ^mrh_$heap_t;
  name_ptr_t = ^mrh_$name_t;
  chunk_entry_t = record
    next: mrh_$chunk_t;                 { 0 free, mrh_$no_chunk last }
    owner: integer;                     { the heap's index; negated when
                                          freed }
  end;
  words_ptr_t = ^array [1..1024] of integer32;

var
  segments: array [0..4095] of integer32;               { +0 }
  heap_names: array [1..256] of name_ptr_t;             { +16384 }
  heaps: array [1..256] of heap_ptr_t;                  { +17408 }
  length_mapped: integer32;                             { +18432 }
  piece_length: integer32;                              { +18436 }
  segments_per_piece: integer32;                        { +18440 }
  mapped_object: univ_ptr;                              { +18444 }
  chunks_per_piece: integer32;                          { +18448 }
  chunks_in_use_max: integer32;                         { +18452 }
  chunks_in_use: integer32;                             { +18456 }
  heap_count: integer32;                                { +18460 }
  segment_count: mrh_$chunk_t;                          { +18464 }
  free_chunks: integer;                                 { +18466 }
  search_start: mrh_$chunk_t;                           { +18468 }
  chunk_count: mrh_$chunk_t;                            { +18470 }
  chunk_table: array [0..32767] of chunk_entry_t;       { +18472 }

{ mrh_$initialize_module - forget every heap.

  0x0876CC, 0xCA bytes: `tst.l (18444,A5); bne'.  No mapped object:
  the chunk counts and the four words cleared, piece_length :=
  SEG_SIZE, segments_per_piece := piece_length div 32768 (`bpl; addi.l
  #32767; asr.l #8; asr.l #7'), chunks_per_piece := that * 8.  Else
  MS_$UNMAP (0x087734) of the object and piece_length, OK_OR_BUG_CHECK
  'MRH -- ms_$unmap%$' (0x087796), prf_gspace_in_use less chunks_in_use
  * 4096, and the counts, the object, the four words and heap_count
  cleared.

  Not known from the original:
  - why heap_count is cleared only after an unmap. }

procedure mrh_$initialize_module;
var
  status: status_$t;                    { (-4,A6) }
begin
  if mapped_object = nil then begin
    chunks_in_use := 0;
    chunks_in_use_max := 0;
    chunk_count := 0;
    search_start := 0;
    free_chunks := 0;
    segment_count := 0;
    piece_length := seg_size;
    segments_per_piece := piece_length div segment_bytes;
    chunks_per_piece := segments_per_piece * 8;
  end
  else begin
    ms_$unmap(mapped_object, piece_length, status);
    ok_or_bug_check(status, 'MRH -- ms_$unmap%$');
    prf_gspace_in_use := prf_gspace_in_use - chunks_in_use * mrh_$chunk_size;
    chunks_in_use := 0;
    chunks_in_use_max := 0;
    mapped_object := nil;
    chunk_count := 0;
    search_start := 0;
    free_chunks := 0;
    segment_count := 0;
    heap_count := 0;
  end;
end;

{ allocate_new_chunk - a free chunk becomes the heap's current one.

  0x0877A8, 0x252 bytes, internal.  No free chunk (`tst.w (18466,A5);
  bne'): search_start := chunk_count; BUG_CHECK('MRH -- exhausted heap
  table space%$') unless segment_count < 4096 (`bcs'); the first piece
  by MS_$CRTEMP (0x0877F4) of the longword 0 at 0x087A78 (location and
  start), the word 0 at 0x0879FA (its length and the concurrency
  mode), piece_length and (-12,A6), the address kept at +18444; later
  ones by MS_$ADDMAP (0x08782C) of the object, segment_count * 32768
  (in (-28,A6)), piece_length and +18432; OK_OR_BUG_CHECK of the status
  with 'MRH -- ms_$crtemp%$' or 'MRH -- ms_$addmap%$'.  The piece's
  address + 8 + i * 32768 is entered for each of its segments (a `for'
  over segments_per_piece, the offset strength-reduced in D1, a `dbf'
  with the high-word borrow); the new chunks' entries are cleared (a
  `for' from chunk_count to chunk_count + chunks_per_piece - 1), and
  free_chunks and chunk_count grow by chunks_per_piece.

  The search starts at the heap's current chunk, or at search_start
  when that is higher (unsigned) or the heap has none, and runs to
  chunk_count for an entry whose next is 0 (`beq' to the claim).  When
  none and the heap has a current chunk, a second search from
  search_start up to the current chunk sets search_start to what it
  finds; when that finds none: BUG_CHECK('MRH -- n_free_chunks <> 0 but
  search failed%$') (0x0879FC) and return.

  The claim (0x08794A): chunks_in_use (and its maximum),
  prf_gspace_in_use (and its peak) by 4096, free_chunks less one; the
  heap's free := 4096; the chunk chained after the current one (or
  first), next := -1, owner := the heap's index; the current chunk; the
  next byte := the segment's address with the low byte cleared (`andi.w
  #-256'), its low word plus (chunk & 7) * 4096; the heap's chunks in
  use (and its maximum, unsigned) one more.

  Not known from the original:
  - whether the searches were written with goto (the found paths jump
    out of the loops past the code that follows them), and the
    locals' names; the location and length passed to MS_$CRTEMP. }

procedure allocate_new_chunk(
    in out heap: mrh_$heap_t); internal;
label
  claim;
var
  status: status_$t;                    { (-12,A6) }
  offset: integer32;                    { (-28,A6) }
  last: mrh_$chunk_t;                   { (-30,A6) }
  base: integer32;
  i: integer32;
  c: mrh_$chunk_t;
begin
  if free_chunks = 0 then begin
    search_start := chunk_count;
    if segment_count >= max_segments then
      bug_check('MRH -- exhausted heap table space%$');
    if segment_count = 0 then begin
      mapped_object := ms_$crtemp(0, 0, 0, piece_length, ms_$nr_xor_1w,
                                  status);
      base := integer32(mapped_object);
      ok_or_bug_check(status, 'MRH -- ms_$crtemp%$');
    end
    else begin
      offset := segment_count * segment_bytes;
      base := integer32(ms_$addmap(mapped_object, offset, piece_length,
                                   length_mapped, status));
      ok_or_bug_check(status, 'MRH -- ms_$addmap%$');
    end;
    base := base + 8;
    for i := 0 to segments_per_piece - 1 do begin
      segments[segment_count] := base + i * segment_bytes;
      segment_count := segment_count + 1;
    end;
    last := chunks_per_piece - 1 + chunk_count;
    for c := chunk_count to last do begin
      chunk_table[c].next := 0;
      chunk_table[c].owner := 0;
    end;
    free_chunks := free_chunks + chunks_per_piece;
    chunk_count := chunk_count + chunks_per_piece;
  end;

  c := heap.current_chunk;
  if search_start > c then
    c := search_start
  else if c = mrh_$no_chunk then
    c := search_start;
  while c < chunk_count do begin
    if chunk_table[c].next = 0 then
      goto claim;
    c := c + 1;
  end;
  if heap.current_chunk <> mrh_$no_chunk then begin
    c := search_start;
    while c < heap.current_chunk do begin
      if chunk_table[c].next = 0 then begin
        search_start := c;
        goto claim;
      end;
      c := c + 1;
    end;
  end;
  bug_check('MRH -- n_free_chunks <> 0 but search failed%$');
  return;

claim:
  chunks_in_use := chunks_in_use + 1;
  if chunks_in_use > chunks_in_use_max then
    chunks_in_use_max := chunks_in_use;
  prf_gspace_in_use := prf_gspace_in_use + mrh_$chunk_size;
  if prf_gspace_in_use > prf_gspace_peak then
    prf_gspace_peak := prf_gspace_in_use;
  free_chunks := free_chunks - 1;
  heap.free := mrh_$chunk_size;
  if heap.first_chunk = mrh_$no_chunk then
    heap.first_chunk := c
  else
    chunk_table[heap.current_chunk].next := c;
  chunk_table[c].next := mrh_$no_chunk;
  chunk_table[c].owner := heap.heap_index;
  heap.current_chunk := c;
  heap.next.address := segments[c div 8] & (~255);
  heap.next.offset := heap.next.offset + (c & 7) * mrh_$chunk_size;
  heap.chunks_in_use := heap.chunks_in_use + 1;
  if heap.chunks_in_use > heap.chunks_max then
    heap.chunks_max := heap.chunks_in_use;
end;

{ release_chunk_list - the chunks chained from first, all owned by the
  heap of that index, become free.

  0x087A7C, 0x90 bytes, internal: first a word at (8,A6), heap a
  longword at (10,A6); prf_gspace_in_use's address in A2.  For each
  chunk until -1: next := its entry's next, BUG_CHECK('MRH -- attempt
  to release an already free chunk%$') when that is 0; next := 0;
  BUG_CHECK('MRH -- attempt to release chunk belonging to another
  heap%$') unless the owner (sign-extended) is heap; the owner negated;
  chunks_in_use less one, prf_gspace_in_use less 4096, free_chunks one
  more; search_start := the chunk when lower (unsigned). }

procedure release_chunk_list(
    first: mrh_$chunk_t;
    heap: integer32); options(val_param); internal;
var
  c: mrh_$chunk_t;
  next: mrh_$chunk_t;
begin
  c := first;
  while c <> mrh_$no_chunk do begin
    next := chunk_table[c].next;
    if next = 0 then
      bug_check('MRH -- attempt to release an already free chunk%$');
    chunk_table[c].next := 0;
    if chunk_table[c].owner <> heap then
      bug_check('MRH -- attempt to release chunk belonging to another heap%$');
    chunk_table[c].owner := -chunk_table[c].owner;
    chunks_in_use := chunks_in_use - 1;
    prf_gspace_in_use := prf_gspace_in_use - mrh_$chunk_size;
    free_chunks := free_chunks + 1;
    if c < search_start then
      search_start := c;
    c := next;
  end;
end;

{ mrh_$initialize - the heap empty.

  0x087B7C, 0xE8 bytes: default_size in D2; above 4096 (unsigned,
  `bls'): BUG_CHECK('MRH -- default (%wd) larger than mrh_chunk_size
  (%ld)%$', default_size (stored back to (14,A6)), the longword 4096 at
  0x087C64) and return.  Else the heap's first chunk (D3) and maximum
  (D1) kept; the fields set (next := 0, free := 0, default_size rounded
  up to 4, first and current chunk -1 by one `move.l #-1', flags,
  chunks in use and maximum by one `move.l #0').  A known heap (its
  index zero-extended not above heap_count, `bgt', and heaps[index] the
  heap): the maximum given back and release_chunk_list of the kept
  first chunk unless -1.  Else BUG_CHECK('MRH -- exceeded number of MRH
  heaps allowed (%lsd)%$', the longword 256 at 0x087C9C) unless
  heap_count < 256; heap_count one more, the heap and name's address
  entered, the index := heap_count's low word. }

procedure mrh_$initialize(
    in out heap: mrh_$heap_t;
    flags: integer;
    default_size: mrh_$chunk_t;
    in name: univ mrh_$name_t);
var
  first: mrh_$chunk_t;
  max: mrh_$chunk_t;
  size: mrh_$chunk_t;
begin
  if default_size > mrh_$chunk_size then
    bug_check('MRH -- default (%wd) larger than mrh_chunk_size (%ld)%$',
              default_size, mrh_$chunk_size)
  else begin
    first := heap.first_chunk;
    max := heap.chunks_max;
    size := (default_size + 3) & (~3);
    heap.next.address := 0;
    heap.free := 0;
    heap.default_size := size;
    heap.first_chunk := mrh_$no_chunk;
    heap.current_chunk := mrh_$no_chunk;
    heap.flags := flags;
    heap.chunks_in_use := 0;
    heap.chunks_max := 0;
    if (heap.heap_index <= heap_count) and then
       (heaps[heap.heap_index] = addr(heap)) then begin
      heap.chunks_max := max;
      if first <> mrh_$no_chunk then
        release_chunk_list(first, heap.heap_index);
    end
    else begin
      if heap_count >= max_heaps then
        bug_check('MRH -- exceeded number of MRH heaps allowed (%lsd)%$',
                  max_heaps);
      heap_count := heap_count + 1;
      heaps[heap_count] := addr(heap);
      heap_names[heap_count] := addr(name);
      heap.heap_index := heap_count;
    end;
  end;
end;

{ mrh_$alloc - size bytes from the heap.

  0x087CD8, 0x82 bytes: size in D2; above 4096 (unsigned):
  BUG_CHECK('MRH -- request (%wd) larger than mrh_chunk_size (%ld)%$',
  size, 4096) and the result unset.  Else size rounded up to 4; a new
  chunk when size > free (signed, `ble'); when flags bit 0 (`btst #0,
  (13,A2)') size div 4 longwords cleared from the next byte (`lsr.w #2;
  beq'; a `subq; bne' loop); the result the next byte (in (-10,A6)), the
  next byte's low word plus size, free less size.

  Not known from the original:
  - how the clearing loop was written (a `for' here). }

function mrh_$alloc(
    in out heap: mrh_$heap_t;
    size: mrh_$chunk_t): univ_ptr;
var
  n: mrh_$chunk_t;
  i: mrh_$chunk_t;
  words: words_ptr_t;
begin
  if size > mrh_$chunk_size then
    bug_check('MRH -- request (%wd) larger than mrh_chunk_size (%ld)%$',
              size, mrh_$chunk_size)
  else begin
    n := (size + 3) & (~3);
    if n > heap.free then
      allocate_new_chunk(heap);
    if odd(heap.flags) then begin
      words := heap.next.ptr;
      for i := 1 to n div 4 do
        words^[i] := 0;
    end;
    mrh_$alloc := heap.next.ptr;
    heap.next.offset := heap.next.offset + n;
    heap.free := heap.free - n;
  end;
end;

{ mrh_$alloc_fixed - the default size from the heap.

  0x087D94, 0x5E bytes: as mrh_$alloc with the size at +6 and no
  check. }

function mrh_$alloc_fixed(
    in out heap: mrh_$heap_t): univ_ptr;
var
  i: integer;
  words: words_ptr_t;
begin
  if heap.default_size > heap.free then
    allocate_new_chunk(heap);
  if odd(heap.flags) then begin
    words := heap.next.ptr;
    for i := 1 to heap.default_size div 4 do
      words^[i] := 0;
  end;
  mrh_$alloc_fixed := heap.next.ptr;
  heap.next.offset := heap.next.offset + heap.default_size;
  heap.free := heap.free - heap.default_size;
end;

{ mrh_$bytes_used - 4096 for each of the heap's chunks, less free.

  0x087DF2, 0x4A bytes: the chain from +8 to -1 through the chunk
  table; free sign-extended. }

function mrh_$bytes_used(
    in heap: mrh_$heap_t): integer32;
var
  total: integer32;
  c: mrh_$chunk_t;
begin
  total := 0;
  c := heap.first_chunk;
  while c <> mrh_$no_chunk do begin
    total := total + mrh_$chunk_size;
    c := chunk_table[c].next;
  end;
  mrh_$bytes_used := total - heap.free;
end;

{ mrh_$get_map - the chunk table's address.

  0x087E3C, 0x20 bytes: `move.l #0x16E770,(-4,A6)'. }

function mrh_$get_map: univ_ptr;
begin
  mrh_$get_map := addr(chunk_table);
end;

{ mrh_$chunks_total - chunk_count zero-extended.  0x087E5C, 0x1A bytes. }

function mrh_$chunks_total: integer32;
begin
  mrh_$chunks_total := chunk_count;
end;

{ mrh_$chunks_in_use - 0x087E76, 0x18 bytes. }

function mrh_$chunks_in_use: integer32;
begin
  mrh_$chunks_in_use := chunks_in_use;
end;

{ mrh_$chunks_in_use_max - 0x087E8E, 0x18 bytes. }

function mrh_$chunks_in_use_max: integer32;
begin
  mrh_$chunks_in_use_max := chunks_in_use_max;
end;

{ mrh_$reset_chunks_in_use_max - 0x087EA6, 0x1C bytes. }

procedure mrh_$reset_chunks_in_use_max;
begin
  chunks_in_use_max := 0;
end;

{ mrh_$mark - the current chunk and offset.

  0x087EC2, 0x2E bytes: the record built at (-4,A6) from +10 and +2,
  copied to the result at (-8,A6), returned in D0. }

function mrh_$mark(
    in heap: mrh_$heap_t): mrh_$mark_t;
var
  mark: mrh_$mark_t;                    { (-4,A6) }
begin
  mark.chunk := heap.current_chunk;
  mark.offset := heap.next.offset;
  mrh_$mark := mark;
end;

{ mrh_$release_all - 0x087EF0, 0x3A bytes: MRH_$INITIALIZE (`bsr') of
  the heap, its flags (+12), default size (+6) and heap_names[its
  index]^. }

procedure mrh_$release_all(
    in out heap: mrh_$heap_t);
begin
  mrh_$initialize(heap, heap.flags, heap.default_size,
                  heap_names[heap.heap_index]^);
end;

{ mrh_$release_to_mark - the heap back to the mark.

  0x087F2A, 0xCC bytes: an empty heap (first chunk -1): BUG_CHECK('MRH
  -- release_to_mark attempted on empty heap%$') (0x087FF8) unless the
  mark's chunk is -1 too.  A mark of chunk -1: MRH_$INITIALIZE as
  mrh_$release_all.  Else the chunks after the mark's (its entry's next,
  in (-4,A6)) cut off (next := -1); the next byte := the segment's
  address with the mark's offset as its low word; the current chunk the
  mark's; free := 4096 - (offset & 4095); release_chunk_list of the
  ones cut off, and the heap's chunks in use less as many as became
  free (free_chunks before, in D2). }

procedure mrh_$release_to_mark(
    in out heap: mrh_$heap_t;
    mark: mrh_$mark_t);
var
  rest: mrh_$chunk_t;                   { (-4,A6) }
  free_before: integer;
begin
  if heap.first_chunk = mrh_$no_chunk then begin
    if mark.chunk <> mrh_$no_chunk then
      bug_check('MRH -- release_to_mark attempted on empty heap%$');
  end
  else if mark.chunk = mrh_$no_chunk then
    mrh_$initialize(heap, heap.flags, heap.default_size,
                    heap_names[heap.heap_index]^)
  else begin
    rest := chunk_table[mark.chunk].next;
    chunk_table[mark.chunk].next := mrh_$no_chunk;
    heap.next.address := segments[mark.chunk div 8];
    heap.next.offset := mark.offset;
    heap.current_chunk := mark.chunk;
    heap.free := mrh_$chunk_size - (mark.offset & (mrh_$chunk_size - 1));
    free_before := free_chunks;
    release_chunk_list(rest, heap.heap_index);
    heap.chunks_in_use := heap.chunks_in_use - (free_chunks - free_before);
  end;
end;
