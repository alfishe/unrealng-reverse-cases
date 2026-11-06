# 05. The source

**Answers:** the game as a source that builds into the original bytes.

**Format:** every directive and kind of the annotation file is in [docs/ann-format.md](../docs/ann-format.md).

1. **Make the first cut with an empty annotation.** Make an L1 build in `work/<build>/l1.json` and fill in
   `case.json`. An `.ann` that holds only its header already assembles to the identical image (zynaps):

   ```bash
   python3 ../../kit/mkgame.py --case . --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS     # no --install yet
   ```

   It prints the code bytes, the number of instructions (and how many of them ran), the entries, and `assembled:
   identical to the original image`. Then read `work/mkgame/game.ctl` and `work/mkgame/*.asm`.

2. **Annotate.** Open entries for the analysis's routines and regions. For a large image, cut it into ranges with
   one annotator each:
   - each annotator writes `work/ann/NN-*.ann` with its xref and its notes;
   - each fragment is proved alone with `mkgame.py --ann FRAGMENT --out work/ann/mk-NN`;
   - the lead merges the fragments ([recipe 11](11-agents.md)).

   A derived case seeds its `.ann` from the base case ([recipe 10](10-derived-case.md)).

3. **Give every entry what it needs:**
   - a name;
   - a title;
   - a description: what it does, its inputs, its outputs, its side effects, and the evidence (recording and frame);
   - inner labels: `python3 ../../kit/ann_names.py --case . CF65=SetRestart ...`;
   - data shapes (`b Name 8`, `w`, `t`);
   - `@res` for each resource (recipe 06);
   - `@isub` for constants that look like addresses;
   - `@equ` for the work space past the image;
   - `@inline` for routines that print a string placed inline after the call.

   **Check every name with a run** (an experiment, a breakpoint hit count), not by reading alone. Stage-2 comments
   stayed wrong until a run checked them: the "tune frequency", the "life lost", the "engine hum"
   ([GUIDE](../GUIDE.md) 6).

4. **Install and build:**

   ```bash
   python3 ../../kit/mkgame.py --case . --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS --install
   tools/build.sh $SJASMPLUS                                        # -> build: identical to orig/GAME.TAP
   ```

   `--install` writes the modules `src/game/game.asm` includes; it deletes only the ones the `.ann` no longer has.
   `--venv` and `--sjasmplus` may be left out when `$SKOOLKIT_VENV` and `$SJASMPLUS` are set. Every other code
   image is a part, written by the same generator from a part file or one command line
   ([ann-format.md](../docs/ann-format.md#5-parts-banks-and-pieces)):

   ```bash
   python3 ../../kit/mkgame.py --part src/endings/deadend.json --install
   python3 ../../kit/mkgame.py --image work/parts/intro-6000.bin --org '$6000' --ann src/intro/intro.ann \
       --top block1 --dest src/intro --res src/res --l1 work/stage2/intro/l1.json --blocks \
       --page 5 --page 2 --save build/obj/block1.bin --install
   ```

   A case with many parts runs them all from one script: `tools/regen.sh` (zynaps-gs, ZS), `tools/mkasm_all.sh`
   (zynaps-128), `tools/mkmix.sh` (nether-earth-editor).

5. **Build one at a time.** `tools/build.sh` holds `build/.lock`, and each case has one builder. A 128K or disk
   build compares every part (`build/obj/*.bin` against `build/orig/parts/`), then the whole medium (`cmp`).

**Checklist**

- [ ] `grep -c 'l_[0-9A-F]\{4\}\|sub_[0-9A-F]\{4\}\|data_[0-9A-F]\{4\}' src/game/*.asm` gives 0
- [ ] every `c` entry has a description, and no bare address is left in prose where a name belongs
- [ ] the `.asm` in git is what the generator writes from the `.ann` in git (run it: `git status` shows no change)
- [ ] `tools/build.sh` from an empty `build/` gives an identical medium
- [ ] the WALKTHROUGH names the generator command and the entry and module counts

**Done when:** the medium rebuilds bit for bit from `src/`, no `l_XXXX` label or bare address is left where a name
belongs, and the generated `.asm` was never edited by hand.
