{ call_conv - the PRISM back end's calling conventions (cc.a88k only):
  at_call_conv builds a call's (or a routine's) conventions record
  (call_conv.ins.pas's call_conv_$t): its preset register sets, its
  properties, and where each argument and the result go (memory, or
  the integer registers 4..9 and the floating registers 8..19 when the
  arguments are placed by prototype); get_rlen_and_size gives an IL
  node's register class and size.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x0B3F48  get_rlen_and_size
    --------  0x0B4252  lib_dsc_name_cmp (internal)
    --------  0x0B42B2  pfm_cleanup_check (internal)
    --------  0x0B4326  ftn_alt_rtn
    --------  0x0B4362  ftn_param_vat_check
    --------  0x0B43B0  entry_blk_check
    --------  0x0B43DE  get_proto
    --------  0x0B449C  fill_arg_desc_using_ptt
    --------  0x0B4604  at_call_conv
    A5 0x44345C: the four presets (+0, +48, +96, +144, 42 bytes each),
    then the names compared: 'PFM_$CLEANUP' (+186), 'pfm_$cleanup'
    (+198), 'PAS_$SET_BUILD' (+216), 'PAS_$SUBSTR' (+232), 'PAS_$CTOV'
    (+248), 'ftn_$stop' (+264).

  The routines but lib_dsc_name_cmp and pfm_cleanup_check (no A5; they
  read the names through their caller's) load A5 and are global,
  though only at_call_conv calls them.  The IL nodes are read through
  il.ins.pas's views by offset (xp, xw, xc ...) and the unit's view of
  a block (cc_blk_t, beyond c_objtype's c_blk_t: its +124 is the
  callee's rtn_t once compiled, +148 an entry's block, +240 the start
  of the static chain, +396 the parameters' allocations).  Node kinds
  as at_call_conv dispatches on them: 159 a run-time library
  descriptor, 208 a call with explicit conventions (its own preset at
  +4, 12-byte argument entries from +90), 105, 107, 108 and 167
  routines (108 a function, 167 an entry), 137 and 138 calls (+36 15 or
  16, +38 the operands, opr[1] the callee at +40), 110 a routine
  variable, 171 a call through a pointer (+16 its type), 175, 146; 121
  a parameter, 168 a prototype's entries (12 bytes from +12), 109 a
  variable, 81 an integer constant, 31 the `...' of a prototype.

  Not known from the original: the locals' and the views' names, the
  presets' names (preset_0 .. preset_3); docs/questions.md 185..212. }
module call_conv;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/codegen.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/isc/isc_lir.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_enumeration.ins.pas';
%include 'lang2/source/isc/isc_attribute_records.ins.pas';
%include 'moon_unit/isc_prism_dervobjs/dseeaggs/iscg_input/hd69fbe76.000/iscg_input/isc_solution_fields.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';

type
  { A block (kinds 105..108, 167's +148) as call_conv reads it, by
    offset (c_objtype.ins.pas's c_blk_t names most of these). }
  cc_blk_ptr_t = ^cc_blk_t;
  cc_blk_t = record
    unused_0: integer;                  { +0 }
    kind: il_$kind_t;                   { +2 }
    unused_4: array [4..11] of char;    { +4 }
    parms: il_$node_ptr_t;              { +12: c_blk_t's old_parms }
    unused_16: array [16..27] of char;  { +16 }
    result: il_$node_ptr_t;             { +28 }
    unused_32: array [32..95] of char;  { +32 }
    ret_var: il_$node_ptr_t;            { +96 }
    unused_100: array [100..123] of char;    { +100 }
    rtn: rtn_ptr_t;                     { +124: its routine record, once
                                          compiled (its clobbers and
                                          properties) }
    unused_128: array [128..147] of char;    { +128 }
    blk148: cc_blk_ptr_t;               { +148: an entry's (167) block }
    unused_152: array [152..191] of char;    { +152 }
    data_sect: univ_ptr;                { +192 }
    unused_196: array [196..239] of char;    { +196 }
    chain: il_$node_ptr_t;              { +240: where the static chain
                                          starts (chained at +12) }
    unused_244: array [244..291] of char;    { +244 }
    lev: packed record                  { +292 }
      b292: 0..255;
      nparms: 0..255;                   { +293 }
      level: -128..127;                 { +294 }
      b295: 0..255;
      end;
    name: c_name_t;                     { +296 }
    unused_304: array [304..315] of char;    { +304 }
    bits316: integer32;                 { +316: a function result's size
                                          in bits (languages 1, 5) }
    unused_320: array [320..331] of char;    { +320 }
    preset: call_conv_$preset_t;        { +332: c_blk_t's ropts }
    unused_374: packed record           { +374 }
      b374_7: boolean;
      b374_6: boolean;                  { .6 }
      b374_5_0: 0..63;
      b375: 0..255;
      b376_7, b376_6: boolean;          { +376 }
      b376_5: boolean;                  { .5: asynchronous }
      b376_4: boolean;                  { .4 (db_adjusted) }
      b376_3, b376_2, b376_1: boolean;
      cls: 0..3;                        { .0 to +377.7 }
      conv: 0..7;                       { +377 .6..4: the language }
      b377_3_0: 0..15;
      made: boolean;                    { +378 .7 }
      b378_6: boolean;                  { .6: has a static link }
      b378_5_0: 0..63;
      b379_7: boolean;                  { +379 }
      b379_6: boolean;                  { .6 }
      b379_5_0: 0..63;
      end;
    unused_380: array [380..391] of char;    { +380 }
    params: c_parlist_ptr_t;            { +392: the prototype's types
                                          (+2 the count, +4k the k-th) }
    vats: array [1..255] of integer;    { +396: the parameters'
                                          allocations (c_vat_t) }
  end;

  cc_vats_t = array [1..255] of integer;
  cc_vats_ptr_t = ^cc_vats_t;

  { A temporary's copy of the record's header and first descriptor
    (106 bytes: `move.l (A0)+,(A1)+' twice by 13 and a word). }
  cc_copy_ptr_t = ^cc_copy_t;
  cc_copy_t = array [1..53] of integer;

  cc_name_t = array [1..14] of char;

var
  { The presets (+0, +48, +96, +144). }
  preset_0: call_conv_$preset_t := [
    fp_preserved := [0, 0], fp_clobbered := [0, 16#F],
    fp16 := [-1, 16#FFFFFFF0], ip_preserved := 16#3FFC00,
    ip_clobbered := 16#44003FF, ip32 := 16#FB800000, w36 := 1,
    flags := [13, 14, 15], reg40 := 26];
  preset_1: call_conv_$preset_t := [
    fp_preserved := [16#FFF00000, 16#F0],
    fp_clobbered := [16#FFFFF, 16#FFFFFF0F], fp16 := [0, 0],
    ip_preserved := 16#3FFC00, ip_clobbered := 16#C003FF,
    ip32 := 16#FF000000, w36 := 1, flags := [3, 13, 14, 15],
    reg40 := 23];
  preset_2: call_conv_$preset_t := [
    fp_preserved := [16#FFF00000, 16#F0],
    fp_clobbered := [16#FFFFF, 16#FFFFFF0F], fp16 := [0, 0],
    ip_preserved := 16#3FFC00, ip_clobbered := 16#C003FF,
    ip32 := 16#FF000000, w36 := 1, flags := [3, 10, 13, 14, 15],
    reg40 := 23];
  preset_3: call_conv_$preset_t := [
    fp_preserved := [16#FFF00000, 16#F0],
    fp_clobbered := [16#FFFFF, 16#FFFFFF0F], fp16 := [0, 0],
    ip_preserved := 16#3FFC00, ip_clobbered := 16#C003FF,
    ip32 := 16#FF000000, w36 := 1, flags := [3, 13, 14, 15],
    reg40 := 23];
  pfm_cleanup_upper: array [1..12] of char := 'PFM_$CLEANUP';
  pfm_cleanup_lower: array [1..12] of char := 'pfm_$cleanup';
  pas_set_build: array [1..14] of char := 'PAS_$SET_BUILD';
  pas_substr: array [1..11] of char := 'PAS_$SUBSTR';
  pas_ctov: array [1..9] of char := 'PAS_$CTOV';
  ftn_stop: array [1..9] of char := 'ftn_$stop';

  { delay.pas's +888 (cc.a88k 0x2E99D8): the bytes of each register
    class (opt_main.pas and opt_strength.pas declare it the same way). }
  class_size: extern array [0..12] of integer;

{ PASS_CHAR_LEN_DIFF - frontend_cc_dummies 0x067688 (false); cg.ins.pas
  has the heading, which call_conv does not open. }
function pass_char_len_diff(
    in r: univ il_$node_ptr_t): boolean; extern;

{ get_rlen_and_size - t's register class and size: by its kind, 108 a
  function of language 1, 3 or 5 its result type's (the size its bits
  at +316 for 1 and 5), 110 its class (+10's low nibble through
  runbackend_18; class_size's bytes, or for class 7 its +8 word, 0 when
  +10 bit 7), 109 and 121 their type's, 137, 138 and 143 their +24 and
  +20, 189 and 190 those of their +20 and +4, the constants and their
  kinds by kind (81 and 84 2 bytes with -I*2), 164 and 165 strings (9)
  of their length, 147 a part of its +24 at offset +32 (1, 2 or 4
  bytes, else nothing).

  0x0B3F48, 0x30A bytes: t (8) in A2, rlen (12) in D2, size (16) in
  A3; the case on 77..200 through a table; type_exp's record at -32. }

procedure get_rlen_and_size(
    t: il_$node_ptr_t;
    out rlen: integer;
    out size: integer32);
var
  te: type_exp_t;
  b: cc_blk_ptr_t;
  n: il_$node_ptr_t;
begin
  rlen := rlen_null;
  size := 0;
  case t^.kind of
    function_blk: begin
      b := cc_blk_ptr_t(t);
      if b^.unused_374.conv in [1, 3, 5] then begin
        type_exp(b^.result, addr(te));
        if b^.unused_374.conv in [1, 5] then
          te.size := rshft(b^.bits316 + 7, 3);
        size := te.size;
        rlen := get_rlen(te);
      end;
    end;
    fortran_symbol: begin
      rlen := runbackend_18[ord(t^.xc[10]) & 15];
      if (ord(t^.xc[10]) & 15) <> 7 then
        size := class_size[rlen] & 16#FFFF
      else if ord(t^.xc[10]) >= 128 then
        size := 0
      else
        size := t^.xw[4];
    end;
    var_name, param_name: begin
      type_exp(t, addr(te));
      rlen := get_rlen(te);
      size := te.size;
    end;
    tree_node, gen_tree_node, cmp_tree_node: begin
      rlen := t^.xw[12];
      size := t^.xl[5];
    end;
    addr_con: begin
      rlen := rlen_addr;
      size := 4;
    end;
    cse_use_ob:
      get_rlen_and_size(t^.xp[5], rlen, size);
    cse_parent_ob:
      get_rlen_and_size(t^.xp[1], rlen, size);
    blogical_ob, ubinteger_ob, char_ob, binteger_ob: begin
      rlen := rlen_byte;
      size := 1;
    end;
    llogical_ob, linteger_ob, ulinteger_ob: begin
      rlen := rlen_long;
      size := 4;
    end;
    integer_ob, uinteger_ob:
      if cargs_$options.i_star_2 then begin
        rlen := rlen_word;
        size := 2;
      end
      else begin
        rlen := rlen_long;
        size := 4;
      end;
    slogical_ob, sinteger_ob, usinteger_ob: begin
      rlen := rlen_word;
      size := 2;
    end;
    real_ob: begin
      rlen := rlen_r4;
      size := 4;
    end;
    dpreal_ob: begin
      rlen := rlen_r8;
      size := 8;
    end;
    complex_ob: begin
      rlen := rlen_c8;
      size := 8;
    end;
    dpcomplex_ob: begin
      rlen := rlen_c16;
      size := 16;
    end;
    varying_ob, char_string_ob, set_con_ob: begin
      rlen := rlen_agg;
      size := t^.xw[8] & 16#FFFF;
    end;
    cs_node: begin
      rlen := rlen_cs;
      n := t^.xp[6];
      if n^.kind = integer_ob then
        size := n^.int_value
      else
        size := 0;
    end;
    cs_temp: begin
      rlen := rlen_cs;
      size := t^.xw[11];
    end;
    disp_node: begin
      get_rlen_and_size(t^.xp[6], rlen, size);
      if t^.xl[8] <> 0 then begin
        if size <= 4 then begin
          size := size - t^.xl[8];
          if size = 1 then begin
            rlen := rlen_byte;
            return;
          end
          else if size = 2 then begin
            rlen := rlen_word;
            return;
          end
          else if size = 4 then begin
            rlen := rlen_long;
            return;
          end;
        end;
        size := 0;
        rlen := rlen_null;
      end;
    end;
    otherwise
      ;
  end;
end;

{ lib_dsc_name_cmp - whether the run-time library descriptor dsc (kind
  159: +8 its name's length, +10 its arguments' count, a word each
  after it, then the name) is called name (len characters).

  0x0B4252, 0x60 bytes, no A5: dsc (8), name (12), len (16) a word. }

function lib_dsc_name_cmp(
    dsc: il_$node_ptr_t;
    in name: univ cc_name_t;
    len: integer): boolean; options(val_param); internal;
var
  k: integer;
begin
  if len <> dsc^.xw[4] then begin
    lib_dsc_name_cmp := false;
    return;
  end;
  for k := 1 to len do
    if name[k] <> dsc^.xc[11 + 2 * dsc^.xw[5] + k] then begin
      lib_dsc_name_cmp := false;
      return;
    end;
  lib_dsc_name_cmp := true;
end;

{ pfm_cleanup_check - whether name (len characters) is PFM_$CLEANUP:
  12 characters, the upper-case name, or (unless cargs flags_286's
  element 0) the lower-case one.  As the image has it, a name that is
  not the upper-case one answers true at once when the flag is set (the
  result register is set before the flag's test).

  0x0B42B2, 0x74 bytes, no A5: name (8), len (12) a word. }

function pfm_cleanup_check(
    in name: univ cc_name_t;
    len: integer): boolean; options(val_param); internal;
var
  differ: boolean;
  k: integer32;
begin
  if len <> 12 then begin
    pfm_cleanup_check := false;
    return;
  end;
  differ := false;
  for k := 1 to 12 do
    if name[k] <> pfm_cleanup_upper[k] then begin
      differ := true;
      exit;
    end;
  if not differ then begin
    pfm_cleanup_check := true;
    return;
  end;
  pfm_cleanup_check := true;
  if 0 in cargs_$options.flags_286 then
    return;
  for k := 1 to 12 do
    if name[k] <> pfm_cleanup_lower[k] then begin
      pfm_cleanup_check := false;
      return;
    end;
end;

{ ftn_alt_rtn - whether n is a routine of language 2 (FORTRAN) with a
  result variable (an alternate return).  0x0B4326, 0x3C bytes: n (8)
  by address. }

function ftn_alt_rtn(
    in n: il_$node_ptr_t): boolean;
begin
  ftn_alt_rtn := (n^.kind = procedure_blk)
                 and (cc_blk_ptr_t(n)^.unused_374.conv = 2)
                 and (cc_blk_ptr_t(n)^.ret_var <> nil);
end;

{ ftn_param_vat_check - a routine variable (110) of allocation 5 (a
  parameter) is passed as an address: rlen 5, size 4.  0x0B4362, 0x4E
  bytes: n (8), rlen (12), size (16) by address. }

procedure ftn_param_vat_check(
    in n: il_$node_ptr_t;
    var rlen: integer;
    var size: integer32);
begin
  if n^.kind = fortran_symbol then
    if rshft(ord(n^.xc[11]) & 16#F0, 4) = 5 then begin
      rlen := rlen_addr;
      size := 4;
    end;
end;

{ entry_blk_check - an entry's (167) block, else n itself.  0x0B43B0,
  0x2E bytes: n (8) by address; A0. }

function entry_blk_check(
    in n: il_$node_ptr_t): cc_blk_ptr_t;
begin
  if n <> nil then
    if n^.kind = entry_blk then begin
      entry_blk_check := cc_blk_ptr_t(n)^.blk148;
      return;
    end;
  entry_blk_check := cc_blk_ptr_t(n);
end;

{ get_proto - the prototype (a parameter list: +2 the count, +4k the
  types) of what n is or points to, through names, pointers,
  structures' and variables' types; nil for none.  0x0B43DE, 0xBE
  bytes: n (8) by address; A0. }

function get_proto(
    in n: il_$node_ptr_t): c_parlist_ptr_t;
label
  10;
var
  t: il_$node_ptr_t;
begin
  t := n;
10:
  case t^.kind of
    procedure_blk, function_blk:
      get_proto := cc_blk_ptr_t(t)^.params;
    cc_func_returning_type:
      get_proto := c_parlist_ptr_t(t^.xp[3]);
    ptr_type, record_type: begin
      t := t^.xp[1];
      goto 10;
    end;
    type_name, disp_node, var_name: begin
      t := t^.xp[7];
      goto 10;
    end;
    field_name, param_name: begin
      t := t^.xp[4];
      goto 10;
    end;
    ptr_node: begin
      t := t^.xp[6];
      goto 10;
    end;
    addr_con:
      if ord(t^.xc[20]) = 2 then begin
        t := t^.xp[2];
        goto 10;
      end
      else
        get_proto := nil;
    otherwise
      get_proto := nil;
  end;
end;

{ fill_arg_desc_using_ptt - argument descriptor d from a run-time
  library argument code (ptt): 0..5 by value (a byte, a word, a long,
  an address, a single, a double: offset aligned to the slot's end for
  a byte or word), 7 and 8 a byte and a word by descriptor (mode 2), 9,
  10 and 11 by descriptor, reference and as the result's (a long, or
  the actual argument's class and size of a call 137/138); mode 3 for
  the result (num 0).

  0x0B449C, 0x168 bytes: d (8) in A2, code (12) by address, n (16) by
  address in A3; the mode in D2. }

procedure fill_arg_desc_using_ptt(
    var d: call_conv_$arg_t;
    in code: integer;
    in n: il_$node_ptr_t);
var
  mode: integer;
  size: integer32;
  rl: integer;
  sz: integer32;
  a: il_$node_ptr_t;
begin
  mode := 0;
  d.f20.kind := 0;
  case code of
    0, 1, 2, 3, 4, 5: begin
      case code of
        0: begin
          d.offset := d.offset + 3;
          d.f16.rlen := rlen_byte;
          size := 1;
        end;
        1: begin
          d.offset := d.offset + 2;
          d.f16.rlen := rlen_word;
          size := 2;
        end;
        2: begin
          d.f16.rlen := rlen_long;
          size := 4;
        end;
        4: begin
          d.f16.rlen := rlen_r4;
          size := 4;
        end;
        5: begin
          d.f16.rlen := rlen_r8;
          size := 8;
        end;
        3: begin
          d.f16.rlen := rlen_addr;
          size := 4;
        end;
      end;
      d.size := size;
      d.by_value := true;
    end;
    7, 8: begin
      if code = 7 then begin
        d.f16.rlen := rlen_byte;
        size := 1;
      end
      else begin
        d.f16.rlen := rlen_word;
        size := 2;
      end;
      d.size := size;
      d.by_value := false;
      mode := 2;
    end;
    9, 10, 11: begin
      d.f16.rlen := rlen_long;
      d.size := 4;
      d.by_value := false;
      case code of
        9: mode := 2;
        10: mode := 1;
        11: mode := 3;
      end;
      if (n^.kind = tree_node) or (n^.kind = gen_tree_node) then
        if (n^.xw[18] = 15) or (n^.xw[18] = 16) then begin
          a := n^.xp[10 + d.num];
          get_rlen_and_size(a, rl, sz);
          ftn_param_vat_check(n^.xp[10 + d.num], rl, sz);
          if rl <> 0 then begin
            d.f16.rlen := rl;
            d.size := sz;
          end;
        end;
    end;
    otherwise
      ;
  end;
  if d.num = 0 then
    mode := 3;
  d.f22.mode := mode;
end;

{ at_call_conv - the conventions of node (a call or a routine; the
  kinds in the header):

  1. by the node's (or the callee's, opr[1] of a call) kind: the preset,
     the parameters (opr: a library descriptor, a parameter chain, a
     prototype's entries, the callee itself), the callee's block (blk),
     the descriptors' count n (with the result's), the result's class
     and size, whether the call is nested and its static link (link);
     cgerr 28 for what it cannot handle.
  2. the record from lir_3f60 (lir_3f78 for a routine), from rws for
     more than 4096 bytes; its properties and register sets (the
     preset's, the callee's rtn_t's clobbers when it was compiled
     first).
  3. the result's descriptor (memory, an integer register, a single's
     or a pair's floating register, or a quad), then each argument's
     by the parameters' kind: in the argument area (offs, 4 bytes a
     slot, an aggregate's by its size).
  4. by prototype (the callee's or the preset's flag 6): singles and
     doubles in the floating registers 8..19, the rest in the integer
     registers 4..9, an aggregate passed by value split over the
     integer registers left (the record grown, the descriptors after it
     moved up; bug_check when they would pass the room made); else the
     first integer-class arguments in registers 4..9 and the floating
     ones that are by value in 8..19.
  5. the b25 flags; a variable-argument routine of this file (its +374
     bit 6, no prototype or one ending in `...') gets descriptors for
     the integer registers left (temporaries from
     make_expression_temporary); each formal's symbol gets its offset in
     the argument area (+16) and its parameter flag, and its allocation
     is checked against how it is passed (bug_check); args_size last.

  0x0B4604, 0x1B3C bytes: node (8, its address passed on); the locals
  as listed with the variables below (offsets from A6); A2 the record,
  A3 link.  Not reproduced: the image tests nested (D3) twice where the
  result descriptor's register class is set; a -396 local (unset) is
  read where a 168 prototype's result descriptor is filled for a
  routine (kept: unset396); the prototype pointer (-392) is read
  uninitialized when only the preset's flag 6 asks for prototypes
  (kept); strtk is given lengths 31 and 42 for messages of 28 and 39
  characters (kept). }

function at_call_conv(
    node: il_$node_ptr_t): call_conv_$ptr_t;
label
  60, 80, 90, 100;
var
  props: call_conv_$ptr_t;              { A2 }
  old: call_conv_$ptr_t;
  d: call_conv_$arg_ptr_t;
  e: call_conv_$arg_ptr_t;
  preset: call_conv_$preset_ptr_t;      { -344 }
  blk: cc_blk_ptr_t;                    { -400 }
  b: cc_blk_ptr_t;
  cur: cc_blk_ptr_t;
  opr: il_$node_ptr_t;                  { -320 }
  callee: il_$node_ptr_t;
  t: il_$node_ptr_t;
  a: il_$node_ptr_t;
  link: il_$node_ptr_t;                 { A3 }
  pt: c_parlist_ptr_t;                  { -392 }
  unset396: il_$node_ptr_t;             { -396 }
  vats: cc_vats_ptr_t;                  { -352 }
  heap: ^mrh_$heap_t;                   { -308 }
  te: type_exp_t;                       { -296 }
  offs: integer32;                      { -416 }
  n: integer32;                         { -412 }
  nfixed: integer32;                    { -388 }
  rsize: integer32;                     { D4 }
  sz: integer32;                        { -328, -384 }
  rl: integer;                          { -424 }
  rlen: integer;                        { -428 }
  size: integer32;
  k: integer32;
  j: integer32;
  i: integer32;
  r: integer32;
  k3: integer32;
  lim: integer32;
  step: integer32;                      { D6 }
  extra: integer32;                     { -408 }
  maxargs: integer32;                   { -316 }
  w: integer32;                         { -364 }
  nint: integer32;                      { -380 }
  hi: integer32;
  nfp: integer;                         { -430 }
  conv: integer;
  lvl: integer;
  code: integer;
  vat: integer;
  m0: integer32;
  m1: integer32;
  has_result: boolean;                  { -442 }
  nested: boolean;                      { D3 }
  pas: boolean;
  proto: boolean;
  typed: boolean;
  dbl: boolean;                         { -438 }
  is4: boolean;
begin
  offs := 0;
  blk := nil;
  link := nil;
  rlen := rlen_null;
  nfixed := 0;
  heap := addr(lir_3f60);
  nested := false;
  vats := nil;

  { 1. What is called. }
  if node^.kind = lib_dsc then begin
    opr := node;
    has_result := false;
    pas := lib_dsc_name_cmp(opr, pas_set_build, 14);
    pas := lib_dsc_name_cmp(opr, pas_ctov, 9) or pas;
    pas := lib_dsc_name_cmp(opr, pas_substr, 11) or pas;
    if pas then begin
      has_result := true;
      rlen := rlen_agg;
      rsize := 32;
    end;
    n := opr^.xw[5] + ord(has_result);
    if ord(opr^.xc[10 + 2 * opr^.xw[5]]) >= 128 then
      n := 20;
    preset := addr(preset_3);
    goto 100;
  end
  else if node^.kind = at_lib_dsc then begin
    opr := node;
    n := ord(node^.xc[80]);
    has_result := false;
    preset := addr(node^.xp[1]);
    goto 100;
  end
  else if (node^.kind = program_blk) or (node^.kind = procedure_blk)
          or (node^.kind = entry_blk) or (node^.kind = function_blk) then begin
    if (node^.kind = function_blk)
       or ((node^.kind = entry_blk)
           and (cc_blk_ptr_t(node)^.blk148^.kind = function_blk)) then begin
      has_result := true;
      get_rlen_and_size(node, rlen, sz);
      rsize := sz;
    end
    else if ftn_alt_rtn(node) then begin
      has_result := true;
      get_rlen_and_size(cc_blk_ptr_t(node)^.ret_var, rlen, sz);
      rsize := sz;
    end
    else
      has_result := false;
    blk := entry_blk_check(node);
    heap := addr(lir_3f78);
    b := cc_blk_ptr_t(node);
    conv := b^.unused_374.conv;
    if conv in [1, 5] then
      preset := addr(b^.preset)
    else if (conv = 3) and (15 in cargs_$options.flags_286) then
      preset := addr(preset_0)
    else
      preset := addr(preset_1);
    if conv = 3 then
      nested := (b^.lev.level > 0) and not b^.unused_374.b376_4
    else
      nested := b^.lev.level > 0;
    if conv in [1, 3, 5] then begin
      opr := b^.parms;
      vats := addr(b^.vats);
      n := b^.lev.nparms + ord(has_result);
      goto 100;
    end;
    cgerr(28, 0, strtk('call_conv cannot handle call', 31));
    goto 100;
  end
  else if (node^.kind = tree_node) or (node^.kind = gen_tree_node) then begin
    if (node^.xw[18] <> 15) and (node^.xw[18] <> 16) then
      goto 90;
    if node^.xw[18] = 16 then begin
      get_rlen_and_size(node, rlen, sz);
      rsize := sz;
      if rlen = rlen_cs then
        has_result := nested
      else
        has_result := true;
    end
    else
      has_result := nested;
    n := node^.xw[19] - 1;
    if has_result then
      n := n + 1;
    callee := node^.xp[10];
    if (callee^.kind = entry_blk) or (callee^.kind = function_blk)
       or (callee^.kind = procedure_blk) then begin
      blk := entry_blk_check(node^.xp[10]);
      opr := blk^.parms;
      conv := blk^.unused_374.conv;
      if conv in [1, 5] then
        preset := addr(blk^.preset)
      else
        preset := addr(preset_1);
      lvl := blk^.lev.level;
      nested := lvl > 0;
      if conv in [1, 5] then begin
        vats := addr(blk^.vats);
        if blk^.unused_374.b378_6 then begin
          cur := cc_blk_ptr_t(il_180);
          if lvl > cur^.lev.level then
            link := il_node_153
          else begin
            link := cur^.chain;
            for k := 1 to cur^.lev.level - blk^.lev.level do
              link := link^.xp[3];
          end;
        end;
        goto 100;
      end;
      if conv = 2 then begin
        if lvl = 0 then begin
          opr := il_$node_ptr_t(blk);
          nfixed := node^.xw[13] & 16#FFFF;
        end;
        if blk^.unused_374.b378_6 then begin
          cur := cc_blk_ptr_t(il_180);
          if lvl > cur^.lev.level then
            link := il_node_153
          else
            link := cur^.chain;
        end;
        goto 100;
      end;
      if conv = 4 then begin
        opr := il_$node_ptr_t(blk);
        goto 100;
      end;
      cgerr(28, 0, strtk('call_conv cannot handle call', 31));
      goto 100;
    end
    else if callee^.kind = pf_call then begin
      t := callee^.xp[5];
      opr := t^.xp[1];
      preset := addr(t^.xp[8]);
      nested := (ord(t^.xc[76]) & 1) <> 0;
      vats := addr(t^.xp[20]);
      goto 100;
    end
    else if callee^.kind = lib_dsc then begin
      opr := callee;
      if lib_dsc_name_cmp(callee, ftn_stop, 9) then
        preset := addr(preset_2)
      else
        preset := addr(preset_3);
      goto 100;
    end
    else if callee^.kind = at_lib_dsc then begin
      opr := callee;
      preset := addr(callee^.xp[1]);
      goto 100;
    end
    else if callee^.kind = fortran_symbol then begin
      opr := callee;
      preset := addr(preset_1);
      if callee^.kind = fortran_symbol then
        blk := entry_blk_check(callee^.xp[10])
      else
        blk := cc_blk_ptr_t(link);
      nfixed := node^.xw[13] & 16#FFFF;
      goto 100;
    end
    else if callee^.kind = cc_call then begin
      opr := callee;
      t := callee^.xp[4];
      if (t^.kind = function_blk) or (t^.kind = procedure_blk) then begin
        blk := cc_blk_ptr_t(t);
        nested := (blk^.lev.level > 0) and not blk^.unused_374.b376_4;
      end
      else
        blk := cc_blk_ptr_t(link);
      if blk <> nil then
        if 15 in cargs_$options.flags_286 then begin
          preset := addr(preset_0);
          goto 100;
        end;
      preset := addr(preset_1);
      goto 100;
    end
    else if callee^.kind = ptr_node then begin
      opr := callee;
      preset := addr(preset_1);
      goto 100;
    end;
    cgerr(28, 0, strtk('unrecognized opr[ 1 ]^.kind in call_conv', 41));
    goto 100;
  end;
90:
  cgerr(28, 0, strtk('unrecognized argument kind in call_conv', 42));
100:

  { 2. The record and its properties. }
  if 7 in preset^.flags then
    nested := true;
  size := 26 * (n - 1) + 108;
  if size > 4096 then
    props := rws_$alloc_heap(size)
  else
    props := mrh_$alloc(heap^, size);
  props^.link := link;
  props^.w12 := 3;
  props^.needs_db := true;
  if node^.kind = at_lib_dsc then begin
    props^.w24 := ord(node^.xc[47]);
    if props^.w24 > 127 then
      props^.w24 := props^.w24 - 256;
    props^.w14 := ord(node^.xc[46]);
    if ord(node^.xc[48]) < 128 then begin
      props^.needs_db := false;
      props^.no_memory_read := true;
      props^.no_arg_block_read := true;
    end;
    if (ord(node^.xc[48]) & 16#40) = 0 then begin
      props^.no_memory_write := true;
      props^.no_arg_block_write := true;
    end;
  end
  else begin
    props^.w24 := -1;
    props^.w14 := 22;
  end;
  props^.w18 := 21;
  props^.nargs := n;
  props^.nested := nested;
  props^.b29 := 10 in preset^.flags;
  if nested then
    if blk <> nil then
      blk^.unused_374.b379_6 := blk^.unused_374.b379_6
                                or blk^.unused_374.b376_4;
  if not nested then
    props^.w16 := 2
  else if blk = nil then
    props^.w16 := 21
  else if blk^.unused_374.b379_6 then
    props^.w16 := 2
  else
    props^.w16 := 21;
  if blk <> nil then begin
    props^.b27 := blk^.unused_374.cls = 0;
    if not props^.b27 then
      props^.uplevel_dynamic_storage_untouched := true;
    props^.data_sect := blk^.data_sect;
    props^.b30 := blk^.unused_374.made;
  end
  else begin
    props^.b27 := false;
    props^.data_sect := nil;
    props^.b30 := false;
  end;
  if blk = nil then begin
    props^.async := 8 in preset^.flags;
    props^.cleanup := false;
    if node^.kind = tree_node then begin
      t := node^.xp[10];
      if t^.kind = fortran_symbol then begin
        props^.cleanup := pfm_cleanup_check(t^.xc[72], t^.xw[35]);
        props^.async := props^.cleanup;
      end;
    end;
  end
  else begin
    props^.async := blk^.unused_374.b376_5;
    t := blk^.name.id;
    props^.cleanup := pfm_cleanup_check(t^.idnt_name, t^.idnt_len);
  end;
  props^.w20 := preset^.reg40;
  m1 := lshft(1, props^.w20 & 31);
  m0 := lshft(1, props^.w14 & 31);
  props^.fp_preserved[0] := preset^.fp_preserved[0];
  props^.fp_preserved[1] := preset^.fp_preserved[1];
  props^.ip_preserved := preset^.ip_preserved & ~m0 & ~m1;
  props^.fp_clobbered[0] := preset^.fp_clobbered[0];
  props^.fp_clobbered[1] := preset^.fp_clobbered[1];
  props^.ip_clobbered := (m0 ! preset^.ip_clobbered) & ~m1;
  props^.fp60[0] := preset^.fp16[0];
  props^.fp60[1] := preset^.fp16[1];
  props^.ip76 := m1 ! (~m0 & preset^.ip32);
  if blk <> nil then
    if blk^.rtn <> nil then
      with blk^.rtn^ do begin
        props^.needs_db := f226.needs_db;
        props^.no_memory_read := f226.no_memory_read;
        props^.no_memory_write := f226.no_memory_write;
        props^.no_arg_block_read := f226.no_arg_block_read;
        props^.no_arg_block_write := f226.no_arg_block_write;
        props^.no_pointer_dereference := f228.no_pointer_dereference;
        props^.common_block_untouched := f226.common_block_untouched;
        props^.static_storage_untouched := f228.static_storage_untouched;
        props^.uplevel_dynamic_storage_untouched := f228.uplevel_dynamic_storage_untouched;
        props^.no_fp_cc_write := f228.no_fp_cc_write;
        props^.no_ip_cc_write := f228.no_ip_cc_write;
        m0 := ~written_fp[0] & props^.fp_clobbered[0];
        props^.fp_clobbered[0] := written_fp[0];
        props^.fp_preserved[0] := props^.fp_preserved[0] ! m0;
        m0 := ~written_fp[1] & props^.fp_clobbered[1];
        props^.fp_clobbered[1] := written_fp[1];
        props^.fp_preserved[1] := props^.fp_preserved[1] ! m0;
        m0 := ~written_ip & props^.ip_clobbered;
        props^.ip_clobbered := written_ip;
        props^.ip_preserved := props^.ip_preserved ! m0;
      end;

  { 3. The result's and the arguments' descriptors. }
  if n = 0 then
    goto 80;
  if has_result then begin
    d := addr(props^.args[1]);
    d^.f16.rlen := rlen & 16#FF;
    d^.size := rsize;
    d^.num := 0;
    d^.w6 := 0;
    d^.f20.kind := 3;
    d^.by_value := true;
    d^.f22.mode := 0;
    d^.f22.reg := 0;
    if node^.kind = function_blk then
      d^.sym := cc_blk_ptr_t(node)^.ret_var
    else if ftn_alt_rtn(node) then
      d^.sym := cc_blk_ptr_t(node)^.ret_var
    else if (node^.kind = entry_blk)
            and (cc_blk_ptr_t(node)^.blk148^.kind = function_blk) then
      d^.sym := cc_blk_ptr_t(node)^.ret_var
    else
      d^.sym := nil;
    case rlen of
      rlen_null: d^.f18.loc := 4;
      rlen_byte, rlen_word, rlen_long, rlen_addr: d^.f18.loc := 0;
      rlen_r4: d^.f18.loc := 1;
      rlen_r8: d^.f18.loc := 2;
      otherwise
        if (blk <> nil) and (blk^.lev.level > 0) and (rlen = rlen_c8) then
          d^.f18.loc := 2
        else if (blk <> nil) and (blk^.lev.level > 0)
                and (rlen = rlen_c16) then
          d^.f18.loc := 3
        else begin
          d^.f18.loc := 0;
          d^.offset := 0;
          d^.f20.kind := 4;
          d^.by_value := false;
          d^.f22.mode := 3;
          offs := 4;
        end;
    end;
  end;
  if opr = nil then
    goto 60;
  if opr^.kind = lib_dsc then begin
    { A run-time library routine's: by its argument codes. }
    r := ord(has_result);
    k3 := 1;
    for k := 1 + r to n do begin
      d := addr(props^.args[k]);
      d^.f18.loc := 4;
      d^.num := k - r;
      d^.w6 := 0;
      d^.offset := offs;
      d^.sym := nil;
      if (node^.kind = tree_node) and (n - (node^.xw[13] & 16#FFFF) < k) then
        code := 8
      else begin
        if (opr^.xw[5] & 16#FFFF) < k3 then begin
          k3 := opr^.xw[5] & 16#FFFF;
          while ord(opr^.xc[8 + 2 * k3]) >= 128 do
            k3 := k3 - 1;
        end;
        code := ord(opr^.xc[11 + 2 * k3]) & 15;
      end;
      fill_arg_desc_using_ptt(d^, code, node);
      offs := offs + 4;
      k3 := k3 + 1;
    end;
    goto 60;
  end;
  if opr^.kind = at_lib_dsc then begin
    { Explicit conventions: the entries' places and registers. }
    for k := 1 to n do begin
      d := addr(props^.args[k]);
      d^.offset := 0;
      d^.num := ord(opr^.xc[78 + 12 * k]);
      if d^.num > 127 then
        d^.num := d^.num - 256;
      d^.w6 := 0;
      d^.f18.loc := ord(opr^.xc[80 + 12 * k]);
      d^.f22.reg := ord(opr^.xc[83 + 12 * k]);
      d^.b25 := false;
      d^.sym := nil;
      code := ord(opr^.xc[82 + 12 * k]);
      fill_arg_desc_using_ptt(d^, code, node);
    end;
    offs := 24;
    goto 60;
  end;
  if (opr^.kind = param_name)
     or ((opr^.kind = param_list) and (blk^.lev.level > 0)) then begin
    { The parameters (121, chained) or a prototype's entries (168). }
    if (opr^.kind = param_list) and (rlen = rlen_cs) then begin
      d := addr(props^.args[1]);
      d^.f18.loc := 4;
      d^.num := 1;
      d^.w6 := 0;
      d^.f20.kind := 4;
      d^.by_value := false;
      d^.f22.mode := 3;
      d^.f16.rlen := rlen_cs;
      if (node^.kind = program_blk) or (node^.kind = procedure_blk)
         or (node^.kind = entry_blk) or (node^.kind = function_blk) then begin
        d^.sym := unset396;
        get_rlen_and_size(unset396, rl, sz);
      end
      else begin
        d^.sym := nil;
        get_rlen_and_size(node, rl, sz);
      end;
      d^.size := sz;
      d^.offset := offs;
      offs := offs + 4;
    end;
    r := ord((rlen = rlen_cs) or has_result);
    for k := 1 + r to n do begin
      d := addr(props^.args[k]);
      d^.f20.kind := 0;
      if opr^.kind = param_name then
        get_rlen_and_size(opr, rl, sz)
      else
        get_rlen_and_size(opr^.xp[3 * (k - ord((rlen = rlen_cs) or has_result))],
                          rl, sz);
      d^.f18.loc := 4;
      d^.f16.rlen := rl;
      d^.size := sz;
      d^.offset := offs;
      d^.num := k - ord(has_result);
      d^.w6 := 0;
      step := 4;
      if (node^.kind = function_blk) or (node^.kind = procedure_blk) then
        d^.sym := blk_fnd_name(c_parm_ptr_t(opr)^.pname, false, false,
                               c_blk_ptr_t(node))
      else
        d^.sym := nil;
      if (opr^.kind = param_name)
         and (((ord(opr^.xc[27]) & 16#40) <> 0)
              or (ord(opr^.xc[27]) >= 128)) then begin
        { A parameter declared in a register. }
        d^.f22.reg := ord(opr^.xc[43]);
        case opr^.xw[20] of
          0: d^.f18.loc := 0;
          1: d^.f18.loc := 1;
          2: begin
            d^.f18.loc := 2;
            step := 8;
          end;
          otherwise
            ;
        end;
        d^.f22.mode := ord(opr^.xc[45]);
        if (ord(opr^.xc[27]) & 16#40) <> 0 then begin
          d^.by_value := true;
          if d^.size < 4 then
            d^.offset := offs + 4 - d^.size;
        end
        else
          d^.by_value := false;
      end
      else if (blk <> nil) and (blk^.unused_374.conv = 2) then begin
        d^.by_value := rshft(ord(il_$node_ptr_t(d^.sym)^.xc[11]) & 16#F0, 4)
                       = 2;
        if d^.by_value then begin
          d^.f22.mode := 2;
          step := (d^.size + 3) div 4 * 4;
          if d^.size < 4 then
            d^.offset := offs + 4 - d^.size;
        end
        else
          d^.f22.mode := 1;
      end
      else if (blk <> nil) and (blk^.unused_374.conv = 3) then begin
        d^.by_value := true;
        d^.f22.mode := 0;
        step := (d^.size + 3) div 4 * 4;
        if d^.size < 4 then
          d^.offset := offs + 4 - d^.size;
      end
      else begin
        d^.f22.mode := ord(opr^.xc[45]);
        d^.by_value := (vats^[d^.num] & 16#FFFF) <= 6;
        if not d^.by_value then begin
          type_exp(opr, addr(te));
          if ((node^.kind = gen_tree_node) or (node^.kind = tree_node))
             and ((node^.xw[18] = 16) or (node^.xw[18] = 15)) then
            if ord(opr^.xc[46]) >= 128 then begin
              a := node^.xp[10 + d^.num];
              if a^.kind = integer_ob then begin
                if (d^.f16.rlen <> rlen_word) and (d^.f16.rlen <> rlen_byte) then begin
                  d^.f16.rlen := rlen_long;
                  d^.size := step;
                end;
              end
              else if (a^.kind = var_name) and (a^.xw[36] = 5) then begin
                d^.f16.rlen := rlen_addr;
                d^.size := step;
              end
              else begin
                get_rlen_and_size(a, rl, sz);
                if rl <> 0 then begin
                  d^.f16.rlen := rl;
                  d^.size := sz;
                end;
              end;
            end
            else if te.base^.kind = varying_type then begin
              get_rlen_and_size(node^.xp[10 + d^.num], rl, sz);
              if rl <> 0 then
                d^.size := sz;
            end;
        end
        else
          case d^.f16.rlen of
            rlen_byte: d^.offset := offs + 3;
            rlen_word: d^.offset := offs + 2;
            rlen_r8: begin
              step := 8;
              d^.offset := offs;
            end;
            rlen_long, rlen_r4: d^.offset := offs;
            otherwise begin
              d^.offset := offs;
              step := (d^.size + 3) div 4 * 4;
            end;
          end;
      end;
      offs := offs + step;
      if opr^.kind = param_name then
        opr := opr^.xp[1];
    end;
    { The parameters done. }
    goto 60;
  end;
  if (opr^.kind = procedure_blk) or (opr^.kind = entry_blk)
      or (opr^.kind = function_blk) then
    is4 := cc_blk_ptr_t(opr)^.unused_374.conv = 4
  else
    is4 := false;
  if is4 or (opr^.kind = fortran_symbol) or (opr^.kind = ptr_node) then begin
    { FORTRAN's: by reference, the strings by descriptor after the
      fixed arguments. }
    r := ord(has_result);
    lim := n - nfixed;
    for k := 1 + r to n do begin
      d := addr(props^.args[k]);
      d^.f18.loc := 4;
      discard(pass_char_len_diff(opr));
      d^.num := k - r;
      d^.w6 := 0;
      d^.offset := offs;
      d^.by_value := false;
      d^.f20.kind := 0;
      d^.sym := nil;
      if d^.num + r <= lim then begin
        d^.f22.mode := 1;
        get_rlen_and_size(node^.xp[10 + d^.num], rl, sz);
        ftn_param_vat_check(node^.xp[10 + d^.num], rl, sz);
        a := node^.xp[10 + d^.num];
        if a^.kind = integer_ob then
          if a^.int_value = 0 then begin
            rl := 4;
            sz := 4;
          end
          else begin
            rl := 2;
            sz := 2;
          end;
        d^.f16.rlen := rl;
        d^.size := sz;
      end
      else begin
        d^.f22.mode := 2;
        if pass_char_len_diff(opr) then begin
          d^.by_value := true;
          d^.f16.rlen := rlen_long;
          d^.size := 4;
          if (rlen = rlen_cs) and (d^.num + r = lim + 1) then
            d^.f20.kind := 5
          else
            d^.f20.kind := 1;
        end
        else begin
          d^.f16.rlen := rlen_word;
          d^.size := 2;
          if (rlen = rlen_cs) and (d^.num + r = lim + 1) then
            d^.f20.kind := 6
          else
            d^.f20.kind := 2;
        end;
      end;
      offs := offs + 4;
    end;
    goto 60;
  end;
  if opr^.kind = cc_call then begin
    { Through a pointer: the callee's prototype, else the pointer's
      entries (a word size at +16, a byte class at +19, 4 each). }
    r := ord(has_result);
    for k := 1 + r to n do begin
      d := addr(props^.args[k]);
      d^.f18.loc := 4;
      j := k - r;
      d^.num := j;
      d^.w6 := 0;
      d^.f20.kind := 0;
      d^.by_value := true;
      d^.f22.mode := 0;
      d^.sym := nil;
      typed := false;
      if blk <> nil then
        if blk^.params <> nil then
          if k - r <= blk^.params^.count then
            if blk^.params^.types[j]^.kind <> label_ob then
              typed := true;
      if typed then begin
        type_exp(blk^.params^.types[j], addr(te));
        d^.f16.rlen := get_rlen(te);
        d^.size := te.size;
      end
      else begin
        d^.size := opr^.xw[8 + 2 * j];
        d^.f16.rlen := ord(opr^.xc[19 + 4 * j]);
      end;
      if d^.size < 4 then
        d^.offset := offs + 4 - d^.size
      else
        d^.offset := offs;
      sz := (d^.size + 3) & ~3;
      offs := offs + sz;
    end;
  end;
60:

  { 4. The registers. }
  nint := 4;
  if has_result then
    if not props^.args[1].by_value then begin
      props^.args[1].f22.reg := 4;
      nint := 5;
    end;
  proto := false;
  if opr <> nil then
    if opr^.kind = cc_call then begin
      proto := true;
      pt := get_proto(opr^.xp[4]);
    end;
  if (node^.kind = procedure_blk) or (node^.kind = entry_blk)
      or (node^.kind = function_blk) then
    if cc_blk_ptr_t(node)^.unused_374.conv = 3 then begin
      proto := true;
      pt := get_proto(node);
    end;
  if 6 in preset^.flags then
    proto := true;
  if proto then begin
    extra := 0;
    nfp := 8;
    for k := 1 + ord(has_result) to n do begin
      i := extra + k;
      d := addr(props^.args[i]);
      if d^.f18.loc = 4 then begin
        typed := false;
        if pt <> nil then
          if pt^.count >= d^.num then
            if pt^.types[d^.num]^.kind <> label_ob then
              typed := true;
        if typed and (d^.f16.rlen = rlen_r4) then begin
          if nfp <= 19 then begin
            d^.f18.loc := 1;
            d^.f22.reg := nfp;
            nfp := nfp + 1;
          end;
          next;
        end;
        if (d^.f16.rlen = rlen_r8)
           and (typed or (node^.kind = function_blk)
                or (node^.kind = procedure_blk)) then begin
          if odd(nfp) then
            nfp := nfp + 1;
          if nfp <= 19 then begin
            d^.f18.loc := 2;
            d^.f22.reg := nfp;
            nfp := nfp + 2;
          end;
          if nint <= 9 then
            nint := nint + 1;
          if nint <= 9 then
            nint := nint + 1;
          next;
        end;
        dbl := (d^.f16.rlen = rlen_r8) and (nfp + 1 <= 19);
        if (nint > 9) and not dbl then
          next;
        if (d^.size <= 4) or not d^.by_value then begin
          d^.f18.loc := 0;
          d^.f22.reg := nint;
          nint := nint + 1;
          next;
        end;

        { An aggregate by value: its longwords in the integer registers
          left (and a double's pair), the descriptors after it moved
          up. }
        if extra = 0 then begin
          old := props;
          maxargs := rshft(19 - nfp, 1);
          if maxargs > n - k then
            maxargs := n - k;
          maxargs := maxargs + (9 + n - nint) + 2;
          size := 26 * maxargs + 108;
          if size > 4096 then
            props := rws_$alloc_heap(size)
          else
            props := mrh_$alloc(heap^, size);
          cc_copy_ptr_t(props)^ := cc_copy_ptr_t(old)^;
          for j := 1 to n do
            props^.args[j] := old^.args[j];
          d := addr(props^.args[i]);
        end;
        w := (d^.size - 1) div 4;
        if 9 - nint + 1 < w then
          w := 9 - nint + 1;
        if nint <= 9 then begin
          d^.f18.loc := 0;
          d^.f22.reg := nint;
          nint := nint + 1;
        end;
        for j := n downto k + 1 do
          props^.args[extra + j + w + ord(dbl)] := props^.args[extra + j];
        for j := 1 to w do begin
          e := addr(props^.args[i + j]);
          e^ := d^;
          e^.w6 := props^.args[i + j - 1].w6 + 4;
          e^.offset := props^.args[i + j - 1].offset + 4;
          if (j = w) and (d^.size - 4 * w > 4) then begin
            e^.size := d^.size - 4 * w;
            e^.f16.rlen := rlen_agg;
          end
          else begin
            e^.size := 4;
            e^.f16.rlen := rlen_long;
          end;
          if nint > 9 then
            e^.f18.loc := 4
          else begin
            if not dbl and (w > 1) then
              e^.b25 := true;
            e^.f22.reg := nint;
            nint := nint + 1;
          end;
        end;
        if dbl then begin
          e := addr(props^.args[i + w + 1]);
          e^ := d^;
          if odd(nfp) then
            nfp := nfp + 1;
          e^.f18.loc := 2;
          e^.f22.reg := nfp;
          nfp := nfp + 2;
        end;
        if w <> 0 then begin
          d^.size := 4;
          d^.f16.rlen := rlen_long;
        end;
        props^.nargs := props^.nargs + ord(dbl) + w;
        extra := extra + ord(dbl) + w;
        if props^.nargs > maxargs then
          bug_check('CALL_CONV -- arg_cnt greater than arg_desc_max%.');
        { The aggregate done. }
      end;
    end;
    n := props^.nargs;
  end
  else begin
    for k := 1 + ord(has_result) to n do begin
      d := addr(props^.args[k]);
      if d^.f18.loc = 4 then
        if (d^.f16.rlen = rlen_byte) or (d^.f16.rlen = rlen_word)
           or (not d^.by_value or (d^.f16.rlen = rlen_addr))
           or (d^.f16.rlen = rlen_long) then begin
          d^.f18.loc := 0;
          d^.f22.reg := nint;
          if nint = 9 then
            exit;
          nint := nint + 1;
        end;
    end;
    nfp := 8;
    for k := 1 + ord(has_result) to n do begin
      d := addr(props^.args[k]);
      if (d^.f18.loc = 4) and d^.by_value then
        if d^.f16.rlen = rlen_r4 then begin
          if nfp > 19 then
            goto 80;
          d^.f18.loc := 1;
          d^.f22.reg := nfp;
          nfp := nfp + 1;
        end
        else if d^.f16.rlen = rlen_r8 then begin
          if odd(nfp) then
            nfp := nfp + 1;
          if nfp > 19 then
            goto 80;
          d^.f18.loc := 2;
          d^.f22.reg := nfp;
          nfp := nfp + 2;
        end;
    end;
  end;
80:

  { 5. The b25 flags, the variable arguments' registers, the formals'
    offsets. }
  for j := 1 to props^.nargs do
    props^.args[j].b25 := false;
  b := cc_blk_ptr_t(node);
  if ((node^.kind = function_blk) or (node^.kind = procedure_blk))
     and b^.unused_374.b374_6 then
    if (b^.params = nil)
       or (b^.params^.types[b^.params^.count]^.kind = label_ob) then begin
      hi := 4;
      for j := 1 to props^.nargs do begin
        d := addr(props^.args[j]);
        if (d^.f18.loc = 0) and (d^.f22.reg >= hi) then
          hi := d^.f22.reg + 1
        else if d^.f18.loc = 2 then
          hi := hi + 2;
      end;
      if hi <= 9 then begin
        old := props;
        size := 26 * (9 + n - hi) + 108;
        if size > 4096 then
          props := rws_$alloc_heap(size)
        else
          props := mrh_$alloc(heap^, size);
        cc_copy_ptr_t(props)^ := cc_copy_ptr_t(old)^;
        for j := 1 to n do
          props^.args[j] := old^.args[j];
        for k := hi to 9 do begin
          n := n + 1;
          d := addr(props^.args[n]);
          d^.offset := offs;
          offs := offs + 4;
          d^.num := props^.args[n - 1].num + 1;
          d^.w6 := 0;
          d^.size := 4;
          d^.f16.rlen := rlen_long;
          d^.f18.loc := 0;
          d^.by_value := true;
          d^.f22.mode := 0;
          d^.f22.reg := k;
          d^.b25 := true;
          d^.sym := make_expression_temporary(122, 32);
        end;
        props^.nargs := n;
      end;
      r := ord(has_result);
      for j := 1 to props^.nargs do begin
        d := addr(props^.args[j]);
        if j <= r then
          d^.b25 := false
        else if (b^.params <> nil) and (d^.num < b^.params^.count) then
          d^.b25 := false
        else begin
          d^.b25 := true;
          if d^.sym <> nil then
            c_sym_ptr_t(d^.sym)^.var_flags :=
              c_sym_ptr_t(d^.sym)^.var_flags + [0];
        end;
      end;
    end;
  for j := props^.nargs downto 1 do begin
    d := addr(props^.args[j]);
    t := d^.sym;
    if t <> nil then
      if not (has_result and (j = 1) and (d^.f22.mode = 0)) then begin
        if t^.kind = var_name then begin
          c_sym_ptr_t(t)^.var_offset := d^.offset + 16;
          c_sym_ptr_t(t)^.var_flags := c_sym_ptr_t(t)^.var_flags + [10];
          vat := ord(c_sym_ptr_t(t)^.var_vat);
        end
        else if t^.kind = fortran_symbol then begin
          t^.xl[3] := d^.offset + 16;
          t^.xc[26] := chr(ord(t^.xc[26]) ! 4);
          vat := rshft(ord(t^.xc[11]) & 16#F0, 4);
        end;
        if (d^.by_value and (vat = 5))
           or (not d^.by_value and (vat = 2)) then begin
          t := cc_blk_ptr_t(node)^.name.id;
          bug_check('CALL_CONV -- by value/by reference consistency check failed in routine %a.%$',
                    t^.idnt_name, t^.idnt_len);
        end;
      end;
  end;
  props^.args_size := offs;
  at_call_conv := props;
end;
