"""cc_dis - the source repository's coff_dis, which domain-c uses.

domain-c's cc_dis.py was merged into the source repository's
domain_os/tools/coff_dis.py (source commit 4ea26bed).  This shim loads that
module under the name cc_dis, both when imported by domain-c's tools and
when run as a script.  $SOURCE_TOOLS overrides the path.
"""
import importlib.util
import os
import sys

SOURCE_TOOLS = os.environ.get('SOURCE_TOOLS', os.path.expanduser(
    '~/src/domainos-archeology/source/domain_os/tools'))
if SOURCE_TOOLS not in sys.path:
    sys.path.insert(0, SOURCE_TOOLS)
_spec = importlib.util.spec_from_file_location(
    'coff_dis', os.path.join(SOURCE_TOOLS, 'coff_dis.py'))
_mod = importlib.util.module_from_spec(_spec)
sys.modules['coff_dis'] = _mod
_spec.loader.exec_module(_mod)
sys.modules['cc_dis'] = _mod

if __name__ == '__main__':
    _mod.main()
