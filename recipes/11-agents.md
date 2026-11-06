# 11. Splitting a case across agents

**Answers:** how the lead runs a case with several agents at once without them breaking each other's work, and
what each one is given.

The lead owns the plan, the briefs, the shared files (`README.md`, `docs/README.md`, `case.json`, the merge of
`.ann` fragments), every commit and the push. The agents own only what their brief assigns them.

## 1. The stages and their briefs

Each brief is a file in the case's `work/`, which is git-ignored. Each agent gets its brief, plus a short prompt
with its id, its port base and its share of the work. The templates are in
[kit/case-template/briefs/](../kit/case-template/briefs/README.md), distilled from the briefs the nine cases ran
with: the lead copies one into `work/`, fills in every `<...>` and adds the case's facts.

| Stage | Brief (template) | Agents | Output |
| --- | --- | --- | --- |
| 1: the medium, the load, the images, a first play | [stage1.md](../kit/case-template/briefs/stage1.md) | 1 | `work/stage1/NOTES.md` (commands and what each proved), images, the memory map, the match against the base |
| 2: the source, bit-exact | [stage2.md](../kit/case-template/briefs/stage2.md); for parallel parts, [stage2-parts.md](../kit/case-template/briefs/stage2-parts.md) (a table of part, folders, bytes and owner; `STATE-<part>.md` per part) | 1, or 1 per part | `.ann` + generated `.asm`, part files, `tools/build_<part>.sh`, `build.sh` identical |
| 2 (one big image): annotation fragments | [ann-fragments.md](../kit/case-template/briefs/ann-fragments.md) (later waves: the same with the open entries) | 5-6, one per address range | `work/ann/NN-*.ann`, `NN-xref.txt`, `NN-notes.md` |
| figures | [figures.md](../kit/case-template/briefs/figures.md) (the figure rule every docs brief cites) | | |
| docs 01-12 | [docs.md](../kit/case-template/briefs/docs.md) | 2 | the documents, `work/docs/<id>-index.md`, `<id>-NOTES.md`, `<id>-diff-notes.md` |
| editor pass | [editor.md](../kit/case-template/briefs/editor.md) | the lead, or 1 | `docs/README.md`, `.ann` comment fixes |
| doc 13 (a derived case) | [doc13.md](../kit/case-template/briefs/doc13.md) | the lead, or 1 | `docs/13-differences-from-<base>.md`, `docs/img/diff/` |

## 2. The docs agents

Two agents per case:

| Agent | Docs | Port bases used |
| --- | --- | --- |
| A | 01-06 | zyA 14500-14599, z128A 16200-16299, zgsA 16600-16699, gsA 15600-15699, zsA 15200 / 15220 |
| B | 07-12 (11 and 12 generated) | zyB 14700-14799, z128B 16400-16499, zgsB 16850-16880, gsB 15800-15899, zsB 15410-15440 |

ANE had four (docS 02/03/11, docL 07/10/12, docP 01/05/08, docR 04/06/09, on bases 13510, 14710, 12910 and
14110). The later cases all used two.

Each agent writes:
- `work/docs/<id>-NOTES.md`: every command it ran and what each proved;
- `work/docs/<id>-index.md`: its index lines and glossary terms, for the lead to merge into `docs/README.md`;
- in a derived case, `work/docs/<id>-diff-notes.md`: the comparison text kept out of 01-12, for doc 13.

## 3. The editor pass

When both halves are in, the lead (or one editor agent) does the following:

1. Writes `docs/README.md`: the index and each document's state, the recordings table, and the glossary, merged
   from the `<id>-index.md` files.
2. Settles every contradiction between the halves against the evidence. Both may be true: z128A's "runs twice a
   pass" and z128B's "every other frame".
3. Fixes source comments that the docs proved wrong, **in the `.ann` only** (descriptions, never bytes), with a
   script kept in `work/lead/` next to the file as it was (`fix_ann.py` + `game.ann.before`). Then it regenerates
   (`kit/mkgame.py --install`, `tools/regen.sh`, `tools/mkasm_all.sh`) and builds, which must be identical. A fix
   to a base case that the derived cases share (Zynaps 48K, `b92fa86`) is carried over to them.
4. Repairs links, runs `check_docs.py`, and writes doc 13 in a derived case ([recipe 10](10-derived-case.md)).
5. Starts the review rounds ([recipe 09](09-review.md)).

## 4. Shared resources

| Resource | Rule |
| --- | --- |
| **unreal-ng binary** | one release build shared by all agents and used read-only (`$UNREAL_NG/cmake-build-agent-release/...`, a worktree such as `scratch/wt-nezs-stage1`); no agent builds unreal-ng or makes a worktree for itself, which matters most when the disk is short. A tool gap is fixed by one agent in one worktree, landed, and the shared binary is rebuilt once |
| **Port bases** | one per agent, 100 or more apart, written in its prompt; the brief lists the ranges other agents hold. Ports run from the base: WebAPI = base, CLI +100, MCP +200, GDB +300, DeZog +400, ZRCP +500. Never take port 10000 or a pid that is not yours |
| **Instances** | muted (audio only to files), offscreen, one per recording; each agent **stops only the instances it started** (`re_session.py stop --work W` checks the pid) |
| **The build** | `tools/build.sh` holds `build/.lock`, and **one builder per case**. A docs agent runs the build only to check it stays identical. Two parts building at once use separate locks (`build/.lock-trd`) |
| **Files** | each agent edits only its assigned docs, its own `tools/` scripts, and its own `work/<id>/` folder; never another part's files, the base case, or `kit/` (copy a script into the case's `tools/` instead) |
| **Notes** | every finding goes into the agent's NOTES with its command; the lead moves it into the WALKTHROUGH. A finding that stays only in a chat does not count |

## 5. A brief's skeleton

```markdown
# <Case>: <stage>

R = <repo>, C = R/games/<case>, B = R/games/<base> (the reference case).

## Why
What is missing, measured (lines, figures, entries named), against the bar (the base case's numbers).

## The standard
R/GUIDE.md sections; the recipes; BRIEF-FIG for figures; the owner's rules for this case (full own reverse;
docs on their own; the target machines). Evidence: every statement an address and a witness.

## Inputs
C/README.md, C/WALKTHROUGH.md, C/src (the .ann are the ground truth), C/work/stage*/ notes and recordings.
Read-only: B, R/kit, other cases.

## Rules
- Own emulator instances on your port base (your prompt), muted, stopped when done; never pids/ports not yours
  (other agents use <ranges>). unreal-ng: the existing build <path> (read-only); never build it or make a worktree.
- Only your assigned files. Shared files (docs/README.md, C/README.md) belong to the lead: put your lines in
  C/work/docs/<id>-index.md.
- `python3 R/kit/check_docs.py --case C` prints "docs: ok"; `tools/build.sh` stays identical.
- English documents, hex in code spans. Leave C/work/<...>/<id>-NOTES.md (commands and what each proved).
- No commits. Report: per item done, the evidence, what is known only from the code.
```

## 6. Commit and push

Only the lead commits, after each finished stage:

1. Run `python3 kit/check_docs.py --case games/<case>`, which must print `docs: ok`.
2. Run `games/<case>/tools/build.sh` from an empty `build/`, which must print `identical`.
3. `git add` only the files this stage produced, never `work/` or `build/` (both ignored) or another session's
   files.
4. Commit, naming the case and the stage: `Zynaps 128K: documents 01-12 at full depth`.
5. `git push github master`.
