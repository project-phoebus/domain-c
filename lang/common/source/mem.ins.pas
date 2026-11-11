{ lang/common/source/mem.ins.pas - MEM_, the compilers' storage pools:
  named pools of items allocated from the RWS heap (each item
  disposable) or from an MRH heap (released together, by marks).

  No Apollo copy survives; the headings are read off mem.pas (cc.m68k
  0x0690D4..0x069AEA) and its callers (bvs.pas, pds.pas, c_main.pas's
  preprocess, iosub.pas, ...).  It stands alone: mem.pas opens it first.
  A pool and a mark are opaque here (mem.pas's records).  Values by
  value (val_param).

  Not known from the original: every type and parameter name here.
}

type
  mem_$pool_t = univ_ptr;
  mem_$mark_t = univ_ptr;

  { A pool's name: its characters up to a `%' (at most 200). }
  mem_$name_t = array [1..200] of char;

var (mem_$data$)
  { The item pool (opened by MEM_$RESET): the section mem_$data$
    (cc.m68k 0x2D2B64, 4 bytes), shared by the units that declare it. }
  mem_$item_pool: mem_$pool_t;

{ MEM_$INITIALISE - MRH_$INITIALIZE_MODULE, no pools, then MEM_$RESET.
  0x06967A. }
procedure mem_$initialise; extern;

{ MEM_$RESET - every pool emptied and dropped, then the item pool
  opened again.  0x0696C2. }
procedure mem_$reset; extern;

{ MEM_$OPEN_POOL - a new pool named name: items from the RWS heap when
  use_rws, else from an MRH heap (items of up to 4095 bytes; larger
  ones from the RWS heap).  0x069754: pool by address, name's address,
  use_rws a byte at (16,A6). }
procedure mem_$open_pool(
    out pool: mem_$pool_t;
    in name: univ mem_$name_t;
    use_rws: boolean); options(val_param); extern;

{ MEM_$ALLOC - size bytes from the pool.  0x0697DE. }
function mem_$alloc(
    pool: mem_$pool_t;
    size: integer32): univ_ptr; options(val_param); extern;

{ MEM_$EMPTY_POOL - every item of the pool given back.  0x069888. }
procedure mem_$empty_pool(
    pool: mem_$pool_t); options(val_param); extern;

{ MEM_$DISPOSE - the item p (which becomes nil) given back to the pool,
  which must be an RWS pool.  0x06990C. }
procedure mem_$dispose(
    pool: mem_$pool_t;
    in out p: univ univ_ptr); options(val_param); extern;

{ MEM_$MARK - a mark of the pool's state.  0x0699C6. }
function mem_$mark(
    pool: mem_$pool_t): mem_$mark_t; options(val_param); extern;

{ MEM_$RELEASE - the pool back to the mark (which becomes nil).
  0x069A6A. }
procedure mem_$release(
    in out mark: mem_$mark_t); extern;
