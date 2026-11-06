# <Case>: the editor pass

R = the repository, C = R/games/<case>. Both halves of the documents are in (C/work/docs/<id>-NOTES.md,
<id>-index.md, <id>-diff-notes.md). This pass is the lead's, or one editor agent's; it owns the shared files.

## Steps

1. **docs/README.md.** The index and each document's state, the recordings table, the glossary, merged from the
   `<id>-index.md` files. Model: R/games/<base>/docs/README.md.
2. **Contradictions.** Every place where the halves disagree is settled against the evidence (a recording frame, a
   counter, a run). Both may be true ("runs twice a pass" and "every other frame"): say how.
3. **Source comments the documents proved wrong**: fixed **in the `.ann` only** (descriptions, never bytes), with a
   script in C/work/lead/ beside a copy of the file as it was (`fix_ann.py` + `game.ann.before`). Then regenerate
   (`kit/mkgame.py --install`, the case's `tools/regen.sh`) and build: identical, and `git diff src/` shows only
   the comments. A fix to a base case that derived cases share is carried over to them.
4. **Docs 11 and 12** regenerated: `python3 R/kit/refdocs.py --case C`.
5. **Links and figures.** `python3 R/kit/check_docs.py --case C` prints "docs: ok" (links, `#anchors`, unlinked
   figures, `$` in prose, mermaid).
6. **Doc 13** in a derived case: [doc13.md](doc13.md).
7. **Review rounds**: R/recipes/09-review.md.

No pushes without the lead; commits only of the files this pass produced, never `work/` or `build/`.
