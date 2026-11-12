/* loc_build.c - LOC_BUILD_, the debugger library's location builder,
 * linked into the compiler: pools of location lists for the .symbols
 * section.  A location is a reference-counted holder of a packed string
 * of location codes (a register, a register or section plus an offset
 * with indirections, an m68k or PRISM addressing mode).  A list maps pc
 * ranges or statement ranges to locations, with a default; closing it
 * packs each range's start (as a delta from the previous range) and
 * length into the range's own node and adds the list to its pool, whose
 * running size is the list's offset.  dump_pool writes a pool through
 * the client's writer, in 1000-byte pieces.  debug_sym_dmp.pas and
 * pds.pas call it (us1/us1/lib/dblib/loc/src/loc_build.ins.pas).
 *
 * Image addresses (DOMAIN C 6.9; the unit is the same in both binaries,
 * code and data):
 *   cc.m68k   cc.a88k
   0x086650  0x088030  loc_build__init
   0x0866A8  0x088088  push_scrap
   0x0866BC  0x08809C  pop_scrap
   0x0866D4  0x0880B4  loc_holder_alloc
   0x086782  0x088162  loc_node_alloc
   0x0867D4  0x0881B4  scrap
   0x086800  0x0881E0  loc_holder_dispose
   0x086868  0x088248  loc_build__open_pool
   0x086882  0x088262  loc_build__pool_size
   0x0868A8  0x088288  loc_build__open_list
   0x086902  0x0882E2  next_dump_string
   0x086940  0x088320  next_dump_position
   0x0869AE  0x08838E  fill_buffer
   0x086A3E  0x08841E  loc_build__dump_pool
   0x086AD6  0x0884B6  loc_build__close_pool
   0x086B5E  0x08853E  range_insert
   0x086B92  0x088572  loc_build__default
   0x086BF6  0x0885D6  loc_build__pc_range
   0x086C84  0x088664  loc_build__stmt_range
   0x086D3A  0x08871A  nybble_pack
   0x086DAA  0x08878A  loc_put_family_op
   0x086F28  0x088908  loc_put_clan_op
   0x086F58  0x088938  fix_stmt_based_list
   0x086FFA  0x0889DA  close_range
   0x087100  0x088AE0  close_all_ranges
   0x08714A  0x088B2A  close_all_locs
   0x0871BC  0x088B9C  terminate_list
   0x0871F6  0x088BD6  loc_build__close_list
   0x087284  0x088C64  loc_build__register_loc
   0x08737C  0x088D5C  loc_build__relative_loc
   0x08749C  0x088E7C  loc_build__m68k_indirect_loc
   0x0875D6  0x088FB6  loc_build__prism_mode_loc
   0x0876B2  0x089092  loc_build__unknown_loc
 *   (.blocks lists all 33 at level 2, in reverse order.)
 *
 * A5 0x35319C (cc.m68k), 0x513B44 (cc.a88k).  The module data, A5-8 ..
 * A5+505 (the .rwdi bytes are the same in both binaries; the offsets
 * are with each definition below): at -8 and -4 the cells through which
 * free and malloc are reached (named by the .rwdi relocations; 0 in
 * .rwdi, set when the program is loaded), then the definitions in the
 * order below.  The compiler records only the initializers written
 * (a family's unwritten bytes are not in .rwdi), so the families are
 * arrays of the bytes given: the one at +80 has room for no more than 4
 * (the next is at +84).  Objects of 8 bytes or more start on 16-byte
 * boundaries, smaller ones on 4.
 *
 * Compiled by Apollo's C compiler (PRISM=>68K Rev 6.89), ANSI C: the
 * unit reads stdarg.h (relative_loc's variable arguments), and chars and
 * shorts are passed in 2-byte slots, which needs prototypes.  The global
 * routines load A5; the static ones (no A5 load) use their caller's.
 * Pointers are returned in A0 and D0; the callers read D0.
 *
 * The files the unit read, in order (.blocks): sys5.3/stdarg.h,
 * apollo/base.h, apollo/isp.h, loc.h, loc_private.h, the derived
 * objects loc_codes.h and loc_sets.h
 * (//ivory/.../dervobjs/dblib_locs/loc.ops/h3df592bb.000/loc/), loc_build.h,
 * loc_pack.h.
 *
 * Verified by reading: not compiled (tools/cc_check.sh compiles Pascal
 * only); each routine was written from its disassembly
 * (tools/cc_dis.py) and read back against it, instruction by
 * instruction; the data from tools/cc_data.py; the address table above
 * by tools/cc_addrcheck.py.
 *
 * Not known from the original: every name but the routines'; the
 * header split (the types are in loc_private.h, the prototypes in
 * loc_build.h, the codes are numbers here: loc_codes.h, loc_sets.h,
 * loc.h and loc_pack.h are stubs); the sizes of the local buffers
 * (from the frame offsets: close_range's 20, the location routines'
 * 58 and 118 bytes at most); whether a code is written `*p++ = c' or by
 * a macro.
 */

#include <stdarg.h>
#include <apollo/base.h>
#include <apollo/isp.h>
#include "loc.h"
#include "loc_private.h"
#include "loc/loc_codes.h"
#include "loc/loc_sets.h"
#include "loc_build.h"
#include "loc_pack.h"

extern void *malloc(long);
extern void free(void *);
extern void bcopy(void *, void *, long);
extern void bzero(void *, long);
extern int bcmp(void *, void *, long);
extern int strcmp(char *, char *);
extern int ffs(int);

/* The state of dump_pool's walk (dump_pool's frame, -1034). */
typedef struct {
    long state;                 /* +0: 0 a list's default location, 1 a
                                   range's packed bytes, 2 a range's
                                   location */
    loc_node_t *list;           /* +4 */
    loc_node_t *range;          /* +8 */
    loc_holder_t *loc;          /* +12 */
    unsigned short pos;         /* +16: the bytes of the string written */
} dump_state_t;

/* A5+0: the free lists of nodes (0), of holders of up to 13 bytes (1)
 * and of up to 37 bytes (2), used when the client gives no free
 * routine. */
static void *scrap_lists[3];

/* A5+12, +16, +20: the client's routines (0 in .rwdi). */
static void *(*alloc_func)(long) = NULL;
static void (*free_func)(void *) = NULL;
static long (*dump_func)(long, long, unsigned char *, long) = NULL;

/* A5+24: a pc range's addresses are shifted right by this (init's
 * fourth argument: debug_sym_dmp passes 2 for targets 1..3, else 1). */
static short pc_shift;

/* The families: [0] the nybble form (the code or'ed with a 3-bit
 * operand; 0 for none), [1..4] the codes taking a 1-, 2-, 3- and 4-byte
 * operand (0 for none).  A clan is two families, for a positive and a
 * negative operand.  Named by use. */

/* A5+28, +36: a later piece of a value after 2 and 3 bytes (zero bytes
 * skipped, then the next nonzero ones); +80 below after 1. */
static unsigned char fam_skip2[] = { 0x48, 0x74 };
static unsigned char fam_skip3[] = { 0x50, 0x75, 0x76 };

/* A5+48: nybble_pack's set of the nybble forms whose operand is an
 * even value 2..16, packed as value / 2 - 1 (bit n & 31 of longword
 * n >> 5: codes 40..71, 92..95, 97..108). */
static unsigned long nybble_sets[8] = {
    0x00000000, 0xFFFFFF00, 0xF00000FF, 0x00001FFE, 0x00000000
};

/* A5+80 (4 bytes at most). */
static unsigned char fam_skip1[] = { 0x73 };

/* A5+84: the value is in register n (register_loc). */
static unsigned char fam_register[] = { 0x10, 0x6D, 0x6E };

/* A5+92: register n's contents (relative_loc's kind 2, the base and
 * index registers of m68k_indirect_loc and prism_mode_loc). */
static unsigned char fam_register_base[] = { 0x18, 0x70, 0x71 };

/* A5+100: section n + 1's address (relative_loc's kind 1). */
static unsigned char fam_section[] = { 0x20, 0x58, 0x59, 0x5A, 0x5B };

/* A5+108: relative_loc's kind 4 (a nybble form only: n 0..7). */
static unsigned char fam_kind4[] = { 0xB8 };

/* A5+116: a range's length (close_range). */
static unsigned char fam_length[] = { 0xA0, 0x88, 0x89, 0x8A, 0x8B };

/* A5+124: a statement range's file, when it changes (close_range). */
static unsigned char fam_file[] = { 0xA8, 0x8D, 0x8E };

/* A5+132: a statement range's byte, when not 0 (close_range). */
static unsigned char fam_byte[] = { 0xB0, 0x8F };

/* A5+144: a value that starts an expression (relative_loc's kind 5, an
 * addressing mode's displacement with nothing before it). */
static unsigned char clan_address[10] = {
    0x28, 0x5C, 0x5D, 0x5E, 0x5F,   0x30, 0x61, 0x62, 0x63, 0x64
};

/* A5+160: an offset added to what is before it. */
static unsigned char clan_offset[10] = {
    0x38, 0x65, 0x66, 0x67, 0x68,   0x40, 0x69, 0x6A, 0x6B, 0x6C
};

/* A5+176: a range's start, as a delta from the previous end. */
static unsigned char clan_start[10] = {
    0x90, 0x80, 0x81, 0x82, 0x83,   0x98, 0x84, 0x85, 0x86, 0x87
};

/* A5+192: registers 0..7's locations (6 bytes each: permanent and
 * register, 1 byte 0x10 + n, its NUL; a holder with room for one code
 * and its NUL, also the unknown location's type). */
static struct loc_holder1 {
    unsigned permanent : 1, is_register : 1, refs : 14;
    unsigned char len;
    unsigned char data[2];
} reg_locs[8] = {
    { 1, 1, 0, 1, { 0x10 } }, { 1, 1, 0, 1, { 0x11 } },
    { 1, 1, 0, 1, { 0x12 } }, { 1, 1, 0, 1, { 0x13 } },
    { 1, 1, 0, 1, { 0x14 } }, { 1, 1, 0, 1, { 0x15 } },
    { 1, 1, 0, 1, { 0x16 } }, { 1, 1, 0, 1, { 0x17 } }
};

/* A5+240: the other registers' locations, made once (8 bytes each: a
 * holder with room for 4 bytes of codes and the NUL); A5+496 how
 * many. */
static struct loc_holder4 {
    unsigned permanent : 1, is_register : 1, refs : 14;
    unsigned char len;
    unsigned char data[5];
} reg_cache[32];
static short reg_cache_count = 0;

/* A5+500: the unknown location (permanent, the one code 0x01). */
static struct loc_holder1 unknown_loc = { 1, 0, 0, 1, { 0x01 } };


/* loc_build__init - the library set up: the client's allocator, free
 * routine and writer, and the pc shift; the free lists emptied.
 *
 * 0x086650, 0x58 bytes: free (12) in A1, alloc (8) in A0; both nil
 * (`cmpaw #0' each, `bnes' past) takes malloc and free from the cells at
 * -4 and -8; dump (16) to +20, the shift (20, a word) to +24; the three
 * lists cleared through A2 (`clrl (A2)+' twice, `clrl (A2)': a loop the
 * compiler unrolled, or three assignments).  No result.
 */
void loc_build__init(
    void *(*alloc)(long),
    void (*dealloc)(void *),
    long (*dump)(long, long, unsigned char *, long),
    short shift)
{
    int i;

    if (alloc == NULL && dealloc == NULL) {
        alloc_func = malloc;
        free_func = free;
    } else {
        alloc_func = alloc;
        free_func = dealloc;
    }
    dump_func = dump;
    pc_shift = shift;
    for (i = 0; i < 3; i++)
        scrap_lists[i] = NULL;
}

/* push_scrap - p onto free list kind (its first longword the link).
 *
 * 0x0866A8, 0x14 bytes: no frame; `movel (A5,D0.l),(A0)', `movel
 * A0,(A5,D0.l)' (kind * 4).
 */
static void push_scrap(long kind, void *p)
{
    *(void **) p = scrap_lists[kind];
    scrap_lists[kind] = p;
}

/* pop_scrap - the head of free list kind (nil when empty), unlinked.
 *
 * 0x0866BC, 0x18 bytes: no frame; the head in A0, `beqs' past the
 * unlinking when nil; returned in D0.
 */
static void *pop_scrap(long kind)
{
    void *p;

    p = scrap_lists[kind];
    if (p != NULL)
        scrap_lists[kind] = *(void **) p;
    return p;
}

/* loc_holder_alloc - a holder of the n bytes at bytes, not permanent,
 * register as is_register says, no references.
 *
 * 0x0866D4, 0xAE bytes: size n + 1 (D2); `cmpil #14' / `bgts' takes a
 * holder from list 1 and asks 14, `cmpil #38' from list 2 and 38, else
 * size (D3); none: alloc(D3 + 2) (`movea.l (12,A5)', `jsr (A0)').  Then
 * `bclr #7' (permanent), the flag's bit 6 (`lslb #6', `andib #64'), refs
 * cleared (`andiw #-16384'), len := size - 1 (`subqb #1'), bcopy(bytes,
 * h + 3, size - 1) (0x086764), the NUL at h + 2 + size (`clrb
 * (2,A2,D2.l)').  The holder in A0 and D0.
 *
 * The allocation is 2 more than the size, so a holder of 13 bytes (16
 * from list 1) or of 37 (40 from list 2) has its NUL one past the end;
 * and loc_holder_dispose files a 14-byte holder (from list 2) on list
 * 1.  Kept as the image has them.
 */
static loc_holder_t *loc_holder_alloc(
    unsigned char *bytes, long n, boolean is_register)
{
    long size, asked;
    loc_holder_t *h;

    size = n + 1;
    h = NULL;
    if (size <= 14) {
        h = pop_scrap(1);
        asked = 14;
    } else if (size <= 38) {
        h = pop_scrap(2);
        asked = 38;
    } else
        asked = size;
    if (h == NULL)
        h = (*alloc_func)(asked + 2);
    if (h != NULL) {
        h->permanent = 0;
        h->is_register = is_register;
        h->refs = 0;
        h->len = size - 1;
        bcopy(bytes, h->data, size - 1);
        h->data[size - 1] = 0;
    }
    return h;
}

/* loc_node_alloc - a zeroed node, from list 0 or the allocator.
 *
 * 0x086782, 0x52 bytes: global (loads A5; not in loc_build.h's
 * interface: the library's other modules may call it); `moveq #30,D2'
 * (the size) for alloc and bzero (0x0867BA).  The node in A0 and D0.
 */
loc_node_t *loc_node_alloc(void)
{
    loc_node_t *node;

    node = pop_scrap(0);
    if (node == NULL)
        node = (*alloc_func)(sizeof(loc_node_t));
    if (node != NULL)
        bzero(node, sizeof(loc_node_t));
    return node;
}

/* scrap - p freed: by the client's free routine when it gave one, else
 * onto free list kind.
 *
 * 0x0867D4, 0x2C bytes: `tstl (16,A5)'; `jsr (A0)' with p, or
 * push_scrap(kind, p).  No result.
 */
static void scrap(long kind, void *p)
{
    if (free_func != NULL)
        (*free_func)(p);
    else
        push_scrap(kind, p);
}

/* loc_holder_dispose - one reference to h dropped; at none, h scrapped
 * (on list 2 when len > 14, else list 1).  Nil and permanent holders
 * are left alone.
 *
 * 0x086800, 0x68 bytes: `andb (A2),D0' with 0x80 for permanent; refs
 * less one (`subqw #1', `andiw #16383', merged into the word); tested
 * again (`andw (A2)' with 0x3FFF, `bnes' out); len (`clrl', `moveb
 * (2,A2)') compared with 14 (`ble'); the list number a byte (`moveq'
 * into D2, then `moveb D2,D1', `extw', `extl' for the argument).
 */
static void loc_holder_dispose(loc_holder_t *h)
{
    char kind;

    if (h != NULL && !h->permanent) {
        h->refs--;
        if (h->refs == 0) {
            if (h->len > 14)
                kind = 2;
            else
                kind = 1;
            scrap(kind, h);
        }
    }
}

/* loc_build__open_pool - a new pool.
 *
 * 0x086868, 0x1A bytes: loc_node_alloc's result (0x086874).
 */
loc_node_t *loc_build__open_pool(void)
{
    return loc_node_alloc();
}

/* loc_build__pool_size - the bytes the pool's closed lists take; -1
 * for nil.
 *
 * 0x086882, 0x26 bytes: `moveq #-1,D0', or (8,A0).
 */
long loc_build__pool_size(loc_node_t *pool)
{
    if (pool == NULL)
        return -1;
    return pool->u.pool.size;
}

/* loc_build__open_list - a new list in pool: for statement ranges
 * (stmt_based) base 0, else base >> pc_shift.
 *
 * 0x0868A8, 0x5A bytes: stmt_based (16, a word) in D2; the node's +0 the
 * pool; base (12) shifted by `asrl' (signed) with pc_shift extended to a
 * longword (kept at -16); +16 := stmt_based <> 0 (`sne', `lsrb #7': 1).
 */
loc_node_t *loc_build__open_list(loc_node_t *pool, long base, short stmt_based)
{
    loc_node_t *list;

    list = loc_node_alloc();
    if (list != NULL) {
        list->next = pool;
        list->u.list.base = stmt_based ? 0 : base >> pc_shift;
        list->u.list.stmt_based = stmt_based != 0;
    }
    return list;
}

/* next_dump_string - the counted string the walk is in: a list's
 * default or a range's location (states 0 and 2: the holder from its
 * len), a range's packed bytes (state 1: the node + 8); nil when there
 * is none.
 *
 * 0x086902, 0x3E bytes: no frame; the state compared with 0, 2 (`beqs'
 * to the holder's case) and 1; (12,A0) + 2, (8,A0) + 8.
 */
static unsigned char *next_dump_string(dump_state_t *st)
{
    switch (st->state) {
    case 0:
    case 2:
        if (st->loc != NULL)
            return &st->loc->len;
        break;
    case 1:
        if (st->range != NULL)
            return &st->range->u.range.u.packed.count;
        break;
    }
    return NULL;
}

/* next_dump_position - the walk's next string: after a list's default
 * its first range; after a range's bytes its location, or after the
 * last range the next list's default; after a location the next range.
 * The position in the string 0.
 *
 * 0x086940, 0x6E bytes: no frame; state 0 (`beqs'), 1, 2; `clrw
 * (16,A0)' at the end.
 */
static void next_dump_position(dump_state_t *st)
{
    switch (st->state) {
    case 0:
        st->state = 1;
        st->range = st->list->u.list.ranges;
        st->loc = NULL;
        break;
    case 1:
        if (st->range != NULL) {
            st->state = 2;
            st->loc = st->range->u.range.loc;
        } else {
            st->state = 0;
            if ((st->list = st->list->next) != NULL)
                st->loc = st->list->u.list.deflt;
        }
        break;
    case 2:
        st->state = 1;
        st->range = st->range->next;
        break;
    }
    st->pos = 0;
}

/* fill_buffer - up to 1000 bytes of the walk copied to buf (the
 * strings' bytes without their counts); their number.
 *
 * 0x0869AE, 0x90 bytes: the count in D2 (a word); while the walk has a
 * list (`tstl (A0)' through D5 = st + 4): the string (A2); room 1000 -
 * count (`bles' out), what is left of the string (D4: the count byte
 * `clrw', `moveb', less pos) if less (`bges'), bcopy(s + pos + 1, buf +
 * count, room) (0x086A10; pos zero-extended, count sign-extended); a
 * string not finished (`cmpw D4,D3', `bges') keeps its place (pos +=
 * room) and ends the buffer; else next_dump_position.
 */
static short fill_buffer(dump_state_t *st, unsigned char *buf)
{
    unsigned char *s;
    short count, room, left;

    count = 0;
    while (st->list != NULL) {
        s = next_dump_string(st);
        if (s != NULL) {
            room = 1000 - count;
            if (room <= 0)
                break;
            left = *s - st->pos;
            if (left < room)
                room = left;
            bcopy(s + st->pos + 1, buf + count, room);
            count += room;
            if (room < left) {
                st->pos += room;
                break;
            }
        }
        next_dump_position(st);
    }
    return count;
}

/* loc_build__dump_pool - the pool's lists written through the client's
 * writer, at offset on (handle passed along; pds.pas passes 0).  0 for
 * a nil pool; a write's result when it is not positive; else total.
 *
 * 0x086A3E, 0x98 bytes: the walk's state at -1034 (state 0, the first
 * list, its default when there is one, range nil, pos 0); the buffer
 * at -1008; total in D4, offset in D3, the piece's count in D5.  Each
 * piece (fill_buffer, `bles' out with total) written until done:
 * dump(handle, offset, buf, count) (`movea.l (20,A5)', `jsr (A0)');
 * `tstl D0', `bles' returns it; count less, offset more.  After a
 * piece, `addl D5,D4' adds the count, which the loop has brought to 0:
 * total stays 0 (the caller, pds.pas's dump_loc_pool, does not use the
 * result).  Kept as the image has it.
 */
long loc_build__dump_pool(loc_node_t *pool, long handle, long offset)
{
    dump_state_t st;
    unsigned char buf[1000];
    long total, count, written;

    if (pool == NULL)
        return 0;
    st.state = 0;
    st.list = pool->next;
    if (st.list != NULL)
        st.loc = st.list->u.list.deflt;
    st.range = NULL;
    st.pos = 0;
    total = 0;
    while ((count = fill_buffer(&st, buf)) > 0) {
        while (count > 0) {
            written = (*dump_func)(handle, offset, buf, count);
            if (written <= 0)
                return written;
            count -= written;
            offset += written;
        }
        total += count;
    }
    return total;
}

/* loc_build__close_pool - the pool and its lists, ranges and locations
 * given up; *poolp nil.  -1 when it is nil already.
 *
 * 0x086AD6, 0x88 bytes: the pool in A3, the list in A2, the range in
 * A4.  For each list (its next taken before it is scrapped): its
 * default disposed; then the ranges: the range's location disposed,
 * A4 := (A4) (`movea.l (A4),A4'), and when that is not nil it is
 * scrapped (`pea (A4)', 0x086B28): the image scraps each range's
 * successor, not the range (the first is never scrapped, and the next
 * step reads the scrapped node's link, which push_scrap has just
 * replaced).  No caller in cc.  Kept as the image has it; the list
 * (`if (A2)') and the pool (`if (A3)') scrapped on list 0.  No result
 * but the -1 (`moveq #-1,D0').
 */
int loc_build__close_pool(loc_node_t **poolp)
{
    loc_node_t *pool, *list, *next, *r;

    pool = *poolp;
    if (pool == NULL)
        return -1;
    *poolp = NULL;
    for (list = pool->next; list != NULL; list = next) {
        loc_holder_dispose(list->u.list.deflt);
        r = list->u.list.ranges;
        while (r != NULL) {
            loc_holder_dispose(r->u.range.loc);
            if ((r = r->next) != NULL)
                scrap(0, r);
        }
        next = list->next;
        if (list != NULL)
            scrap(0, list);
    }
    if (pool != NULL)
        scrap(0, pool);
}

/* range_insert - r into the list's ranges, sorted by start (after those
 * with a start not greater).
 *
 * 0x086B5E, 0x34 bytes: r's +8 in D0; A0 the link (the list's +4, then
 * each range, whose link is at +0); `cmpl (8,A2),D0', `blss' stops
 * (unsigned: the pc view, also for statement ranges' lines).  No
 * result.
 */
static void range_insert(loc_node_t *list, loc_node_t *r)
{
    loc_node_t **link, *at;

    link = &list->u.list.ranges;
    while ((at = *link) != NULL && r->u.range.u.pc.lo > at->u.range.u.pc.lo)
        link = &at->next;
    r->next = at;
    *link = r;
}

/* loc_build__default - the list's default location: -1 for a nil
 * list, -2 when it has another; else loc set (and counted unless
 * permanent), 0.
 *
 * 0x086B92, 0x64 bytes: `cmpal A0,A2' (the old against loc); refs + 1
 * (`addqw #1', `andiw #16383') unless bit 7.
 */
int loc_build__default(loc_node_t *list, loc_holder_t *loc)
{
    if (list == NULL)
        return -1;
    if (list->u.list.deflt != NULL && list->u.list.deflt != loc)
        return -2;
    list->u.list.deflt = loc;
    if (!loc->permanent)
        loc->refs++;
    return 0;
}

/* loc_build__pc_range - loc from lo to hi (shifted right by pc_shift,
 * ordered) added to the list: -1 for a nil list or location, else 0
 * (also when no node could be had).
 *
 * 0x086BF6, 0x8E bytes: the test of the list is the flags of `movel
 * (8,A6),D4' (the `moveal' after it sets none); `lsrl D0' (unsigned) on
 * both; `cmpl D3,D2', `bhis' to the swapped stores; loc counted as in
 * default; range_insert (0x086C74).
 */
int loc_build__pc_range(
    loc_node_t *list, loc_holder_t *loc,
    unsigned long lo, unsigned long hi)
{
    loc_node_t *r;

    if (list == NULL || loc == NULL)
        return -1;
    r = loc_node_alloc();
    if (r != NULL) {
        lo >>= pc_shift;
        hi >>= pc_shift;
        if (lo <= hi) {
            r->u.range.u.pc.lo = lo;
            r->u.range.u.pc.hi = hi;
        } else {
            r->u.range.u.pc.lo = hi;
            r->u.range.u.pc.hi = lo;
        }
        r->u.range.loc = loc;
        if (!loc->permanent)
            loc->refs++;
        range_insert(list, r);
    }
    return 0;
}

/* loc_build__stmt_range - loc from statement (line1, file1, byte1) to
 * (line2, file2, byte2) added to the list (the files stored less one):
 * -1 for a nil list or location, else 0.
 *
 * 0x086C84, 0xB6 bytes: `subqw #1' on file1 (D5) and file2 (D2) before
 * the node is had; the six fields stored (byte2 straight from (30,A6)).
 * When line1 > line2 (`cmpl D3,D6', `bles' past; signed) the end is
 * made the start (`movel (A0)+,(16,A2)', `movel (A0),(20,A2)') and then
 * line1, file1, byte1 again (`movel D6,(16,A2)', `movew D5,(20,A2)',
 * `movew D4,(22,A2)'): the range becomes the start alone, where an
 * exchange seems meant.  Kept as the image has it.
 */
int loc_build__stmt_range(
    loc_node_t *list, loc_holder_t *loc,
    long line1, short file1, short byte1,
    long line2, short file2, short byte2)
{
    loc_node_t *r;

    if (list == NULL || loc == NULL)
        return -1;
    file1--;
    file2--;
    r = loc_node_alloc();
    if (r != NULL) {
        r->u.range.u.stmt.start.line = line1;
        r->u.range.u.stmt.start.file = file1;
        r->u.range.u.stmt.start.byte = byte1;
        r->u.range.u.stmt.end.line = line2;
        r->u.range.u.stmt.end.file = file2;
        r->u.range.u.stmt.end.byte = byte2;
        if (line1 > line2) {
            r->u.range.u.stmt.end = r->u.range.u.stmt.start;
            r->u.range.u.stmt.end.line = line1;
            r->u.range.u.stmt.end.file = file1;
            r->u.range.u.stmt.end.byte = byte1;
        }
        r->u.range.loc = loc;
        if (!loc->permanent)
            loc->refs++;
        range_insert(list, r);
    }
    return 0;
}

/* nybble_pack - code with a 3-bit operand in one byte at *out, when
 * code has a nybble form (not 0) and value fits: 1, else 0.  For the
 * codes in nybble_sets value must be even, 2..16 (`1 << value' and
 * 0x15554), and is packed as value / 2 - 1; for the others 0..7.
 *
 * 0x086D3A, 0x70 bytes: code (8, a byte in a 2-byte slot) zero-extended;
 * value (10); `andl (48,A5,D5.l),D4' with D5 = code >> 5 times 4 and D4
 * = 1 << (code & 31); `cmpil #16' / `bhis' and `cmpil #7' / `blss'
 * unsigned; `lsrl #1', `subql #1'; `orb D2,D0' into (A0); the result a
 * byte (`clrb D0', `moveq #1,D0').
 */
static char nybble_pack(unsigned char code, unsigned long value, unsigned char *out)
{
    if (code == 0)
        return 0;
    if (nybble_sets[code >> 5] & (1 << (code & 31))) {
        if (value > 16 || !((1 << value) & 0x15554))
            return 0;
        value = (value >> 1) - 1;
    } else if (value > 7)
        return 0;
    *out = code | value;
    return 1;
}

/* loc_put_family_op - value's codes from family put at p; the end
 * returned (p itself when nothing could be put).
 *
 * value's four bytes (copied to -10 one by one, `moveb (-1,A1),(A0)+'
 * three times and `moveb (A1),(A0)+', and a zero byte after them) are
 * taken in pieces: a piece is the zero bytes skipped (`cmpal D2,A0',
 * `blss' at the end) and the nonzero bytes after them (until the zero
 * byte that ends them).  The first piece starts 3, 2 or 1 bytes in when
 * the family has no 2-, 3- or 4-byte form (`tstw' of family[2], [3],
 * [4]); its code is the family's; a later piece's is by its length,
 * fam_skip1 (+80), fam_skip2 (+28) or fam_skip3 (+36).  A piece is the
 * nybble form when it fits (`tstb D0' after nybble_pack, then `addql
 * #1,A2'), nothing when it is 0 and does not (return p: `movea.l D3,A0'),
 * else the code for its size (`cmpil #256', #65536, #16777216, `bccs'
 * unsigned) and its low 1..4 bytes from -36 (the four tails share
 * their last moves).
 *
 * 0x086DAA, 0x17E bytes: family (8) in A3, value (12), p (16) in D3 and
 * A2; the piece's start in D1, the scan in D2, the piece at -36, the
 * end of the bytes (-6) at -52.
 */
static unsigned char *loc_put_family_op(
    unsigned char *family, unsigned long value, unsigned char *p)
{
    unsigned char bytes[5];
    unsigned char *op, *s, *start, *bp, *vp;
    unsigned long piece;

    op = p;
    bp = bytes;
    vp = (unsigned char *) &value;
    *bp++ = *vp++;
    *bp++ = *vp++;
    *bp++ = *vp++;
    *bp++ = *vp;
    bytes[4] = 0;
    s = bytes;
    if (family[2] == 0)
        s += 3;
    else if (family[3] == 0)
        s += 2;
    else if (family[4] == 0)
        s += 1;
    do {
        start = s;
        piece = 0;
        while (s < &bytes[4] && *s == 0)
            s++;
        while (*s != 0)
            piece = (piece << 8) | *s++;
        if (family == NULL)
            switch (s - start) {
            case 1:
                family = fam_skip1;
                break;
            case 2:
                family = fam_skip2;
                break;
            case 3:
                family = fam_skip3;
                break;
            }
        if (nybble_pack(family[0], piece, op))
            op++;
        else if (piece == 0)
            return p;
        else if (piece < 0x100) {
            *op++ = family[1];
            *op++ = ((unsigned char *) &piece)[3];
        } else if (piece < 0x10000) {
            *op++ = family[2];
            vp = (unsigned char *) &piece + 2;
            *op++ = *vp++;
            *op++ = *vp;
        } else if (piece < 0x1000000) {
            *op++ = family[3];
            vp = (unsigned char *) &piece + 2;
            *op++ = vp[-1];
            *op++ = *vp++;
            *op++ = *vp;
        } else {
            *op++ = family[4];
            vp = (unsigned char *) &piece;
            *op++ = *vp++;
            *op++ = *vp++;
            *op++ = *vp++;
            *op++ = *vp;
        }
        family = NULL;
    } while (s < &bytes[4]);
    return op;
}

/* loc_put_clan_op - value's codes from the clan's positive family, or
 * -value's from its negative one (5 bytes on).
 *
 * 0x086F28, 0x30 bytes: `bpls' on the flags of `movel (12,A6),D2';
 * `negl D2', `addql #5,A2'.
 */
static unsigned char *loc_put_clan_op(
    unsigned char *clan, long value, unsigned char *p)
{
    if (value < 0) {
        value = -value;
        clan += 5;
    }
    return loc_put_family_op(clan, value, p);
}

/* fix_stmt_based_list - in a statement list, a range not in a register
 * that ends where the next one (in a register) starts is exchanged with
 * it (the nodes' contents exchanged, the links kept), so it moves after
 * the register ranges that follow it.
 *
 * 0x086F58, 0xA2 bytes: the range in A1, the next in A0; the holders'
 * 0x40 bits (`lsrw #6', `bnes' past for the first, `beqs' past for the
 * second); the first's +16 against the second's +8, two `cmpml' (after
 * `moveq #1,D0', unused: an inline comparison of the 8-byte positions);
 * three 30-byte copies through -38 (7 longwords and a word each); then
 * the second's link := the first's, the first's := the second.  No
 * result.
 */
static void fix_stmt_based_list(loc_node_t *list)
{
    loc_node_t *r, *next, tmp;

    if ((r = list->u.list.ranges) == NULL)
        return;
    while ((next = r->next) != NULL) {
        if (!r->u.range.loc->is_register
                && next->u.range.loc->is_register
                && r->u.range.u.stmt.end.line == next->u.range.u.stmt.start.line
                && r->u.range.u.stmt.end.file == next->u.range.u.stmt.start.file
                && r->u.range.u.stmt.end.byte == next->u.range.u.stmt.start.byte) {
            tmp = *r;
            *r = *next;
            *next = tmp;
            next->next = r->next;
            r->next = next;
        }
        r = next;
    }
}

/* close_range - r's start (as a delta from *base) and length packed
 * into r (its count at +8, the bytes from +9); for a statement range
 * also its file (when not *file) and bytes (when not 0) at each end.
 * *base := r's end, *file := its end's file; the bytes' number.
 *
 * 0x086FFA, 0x106 bytes: r (8) in A3, base (12) in A4, file (16); the
 * fields read first (start D4, end at -40, the files D3 and D5, the
 * bytes D2 and D6); the codes built at -28 (A2).  The start is put
 * when it differs from *base or something is before it (`cmpal A2,A0',
 * `bccs' past: buf < p); the length (end - start) always.  bcopy(buf,
 * r + 9, n) (0x0870EA), `moveb D2,(8,A3)'.
 */
static long close_range(loc_node_t *r, long *base, short *file)
{
    unsigned char buf[20];
    unsigned char *p;
    long start, end, n;
    short file1, file2, byte1, byte2;

    p = buf;
    start = r->u.range.u.stmt.start.line;
    end = r->u.range.u.stmt.end.line;
    file1 = r->u.range.u.stmt.start.file;
    file2 = r->u.range.u.stmt.end.file;
    byte1 = r->u.range.u.stmt.start.byte;
    byte2 = r->u.range.u.stmt.end.byte;
    if (file1 != *file)
        p = loc_put_family_op(fam_file, file1, p);
    if (byte1 != 0)
        p = loc_put_family_op(fam_byte, byte1, p);
    if (start != *base || buf < p)
        p = loc_put_clan_op(clan_start, start - *base, p);
    if (file2 != file1)
        p = loc_put_family_op(fam_file, file2, p);
    if (byte2 != 0)
        p = loc_put_family_op(fam_byte, byte2, p);
    p = loc_put_family_op(fam_length, end - start, p);
    *base = end;
    *file = file2;
    n = p - buf;
    bcopy(buf, r->u.range.u.packed.bytes, n);
    r->u.range.u.packed.count = n;
    return n;
}

/* close_all_ranges - every range of the list packed (from the list's
 * base, file 0); the bytes they take.
 *
 * 0x087100, 0x4A bytes: base at -12, file at -14 (`movew #0'), the sum
 * in D2.
 */
static long close_all_ranges(loc_node_t *list)
{
    long total;
    long base = list->u.list.base;
    short file = 0;
    loc_node_t *r;

    total = 0;
    for (r = list->u.list.ranges; r != NULL; r = r->next)
        total += close_range(r, &base, &file);
    return total;
}

/* close_all_locs - a range whose location is the same string as the
 * next range's gives it up (disposed, nil: the dump then writes the
 * next one's only); the bytes of the locations kept.
 *
 * 0x08714A, 0x72 bytes: the range in A2, the next in A3; the lengths
 * compared (`cmpb (2,A4),D0'), then strcmp(&loc->len, &next's->len)
 * (0x087184); the length added (`clrl', `moveb (2,A0)') otherwise.
 */
static long close_all_locs(loc_node_t *list)
{
    long total;
    loc_node_t *r, *next;

    total = 0;
    for (r = list->u.list.ranges; r != NULL; r = next) {
        next = r->next;
        if (next != NULL
                && r->u.range.loc->len == next->u.range.loc->len
                && strcmp((char *) &r->u.range.loc->len,
                          (char *) &next->u.range.loc->len) == 0) {
            loc_holder_dispose(r->u.range.loc);
            r->u.range.loc = NULL;
        } else
            total += r->u.range.loc->len;
    }
    return total;
}

/* terminate_list - a last range added: packed count 1, its byte 0 (the
 * list's end), no location.
 *
 * 0x0871BC, 0x3A bytes: the node not tested for nil; `moveb #1,(8,A1)';
 * appended (A2 the last).  No result.
 */
static void terminate_list(loc_node_t *list)
{
    loc_node_t *end, *r, *last;

    end = loc_node_alloc();
    end->u.range.u.packed.count = 1;
    if ((r = list->u.list.ranges) == NULL)
        list->u.list.ranges = end;
    else {
        while (r != NULL) {
            last = r;
            r = r->next;
        }
        last->next = end;
    }
}

/* loc_build__close_list - the list (*listp; then nil) closed: its
 * statement ranges ordered (fix_stmt_based_list), its ranges packed,
 * its repeated locations dropped, its end added; appended to its pool,
 * whose size grows by the list's bytes.  The list's offset in the pool
 * (the size before); -1 for a nil list.
 *
 * 0x0871F6, 0x8E bytes: `tstb (16,A2)'; the default's length (`clrl
 * D2', `moveb (2,A0),D2'), the two sums and 1 for the end in D2; the
 * pool from +0, then +0 := nil, the list appended (`tstl (A0)': the
 * first, else the last's link); `movel (8,A0),D0', `addl D2,(8,A0)'.
 */
long loc_build__close_list(loc_node_t **listp)
{
    loc_node_t *list, *pool;
    long size, offset;

    list = *listp;
    if (list == NULL)
        return -1;
    *listp = NULL;
    if (list->u.list.stmt_based)
        fix_stmt_based_list(list);
    size = 0;
    if (list->u.list.deflt != NULL)
        size = list->u.list.deflt->len;
    size += close_all_ranges(list);
    size += close_all_locs(list);
    terminate_list(list);
    size += 1;
    pool = list->next;
    list->next = NULL;
    if (pool->next == NULL)
        pool->next = list;
    else
        pool->u.pool.last->next = list;
    pool->u.pool.last = list;
    offset = pool->u.pool.size;
    pool->u.pool.size += size;
    return offset;
}

/* loc_build__register_loc - the location of register reg: for 0..7
 * reg_locs' (6 bytes each), else the cached one with the same codes, a
 * new cached one (while there are fewer than 32), or a new holder.
 *
 * 0x087284, 0xF8 bytes: reg (8) zero-extended into D2; `cmpil #7',
 * `bgts'; reg * 6 (`addl D0,D0' ...) + 192.  The codes at -8, bytes 2
 * and 3 cleared first (`moveb #0,(-6,A6)', `moveb (-6,A6),(-5,A6)') so
 * that 4 bytes compare; their number in D2.  The cache searched from
 * the last (`subql #8,A2', `bcss' below +240) with bcmp(h + 3, buf, 4)
 * (0x08730A); `cmpiw #32,(496,A5)', `bges'; the count's old value
 * indexes (`addqw #1'); `orib #-64,(A2)' sets permanent and is_register
 * at once; bcopy(buf, h + 3, 4) (0x08734E); else
 * loc_holder_alloc(buf, n, true) (`st' pushed).
 */
loc_holder_t *loc_build__register_loc(unsigned short reg)
{
    unsigned char buf[4];
    long n;
    struct loc_holder4 *h;

    if (reg <= 7)
        return (loc_holder_t *) &reg_locs[reg];
    buf[3] = buf[2] = 0;
    n = loc_put_family_op(fam_register, reg, buf) - buf;
    h = &reg_cache[reg_cache_count];
    while (--h >= reg_cache)
        if (bcmp(h->data, buf, 4) == 0)
            return (loc_holder_t *) h;
    if (reg_cache_count < 32) {
        h = &reg_cache[reg_cache_count++];
        h->permanent = 1;
        h->is_register = 1;
        h->len = n;
        bcopy(buf, h->data, 4);
        return (loc_holder_t *) h;
    }
    return loc_holder_alloc(buf, n, true);
}

/* loc_build__relative_loc - a location relative to something (kind: 1
 * section reg's address (reg 1-based), 2 register reg's contents, 3 the
 * code 0x72, 4 fam_kind4's form of reg, 5 none: offset is an address),
 * plus offset, then through each longword the nil-ended arguments point
 * at (indirect, plus the longword when not 0), while the codes are not
 * over 100 bytes; an empty location is the code 0x02.
 *
 * 0x08737C, 0x120 bytes: kind (8) and reg (10) words (D2, D3); the
 * switch a jump table on kind - 1 (`cmpiw #4', `bccs'; 0x0873AC); kind
 * 1's `subqw #1,D3' then zero-extended (an unsigned short result, so
 * --reg); offset put when not 0 or kind 5 (clan_address for 5,
 * clan_offset otherwise); the arguments from (12,A6) + 4 (`addql #4,A3'
 * each, the pointer at -4); `cmpil #100', `bgts' out; `moveb #14'; the
 * longword `tstl (A2)', `beqs' back; codes at -118.  loc_holder_alloc
 * (buf, n, false) (`clrw' pushed).
 */
loc_holder_t *loc_build__relative_loc(
    unsigned short kind, unsigned short reg, long offset, ...)
{
    unsigned char buf[118];
    unsigned char *p;
    long *ind;
    va_list ap;

    p = buf;
    switch (kind) {
    case 1:
        p = loc_put_family_op(fam_section, --reg, p);
        break;
    case 2:
        p = loc_put_family_op(fam_register_base, reg, p);
        break;
    case 3:
        *p++ = 0x72;
        break;
    case 4:
        p = loc_put_family_op(fam_kind4, reg, p);
        break;
    }
    if (offset != 0 || kind == 5)
        p = loc_put_clan_op(kind == 5 ? clan_address : clan_offset, offset, p);
    va_start(ap, offset);
    while ((ind = va_arg(ap, long *)) != NULL && p - buf <= 100) {
        *p++ = 0x0E;
        if (*ind != 0)
            p = loc_put_clan_op(clan_offset, *ind, p);
    }
    va_end(ap);
    if (p == buf)
        *p++ = 0x02;
    return loc_holder_alloc(buf, p - buf, false);
}

/* loc_build__m68k_indirect_loc - the location of an m68k addressing
 * mode: base register (32 none) plus disp; for a memory indirect mode
 * (indirect 1 preindexed, 2 postindexed) the fetch before or after the
 * index; the index register (32 none: a word index when its size is
 * under 4) scaled by log2(scale) (`ffs' less 1, at most 3) and added;
 * then the outer displacement.
 *
 * 0x08749C, 0x13A bytes: disp (8) D6, base (12) D5, index (14) D4,
 * index size (16), scale (18), indirect (20) D2, outer (24) D3; codes
 * at -58 (A2).  A displacement is clan_offset's when something is
 * before it (`cmpal A2,A3', `bccs' to clan_address: buf >= p), so is
 * the outer one.  ffs(scale) (0x087548, scale sign-extended) less one
 * is a byte (`tstb D0', `bles'; `cmpb D1,D0' with 3); `moveb #11',
 * then the shift, then `moveb #9'.
 */
loc_holder_t *loc_build__m68k_indirect_loc(
    long disp, unsigned short base_reg, unsigned short index_reg,
    short index_size, short scale, long indirect, long outer)
{
    unsigned char buf[58];
    unsigned char *p;
    char shift;

    p = buf;
    if (base_reg != 32)
        p = loc_put_family_op(fam_register_base, base_reg, p);
    if (disp != 0)
        p = loc_put_clan_op(buf < p ? clan_offset : clan_address, disp, p);
    if (indirect == 1 && buf < p)
        *p++ = 0x0E;
    if (index_reg != 32) {
        p = loc_put_family_op(fam_register_base, index_reg, p);
        if (index_size < 4)
            *p++ = 0x0D;
        shift = ffs(scale) - 1;
        if (shift > 0) {
            *p++ = 0x0B;
            *p++ = shift > 3 ? 3 : shift;
        }
        *p++ = 0x09;
    }
    if (indirect == 2 && buf < p)
        *p++ = 0x0E;
    if (indirect != 0 && outer != 0)
        p = loc_put_clan_op(buf < p ? clan_offset : clan_address, outer, p);
    return loc_holder_alloc(buf, p - buf, false);
}

/* loc_build__prism_mode_loc - the location of a PRISM addressing mode:
 * base register (137 none; a base makes mode 0), then unless mode is 1
 * the displacement (not indexed) or the index register in disp (137
 * none) scaled by log2(scale) and added.
 *
 * 0x0875D6, 0xDC bytes: base (8) D2, mode (10) D0 (`clrw D0' after the
 * base is put), indexed (12), scale (14), disp (16) D3.  The index
 * register's test is `cmpiw #137,D3', a word compare of the longword:
 * written with a cast.  The scale and the codes as in
 * m68k_indirect_loc; codes at -58.  No caller in cc.
 */
loc_holder_t *loc_build__prism_mode_loc(
    unsigned short base_reg, short mode, short indexed, short scale,
    long disp)
{
    unsigned char buf[58];
    unsigned char *p;
    char shift;

    p = buf;
    if (base_reg != 137) {
        p = loc_put_family_op(fam_register_base, base_reg, p);
        mode = 0;
    }
    if (mode != 1) {
        if (indexed == 0)
            p = loc_put_clan_op(buf < p ? clan_offset : clan_address, disp, p);
        else if ((short) disp != 137) {
            p = loc_put_family_op(fam_register_base, disp, p);
            shift = ffs(scale) - 1;
            if (shift > 0) {
                *p++ = 0x0B;
                *p++ = shift > 3 ? 3 : shift;
            }
            *p++ = 0x09;
        }
    }
    return loc_holder_alloc(buf, p - buf, false);
}

/* loc_build__unknown_loc - the unknown location (A5+500).
 *
 * 0x0876B2, 0x1A bytes: `lea (500,A5),A0', returned in D0.
 */
loc_holder_t *loc_build__unknown_loc(void)
{
    return (loc_holder_t *) &unknown_loc;
}
