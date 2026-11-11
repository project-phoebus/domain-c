{ htm - HTM_, hash tables and hashing.  A table (from the RWS heap)
  holds a power of 2 of chained buckets; each entry added is counted
  and the table doubled (its entries rehashed by their keys) when the
  entries outnumber twice the buckets, up to 65536 buckets.  The hashes
  are CRC-32 (the reflected polynomial 16#EDB88320, by a table of 256
  longwords) over the bytes least significant first, from -1, with the
  result's two words exchanged; the running forms carry a CRC on.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x068908  0x06A2E8  htm_$create_table
    0x06896C  0x06A34C  htm_$release_table
    0x0689C8  0x06A3A8  htm_$increment_table_entries
    0x068ABE  0x06A49E  htm_$bucket
    0x068ADE  0x06A4BE  htm_$hash_byte
    0x068B2E  0x06A50E  htm_$hash_word
    0x068BAC  0x06A58C  htm_$hash_long
    0x068C76  0x06A656  htm_$hash_quad
    0x068DE0  0x06A7C0  htm_$hash_string
    0x068E50  0x06A830  htm_$hash_upcased_name
    0x068F08  0x06A8E8  htm_$hash_running_quad_multiple
    0x06907A  0x06AA5A  htm_$hash_running_byte_multiple
    A5 0x14B2F4 (cc.m68k), 0x2CB364 (cc.a88k): the module's data, 0x500
    bytes to mem's.

  Module data: +0 the upcasing table (256 characters, a-z to A-Z, the
  rest themselves); +256 the CRC table.  Both are initialized data
  (.rwdi; the same in both binaries) that no routine writes.

  Every routine is global and loads A5.  Each CRC step is written out
  where the image has it (no loops but the strings').
}
module htm;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/common/source/htm.ins.pas';

type
  { A CRC as a longword, its words, its bytes (b[3] the low one). }
  crc_t = record
    case integer of
      1: (all: integer32);
      2: (high: integer;
          low: integer);
      3: (b: array [0..3] of char);
  end;

var
  upcase: array [0..255] of char := [
    chr(0), chr(1), chr(2), chr(3), chr(4), chr(5), chr(6), chr(7),
    chr(8), chr(9), chr(10), chr(11), chr(12), chr(13), chr(14), chr(15),
    chr(16), chr(17), chr(18), chr(19), chr(20), chr(21), chr(22), chr(23),
    chr(24), chr(25), chr(26), chr(27), chr(28), chr(29), chr(30), chr(31),
    chr(32), '!', '"', '#', '$', '%', '&', chr(39),
    '(', ')', '*', '+', ',', '-', '.', '/',
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', ':', ';', '<', '=', '>', '?',
    '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
    'X', 'Y', 'Z', '[', '\', ']', '^', '_',
    '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g',
    'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
    'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
    'x', 'y', 'z', chr(123), '|', chr(125), '~', chr(127),
    chr(128), chr(129), chr(130), chr(131), chr(132), chr(133), chr(134), chr(135),
    chr(136), chr(137), chr(138), chr(139), chr(140), chr(141), chr(142), chr(143),
    chr(144), chr(145), chr(146), chr(147), chr(148), chr(149), chr(150), chr(151),
    chr(152), chr(153), chr(154), chr(155), chr(156), chr(157), chr(158), chr(159),
    chr(160), chr(161), chr(162), chr(163), chr(164), chr(165), chr(166), chr(167),
    chr(168), chr(169), chr(170), chr(171), chr(172), chr(173), chr(174), chr(175),
    chr(176), chr(177), chr(178), chr(179), chr(180), chr(181), chr(182), chr(183),
    chr(184), chr(185), chr(186), chr(187), chr(188), chr(189), chr(190), chr(191),
    chr(192), chr(193), chr(194), chr(195), chr(196), chr(197), chr(198), chr(199),
    chr(200), chr(201), chr(202), chr(203), chr(204), chr(205), chr(206), chr(207),
    chr(208), chr(209), chr(210), chr(211), chr(212), chr(213), chr(214), chr(215),
    chr(216), chr(217), chr(218), chr(219), chr(220), chr(221), chr(222), chr(223),
    chr(224), chr(225), chr(226), chr(227), chr(228), chr(229), chr(230), chr(231),
    chr(232), chr(233), chr(234), chr(235), chr(236), chr(237), chr(238), chr(239),
    chr(240), chr(241), chr(242), chr(243), chr(244), chr(245), chr(246), chr(247),
    chr(248), chr(249), chr(250), chr(251), chr(252), chr(253), chr(254), chr(255)
    ];
  crc_table: array [0..255] of integer32 := [
    16#00000000, 16#77073096, 16#EE0E612C, 16#990951BA,
    16#076DC419, 16#706AF48F, 16#E963A535, 16#9E6495A3,
    16#0EDB8832, 16#79DCB8A4, 16#E0D5E91E, 16#97D2D988,
    16#09B64C2B, 16#7EB17CBD, 16#E7B82D07, 16#90BF1D91,
    16#1DB71064, 16#6AB020F2, 16#F3B97148, 16#84BE41DE,
    16#1ADAD47D, 16#6DDDE4EB, 16#F4D4B551, 16#83D385C7,
    16#136C9856, 16#646BA8C0, 16#FD62F97A, 16#8A65C9EC,
    16#14015C4F, 16#63066CD9, 16#FA0F3D63, 16#8D080DF5,
    16#3B6E20C8, 16#4C69105E, 16#D56041E4, 16#A2677172,
    16#3C03E4D1, 16#4B04D447, 16#D20D85FD, 16#A50AB56B,
    16#35B5A8FA, 16#42B2986C, 16#DBBBC9D6, 16#ACBCF940,
    16#32D86CE3, 16#45DF5C75, 16#DCD60DCF, 16#ABD13D59,
    16#26D930AC, 16#51DE003A, 16#C8D75180, 16#BFD06116,
    16#21B4F4B5, 16#56B3C423, 16#CFBA9599, 16#B8BDA50F,
    16#2802B89E, 16#5F058808, 16#C60CD9B2, 16#B10BE924,
    16#2F6F7C87, 16#58684C11, 16#C1611DAB, 16#B6662D3D,
    16#76DC4190, 16#01DB7106, 16#98D220BC, 16#EFD5102A,
    16#71B18589, 16#06B6B51F, 16#9FBFE4A5, 16#E8B8D433,
    16#7807C9A2, 16#0F00F934, 16#9609A88E, 16#E10E9818,
    16#7F6A0DBB, 16#086D3D2D, 16#91646C97, 16#E6635C01,
    16#6B6B51F4, 16#1C6C6162, 16#856530D8, 16#F262004E,
    16#6C0695ED, 16#1B01A57B, 16#8208F4C1, 16#F50FC457,
    16#65B0D9C6, 16#12B7E950, 16#8BBEB8EA, 16#FCB9887C,
    16#62DD1DDF, 16#15DA2D49, 16#8CD37CF3, 16#FBD44C65,
    16#4DB26158, 16#3AB551CE, 16#A3BC0074, 16#D4BB30E2,
    16#4ADFA541, 16#3DD895D7, 16#A4D1C46D, 16#D3D6F4FB,
    16#4369E96A, 16#346ED9FC, 16#AD678846, 16#DA60B8D0,
    16#44042D73, 16#33031DE5, 16#AA0A4C5F, 16#DD0D7CC9,
    16#5005713C, 16#270241AA, 16#BE0B1010, 16#C90C2086,
    16#5768B525, 16#206F85B3, 16#B966D409, 16#CE61E49F,
    16#5EDEF90E, 16#29D9C998, 16#B0D09822, 16#C7D7A8B4,
    16#59B33D17, 16#2EB40D81, 16#B7BD5C3B, 16#C0BA6CAD,
    16#EDB88320, 16#9ABFB3B6, 16#03B6E20C, 16#74B1D29A,
    16#EAD54739, 16#9DD277AF, 16#04DB2615, 16#73DC1683,
    16#E3630B12, 16#94643B84, 16#0D6D6A3E, 16#7A6A5AA8,
    16#E40ECF0B, 16#9309FF9D, 16#0A00AE27, 16#7D079EB1,
    16#F00F9344, 16#8708A3D2, 16#1E01F268, 16#6906C2FE,
    16#F762575D, 16#806567CB, 16#196C3671, 16#6E6B06E7,
    16#FED41B76, 16#89D32BE0, 16#10DA7A5A, 16#67DD4ACC,
    16#F9B9DF6F, 16#8EBEEFF9, 16#17B7BE43, 16#60B08ED5,
    16#D6D6A3E8, 16#A1D1937E, 16#38D8C2C4, 16#4FDFF252,
    16#D1BB67F1, 16#A6BC5767, 16#3FB506DD, 16#48B2364B,
    16#D80D2BDA, 16#AF0A1B4C, 16#36034AF6, 16#41047A60,
    16#DF60EFC3, 16#A867DF55, 16#316E8EEF, 16#4669BE79,
    16#CB61B38C, 16#BC66831A, 16#256FD2A0, 16#5268E236,
    16#CC0C7795, 16#BB0B4703, 16#220216B9, 16#5505262F,
    16#C5BA3BBE, 16#B2BD0B28, 16#2BB45A92, 16#5CB36A04,
    16#C2D7FFA7, 16#B5D0CF31, 16#2CD99E8B, 16#5BDEAE1D,
    16#9B64C2B0, 16#EC63F226, 16#756AA39C, 16#026D930A,
    16#9C0906A9, 16#EB0E363F, 16#72076785, 16#05005713,
    16#95BF4A82, 16#E2B87A14, 16#7BB12BAE, 16#0CB61B38,
    16#92D28E9B, 16#E5D5BE0D, 16#7CDCEFB7, 16#0BDBDF21,
    16#86D3D2D4, 16#F1D4E242, 16#68DDB3F8, 16#1FDA836E,
    16#81BE16CD, 16#F6B9265B, 16#6FB077E1, 16#18B74777,
    16#88085AE6, 16#FF0F6A70, 16#66063BCA, 16#11010B5C,
    16#8F659EFF, 16#F862AE69, 16#616BFFD3, 16#166CCF45,
    16#A00AE278, 16#D70DD2EE, 16#4E048354, 16#3903B3C2,
    16#A7672661, 16#D06016F7, 16#4969474D, 16#3E6E77DB,
    16#AED16A4A, 16#D9D65ADC, 16#40DF0B66, 16#37D83BF0,
    16#A9BCAE53, 16#DEBB9EC5, 16#47B2CF7F, 16#30B5FFE9,
    16#BDBDF21C, 16#CABAC28A, 16#53B39330, 16#24B4A3A6,
    16#BAD03605, 16#CDD70693, 16#54DE5729, 16#23D967BF,
    16#B3667A2E, 16#C4614AB8, 16#5D681B02, 16#2A6F2B94,
    16#B40BBE37, 16#C30C8EA1, 16#5A05DF1B, 16#2D02EF8D
    ];

{ htm_$create_table - a table of size buckets.

  0x068908, 0x64 bytes: RWS_$ALLOC_HEAP (0x06892C) of size * 4 + 16 (in
  (-20,A6)); count := 0, size, mask := size - 1, +0 := the mask; a
  `for' from 0 to size - 1 clears bucket i (`clr.l (10,A0,D1.l)').  The
  result left in A0 (and D0).

  Not known from the original:
  - the declaration that puts bucket i at +10 + 4 * i, so that clearing
    bucket 0 clears the size's low word (and the mask's high word);
    no unit of DOMAIN C calls HTM_'s table routines. }

function htm_$create_table(
    size: integer32): htm_$table_ptr_t;
var
  table: htm_$table_ptr_t;
  i: integer32;
begin
  table := rws_$alloc_heap(size * 4 + 16);
  table^.count := 0;
  table^.size := size;
  table^.mask := size - 1;
  table^.mask_copy := table^.mask;
  for i := 0 to size - 1 do
    table^.buckets[i] := nil;
  htm_$create_table := table;
end;

{ htm_$release_table - the table back to the RWS heap.

  0x06896C, 0x3A bytes: RWS_$RELEASE_HEAP (0x068984) of the table (its
  variable's address passed on) and (-4,A6); OK_OR_BUG_CHECK of the
  status and 'HTM -- rws_$release_heap failure%$' (0x0689A6). }

procedure htm_$release_table(
    in table: htm_$table_ptr_t);
var
  status: status_$t;                    { (-4,A6) }
begin
  rws_$release_heap(table, status);
  ok_or_bug_check(status, 'HTM -- rws_$release_heap failure%$');
end;

{ htm_$increment_table_entries - one more entry.

  0x0689C8, 0xF6 bytes: count one more; unless size >= 32768 (unsigned,
  `bcc') or twice size (the low word doubled, zero-extended) >= count:
  htm_$create_table (`bsr') of twice size; its +0 and count from the
  old table; each old bucket's entries moved (a `for' over 0..mask, a
  `while' down each chain) to bucket ((i & old mask) | (key & ~old
  mask)) & new mask, each pushed on its front; the old table released
  (RWS_$RELEASE_HEAP of the variable's value, OK_OR_BUG_CHECK); table :=
  the new one; bucket := key & its mask.  bucket is set only then.

  Not known from the original:
  - the locals' names. }

procedure htm_$increment_table_entries(
    in out table: htm_$table_ptr_t;
    key: integer32;
    out bucket: integer32);
var
  status: status_$t;                    { (-4,A6) }
  new_size: integer32;
  new_table: htm_$table_ptr_t;          { (-16,A6) }
  i: integer32;
  entry: htm_$entry_ptr_t;
  next: htm_$entry_ptr_t;
  b: integer32;
begin
  table^.count := table^.count + 1;
  if table^.size < 32768 then begin
    new_size := table^.size * 2;
    if new_size < table^.count then begin
      new_table := htm_$create_table(new_size);
      new_table^.mask_copy := table^.mask_copy;
      new_table^.count := table^.count;
      for i := 0 to table^.mask do begin
        entry := table^.buckets[i];
        while entry <> nil do begin
          next := entry^.next;
          b := ((i & table^.mask) ! (entry^.key & (~table^.mask)))
               & new_table^.mask;
          entry^.next := new_table^.buckets[b];
          new_table^.buckets[b] := entry;
          entry := next;
        end;
      end;
      rws_$release_heap(table, status);
      ok_or_bug_check(status, 'HTM -- rws_$release_heap failure%$');
      table := new_table;
      bucket := key & new_table^.mask;
    end;
  end;
end;

{ htm_$bucket - key & the table's mask.  0x068ABE, 0x20 bytes. }

function htm_$bucket(
    table: htm_$table_ptr_t;
    key: integer32): integer32;
begin
  htm_$bucket := key & table^.mask;
end;

{ htm_$hash_byte - the hash of b.

  0x068ADE, 0x50 bytes: crc (-4,A6) := -1; one step: b xor crc's low
  byte (`eor.b'), crc shifted right 8 (`lsr.l'), crc xor the table
  entry of that byte (zero-extended, `lsl.w #2', (256,A5,..)); then the
  words exchanged through D0 and the result loaded from (-4,A6). }

function htm_$hash_byte(
    b: char): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  index: integer;
  t: integer;
begin
  crc.all := -1;
  index := xor(ord(b), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_byte := crc.all;
end;

{ htm_$hash_word - the hash of w's bytes, low then high.

  0x068B2E, 0x7E bytes: w stored at (-8,A6); steps with (-7,A6), then
  (-8,A6). }

function htm_$hash_word(
    w: integer): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  v: record                             { (-8,A6) }
    case integer of
      1: (w: integer);
      2: (b: array [0..1] of char);
  end;
  index: integer;
  t: integer;
begin
  v.w := w;
  crc.all := -1;
  index := xor(ord(v.b[1]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[0]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_word := crc.all;
end;

{ htm_$hash_long - the hash of l's bytes, least significant first.

  0x068BAC, 0xCA bytes: l stored at (-8,A6); steps with (-5,A6) ..
  (-8,A6). }

function htm_$hash_long(
    l: integer32): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  v: crc_t;                             { (-8,A6) }
  index: integer;
  t: integer;
begin
  v.all := l;
  crc.all := -1;
  index := xor(ord(v.b[3]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[2]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[1]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[0]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_long := crc.all;
end;

{ htm_$hash_quad - the hash of the quadword (high, low), its bytes
  least significant first.

  0x068C76, 0x16A bytes: high at (-12,A6), low at (-8,A6); steps with
  (-5,A6) down to (-12,A6). }

function htm_$hash_quad(
    high: integer32;
    low: integer32): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  v: record                             { (-12,A6) }
    case integer of
      1: (high: integer32;
          low: integer32);
      2: (b: array [0..7] of char);
  end;
  index: integer;
  t: integer;
begin
  v.high := high;
  v.low := low;
  crc.all := -1;
  index := xor(ord(v.b[7]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[6]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[5]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[4]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[3]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[2]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[1]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  index := xor(ord(v.b[0]), ord(crc.b[3]));
  crc.all := rshft(crc.all, 8);
  crc.all := xor(crc.all, crc_table[index]);
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_quad := crc.all;
end;

{ htm_$hash_string - the hash of the len characters of s.

  0x068DE0, 0x70 bytes: `tst.w D1; ble' past a `for' from 1 to len (a
  `dbf' loop), one step for each s[i] (`move.b (-1,A0,D1.w)'). }

function htm_$hash_string(
    in s: univ htm_$string_t;
    len: integer): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  i: integer;
  index: integer;
  t: integer;
begin
  crc.all := -1;
  for i := 1 to len do begin
    index := xor(ord(s[i]), ord(crc.b[3]));
    crc.all := rshft(crc.all, 8);
    crc.all := xor(crc.all, crc_table[index]);
  end;
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_string := crc.all;
end;

{ htm_$hash_upcased_name - the hash of the name upcased.

  0x068E50, 0xB8 bytes: as htm_$hash_string, each character first
  upcased through the table at +0 (`move.b (0,A5,D4.w)') and stored to
  upcased[i]; then, when len mod 4 (`divs.w #4; swap') is not 0, a
  `for' from 1 to 4 - len mod 4 clears upcased[len + i]. }

function htm_$hash_upcased_name(
    in name: univ htm_$string_t;
    out upcased: univ htm_$string_t;
    len: integer): integer32;
var
  crc: crc_t;                           { (-4,A6) }
  i: integer;
  c: char;
  index: integer;
  t: integer;
begin
  crc.all := -1;
  for i := 1 to len do begin
    c := upcase[ord(name[i])];
    upcased[i] := c;
    index := xor(ord(c), ord(crc.b[3]));
    crc.all := rshft(crc.all, 8);
    crc.all := xor(crc.all, crc_table[index]);
  end;
  if (len mod 4) <> 0 then
    for i := 1 to 4 - (len mod 4) do
      upcased[len + i] := chr(0);
  t := crc.high;
  crc.high := crc.low;
  crc.low := t;
  htm_$hash_upcased_name := crc.all;
end;

{ htm_$hash_running_quad_multiple - crc carried over the quadword
  (high, low), its bytes least significant first.

  0x068F08, 0x172 bytes: crc at (-12,A6), high at (-8,A6), low at
  (-4,A6); steps with (-1,A6) down to (-8,A6), each against crc's low
  byte (-9,A6); the words exchanged. }

function htm_$hash_running_quad_multiple(
    crc: integer32;
    high: integer32;
    low: integer32): integer32;
var
  c: crc_t;                             { (-12,A6) }
  v: record                             { (-8,A6) }
    case integer of
      1: (high: integer32;
          low: integer32);
      2: (b: array [0..7] of char);
  end;
  index: integer;
  t: integer;
begin
  v.high := high;
  v.low := low;
  c.all := crc;
  index := xor(ord(v.b[7]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[6]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[5]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[4]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[3]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[2]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[1]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  index := xor(ord(v.b[0]), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  t := c.high;
  c.high := c.low;
  c.low := t;
  htm_$hash_running_quad_multiple := c.all;
end;

{ htm_$hash_running_byte_multiple - crc carried over b.

  0x06907A, 0x5A bytes: crc at (-4,A6); one step; the words
  exchanged. }

function htm_$hash_running_byte_multiple(
    crc: integer32;
    b: char): integer32;
var
  c: crc_t;                             { (-4,A6) }
  index: integer;
  t: integer;
begin
  c.all := crc;
  index := xor(ord(b), ord(c.b[3]));
  c.all := rshft(c.all, 8);
  c.all := xor(c.all, crc_table[index]);
  t := c.high;
  c.high := c.low;
  c.low := t;
  htm_$hash_running_byte_multiple := c.all;
end;
