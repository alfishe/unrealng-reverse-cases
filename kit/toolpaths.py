#!/usr/bin/env python3
"""Find the outside tools the kit and the cases run: sjasmplus, a SkoolKit virtualenv, an unreal-ng checkout.

    python3 kit/toolpaths.py sjasmplus|venv|unreal|binary|re_session [HINT]   # prints the path, or fails with what
                                                                              # it tried

From Python: toolpaths.sjasmplus(hint), toolpaths.skoolkit_venv(hint), toolpaths.unreal_ng(hint),
toolpaths.unreal_binary(hint), toolpaths.re_session(hint) (the checkout's tools/verification/analysis/re_session.py,
which kit/rs.py runs). Each takes the first that exists of:

| Tool | Order |
| --- | --- |
| sjasmplus | the hint (--sjasmplus), $SJASMPLUS, `sjasmplus` on PATH, a checkout `sjasmplus/build/release/sjasmplus` (or `sjasmplus/sjasmplus`) up to two folders below any of the three folders above this repository |
| SkoolKit venv | the hint (--venv), $SKOOLKIT_VENV, $VIRTUAL_ENV, the running Python's own prefix when it has SkoolKit, `.venv` / `venv-skoolkit` in this repository, the folder above `sna2skool.py` on PATH, `scratch/venv-skoolkit` of an unreal-ng checkout (found as below) |
| unreal-ng | the hint (--unreal), $UNREAL_NG, the `unreal-ng` submodule of this repository (when checked out), an `unreal-ng` checkout up to two folders below any of the three folders above this repository |
| unreal-qt binary | the hint (--binary), $UNREAL_BINARY, `cmake-build-agent-release/bin/unreal-qt` (the macOS app's or the plain one) of the unreal-ng checkout found as above |

A venv is a folder with bin/sna2skool.py; an unreal-ng checkout one with tools/verification/analysis/re_session.py.
No path of one machine is written in the kit or the cases: set the variables once (docs/case-files.md 10).
"""
import glob
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)


def _above():
    """the three folders above the repository, nearest first"""
    out, d = [], REPO
    for _ in range(3):
        d = os.path.dirname(d)
        out.append(d)
    return out


def _below(name, suffixes):
    """name/<suffix> up to two folders below each folder above the repository"""
    for top in _above():
        for depth in ('', '*', os.path.join('*', '*')):
            for suffix in suffixes:
                for hit in sorted(glob.glob(os.path.join(top, depth, name, suffix))):
                    yield hit


def _is_exe(path):
    return path and os.path.isfile(path) and os.access(path, os.X_OK)


def sjasmplus(hint=None, required=True):
    tried = []
    for c in (hint, os.environ.get('SJASMPLUS'), shutil.which('sjasmplus')):
        if c:
            tried.append(c)
            found = c if os.sep in c else shutil.which(c)
            if _is_exe(found):
                return os.path.abspath(found)
    for c in _below('sjasmplus', [os.path.join('build', 'release', 'sjasmplus'), 'sjasmplus']):
        if _is_exe(c):
            return os.path.abspath(c)
    if required:
        raise SystemExit('sjasmplus not found (tried %s, PATH and checkouts near this repository): pass --sjasmplus '
                         'or set SJASMPLUS' % (', '.join(tried) or 'no hint'))
    return None


def _is_venv(path):
    return path and os.path.isfile(os.path.join(path, 'bin', 'sna2skool.py'))


def skoolkit_venv(hint=None, required=True):
    candidates = [hint, os.environ.get('SKOOLKIT_VENV'), os.environ.get('VIRTUAL_ENV'), sys.prefix,
                  os.path.join(REPO, '.venv'), os.path.join(REPO, 'venv-skoolkit')]
    on_path = shutil.which('sna2skool.py')
    if on_path:
        candidates.append(os.path.dirname(os.path.dirname(on_path)))
    for c in candidates:
        if _is_venv(c):
            return os.path.abspath(c)
    for unreal in [os.environ.get('UNREAL_NG'), os.path.join(REPO, 'unreal-ng')] + list(_below('unreal-ng', [''])):
        if unreal and _is_venv(os.path.join(unreal, 'scratch', 'venv-skoolkit')):
            return os.path.abspath(os.path.join(unreal, 'scratch', 'venv-skoolkit'))
    if required:
        raise SystemExit('no SkoolKit virtualenv found (a folder with bin/sna2skool.py): pass --venv or set '
                         'SKOOLKIT_VENV')
    return None


def _is_unreal(path):
    return path and os.path.isfile(os.path.join(path, 'tools', 'verification', 'analysis', 're_session.py'))


def unreal_ng(hint=None, required=True):
    for c in (hint, os.environ.get('UNREAL_NG'), os.path.join(REPO, 'unreal-ng')):
        if _is_unreal(c):
            return os.path.abspath(c)
    for c in _below('unreal-ng', ['']):
        if _is_unreal(c):
            return os.path.abspath(c)
    if required:
        raise SystemExit('unreal-ng checkout not found: pass --unreal or set UNREAL_NG')
    return None


def re_session(hint=None, required=True):
    """unreal-ng's tools/verification/analysis/re_session.py in the checkout found as unreal_ng finds it"""
    unreal = unreal_ng(hint, required)
    return os.path.join(unreal, 'tools', 'verification', 'analysis', 're_session.py') if unreal else None


def unreal_binary(hint=None, required=True):
    if hint or os.environ.get('UNREAL_BINARY'):
        c = hint or os.environ['UNREAL_BINARY']
        if _is_exe(c):
            return os.path.abspath(c)
        if required:
            raise SystemExit('unreal-qt binary %s is not an executable' % c)
        return None
    unreal = unreal_ng(required=required)
    if unreal:
        build = os.path.join(unreal, 'cmake-build-agent-release', 'bin')
        for c in (os.path.join(build, 'unreal-qt.app', 'Contents', 'MacOS', 'unreal-qt'),
                  os.path.join(build, 'unreal-qt'), os.path.join(build, 'unreal-qt.exe')):
            if _is_exe(c):
                return c
    if required:
        raise SystemExit('unreal-qt binary not found: pass --binary, set UNREAL_BINARY, or set UNREAL_NG to a checkout '
                         'built with tools/build/build.sh unreal-qt')
    return None


def skoolkit_python(venv):
    """the venv's Python (the one that runs sna2skool.py / skool2asm.py)"""
    for name in ('python', 'python3'):
        path = os.path.join(venv, 'bin', name)
        if os.path.exists(path):
            return path
    return sys.executable


def main():
    if len(sys.argv) not in (2, 3) or sys.argv[1] not in ('sjasmplus', 'venv', 'unreal', 'binary', 're_session'):
        sys.exit(__doc__)
    hint = sys.argv[2] if len(sys.argv) == 3 and sys.argv[2] else None
    print({'sjasmplus': sjasmplus, 'venv': skoolkit_venv, 'unreal': unreal_ng,
           'binary': unreal_binary, 're_session': re_session}[sys.argv[1]](hint))


if __name__ == '__main__':
    main()
