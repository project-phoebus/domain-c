"""coff_compare - the source repository's tool, which domain-c uses.

domain-c's patched copy (the .blocks version 4 reader, unnamed C scope
blocks, units by tree path) was merged into the source repository's
domain_os/tools/coff_compare.py (source commit 4ea26bed, with .blocks
version 3 added there).  This shim loads that module under the name
coff_compare, both when imported by domain-c's tools and when run as a
script, so the tree's tools keep their `import coff_compare' and
`python3 tools/coff_compare.py'.  $SOURCE_TOOLS overrides the path.
"""
import importlib.util
import os
import sys

SOURCE_TOOLS = os.environ.get('SOURCE_TOOLS', os.path.expanduser(
    '~/src/domainos-archeology/source/domain_os/tools'))
if SOURCE_TOOLS not in sys.path:
    sys.path.insert(0, SOURCE_TOOLS)
_spec = importlib.util.spec_from_file_location(
    'coff_compare', os.path.join(SOURCE_TOOLS, 'coff_compare.py'))
_mod = importlib.util.module_from_spec(_spec)
sys.modules['coff_compare'] = _mod
_spec.loader.exec_module(_mod)

if __name__ == '__main__':
    _mod.main()
