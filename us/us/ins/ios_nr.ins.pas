{ us/us/ins/ios_nr.ins.pas - Apollo's internal IOS_ (non-reentrant) insert (//us/us/ins).

  No copy survives.  objio.pas (lang/bind/source) opens it; nothing
  objio.pas uses is known to come from it.  lang/lang/source/iosub.pas
  opens it after the customer /sys/ins/ios.ins.pas.

  Not known from the original: everything about its contents.
}

type
  ios_nr_$name_t = array [1..256] of char;

{ IOS_$INQ_NAME - the name of the object a stream is open on.
  lang/lang/source/iosub.pas's stream_error (cc.m68k 0x0B5090) passes
  the stream id's slot, a 256-character buffer, a word for the length
  and a status, all by address.  The routine is not in the customer
  /sys/ins/ios.ins.pas; which of iosub's inserts declared it is not
  known (it is placed here). }
procedure ios_$inq_name(
    in id: integer;
    out name: univ ios_nr_$name_t;
    out name_len: integer;
    out status: status_$t); extern;
