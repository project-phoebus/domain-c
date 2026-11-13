{ reg_alloc - the m68k register allocator's driver: the live ranges of
  the variables assigned at the routine's numbered statements, of its
  cse parents and of the constants its loops use (reg_life); ranges of
  one object that meet are joined; their costs (reg_cost_68k), their
  interference (reg_life) and colouring (reg_color_68k); ranges of one
  object given one register joined again; the loads and stores
  (reg_action), the registers each block starts with, the variables
  that got none given frame (or static) offsets, and the debugger's
  view (reg_vars).  Its pool of 32K chunks holds the conflict cells
  and the ranges' block lists; opt_main_20 holds the ranges and their
  bit vectors.

  Image addresses (DOMAIN C 6.9; cc.m68k only):
    cc.m68k   cc.a88k
    0x0C39A0  --------  dump_lifetime_endpoint
    0x0C3A00  --------  dump_lifetimes
    0x0C3D90  --------  initpool
    0x0C3DE2  --------  freepools
    0x0C3DF6  --------  release_space
    0x0C3E0A  --------  newconflict
    0x0C3E3E  --------  align
    0x0C3E78  --------  alloc_comp_vars
    0x0C41C4  --------  alloc_ftn_vars
    0x0C4476  --------  test_stmt
    0x0C44C4  --------  compress_graph
    0x0C45B6  --------  find_prev
    0x0C45F8  --------  defined_var
    0x0C487E  --------  editregassign
    0x0C4A62  --------  reg_alloc
    A5 0x2D256C (cc.m68k): the module's data, 16 bytes (no .rwdi
    record): reg_alloc.ins.pas's reg_pool +0, reg_ranges +4,
    reg_nranges +8, reg_nest +0xA, reg_words +0xC.

  initpool, newconflict, test_stmt and reg_alloc load A5 (global;
  reg_alloc.ins.pas, g_opt.ins.pas); the others are internal (find_prev
  a leaf without a frame, docs/rev889-patterns.md 16), defined_var and
  editregassign nested in reg_alloc.  dump_lifetimes runs on reg_alloc's
  A5 and writes its line's end on the standard output at (-4,A5).

  The ranges are reg_alloc.ins.pas's reg_range_t, the statements and
  blocks g_opt.ins.pas's views, the variables (109, 110) and the
  routine block il_180^ by offset (il.ins.pas): a variable's +28 its
  type, +32 flags (bit 18: given storage here), +36 its size
  descriptor (bits, a longword, a word), +56 its offset, +72 its
  class; a Fortran variable's (110) +10 low nibble its size class, +11
  high nibble its class, +12 its offset, +24 flags; the routine
  block's +80, +112 and +176 frame offsets, +96 a function's result,
  +192 its static section (+20, +24 offsets), +296 its name, +376 bit
  7 and +377 bits 6..4 (2 Fortran).

  Not known from the original: the locals' and parameters' names; the
  size descriptors' type (copied whole from 10-byte constants after
  alloc_comp_vars, written here as three stores).

  dpc gaps (docs/dpc-gaps.md): 4 (dump_lifetimes' `writeln'), 8 (`in'
  on the node kind sets).
}
module reg_alloc;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/reg_alloc.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/g_opt.ins.pas';
%include 'lang2/source/ftn/source/f_hash.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/common/source/std.ins.pas';

type
  { What type_exp tells of a variable's type (c_objtype.ins.pas's
    type_exp_t, which this unit does not open): its size in bytes at
    +16. }
  ra_texp_t = record
    unused_0: array [0..3] of integer32;  { +0 }
    size: integer32;                    { +16 }
    unused_20: array [0..2] of integer32;  { +20 }
  end;

  { A block's register contents at its entry (editregassign: a kind
    178 node of 196 bytes, a block's +24 as cg_top's basicblock reads
    it, the entries as cg.ins.pas's cg_cache_t): by register, the
    object it holds and the object's register class. }
  ra_cache_t = record
    obj: il_$node_ptr_t;                { +0 }
    size: integer;                      { +4 }
    load: boolean;                      { +6 }
    live: boolean;                      { +7 }
  end;
  ra_regs_ptr_t = ^ra_regs_t;
  ra_regs_t = record
    unused_0: integer;                  { +0 }
    kind: il_$kind_t;                   { +2 }
    ent: array [0..23] of ra_cache_t;   { +4 }
  end;

define
  reg_pool, reg_ranges, reg_nranges, reg_nest, reg_words, initpool,
  newconflict, test_stmt, reg_alloc;

{ dump_lifetime_endpoint - point p of a bit vector as the statement it
  is at (from 1): o before it for the point after the statement, i
  after it for the point before.

  0x0C39A0, 0x54 bytes: p a word (`btst #0' for odd); p div 2 + 1 by
  `asr.l' with the negative correction, a longword in a frame
  temporary passed by address. }

procedure dump_lifetime_endpoint(
    p: integer); options(val_param); internal;
var
  n: integer32;
begin
  if odd(p) then
    vfmt_$write('o%$');
  n := p div 2 + 1;
  vfmt_$write('%d%$', n);
  if not odd(p) then
    vfmt_$write('i%$');
end;

{ dump_lifetimes - under -DUMP68 RA, the n ranges r^[1..n] at stage s
  (len characters): for each its number, node, name (up to 12
  characters of a variable's), the statements it spans, its register
  and the runs of points of its bit vector ([ start..end ]).

  0x0C3A00, 0x2E6 bytes: the heading's string at 0x0C3D34 begins with
  a newline byte (0x0A) and ends `%.'; the routine's name is il_180's
  +296 node (an identifier: its length +16 and characters +18); the
  names' lengths zero-extended and limited to 12 (`cmpi.l #12; ble');
  a parameter's (110) length and characters at +70, +72; the
  statements' nodes are their opt_4009c entries (0x312F8C), the
  numbers zero-extended; the register's classes by unsigned compares
  (`cmpi.w #7; bhi', 8..15); the bit vector's longwords k (from 1, k
  a word in D5) tested whole (`tst.l'), a run starting at bit 0 when
  the previous longword's bit 31 is clear (`tst.l; bmi'), ending at
  bit 31 when the next longword's bit 0 is clear (`lsr.b #1; bcs');
  the inner loop's counter (D2) incremented between its two tests
  and compared `cmpi.w #31; bcs' at its end, the first test's b + 1
  range-checked (`cmpi #31; bcs'); `addq.l #2' after ' [ %$' leaves the
  pad of dump_lifetime_endpoint's word (docs/rev889-patterns.md 51);
  the line ended by PAS_$WRITELN on (-4,A5).  nest (+14) is not read.

  Not known from the original:
  - how the newline was put in the heading's string (written with the
    reference's (10) notation); the loops' form. }

procedure dump_lifetimes(
    r: reg_ranges_ptr_t;
    n: integer;
    nest: integer;
    in s: univ prtsub_$chars_t;
    len: integer32); options(val_param); internal;
var
  i: integer;
  k: integer;
  b: integer;
  v: integer32;
  w: integer32;
  t: il_$node_ptr_t;
begin
  vfmt_$write(''(10)'reg_alloc lifetimes for routine %A %A%.',
              il_180^.xp[74]^.idnt_name, il_180^.xp[74]^.idnt_len, s, len);
  for i := 1 to n do
    if r^[i].node <> nil then begin
      v := i;
      vfmt_$write('%3LD %8ZLH  %$', v, r^[i].node);
      t := r^[i].node;
      if t^.kind = var_name then begin
        v := t^.xp[1]^.idnt_len;
        if v > 12 then
          v := 12;
        vfmt_$write('%13ZA%$', t^.xp[1]^.idnt_name, v);
      end
      else if t^.kind = fortran_symbol then begin
        v := t^.xw[35];
        if v > 12 then
          v := 12;
        vfmt_$write('%13ZA%$', t^.xc[72], v);
      end
      else
        vfmt_$write('             %$');
      v := r^[i].last;
      w := r^[i].first;
      vfmt_$write('  LR start %3LD %8ZLH   LR end %3LD %8ZLH  %$',
                  w, opt_4009c[r^[i].first], v, opt_4009c[r^[i].last]);
      if r^[i].reg <= 7 then begin
        w := r^[i].reg;
        vfmt_$write('d%d  %$', w);
      end
      else if (r^[i].reg >= 8) and (r^[i].reg <= 15) then begin
        w := r^[i].reg - 8;
        vfmt_$write('a%d  %$', w);
      end
      else if r^[i].reg = 31 then
        vfmt_$write('not %$')
      else begin
        w := r^[i].reg - 16;
        vfmt_$write('fp%d %$', w);
      end;
      if r^[i].live <> nil then
        for k := 1 to reg_words do
          if r^[i].live^[k - 1] <> [] then begin
            if (0 in r^[i].live^[k - 1]) and
               ((k = 1) or not (31 in r^[i].live^[k - 2])) then begin
              vfmt_$write(' [ %$');
              dump_lifetime_endpoint((k - 1) * 32);
              vfmt_$write('..%$');
            end;
            b := 0;
            while b < 31 do begin
              if (b in r^[i].live^[k - 1]) and
                 not ((b + 1) in r^[i].live^[k - 1]) then begin
                dump_lifetime_endpoint((k - 1) * 32 + b);
                vfmt_$write(' ] %$');
              end;
              b := b + 1;
              if (b in r^[i].live^[k - 1]) and
                 not ((b - 1) in r^[i].live^[k - 1]) then begin
                vfmt_$write(' [ %$');
                dump_lifetime_endpoint((k - 1) * 32 + b);
                vfmt_$write('..%$');
              end;
            end;
            if (31 in r^[i].live^[k - 1]) and
               ((k = reg_words) or not (0 in r^[i].live^[k])) then begin
              dump_lifetime_endpoint((k - 1) * 32 + 31);
              vfmt_$write(' ] %$');
            end;
          end;
      writeln;
    end;
end;

{ initpool - a new chunk of 32768 bytes (and its header) from
  opt_main_24 on reg_pool.

  0x0C3D90, 0x52 bytes: mem_$alloc of 32776 bytes; a nil one reported
  (cgerr_no_source(9, 0), its 6 bytes padded to 8 and not popped). }

procedure initpool;
var
  p: reg_chunk_ptr_t;
begin
  p := mem_$alloc(opt_main_24, 32776);
  if p = nil then
    cgerr_no_source(9, 0);
  p^.next := reg_pool;
  p^.free := 32768;
  reg_pool := p;
end;

{ freepools - reg_pool's chunks given back (opt_main_24 emptied).

  0x0C3DE2, 0x14 bytes. }

procedure freepools; internal;
begin
  mem_$empty_pool(opt_main_24);
end;

{ release_space - the ranges and bit vectors given back (opt_main_20
  emptied).

  0x0C3DF6, 0x14 bytes. }

procedure release_space; internal;
begin
  mem_$empty_pool(opt_main_20);
end;

{ newconflict - 8 bytes from the end of reg_pool's free space for a
  conflict cell; a new chunk first when fewer than 6 bytes are left.

  0x0C3E0A, 0x34 bytes: `cmpi.l #6; bge'; the cell's address
  (`lea (8,A0,D0.l)') left in A0. }

function newconflict: reg_conflict_ptr_t;
begin
  if reg_pool^.free < 6 then
    initpool;
  reg_pool^.free := reg_pool^.free - 8;
  newconflict := addr(reg_pool^.data[reg_pool^.free]);
end;

{ align - x rounded to a multiple of 2 ** shift: up when down is 0,
  else down.

  0x0C3E3E, 0x3A bytes: the mask -1 shifted left (`lsl.l D1'); x
  changed only when it is not a multiple; down a word tested
  `tst.w' (the callers push 0 and 1). }

procedure align(
    var x: integer32;
    shift: integer;
    down: integer); options(val_param); internal;
var
  m: integer32;
begin
  m := lshft(-1, shift) & x;
  if m <> x then
    if down = 0 then
      x := m + lshft(1, shift)
    else
      x := m;
end;

{ alloc_comp_vars - storage for the variables (109) of the n ranges
  r^[1..n] that the allocator took into its hands and that got no
  register (a language other than Fortran).

  First each such variable not yet given storage (+32 bit 18 clear)
  gets its size descriptor: a longword's (32 bits, class 2) when its
  range may have an address register (flags element 2, or A0..A3 in
  avail), else a short's (16 bits, class 1) when its type, or its
  type's +28, is the type at runbackend_10, else a longword's.  Then,
  by alignment 4, 2 and 1, each variable of class other than 3 and 10,
  without an offset and not of a type of kind 107 or 108, that is as
  large as the alignment gets class 2 and storage (marked by bit 18):
  a static (class 1 or 4) in its routine's static section at +20, or
  at +24 (class 7 or 8) when +20 would pass 24576 bytes and the -CPU
  is not M020 (3: 16-bit displacements); a local below the frame's
  +112 or +80, whichever is lower, or at +176 (class 6) when the frame
  would pass -24576.  At the end the offsets are aligned to 2 and +80
  takes the lower of +112 and +80.

  0x0C3E78, 0x338 bytes, link #-72: the first loop by `dbf'; the
  descriptors copied from 0x0C41B0 (00000020 00000000 0002) and
  0x0C41BA (00000010 00000000 0001) to +36 (`move.l; move.l;
  move.w'); runbackend_0c's address loaded into D2 and not used
  (docs/rev889-patterns.md 53); the alignments (D3) 2 down to 0 by a
  count in the frame, the alignment's bytes (D6) 1 shifted left; the
  second loop enters without testing n (`cmp.w (12,A6),D5; ble' at its
  end only); type_exp of the variable into a frame record (-32), its
  size (-16) set to 4 for an address register's range and made even
  (`btst #0,(-13,A6)'); the type's kinds evaluated whole (`seq; seq;
  or.b; bmi', docs/rev889-patterns.md 29); the far tests `lsr.l #2' of
  32768 less the offset (or the frame's +112 plus 31000), signed
  compares; the frame's choice `if +112 <= +80 ... else if +112 > +80'
  (`ble' on the same operands); D0 is left as the last value it held.

  Not known from the original: the descriptors' type; the classes'
  meaning (1 and 4 static, 7 and 8 their far forms, 6 a far local). }

procedure alloc_comp_vars(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); internal;
var
  k: integer;
  short: boolean;
  shift: integer;
  a: integer32;
  v: il_$node_ptr_t;
  sect: il_$node_ptr_t;
  d: ra_texp_t;
begin
  for k := 1 to n do begin
    v := r^[k].node;
    if (v^.kind = var_name) and ((v^.xl[8] & 16#40000) = 0) then begin
      if (2 in r^[k].flags) or (r^[k].avail * [8..11] <> []) then
        short := false
      else if v^.xp[7] = runbackend_10 then
        short := true
      else if v^.xp[7] = runbackend_0c then
        short := false
      else if v^.xp[7]^.xp[7] = runbackend_10 then
        short := true
      else
        short := false;
      if short then begin
        v^.xl[9] := 16;
        v^.xl[10] := 0;
        v^.xw[22] := 1;
      end
      else begin
        v^.xl[9] := 32;
        v^.xl[10] := 0;
        v^.xw[22] := 2;
      end;
    end;
  end;
  for shift := 2 downto 0 do begin
    a := lshft(1, shift);
    k := 1;
    repeat
      v := r^[k].node;
      if (v^.kind = var_name) and ((v^.xl[8] & 16#40000) = 0) and
         (v^.xw[36] <> 3) and (v^.xl[14] = 0) and (v^.xw[36] <> 10) and
         not ((v^.xp[7]^.kind = function_blk)
              or (v^.xp[7]^.kind = procedure_blk)) then begin
        v^.xw[36] := 2;
        type_exp(v, addr(d));
        if 2 in r^[k].flags then
          d.size := 4;
        if odd(d.size) then
          d.size := d.size + 1;
        if d.size >= a then begin
          v^.xl[8] := v^.xl[8] ! 16#40000;
          if (v^.xw[36] = 1) or (v^.xw[36] = 4) then begin
            sect := il_180^.xp[48];
            if (sect^.xl[5] + d.size > 24576) and
               (rshft(32768 - sect^.xl[5], 2) < d.size) and
               not (3 in cargs_$options.cpu) then begin
              align(sect^.xl[6], shift, 0);
              v^.xl[14] := il_180^.xp[48]^.xl[6];
              il_180^.xp[48]^.xl[6] := il_180^.xp[48]^.xl[6] + d.size;
              if v^.xw[36] = 1 then
                v^.xw[36] := 7
              else
                v^.xw[36] := 8;
            end
            else begin
              align(sect^.xl[5], shift, 0);
              v^.xl[14] := il_180^.xp[48]^.xl[5];
              il_180^.xp[48]^.xl[5] := il_180^.xp[48]^.xl[5] + d.size;
            end;
          end
          else if (il_180^.xl[28] - d.size < -24576) and
                  (rshft(il_180^.xl[28] + 31000, 2) < d.size) and
                  not (3 in cargs_$options.cpu) then begin
            align(il_180^.xl[44], shift, 0);
            v^.xw[36] := 6;
            v^.xl[14] := il_180^.xl[44];
            il_180^.xl[44] := il_180^.xl[44] + d.size;
          end
          else if il_180^.xl[28] <= il_180^.xl[20] then begin
            il_180^.xl[28] := il_180^.xl[28] - d.size;
            align(il_180^.xl[28], shift, 1);
            v^.xl[14] := il_180^.xl[28];
          end
          else if il_180^.xl[28] > il_180^.xl[20] then begin
            il_180^.xl[20] := il_180^.xl[20] - d.size;
            align(il_180^.xl[20], shift, 1);
            v^.xl[14] := il_180^.xl[20];
          end;
        end;
      end;
      k := k + 1;
    until k > n;
  end;
  align(il_180^.xp[48]^.xl[5], 1, 0);
  align(il_180^.xp[48]^.xl[6], 1, 0);
  align(il_180^.xl[44], 1, 0);
  align(il_180^.xl[28], 1, 1);
  if il_180^.xl[28] < il_180^.xl[20] then
    il_180^.xl[20] := il_180^.xl[28];
end;

{ alloc_ftn_vars - storage for Fortran's strength reduction
  temporaries (110) among the n ranges r^[1..n] that got no register:
  by alignment 4, 2 and 1, each not yet given storage (+24 bit 18
  clear) whose size (by its +10 size class: 1, 2, 4 for classes 3, 4
  and 11, 8 for 5, 0 otherwise; 4 for an address register's range) is
  as large as the alignment gets class 6 (+11's high nibble), bit 18
  and an offset (+12): a static's (classes 1, 4, 7, 8, 11: not met,
  the class was just set to 6) in the static section as
  alloc_comp_vars does (class 7 far, 1 near), else in the frame as
  alloc_comp_vars does (class 6 kept for the far form).  The offsets
  are aligned at the end as there.

  0x0C41C4, 0x2B2 bytes, link #-24: the alignments (D5) 2 down to 0,
  the bytes (-8); the ranges by `dbf' (D6); the size class by a jump
  table over 1..11 (0x0C4254, D1 cleared before it); the class stored
  `andi.b #15; or.b #0x60' and read back for the static test (`btst'
  in 0x0992: 1, 4, 7, 8, 11); the far tests as alloc_comp_vars's. }

procedure alloc_ftn_vars(
    r: reg_ranges_ptr_t;
    n: integer); options(val_param); internal;
var
  shift: integer;
  k: integer;
  a: integer32;
  sz: integer;
  cls: integer;
  v: il_$node_ptr_t;
  sect: il_$node_ptr_t;
begin
  for shift := 2 downto 0 do begin
    a := lshft(1, shift);
    for k := 1 to n do begin
      v := r^[k].node;
      if v^.kind = fortran_symbol then
        if il_utils_$is_strength_reduction_temp(v) then
          if r^[k].reg = 31 then
            if (r^[k].node^.xl[6] & 16#40000) = 0 then begin
              sz := 0;
              case ord(v^.xc[10]) & 15 of
                1: sz := 1;
                2: sz := 2;
                3, 4, 11: sz := 4;
                5: sz := 8;
                6, 7, 8, 9, 10: ;
                otherwise
              end;
              if 2 in r^[k].flags then
                sz := 4;
              if sz >= a then begin
                v^.xc[11] := chr((ord(v^.xc[11]) & 16#0F) ! 16#60);
                v := r^[k].node;
                v^.xl[6] := v^.xl[6] ! 16#40000;
                cls := rshft(ord(v^.xc[11]) & 16#F0, 4);
                if cls in [1, 4, 7, 8, 11] then begin
                  sect := il_180^.xp[48];
                  if (sz + sect^.xl[5] > 24576) and
                     (rshft(32768 - sect^.xl[5], 2) < sz) and
                     not (3 in cargs_$options.cpu) then begin
                    align(sect^.xl[6], shift, 0);
                    v^.xl[3] := il_180^.xp[48]^.xl[6];
                    il_180^.xp[48]^.xl[6] := il_180^.xp[48]^.xl[6] + sz;
                    v^.xc[11] := chr((ord(v^.xc[11]) & 16#0F) ! 16#70);
                  end
                  else begin
                    align(sect^.xl[5], shift, 0);
                    v^.xl[3] := il_180^.xp[48]^.xl[5];
                    il_180^.xp[48]^.xl[5] := il_180^.xp[48]^.xl[5] + sz;
                    v^.xc[11] := chr((ord(v^.xc[11]) & 16#0F) ! 16#10);
                  end;
                end
                else if (il_180^.xl[28] - sz < -24576) and
                        (rshft(il_180^.xl[28] + 31000, 2) < sz) and
                        not (3 in cargs_$options.cpu) then begin
                  align(il_180^.xl[44], shift, 0);
                  v^.xc[11] := chr((ord(v^.xc[11]) & 16#0F) ! 16#60);
                  v^.xl[3] := il_180^.xl[44];
                  il_180^.xl[44] := il_180^.xl[44] + sz;
                end
                else if il_180^.xl[28] <= il_180^.xl[20] then begin
                  il_180^.xl[28] := il_180^.xl[28] - sz;
                  align(il_180^.xl[28], shift, 1);
                  v^.xl[3] := il_180^.xl[28];
                end
                else if il_180^.xl[28] > il_180^.xl[20] then begin
                  il_180^.xl[20] := il_180^.xl[20] - sz;
                  align(il_180^.xl[20], shift, 1);
                  v^.xl[3] := il_180^.xl[20];
                end;
              end;
            end;
    end;
  end;
  align(il_180^.xp[48]^.xl[5], 1, 0);
  align(il_180^.xp[48]^.xl[6], 1, 0);
  align(il_180^.xl[44], 1, 0);
  align(il_180^.xl[28], 1, 1);
  if il_180^.xl[28] < il_180^.xl[20] then
    il_180^.xl[20] := il_180^.xl[28];
end;

{ test_stmt - whether point k is in r's bit vector (the point's bit
  k - 2 * opt_region + 2).

  0x0C4476, 0x4E bytes: opt_region subtracted twice (`sub.w' each);
  the longword `lsr.w #5; lsl.w #2', the bit `andi.w #31' tested
  `btst' of the longword; `sne'. }

function test_stmt;
var
  p: integer;
begin
  p := k - opt_region - opt_region + 2;
  test_stmt := (p & 31) in r^.live^[rshft(p, 5)];
end;

{ compress_graph - the n ranges r^[1..n] with the emptied ones (node
  nil) removed: each empty slot i below n takes the last full range
  above it (counting n down past empty ones), which is renumbered i,
  and that range's slot is emptied and cleared (degree, conflict,
  first, last, reg and w24 31, prefer, uses, defs, cost, priority,
  flags, live); then n drops past empty slots at the end.

  0x0C44C4, 0xF2 bytes, link #-16: n by address; the outer loop's
  count n - 2 taken once, the inner loop from n (D2) down to i + 1;
  the 64-byte copy by four `move.l' a pass of a `dbf' of 4; the
  clearing stores in the image's order, the depth's (+44) indexed by
  i (`clr.l (-0x14,A1,D3.l)', D3 i's offset) where the others use
  j's (D0): the moved range's depth is cleared, the emptied slot's
  kept; the last loop `clr.l; move.w' of n (zero-extended), leaving
  when n reaches 0. }

procedure compress_graph(
    r: reg_ranges_ptr_t;
    var n: integer); internal;
var
  i: integer;
  j: integer;
begin
  for i := 1 to n - 1 do
    if r^[i].node = nil then
      for j := n downto i + 1 do
        if r^[j].node = nil then
          n := n - 1
        else begin
          r^[i] := r^[j];
          r^[i].num := i;
          r^[j].node := nil;
          r^[j].degree := 0;
          r^[j].conflict.next := nil;
          r^[j].conflict.num := 0;
          r^[j].first := 0;
          r^[j].last := 0;
          r^[j].reg := 31;
          r^[j].w24 := 31;
          r^[j].prefer := [];
          r^[j].uses := 0;
          r^[j].defs := 0;
          r^[j].cost := 0;
          r^[i].depth := 0;
          r^[j].priority := 0;
          r^[j].flags := [];
          r^[j].live := nil;
          exit;
        end;
  while r^[n].node = nil do begin
    n := n - 1;
    if n = 0 then
      exit;
  end;
end;

{ find_prev - the region number of statement s, else of the nearest
  statement before it that has one.

  0x0C45B6, 0x42 bytes: no frame, s at (4,SP) (docs/rev889-patterns.md
  16); the region the bits 23..8 of the longword at +42 (`andi.l
  #0xFFFF00; lsr.l #8'); the walk through +4 stops at nil and then
  reads the nil statement's region. }

function find_prev(
    s: g_opt_stmt_ptr_t): integer; options(val_param); internal;
begin
  if s^.hdr.region = 0 then
    repeat
      s := s^.prev;
    until (s = nil) or (s^.hdr.region <> 0);
  find_prev := s^.hdr.region;
end;

{ reg_alloc - allocate registers for the routine's numbered statements
  (nothing without basic blocks).

  reg_nest counts the ranges the routine may need: the statements
  that assign a variable, the strength reduction temporaries' plain
  assignments (140, op 0), the constants of the evaluations (139)
  that head a loop's latch block, and the cse parents.  With none,
  only the pool goes back.  Otherwise the ranges come from add_range
  (for each assigned variable defined_var accepts), add_cse_ranges,
  add_con_range (the latch evaluations' constants under opt_on 17, 18
  or 20, and the temporaries' assignments); ranges of one object that
  intersect are combined until none do (compress_graph after each
  pass); compute_costs and compress_graph drop those not worth a
  register; a C function's result is moved to the first slot;
  run_interference and color_graph colour them; ranges of one object
  (not a cse parent or a Fortran constant) given the same register
  are combined; insert_reg_stmts, editregassign, then the variables'
  storage (alloc_ftn_vars for Fortran, alloc_comp_vars otherwise) and
  under -DB.. store_debug_info.  -DUMP68 RA lists the ranges after the
  first combining, the costs and the colouring.

  0x0C4A62, 0x5F8 bytes, link #-104: il_11c tested first (`tst.l;
  beq' to the epilogue); the statements from il_d4 through +8; the
  latch tests `cmpa.l (84,A0)' (the block's first statement) or the
  block's number (+82) equal to opt_first_block, then +0 bit 2; the
  constant kinds a 26-byte set (0x0C505A, `btst' after the 207 range
  check: 88, 89, 145..147, 163, 195); the cse parents' loop tested
  before it is entered; the ranges' allocation of reg_nest * 64
  (`lsl.l #6'), a nil one reported (cgerr_no_source(9, 0)); reg_words
  ((runbackend_16 - opt_region + 1) * 2 + 31) div 32 + 2 from
  zero-extended words; opt_on's longword (0x2C366C) kept in D5 and
  masked `andi.l #0x7FFFFFFE; lsr.l #1; andi.l #0x160000'; the region
  number the bits 23..8 of +42; the combining loop entered at its test
  (`bra'), its flag at -82; the swap through a frame copy (-64) with
  the numbers set again; the kinds 145, 146, 190, 147 compared in that
  order; il_180's +377 bits 6..4 for the language; db (+0x282 bits
  16..15) tested non-zero.  The labels passed to dump_lifetimes are
  laid out after the routine: 'final edition', 'duplicate obj''s
  compressed', 'initial discrete'.

  Not known from the original: the locals' names; whether the loops
  were `for' loops. }

procedure reg_alloc;
var
  tmp: reg_range_t;
  changed: boolean;
  s: g_opt_stmt_ptr_t;
  b: g_opt_block_ptr_t;
  c: g_opt_cse_ptr_t;
  i: integer;
  j: integer;
  x: il_$node_ptr_t;

  { defined_var - whether the variable statement s assigns (its vnum
    in s's table) may live in a register.

    A variable (109): not when its entry's +16 bit 10 is set, its +32
    has bits 0, 8, 12 or 21, the optimizer knows no node for it
    (opt_var_types), or opt_region's entry has flag 3; yes when of class
    5; a kind 123 needs a -CPU of 160, 5700, FPA1 or MATHLIB and
    il_180's +376 bit 7; the node must be of kind 134, 123 or 130 unless
    the optimizer's +25 bit 6 is set; a 134 only when at most 4 bytes.
    A Fortran variable (110): of class 3 (+44's high nibble), without
    +26 bit 8 or +24 bits 0, 12, 21 (+24 bit 21 cleared first when +32
    is set and the class is 5); not of size class 6 or 13 unless of
    class 5; reals (4, 5) as for 123; class 7 only in a routine block
    of kind 105; not with opt_region's flag 3; not of class 3 and size
    class 7; any other size class yes, a real or 6 also when it is a
    C function's result, else only when no statement its value
    reaches has +41 bit 4, or assigns it from another value with that
    bit; when one does, +24 bit 21 is set (no register).  Other nodes
    yes.

    0x0C45F8, 0x286 bytes, link #-24: the result in D0 cleared first,
    `st' on the yes paths; opt_var_types indexed by 28v; the kinds
    compared 134, 123, 130; the -CPU set's word (0x2C3670) `andi.w
    #0x3FFC; lsr.w #2; andi.w #0x714'; the size class's sets 0x2040
    (6, 13), 0x30 (4, 5), 0x70 (4..6); the kinds 188 and 140 evaluated
    whole (`seq; seq; or.b; bpl'). }

  function defined_var(
      s: g_opt_stmt_ptr_t): boolean; options(val_param);
  var
    v: integer;
    e: g_opt_var_ptr_t;
    t: il_$node_ptr_t;
    sz: integer;
    cls: integer;
    ch: g_opt_chain_ptr_t;
    st: g_opt_stmt_ptr_t;
  begin
    defined_var := false;
    v := s^.hdr.vnum;
    e := s^.vars^[v];
    if e = nil then
      return;
    if (e^.flags & 16#400) <> 0 then
      return;
    t := e^.node;
    if t^.kind = var_name then begin
      if (t^.xl[8] & 16#201101) <> 0 then
        return;
      if opt_var_types^[v].base = nil then
        return;
      if t^.xw[36] = 5 then begin
        defined_var := true;
        return;
      end;
      if opt_var_types^[v].base^.kind = real_type then begin
        if cargs_$options.cpu * [2, 4, 8..10] = [] then
          return;
        if (ord(il_180^.xc[376]) & 16#80) = 0 then
          return;
      end;
      if (opt_4009c[opt_region]^.vars^[v]^.flags & 8) <> 0 then
        return;
      if not opt_var_types^[v].flags.ranged then
        if (opt_var_types^[v].base^.kind <> set_type) and
           (opt_var_types^[v].base^.kind <> real_type) and
           (opt_var_types^[v].base^.kind <> ptr_type) then
          return;
      if opt_var_types^[v].base^.kind = set_type then
        defined_var := opt_var_types^[v].size <= 4
      else
        defined_var := true;
    end
    else if t^.kind = fortran_symbol then begin
      if rshft(ord(t^.xc[44]) & 16#F0, 4) <> 3 then
        return;
      if (t^.xw[13] & 16#100) <> 0 then
        return;
      if (t^.xl[6] & 16#201001) <> 0 then
        return;
      if t^.xl[8] <> 0 then
        if rshft(ord(t^.xc[11]) & 16#F0, 4) = 5 then
          t^.xl[6] := t^.xl[6] & ~16#200000;
      t := e^.node;
      sz := ord(t^.xc[10]) & 15;
      if sz in [6, 13] then
        if rshft(ord(t^.xc[11]) & 16#F0, 4) <> 5 then
          return;
      cls := rshft(ord(t^.xc[11]) & 16#F0, 4);
      if (cls <> 5) and (sz in [4, 5]) then begin
        if cargs_$options.cpu * [2, 4, 8..10] = [] then
          return;
        if (ord(il_180^.xc[376]) & 16#80) = 0 then
          return;
      end;
      if cls = 7 then
        if il_180^.kind <> program_blk then
          return;
      if (opt_4009c[opt_region]^.vars^[v]^.flags & 8) <> 0 then
        return;
      t := e^.node;
      if rshft(ord(t^.xc[44]) & 16#F0, 4) = 3 then
        if sz = 7 then
          return;
      if not (sz in [4..6]) then begin
        defined_var := true;
        return;
      end;
      if il_180^.kind = function_blk then
        if il_180^.xp[24] = t then begin
          defined_var := true;
          return;
        end;
      ch := e^.du;
      while ch <> nil do begin
        st := ch^.stmt;
        if st^.hdr.b4 then begin
          defined_var := true;
          return;
        end;
        if (st^.kind = use_def_ob) or (st^.kind = assign_node) then begin
          if st^.kind = assign_node then
            if st^.asg_rhs <> e^.node then
              if st^.hdr.b4 then begin
                defined_var := true;
                return;
              end;
        end
        else begin
          defined_var := true;
          return;
        end;
        ch := ch^.next;
      end;
      e^.node^.xl[6] := e^.node^.xl[6] ! 16#200000;
    end
    else
      defined_var := true;
  end;

  { editregassign - for each basic block, the registers holding a
    range's value at the block's entry (point 2s of its first
    statement's region s, or of the nearest numbered statement before
    it): a kind 178 node (196 bytes, the 24 registers' entries
    cleared) made for the block's +24 when it has none, and the
    register's entry given the object (a cse parent's tree) and the
    range's class.  A range not live there is skipped, as are a cse
    parent made at the block's first statement and, in a latch block,
    constants (and 137, 138) and strength reduction temporaries not
    live at the point before.

    0x0C487E, 0x1CA bytes, link #-36: nothing for n = 0 or when
    opt_last_block < opt_first_block (unsigned); the blocks' loop by a
    count (-18) and the number at -16; the point doubled `add.w';
    find_prev for blocks other than the first whose point is 0; the
    ranges by `dbf'; the constants' set (0x0C4A48: 88, 89, 137, 138,
    145..147, 163, 195) after the 207 range check; the entries cleared
    by a `dbf' of 24 (`clr.l; clr.w; clr.b; clr.b'); the entry at the
    register's 8 bytes (`lsl.w #3'). }

  procedure editregassign(
      r: reg_ranges_ptr_t;
      n: integer); options(val_param);
  var
    bn: g_opt_num_t;
    b: g_opt_block_ptr_t;
    p: integer;
    i: integer;
    m: integer;
    rr: reg_range_ptr_t;
    regs: ra_regs_ptr_t;
  begin
    if n = 0 then
      return;
    for bn := opt_first_block to opt_last_block do begin
      b := g_opt_blocks_ptr_t(il_11c)^[bn];
      p := b^.first_stmt^.hdr.region * 2;
      if (bn <> 1) and (p = 0) then
        p := find_prev(b^.first_stmt) * 2;
      for i := 1 to n do begin
        rr := addr(r^[i]);
        if rr^.reg = 31 then
          next;
        if not test_stmt(rr, p) then
          next;
        if rr^.node^.kind = cse_parent_ob then
          if g_opt_cse_ptr_t(rr^.node)^.p_stmt = b^.first_stmt then
            next;
        if (rr^.node^.kind in [real_ob..dpreal_ob, tree_node..gen_tree_node,
                               dindex_node..disp_node, addr_con,
                               reloc_absolute_addr_con]) and
           b^.flags.latch then
          if not test_stmt(rr, p - 1) then
            next;
        if il_utils_$is_strength_reduction_temp(rr^.node) and
           b^.flags.latch then
          if not test_stmt(rr, p - 1) then
            next;
        if g_opt_bb_ptr_t(b)^.cache_in = nil then begin
          regs := gspace(196);
          regs^.kind := reg_assign_ob;
          for m := 0 to 23 do begin
            regs^.ent[m].obj := nil;
            regs^.ent[m].size := 0;
            regs^.ent[m].load := false;
            regs^.ent[m].live := false;
          end;
          g_opt_bb_ptr_t(b)^.cache_in := regs;
        end;
        regs := g_opt_bb_ptr_t(b)^.cache_in;
        if rr^.node^.kind = cse_parent_ob then
          regs^.ent[rr^.reg].obj := g_opt_cse_ptr_t(rr^.node)^.p_tree
        else
          regs^.ent[rr^.reg].obj := rr^.node;
        regs^.ent[rr^.reg].size := rr^.rlen;
      end;
    end;
  end;

begin
  if il_11c = nil then
    return;
  initpool;
  reg_nest := 0;
  s := g_opt_stmt_ptr_t(il_d4);
  while s <> nil do begin
    if s^.hdr.vnum <> 0 then
      reg_nest := reg_nest + 1;
    if (s^.kind = assign_node) and (s^.asg_op = scalar_aop) then
      if il_utils_$is_strength_reduction_temp(s^.asg_lhs) then
        reg_nest := reg_nest + 1;
    b := s^.block;
    if (b^.first_stmt = s) or (b^.num = opt_first_block) then
      if b^.flags.latch and (s^.kind = eval_node) then
        for i := 1 to s^.eval_count do
          if s^.eval_opnd[i]^.kind in [real_ob..dpreal_ob,
                                       dindex_node..disp_node, addr_con,
                                       reloc_absolute_addr_con] then
            reg_nest := reg_nest + 1;
    c := g_opt_cse_ptr_t(s^.cses);
    while c <> nil do begin
      reg_nest := reg_nest + 1;
      c := c^.p_next;
    end;
    s := s^.next;
  end;
  if reg_nest <> 0 then begin
    reg_ranges := mem_$alloc(opt_main_20, reg_nest * 64);
    if reg_ranges = nil then
      cgerr_no_source(9, 0);
    reg_words := ((runbackend_16 - opt_region + 1) * 2 + 31) div 32 + 2;
    reg_nranges := 0;
    s := g_opt_stmt_ptr_t(il_d4);
    while s <> nil do begin
      if s^.hdr.vnum <> 0 then
        if defined_var(s) then
          add_range(s^.hdr.vnum, s^.hdr.region);
      if s^.cses <> nil then
        add_cse_ranges(s^.hdr.region);
      if cargs_$options.opt_on * [17, 18, 20] <> [] then begin
        b := s^.block;
        if (b^.first_stmt = s) or (b^.num = opt_first_block) then
          if b^.flags.latch and (s^.kind = eval_node) then
            for i := 1 to s^.eval_count do
              if s^.eval_opnd[i]^.kind in [real_ob..dpreal_ob,
                                           dindex_node..disp_node, addr_con,
                                           reloc_absolute_addr_con] then
                add_con_range(s^.hdr.region, s^.eval_opnd[i]);
      end;
      if (s^.kind = assign_node) and (s^.asg_op = scalar_aop) then
        if il_utils_$is_strength_reduction_temp(s^.asg_lhs) then
          add_con_range(s^.hdr.region, s^.asg_lhs);
      s := s^.next;
    end;
    if reg_nranges <> 0 then begin
      if cargs_$options.ra then
        dump_lifetimes(reg_ranges, reg_nranges, reg_nest,
                       'initial discrete', 16);
      changed := true;
      while changed do begin
        changed := false;
        for i := 1 to reg_nranges do begin
          x := reg_ranges^[i].node;
          if x <> nil then
            if x^.kind <> cse_parent_ob then
              for j := 1 to reg_nranges do
                if (reg_ranges^[j].node = x) and (i <> j) then
                  if ranges_intersect(addr(reg_ranges^[i]),
                                      addr(reg_ranges^[j])) then begin
                    changed := true;
                    combine_ranges(addr(reg_ranges^[i]),
                                   addr(reg_ranges^[j]));
                  end;
        end;
        compress_graph(reg_ranges, reg_nranges);
      end;
      if reg_nranges <> 0 then begin
        if cargs_$options.ra then
          dump_lifetimes(reg_ranges, reg_nranges, reg_nest,
                         'duplicate obj''s compressed', 26);
        compute_costs(reg_ranges, reg_nranges);
        compress_graph(reg_ranges, reg_nranges);
        if reg_nranges <> 0 then begin
          if il_180^.kind = function_blk then
            if il_180^.xp[24] <> nil then
              if il_180^.xp[24] <> reg_ranges^[1].node then
                if reg_nranges > 1 then
                  for i := 2 to reg_nranges do
                    if reg_ranges^[i].node = il_180^.xp[24] then begin
                      tmp := reg_ranges^[1];
                      reg_ranges^[1] := reg_ranges^[i];
                      reg_ranges^[1].num := 1;
                      reg_ranges^[i] := tmp;
                      reg_ranges^[i].num := i;
                      exit;
                    end;
          run_interference(reg_ranges, reg_nranges);
          color_graph(reg_ranges, reg_nranges);
          for i := 1 to reg_nranges do begin
            x := reg_ranges^[i].node;
            if x <> nil then
              if (x^.kind <> dindex_node) and (x^.kind <> ptr_node) and
                 (x^.kind <> cse_parent_ob) and (x^.kind <> disp_node) then
                for j := i + 1 to reg_nranges do
                  if reg_ranges^[j].node = reg_ranges^[i].node then
                    if reg_ranges^[i].reg = reg_ranges^[j].reg then
                      combine_ranges(addr(reg_ranges^[i]),
                                     addr(reg_ranges^[j]));
          end;
          compress_graph(reg_ranges, reg_nranges);
          if reg_nranges <> 0 then begin
            if cargs_$options.ra then
              dump_lifetimes(reg_ranges, reg_nranges, reg_nest,
                             'final edition', 13);
            insert_reg_stmts(reg_ranges, reg_nranges);
            editregassign(reg_ranges, reg_nranges);
            if rshft(ord(il_180^.xc[377]) & 16#70, 4) <> 2 then
              alloc_comp_vars(reg_ranges, reg_nranges)
            else
              alloc_ftn_vars(reg_ranges, reg_nranges);
            if cargs_$options.db <> 0 then
              store_debug_info(reg_ranges, reg_words, reg_nranges);
          end;
        end;
      end;
    end;
    release_space;
  end;
  freepools;
end;
