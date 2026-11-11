{ lang/c_compiler/source/cppansi.ins.pas - running the ANSI C
  preprocessor: the C routines of c_run_acpp.c as c_main's preprocess
  and cc call them.  Opened last by c_main.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (c_run_acpp.c's routines and c_main's call sites).

  Not known from the original: every name but the routines'.
}

{ TODO(pascal) cppansi.ins.pas is read off the call sites only

  Narrow the types when c_main.pas is translated. }

{ C_RUN_ACPP - run the argument vector argv (argv[2] the output file,
  replaced by a temporary name unless it begins with '-') and wait;
  the exit status through status^.  c_run_acpp.c 0x05BE38; preprocess
  0x05AC60 pushes its vector pointer by value and the address of a
  pointer to the status word. }
procedure c_run_acpp(
    argv: univ_ptr;
    var status: univ_ptr); options(val_param); extern;

{ C_DELETE_TEMP - remove the file named by name^.  0x05BEAA; preprocess
  and cc pass the address of argv[2]. }
procedure c_delete_temp(
    var name: univ univ_ptr); extern;

{ C_CPP_PRESENT - found^ := 0 when the file path^ exists (access).
  0x05BECC; preprocess 0x05A9D4. }
procedure c_cpp_present(
    var found: univ_ptr;
    var path: univ_ptr); extern;
