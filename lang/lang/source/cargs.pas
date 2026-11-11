{ cargs - CARGS, the compiler's command line: the options' defaults, the
  source file name (or -USAGE, -HELP, -VERSION), the options into
  cargs_$options (parse_options, an if-else chain over the option names,
  each matched by match_arg against a pattern such as `-NANSI.'), the
  arguments the KAP preprocessor is to get (push_kap), and the compiler's
  name and version string.

  Image addresses (DOMAIN C 6.9):
    cc.m68k   cc.a88k
    0x0B2568  0x0B6228  argument_error
    0x0B2584  0x0B6244  print_version
    0x0B25E8  0x0B62A8  set_name
    0x0B2652  0x0B6312  push_kap
    0x0B26E0  0x0B63A0  match_arg
    0x0B277C  0x0B643C  option_error
    0x0B2788  0x0B6448  match
    0x0B27AC  0x0B646C  arg_option_parameter
    0x0B2854  0x0B6514  arg_option_parameter_numeric
    0x0B296C  0x0B662C  fill_array_with_args
    0x0B29B6  0x0B6676  parse_opt_on_or_off
    0x0B2A50  0x0B6710  parse_options
    0x0B4732  0x0B81E8  build_my_name_string
    0x0B48D0  0x0B8386  get_compiler_image_timestamp_and_edit_number
    0x0B4906  0x0B83BC  encode_it
    0x0B496E  0x0B8424  build_my_version_string
    0x0B4A18  0x0B84D4  cargs_$identify_self
    0x0B4A54  0x0B8510  get_little_version
    0x0B4A86  0x0B8542  cargs_$init_option_defaults
    0x0B4CF2  0x0B87BA  match
    0x0B4D16  0x0B87DE  no_source_file
    0x0B4D94  0x0B885C  cargs_$parse_command_line_fixed_arguments
    0x0B4E9A  0x0B8962  cargs_$parse_command_line_options
    0x0B4F0E  0x0B89D6  cargs_$parse_line_options
    A5 0x2C33EC (cc.m68k), 0x443570 (cc.a88k): the module's data, 0xA3F8
    bytes (to iosub's), laid out as cargs.ins.pas describes; the 30 names
    -OPT_ON and -OPT_OFF take (+0x2BE8, 1024 characters each) are
    initialized, nothing else is.

  The binaries differ in parse_options (0x16FE and 0x153E bytes) and
  cargs_$init_option_defaults (0x26C, 0x278): cc.m68k has -VARARGS,
  -AEGIS10, -NPEB, -PEB, -CPU460 (and 660, 160), -NC, -C, -CC, -DUMP68
  and the 68K processors of -CPU; cc.a88k has -NO_FP, -SOME_FP, -INVOL,
  -VENDOR, -PRASM, the a88k processors of -CPU and the warning when -CPU
  names another; its default optimizations lack 13, 14 and 20, its
  default processor is 6 and -INDEXL is on by default.  The one source
  tests the conditional variable cc_a88k (tools/cc_check.sh sets it for
  cc.a88k); the original's mechanism is not known.

  argument_error, set_name, match_arg and parse_options do not load A5
  (internal); the others are global.  parse_options' nested routines
  share its frame: the argument vector and count, the argument index
  (-32), the current argument (-16), the current option parameter (-20)
  and `first' (-48, true until the argument's first parameter is taken).

  Not known from the original: every name but the routines'; the type
  names; how the 68K and a88k variants were selected.
}
module cargs;

%include 'lang/lang/source/globals.ins.pas';
%include 'us/us/ins/ubase.ins.pas';
%include '/sys/ins/pgm.ins.pas';
%include '/sys/ins/error.ins.pas';
%include '/sys/ins/vfmt.ins.pas';
%include 'us/us/ins/name.ins.pas';
%include 'us/us/ins/objmod.ins.pas';
%include 'us/us/ins/objio.ins.pas';
%include 'us/us/ins/helplib.ins.pas';
%include 'lang/lang/source/versions.ins.pas';
%include 'lang/common/source/ass.ins.pas';
%include 'lang/common/source/std.ins.pas';
%include 'lang/common/source/diag.ins.pas';
%include 'lang2/source/ftn/source/kap.ins.pas';

%var cc_a88k;

const
  { The optimizations of -OPT 3 (the default, -OPTALL, -OPT alone) and
    -OPT 4 (the same and 26): the constants stored, cc.m68k 0x7677FBFE
    and 0x7E77FBFE, cc.a88k 0x76573BFE and 0x7E573BFE (bits 30..1). }
%if cc_a88k %then
  opt_on_3 = [0..8, 10..12, 15..17, 19, 21, 24, 25, 27..29];
  opt_on_4 = [0..8, 10..12, 15..17, 19, 21, 24..29];
%else
  opt_on_3 = [0..8, 10..17, 19..21, 24, 25, 27..29];
  opt_on_4 = [0..8, 10..17, 19..21, 24..29];
%endif

type
  { An argument: pgm_$arg (a length and 128 characters, 130 bytes);
    the argument vector of pgm_$get_args, and the vector
    cargs_$parse_line_options builds (512 bytes). }
  cargs_arg_ptr_t = ^pgm_$arg;
  cargs_argv_t = array [0..127] of cargs_arg_ptr_t;
  cargs_argv_ptr_t = ^cargs_argv_t;

  { The lists -DEF, -IDIR, -INLIB and -UNDEF add their arguments to
    (1-based: list^[n] at -4 + 4 * n). }
  cargs_arg_list_t = array [1..32767] of cargs_arg_ptr_t;
  cargs_arg_list_ptr_t = ^cargs_arg_list_t;

  { An -OPT_ON/-OPT_OFF name, as a match_arg pattern. }
  cargs_opt_name_t = array [1..1024] of char;

  cargs_opt_set_t = set of 0..29;

define
  cargs_$debug_switches,                { +0x200 }
  cargs_$options,                       { +0x278 }
  cargs_$source_name,                   { +0x26A8 }
  cargs_$version_string,                { +0x2AB0 }
  cargs_$2bd2,                          { +0x2BD2 }
  cargs_$timestamp,                     { +0x2BD4 }
  cargs_$version_length;                { +0x2BDE }

var
  kap_args: array [1..128] of cargs_arg_ptr_t;  { +0x0 }
  my_name: obj_$image_name_t;           { +0x2BB0: the compiler's name }
  word_2bd0: integer;                   { +0x2BD0: cleared with +0x2BD2 }
  edit_number: integer;                 { +0x2BD8 }
  my_compiler: integer;                 { +0x2BDA: 1 C, 2 FORTRAN, 3 Modula-2,
                                          4 Pascal, 5 the Ada code
                                          generator }
  kap_count: integer;                   { +0x2BDC }
  my_name_length: integer;              { +0x2BE0 }
  p_option: boolean;                    { +0x2BE2: -P }
  opt_names: array [0..29] of cargs_opt_name_t := [ { +0x2BE8 }
    'SETHI_U.', 'JMP_BRANCH.', 'CONST_FOLD.', 'FRONT_END_CSES.',
    'NO_REG_PURGE.', 'XXX_JMP.', 'DELAY.', 'CONST_MUL.', 'ASSIGN_MERGE.',
    'LIMITED_CSE.', 'REACHDEF.', 'LIVEVARS.', 'ASSIGN_ELIM.',
    'ALLOC_REGS.', 'INSTR_REORDER.', 'ALL_CSE.', 'LOOP_TREE.',
    'LOOP_CONS.', 'LOOP_GLOBALS.', 'VECTOR_TRANSFORM.', 'STRENGTH.',
    'DISTRIB.', 'LOOPUNROLL.', 'LOOPJAM.', 'INLINE.', 'INLINE_STMTFUN.',
    'INLINE_PLUS.', 'PEEPHOLE.', 'EXCEPTION_BRANCH.', 'STACK_FRAMES.'];

{ argument_error - stop the compilation for a bad command line.

  0x0B2568, 0x1A bytes, no A5: pgm_$set_severity(5) (a word constant
  after the routine), pgm_$exit. }

procedure argument_error; internal;
begin
  pgm_$set_severity(pgm_$internal_fatal);
  pgm_$exit;
end;

{ print_version - -VERSION.

  0x0B2584, 0x42 bytes.  With no version string (`tst.w (11230,A5)')
  vfmt_$write2 of 'Unknown compiler version%.' and a zero longword
  twice; else of '%a%.', the string and its length widened to a
  longword in a frame temporary. }

procedure print_version;
var
  length: integer32;
begin
  if cargs_$version_length = 0 then
    vfmt_$write2('Unknown compiler version%.', 0, 0)
  else begin
    length := cargs_$version_length;
    vfmt_$write2('%a%.', cargs_$version_string, length);
  end;
end;

{ set_name - name := the argument (when there is one and it is not
  empty): blanks, then at most 1024 characters, then a null after a
  shorter name.

  0x0B25E8, 0x6A bytes, no A5: arg (12) by value, tested against nil;
  the blanks stored one and then 3 at a time (341 passes); the copy a
  counted loop from 1 (`dbf'); the null at body[length + 1] when length
  < 1024. }

procedure set_name(
    out name: cargs_$name_t;
    arg: cargs_arg_ptr_t); options(val_param); internal;
var
  n: integer;
  i: integer;
begin
  if (arg <> nil) and (arg^.len > 0) then begin
    name.body := ' ';
    n := arg^.len;
    if n > 1024 then
      n := 1024;
    name.length := n;
    for i := 1 to n do
      name.body[i] := arg^.chars[i];
    if name.length < 1024 then
      name.body[name.length + 1] := chr(0);
  end;
end;

{ push_kap - keep `-mp' and the len characters of s for KAP.

  0x0B2652, 0x8E bytes.  At most 128 (`cmpi.w #128; bcc', unsigned):
  the count grows, an argument is obtained with PAS_$NEW (`pea 0x82',
  130 bytes), its characters set to '-mp' and blanks, s copied after
  the 3 (a counted loop, s[i] to chars[3 + i]), its length set to len +
  3, and it is kept at kap_args[count] (`move.l A0,(-4,A5,D0.l)'). }

procedure push_kap;
var
  p: cargs_arg_ptr_t;
  i: integer;
begin
  if kap_count < 128 then begin
    kap_count := kap_count + 1;
    new(p);
    p^.chars := '-mp';
    for i := 1 to len do
      p^.chars[3 + i] := s[i];
    p^.len := len + 3;
    kap_args[kap_count] := p;
  end;
end;

{ match_arg - whether arg matches pattern, ignoring case and trailing
  blanks.  The pattern ends at '.' or ']'; the part after '[' is
  optional (`-OPT[...]').

  0x0B26E0, 0x9C bytes, no A5: arg's length less trailing blanks (D3);
  pattern index D2, arg index D4, `optional' a frame byte (-20).  Each
  pattern character is made upper case (`cmpi.b #97; bcs; cmpi.b #122;
  bhi; subi.b #32') and compared in a case of compare chain: ']' and
  '.' answer arg exhausted (`cmp.l D3,D4; sgt'), '[' sets optional;
  any other answers optional when arg is exhausted, else the next arg
  character, made upper case, must equal it.

  Not known from the original: the locals' names; the form of the loop
  (the image jumps back to the head of the case). }

function match_arg(
    in pattern: univ cargs_opt_name_t;
    arg: cargs_arg_ptr_t): boolean; options(val_param); internal;
var
  n: integer32;
  i: integer32;
  j: integer32;
  c: char;
  d: char;
  optional: boolean;
begin
  n := arg^.len;
  while (n <> 0) and (arg^.chars[n] = ' ') do
    n := n - 1;
  j := 1;
  i := 1;
  optional := false;
  repeat
    c := pattern[i];
    i := i + 1;
    if (c >= 'a') and (c <= 'z') then
      c := chr(ord(c) - 32);
    case c of
      ']', '.': begin
        match_arg := j > n;
        return;
      end;
      '[':
        optional := true;
      otherwise begin
        if j > n then begin
          match_arg := optional;
          return;
        end;
        d := arg^.chars[j];
        if (d >= 'a') and (d <= 'z') then
          d := chr(ord(d) - 32);
        j := j + 1;
        if d <> c then begin
          match_arg := false;
          return;
        end;
      end;
    end;
  until false;
end;

{ parse_options - the options in argv^[2..argc - 1] into opts; -DEF,
  -IDIR, -INLIB and -UNDEF add their arguments to the four lists (count,
  size, list); dot, when not nil and the -IDIR list has room, is made
  `.' and entered first.

  0x0B2A50 (cc.a88k 0x0B6710), 0x16FE bytes (0x153E), no A5; opts in
  A2.  The four counts are cleared first.  Each argument with a
  positive length is matched against the option patterns in turn
  (match, 105 call sites); an unknown one is reported ('"%UA" is not a
  recognized option.%$', 0x0B404C) and stops the compilation
  (option_error).  -OPT_ON and -OPT_OFF collect elements in two sets
  (cc.m68k D3 and D2, cc.a88k frame longwords) applied after the loop,
  -NFPRA a flag (D5, -46).  After the loop (0x0B4072): cc.m68k removes
  -ALIGN for the PEB; -DBA keeps only the safe optimizations; the
  options -FORCE_INLINE implies are added and the -OPT_ON and -OPT_OFF
  sets applied; cc.a88k forces processor 6 (with a warning) unless -TREE
  was given, and removes -AC for processor 6; -ES and -ESF drop the
  binary and listing (with a warning), else -EXP without a binary is an
  error; -NFPRA clears fpra.

  The packed fields are written one assignment each; Rev 8.89 merges
  consecutive stores of one constant (docs/rev889-patterns.md 10: -IMAP
  `ori.w #0x180', -ANSI `or.w #0x34').  `a or b or c' of matches is
  evaluated whole (the results or-ed in a frame byte, -54) except in
  cc.a88k's -VENDOR/-PRASM and -NVENDOR/-NPRASM, which branch after the
  first.  Shared tails (the store of a -OPT level's constants, the set
  stores of -CPU's choices, -EXP's and -PRASM's in cc.a88k) are
  separate statements here.

  Not known from the original: the locals' names; whether the chain was
  written as one if-else chain (the image tests each pattern in turn and
  every action jumps to the loop's increment). }

procedure parse_options(
    argv: cargs_argv_ptr_t;
    argc: integer;
    var opts: cargs_$options_t;
    var ndef: integer;
    maxdef: integer;
    deflist: cargs_arg_list_ptr_t;
    var nidir: integer;
    maxidir: integer;
    idirlist: cargs_arg_list_ptr_t;
    dot: cargs_arg_ptr_t;
    var ninlib: integer;
    maxinlib: integer;
    inliblist: cargs_arg_list_ptr_t;
    var nundef: integer;
    maxundef: integer;
    undeflist: cargs_arg_list_ptr_t); options(val_param); internal;
var
  arg: cargs_arg_ptr_t;                 { -16 }
  param: cargs_arg_ptr_t;               { -20 }
  i: integer;                           { -32 }
  first: boolean;                       { -48 }
  off_set: cargs_opt_set_t;             { D2 (cc.a88k -12) }
  on_set: cargs_opt_set_t;              { D3 (cc.a88k -8) }
  nfpra: boolean;                       { D5 (cc.a88k -46) }
  n: integer;
  k: integer;
%if cc_a88k %then
  c: char;
  j: integer;
  start: integer;
  negative: boolean;
  v: integer32;
%endif

  { option_error - stop for a bad option.  0x0B277C, 0xC bytes:
    argument_error. }

  procedure option_error;
  begin
    argument_error;
  end;

  { match - whether the current argument matches pattern.  0x0B2788,
    0x24 bytes: match_arg(pattern, arg); the parent's frame through the
    dynamic link (`movea.l (A6),A2'). }

  function match(
      in pattern: univ cargs_opt_name_t): boolean;
  begin
    match := match_arg(pattern, arg);
  end;

  { arg_option_parameter - the option's next parameter: the next
    argument when there is one and it does not begin with '-' (then it
    is taken); else nil, or, when required, an error that stops the
    compilation.

    0x0B27AC, 0x78 bytes: the parent's frame in A1; first := false;
    argv^[i + 1] read before the test (`cmp.l D2,D1; bge'). }

  function arg_option_parameter(
      required: boolean): cargs_arg_ptr_t; options(val_param);
  var
    p: cargs_arg_ptr_t;
  begin
    first := false;
    p := argv^[i + 1];
    if (i + 1 < argc) and (p^.chars[1] <> '-') then begin
      i := i + 1;
      arg_option_parameter := p;
    end
    else if not required then
      arg_option_parameter := nil
    else begin
      error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                        arg^.chars, arg^.len);
      option_error;
    end;
  end;

  { arg_option_parameter_numeric - the option's next parameter as a
    decimal number, -1 when there is none (an error when required).

    0x0B2854, 0xB2 bytes: a malformed digit is reported ('Malformed
    numeric parameter "%UA" option.%$') and stops the compilation; the
    value accumulates in a word (`add.w D2,D2; ... lsl.w #2', times 10). }

  function arg_option_parameter_numeric(
      required: boolean): integer; options(val_param);
  var
    p: cargs_arg_ptr_t;
    value: integer;
    j: integer;
    c: char;
  begin
    p := arg_option_parameter(required);
    if (p = nil) or (p^.len <= 0) then begin
      if required then begin
        error_$std_format(0,
          'Illegal or missing numeric parameter to "%UA" option.%$',
          arg^.chars, arg^.len);
        option_error;
      end;
      arg_option_parameter_numeric := -1;
    end
    else begin
      value := 0;
      for j := 1 to p^.len do begin
        c := p^.chars[j];
        if (c < '0') or (c > '9') then begin
          error_$std_format(0, 'Malformed numeric parameter "%UA" option.%$',
                            arg^.chars, arg^.len);
          option_error;
        end;
        value := value * 10 + (ord(c) - ord('0'));
      end;
      arg_option_parameter_numeric := value;
    end;
  end;

  { fill_array_with_args - add the option's parameters to a list, while
    it has room.

    0x0B296C, 0x4A bytes: the parameters taken with `first' (the
    parent's -48); `cmp.w (A2),D2; bls' (unsigned). }

  procedure fill_array_with_args(
      var count: integer;
      max: integer;
      list: cargs_arg_list_ptr_t); options(val_param);
  var
    p: cargs_arg_ptr_t;
  begin
    repeat
      p := arg_option_parameter(first);
      if p = nil then
        exit;
      if count < max then begin
        count := count + 1;
        list^[count] := p;
      end;
    until false;
  end;

  { parse_opt_on_or_off - add the optimizations the option's parameters
    name (opt_names) to s.

    0x0B29B6, 0x9A bytes: the parameter kept in the parent's param;
    the first one required (a frame byte, -14, true then false); each
    looked up in the 30 names (`dbf'), an unknown one reported
    ('Illegal or missing parameter ...') and stopping the compilation.

    Not known from the original: the locals' names. }

  procedure parse_opt_on_or_off(
      var s: cargs_opt_set_t);
  var
    required: boolean;
    found: boolean;
    j: integer;
  begin
    required := true;
    repeat
      param := arg_option_parameter(required);
      if param <> nil then begin
        found := false;
        for j := 0 to 29 do
          if match_arg(opt_names[j], param) then begin
            s := s + [j];
            found := true;
            exit;
          end;
        if not found then begin
          error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                            arg^.chars, arg^.len);
          option_error;
        end;
      end;
      required := false;
    until param = nil;
  end;

begin
  ndef := 0;
  nundef := 0;
  nidir := 0;
  ninlib := 0;
  if (maxidir <> 0) and (dot <> nil) then begin
    dot^.len := 1;
    dot^.chars[1] := '.';
    nidir := nidir + 1;
    idirlist^[nidir] := dot;
  end;
  off_set := [];
  nfpra := false;
  on_set := off_set;
  i := 2;
  while i < argc do begin
    first := true;
    arg := argv^[i];
    if arg^.len > 0 then begin
      if match('-ES.') then begin
        opts.es := 1;
        opts.outputs := opts.outputs - [1];
      end
      else if match('-ESF.') then begin
        opts.es := 2;
        opts.outputs := opts.outputs - [1];
        set_name(opts.esf_name, arg_option_parameter(false));
      end
      else if match('-NNATURAL.') then begin
        push_kap('nonatural', 9);
        opts.natural := false;
        opts.b28b_0 := false;
      end
      else if match('-NATURAL.') then begin
        push_kap('natural', 7);
        opts.natural := true;
        opts.b28b_0 := true;
      end
      else if match('-NINDEXL.') then
        opts.indexl := false
      else if match('-INDEXL.') then
        opts.indexl := true
      else if match('-NSUBCHK.') then
        opts.subchk := false
      else if match('-SUBCHK.') then
        opts.subchk := true
      else if match('-NFRND.') then
        opts.frnd := false
      else if match('-FRND.') then
        opts.frnd := true
      else if match('-NFPRA.') then
        nfpra := true
      else if match('-NALIGN.') then
        opts.flags_286 := opts.flags_286 - [4]
      else if match('-ALIGN.') then
        opts.flags_286 := opts.flags_286 + [4]
      else if match('-RUNTYPE.') then
        set_name(opts.runtype, arg_option_parameter(true))
      else if match('-NXRS.') then
        opts.xrs := false
      else if match('-XRS.') then
        opts.xrs := true
%if not cc_a88k %then
      else if match('-NVARARGS.') then
        opts.flags_286 := opts.flags_286 - [5]
      else if match('-VARARGS.') then
        opts.flags_286 := opts.flags_286 + [5]
%endif
      else if match('-PIC.') then
        opts.flags_286 := opts.flags_286 - [7, 8]
      else if match('-AC.') then
        opts.flags_286 := opts.flags_286 + [7, 8]
      else if match('-ABS.') then
        opts.flags_286 := opts.flags_286 - [8] + [7]
      else if match('-INLIB.') then begin
        opts.outputs := opts.outputs + [6];
        fill_array_with_args(ninlib, maxinlib, inliblist);
      end
      else if match('-IDIR.') then
        fill_array_with_args(nidir, maxidir, idirlist)
      else if match('-NCOND.') then begin
        opts.cond := false;
        push_kap('nodlines', 8);
      end
      else if match('-COND.') then begin
        opts.cond := true;
        push_kap('dlines', 6);
      end
      else if match('-NSTD.') then
        opts.std := false
      else if match('-STD.') then
        opts.std := true
      else if match('-NMAP.') then
        opts.map := false
      else if match('-MAP.') then begin
        opts.outputs := opts.outputs + [0];
        opts.map := true;
      end
      else if match('-IMAP.') then begin
        opts.map := true;
        opts.imap := true;
        opts.outputs := opts.outputs + [0];
      end
      else if match('-ACMAP.') then begin
        opts.map := true;
        opts.acmap := true;
        opts.outputs := opts.outputs + [0];
      end
      else if match('-P.') then
        p_option := true
      else if match('-NTYPE.') then begin
        push_kap('notype', 6);
        opts.type_opt := false;
        opts.xansi := false;
        opts.stdc := false;
      end
      else if match('-TYPE.') then begin
        push_kap('type', 4);
        opts.type_opt := true;
      end
      else if match('-USRCH.') then
        opts.usrch := true
      else if match('-NOCPP.') then
        opts.flags_286 := opts.flags_286 + [20]
      else if match('-UMSG.') then
        opts.flags_286 := opts.flags_286 + [12]
      else if match('-NCOMCHK.') then
        opts.comchk := false
      else if match('-COMCHK.') then
        opts.comchk := true
      else if match('-CPP.') then
        set_name(opts.cpp_name, arg_option_parameter(true))
      else if match('-DEF.') then
        fill_array_with_args(ndef, maxdef, deflist)
      else if match('-UNDEF.') then
        fill_array_with_args(nundef, maxundef, undeflist)
      else if match('-NSTDC.') then
        opts.stdc := false
      else if match('-SYSTYPE.') then
        set_name(opts.systype, arg_option_parameter(true))
      else if match('-OLDCPP.') then
        opts.flags_286 := opts.flags_286 + [19]
      else if match('-NULINE.') then
        opts.flags_286 := opts.flags_286 - [6]
      else if match('-ULINE.') then
        opts.flags_286 := opts.flags_286 + [6]
      else if match('-NANSI.') then begin
        opts.type_opt := false;
        opts.xansi := false;
        opts.nansi := true;
        opts.ansi := false;
        opts.stdc := false;
        opts.std := false;
      end
      else if match('-ANSI.') then begin
        opts.type_opt := true;
        opts.xansi := true;
        opts.ansi := true;
        opts.stdc := true;
        opts.std := true;
      end
      else if match('-XANSI.') then begin
        opts.type_opt := true;
        opts.xansi := true;
      end
      else if match('-NBSS.') then
        opts.flags_286 := opts.flags_286 - [11]
      else if match('-BSS.') then
        opts.flags_286 := opts.flags_286 + [11]
%if not cc_a88k %then
      else if match('-AEGIS10.') then
        opts.flags_286 := opts.flags_286 + [15]
%endif
      else if match('-FORCE_INLINE.') then
        opts.force_inline := true
      else if match('-NOPT.') then begin
        opts.opt := 1;
        opts.opt_on := [0..6, 25, 27];
      end
      else if match('-OPTALL.') then begin
        opts.opt := 6;
        opts.opt_on := opt_on_3;
      end
      else if match('-OPT.') then begin
        n := arg_option_parameter_numeric(false);
        if n < 0 then begin
          opts.opt := 6;
          opts.opt_on := opt_on_3;
        end
        else
          case n of
            0: begin
              opts.opt := 1;
              opts.opt_on := [0..6, 25, 27];
            end;
            1: begin
              opts.opt := 3;
              opts.opt_on := [0..9, 25, 27..29];
            end;
            2: begin
              opts.opt := 5;
              opts.opt_on := [0..10, 25, 27..29];
            end;
            3: begin
              opts.opt := 6;
              opts.opt_on := opt_on_3;
            end;
            4: begin
              opts.opt := 9;
              opts.opt_on := opt_on_4;
              opts.fpra := true;
            end;
            otherwise begin
              error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                                arg^.chars, arg^.len);
              option_error;
            end;
          end;
      end
      else if match('-OPT_OFF.') then
        parse_opt_on_or_off(off_set)
      else if match('-OPT_ON.') then
        parse_opt_on_or_off(on_set)
      else if match('-NB.') then
        opts.outputs := opts.outputs - [1]
      else if match('-B.') then begin
        opts.outputs := opts.outputs + [1, 2];
        set_name(opts.b_name, arg_option_parameter(false));
      end
      else if match('-BX.') then begin
        opts.outputs := opts.outputs + [1, 2, 5];
        set_name(opts.b_name, arg_option_parameter(true));
      end
      else if match('-NCOMPRESS.') then
        opts.ncompress := true
      else if match('-COMPRESS.') then
        opts.compress := true
      else if match('-CD.') then
        opts.cd := true
      else if match('-NCD.') then
        opts.cd := false
      else if match('-OLD_UNWIND.') then
        opts.unwind := 0
      else if match('-NEW_UNWIND.') then
        opts.unwind := 1
      else if match('-PROF.') then begin
        opts.flags_286 := opts.flags_286 + [10];
        opts.ncompress := true;
      end
      else if match('-NCLINES.') then
        opts.nclines := true
      else if match('-NDB.') then
        opts.db := 0
      else if match('-DBA.') then
        opts.db := 3
      else if match('-DBH.') then begin
        opts.dbh := true;
        opts.db := 2;
      end
      else if match('-DBS.') then
        opts.db := 2
      else if match('-DB.') then
        opts.db := 1
      else if match('-NMSGS.') then
        opts.flags_286 := opts.flags_286 + [3]
      else if match('-MSGS.') then
        opts.flags_286 := opts.flags_286 - [3]
      else if match('-NWARN.') then begin
        push_kap('suppress=w', 10);
        opts.warn := false;
      end
      else if match('-WARN.') then
        opts.warn := true
      else if match('-ALNCHK.') then
        opts.alnchk := not (6 in opts.cpu)
      else if match('-NEXTRA.') then
        opts.flags_286 := opts.flags_286 - [1]
      else if match('-EXTRA.') then
        opts.flags_286 := opts.flags_286 + [1]
      else if match('-NINFO.') then
        opts.info := 0
      else if match('-INFO.') then begin
        n := arg_option_parameter_numeric(false);
        if n < 0 then
          opts.info := 2
        else begin
          if n > 4 then begin
            error_$std_format(0,
              'Numeric parameter is too large for "%UA" option.%$',
              arg^.chars, arg^.len);
            option_error;
          end;
          opts.info := n;
        end;
      end
      else if match('-METER.') then
        opts.meter := true
      else if match('-NL.') then
        opts.outputs := opts.outputs - [0]
      else if match('-L.') then begin
        opts.outputs := opts.outputs + [0];
        set_name(opts.l_name, arg_option_parameter(false));
      end
      else if match('-NSTAT.') then
        opts.flags_286 := opts.flags_286 - [9]
      else if match('-STAT.') then
        opts.flags_286 := opts.flags_286 + [9]
      else if match('-NEXP.') then
        opts.exp := false
      else if match('-EXP.') then begin
        if (my_compiler = 2) and opts.map then begin
          opts.exp := false;
          opts.outputs := opts.outputs - [0];
        end
        else begin
          opts.exp := true;
          opts.outputs := opts.outputs + [0];
        end;
      end
      else if match('-TREE.') then begin
        opts.tree := 47;
        param := arg_option_parameter(false);
        while param <> nil do begin
          if match_arg('AF.', param) then opts.tree := 1
          else if match_arg('AI.', param) then opts.tree := 2
          else if match_arg('BDIST.', param) then opts.tree := 8
          else if match_arg('ADIST.', param) then opts.tree := 9
          else if match_arg('BFLOW.', param) then opts.tree := 12
          else if match_arg('AFLOW.', param) then opts.tree := 13
          else if match_arg('ADOM.', param) then opts.tree := 14
          else if match_arg('BUP.', param) then opts.tree := 15
          else if match_arg('AUP.', param) then opts.tree := 16
          else if match_arg('BFIND_LOOPS.', param) then opts.tree := 17
          else if match_arg('AFIND_LOOPS.', param) then opts.tree := 18
          else if match_arg('BRD.', param) then opts.tree := 19
          else if match_arg('ARD.', param) then opts.tree := 20
          else if match_arg('BSR.', param) then opts.tree := 21
          else if match_arg('SR0.', param) then opts.tree := 21
          else if match_arg('SR1.', param) then opts.tree := 22
          else if match_arg('SR2.', param) then opts.tree := 23
          else if match_arg('SR8.', param) then opts.tree := 29
          else if match_arg('SR9.', param) then opts.tree := 30
          else if match_arg('ASR.', param) then opts.tree := 30
          else if match_arg('BCSE.', param) then opts.tree := 31
          else if match_arg('ACSE.', param) then opts.tree := 32
          else if match_arg('BLOOPOPT.', param) then opts.tree := 33
          else if match_arg('ALOOPOPT.', param) then opts.tree := 34
          else if match_arg('BCSECLEANUP.', param) then opts.tree := 35
          else if match_arg('ACSECLEANUP.', param) then opts.tree := 36
          else if match_arg('BREVISEUSES.', param) then opts.tree := 37
          else if match_arg('AREVISEUSES.', param) then opts.tree := 38
          else if match_arg('BLIVEANALYSIS.', param) then opts.tree := 39
          else if match_arg('ALIVEANALYSIS.', param) then opts.tree := 40
          else if match_arg('BMOTION_CONSTANTS.', param) then opts.tree := 41
          else if match_arg('AMOTION_CONSTANTS.', param) then opts.tree := 42
          else if match_arg('BGENERAL_OPTS.', param) then opts.tree := 43
          else if match_arg('AGENERAL_OPTS.', param) then opts.tree := 44
          else if match_arg('BREG_ALLOC.', param) then opts.tree := 45
          else if match_arg('AREG_ALLOC.', param) then opts.tree := 46
          else if match_arg('AO.', param) then opts.tree := 47
          else if match_arg('BCG.', param) then opts.tree := 48
          else if match_arg('ACG.', param) then opts.tree := 49
          else if match_arg('EXP.', param) then opts.tree := 50
          else if match_arg('NA.', param) then opts.na := true
          else if match_arg('NN.', param) then opts.nn := true
          else if match_arg('ADDR.', param) then opts.addr := true
          else if match_arg('BCT.', param) then opts.bct := true
          else begin
            error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                              arg^.chars, arg^.len);
            option_error;
          end;
          param := arg_option_parameter(false);
        end;
        opts.outputs := opts.outputs + [0];
      end
%if not cc_a88k %then
      else if match('-NPEB.') or match('-CPUANY.') or match('-CPUALL.') then
        opts.cpu := [0]
      else if match('-PEB.') or match('-CPUPEB.') then
        opts.cpu := [1]
      else if match('-CPU460.') or match('-CPU660.') or match('-CPU160.') then
        opts.cpu := [2]
      else if match('-NC.') then
        opts.c := 0
      else if match('-C.') then begin
        opts.c := 2;
        opts.outputs := opts.outputs + [0];
      end
      else if match('-CC.') then
        opts.c := 1
      else if match('-DUMP68.') then begin
        param := arg_option_parameter(true);
        while param <> nil do begin
          if match_arg('RA.', param) then
            opts.ra := true
          else if match_arg('RD.', param) then
            opts.rd := true
          else if match_arg('SRI.', param) then
            opts.sri := true
          else begin
            error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                              arg^.chars, arg^.len);
            option_error;
          end;
          param := arg_option_parameter(false);
        end;
      end
%else
      else if match('-NO_FP.') then
        opts.flags_286 := opts.flags_286 + [13]
      else if match('-SOME_FP.') then
        opts.flags_286 := opts.flags_286 + [14]
      else if match('-INVOL.') then begin
        { the debugging switches: letters, each followed by an optional
          octal number (1 when there is none; - negates, a lone - is
          16#8000) }
        param := arg_option_parameter(true);
        j := 1;
        while j <= param^.len do begin
          c := param^.chars[j];
          if not (c in ['A'..'Z', 'a'..'z']) then begin
            error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                              arg^.chars, arg^.len);
            option_error;
          end;
          j := j + 1;
          v := 0;
          start := j;
          negative := false;
          if j <= param^.len then
            if param^.chars[j] = '-' then begin
              negative := true;
              j := j + 1;
            end;
          while j <= param^.len do begin
            if (param^.chars[j] < '0') or (param^.chars[j] > '7') then
              exit;
            v := lshft(v, 3) ! (ord(param^.chars[j]) - ord('0'));
            j := j + 1;
          end;
          if j = start then
            v := 1;
          if negative then begin
            v := -v;
            if v = 0 then
              v := 16#8000;
          end;
          cargs_$debug_switches[c] := v;
        end;
      end
      else if match('-VENDOR.') or match('-PRASM.') then begin
        opts.flags_286 := opts.flags_286 + [16];
        opts.exp := true;
        opts.outputs := opts.outputs + [0];
      end
      else if match('-NVENDOR.') or match('-NPRASM.') then
        opts.flags_286 := opts.flags_286 - [16]
%endif
      else if match('-CPU.') then begin
        opts.cpu := [];
        k := 1;
        repeat
          param := arg_option_parameter(first);
          if param = nil then
            exit;
          if k <= 3 then begin
%if not cc_a88k %then
            if match_arg('ANY.', param) or match_arg('ALL.', param) or
               match_arg('M68k.', param) or match_arg('68000.', param) then
              opts.cpu := [0]
            else if match_arg('SR11.', param) then
              opts.cpu := [3, 4, 9]
            else if match_arg('MATHCHIP.', param) then
              opts.cpu := opts.cpu + [3, 4]
            else if match_arg('MATHLIB.', param) then
              opts.cpu := opts.cpu + [3, 4, 9]
            else if match_arg('MATHLIB_SR10.', param) then
              opts.cpu := opts.cpu + [3, 4, 10]
            else if match_arg('FPA1.', param) then
              opts.cpu := opts.cpu + [3, 8]
            else if match_arg('FPX.', param) then
              opts.cpu := opts.cpu + [3, 4, 5]
            else if match_arg('M881.', param) or match_arg('68881.', param) or
                    match_arg('560.', param) or match_arg('330.', param) or
                    match_arg('90.', param) or match_arg('3000.', param) or
                    match_arg('570.', param) or match_arg('580.', param) or
                    match_arg('5700.', param) then
              opts.cpu := opts.cpu + [3, 4]
            else if match_arg('68020.', param) or match_arg('M020.', param) then
              opts.cpu := opts.cpu + [3]
            else if match_arg('460.', param) or match_arg('660.', param) or
                    match_arg('160.', param) then
              opts.cpu := [2]
            else if match_arg('PEB.', param) then
              opts.cpu := [0, 1]
%else
            if match_arg('ANY.', param) or match_arg('ALL.', param) then
              opts.cpu := [6]
            else if match_arg('SR11.', param) then
              opts.cpu := opts.cpu
            else if match_arg('AT.', param) or match_arg('A88K.', param) or
                    match_arg('PRISM.', param) or match_arg('10000.', param) then
              opts.cpu := [6]
            else if match_arg('10000TX.', param) or match_arg('TX.', param) or
                    match_arg('KODIAK.', param) then
              opts.cpu := [6, 7]
%endif
            else begin
              error_$std_format(0, 'Illegal or missing parameter to "%UA" option.%$',
                                arg^.chars, arg^.len);
              option_error;
            end;
          end;
          k := k + 1;
        until false;
      end
      else begin
        error_$std_format(0, '"%UA" is not a recognized option.%$',
                          arg^.chars, arg^.len);
        option_error;
      end;
    end;
    i := i + 1;
  end;
%if not cc_a88k %then
  if 1 in opts.cpu then
    opts.flags_286 := opts.flags_286 - [4];
%endif
  if opts.db = 3 then begin
    opts.opt := 0;
    opts.opt_on := [0..3, 6, 25, 27];
  end;
  if opts.force_inline then
    opts.opt_on := opts.opt_on + [24..26];
  opts.opt_on := on_set + opts.opt_on - off_set;
%if cc_a88k %then
  if (opts.cpu - [7] <> [6]) and (opts.tree = 0) then begin
    error_$std_format(0,
      '*** Warning: -cpu option ignored; generating a88k code%.');
    opts.cpu := [6];
  end;
  if 6 in opts.cpu then
    opts.flags_286 := opts.flags_286 - [7, 8];
%endif
  if (opts.es <> 0) and (opts.outputs * [0, 2] <> []) then begin
    error_$std_format(0,
      'No binary or expanded listing produced since -es or -esf was specified.%$');
    opts.outputs := opts.outputs - [0, 1, 2];
  end
  else if not (2 in opts.outputs) and opts.exp then begin
    error_$std_format(0, '-EXP and -NB are incompatible options.%$');
    option_error;
  end;
  if nfpra then
    opts.fpra := false;
end;

{ cargs_$identify_self - record which compiler this is and build its
  name and version string.

  0x0B4A18, 0x3C bytes: compiler (a word by value) to +0x2BDA;
  build_my_name_string; ass_$initialise with the name and its length
  widened; the image's time stamp and edit number; the version
  string. }

procedure cargs_$identify_self;

  { build_my_name_string - the compiler's name: by the compiler, 'cc',
    'ftn', 'm2', 'pas', 'adacg' or 'compiler' (blank padded to 32),
    then, when the program's argument 0 can be had, its leaf
    (name_$strip_leaf_lc, at most 32 characters).

    0x0B4732, 0x19C bytes: the names stored as word, byte and longword
    constants and blanks, the shared tails of equal lengths jumped to.
    After a successful name_$strip_leaf_lc the name is blanked
    (`move.b #32,(A0)+' ... 32 bytes, 0x0B4872) and its upper-case
    letters, now blanks, made lower case: as the image has it.

    Not known from the original: the locals' names; whether the
    blanking after name_$strip_leaf_lc was meant (it loses the leaf). }

  procedure build_my_name_string;
  var
    argc: integer;                      { -20 }
    dir_length: integer;                { -18 }
    argv: pgm_$argv_ptr;                { -16 }
    status: status_$t;                  { -8 }
    arg0: cargs_arg_ptr_t;
    j: integer;
  begin
    if my_compiler = 1 then begin
      my_name := 'cc';
      my_name_length := 2;
    end
    else if my_compiler = 2 then begin
      my_name := 'ftn';
      my_name_length := 3;
    end
    else if my_compiler = 3 then begin
      my_name := 'm2';
      my_name_length := 2;
    end
    else if my_compiler = 4 then begin
      my_name := 'pas';
      my_name_length := 3;
    end
    else if my_compiler = 5 then begin
      my_name := 'adacg';
      my_name_length := 5;
    end
    else begin
      my_name := 'compiler';
      my_name_length := 8;
    end;
    pgm_$get_args(argc, argv);
    if argc > 0 then begin
      arg0 := cargs_arg_ptr_t(argv^[0]);
      if arg0 <> nil then begin
        name_$strip_leaf_lc(arg0^.chars, arg0^.len, 32, dir_length, my_name,
                            my_name_length, status);
        if status.all = status_$ok then begin
          my_name := ' ';
          for j := 1 to my_name_length do
            if (my_name[j] >= 'A') and (my_name[j] <= 'Z') then
              my_name[j] := chr(ord(my_name[j]) + 32);
        end;
      end;
    end;
  end;

  { get_compiler_image_timestamp_and_edit_number - from the image
    (obj_$get_my_obj_info); both cleared when they cannot be had.

    0x0B48D0, 0x34 bytes: `clr.l' of +0x2BD0 (the word there and
    cargs_$2bd2) and of +0x2BD4.

    Not known from the original: the locals' names. }

  procedure get_compiler_image_timestamp_and_edit_number;
  var
    failed: boolean;                    { -42 }
    image_name: obj_$image_name_t;      { -40 }
  begin
    obj_$get_my_obj_info(1234, image_name, edit_number, cargs_$timestamp,
                         failed);
    if failed then begin
      word_2bd0 := 0;
      cargs_$2bd2 := 0;
      cargs_$timestamp := 0;
    end;
  end;

  { build_my_version_string - 'C compiler 68K Rev 6.9' and, when the
    edit number is known, '(edit)', into cargs_$version_string.

    0x0B496E, 0x70 bytes: the place and capacity in the frame (-16, -14;
    1 and 256), the length of 'C compiler' (10) in a frame word passed
    by address; -12 cleared at the end and read by nothing; the version
    string's length set to the place less 1; +0x2BD0 cleared
    (`clr.l').

    Not known from the original: the locals' names; whether 10 was a
    variable or a constant Rev 8.89 put in the frame. }

  procedure build_my_version_string;
  var
    place: integer;                     { -16 }
    capacity: integer;                  { -14 }
    unused: integer;                    { -12 }
    length: integer;                    { -10 }

    { encode_it - vfmt_$encode of the control string and up to five
      arguments at the place; the place moves past the text.

      0x0B4906, 0x68 bytes: the five argument addresses passed on
      whatever the caller passed (calls pass 1 to 3); the capacity left
      (capacity - place + 1) in a frame word. }

    procedure encode_it(
        in control: univ vfmt_$string_t;
        in a1, a2, a3, a4, a5: univ vfmt_$generic_signed_arg);
        options(variable);
    var
      left: integer;                    { -12 }
      text_length: integer;             { -10 }
    begin
      left := capacity - place + 1;
      vfmt_$encode(control, cargs_$version_string[place], left, text_length,
                   a1, a2, a3, a4, a5);
      place := place + text_length;
    end;

  begin
    place := 1;
    capacity := 256;
    length := 10;
    encode_it('%MA %$', 'C compiler', length);
    encode_it('68K%$');
    encode_it(' Rev %JULD.%JULD%$', 6, 9);
    if edit_number <> 0 then
      encode_it('(%JUWD)%$', edit_number);
    unused := 0;
    cargs_$version_length := place - 1;
    word_2bd0 := 0;
    cargs_$2bd2 := 0;
  end;

begin
  my_compiler := compiler;
  build_my_name_string;
  ass_$initialise(my_name, my_name_length);
  get_compiler_image_timestamp_and_edit_number;
  build_my_version_string;
end;

{ get_little_version - 6, 9 and the image's edit number.

  0x0B4A54, 0x32 bytes: word stores through the three addresses. }

procedure get_little_version;
begin
  major := 6;
  minor := 9;
  edit := edit_number;
end;

{ cargs_$init_option_defaults - the options' defaults.

  0x0B4A86 (cc.a88k 0x0B8542), 0x26C bytes (0x278).  Field by field
  in record order; Rev 8.89 merges runs of one constant into one
  `andi'/`ori' (docs/rev889-patterns.md 10: `andi.l #0x7FF' of +0x278,
  `andi.w #0xF83F', `andi.w #0xFFE0' of +0x27B bits 4..0, cc.a88k
  `bclr #4; bset #3; andi.w #0xFFF8').  The six names (+0x28C ...) are
  emptied, their characters blanked (`move.b #32' then 0x20202020),
  except that +0xA90 (l_name) has only its length cleared and +0xE92
  (name_e92) only its characters blanked, as the image does
  (0x0B4C42: `clr.w (2704,A5); lea (3732,A5),A0').  The debugging
  switches are cleared 'A'..'z' (`dbf' from 57).

  Not known from the original: whether the l_name/name_e92 pairing was
  meant; the order of the stores within a merged run. }

procedure cargs_$init_option_defaults;
var
  letter: char;
begin
  with cargs_$options do begin
    tree := 0;
    b278_1 := false;
    b278_0 := false;
    b279_7 := false;
    b279_6 := false;
    b279_5 := false;
    bct := false;
    addr := false;
    na := false;
    nn := false;
    ra := false;
    b27a_7 := false;
    b27a_6 := false;
    sri := false;
    b27a_4 := false;
    rd := false;
    force_inline := false;
    exp := false;
    map := false;
    imap := false;
    acmap := false;
    type_opt := true;
    b27b_4 := false;
%if cc_a88k %then
    indexl := true;
%else
    indexl := false;
%endif
    subchk := false;
    b27b_1 := false;
    b27b_0 := false;
    x27c_7 := 10;
    b27c_3 := false;
    std := false;
    b27c_1 := false;
    cond := false;
    warn := true;
    usrch := false;
    comchk := false;
    xrs := true;
    c := 1;
    x27d_0 := 2;
    x27e_6 := 2;
    b27e_3 := true;
    opt := 6;
    info := 0;
    opt_on := opt_on_3;
    db := 1;
    dbh := false;
%if cc_a88k %then
    cpu := [6];
%else
    cpu := [3, 4, 10];
%endif
    es := 0;
    flags_286 := [4, 7..9, 16];
    if my_compiler in [1, 3, 5] then
      flags_286 := flags_286 + [0];
    if my_compiler in [1] then
      flags_286 := flags_286 + [2];
    if my_compiler = 1 then
      flags_286 := flags_286 + [6];
    x289 := 123;
    b28a_7 := false;
    if my_compiler in [1, 3, 5] then
      b28a_6 := true
    else
      b28a_6 := false;
    b28a_5 := false;
    b28a_4 := false;
    b28a_3 := false;
    alnchk := false;
    b28a_1 := false;
    compress := false;
    ncompress := false;
    cd := false;
    xansi := true;
    ansi := false;
    nansi := false;
    stdc := true;
    natural := false;
    b28b_0 := natural;
    systype.length := 0;
    systype.body := ' ';
    runtype.length := 0;
    runtype.body := ' ';
    l_name.length := 0;
    name_e92.body := ' ';
    b_name.length := 0;
    b_name.body := ' ';
    esf_name.length := 0;
    esf_name.body := ' ';
    cpp_name.length := 0;
    cpp_name.body := ' ';
    outputs := [1];
    meter := false;
    nclines := false;
    unwind := 0;
    name_1e9c.length := 0;
    b229e_7 := false;
    name_22a0.length := 0;
  end;
  for letter := 'A' to 'z' do
    cargs_$debug_switches[letter] := 0;
end;

{ cargs_$parse_command_line_fixed_arguments - the source file name, the
  first argument; or -USAGE, -HELP or -VERSION, then exit.

  0x0B4D94, 0xE4 bytes: argument 1 in a frame longword (-4); `done' in
  D2 (set, cleared when no query matched); help_$print_opts of 2, the
  mode (2 -USAGE, 1 -HELP), the compiler's name and length and
  'sr10.0', 6 (the two calls share their tail).  An argument beginning
  with '-' is not a file name. }

procedure cargs_$parse_command_line_fixed_arguments;
var
  argc: integer;                        { -10 }
  argv: pgm_$argv_ptr;                  { -8 }
  arg1: cargs_arg_ptr_t;                { -4 }
  done: boolean;

  { match - whether argument 1 matches pattern.  0x0B4CF2, 0x24 bytes. }

  function match(
      in pattern: univ cargs_opt_name_t): boolean;
  begin
    match := match_arg(pattern, arg1);
  end;

  { no_source_file - stop: no file name.  0x0B4D16, 0x2A bytes: the
    message by the compiler (5 the IL code generator), then
    argument_error. }

  procedure no_source_file;
  begin
    if my_compiler = 5 then
      error_$std_format(0, 'IL file name required as 1st argument.%$')
    else
      error_$std_format(0, 'Source file name required as 1st argument.%$');
    argument_error;
  end;

begin
  pgm_$get_args(argc, argv);
  if (argc <= 1) or (argv^[1] = nil) then
    no_source_file;
  arg1 := cargs_arg_ptr_t(argv^[1]);
  done := true;
  if match('-USAGE.') then
    help_$print_opts(2, 2, my_name, my_name_length, 'sr10.0', 6)
  else if match('-HELP.') then
    help_$print_opts(2, 1, my_name, my_name_length, 'sr10.0', 6)
  else if match('-VERSION.') then
    print_version
  else
    done := false;
  if done then
    pgm_$exit;
  if arg1^.chars[1] = '-' then
    no_source_file;
  set_name(cargs_$source_name, arg1);
end;

{ cargs_$parse_command_line_options - the command line's options into
  cargs_$options.

  0x0B4E9A, 0x74 bytes: pgm_$get_args, then parse_options with the
  vector, the count, cargs_$options (`pea (632,A5)') and the parameters
  passed on. }

procedure cargs_$parse_command_line_options;
var
  argc: integer;                        { -6 }
  argv: pgm_$argv_ptr;                  { -4 }
begin
  pgm_$get_args(argc, argv);
  parse_options(cargs_argv_ptr_t(argv), argc, cargs_$options,
                ndef, maxdef, cargs_arg_list_ptr_t(deflist),
                nidir, maxidir, cargs_arg_list_ptr_t(idirlist),
                cargs_arg_ptr_t(dot),
                ninlib, maxinlib, cargs_arg_list_ptr_t(inliblist),
                nundef, maxundef, cargs_arg_list_ptr_t(undeflist));
end;

{ cargs_$parse_line_options - the options in the len characters of line
  (words separated by blanks) into opts.

  0x0B4F0E, 0x114 bytes: a vector of 128 arguments obtained with
  PAS_$NEW (512 bytes) and filled from index 2 (at most 127; each word
  an argument of 130 bytes, at most 128 characters kept); parse_options
  with no lists (the counts a shared frame word, -10); the arguments and
  the vector given back with PAS_$DISPOSE.

  Not known from the original: the locals' names. }

procedure cargs_$parse_line_options;
var
  argv: cargs_argv_ptr_t;               { -8 }
  arg: cargs_arg_ptr_t;                 { -4 }
  none: integer;                        { -10 }
  argc: integer;
  i: integer;
  j: integer;
begin
  argc := 2;
  new(argv);
  i := 1;
  while (i <= len) and (argc <= 127) do begin
    while (i <= len) and (line[i] = ' ') do
      i := i + 1;
    if i <= len then begin
      new(arg);
      argv^[argc] := arg;
      arg^.len := 0;
      argc := argc + 1;
      while (i <= len) and (line[i] <> ' ') do begin
        if arg^.len < 128 then begin
          arg^.len := arg^.len + 1;
          arg^.chars[arg^.len] := line[i];
        end;
        i := i + 1;
      end;
    end;
  end;
  parse_options(argv, argc, opts, none, 0, nil, none, 0, nil, nil,
                none, 0, nil, none, 0, nil);
  for j := 2 to argc - 1 do
    dispose(argv^[j]);
  dispose(argv);
end;
