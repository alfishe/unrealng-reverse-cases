#!/usr/bin/env python3
"""Find the outside tools the kit and the cases run: sjasmplus, a SkoolKit virtualenv, an unreal-ng checkout.

    python3 kit/toolpaths.py sjasmplus|venv|unreal|binary|re_session [HINT]   # prints the path, or fails with what
                                                                              # it tried
    python3 kit/toolpaths.py build [BINARY]     # the unreal-ng commit a binary holds, and the fixes it lacks

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

`build` (toolpaths.binary_build, binary_fixes; kit/rs.py open / capture warn the same way): the commit an unreal-qt
binary was built from, read from its build folder (the folder above it with CMakeCache.txt: generated/emulator/
buildinfo.h, kGitCommit and kGitBranch, and the source checkout CMAKE_HOME_DIRECTORY), else from the binary's own
bytes (the version, branch and commit strings the About box shows). Then, for each unreal-ng fix a recipe names
(FIXES below), whether that commit holds it (git merge-base --is-ancestor in the source checkout, or the unreal-ng
checkout found as above): "has", "LACKS" (with what fails without it) or "unknown" (no checkout knows the commit).
buildinfo.h is written when CMake configures, so a binary built later from a newer HEAD of the same worktree may
hold more than it says: when the worktree's HEAD differs and the binary is newer than HEAD's commit, the HEAD is
checked too and printed beside it. Exit status 0, or 2 when a fix is lacking.
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


# The unreal-ng fixes a recipe names: a case binary without one fails as told (python3 kit/toolpaths.py build)
FIXES = [
    ('f13cee7da', 'recipes/02-capture.md', 'an ended tape holds the level of its last edge: without it a TZX whose '
     'last data block ends the file with no pause does not load (Deflektor, Enduro Racer: the machine resets at the '
     'tape\'s end); load a dump with a pause at the end, or use a later binary'),
]


def _git(source, *args):
    import subprocess
    try:
        return subprocess.run(['git', '-C', source] + list(args), capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None


def binary_build(binary):
    """{"binary", "commit", "branch", "source", "how", "head", "head_time", "binary_time"} of an unreal-qt binary:
    its build folder's generated/emulator/buildinfo.h (configure time) or the strings in the binary; "commit" None
    when neither says"""
    import re
    out = {'binary': binary, 'commit': None, 'branch': None, 'source': None, 'how': None, 'head': None,
           'head_time': None, 'binary_time': os.path.getmtime(binary) if os.path.exists(binary) else None}
    d = os.path.dirname(os.path.abspath(binary))
    while d and d != os.path.dirname(d):
        cache = os.path.join(d, 'CMakeCache.txt')
        if os.path.isfile(cache):
            for line in open(cache, errors='replace'):
                if line.startswith('CMAKE_HOME_DIRECTORY:'):
                    out['source'] = line.split('=', 1)[1].strip()
            info = os.path.join(d, 'generated', 'emulator', 'buildinfo.h')
            if os.path.isfile(info):
                text = open(info, errors='replace').read()
                for key, name in (('commit', 'kGitCommit'), ('branch', 'kGitBranch')):
                    m = re.search(name + r'\s*=\s*"([^"]*)"', text)
                    if m and m.group(1) != 'unknown':
                        out[key] = m.group(1)
                if out['commit']:
                    out['how'] = info
            break
        d = os.path.dirname(d)
    if not out['commit'] and os.path.isfile(binary):
        # the About box's strings: version, branch, commit, one after another
        m = re.search(rb'\x00\d+\.\d+\.\d+\x00([\w./+-]{1,80})\x00([0-9a-f]{7,40})\x00', open(binary, 'rb').read())
        if m:
            out['branch'], out['commit'], out['how'] = m.group(1).decode(), m.group(2).decode(), 'the binary\'s strings'
    if out['source']:
        r = _git(out['source'], 'log', '-1', '--format=%h %ct')
        if r is not None and r.returncode == 0 and r.stdout.strip():
            head, stamp = r.stdout.split()
            out['head'], out['head_time'] = head, int(stamp)
    return out


def _holds(sources, fix, commit):
    """True / False / None (no checkout knows both commits)"""
    for source in sources:
        if not source or not os.path.isdir(source):
            continue
        r = _git(source, 'merge-base', '--is-ancestor', fix, commit)
        if r is not None and r.returncode in (0, 1):
            return r.returncode == 0
    return None


def binary_fixes(binary, build=None):
    """[(fix, recipe, what, status)] for FIXES: status "has", "LACKS" or "unknown" (with ", HEAD has it" when only
    the newer worktree HEAD holds it, see binary_build)"""
    build = build or binary_build(binary)
    sources = [build['source'], unreal_ng(required=False)]
    rows = []
    for fix, recipe, what in FIXES:
        status = 'unknown'
        if build['commit']:
            held = _holds(sources, fix, build['commit'])
            status = {True: 'has', False: 'LACKS', None: 'unknown'}[held]
            newer = build['head'] and not build['head'].startswith(build['commit'][:7]) and \
                build['binary_time'] and build['head_time'] and build['binary_time'] > build['head_time']
            if held is False and newer and _holds(sources, fix, build['head']):
                status = 'LACKS by buildinfo, HEAD %s has it (the binary is newer than HEAD: perhaps built from it)' % \
                    build['head']
        rows.append((fix, recipe, what, status))
    return rows


def warn_binary(binary, who='kit', out=None):
    """one line for each fix a recipe names that the binary lacks (printed to stderr); returns them"""
    lacking = [row for row in binary_fixes(binary) if row[3].startswith('LACKS')]
    for fix, recipe, what, status in lacking:
        print(f'{who}: WARNING: {binary} {status} unreal-ng {fix} ({recipe}): {what}', file=out or sys.stderr,
              flush=True)
    return lacking


def build_report(hint=None):
    binary = unreal_binary(hint)
    b = binary_build(binary)
    print(f'binary  {binary}')
    print(f'commit  {b["commit"] or "unknown"}' + (f' ({b["branch"]})' if b['branch'] else '') +
          (f', from {b["how"]}' if b['how'] else ''))
    if b['source']:
        print(f'source  {b["source"]}' + (f', HEAD {b["head"]}' if b['head'] else ''))
    status = 0
    for fix, recipe, what, state in binary_fixes(binary, b):
        print(f'{fix}  {state}  ({recipe}){": " + what if state.startswith("LACKS") else ""}')
        status = 2 if state.startswith('LACKS') else status
    return status


def skoolkit_python(venv):
    """the venv's Python (the one that runs sna2skool.py / skool2asm.py)"""
    for name in ('python', 'python3'):
        path = os.path.join(venv, 'bin', name)
        if os.path.exists(path):
            return path
    return sys.executable


def main():
    if len(sys.argv) not in (2, 3) or sys.argv[1] not in ('sjasmplus', 'venv', 'unreal', 'binary', 're_session',
                                                          'build'):
        sys.exit(__doc__)
    hint = sys.argv[2] if len(sys.argv) == 3 and sys.argv[2] else None
    if sys.argv[1] == 'build':
        sys.exit(build_report(hint))
    print({'sjasmplus': sjasmplus, 'venv': skoolkit_venv, 'unreal': unreal_ng,
           'binary': unreal_binary, 're_session': re_session}[sys.argv[1]](hint))


if __name__ == '__main__':
    main()
