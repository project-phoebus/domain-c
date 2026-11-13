{ ra - the register allocator (cc.a88k only): the RA phase.  A
  graph-colouring allocator run once for each register class (ra_class:
  1 the integer registers, 2 the floating singles, 3 the floating
  pairs).  Each pass renumbers the instructions of each block, rebuilds
  the live ranges' segment lists and the lifetime bit vectors
  (ra_$clean_bb_and_init_bit_vectors), weights each reference by the
  block's loop depth into a live range's spill cost
  (ra_$initialize_basic_block: 16 to the depth), builds the conflict
  graph (complex live ranges, those live across blocks, in triangular
  bit matrices; simple ones, local to a block, numbered per block), the
  aversions and preferences between live ranges (moves to be coalesced,
  live ranges a pipeline delay keeps apart: the "protection pipe"),
  orders the live ranges by repeatedly removing the least constrained
  one (ra_$collapse_conflict_graph, Chaitin's cost over degree for the
  spill candidates) and assigns registers in the reverse order
  (ra_$assign_registers), opening registers the conventions would have
  saved before giving up a live range to spilling; the spill code is
  ra_utils' (ra_utils_$add_spill_code), after which the pass repeats.
  After the last class, the stack frame's objects are laid out
  (ra_$allocate_stack_frame) and the automatic storage relocated.

  Image addresses (DOMAIN C 6.9; cc.a88k only):
    cc.m68k   cc.a88k
    --------  0x266C58  utils_ins_$operands_instruction (utils.ins.pas)
    --------  0x266C7A  zero (internal)
    --------  0x266C90  ra_$begin_compilation
    --------  0x266E30  ra_$end_compilation
    --------  0x266E32  ra_$initialize_lr (internal)
    --------  0x266EB8  get_lr_equivalence_class_parent (internal)
    --------  0x266F78  ra_$process_operand_on_this_pass (internal)
    --------  0x267000  lr_safely_unconsumed (internal)
    --------  0x267048  ra_$clean_bb_and_init_bit_vectors
    --------  0x2672A2  ra_$initialize_basic_block (internal)
    --------  0x2678D4  ra_$allocate_stack_frame (internal)
    --------  0x267B4C  ra_$db_was_referenced (internal)
    --------  0x267C4C  init_complex (internal)
    --------  0x267C72  ra_$initialize_routine (internal)
    --------  0x268298  ra_$calc_canonical_desc_bit (internal)
    --------  0x268334  ra_$init_descriptor (internal)
    --------  0x268474  ra_$new_simple_id (internal)
    --------  0x268528  ra_$lrs_already_conflict (internal)
    --------  0x268748  ra_$lookup_a_p (internal)
    --------  0x2687DE  ra_$enter_a_p (internal)
    --------  0x268944  ra_$enter_preference (internal)
    --------  0x2689D4  ra_$new_conflict (internal)
    --------  0x268AF0  ra_$enter_conflicts (internal)
    --------  0x268B66  ra_$enter_architectural_conflict (internal)
    --------  0x268B98  process_call_or_svc_clobbers (internal)
    --------  0x268BFC  ra_$call_or_svc_ip_clobbers (internal)
    --------  0x268C60  ra_$call_or_svc_fp_clobbers (internal)
    --------  0x268D34  ra_$advance_one_clock_tick (internal)
    --------  0x268E1C  ra_$unlink_protected_lr (internal)
    --------  0x268F60  ra_$protect_lr_for_n_ticks (internal)
    --------  0x269016  ra_$drop_if_now_dead (internal)
    --------  0x26920C  ra_$protected_final_lrs_this_bb (internal)
    --------  0x2692D4  ra_$fill_protected_lr_pipe (internal)
    --------  0x269362  ra_$possible_aversions (internal)
    --------  0x269560  ra_$create_true_aversions (internal)
    --------  0x269662  ra_$release_rws_storage (internal)
    --------  0x2696C2  ra_$build_conflict_graph
    --------  0x26A9CE  enter_lr_in_appropriate_work_list (internal)
    --------  0x26AACC  remove_lr_from_current_work_list (internal)
    --------  0x26AB4A  ra_$remove_lr_from_graph (internal)
    --------  0x26AC2E  pick_uwork_candidate (internal)
    --------  0x26AC88  pick_uwork_victim (internal)
    --------  0x26AD22  sort_ap_table (internal)
    --------  0x26AE56  ra_$collapse_conflict_graph (internal)
    --------  0x26B8F2  ra_$extra_registers_needed (internal)
    --------  0x26B9C8  ra_$open_another_fp_register (internal)
    --------  0x26BC60  ra_$open_another_ip_register (internal)
    --------  0x26BCE4  ra_$count_available_registers (internal)
    --------  0x26BD72  ra_$determine_available_registers (internal)
    --------  0x26C014  ra_$combine_with_sf (internal)
    --------  0x26C162  ra_$open_registers (internal)
    --------  0x26C3D4  ra_$close_live_range_preferences (internal)
    --------  0x26C46E  ra_$zero_closure_next_fields (internal)
    --------  0x26C48A  ra_$spill_lr (internal)
    --------  0x26C594  ra_$pick_spill_lr (internal)
    --------  0x26C640  ra_$try_opening_another_register (internal)
    --------  0x26C772  ra_$assign_registers (internal)
    --------  0x26D2F8  ra_$relocate_automatic_storage (internal)
    --------  0x26D380  ra_$accumulate_true_writes (internal)
    --------  0x26D51C  ra_$spill_zero_cost_lrs (internal)
    --------  0x26D610  ra_$process_routine
    --------  0x26DF22  ra_$end_routine
    A5 0x48F488 (0x66C bytes): the dumps' titles (+0, three of 20
    characters, initialized), the work areas below, the bit masks 1 ..
    0x80 (+0x590, initialized) and the titles' lengths (+0x598, 13, 13,
    18), the register sets and counters (+0x5A0 .. +0x66A).  +0x65C
    holds the classes' letters, 'ISD' (initialized; process_routine's
    failure message reads one at A5 + 0x65B + class): ra_utils has the
    same three characters at its +0x204, and only these two units open
    ra.pvt.pas (an initialized variable of that insert, most likely;
    docs/questions.md 229).

  Every routine but the four entry points and the two ra_utils calls
  (ra_$clean_bb_and_init_bit_vectors, ra_$build_conflict_graph) is
  internal and reaches the unit's data through the caller's A5.

  The live ranges, segments and instructions carry the allocator's own
  data in batch A's records during RA, read here through views (ra_lr_t,
  ra_lts_t, ra_instr_t, ra_rtn_t; the offsets and meanings are reported
  in docs/backend-plan.md).  The spill costs are single reals computed
  through the FPP emulator (fpp_$, fpp_$eslv): written as real
  arithmetic, which dpc does not compile (docs/dpc-gaps.md 7; the gate's
  rewrites store the bits or use integers).  The FPP words decoded
  here: 0x0000 add, 0x000C subtract, 0x0018 reverse subtract, 0x0024
  multiply (0x002C by an immediate single), 0x003C reverse divide,
  0x0048 compare (0x0050 with an immediate), 0x005C an integer operand,
  0x00C4 a longword operand, 0x00A0 a multiply by an immediate double,
  0x007C the accumulator stored to an address operand, 0x0148 the power
  (x ** that operand), 0x00D4 0xFF3E the result stored as a single.

  Not known from the original: every local, parameter, type and module
  variable name but the routines' (the .blocks names); the views' field
  names. }
module ra;

%include '/sys/ins/base.ins.pas';
%include '/sys/ins/rws.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'lang2/source/lt_utils/source/bug_check.ins.pas';
%include 'lang/lang/source/globals.ins.pas';
%include 'lang2/source/be_com/backend.ins.pas';
%include 'lang2/source/lt_utils/source/mrh.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang2/source/be_prism/target.ins.pas';
%include 'idccclx/be_prism_68k_pool/dseemgrs/apollo/dervobjs/be_com/opcodes.def/h7ecfdfe8.000/opcodes/opcode_enumeration.ins.pas';
%include 'lang2/source/be_com/call_conv.ins.pas';
%include 'lang2/source/be_com/ra.pvt.pas';
%include 'lang2/source/be_com/utils.ins.pas';

const
  { The register classes (ra_class). }
  ra_ip = 1;
  ra_fp = 2;
  ra_pair = 3;

type
  { A single real and its bits (the gate's gap 7 rewrites store the
    bits). }
  ra_real_t = record
    case integer of
      1: (r: real);
      2: (i: integer32);
  end;

  { The floating registers as ra keeps them: 0..31 first (unlike the
    routine's and the conventions' sets, 32..63 first). }
  ra_fpset_t = record
    lo: bv_word_t;                      { F0..F31 }
    hi: bv_word_t;                      { F32..F63 }
  end;
  { A set of the 64 floating registers in dpc's layout (elements 63..32
    in the first longword) and its halves. }
  ra_set64_t = record
    case integer of
      1: (s: set of 0..63);
      2: (hi: bv_word_t;
          lo: bv_word_t);
  end;

  ra_lr_ptr_t = ^ra_lr_t;
  ra_lts_ptr_t = ^ra_lts_t;
  ra_ap_ptr_t = ^ra_ap_t;
  ra_conf_ptr_t = ^ra_conf_t;

  { A live range's +44: its reload cost (a single), during the conflict
    graph its conflicts. }
  ra_x44_t = record
    case integer of
      1: (r: real);
      2: (i: integer32);
      3: (conf: ra_conf_ptr_t);
  end;
  { A live range's +52: the segment last seen, then the next live range
    on the live list or in a pipe slot. }
  ra_x52_t = record
    case integer of
      1: (lts: ra_lts_ptr_t);
      2: (lr: ra_lr_ptr_t);
  end;

  { An aversion or preference between two live ranges (on both their
    lists, +60, next_a for a's and next_b for b's): at loop depth
    (+28, the lists' order), the aversion's strength (+20: ticks a
    pipeline delay would cost if they shared a register) and the
    preference's (+24: moves between them, each its delay plus one).
    From ra_ap_heaps[which]. }
  ra_ap_t = record
    a: ra_lr_ptr_t;                     { +0 }
    b: ra_lr_ptr_t;                     { +4 }
    next_a: ra_ap_ptr_t;                { +8 }
    next_b: ra_ap_ptr_t;                { +12 }
    closure: ra_ap_ptr_t;               { +16: the preference closure
                                          (ra_$close_live_range_preferences) }
    avoid: integer32;                   { +20 }
    pref: integer32;                    { +24 }
    depth: char;                        { +28 }
    done: boolean;                      { +29: counted out of the active
                                          ones (ra_$remove_lr_from_graph) }
  end;

  ra_ap_table_t = array [0..65535] of ra_ap_ptr_t;
  ra_ptrs_ptr_t = ^ra_ptrs_t;
  ra_ptrs_t = array [0..16#3FFFFFF] of univ_ptr;

  { A live range's +64, +68 while registers are assigned: the registers
    it prefers (the floating 32..63, then the rest). }
  ra_pref_ptr_t = ^ra_pref_t;
  ra_pref_t = record
    space0: array [0..63] of char;
    hi: bv_word_t;                      { +64 }
    lo: bv_word_t;                      { +68 }
  end;
  ra_lrs_ptr_t = ^ra_lrs_t;
  ra_lrs_t = array [0..16#3FFFFFF] of ra_lr_ptr_t;

  { A conflict between two unassigned live ranges (on both their lists,
    +44).  From ra_conf_heaps[which]. }
  ra_conf12_t = record
    case integer of
      1: (next_b: ra_conf_ptr_t);
      2: (f: packed record
            b12, b13, b14: 0..255;
            b15_7_1: 0..127;
            removed: boolean;           { +15 .0: taken out of the graph
                                          (ra_$remove_lr_from_graph) }
            end);
  end;
  ra_conf_t = record
    a: ra_lr_ptr_t;                     { +0 }
    b: ra_lr_ptr_t;                     { +4 }
    next_a: ra_conf_ptr_t;              { +8 }
    f12: ra_conf12_t;                   { +12 }
  end;

  { A pending aversion (ra_$possible_aversions): a and b, the ticks b's
    protection had left. }
  ra_pend_ptr_t = ^ra_pend_t;
  ra_pend_t = record
    next: ra_pend_ptr_t;                { +0 }
    a: ra_lr_ptr_t;                     { +4 }
    b: ra_lr_ptr_t;                     { +8 }
    ticks: integer32;                   { +12 }
  end;

  ra_bytes_ptr_t = ^ra_bytes_t;
  ra_bytes_t = array [0..16#7FFFFFF] of char;
  ra_longs_ptr_t = ^ra_longs_t;
  ra_longs_t = array [1..16#3FFFFFF] of integer32;

  { A conflict bit matrix (ra_$init_descriptor): an ordinary one's rows
    (bits a column) and the longwords a column takes less one; its size
    in longwords and vector (bit k of byte n is pair 8n + k: ra_masks);
    cursor the next column to clear (the complex x simple matrix's,
    ra_$new_simple_id). }
  ra_desc_t = record
    bits: integer32;                    { +0 }
    words: integer32;                   { +4 }
    size: integer32;                    { +8 }
    vec: ra_bytes_ptr_t;                { +12 }
    cursor: ra_longs_ptr_t;             { +16 }
    l20: integer32;                     { +20 }
  end;

  { lr_t (batch A's) as the allocator uses it.  +2
    physical_register_number the register assigned (+3 bit 7
    physical_register, set once it is; lr_t's names, the original's:
    docs/questions.md 311), +3 bit 0 a
    spill victim; +28 the spill cost and +44 the reload cost (single
    reals: what a reload folded into a byte or halfword load or a TST
    saves; added to the cost of a rematerializable live range), +44
    later the head of its conflicts (ra_conf_t); +36 the segments
    (rebuilt each pass); +52 the segment last seen (in the block being
    cleaned), later the next on the live list or in a pipe slot; +58
    its serial number (ra_serial) or, for a simple live range, its
    index in the block (+40); +72 the first definition (the others
    chained at the segments' +36). }
  ra_lr_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      physical_register_number: 0..255;
      physical_register: boolean;       { +3 .7 }
      physical_register_is_no_modify: boolean;  { .6 }
      physical_register_user_declared: boolean; { .5 }
      b3_4: boolean;
      live: boolean;                   { .3: on the live list }
      b3_2, b3_1: boolean;
      spilled: boolean;                 { .0 }
      end;
    id: 0..65535;                       { +4 }
    num: integer;                       { +6 }
    f8: packed record                   { +8 }
      kind: 0..255;
      b9: 0..255;                       { +9 }
      b10_7: boolean;                   { +10 }
      protected: boolean;               { .6: in the protection pipe }
      b10_5: boolean;
      b10_4_0: 0..31;
      b11: 0..255;
      end;
    next: ra_lr_ptr_t;                  { +12 }
    mate: ra_lr_ptr_t;                  { +16 }
    node20: univ_ptr;                   { +20 }
    memory_home: univ_ptr;              { +24 }
    cost: ra_real_t;                    { +28 }
    home_lr: ra_lr_ptr_t;               { +32 }
    ltss: ra_lts_ptr_t;                 { +36 }
    bb40: bb_ptr_t;                     { +40: the block its simple index
                                          (+58) is for }
    x44: ra_x44_t;                      { +44 }
    prev: ra_lr_ptr_t;                  { +48: on the live list or in a
                                          pipe slot }
    x52: ra_x52_t;                      { +52 }
    w56: 0..65535;                      { +56: its conflicts }
    serial: 0..65535;                   { +58 }
    aps: ra_ap_ptr_t;                   { +60: its aversions and
                                          preferences }
    expires: integer32;                 { +64: the clock its protection
                                          ends at; when it went live }
    live_time: ra_real_t;               { +68: the instructions it was
                                          live, weighted }
    defs: ra_lts_ptr_t;                 { +72 }
    dead: ra_lts_ptr_t;                 { +76: its segments dropped from
                                          the live list (chained at +40) }
    avoid_hi: bv_word_t;                { +80: registers assigned to live
                                          ranges it conflicts with (the
                                          floating 32..63) }
    avoid_lo: bv_word_t;                { +84: (the rest) }
  end;

  { lts_t (batch A's) as the allocator uses it: +32 the number of the
    instruction that last referred to it (a word), +36 the next
    definition of its live range, +40 its last reference (an operand). }
  ra_lts_t = record
    rrp: rrp$set_t;                     { +0 }
    f2: packed record                   { +2 }
      num: 0..255;
      exposed: boolean;                 { +3 .7 }
      first_in_bb: boolean;             { .6 }
      b3_5, final, b3_3, b3_2, b3_1, b3_0: boolean;
      end;
    refs: opnd_ptr_t;                   { +4 }
    next: ra_lts_ptr_t;                 { +8 }
    bb: bb_ptr_t;                       { +12 }
    next_exposed: ra_lts_ptr_t;         { +16 }
    next_final: ra_lts_ptr_t;           { +20 }
    l24: integer32;                     { +24 }
    l28: integer32;                     { +28 }
    num: 0..65535;                      { +32 }
    w34: 0..65535;                      { +34 }
    next_def: ra_lts_ptr_t;             { +36 }
    last_ref: opnd_ptr_t;               { +40 }
    l44: univ_ptr;                      { +44 }
    lr: ra_lr_ptr_t;                    { +48 }
  end;

  { The routine's fields batch A has not named: +16 its calling
    conventions, +48 the stack frame's size (ra_$allocate_stack_frame),
    +116 the stack frame's live range, +120 another live range never
    spilled. }
  ra_rtn_ptr_t = ^ra_rtn_t;
  ra_rtn_t = record
    space0: array [0..15] of char;
    conv: call_conv_$ptr_t;             { +16 }
    space20: array [20..47] of char;
    frame_size: integer32;              { +48 }
    space52: array [52..115] of char;
    lr116: ra_lr_ptr_t;                 { +116 }
    lr120: ra_lr_ptr_t;                 { +120 }
  end;

  { An IL VAR_NAME (kind 109) or FORTRAN symbol (110) the stack frame
    holds (dbg_life's readings, docs/questions.md 194): flags (+32, a
    FORTRAN symbol's at +24) bit 27 on ra_frame_objs, bit 18 placed;
    size in bits (+36), alignment (+44, a log2), offset (+56), storage
    class (+72), the next on ra_frame_objs (+76; a FORTRAN symbol's
    +66).  A FORTRAN symbol's storage class is +11 bits 7..4, its offset
    +12, its equivalence ring +28. }
  ra_var_ptr_t = ^ra_var_t;
  ra_var_t = record
    space0: array [0..1] of char;
    kind: il_$kind_t;                   { +2 }
    space4: array [4..31] of char;
    flags: set of 0..31;                { +32 }
    size: integer32;                    { +36 }
    space40: array [40..43] of char;
    align: integer;                     { +44 }
    space46: array [46..55] of char;
    offset: integer32;                  { +56 }
    space60: array [60..71] of char;
    class: integer;                     { +72 }
    space74: array [74..75] of char;
    next: ra_var_ptr_t;                 { +76 }
  end;
  ra_fsym_ptr_t = ^ra_fsym_t;
  ra_fsym_t = record
    space0: array [0..1] of char;
    kind: il_$kind_t;                   { +2 }
    space4: array [4..10] of char;
    f11: packed record                  { +11 }
      class: 0..15;
      b11_3_0: 0..15;
      end;
    offset: integer32;                  { +12 }
    space16: array [16..23] of char;
    flags: set of 0..31;                { +24 }
    ring: ra_fsym_ptr_t;                { +28 }
    space32: array [32..65] of char;
    next: ra_var_ptr_t;                 { +66 }
  end;

  { An instruction during RA: the next move on a list of moves to
    preference (+24); the floating and integer registers live after it
    and at most during it (dmp's four counts, +28..+31). }
  ra_instr_ptr_t = ^ra_instr_t;
  ra_instr_t = record
    space0: array [0..23] of char;
    next_move: instr_ptr_t;             { +24 }
    fp_final: char;                     { +28 }
    fp_peak: char;                      { +29 }
    ip_final: char;                     { +30 }
    ip_peak: char;                      { +31 }
  end;

  { An instruction's first longword as the allocator reads it: +2 bits
    3..0 its stall cycles from SCHED (batch A's instr_hdr_t names bit 3
    do_not_delete). }
  ra_ihdr_ptr_t = ^ra_ihdr_t;
  ra_ihdr_t = packed record
    b0: 0..255;                         { +0 }
    nopnds: 0..255;                     { +1 }
    b2_7_4: 0..15;                      { +2 }
    stall: 0..15;                       { .3..0 }
    b3: 0..255;                         { +3 }
  end;

  { A block during RA: the registers live on entry and exit, the most
    live and those passing through, of each file (dmp's dmp_bb_t,
    ra_utils' ru_bb_t), and the registers written in it (+122 the
    integer, +126 the floating 32..63, +130 0..31). }
  ra_bb_ptr_t = ^ra_bb_t;
  ra_bb_t = record
    live_in_ip: char;                   { +0 }
    live_out_ip: char;
    max_ip: char;
    pass_ip: char;
    live_in_fp: char;                   { +4 }
    live_out_fp: char;
    max_fp: char;
    pass_fp: char;
    space8: array [8..121] of char;
    written_ip: bv_word_t;              { +122 }
    written_hi: bv_word_t;              { +126 }
    written_lo: bv_word_t;              { +130 }
  end;

  { instruction_attributes' operand descriptions (sched_utils'
    su_attr_t). }
  ra_attr_opnd_t = packed record
    form: 0..255;                       { +4k }
    num: 0..255;                        { +4k+1 }
    kind2: 0..3;                        { +4k+2 .7..6 }
    delay: 0..15;                       { .5..2 }
    b2_1_0: 0..3;
    b3: 0..255;                         { +4k+3 }
  end;
  ra_attr_opnds_ptr_t = ^ra_attr_opnds_t;
  ra_attr_opnds_t = array [1..4] of ra_attr_opnd_t;

  { lir's physical live ranges by register (lir_3f90: the 64 floating,
    lir_4090: the integer). }
  ra_phys_ptr_t = ^ra_phys_t;
  ra_phys_t = array [0..63] of ra_lr_ptr_t;

  ra_title_t = array [1..20] of char;

  { The sets a call or SVC clobbers, after its n operands. }
  ra_clob_ptr_t = ^ra_clob_t;
  ra_clob_t = record
    fp_hi: bv_word_t;                   { +44 + 12n }
    fp_lo: bv_word_t;                   { +48 + 12n }
    ip: bv_word_t;                      { +52 + 12n }
  end;

var
  ra_titles: array [ra_ip .. ra_pair] of ra_title_t
      := ['IP REGISTERS:%.     ', 'FP REGISTERS:%.     ',
          'FP REGISTER PAIRS:%.'];      { +0 }
  ra_masks: array [0..7] of char
      := [chr(1), chr(2), chr(4), chr(8), chr(16), chr(32), chr(64),
          chr(128)];                    { +0x590 }
  ra_pipe: array [0..20] of ra_lr_ptr_t;    { +0x40: the protection
                                          pipe's slots (from 1), each a
                                          list through +52 and +48 }
  ra_94: integer32;                     { +0x94 (not referenced) }
  ra_pend_xx: array [0..255] of ra_pend_ptr_t;    { +0x98: the pending
                                          aversions between complex live
                                          ranges, by loop depth }
  ra_ap_heaps: array [0..2] of mrh_$heap_t;    { +0x498: the aversion
                                          and preference records ("ra ss
                                          real A/P heap", sc, cc) }
  ra_conf_heaps: array [0..2] of mrh_$heap_t;  { +0x4D8: the conflict
                                          records ("ra ss conflict heap",
                                          sc, cc) }
  ra_pend_xx_heap: mrh_$heap_t;         { +0x518 ("ra pending aversion
                                          xx heap") }
  ra_pend_bb_heap: mrh_$heap_t;         { +0x530 ("ra pending aversion BB
                                          heap") }
  ra_ss: ra_desc_t;                     { +0x548: simple x simple }
  ra_cs: ra_desc_t;                     { +0x560: complex x simple }
  ra_cc: ra_desc_t;                     { +0x578: complex x complex }
  ra_title_len: array [ra_ip .. ra_pair] of integer
      := [13, 13, 18];                  { +0x598 }
  ra_pipe_len: integer32;               { +0x5A0: the pipe's last slot in
                                          use }
  ra_pend_depth: integer32;             { +0x5A4: the deepest
                                          ra_pend_xx list }
  ra_pend_bb: ra_pend_ptr_t;            { +0x5A8: the pending aversions
                                          within a block }
  ra_fp_reserved: ra_fpset_t;           { +0x5AC: the floating zero
                                          register, if any }
  ra_ip_reserved: bv_word_t;            { +0x5B4: the zero and PC-like
                                          registers }
  ra_pair_unalloc: ra_fpset_t;          { +0x5B8: the registers the pair
                                          class may not use (every odd
                                          one) }
  ra_fp_unalloc: ra_fpset_t;            { +0x5C0: the floating registers
                                          never allocated }
  ra_ip_unalloc: bv_word_t;             { +0x5C8: the integer registers
                                          never allocated (R24..R31) }
  ra_ip_like: bv_word_t;                { +0x5CC: the registers ip_reg_like
                                          operands name }
  ra_max_simple: integer32;             { +0x5D0: the most simple
                                          definitions in a block (rounded
                                          up: + 81, to 32) }
  ra_max_depth: integer32;              { +0x5D4: the deepest loop }
  ra_max_conflicts: integer32;          { +0x5D8: the most conflicts of a
                                          live range }
  ra_simple_ids: integer32;             { +0x5DC: the simple indices given
                                          in the block }
  ra_serial: integer32;                 { +0x5E0: the live ranges' serial
                                          numbers (lr +58) }
  ra_bb_late: integer32;                { +0x5E4 }
  ra_bb_last: integer32;                { +0x5E8 }
  ra_ip_zero: integer32;                { +0x5EC: target_properties
                                          +0x14, the zero register }
  ra_fp_zero: integer32;                { +0x5F0: +0x38, the floating
                                          one (-1: none) }
  ra_live_out: bv_ptr_t;                { +0x5F4 }
  ra_bb_mark: bb_ptr_t;                 { +0x5F8: the block being built
                                          (the simple indices') }
  ra_work_low: integer32;               { +0x5FC: COLLAPSE_WORK_LOW, the
                                          level the collapse is at }
  ra_work: ra_lrs_ptr_t;                { +0x600: the work lists, by twice
                                          the conflicts (+1 with active
                                          aversions or preferences) }
  ra_cand: ra_lrs_ptr_t;                { +0x608: the candidate lists, by
                                          depth }
  ra_unconstrained: integer32;          { +0x60C: COLLAPSE_UNCONSTRAINED }
  ra_clock: integer32;                  { +0x610: the protection pipe's
                                          clock }
  ra_ip_clobbered: bv_word_t;           { +0x614: the calls' and SVCs'
                                          clobbers }
  ra_fp_clobbered: ra_fpset_t;          { +0x618 }
  ra_save_ip: integer32;                { +0x620: the bytes of integer
                                          registers to save (ra_$open_registers) }
  ra_save_bytes: integer32;             { +0x624: the bytes of the other
                                          registers opened to save }
  ra_return_bb: bb_ptr_t;               { +0x628: the RETURN's block }
  ra_entry_bb: bb_ptr_t;                { +0x62C: the ENTRY's block }
  ra_fp_alloc: ra_fpset_t;              { +0x630: the floating registers
                                          allocated (complement of
                                          ra_fp_unalloc) }
  ra_ip_alloc: bv_word_t;               { +0x638 }
  ra_ip_used: bv_word_t;                { +0x63C }
  ra_fp_used: ra_fpset_t;               { +0x640 }
  ra_frame_objs: ra_var_ptr_t;          { +0x648: the stack frame's
                                          objects (chained at a VAR_NAME's
                                          +76, a FORTRAN symbol's +66) }
  ra_lrs: ra_lr_ptr_t;                  { +0x64C: the live ranges met this
                                          pass (chained at +12) }
  ra_class: integer;                    { +0x660: 1, 2, 3 }
  ra_no_clobbers: boolean;              { +0x662 }
  ra_check_db: boolean;                 { +0x664: decide whether the DB
                                          register is needed }
  ra_dropped: boolean;                  { +0x666: a live range left the
                                          live list }
  ra_final: boolean;                    { +0x668: the integer pass (the
                                          last): the frame is laid out }
  ra_db_used: boolean;                  { +0x66A }
  ra_letters: packed array [ra_ip .. ra_pair] of char := 'ISD';  { +0x65C:
                                          the classes' letters (the
                                          failure's message) }

define
  ra_650;                               { +0x650 }
  ra_654;                               { +0x654 (lir_main sets it) }
  ra_658;                               { +0x658 (lir_main sets it) }

{ ISC_$IS_A_REGISTER_CANDIDATE - isc_lir.ins.pas's heading (batch A,
  PA5), which ra does not open (its .blocks include list): declared
  here for ra_$process_routine.  isc_user_routines 0x213198. }
function isc_$is_a_register_candidate(
    sym: univ_ptr): boolean; options(val_param); extern;

{ zero - n bytes from p cleared, a longword at a time ((n + 3) div 4 of
  them; nothing for 0): rev889-patterns 100.

  0x266C7A, 0x16 bytes, internal, no frame. }

procedure zero(
    p: univ_ptr;
    n: integer32); options(val_param); internal;
var
  q: ra_longs_ptr_t;
  k: integer32;
begin
  if n <> 0 then begin
    q := p;
    for k := 1 to rshft(n + 3, 2) do
      q^[k] := 0;
  end;
end;

{ RA_$BEGIN_COMPILATION - the target's register files: the zero
  registers (target_properties +0x14, +0x38), the integer and floating
  registers never allocated (the complements of the allocatable ranges,
  +0x1C and +0x24 count, +0x3C and +0x44 count) and those reserved (the
  zero and PC-like registers, +0x18; the floating zero register).

  0x266C90, 0x192 bytes: each range a set of the range's bounds (`bset'
  downwards, the bound clamped to 31 or 63), complemented against the
  constant 0xFFFFFFFF (`not; and' with 0x266E24, 0x266E28): the
  ranges' constructors, whose upper bounds the compiler clamps (`cmpi.w
  #31; bls') and whose loops it skips for an empty range (`bcs'; dpc
  refuses a run-time range: docs/dpc-gaps.md 38); a 64-bit
  set built in dpc's layout and stored halves swapped (-8 to +0x5C4, -4
  to +0x5C0); the reserved integer set from ra_ip_zero's low word (+0x5EE)
  but the PC-like register from target_properties' own word (+0x1A),
  each guarded by its sign. }

procedure ra_$begin_compilation;
var
  f: ra_set64_t;
begin
  ra_ip_zero := target_properties.p_14[0];
  ra_fp_zero := target_properties.p_14[9];
  ra_ip_unalloc := [0..31] - [target_properties.p_14[2] ..
      target_properties.p_14[2] + target_properties.p_14[4] - 1];
  f.s := [0..63] - [target_properties.p_14[10] ..
      target_properties.p_14[10] + target_properties.p_14[12] - 1];
  ra_fp_unalloc.hi := f.hi;
  ra_fp_unalloc.lo := f.lo;
  if ra_ip_zero >= 0 then
    ra_ip_reserved := [ra_ip_zero]
  else
    ra_ip_reserved := [];
  if target_properties.p_14[1] >= 0 then
    ra_ip_reserved := ra_ip_reserved + [target_properties.p_14[1]];
  f.s := [];
  if ra_fp_zero >= 0 then
    f.s := [ra_fp_zero];
  ra_fp_reserved.hi := f.hi;
  ra_fp_reserved.lo := f.lo;
end;

{ RA_$END_COMPILATION - nothing.  0x266E30, 2 bytes (no A5). }

procedure ra_$end_compilation;
begin
end;

{ ra_$initialize_lr - a live range met for the first time this pass:
  its allocation marks cleared (rrp modify .. true_write, +3 bits 3, 2,
  +10 bit 6), life_mark (never spill) set for a physical register or,
  with simple, a simple live range; its cost, segments, +40 .. +56 and
  first definition cleared, and with all its assignment too (+60 ..
  +68, +76 .. +84, +9, +10 bit 5).

  0x266E32, 0x86 bytes, internal: the rrp computed in D2 (`andi.w
  #-2045', `ori.w #256') and stored once. }

procedure ra_$initialize_lr(
    lr: ra_lr_ptr_t;
    simple: boolean;
    all: boolean); options(val_param); internal;
var
  s: rrp$set_t;
begin
  if lr <> nil then begin
    s := lr^.rrp - [rrp$modify .. rrp$true_write];
    if lr^.f2.physical_register or (simple and (lr^.id = 0)) then
      s := s + [rrp$life_mark];
    lr^.rrp := s;
    lr^.f2.live := false;
    lr^.f2.b3_2 := false;
    lr^.f8.protected := false;
    lr^.cost.r := 0.0;
    lr^.ltss := nil;
    lr^.x44.r := 0.0;
    lr^.prev := nil;
    lr^.x52.lr := nil;
    lr^.w56 := 0;
    lr^.serial := 0;
    lr^.defs := nil;
    lr^.bb40 := nil;
    if all then begin
      lr^.aps := nil;
      lr^.expires := 0;
      lr^.live_time.r := 0.0;
      lr^.dead := nil;
      lr^.avoid_hi := [];
      lr^.avoid_lo := [];
      lr^.f8.b9 := 0;
      lr^.f8.b10_5 := false;
    end;
  end;
end;

{ get_lr_equivalence_class_parent - the live range whose register lr
  takes: in the floating classes, the physical register's live range
  (lir_3f90) of an assigned single, and in the pair class the mate of
  an odd half (odd register or fp_reg_odd_only); otherwise lr itself
  (an integer live range, nil).

  0x266EB8, 0x84 bytes, internal; A0. }

function get_lr_equivalence_class_parent(
    lr: ra_lr_ptr_t): ra_lr_ptr_t; options(val_param); internal;
var
  phys: ra_phys_ptr_t;
begin
  if (lr = nil) or (rrp$ip_reg in lr^.rrp) then
    get_lr_equivalence_class_parent := lr
  else
    case ra_class of
      ra_fp:
        if lr^.f2.physical_register then begin
          phys := univ_ptr(addr(lir_3f90));
          get_lr_equivalence_class_parent := phys^[lr^.f2.physical_register_number];
        end
        else
          get_lr_equivalence_class_parent := lr;
      ra_pair:
        if odd(lr^.f2.physical_register_number) or (rrp$fp_reg_odd_only in lr^.rrp) then begin
          get_lr_equivalence_class_parent := lr^.mate;
          if lr^.mate = nil then
            bug_check('RA: GET_LR_EQUIVALENCE_CLASS_PARENT -- LR %wd has no mate%$',
                lr^.num);
        end
        else
          get_lr_equivalence_class_parent := lr;
      otherwise
        get_lr_equivalence_class_parent := lr;
    end;
end;

{ ra_$process_operand_on_this_pass - whether op belongs to one of the
  classes asked for: an ip_reg for 1, an fp_reg or fp_reg_pair for 2,
  and for 3 a pair, or a single that is half of one (the operand's or
  its live range's fp_reg_even/odd_only, or the live range assigned).

  0x266F78, 0x88 bytes, internal: classes a longword (the callers build
  [ra_class] in a word, `clr.w; bset', and zero-extend it). }

function ra_$process_operand_on_this_pass(
    op: opnd_ptr_t;
    classes: ra_classes_t): boolean; options(val_param); internal;
var
  lr: ra_lr_ptr_t;
begin
  ra_$process_operand_on_this_pass := true;
  if (ra_ip in classes) and (op^.h.kind = operand$ip_reg) then
    return;
  if (ra_fp in classes) and
     (op^.h.kind in [operand$fp_reg, operand$fp_reg_pair]) then
    return;
  if ra_pair in classes then begin
    if not (op^.h.kind in [operand$fp_reg, operand$fp_reg_pair]) then
      ra_$process_operand_on_this_pass := false
    else if (op^.h.kind <> operand$fp_reg_pair) and
            not (op^.h.fp_reg_odd_only or op^.h.fp_reg_even_only) then begin
      lr := ra_lts_ptr_t(op^.lts)^.lr;
      if lr^.rrp * [rrp$fp_reg_even_only, rrp$fp_reg_odd_only] = [] then
        ra_$process_operand_on_this_pass := lr^.f2.physical_register;
    end;
  end
  else
    ra_$process_operand_on_this_pass := false;
end;

{ lr_safely_unconsumed - whether op is an unconsumed write of a simple,
  unassigned integer live range when the target has a zero register:
  the result can go to the zero register.

  0x267000, 0x48 bytes, internal. }

function lr_safely_unconsumed(
    op: opnd_ptr_t): boolean; options(val_param); internal;
var
  lr: ra_lr_ptr_t;
begin
  lr_safely_unconsumed := false;
  if op^.h.unconsumed and op^.h.write then begin
    lr := ra_lts_ptr_t(op^.lts)^.lr;
    if (lr^.id = 0) and (rrp$ip_reg in lr^.rrp) and
       not lr^.f2.physical_register and (target_properties.p_14[0] >= 0) then
      lr_safely_unconsumed := true;
  end;
end;

{ RA_$CLEAN_BB_AND_INIT_BIT_VECTORS - bb's instructions renumbered (a
  group counts as one) and given the block's loop depth (+41); those not
  marked to stay (+2 bit 6) unlinked; each register operand of the
  classes asked for linked into its segment (the segment's references
  and last reference, +40; its live range's segment list, rebuilt, and
  definitions, +72), its live range initialized the first time it is
  met (and, with first, chained on ra_lrs and numbered), and the block's
  lifetime vectors set (live_gen, transparent, avail_gen).

  0x267048, 0x25A bytes (A5): the unlinking branches on the flags of
  the moves of the next instruction (pattern 111); the instruction
  counter a word (D4); `ori.w #1024' (true_write) for a write but in a
  preference move or the ENTRY; the second test of +2 bit 6 kept. }

procedure ra_$clean_bb_and_init_bit_vectors;
var
  n: integer;
  prev, i: instr_ptr_t;
  k: integer;
  op: opnd_ptr_t;
  lts, l: ra_lts_ptr_t;
  lr: ra_lr_ptr_t;
  w: integer;
  s: rrp$set_t;
begin
  n := 1;
  prev := nil;
  i := bb^.first;
  while i <> nil do begin
    if not i^.h.b2_6 then begin
      if prev = nil then
        bb^.first := i^.next
      else
        prev^.next := i^.next;
      if i^.next = nil then
        bb^.last := prev
      else
        i^.next^.prev := prev;
    end
    else begin
      i^.num := n;
      i^.b41 := chr(bb^.f.depth);
      for k := 1 to i^.h.nopnds do begin
        op := addr(i^.opnds[k]);
        if ra_$process_operand_on_this_pass(op, classes) then begin
          lts := ra_lts_ptr_t(op^.lts);
          lr := lts^.lr;
          if not lr_safely_unconsumed(op) then begin
            if not (rrp$ra_marked in lr^.rrp) then begin
              ra_$initialize_lr(lr, bb^.f.atomic, first);
              lr^.rrp := lr^.rrp + [rrp$ra_marked];
              lr^.x52.lts := lts;
              if first then begin
                if lr^.id <> 0 then begin
                  ra_serial := ra_serial + 1;
                  lr^.serial := ra_serial;
                end;
                lr^.next := ra_lrs;
                ra_lrs := lr;
              end;
            end;
            if rrp$ra_marked in lts^.rrp then
              lts^.last_ref^.link := op
            else begin
              lts^.rrp := lts^.rrp - [rrp$modify .. rrp$life_mark,
                  rrp$true_write] + [rrp$ra_marked];
              lts^.f2.first_in_bb := true;
              lts^.f2.b3_2 := false;
              lts^.bb := bb;
              lts^.refs := op;
              lts^.next := lr^.ltss;
              lr^.ltss := lts;
              lts^.next_def := nil;
              lts^.num := 0;
              lts^.w34 := 0;
            end;
            lts^.num := i^.num;
            w := opnd_bytes_ptr_t(op)^.rrp;
            s := rrp$set_t(w);
            if s * [rrp$modify, rrp$write] <> [] then begin
              if not i^.h.preference and (i^.opc <> ord(opc$entry)) then
                s := s + [rrp$true_write];
              if rrp$write in s then begin
                lts^.next_def := lr^.defs;
                lr^.defs := lts;
              end;
            end;
            lr^.rrp := lr^.rrp + s;
            lts^.rrp := lts^.rrp + s;
            lts^.last_ref := op;
            op^.link := nil;
            l := lr^.x52.lts;
            if l <> lts then begin
              if (l <> nil) and (l^.bb = bb) then
                l^.f2.first_in_bb := false;
              lr^.x52.lts := lts;
            end;
            if lr^.id <> 0 then
              if op^.h.read then
                bv_$set_if_not_killed(bb^.transparent, lr_ptr_t(lr),
                    bb^.live_gen)
              else if s * [rrp$modify, rrp$write] <> [] then begin
                bv_$clear(bb^.transparent, lr_ptr_t(lr));
                bv_$set(bb^.avail_gen, lr_ptr_t(lr));
              end;
          end;
        end;
      end;
      if i^.h.b2_6 then begin
        prev := i;
        if not i^.h.grouped then
          n := n + 1
        else if not i^.next^.h.b2_6 then begin
          i^.h.grouped := false;
          n := n + 1;
        end;
      end;
    end;
    i := i^.next;
  end;
end;

{ ra_$initialize_basic_block - bb cleaned for this pass, then each
  instruction's reference costs: a reference weighs 16 to the block's
  loop depth (capped at 24); a read or write adds the weight to its live
  range's spill cost, a modify twice the weight; a write that is not
  read subtracts twice the weight from the reload cost, a read that a
  reload can absorb (TSTB, TSTW, EXTEND7/15 setting the condition codes
  with an unconsumed or zero result, an EXTRACTU of the low byte or
  halfword in place) adds it to the reload cost, a floating control
  instruction's read moves it from the spill cost to twice the reload
  cost; a register-to-register move that sets no condition codes costs
  nothing, nor a TST.  An intend-to-modify read of a result's live range
  makes the result a plain write; an unconsumed simple result goes to
  the zero register (operand kind ip_reg_like).  Calls and SVCs add
  their clobbers to ra_ip_clobbered/ra_fp_clobbered (a call sets the
  routine's contains_call and save_rpc); the RETURN's and ENTRY's blocks
  are noted; ip_reg_like operands' registers collected; in the last
  pass each stack-frame displacement's object is put on ra_frame_objs
  once (flags bit 27; bit 18, placed, cleared; a VAR_NAME's alignment
  from its size when +32 bit 17).  The deepest loop and the most simple
  definitions in a block are kept.

  0x2672A2, 0x566 bytes, internal: the weight `2.0 ** (depth * 4.0)'
  through fpp_$ (0x00C4 the depth, 0x00A0 4.0, 0x007C into a temporary,
  0x0078 2.0, 0x0148 the power, 0x00D4 0xFF3E to a single); the costs
  through fpp_$eslv (0x0000, 0x000C, 0x0018, 0x002C 2.0); the classes
  call and SVC as the mask 0x100004; the operand loop counts k (D7) and
  the operand description (-64) together. }

procedure ra_$initialize_basic_block(
    bb: bb_ptr_t); options(val_param); internal;
type
  ra_attr_view_ptr_t = ^ra_attr_view_t;
  ra_attr_view_t = record
    w0: 0..65535;
    w2: 0..65535;
    opnds: ra_attr_opnds_t;             { +4 }
  end;
var
  depth: integer32;
  weight, reload, cost: ra_real_t;
  nsimple: integer32;
  bbdepth: integer32;
  i: instr_ptr_t;
  attr: instr_attr_ptr_t;
  k: integer;
  op, res: opnd_ptr_t;
  lts: ra_lts_ptr_t;
  lr: ra_lr_ptr_t;
  clob: ra_clob_ptr_t;
  rtn: rtn_ptr_t;
  v: ra_var_ptr_t;
  fs: ra_fsym_ptr_t;
  free, absorbed: boolean;
begin
  ra_$clean_bb_and_init_bit_vectors(bb, [ra_class], true);
  depth := bb^.f.depth;
  if depth > 24 then
    depth := 24;
  weight.r := 2.0 ** (depth * 4.0);
  nsimple := 0;
  bbdepth := bb^.f.depth;
  if bbdepth > ra_max_depth then
    ra_max_depth := bbdepth;
  i := bb^.first;
  while i <> nil do begin
    i^.b41 := chr(bbdepth);
    attr := addr(instruction_attributes[i^.opc]);
    if attr^.class in [class$call, class$svc] then begin
      if attr^.class = class$call then begin
        rtn := rtn_ptr_t(at_backend_4fc);
        rtn^.f226.contains_call := true;
        rtn^.f226.save_rpc := true;
      end;
      clob := univ_ptr(addr(i^.opnds[i^.h.nopnds + 1]));
      ra_fp_clobbered.hi := (clob^.fp_hi + ra_fp_clobbered.hi) -
          ra_fp_reserved.hi;
      ra_fp_clobbered.lo := (clob^.fp_lo + ra_fp_clobbered.lo) -
          ra_fp_reserved.lo;
      ra_ip_clobbered := (clob^.ip + ra_ip_clobbered) - ra_ip_reserved;
    end
    else if i^.opc = ord(opc$return) then
      ra_return_bb := bb
    else if i^.opc = ord(opc$entry) then
      ra_entry_bb := bb;
    for k := 1 to i^.h.nopnds do begin
      op := addr(i^.opnds[k]);
      case op^.h.kind of
        operand$ip_reg, operand$fp_reg, operand$fp_reg_pair:
          if ra_$process_operand_on_this_pass(op, [ra_class]) then begin
            if (k < attr^.nresults) and op^.h.intend_to_modify and
               (ra_attr_view_ptr_t(attr)^.opnds[k].kind2 = 0) then begin
              op^.h.intend_to_modify := false;
              res := addr(i^.opnds[attr^.nresults]);
              if not res^.h.modify then
                bug_check('RA_$INITIALIZE_BASIC_BLOCK -- destination is not a modify access%$');
              res^.h.modify := false;
              res^.h.write := true;
            end;
            lts := ra_lts_ptr_t(op^.lts);
            lr := lts^.lr;
            if lr_safely_unconsumed(op) then begin
              op^.h.kind := operand$ip_reg_like;
              lr^.f2.physical_register := true;
              lr^.f2.physical_register_number := ra_ip_zero;
            end
            else begin
              reload.r := lr^.x44.r;
              cost := lr^.cost;
              free := false;
              if attr^.b6_0 and
                 (i^.opnds[1].h.kind = i^.opnds[2].h.kind) and
                 (i^.opnds[1].h.count = 0) then
                free := not (i^.h.sets_cc or i^.h.fp_ccs);
              if not free and (i^.opc <> ord(opc$tst)) then begin
                absorbed := false;
                if (i^.opc = ord(opc$tstw)) or (i^.opc = ord(opc$tstb)) then
                  absorbed := true
                else if ((i^.opc = ord(opc$extend7)) or
                         (i^.opc = ord(opc$extend15))) and
                        i^.h.sets_cc then begin
                  if i^.opnds[2].h.unconsumed then
                    absorbed := true
                  else if (i^.opnds[2].h.kind = operand$ip_reg_like) and
                          (integer32(i^.opnds[2].lts) = lir_main_c4c) then
                    absorbed := true;
                end;
                if not absorbed and (i^.opc = ord(opc$extractu)) and
                   (i^.opnds[1].h.kind = operand$ip_reg) and
                   (i^.opnds[1].lts = lts_ptr_t(lts)) and
                   (i^.opnds[2].h.kind = operand$immediate) and
                   (i^.opnds[2].value = 0) and
                   ((i^.h.width = 8) or (i^.h.width = 16)) then
                  absorbed := true;
                if absorbed then
                  reload.r := reload.r + weight.r
                else if (attr^.class = class$fp_control) and
                        (op^.h.read or i^.h.sets_cc) then begin
                  reload.r := reload.r + weight.r * 2.0;
                  cost.r := cost.r - weight.r;
                end
                else if op^.h.modify then
                  cost.r := weight.r * 2.0 + cost.r
                else begin
                  if not op^.h.read then
                    reload.r := reload.r - weight.r * 2.0;
                  cost.r := cost.r + weight.r;
                end;
              end;
              lr^.x44.r := reload.r;
              lr^.cost := cost;
              if (lr^.id = 0) and op^.h.write then
                nsimple := nsimple + 1;
            end;
          end;
        operand$ip_reg_like:
          ra_ip_like := ra_ip_like +
              [ra_lts_ptr_t(op^.lts)^.lr^.f2.physical_register_number mod 32];
        operand$displacement_stack_frame:
          if ra_final then begin
            v := ra_var_ptr_t(op^.link);
            case v^.kind of
              var_name:
                if v^.flags * [8, 27] = [] then begin
                  v^.flags := v^.flags - [18] + [27];
                  if 17 in v^.flags then begin
                    if v^.size <= 32 then
                      v^.align := 2
                    else
                      v^.align := 3;
                  end
                  else if v^.align > 3 then
                    bug_check('RA_$INITIALIZE_BASIC_BLOCK -- alignment greater than quadword%$');
                  v^.next := ra_frame_objs;
                  ra_frame_objs := v;
                end;
              fortran_symbol: begin
                fs := ra_fsym_ptr_t(v);
                if fs^.flags * [8, 27] = [] then begin
                  fs^.flags := fs^.flags - [18] + [27];
                  fs^.next := ra_frame_objs;
                  ra_frame_objs := v;
                end;
                end;
              otherwise
                bug_check('RA_$INITIALIZE_BASIC_BLOCK -- displacement_stack_frame to unknown object%$');
            end;
          end;
        otherwise
      end;
    end;
    i := i^.next;
  end;
  if nsimple > ra_max_simple then
    ra_max_simple := nsimple;
end;

{ ra_$allocate_stack_frame - the objects on ra_frame_objs not yet placed
  (flags bit 18) given offsets in the routine's frame (+48, from where it
  is), by alignment, the largest first (level 3, 8 bytes, down to 0):
  at each level the objects of that alignment that fit, then smaller
  alignments' objects larger than half the level's size; the frame then
  padded to the level's alignment.  room bounds the bytes placed (the
  routine returns when it is used up).  A VAR_NAME's size is its bits
  rounded to bytes (4 for storage class 5), a FORTRAN symbol's sz_fsym's
  (its equivalence ring's extent, which moves with it; 4 for class 5),
  its alignment by its size.  A level-3 object makes the routine
  quad_aligned.

  0x2678D4, 0x246 bytes, internal: max (-36) 1 shl level, maxint at
  level 3; half (-28); the fit test `seq; sle; and.b' then three
  branches; the padding `lsl.l' of the size by 32 - level, then a loop
  over the low bits. }

procedure ra_$allocate_stack_frame(
    rtn: rtn_ptr_t;
    level: integer32;
    room: integer32); options(val_param); internal;
label
  10;
var
  off, size, align, max, half, low, t, k, m: integer32;
  obj, next: ra_var_ptr_t;
  fs, p: ra_fsym_ptr_t;
begin
  off := ra_rtn_ptr_t(rtn)^.frame_size;
  while level >= 0 do begin
    max := lshft(1, level);
    half := rshft(max, 1);
    if level = 3 then
      max := 16#7FFFFFFF;
    obj := ra_frame_objs;
    while obj <> nil do begin
      fs := ra_fsym_ptr_t(obj);
      case obj^.kind of
        var_name: begin
          next := obj^.next;
          if 18 in obj^.flags then
            goto 10;
          if obj^.class = 5 then
            size := 4
          else
            size := rshft(obj^.size + 7, 3);
          align := obj^.align;
          end;
        fortran_symbol: begin
          next := fs^.next;
          if 18 in fs^.flags then
            goto 10;
          if fs^.f11.class = 5 then
            size := 4
          else if fs^.ring = nil then
            size := sz_fsym(il_$node_ptr_t(fs))
          else begin
            low := fs^.offset;
            size := sz_fsym(il_$node_ptr_t(fs)) + fs^.offset;
            p := fs^.ring;
            while p <> fs do begin
              if low > p^.offset then
                low := p^.offset;
              t := sz_fsym(il_$node_ptr_t(p)) + p^.offset;
              if size < t then
                size := t;
              p := p^.ring;
            end;
            size := size - low;
          end;
          if size <= 1 then
            align := 0
          else if size = 2 then
            align := 1
          else if size <= 4 then
            align := 2
          else
            align := 3;
          end;
        otherwise
          bug_check('RA_$ALLOCATE_STACK_FRAME -- unknown object type%$');
      end;
      if size > room then
        goto 10;
      if not ((level = align) and (size <= max)) then begin
        if size > max then
          goto 10;
        if level <= align then
          goto 10;
        if size <= half then
          goto 10;
      end;
      if obj^.kind = var_name then begin
        obj^.flags := obj^.flags + [18];
        obj^.offset := off;
      end
      else if (fs^.f11.class = 5) or (fs^.ring = nil) then begin
        fs^.flags := fs^.flags + [18];
        fs^.offset := off;
      end
      else begin
        p := fs;
        repeat
          p^.flags := p^.flags + [18];
          p^.offset := p^.offset - low + off;
          p := p^.ring;
        until p = fs;
      end;
      off := off + size;
      ra_rtn_ptr_t(rtn)^.frame_size := off;
      if level = 3 then
        rtn^.f226.quad_aligned := true;
      room := room - size;
      if room = 0 then
        return;
      if lshft(size, 32 - level) <> 0 then
        for k := 0 to level - 1 do begin
          m := lshft(1, k);
          if (off & m) <> 0 then begin
            off := off + m;
            room := room - m;
            ra_rtn_ptr_t(rtn)^.frame_size := off;
            if room = 0 then
              return;
          end;
        end;
10:
      obj := next;
    end;
    level := level - 1;
  end;
end;

{ ra_$db_was_referenced - whether any operand of lr (the DB register's
  live range) reads it outside the RETURN (a move of it to a register
  the RETURN alone reads counts as the RETURN's); traced at level 2.

  0x267B4C, 0xD6 bytes, internal: each reader's instruction computed
  inline (pattern 121), the move's opcode 75 and number 1 tested before
  following its operand 2's link when that is the only reader. }

function ra_$db_was_referenced(
    lr: ra_lr_ptr_t): boolean; options(val_param); internal;
var
  lts: ra_lts_ptr_t;
  op, o2: opnd_ptr_t;
  i: instr_ptr_t;
begin
  lts := lr^.ltss;
  while lts <> nil do begin
    op := lts^.refs;
    while op <> nil do begin
      if not op^.h.write then begin
        i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
        if (i^.opc = ord(opc$move)) and (op^.h.num = 1) then begin
          o2 := i^.opnds[2].link;
          if o2 <> nil then
            if o2^.link = nil then
              i := instr_ptr_t(integer32(o2) - 32 - 12 * o2^.h.num);
        end;
        if i^.opc <> ord(opc$return) then begin
          if ra_650 > 1 then
            vfmt_$write('DB is referenced.%.');
          ra_$db_was_referenced := true;
          return;
        end;
      end;
      op := op^.link;
    end;
    lts := lts^.next;
  end;
  if ra_650 > 1 then
    vfmt_$write('DB never referenced.%.');
  ra_$db_was_referenced := false;
end;

{ init_complex - a serial number for the complex live range of lts, if
  it has none.  0x267C4C, 0x26 bytes, internal, no frame. }

procedure init_complex(
    lts: ra_lts_ptr_t); options(val_param); internal;
var
  lr: ra_lr_ptr_t;
begin
  if lts <> nil then begin
    lr := lts^.lr;
    if (lr^.id <> 0) and (lr^.serial = 0) then begin
      ra_serial := ra_serial + 1;
      lr^.serial := ra_serial;
    end;
  end;
end;

{ ra_$initialize_routine - a pass's start: the physical registers' live
  ranges of the class initialized, the clobber and use sets cleared (in
  the last, integer, pass the stack frame's objects taken off their list
  and the uplevel-referenced variables, rtn +12, put on it); the bit
  vectors made (seven a block, availability on any path); each block
  initialized (its exposed and final lists emptied) with the debug
  level of its own (at_backend_switches, ra_650; dmp's block header at
  level 2); the simple-definition count rounded up (+ 81, to 32); in the
  pair pass the mates of the live ranges met initialized too; serial
  numbers for the physical registers' live ranges and the zero, DB and
  memory segments' (lir_main_c48 .. c54).  With ra_check_db, whether the
  routine needs the DB register: the conventions' DB register when it
  names an ip_reg_like operand's register, else any reference to it
  (ra_$db_was_referenced), or an asynchronous return; a needed DB
  register the conventions preserve is never spilled, nor the argument
  pointer.  A rematerializable live range's reload cost moves into its
  spill cost.  In the last pass the frame is laid out (the argument
  pointer's and +112's objects placed first when the routine needs a
  frame; a frame of more than 24 bytes needs one), and with a frame the
  RETURN's argument pointer read is dropped (operand$none) when nothing
  else in the RETURN's block reads it, its life moved to the ENTRY's
  block.  Finally the complex lifetimes are narrowed and the
  availability vectors released.

  0x267C72, 0x53E bytes, internal: the class's title from ra_titles at
  A5 - 20 + 20 * class (`pea (-0x14,A5,D0.w)'); the floating physical
  live ranges 64 (lir_3f90, 0x48B110), the integer ones 30 for
  initialization and 32 for numbering (lir_4090, 0x48B210); the unknown
  object's bug check does not leave its loop. }

procedure ra_$initialize_routine(
    rtn: rtn_ptr_t); options(val_param); internal;
label
  20;
var
  phys: ra_phys_ptr_t;
  k: integer;
  v: ra_var_ptr_t;
  bb: bb_ptr_t;
  lr, m, ap: ra_lr_ptr_t;
  conv: call_conv_$ptr_t;
  ret, i: instr_ptr_t;
begin
  if dmp_3c2.level > 1 then begin
    vfmt_$write('%/%/TRACE OF RA_$INITIALIZE_ROUTINE -- %$');
    vfmt_$write(ra_titles[ra_class]);
  end;
  if not ra_final then begin
    phys := univ_ptr(addr(lir_3f90));
    for k := 0 to 63 do
      ra_$initialize_lr(phys^[k], true, true);
    ra_fp_used.hi := [];
    ra_fp_used.lo := [];
    ra_fp_clobbered.hi := [];
    ra_fp_clobbered.lo := [];
    rtn^.written_fp[0] := 0;
    rtn^.written_fp[1] := 0;
  end
  else begin
    phys := univ_ptr(addr(lir_4090));
    for k := 0 to 29 do
      ra_$initialize_lr(phys^[k], true, true);
    ra_ip_used := [];
    ra_ip_clobbered := [];
    rtn^.written_ip := 0;
    ra_ip_like := [];
    v := ra_frame_objs;
    while v <> nil do
      case v^.kind of
        var_name: begin
          v^.flags := v^.flags - [18, 27];
          v := v^.next;
          end;
        fortran_symbol: begin
          ra_fsym_ptr_t(v)^.flags := ra_fsym_ptr_t(v)^.flags - [18, 27];
          v := ra_fsym_ptr_t(v)^.next;
          end;
        otherwise
          bug_check('RA_$INITIALIZE_ROUTINE -- unknown object%$');
      end;
    v := ra_var_ptr_t(rtn^.l12);
    ra_frame_objs := v;
    while v <> nil do
      case v^.kind of
        var_name: begin
          v^.flags := v^.flags - [18] + [27];
          v := v^.next;
          end;
        fortran_symbol: begin
          ra_fsym_ptr_t(v)^.flags := ra_fsym_ptr_t(v)^.flags - [18] + [27];
          v := ra_fsym_ptr_t(v)^.next;
          end;
        otherwise
          bug_check('RA_$INITIALIZE_ROUTINE -- unknown object%$');
      end;
  end;
  bv_$initialize_bit_vectors(rtn, rtn^.l192 + 1, 7, true);
  ra_serial := 0;
  ra_max_simple := 0;
  ra_lrs := nil;
  bb := rtn^.bbs;
  while bb <> nil do begin
    ra_650 := at_backend_switches.level;
    if ra_650 > 1 then
      dmp_$starting_basic_block(bb);
    bb^.exposed := nil;
    bb^.finals := nil;
    ra_$initialize_basic_block(bb);
    bb := bb^.next;
  end;
  ra_max_simple := (ra_max_simple + 81) & (~31);
  if ra_class = ra_pair then begin
    lr := ra_lrs;
    while lr <> nil do begin
      m := lr^.mate;
      if m <> nil then
        if not (rrp$ra_marked in m^.rrp) then begin
          ra_$initialize_lr(m, rrp$life_mark in lr^.rrp, true);
          m^.rrp := m^.rrp + [rrp$ra_marked];
          m^.next := ra_lrs;
          ra_lrs := m;
          if m^.id <> 0 then begin
            ra_serial := ra_serial + 1;
            m^.serial := ra_serial;
          end;
        end;
      lr := lr^.next;
    end;
  end;
  if not ra_final then begin
    phys := univ_ptr(addr(lir_3f90));
    for k := 0 to 63 do begin
      lr := phys^[k];
      if (lr^.id <> 0) and (lr^.serial = 0) then begin
        ra_serial := ra_serial + 1;
        lr^.serial := ra_serial;
      end;
    end;
    init_complex(ra_lts_ptr_t(lir_main_c50));
    init_complex(ra_lts_ptr_t(lir_main_c54));
  end
  else begin
    phys := univ_ptr(addr(lir_4090));
    for k := 0 to 31 do begin
      lr := phys^[k];
      if (lr^.id <> 0) and (lr^.serial = 0) then begin
        ra_serial := ra_serial + 1;
        lr^.serial := ra_serial;
      end;
    end;
    init_complex(ra_lts_ptr_t(lir_main_c48));
    init_complex(ra_lts_ptr_t(lir_main_c4c));
  end;
  conv := ra_rtn_ptr_t(rtn)^.conv;
  if ra_check_db then begin
    if (conv^.w16 = conv^.w18) and
       ((conv^.w18 & 31) in bv_word_t(conv^.ip76)) then
      ra_db_used := (conv^.w18 & 31) in ra_ip_like
    else
      ra_db_used := ra_$db_was_referenced(ra_lr_ptr_t(rtn^.db_lr));
    rtn^.f226.needs_db := rtn^.f226.asynchronous_return or ra_db_used;
  end;
  if rtn^.f226.needs_db then
    if bv_word_t(conv^.ip_preserved) - ra_ip_clobbered <> [] then
      rtn^.db_lr^.rrp := rtn^.db_lr^.rrp + [rrp$life_mark];
  rtn^.ap_lr^.rrp := rtn^.ap_lr^.rrp + [rrp$life_mark];
  lr := ra_lrs;
  while lr <> nil do begin
    if ra_utils_$rematerialize(rtn, lr_ptr_t(lr), false) <> nil then
      lr^.cost.r := lr^.cost.r + lr^.x44.r;
    lr^.x44.r := 0.0;
    lr := lr^.next;
  end;
  if ra_final then begin
    ra_check_db := false;
    if rtn^.f226.needs_frame then begin
      v := ra_var_ptr_t(rtn^.ap_lr^.node20);
      if v^.kind = var_name then
        v^.flags := v^.flags + [18]
      else
        ra_fsym_ptr_t(v)^.flags := ra_fsym_ptr_t(v)^.flags + [18];
      v := ra_var_ptr_t(lr_ptr_t(rtn^.l112)^.node20);
      if v^.kind = var_name then
        v^.flags := v^.flags + [18]
      else
        ra_fsym_ptr_t(v)^.flags := ra_fsym_ptr_t(v)^.flags + [18];
    end;
    ra_rtn_ptr_t(rtn)^.frame_size := 0;
    ra_$allocate_stack_frame(rtn, 3, 16#7FFFFFFF);
    if ra_rtn_ptr_t(rtn)^.frame_size > 24 then
      rtn^.f226.needs_frame := true;
    ap := ra_lr_ptr_t(rtn^.ap_lr);
    if rtn^.f226.needs_frame and not rtn^.f226.no_return_block and
       (rrp$read in ap^.rrp) then begin
      ret := rtn^.return_instr;
      if ret^.opnds[3].h.kind <> operand$none then
        if ra_lts_ptr_t(ret^.opnds[3].lts)^.lr <> ap then
          if not ap^.f2.spilled then
            bug_check('RA_$INITIALIZE_ROUTINE -- AP operand in RETURN not in expected position%$');
      ret^.opnds[3].h.kind := operand$none;
      i := ra_return_bb^.first;
      while i <> nil do begin
        if i^.opc = ord(opc$return) then
          exit;
        for k := i^.h.nopnds downto 1 do
          if i^.opnds[k].h.kind = operand$ip_reg then
            if ra_lts_ptr_t(i^.opnds[k].lts)^.lr = ap then
              goto 20;
        i := i^.next;
      end;
      bv_$clear(ra_return_bb^.live_gen, lr_ptr_t(ap));
      bv_$set(ra_entry_bb^.live_in, lr_ptr_t(ap));
20:
      if ra_650 > 1 then
        vfmt_$write('AP separated from caller''s SF: read in RETURN converted to operand$none.%.');
    end;
  end;
  ra_utils_$compute_complex_lifetimes(rtn);
  bv_$release_availability_bit_vectors(rtn);
end;

{ ra_$calc_canonical_desc_bit - the bit of the pair (a, b) in a
  triangular matrix: with hi the larger and lo the smaller index,
  (hi - 2) * (hi - 1) div 2 + lo - 1; equal indices or a 0 are a bug.

  0x268298, 0x5E bytes, internal: the swap in registers; the product by
  m$mis$lll, its halving rounded toward zero (`bpl; addq #1; asr #1'). }

function ra_$calc_canonical_desc_bit(
    a: integer32;
    b: integer32): integer32; options(val_param); internal;
var
  t, bit: integer32;
begin
  if a > b then begin
    t := a;
    a := b;
    b := t;
  end;
  bit := ((b - 2) * (b - 1)) div 2 + (a - 1);
  if (b = a) or (a = 0) then
    bug_check('RA_$CALC_CANONICAL_DESC_BIT: indices may not be equal or 0.%$');
  ra_$calc_canonical_desc_bit := bit;
end;

{ ra_$init_descriptor - a conflict bit matrix of rows by cols: an
  ordinary one keeps its rows (bits a column) and the longwords a column
  takes (rows div 32 + 1, cols + 1 columns); a reflexive (triangular)
  one, rows = cols, the bits of the last pair rounded up to longwords
  (one longword for a single row).  The vector from the heap.

  0x268334, 0xC8 bytes, internal: rows div 32 rounded toward zero
  (`bpl; addi #31; asr #5'); the size passed by address (-8). }

procedure ra_$init_descriptor(
    var desc: ra_desc_t;
    rows: integer32;
    cols: integer32;
    reflexive: boolean); options(val_param); internal;
var
  bytes: integer32;
begin
  if not reflexive then begin
    desc.bits := rows;
    desc.words := rshft(rows, 5);
    desc.size := (cols + 1) * (rows div 32 + 1);
  end
  else begin
    if rows <> cols then
      bug_check('RA_$INIT_DESCRIPTOR: reflexive descriptors need identical dimensions%$');
    desc.bits := 0;
    desc.words := 0;
    if rows > 1 then
      desc.size := (ra_$calc_canonical_desc_bit(rows - 1, rows) + 32) div 32
    else
      desc.size := 1;
  end;
  bytes := desc.size * 4;
  desc.vec := rws_$alloc_heap(bytes);
  if desc.vec = nil then
    bug_check('RA_$INIT_DESCRIPTOR -- failed (no disk space?)%$');
end;

{ ra_$new_simple_id - the next simple live range's index (its row of
  the complex x simple matrix cleared): 32767 of them is the error
  "basic block too complex" (cgerr_no_source 24), more than
  ra_max_simple a bug.

  0x268474, 0x6C bytes, internal: the row (ra_cs.words longwords at
  the cursor ra_cs.cursor) cleared by a counted loop. }

function ra_$new_simple_id: integer32; internal;
var
  p: ra_longs_ptr_t;
  k, n: integer32;
begin
  if ra_simple_ids = 32767 then
    cgerr_no_source(24, integer32(idntk(id_ob, 'basic block too complex', 23)))
  else if ra_simple_ids >= ra_max_simple then
    bug_check('RA_$NEW_SIMPLE_ID -- no cornucopia found here%$');
  p := ra_cs.cursor;
  n := ra_cs.words;
  k := 0;
  while n > 0 do begin
    k := k + 1;
    p^[k] := 0;
    n := n - 1;
  end;
  ra_cs.cursor := univ_ptr(integer32(p) + 4 * k);
  ra_simple_ids := ra_simple_ids + 1;
  ra_$new_simple_id := ra_simple_ids;
end;

{ ra_$lrs_already_conflict - whether a and b need no conflict entered
  (the same live range, different register files, a reserved register
  assigned to either, both assigned) or have one already; otherwise
  their conflict bit is tested, and set with set.  which is the matrix
  (0 simple x simple, 1 complex x simple, 2 complex x complex) and the
  heap index for their records; a simple live range gets its index in
  this block (+58, +40 the block's marker ra_bb_mark) the first time.

  0x268528, 0x220 bytes, internal: which by address (18); each
  register's bit `and.w #31' then the compiler's range check (`cmp.w;
  bcs'), a floating register's half by `cmpi.l #31'; the matrix bit's
  byte and mask from ra_masks (+0x590). }

function ra_$lrs_already_conflict(
    a: ra_lr_ptr_t;
    b: ra_lr_ptr_t;
    set_it: boolean;
    var which: integer): boolean; options(val_param); internal;
label
  10;
var
  r, k, bit: integer32;
  vec: ra_bytes_ptr_t;
  m: integer;
begin
  if a = b then
    goto 10;
  if a^.rrp * b^.rrp * [rrp$fp_reg, rrp$ip_reg] = [] then
    goto 10;
  if a^.f2.physical_register then begin
    r := a^.f2.physical_register_number;
    if rrp$ip_reg in a^.rrp then begin
      if (r mod 32) in ra_ip_reserved then
        goto 10;
    end
    else if r <= 31 then begin
      if (r mod 32) in ra_fp_reserved.lo then
        goto 10;
    end
    else if (r mod 32) in ra_fp_reserved.hi then
      goto 10;
  end;
  if b^.f2.physical_register then begin
    r := b^.f2.physical_register_number;
    if rrp$ip_reg in b^.rrp then begin
      if (r mod 32) in ra_ip_reserved then
        goto 10;
    end
    else if r <= 31 then begin
      if (r mod 32) in ra_fp_reserved.lo then
        goto 10;
    end
    else if (r mod 32) in ra_fp_reserved.hi then
      goto 10;
  end;
  if a^.f2.physical_register and b^.f2.physical_register then
    goto 10;
  k := 0;
  if a^.id <> 0 then
    k := 1
  else if (a^.serial = 0) or (a^.bb40 <> ra_bb_mark) then begin
    a^.serial := ra_$new_simple_id;
    a^.bb40 := ra_bb_mark;
  end;
  if b^.id <> 0 then
    k := k + 2
  else if (b^.serial = 0) or (b^.bb40 <> ra_bb_mark) then begin
    b^.serial := ra_$new_simple_id;
    b^.bb40 := ra_bb_mark;
  end;
  case k of
    0: begin
      which := 0;
      bit := ra_$calc_canonical_desc_bit(a^.serial, b^.serial);
      vec := ra_ss.vec;
      end;
    1: begin
      which := 1;
      bit := b^.serial * ra_cs.bits + a^.serial;
      vec := ra_cs.vec;
      end;
    2: begin
      which := 1;
      bit := a^.serial * ra_cs.bits + b^.serial;
      vec := ra_cs.vec;
      end;
    otherwise begin
      which := 2;
      bit := ra_$calc_canonical_desc_bit(a^.serial, b^.serial);
      vec := ra_cc.vec;
      end;
  end;
  m := ord(ra_masks[bit & 7]);
  if (ord(vec^[rshft(bit, 3)]) & m) <> 0 then
    goto 10;
  if set_it then
    vec^[rshft(bit, 3)] := chr(ord(vec^[rshft(bit, 3)]) ! m);
  ra_$lrs_already_conflict := false;
  return;
10:
  ra_$lrs_already_conflict := true;
end;

{ ra_$lookup_a_p - the aversion/preference record of a and b at loop
  depth depth on a's list (+60: by depth, deepest first, then by the
  other live range's number, highest first), nil when there is none;
  prev the record before where it is or would go (nil: the head).

  0x268748, 0x96 bytes, internal: prev by address; A0. }

function ra_$lookup_a_p(
    a: ra_lr_ptr_t;
    b: ra_lr_ptr_t;
    depth: integer32;
    var prev: ra_ap_ptr_t): ra_ap_ptr_t; options(val_param); internal;
var
  p, nxt: ra_ap_ptr_t;
  other: ra_lr_ptr_t;
begin
  prev := nil;
  p := a^.aps;
  while p <> nil do begin
    if ord(p^.depth) <= depth then
      exit;
    prev := p;
    if p^.a = a then
      p := p^.next_a
    else
      p := p^.next_b;
  end;
  other := nil;
  while p <> nil do begin
    if ord(p^.depth) <> depth then
      exit;
    if p^.a = a then begin
      other := p^.b;
      nxt := p^.next_a;
    end
    else begin
      other := p^.a;
      nxt := p^.next_b;
    end;
    if other^.num <= b^.num then
      exit;
    prev := p;
    p := nxt;
  end;
  if other <> b then
    p := nil;
  ra_$lookup_a_p := p;
end;

{ ra_$enter_a_p - the aversion/preference record of a and b at depth
  (the complex one second), made from heap which's records and put on
  both lists in order when there is none (a record on only one list is
  a bug).

  0x2687DE, 0x10C bytes, internal: heap which a word; A0. }

function ra_$enter_a_p(
    a: ra_lr_ptr_t;
    b: ra_lr_ptr_t;
    depth: integer32;
    which: integer): ra_ap_ptr_t; options(val_param); internal;
var
  t: ra_lr_ptr_t;
  r, pa, pb: ra_ap_ptr_t;
begin
  if a^.id <> 0 then begin
    t := a;
    a := b;
    b := t;
  end;
  r := ra_$lookup_a_p(a, b, depth, pa);
  if r = nil then begin
    if ra_$lookup_a_p(b, a, depth, pb) <> nil then
      bug_check('RA_$ENTER_A_P:  Aversion/preference relationship not reflexive for LRs %3ZWD and %3ZWD%$',
          a^.num, b^.num);
    r := mrh_$alloc_fixed(ra_ap_heaps[which]);
    r^.a := a;
    r^.b := b;
    r^.closure := nil;
    r^.avoid := 0;
    r^.pref := 0;
    r^.depth := chr(depth);
    if pa = nil then begin
      r^.next_a := a^.aps;
      a^.aps := r;
    end
    else if pa^.a = a then begin
      r^.next_a := pa^.next_a;
      pa^.next_a := r;
    end
    else begin
      r^.next_a := pa^.next_b;
      pa^.next_b := r;
    end;
    if pb = nil then begin
      r^.next_b := b^.aps;
      b^.aps := r;
    end
    else if pb^.a = b then begin
      r^.next_b := pb^.next_a;
      pb^.next_a := r;
    end
    else begin
      r^.next_b := pb^.next_b;
      pb^.next_b := r;
    end;
  end;
  ra_$enter_a_p := r;
end;

{ ra_$enter_preference - a register move's preference: its source and
  destination (their classes' parents) should share a register, by the
  move's delay plus one at the move's loop depth; a move between live
  ranges that conflict marks the destination's true_write instead.  A
  COPYD's operand count is set to 4, every other move's to 2.

  0x268944, 0x90 bytes, internal: the delay +58 bits 3..0 (operand 2's
  +2); which by address (-30). }

procedure ra_$enter_preference(
    i: instr_ptr_t); options(val_param); internal;
var
  delay: integer32;
  a, b: ra_lr_ptr_t;
  which: integer;
  r: ra_ap_ptr_t;
begin
  if i^.opc = ord(opc$copyd) then
    i^.h.nopnds := 4
  else
    i^.h.nopnds := 2;
  delay := i^.opnds[2].h.b2_3_0;
  a := get_lr_equivalence_class_parent(ra_lts_ptr_t(i^.opnds[1].lts)^.lr);
  b := get_lr_equivalence_class_parent(ra_lts_ptr_t(i^.opnds[2].lts)^.lr);
  if ra_$lrs_already_conflict(a, b, false, which) then begin
    if a <> b then
      b^.rrp := b^.rrp + [rrp$true_write];
  end
  else begin
    r := ra_$enter_a_p(a, b, ord(i^.b41), which);
    r^.pref := r^.pref + (delay + 1);
  end;
end;

{ ra_$new_conflict - a conflict between a and b entered: a register
  assigned to one goes into the other's conflicting registers (+80 the
  floating 32..63, +84 the rest), each counts one more conflict (+56;
  the most kept in ra_max_conflicts), and between two unassigned live
  ranges a record from heap which goes on both lists (+44).

  0x2689D4, 0x11C bytes, internal: each register's bit `and.w #31',
  its half by `cmpi.b #31' (bhi). }

procedure ra_$new_conflict(
    a: ra_lr_ptr_t;
    b: ra_lr_ptr_t); options(val_param); internal;
var
  which: integer;
  c: ra_conf_ptr_t;
begin
  if not ra_$lrs_already_conflict(a, b, true, which) then begin
    if a^.f2.physical_register then
      if a^.f2.physical_register_number <= 31 then
        b^.avoid_lo := b^.avoid_lo + [a^.f2.physical_register_number mod 32]
      else
        b^.avoid_hi := b^.avoid_hi + [a^.f2.physical_register_number mod 32];
    a^.w56 := a^.w56 + 1;
    if a^.w56 > ra_max_conflicts then
      ra_max_conflicts := a^.w56;
    if b^.f2.physical_register then
      if b^.f2.physical_register_number <= 31 then
        a^.avoid_lo := a^.avoid_lo + [b^.f2.physical_register_number mod 32]
      else
        a^.avoid_hi := a^.avoid_hi + [b^.f2.physical_register_number mod 32];
    b^.w56 := b^.w56 + 1;
    if b^.w56 > ra_max_conflicts then
      ra_max_conflicts := b^.w56;
    if not (a^.f2.physical_register or b^.f2.physical_register) then begin
      c := mrh_$alloc_fixed(ra_conf_heaps[which]);
      c^.a := a;
      c^.next_a := a^.x44.conf;
      a^.x44.conf := c;
      c^.b := b;
      c^.f12.next_b := b^.x44.conf;
      b^.x44.conf := c;
    end;
  end;
end;

{ ra_$enter_conflicts - the live range op writes conflicts with every
  live range on the live list (live, a circular list through +52 from
  its head) but the class parent of lr (the move's source, for a move)
  and those sharing its home live range when it holds a unique value.

  0x268AF0, 0x76 bytes, internal: the home -1 when there is none. }

procedure ra_$enter_conflicts(
    op: opnd_ptr_t;
    lr: ra_lr_ptr_t;
    live: ra_lr_ptr_t); options(val_param); internal;
var
  src, dst, p, q: ra_lr_ptr_t;
  home: integer32;
begin
  src := get_lr_equivalence_class_parent(lr);
  dst := get_lr_equivalence_class_parent(ra_lts_ptr_t(op^.lts)^.lr);
  home := integer32(dst^.home_lr);
  if (home = 0) or not (rrp$unique_value in dst^.rrp) then
    home := -1;
  q := live^.x52.lr;
  while q <> live do begin
    p := get_lr_equivalence_class_parent(q);
    if p <> src then
      if integer32(q^.home_lr) <> home then
        ra_$new_conflict(dst, p);
    q := q^.x52.lr;
  end;
end;

{ ra_$enter_architectural_conflict - op's live range may not share lr's
  register (their class parents conflict).  0x268B66, 0x32 bytes,
  internal. }

procedure ra_$enter_architectural_conflict(
    op: opnd_ptr_t;
    lr: ra_lr_ptr_t); options(val_param); internal;
begin
  ra_$new_conflict(get_lr_equivalence_class_parent(ra_lts_ptr_t(op^.lts)^.lr),
      get_lr_equivalence_class_parent(lr));
end;

{ process_call_or_svc_clobbers - every unassigned live range on the live
  list conflicts with the n physical registers' live ranges in regs.

  0x268B98, 0x64 bytes, internal: the inner loop `dbf' with the
  longword count's high word (`clr.w; subq.l #1; bcc'). }

procedure process_call_or_svc_clobbers(
    live: ra_lr_ptr_t;
    in regs: ra_phys_t;
    n: integer32); options(val_param); internal;
var
  q, p: ra_lr_ptr_t;
  k: integer32;
begin
  q := live^.x52.lr;
  while q <> live do begin
    if not q^.f2.physical_register then begin
      p := get_lr_equivalence_class_parent(q);
      for k := 0 to n - 1 do
        ra_$new_conflict(p, regs[k]);
    end;
    q := q^.x52.lr;
  end;
end;

{ ra_$call_or_svc_ip_clobbers - the integer registers 0..29 in the
  clobbered set s, counted; unless ra_no_clobbers, the live list
  conflicts with their live ranges (lir_4090).

  0x268BFC, 0x64 bytes, internal: the registers' live ranges collected
  in a frame array (-264); the count in D0. }

function ra_$call_or_svc_ip_clobbers(
    s: bv_word_t;
    live: ra_lr_ptr_t): integer32; options(val_param); internal;
var
  count, n, r: integer32;
  phys: ra_phys_ptr_t;
  regs: ra_phys_t;
begin
  count := 0;
  n := 0;
  phys := univ_ptr(addr(lir_4090));
  for r := 0 to 29 do
    if (r mod 32) in s then begin
      regs[n] := phys^[r];
      count := count + 1;
      n := n + 1;
    end;
  if not ra_no_clobbers then
    process_call_or_svc_clobbers(live, regs, n);
  ra_$call_or_svc_ip_clobbers := count;
end;

{ ra_$call_or_svc_fp_clobbers - the floating registers in the clobbered
  sets lo (F0..F31) and hi (F32..F63), counted (by pairs in the pair
  class, a whole pair counting two); unless ra_no_clobbers, the live
  list conflicts with their live ranges (lir_3f90; a pair's even half).

  0x268C60, 0xD4 bytes, internal: the step (-268) and mask (-272) 2
  and 3 for pairs, 1 and 1 otherwise; the count in D0. }

function ra_$call_or_svc_fp_clobbers(
    lo: integer32;
    hi: integer32;
    live: ra_lr_ptr_t): integer32; options(val_param); internal;
var
  count, n, r, m, b, step, mask: integer32;
  phys: ra_phys_ptr_t;
  regs: ra_phys_t;
begin
  if ra_class = ra_pair then begin
    step := 2;
    mask := 3;
  end
  else begin
    step := 1;
    mask := 1;
  end;
  count := 0;
  n := 0;
  r := 0;
  m := mask;
  phys := univ_ptr(addr(lir_3f90));
  repeat
    b := m & lo;
    if b <> 0 then begin
      regs[n] := phys^[r];
      if b = 3 then
        count := count + 2
      else
        count := count + 1;
      n := n + 1;
    end;
    m := lshft(m, step);
    r := r + step;
  until r = 32;
  m := mask;
  repeat
    b := m & hi;
    if b <> 0 then begin
      regs[n] := phys^[r];
      if b = 3 then
        count := count + 2
      else
        count := count + 1;
      n := n + 1;
    end;
    m := lshft(m, step);
    r := r + step;
  until r = 64;
  if not ra_no_clobbers then
    process_call_or_svc_clobbers(live, regs, n);
  ra_$call_or_svc_fp_clobbers := count;
end;

{ ra_$advance_one_clock_tick - the protection pipe moves one slot: the
  live ranges whose protection ends now (slot 1) lose it (+10 bit 6),
  the other slots move down.  Traced at level 3.

  0x268D34, 0xB0 bytes, internal: the slots at A5 + 0x40 + 4k (k from
  1); the move a `dbf' over the longword count. }

procedure ra_$advance_one_clock_tick; internal;
var
  lr: ra_lr_ptr_t;
  name: dmp_$lr_name_t;
  k: integer32;
begin
  ra_clock := ra_clock + 1;
  if ra_650 > 2 then
    vfmt_$write('## clock tick %LD%.', ra_clock);
  if ra_pipe_len > 0 then begin
    ra_pipe_len := ra_pipe_len - 1;
    lr := ra_pipe[1];
    while lr <> nil do begin
      if ra_650 > 2 then begin
        name := dmp_$three_char_lr_name_from_lr(lr_ptr_t(lr));
        vfmt_$write(' - dropping protection on LR %M4A%.', name);
      end;
      lr^.f8.protected := false;
      lr := lr^.x52.lr;
    end;
    for k := 1 to ra_pipe_len do
      ra_pipe[k] := ra_pipe[k + 1];
    ra_pipe[ra_pipe_len + 1] := nil;
  end;
end;

{ ra_$unlink_protected_lr - lr taken out of the protection pipe (its
  slot's list: +48 the previous, +52 the next; a slot's head found by
  searching the slots).  Traced at level 2 with the ticks it had left.

  0x268E1C, 0xC2 bytes, internal: the search from the last slot down;
  after the bug check (no return) the code runs on with slot 0. }

procedure ra_$unlink_protected_lr(
    lr: ra_lr_ptr_t); options(val_param); internal;
var
  k: integer32;
  ticks: integer32;
  name: dmp_$lr_name_t;
begin
  lr^.f8.protected := false;
  if lr^.prev = nil then begin
    k := ra_pipe_len;
    while k > 0 do begin
      if ra_pipe[k] = lr then
        exit;
      k := k - 1;
    end;
    if k <= 0 then
      bug_check('RA_$UNLINK_PROTECTED_LR -- could not find protected LR in array%$');
    ra_pipe[k] := lr^.x52.lr;
    if lr^.x52.lr <> nil then
      lr^.x52.lr^.prev := nil;
  end
  else if lr^.x52.lr = nil then
    lr^.prev^.x52.lr := nil
  else begin
    lr^.prev^.x52.lr := lr^.x52.lr;
    lr^.x52.lr^.prev := lr^.prev;
  end;
  if ra_650 > 1 then begin
    ticks := lr^.expires - ra_clock;
    name := dmp_$three_char_lr_name_from_lr(lr_ptr_t(lr));
    vfmt_$write('-- unlinking protected LR %M4A (%LD ticks before end of pipe)%.',
        name, ticks);
  end;
end;

{ ra_$protect_lr_for_n_ticks - lr put in slot n of the protection pipe
  (out of its old slot first), protected (+10 bit 6) until the clock
  reaches now + n (+64).  Traced at level 3.

  0x268F60, 0x8C bytes, internal. }

procedure ra_$protect_lr_for_n_ticks(
    lr: ra_lr_ptr_t;
    n: integer32); options(val_param); internal;
var
  h: ra_lr_ptr_t;
  name: dmp_$lr_name_t;
begin
  if lr^.f8.protected then
    ra_$unlink_protected_lr(lr);
  if n > ra_pipe_len then
    ra_pipe_len := n;
  h := ra_pipe[n];
  if h <> nil then
    h^.prev := lr;
  lr^.x52.lr := h;
  lr^.prev := nil;
  ra_pipe[n] := lr;
  lr^.f8.protected := true;
  lr^.expires := n + ra_clock;
  if ra_650 > 2 then begin
    name := dmp_$three_char_lr_name_from_lr(lr_ptr_t(lr));
    vfmt_$write(' - protecting LR %M4A until clock = %LD%.', name, lr^.expires);
  end;
end;

{ ra_$drop_if_now_dead - lr leaves the live list at instruction num when
  lts (its segment, operand op of instr) was last referred to there:
  not while the segment is the last of a complex live range in the
  block and live out of it (ra_live_out), nor at a modify of a consumed
  value; a simple segment whose readers are all at its definition's
  instruction (its block's last or a late one: +34 against ra_bb_last,
  ra_bb_late) gets life_mark.  The live range's +68 accumulates the
  instructions it was live (num - +64) times weight; the segment goes on
  the live range's dead list (+76, chained at +40); a simple live range
  all of whose segments have life_mark gets it.  kind is the ticks to
  protect it for: 4 after a floating operation, 2 after a store's
  operand 1 (STOREB, STOREW, STOREL); 0 otherwise or with
  ra_no_clobbers.  Sets ra_dropped.

  0x269016, 0x1D6 bytes, internal: weight a single by value; the time
  live through fpp_$ (0x005C, 0x0024, 0x0000); the floating classes as
  the mask 0x20108; kind by address. }

function ra_$drop_if_now_dead(
    num: integer32;
    instr: instr_ptr_t;
    lr: ra_lr_ptr_t;
    lts: ra_lts_ptr_t;
    op: opnd_ptr_t;
    weight: ra_real_t;
    var kind: integer32): boolean; options(val_param); internal;
label
  10;
var
  t: ra_real_t;
  n: integer;
  o: opnd_ptr_t;
  s: ra_lts_ptr_t;
  all: boolean;
  k: integer32;
begin
  kind := 0;
  ra_$drop_if_now_dead := false;
  if lts^.num <> num then
    return;
  if not lr^.f2.live then
    return;
  if lr^.id <> 0 then
    if lts^.f2.first_in_bb then
      if bv_$test(ra_live_out, lr_ptr_t(lr)) then
        return;
  if lr^.id = 0 then
    if (lts^.w34 = ra_bb_last) or (lts^.w34 >= ra_bb_late) then begin
      n := lts^.num;
      o := lts^.refs;
      while o <> nil do begin
        if o^.h.read then
          if utils_ins_$operands_instruction(o)^.num <> n then
            goto 10;
        o := o^.link;
      end;
      lts^.rrp := lts^.rrp + [rrp$life_mark];
    end;
10:
  if op <> nil then
    if op^.h.modify and not op^.h.unconsumed then
      return;
  lr^.prev^.x52.lr := lr^.x52.lr;
  lr^.x52.lr^.prev := lr^.prev;
  lr^.f2.live := false;
  t.r := lr^.live_time.r + (num - lr^.expires) * weight.r;
  lr^.live_time := t;
  lts^.last_ref := opnd_ptr_t(lr^.dead);
  lr^.dead := lts;
  if ra_650 > 1 then
    vfmt_$write('      Dropping:      LR %3ZWD%.', lr^.num);
  if lr^.id = 0 then begin
    all := true;
    s := lr^.ltss;
    while s <> nil do begin
      if not (rrp$life_mark in s^.rrp) then begin
        all := false;
        exit;
      end;
      s := s^.next;
    end;
    if all then
      lr^.rrp := lr^.rrp + [rrp$life_mark];
  end;
  if not ra_no_clobbers and (instr <> nil) then begin
    k := 0;
    if instruction_attributes[instr^.opc].class in
       [class$fp_double, class$immediate, class$fp_single] then
      k := 4
    else if op^.h.num = 1 then
      if (instr^.opc = ord(opc$storel)) or (instr^.opc = ord(opc$storeb)) or
         (instr^.opc = ord(opc$storew)) then
        k := 2;
    if k <> 0 then
      kind := k;
  end;
  ra_dropped := true;
  ra_$drop_if_now_dead := true;
end;

{ ra_$protected_final_lrs_this_bb - the live ranges bb's last
  instructions read (the last three, one in the last pass; a group
  counts as one) protected for as many ticks as remain: a simple one
  while count lasts (decremented), a complex one unless it is live in
  vec (the successor's live_in).

  0x26920C, 0xC8 bytes, internal: count by address; the walk backwards
  from bb's last instruction. }

procedure ra_$protected_final_lrs_this_bb(
    bb: bb_ptr_t;
    classes: ra_classes_t;
    vec: bv_ptr_t;
    var count: integer32); options(val_param); internal;
label
  10;
var
  ticks: integer32;
  i: instr_ptr_t;
  k: integer;
  op: opnd_ptr_t;
  lr: ra_lr_ptr_t;
begin
  if bb^.first <> nil then begin
    if ra_final then
      ticks := 1
    else
      ticks := 3;
    i := bb^.last;
    while i <> nil do begin
      for k := 1 to i^.h.nopnds do begin
        op := addr(i^.opnds[k]);
        if op^.h.read then
          if ra_$process_operand_on_this_pass(op, classes) then begin
            lr := ra_lts_ptr_t(op^.lts)^.lr;
            if lr^.id = 0 then begin
              if count = 0 then
                goto 10;
              count := count - 1;
            end
            else if bv_$test(vec, lr_ptr_t(lr)) then
              goto 10;
            ra_$protect_lr_for_n_ticks(lr, ticks);
          end;
10:
      end;
      i := i^.prev;
      if i = nil then
        exit;
      if not i^.h.grouped then begin
        ticks := ticks - 1;
        if ticks = 0 then
          exit;
      end;
    end;
  end;
end;

{ ra_$fill_protected_lr_pipe - the pipe at bb's entry: the final reads
  of its predecessors, those at bb's loop depth or deeper first, then
  the shallower ones (48 simple live ranges at most).

  0x2692D4, 0x8E bytes, internal: the count a frame longword (-8)
  passed by address. }

procedure ra_$fill_protected_lr_pipe(
    bb: bb_ptr_t;
    classes: ra_classes_t); options(val_param); internal;
var
  count: integer32;
  depth: integer32;
  e: fg_edge_ptr_t;
begin
  count := 48;
  depth := bb^.f.depth;
  e := bb^.preds;
  while e <> nil do begin
    if e^.source^.f.depth >= depth then
      ra_$protected_final_lrs_this_bb(e^.source, classes, bb^.live_in,
          count);
    e := e^.next_pred;
  end;
  e := bb^.preds;
  while e <> nil do begin
    if e^.source^.f.depth < depth then
      ra_$protected_final_lrs_this_bb(e^.source, classes, bb^.live_in,
          count);
    e := e^.next_pred;
  end;
end;

{ ra_$possible_aversions - lr (just written) and each live range still
  protected in slots n down to 1 of the pipe (same register file, not
  yet expired, not conflicting) may be kept apart: a pending aversion
  of the ticks left, on ra_pend_bb for two live ranges of which one is
  simple, on ra_pend_xx[depth] for two complex ones (the deepest depth
  kept).  Traced at level 3.

  0x269362, 0x174 bytes, internal: the slots' loop tested at its end
  (slot n is looked at even for n <= 0). }

procedure ra_$possible_aversions(
    lr: ra_lr_ptr_t;
    n: integer32;
    depth: integer32); options(val_param); internal;
var
  k, ticks: integer32;
  p: ra_lr_ptr_t;
  which: integer;
  r: ra_pend_ptr_t;
  name1, name2: dmp_$lr_name_t;
begin
  k := n;
  repeat
    p := ra_pipe[k];
    while p <> nil do begin
      if lr^.rrp * p^.rrp * [rrp$fp_reg, rrp$ip_reg] <> [] then
        if p^.expires >= ra_clock then
          if not ra_$lrs_already_conflict(lr, p, false, which) then begin
            if which <> 2 then begin
              if ra_650 > 2 then begin
                name1 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(p));
                name2 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(lr));
                ticks := p^.expires - ra_clock;
                vfmt_$write(' - possible %LD tick in-BB aversion between LR %M4A and LR %M4A%.',
                    ticks, name2, name1);
              end;
              r := mrh_$alloc_fixed(ra_pend_bb_heap);
              r^.next := ra_pend_bb;
              ra_pend_bb := r;
            end
            else begin
              if ra_650 > 2 then begin
                name1 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(p));
                name2 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(lr));
                ticks := p^.expires - ra_clock;
                vfmt_$write(' - possible %LD tick XX-depth %LD aversion between LR %M4A and LR %M4A%.',
                    ticks, depth, name2, name1);
              end;
              r := mrh_$alloc_fixed(ra_pend_xx_heap);
              r^.next := ra_pend_xx[depth];
              ra_pend_xx[depth] := r;
              if depth > ra_pend_depth then
                ra_pend_depth := depth;
            end;
            r^.a := lr;
            r^.b := p;
            r^.ticks := p^.expires - ra_clock;
          end;
      p := p^.x52.lr;
    end;
    k := k - 1;
  until k <= 0;
end;

{ ra_$create_true_aversions - the pending aversions on list made real:
  each pair that does not conflict gets its record at depth, its
  aversion (+20) increased by the ticks.  Traced at level 3.

  0x269560, 0xB2 bytes, internal. }

procedure ra_$create_true_aversions(
    list: ra_pend_ptr_t;
    depth: integer32); options(val_param); internal;
var
  which: integer;
  ap: ra_ap_ptr_t;
  name1, name2: dmp_$lr_name_t;
begin
  while list <> nil do begin
    if not ra_$lrs_already_conflict(list^.a, list^.b, false, which) then begin
      ap := ra_$enter_a_p(list^.a, list^.b, depth, which);
      ap^.avoid := ap^.avoid + list^.ticks;
      if ra_650 > 2 then begin
        name1 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(list^.b));
        name2 := dmp_$three_char_lr_name_from_lr(lr_ptr_t(list^.a));
        vfmt_$write(' - true %LD tick aversion between LR %M4A and LR %M4A (pref= %LD, avoid= %LD)%.',
            list^.ticks, name2, name1, ap^.pref, ap^.avoid);
      end;
    end;
    list := list^.next;
  end;
end;

{ ra_$release_rws_storage - p back to the heap (a bad status a bug
  check).  0x269662, 0x2C bytes, internal: p by address to
  rws_$release_heap. }

procedure ra_$release_rws_storage(
    p: univ_ptr); options(val_param); internal;
var
  status: status_$t;
begin
  if p <> nil then begin
    rws_$release_heap(p, status);
    ok_or_bug_check(status, 'RA_$RELEASE_RWS_STORAGE -- freeing data structure%$');
  end;
end;

{ RA_$BUILD_CONFLICT_GRAPH - the conflict graph and register pressure of
  the classes asked for.  Unless count_only, the three conflict matrices
  are made (complex x complex by the complex live ranges' serial
  numbers, complex x simple, simple x simple by the simple indices
  given in a block).  Each block is walked forwards from its live-in
  live ranges (those of this pass not written in it given a dummy
  register: the zero register, F1) with a live list (a circular list
  through +52/+48 from a header in the frame) and the protection pipe
  (its predecessors' final reads; a clock tick per instruction or group,
  more for the instruction's stall, +2 bits 3..0): a read drops its
  live range when it is the segment's last reference (and protects it
  for 4 ticks after a floating operation, 2 after a store's operand 1);
  a write conflicts with everything live (but a move's source), within
  a group with what the group reads and writes, then goes live (with
  possible aversions to live ranges still protected); a call's or SVC's
  clobbers conflict with everything live.  Moves become preferences
  (those between complex live ranges after the last block), pending
  aversions true aversions.  The registers written by assigned live
  ranges go into the block's and the routine's written sets (the ENTRY's
  into ra_ip_used/ra_fp_used).  Each instruction gets its live counts
  (+28..+31), each block its counts, lir_main_c88/c89 the routine's
  peaks.  Finally each live range's cost is divided by its weighted
  live time (when above 1.0), and a pair's never-spill marks made
  consistent.

  0x2696C2, 0x1000 bytes (A5): the frame holds the live list's header
  (-8280, a live range), the reads of an instruction (-8192, 12 bytes:
  live range, instruction, ticks; at most 256) and its writes (-5120, 20
  bytes: the operand copied, the instruction, the move's source),
  reached by cursors (-8480, -8476); the weight 8 to the depth (capped
  at 32) through fpp_$ (0x00A0 3.0, 0x007C, 0x0078 2.0, 0x0148); the
  live time's fpp_$ 0x005C 0x0024 0x0000; the cost's eslv 0x0050 1.0
  (`ble') and 0x0030; the ip class mask 0x9F1CE94 for possible
  aversions; the literal 12 for %ZA after the strings (pattern 116). }

procedure ra_$build_conflict_graph;
label
  20, 30;
type
  ra_read_t = record
    lr: ra_lr_ptr_t;                    { -8192 + 12n }
    instr: instr_ptr_t;
    kind: integer32;
  end;
  ra_write_t = record
    op: opnd_t;                         { -5120 + 20m }
    instr: instr_ptr_t;
    src: ra_lr_ptr_t;
  end;
const
  no_aversion = [class$call, class$entry, class$enable, class$seq,
      class$synch, class$limit, class$trap, class$load_pair,
      class$load, class$svc, class$store, class$mfpr, class$mtpr,
      class$return, class$trap_cond];   { 0x9F1CE94 }
var
  ip, fp: boolean;
  bb: bb_ptr_t;
  bbx: ra_bb_ptr_t;
  num: integer32;
  nip, nfp: integer32;
  peak_ip, peak_fp, instr_ip, instr_fp: integer32;
  live_in: bv_ptr_t;
  lr, m, src, p: ra_lr_ptr_t;
  s: rrp$set_t;
  complex_moves, local_moves, call, i, instr0, mv: instr_ptr_t;
  nreads, nwrites, k, j, d, kind, stall, cs_rows, nbytes, n, g: integer32;
  continued: boolean;
  weight, t: ra_real_t;
  op: opnd_ptr_t;
  lts: ra_lts_ptr_t;
  reg: integer;
  bit: bv_word_t;
  conv: call_conv_$ptr_t;
  clob_ip, clob_hi, clob_lo: bv_word_t;
  pl: ra_pend_ptr_t;
  depth: integer32;
  mismatch: boolean;
  clob: ra_clob_ptr_t;
  hdr: ra_lr_ptr_t;
  live: ra_lr_t;
  reads: array [0..255] of ra_read_t;
  writes: array [0..255] of ra_write_t;
begin
  ra_no_clobbers := count_only;
  ip := ra_ip in classes;
  fp := classes * [ra_fp, ra_pair] <> [];
  if dmp_3c2.level > 1 then begin
    vfmt_$write('%/%/TRACE OF RA_$BUILD_CONFLICT_GRAPH -- %$');
    if fp and ip then
      vfmt_$write('%.')
    else
      vfmt_$write(ra_titles[ra_class]);
  end;
  if classes - [ra_ip .. ra_pair] <> [] then
    bug_check('RA_$BUILD_CONFLICT_GRAPH -- illegal operand kind requested%$');
  if fp and ip and not count_only then
    bug_check('RA_$BUILD_CONFLICT_GRAPH -- little brain fried%$');
  if not count_only then begin
    if ra_serial <> 0 then begin
      ra_$init_descriptor(ra_cc, ra_serial + 1, ra_serial + 1, true);
      for k := 1 to ra_cc.size do
        ra_longs_ptr_t(ra_cc.vec)^[k] := 0;
    end;
    cs_rows := (ra_serial + 32) & (~31);
    ra_$init_descriptor(ra_cs, cs_rows, ra_max_simple, false);
    ra_$init_descriptor(ra_ss, ra_max_simple, ra_max_simple, true);
    for k := 1 to ra_ss.size do
      ra_longs_ptr_t(ra_ss.vec)^[k] := 0;
  end;
  ra_max_conflicts := 0;
  complex_moves := nil;
  ra_clock := 10;
  ra_simple_ids := 0;
  lir_main_c88 := chr(0);
  lir_main_c89 := chr(0);
  ra_pend_bb := nil;
  ra_pend_depth := 0;
  ra_pipe_len := 0;
  zero(addr(ra_pipe), sizeof(ra_pipe));
  zero(addr(ra_pend_xx), sizeof(ra_pend_xx));
  zero(addr(writes), sizeof(writes));
  bb := rtn^.bbs;
  while bb <> nil do begin
    bbx := ra_bb_ptr_t(bb);
    ra_bb_mark := bb;
    ra_650 := at_backend_switches.level;
    if ra_650 > 1 then
      dmp_$starting_basic_block(bb);
    hdr := addr(live);
    hdr^.prev := hdr;
    hdr^.x52.lr := hdr;
    if bb^.first <> nil then
      num := bb^.first^.num
    else
      num := 0;
    nip := 0;
    nfp := 0;
    if not bb^.f.entry then begin
      live_in := bb^.live_in;
      lr := nil;
20:
      lr := ra_lr_ptr_t(bv_$find_next(rtn, live_in, lr_ptr_t(lr)));
      if lr <> nil then begin
        s := lr^.rrp;
        m := lr^.mate;
        if m <> nil then
          if ra_class = ra_pair then
            s := s + m^.rrp;
        if (lr = ra_lr_ptr_t(rtn^.l112)) and rtn^.f226.save_rpc then
          lr^.f2.live := true
        else if s * [rrp$modify, rrp$write] <> [] then begin
          if ra_650 > 1 then
            vfmt_$write('      Live on entry: LR %3ZWD%.', lr^.num);
          if rrp$ip_reg in s then
            nip := nip + 1
          else
            nfp := nfp + 1;
          hdr^.x52.lr^.prev := lr;
          lr^.x52.lr := hdr^.x52.lr;
          lr^.prev := hdr;
          hdr^.x52.lr := lr;
          lr^.f2.live := true;
          lr^.expires := num - 1;
        end
        else if not lr^.f2.physical_register then begin
          lr^.f2.physical_register := true;
          if rrp$ip_reg in lr^.rrp then
            lr^.f2.physical_register_number := ra_ip_zero
          else if m <> nil then begin
            m^.f2.physical_register := true;
            if rrp$fp_reg_odd_only in m^.rrp then
              m^.f2.physical_register_number := 1
            else
              lr^.f2.physical_register_number := 1;
          end;
        end;
        goto 20;
      end;
    end;
    if ip then begin
      bbx^.live_in_ip := chr(nip);
      bbx^.written_ip := [];
      if ra_650 > 1 then
        vfmt_$write('      IP regs on entry = %LD%/%.', ord(bbx^.live_in_ip));
    end;
    if fp then begin
      bbx^.live_in_fp := chr(nfp);
      bbx^.written_hi := [];
      bbx^.written_lo := [];
      if ra_650 > 1 then
        vfmt_$write('      FP regs on entry = %LD%/%.', ord(bbx^.live_in_fp));
    end;
    if not count_only then begin
      ra_cs.cursor := univ_ptr(integer32(ra_cs.vec) + ra_cs.words * 4);
      if ra_simple_ids > 1 then begin
        nbytes := (ra_$calc_canonical_desc_bit(ra_simple_ids - 1,
            ra_simple_ids) + 8) div 8;
        zero(ra_ss.vec, nbytes);
      end;
      ra_simple_ids := 0;
    end;
    ra_$fill_protected_lr_pipe(bb, classes);
    local_moves := nil;
    ra_dropped := false;
    ra_bb_last := 0;
    ra_bb_late := 0;
    call := nil;
    nreads := 0;
    nwrites := 0;
    peak_ip := nip;
    if not count_only and ip and bb^.f.asynchronous_return then begin
      bbx^.written_ip := bbx^.written_ip + [0..3];
      n := ra_$call_or_svc_ip_clobbers([0..3], hdr);
      if n > peak_ip then
        peak_ip := n;
    end;
    peak_fp := nfp;
    stall := 0;
    continued := false;
    ra_live_out := bb^.live_out;
    depth := bb^.f.depth;
    if depth > 32 then
      depth := 32;
    weight.r := 2.0 ** (depth * 3.0);
    i := bb^.first;
    while i <> nil do begin
      if not continued then begin
        while stall > 0 do begin
          if ra_650 > 2 then
            vfmt_$write('## stalling for dataflow latency...%.');
          ra_$advance_one_clock_tick;
          stall := stall - 1;
        end;
        ra_$advance_one_clock_tick;
        instr0 := i;
        instr_ip := nip;
        instr_fp := nfp;
      end;
      if ra_ihdr_ptr_t(i)^.stall > stall then
        stall := ra_ihdr_ptr_t(i)^.stall;
      if ra_650 > 1 then begin
        g := ord(i^.h.grouped);
        vfmt_$write('%4WD: %ZA   (continued = %D)%.', i^.num,
            instruction_mnemonic[i^.opc], 12, g);
      end;
      if instruction_attributes[i^.opc].class in [class$call, class$svc] then
        call := i;
      num := i^.num;
      for k := 1 to i^.h.nopnds do begin
        op := addr(i^.opnds[k]);
        if not ra_$process_operand_on_this_pass(op, classes) then
          goto 30;
        lts := ra_lts_ptr_t(op^.lts);
        lr := lts^.lr;
        if lr^.bb40 <> bb then begin
          if lr^.id = 0 then
            lr^.serial := 0;
          lr^.bb40 := bb;
        end;
        lts^.rrp := lts^.rrp - [rrp$ra_marked];
        lr^.rrp := lr^.rrp - [rrp$ra_marked];
        if (lr = ra_lr_ptr_t(rtn^.l112)) and rtn^.f226.save_rpc then begin
          lr^.f2.live := true;
          goto 30;
        end;
        if op^.h.read then begin
          if lr^.rrp * [rrp$modify, rrp$write] = [] then
            goto 30;
          reads[nreads].lr := lr;
          reads[nreads].instr := i;
          if ra_$drop_if_now_dead(num, i, lr, lts, op, weight, kind) then begin
            if rrp$ip_reg in lr^.rrp then
              nip := nip - 1
            else
              nfp := nfp - 1;
            reads[nreads].kind := kind;
          end
          else
            reads[nreads].kind := 0;
          nreads := nreads + 1;
          goto 30;
        end;
        if op^.h.unconsumed and (i^.opc = ord(opc$entry)) then begin
          if ra_650 > 1 then
            vfmt_$write('      Ignoring unconsumed ENTRY operand %d.%.', k);
          goto 30;
        end;
        if op^.h.modify then
          src := lr
        else begin
          if lr^.f2.live and (ra_class <> ra_pair) and not count_only then
            bug_check('RA_$BUILD_CONFLICT_GRAPH -- true write to LR on live list.%$');
          if (k > 2) or i^.h.fp_ccs or not i^.h.preference or
             i^.h.sets_cc then
            src := nil
          else begin
            src := ra_lts_ptr_t(i^.opnds[1].lts)^.lr;
            mismatch := false;
            if not (lr^.f2.physical_register or src^.f2.physical_register) then
              if (lr^.mate = nil) and (src^.mate <> nil) then
                mismatch := true
              else if lr^.mate <> nil then
                if src^.mate = nil then
                  mismatch := true;
            if mismatch then
              src := nil
            else if (i^.opc = ord(opc$copyd)) and (ra_class = ra_pair) then
              src := nil
            else if (src^.id <> 0) and
                    (ra_lts_ptr_t(i^.opnds[2].lts)^.lr^.id <> 0) then begin
              ra_instr_ptr_t(i)^.next_move := complex_moves;
              complex_moves := i;
            end
            else begin
              ra_instr_ptr_t(i)^.next_move := local_moves;
              local_moves := i;
            end;
          end;
        end;
        writes[nwrites].op := op^;
        writes[nwrites].instr := i;
        writes[nwrites].src := src;
        nwrites := nwrites + 1;
        if not count_only and lr^.f2.physical_register then begin
          reg := lr^.f2.physical_register_number;
          bit := [reg mod 32];
          if rrp$fp_reg in lr^.rrp then begin
            if lr^.f2.physical_register_number < 32 then begin
              if i^.opc = ord(opc$entry) then
                ra_fp_used.lo := ra_fp_used.lo + bit
              else
                bbx^.written_lo := bbx^.written_lo + bit;
            end
            else if i^.opc = ord(opc$entry) then
              ra_fp_used.hi := ra_fp_used.hi + bit
            else
              bbx^.written_hi := bbx^.written_hi + bit;
          end
          else begin
            conv := ra_rtn_ptr_t(rtn)^.conv;
            if not (conv^.nested and (reg = conv^.w18) and
                    (src = ra_lr_ptr_t(rtn^.db_lr))) then
              if i^.opc = ord(opc$entry) then begin
                if not (conv^.nested and (reg = conv^.w18)) then
                  ra_ip_used := ra_ip_used + bit;
              end
              else
                bbx^.written_ip := bbx^.written_ip + bit;
          end;
        end;
30:
      end;
      if i^.h.grouped then
        continued := true
      else begin
        while nwrites > 0 do begin
          nwrites := nwrites - 1;
          op := addr(writes[nwrites].op);
          { The write's conflicts. }
          if not count_only then begin
            if continued then begin
              for j := nreads - 1 downto 0 do
                if reads[j].instr <> writes[nwrites].instr then
                  ra_$enter_architectural_conflict(op, reads[j].lr);
              for j := nwrites - 1 downto 0 do begin
                p := ra_lts_ptr_t(writes[j].op.lts)^.lr;
                if writes[j].instr <> writes[nwrites].instr then begin
                  if p^.id = 0 then
                    if p^.serial = 0 then
                      p^.serial := ra_$new_simple_id;
                  ra_$enter_architectural_conflict(op, p);
                end;
              end;
            end;
            ra_$enter_conflicts(op, writes[nwrites].src, hdr);
          end;
          { Its live range goes live. }
          lts := ra_lts_ptr_t(op^.lts);
          lr := lts^.lr;
          { (out of the pipe first) }
          if lr^.f8.protected then
            ra_$unlink_protected_lr(lr);
          if not lr^.f2.live then begin
            hdr^.x52.lr^.prev := lr;
            lr^.x52.lr := hdr^.x52.lr;
            lr^.prev := hdr;
            hdr^.x52.lr := lr;
            lr^.f2.live := true;
            lr^.expires := num;
            lts^.w34 := num;
            ra_bb_last := num;
            if ra_650 > 1 then
              vfmt_$write('      Adding live:   LR %3ZWD%.', lr^.num);
            if rrp$ip_reg in lr^.rrp then begin
              nip := nip + 1;
              if nip > peak_ip then
                peak_ip := nip;
              if nip > instr_ip then
                instr_ip := nip;
              if not count_only and (ra_pipe_len > 0) then
                if not (instruction_attributes[i^.opc].class in no_aversion) then
                  ra_$possible_aversions(lr, 1, bb^.f.depth);
            end
            else begin
              nfp := nfp + 1;
              if nfp > peak_fp then
                peak_fp := nfp;
              if nfp > instr_fp then
                instr_fp := nfp;
              if not count_only and (ra_pipe_len > 0) then
                if (writes[nwrites].instr^.opc = ord(opc$loads)) or
                   (writes[nwrites].instr^.opc = ord(opc$loadse)) or
                   (writes[nwrites].instr^.opc = ord(opc$loadd)) or
                   (writes[nwrites].instr^.opc = ord(opc$loadso)) then
                  ra_$possible_aversions(lr, ra_pipe_len, bb^.f.depth);
            end;
          end
          else if op^.h.modify and (lts^.w34 = 0) then
            lts^.w34 := num;
          { It may die at once. }
          if ra_$drop_if_now_dead(num, nil, lr, lts, nil, weight, kind) then
            if rrp$ip_reg in lr^.rrp then
              nip := nip - 1
            else
              nfp := nfp - 1;
        end;
        for j := 0 to nreads - 1 do
          if reads[j].kind <> 0 then
            if not reads[j].lr^.f2.live then
              ra_$protect_lr_for_n_ticks(reads[j].lr, reads[j].kind);
        if ip then begin
          ra_instr_ptr_t(instr0)^.ip_final := chr(nip);
          ra_instr_ptr_t(instr0)^.ip_peak := chr(instr_ip);
        end;
        if fp then begin
          ra_instr_ptr_t(instr0)^.fp_final := chr(nfp);
          ra_instr_ptr_t(instr0)^.fp_peak := chr(instr_fp);
        end;
        { The clobbers of a call or SVC. }
        if call <> nil then begin
          clob := univ_ptr(addr(call^.opnds[call^.h.nopnds + 1]));
          clob_ip := clob^.ip;
          clob_lo := clob^.fp_lo;
          clob_hi := clob^.fp_hi;
          if ip then begin
            if clob_ip - ra_ip_reserved <> [] then
              ra_dropped := true;
            bbx^.written_ip := bbx^.written_ip + clob_ip;
            instr_ip := ra_$call_or_svc_ip_clobbers(clob_ip, hdr) +
                nip;
            if ord(ra_instr_ptr_t(instr0)^.ip_peak) < instr_ip then
              ra_instr_ptr_t(instr0)^.ip_peak := chr(instr_ip);
            if instr_ip > peak_ip then
              peak_ip := instr_ip;
          end;
          if fp then begin
            if clob_lo - ra_fp_reserved.lo <> [] then
              ra_dropped := true;
            bbx^.written_lo := bbx^.written_lo + clob_lo;
            if clob_hi - ra_fp_reserved.hi <> [] then
              ra_dropped := true;
            bbx^.written_hi := bbx^.written_hi + clob_hi;
            instr_fp := ra_$call_or_svc_fp_clobbers(integer32(clob_lo),
                integer32(clob_hi), hdr) + nfp;
            if ord(ra_instr_ptr_t(instr0)^.fp_peak) < instr_fp then
              ra_instr_ptr_t(instr0)^.fp_peak := chr(instr_fp);
            if instr_fp > peak_fp then
              peak_fp := instr_fp;
          end;
          call := nil;
          ra_bb_last := num;
          ra_bb_late := num;
        end;
        { Ready for the next instruction. }
        nreads := 0;
        continued := false;
        if ra_dropped then begin
          ra_bb_late := num;
          ra_dropped := false;
        end;
        if ra_650 > 1 then begin
          if ip then
            vfmt_$write('      Peak IP regs = %LD,  final = %LD%.',
                ord(ra_instr_ptr_t(instr0)^.ip_peak),
                ord(ra_instr_ptr_t(instr0)^.ip_final));
          if fp then
            vfmt_$write('      Peak FP regs = %LD,  final = %LD%.',
                ord(ra_instr_ptr_t(instr0)^.fp_peak),
                ord(ra_instr_ptr_t(instr0)^.fp_final));
        end;
      end;
      i := i^.next;
    end;
    if not count_only then begin
      while local_moves <> nil do begin
        ra_$enter_preference(local_moves);
        local_moves := ra_instr_ptr_t(local_moves)^.next_move;
      end;
      ra_$create_true_aversions(ra_pend_bb, bb^.f.depth);
      ra_pend_bb := nil;
      mrh_$release_all(ra_pend_bb_heap);
    end;
    if ip then begin
      rtn^.written_ip := rtn^.written_ip ! integer32(bbx^.written_ip);
      bbx^.live_out_ip := chr(nip);
      bbx^.max_ip := chr(peak_ip);
      bbx^.pass_ip := chr(0);
      if ord(lir_main_c89) < peak_ip then
        lir_main_c89 := chr(peak_ip);
      if ra_650 > 1 then begin
        vfmt_$write('      IP regs on exit = %LD%/%.', ord(bbx^.live_out_ip));
        vfmt_$write('      Max IP pressure = %LD%/%.', ord(bbx^.max_ip));
      end;
    end;
    if fp then begin
      rtn^.written_fp[0] := rtn^.written_fp[0] ! integer32(bbx^.written_hi);
      rtn^.written_fp[1] := rtn^.written_fp[1] ! integer32(bbx^.written_lo);
      bbx^.live_out_fp := chr(nfp);
      bbx^.max_fp := chr(peak_fp);
      bbx^.pass_fp := chr(0);
      if ord(lir_main_c88) < peak_fp then
        lir_main_c88 := chr(peak_fp);
      if ra_650 > 1 then begin
        vfmt_$write('      FP regs on exit = %LD%/%.', ord(bbx^.live_out_fp));
        vfmt_$write('      Max FP pressure = %LD%/%.', ord(bbx^.max_fp));
      end;
    end;
    p := live.x52.lr;
    if p <> hdr then
      if not count_only then
        repeat
          if ra_650 > 1 then
            vfmt_$write('      Live on exit:  LR %3ZWD%.', p^.num);
          p^.f2.live := false;
          t.r := (num - p^.expires) * weight.r + p^.live_time.r;
          p^.live_time := t;
          p := p^.x52.lr;
        until p = hdr
      else
        repeat
          p^.f2.live := false;
          p := p^.x52.lr;
        until p = hdr;
    while ra_pipe_len > 0 do
      ra_$advance_one_clock_tick;
    bb := bb^.next;
  end;
  if ra_650 > 1 then begin
    vfmt_$write('      Routine max IP pressure = %LD%/%.', ord(lir_main_c89));
    vfmt_$write('      Routine max FP pressure = %LD%/%.', ord(lir_main_c88));
  end;
  if not count_only then begin
    while complex_moves <> nil do begin
      ra_$enter_preference(complex_moves);
      complex_moves := ra_instr_ptr_t(complex_moves)^.next_move;
    end;
    d := ra_pend_depth;
    while d > 0 do begin
      pl := ra_pend_xx[d];
      ra_pend_xx[d] := nil;
      ra_$create_true_aversions(pl, d);
      d := d - 1;
    end;
    mrh_$release_all(ra_pend_xx_heap);
    lr := ra_lrs;
    while lr <> nil do begin
      if lr^.live_time.r > 1.0 then
        lr^.cost.r := lr^.cost.r / lr^.live_time.r;
      lr^.expires := 0;
      lr^.live_time.r := 0.0;
      if lr^.mate <> nil then
        if (rrp$life_mark in lr^.rrp) <> (rrp$life_mark in lr^.mate^.rrp) then begin
          p := lr^.mate;
          if not (rrp$life_mark in lr^.rrp) then
            p := lr;
          if p^.ltss = nil then
            p^.rrp := p^.rrp + [rrp$life_mark]
          else
            p^.mate^.rrp := p^.mate^.rrp - [rrp$life_mark];
        end;
      lr^.bb40 := nil;
      lr := lr^.next;
    end;
    ra_$release_rws_storage(ra_cc.vec);
    ra_$release_rws_storage(ra_cs.vec);
    ra_$release_rws_storage(ra_ss.vec);
  end;
end;

{ enter_lr_in_appropriate_work_list - an unassigned live range put on
  the collapse's work lists: one with no active aversions or
  preferences (+58), or with few enough conflicts (+56, at most
  ra_unconstrained), on the work list of its conflicts (twice its
  conflicts, one more with active ones; ra_work_low follows the least);
  the others (+10 bit 5) on the candidate list of the depth of their
  first aversion/preference, ordered by its preference less aversion.

  0x26A9CE, 0xFE bytes, internal. }

procedure enter_lr_in_appropriate_work_list(
    lr: ra_lr_ptr_t); options(val_param); internal;
label
  10;
var
  idx, key, d: integer32;
  old, prv: ra_lr_ptr_t;
begin
  if lr^.f2.physical_register then
    return;
  if (lr^.serial = 0) or (lr^.w56 <= ra_unconstrained) then begin
    lr^.f8.b10_5 := false;
    if lr^.w56 < ra_work_low then
      ra_work_low := lr^.w56;
    idx := lr^.w56 * 2;
    if lr^.aps <> nil then
      if lr^.serial <> 0 then
        idx := idx + 1;
    old := ra_work^[idx];
    ra_work^[idx] := lr;
  end
  else begin
    lr^.f8.b10_5 := true;
    key := lr^.aps^.pref - lr^.aps^.avoid;
    d := ord(lr^.aps^.depth);
    old := ra_cand^[d];
    if old <> nil then
      if old^.aps^.pref - old^.aps^.avoid < key then begin
        repeat
          prv := old;
          old := old^.x52.lr;
          if old = nil then
            goto 10;
        until old^.aps^.pref - old^.aps^.avoid >= key;
        old^.prev := lr;
10:
        lr^.prev := prv;
        lr^.x52.lr := old;
        prv^.x52.lr := lr;
        return;
      end;
    ra_cand^[d] := lr;
  end;
  if old <> nil then
    old^.prev := lr;
  lr^.x52.lr := old;
  lr^.prev := nil;
end;

{ remove_lr_from_current_work_list - an unassigned live range taken off
  its work or candidate list.

  0x26AACC, 0x7E bytes, internal: the unlinking branches on the flags
  of the stores of the next (pattern 111). }

procedure remove_lr_from_current_work_list(
    lr: ra_lr_ptr_t); options(val_param); internal;
var
  nxt, prv: ra_lr_ptr_t;
  idx: integer32;
begin
  nxt := lr^.x52.lr;
  prv := lr^.prev;
  if not lr^.f2.physical_register then
    if prv <> nil then begin
      prv^.x52.lr := nxt;
      if nxt <> nil then
        nxt^.prev := prv;
    end
    else begin
      if lr^.f8.b10_5 then
        ra_cand^[ord(lr^.aps^.depth)] := nxt
      else begin
        idx := lr^.w56 * 2;
        if lr^.aps <> nil then
          if lr^.serial <> 0 then
            idx := idx + 1;
        ra_work^[idx] := nxt;
      end;
      if nxt <> nil then
        nxt^.prev := nil;
    end;
end;

{ ra_$remove_lr_from_graph - lr leaves the graph: each of its conflicts
  not yet removed (marked in the record's +15 bit 0) lowers the other
  live range's conflicts (moving it between work lists), and each of
  its aversions and preferences not yet done (+29) the other's active
  count (+58) by one while it is above 1.

  0x26AB4A, 0xE4 bytes, internal: the conflict pointers' two low bits
  masked off (`andi.l #-4'); the count of lr's conflicts ends the walk.
  The path that would move a live range whose active count reaches 0
  is never taken (both tests `cmp.w #1; bcc': a slip, docs/questions.md
  230). }

procedure ra_$remove_lr_from_graph(
    lr: ra_lr_ptr_t); options(val_param); internal;
var
  c, cn: ra_conf_ptr_t;
  ap, an: ra_ap_ptr_t;
  other: ra_lr_ptr_t;
  n: integer32;
begin
  c := lr^.x44.conf;
  n := lr^.w56;
  c := ra_conf_ptr_t(integer32(c) & (~3));
  while c <> nil do begin
    if c^.a = lr then begin
      other := c^.b;
      cn := c^.next_a;
    end
    else begin
      other := c^.a;
      cn := c^.f12.next_b;
    end;
    if not c^.f12.f.removed then begin
      c^.f12.f.removed := true;
      if other^.f8.b10_5 then
        other^.w56 := other^.w56 - 1
      else begin
        remove_lr_from_current_work_list(other);
        other^.w56 := other^.w56 - 1;
        enter_lr_in_appropriate_work_list(other);
      end;
      n := n - 1;
      if n = 0 then
        exit;
    end;
    c := ra_conf_ptr_t(integer32(cn) & (~3));
  end;
  lr^.serial := 0;
  ap := lr^.aps;
  while ap <> nil do begin
    if ap^.a = lr then begin
      other := ap^.b;
      an := ap^.next_a;
    end
    else begin
      other := ap^.a;
      an := ap^.next_b;
    end;
    if not ap^.done then begin
      ap^.done := true;
      if other^.serial > 1 then
        other^.serial := other^.serial - 1
      else if other^.serial > 1 then begin
        remove_lr_from_current_work_list(other);
        other^.serial := 0;
        enter_lr_in_appropriate_work_list(other);
      end;
    end;
    ap := an;
  end;
end;

{ pick_uwork_candidate - the first candidate (shallowest depth first)
  whose conflicts and active aversions/preferences together are at
  most ra_work_low; nil when there is none.

  0x26AC2E, 0x5A bytes, internal; A0. }

function pick_uwork_candidate: ra_lr_ptr_t; internal;
var
  d: integer32;
  lr: ra_lr_ptr_t;
begin
  for d := 0 to ra_max_depth do begin
    lr := ra_cand^[d];
    while lr <> nil do begin
      if lr^.w56 + lr^.serial <= ra_work_low then begin
        pick_uwork_candidate := lr;
        return;
      end;
      lr := lr^.x52.lr;
    end;
  end;
  pick_uwork_candidate := nil;
end;

{ pick_uwork_victim - at the shallowest depth that has one, the
  candidate with the fewest conflicts among those with an aversion or
  preference to a constrained (more than ra_unconstrained conflicts),
  unassigned live range that is not a candidate itself; nil when there
  is none.

  0x26AC88, 0x9A bytes, internal; A0. }

function pick_uwork_victim: ra_lr_ptr_t; internal;
label
  10;
var
  best, lr, other: ra_lr_ptr_t;
  ap, an: ra_ap_ptr_t;
  d: integer32;
begin
  best := nil;
  for d := 0 to ra_max_depth do begin
    lr := ra_cand^[d];
    while lr <> nil do begin
      ap := lr^.aps;
      while ap <> nil do begin
        if ap^.a = lr then begin
          other := ap^.b;
          an := ap^.next_a;
        end
        else begin
          other := ap^.a;
          an := ap^.next_b;
        end;
        if other^.w56 > ra_unconstrained then
          if not other^.f2.physical_register then
            if not other^.f8.b10_5 then begin
              if best = nil then
                best := lr
              else if best^.w56 > lr^.w56 then
                best := lr;
              goto 10;
            end;
        ap := an;
      end;
10:
      lr := lr^.x52.lr;
    end;
    if best <> nil then
      exit;
  end;
  pick_uwork_victim := best;
end;

{ sort_ap_table - table[lo..hi] sorted (a quicksort, the last element
  the pivot) by depth, deepest first, then by the size of preference
  less aversion, largest first.

  0x26AD22, 0x134 bytes, internal, recursive. }

procedure sort_ap_table(
    var table: ra_ap_table_t;
    lo: integer32;
    hi: integer32); options(val_param); internal;
var
  i, j, key, k: integer32;
  pivot, e: ra_ap_ptr_t;
begin
  i := lo;
  j := hi - 1;
  pivot := table[hi];
  key := abs(pivot^.pref - pivot^.avoid);
  repeat
    while i < j do begin
      e := table[i];
      if e^.depth < pivot^.depth then
        exit;
      if e^.depth = pivot^.depth then
        if abs(e^.pref - e^.avoid) < key then
          exit;
      i := i + 1;
    end;
    while i < j do begin
      e := table[j];
      if e^.depth > pivot^.depth then
        exit;
      if e^.depth = pivot^.depth then
        if abs(e^.pref - e^.avoid) > key then
          exit;
      j := j - 1;
    end;
    if i < j then begin
      e := table[i];
      table[i] := table[j];
      table[j] := e;
    end;
  until i >= j;
  if i < hi then begin
    e := table[i];
    k := 0;
    if e^.depth < pivot^.depth then
      k := 1
    else if e^.depth = pivot^.depth then
      if abs(e^.pref - e^.avoid) < key then
        k := 1;
    if k <> 0 then begin
      table[i] := table[hi];
      table[hi] := e;
    end;
  end;
  i := i + 1;
  if i < hi then
    sort_ap_table(table, i, hi);
  if lo < j then
    sort_ap_table(table, lo, j);
end;

{ ra_$collapse_conflict_graph - the allocation order: the live ranges
  removed from the graph one by one onto order (each pushed on, so the
  last removed is coloured first).  Those already assigned go on
  flushed, as does a live range defined only by a plain move from an
  assigned no_modify register (given that register).  Each other live
  range's aversions and preferences that do not cancel are sorted (by
  depth, then strength) and counted active (+58); the work lists hold
  the unconstrained live ranges by conflicts.  At each level (from
  ra_work_low) the work list's live range is removed (the costliest of
  those without active aversions or preferences), or a candidate that
  has become unconstrained, until the level reaches nregs; above it a
  victim with an aversion or preference to a constrained live range,
  and failing that the spill candidate of least cost per conflict (+3
  bit 7 of rrp, spare_1, marks it; never one with life_mark), and when
  there is none the remaining live ranges are taken as they come.
  Finally the candidates still listed are flushed onto order.  Traced
  with trace; the result is the highest level reached plus one (the
  chromatic number).

  0x26AE56, 0x760 bytes, internal: the aversion table in the frame
  (262144 bytes past the locals, its address at -106); the work lists
  and candidate lists from the heap (ra_work, ra_cand); the cost
  comparisons through fpp_$eslv 0x0048 (`bpl'), cost per conflict
  through fpp_$ 0x005C 0x003C; the best ratio starts at 0x7F7FFF9E (the
  largest single, about 3.4e38); p2 is not read; the No Mod trace
  passes a constant 0 (0x26B82E) and *UCAND* the address of the word
  +58 for %4LD. }

function ra_$collapse_conflict_graph(
    nregs: integer32;
    p2: integer32;
    var flushed: ra_lr_ptr_t;
    var order: ra_lr_ptr_t;
    trace: boolean): integer32; options(val_param); internal;
var
  n, k, bytes, cnt, idx, top, maxlevel, active, id, w: integer32;
  work, cand: ra_lrs_ptr_t;
  moved, lr, nxt, p, src: ra_lr_ptr_t;
  ap, prev: ra_ap_ptr_t;
  op: opnd_ptr_t;
  i: instr_ptr_t;
  spilling: boolean;
  best, ratio: ra_real_t;
  table: ra_ap_table_t;
begin
  if trace then begin
    vfmt_$write('%/%/TRACE OF RA_$COLLAPSE_CONFLICT_GRAPH -- THRESHOLD %LD / %$',
        nregs);
    vfmt_$write(ra_titles[ra_class]);
  end;
  n := (ra_max_conflicts + 1) * 2 + 1;
  bytes := (n + 1) * 8;
  work := rws_$alloc_heap(bytes);
  ra_work := work;
  for k := 0 to n do
    work^[k] := nil;
  bytes := (ra_max_depth + 1) * 4;
  cand := rws_$alloc_heap(bytes);
  ra_cand := cand;
  for k := 0 to ra_max_depth do
    cand^[k] := nil;
  case ra_class of
    ra_ip: begin
      ra_unconstrained := ord(lir_main_c89);
      if ra_unconstrained > nregs then
        ra_unconstrained := nregs;
      end;
    ra_fp: begin
      ra_unconstrained := ord(lir_main_c88);
      if ra_unconstrained > nregs then
        ra_unconstrained := nregs;
      end;
    ra_pair: begin
      ra_unconstrained := rshft(ord(lir_main_c88), 1);
      if ra_unconstrained > nregs then
        ra_unconstrained := nregs;
      end;
  end;
  ra_unconstrained := ra_unconstrained - 1;
  ra_work_low := 0;
  moved := nil;
  flushed := nil;
  order := nil;
  lr := ra_lrs;
  while lr <> nil do begin
    lr^.serial := 0;
    if lr^.f2.physical_register then begin
      lr^.x52.lr := flushed;
      flushed := lr;
    end
    else begin
      src := nil;
      if not (rrp$true_write in lr^.rrp) and (lr^.defs <> nil) then
        if lr^.defs^.next_def = nil then begin
          op := lr^.defs^.refs;
          i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
          if instruction_attributes[i^.opc].b6_0 and
             (i^.opnds[1].h.count = 0) then begin
            p := ra_lts_ptr_t(i^.opnds[1].lts)^.lr;
            if p^.f2.physical_register and p^.f2.physical_register_is_no_modify then
              src := p;
          end;
        end;
      if src <> nil then begin
        lr^.f2.physical_register := true;
        lr^.f2.physical_register_number := src^.f2.physical_register_number;
        lr^.x52.lr := moved;
        moved := lr;
      end
      else begin
        cnt := 0;
        ap := lr^.aps;
        lr^.aps := nil;
        while ap <> nil do begin
          if ap^.avoid <> ap^.pref then begin
            table[cnt] := ap;
            cnt := cnt + 1;
          end;
          if ap^.a = lr then
            ap := ap^.next_a
          else
            ap := ap^.next_b;
        end;
        lr^.serial := cnt;
        if cnt <> 0 then begin
          if cnt > 1 then
            sort_ap_table(table, 0, cnt - 1);
          prev := nil;
          while cnt <> 0 do begin
            cnt := cnt - 1;
            ap := table[cnt];
            if ap^.a = lr then
              ap^.next_a := prev
            else
              ap^.next_b := prev;
            prev := ap;
          end;
          lr^.aps := prev;
        end;
        enter_lr_in_appropriate_work_list(lr);
      end;
    end;
    lr := lr^.next;
  end;
  while moved <> nil do begin
    if trace then begin
      w := moved^.w56;
      id := moved^.id;
      vfmt_$write('No Mod   LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%.',
          moved^.num, id, w, 0);
    end;
    ra_$remove_lr_from_graph(moved);
    nxt := moved^.x52.lr;
    moved^.x52.lr := flushed;
    flushed := moved;
    moved := nxt;
  end;
  spilling := false;
  maxlevel := 0;
  ra_work_low := 0;
  while ra_work_low <= ra_max_conflicts do begin
    idx := ra_work_low * 2;
    lr := work^[idx];
    if lr = nil then begin
      idx := idx + 1;
      lr := work^[idx];
    end;
    if lr = nil then begin
      lr := pick_uwork_candidate;
      if trace and (lr <> nil) then begin
        w := lr^.w56;
        id := lr^.id;
        vfmt_$write('*UCAND*  LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%.',
            lr^.num, id, w, lr^.serial);
      end;
    end;
    if lr = nil then begin
      ra_work_low := ra_work_low + 1;
      if trace then
        vfmt_$write('-- COLLAPSE_WORK_LOW incremented to %LD%.', ra_work_low);
    end
    else begin
      if spilling or (ra_work_low < nregs) then begin
        if ra_work_low > maxlevel then begin
          maxlevel := ra_work_low;
          if ra_work_low < nregs then begin
            ra_unconstrained := ra_work_low;
            if trace then
              vfmt_$write('-- COLLAPSE_UNCONSTRAINED increased to %LD%.',
                  ra_unconstrained);
          end;
        end;
        if not odd(idx) then begin
          p := lr^.x52.lr;
          while p <> nil do begin
            if lr^.cost.r < p^.cost.r then
              lr := p;
            p := p^.x52.lr;
          end;
        end;
        if lr^.serial <> 0 then
          if lr^.w56 <= ra_unconstrained then
            if not lr^.f8.b10_5 then begin
              remove_lr_from_current_work_list(lr);
              enter_lr_in_appropriate_work_list(lr);
              if trace then begin
                w := lr^.w56;
                id := lr^.id;
                vfmt_$write('*DEFER*  LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%.',
                    lr^.num, id, w, lr^.serial);
              end;
              lr := nil;
            end;
      end
      else begin
        lr := pick_uwork_victim;
        if trace and (lr <> nil) then begin
          w := lr^.w56;
          id := lr^.id;
          vfmt_$write('*UVICT*  LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%.',
              lr^.num, id, w, lr^.serial);
        end;
        if lr = nil then begin
          best.i := 16#7F7FFF9E;
          if trace then
            vfmt_$write('  Spill candidates at level %LD:%.', ra_work_low);
          top := ra_max_conflicts * 2 + 1;
          for idx := top downto ra_work_low * 2 do begin
            p := work^[idx];
            while p <> nil do begin
              if not (rrp$life_mark in p^.rrp) and not p^.f2.physical_register then
                if p^.w56 <> 0 then begin
                  ratio.r := p^.cost.r / p^.w56;
                  if ratio.r < best.r then begin
                    best := ratio;
                    lr := p;
                  end;
                end;
              if trace then begin
                w := p^.w56;
                vfmt_$write('         LR %3ZWD: %15.3WF / %8JWD %15.3WF%.',
                    p^.num, p^.cost, w, ratio);
              end;
              p := p^.x52.lr;
            end;
          end;
          if lr = nil then
            spilling := true
          else begin
            if rrp$life_mark in lr^.rrp then
              bug_check('RA_$COLLAPSE_CONFLICT_GRAPH -- spill victim is marked never_spill%$');
            lr^.rrp := lr^.rrp + [rrp$spare_1];
          end;
        end;
      end;
      if lr <> nil then begin
        remove_lr_from_current_work_list(lr);
        lr^.x52.lr := order;
        order := lr;
        if trace then begin
          if lr^.aps = nil then
            active := 0
          else
            active := lr^.serial;
          w := lr^.w56;
          id := lr^.id;
          vfmt_$write('Removing LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%$',
              lr^.num, id, w, active);
          if rrp$life_mark in lr^.rrp then
            vfmt_$write(', never spill%.')
          else if rrp$spare_1 in lr^.rrp then
            vfmt_$write(', spill candidate%.')
          else
            vfmt_$write('%.');
        end;
        ra_$remove_lr_from_graph(lr);
      end;
    end;
  end;
  ra_$release_rws_storage(work);
  for k := 0 to ra_max_depth do
    while cand^[k] <> nil do begin
      lr := cand^[k];
      remove_lr_from_current_work_list(lr);
      ra_$remove_lr_from_graph(lr);
      lr^.x52.lr := order;
      order := lr;
      if trace then begin
        if lr^.aps = nil then
          active := 0
        else
          active := lr^.serial;
        w := lr^.w56;
        id := lr^.id;
        vfmt_$write('Flushing LR %3ZWD,   COMPLEX_ID %3ZLD,  remaining =%4LD,  active A/Ps =%4LD%$',
            lr^.num, id, w, active);
        if rrp$life_mark in lr^.rrp then
          vfmt_$write(', never spill%.')
        else if rrp$spare_1 in lr^.rrp then
          vfmt_$write(', spill candidate%.')
        else
          vfmt_$write('%.');
      end;
    end;
  ra_$release_rws_storage(cand);
  if trace and (ra_650 > 1) then
    dmp_$interference_graph_analysis('%/%/ALLOCATION ORDER -- %$',
        ra_titles[ra_class], maxlevel + 1, lr_ptr_t(order), true);
  ra_$collapse_conflict_graph := maxlevel + 1;
end;

{ ra_$extra_registers_needed - of the n registers wanted, those in avail
  (each taken; one not yet in used costs step bytes of saving: 4, or 8
  for pairs) and, beyond what avail held, those used already (free) or
  else to be saved (step each); the registers still wanted.

  0x26B8F2, 0xD6 bytes, internal: the sets in dpc's 64-bit layout (32..63
  first); extra by address; the product by m$mis$lll. }

function ra_$extra_registers_needed(
    n: integer32;
    in avail: ra_set64_t;
    in used: ra_set64_t;
    out extra: integer32): integer32; options(val_param); internal;
var
  step, cnt, r, d: integer32;
begin
  step := 4;
  if ra_class = ra_pair then
    step := 8;
  extra := 0;
  cnt := 0;
  if avail.lo <> [] then
    for r := 0 to 31 do
      if (r mod 32) in avail.lo then begin
        n := n - 1;
        if not ((r mod 32) in used.lo) then
          extra := extra + step;
      end
      else if (r mod 32) in used.lo then
        cnt := cnt + 1;
  if avail.hi <> [] then
    for r := 0 to 31 do
      if (r mod 32) in avail.hi then begin
        n := n - 1;
        if not ((r mod 32) in used.hi) then
          extra := extra + step;
      end
      else if (r mod 32) in used.hi then
        cnt := cnt + 1;
  if n < 0 then
    n := 0;
  d := n - cnt;
  if d > 0 then
    extra := extra + d * step;
  ra_$extra_registers_needed := n;
end;

{ ra_$open_another_fp_register - one more floating register (a pair's
  even half in the pair class: the registers whose odd half the
  conventions' fp60 names count as taken) added to regs: one the
  conventions clobber anyway (paired true), else one they preserve,
  preferring the other half of a pair one of whose halves regs already
  has; false when none is left.  reg the register (for the pair
  search, the pair's odd register).

  0x26B9C8, 0x298 bytes, internal: regs, reg and paired by address; the
  floating sets in dpc's layout (32..63 first); every bit test with the
  compiler's range check after `and #31'. }

function ra_$open_another_fp_register(
    var regs: ra_set64_t;
    conv: call_conv_$ptr_t;
    out reg: integer32;
    out paired: boolean): boolean; options(val_param); internal;
label
  10;
var
  hi, lo, nhi, nlo, c_hi, c_lo, bit: bv_word_t;
  r, r1: integer32;
begin
  if ra_class = ra_fp then begin
    hi := regs.hi + ra_fp_unalloc.hi;
    lo := regs.lo + ra_fp_unalloc.lo;
  end
  else begin
    hi := regs.hi + ra_pair_unalloc.hi;
    lo := regs.lo + ra_pair_unalloc.lo;
    r := 30;
    r1 := 31;
    while r >= 0 do begin
      if (r1 mod 32) in bv_word_t(conv^.fp60[0]) then
        hi := hi + [r mod 32];
      if (r1 mod 32) in bv_word_t(conv^.fp60[1]) then
        lo := lo + [r mod 32];
      r := r - 2;
      r1 := r1 - 2;
    end;
  end;
  nhi := [0..31] - hi;
  c_hi := nhi * bv_word_t(conv^.fp_clobbered[0]);
  nlo := [0..31] - lo;
  c_lo := nlo * bv_word_t(conv^.fp_clobbered[1]);
  if (c_lo <> []) or (c_hi <> []) then
    paired := true
  else begin
    paired := false;
    c_hi := nhi * bv_word_t(conv^.fp_preserved[0]);
    c_lo := nlo * bv_word_t(conv^.fp_preserved[1]);
    if (c_lo = []) and (c_hi = []) then begin
      ra_$open_another_fp_register := false;
      return;
    end;
    r := 0;
    r1 := 1;
    while r < 32 do begin
      if ((r1 mod 32) in regs.lo) and
         ((r1 mod 32) in bv_word_t(conv^.fp_preserved[1])) and
         ((r mod 32) in c_lo) then begin
        regs.lo := regs.lo + [r mod 32];
        goto 10;
      end;
      if ((r mod 32) in regs.lo) and
         ((r mod 32) in bv_word_t(conv^.fp_preserved[1])) and
         ((r1 mod 32) in c_lo) then begin
        regs.lo := regs.lo + [r1 mod 32];
        goto 10;
      end;
      r := r + 2;
      r1 := r1 + 2;
    end;
    r := 0;
    r1 := 33;
    while r < 32 do begin
      if ((r1 mod 32) in regs.hi) and
         ((r1 mod 32) in bv_word_t(conv^.fp_preserved[0])) and
         ((r mod 32) in c_hi) then begin
        regs.hi := regs.hi + [r mod 32];
        goto 10;
      end;
      if ((r mod 32) in regs.hi) and
         ((r mod 32) in bv_word_t(conv^.fp_preserved[0])) and
         ((r1 mod 32) in c_hi) then begin
        regs.hi := regs.hi + [r1 mod 32];
        goto 10;
      end;
      r := r + 2;
      r1 := r1 + 2;
    end;
  end;
  if c_lo <> [] then begin
    r1 := 0;
    while not ((r1 mod 32) in c_lo) do
      r1 := r1 + 1;
    regs.lo := regs.lo + [r1 mod 32];
  end
  else begin
    r1 := 32;
    while not ((r1 mod 32) in c_hi) do
      r1 := r1 + 1;
    regs.hi := regs.hi + [r1 mod 32];
  end;
10:
  reg := r1;
  ra_$open_another_fp_register := true;
end;

{ ra_$open_another_ip_register - one more integer register added to
  regs (its low longword): one the conventions clobber (paired true),
  else one they preserve; false when none is left.

  0x26BC60, 0x84 bytes, internal. }

function ra_$open_another_ip_register(
    var regs: ra_set64_t;
    conv: call_conv_$ptr_t;
    out reg: integer32;
    out paired: boolean): boolean; options(val_param); internal;
var
  na, c: bv_word_t;
  r: integer32;
begin
  na := [0..31] - (regs.lo + ra_ip_unalloc);
  c := na * bv_word_t(conv^.ip_clobbered);
  if c <> [] then
    paired := true
  else begin
    paired := false;
    c := na * bv_word_t(conv^.ip_preserved);
    if c = [] then begin
      ra_$open_another_ip_register := false;
      return;
    end;
  end;
  r := 0;
  while not ((r mod 32) in c) do
    r := r + 1;
  regs.lo := regs.lo + [r mod 32];
  reg := r;
  ra_$open_another_ip_register := true;
end;

{ ra_$count_available_registers - the registers of the pass's file that
  could be opened from none (count), those clobbered anyway among them
  (cheap).  0x26BCE4, 0x8E bytes, internal. }

procedure ra_$count_available_registers(
    rtn: rtn_ptr_t;
    out count: integer32;
    out cheap: integer32); options(val_param); internal;
var
  conv: call_conv_$ptr_t;
  regs: ra_set64_t;
  reg, n, c: integer32;
  paired: boolean;
begin
  conv := ra_rtn_ptr_t(rtn)^.conv;
  regs.hi := [];
  regs.lo := [];
  n := 0;
  c := 0;
  if ra_final then
    while ra_$open_another_ip_register(regs, conv, reg, paired) do begin
      n := n + 1;
      if paired then
        c := c + 1;
    end
  else
    while ra_$open_another_fp_register(regs, conv, reg, paired) do begin
      n := n + 1;
      if paired then
        c := c + 1;
    end;
  count := n;
  cheap := c;
end;

{ ra_$determine_available_registers - the register files under the
  routine's conventions: the integer registers reserved (the calls'
  read registers, ip76, and the zero and PC-like registers) and never
  allocated (the complement of the allocatable range, lir_420c's and
  the reserved; ra_ip_alloc the complement); the floating ones reserved
  (fp60 and the floating zero register) and never allocated (with
  lir_4204/4208 and the complement of the allocatable range;
  ra_fp_alloc the complement); then, in the floating class, as many
  registers opened from the clobbered ones as the opening finds (three
  eighths of them when that is above 6, else at most 6), the pair
  class's unavailable registers (ra_pair_unalloc) the preserved ones
  so opened, lir_main's ra_654/ra_658 and every odd register.

  0x26BD72, 0x2A2 bytes, internal: the ranges' set constructors as in
  ra_$begin_compilation (docs/dpc-gaps.md 38); ra_class set to 2. }

procedure ra_$determine_available_registers(
    conv: call_conv_$ptr_t); options(val_param); internal;
var
  s: bv_word_t;
  f, g: ra_set64_t;
  n, m, reg: integer32;
  paired: boolean;
begin
  ra_ip_reserved := bv_word_t(conv^.ip76);
  ra_ip_zero := target_properties.p_14[0];
  if ra_ip_zero >= 0 then
    ra_ip_reserved := ra_ip_reserved + [ra_ip_zero];
  if target_properties.p_14[1] >= 0 then
    ra_ip_reserved := ra_ip_reserved + [target_properties.p_14[1]];
  s := [0..31] - [target_properties.p_14[2] ..
      target_properties.p_14[2] + target_properties.p_14[4] - 1];
  s := bv_word_t(lir_420c) + s;
  s := ra_ip_reserved + s;
  ra_ip_unalloc := s;
  ra_ip_alloc := [0..31] - ra_ip_unalloc;
  f.hi := bv_word_t(conv^.fp60[0]);
  f.lo := bv_word_t(conv^.fp60[1]);
  ra_fp_zero := target_properties.p_14[9];
  if ra_fp_zero >= 0 then begin
    g.s := [ra_fp_zero];
    f.s := f.s + g.s;
  end;
  ra_fp_reserved.hi := f.hi;
  ra_fp_reserved.lo := f.lo;
  f.hi := f.hi + bv_word_t(lir_4208);
  f.lo := f.lo + bv_word_t(lir_4204);
  g.s := [0..63] - [target_properties.p_14[10] ..
      target_properties.p_14[10] + target_properties.p_14[12] - 1];
  f.s := f.s + g.s;
  ra_fp_unalloc.hi := f.hi;
  ra_fp_alloc.hi := [0..31] - ra_fp_unalloc.hi;
  ra_fp_unalloc.lo := f.lo;
  ra_fp_alloc.lo := [0..31] - ra_fp_unalloc.lo;
  ra_class := ra_fp;
  f.hi := bv_word_t(conv^.fp_clobbered[0]);
  f.lo := bv_word_t(conv^.fp_clobbered[1]);
  n := 0;
  while ra_$open_another_fp_register(f, conv, reg, paired) do
    n := n + 1;
  m := rshft(n * 3, 3);
  if m > 6 then
    n := m
  else if n > 6 then
    n := 6;
  f.hi := bv_word_t(conv^.fp_clobbered[0]);
  f.lo := bv_word_t(conv^.fp_clobbered[1]);
  while n > 0 do begin
    if not ra_$open_another_fp_register(f, conv, reg, paired) then
      exit;
    n := n - 1;
  end;
  ra_pair_unalloc.hi := ([0..31] - bv_word_t(conv^.fp_clobbered[0])) * f.hi +
      bv_word_t(ra_658) + bv_word_t(16#AAAAAAAA);
  ra_pair_unalloc.lo := ([0..31] - bv_word_t(conv^.fp_clobbered[1])) * f.lo +
      bv_word_t(ra_654) + bv_word_t(16#AAAAAAAA);
end;

{ ra_$combine_with_sf - lr given the conventions' frame register (w20)
  and each of its definitions, a move from the frame register's
  value (an ip_reg operand 1, no count, setting no condition codes,
  whose live range has F1 or that register), made to read the move's
  destination instead (its operand 1 the operand 2's segment): the
  live range shares the stack frame's register.

  0x26C014, 0xD2 bytes, internal: the definition's instruction computed
  inline (pattern 121). }

procedure ra_$combine_with_sf(
    lr: ra_lr_ptr_t;
    conv: call_conv_$ptr_t); options(val_param); internal;
var
  s: ra_lts_ptr_t;
  op: opnd_ptr_t;
  i: instr_ptr_t;
  src: ra_lr_ptr_t;
  ok: boolean;
begin
  lr^.f2.physical_register := true;
  lr^.f2.physical_register_number := conv^.w20 & 255;
  s := lr^.defs;
  while s <> nil do begin
    op := s^.refs;
    if op <> nil then begin
      i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
      if i^.opc <> ord(opc$move) then
        bug_check('RA_$COMBINE_WITH_SF -- defining instruction in not a MOVE%$');
      ok := false;
      if (i^.opnds[1].h.kind = operand$ip_reg) and
         (i^.opnds[1].h.count = 0) and not i^.h.sets_cc then begin
        src := ra_lts_ptr_t(i^.opnds[1].lts)^.lr;
        if src^.f2.physical_register then
          if (src^.f2.physical_register_number = 1) or (src^.f2.physical_register_number = conv^.w20) then
            ok := true;
      end;
      if not ok then
        bug_check('RA_$COMBINE_WITH_SF -- problem with defining MOVE instruction%$');
      i^.opnds[1].lts := i^.opnds[2].lts;
    end;
    s := s^.next_def;
  end;
end;

{ ra_$open_registers - the registers the pass may assign: the routine's
  written registers updated with the ENTRY's and the calls' (less the
  reserved); in a floating pass those written (by pairs in the pair
  class) and not reserved by the conventions (fp60) or never allocated,
  plus as many of the conventions' preserved ones as the chromatic
  number chrom still needs (ra_$extra_registers_needed; the saving
  bytes in ra_save_bytes), the written sets then reset to the calls'
  clobbers; in the integer pass those written and not read by calls
  (ip76) or never allocated, the nested routine's static link register
  (w18) unless a call reads it, and the return address register (w14:
  the routine's +112 live range gets it, or the zero register with
  save_rpc and needs_frame when chrom is below the registers there are,
  the return address is saved already, there is no return block, or
  the register is written), more registers opened as needed (saving
  bytes in ra_save_ip), the frame needed when the saves with the frame
  exceed 24 bytes (always with lir_main_da4, a call, or the routine
  node's +378 bit 4).  needed the registers still wanted.

  0x26C162, 0x272 bytes, internal: the sets by address (hi, lo); the
  pair class's written sets folded `lsr.l #1; or; and #0x55555555'. }

procedure ra_$open_registers(
    rtn: rtn_ptr_t;
    chrom: integer32;
    nregs: integer32;
    out hi: bv_word_t;
    out lo: bv_word_t;
    out needed: integer32); options(val_param); internal;
var
  w_hi, w_lo, w_ip, bit: bv_word_t;
  conv: call_conv_$ptr_t;
  avail, used: ra_set64_t;
  reg: integer32;
  paired: boolean;
  sf: ra_lr_ptr_t;
begin
  w_hi := (bv_word_t(rtn^.written_fp[0]) + ra_fp_used.hi + ra_fp_clobbered.hi) -
      ra_fp_reserved.hi;
  rtn^.written_fp[0] := integer32(w_hi);
  w_lo := (bv_word_t(rtn^.written_fp[1]) + ra_fp_used.lo + ra_fp_clobbered.lo) -
      ra_fp_reserved.lo;
  rtn^.written_fp[1] := integer32(w_lo);
  w_ip := (bv_word_t(rtn^.written_ip) + ra_ip_used + ra_ip_clobbered) -
      ra_ip_reserved;
  rtn^.written_ip := integer32(w_ip);
  conv := ra_rtn_ptr_t(rtn)^.conv;
  if not ra_final then begin
    if ra_class = ra_pair then begin
      rtn^.written_fp[0] := (rshft(integer32(w_hi), 1) ! rtn^.written_fp[0]) &
          16#55555555;
      w_hi := bv_word_t(rtn^.written_fp[0]);
      rtn^.written_fp[1] := (rshft(rtn^.written_fp[1], 1) ! rtn^.written_fp[1]) &
          16#55555555;
    end;
    avail.hi := (w_hi - bv_word_t(conv^.fp60[0])) - ra_fp_unalloc.hi;
    avail.lo := (bv_word_t(rtn^.written_fp[1]) - bv_word_t(conv^.fp60[1])) -
        ra_fp_unalloc.lo;
    used.hi := bv_word_t(conv^.fp_clobbered[0]);
    used.lo := bv_word_t(conv^.fp_clobbered[1]);
    needed := ra_$extra_registers_needed(nregs, avail, used, ra_save_bytes);
    while needed <> 0 do begin
      if not ra_$open_another_fp_register(avail, conv, reg, paired) then
        exit;
      needed := needed - 1;
    end;
    rtn^.written_fp[0] := integer32(ra_fp_clobbered.hi);
    rtn^.written_fp[1] := integer32(ra_fp_clobbered.lo);
  end
  else begin
    avail.hi := [];
    avail.lo := (w_ip - bv_word_t(conv^.ip76)) - ra_ip_unalloc;
    used.hi := [];
    used.lo := bv_word_t(conv^.ip_clobbered);
    if conv^.nested then
      if not ((conv^.w18 & 31) in bv_word_t(conv^.ip76)) then
        avail.lo := avail.lo + [conv^.w18 & 31];
    sf := ra_lr_ptr_t(rtn^.l112);
    if (chrom < nregs) or rtn^.f226.save_rpc or
       rtn^.f226.no_return_block or ((conv^.w14 & 31) in w_ip) then begin
      sf^.f2.physical_register_number := ra_ip_zero;
      rtn^.f226.save_rpc := true;
      rtn^.f226.needs_frame := true;
    end
    else
      sf^.f2.physical_register_number := conv^.w14 & 255;
    sf^.f2.physical_register := true;
    bit := [conv^.w14 & 31];
    avail.lo := avail.lo + bit;
    used.lo := used.lo + bit;
    needed := ra_$extra_registers_needed(chrom, avail, used, ra_save_ip);
    if lir_main_da4 or rtn^.f226.contains_call or
       ((ord(ra_bytes_ptr_t(rtn^.node)^[378]) & 16) <> 0) then
      rtn^.f226.needs_frame := true
    else if ra_save_bytes + ra_save_ip + ra_rtn_ptr_t(rtn)^.frame_size > 24 then
      rtn^.f226.needs_frame := true;
    if not rtn^.f226.save_rpc then
      avail.lo := avail.lo + [conv^.w14 & 31];
    while needed <> 0 do begin
      if not ra_$open_another_ip_register(avail, conv, reg, paired) then
        exit;
      needed := needed - 1;
    end;
    avail.lo := avail.lo - [sf^.f2.physical_register_number mod 32];
    rtn^.written_ip := integer32(ra_ip_clobbered);
  end;
  hi := avail.hi;
  lo := avail.lo;
end;

{ ra_$close_live_range_preferences - the registers (hi, lo) just given
  to lr preferred by the live ranges its preferences (preference above
  aversion) reach, transitively (+64, +68), through unassigned live
  ranges that do not conflict with them; each record reached is chained
  into the closure (+16, from root; the first to itself).  The last
  record chained.

  0x26C3D4, 0x9A bytes, internal, recursive (`bsr.s'); root (12) is
  overwritten with each record reached; A0. }

function ra_$close_live_range_preferences(
    lr: ra_lr_ptr_t;
    root: ra_ap_ptr_t;
    hi: bv_word_t;
    lo: bv_word_t): ra_ap_ptr_t; options(val_param); internal;
var
  last, ap, an: ra_ap_ptr_t;
  other: ra_lr_ptr_t;
begin
  last := root;
  ap := lr^.aps;
  while ap <> nil do begin
    if ap^.a = lr then begin
      an := ap^.next_a;
      other := ap^.b;
    end
    else begin
      an := ap^.next_b;
      other := ap^.a;
    end;
    if ap^.pref > ap^.avoid then
      if ap^.closure = nil then
        if not other^.f2.physical_register then
          if (hi * other^.avoid_hi) + (lo * other^.avoid_lo) = [] then begin
            if last = nil then
              ap^.closure := ap
            else
              ap^.closure := last;
            root := ap;
            ra_pref_ptr_t(other)^.hi := ra_pref_ptr_t(other)^.hi + hi;
            ra_pref_ptr_t(other)^.lo := ra_pref_ptr_t(other)^.lo + lo;
            last := ra_$close_live_range_preferences(other, root, hi, lo);
          end;
    ap := an;
  end;
  ra_$close_live_range_preferences := last;
end;

{ ra_$zero_closure_next_fields - the closure chained from ap undone.
  0x26C46E, 0x1C bytes, internal, no frame. }

procedure ra_$zero_closure_next_fields(
    ap: ra_ap_ptr_t); options(val_param); internal;
var
  nxt: ra_ap_ptr_t;
begin
  while ap <> nil do begin
    nxt := ap^.closure;
    ap^.closure := nil;
    if nxt = ap then
      exit;
    ap := nxt;
  end;
end;

{ ra_$spill_lr - lr marked a spill victim (+3 bit 0) once; an assigned
  one that may be spilled loses its register, which leaves the
  conflicting registers of each unassigned live range it conflicts
  with unless another of that one's conflicts holds it.

  0x26C48A, 0x10A bytes, internal: the first conflict pointer of each
  neighbour not masked, the later ones `andi.l #-4'. }

procedure ra_$spill_lr(
    lr: ra_lr_ptr_t); options(val_param); internal;
label
  10;
var
  r: integer32;
  c, cn, q, qn: ra_conf_ptr_t;
  other, o2: ra_lr_ptr_t;
begin
  if lr^.f2.spilled then
    return;
  lr^.f2.spilled := true;
  if not lr^.f2.physical_register then
    return;
  if rrp$life_mark in lr^.rrp then
    return;
  lr^.f2.physical_register := false;
  r := lr^.f2.physical_register_number;
  lr^.f2.physical_register_number := 0;
  c := lr^.x44.conf;
  while c <> nil do begin
    if c^.a = lr then begin
      other := c^.b;
      cn := c^.next_a;
    end
    else begin
      other := c^.a;
      cn := c^.f12.next_b;
    end;
    if not other^.f2.physical_register then begin
      q := other^.x44.conf;
      while q <> nil do begin
        if q^.a = other then begin
          o2 := q^.b;
          qn := q^.next_a;
        end
        else begin
          o2 := q^.a;
          qn := q^.f12.next_b;
        end;
        if o2^.f2.physical_register then
          if o2^.f2.physical_register_number = r then
            goto 10;
        q := ra_conf_ptr_t(integer32(qn) & (~3));
      end;
      if r <= 31 then
        other^.avoid_lo := other^.avoid_lo - [r]
      else
        other^.avoid_hi := other^.avoid_hi - [r - 32];
    end;
10:
    c := ra_conf_ptr_t(integer32(cn) & (~3));
  end;
end;

{ ra_$pick_spill_lr - a live range lr (never spilled itself) conflicts
  with to spill instead: of the conflicts that may be spilled and are
  not victims yet, the first, replaced by an assigned one marked a
  spill candidate (spare_1) when the choice is not, else by any later
  assigned one when neither is a candidate, or a cheaper one when both
  are.  Whether any conflict may be spilled at all.

  0x26C594, 0xAC bytes, internal: victim by address; the costs through
  fpp_$eslv 0x0048 (`slt'). }

function ra_$pick_spill_lr(
    lr: ra_lr_ptr_t;
    out victim: ra_lr_ptr_t): boolean; options(val_param); internal;
var
  found, cheaper: boolean;
  c: ra_conf_ptr_t;
  other: ra_lr_ptr_t;
begin
  found := false;
  victim := nil;
  c := lr^.x44.conf;
  while c <> nil do begin
    if c^.a = lr then begin
      other := c^.b;
      c := c^.next_a;
    end
    else begin
      other := c^.a;
      c := c^.f12.next_b;
    end;
    if not (rrp$life_mark in other^.rrp) then begin
      found := true;
      if not other^.f2.spilled then
        if victim = nil then
          victim := other
        else if other^.f2.physical_register then
          if (rrp$spare_1 in other^.rrp) and
             not (rrp$spare_1 in victim^.rrp) then
            victim := other
          else begin
            cheaper := other^.cost.r < victim^.cost.r;
            if (cheaper and (rrp$spare_1 in other^.rrp)) =
               (rrp$spare_1 in victim^.rrp) then
              victim := other;
          end;
    end;
    c := ra_conf_ptr_t(integer32(c) & (~3));
  end;
  ra_$pick_spill_lr := found;
end;

{ ra_$try_opening_another_register - one more register added to regs (in
  the integer pass not the return address's register); one the
  conventions preserve costs saving bytes (ra_save_bytes: 4, a pair 8)
  and may make the frame needed.  false when none is left.

  0x26C640, 0x132 bytes, internal: the opening works on a copy. }

function ra_$try_opening_another_register(
    rtn: rtn_ptr_t;
    var regs: ra_set64_t): boolean; options(val_param); internal;
var
  t: ra_set64_t;
  reg: integer32;
  paired: boolean;
begin
  t.hi := regs.hi;
  t.lo := regs.lo;
  if ra_final then begin
    t.lo := t.lo + [lr_ptr_t(rtn^.l112)^.f2.physical_register_number];
    if not ra_$open_another_ip_register(t, ra_rtn_ptr_t(rtn)^.conv, reg,
        paired) then begin
      ra_$try_opening_another_register := false;
      return;
    end;
    if not paired then
      ra_save_bytes := ra_save_bytes + 4;
    regs.lo := regs.lo + [reg mod 32];
  end
  else begin
    if not ra_$open_another_fp_register(t, ra_rtn_ptr_t(rtn)^.conv, reg,
        paired) then begin
      ra_$try_opening_another_register := false;
      return;
    end;
    if not paired then
      if ra_class = ra_pair then
        ra_save_bytes := ra_save_bytes + 8
      else
        ra_save_bytes := ra_save_bytes + 4;
    if reg < 32 then
      regs.lo := regs.lo + [reg mod 32]
    else
      regs.hi := regs.hi + [reg mod 32];
  end;
  if ra_save_bytes + ra_save_ip + ra_rtn_ptr_t(rtn)^.frame_size > 24 then
    rtn^.f226.needs_frame := true;
  ra_$try_opening_another_register := true;
end;

{ ra_$assign_registers - registers for the live ranges in allocation
  order (chained at +52): each takes, from the allowed registers less
  its conflicting ones (opening another register when none is left),
  by preference: its home live range's, the ENTRY's physical register
  its one definition copies, an assigned live range's it prefers
  (avoiding those it averts, unless that empties the choice: then a
  register is opened and the choice rescanned, or the aversion
  ignored), registers its conflicts and their homes do not prefer, the
  registers of its dead segments' writes and definitions' reads, its
  own preferenced set; then, from a rotating start, a register already
  written, else any (in the pair class the even one, the odd for an
  fp_reg_odd_only half; its mate the other).  An assigned register goes
  into its home's preferences, the written sets (a true write) and its
  conflicts' conflicting sets, and its preference closure.  With no
  register left, the live range (or, never spilled, the conflict
  ra_$pick_spill_lr picks) is spilled with its mate, victim set and the
  result false.  Traced with trace (verbose: the conflicts' new sets).

  0x26C772, 0x982 bytes, internal: the candidates in D6/D5 (hi, lo);
  the bit tests' ranges by `and #31' or `sub #32'; the first search
  loops over the used sets (-24, -20), the second over the candidates. }

function ra_$assign_registers(
    rtn: rtn_ptr_t;
    order: ra_lr_ptr_t;
    in regs: ra_set64_t;
    trace: boolean;
    verbose: boolean;
    out victim: ra_lr_ptr_t): boolean; options(val_param); internal;
label
  10, 20, 21, 30, 40;
var
  allowed: ra_set64_t;
  ok, can_open: boolean;
  start: integer;
  used_hi, used_lo: bv_word_t;
  lr, h, other, v, src: ra_lr_ptr_t;
  c_hi, c_lo, t_hi, t_lo, s_hi, s_lo, b_hi, b_lo, o_hi, o_lo: bv_word_t;
  ap, an: ra_ap_ptr_t;
  c, cn: ra_conf_ptr_t;
  d, s: ra_lts_ptr_t;
  i, i2: instr_ptr_t;
  k, r, n: integer32;
  op: opnd_ptr_t;
begin
  allowed := regs;
  if trace then begin
    vfmt_$write('Allowed: %$');
    dmp_$reg_set(allowed.hi, allowed.lo);
    vfmt_$write('%.');
  end;
  ok := true;
  victim := nil;
  can_open := true;
  start := 0;
  used_hi := [];
  used_lo := [];
  lr := order;
  while lr <> nil do begin
    if trace then
      vfmt_$write('%3ZWD%.', lr^.num);
    if lr^.f2.spilled then begin
      if trace then
        vfmt_$write(' Spill victim.%.');
      goto 40;
    end;
    if lr^.f2.physical_register then begin
      r := lr^.f2.physical_register_number;
      goto 30;
    end;
    if get_lr_equivalence_class_parent(lr) <> lr then begin
      if trace then
        vfmt_$write('  Wait for mate.%.');
      goto 40;
    end;
10:
    c_hi := allowed.hi - lr^.avoid_hi;
    c_lo := allowed.lo - lr^.avoid_lo;
    if trace then begin
      vfmt_$write('  Candidates:  %$');
      dmp_$reg_set(c_hi, c_lo);
      vfmt_$write('  Conflicts:   %$');
      dmp_$reg_set(lr^.avoid_hi, lr^.avoid_lo);
      if ra_pref_ptr_t(lr)^.hi + ra_pref_ptr_t(lr)^.lo <> [] then begin
        vfmt_$write('  Preferences: %$');
        dmp_$reg_set(ra_pref_ptr_t(lr)^.hi, ra_pref_ptr_t(lr)^.lo);
      end;
    end;
    if can_open and (c_hi + c_lo = []) then begin
      can_open := ra_$try_opening_another_register(rtn, allowed);
      c_hi := allowed.hi - lr^.avoid_hi;
      c_lo := allowed.lo - lr^.avoid_lo;
      if can_open and trace then begin
        vfmt_$write('  ** opening another register to avoid spilling; new candidates:  %$');
        dmp_$reg_set(c_hi, c_lo);
      end;
    end;
    if c_hi + c_lo = [] then begin
      if trace then
        vfmt_$write(' !!! Spill victim !!!%.');
      if not (rrp$life_mark in lr^.rrp) then
        v := lr
      else begin
        if not ra_$pick_spill_lr(lr, v) then
          bug_check('RA_$ASSIGN_REGISTERS -- no spill victim to pick%$');
        if trace then
          vfmt_$write('Spilling %3ZWD instead%.', v^.num);
      end;
      if v <> nil then begin
        ra_$spill_lr(v);
        if v^.mate <> nil then
          ra_$spill_lr(v^.mate);
        victim := v;
      end;
      ok := false;
      goto 40;
    end;
    h := lr^.home_lr;
    if h <> nil then begin
      t_hi := c_hi * ra_pref_ptr_t(h)^.hi;
      t_lo := c_lo * ra_pref_ptr_t(h)^.lo;
      if t_hi + t_lo <> [] then begin
        c_hi := t_hi;
        c_lo := t_lo;
      end;
      t_hi := c_hi - h^.avoid_hi;
      t_lo := c_lo - h^.avoid_lo;
      if t_hi + t_lo <> [] then begin
        c_hi := t_hi;
        c_lo := t_lo;
      end;
    end;
    d := lr^.defs;
    if d <> nil then
      if d^.next_def = nil then begin
        op := d^.refs;
        i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
        if i^.h.preference then begin
          s := ra_lts_ptr_t(i^.opnds[1].lts);
          op := s^.refs;
          i2 := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
          if i2^.opc = ord(opc$entry) then begin
            src := s^.lr;
            if src^.f2.physical_register then begin
              r := src^.f2.physical_register_number;
              if r <= 31 then begin
                if (r mod 32) in c_lo then
                  goto 20;
              end
              else if (r mod 32) in c_hi then
                goto 20;
            end;
          end;
        end;
      end;
    ap := lr^.aps;
    while ap <> nil do begin
      k := ap^.pref - ap^.avoid;
      if ap^.a = lr then begin
        other := ap^.b;
        an := ap^.next_a;
      end
      else begin
        other := ap^.a;
        an := ap^.next_b;
      end;
      if k <> 0 then begin
        r := other^.f2.physical_register_number;
        if k > 0 then begin
          if other^.f2.physical_register then begin
            if r <= 31 then begin
              if (r mod 32) in c_lo then
                goto 20;
            end
            else if (r mod 32) in c_hi then
              goto 20;
          end
          else begin
            t_hi := c_hi - other^.avoid_hi;
            t_lo := c_lo - other^.avoid_lo;
            if t_hi + t_lo <> [] then begin
              c_hi := t_hi;
              c_lo := t_lo;
            end;
            h := other^.home_lr;
            if h <> nil then begin
              t_hi := c_hi - h^.avoid_hi;
              t_lo := c_lo - h^.avoid_lo;
              if t_hi + t_lo <> [] then begin
                c_hi := t_hi;
                c_lo := t_lo;
              end;
            end;
          end;
        end
        else begin
          s_hi := c_hi;
          s_lo := c_lo;
          if other^.f2.physical_register then begin
            if r <= 31 then
              c_lo := c_lo - [r mod 32]
            else
              c_hi := c_hi - [r mod 32];
            if trace then begin
              vfmt_$write('  -- aversion to LR %3ZWD assigned to %2ZLD; new candidates: %$',
                  other^.num, r);
              dmp_$reg_set(c_hi, c_lo);
            end;
          end;
          if c_hi + c_lo = [] then begin
            if can_open then begin
              can_open := ra_$try_opening_another_register(rtn, allowed);
              if can_open then begin
                if trace then
                  vfmt_$write('  !! opened another register; rescanning...%.');
                goto 10;
              end;
            end;
            if c_hi + c_lo = [] then begin
              c_hi := s_hi;
              c_lo := s_lo;
              if trace then begin
                vfmt_$write('  -- restoring candidates;       new candidates: %$');
                dmp_$reg_set(c_hi, c_lo);
              end;
            end;
          end;
        end;
      end;
      ap := an;
    end;
    c := lr^.x44.conf;
    while c <> nil do begin
      if c^.a = lr then begin
        other := c^.b;
        cn := c^.next_a;
      end
      else begin
        other := c^.a;
        cn := c^.f12.next_b;
      end;
      t_hi := c_hi - ra_pref_ptr_t(other)^.hi;
      t_lo := c_lo - ra_pref_ptr_t(other)^.lo;
      if t_hi + t_lo <> [] then begin
        c_hi := t_hi;
        c_lo := t_lo;
      end;
      h := other^.home_lr;
      if h <> nil then begin
        t_hi := c_hi - ra_pref_ptr_t(h)^.hi;
        t_lo := c_lo - ra_pref_ptr_t(h)^.lo;
        if t_hi + t_lo <> [] then begin
          c_hi := t_hi;
          c_lo := t_lo;
        end;
      end;
      c := ra_conf_ptr_t(integer32(cn) & (~3));
    end;
    s := lr^.dead;
    while s <> nil do begin
      op := s^.refs;
      i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
      for n := i^.h.nopnds downto 1 do
        if ord(i^.opnds[n].h.kind) = ra_class then
          if i^.opnds[n].h.write then begin
            other := ra_lts_ptr_t(i^.opnds[n].lts)^.lr;
            if other^.f2.physical_register then begin
              r := other^.f2.physical_register_number;
              if r <= 31 then begin
                if (r mod 32) in c_lo then
                  goto 20;
              end
              else if (r mod 32) in c_hi then
                goto 20;
            end;
          end;
      s := ra_lts_ptr_t(s^.last_ref);
    end;
    s := lr^.defs;
    while s <> nil do begin
      op := s^.refs;
      i := instr_ptr_t(integer32(op) - 32 - 12 * op^.h.num);
      for n := i^.h.nopnds downto 1 do
        if ord(i^.opnds[n].h.kind) = ra_class then
          if i^.opnds[n].h.read then begin
            other := ra_lts_ptr_t(i^.opnds[n].lts)^.lr;
            if other^.f2.physical_register then begin
              r := other^.f2.physical_register_number;
              if r <= 31 then begin
                if (r mod 32) in c_lo then
                  goto 20;
              end
              else if (r mod 32) in c_hi then
                goto 20;
            end;
          end;
      s := s^.next_def;
    end;
    t_hi := c_hi * ra_pref_ptr_t(lr)^.hi;
    t_lo := c_lo * ra_pref_ptr_t(lr)^.lo;
    if t_hi + t_lo <> [] then begin
      c_hi := t_hi;
      c_lo := t_lo;
    end;
    for r := start to 31 do
      if ((r mod 32) in c_lo) and ((r mod 32) in used_lo) then
        goto 21;
    for r := 32 to 63 do
      if ((r mod 32) in c_hi) and ((r mod 32) in used_hi) then
        goto 21;
    for r := 0 to 31 do
      if ((r mod 32) in c_lo) and ((r mod 32) in used_lo) then
        goto 21;
    for r := 32 to 63 do
      if ((r mod 32) in c_hi) and ((r mod 32) in used_hi) then
        goto 21;
    for r := start to 31 do
      if r in c_lo then
        goto 21;
    for r := 32 to 63 do
      if (r - 32) in c_hi then
        goto 21;
    for r := 0 to 31 do
      if r in c_lo then
        goto 21;
    for r := 32 to 63 do
      if (r - 32) in c_hi then
        goto 21;
    bug_check('RA_$ASSIGN_REGISTERS -- could not find the candidate%$');
21:
    start := r + 1;
20:
    if ra_class = ra_pair then
      r := (r & (~1)) ! ord(rrp$fp_reg_odd_only in lr^.rrp);
    lr^.f2.physical_register_number := r;
    lr^.f2.physical_register := true;
    if lr^.mate <> nil then begin
      lr^.mate^.f2.physical_register_number := xor(r, 1);
      lr^.mate^.f2.physical_register := true;
    end;
30:
    if r <= 31 then begin
      b_hi := [];
      b_lo := [r mod 32];
    end
    else begin
      b_hi := [r mod 32];
      b_lo := [];
    end;
    h := lr^.home_lr;
    if h <> nil then begin
      ra_pref_ptr_t(h)^.hi := ra_pref_ptr_t(h)^.hi + b_hi;
      ra_pref_ptr_t(h)^.lo := ra_pref_ptr_t(h)^.lo + b_lo;
    end;
    if rrp$true_write in lr^.rrp then
      if rrp$ip_reg in lr^.rrp then begin
        rtn^.written_ip := rtn^.written_ip ! integer32(b_lo);
        used_lo := used_lo + b_lo;
      end
      else begin
        rtn^.written_fp[0] := rtn^.written_fp[0] ! integer32(b_hi);
        rtn^.written_fp[1] := rtn^.written_fp[1] ! integer32(b_lo);
        used_hi := used_hi + b_hi;
        used_lo := used_lo + b_lo;
      end;
    c := lr^.x44.conf;
    while c <> nil do begin
      if c^.a = lr then begin
        other := c^.b;
        cn := c^.next_a;
      end
      else begin
        other := c^.a;
        cn := c^.f12.next_b;
      end;
      if verbose then begin
        o_hi := other^.avoid_hi;
        o_lo := other^.avoid_lo;
      end;
      other^.avoid_hi := other^.avoid_hi + b_hi;
      other^.avoid_lo := other^.avoid_lo + b_lo;
      h := other^.home_lr;
      if h <> nil then begin
        h^.avoid_hi := h^.avoid_hi + b_hi;
        h^.avoid_lo := h^.avoid_lo + b_lo;
      end;
      if verbose then
        if (other^.avoid_hi <> o_hi) or (other^.avoid_lo <> o_lo) then begin
          vfmt_$write('  %3ZWD new conflicts: %$', other^.num);
          dmp_$reg_set(other^.avoid_hi, other^.avoid_lo);
        end;
      c := ra_conf_ptr_t(integer32(cn) & (~3));
    end;
    ra_$zero_closure_next_fields(
        ra_$close_live_range_preferences(lr, nil, b_hi, b_lo));
40:
    lr := lr^.x52.lr;
  end;
  ra_$assign_registers := ok;
end;

{ ra_$relocate_automatic_storage - the stack frame's objects moved past
  the frame's fixed part (lir_main_c6c) and taken off ra_frame_objs'
  chain; with a frame, the argument pointer's object at 0 and +112's
  at 8.

  0x26D2F8, 0x88 bytes, internal. }

procedure ra_$relocate_automatic_storage(
    rtn: rtn_ptr_t); options(val_param); internal;
var
  off: integer32;
  v, nxt: ra_var_ptr_t;
begin
  off := lir_main_c6c;
  v := ra_frame_objs;
  while v <> nil do begin
    if v^.kind = var_name then begin
      v^.offset := v^.offset + off;
      nxt := v^.next;
      v^.next := nil;
    end
    else begin
      ra_fsym_ptr_t(v)^.offset := ra_fsym_ptr_t(v)^.offset + off;
      nxt := ra_fsym_ptr_t(v)^.next;
      ra_fsym_ptr_t(v)^.next := nil;
    end;
    v := nxt;
  end;
  if rtn^.f226.needs_frame then begin
    v := ra_var_ptr_t(rtn^.ap_lr^.node20);
    if v^.kind = var_name then
      v^.offset := 0
    else
      ra_fsym_ptr_t(v)^.offset := 0;
    v := ra_var_ptr_t(lr_ptr_t(rtn^.l112)^.node20);
    if v^.kind = var_name then
      v^.offset := 8
    else
      ra_fsym_ptr_t(v)^.offset := 8;
  end;
end;

{ ra_$accumulate_true_writes - the registers the routine writes: the
  calls' and SVCs' clobbers and every assigned register written or
  modified (a pair's both halves; the integer set for an ip_reg
  operand, the floating sets for the other register kinds), but by the
  ENTRY or by a move of a register to itself that sets no condition
  codes.

  0x26D380, 0x19C bytes, internal: the register kinds as the mask 126;
  the move's sets_cc tested `btst D2,(A0)' with D2 still the class
  mask 0x100004 (bit 4 modulo 8: pattern 148). }

procedure ra_$accumulate_true_writes(
    rtn: rtn_ptr_t); options(val_param); internal;
label
  10;
var
  bb: bb_ptr_t;
  i: instr_ptr_t;
  attr: instr_attr_ptr_t;
  clob: ra_clob_ptr_t;
  k: integer32;
  r: integer;
  bits: bv_word_t;
begin
  bb := rtn^.bbs;
  while bb <> nil do begin
    i := bb^.first;
    while i <> nil do begin
      attr := addr(instruction_attributes[i^.opc]);
      if attr^.class in [class$call, class$svc] then begin
        clob := univ_ptr(addr(i^.opnds[i^.h.nopnds + 1]));
        rtn^.written_ip := rtn^.written_ip ! integer32(clob^.ip);
        rtn^.written_fp[0] := rtn^.written_fp[0] ! integer32(clob^.fp_hi);
        rtn^.written_fp[1] := rtn^.written_fp[1] ! integer32(clob^.fp_lo);
      end;
      if attr^.b6_0 and
         (i^.opnds[1].h.kind in [operand$ip_reg ..
              operand$fp_reg_pair_physical]) and
         (i^.opnds[1].h.count = 0) and not i^.h.sets_cc and
         not i^.h.fp_ccs then
        if ra_lts_ptr_t(i^.opnds[1].lts)^.lr^.f2.physical_register_number =
           ra_lts_ptr_t(i^.opnds[2].lts)^.lr^.f2.physical_register_number then
          goto 10;
      if i^.opc <> ord(opc$entry) then
        for k := 1 to i^.h.nopnds do
          if (opnd_bytes_ptr_t(addr(i^.opnds[k]))^.rrp & 12) <> 0 then
            if i^.opnds[k].h.kind in [operand$ip_reg ..
                operand$fp_reg_pair_physical] then begin
              r := ra_lts_ptr_t(i^.opnds[k].lts)^.lr^.f2.physical_register_number;
              bits := [r mod 32];
              if i^.opnds[k].h.kind = operand$fp_reg_pair then
                bits := bits + [(xor(r, 1)) mod 32];
              if i^.opnds[k].h.kind = operand$ip_reg then
                rtn^.written_ip := rtn^.written_ip ! integer32(bits)
              else if r <= 31 then
                rtn^.written_fp[1] := rtn^.written_fp[1] ! integer32(bits)
              else
                rtn^.written_fp[0] := rtn^.written_fp[0] ! integer32(bits);
            end;
10:
      i := i^.next;
    end;
    bb := bb^.next;
  end;
end;

{ ra_$spill_zero_cost_lrs - false at once: the body (complex live
  ranges whose cost is below 1.0e-4 marked spill victims, the marks
  cleared, the spill code added, the frame and the RETURN's argument
  pointer read settled) is jumped over (pattern 101), its loop's live
  range never set.

  0x26D51C, 0xF4 bytes, internal: `clr.b D0; bra.w' to the epilogue; the
  cost compared through fpp_$eslv 0x0050 0x38D1B717. }

function ra_$spill_zero_cost_lrs(
    rtn: rtn_ptr_t): boolean; options(val_param); internal;
var
  lr: ra_lr_ptr_t;
  s: ra_lts_ptr_t;
  ap: ra_lr_ptr_t;
begin
  ra_$spill_zero_cost_lrs := false;
  return;
  while lr <> nil do begin
    if lr^.id <> 0 then
      if not lr^.f2.physical_register and not (rrp$life_mark in lr^.rrp) and
         not lr^.f2.spilled then
        if lr^.cost.r < 1.0e-4 then begin
          lr^.f2.spilled := true;
          if lr^.mate <> nil then
            lr^.mate^.f2.spilled := true;
        end;
    lr := lr^.next;
  end;
  lr := ra_lrs;
  while lr <> nil do begin
    lr^.rrp := lr^.rrp - [rrp$ra_marked];
    s := lr^.ltss;
    while s <> nil do begin
      s^.rrp := s^.rrp - [rrp$ra_marked];
      s := s^.next;
    end;
    lr := lr^.next;
  end;
  rtn^.lrs := lr_ptr_t(ra_lrs);
  ra_utils_$add_spill_code(rtn, operand$t(ra_class), 0);
  if ra_rtn_ptr_t(rtn)^.frame_size > 24 then
    rtn^.f226.needs_frame := true;
  ap := ra_lr_ptr_t(rtn^.ap_lr);
  if ap^.f2.spilled and rtn^.f226.needs_frame and
     not rtn^.f226.no_return_block and (rrp$read in ap^.rrp) then
    rtn^.return_instr^.opnds[3].h.kind := operand$none;
  ra_$spill_zero_cost_lrs := true;
end;

{ RA_$PROCESS_ROUTINE - the routine's registers: the heaps made (the
  conflict heaps' names in the reverse of their use, "cc" for the
  simple x simple records: a slip of the original), a map of the live
  ranges by number from the heap, the register files under the
  conventions; then for each class, pairs first and the integer
  registers last (ra_final), passes until an assignment succeeds:
  initialize, count the registers that can be opened, build the
  conflict graph, collapse it, close the preferences of the live
  ranges assigned already, open the registers the chromatic number
  needs, assign; a failure undoes the assignments and adds the spill
  code (pass 0 up to the fifth, 1 to the seventh, 2 after or with
  lir_main_da4), more than 15 passes being a bug.  Each class's live
  ranges go into the map.  Then without a frame the argument pointer
  and the conventions' b30 live ranges (and the routine's common member
  the ISC made a register candidate) share the frame register; the
  return address register settled (save_rpc when it got the zero
  register), the conventions' needs_db and the routine node's +374 bit
  19 set; the writes accumulated, the saves and restores made
  (lir_main_$save_and_restore_code), the frame's objects relocated; the
  routine's live ranges rechained from the map in number order, the
  node's +378 bit 2 the frame flag.  Dumps and traces by the switches
  (sw9 after initialization, sw10 after the conflict graph, sw12 the
  counts, sw13 the assignment).

  0x26D610, 0x6D0 bytes (A5): the map 262144 bytes (the size a constant
  after the strings, by address); the class's letter for %m1a from
  ra_letters at A5 + 0x65B + class; isc_$get_il_live_range called with
  combine_with_sf's second argument already pushed (pattern 103); the
  node's +374 field `lsr.l #11' with bit 8 replaced. }

procedure ra_$process_routine;
label
  10;
var
  map: ra_lrs_ptr_t;
  start, pass, k, n, cheap, chrom, needed, w, t: integer32;
  flushed, order, lr, victim, ap: ra_lr_ptr_t;
  r: integer;
  b_hi, b_lo: bv_word_t;
  regs: ra_set64_t;
  mode: integer;
  conv: call_conv_$ptr_t;
  ret: instr_ptr_t;
  node: univ_ptr;
  s: ra_lts_ptr_t;
  bytes: integer32;
begin
  utils_$strip_extraneous_modifies(rtn);
  mrh_$initialize(ra_conf_heaps[0], 0, 16, 'ra cc conflict heap%');
  mrh_$initialize(ra_conf_heaps[1], 0, 16, 'ra sc conflict heap%');
  mrh_$initialize(ra_conf_heaps[2], 0, 16, 'ra ss conflict heap%');
  mrh_$initialize(ra_ap_heaps[0], 0, 32, 'ra ss real A/P heap%');
  mrh_$initialize(ra_ap_heaps[1], 0, 32, 'ra sc real A/P heap%');
  mrh_$initialize(ra_ap_heaps[2], 0, 32, 'ra cc real A/P heap%');
  mrh_$initialize(ra_pend_bb_heap, 0, 16, 'ra pending aversion BB heap%');
  mrh_$initialize(ra_pend_xx_heap, 0, 16, 'ra pending aversion xx heap%');
  bytes := 16#40000;
  map := rws_$alloc_heap(bytes);
  if map = nil then
    bug_check('RA_$PROCESS_ROUTINE -- failed (no disk space?)%$');
  start := 0;
  ra_save_ip := 0;
  ra_save_bytes := 0;
  ra_$determine_available_registers(ra_rtn_ptr_t(rtn)^.conv);
  ra_frame_objs := nil;
  ra_class := ra_pair;
  ra_check_db := true;
  repeat
    ra_final := ra_class = ra_ip;
    pass := 1;
10:
    ra_$initialize_routine(rtn);
    if ra_$spill_zero_cost_lrs(rtn) then begin
      bv_$release_bit_vectors(rtn);
      ra_$initialize_routine(rtn);
    end;
    if at_backend_switches.sw9 then begin
      vfmt_$write('%/%/%a  DUMP FOLLOWING CALL TO "ra_$initialize_routine"%/%.',
          ra_titles[ra_class], ra_title_len[ra_class]);
      dmp_$all_basic_block_headers(rtn);
    end;
    ra_$count_available_registers(rtn, n, cheap);
    if at_backend_switches.sw12 then
      vfmt_$write('RA_$COUNT_AVAILABLE_REGISTERS = %LD, CHEAP = %LD.%.', n,
          cheap);
    mrh_$release_all(ra_conf_heaps[0]);
    mrh_$release_all(ra_conf_heaps[1]);
    mrh_$release_all(ra_conf_heaps[2]);
    mrh_$release_all(ra_ap_heaps[0]);
    mrh_$release_all(ra_ap_heaps[1]);
    mrh_$release_all(ra_ap_heaps[2]);
    mrh_$release_all(ra_pend_bb_heap);
    mrh_$release_all(ra_pend_xx_heap);
    ra_$build_conflict_graph(rtn, [ra_class], false);
    if at_backend_switches.sw10 then begin
      vfmt_$write('%/%/%a  DUMP FOLLOWING CALL TO "ra_$build_conflict_graph"%/%.',
          ra_titles[ra_class], ra_title_len[ra_class]);
      dmp_$all_basic_block_headers(rtn);
    end;
    bv_$release_bit_vectors(rtn);
    chrom := ra_$collapse_conflict_graph(n, cheap, flushed, order,
        at_backend_switches.sw12);
    lr := flushed;
    while lr <> nil do begin
      r := lr^.f2.physical_register_number;
      if r <= 31 then begin
        b_hi := [];
        b_lo := [r mod 32];
      end
      else begin
        b_hi := [r mod 32];
        b_lo := [];
      end;
      ra_$zero_closure_next_fields(
          ra_$close_live_range_preferences(lr, nil, b_hi, b_lo));
      lr := lr^.x52.lr;
    end;
    ra_$open_registers(rtn, chrom, n, regs.hi, regs.lo, needed);
    if at_backend_switches.sw12 then
      vfmt_$write('RA_$OPEN_REGISTERS: needed = %LD.%.', needed);
    if not ra_$assign_registers(rtn, order, regs, at_backend_switches.sw13,
        at_backend_switches.sw13 and (ra_650 > 3), victim) then begin
      lr := order;
      while lr <> nil do begin
        lr^.f2.physical_register := false;
        lr^.f2.physical_register_number := 0;
        lr^.rrp := lr^.rrp - [rrp$ra_marked];
        s := lr^.ltss;
        while s <> nil do begin
          s^.rrp := s^.rrp - [rrp$ra_marked];
          s := s^.next;
        end;
        lr := lr^.x52.lr;
      end;
      if pass > 15 then begin
        if at_backend_switches.sw4 then begin
          vfmt_$write('RA_$PROCESS_ROUTINE -- no success spilling %m1aP registers, LR %3ZWD%.',
              ra_letters[ra_class], victim^.num);
          dmp_$whole_routine(rtn, at_backend_switches.sw5, true);
        end;
        bug_check('RA_$PROCESS_ROUTINE -- no success spilling %m1aP registers, LR %3ZWD%$',
            ra_letters[ra_class], victim^.num);
        goto 10;
      end;
      rtn^.lrs := lr_ptr_t(ra_lrs);
      if lir_main_da4 or (pass > 7) then
        mode := 2
      else if pass > 5 then
        mode := 1
      else
        mode := 0;
      ra_utils_$add_spill_code(rtn, operand$t(ra_class), mode);
      if ra_rtn_ptr_t(rtn)^.frame_size > 24 then
        rtn^.f226.needs_frame := true;
      ap := ra_lr_ptr_t(rtn^.ap_lr);
      if ap^.f2.spilled and rtn^.f226.needs_frame and
         not rtn^.f226.no_return_block and (rrp$read in ap^.rrp) then
        rtn^.return_instr^.opnds[3].h.kind := operand$none;
      pass := pass + 1;
      goto 10;
    end;
    for k := start to rtn^.l200 do
      map^[k] := nil;
    start := rtn^.l200 + 1;
    lr := ra_lrs;
    while lr <> nil do begin
      map^[lr^.num] := lr;
      lr := lr^.next;
    end;
    ra_class := ra_class - 1;
  until ra_class = 0;
  conv := ra_rtn_ptr_t(rtn)^.conv;
  if not rtn^.f226.needs_frame then begin
    ap := ra_lr_ptr_t(rtn^.ap_lr);
    if rrp$read in ap^.rrp then begin
      ret := rtn^.return_instr;
      if ra_lts_ptr_t(ret^.opnds[3].lts)^.lr <> ap then
        bug_check('RA_$INITIALIZE_ROUTINE -- AP operand in RETURN not in expected position%$');
      if ret^.opnds[3].h.kind = operand$ip_reg then
        ra_$combine_with_sf(ap, conv);
    end;
    if conv^.b30 then begin
      ra_$combine_with_sf(ra_rtn_ptr_t(rtn)^.lr120, conv);
      node := ra_ptrs_ptr_t(rtn^.node)^[60];
      if node <> nil then
        if isc_$is_a_register_candidate(node) then
          ra_$combine_with_sf(ra_lr_ptr_t(isc_$get_il_live_range(node)), conv);
    end;
  end;
  lr := ra_lr_ptr_t(rtn^.l112);
  if lr^.f2.physical_register_number = ra_ip_zero then
    rtn^.f226.save_rpc := true;
  lr^.f2.physical_register_number := conv^.w14 & 255;
  conv^.needs_db := rtn^.f226.needs_db;
  w := ra_longs_ptr_t(univ_ptr(integer32(rtn^.node) + 374))^[1];
  t := rshft(w, 11) & (~16#100);
  if conv^.needs_db then
    t := t ! 16#100;
  ra_longs_ptr_t(univ_ptr(integer32(rtn^.node) + 374))^[1] :=
      (w & 2047) ! lshft(t, 11);
  ra_$accumulate_true_writes(rtn);
  lir_main_$save_and_restore_code(rtn);
  ra_$relocate_automatic_storage(rtn);
  bv_$release_bit_vectors(rtn);
  mrh_$release_all(ra_conf_heaps[0]);
  mrh_$release_all(ra_conf_heaps[1]);
  mrh_$release_all(ra_conf_heaps[2]);
  mrh_$release_all(ra_ap_heaps[0]);
  mrh_$release_all(ra_ap_heaps[1]);
  mrh_$release_all(ra_ap_heaps[2]);
  mrh_$release_all(ra_pend_bb_heap);
  mrh_$release_all(ra_pend_xx_heap);
  lr := nil;
  for k := rtn^.l200 downto 0 do
    if map^[k] <> nil then begin
      map^[k]^.next := lr;
      lr := map^[k];
    end;
  rtn^.lrs := lr_ptr_t(lr);
  if rtn^.f226.needs_frame then
    ra_bytes_ptr_t(rtn^.node)^[378] := chr(ord(ra_bytes_ptr_t(rtn^.node)^[378]) ! 4)
  else
    ra_bytes_ptr_t(rtn^.node)^[378] := chr(ord(ra_bytes_ptr_t(rtn^.node)^[378]) & 251);
  ra_$release_rws_storage(map);
end;

{ RA_$END_ROUTINE - nothing.  0x26DF22, 2 bytes (no A5). }

procedure ra_$end_routine;
begin
end;
