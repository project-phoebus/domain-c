/* c_initdate - INITDATE, the compilation's date and time for the
 * preprocessor's __DATE__ and __TIME__: the current time as asctime
 * gives it ("Sun Sep 16 01:03:52 1973\n"), its month, day and year
 * copied to c_macro_read's date cell and its hh:mm:ss to its time cell
 * (mr_date, mr_time in macro_read.ins.pas; mu_$initialize quotes them).
 *
 * Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
 *   cc.m68k   cc.a88k
 *   0x053354  0x0535D4  initdate
 *   A5 0x142528 (cc.m68k), 0x2C2528 (cc.a88k): the unit has no data
 *   (c_lex_pp's A5 is the same address).
 *
 * Compiled by Apollo's C compiler (PRISM=>68K Rev 6.89); the unit opens
 * no header file (its .blocks file list is empty), so time, localtime,
 * asctime and strncpy are used undeclared (K&R int functions; the
 * results are taken from D0) and the cells are declared here.
 *
 * initdate, 0x053354, 0x92 bytes: `link #-8' (t at -8), `pea (A5)',
 * `pea (A2)', A5 loaded; time(0) (`clr.l -(SP)', 0x053364), the result
 * stored in t; localtime(&t) (0x053374); asctime of that (0x05337E),
 * kept in A2; then strncpy(0x149684, A2 + 4, 7) (the month and day,
 * `lea (4,A2),A0'), strncpy(0x14968B, A2 + 20, 4) (the year, `movea.l
 * #20,A0; adda.l A2,A0') and strncpy(0x14967C, A2 + 11, 8) (the time):
 * 0x149684 is c_macro_read's data +0x608 (mr_date, 11 characters),
 * 0x14967C its +0x600 (mr_time, 8 characters).  No value is returned
 * (D0 is strncpy's); c_main's cc calls it with no arguments (0x05B1BE).
 *
 * Not known from the original:
 * - the cells' and the locals' names (the binary keeps no names for
 *   them: they are reached absolutely); the declared types of t and of
 *   the asctime result; whether initdate was declared int or void (the
 *   C compiler of the time may not have had void).
 */

extern char mr_time[8];
extern char mr_date[11];

initdate()
{
    long t;
    char *s;

    t = time(0);
    s = (char *) asctime(localtime(&t));
    strncpy(mr_date, s + 4, 7);
    strncpy(mr_date + 7, s + 20, 4);
    strncpy(mr_time, s + 11, 8);
}
