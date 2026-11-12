/* loc_build.h - LOC_BUILD_, the location builder's interface: the
 * routines loc_build.c exports (each loads A5: Apollo's C compiler loads
 * it in every external routine and in no static one).
 *
 * No Apollo copy survives; the headings are read off loc_build.c's
 * frames.  The compiler passes a char or a short in a 2-byte slot when a
 * prototype is in scope (relative_loc's kind and register at 8 and 10;
 * debug_sym_dmp pushes them as one longword, 0x50000), so these are
 * prototypes.  The Pascal callers' view is
 * us1/us1/lib/dblib/loc/src/loc_build.ins.pas.
 *
 * Not known from the original: the parameter names; the result types
 * of default, pc_range and stmt_range (they return 0, -1 or -2; the
 * callers ignore them) and of close_pool (-1, or nothing).
 */

struct loc_holder;
struct loc_node;

extern void loc_build__init(
    void *(*alloc_func)(long),
    void (*free_func)(void *),
    long (*dump_func)(long, long, unsigned char *, long),
    short pc_shift);
extern struct loc_node *loc_build__open_pool(void);
extern long loc_build__pool_size(struct loc_node *pool);
extern struct loc_node *loc_build__open_list(
    struct loc_node *pool, long base, short stmt_based);
extern long loc_build__dump_pool(struct loc_node *pool, long handle, long offset);
extern int loc_build__close_pool(struct loc_node **poolp);
extern int loc_build__default(struct loc_node *list, struct loc_holder *loc);
extern int loc_build__pc_range(
    struct loc_node *list, struct loc_holder *loc,
    unsigned long lo, unsigned long hi);
extern int loc_build__stmt_range(
    struct loc_node *list, struct loc_holder *loc,
    long line1, short file1, short byte1,
    long line2, short file2, short byte2);
extern long loc_build__close_list(struct loc_node **listp);
extern struct loc_holder *loc_build__register_loc(unsigned short reg);
extern struct loc_holder *loc_build__relative_loc(
    unsigned short kind, unsigned short reg, long offset, ...);
extern struct loc_holder *loc_build__m68k_indirect_loc(
    long disp, unsigned short base_reg, unsigned short index_reg,
    short index_size, short scale, long indirect, long outer);
extern struct loc_holder *loc_build__prism_mode_loc(
    unsigned short base_reg, short mode, short indexed, short scale,
    long disp);
extern struct loc_holder *loc_build__unknown_loc(void);
