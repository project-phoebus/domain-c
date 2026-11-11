{ time - TIME, the compilation's time stamp: taken from the clock once,
  and written as local date, time, time zone and weekday.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x098A8C  0x09A46C  get_time_stamp
    0x098AAE  0x09A48E  cat_time_info
    A5 0x19DF8C (cc.m68k), 0x31DFFC (cc.a88k): the module's data, 4
    bytes (to token's): the time stamp.

  Every routine is global and loads A5.
}
module time;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/time.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/time.ins.pas';
%include 'us/us/ins/vfmt.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/cal.ins.pas';
%include '/sys/ins/cal.ins.pas';

var
  stamp: time_$clockh_t;                { +0 }

{ get_time_stamp - take the time stamp.

  0x098A8C, 0x22 bytes: time_$clock into a local (-8); its first
  longword (the high 32 bits) to +0. }

procedure get_time_stamp;
var
  clock: time_$clock_t;
begin
  time_$clock(clock);
  stamp := clock.high;
end;

{ cat_time_info - the time stamp, written, to the end of s.

  0x098AAE, 0xD2 bytes.  The weekday names (28 bytes at 0x098B84, `Sun
  Mon ... Sat ') are copied to a local (-312).  A clock (-336) of the
  stamp and a low word of 0 gets cal_$apply_local_offset, then
  cal_$decode_time (-280) and cal_$get_info (-328); cal_$weekday of the
  date indexes the names (`lsl.w #2').  vfmt_$encode10 (the format at
  0x098BA0, `%4wd/%2zwd/%2zwd %2rwd:%2zwd:%2zwd %a (%a)%$', into a
  256-character local, -262, its length -264) gets the year, month,
  day, hour, minute, second, the zone's name and 4, the weekday's name
  and 3 (the lengths longword constants at 0x098BCC, 0x098BD0; the last
  argument pushed before the cal_$weekday call); then prtcats(s, the
  text, its length).

  Not known from the original:
  - the locals' names; whether the names were a constant array (the
    image copies them, as for a typed constant used by value); how s
    was passed on to prtcats (time.ins.pas, opened before prtsub's
    insert, declares s with its own type). }

procedure cat_time_info(
    in out s: time_$line_t);
type
  day_names_t = array [0..6] of array [1..4] of char;
var
  clock: time_$clock_t;
  tz: cal_$timezone_rec_t;
  td: cal_$timedate_rec_t;
  len: integer;
  text: array [1..256] of char;
  names: day_names_t;
  wd: cal_$weekday_t;
  four, three: integer32;
  ps: ^prtsub_$line_t;
begin
  names[0] := 'Sun ';
  names[1] := 'Mon ';
  names[2] := 'Tue ';
  names[3] := 'Wed ';
  names[4] := 'Thu ';
  names[5] := 'Fri ';
  names[6] := 'Sat ';
  clock.high := stamp;
  clock.low := 0;
  cal_$apply_local_offset(clock);
  cal_$decode_time(clock, td);
  cal_$get_info(tz);
  wd := cal_$weekday(td.year, td.month, td.day);
  four := 4;
  three := 3;
  vfmt_$encode10('%4wd/%2zwd/%2zwd %2rwd:%2zwd:%2zwd %a (%a)%$', text, 256,
                 len, td.year, td.month, td.day, td.hour, td.minute,
                 td.second, tz.tz_name, four, names[ord(wd)], three);
  ps := addr(s);
  prtcats(ps^, text, len);
end;
