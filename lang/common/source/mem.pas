{ mem - MEM_, the compilers' storage pools.  A pool's descriptor (44
  bytes, itself a chunk of the module's pool of descriptors) holds its
  name and kind.  An RWS pool chains its items, each a chunk of the RWS
  heap behind a 16-byte header (next, previous, size), so that each can
  be disposed.  An MRH pool takes items of up to 4095 bytes from an MRH
  heap and larger ones from a second RWS chain; its marks are MRH marks
  with the bytes used.  Totals of the bytes taken are kept for the
  statistics (prf_gspace_in_use and its peak, in PRFPKG).

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x0690D4  0x06AAB4  pool_name_len (internal)
    0x0690F4  0x06AAD4  rws_alloc_chunk (internal)
    0x0691FE  0x06ABDE  rws_dispose_chunk (internal)
    0x0692F2  0x06ACD2  rws_alloc (internal)
    0x069352  0x06AD32  rws_dispose (internal)
    0x06941C  0x06ADFC  rws_empty_pool (internal)
    0x069454  0x06AE34  rws_release (internal)
    0x06951C  0x06AEFC  mrh_alloc (internal)
    0x0695EA  0x06AFCA  mrh_empty_pool (internal)
    0x069610  0x06AFF0  mrh_mark (internal)
    0x069642  0x06B022  mrh_release (internal)
    0x06967A  0x06B05A  mem_$initialise
    0x0696C2  0x06B0A2  mem_$reset
    0x069754  0x06B134  mem_$open_pool
    0x0697DE  0x06B1BE  mem_$alloc
    0x069888  0x06B268  mem_$empty_pool
    0x06990C  0x06B2EC  mem_$dispose
    0x0699C6  0x06B3A6  mem_$mark
    0x069A6A  0x06B44A  mem_$release
    A5 0x14B7F4 (cc.m68k), 0x2CB864 (cc.a88k): the module's data, 0x20
    bytes to pds's.  mem_$item_pool is the section mem_$data$
    (0x2D2B64).

  Module data as the image uses it: +0 the RWS chain of the pools'
  descriptors; +8 an empty RWS chain, never written, copied wherever a
  chain is set up; +16 the bytes taken from MRH heaps; +20 the bytes
  taken from the RWS heap; +24 the open pools.

  The global routines load A5; the module-level helpers, which do not
  (they run on their callers' A5), are internal.  pool_name_len has no
  frame at all (`movea.l (4,SP),A0' ... `rts').
}
module mem;

%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include '/sys/ins/base.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/diag.ins.pas';

const
  header_bytes = 16;                    { an RWS item's header }
  max_mrh_item = 4095;                  { larger items: the RWS chain }

type
  name_ptr_t = ^mem_$name_t;

  { An RWS chunk: the header, then the item. }
  chunk_ptr_t = ^chunk_t;
  chunk_t = record
    next: chunk_ptr_t;                  { +0: older }
    prev: chunk_ptr_t;                  { +4: newer }
    size: integer32;                    { +8: the bytes taken }
    unused_12: integer32;               { +12 }
  end;

  { A chain of RWS chunks and the bytes they take. }
  rws_chain_t = record
    head: chunk_ptr_t;                  { +0: the newest }
    bytes: integer32;                   { +4 }
  end;

  { An MRH heap and the bytes taken from it. }
  mrh_part_t = record
    heap: mrh_$heap_t;                  { +0 }
    bytes: integer32;                   { +20 }
  end;

  { An MRH mark and the bytes used then. }
  mrh_mark_t = record
    mark: mrh_$mark_t;                  { +0 }
    bytes: integer32;                   { +4 }
  end;

  { A pool's descriptor (44 bytes). }
  pool_ptr_t = ^pool_t;
  pool_t = record
    next: pool_ptr_t;                   { +0 }
    name: name_ptr_t;                   { +4 }
    use_rws: boolean;                   { +8 }
    case integer of
      1: (rws: rws_chain_t);            { +12 }
      2: (mrh: mrh_part_t;              { +12 }
          big_rws: rws_chain_t);        { +36 }
  end;

  { A mark (12 bytes, an item of the pool's RWS chain). }
  mark_ptr_t = ^mark_t;
  mark_t = record
    pool: pool_ptr_t;                   { +0 }
    mrh: mrh_mark_t;                    { +4 }
  end;

  quads_ptr_t = ^array [1..16#7FFFFFF] of array [0..3] of integer32;

var
  pool_chain: rws_chain_t;              { +0 }
  empty_chain: rws_chain_t;             { +8 }
  mrh_bytes: integer32;                 { +16 }
  rws_bytes: integer32;                 { +20 }
  pools: pool_ptr_t;                    { +24 }

{ pool_name_len - the characters of the name before its `%', at most
  200; 0 for no name.

  0x0690D4, 0x20 bytes, internal, no frame: `cmpa.l D0,A0; beq' (nil);
  `cmpi.l #200,D0; bcc' out, `cmpi.b #37,(0,A0,D0.l); bne' to the next
  (name^[len + 1], the -1 folded). }

function pool_name_len(
    name: name_ptr_t): integer32; options(val_param); internal;
var
  len: integer32;
begin
  len := 0;
  if name <> nil then
    while (len < 200) and then (name^[len + 1] <> '%') do
      len := len + 1;
  pool_name_len := len;
end;

{ rws_alloc_chunk - a cleared chunk of the RWS heap of at least size
  bytes (a multiple of 16), counted in the chain and the totals.

  0x0690F4, 0xAC bytes, internal: bytes := size, rounded up to 16 when
  size & 15 (`andi.b #-16; addi.l #16'); RWS_$ALLOC_HEAP (0x069124);
  nil: ass_$external_resource_error('MEM_$RWS_ALLOC_CHUNK -- failed to
  allocate %lsd bytes (pool "%qa"), insufficient disk space%$' (0x0691A0),
  bytes, the name and its length in (-16,A6)).  Then bytes div 16
  (`lsr.l #4') passes clearing four longwords each (`subq.l #1; bne');
  chain.bytes, rws_bytes and prf_gspace_in_use grow by bytes,
  prf_gspace_peak follows.

  Not known from the original:
  - how the clearing loop was written (a `for' here). }

procedure rws_alloc_chunk(
    in out chain: rws_chain_t;
    name: name_ptr_t;
    size: integer32;
    out bytes: integer32;
    out chunk: chunk_ptr_t); options(val_param); internal;
var
  name_length: integer32;               { (-16,A6) }
  quads: quads_ptr_t;
  i: integer32;
begin
  if (size & 15) <> 0 then
    bytes := (size & (~15)) + 16
  else
    bytes := size;
  chunk := rws_$alloc_heap(bytes);
  if chunk = nil then begin
    name_length := pool_name_len(name);
    ass_$external_resource_error(
      'MEM_$RWS_ALLOC_CHUNK -- failed to allocate %lsd bytes (pool "%qa"), insufficient disk space%$',
      bytes, name^, name_length);
  end;
  quads := univ_ptr(chunk);
  for i := 1 to bytes div 16 do begin
    quads^[i][0] := 0;
    quads^[i][1] := 0;
    quads^[i][2] := 0;
    quads^[i][3] := 0;
  end;
  chain.bytes := chain.bytes + bytes;
  rws_bytes := rws_bytes + bytes;
  prf_gspace_in_use := prf_gspace_in_use + bytes;
  if prf_gspace_in_use > prf_gspace_peak then
    prf_gspace_peak := prf_gspace_in_use;
end;

{ rws_dispose_chunk - the chunk back to the RWS heap, uncounted.

  0x0691FE, 0x6A bytes, internal: RWS_$RELEASE_HEAP (0x06921C) of the
  chunk (`pea (16,A6)': a value parameter passed by address) and
  (-8,A6); a bad status: ass_$os_error(status, 'MEM_$RWS_DISPOSE_CHUNK
  -- failed to dispose of item, probably not allocated from a rws pool,
  or already previously disposed (pool "%a")%$' (0x069268), the name and
  its length in (-12,A6)); chain.bytes, rws_bytes and prf_gspace_in_use
  less size. }

procedure rws_dispose_chunk(
    in out chain: rws_chain_t;
    name: name_ptr_t;
    chunk: univ_ptr;
    size: integer32); options(val_param); internal;
var
  status: status_$t;                    { (-8,A6) }
  name_length: integer32;               { (-12,A6) }
begin
  rws_$release_heap(chunk, status);
  if status.all <> status_$ok then begin
    name_length := pool_name_len(name);
    ass_$os_error(status,
      'MEM_$RWS_DISPOSE_CHUNK -- failed to dispose of item, probably not allocated from a rws pool, or already previously disposed (pool "%a")%$',
      name^, name_length);
  end;
  chain.bytes := chain.bytes - size;
  rws_bytes := rws_bytes - size;
  prf_gspace_in_use := prf_gspace_in_use - size;
end;

{ rws_alloc - an item of size bytes on the chain.

  0x0692F2, 0x60 bytes, internal: rws_alloc_chunk (0x069316) of size +
  16 into (-8,A6) and (-12,A6); the chunk first on the chain (next the
  old head, prev nil, its size, the old head's prev); the result the
  chunk's address + 16 (`moveq #16; add.l A0'), stored at (-16,A6) and
  returned in A0. }

function rws_alloc(
    in out chain: rws_chain_t;
    name: name_ptr_t;
    size: integer32): univ_ptr; options(val_param); internal;
var
  bytes: integer32;                     { (-8,A6) }
  chunk: chunk_ptr_t;                   { (-12,A6) }
begin
  rws_alloc_chunk(chain, name, size + header_bytes, bytes, chunk);
  chunk^.next := chain.head;
  chunk^.prev := nil;
  chunk^.size := bytes;
  if chain.head <> nil then
    chain.head^.prev := chunk;
  chain.head := chunk;
  rws_alloc := univ_ptr(integer32(chunk) + header_bytes);
end;

{ rws_dispose - the item p off the chain and back to the heap; p := nil.

  0x069352, 0x8A bytes, internal: p nil: ass_$precondition_fail('MEM_$
  RWS_DISPOSE -- cannot dispose of NIL pointer (pool "%a")%$'
  (0x0693DC), the name and its length in (-24,A6)).  The chunk at p -
  16 (`subi.l #16'); its next, prev (A3, A4) and size (-8,A6) kept;
  rws_dispose_chunk; next's prev := prev; prev's next := next, or the
  head := next when there is no prev. }

procedure rws_dispose(
    in out chain: rws_chain_t;
    name: name_ptr_t;
    in out p: univ_ptr); options(val_param); internal;
var
  name_length: integer32;               { (-24,A6) }
  chunk: chunk_ptr_t;
  next: chunk_ptr_t;
  prev: chunk_ptr_t;
  size: integer32;                      { (-8,A6) }
begin
  if p = nil then begin
    name_length := pool_name_len(name);
    ass_$precondition_fail(
      'MEM_$RWS_DISPOSE -- cannot dispose of NIL pointer (pool "%a")%$',
      name^, name_length);
  end;
  chunk := univ_ptr(integer32(p) - header_bytes);
  next := chunk^.next;
  prev := chunk^.prev;
  size := chunk^.size;
  rws_dispose_chunk(chain, name, chunk, size);
  if next <> nil then
    next^.prev := prev;
  if prev <> nil then
    prev^.next := next
  else
    chain.head := next;
  p := nil;
end;

{ rws_empty_pool - every chunk of the chain back to the heap.

  0x06941C, 0x38 bytes, internal: while the head is not nil, the head
  taken off and rws_dispose_chunk'd with its size. }

procedure rws_empty_pool(
    in out chain: rws_chain_t;
    name: name_ptr_t); options(val_param); internal;
var
  chunk: chunk_ptr_t;
begin
  while chain.head <> nil do begin
    chunk := chain.head;
    chain.head := chunk^.next;
    rws_dispose_chunk(chain, name, chunk, chunk^.size);
  end;
end;

{ rws_release - the chunk at mark (a mark item) and every newer one back
  to the heap; mark := nil.

  0x069454, 0x8A bytes, internal: mark nil:
  ass_$precondition_fail('MEM_$RWS_RELEASE -- cannot dispose to NIL
  chunk (pool "%a")%$' (0x0694DE), the name and its length).  The chunk
  at mark - 16; its next (older, D4) kept; then each chunk's prev
  (newer) and size taken before rws_dispose_chunk, until no prev.  The
  older chunk's prev := nil, or the head := nil when there is none.

  Not known from the original:
  - why the head is not set to the older chunk when there is one (the
    image leaves it on the newest chunk disposed). }

procedure rws_release(
    in out chain: rws_chain_t;
    name: name_ptr_t;
    in out mark: univ_ptr); options(val_param); internal;
var
  name_length: integer32;               { (-24,A6) }
  chunk: chunk_ptr_t;
  older: chunk_ptr_t;
  newer: chunk_ptr_t;
  size: integer32;                      { (-8,A6) }
begin
  if mark = nil then begin
    name_length := pool_name_len(name);
    ass_$precondition_fail(
      'MEM_$RWS_RELEASE -- cannot dispose to NIL chunk (pool "%a")%$',
      name^, name_length);
  end;
  chunk := univ_ptr(integer32(mark) - header_bytes);
  older := chunk^.next;
  repeat
    newer := chunk^.prev;
    size := chunk^.size;
    rws_dispose_chunk(chain, name, chunk, size);
    chunk := newer;
  until chunk = nil;
  if older <> nil then
    older^.prev := nil
  else
    chain.head := nil;
  mark := nil;
end;

{ mrh_alloc - an item of size bytes from the MRH heap.

  0x06951C, 0x6C bytes, internal: MRH_$ALLOC (0x069538) of size as a
  word, kept at (-8,A6); nil: ass_$external_resource_error('MEM_$POOL_
  ALLOC -- failed to allocate %lsd bytes (pool "%a") using MRH,
  insufficient disk space%$' (0x069588), size (`pea (16,A6)'), the name
  and its length); part.bytes and mrh_bytes grow by size; the result
  copied to (-12,A6) and returned in A0. }

function mrh_alloc(
    in out part: mrh_part_t;
    name: name_ptr_t;
    size: integer32): univ_ptr; options(val_param); internal;
var
  p: univ_ptr;                          { (-8,A6) }
  name_length: integer32;               { (-16,A6) }
begin
  p := mrh_$alloc(part.heap, size);
  if p = nil then begin
    name_length := pool_name_len(name);
    ass_$external_resource_error(
      'MEM_$POOL_ALLOC -- failed to allocate %lsd bytes (pool "%a") using MRH, insufficient disk space%$',
      size, name^, name_length);
  end;
  part.bytes := part.bytes + size;
  mrh_bytes := mrh_bytes + size;
  mrh_alloc := p;
end;

{ mrh_empty_pool - the MRH heap emptied (MRH_$RELEASE_ALL, 0x0695F6);
  mrh_bytes less part.bytes, part.bytes := 0.

  0x0695EA, 0x26 bytes, internal.  The callers pass the name too; it is
  not read. }

procedure mrh_empty_pool(
    in out part: mrh_part_t;
    name: name_ptr_t); options(val_param); internal;
begin
  mrh_$release_all(part.heap);
  mrh_bytes := mrh_bytes - part.bytes;
  part.bytes := 0;
end;

{ mrh_mark - the MRH heap's mark and the bytes used.

  0x069610, 0x32 bytes, internal: an 8-byte function result, written
  through the address the caller passes first ((8,A6)); MRH_$MARK
  (0x06961C) into (-16,A6), part.bytes into (-12,A6), both copied.  The
  name is not read. }

function mrh_mark(
    in out part: mrh_part_t;
    name: name_ptr_t): mrh_mark_t; options(val_param); internal;
var
  mark: mrh_mark_t;                     { (-16,A6) }
begin
  mark.mark := mrh_$mark(part.heap);
  mark.bytes := part.bytes;
  mrh_mark := mark;
end;

{ mrh_release - the MRH heap back to the mark.

  0x069642, 0x38 bytes, internal: MRH_$RELEASE_TO_MARK (0x069656) of
  the heap and mark.mark (by value); mrh_bytes less what was taken since
  (part.bytes - mark.bytes), part.bytes := mark.bytes.  The name is not
  read. }

procedure mrh_release(
    in out part: mrh_part_t;
    name: name_ptr_t;
    in mark: mrh_mark_t); options(val_param); internal;
var
  released: integer32;
begin
  mrh_$release_to_mark(part.heap, mark.mark);
  released := part.bytes - mark.bytes;
  part.bytes := mark.bytes;
  mrh_bytes := mrh_bytes - released;
end;

{ mem_$initialise - MRH_$INITIALIZE_MODULE (0x069686), pool_chain :=
  empty_chain, no pools, the totals and mem_$item_pool cleared
  (`move.l #0' each), then mem_$reset (`bsr').

  0x06967A, 0x48 bytes. }

procedure mem_$initialise;
begin
  mrh_$initialize_module;
  pool_chain := empty_chain;
  pools := nil;
  rws_bytes := 0;
  mrh_bytes := 0;
  mem_$item_pool := nil;
  mem_$reset;
end;

{ mem_$reset - every pool emptied and dropped; the item pool opened
  again.

  0x0696C2, 0x80 bytes: MRH_$INITIALIZE_MODULE (0x0696D0); for each
  pool: rws_empty_pool of the chain at +12 (whatever the pool's kind),
  then its descriptor back (rws_dispose_chunk of pool_chain, its name,
  it, 44).  The totals and pools cleared; mem_$open_pool (`bsr') of
  mem_$item_pool's address (`move.l #0x2D2B64'), 'mem_$item_pool%'
  (0x069744) and true.

  Not known from the original:
  - whether an MRH pool's heap was meant to be emptied here (the image
    treats +12 as an RWS chain for every pool; MRH_$INITIALIZE_MODULE
    has already dropped the chunks). }

procedure mem_$reset;
var
  pool: pool_ptr_t;
  next: pool_ptr_t;
  name: name_ptr_t;                     { (-4,A6) }
begin
  mrh_$initialize_module;
  pool := pools;
  while pool <> nil do begin
    rws_empty_pool(pool^.rws, pool^.name);
    next := pool^.next;
    name := pool^.name;
    rws_dispose_chunk(pool_chain, name, pool, sizeof(pool_t));
    pool := next;
  end;
  rws_bytes := 0;
  mrh_bytes := 0;
  pools := nil;
  mem_$open_pool(mem_$item_pool, 'mem_$item_pool%', true);
end;

{ mem_$open_pool - a new pool.

  0x069754, 0x8A bytes: rws_alloc_chunk (0x06977C) of pool_chain, the
  name, 44, (-4,A6), (-8,A6); the name's address and use_rws stored;
  an RWS pool: its chain := empty_chain; an MRH pool: MRH_$INITIALIZE
  (0x0697B2) of the heap at +12 with flags 1 and default size 0 (one
  `move.l #65536' push for both words) and the name, part.bytes := 0,
  the big chain := empty_chain.  The descriptor first on pools; pool :=
  it.

  Not known from the original:
  - whether the size was written as 44 or sizeof (dpc's layout of the
    descriptor need not be 44 bytes). }

procedure mem_$open_pool(
    out pool: mem_$pool_t;
    in name: univ mem_$name_t;
    use_rws: boolean);
var
  bytes: integer32;                     { (-4,A6) }
  chunk: chunk_ptr_t;                   { (-8,A6) }
  p: pool_ptr_t;
begin
  rws_alloc_chunk(pool_chain, addr(name), sizeof(pool_t), bytes, chunk);
  p := univ_ptr(chunk);
  p^.name := addr(name);
  p^.use_rws := use_rws;
  if use_rws then
    p^.rws := empty_chain
  else begin
    mrh_$initialize(p^.mrh.heap, 1, 0, name);
    p^.mrh.bytes := 0;
    p^.big_rws := empty_chain;
  end;
  p^.next := pools;
  pools := p;
  pool := p;
end;

{ mem_$alloc - size bytes from the pool.

  0x0697DE, 0x84 bytes: pool nil: ass_$precondition_fail('MEM_$ALLOC --
  NIL pool descriptor%$') (0x069864).  An RWS pool: rws_alloc of its
  chain; else when STD_$IN_RANGE_LOWER_TO_UPPER(size, 0, 4095)
  (0x069822): mrh_alloc, else rws_alloc of the big chain.  The result
  stored at (-8,A6), returned in A0. }

function mem_$alloc(
    pool: mem_$pool_t;
    size: integer32): univ_ptr;
var
  p: pool_ptr_t;
begin
  p := pool;
  if p = nil then
    ass_$precondition_fail('MEM_$ALLOC -- NIL pool descriptor%$');
  if p^.use_rws then
    mem_$alloc := rws_alloc(p^.rws, p^.name, size)
  else if std_$in_range_lower_to_upper(size, 0, max_mrh_item) then
    mem_$alloc := mrh_alloc(p^.mrh, p^.name, size)
  else
    mem_$alloc := rws_alloc(p^.big_rws, p^.name, size);
end;

{ mem_$empty_pool - every item of the pool given back.

  0x069888, 0x5C bytes: pool nil: ass_$precondition_fail('MEM_$EMPTY_
  POOL -- NIL pool descriptor%$') (0x0698E4).  An RWS pool:
  rws_empty_pool of its chain; else mrh_empty_pool and rws_empty_pool of
  the big chain. }

procedure mem_$empty_pool(
    pool: mem_$pool_t);
var
  p: pool_ptr_t;
begin
  p := pool;
  if p = nil then
    ass_$precondition_fail('MEM_$EMPTY_POOL -- NIL pool descriptor%$');
  if p^.use_rws then
    rws_empty_pool(p^.rws, p^.name)
  else begin
    mrh_empty_pool(p^.mrh, p^.name);
    rws_empty_pool(p^.big_rws, p^.name);
  end;
end;

{ mem_$dispose - the item back to an RWS pool.

  0x06990C, 0x5A bytes: pool nil: ass_$precondition_fail('MEM_$DISPOSE
  -- NIL pool descriptor%$') (0x069966); not an RWS pool:
  ass_$precondition_fail('MEM_$DISPOSE -- requested pool %lsd is not the
  item pool%$' (0x06998C), pool (`pea (8,A6)')); rws_dispose of its
  chain, its name and p. }

procedure mem_$dispose(
    pool: mem_$pool_t;
    in out p: univ univ_ptr);
var
  d: pool_ptr_t;
begin
  d := pool;
  if d = nil then
    ass_$precondition_fail('MEM_$DISPOSE -- NIL pool descriptor%$');
  if not d^.use_rws then
    ass_$precondition_fail(
      'MEM_$DISPOSE -- requested pool %lsd is not the item pool%$', pool);
  rws_dispose(d^.rws, d^.name, p);
end;

{ mem_$mark - a mark of the pool.

  0x0699C6, 0x82 bytes: pool nil: ass_$precondition_fail('MEM_$MARK --
  NIL pool descriptor%$') (0x069A48).  A 12-byte item from the pool's
  chain (the big chain for an MRH pool; rws_alloc, 0x069A0C); its pool
  := pool; for an MRH pool its mrh := mrh_mark (0x069A2C, into
  (-36,A6), copied).  The result in A0. }

function mem_$mark(
    pool: mem_$pool_t): mem_$mark_t;
var
  p: pool_ptr_t;
  mark: mark_ptr_t;
begin
  p := pool;
  if p = nil then
    ass_$precondition_fail('MEM_$MARK -- NIL pool descriptor%$');
  if p^.use_rws then
    mark := rws_alloc(p^.rws, p^.name, sizeof(mark_t))
  else
    mark := rws_alloc(p^.big_rws, p^.name, sizeof(mark_t));
  mark^.pool := p;
  if not p^.use_rws then
    mark^.mrh := mrh_mark(p^.mrh, p^.name);
  mem_$mark := mark;
end;

{ mem_$release - the pool back to the mark; mark := nil.

  0x069A6A, 0x82 bytes: mark nil: ass_$precondition_fail('MEM_$RELEASE
  -- NIL mark%$') (0x069AEC).  For an MRH pool mrh_release of the mark's
  mrh (`pea (4,A4)'); then rws_release of the pool's chain (the big one
  for an MRH pool) and the mark item, through a copy at (-8,A6). }

procedure mem_$release(
    in out mark: mem_$mark_t);
var
  m: mark_ptr_t;
  p: pool_ptr_t;
  item: univ_ptr;                       { (-8,A6) }
begin
  if mark = nil then
    ass_$precondition_fail('MEM_$RELEASE -- NIL mark%$');
  m := mark;
  p := m^.pool;
  if not p^.use_rws then
    mrh_release(p^.mrh, p^.name, m^.mrh);
  item := m;
  if p^.use_rws then
    rws_release(p^.rws, p^.name, item)
  else
    rws_release(p^.big_rws, p^.name, item);
  mark := nil;
end;
