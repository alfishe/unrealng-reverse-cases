# <Case>: stage 1 brief (the medium, the load, the images)

R = the repository, C = R/games/<case> (this case), B = R/games/<base> (the finished reference case, if this is a
version of it). Standard: R/GUIDE.md, R/recipes/ (01-04), R/kit/README.md, unreal-ng's
`.recipe/articles/game-reverse-case.md` (`$UNREAL_NG`).

## The medium

C/orig/<file> (sha1 ..., sha256 ...): what it holds (files / blocks, sizes, the label). Other copies in the
collections and earlier releases, each with its hash and where it lies; extract them into C/work/ for comparison,
never into orig/. ZXDB entry, publisher, year, language, the machine it says it needs.

## Stage 1 (you)

1. **Machine.** Which model it needs (what boots and what plays). Record from power-on through the load into play
   (R/recipes/02-record.md; own instance on your port base, muted, stopped when done).
2. **The stages.** The BASIC, the loaders, the packers (identify each: a known packer, its version), what is unpacked
   where, which 128K pages are used. Writes and runs from the recording (`re_session.py stages`, the access trace),
   not guesses. Draft C/docs/03-build-and-load.md.
3. **The images.** Dump each final memory image (every page in use) into C/work/images/ and draw the memory map
   (draft C/docs/02-architecture.md).
4. **Known pieces.** `python3 R/kit/sig_scan.py IMAGE --base ADDR` on every image; list each hit and what it
   names.
5. **Shared with the base** (a derived case). A case tool C/tools/<base>_match.py that finds B's routines and data
   in the images (B's bytes with the entry extents of B's `.ann`, absolute operands masked so a moved routine still
   matches): per entry same at X / moved / changed (similarity) / absent; also sprites, font, map, tunes. The table
   C/work/stage1/match.tsv and a summary in C/docs/02.
6. **Play it.** Screenshots of every screen reachable without much skill (menus, play, the texts); what a player
   sees.

## Rules

- Own emulator instances on your port base (your prompt), muted, stopped when done; never a pid or port you did not
  start (other agents use <ranges>). unreal-ng: the shared build `$UNREAL_NG/cmake-build-agent-release` (read-only);
  never build unreal-ng or make a worktree.
- Never edit B, R/kit or other cases. Case tools in C/tools/, temp files in C/work/stage1/.
- Every claim with a witness (an address and a recording frame, a counter, a run).
- English in files, hex in code spans in Markdown. No commits.

## Output

C/work/stage1/NOTES.md (every command and what it proved), C/work/images/, the drafts of docs 02 and 03, the match
table. Report: the machine, the stages, the images, the known pieces, what is open.
