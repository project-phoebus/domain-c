{ misc_server/clib/ins/unix_time.ins.pas - the C library's UNIX_TIME_ insert.

  No copy survives.  It needs time_$clock_t (us/us/ins/time.ins.pas).  The declarations are the source repository's
  com/ins/unix_time.ins.pas (what the SR10.2 /com/bind uses), which
  lang/bind/source's units call.

  Not known from the original: everything about its contents but the
  routine names.
}

type
  { A Unix time: seconds and microseconds since 1970. }
  unix_time_$timeval_t = record
    sec: integer32;
    usec: integer32;
  end;

{ UNIX_TIME_$CLOCK_TO_TIMEVAL - an Apollo clock as a Unix time. }
procedure unix_time_$clock_to_timeval(in mode: integer;
                                      in clock: time_$clock_t;
                                      out tv: unix_time_$timeval_t);
  extern;

{ UNIX_TIME_$TIMEVAL_TO_CLOCK - a Unix time as an Apollo clock. }
procedure unix_time_$timeval_to_clock(in mode: integer;
                                      in tv: unix_time_$timeval_t;
                                      out clock: time_$clock_t);
  extern;
