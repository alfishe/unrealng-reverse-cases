#!/usr/bin/env python3
"""Check input scripts (mm_session.py's format, kitlib.input_script) before a capture: every word a key, and an
"N END" line (a script without one ends at its last event silently: the recording stops there, or the next script
starts there).

    python3 kit/input_lint.py [--allow WORD,...] SCRIPT ...

--allow names the first words of a case wrapper's own lines, skipped (Rex's tools/capture.py: --allow TAPE,POKE).
Prints each problem and warning; exits 1 when there is any. kit/rs.py capture runs the same checks on its --inputs
(a word that is no key stops it, a missing END is a warning); a case's own capture wrapper runs this first.
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kitlib  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('scripts', nargs='+')
    ap.add_argument('--allow', default='', help='first words of the wrapper\'s own lines (TAPE,POKE)')
    a = ap.parse_args()
    allow = [w for w in a.allow.split(',') if w]
    found = 0
    for path in a.scripts:
        lines, problems = kitlib.input_script(path, allow)
        warning = kitlib.missing_end(path, lines)
        for text in problems + ([warning] if warning else []):
            print(text)
            found += 1
    print(f'{len(a.scripts)} scripts, {found} problems')
    return 1 if found else 0


if __name__ == '__main__':
    sys.exit(main())
