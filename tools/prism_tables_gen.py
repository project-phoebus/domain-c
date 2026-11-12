#!/usr/bin/env python3
"""prism_tables_gen.py - print the PRISM decode tables as Python literals.

    tools/prism_tables_gen.py [IMAGE]

The source repository's tools/prism_dis.py (the a88k disassembler,
domain_os/tools/prism_dis.py) builds its decoder from DOMAIN C 6.9's own
opcode tables, which it carries as literals (source commit 9695aa26)
rather than reading them from the image; this reads them from the image (cc.a88k, by default this checkout's
ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k) and prints that block, from
its `# ----' line to the end of OF_STRING, so it can be regenerated:

- instruction_assembly, 44 bytes an opcode: the register and immediate
  forms' templates (+0, +4), the flags byte (+8: 0x20 squash, 0x10 five
  operands, 0x0F the -PRASM operator's length), +9 (the name's length
  << 4 | the half-register bits << 1), the -PRASM layout (+10), the
  -PRASM operator (+11), the instruction_assembly name (+19), the four
  operands' halfwords (+36: field kind << 3 | format << 1);
- instruction_attributes, 20 bytes an opcode: each operand's form (+4k,
  k = 1..4) and its byte 2 (+4k+2; +14, operand 3's, is also the width
  and .CC flags), the class (+7), +11 (& 7: the operands shown), +19
  (& 7: log2 of the access size);
- instruction_mnemonic (12 bytes an entry) with instruction_mnemonic_length
  (a halfword an entry): the classic listing's names;
- of_string (34 bytes an entry) with of_string_length: the operand
  forms' names.

Only what prism_dis.py's load_tables() reads is printed: the first 212
opcodes, the first 43 forms, and of a record only the bytes it parses.

To check the embedded block:

    tools/prism_tables_gen.py > /tmp/t.py
    sed -n '/^# ---- the decode tables/,/^]  # end of OF_STRING/p' \\
        ~/src/domainos-archeology/source/domain_os/tools/prism_dis.py | diff - /tmp/t.py
"""
import hashlib
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOP = os.path.dirname(HERE)
IMAGE_REL = 'ctape/install/ri.apollo.cc.v.6.9.mpx/cc.a88k'

N_OPCODES = 212         # instruction_assembly and instruction_attributes hold these
N_FORMS = 43            # of$t

SECTIONS = ['of_string_length', 'of_string', 'instruction_mnemonic_length',
            'instruction_mnemonic', 'instruction_attributes', 'instruction_assembly']


def sections(d):
    """{name: (vaddr, size, file offset)} of an Apollo COFF image."""
    magic, nscns, _, symptr, nsyms, opthdr, _ = struct.unpack('>HHIIIHH', d[:20])
    if magic not in (0x194, 0x197):
        raise SystemExit('not an Apollo COFF file (magic 0x%X)' % magic)
    strtab = symptr + 18 * nsyms
    out = {}
    off = 20 + opthdr
    for _ in range(nscns):
        s = d[off:off + 40]
        off += 40
        if s[:4] == b'\0\0\0\0':                # a long name, in the string table
            o = strtab + struct.unpack('>I', s[4:8])[0]
            name = d[o:d.index(b'\0', o)].decode('latin1')
        else:
            name = s[:8].rstrip(b'\0').decode('latin1')
        _, va, sz, sp = struct.unpack('>IIII', s[8:24])
        out[name] = (va, sz, sp)
    return out


def h(v, n):
    return '0x%0*X' % (n, v)


def main():
    if len(sys.argv) > 2:
        raise SystemExit(__doc__.split('\n\n')[1])
    image = sys.argv[1] if len(sys.argv) == 2 else os.path.join(TOP, IMAGE_REL)
    d = open(image, 'rb').read()
    secs = sections(d)

    def sec(name):
        if name not in secs or not secs[name][2]:
            raise SystemExit('%s: no section %s' % (image, name))
        va, sz, sp = secs[name]
        return d[sp:sp + sz]
    asm, attr = sec('instruction_assembly'), sec('instruction_attributes')
    mn, mnl = sec('instruction_mnemonic'), sec('instruction_mnemonic_length')
    ofs, ofl = sec('of_string'), sec('of_string_length')
    assert len(asm) >= 44 * N_OPCODES and len(attr) >= 20 * N_OPCODES

    def mnem(n):
        return mn[12 * n:12 * n + struct.unpack('>H', mnl[2 * n:2 * n + 2])[0]].decode('latin1')

    out = []
    p = out.append
    p('# ---- the decode tables ' + '-' * 51)
    p('# DOMAIN C 6.9\'s own opcode tables, from its PRISM back end cc.a88k (an')
    p('# m68k COFF image: domain-c\'s %s,' % IMAGE_REL)
    p('# %d bytes, sha256 %s...),' % (len(d), hashlib.sha256(d).hexdigest()[:16]))
    p('# these read-only sections (address, size in the image):')
    for name in SECTIONS:
        va, sz, sp = secs[name]
        p('#   %-28s 0x%06X  %5d bytes' % (name, va, sz))
    p('# printed by domain-c\'s tools/prism_tables_gen.py (it reads the image and')
    p('# prints this block, to the end of OF_STRING): regenerate, do not edit.')
    p('# Only what load_tables() reads: %d opcodes, %d forms, of a record the bytes'
      % (N_OPCODES, N_FORMS))
    p('# it parses (instruction_mnemonic and its lengths have 384 entries).')
    p('')
    p('# instruction_assembly, 44 bytes an opcode: +0 the register form\'s template,')
    p('# +4 the immediate form\'s; +8 0x20 squash, 0x10 five operands, 0x0F the')
    p('# -PRASM operator\'s length; +9 the name\'s length << 4 | half << 1; +10 the')
    p('# -PRASM layout; +11 the -PRASM operator; +19 the name; +36 the four')
    p('# operands\' halfwords (field kind << 3 | format << 1)')
    p('INSTRUCTION_ASSEMBLY = [')
    for n in range(N_OPCODES):
        a = asm[44 * n:44 * n + 44]
        w0, w4 = struct.unpack('>II', a[:8])
        prasm_len = a[8] & 15
        name_len = a[9] >> 4
        prasm_op = a[11:11 + prasm_len].decode('latin1')
        aname = a[19:19 + name_len].decode('latin1')
        opnd = struct.unpack('>HHHH', a[36:44])
        p('    (%s, %s, %s, %s, %d, %r, %r, (%s)),  # %d %s'
          % (h(w0, 8), h(w4, 8), h(a[8], 2), h(a[9], 2), a[10], prasm_op, aname,
             ', '.join(h(x, 4) for x in opnd), n, mnem(n)))
    p(']')
    p('')
    p('# instruction_attributes, 20 bytes an opcode: operands 1..4\'s forms (+4, +8,')
    p('# +12, +16) and their bytes 2 (+6, +10, +14, +18; +14 also the width and .CC')
    p('# flags); +7 the class; +11 (& 7 the operands shown); +19 (& 7 log2 of the')
    p('# access size)')
    p('INSTRUCTION_ATTRIBUTES = [')
    for n in range(N_OPCODES):
        t = attr[20 * n:20 * n + 20]
        p('    ((%s), (%s), %d, %s, %s),  # %d %s'
          % (', '.join('%d' % t[4 * k] for k in range(1, 5)),
             ', '.join(h(t[4 * k + 2], 2) for k in range(1, 5)),
             t[7], h(t[11], 2), h(t[19], 2), n, mnem(n)))
    p(']')
    p('')
    p('# instruction_mnemonic (with instruction_mnemonic_length): the classic')
    p('# listing\'s names, by opcode')
    p('INSTRUCTION_MNEMONIC = [')
    line = '   '
    for n in range(N_OPCODES):
        item = ' %r,' % mnem(n)
        if len(line) + len(item) > 79:
            p(line)
            line = '   '
        line += item
    p(line)
    p(']')
    p('')
    p('# of_string (with of_string_length): the operand forms\' names, by of$t')
    p('OF_STRING = [')
    for k in range(N_FORMS):
        s = ofs[34 * k:34 * k + struct.unpack('>H', ofl[2 * k:2 * k + 2])[0]].decode()
        p('    %r,  # %d' % (s, k))
    p(']  # end of OF_STRING')
    sys.stdout.write(''.join(x.rstrip() + '\n' for x in out))


if __name__ == '__main__':
    main()
