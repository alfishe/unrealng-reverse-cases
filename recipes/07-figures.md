# 07. Figures

**Answers:** what a routine does, shown, and which code made each piece of the screen. The kinds of figure and
the density required are in [the guide, section 4](../GUIDE.md#4-figures).

The figure rule comes from Nether Earth's `work/ann/BRIEF-FIG.md`, and every docs brief since has used it:
- the title states the figure's point;
- every mark is labelled;
- the numbers agree with the text;
- the figure is readable at about 900 px;
- a "how to read" list sits next to it;
- the command that drew it is named.

Do not make a figure that says nothing.

1. **Pick the moments.** For each subsystem's central routine, take one call at a typical moment and one at a busy
   moment. `time_travel explain_frame` lists the routines of a frame with their time, and `find_event` finds a
   moment by an event.

2. **Routine animations.**

   ```bash
   python3 ../../kit/routine_anim.py --work work/p2 --window 1001:5336-1001:45336 --listing build/game.lst \
       --view buffer:8000:128x128:columns-up --pc EAE3-EBA9 --range 8000-FFFF --out docs/img/routines/DrawSprites.gif
   ```

   - The script traces the window once with unreal-ng's `analysis trace` and keeps the trace in `W/traces/`.
   - `--pc LO-HI` gives the routine's code; everything else counts as "other". Several ranges (`--pc A-B,C-D` or
     `--pc` repeated) take the routines it calls elsewhere in memory too.
   - `--range` limits the memory map.
   - `--view buffer:ADDR:WxH[:rows|:columns|:columns-up]` or `--view screen` sets what is drawn.
   - `--pictures` or `--step` sets how many pictures.
   - The picture is 1050 px wide (`--width`): the memory map above the view, the listing beside them. `--layout wide`
     draws the three panels side by side, up to 2566 px, too wide for a document.
   - Name the file after the routine's label, so that doc 12 links it.

3. **Code vs screen.**

   ```bash
   python3 ../../kit/writers_map.py --work W --window F:T-F:T --listing build/game.lst --out docs/img/render/writers.png \
       [--by pc] [--zoom X,Y,W,H] [--sources]
   ```

4. **Beam timelines.**

   ```bash
   python3 ../../kit/beam_timeline.py --work W --window F:0-F+3:0 --listing build/game.lst --out docs/img/loop/beam.png
   ```

   - The T axis is the frame T as the trace stores it, not the time from the INT.
   - The INT falls at frame T 1812 on the 48K, 1846 on the 128K and -44 on the Pentagon.
   - So the paper starts at frame T 16 152, 16 212 and 17 944.
   - `--machine`, `--int-t`, `--int-to-paper` and `--paper-t` override these values.
   - A case's own beam figure uses the same numbers and says which axis it shows.

5. **Stage animations, heatmaps, screenshots and the budget.**

   ```bash
   python3 ../../kit/memanim.py --work W --from F --to G --step 69888 docs/img/load/load.gif [--screen]
   python3 ../../kit/heatmap.py work/game/l1.json docs/img/arch/heat.png --cell 2 --regions tools/regions.txt
   python3 ../../kit/screen_shot.py --work W --out-dir docs/img/play title=1200 menu=1450:0 play=3300
   python3 ../../kit/fig_budget.py ...          # where the CPU time goes, per routine / module (kit README)
   ```

   `memanim.py --screen` puts the screen under the grid when the two side by side would pass 1050 px (`--width`;
   `--layout wide` keeps them side by side). `fig_budget.py` is 1050 px wide and wraps a long `--note`.

   `screen_shot.py` reads the CPU's view at `$4000`. On a 128K game that shows screen 7, read the page through
   `memory_at` instead (ANE).

6. **Case scripts.** Draw what the kit does not with case scripts in `tools/fig_*.py`. Examples:
   - hate: `pass_anim.py`, `fig_l1.py`;
   - zynaps-128: `sound_render.py chart` (the notes over time), `fig_ports.py`;
   - nether-earth: `fig_path_*.py`.

7. **Audio.** TTD replay suppresses the sound analyzers, so render sound from snapshots, scripts and bots. In ANE
   the capture is capped at 30 s and padded with zeros. `tools/render_audio.py` writes `docs/audio/*.mp3` and their
   README.

8. **Place the figures.**
   - Put each figure in the document that describes its routine.
   - Give it a caption: what it shows, the recording, the frames and the T-states.
   - Keep images in `docs/img/<topic>/`.
   - `refdocs.py` links `docs/img/routines/<Label>.gif` from doc 12.

   `check_docs.py` lists unlinked figures only in `docs/img/` and `docs/img/routines/`. Check the topic folders
   yourself:

   ```bash
   for f in docs/img/*/*.*; do grep -rqF "${f#docs/}" docs/*.md README.md || echo "unlinked: $f"; done
   ```

**Done when:** the checklist in the guide's section 4.2 is met, and every figure is rebuilt by a command in the
WALKTHROUGH or in its caption.
