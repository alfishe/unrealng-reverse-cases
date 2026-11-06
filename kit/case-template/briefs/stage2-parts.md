# <Case>: stage 2, shared brief for the part agents

R = the repository, C = R/games/<case>, B = R/games/<base>. Read C/work/stage1/NOTES.md, C/docs/02 and 03 first.
Everything in [stage2.md](stage2.md) (the standard, the recordings, the rules) holds; this brief adds the split.

## Tools already in the case

- `python3 C/tools/<media>.py` writes C/work/media/: every block as read and every packed block's output, with
  its address and page (list them here).
- The packers both ways (`tools/<packer>.py check`). The packed blocks' set-up and depacker belong to the lead
  (`src/sfx/`): a part delivers the UNPACKED bytes.

## Layout and ownership

Each part agent owns only its folders and files. It writes `tools/build_<part>.sh`, which writes
`C/build/<part>/*.bin` bit-exact against the bytes the part stands for (from C/work/media, never from a recording),
and its part file `src/<part>/<name>.json` for `R/kit/mkgame.py --part`. It appends its state to
`C/work/stage2/STATE-<part>.md`: what is done, the labels other parts may rely on (stable once written there), the
open points. Tools it adds are `tools/<part>_*.py`. Never edit another part's files. Temp files in
C/work/stage2/<part>/.

| Part | Agent's folders | Bytes it builds |
| --- | --- | --- |
| <part> | `src/<part>/`, `src/res/<part>/` | <block, range, page> |
| texts | `src/res/text/`, `docs/texts/`, `docs/img/` screenshots | the text files, as on disk |
| lead | `case.json`, `src/sfx/`, `src/disk*.txt`, `tools/build.sh`, the medium writer, README, WALKTHROUGH | the medium |

The lead calls each `build_<part>.sh` from `tools/build.sh` once its agent reports it bit-exact, and removes the raw
block it replaces.
