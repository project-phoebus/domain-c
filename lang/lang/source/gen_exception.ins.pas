{ lang/lang/source/gen_exception.ins.pas - GEN_EXCEPTION, the exception
  table's frame and handler records written into the object file
  (lang/lang/source/gen_exception.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries:
  the routines gen_unwind (sub_one, gen_unwind_$dump_exception_table)
  calls, and the one nothing calls.

  Not known from the original: the parameter names.
}

{ GEN_EXCEPTION_$BEGIN_EXCEPTION_COMPILATION - start a compilation's
  exception records.  0x07A0AE: no parameters; no caller in either
  binary. }
procedure gen_exception_$begin_exception_compilation; extern;

{ GEN_EXCEPTION_$WRITE_FRAME_AND_HANDLER_RECORDS - the records of frame
  (its code from start, len bytes, base the table's start) at offset
  in the object file, offset advanced; the result the bytes written.
  0x07A1AE: four longwords by value, offset by address, the result a
  word in D0 (gen_unwind's sub_one). }
function gen_exception_$write_frame_and_handler_records(
    frame: univ_ptr;
    start: integer32;
    len: integer32;
    base: integer32;
    var offset: integer32): integer; options(val_param); extern;

{ GEN_EXCEPTION_$END_TABLE - the frames still referred to, an end
  record, padding to a multiple of 8; the records' heap released.
  0x07A7FE: offset by address, the bytes written in D0
  (gen_unwind_$dump_exception_table). }
function gen_exception_$end_table(
    var offset: integer32): integer; extern;
