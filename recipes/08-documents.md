# 08. Documents

**Answers:** the game's documentation, kept as its developers would keep it.

1. **Docs 01-10, one subsystem at a time.** Use the names that the analysis and the source give.
   - Each document opens with what it covers and the recordings it rests on.
   - Every number comes from a script. Every claim has an address and a witness.
   - Usually two agents write them: one takes 01-06 and the other 07-12 ([recipe 11](11-agents.md)).
   - The bar is a finished case. Read two or three of Nether Earth's or Zynaps' documents end to end before you
     write.

2. **Docs 11 and 12 are generated.**

   ```bash
   python3 ../../kit/mkgame.py --case . --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS   # writes work/mkgame/game.ctl
   python3 ../../kit/refdocs.py --case .                                             # docs/11-..., docs/12-...
   ```

   - `ref_builds` in `case.json` names the recordings that doc 12's runs and times come from. `overlay` and
     `data_note` are optional.
   - A case with several parts copies refdocs into its own `tools/` and extends it (`refdocs_zy.py`,
     `zsB_refdocs.py`, ANE's `fig_routines.py` / `fig_dataref.py`).
   - To fix a description, edit the `.ann` and regenerate. Never edit docs 11 and 12 by hand.

3. **`docs/README.md`** belongs to the lead and holds:
   - the index, with each document's state;
   - the recordings table: name, how loaded, frames, what it reached;
   - the glossary, which defines every term once so the documents can link it.

   The agents send their lines in `work/docs/<id>-index.md`.

4. **Formatting.**

   ```bash
   python3 ../../kit/code_addresses.py docs/NN-name.md        # hex addresses in prose into code spans
   python3 ../../kit/check_docs.py --case .                   # -> docs: ok
   ```

   `check_docs.py`:
   - renders every mermaid block (`mmdc`);
   - resolves links and images;
   - fails on `$` in prose;
   - fails on HTML entities in mermaid (write `#quot;`, not `&quot;`).

5. **The WALKTHROUGH** follows the work. It has:
   - a section per question, under the headings **Asked / Used / Instead, without it / Produced**;
   - the tool-gap table;
   - a section per review round;
   - for a large case, its cost (nether-earth: `tools/case_tokens.py` and `tools/case_cost.py`).

**Checklist**

- [ ] every frame number names its recording and how that recording was loaded
- [ ] a number is written the same everywhere it appears (grep for it)
- [ ] what no recording reached is said, with where the code shows it
- [ ] a pass and a frame are not confused (one pass can take two frames)
- [ ] `tools/build.sh` still gives an identical build after the `.ann` description fixes

**Done when:** `check_docs.py` prints `docs: ok` and every document's state in `docs/README.md` is "written".
