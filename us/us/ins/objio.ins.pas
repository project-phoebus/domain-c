{ us/us/ins/objio.ins.pas - OBJ_, the object file I/O of the binder,
  linked into the compiler from lang/bind/source/objio.pas: object files
  opened as channels, read and written by mapping.

  No copy survives.  The status codes and headings are the source
  repository's com/bind/objio.ins.pas reconstruction (read off the SR10.2
  /com/bind's objio and its callers).  The OBJ records are in
  us/us/ins/objmod.ins.pas, which every unit opening this insert opens
  first.

  Include /sys/ins/base.ins.pas (us/us/ins/ubase.ins.pas) and
  us/us/ins/objmod.ins.pas before it.

  Not known from the original: every name here but the routines'.
}

const
  { Status codes. }
  obj_$too_many_channels = 16#04040001;
  obj_$channel_not_open = 16#04040002;
  obj_$outside_file = 16#04040003;      { get or put outside the file }
  obj_$no_rw_storage = 16#04040004;
  obj_$temp_file_open = 16#04040005;
  obj_$not_an_object = 16#04040006;
  obj_$not_open_for_write = 16#04040007;  { put on a channel opened to read }
  obj_$bad_channel = 16#04040008;       { channel 0 }

type
  obj_$string_t = array[1..256] of char;
  obj_$pname_t = array[1..1024] of char;  { a pathname }

{ OBJ_$INIT_IO - start the module: no channels open; the channels are
  cleaned up when the program ends. }
procedure obj_$init_io; extern;

{ OBJ_$VALIDATE_OBJECT_MODULE - whether a file (its UID, uid_$nil when
  it has none) is an object file or can become one: COFF, OBJ, a
  compound executable, or an unstructured file holding a COFF file
  header's magic number. }
procedure obj_$validate_object_module(
    in name: univ obj_$pname_t;
    in name_len: integer;
    in uid: uid_$t;
    out status: status_$t); extern;

{ OBJ_$GET_MY_OBJ_INFO - the running program's name (its module's),
  version and time; failed true when its object file cannot be read.
  The first argument is not read. }
procedure obj_$get_my_obj_info(
    in key: integer;
    out name: univ obj_$name_t;
    out version: integer;
    out time: integer32;
    out failed: boolean); extern;

{ OBJ_$PUT - map len bytes of a channel opened to write, from offset,
  for the caller to fill. }
function obj_$put(
    in chan: pinteger;
    in offset: linteger;
    in len: linteger;
    out status: status_$t): univ_ptr; extern;

{ OBJ_$INQ_TYPE_UID - the type of the object a channel is open on. }
procedure obj_$inq_type_uid(
    in chan: pinteger;
    out type_uid: uid_$t); extern;

{ OBJ_$INQ_TS, OBJ_$INQ_UNIX_TS - an object file's time (its module
  header's or its COFF file header's), as the high 32 bits of the Apollo
  clock or as Unix seconds. }
function obj_$inq_ts(in chan: pinteger): integer32; extern;
function obj_$inq_unix_ts(in chan: pinteger): integer32; extern;

{ OBJ_$OPEN_W - create an object file (truncated if it exists) and
  open it to write. }
procedure obj_$open_w(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out status: status_$t); extern;

{ OBJ_$OPEN_WL - open an object file to write, creating it if it does
  not exist; existed tells which. }
procedure obj_$open_wl(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out existed: boolean;
    out status: status_$t); extern;

{ OBJ_$OPEN_T - open a new object file to write, under its name only
  when it is closed: an existing file of the name is renamed .bak until
  then, and deleted at the close.  One at a time. }
procedure obj_$open_t(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out status: status_$t); extern;

{ OBJ_$OPEN_R_TAG - open an object file to read: in a compound
  executable, the part with the tag (tag_len 0: 'm68k'); len is the
  length of what is read. }
procedure obj_$open_r_tag(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    in tag: univ obj_$string_t;
    in tag_len: integer;
    out len: integer32;
    out status: status_$t); extern;

{ OBJ_$OPEN_R - open an object file to read; len is its length. }
procedure obj_$open_r(
    out chan: pinteger;
    in name: univ obj_$pname_t;
    in name_len: integer;
    out len: integer32;
    out status: status_$t); extern;

{ OBJ_$CLOSE - close a channel: unmap what is mapped; a file written
  gets its length, and under OBJ_$OPEN_T its name. }
procedure obj_$close(
    in chan: pinteger;
    out status: status_$t); extern;

{ OBJ_$FREE - give back what obj_$get or obj_$put mapped. }
procedure obj_$free(
    in chan: pinteger;
    in ptr: univ_ptr;
    out status: status_$t); extern;

{ OBJ_$GET - map len bytes of an open file from offset. }
function obj_$get(
    in chan: pinteger;
    in offset: linteger;
    in len: linteger;
    out status: status_$t): univ_ptr; extern;

{ OBJ_$GET_NAME - the pathname of the file a channel is open on. }
procedure obj_$get_name(
    in chan: pinteger;
    out name: univ obj_$pname_t;
    out name_len: integer;
    out status: status_$t); extern;

{ OBJ_$MAP - map a whole file to write (4 MB of it); len is what was
  mapped. }
function obj_$map(
    in chan: pinteger;
    out len: linteger;
    out status: status_$t): univ_ptr; extern;

{ OBJ_$SET_LENGTH - the length a file written will have. }
procedure obj_$set_length(
    in chan: pinteger;
    in len: integer32;
    out status: status_$t); extern;

{ SEARCH_APOLLO_SECTION_TABLES, SEARCH_APOLLO_GLOBAL_TABLES - whether
  an OBJ file has a section whose name is a global (a defined global
  symbol not hidden) of the name; a file that cannot be read ends the
  program. }
function search_apollo_section_tables(
    in chan: pinteger;
    in file_name: univ obj_$pname_t;
    in file_name_len: integer;
    in name: univ obj_$name_t;
    in name_len: integer): boolean; extern;

function search_apollo_global_tables(
    in chan: pinteger;
    in file_name: univ obj_$pname_t;
    in file_name_len: integer;
    in name: univ obj_$name_t;
    in name_len: integer): boolean; extern;
