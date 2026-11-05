# Recipes

One recipe a phase of [the case standard](../GUIDE.md#5-process). Each says what it answers, the commands, and when
the phase is done. `$U` is the unreal-ng checkout (a worktree with a release build:
`$U/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt`), `$C` the case folder
(`unrealng-reverse-cases/<game>`), `$K` the kit (`unrealng-reverse-cases/kit`).

| Recipe | Phase |
| --- | --- |
| [01-start-a-case.md](01-start-a-case.md) | the folder, the original, the medium block by block |
| [02-capture.md](02-capture.md) | recordings: from power-on, the start image, the bot, coverage of the game |
| [03-stages-and-packers.md](03-stages-and-packers.md) | the stages and their windows, the packers proved both ways |
| [04-analysis.md](04-analysis.md) | L1 / L2 per stage, the review queue, unknowns, tool gaps |
| [05-source.md](05-source.md) | `game.ann`, `mkgame.py`, sjasmplus, the bit-for-bit build |
| [06-resources.md](06-resources.md) | resources out of the code, editable formats, checks against the recording |
| [07-figures.md](07-figures.md) | routine animations, code vs screen, beam timelines, heatmaps, data sheets |
| [08-documents.md](08-documents.md) | docs 01-12, the generated references, `check_docs.py` |
| [09-review.md](09-review.md) | independent review rounds and how to work their findings |
| [10-derived-case.md](10-derived-case.md) | a version, remake or conversion of a game already reversed: own reverse, docs on their own, texts, comparison figures, doc 13 from the diff |
| [11-agents.md](11-agents.md) | splitting a case across agents: stage and docs briefs, port bases, the editor pass, the shared binary, the build lock, commits |

Two references every recipe leans on: [the annotation file](../docs/ann-format.md) (every directive of a `.ann`,
what the generators do with it, common mistakes) and [the files of a case](../docs/case-files.md) (each file, the
command that makes it, its consumer, whether git keeps it, and the unreal-ng side).

The recipes write `$RS` for `$U/tools/verification/analysis/re_session.py`, `$BIN` for the shared unreal-qt
binary, and run case commands from the case folder (`../../kit/...`).

Emulator rules for every recipe (detail in unreal-ng's
[game-reverse-case recipe](https://github.com/alfishe/unreal-ng/blob/master/.recipe/articles/game-reverse-case.md)):
one instance per recording, muted, on its own port base; a saved recording (`.ttd`) is the evidence, opened again
for every question; reads go to `time_travel memory_at` at a frame and T-state, never to a running machine; stop
only the instances you started.
