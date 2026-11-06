# <Case>: the documents 01-12 at <base>'s standard

R = the repository, C = R/games/<case>, B = R/games/<base> (the reference case).

## Why

The source is complete and bit-exact (stage 2); the documents are stage drafts. Measured now: B <N> docs, <lines>
lines, <figures> figures; this case: `wc -l C/docs/*.md`, `find C/docs/img -type f | wc -l`. The owner judges a case
by its documents and figures against the finished sibling: read two or three of B's end to end before writing and
match their depth, tone, figure density and evidence.

## The standard

- R/GUIDE.md sections 2-4: the fixed numbering 01-12 (01 game design, 02 architecture, 03 build and load, 04 game
  loop, 05 controls, 06 rendering, 07 objects, 08 HUD and text, 09 sound, 10 gameplay logic, 11 data reference,
  12 routine reference), the writing rules, the figure kinds and their density.
- The figure rule: [figures.md](figures.md).
- A derived case is its own game, reversed in full on its own: each document describes it completely, at B's depth,
  as if B did not exist. No "same as <base>", no "what it changed" sections; text that compares goes to
  C/work/docs/<id>-diff-notes.md for doc 13. Keep `docs/img/compare` and `docs/texts` (the one allowed comparison).
- Runs on <machine> (and <other machines> where a document speaks of them).
- Figures are rendered from recordings by case scripts in C/tools/ (copy from R/kit or B and adapt, never edit
  them). Images in C/docs/img/<topic>/.
- 11 and 12 are generated: `python3 R/kit/refdocs.py --case C` (after `kit/mkgame.py`), never hand-written.
- Evidence: every statement an address and a witness (recording + frame, counter, experiment). What no recording
  reached is said so.

## Inputs

C/README.md, C/WALKTHROUGH.md, the current C/docs (facts and figures to keep and extend), C/src (every `.ann`: the
names and descriptions are the ground truth), C/src/res, C/tools, C/work/stage* notes and recordings. Do not edit
C/src or C/tools files you did not create; never B, R/kit or other cases.

## Rules

- Own emulator instances on your port base (your prompt), muted, stopped when done; never pids or ports not yours
  (other agents use <ranges>). unreal-ng: the shared build `$UNREAL_NG/cmake-build-agent-release` (read-only);
  never build unreal-ng or make a worktree.
- Only the documents assigned to you. Shared files (docs/README.md, C/README.md) belong to the lead: put your index
  lines and glossary terms into C/work/docs/<id>-index.md.
- `python3 R/kit/check_docs.py --case C` prints "docs: ok"; `tools/build.sh` stays identical.
- English, hex in code spans, one idea per sentence, lists over long paragraphs.
- Code snippets (the owner on a block mixing instructions, `DEC SP / DEC SP / POP BC` and ad hoc `HL += DE`:
  "not very readable"):
  - real code is the real listing as `src/` has it, one instruction a line, a short comment column, in an `asm` block,
    cut to the lines that make the point (`; ...` marks a cut);
  - the algorithm is a separate pseudocode block next to it, with named variables and real loops, no registers unless
    the register is the point;
  - constants are explained in the prose before the block, not in long trailing comments;
  - a transform (decryptor, checksum, packer) gets a worked example: real input bytes, the key, the output.
- Leave C/work/docs/<id>-NOTES.md (commands and what each proved). No commits.

## Report

Per document: sections, figures (each with its point), what is known only from the code.
