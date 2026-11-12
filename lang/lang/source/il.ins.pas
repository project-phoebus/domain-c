{ lang/lang/source/il.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/il.pas (initialize_module) and the IL node types.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ The IL node kinds, as the image names them: add_node writes a kind as
  an enumerated value (PAS_$WRITE code 3877), and the run time's name
  table for the type follows add_node_$dispose_top_level (cc.m68k
  0x0A06A6, cc.a88k 0x0A2086; cc.a88k has the same 237 names after
  dmp_$instruction, the ISC's printers and alignment_from_sr_info:
  tools/cc_enumnames.py).  0 end_ob .. 104 signed_cob are the tokens,
  105 program_blk .. 236 union_ob the IL's nodes.  A value is a word, as
  the nodes' kind field is.

  The ISC's il$t (isc_enumeration.ins.pas) is another type: the
  generator's alphabetical classification of the kinds and operators it
  has patterns for (docs/questions.md 78).

  Not known from the original: the type's name. }

type
  il_$kind_t = (
    end_ob,                           { 0 }
    if_ob,                            { 1 }
    then_ob,                          { 2 }
    begin_ob,                         { 3 }
    else_ob,                          { 4 }
    do_ob,                            { 5 }
    with_ob,                          { 6 }
    in_ob,                            { 7 }
    of_ob,                            { 8 }
    while_ob,                         { 9 }
    case_ob,                          { 10 }
    repeat_ob,                        { 11 }
    until_ob,                         { 12 }
    procedure_ob,                     { 13 }
    var_ob,                           { 14 }
    for_ob,                           { 15 }
    array_ob,                         { 16 }
    record_ob,                        { 17 }
    set_ob,                           { 18 }
    to_ob,                            { 19 }
    downto_ob,                        { 20 }
    mod_ob,                           { 21 }
    or_ob,                            { 22 }
    and_ob,                           { 23 }
    not_ob,                           { 24 }
    div_ob,                           { 25 }
    const_ob,                         { 26 }
    type_ob,                          { 27 }
    function_ob,                      { 28 }
    program_ob,                       { 29 }
    packed_ob,                        { 30 }
    label_ob,                         { 31 }
    goto_ob,                          { 32 }
    file_ob,                          { 33 }
    forward_ob,                       { 34 }
    static_ob,                        { 35 }
    external_ob,                      { 36 }
    define_ob,                        { 37 }
    module_ob,                        { 38 }
    val_param_ob,                     { 39 }
    exit_ob,                          { 40 }
    next_ob,                          { 41 }
    internal_ob,                      { 42 }
    return_ob,                        { 43 }
    otherwise_ob,                     { 44 }
    cast_ob,                          { 45 }
    univ_ob,                          { 46 }
    implies_ob,                       { 47 }
    out_ob,                           { 48 }
    up_to_ob,                         { 49 }
    bus_ob,                           { 50 }
    period_ob,                        { 51 }
    becomes_ob,                       { 52 }
    colon_ob,                         { 53 }
    le_ob,                            { 54 }
    ne_ob,                            { 55 }
    lt_ob,                            { 56 }
    eq_ob,                            { 57 }
    ge_ob,                            { 58 }
    gt_ob,                            { 59 }
    sub_ob,                           { 60 }
    open_ob,                          { 61 }
    close_ob,                         { 62 }
    comma_ob,                         { 63 }
    semicolon_ob,                     { 64 }
    star_ob,                          { 65 }
    slash_ob,                         { 66 }
    plus_ob,                          { 67 }
    minus_ob,                         { 68 }
    ampersand_ob,                     { 69 }
    excl_ob,                          { 70 }
    arrow_ob,                         { 71 }
    eom_ob,                           { 72 }
    error_ob,                         { 73 }
    tilde_ob,                         { 74 }
    badchar_ob,                       { 75 }
    id_ob,                            { 76 }
    blogical_ob,                      { 77 }
    slogical_ob,                      { 78 }
    llogical_ob,                      { 79 }
    sinteger_ob,                      { 80 }
    integer_ob,                       { 81 }
    linteger_ob,                      { 82 }
    usinteger_ob,                     { 83 }
    uinteger_ob,                      { 84 }
    ulinteger_ob,                     { 85 }
    ubinteger_ob,                     { 86 }
    char_ob,                          { 87 }
    real_ob,                          { 88 }
    dpreal_ob,                        { 89 }
    complex_ob,                       { 90 }
    varying_ob,                       { 91 }
    char_string_ob,                   { 92 }
    char32_string_ob,                 { 93 }
    nil_ob,                           { 94 }
    starstar_ob,                      { 95 }
    routine_option_ob,                { 96 }
    attribute_ob,                     { 97 }
    begin_critical_ob,                { 98 }
    end_critical_ob,                  { 99 }
    library_ob,                       { 100 }
    char16_ob,                        { 101 }
    const_cob,                        { 102 }
    volatile_cob,                     { 103 }
    signed_cob,                       { 104 }
    program_blk,                      { 105 }
    module_blk,                       { 106 }
    procedure_blk,                    { 107 }
    function_blk,                     { 108 }
    var_name,                         { 109 }
    fortran_symbol,                   { 110 }
    common_block_name,                { 111 }
    fdim_info,                        { 112 }
    fdata_nlist,                      { 113 }
    fdata_clist,                      { 114 }
    equiv_stmt,                       { 115 }
    const_name,                       { 116 }
    label_name,                       { 117 }
    type_name,                        { 118 }
    field_name,                       { 119 }
    pfield_name,                      { 120 }
    param_name,                       { 121 }
    integer_type,                     { 122 }
    real_type,                        { 123 }
    bool_type,                        { 124 }
    char_type,                        { 125 }
    char_string_con_type,             { 126 }
    char_array_type,                  { 127 }
    subr_type,                        { 128 }
    enum_type,                        { 129 }
    ptr_type,                         { 130 }
    array_type,                       { 131 }
    record_type,                      { 132 }
    file_type,                        { 133 }
    set_type,                         { 134 }
    univ_ptr_type,                    { 135 }
    null_set_type,                    { 136 }
    tree_node,                        { 137 }
    gen_tree_node,                    { 138 }
    eval_node,                        { 139 }
    assign_node,                      { 140 }
    branch_node,                      { 141 }
    cbranch_node,                     { 142 }
    cmp_tree_node,                    { 143 }
    label_node,                       { 144 }
    dindex_node,                      { 145 }
    ptr_node,                         { 146 }
    disp_node,                        { 147 }
    block_entry_node,                 { 148 }
    blk_end_node,                     { 149 }
    nlbranch_node,                    { 150 }
    return_node,                      { 151 }
    alloc_temp,                       { 152 }
    sb_register,                      { 153 }
    db_register,                      { 154 }
    display_register,                 { 155 }
    set_con_ob,                       { 156 }
    def_const_ob,                     { 157 }
    std_func,                         { 158 }
    lib_dsc,                          { 159 }
    ref_list,                         { 160 }
    state_save,                       { 161 }
    lnum_entry,                       { 162 }
    addr_con,                         { 163 }
    cs_node,                          { 164 }
    cs_temp,                          { 165 }
    fdata_do,                         { 166 }
    entry_blk,                        { 167 }
    param_list,                       { 168 }
    ftn_xref,                         { 169 }
    ptr_hdr,                          { 170 }
    cc_call,                          { 171 }
    inner_blk,                        { 172 }
    proc__type,                       { 173 }
    func__type,                       { 174 }
    pf_call,                          { 175 }
    rec_const_ob,                     { 176 }
    offset_type,                      { 177 }
    reg_assign_ob,                    { 178 }
    actparam,                         { 179 }
    ext_state_save,                   { 180 }
    dead_temp,                        { 181 }
    procedure_section,                { 182 }
    data_section,                     { 183 }
    inline_constant,                  { 184 }
    namelist_id_ob,                   { 185 }
    lnref_ob,                         { 186 }
    variant_ob,                       { 187 }
    use_def_ob,                       { 188 }
    cse_use_ob,                       { 189 }
    cse_parent_ob,                    { 190 }
    reg_list_ob,                      { 191 }
    transfer_vector,                  { 192 }
    proc_reloc,                       { 193 }
    external_ref,                     { 194 }
    reloc_absolute_addr_con,          { 195 }
    varying_type,                     { 196 }
    parray_type,                      { 197 }
    dpcomplex_ob,                     { 198 }
    m68k_unpacked,                    { 199 }
    binteger_ob,                      { 200 }
    routine_option_name,              { 201 }
    attribute_name,                   { 202 }
    physical_register_ob,             { 203 }
    argument_block_location_ob,       { 204 }
    sym_disp_node,                    { 205 }
    dynamic_array_type,               { 206 }
    dope_vector,                      { 207 }
    at_lib_dsc,                       { 208 }
    blockdata_blk,                    { 209 }
    void_type,                        { 210 }
    ap_register,                      { 211 }
    namelist_constant_ob,             { 212 }
    undefined_object,                 { 213 }
    case_node_range_check,            { 214 }
    case_node_no_range_check,         { 215 }
    defaulted_info,                   { 216 }
    char16_type,                      { 217 }
    char16_array_type,                { 218 }
    isc_fetch,                        { 219 }
    isc_convert,                      { 220 }
    fdata_default_seq,                { 221 }
    exception_frame,                  { 222 }
    exception_handler_entry,          { 223 }
    raise_exception,                  { 224 }
    release_dynamic_space,            { 225 }
    exception_register,               { 226 }
    insert_bit_field,                 { 227 }
    bit_field_assign,                 { 228 }
    lb_register,                      { 229 }
    virt_var_name,                    { 230 }
    spine_mark,                       { 231 }
    isc_share,                        { 232 }
    pa_mmu_bip,                       { 233 }
    cc_func_returning_type,           { 234 }
    indexed_reference,                { 235 }
    union_ob);                        { 236 }

{ The compiler's nodes.  Every node begins with a word not yet
  identified and the node's kind at +2 (il.pas initialize_module 0x07D882
  sets +2 of each node it creates; idntk sets it in each identifier
  entry it creates).  The variants are added as the units that build and
  read them are translated.

  Not known from the original: every name here but the kinds'. }

{ TODO(pascal) most variants are not declared yet

  IL's globals below are named by their offset in il.pas's data until
  their users are translated. }

type
  il_$node_ptr_t = ^il_$node_t;
  il_$node_t = record
    unused_0: integer;                  { +0 }
    kind: integer;                      { +2 }
    case integer of
      { An identifier, entered by idntk (strings.pas). }
      1: (idnt_next: il_$node_ptr_t;    { +4: the hash chain }
          idnt_unused_8: integer32;     { +8: cleared by idntk }
          idnt_unused_12: integer32;    { +12: cleared by idntk }
          idnt_len: integer;            { +16 }
          idnt_name: array [1..4096] of char);  { +18: sortidntk's qsort
                                          compares 4096 bytes (cmpm.b,
                                          dbne 4095), sortidentifiers
                                          puts a NUL after a name of
                                          fewer than 4096 }
      { An integer constant (smcontk; 12 bytes). }
      2: (int_next: il_$node_ptr_t;     { +4: the sorted chain }
          int_value: integer32);        { +8 }
      { A real constant (floating_token; 24 bytes). }
      3: (real_next: il_$node_ptr_t;    { +4 }
          real_unused_8: integer32;     { +8 }
          real_value: double;           { +12 }
          real_single_exact: boolean;   { +20: exactly a single }
          real_single_range: boolean);  { +21: in a single's range }
      { A pair of singles, a complex constant (kind 90; 20 bytes). }
      4: (pair_next: il_$node_ptr_t;    { +4 }
          pair_unused_8: integer32;     { +8: cleared }
          pair_a: integer32;            { +12 }
          pair_b: integer32);           { +16 }
      { A double complex constant (kind 198; 28 bytes). }
      5: (dcx_next: il_$node_ptr_t;     { +4 }
          dcx_unused_8: integer32;      { +8: cleared }
          dcx_re: double;               { +12 }
          dcx_im: double);              { +20 }
      { A string constant (strtk, kind 92; len + 18 bytes): laid out as
        an identifier.  inc_list reads an include file's name, ending in
        its closing delimiter, from such a node. }
      6: (str_next: il_$node_ptr_t;     { +4: the sorted chain }
          str_unused_8: integer32;      { +8: cleared }
          str_unused_12: integer32;     { +12: cleared }
          str_len: integer;             { +16 }
          str_chars: array [1..1024] of char);  { +18 }
      { The longwords of a real (88, 89: high, low), a pair (90) or a
        double complex (198: re high, re low, im high, im low) as
        token.pas compares them (signed, high first). }
      7: (bits_next: il_$node_ptr_t;    { +4 }
          bits_unused_8: integer32;     { +8 }
          bits: array [1..4] of integer32);  { +12 }
      { A set constant of more than 4 bytes (setcontk, kind 156; len + 18
        bytes): the bytes as words. }
      8: (set_next: il_$node_ptr_t;     { +4: its chain, by size }
          set_unused_8: integer32;      { +8: cleared }
          set_unused_12: integer32;     { +12 }
          set_len: integer;             { +16: bytes }
          set_words: array [1..2048] of integer);  { +18 }
      { A node seen by offset, for the kinds whose variants are not
        declared yet (il_utils.pas: the tree nodes 137..233, the
        variables 109 and 110, the blocks 105 and 172): xp[k] the pointer
        and xl[k] the longword at +4k, xp2[k] and xl2[k] those at +4k+2,
        xw[k] the word at +2k, xc[k] the byte at +k.  Replace uses with
        named variants as the kinds are identified. }
      9: (xp: array [1..94] of il_$node_ptr_t);     { +4 }
      10: (xp2_pad: integer;                        { +4 }
           xp2: array [1..93] of il_$node_ptr_t);   { +6 }
      11: (xl: array [1..94] of integer32);         { +4 }
      12: (xl2_pad: integer;                        { +4 }
           xl2: array [1..93] of integer32);        { +6 }
      13: (xw: array [2..189] of integer);          { +4 }
      14: (xc: array [4..379] of char);             { +4 }
  end;

var
  { IL's globals: il.pas's data, A5 0x169C70 (cc.m68k), 0x2E9CE0
    (cc.a88k).  Widths from every unit's accesses (docs/globals-cc.*.md;
    `pointer' where some unit loads the cell into an address register);
    initialize_module (il.pas) sets them up. }
  il_tab_0: extern array [0..15] of univ_ptr;          { +0x00 }
  il_tab_40: extern array [0..15] of univ_ptr;         { +0x40 }
  il_tab_80: extern array [0..15] of univ_ptr;         { +0x80 }
  il_c0: extern boolean;                               { +0xC0 }
  il_c1: extern boolean;                               { +0xC1 }
  il_c2: extern boolean;                               { +0xC2 }
  il_c3: extern boolean;                               { +0xC3 }
  il_c4: extern integer;                               { +0xC4 }
  il_c6: extern integer;                               { +0xC6 }
  il_c8: extern il_$node_ptr_t;                        { +0xC8: c_stmt_sem's
                                                         pending label chain
                                                         (through +48) }
  il_cc: extern il_$node_ptr_t;                        { +0xCC }
  il_d0: extern integer;                               { +0xD0 }
  il_d4: extern il_$node_ptr_t;                        { +0xD4: the first
                                                         top-level node
                                                         (c_stmt_sem) }
  il_d8: extern il_$node_ptr_t;                        { +0xD8: the last one
                                                         (link_top chains
                                                         them: +4 back, +8
                                                         on) }
  il_node_155: extern il_$node_ptr_t;                  { +0xDC }
  il_node_154: extern il_$node_ptr_t;                  { +0xE0 }
  il_node_153: extern il_$node_ptr_t;                  { +0xE4 }
  il_node_211: extern il_$node_ptr_t;                  { +0xE8 }
  il_node_226: extern il_$node_ptr_t;                  { +0xEC }
  il_f0: extern array [0..6] of univ_ptr;              { +0xF0 }
  il_10c: extern univ_ptr;                             { +0x10C }
  il_110: extern il_$node_ptr_t;                       { +0x110 }
  il_114: extern integer32;                            { +0x114 }
  il_118: extern il_$node_ptr_t;                       { +0x118 }
  il_11c: extern univ_ptr;                             { +0x11C }
  il_120: extern univ_ptr;                             { +0x120 }
  il_124: extern integer;                              { +0x124 }
  il_126: extern integer;                              { +0x126 }
  il_128: extern univ_ptr;                             { +0x128 }
  il_12c: extern univ_ptr;                             { +0x12C }
  il_130: extern univ_ptr;                             { +0x130 }
  il_134: extern integer32;                            { +0x134 }
  il_138: extern integer32;                            { +0x138 }
  il_13c: extern integer32;                            { +0x13C }
  il_140: extern integer;                              { +0x140 }
  il_144: extern integer;                              { +0x144 }
  il_146: extern array [0..21] of integer;             { +0x146 }
  il_172: extern integer;                              { +0x172 }
  il_174: extern il_$node_ptr_t;                       { +0x174 }
  il_178: extern il_$node_ptr_t;                       { +0x178 }
  il_17c: extern univ_ptr;                             { +0x17C }
  il_180: extern il_$node_ptr_t;                       { +0x180: 37 units }
  il_184: extern il_$node_ptr_t;                       { +0x184 }

{ INITIALIZE_MODULE - set up IL's and TOKEN's tables and globals for a
  compilation.  il.pas 0x07D74C. }
procedure initialize_module; extern;

