{ lang/lang/source/time.ins.pas - TIME, the compilation's time stamp
  (lang/lang/source/time.pas).

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (time.pas cc.m68k 0x098A8C..0x098B7E and its caller, c_main's cc).

  Not known from the original: the parameter name.
}

type
  { The line cat_time_info appends to: prtsub's line (a varying string
    of at most 256 characters), which this insert, opened before
    prtsub.ins.pas, cannot name. }
  time_$line_t = varying [256] of char;

{ GET_TIME_STAMP - take the time stamp (the clock's high 32 bits) for
  the compilation.  0x098A8C. }
procedure get_time_stamp; extern;

{ CAT_TIME_INFO - the time stamp as local date, time, time zone and
  weekday (`yyyy/mm/dd hh:mm:ss tz (day)') to the end of s.  0x098AAE:
  s by address (c_main passes a module line, a5@(3184)). }
procedure cat_time_info(
    in out s: time_$line_t); extern;
