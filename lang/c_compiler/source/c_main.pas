{ c_main - cc, the C compiler's main program: it parses the command
  line (iosub_$init_all), sets up the IL, the reserved words and the
  front end's identifiers and basic types, defines and undefines the
  command line's macros, runs the external ANSI preprocessor when one
  is wanted (preprocess), the parser (syntax), the start-up routine of
  a program with a main (make_main_pgm) and the back end, then prints
  the summary line and ends with the severity of the diagnostics.

  Image addresses (DOMAIN C 6.9; the unit is the same in both binaries):
    cc.m68k   cc.a88k
    0x05AF72  0x05B1F2  cc
    0x059F14  0x05A194  make_main_pgm
    0x05A17A  0x05A3FA  do_cmd_defs
    0x05A2D8  0x05A558  do_cmd_undefs
    0x05A380  0x05A600  do_lex_for_listings
    0x05A3C4  0x05A644  rword_init
    0x05A5B0  0x05A830  addarg
    0x05A624  0x05A8A4  addincludes
    0x05A6D2  0x05A952  do_ansi_defs
    0x05A862  0x05AAE2  do_ansi_undefs
    0x05A934  0x05ABB4  preprocess
    0x05ADC4  0x05B044  fe_cc_$end_compilation
    0x05ADD2  0x05B052  init_basic_types
    A5 0x1498C4 (cc.m68k), 0x2C98C4 (cc.a88k): the program's data,
    0xDBC bytes: the preprocessor's path (+0x0), the outermost block's
    declaration (+0x400), the directory `/usr/include/' (+0x428), the
    -UNDEF and -DEF lists (+0x830, +0xA30), the clean-up record
    (+0xC30), the summary line (+0xC70), the outermost block's name
    (+0xD78), the preprocessor's argument count and vector (+0xD80,
    +0xD84), the environment variable's value (+0xD88), the clean-up
    status (+0xDA0), the last line (+0xDA4), the variable's length
    (+0xDA6), the system type's versions (+0xDA8, +0xDAA, +0xDAC), the
    severity (+0xDAE), the lists' counts (+0xDB0, +0xDB2), preprocess's
    loop index (+0xDB8) and whether a temporary file is to be deleted
    (+0xDBA).

  cc and do_lex_for_listings load A5 (do_lex_for_listings is passed to
  run_backend); the other routines do not (internal).

  The command line's -DEF and -UNDEF arguments are cargs_$name_t
  records (a length and the characters).  new is docs/dpc-gaps.md 3,
  ptoc and ctop docs/dpc-gaps.md 16.
}
program cc;

%include 'lang/lang/source/globals.ins.pas';
%include 'lang/lang/source/time.ins.pas';
%include 'lang/lang/source/prtsub.ins.pas';
%include 'lang/lang/source/prfpkg.ins.pas';
%include 'lang/lang/source/iosub.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/lang/source/attributes.ins.pas';
%include 'lang/c_compiler/source/c_objtype.ins.pas';
%include 'lang/c_compiler/source/c_globals.ins.pas';
%include 'lang/c_compiler/source/c_externs.ins.pas';
%include 'lang/c_compiler/source/c_pre_proc.ins.pas';
%include 'lang/c_compiler/source/general_utl.ins.pas';
%include 'lang/c_compiler/source/macro_utl.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include 'us/us/ins/pfm.ins.pas';
%include 'us/us/ins/pgm.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include 'us/us/ins/proc2.ins.pas';
%include 'us/us/ins/unix_sig.ins.pas';
%include 'us/us/ins/unix_resource.ins.pas';
%include 'us/us/ins/fault.ins.pas';
%include '/sys/ins/fault.ins.pas';
%include 'us/us/ins/as_info.ins.pas';
%include 'us/us/ins/c.ins.pas';
%include 'us/us/ins/ev.ins.pas';
%include 'us/us/ins/pm.ins.pas';
%include '/sys/ins/pm.ins.pas';
%include 'us/us/ins/acl.ins.pas';
%include 'ivory/volume_4/report/source/report.ins.pas';
%include 'lang/common/source/mem.ins.pas';
%include 'lang/c_compiler/source/cppansi.ins.pas';

type
  { An argument for the preprocessor, built as a varying string and
    made a C string (ptoc) before addarg copies it. }
  arg_t = varying [1024] of char;
  arg_chars_t = cargs_$chars_t;
  arg_vector_t = array [1..1000] of ^arg_chars_t;

  { A -DEF or -UNDEF argument. }
  name_list_t = array [1..128] of inc_list_$name_ptr_t;

var
  cpp_path: arg_chars_t;                { +0x0: the preprocessor (-CPP
                                          name, else /usr/apollo/lib/cpp),
                                          a C string }
  outer_decl: c_decl_t;                 { +0x400 }
  usr_include: cargs_$name_t;           { +0x428: the last -IDIR
                                          directory }
  undefs: name_list_t;                  { +0x830 }
  defs: name_list_t;                    { +0xA30 }
  crec: pfm_$cleanup_rec;               { +0xC30 }
  summary: prtsub_$line_t;              { +0xC70 }
  outer_name: c_name_t;                 { +0xD78 }
  argc: integer32;                      { +0xD80 }
  argv: ^arg_vector_t;                  { +0xD84: [1] the preprocessor,
                                          [2] the source, [3] the output
                                          (a temporary), then the
                                          options }
  ev_value: ev_$string_ptr_t;           { +0xD88 }
  status: status_$t;                    { +0xDA0 }
  last_line: integer;                   { +0xDA4: lex_line after the
                                          parse, for run_backend }
  ev_len: integer;                      { +0xDA6 }
  sys_v2: integer;                      { +0xDA8 }
  sys_v1: integer;                      { +0xDAA }
  run_v1: integer;                      { +0xDAC }
  severity: integer;                    { +0xDAE }
  nundefs: integer;                     { +0xDB0 }
  ndefs: integer;                       { +0xDB2 }
  i: integer;                           { +0xDB8: preprocess's loop }
  cpp_temp: boolean;                    { +0xDBA: argv[3], the
                                          preprocessor's output, is to
                                          be deleted }

{ DO_REPORT - the compilation report (ivory's do_report.pas 0x07916C,
  which no insert c_main opens declares): the language (a word constant
  by address), the address of lex_total_lines and of the status.  The
  first parameter is do_report's report_$word_t, a word. }
procedure do_report(
    in language: integer;
    in lines: univ integer32;
    in p3: univ integer32); extern;

{ PAS_$CTOV - the C string s (at most max characters) as a varying
  string.  Called through the transfer vector by preprocess (v and s
  by address, max a word by value); no prelude insert declares it.

  Not known from the original: whether it was written as a call. }
procedure pas_$ctov(
    out v: univ arg_t;
    in s: univ arg_chars_t;
    max: integer); options(val_param); extern;

{ make_main_pgm - for a program whose main is a function defined here
  (fnd_name of id_main a variable, 109, of a function type, 108, whose
  2-bit field at +376 is 0), the start-up routine: the function
  unix_$main and the block <apollo_c_startup> (def_blk_skeleton 108 and
  105 with an int and an il_178 declaration, lines 31999), then a body
  that calls main with the address constant of its argument (expr_op
  of `&' twice) and returns its value (body_opr, expr_op 18, call_s,
  body_e).  Not after an error.  -TYPE (cargs_$options.type_opt) is off
  meanwhile.

  0x059F14, 0x24A bytes, link #-84.  The locals: the two names (-64,
  -56; c_name_t), the declaration (-40), the `&' token's pair (-48),
  the address constant's offset (-68); the -TYPE flag in D2 (`sne',
  put back with `lsr.b #7; lsl.b #5; andi.b #-33; or.b').  The top
  entry of the expression stack (0x140440 + 64 * cexs_23bc - 64) gets
  get_addr_con(4, its type (+28: main's block), offset, cdef_data_sect,
  false).  The sections
  come from main's block (+188, +192).

  Not known from the original:
  - the names; the two expr_op calls' loop (`moveq #1; dbf'). }

procedure make_main_pgm; internal;
var
  saved_type_opt: boolean;
  m, b: il_$node_ptr_t;
  name1, name2, amp: c_name_t;
  decl: c_decl_t;
  offset: integer32;
  k: integer;
begin
  if lex_errors <> 0 then
    return;
  m := fnd_name(addr(id_main), true, false);
  if m = il_178 then
    return;
  if m^.kind <> 109 then
    return;
  b := m^.xp[7];
  if b^.kind <> 108 then
    return;
  if rshft(b^.xw[188] & 16#180, 7) <> 0 then
    return;
  saved_type_opt := cargs_$options.type_opt;
  cargs_$options.type_opt := false;
  name1.id := idntk(ctk_identifier, 'unix_$main', 10);
  name1.line := 31999;
  cdef_code_sect := b^.xp[47];
  cdef_data_sect := b^.xp[48];
  decl.dtype := int_type;
  decl.name := name1.id;
  decl.line := name1.line;
  decl.flags := [];
  def_blk_skeleton(108, addr(name1), 2, addr(decl), nil, nil, false, 3, 0, nil);
  name2.id := idntk(ctk_identifier, '<apollo_c_startup>', 18);
  name2.line := 31999;
  decl.dtype := il_178;
  decl.name := name2.id;
  decl.line := name2.line;
  decl.flags := [];
  def_blk_skeleton(105, addr(name2), 0, addr(decl), nil, nil, false, 3, 0, nil);
  cdef_50 := c_blk_ptr_t(il_180);
  def_blk_params(false);
  il_d0 := 31999;
  il_c3 := true;
  body_s;
  body_opr(1, addr(name1));
  body_opr(1, addr(id_main));
  with cexs_stack[cexs_23bc] do begin
    offset := 0;
    node := get_addr_con(4, il_$node_ptr_t(typ.base), offset,
                         cdef_data_sect, false);
  end;
  amp.id := lex_tokens[ctk_amp];
  amp.line := 31999;
  for k := 1 to 2 do
    expr_op(17, addr(amp), 1);
  body_opr(5, addr(id_main));
  expr_op(18, addr(name1), 2);
  body_opr(5, addr(name1));
  call_s;
  cexs_23bc := cexs_23bc - 1;
  body_e;
  cargs_$options.type_opt := saved_type_opt;
end;

{ do_cmd_defs - the -DEF name[=value] arguments as macros (value 1 when
  none is given).

  0x05A17A, 0x15C bytes, link #-32.  Diagnostics are reported with no
  line (both written flags set around the loop).  For each argument:
  the first `=' splits it (an empty name is error0(7) and the argument
  is skipped); a predefined macro of the name (mu_$lookup_name and its
  predefined flag) is error1(259); else mu_$def_macro (name, `1' (the
  literal at 0x05A2D6) when there is no `=', the empty value after a
  lone `='), and false is error1(10).  The value's length in (-10), the
  name's in D2, the value's start in D4, the result in D5 (true
  first).

  Not known from the original:
  - the locals' names. }

procedure do_cmd_defs; internal;
var
  k, j: integer;
  p: inc_list_$name_ptr_t;
  vlen, nlen, vstart, len: integer;
  m: mu_$macro_ptr_t;
  ok: boolean;
label
  9;
begin
  lex_text_written := true;
  lex_hdr_written := true;
  for k := 1 to ndefs do begin
    vlen := 0;
    nlen := 0;
    ok := true;
    p := defs[k];
    for j := 1 to p^.length do
      if p^.body[j] = '=' then begin
        vlen := p^.length - j;
        nlen := j - 1;
        vstart := j + 1;
        if nlen = 0 then begin
          error0(7, 0);
          goto 9;
        end;
        exit;
      end;
    if nlen = 0 then
      len := p^.length
    else
      len := nlen;
    if mu_$lookup_name(len, p^.body, m) and then m^.predefined then
      error1(259, 0, idntk(ctk_identifier, p^.body, len))
    else if vlen = 0 then begin
      if nlen = 0 then
        ok := mu_$def_macro(p^.length, p^.body, 1, '1', false)
      else
        ok := mu_$def_macro(nlen, p^.body, 0, '1', false);
    end
    else
      ok := mu_$def_macro(nlen, p^.body, vlen, p^.body[vstart], false);
    if not ok then
      error1(10, 0, idntk(ctk_identifier, p^.body, len));
  9:
  end;
  lex_text_written := false;
  lex_hdr_written := false;
end;

{ do_cmd_undefs - the -UNDEF arguments: each macro cancelled, a
  predefined one refused (error1(259)).

  0x05A2D8, 0xA8 bytes, link #-28.

  Not known from the original:
  - the locals' names. }

procedure do_cmd_undefs; internal;
var
  k: integer;
  p: inc_list_$name_ptr_t;
  n: integer;
  m: mu_$macro_ptr_t;
begin
  lex_text_written := true;
  lex_hdr_written := true;
  for k := 1 to nundefs do begin
    p := undefs[k];
    n := p^.length;
    if mu_$lookup_name(n, p^.body, m) and then m^.predefined then
      error1(259, 0, idntk(ctk_identifier, p^.body, n))
    else
      mu_$cancel_name(n, p^.body);
  end;
  lex_text_written := false;
  lex_hdr_written := false;
end;

{ do_lex_for_listings - start the source again for the back end's
  listing (run_backend calls it through the address cc passes): the
  -DEF macros, init_lex, the implicit #include already done
  (mr_std_include_state 2), the #systype state cleared unless it came
  from the command line (1), token_kind 38 (ctk_short), no #module.

  0x05A380, 0x44 bytes, link #-4; loads A5 (not internal). }

procedure do_lex_for_listings;
begin
  do_cmd_defs;
  init_lex;
  mr_std_include_state := 2;
  if lex_systype_state <> 1 then
    lex_systype_state := 0;
  token_kind := ctk_short;
  lex_module_seen := false;
end;

{ rword_init - the reserved words and operators as identifiers of
  their classes: lex_tokens[k] := idntk(k, the k-th name of
  c_rword_table, its length to the first blank (at most 10)) for k in
  0..75; under -XANSI `const', `volatile' and `signed' (classes 102,
  103, 104); the compound assignments (class ctk_assign).

  0x05A3C4, 0x1BE bytes, link #-12.  The names' offset in D4 (+10 a
  pass), the length in D5 (`cmpi.w #10; bcs'), the stores through A3
  from lex_tokens[0] (0x144C38).

  Not known from the original:
  - the locals' names. }

procedure rword_init; internal;
var
  k, n: integer;
begin
  for k := 0 to 75 do begin
    n := 1;
    while n < 10 do begin
      if c_rword_table[k][n + 1] = ' ' then
        exit;
      n := n + 1;
    end;
    lex_tokens[k] := idntk(k, c_rword_table[k], n);
  end;
  if cargs_$options.xansi then begin
    lex_tokens[102] := idntk(102, 'const', 5);
    lex_tokens[103] := idntk(103, 'volatile', 8);
    lex_tokens[104] := idntk(104, 'signed', 6);
  end;
  lex_tokens[lex_add_assign] := idntk(ctk_assign, '+=', 2);
  lex_tokens[lex_sub_assign] := idntk(ctk_assign, '-=', 2);
  lex_tokens[lex_mul_assign] := idntk(ctk_assign, '*=', 2);
  lex_tokens[lex_div_assign] := idntk(ctk_assign, '/=', 2);
  lex_tokens[lex_mod_assign] := idntk(ctk_assign, '%=', 2);
  lex_tokens[lex_shr_assign] := idntk(ctk_assign, '>>=', 3);
  lex_tokens[lex_shl_assign] := idntk(ctk_assign, '<<=', 3);
  lex_tokens[lex_and_assign] := idntk(ctk_assign, '&=', 2);
  lex_tokens[lex_or_assign] := idntk(ctk_assign, '|=', 2);
  lex_tokens[lex_xor_assign] := idntk(ctk_assign, '^=', 2);
end;

{ addarg - s, made a C string, as the preprocessor's next argument (a
  1024-byte copy from pas_$new).

  0x05A5B0, 0x74 bytes, link #-1040: s copied into the frame
  ((length + 2) div 4 + 1 longwords), pas_$ptoc, argc counted,
  pas_$new(argv^[argc], 1024), 1024 bytes copied.

  Not known from the original:
  - the parameter's name. }

procedure addarg(
    s: arg_t); internal;
begin
  ptoc(s);
  argc := argc + 1;
  new(argv^[argc]);
  argv^[argc]^ := s.body;
end;

{ addincludes - `-I' and each -IDIR directory but the first (the
  source's own) and the last (/usr/include/, which cc adds).

  0x05A624, 0x6E bytes, link #-1052.  The loop runs over
  inc_list_idirs[2..nidir-1] (`subq.l #2' guard, then `subq.w #3' the
  count, the offset in D3 from 8).

  Not known from the original:
  - the locals' names. }

procedure addincludes; internal;
var
  arg: arg_t;
  k, j: integer;
begin
  for k := 2 to inc_list_nidir - 1 do begin
    arg.length := 0;
    arg.body[1] := chr(0);
    arg.body[1] := '-';
    arg.body[2] := 'I';
    arg.length := 2;
    addarg(arg);
    arg.length := 0;
    arg.body[1] := chr(0);
    for j := 1 to inc_list_idirs[k]^.length do
      arg.body[j] := inc_list_idirs[k]^.body[j];
    arg.length := inc_list_idirs[k]^.length;
    addarg(arg);
  end;
end;

{ do_ansi_defs - the -DEF arguments as the preprocessor's -D options
  (`-Dname' or `-Dname=value'); a predefined macro's name is reported
  (error1(259)) and passed all the same, an empty name skipped
  (error0(7)).

  0x05A6D2, 0x190 bytes, link #-1072.  The count in (-1062), counted
  down (`subq.w #1; bcc').

  Not known from the original:
  - the locals' names. }

procedure do_ansi_defs; internal;
var
  arg: arg_t;
  k, j: integer;
  p: inc_list_$name_ptr_t;
  vlen, nlen, vstart, len, n: integer;
  m: mu_$macro_ptr_t;
label
  9;
begin
  lex_text_written := true;
  lex_hdr_written := true;
  for k := 1 to ndefs do begin
    vlen := 0;
    nlen := 0;
    p := defs[k];
    for j := 1 to p^.length do
      if p^.body[j] = '=' then begin
        vlen := p^.length - j;
        nlen := j - 1;
        vstart := j + 1;
        if nlen = 0 then begin
          error0(7, 0);
          goto 9;
        end;
        exit;
      end;
    if nlen = 0 then
      len := p^.length
    else
      len := nlen;
    arg.length := 0;
    arg.body[1] := chr(0);
    arg.body[1] := '-';
    arg.body[2] := 'D';
    for j := 1 to len do
      arg.body[j + 2] := p^.body[j];
    n := len + 3;
    if mu_$lookup_name(len, p^.body, m) and then m^.predefined then
      error1(259, 0, idntk(ctk_identifier, p^.body, len))
    else if vlen <> 0 then begin
      arg.body[n] := '=';
      n := n + 1;
      for j := 1 to vlen do
        arg.body[n + j - 1] := p^.body[vstart + j - 1];
      n := n + vlen;
    end;
    arg.length := n - 1;
    addarg(arg);
  9:
  end;
  lex_text_written := false;
  lex_hdr_written := false;
end;

{ do_ansi_undefs - the -UNDEF arguments as -U options (a predefined
  macro reported, error1(259), and passed).

  0x05A862, 0xD2 bytes, link #-1068.

  Not known from the original:
  - the locals' names. }

procedure do_ansi_undefs; internal;
var
  arg: arg_t;
  k, j, n: integer;
  p: inc_list_$name_ptr_t;
  m: mu_$macro_ptr_t;
begin
  lex_text_written := true;
  lex_hdr_written := true;
  for k := 1 to nundefs do begin
    p := undefs[k];
    n := p^.length;
    arg.length := 0;
    arg.body[1] := chr(0);
    arg.body[1] := '-';
    arg.body[2] := 'U';
    for j := 1 to n do
      arg.body[j + 2] := p^.body[j];
    if mu_$lookup_name(n, p^.body, m) and then m^.predefined then
      error1(259, 0, idntk(ctk_identifier, p^.body, n));
    arg.length := n + 2;
    addarg(arg);
  end;
  lex_text_written := false;
  lex_hdr_written := false;
end;

{ preprocess - under -XANSI (not -USRCH, not -OLDCPP), run the ANSI
  preprocessor and read its output; false after an error.

  0x05A934, 0x3D4 bytes, link #-4160.  The result in D2 (true first).
  The preprocessor is -CPP's name (1024 bytes copied) or
  /usr/apollo/lib/cpp (a varying literal made a C string);
  c_cpp_present tells whether it is there: when not, a named one is
  error1(292) and fails (lex_errors := 1), the default error0(308) and
  -OLDCPP is set (`bset #30' of the longword at +0x286: flags_286
  element 19), the compiler's own preprocessor then doing the work.
  Else: cpp_temp set; an argument vector from a MEM_ pool
  (`argument_list'), 4 * (2 * (defs + undefs + idirs) + 19) bytes; the
  arguments: the preprocessor (pas_$ctov of its path), the source,
  `placeholder' (the output, which c_run_acpp replaces by a temporary),
  the -D and -U options, the -I directories, -D__apollo, -D_BFMT__COFF,
  the target's -D_ISP__M68K=1, -D_ISP__PA_RISC=1 or -D_ISP__A88K=1
  (target_properties_10 0, 2, 3), without -ANSI -Dapollo, -Daegis,
  -Dunix and -D_APOLLO_SOURCE, without -WARN -w.  c_run_acpp runs it:
  a non-zero status fails (the pool emptied, lex_errors := 1,
  error0(309), the output deleted); else the source is redirected to
  the output (pas_$ctop of argv[3]; iosub_$redirect_source_input) and
  output 0 marked.  The varying literals are copied whole (length and
  characters) from the pool at 0x05AD08..0x05ADC2; `-w' is one
  longword (0x00022D77) and a NUL.  The loop over the source's
  pathname uses the program's variable i.

  Not known from the original:
  - the locals' names; the status pointer's handling (the frame
    pointers at -3124, -2072, -3128 and -2084 hold the addresses
    c_cpp_present and c_run_acpp take). }

function preprocess: boolean; internal;
var
  ok: boolean;
  arg: arg_t;
  found: integer32;
  found_p, path_p, status_p: univ_ptr;
  pool: mem_$pool_t;
  size: integer32;
  tmp: arg_t;
  path: arg_chars_t;
begin
  ok := true;
  if cargs_$options.usrch or not cargs_$options.xansi or
     (19 in cargs_$options.flags_286) then begin
    preprocess := ok;
    return;
  end;
  if cargs_$options.cpp_name.length > 0 then
    cpp_path := cargs_$options.cpp_name.body
  else begin
    arg := '/usr/apollo/lib/cpp';
    ptoc(arg);
    cpp_path := arg.body;
  end;
  found_p := addr(found);
  path_p := addr(cpp_path);
  c_cpp_present(found_p, path_p);
  if found <> 0 then begin
    if cargs_$options.cpp_name.length > 0 then begin
      error1(292, 0, idntk(ctk_identifier, cargs_$options.cpp_name.body,
                           cargs_$options.cpp_name.length));
      lex_errors := 1;
      ok := false;
    end
    else begin
      error0(308, 0);
      cargs_$options.flags_286 := cargs_$options.flags_286 + [19];
    end;
    preprocess := ok;
    return;
  end;
  cpp_temp := ok;
  mem_$initialise;
  mem_$open_pool(pool, 'argument_list', false);
  size := (2 * (ndefs + nundefs + inc_list_nidir) + 19) * 4;
  argv := mem_$alloc(pool, size);
  pas_$ctov(tmp, cpp_path, 1024);
  arg := tmp;
  addarg(arg);
  arg.length := 0;
  arg.body[1] := chr(0);
  for i := 1 to iosub_$source_pathname_length do
    arg.body[i] := iosub_$source_pathname[i];
  arg.length := iosub_$source_pathname_length;
  addarg(arg);
  arg := 'placeholder';
  addarg(arg);
  do_ansi_defs;
  do_ansi_undefs;
  addincludes;
  arg := '-D__apollo';
  addarg(arg);
  arg := '-D_BFMT__COFF';
  addarg(arg);
  case target_properties.p_10 of
    0: begin
      arg := '-D_ISP__M68K=1';
      addarg(arg);
    end;
    2: begin
      arg := '-D_ISP__PA_RISC=1';
      addarg(arg);
    end;
    3: begin
      arg := '-D_ISP__A88K=1';
      addarg(arg);
    end;
    otherwise
      ;
  end;
  if not cargs_$options.ansi then begin
    arg := '-Dapollo';
    addarg(arg);
    arg := '-Daegis';
    addarg(arg);
    arg := '-Dunix';
    addarg(arg);
    arg := '-D_APOLLO_SOURCE';
    addarg(arg);
  end;
  if not cargs_$options.warn then begin
    arg.length := 2;
    arg.body[1] := '-';
    arg.body[2] := 'w';
    arg.body[3] := chr(0);
    addarg(arg);
  end;
  found := 0;
  status_p := found_p;
  c_run_acpp(argv, status_p);
  if found <> 0 then begin
    mem_$empty_pool(pool);
    lex_errors := 1;
    ok := false;
    error0(309, 0);
    c_delete_temp(argv^[3]);
  end
  else begin
    arg.body := argv^[3]^;
    ctop(arg);
    path := arg.body;
    iosub_$redirect_source_input(path, arg.length);
    io_mark(0);
  end;
  preprocess := ok;
end;

{ fe_cc_$end_compilation - the front end's last step: def_lnktbl_clear.
  0x05ADC4, 0xE bytes, link #-4. }

procedure fe_cc_$end_compilation; internal;
begin
  def_lnktbl_clear;
end;

{ init_basic_types - the basic types' nodes (gspace): char, short, int
  (signed integral, kind 122, lengths 1, 2, 4), their unsigned forms,
  float and double (kind 123, 6 and 7), void (210) and kind 136;
  runbackend_10 and runbackend_0c get short and int, cexs_23b4 unsigned
  int.

  0x05ADD2, 0x1A0 bytes, link #-4. }

procedure init_basic_types; internal;
begin
  char_type := gspace(8);
  char_type^.kind := 122;
  char_type^.len := 1;
  char_type^.signed := true;
  short_type := gspace(8);
  short_type^.kind := 122;
  short_type^.len := 2;
  short_type^.signed := true;
  runbackend_10 := short_type;
  int_type := gspace(8);
  int_type^.kind := 122;
  int_type^.len := 4;
  int_type^.signed := true;
  runbackend_0c := int_type;
  uchar_type := gspace(8);
  uchar_type^.kind := 122;
  uchar_type^.len := 1;
  uchar_type^.signed := false;
  ushort_type := gspace(8);
  ushort_type^.kind := 122;
  ushort_type^.len := 2;
  ushort_type^.signed := false;
  uint_type := gspace(8);
  uint_type^.kind := 122;
  uint_type^.len := 4;
  uint_type^.signed := false;
  cexs_23b4 := uint_type;
  float_type := gspace(6);
  float_type^.kind := 123;
  float_type^.len := 6;
  double_type := gspace(6);
  double_type^.kind := 123;
  double_type^.len := 7;
  void_type := gspace(4);
  void_type^.kind := 210;
  cexs_23b8 := gspace(4);
  cexs_23b8^.kind := 136;
end;

{ cc - the program.

  0x05AF72, 0xC90 bytes, link #-8, all of D2-D7/A2-A5 saved; A5 the
  program's data.  cargs_$identify_self(1); lex_total_lines, c_error's
  cells (through A0 = &lex_line: +8, +9 cleared, +10 set, the error
  and warning counts one `clr.l', lex_text empty); iosub_$init_all
  ('.c', 2, the four lists); /usr/include/ (its 13 characters then
  blanks) the last -IDIR directory; a clean-up handler that deletes
  the preprocessor's output, closes GSPACE and signals on; outputs 0
  and 1 marked; initialize_module, the sections (il_10c, il_110),
  rword_init, init_exp_tbl; kw_attribute and kw_options from the
  identifiers `attribute' and `options' (classes 30 and 45; the kind
  stored, then 4110 bytes copied from the entry's +4); `__attribute',
  `__options'; uobj_hp_standard cleared; the outermost block (106,
  il_178's name) with def_blk_skeleton, il_184 and cdef_outer_block
  il_180; initdate, cr_$initialize(false), the -DEF and -UNDEF macros,
  init_lex.  The system type: -SYSTYPE's (c_$decode_version; version
  2 sets uobj_systype_2, another sets SYSTYPE and COMPILESYSTYPE;
  lex_systype_state 1; a bad one error1(179)) or COMPILESYSTYPE's from
  the environment (SYSTYPE set from it; a bad one error1(291)); a
  -RUNTYPE of the same version is dropped, a bad one error1(222).
  init_basic_types; con_zero and con_minus_one; the front end's
  identifiers (id_string_constant, id_at, end_of_while, end_of_for,
  main, the attribute keywords, the six c_def_sem names); the counters;
  cst_stack_size; c_expr_syn_$begin_compilation; -ANSI or -XANSI take
  optimization 2 off (`bclr #3' at +0x283).  perfinit, get_time_stamp,
  perfstart(0), preprocess; when it worked, syntax,
  fe_cc_$end_compilation, perfstop(0), last_line, cerr_quiet set, and
  unless -ES: make_main_pgm, cr_$initialize(true), run_backend (with
  -TREE, or without errors when iosub's flag bit 2 is set), sym_map
  under -MAP, perfsummary, and the summary line (errors, warnings,
  informational messages, the version; the time without errors when
  the flag is set) listed and, unless -NMSGS, typed.  The severity (4
  errors, 2 warnings, else 0) to io_term; the output deleted;
  pfm_$rls_cleanup; do_report(2, lex_total_lines, status);
  pgm_$set_severity, pgm_$exit.

  Not known from the original:
  - the order of the idntk calls' text in the source (the image's is
    kept); the literals' lengths for `_longjmp', `longjmp' and
    `sigsetjmp' (7, 6, 6: kept, see c_globals.ins.pas). }

var
  p: c_kw_node_ptr_t;
  len: integer;
begin
  cargs_$identify_self(1);
  lex_total_lines := 0;
  lex_fatal := false;
  lex_fatal_suppressed := false;
  lex_type_errors := true;
  lex_errors := 0;
  lex_warnings := 0;
  lex_text.length := 0;
  iosub_$init_all('.c', 2, ndefs, 128, addr(defs), inc_list_nidir, 64,
                  addr(inc_list_idirs), inc_list_ninlib, 65,
                  addr(inc_list_inlibs), nundefs, 128, addr(undefs));
  usr_include.length := 13;
  usr_include.body := '/usr/include/';
  inc_list_nidir := inc_list_nidir + 1;
  inc_list_idirs[inc_list_nidir] := addr(usr_include);
  status := pfm_$cleanup(crec);
  if status.all <> pfm_$cleanup_set then begin
    if cpp_temp then
      c_delete_temp(argv^[3]);
    gspace_$close;
    pfm_$signal(status);
  end;
  io_mark(0);
  io_mark(1);
  initialize_module;
  cdef_code_sect := il_10c;
  cdef_data_sect := il_110;
  rword_init;
  init_exp_tbl;
  p := c_kw_node_ptr_t(idntk(ctk_identifier, 'attribute', 9));
  kw_attribute.kind := ctk_attribute;
  kw_attribute.body := p^.body;
  p := c_kw_node_ptr_t(idntk(ctk_identifier, 'options', 7));
  kw_options.kind := ctk_options;
  kw_options.body := p^.body;
  idu_attribute := idntk(ctk_identifier, '__attribute', 11);
  idu_options := idntk(ctk_identifier, '__options', 9);
  uobj_hp_standard := 0;
  outer_name.id := il_178;
  outer_name.line := 0;
  outer_decl.dtype := il_178;
  outer_decl.name := il_178;
  outer_decl.line := 0;
  outer_decl.flags := [];
  def_blk_skeleton(106, addr(outer_name), 0, addr(outer_decl), nil, nil,
                   false, 3, 0, nil);
  il_184 := il_180;
  cdef_outer_block := il_180;
  initdate;
  cr_$initialize(false);
  do_cmd_defs;
  do_cmd_undefs;
  init_lex;
  if cargs_$options.systype.length <> 0 then begin
    if c_$decode_version(cargs_$options.systype.body,
                         cargs_$options.systype.length,
                         sys_v1, sys_v2) then begin
      if sys_v1 = 2 then
        uobj_systype_2 := true
      else begin
        discard(ev_$set_var('SYSTYPE', 7, cargs_$options.systype.body,
                            cargs_$options.systype.length));
        discard(ev_$set_var('COMPILESYSTYPE', 14,
                            cargs_$options.systype.body,
                            cargs_$options.systype.length));
      end;
      lex_systype_state := 1;
    end
    else
      error1(179, 0, strtk(cargs_$options.systype.body,
                           cargs_$options.systype.length + 1));
  end
  else if ev_$get_var('COMPILESYSTYPE', 14, ev_value, ev_len) then begin

    if c_$decode_version(ev_value^, ev_len, sys_v1, sys_v2) then begin
      if sys_v1 = 2 then
        uobj_systype_2 := true
      else
        discard(ev_$set_var('SYSTYPE', 7, ev_value^, ev_len));
    end
    else
      error1(291, 0, strtk(ev_value^, ev_len + 1));
  end;
  if cargs_$options.runtype.length <> 0 then
    if c_$decode_version(cargs_$options.runtype.body,
                         cargs_$options.runtype.length,
                         run_v1, sys_v2) then begin
      if run_v1 = sys_v1 then
        cargs_$options.runtype.length := 0;
    end
    else
      error1(222, 0, strtk(cargs_$options.runtype.body,
                           cargs_$options.runtype.length + 1));
  init_basic_types;
  con_zero := smcontk(ctk_int_con, 0);
  con_minus_one := smcontk(ctk_int_con, -1);
  id_string_constant := idntk(ctk_identifier, '<string-constant>', 17);
  csyn_5c := 0;
  id_at := idntk(ctk_identifier, '@', 1);
  csyn_54 := 0;
  id_end_of_while := idntk(ctk_identifier, 'end_of_while', 12);
  cst_40c := 0;
  id_end_of_for := idntk(ctk_identifier, 'end_of_for', 10);
  cst_404 := 0;
  id_main := idntk(ctk_identifier, 'main', 4);
  csyn_4c := 0;
  id_volatile := idntk(ctk_identifier, 'volatile', 8);
  idu_volatile := idntk(ctk_identifier, '__volatile', 10);
  id_read := idntk(ctk_identifier, 'read', 4);
  idu_read := idntk(ctk_identifier, '__read', 6);
  id_write := idntk(ctk_identifier, 'write', 5);
  idu_write := idntk(ctk_identifier, '__write', 7);
  id_address := idntk(ctk_identifier, 'address', 7);
  idu_address := idntk(ctk_identifier, '__address', 9);
  id_device := idntk(ctk_identifier, 'device', 6);
  idu_device := idntk(ctk_identifier, '__device', 8);
  id_bit := idntk(ctk_identifier, 'bit', 3);
  id_byte := idntk(ctk_identifier, 'byte', 4);
  id_word := idntk(ctk_identifier, 'word', 4);
  id_long := idntk(ctk_identifier, 'long', 4);
  id_quad := idntk(ctk_identifier, 'quad', 4);
  id_size := idntk(ctk_identifier, 'size', 4);
  id_aligned := idntk(ctk_identifier, 'aligned', 7);
  idu_aligned := idntk(ctk_identifier, '__aligned', 9);
  id_unaligned := idntk(ctk_identifier, 'unaligned', 9);
  id_natural := idntk(ctk_identifier, 'natural', 7);
  idu_natural := idntk(ctk_identifier, '__natural', 9);
  id_physical := idntk(ctk_identifier, 'physical', 8);
  id_processor_register := idntk(ctk_identifier, 'processor_register', 18);
  id_fp_internal_register := idntk(ctk_identifier, 'fp_internal_register', 20);
  id_register := idntk(ctk_identifier, 'register', 8);
  id_immediate := idntk(ctk_identifier, 'immediate', 9);
  id_reference := idntk(ctk_identifier, 'reference', 9);
  id_atomic := idntk(ctk_identifier, 'atomic', 6);
  idu_atomic := idntk(ctk_identifier, '__atomic', 8);
  id_no_fp := idntk(ctk_identifier, 'no_fp', 5);
  id_save_db := idntk(ctk_identifier, 'save_db', 7);
  id_section := idntk(ctk_identifier, 'section', 7);
  idu_section := idntk(ctk_identifier, '__section', 9);
  id_resident_procedure := idntk(ctk_identifier, 'resident_procedure', 18);
  cdef_id_setjmp := idntk(ctk_identifier, 'setjmp', 6);
  cdef_2c := 0;
  cdef_id_pfm_cleanup := idntk(ctk_identifier, 'pfm_$cleanup', 12);
  cdef_1c := 0;
  cdef_id_usetjmp := idntk(ctk_identifier, '_setjmp', 7);
  cdef_24 := 0;
  cdef_id_sigsetjmp := idntk(ctk_identifier, 'sigsetjmp', 6);
  cdef_14 := 0;
  cdef_id_longjmp := idntk(ctk_identifier, 'longjmp', 6);
  cdef_0c := 0;
  cdef_id_ulongjmp := idntk(ctk_identifier, '_longjmp', 7);
  cdef_04 := 0;
  cexs_23bc := 0;
  cst_5fa := 0;
  csyn_202 := 1;
  csyn_60[1] := 3;
  cst_stack_size := as_info_$stack_size;
  c_expr_syn_$begin_compilation;
  if cargs_$options.ansi or cargs_$options.xansi then
    cargs_$options.opt_on := cargs_$options.opt_on - [2];
  perfinit;
  get_time_stamp;
  perfstart(0);
  if preprocess then begin
    syntax;
    fe_cc_$end_compilation;
    perfstop(0);
    last_line := lex_line;
    cerr_quiet := true;
    if (cargs_$options.es <> 1) and (cargs_$options.es <> 2) then begin
      make_main_pgm;
      cr_$initialize(true);
      if (cargs_$options.tree <> 0) or
         ((lex_errors = 0) and (iosub_$object_open in iosub_$state)) then
        run_backend(1, addr(do_lex_for_listings), last_line, nil);
      if cargs_$options.map then
        sym_map;
      perfsummary(lex_total_lines);
      summary.length := 0;
      if lex_errors = 0 then
        prtcats(summary, 'No errors', 9)
      else if lex_errors = 1 then
        prtcats(summary, '1 error', 7)
      else begin
        prtint(summary, lex_errors, 4, false);
        prtcats(summary, ' errors', 7);
      end;
      if lex_warnings = 0 then
        prtcats(summary, ', no warnings', 13)
      else if lex_warnings = 1 then
        prtcats(summary, ', 1 warning', 11)
      else begin
        prtcats(summary, ', ', 2);
        prtint(summary, lex_warnings, 4, false);
        prtcats(summary, ' warnings', 9);
      end;
      if lex_infos = 0 then
        prtcats(summary, ', no info msgs', 14)
      else if lex_infos = 1 then
        prtcats(summary, ', 1 info msg', 12)
      else begin
        prtcats(summary, ', ', 2);
        prtint(summary, lex_infos, 4, false);
        prtcats(summary, ' info msgs', 10);
      end;
      prtcats(summary, ', ', 2);
      prtcats(summary, cargs_$version_string, cargs_$version_length);
      len := summary.length;
      if (iosub_$object_open in iosub_$state) and (lex_errors = 0) then begin
        prtcats(summary, ', ', 2);
        cat_time_info(summary);
      end;
      listln(summary);
      summary.length := len;
      if not (3 in cargs_$options.flags_286) then
        typemsg(summary);
    end;
  end;
  severity := 0;
  if lex_errors <> 0 then
    severity := 4
  else if lex_warnings <> 0 then
    severity := 2;
  io_term(severity);
  if cpp_temp then
    c_delete_temp(argv^[3]);
  pfm_$rls_cleanup(crec, status);
  status.all := 0;
  do_report(2, lex_total_lines, status);
  pgm_$set_severity(severity);
  pgm_$exit;
end.
