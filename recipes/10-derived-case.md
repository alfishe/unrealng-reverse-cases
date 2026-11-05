# 10. A derived case

**Answers:** how to reverse an alternative version, remake or conversion of a game that is already a case here,
and how to say what it changed.

Six cases are derived:

| Case | Base | Machine |
| --- | --- | --- |
| nether-earth-gs | nether-earth | Pentagon 128 + General Sound / NeoGS |
| nether-earth-zs-edition | nether-earth | Pentagon, Scorpion |
| advanced-nether-earth | nether-earth | Pentagon 128, TR-DOS |
| nether-earth-editor | nether-earth | 48K |
| zynaps-gs | zynaps | 128K + TR-DOS + General Sound |
| zynaps-128 | zynaps | Pentagon 128 |

## The owner's rules

| Rule | Means |
| --- | --- |
| **A full own reverse** | every part of the version (game, loaders, boot, menus, drivers, intro) has its own `.ann`, every routine is named and described as true for this game, the build is bit-exact, the resources are editable. **Never "the base's source plus ORG patches"**: ANE's stage 2 did that and was rejected ("some patcher"); its `work/stage3/BRIEF-SOURCE.md` redid it |
| **Docs 01-12 on their own** | each describes this game at the base case's depth, as if the base did not exist: no "same as the 48K", no "what it changed" sections. Text that compares goes to `work/docs/<id>-diff-notes.md` for doc 13 |
| **The one comparison inside 01-12** | `docs/img/compare/`: start-up and menu screenshots side by side with the base, made by a script |
| **Texts** | every text on the medium as a UTF-8 Markdown page in `docs/texts/` with a translation; the build input stays in `src/res/text/` |
| **Doc 13 last** | `docs/13-differences-from-<base>.md` is written only after the full reverse, from the diff of the two reverses |
| **The target machine only** | run the version only on the machines it was made for (a 128K version never on a 48K). The base's own recordings come from the base case |
| **Cases stay apart** | read the base case, never edit it or `kit/`. A tool taken from a sibling is copied with its origin named in its header |

## Steps

1. **Start as any case** (recipes 01-02). The README's `Machine` row names the target. Scan first:

   ```bash
   python3 ../../kit/sig_scan.py work/media/scl/files/neart001.C --base 6590 --all --out work/stage1/sig-neart001.json
   ```

   The base case's modules are in the signature base, so the scan shows what survived and where it moved.

2. **Match the base.** Find the base's routines in the version's images (stage 1):

   ```bash
   python3 tools/ne_match.py --image work/media/scl/files/neart001.C@6590:file --out work/stage1/match.tsv --summary
   python3 tools/byte_diff.py A.bin@6590 ../nether-earth/work/mkgame/original.bin@0000 --from 6590 --to D7D3 --gap 8
   ```

   `ne_match.py` (ANE, ZS) gives the status of each base entry: `same`, `moved`, `relocated`, `changed` or
   `absent`. This shows which release is the game (recipe 01, step 2) and seeds the annotations.

3. **Capture on the target machines** (recipe 02): `--model PENTAGON`, `--model SCORPION`, `--disk`, a GS card.
   Keep one recording per machine the version supports.

4. **Seed, then rewrite the `.ann`.**
   - Start from the base's `.ann`: drop the entries outside the version's image and the entries the version
     rewrote, merge entries that existed only because of where the base's recordings started, and re-attribute the
     evidence ("Nether Earth's deep recording").
   - Examples: nether-earth-gs `work/stage2/ann/seed_ann.py`, ANE `work/stage3/aneg/seed_ann.py`, zynaps-128
     `work/stage2/game128/mkann.py`.
   - Then **write again every entry the version touched**, and prove every name with this version's recordings.
   - The other parts get their own `.ann` and a part generator ([ann-format.md](../docs/ann-format.md#5-extensions-in-the-cases)):

   | Case | Parts | Generators |
   | --- | --- | --- |
   | nether-earth-gs | `src/game`, `src/trd/boot/{menu,print64}` | `tools/game_mkgame.py` (`# @bank`, `# @var`, `# @alias`), `tools/trd_mkasm.py` |
   | zynaps-128 | boot, intro, loader, depacker, sound (starkos, engine), game + stubs, glue, setup, mouse | `tools/part_mkasm.py` per part, all in `tools/mkasm_all.sh` |
   | zynaps-gs | `src/game` + `src/disk/{boot,screen,loader,menu,driver}` | `kit/mkgame.py` + `tools/part_mkasm.py --page N`, all in `tools/regen.sh` |
   | ZS | intro98, game98, menu99, game99, patches99, music99, stage2, stage3, pictures99 | `tools/<part>_mkgame.py` each (`# @over`, `# @piece`) |
   | ANE | game, bootmenu, disk ×4, endings ×4, intro ×4 | `game_mkgame.py`, `bootmenu_mkasm.py`, `disk_mkgame.py` / `endings_mkgame.py` (JSON part files), `intro_mkpart.py` |

   One source can serve two targets through `IFDEF`. For example, nether-earth-gs assembles `src/game/game.asm`
   plain and with `-DHOOD_TAPE`.

5. **Resources, figures and docs 01-12** follow recipes 06-08. The docs brief says: "as if the base case did not
   exist". Measure the gap against the base first (`wc -l docs/*.md`, `ls docs/img/*/*`): the base's line and
   figure counts are the bar.

6. **Texts.** For each text on the medium (BASIC, catalogue notes, readmes, scroller texts, menu strings):
   - The build input goes in `src/res/text/<name>.txt`, written in the case codec's text format (`#codec cp866`,
     pieces ending in `|`, `\xNN` for single bytes), and is encoded by the build:

     ```bash
     python3 tools/trd_text.py check src/res/text/trd-boot-menu.txt build/... OFFSET     # nether-earth-gs
     python3 tools/texts_build.py check --out build/texts                                # ZS: CP866, CR LF, the slack
     python3 tools/game_text.py IMAGE --from 83B0 --to 8516 --markdown                   # zynaps-128
     ```

   - The reader's page goes in `docs/texts/<name>.md`. It gives what the text is, its file and address, its
     encoding, a link to the build input, the original as UTF-8, and then an English translation (none is needed
     for an English text). `docs/texts/README.md` lists the pages.

7. **Comparison figures** in `docs/img/compare/`. They show real frames side by side, the version on the left, at
   2x with nearest neighbour, with the measured pixel or cell difference in the caption:

   ```bash
   python3 tools/fig_capture.py && python3 tools/fig_compare.py --shots work/stage2/shots --out docs/img/compare    # nether-earth-gs (zynaps-gs: shots copied into work/stage2/shots)
   python3 tools/compare_shots.py --work W --name c1 --out work/stage2/compare/shots 1990 2740 3460:12000         # zynaps-128: memory_at screens
   python3 tools/fig_compare.py --shots work/stage2/compare/shots --out docs/img/compare
   python3 tools/fig_compare.py --port-base 16530                                                                 # ZS: three panels, NE / '98 / '99
   ```

   The base's frames come from the base case's recordings (`../zynaps/work/explore`), never from running the
   version on the base's machine.

8. **Doc 13, after the full reverse.** Both cases must be built first, because the diff tools read the builds:
   `../<base>/tools/build.sh` and `tools/build.sh`.

   | Tool | Command | Compares |
   | --- | --- | --- |
   | `diff_ne.py` (nether-earth-gs) | `--summary`, `--runs [--gap N]`, `--show NAME...`, `--tape`, `--json work/diff/diff.json` | the version's and the base's images and listings, address by address: same / differ / ne-only / gs-only |
   | `diff_zy.py` (zynaps-gs, copied from diff_ne) | `--summary`, `--runs`, `--show`, `--installer --live work/zgsA/r1-play/start.bin` | the same, with the 48K image first put through Start's copy and complement |
   | `diff_48k.py` (zynaps-128) | `--summary` (a Markdown table doc 13 quotes), `--runs`, `--patches`, `--show` | same / changed / zeroed / 48k-only / 128-only |
   | `diff_game.py` (ANE; ZS three-sided: `--pair NE:Z98\|NE:Z99\|Z98:Z99`) | `--summary`, `--tsv work/diff/entries.tsv`, `--show NAME --context N` | entry by entry, with 16-bit label operands masked: same / operands / moved / changed / retargeted / only-in |
   | `diff_res.py` (ANE) | `--section sprites\|font\|level\|map\|strings\|orders\|tables`, `--all`, `buildmap --out work/diff/buildmap` | the resources |
   | `entry_diff.py` (ANE) | `--ane IMAGE64K NAME[@ADDR] ...` | one routine on both sides, disassembled and aligned |
   | `fig_diff_memmap.py`, `fig_diff_*.py` | `--map docs/img/diff/memmap-diff.png --runs ...` | the byte map of the classes, and per-subsystem figures in `docs/img/diff/` |

   Doc 13 opens with a "How compared" list naming each tool, then: "The figures are in `docs/img/diff/` and
   `docs/img/compare/`. Every command is run from this case's root." Each difference is stated with its witness
   (`diff_res.py --section strings`, `--show PlayLoop`). The document ends with a tools section and a figure table
   (`| file | section | command |`).

   Collect the agents' `<id>-diff-notes.md` and check each note against the diff. A difference that the base
   shares is not a difference: zynaps-gs's doc-13 draft took the level shuffle for the conversion's own, but the
   48K has the same shuffle.

9. **Signatures at the end.** Add a `sources.json` row per finished part (`mode: ann`), plus `lst` rows for the
   third-party pieces the case identified: the GS driver, the depacker, the player, the mouse driver. Then:

   ```bash
   python3 ../../kit/sig_add.py sources && python3 ../../kit/sig_index.py --check && python3 ../../kit/sig_index.py
   ```

   A module identical to the base's becomes one more `found_in` of the base's entry. zynaps-128 found 41 pieces
   already in the base.

**Done when:** every part rebuilds bit for bit from its own `.ann`; docs 01-12 describe the game on its own at the
base's depth; `docs/texts` and `docs/img/compare` are complete; doc 13 is written from the diff tools with every
command named; and the signature rows are added.
