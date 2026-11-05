# 03. Stages and packers

**Answers:** what each stage on the medium does, where its code arrives, and how the packed data was made.

1. **List the stages.** Build L1 over the whole power-on recording, then list the code arrivals:

   ```bash
   python3 $RS stages --work work/c1          # a loader in a REM, a screen unpacker, a depacker, the game
   python3 $RS interrupts --work work/c1      # interrupt $FDFD -> $8340: 27645 entries ... (hate)
   ```

   Each arrival comes with the window to build it in (`--to-frame` is the next arrival's frame + 1). `stages` also
   lists an IM 2 handler swap as a stage (nether-earth); drop those.

2. **Build each stage in its own window.**

   ```bash
   python3 $RS build --work work/c1 --stage N --into work/c1/<stage>
   python3 $RS build --work work/stage2/c1 --from-frame 2182 --from-tinframe 53027 --to-frame 2838 \
       --into work/stage2/intro                                                       # zynaps-128
   ```

   An unpacker can read its input from the addresses the game later runs from. In such a window the data reads say
   nothing about the game, so take the game's data reads only from windows after the unpack (`read_builds`).

3. **Read memory at a moment.**
   - Read with `time_travel memory_at` at any frame, T-state and page.
   - Dump banks with the case's `tools/ttd_dump.py --work W --frame F --out work/images/NAME --pages 0-7 --cpu`
     (ZS, ANE).
   - Find the frame where a block arrives by a binary search (`first_change.py`, `check_load.py`).
   - On a 128K machine, read `$C000` through `memory_at` with an explicit RAM page. A paused instance often has
     another bank paged in.

4. **Prove each packer both ways.**
   - Reimplement the unpacker in Python (`tools/depack.py`, `hrust1.py`, `hrum.py`, `picy.py`, `zspack.py`,
     `trush.py`).
   - Check its output against the recording's memory at the moment the unpacker returns. Zero bytes may differ.
   - Write the packer. Its output must be identical to the medium's bytes.
   - Work out the packer's rules from the tokens of the stream (run lengths, escapes, the order of choices), not by
     guessing a known packer.
   - Where the original packer made choices that a rule does not reproduce, store them as hints in `src/`
     (`src/sfx/hints/*.lzhints`, `src/intro/block1.hints`) and say how many there are.

   ```bash
   python3 tools/hrust1.py check && python3 tools/hrust1.py pack --file NAME        # zynaps-128
   python3 tools/zspack.py check                                                    # ZS, with .lzhints
   python3 tools/picy.py check                                                      # zynaps: 3049 literals, 775 masks, 108 flags
   ```

   Treat ciphers the same way: `tools/ultraxor.py decrypt|encrypt` (ANE), `tools/xorchain.py encrypt` (zynaps).

5. **Animate each unpack** for doc 3:

   ```bash
   python3 ../../kit/memanim.py --work W --from F:T --to F:T --step TSTATES docs/img/load/unpack.gif [--screen]
   ```

6. **Write the small stages as source.**
   - Write each loader stage as source (`src/loader.asm`, `src/screen.asm`, `src/tape/*.asm`), by hand or from its
     own `.ann` through a part generator. It must assemble to the medium's bytes.
   - Describe the medium in a text file (`src/media/trd.txt`, `src/disk99.txt`, `src/tape/zynaps-tzx.txt`).
     `mkdisk.py`, `mkscl.py`, `tzx.py` or `kit/tap.py` turn it back into the image.

**Disk cases:**
- Trace the boot through the `$7FFD` writes and per-bank dumps.
- Use the real TR-DOS ROM. Protections and disk modules call ROM gadgets (`JP $3D2F`), so trapping `$3D13` fails
  (ANE).
- When a stage has to be run many times, a simulator can stand in for the emulator:
  `advanced-nether-earth/tools/ane_sim.py` (SkoolKit plus 128K paging, the TR-DOS ROM and a WD1793 model).

**Done when:** `tools/build.sh` writes the medium bit for bit (`build: identical to orig/...`). The game image may
still be unpacked from the original at this point; recipe 05 replaces it with the game's source.
