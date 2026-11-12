/* loc_private.h - the location library's own records, as loc_build.c
 * (cc.m68k 0x086650..0x0876CC) uses them: the holder of a packed
 * location, and the 30-byte node that is a pool, a list or a range.
 *
 * No Apollo copy survives; the layouts are read off loc_build.c's code
 * (offsets in the comments).  The compiler is Apollo's C compiler
 * (PRISM=>68K Rev 6.89): bit fields are allocated from the most
 * significant bit, and structures are aligned to 2 bytes (the node is
 * 30 bytes: loc_node_alloc asks for 30, fix_stmt_based_list copies 30).
 *
 * Not known from the original: every name; the declared types of the
 * bit fields (the image updates them with word and byte operations on
 * +0, so their storage unit is the first word); whether the node was
 * one union, as here, or separate records cast to one another.
 */

/* A packed location: a reference-counted string of location codes
 * (the codes are loc_codes.h's; the strings are built by loc_build's
 * routines and written into the .symbols section by dump_pool).  data
 * holds len bytes and a NUL (strcmp compares holders from len on, in
 * close_all_locs).  The static holders (the first eight registers, the
 * register cache, the unknown location) are permanent and never
 * counted.
 */
typedef struct loc_holder {
    unsigned permanent : 1;     /* +0 bit 15 (`bclr #7', `orib #0xC0') */
    unsigned is_register : 1;   /* +0 bit 14 (`andib #0xBF', the 0x40 tests) */
    unsigned refs : 14;         /* +0 bits 13..0 (`andiw #0x3FFF') */
    unsigned char len;          /* +2 */
    unsigned char data[1];      /* +3: len bytes, then a NUL */
} loc_holder_t;

/* A statement position (a stmt_range's ends): 8 bytes. */
typedef struct loc_pos {
    long line;                  /* +0 */
    short file;                 /* +4 (stmt_range stores file - 1) */
    short byte;                 /* +6 */
} loc_pos_t;

/* A pool, a list or a range (loc_node_alloc's 30 zeroed bytes).
 *
 * pool:  next the first closed list, pool.last the last, pool.size the
 *        bytes the closed lists take (a list's offset in the pool is the
 *        size before it was added; loc_build__pool_size).
 * list:  next its pool while open, the next list in the pool once
 *        closed; list.ranges sorted by start (range_insert), list.deflt
 *        the default location, list.base the start that the first
 *        range's delta is from (open_list's base >> pc_shift, or 0 for
 *        statement ranges), list.stmt_based true for statement ranges.
 * range: range.loc its location; then pc (lo, hi), or stmt (start,
 *        end), until close_range replaces both with the packed bytes
 *        (count, bytes; terminate_list's end-of-list range has count 1
 *        and a zero byte).
 */
typedef struct loc_node {
    struct loc_node *next;                      /* +0 */
    union {
        struct {
            struct loc_node *last;              /* +4 */
            long size;                          /* +8 */
        } pool;
        struct {
            struct loc_node *ranges;            /* +4 */
            loc_holder_t *deflt;                /* +8 */
            long base;                          /* +12 */
            char stmt_based;                    /* +16 */
        } list;
        struct {
            loc_holder_t *loc;                  /* +4 */
            union {
                struct {
                    unsigned long lo;           /* +8 */
                    long fill;                  /* +12 */
                    unsigned long hi;           /* +16 */
                } pc;
                struct {
                    loc_pos_t start;            /* +8 */
                    loc_pos_t end;              /* +16 */
                } stmt;
                struct {
                    unsigned char count;        /* +8 */
                    unsigned char bytes[21];    /* +9..+29 */
                } packed;
            } u;
        } range;
    } u;
} loc_node_t;
