{ lang/lang/source/gen_utils.ins.pas - part of the compilers' common prelude
  (lang/lang/source/globals.ins.pas includes it).

  The interface of lang/lang/source/gen_utils.pas.

  No Apollo copy survives; reconstructed from the DOMAIN C 6.9 binaries
  (docs/core-plan.md).
}

{ GEN_UTILS - code generation helpers: address constants (kind 163 and
  195 nodes) in a section's chain, sections (182 code, 183 data),
  transfer vectors (192), external references (194) and the libraries
  the program is bound with (-inlib, through OBJUTIL_).  gen_utils.pas
  (cc.m68k 0x07C3C4..0x07D4C4, cc.a88k 0x07DDA4..0x07EEA4).  Headings
  from the bodies and the call sites.

  Not known from the original: every parameter name. }

type
  { A NUL-terminated name as OBJUTIL_ passes it to inlib_error. }
  gen_utils_$cstring_t = array [1..1024] of char;

{ INLIB_ERROR - the error routine OBJUTIL_ reports through (passed to
  objutil_$inlib_init): the message, `(file name, line n)' when there
  is a name, reported with cgerr_no_source code 30, 31 or 32 by
  severity 0, 1 or other.  0x07C3C4: every parameter by address. }
procedure inlib_error(
    in severity: integer;
    in line: integer;
    in name: univ gen_utils_$cstring_t;
    in msg: univ gen_utils_$cstring_t); extern;

{ INLIB_INIT, INLIB_TERM - start and end reading the libraries the
  program is bound with (-inlib).  0x07C552, 0x07C582. }
procedure inlib_init; extern;
procedure inlib_term; extern;

{ INLIB_ADD - a library to read: its name and the name's length.
  0x07C59C: name by address, len a word by value (its slot passed by
  address to objutil_$inlib_libname). }
procedure inlib_add(
    in name: univ cargs_$chars_t;
    len: integer); options(val_param); extern;

{ MAKE_ABS_ADDR_CON - the kind 195 node of (kind, sym, value) in
  il_130's chain, entered when new.  0x07C5C6. }
function make_abs_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32): il_$node_ptr_t; options(val_param); extern;

{ CHECK_FOR_ADDR_CON - the address constant of sym (or of a symbol of
  the same name) and value in sect's chain, or nil.  0x07C63E. }
function check_for_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GET_ADDR_CON - make_new_addr_con for offset rounded to a multiple of
  target_properties.p_88; offset keeps the rest.  0x07C8EC: offset by
  address. }
function get_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    var offset: integer32;
    sect: il_$node_ptr_t;
    no_inlib: boolean): il_$node_ptr_t; options(val_param); extern;

{ MAKE_NEW_ADDR_CON - the address constant of sym and value in sect,
  an absolute one (make_abs_addr_con) for a symbol found in an -inlib
  library unless no_inlib.  0x07C9F8. }
function make_new_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t;
    no_inlib: boolean): il_$node_ptr_t; options(val_param); extern;

{ GET_PROC_ADDR_CON - the procedure address constant (kinds 6, 7, 12)
  of sym and value in sect, entered when new.  0x07CD52. }
function get_proc_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GEN_UTILS_$ALLOC_NEW_ADDR_CON - a new address constant of sym and
  value at the head of sect's chain.  0x07D414. }
function gen_utils_$alloc_new_addr_con(
    kind: integer;
    sym: il_$node_ptr_t;
    value: integer32;
    sect: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ CHANGE_NAME_LOWER_CASE - id's characters to buf, made lower case
  unless cargs_$options.b28a_6.  0x07C966: id and buf by address. }
procedure change_name_lower_case(
    in id: il_$node_ptr_t;
    out buf: univ cargs_$chars_t); extern;

{ FIND_AC_DSECT - the data section whose chain holds ac, or nil.
  0x07CE7A. }
function find_ac_dsect(
    ac: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GET_XDYNM_PTR, MAKE_XDYNM_PTR - the address constant of a routine's
  (blk's) dynamic area at value, entered in its chain (+180) when new;
  get_xdynm_ptr rounds offset as get_addr_con does.  0x07CECE (offset
  by address), 0x07CF2E. }
function get_xdynm_ptr(
    blk: il_$node_ptr_t;
    var offset: integer32): il_$node_ptr_t; options(val_param); extern;

function make_xdynm_ptr(
    blk: il_$node_ptr_t;
    value: integer32): il_$node_ptr_t; options(val_param); extern;

{ CHECK_SECTION_NAME - the code, data or il_118 section named as name,
  else name.  0x07D0C4. }
function check_section_name(
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ ADD_PSECT, ADD_DSECT - enter a code (procedure) or data section of the
  name (an identifier node); the section's node.  0x07D15C, 0x07D1D4;
  il.pas's initialize_module enters `.text' and `.data'. }
function add_psect(
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

function add_dsect(
    name: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GET_TRANSFER_VECTOR - the transfer vector entry of sym (kind 192),
  entered when new.  0x07D2EE. }
function get_transfer_vector(
    sym: il_$node_ptr_t): il_$node_ptr_t; options(val_param); extern;

{ GET_EXTERNAL_REF - enter sym as an external reference (kind 194)
  when new.  0x07D3B6. }
procedure get_external_ref(
    sym: il_$node_ptr_t); options(val_param); extern;
