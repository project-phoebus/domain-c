{ dmp - the PRISM back end's dumps (cc.a88k only): what the phases'
  debug switches print of a routine as it is compiled: its blocks
  (dmp_$basic_block_header: the flow graph, dominators, loops,
  hammocks, the data flow vectors and the register allocator's
  counts), its instructions (dmp_$instruction, one line for each flag
  and operand, or dmp_$instr_print_single_line), its live ranges and
  their lifetime segments (dmp_$whole_routine), the register
  allocator's interference graph, and MRH's memory use.  Everything is
  written with vfmt_$write; what is printed depends on the running
  phase (at_backend_phase): the same fields mean other things before
  and after the scheduler, the register allocator and the assembler.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x22F188  dmp_$starting_basic_block
    --------  0x22F1FC  dmp_$note_label
    --------  0x22F228  dmp_$operand_kind
    --------  0x22F274  print_jbi_list (internal)
    --------  0x22F2DA  dmp_$flow_graph_edge_list (internal)
    --------  0x22F374  dmp_$complex_lr_bit_vector_header
    --------  0x22F48C  dmp_$complex_lr_bit_vector
    --------  0x22F5D8  dmp_$reg_set
    --------  0x22F6D8  dmp_$basic_block_register_info (internal)
    --------  0x22F87C  dmp_$bit_vectors_for_basic_block (internal)
    --------  0x22FA44  dmp_$basic_block_header (internal)
    --------  0x2304A8  dmp_$all_basic_block_headers
    --------  0x2304E8  print_memory_home (internal)
    --------  0x2306D0  print_register_if_assigned (internal)
    --------  0x230834  print_alias_desc (internal)
    --------  0x2309C4  dmp_$get_line_number
    --------  0x230A2E  dmp_$instruction
    --------  0x232010  dmp_$three_char_lr_name_from_lr
    --------  0x232130  dmp_$instr_print_single_line
    --------  0x232F74  print_properties
    --------  0x233054  print_lts_list (internal)
    --------  0x23360C  dmp_$print_exposed_lts_list
    --------  0x233672  dmp_$print_final_lts_list
    --------  0x2336CA  display_ra_info (internal)
    --------  0x23394A  dmp_$whole_routine
    --------  0x2345FA  dmp_$interference_graph_analysis
    --------  0x23474A  dmp_$memory_usage
    A5 0x486074: the module's data (0x3F8 bytes): the line prtobj,
    lst_$prtlit and the symbol names are put in (+0, a prtsub_$line_t),
    the scale suffixes (+0x108, initialized "  *2*4*8"), the .init
    tables (rrp_string_length +0x110, rrp_string +0x130,
    lsq_string_length +0x240, lsq_string +0x260, block_string_length
    +0x2E0, block_string +0x2E8, am_string_length +0x300, am_string
    +0x320), the block at which to turn the debug switches on (+0x3C0)
    and those switches (dmp_3c2, +0x3C2: at_backend sets both),
    operand_letter (+0x3C8) and rrp_letter (+0x3E8).  Standard output
    (for one `write' of an IL node kind) is the file at (-4,A5).

  The phases' dumps read many fields of batch A's records that the
  translated units have not named: they are read here through
  unit-local views (dmp_ihdr_t, dmp_opnd_t, dmp_rtn_t, dmp_bb_t,
  dmp_lr_t, ...), with the meanings the dumps' texts give them; the
  names are dmp's strings.  An instruction's operand k is at +32 + 12k
  (its +0 k): dmp finds an operand's instruction by subtracting (as
  utils_ins_$operands_instruction does, inline here: dmp does not open
  utils.ins.pas).

  Other units' cells: alias.pas's class_names (A5 0x2E8DFC, as mmt
  reads them; docs/questions.md 170) and mrh.pas's heap_names, heaps
  and heap_count (its data +0x4000, +0x4400, +0x481C: 0x2EDFB8,
  0x2EE3B8, 0x2EE7D4, reached absolutely), declared extern here with
  their owners' names (neither owner defines them: docs/questions.md).

  Not known from the original: every local, parameter and type name;
  the views' field names other than the dumps' strings.

  dpc gaps (docs/dpc-gaps.md): 4 (the `write' of an IL node kind in
  dmp_$instruction). }
module dmp;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/alias.ins.pas';
%include 'lang/lang/source/prtobj.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_com/at_base.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/am_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/am_string_length.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/block_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/block_string_length.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/lsq_string_length.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_string.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_string_length.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/operand_letter.init';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/backend.ins.pas/hbe6404cd.000/backend.ins/rrp_letter.init';

type
  { An instruction's first longword as the dumps name its bits (batch
    A's instr_hdr_t; dmp copies it to a local).  +2 and +3 mean other
    things by the phase and the opcode: +2 bit 7 has_alias_descriptor
    (of an instruction whose class may carry one) and, from the ASM
    phase, has_fp_companion; bit 6 needed, from the ASM phase
    pair_with_companion_nop; bits 3..0 (signed) the stalls the
    scheduler counted; +3 of a branch (an opcode that takes a squash
    suffix) its squash and call flags, of a load or store its
    addressing mode and qualifier (and bits 3..1 a signed number
    printed with +2's bits 1..0 before the scheduler), of a label its
    label flags, of an insert or extract its field width. }
  dmp_ihdr_ptr_t = ^dmp_ihdr_t;
  dmp_ihdr_t = packed record
    atomic_update: boolean;             { +0 .7 }
    preference: boolean;                { .6 }
    quad_aligned: boolean;              { .5 }
    ip_ccs: boolean;                    { .4 (batch A's sets_cc) }
    fp_ccs: boolean;                    { .3 }
    continued: boolean;                 { .2 (batch A's grouped) }
    b0_1: boolean;                      { .1: +32 points to the source
                                          position }
    b0_0: boolean;
    nopnds: 0..255;                     { +1 }
    case integer of
      1: (b2_7: boolean;                { +2 .7 }
          b2_6: boolean;                { .6 }
          may_generate_an_exception: boolean;    { .5 }
          volatile_location: boolean;   { .4 }
          do_not_delete: boolean;       { .3 }
          b2_2_0: 0..7;
          s_seq: boolean;               { +3 .7: the delay slot runs on
                                          sequential flow }
          s_xfer: boolean;              { .6: it runs on the transfer }
          possible_nonlocal_return: boolean;     { .5 }
          no_return: boolean;           { .4 }
          final_call: boolean;          { .3 }
          b3_2: boolean;
          function_key: 0..3);          { .1..0: 1 cos, 2 sin, 3 cossin }
      2: (b2_7_4: 0..15;
          stalls: -8..7;                { +2 .3..0 }
          modify: 0..3;                 { +3 .7..6: am$t }
          lsq: 0..3;                    { .5..4: lsq$t }
          disp3: -4..3;                 { .3..1 }
          b3_0: boolean);
      3: (b2_7_2: 0..63;
          disp2: -2..1;                 { +2 .1..0 }
          required_label: boolean;      { +3 .7 }
          label_is_reachable: boolean;  { .6 }
          b3_5_0: 0..63);
      4: (b2: 0..255;
          width: 0..255);               { +3 }
  end;

  { An operand as the dumps read it (batch A's opnd_t): rrp the low byte
    of its rrp$set_t; last_use (+2 bit 7); count (+2 bits 5..4, which
    print as a digit); bias (+2 bits 3..0, signed); bytes (+3 bits 7..5,
    signed: a displacement's access size); the kind; link (+4) the
    symbol, label, literal or join inputs; +8 the value, the segment
    (before the POST phase) or the live range (after it), the edge. }
  dmp_opnd_ptr_t = ^dmp_opnd_t;
  dmp_opnd_t = packed record
    num: 0..255;                        { +0 }
    rrp: 0..255;                        { +1 }
    last_use: boolean;                  { +2 .7 }
    b2_6: boolean;
    count: 0..3;                        { .5..4 }
    bias: -8..7;                        { .3..0 }
    bytes: -4..3;                       { +3 .7..5 }
    kind: 0..31;                        { .4..0: operand$t }
    link: univ_ptr;                     { +4 }
    case integer of                     { +8 }
      1: (value: integer32);
      2: (lts: lts_ptr_t);
      3: (lr: lr_ptr_t);
      4: (edge: fg_edge_ptr_t);
      5: (col: integer;                 { +8 }
          msg: 0..255;                  { +10 }
          svc: 0..255);                 { +11 }
      6: (w8: 0..65535;
          w10: 0..65535);
  end;

  { An 8-byte register set (registers 32..63 in hi, 0..31 in lo). }
  dmp_set64_t = record
    hi: bv_word_t;
    lo: bv_word_t;
  end;

  { The routine's IL node: the register sets the conventions give it. }
  dmp_rnode_ptr_t = ^dmp_rnode_t;
  dmp_rnode_t = record
    space0: array [0..331] of char;
    fp_preserve: dmp_set64_t;           { +332 }
    fp_no_preserve: dmp_set64_t;        { +340 }
    fp_no_modify: dmp_set64_t;          { +348 }
    ip_preserve: bv_word_t;             { +356 }
    ip_no_preserve: bv_word_t;          { +360 }
    ip_no_modify: bv_word_t;            { +364 }
  end;

  { The routine (batch A's rtn_t) where the dumps read fields it has
    not named; +208..+224 are lst's pe_info_t (bin passes the routine
    there). }
  dmp_rtn_ptr_t = ^dmp_rtn_t;
  dmp_rtn_t = record
    node: dmp_rnode_ptr_t;              { +0 }
    space4: array [4..47] of char;
    frame_size: integer32;              { +48 }
    space52: array [52..147] of char;
    written_ip: bv_word_t;              { +148 }
    written_fp: dmp_set64_t;            { +152 }
    saved_ip: bv_word_t;                { +160 }
    saved_fp: dmp_set64_t;              { +164 }
    space172: array [172..175] of char;
    arg_end: integer32;                 { +176: the supplied argument
                                          block's end offset }
    space180: array [180..193] of char;
    ncomplex: 0..65535;                 { +194: rtn_t's l192's low word }
    space196: array [196..197] of char;
    ncomplex2: 0..65535;                { +198: added (rounded up to 32)
                                          from the DBG_LIFE phase }
    space200: array [200..207] of char;
    sf_reg: integer;                    { +208: the stack frame's
                                          register }
    all_regs_saved: integer;            { +210 }
    different_db: integer;              { +212 }
    from_ecb: integer;                  { +214 }
    stack_pushed: integer;              { +216 }
    saved_from: integer;                { +218 }
    saved_to: integer;                  { +220 }
    save_reg_4: integer;                { +222: saved at [04,SF] }
    save_reg_12: integer;               { +224: saved at [12,SF] }
  end;

  { A block's exception frame (bb +42). }
  dmp_exc_ptr_t = ^dmp_exc_t;
  dmp_exc_t = record
    l0: integer32;
    l4: integer32;
    frame: integer32;                   { +8 }
  end;

  { A block (batch A's bb_t) where the dumps read fields it has not
    named: the register allocator's counts (+0..+7) and the written
    registers (+122..+133, the availability vectors' place). }
  dmp_bb_ptr_t = ^dmp_bb_t;
  dmp_bb_t = record
    ra: packed record                   { +0 }
      live_in_ip: 0..255;
      live_out_ip: 0..255;
      max_ip: 0..255;
      pass_ip: 0..255;
      live_in_fp: 0..255;
      live_out_fp: 0..255;
      max_fp: 0..255;
      pass_fp: 0..255;
      end;
    space8: array [8..41] of char;
    exc: dmp_exc_ptr_t;                 { +42 }
    space46: array [46..121] of char;
    written_ip: bv_word_t;              { +122 }
    written_fp: dmp_set64_t;            { +126 }
  end;

  { A hammock (hal's, bb_t's l98): head and exit blocks, the hammock it
    is in, its first child and its next sibling. }
  dmp_ham_ptr_t = ^dmp_ham_t;
  dmp_ham_t = record
    head: bb_ptr_t;                     { +0 }
    exit: bb_ptr_t;                     { +4 }
    parent: dmp_ham_ptr_t;              { +8 }
    children: dmp_ham_ptr_t;            { +12 }
    next: dmp_ham_ptr_t;                { +16 }
  end;

  { A conflict of the register allocator's interference graph (a live
    range's +44 during RA): the two live ranges, the next conflict of
    each (tagged in the low two bits), and what display_ra_info prints
    of it. }
  dmp_conf_ptr_t = ^dmp_conf_t;
  dmp_conf_t = record
    a: lr_ptr_t;                        { +0 }
    b: lr_ptr_t;                        { +4 }
    next_a: integer32;                  { +8 }
    next_b: integer32;                  { +12 }
    l16: integer32;
    l20: integer32;                     { +20 }
    l24: integer32;                     { +24 }
    b28: char;                          { +28 }
  end;

  { A PC range of a live range's lifetime (+44 in the DBG_LIFE phase). }
  dmp_pcr_ptr_t = ^dmp_pcr_t;
  dmp_pcr_t = record
    next: dmp_pcr_ptr_t;                { +0 }
    loaded: integer32;                  { +4 }
    killed: integer32;                  { +8 }
  end;

  { A live range (batch A's lr_t) where the dumps read fields it has
    not named: during RA the preferenced (+64) and conflicting (+80)
    register sets in the segment lists' place; in DBG_LIFE the PC
    ranges (+44) and their count (+72). }
  dmp_lr_ptr_t = ^dmp_lr_t;
  dmp_lr_t = record
    space0: array [0..43] of char;
    l44: univ_ptr;                      { +44 }
    space48: array [48..63] of char;
    preferenced: dmp_set64_t;           { +64 }
    nranges: integer32;                 { +72 }
    space76: array [76..79] of char;
    conflicting: dmp_set64_t;           { +80 }
  end;

  { The KONST phase's value of a segment (lts +40): kind (+7) 0 bottom,
    1 symbolic, 2 B_K/B_T, 3 a CS range, 4 a constant, 5 top. }
  dmp_konst_ptr_t = ^dmp_konst_t;
  dmp_konst_t = record
    l0: integer32;
    w4: integer;
    b6: char;
    kind: char;                         { +7 }
    l8: integer32;                      { +8 }
    l12: integer32;
    l16: integer32;
    l20: integer32;
    sym: univ_ptr;                      { +24 }
  end;

  { A join birthpoint's inputs (jbi): next (+4) and the segment (+8). }
  dmp_jbi_ptr_t = ^dmp_jbi_t;
  dmp_jbi_t = record
    l0: integer32;
    next: dmp_jbi_ptr_t;                { +4 }
    lts: lts_ptr_t;                     { +8 }
  end;

  { The joins a defining segment is an input to (lts +44): next (+0),
    the join's instruction (+12). }
  dmp_join_ptr_t = ^dmp_join_t;
  dmp_join_t = record
    next: dmp_join_ptr_t;               { +0 }
    l4: integer32;
    l8: integer32;
    instr: instr_ptr_t;                 { +12 }
  end;

  { An IL node, as the dumps read it: kind (+2), +4, the memory home's
    vat (+11 bits 7..4 of kind 110, +72 of kind 109). }
  dmp_node_ptr_t = ^dmp_node_t;
  dmp_node_t = record
    w0: integer;
    kind: il_$kind_t;                   { +2 }
    l4: univ_ptr;                       { +4 }
    space8: array [8..10] of char;
    b11: char;                          { +11 }
    space12: array [12..71] of char;
    vat: integer;                       { +72 }
  end;

  { An instruction's source position (+32): with +0 bit 1 a pointer
    to a record whose +4 is the line, else the line and a word that,
    nonzero, marks a line not to be used before the MMT phase. }
  dmp_pos_ptr_t = ^dmp_pos_t;
  dmp_pos_t = record
    l0: integer32;
    line: 0..65535;                     { +4 }
  end;
  dmp_ipos_ptr_t = ^dmp_ipos_t;
  dmp_ipos_t = record
    case integer of
      1: (p: dmp_pos_ptr_t);
      2: (line: 0..65535;
          marked: integer);
  end;

  { An instruction's +28..+31 during RA: four counts. }
  dmp_i28_ptr_t = ^dmp_i28_t;
  dmp_i28_t = packed record
    b28, b29, b30, b31: 0..255;
  end;

  { The registers a call or SVC clobbers, after its operands. }
  dmp_clob_ptr_t = ^dmp_clob_t;
  dmp_clob_t = record
    fp: dmp_set64_t;                    { +44 + 12n }
    ip: bv_word_t;                      { +52 + 12n }
  end;

  { lst_13c: by source line, its line in the listing. }
  dmp_line_map_ptr_t = ^dmp_line_map_t;
  dmp_line_map_t = array [0..65535] of 0..65535;

  { MRH's chunk map (mrh_$get_map): by chunk, the next and its owner
    (a heap's index; negated when freed). }
  dmp_map_ptr_t = ^dmp_map_t;
  dmp_map_t = array [0..65535] of record
    next: integer;
    owner: integer;
  end;

  dmp_desc_ptr_t = ^alias_$desc_t;
  dmp_sw_view_ptr_t = ^dmp_sw_view_t;
  dmp_sw_view_t = record
    case integer of
      1: (s: at_switches_t);
      2: (w: integer);
  end;
  dmp_rrp_view_t = record
    case integer of
      1: (w: integer);
      2: (s: rrp$set_t);
  end;
  dmp_name9_t = packed array [1..9] of char;
  dmp_name20_t = packed array [1..20] of char;

var
  dmp_line: prtsub_$line_t;             { +0 }
  dmp_scale: array [0..3] of packed array [1..2] of char := [
    '  ', '*2', '*4', '*8'];            { +0x108 }
  dmp_3c0: integer;                     { +0x3C0: the block at which
                                          dmp_$starting_basic_block turns
                                          the switches on (at_backend) }

  { Other units' cells (above). }
  class_names: extern array [0..16] of dmp_name20_t;
  heap_names: extern array [1..256] of ^mrh_$name_t;
  heaps: extern array [1..256] of ^mrh_$heap_t;
  heap_count: extern integer32;

define
  dmp_3c2;

{ DMP_$STARTING_BASIC_BLOCK - 0x22F188, 0x5E bytes.  dmp_3c0 0
  (`tst.w (960,A5)'): the block's number when dmp_3c2's level is set
  (`moveq #7; and.b (963,A5)'); else at that block dmp_3c2 is stored in
  at_backend_switches (`move.w (962,A5),0x485D30'), elsewhere a word
  0 (`clr.w'). }
procedure dmp_$starting_basic_block;
begin
  if dmp_3c0 = 0 then begin
    if dmp_3c2.level <> 0 then
      vfmt_$write('%/%/  -- BB#%3ZWD%/%.', bb^.num);
  end
  else if bb^.num = dmp_3c0 then
    at_backend_switches := dmp_3c2
  else
    dmp_sw_view_ptr_t(addr(at_backend_switches))^.w := 0;
end;

{ DMP_$NOTE_LABEL - 0x22F1FC, 0x22 bytes. }
procedure dmp_$note_label;
begin
  vfmt_$write('%/L$%wd:%.', lab);
end;

{ DMP_$OPERAND_KIND - an operand kind's name.  0x22F228, 0x42 bytes;
  the width 25 passed by reference from the longword after the control
  string (docs/rev889-patterns.md 116). }
procedure dmp_$operand_kind(
    kind: integer); options(val_param);
begin
  vfmt_$write('%za%$', operand_string[kind], 25);
end;

{ print_jbi_list - a join birthpoint's inputs: each segment's block and
  number.  0x22F274, 0x52 bytes, no A5. }
procedure print_jbi_list(
    j: dmp_jbi_ptr_t); options(val_param, internal);
begin
  vfmt_$write('JBIs%$');
  while j <> nil do begin
    vfmt_$write(' %3ZWD-%2ZLD%$', j^.lts^.bb^.num, integer32(j^.lts^.f2.num));
    j := j^.next;
  end;
end;

{ DMP_$FLOW_GRAPH_EDGE_LIST - the blocks at the other end of a list of
  edges (succs: the targets, chained at next_succ; else the sources,
  next_pred), 16 to a line.  0x22F2DA, 0x6E bytes, no A5 (internal);
  the count a longword (`moveq #15; and.l D3'). }
procedure dmp_$flow_graph_edge_list(
    e: fg_edge_ptr_t;
    succs: boolean); options(val_param, internal);
label
  1;
var
  n: integer32;
  b: bb_ptr_t;
begin
  if e <> nil then begin
    n := 1;
    repeat
      if succs then begin
        b := e^.target;
        e := e^.next_succ;
      end
      else begin
        b := e^.source;
        e := e^.next_pred;
      end;
      vfmt_$write(' BB#%3ZWD%$', b^.num);
      if e = nil then
        goto 1;
      if (n & 15) = 0 then
        vfmt_$write('%/                        %$');
      n := n + 1;
    until false;
  end;
1:
  vfmt_$write('%.');
end;

{ DMP_$COMPLEX_LR_BIT_VECTOR_HEADER - the two lines of column numbers
  over a vector.  0x22F374, 0x2A bytes. }
procedure dmp_$complex_lr_bit_vector_header;
begin
  vfmt_$write('%/    0000000000 1111111111 2222222222 3333333333 4444444444 5555555555 6666666666 7777777777 8888888888 9999999999%$');
  vfmt_$write('%/    0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789 0123456789%/%.');
end;

{ DMP_$COMPLEX_LR_BIT_VECTOR - a vector's bits 0..n, 100 to a line (the
  line's first bit number before it when n > 99), groups of 10, the
  text after the first line.  0x22F48C, 0x12A bytes.  n the routine's
  complex live ranges (rtn +194, a word), from the DBG_LIFE phase
  rounded up to 32 with +198 added (`cmpi.w #17; bcs'); the counts
  words compared unsigned (`bhi', `bls'). }
procedure dmp_$complex_lr_bit_vector;
var
  first, head: boolean;
  i, n, col, cnt: integer;
begin
  if at_backend_phase >= phase$dbg_life then
    n := ((dmp_rtn_ptr_t(rtn)^.ncomplex + 31) & (-32))
         + dmp_rtn_ptr_t(rtn)^.ncomplex2
  else
    n := dmp_rtn_ptr_t(rtn)^.ncomplex;
  if n <= 99 then
    vfmt_$write('    %$');
  first := true;
  i := 0;
  head := true;
  col := i;
  cnt := i;
  while i <= n do begin
    if first and (n > 99) then
      vfmt_$write('%3ZWD %$', i);
    first := false;
    if (i mod 32) in v^[i div 32] then
      vfmt_$write('1%$')
    else
      vfmt_$write('0%$');
    i := i + 1;
    col := col + 1;
    cnt := cnt + 1;
    if cnt = 100 then begin
      if head then begin
        vfmt_$write('  %ZA%$', text, len);
        head := false;
      end;
      vfmt_$write('%.');
      first := true;
      col := 0;
      cnt := col;
    end;
    if col = 10 then begin
      vfmt_$write(' %$');
      col := 0;
    end;
  end;
  if not first then begin
    if head then
      vfmt_$write('  %ZA%$', text, len);
    vfmt_$write('%.');
  end;
end;

{ DMP_$REG_SET - 0x22F5D8, 0xE4 bytes.  Each run of registers as
  "[n" or ", n" (and "..m" when longer than one); "[" alone for none.
  The register numbers words, the runs' ends longwords (`clr.l; move.w';
  `subq.l #1'). }
procedure dmp_$reg_set;
var
  sep: char;
  i, start: integer;
  first, last: integer32;
begin
  sep := '[';
  i := 0;
  while i <= 63 do begin
    while (i <= 63) and not (((i <= 31) and then (i in lo))
                             or else ((i > 31) and then ((i - 32) in hi))) do
      i := i + 1;
    start := i;
    while (i <= 63) and (((i <= 31) and then (i in lo))
                         or else ((i > 31) and then ((i - 32) in hi))) do
      i := i + 1;
    if start <= 63 then begin
      first := start;
      vfmt_$write('%M1A %LD%$', sep, first);
      last := i;
      last := last - 1;
      if first < last then
        vfmt_$write('..%LD%$', last);
      sep := ',';
    end;
  end;
  if sep = '[' then
    vfmt_$write('[%$');
  vfmt_$write(' ]%.');
end;

{ DMP_$BASIC_BLOCK_REGISTER_INFO - the register allocator's counts of a
  block (bytes +0..+7) and the registers written in it (+122, +126).
  0x22F6D8, 0xD8 bytes, no A5. }
procedure dmp_$basic_block_register_info(
    bb: dmp_bb_ptr_t); options(val_param, internal);
begin
  vfmt_$write('%/    live on entry: %3LD IP, %3LD FP;  live on exit: %3LD IP, %3LD FP.%.',
              integer32(bb^.ra.live_in_ip), integer32(bb^.ra.live_in_fp),
              integer32(bb^.ra.live_out_ip), integer32(bb^.ra.live_out_fp));
  vfmt_$write('    max live:      %3LD IP, %3LD FP;  pass thrus:   %3LD IP, %3LD FP.%.',
              integer32(bb^.ra.max_ip), integer32(bb^.ra.max_fp),
              integer32(bb^.ra.pass_ip), integer32(bb^.ra.pass_fp));
  vfmt_$write('    written IP registers: %$');
  dmp_$reg_set([], bb^.written_ip);
  vfmt_$write('    written FP registers: %$');
  dmp_$reg_set(bb^.written_fp.hi, bb^.written_fp.lo);
end;

{ DMP_$BIT_VECTORS_FOR_BASIC_BLOCK - a block's data flow vectors, from
  the DFA phase: from DBG_LIFE avail on entry and live on entry, in RA
  live on entry and exit, else exposed uses, live on entry, killed
  (bb +110) and live on exit, and before TRANS IDEF, SDEF and LABELDEF
  (bb +126, +122, +130); from RA the register counts.  0x22F87C, 0x15A
  bytes, no A5. }
procedure dmp_$bit_vectors_for_basic_block(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
begin
  if at_backend_phase >= phase$dfa then begin
    if lir_main_c78 = nil then
      vfmt_$write('--- bit vectors not allocated ---%.')
    else begin
      dmp_$complex_lr_bit_vector_header(rtn);
      if at_backend_phase >= phase$dbg_life then begin
        dmp_$complex_lr_bit_vector(rtn, 'AVAIL_ON_ENTRY', 14, bb^.avail_in);
        dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_ENTRY', 13, bb^.live_in);
      end
      else if at_backend_phase = phase$ra then begin
        dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_ENTRY', 13, bb^.live_in);
        dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_EXIT', 12, bb^.live_out);
      end
      else begin
        dmp_$complex_lr_bit_vector(rtn, 'EXPOSED_USE', 11, bb^.live_gen);
        dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_ENTRY', 13, bb^.live_in);
        dmp_$complex_lr_bit_vector(rtn, 'KILLED', 6, bb^.transparent);
        dmp_$complex_lr_bit_vector(rtn, 'LIVE_ON_EXIT', 12, bb^.live_out);
        if at_backend_phase < phase$trans then begin
          dmp_$complex_lr_bit_vector(rtn, 'IDEF', 4, bb^.avail_out);
          dmp_$complex_lr_bit_vector(rtn, 'SDEF', 4, bb^.avail_in);
          dmp_$complex_lr_bit_vector(rtn, 'LABELDEF', 8, bb^.avail_gen);
        end;
      end;
      if at_backend_phase >= phase$ra then
        dmp_$basic_block_register_info(dmp_bb_ptr_t(bb));
    end;
  end;
end;

{ DMP_$BASIC_BLOCK_HEADER - a block: its numbers, kind, flags (bb +17,
  +18, +19), dominators, interval, loops, hammocks, edges and vectors.
  0x22FA44, 0x550 bytes, no A5.  Batch A's bb_t bits as the dump names
  them: +17 .7 entry, .6 atomic, .4 asynchronous_return, .3
  pfm_cleanup, .2 asynchronous_path, .1 FORWARDED, .0
  sequential_flow_out; +18 .7 hidden_successor_edges, .6 a loop's
  distinguished entry, .5 to an irreducible loop, .4 multi-level exits,
  .3 an additional entry, .2 conditional, .1 a loop exit, .0 a
  multi-level one; +19 .7 a hammock's entry, .6 a hammock's exit, .5 a
  hammock with loops, .0 executable.  w8 PRE#, order POST#, +16 the loop
  depth, +14 the kind and +15 path_to (block$t), l54 the immediate
  dominator, l58 the post-dominator, l70 the interval, l74 the loop's
  blocks (chained at l78), l82 the hammock, l98 the hammock record, l102
  its blocks (chained at l106), +42 the exception frame. }
procedure dmp_$basic_block_header(
    rtn: rtn_ptr_t;
    bb: bb_ptr_t); options(val_param, internal);
var
  b: bb_ptr_t;
  n: integer32;
  h, p: dmp_ham_ptr_t;
begin
  vfmt_$write('%/%/BLOCK BB#%3ZWD%$', bb^.num);
  if at_backend_phase <> 0 then
    vfmt_$write(',  PRE#%3ZWD,  POST#%3ZWD,  depth= %LD%$', bb^.w8,
                bb^.order, integer32(bb^.f.depth));
  vfmt_$write(',  kind= %A,  path_to= %A%$',
              block_string[block$t(integer(bb^.f14.kind))],
              block_string_length[block$t(integer(bb^.f14.kind))],
              block_string[block$t(integer(bb^.f14.path_to))],
              block_string_length[block$t(integer(bb^.f14.path_to))]);
  if (at_backend_phase >= phase$konst) and not bb^.f.executable then
    vfmt_$write(', ** NOT EXECUTABLE **%$');
  if bb^.f.entry then
    vfmt_$write(', entry%$');
  if bb^.f.hidden_successor_edges then
    vfmt_$write(', hidden_successor_edges%$');
  if bb^.f.asynchronous_return then
    vfmt_$write(', asynchronous_return%$');
  if bb^.f.pfm_cleanup then
    vfmt_$write(', pfm_cleanup%$');
  if bb^.f.asynchronous_path then
    vfmt_$write(', asynchronous_path%$');
  if bb^.f.atomic then
    vfmt_$write(', atomic%$');
  if at_backend_phase < phase$dfa then begin
    vfmt_$write('%.');
  end
  else begin
    if bb^.l54 = nil then
      vfmt_$write('%/    root of dominator tree%.')
    else
      vfmt_$write('%/    immediate dominator: BB#%3ZWD%.', bb^.l54^.num);
    if bb^.l58 = nil then
      vfmt_$write('    root of post-dominator tree%.')
    else
      vfmt_$write('    post-dominator:      BB#%3ZWD%.', bb^.l58^.num);
    if bb^.l70 = nil then
      vfmt_$write('    in interval:         -NONE-%.')
    else
      vfmt_$write('    in interval:         BB#%3ZWD%.', bb^.l70^.num);
    if bb^.f.additional_entry then begin
      vfmt_$write('    additional entry %$');
      if bb^.f.conditional_entry then
        vfmt_$write('(CONDITIONAL) %$');
      if bb^.l70 = nil then
        vfmt_$write('to IRREDUCIBLE loop ****** (outermost?)%.')
      else
        vfmt_$write('to IRREDUCIBLE loop BB#%3ZWD%.', bb^.l70^.num);
    end
    else if bb^.f.distinguished_entry then begin
      vfmt_$write('    distinguished entry %$');
      if bb^.f.conditional_entry then
        vfmt_$write('(CONDITIONAL) %$');
      if bb^.f.irreducible then
        vfmt_$write('to IRREDUCIBLE%$')
      else
        vfmt_$write('to%$');
      vfmt_$write(' loop containing:%/                        %$');
      b := bb_ptr_t(bb^.l74);
      n := 1;
      while b <> nil do begin
        vfmt_$write(' BB#%3ZWD%$', b^.num);
        b := b^.l78;
        if b <> nil then
          if (n & 15) = 0 then
            vfmt_$write('%/                        %$');
        n := n + 1;
      end;
      vfmt_$write('%.');
      if bb^.f.multi_level_exits then
        vfmt_$write('    loop contains multi level exit(s)%.');
    end;
    if bb^.f.loop_exit then begin
      vfmt_$write('    loop exit: BB has successor outside immediately containing loop%$');
      if bb^.l70 <> nil then
        vfmt_$write(' BB#%3ZWD%.', bb^.l70^.num)
      else
        vfmt_$write('.%.');
    end;
    if bb^.f.multi_level_exit then
      vfmt_$write('    loop exit is mult-level%.');
    if at_backend_phase < phase$post then begin
      if bb^.f.hammock_exit then begin
        b := bb^.preds^.source;
        if not b^.f.hammock_entry then
          b := b^.l82;
        vfmt_$write('    hammock exit from hammock headed by BB#%3ZWD%.', b^.num);
      end;
      if bb^.l82 = nil then
        vfmt_$write('    in hammock:          -NONE-%.')
      else
        vfmt_$write('    in hammock:          BB#%3ZWD%.', bb^.l82^.num);
      if bb^.f.hammock_entry then begin
        vfmt_$write('    entry to hammock with exit BB#%3ZWD%/                        %$',
                    dmp_ham_ptr_t(bb^.l98)^.exit^.num);
        b := bb^.l102;
        n := 1;
        while b <> nil do begin
          vfmt_$write(' BB#%3ZWD%$', b^.num);
          b := b^.l106;
          if b <> nil then
            if (n & 15) = 0 then
              vfmt_$write('%/                        %$');
          n := n + 1;
        end;
        vfmt_$write('%.');
        if bb^.f.hammock_with_loops then
          vfmt_$write('    hammock contains loop(s)%.');
        h := dmp_ham_ptr_t(bb^.l98);
        if (h^.parent <> nil) and then (h^.parent^.head = bb) then begin
          vfmt_$write('    grouped hammocks:   %$');
          h := h^.parent^.children;
          repeat
            p := h^.parent;
            vfmt_$write(' BB#%3ZWD%$', h^.head^.num);
            h := h^.next;
          until h = nil;
          vfmt_$write('%.');
        end
        else
          p := h^.parent;
        if p = nil then
          vfmt_$write('    parent hammock:      -ROOT-%.')
        else if dmp_ham_ptr_t(p^.head^.l98) <> p then
          vfmt_$write('    hammock group head:  BB#%3ZWD%.', p^.head^.num)
        else
          vfmt_$write('    parent hammock:      BB#%3ZWD%.', p^.head^.num);
        h := dmp_ham_ptr_t(bb^.l98)^.children;
        if h <> nil then begin
          vfmt_$write('    child hammocks:     %$');
          repeat
            vfmt_$write(' BB#%3ZWD%$', h^.head^.num);
            h := h^.next;
          until h = nil;
          vfmt_$write('%.');
        end;
      end;
    end;
    if bb^.f.sequential_flow_out then
      vfmt_$write('    sequential_flow_out%.');
    if bb^.f.forwarded then
      vfmt_$write('    **** FORWARDED ****%.');
    if dmp_bb_ptr_t(bb)^.exc <> nil then
      vfmt_$write('    exception frame:     %LD%.', dmp_bb_ptr_t(bb)^.exc^.frame);
    vfmt_$write('    predecessors are:   %$');
    dmp_$flow_graph_edge_list(bb^.preds, false);
    vfmt_$write('    successors are:     %$');
    dmp_$flow_graph_edge_list(bb^.succs, true);
    vfmt_$write('%.');
    dmp_$bit_vectors_for_basic_block(rtn, bb);
    vfmt_$write('%.');
  end;
end;

{ DMP_$ALL_BASIC_BLOCK_HEADERS - 0x2304A8, 0x40 bytes. }
procedure dmp_$all_basic_block_headers;
var
  bb: bb_ptr_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    dmp_$basic_block_header(rtn, bb);
    bb := bb^.next;
  end;
end;

{ print_memory_home - a live range's memory home (its +24, an IL node:
  kind 109 its vat at +72, kind 110 at +11 bits 7..4).  0x2304E8, 0xD2
  bytes, no A5.  The names are 9-character constants (10 bytes apart)
  whose address is passed. }
procedure print_memory_home(
    n: dmp_node_ptr_t); options(val_param, internal);
var
  vat: integer;
  name: dmp_name9_t;
begin
  if n <> nil then begin
    if n^.kind = var_name then
      vat := n^.vat
    else if n^.kind = fortran_symbol then
      vat := (ord(n^.b11) & 16#F0) div 16
    else
      bug_check('DMP: PRINT_MEMORY_HOME -- LR has unexpected kind for memory home%$');
    case vat of
      0: name := 'local    ';
      1: name := 'static   ';
      2: name := 'dynm     ';
      3: name := 'extern   ';
      4: name := 'externdef';
      5: name := 'param    ';
      6: name := 'xdynm    ';
      7: name := 'xstatic  ';
      8: name := 'xextrndef';
      9: name := 'based    ';
      10: name := 'sect     ';
      11: name := 'absolute ';
      otherwise
        bug_check('DMP: PRINT_MEMORY_HOME -- LR''s memory home has unexpected vat%$');
    end;
    vfmt_$write(', MEMORY HOME = %M9A_vat%$', name);
  end;
end;

{ print_register_if_assigned - a live range's register (+3 bit 7: one
  is assigned; rrp's ip_reg and fp_reg its file, register 30 and 31
  without them the integer and floating condition codes), its
  NO_MODIFY (+3 bit 6) and SERIALIZE (+3 bit 5), or MEMORY.  0x2306D0,
  0xCC bytes, no A5. }
procedure print_register_if_assigned(
    lr: lr_ptr_t); options(val_param, internal);
begin
  if lr^.f2.physical_register then begin
    if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then begin
      if lr^.f2.physical_register_number = 30 then
        vfmt_$write(', IP CONDITION CODES%$')
      else if lr^.f2.physical_register_number = 31 then
        vfmt_$write(', FP CONDITION CODES%$')
      else
        vfmt_$write(', lr^.register = %ld but no type bits%$', integer32(lr^.f2.physical_register_number));
    end
    else begin
      vfmt_$write(', ASSIGNED TO %$');
      if rrp$ip_reg in lr^.rrp then
        vfmt_$write('R%ld%$', integer32(lr^.f2.physical_register_number))
      else
        vfmt_$write('F%ld%$', integer32(lr^.f2.physical_register_number));
    end;
    if lr^.f2.physical_register_is_no_modify then
      vfmt_$write(', NO_MODIFY%$');
    if lr^.f2.physical_register_user_declared then
      vfmt_$write(', SERIALIZE%$');
  end
  else if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then
    vfmt_$write(', MEMORY%$');
end;

{ print_alias_desc - a load's or store's alias descriptor, which lies
  in the 24 bytes before the instruction (`subi.l #24'): its class,
  base, displacement, size and symbol, and its flags (alias.ins.pas's
  inexact "indexed", uplevel, phase_34 "device", f19_3
  "passed_by_ref", whole "entire_object").  0x230834, 0x112 bytes, no
  A5 (dmp_line by the caller's). }
procedure print_alias_desc(
    instr: instr_ptr_t); options(val_param, internal);
var
  d: dmp_desc_ptr_t;
begin
  d := dmp_desc_ptr_t(integer32(instr) - 24);
  dmp_line.length := 0;
  prtobj(dmp_line, d^.base);
  vfmt_$write('[ %M20A: base= %A, disp= %SLD, size= %SLD%$',
              class_names[d^.class], dmp_line.body,
              integer32(dmp_line.length), d^.disp, d^.size);
  if d^.sym <> nil then begin
    dmp_line.length := 0;
    prtobj(dmp_line, d^.sym);
    vfmt_$write(', sym = %A%$', dmp_line.body, integer32(dmp_line.length));
  end;
  if d^.inexact then
    vfmt_$write(', indexed%$');
  if d^.uplevel then
    vfmt_$write(', uplevel%$');
  if d^.phase_34 then
    vfmt_$write(', device%$');
  if d^.f19_3 then
    vfmt_$write(', passed_by_ref%$');
  if d^.whole then
    vfmt_$write(', entire_object%$');
  vfmt_$write(' ]%.');
end;

{ DMP_$GET_LINE_NUMBER - 0x2309C4, 0x6A bytes.  A marked line counts 0
  in the ISC and FGA phases (`cmpi.w #1; bhi'); runbackend_16 (the last
  line) and the line compared as unsigned words widened (`clr.l;
  move.w'; `blt'). }
function dmp_$get_line_number;
var
  line, last: integer32;
  pos: dmp_ipos_ptr_t;
begin
  pos := dmp_ipos_ptr_t(addr(instr^.l32));
  if instr^.h.b0_1 then
    line := pos^.p^.line
  else if (pos^.marked <> 0) and (at_backend_phase <= phase$fga) then
    line := 0
  else
    line := pos^.line;
  last := runbackend_16;
  last := last & 16#FFFF;
  if last >= line then
    dmp_$get_line_number := dmp_line_map_ptr_t(lst_13c)^[line]
  else
    dmp_$get_line_number := 0;
end;

{ DMP_$INSTRUCTION - 0x230A2E, 0x800 bytes.  The first line: the source
  line, the mnemonic (its width 12 by reference from the constant
  before the strings, docs/rev889-patterns.md 116), the stalls (from
  SCHED), the flags by phase and class, the field width and the
  floating registers written (+41); then the alias descriptor; then one
  line for each operand: its number, kind (a register's with its
  scale), bias, properties (rrp_string, 14 of them: `moveq #13' and
  `dbf'), and what its kind refers to.  The classes that carry an alias
  descriptor are the set 0x09F1CE94 (call, entry, enable, seq, synch,
  limit, trap, load_pair, load, svc, store, mfpr, mtpr, return,
  trap_cond); loads and stores 0x210000.  The displacement kinds
  (routine, arg block, stack frame) share their code
  (docs/rev889-patterns.md 78).  An IL node kind is written to standard
  output with `write' (dpc gap 4). }
procedure dmp_$instruction;
var
  opc: integer;
  h: dmp_ihdr_t;
  attr: instr_attr_view_ptr_t;
  k: integer;
  op: dmp_opnd_ptr_t;
  sep: char;
  j: integer;
  rv: dmp_rrp_view_t;
  lr: lr_ptr_t;
  sym: univ_ptr;
  mode: integer;
  kind: integer;
begin
  opc := instr^.opc;
  vfmt_$write('%/%4ld) %za%$', dmp_$get_line_number(instr),
              instruction_mnemonic[opc], 12);
  h := dmp_ihdr_ptr_t(instr)^;
  if at_backend_phase >= phase$sched then
    vfmt_$write(' stalls=%ld%$', integer32(h.stalls));
  vfmt_$write(' [%$');
  if h.atomic_update then
    vfmt_$write(' atomic_update%$');
  if h.ip_ccs then
    vfmt_$write(' ip_ccs%$');
  if h.fp_ccs then
    vfmt_$write(' fp_ccs%$');
  if h.continued then
    vfmt_$write(' continued%$');
  if h.preference then
    vfmt_$write(' preference%$');
  if h.quad_aligned then
    vfmt_$write(' quad_aligned%$');
  if at_backend_phase < phase$asm then begin
    if h.b2_6 then
      vfmt_$write(' needed%$');
    if h.may_generate_an_exception then
      vfmt_$write(' may_generate_an_exception%$');
    if h.volatile_location then
      vfmt_$write(' volatile_location%$');
    if h.do_not_delete then
      vfmt_$write(' do_not_delete%$');
  end
  else begin
    if h.b2_7 then
      vfmt_$write(' has_fp_companion%$');
    if h.b2_6 then
      vfmt_$write(' pair_with_companion_nop%$');
  end;
  if instruction_assembly[opc].squash then begin
    if h.s_seq then
      vfmt_$write(' s_seq%$');
    if h.s_xfer then
      vfmt_$write(' s_xfer%$');
    if h.no_return then
      vfmt_$write(' no_return%$');
    if h.final_call then
      vfmt_$write(' final_call%$');
    if h.possible_nonlocal_return then
      vfmt_$write(' possible_nonlocal_return%$');
    case h.function_key of
      1: vfmt_$write(' function_key$cos%$');
      2: vfmt_$write(' function_key$sin%$');
      3: vfmt_$write(' function_key$cossin%$');
      otherwise
    end;
  end;
  attr := addr(instruction_attributes[opc]);
  if instruction_attributes[opc].class = class$label then begin
    if h.required_label then
      vfmt_$write(' required_label%$');
    if h.label_is_reachable then
      vfmt_$write(' label_is_reachable%$');
  end;
  if (instruction_attributes[opc].class in
      [2, 4, 7, 9, 10, 11, 14, 15, 16, 20, 21, 22, 23, 24, 27]) and h.b2_7 then
    vfmt_$write(' has_alias_descriptor%$');
  if instruction_attributes[opc].class in [class$load, class$store] then begin
    if h.lsq = 1 then
      vfmt_$write(' lock%$');
    if h.lsq = 2 then
      vfmt_$write(' unlock%$');
    if h.lsq = 3 then
      vfmt_$write(' physical%$');
    if at_backend_phase < phase$sched then
      vfmt_$write(' %ld:%ld%$', integer32(h.disp2), integer32(h.disp3));
  end;
  vfmt_$write(' ]%$');
  if odd(instruction_attributes[opc].b14_7_1) then
    vfmt_$write('  fw=%ld%$', integer32(h.width));
  if instr^.b41 <> chr(0) then
    vfmt_$write('  n_written_fp_reg=%ld%$', integer32(ord(instr^.b41)));
  vfmt_$write('%.');
  if (instruction_attributes[opc].class in
      [2, 4, 7, 9, 10, 11, 14, 15, 16, 20, 21, 22, 23, 24, 27]) and h.b2_7 then begin
    vfmt_$write('      %$');
    print_alias_desc(instr);
  end;
  for k := 1 to h.nopnds do begin
    op := dmp_opnd_ptr_t(addr(instr^.opnds[k]));
    vfmt_$write('%7ld: %$', integer32(op^.num));
    kind := op^.kind;
    if kind <> 1 then
      dmp_$operand_kind(kind)
    else
      vfmt_$write('%a%m2za%za%$', operand_string[kind],
                  operand_string_length[kind], dmp_scale[op^.count],
                  '                        ',
                  25 - integer32(operand_string_length[kind]) - 2);
    vfmt_$write(' %ld  %$', integer32(op^.bias));
    sep := '[';
    rv.w := op^.rrp;
    for j := 0 to 13 do
      if (j <= 15) and (rrp$t(j) in rv.s) then begin
        vfmt_$write('%m1a %a%$', sep, rrp_string[rrp$t(j)],
                    rrp_string_length[rrp$t(j)]);
        sep := ',';
      end;
    if sep = '[' then
      vfmt_$write('[%$');
    vfmt_$write(' ]%$');
    case op^.kind of
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 17: begin
        if op^.last_use then
          vfmt_$write(' last_use%$');
        if at_backend_phase > phase$post then begin
          lr := op^.lr;
          sym := op^.link;
          vfmt_$write('  (LR %3ZWD%$', lr^.num);
        end
        else begin
          lr := op^.lts^.lr;
          sym := lr^.node20;
          vfmt_$write('  (LTS %3ZWD.%2ZLD%$', lr^.num,
                      integer32(op^.lts^.f2.num));
        end;
        if sym <> nil then begin
          vfmt_$write(' = "%$');
          discard(sym_$display_symbol_print_name(sym));
          vfmt_$write('"%$');
        end;
        print_register_if_assigned(lr);
        vfmt_$write(')%$');
      end;
      16:
        vfmt_$write('  (L$%WD)%$', op^.edge^.target^.w8);
      18, 19, 20, 21: begin
        if op^.kind = 21 then
          vfmt_$write('  (literal%$')
        else begin
          vfmt_$write('  (%$');
          if op^.link = nil then
            vfmt_$write('<nil object>%$')
          else if not sym_$display_symbol_print_name(op^.link) then
            write('<object.kind= ', dmp_node_ptr_t(op^.link)^.kind, '>');
        end;
        if op^.value <> 0 then
          vfmt_$write('%PLD%$', op^.value);
        if op^.bytes <> 0 then
          vfmt_$write(', bytes= %LD%$', integer32(op^.bytes));
        vfmt_$write(')%$');
      end;
      23:
        vfmt_$write('  (#%SLD / #x%8ZLH /%WF)%$', op^.value, op^.value,
                    op^.value);
      27:
        print_jbi_list(op^.link);
      28:
        vfmt_$write('  (frame= x%8ZLH, col= %LUD, msg= %LUD, svc= %LUD)%$',
                    op^.link, integer32(op^.col), integer32(op^.msg),
                    integer32(op^.svc));
      otherwise
    end;
    if (instruction_attributes[opc].nresults >= k)
       and ((attr^.opnds[k].b2 & 16#C0) div 64 = 1) then begin
      mode := h.modify;
      if mode = 1 then
        vfmt_$write('  postmodify%$');
      if mode = 2 then
        vfmt_$write('  premodify%$');
    end;
    vfmt_$write('%.');
  end;
end;

{ DMP_$THREE_CHAR_LR_NAME_FROM_LR - a live range's name in four
  characters (returned in D0): its register once assigned (+3 bit 7)
  from the RA phase ("rnn ", "fnn " for rrp's fp_reg, "pc_ " for the
  register target_properties +0x18 names, "sf_ " for the stack frame's
  live range, at_backend_4fc's +116), before RA only the condition
  codes ("icc ", "fcc "); else its number ("nnn ").  0x232010, 0x114
  bytes; vfmt_$encode's capacities (4, 2) words by reference from the
  constants before the control strings. }
function dmp_$three_char_lr_name_from_lr;
label
  1, 2, 9;
type
  sf_view_ptr_t = ^sf_view_t;
  sf_view_t = record
    space0: array [0..115] of char;
    sf_lr: lr_ptr_t;                    { +116 }
  end;
var
  name: packed record
    case integer of
      1: (c: packed array [1..4] of char);
      2: (c1: char;
          rest: packed array [1..3] of char);
      3: (n: dmp_$lr_name_t);
  end;
  len: integer;
  reg: integer32;
begin
  if lr^.f2.physical_register and (at_backend_phase < phase$ra) then begin
    if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] <> [] then
      goto 2;
    if lr^.f2.physical_register_number = 30 then
      name.c[1] := 'i'
    else if lr^.f2.physical_register_number = 31 then
      name.c[1] := 'f'
    else
      goto 1;
    name.c[2] := 'c';
    name.c[3] := 'c';
    name.c[4] := ' ';
    goto 9;
  end;
1:
  vfmt_$encode('%3ZWD %$', name.c, 4, len, lr^.num);
  goto 9;
2:
  reg := lr^.f2.physical_register_number;
  if rrp$fp_reg in lr^.rrp then
    name.c[1] := 'f'
  else if reg = target_properties.p_14[1] then begin
    name.c[1] := 'p';
    name.c[2] := 'c';
    name.c[3] := '_';
    name.c[4] := ' ';
    goto 9;
  end
  else if sf_view_ptr_t(at_backend_4fc)^.sf_lr = lr then begin
    name.c[1] := 's';
    name.c[2] := 'f';
    name.c[3] := '_';
    name.c[4] := ' ';
    goto 9;
  end
  else
    name.c[1] := 'r';
  name.c[2] := ' ';
  name.c[3] := ' ';
  name.c[4] := ' ';
  vfmt_$encode('%2ZLD%$', name.rest, 2, len, reg);
9:
  dmp_$three_char_lr_name_from_lr := name.n;
end;

{ DMP_$INSTR_PRINT_SINGLE_LINE - an instruction on one line: a mark
  ('v' continued, '!' needed or a required label, 'd' deletable before
  ASM), its source line, block and number (in RA its four counts), the
  mnemonic with its suffixes (squash, function key, condition codes,
  modification), each operand (seven to a line) with its properties,
  kind letter and what it refers to, the field width, and after "  ; ="
  the symbol or literal and offset the instruction's results name; the
  operands' bad numbers before RA, the alias descriptor, a call's
  clobbered registers.  0x232130, 0xB8C bytes.  The kinds 18..20 put
  the symbol's name in dmp_line filled with blanks and its offset at
  body[8..10]; the literal kinds' two letters are 7-character constants
  copied (`move.l; move.w; move.b').  A register's segment is named by
  its readers' order: "a".."z", "aa".. ("??" not found).  The symbols'
  kinds that keep "  ; = " (else "  ; ") are the set at 0x232CFA. }
procedure dmp_$instr_print_single_line(
    instr: instr_ptr_t); options(val_param);
type
  lit_name_t = packed array [1..7] of char;
label
  7, 8, 9;
var
  attr: instr_attr_view_ptr_t;
  mark: char;
  extra: integer32;
  sym: dmp_node_ptr_t;
  lit: lit_ptr_t;
  bad: boolean;
  col: integer32;
  k: integer32;
  op: dmp_opnd_ptr_t;
  lts: lts_ptr_t;
  r: opnd_ptr_t;
  hi, lo, c, sep: char;
  off, v: integer32;
  lname: lit_name_t;
  rrp: integer;
  i28: dmp_i28_ptr_t;
  clob: dmp_clob_ptr_t;
begin
  attr := addr(instruction_attributes[instr^.opc]);
  if at_backend_phase < phase$dfa then
    mark := ' '
  else if instr^.h.grouped then
    mark := 'v'
  else if instr^.h.may_generate_an_exception then
    mark := '!'
  else if (instruction_attributes[instr^.opc].class = class$label)
          and dmp_ihdr_ptr_t(instr)^.required_label then
    mark := '!'
  else if instr^.h.b2_6 then
    mark := ' '
  else if at_backend_phase < phase$asm then
    mark := 'd'
  else
    mark := ' ';
  if at_backend_phase <> phase$ra then
    vfmt_$write('%4JLD %3ZWD:%3ZWD%$', dmp_$get_line_number(instr),
                instr^.bb^.num, instr^.num)
  else if (instr^.prev <> nil) and then instr^.prev^.h.grouped then
    vfmt_$write('             %$')
  else begin
    i28 := dmp_i28_ptr_t(addr(instr^.l28));
    vfmt_$write('%3LD%3LD%3LD%3LD %$', integer32(i28^.b30),
                integer32(i28^.b31), integer32(i28^.b28),
                integer32(i28^.b29));
  end;
  vfmt_$write('%M1ZA%ZA%$', mark, instruction_mnemonic[instr^.opc],
              instruction_mnemonic_length[instr^.opc]);
  extra := 0;
  if instruction_assembly[instr^.opc].squash then begin
    if dmp_ihdr_ptr_t(instr)^.s_seq then begin
      if dmp_ihdr_ptr_t(instr)^.s_xfer then
        vfmt_$write('.sa%$')
      else
        vfmt_$write('.ss%$');
    end
    else if dmp_ihdr_ptr_t(instr)^.s_xfer then
      vfmt_$write('.st%$')
    else
      vfmt_$write('.sn%$');
    case dmp_ihdr_ptr_t(instr)^.function_key of
      1: begin
        vfmt_$write(' cos%$');
        extra := 7;
      end;
      2: begin
        vfmt_$write(' sin%$');
        extra := 7;
      end;
      3: begin
        vfmt_$write(' cssn%$');
        extra := 8;
      end;
      otherwise
        extra := 3;
    end;
  end
  else if instruction_attributes[instr^.opc].b14_0 then begin
    if instr^.h.sets_cc or instr^.h.fp_ccs then
      case dmp_ihdr_ptr_t(instr)^.lsq of
        0: begin
          vfmt_$write('.cc%$');
          extra := 3;
        end;
        1: begin
          vfmt_$write('.ucc%$');
          extra := 4;
        end;
        2: begin
          vfmt_$write('.scc%$');
          extra := 4;
        end;
        3: begin
          vfmt_$write('.zcc%$');
          extra := 4;
        end;
      end;
  end;
  if (instruction_attributes[instr^.opc].class in [class$load, class$store])
     and (dmp_ihdr_ptr_t(instr)^.modify <> 0) then begin
    if dmp_ihdr_ptr_t(instr)^.modify = 2 then
      vfmt_$write(' ++[]%$')
    else
      vfmt_$write(' []++%$');
    extra := extra + 5;
  end;
  vfmt_$write('%ZA%$', '           ',
              12 - extra - instruction_mnemonic_length[instr^.opc]);
  sym := nil;
  lit := nil;
  bad := false;
  col := 0;
  for k := 1 to instr^.h.nopnds do begin
    if col = 7 then begin
      vfmt_$write('%/                         %$');
      if at_backend_phase = phase$ra then
        vfmt_$write(' %$');
      col := 0;
    end;
    col := col + 1;
    vfmt_$write('  %$');
    op := dmp_opnd_ptr_t(addr(instr^.opnds[k]));
    if op^.kind = 0 then begin
      vfmt_$write('-------------%$');
      goto 8;
    end;
    if op^.num <> k then
      bad := true;
    rrp := op^.rrp;
    if (rrp & 16#20) <> 0 then
      vfmt_$write('i%$')
    else if (rrp & 16#10) <> 0 then
      vfmt_$write('r%$');
    if (rrp & 4) <> 0 then
      vfmt_$write('m%$');
    if (rrp & 16#40) <> 0 then
      vfmt_$write('u%$')
    else if (rrp & 8) <> 0 then
      vfmt_$write('w%$');
    if (rrp & 28) = 0 then
      vfmt_$write('-%$');
    if (rrp & 1) <> 0 then
      c := 'e'
    else if (rrp & 2) <> 0 then
      c := 'o'
    else if op^.count <> 0 then
      c := chr(op^.count + ord('0'))
    else
      c := ' ';
    vfmt_$write('%m1a%m1za%$', operand_letter[operand$t(op^.kind)], c);
    case op^.kind of
      1, 2, 3, 7, 8, 9, 10, 11:
        if at_backend_phase >= phase$post then
          vfmt_$write('reg  = %M4A%$',
                      dmp_$three_char_lr_name_from_lr(op^.lts^.lr))
        else begin
          lts := op^.lts;
          hi := ' ';
          r := lts^.refs;
          lo := 'a';
          while r <> opnd_ptr_t(op) do begin
            if r = nil then begin
              hi := '?';
              lo := hi;
              goto 7;
            end;
            lo := succ(lo);
            if lo = '{' then begin
              lo := 'a';
              if hi = ' ' then
                hi := lo
              else
                hi := succ(hi);
            end;
            r := r^.link;
          end;
        7:
          vfmt_$write('(%M4A.%2ZLD%M1ZA%M1ZA)%$',
                      dmp_$three_char_lr_name_from_lr(op^.lts^.lr),
                      integer32(lts^.f2.num), hi, lo);
        end;
      12, 17:
        vfmt_$write('reg  = %M4A%$',
                    dmp_$three_char_lr_name_from_lr(op^.lts^.lr));
      13:
        vfmt_$write('reg  = %M4A%$',
                    dmp_$three_char_lr_name_from_lr(op^.lts^.lr));
      14:
        vfmt_$write('pair = %M4A%$',
                    dmp_$three_char_lr_name_from_lr(op^.lts^.lr));
      15:
        vfmt_$write('?UNRESOLVED%$');
      16:
        vfmt_$write('BB#%3ZWD    %$', op^.edge^.target^.num);
      18, 19, 20: begin
        dmp_line.length := 0;
        for v := 1 to 256 do
          dmp_line.body[v] := ' ';
        if not sym_$append_symbol_print_name(addr(dmp_line), op^.link) then begin
          dmp_line.body[1] := '?';
          dmp_line.body[2] := '?';
          dmp_line.body[3] := '?';
          dmp_line.body[4] := '?';
          dmp_line.body[5] := '?';
          dmp_line.body[6] := '?';
          dmp_line.body[7] := '?';
          dmp_line.body[8] := '?';
          dmp_line.body[9] := '?';
          dmp_line.body[10] := '?';
        end;
        v := op^.value;
        if v <> 0 then begin
          if v > 0 then
            dmp_line.body[8] := '+'
          else begin
            v := -v;
            dmp_line.body[8] := '-';
          end;
          if v > 99 then begin
            dmp_line.body[9] := '!';
            dmp_line.body[10] := '!';
          end
          else begin
            dmp_line.body[9] := chr(v div 10 + 48);
            dmp_line.body[10] := chr(v mod 10 + 48);
          end;
        end;
        vfmt_$write('%M10ZA%$', dmp_line.body);
        if instruction_attributes[instr^.opc].nresults >= k then begin
          sym := op^.link;
          off := op^.value;
        end;
      end;
      21: begin
        lname[1] := '%';
        case lit_ptr_t(op^.link)^.kind of
          0: lname := 'i      ';
          1: lname := 'si     ';
          2: lname := 'bi     ';
          3: lname := 'li     ';
          4: lname := 'u      ';
          5: lname := 'su     ';
          6: lname := 'bu     ';
          7: lname := 'lu     ';
          8: lname := 'sl     ';
          9: lname := 'bl     ';
          10: lname := 'll     ';
          11: lname := 'ch     ';
          12: lname := 'sf     ';
          13: lname := 'df     ';
          14: lname := 'sc     ';
          15: lname := 'dc     ';
          19: lname := 'st     ';
          20: lname := 'se     ';
          otherwise
        end;
        if lname[1] = '%' then
          vfmt_$write('%6ZLH+%3ZLH%$', integer32(op^.link) & 16#FFFFFF,
                      op^.value & 16#FFF)
        else
          vfmt_$write('%M2ZA %4ZLH+%2ZLH%$', lname,
                      integer32(op^.link) & 16#FFFF,
                      op^.value & 16#FF);
        if instruction_attributes[instr^.opc].nresults >= k then begin
          if at_backend_phase >= phase$asm then
            lit := lpe_ptr_t(op^.link)^.lit
          else
            lit := op^.link;
          off := op^.value;
        end;
      end;
      23: begin
        if (op^.value <> 0) and (op^.w10 = 0) then
          vfmt_$write('#x%8ZLH%$', op^.value)
        else
          vfmt_$write('#%9JSLD%$', op^.value);
        if instruction_attributes[instr^.opc].nresults >= k then
          sym := op^.link;
      end;
      25: begin
        dmp_line.length := 0;
        for v := 1 to 256 do
          dmp_line.body[v] := ' ';
        if sym_$append_symbol_print_name(addr(dmp_line), op^.link) then
          vfmt_$write('%M10ZA%$', dmp_line.body)
        else
          vfmt_$write('?????     %$');
      end;
      27:
        print_jbi_list(op^.link);
      28:
        vfmt_$write('f:%8ZLH%$', op^.link);
      otherwise
        vfmt_$write('?????     %$');
    end;
  8:
  end;
  if odd(instruction_attributes[instr^.opc].b14_7_1) then
    vfmt_$write('  fw=%ld%$', integer32(instr^.h.width));
  dmp_line.length := 6;
  dmp_line.body[1] := ' ';
  dmp_line.body[2] := ' ';
  dmp_line.body[3] := ';';
  dmp_line.body[4] := ' ';
  dmp_line.body[5] := '=';
  dmp_line.body[6] := ' ';
  if sym <> nil then begin
    if (sym^.kind = var_name) and (sym^.l4 = nil) then
      goto 9;
    if not (sym^.kind in [blogical_ob..complex_ob, char_string_ob,
                          char32_string_ob, char16_ob, set_con_ob,
                          rec_const_ob, dpcomplex_ob, binteger_ob]) then
      dmp_line.length := 4;
    if not sym_$append_symbol_print_name(addr(dmp_line), sym) then
      prtobj(dmp_line, sym);
  end
  else if lit <> nil then
    lst_$prtlit(dmp_line, lit)
  else
    goto 9;
  if off > 0 then begin
    prtcatc(dmp_line, '+');
    prtint(dmp_line, off, 5, false);
  end
  else if off < 0 then begin
    prtcatc(dmp_line, '-');
    prtint(dmp_line, -off, 5, false);
  end;
  vfmt_$write('%a%$', dmp_line.body, integer32(dmp_line.length));
9:
  vfmt_$write('%.');
  if bad and (at_backend_phase < phase$ra) then begin
    vfmt_$write('%/*** Bad operand numbers%$');
    sep := ':';
    for k := 1 to instr^.h.nopnds do begin
      op := dmp_opnd_ptr_t(addr(instr^.opnds[k]));
      if (op^.kind <> 0) and (op^.num <> k) then begin
        v := op^.num;
        vfmt_$write('%M1A %LD = %WD%$', sep, k, v);
        sep := ',';
      end;
    end;
    vfmt_$write(' ***%/%.');
  end;
  if (instruction_attributes[instr^.opc].class in [class$load, class$store])
     and instr^.h.b2_7 then begin
    vfmt_$write('             %$');
    if at_backend_phase < phase$dfa then
      vfmt_$write('    %$');
    print_alias_desc(instr);
  end;
  if instruction_attributes[instr^.opc].class in [class$call, class$svc] then begin
    clob := dmp_clob_ptr_t(addr(instr^.opnds[instr^.h.nopnds + 1]));
    vfmt_$write('%24Tclobbered ip regs = %$');
    dmp_$reg_set([], clob^.ip);
    vfmt_$write('%24Tclobbered fp regs = %$');
    dmp_$reg_set(clob^.fp.hi, clob^.fp.lo);
  end;
end;

{ PRINT_PROPERTIES - a segment's or live range's properties (rrp, by
  rrp_letter: a blank for one not set), x as 'X', then 'A' for a, else
  the letter given for b.  0x232F74, 0xC8 bytes; everything by
  reference (the constant false at 0x2340E6 for whole_routine's a). }
procedure print_properties(
    in rrp: rrp$set_t;
    in x: boolean;
    in b: boolean;
    in letter: univ dmp_$text_t;
    in a: boolean);
var
  p: rrp$t;
begin
  vfmt_$write(' [%$');
  for p := rrp$fp_reg_even_only to rrp$ip_reg do
    if rrp_letter[p] <> chr(0) then
      if p in rrp then
        vfmt_$write('%m1a%$', rrp_letter[p])
      else
        vfmt_$write(' %$');
  vfmt_$write(' | %$');
  if x then
    vfmt_$write('X%$')
  else
    vfmt_$write(' %$');
  if a then
    vfmt_$write('A%$')
  else if b then
    vfmt_$write(letter)
  else
    vfmt_$write(' %$');
  vfmt_$write(']%$');
end;

{ print_lts_list - a live range's segments, last first (it recurs on
  the next before printing): properties, block, number; before XTP from
  the DFA phase where an exposed one is defined (the final segment that
  reaches it, l44: "DEF" or a join's "JBP", ** UNDEF ** when none) or a
  defining one's KONST value (lts +40, before XTP: TOP, BOTTOM, ?TOP?
  when none after KONST); before POST its references (block,
  instruction, operand, the use's letter: '*' an instruction not
  needed), the KONST value's range and symbol, and before SCHED the
  exposed segments a definition reaches (l28) and the joins it is an
  input to (l44).  0x233054, 0x444 bytes, no A5.  The tags are
  longword constants ('JBP ', 'DEF ', 'JOIN', blanks); the TOP and
  BOTTOM paths clear the value (a shared tail with the nil paths,
  docs/rev889-patterns.md 23). }
procedure print_lts_list(
    lr: lr_ptr_t;
    lts: lts_ptr_t); options(val_param, internal);
label
  5;
var
  ph: integer;
  op: opnd_ptr_t;
  instr, i2: instr_ptr_t;
  e: lts_ptr_t;
  tag: packed array [1..4] of char;
  k: dmp_konst_ptr_t;
  c: char;
  rrp: integer;
  j: dmp_join_ptr_t;
begin
  if lts <> nil then begin
    print_lts_list(lr, lts^.next);
    vfmt_$write('   %$');
    print_properties(lts^.rrp, lts^.f2.exposed, lts^.f2.first_in_bb, 'F%$',
                     lts^.f2.final);
    vfmt_$write(' in BB#%3ZWD LTS %M4A.%2ZLD%$', lts^.bb^.num,
                dmp_$three_char_lr_name_from_lr(lr), integer32(lts^.f2.num));
    k := nil;
    ph := at_backend_phase;
    op := lts^.refs;
    if (ph >= phase$dfa) and (ph < phase$sched) and (op <> nil) then begin
      instr := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
      if lts^.f2.exposed then begin
        e := lts_ptr_t(lts^.l44);
        if e = nil then begin
          if instr^.opc = ord(opc$join_bp) then
            vfmt_$write('             %$')
          else
            vfmt_$write(' ** UNDEF ** %$');
        end
        else begin
          i2 := instr_ptr_t(integer32(e^.refs) - 32 - 12 * e^.refs^.h.num);
          if i2^.opc = ord(opc$join_bp) then
            tag := 'JBP '
          else
            tag := 'DEF ';
          vfmt_$write(' (%M3A %3ZWD-%2ZLD)%$', tag, e^.bb^.num,
                      integer32(e^.f2.num));
        end;
      end
      else begin
        if instr^.opc = ord(opc$join_bp) then
          tag := 'JOIN'
        else
          tag := '    ';
        if ph < phase$xtp then begin
          k := dmp_konst_ptr_t(lts^.l40);
          if k = nil then begin
            if ph > phase$konst then
              vfmt_$write(' %M4ZA  ?TOP? %$', tag)
            else
              vfmt_$write(' %M4ZA        %$', tag);
          end
          else if ord(k^.kind) = 5 then begin
            vfmt_$write(' %M4ZA  TOP   %$', tag);
            k := nil;
          end
          else if ord(k^.kind) = 0 then begin
            vfmt_$write(' %M4ZA  BOTTOM%$', tag);
            k := nil;
          end
          else
            vfmt_$write(' %M4ZA        %$', tag);
        end;
      end;
    end;
    vfmt_$write(' =%$');
    if at_backend_phase < phase$post then begin
      op := lts^.refs;
      while op <> nil do begin
        instr := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
        rrp := opnd_bytes_ptr_t(op)^.rrp;
        if not instr^.h.b2_6 and (at_backend_phase >= phase$dfa) then
          c := '*'
        else if (rrp & 16#10) <> 0 then begin
          if (rrp & 16#20) <> 0 then
            c := 'i'
          else
            c := 'r';
        end
        else if (rrp & 4) <> 0 then
          c := 'm'
        else if (rrp & 8) <> 0 then
          c := 'w'
        else
          c := ' ';
        vfmt_$write('  %3ZWD:%3ZWD#%3ZLD%M1A%$', lts^.bb^.num, instr^.num,
                    integer32(op^.h.num), c);
        if op^.h.b2_7 then
          vfmt_$write(' L%$');
        op := op^.link;
      end;
      if k <> nil then begin
        case ord(k^.kind) of
          1: vfmt_$write('%/    SYMBOLIC:%$');
          2: vfmt_$write('%/    B_K/B_T: %$');
          3: vfmt_$write('%/    CS RANGE:%$');
          4: vfmt_$write('%/    CONSTANT:%$');
          otherwise
            goto 5;
        end;
        vfmt_$write('  [%8ZLH/%8ZLH]   %8ZLH..%8ZLH%$', k^.l8, k^.l12, k^.l16,
                    k^.l20);
        if k^.sym <> nil then begin
          vfmt_$write('   = %$');
          if not sym_$display_symbol_print_name(k^.sym) then begin
            prtobj(dmp_line, k^.sym);
            vfmt_$write('%a%$', dmp_line.body, integer32(dmp_line.length));
          end;
        end;
      end;
    5:
      if (lts^.rrp * [rrp$modify, rrp$write] <> [])
         and (at_backend_phase < phase$sched) then begin
        e := lts^.l28;
        if e <> nil then begin
          vfmt_$write('%/    DEFINITION FOR:  %$');
          repeat
            vfmt_$write('  %3ZWD-%2ZLD%$', e^.bb^.num, integer32(e^.f2.num));
            e := e^.l28;
          until e = nil;
        end;
        j := dmp_join_ptr_t(lts^.l44);
        if j <> nil then begin
          vfmt_$write('%/    JOIN INPUT TO:   %$');
          repeat
            vfmt_$write('  %3ZWD:%3ZWD%$', j^.instr^.bb^.num, j^.instr^.num);
            j := j^.next;
          until j = nil;
        end;
      end;
    end;
    vfmt_$write('%.');
  end;
end;

{ DMP_$PRINT_EXPOSED_LTS_LIST - a block's (or live range's) exposed
  segments, chained at next_exposed.  0x23360C, 0x58 bytes. }
procedure dmp_$print_exposed_lts_list(
    lts: lts_ptr_t); options(val_param);
begin
  while lts <> nil do begin
    vfmt_$write(' %M4A.%2ZLD%$', dmp_$three_char_lr_name_from_lr(lts^.lr),
                integer32(lts^.f2.num));
    lts := lts^.next_exposed;
  end;
end;

{ DMP_$PRINT_FINAL_LTS_LIST - the final segments, chained at
  next_final.  0x233672, 0x58 bytes. }
procedure dmp_$print_final_lts_list(
    lts: lts_ptr_t); options(val_param);
begin
  while lts <> nil do begin
    vfmt_$write(' %M4A.%2ZLD%$', dmp_$three_char_lr_name_from_lr(lts^.lr),
                integer32(lts^.f2.num));
    lts := lts^.next_final;
  end;
end;

{ display_ra_info - a live range during RA: its remaining conflicts
  (w56), never spill (rrp's life_mark element), spill victim (+3 bit
  0), the live ranges it conflicts with (+44: each conflict on both
  live ranges' lists, the next pointers tagged in their low two bits,
  17 names to a line) and the conflicting register set (+80).  0x2336CA,
  0x1BE bytes, no A5.  After the set the code jumps to its end from
  `suba.l A3,A3' (`bra.w' to the epilogue): the loop over the
  conflicts' displacements (9 to a line) and the preferenced set (+64)
  are never reached (written as a test of the pointer just cleared). }
procedure display_ra_info(
    lr: lr_ptr_t); options(val_param, internal);
var
  c: dmp_conf_ptr_t;
  n, disp, b: integer32;
begin
  vfmt_$write('    REMAINING CONFLICTS: %4ld%$', integer32(lr^.w56) & 16#FFFF);
  if rrp$life_mark in lr^.rrp then
    vfmt_$write(',   never spill%.')
  else if lr^.f2.b3_0 then
    vfmt_$write(',   spill victim%.')
  else
    vfmt_$write('%.');
  c := dmp_conf_ptr_t(dmp_lr_ptr_t(lr)^.l44);
  if c <> nil then begin
    vfmt_$write('    CONFLICTING LRs: %$');
    n := 0;
    repeat
      if n = 17 then begin
        vfmt_$write('%/                     %$');
        n := 0;
      end;
      n := n + 1;
      if c^.a = lr then begin
        vfmt_$write('%M4A %$', dmp_$three_char_lr_name_from_lr(c^.b));
        c := dmp_conf_ptr_t(c^.next_a & (-4));
      end
      else begin
        vfmt_$write('%M4A %$', dmp_$three_char_lr_name_from_lr(c^.a));
        c := dmp_conf_ptr_t(c^.next_b & (-4));
      end;
    until c = nil;
    vfmt_$write('%.');
  end;
  vfmt_$write('    CONFLICTING SET: %$');
  dmp_$reg_set(dmp_lr_ptr_t(lr)^.conflicting.hi, dmp_lr_ptr_t(lr)^.conflicting.lo);
  c := nil;
  if c <> nil then begin
    repeat
      if n = 9 then begin
        vfmt_$write('%/                     %$');
        n := 0;
      end;
      disp := c^.l24;
      n := n + 1;
      disp := disp - c^.l20;
      b := ord(c^.b28);
      if c^.a = lr then begin
        vfmt_$write('%M4A%$', dmp_$three_char_lr_name_from_lr(c^.b));
        c := dmp_conf_ptr_t(c^.next_a);
      end
      else begin
        vfmt_$write('%M4A%$', dmp_$three_char_lr_name_from_lr(c^.a));
        c := dmp_conf_ptr_t(c^.next_b);
      end;
      vfmt_$write('%PLD@%ULD %$', disp, b);
    until c = nil;
    vfmt_$write('%/    PREFERENCED SET: %$');
    dmp_$reg_set(dmp_lr_ptr_t(lr)^.preferenced.hi,
                 dmp_lr_ptr_t(lr)^.preferenced.lo);
  end;
end;

{ DMP_$WHOLE_ROUTINE - 0x23394A, 0x718 bytes.  The routine's frame, its
  flags (batch A's f226, f227, f228 bits as the dump names them: +226
  .7 save sl, .6 save rpc, .5 db never referenced, .4 internal db, .3
  quad aligned, .2 contains call, .1 needs_db, .0 needs frame; +227 .7
  no return block, .6 asynchronous return, .5 shares frame with lexical
  parent, .4 no_memory_read, .3 no_memory_write, .2 no_arg_block_read,
  .1 no_arg_block_write, .0 common_block_untouched; +228 .7
  static_storage_untouched, .6 no_pointer_dereference, .5
  uplevel_dynamic_storage_untouched, .4 no_fp_cc_write, .3
  no_ip_cc_write), the frame's offsets, the conventions' register sets
  (the routine's IL node +332..+364), the written and saved registers,
  each block with its segments and instructions, and unless the switch
  sw7 the live ranges (unless sw6 their segments, from DBG_LIFE (with
  -DBS or -DBA) their PC ranges; in RA display_ra_info).  The phase is
  stepped back one while it runs (unless this_phase) and restored
  (`move.w D3,0x485D32'). }
procedure dmp_$whole_routine;
var
  saved_phase: integer;
  r: dmp_rtn_ptr_t;
  node: dmp_rnode_ptr_t;
  bb: bb_ptr_t;
  instr: instr_ptr_t;
  lr: lr_ptr_t;
  pcr: dmp_pcr_ptr_t;
  n: integer;
  set64: dmp_set64_t;
begin
  r := dmp_rtn_ptr_t(rtn);
  saved_phase := at_backend_phase;
  if (saved_phase <> 0) and not this_phase then
    at_backend_phase := at_backend_phase - 1;
  vfmt_$write('CONTENTS OF ROUTINE:%.');
  vfmt_$write('    frame size: %LD, SF = R%WD%$', r^.frame_size, r^.sf_reg);
  if rtn^.f226.contains_call then
    vfmt_$write(', contains call%$');
  if rtn^.f226.needs_frame then
    vfmt_$write(', needs frame%$');
  if rtn^.f226.save_rpc then
    vfmt_$write(', save rpc%$');
  if rtn^.f226.save_sl then
    vfmt_$write(', save sl%$');
  if rtn^.f226.quad_aligned then
    vfmt_$write(', quad aligned%$');
  if rtn^.f226.db_never_referenced then
    vfmt_$write(', db never referenced%$');
  if rtn^.f226.internal_db then
    vfmt_$write(', internal db%$');
  if rtn^.f226.no_return_block then
    vfmt_$write(', no return block%$');
  if rtn^.f226.asynchronous_return then
    vfmt_$write(', asynchronous return%$');
  vfmt_$write('%/   %$');
  if rtn^.f226.needs_db then
    vfmt_$write(' needs_db%$');
  if rtn^.f226.no_memory_read then
    vfmt_$write(' no_memory_read%$');
  if rtn^.f226.no_memory_write then
    vfmt_$write(' no_memory_write%$');
  if rtn^.f226.no_arg_block_read then
    vfmt_$write(' no_arg_block_read%$');
  if rtn^.f226.no_arg_block_write then
    vfmt_$write(' no_arg_block_write%$');
  if rtn^.f228.no_pointer_dereference then
    vfmt_$write(' no_pointer_dereference%$');
  if rtn^.f226.common_block_untouched then
    vfmt_$write(' common_block_untouched%$');
  if rtn^.f228.static_storage_untouched then
    vfmt_$write(' static_storage_untouched%$');
  if rtn^.f228.uplevel_dynamic_storage_untouched then
    vfmt_$write(' uplevel_dynamic_storage_untouched%$');
  if rtn^.f228.no_fp_cc_write then
    vfmt_$write(' no_fp_cc_write%$');
  if rtn^.f228.no_ip_cc_write then
    vfmt_$write(' no_ip_cc_write%$');
  if rtn^.f226.needs_frame then begin
    if (r^.save_reg_4 <> 31) and (r^.save_reg_4 <> -1) then
      vfmt_$write(',%/    save R%WD at [04,SF]%$', r^.save_reg_4);
    if (r^.save_reg_12 <> 31) and (r^.save_reg_12 <> -1) then
      vfmt_$write(',%/    save R%WD at [12,SF]%$', r^.save_reg_12);
  end
  else if rtn^.f226.shares_frame then
    vfmt_$write('%/    shares frame with lexical parent%$');
  vfmt_$write('%/    supplied arg block end offset = %LD%$', r^.arg_end);
  if r^.saved_from <> 0 then
    vfmt_$write('%/    regs saved from [%WD,SF] to [%WD,SF]%$', r^.saved_from,
                r^.saved_to);
  if at_backend_phase >= phase$asm then begin
    vfmt_$write('%/    prolog offsets:  from ECB = %WD,  different DB = %WD%$',
                r^.from_ecb, r^.different_db);
    vfmt_$write('%/    prolog offsets:  stack pushed = %WD,  all regs saved = %WD%$',
                r^.stack_pushed, r^.all_regs_saved);
  end;
  node := r^.node;
  vfmt_$write('%/    preserve IP registers:    %$');
  dmp_$reg_set([], node^.ip_preserve);
  vfmt_$write('    preserve FP registers:    %$');
  set64 := node^.fp_preserve;
  dmp_$reg_set(set64.hi, set64.lo);
  vfmt_$write('    no_preserve IP registers: %$');
  dmp_$reg_set([], node^.ip_no_preserve);
  vfmt_$write('    no_preserve FP registers: %$');
  set64 := node^.fp_no_preserve;
  dmp_$reg_set(set64.hi, set64.lo);
  vfmt_$write('    no_modify IP registers:   %$');
  dmp_$reg_set([], node^.ip_no_modify);
  vfmt_$write('    no_modify FP registers:   %$');
  set64 := node^.fp_no_modify;
  dmp_$reg_set(set64.hi, set64.lo);
  if at_backend_phase >= phase$dfa then begin
    vfmt_$write('    written IP registers:     %$');
    dmp_$reg_set([], r^.written_ip);
    vfmt_$write('    written FP registers:     %$');
    dmp_$reg_set(r^.written_fp.hi, r^.written_fp.lo);
    if at_backend_phase >= phase$ra then begin
      vfmt_$write('    saved IP registers:       %$');
      dmp_$reg_set([], r^.saved_ip);
      vfmt_$write('    saved FP registers:       %$');
      dmp_$reg_set(r^.saved_fp.hi, r^.saved_fp.lo);
    end;
  end;
  bb := rtn^.bbs;
  while bb <> nil do begin
    dmp_$basic_block_header(rtn, bb);
    if bb^.exposed <> nil then begin
      vfmt_$write('    EXPOSED SEGMENTS: %$');
      dmp_$print_exposed_lts_list(bb^.exposed);
      vfmt_$write('%/%.');
    end;
    instr := bb^.first;
    while instr <> nil do begin
      if verbose then
        dmp_$instruction(instr)
      else
        dmp_$instr_print_single_line(instr);
      instr := instr^.next;
    end;
    if bb^.finals <> nil then begin
      vfmt_$write('%/    FINAL SEGMENTS:   %$');
      dmp_$print_final_lts_list(bb^.finals);
      vfmt_$write('%.');
    end;
    bb := bb^.next;
  end;
  if not at_backend_switches.sw7 then begin
    vfmt_$write('%/%/LIVE RANGES:%/%.');
    lr := rtn^.lrs;
    while lr <> nil do begin
      vfmt_$write('%M4A%$', dmp_$three_char_lr_name_from_lr(lr));
      print_properties(lr^.rrp, lr^.f2.b3_4, lr^.f2.b3_1, 'U%$', false);
      if lr^.f2.physical_register then begin
        vfmt_$write(', LR#%3ZWD = %2ZLD%$', lr^.num, integer32(lr^.f2.physical_register_number));
        if lr^.f2.physical_register then begin
          if lr^.f2.physical_register_is_no_modify then
            vfmt_$write(', NO_MODIFY%$');
          if lr^.f2.physical_register_user_declared then
            vfmt_$write(', SERIALIZE%$');
        end;
      end
      else if lr^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then
        vfmt_$write(', MEMORY%$');
      if lr^.id <> 0 then
        vfmt_$write(', CX# %LD%$', integer32(lr^.id));
      if lr^.mate <> nil then
        vfmt_$write(', MATE %M4A%$', dmp_$three_char_lr_name_from_lr(lr^.mate));
      if lr^.node20 <> nil then begin
        vfmt_$write('  "%$');
        discard(sym_$display_symbol_print_name(lr^.node20));
        vfmt_$write('"%$');
      end;
      print_memory_home(lr^.memory_home);
      vfmt_$write('%.');
      if not at_backend_switches.sw6 then begin
        if at_backend_phase = phase$dbg_life then begin
          if cargs_$options.db >= 2 then begin
            vfmt_$write('    PC RANGES OF LIFETIME: %$');
            pcr := dmp_pcr_ptr_t(dmp_lr_ptr_t(lr)^.l44);
            if pcr = nil then
              vfmt_$write('none.%.')
            else begin
              n := 0;
              while pcr <> nil do begin
                n := n + 1;
                if n <> 1 then begin
                  vfmt_$write('%.');
                  vfmt_$write('                           %$');
                end;
                vfmt_$write('loaded: %8zlh, killed: %8zlh%$', pcr^.loaded,
                            pcr^.killed);
                pcr := pcr^.next;
              end;
              if n <> dmp_lr_ptr_t(lr)^.nranges then
                vfmt_$write('   !!!ERROR!!! PC_LIVE_RANGE_ENTRIES DOES NOT MATCH ACTUAL NUMBER OF RECORDS.%.');
              vfmt_$write('%.');
            end;
          end;
        end
        else begin
          if at_backend_phase < phase$ra then
            print_lts_list(lr, lr^.ltss);
          if at_backend_phase < phase$ra then begin
            if lr^.exposed <> nil then begin
              vfmt_$write('    EXPOSED SEGMENTS: %$');
              dmp_$print_exposed_lts_list(lr^.exposed);
              vfmt_$write('%.');
            end;
            if lr^.finals <> nil then begin
              vfmt_$write('    FINAL SEGMENTS:   %$');
              dmp_$print_final_lts_list(lr^.finals);
              vfmt_$write('%.');
            end;
          end;
        end;
      end;
      if at_backend_phase = phase$ra then
        display_ra_info(lr);
      vfmt_$write('%.');
      lr := lr^.next;
    end;
    vfmt_$write('%.');
  end;
  at_backend_phase := saved_phase;
end;

{ DMP_$INTERFERENCE_GRAPH_ANALYSIS - 0x2345FA, 0xC8 bytes. }
procedure dmp_$interference_graph_analysis;
begin
  vfmt_$write(title1);
  vfmt_$write(title2);
  vfmt_$write('  CHROMATIC NUMBER = %LD%/  ALLOCATION ORDER AND CONFLICTS:%$',
              chromatic);
  while lrs <> nil do begin
    vfmt_$write('%/    LR %3ZWD,   COMPLEX_ID %3ZLD,%$', lrs^.num,
                integer32(lrs^.id));
    if full then
      display_ra_info(lrs)
    else begin
      vfmt_$write('   remaining conflicts =%4LD%$',
                  integer32(lrs^.w56) & 16#FFFF);
      if lrs^.node20 <> nil then begin
        vfmt_$write('   %$');
        discard(sym_$display_symbol_print_name(lrs^.node20));
      end;
    end;
    lrs := lrs^.l52;
  end;
  vfmt_$write('%/%/%.');
end;

{ DMP_$MEMORY_USAGE - each MRH heap's bytes, chunks, peak and name (up
  to its '%'), the chunks in use and allocated (the heaps' chunks
  summed, when they differ), and with debug switch M's bit 9 the chunk
  map, 16 to a line (the owner; negated when freed, "--" free).
  0x23474A, 0x188 bytes. }
procedure dmp_$memory_usage;
var
  i, total, accounted, in_use, bytes, len, owner: integer32;
  map: dmp_map_ptr_t;
begin
  accounted := 0;
  for i := 1 to heap_count do begin
    bytes := mrh_$bytes_used(heaps[i]^);
    accounted := accounted + heaps[i]^.chunks_in_use;
    len := 1;
    while heap_names[i]^[len] <> '%' do
      len := len + 1;
    len := len - 1;
    vfmt_$write('%11LD bytes   %5WD chunks   %5WD peak    %2ZWD: %A%.', bytes,
                heaps[i]^.chunks_in_use, heaps[i]^.chunks_max,
                heaps[i]^.heap_index, heap_names[i]^, len);
  end;
  total := mrh_$chunks_total;
  in_use := mrh_$chunks_in_use;
  vfmt_$write('%/%LD chunks in use out of %LD chunks allocated%$', in_use,
              total);
  if accounted <> in_use then
    vfmt_$write('   (*** ONLY %LD CHUNKS ACCOUNTED FOR ***)%$', accounted);
  if (cargs_$debug_switches['M'] & 16#200) <> 0 then begin
    map := mrh_$get_map;
    vfmt_$write('%.');
    for i := 0 to total - 1 do begin
      if (i & 15) = 0 then
        vfmt_$write('%.');
      owner := map^[i].owner;
      if owner < 0 then
        vfmt_$write('[%2ZLD] %$', -owner)
      else if owner = 0 then
        vfmt_$write(' --  %$', owner)
      else
        vfmt_$write(' %2ZLD  %$', owner);
    end;
  end;
  vfmt_$write('%/%/%.');
end;
