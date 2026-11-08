# 09. Review

**Answers:** whether what the documents say is true.

1. **A review round** is done by an agent that has not seen the case's work.
   - Give it the documents, or a part of them, and the ground truth: `build/*.lst`, `src/`, `orig/` and the tools.
   - Ask for a numbered report. Each finding has the claim, the evidence and a fix, and is marked VERIFIED or
     SUSPECTED.
   - The round is read-only.

2. **Check every finding yourself before editing.** Check it against the listing, the medium's bytes or the
   recording. For the recording, open it and read memory at the frames in question (`time_travel memory_at`). A
   reviewer can be wrong: in H.A.T.E.'s fourth round, one of 31 findings was wrong.

3. **The editor pass** comes after the docs agents and before the review rounds. One agent does it, usually the
   lead ([recipe 11](11-agents.md)). The editor:
   - reads both halves;
   - settles each contradiction against the evidence (both sides may be true, as with "runs twice a pass" and
     "every other frame");
   - fixes comments in the `.ann` only (descriptions, never bytes), with a script kept in `work/lead/`;
   - writes `docs/README.md`;
   - repairs links.

4. **Fix and regenerate.** Make the fix in the annotation, the documents and the tools. Then run:

   ```bash
   python3 ../../kit/mkgame.py --case . --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS --install   # or the case's generator
   python3 ../../kit/refdocs.py --case .
   rm -rf build && tools/build.sh $SJASMPLUS                                                      # identical
   python3 ../../kit/check_docs.py --case .                                                       # docs: ok
   ```

5. **Add a WALKTHROUGH section per round.** It says what was asked, what was found (by kind: wrong number, wrong
   mechanism, missing evidence, stale name) and what changed.

6. **The WALKTHROUGH's Review section** states what was proved:
   - the byte-for-byte rebuild;
   - the "read, not run" counts (nether-earth: 702 of 4922 instructions);
   - what was reached only by a POKE;
   - what was not tested;
   - the claims that rest on the code alone.

**Completeness rounds** run next to the fact rounds ([AGENTS.md section 5](../AGENTS.md#5-quality-gates-before-done)): a fresh agent maps every routine of the `.ann` to the section that explains it, checks each mechanism against the bar (prose, pseudocode, asm, mermaid, worked example, witness, figure, the point) and against the reference cases, and writes P1/P2/P3 gaps to `work/review/cmp<id>.md`.

**Rounds:** at least two of each kind, the second on what the first did not read. After the last round, go through the figure
checklist again.

**Done when:** a fact round finds nothing factual, a completeness round finds no P1 or P2, and the case README's state says so.
