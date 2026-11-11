/* c_run_acpp - running the ANSI C preprocessor (acpp) as a separate
 * process for c_main's preprocess: whether it is installed, running it
 * on an argument vector (its output to a temporary file named from
 * "/tmp/cppaXXXXXX" unless the vector names one), and deleting the
 * temporary file.
 *
 * Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
 *   cc.m68k   cc.a88k
 *   0x05BE38  0x05C0B8  c_run_acpp
 *   0x05BEAA  0x05C12A  c_delete_temp
 *   0x05BECC  0x05C14C  c_cpp_present
 *   A5 0x14A684 (cc.m68k), 0x2CA684 (cc.a88k): the unit's data, the
 *   template "/tmp/cppaXXXXXX" (16 bytes from .rwdi); at (-4,A5) the
 *   cell through which environ is reached (0 in .rwdi, set when the
 *   program is loaded).
 *
 * Compiled by Apollo's C compiler (PRISM=>68K Rev 6.89).  The unit read
 * //us/us/unix/include/sys5.3/stdio.h, sys/types.h, sys/stdsyms.h,
 * sys/stdtypes.h and sys/wait.h, in that order (stdsyms.h and
 * stdtypes.h taken to be included by types.h).  Every routine loads A5.
 *
 * c_main calls these from Pascal: each argument is a Pascal variable
 * passed by address, so the C side sees a pointer to the Pascal pointer
 * (preprocess 0x05A9D4, 0x05AC60, 0x05AC98; cc 0x05B06A, 0x05BBB2).
 *
 * Not known from the original: the parameters' and the template's
 * names; whether the template was static; the declarations of the
 * library routines (mktemp's result is
 * stored as a pointer, fork's and wait's tested as integers).
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>

extern char **environ;

static char cpp_template[] = "/tmp/cppaXXXXXX";

/* c_run_acpp - run argv[0] with argv; the exit status in **status.
 *
 * 0x05BE38, 0x72 bytes: argv (8) in A2, status (12) in A3.  Unless
 * argv[2] begins with '-' (`cmpi.b #45'), argv[2] := mktemp(template)
 * (0x05BE5C; the template is the unit's data, `movea.l A5,A4').  With
 * no name (mktemp failed) **status := 1 and 1 is returned.  Otherwise
 * fork (0x05BE6E): the parent waits (wait(*status)) and returns
 * **status; the child execve(argv[0], argv, environ) (0x05BE90) and,
 * should that return, 0.
 */
c_run_acpp(argv, status)
    char **argv;
    int **status;
{
    if (argv[2][0] != '-')
        argv[2] = mktemp(cpp_template);
    if (argv[2] == 0) {
        **status = 1;
        return 1;
    }
    if (fork() != 0) {
        wait(*status);
        return **status;
    }
    execve(argv[0], argv, environ);
    return 0;
}

/* c_delete_temp - remove the temporary file *name.
 *
 * 0x05BEAA, 0x22 bytes: unlink(*name) (0x05BEBC); 0 (`clr.l D0').
 */
c_delete_temp(name)
    char **name;
{
    unlink(*name);
    return 0;
}

/* c_cpp_present - **found := access(*path, 0): 0 when the file exists.
 *
 * 0x05BECC, 0x2A bytes: access(*path, 0) (0x05BEE0), stored through
 * *found; no return statement (D0 is access's result).
 */
c_cpp_present(found, path)
    int **found;
    char **path;
{
    **found = access(*path, 0);
}
