/* loc_codes.h - the location codes, a DSEE derived object built from
 * dblib_locs' loc.ops (opened by loc_build.c after loc_private.h).
 * No Apollo copy survives.
 *
 * TODO(c) loc_codes.h not reconstructed.  The codes loc_build.c uses
 * appear there as numbers with their use (the names are not known):
 *   0x02  an empty relative location (relative_loc)
 *   0x09  add (after an index register, m68k_indirect_loc and
 *         prism_mode_loc)
 *   0x0B  scale by 2 ** n (n the next byte, at most 3)
 *   0x0D  a word index (m68k_indirect_loc, index size < 4)
 *   0x0E  indirect (fetch through the address)
 *   0x72  relative_loc's kind 3
 * and the family and clan tables in loc_build.c's data (their bytes are
 * codes: a nybble form, then the 1-, 2-, 3- and 4-byte operand forms).
 */
