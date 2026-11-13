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

{ The tree operators (a tree node's word at +36), as the image names
  them: the ISC's printers write an operator as an enumerated value, and
  cc.a88k has the run time's name table for the type after
  isc_print_il_node (0x0C69A4, 0x0CE4C6, 0x0D3F0C), isc_unrecognized_il_node
  (0x0DC290), alignment_from_sr_info (0x20FD9A) and il_node_to_empty_string
  (0x217BB4): 90 names, 0 nop_top .. 89 illegal_top (tools/cc_enumnames.py).
  list_tree's print_tree_exp prints most of them without the suffix
  ('ADD'), some in a display form of its own (27 lshf_top 'LSHFT', 49
  alshf_top 'ALSHFT', 23 set_compare_top 'SET_CMP', 24 agg_compare_top
  'AGG_CMP', 51..57 the C front end's cc_*_ptop 'p_C3EXPR' .., 58
  ref_expr_top 'REF_EXPRp_', 65 allocate_dynamic_space_top 'ALLOC_DYNM',
  47 sr_top 'AND-to-SR' or 'OR-to-SR'); its fallback prints
  '<ORD(TOP)=' n '>'.  The ISC's il$t (isc_enumeration.ins.pas) names
  them with il_ before (il_add_top).  A value is a word, as the field is.

  Not known from the original: the type's name. }
  il_$top_t = (
    nop_top,                          { 0 }
    add_top,                          { 1 }
    sub_top,                          { 2 }
    mul_top,                          { 3 }
    div_top,                          { 4 }
    divide_top,                       { 5 }
    mod_top,                          { 6 }
    neg_top,                          { 7 }
    not_top,                          { 8 }
    and_top,                          { 9 }
    or_top,                           { 10 }
    bit_test_top,                     { 11 }
    compare_top,                      { 12 }
    index_top,                        { 13 }
    unpack_top,                       { 14 }
    call_top,                         { 15 }
    func_call_top,                    { 16 }
    value_top,                        { 17 }
    extend_top,                       { 18 }
    set_and_top,                      { 19 }
    set_or_top,                       { 20 }
    set_diff_top,                     { 21 }
    set_extend_top,                   { 22 }
    set_compare_top,                  { 23 }
    agg_compare_top,                  { 24 }
    bit_set_top,                      { 25 }
    addr_top,                         { 26 }
    lshf_top,                         { 27 }
    rshf_top,                         { 28 }
    abs_top,                          { 29 }
    isc_call_top,                     { 30 }
    isc_func_call_top,                { 31 }
    isc_func_call_hidden_temp_top,    { 32 }
    isc_mul_top,                      { 33 }
    f_add_top,                        { 34 }
    f_sub_top,                        { 35 }
    f_mul_top,                        { 36 }
    f_div_top,                        { 37 }
    f_neg_top,                        { 38 }
    f_extend_top,                     { 39 }
    f_compare_top,                    { 40 }
    f_math_top,                       { 41 }
    f_expon_top,                      { 42 }
    expon_top,                        { 43 }
    eor_top,                          { 44 }
    max_top,                          { 45 }
    min_top,                          { 46 }
    sr_top,                           { 47 }
    chk_top,                          { 48 }
    alshf_top,                        { 49 }
    arshf_top,                        { 50 }
    cc_c3expr_ptop,                   { 51 }
    cc_logor_ptop,                    { 52 }
    cc_logand_ptop,                   { 53 }
    cc_assign_ptop,                   { 54 }
    cc_post_id_ptop,                  { 55 }
    cc_comma_ptop,                    { 56 }
    cc_lognot_ptop,                   { 57 }
    ref_expr_top,                     { 58 }
    signed_div_top,                   { 59 }
    unsigned_div_top,                 { 60 }
    signed_mod_top,                   { 61 }
    unsigned_mod_top,                 { 62 }
    align_top,                        { 63 }
    isc_addr_top,                     { 64 }
    allocate_dynamic_space_top,       { 65 }
    cache_top,                        { 66 }
    isc_fio_init,                     { 67 }
    strcmp_top,                       { 68 }
    strlen_top,                       { 69 }
    strncmp_top,                      { 70 }
    isc_select,                       { 71 }
    set_bit_in_set_top,               { 72 }
    set_range_in_set_top,             { 73 }
    isc_signed_rem_top,               { 74 }
    isc_unsigned_rem_top,             { 75 }
    isc_signed_mod_top,               { 76 }
    isc_unsigned_mod_top,             { 77 }
    isc_agg_cmp_top,                  { 78 }
    isc_agg_lex_cmp_top,              { 79 }
    range_check_top,                  { 80 }
    f_range_check_top,                { 81 }
    mark_dynamic_space_top,           { 82 }
    extract_bit_field_top,            { 83 }
    bit_field_cmp_top,                { 84 }
    physical_top,                     { 85 }
    ada_expon_top,                    { 86 }
    f_ada_expon_top,                  { 87 }
    pas_get_chk_ptop,                 { 88 }
    illegal_top);                     { 89 }

{ The assignment operators (an assignment node's word at +76), as the
  image names them: the run time's name table for the type after
  isc_print_il_node (0x0BE472, 0x0D5EFC), isc_unrecognized_il_node
  (0x0DC7B0) and alignment_from_sr_info (0x210354): 38 names, 0
  scalar_aop .. 37 illegal_aop.  list_tree's print_top_node prints them
  without the suffix ('SCALAR', 'ADD_TO', ...).

  Not known from the original: the type's name. }
  il_$aop_t = (
    scalar_aop,                       { 0 }
    add_to_aop,                       { 1 }
    sub_from_aop,                     { 2 }
    and_to_aop,                       { 3 }
    or_to_aop,                        { 4 }
    eor_to_aop,                       { 5 }
    agg_aop,                          { 6 }
    set_and_to_aop,                   { 7 }
    set_or_to_aop,                    { 8 }
    set_diff_from_aop,                { 9 }
    pack_aop,                         { 10 }
    fp_aop,                           { 11 }
    field_aop,                        { 12 }
    not_to_aop,                       { 13 }
    neg_to_aop,                       { 14 }
    lshft_to_aop,                     { 15 }
    rshft_to_aop,                     { 16 }
    bset_to_aop,                      { 17 }
    bclr_to_aop,                      { 18 }
    f_add_to_aop,                     { 19 }
    f_sub_from_aop,                   { 20 }
    f_mul_to_aop,                     { 21 }
    f_div_by_aop,                     { 22 }
    mul_to_aop,                       { 23 }
    div_by_aop,                       { 24 }
    agg_len_aop,                      { 25 }
    isc_mul_to_aop,                   { 26 }
    strcat_aop,                       { 27 }
    strcpy_aop,                       { 28 }
    strncat_aop,                      { 29 }
    strncpy_aop,                      { 30 }
    isc_agg_aop,                      { 31 }
    isc_slice_aop,                    { 32 }
    isc_agg_zero_aop,                 { 33 }
    isc_fill_aop,                     { 34 }
    range_check_to_aop,               { 35 }
    f_range_check_to_aop,             { 36 }
    illegal_aop);                     { 37 }

{ A variable's allocation (a variable node's word at +72), as the image
  names it: the run time's name table after isc_print_il_node (0x0C7A7C,
  0x0D2E18, 0x0D5D6C): 12 names.  list_tree's print_variable prints the
  same names.

  Not known from the original: the type's name. }
  il_$vat_t = (
    local_vat,                        { 0 }
    static_vat,                       { 1 }
    dynm_vat,                         { 2 }
    extern_vat,                       { 3 }
    externdef_vat,                    { 4 }
    param_vat,                        { 5 }
    xdynm_vat,                        { 6 }
    xstatic_vat,                      { 7 }
    xextrndef_vat,                    { 8 }
    based_vat,                        { 9 }
    sect_vat,                         { 10 }
    absolute_vat);                    { 11 }

{ A block's allocation (bits 8..7 of a block node's word at +376), as
  the image names it: the run time's name table after isc_print_il_node
  (0x0C8500, 0x0D3E16): 4 names.  list_tree's print_routine_block
  prints the same names.

  Not known from the original: the type's name. }
  il_$bat_t = (
    local_bat,                        { 0 }
    forward_bat,                      { 1 }
    extern_bat,                       { 2 }
    param_bat);                       { 3 }

{ The register classes (a tree node's descriptor's word at +4,
  add_node_$desc_t's rlen, and the operand modifiers that name a class),
  as list_tree's print_rlen names them: 0 null (printed '??-null-??'),
  1 byte, 2 word, 4 long, 5 addr, 6 r4, 7 r8, 8 c8, 9 cs, 10 vcs, 11
  agg, 12 c16; 3 has no name and is not used.  Constants, not an
  enumeration: the values have a gap, and the units keep a class in
  integer words, index tables by it (opt_inline's class_bytes, the ISC's
  rlen_arith) and compare it as a number.  The names are the dump's
  with rlen_ before them, chosen here: the dump's names alone (byte,
  word, long) would clash with the units' identifiers.

  Not known from the original: the constants' names. }
const
  rlen_null = 0;
  rlen_byte = 1;
  rlen_word = 2;
  rlen_long = 4;
  rlen_addr = 5;
  rlen_r4 = 6;
  rlen_r8 = 7;
  rlen_c8 = 8;
  rlen_cs = 9;
  rlen_vcs = 10;
  rlen_agg = 11;
  rlen_c16 = 12;

{ A variable's attributes (the set at +32 of a variable node, 109), as
  list_tree's print_variable names them ('var_$volatile ' ..
  'var_$withrecord ', its string pool in cc.m68k: the identifiers are the
  strings without the trailing blank): bit n is element n.  A set of 32
  elements is a longword, as set of 0..31 is.  The other units test the
  attributes as masks of the node's longword (il_utils' 16#20000 for
  var_$strength_reduction) and keep their numbers.

  Not known from the original: the types' names. }
type
  il_$var_attr_t = (
    var_$volatile,                    { 0 }
    var_$atomic,                      { 1 }
    var_$physical,                    { 2 }
    var_$dev_read,                    { 3 }
    var_$dev_write,                   { 4 }
    var_$processor_reg,               { 5 }
    var_$initialized,                 { 6 }
    var_$forloopindex,                { 7 }
    var_$uplevel,                     { 8 }
    var_$loop_trip_count,             { 9 }
    var_$is_formal_parameter,         { 10 }
    var_$unique_value,                { 11 }
    var_$address_exposed,             { 12 }
    var_$passed_by_reference,         { 13 }
    var_$temporary,                   { 14 }
    var_$register,                    { 15 }
    var_$bss,                         { 16 }
    var_$strength_reduction,          { 17 }
    var_$allocated,                   { 18 }
    var_$already_seen_this_formal,    { 19 }
    var_$induction,                   { 20 }
    var_$nooptimize,                  { 21 }
    var_$force_to_memory,             { 22 }
    var_$display_ptr,                 { 23 }
    var_$wasbound,                    { 24 }
    var_$isc_was_here,                { 25 }
    var_$is_a_register_candidate,     { 26 }
    var_$seen_in_ra,                  { 27 }
    var_$mentioned_in_sym_disp,       { 28 }
    var_$spilled_to_memory,           { 29 }
    var_$local_copy,                  { 30 }
    var_$withrecord);                 { 31 }
  il_$var_attrs_t = set of il_$var_attr_t;

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
    kind: il_$kind_t;                   { +2 }
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

