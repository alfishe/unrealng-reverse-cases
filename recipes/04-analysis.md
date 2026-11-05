# 04. Analysis

**Answers:** what every byte of the game is (code, or data of which kind), and who reads and writes it.

**Read first:** unreal-ng's `docs/emulator/analysis/analysis-layers.md` (L0-L3 and the access trace) and
`.recipe/analysis/reverse-engineering.md`.

1. **Build the game's window**, and do the same over each bot recording:

   ```bash
   python3 $RS open --work work/stage2/c1 --ttd work/stage1/c1/session.ttd --model PENTAGON \
       --port-base <yours> --ranges 5B00-FFFF --binary $BIN
   python3 $RS build --work work/stage2/c1 --from-frame 2613 --from-tinframe 53257 --into work/game
   python3 $RS interrupts --work work/game
   python3 $RS stop --work work/stage2/c1
   ```

   - The window's `start.bin` must equal your depacker's output. In hate it did, byte for byte.
   - Start the window after the load, so that loaded code is not taken for data (editor: from frame 2700).
   - Put a build the kit should read in `work/<name>/l1.json`. Put one it must not read (another program at the
     same addresses) deeper: `work/stage2/<window>/` ([case-files.md](../docs/case-files.md#71-a-re_sessionpy-work-folder)).

2. **Work the review queue**: `python3 $RS call --work W review '{"op":"next"}'`. Take at most 40 items a page and
   use each item's fact sheet. Resolve items through `review resolve`; never edit the draft.

3. **Ask the recording** what the queue does not answer:

   | Question | Call |
   | --- | --- |
   | who wrote this byte | `time_travel find_last access=write addr=... from_frame=F before_frame=G` (write journal on) |
   | who ran this address in that bank | `time_travel find_last access=execute addr=... phys_page=2 all=true from_frame=F before_frame=F+1` |
   | what a frame did | `time_travel explain_frame` |
   | when an event happened | `find_event` (narrow windows) |
   | every port access | `time_travel port_events`, or the case's `fig_ports.py collect` |
   | where the player's variables are | `python3 ../../kit/input_vars.py --work work/play --inputs S --start F` |
   | one stretch, access by access | `analysis trace` (the kit's trace scripts run it for you, recipe 07) |

4. **Treat every unknown as a tool gap.** Read each unknown left outside the ROM against the replay. What is it?
   Why did no detector name it? Which generic rule would?
   - Put each rule into unreal-ng with a fixture and a test that fails without it: a worktree, the build, the
     filtered tests, land. The shared binary is then rebuilt once (recipe 11).
   - Build the case again.
   - Add a row to the WALKTHROUGH's tool-gap table: the gap, how it was seen, the fix with its test names, and the
     effect on the case.
   - List the gaps that were not fixed too. Example: L1 takes the return of a nested interrupt that does not come
     back to the interrupted call for a dispatch, which gave 28 false entries in Zynaps.

5. **Run the gates** after each round. `rebuild` and `assemble` must both give the image byte for byte:

   ```bash
   python3 $RS export --work W        # W/draft: draft.skool, .ctl, .map.txt, fields, findings register
   python3 $RS check --work W --venv $SKOOLKIT_VENV --sjasmplus $SJASMPLUS
   ```

**Done when:** no unknown outside the ROM is left unexplained, the gates pass, and the bugs that remain are
understood (code overlaid by a buffer is a finding, not an error).
