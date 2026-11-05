# 07. Figures

**Answers:** what a routine does, shown, and what on the screen each piece of code made. The kinds and the
density required are in [the guide, section 4](../GUIDE.md#4-figures).

1. **Pick the moments**: for each subsystem's central routine, one call in a recording at a typical moment and one
   at a busy one (`time_travel explain_frame` names the routines of a frame with their time; `find_event` finds a
   moment by an event).
2. **Routine animations**: `kit/routine_anim.py --work W --window F:T-F:T --listing build/game.lst --out
   docs/img/routines/<Label>.gif` traces that window (unreal-ng `analysis trace`: every instruction with its
   registers, every fetch, read, write and port access with its T-state; kept in `W/traces/`) and draws, picture by
   picture, the memory map lit by age, the screen or buffer the routine writes, the listing window and the
   registers. `--pc LO-HI` names the routine's code (the rest, an interrupt, counts as "other"); `--range` limits
   the map to the addresses that matter; `--view buffer:ADDR:WxH[:rows|:columns|:columns-up]` draws a buffer in its geometry and storage order, `--view screen`
   the screen; `--pictures` or `--step` sets the slices. Name the file after the routine's label: doc 12 links it.
3. **Code vs screen**: `kit/writers_map.py --work W --window F:T-F:T --listing build/game.lst --out ...` colours
   every byte of the view by the routine that wrote it last in the window, with a legend of writers and the
   instructions that wrote; `--by pc` colours by instruction, `--zoom X,Y,W,H` adds an enlarged inset with the byte
   grid, `--sources` names the data each writer read before its writes (a sprite frame, a mask, a glyph).
4. **Beam timelines**: `kit/beam_timeline.py --work W --window F:0-F+3:0 --listing build/game.lst --out ...` draws
   each frame's T axis with the routine running, the beam's diagonal and every screen write against it, with the
   counts of writes before and after the beam. The T axis is the frame T, the T-state in unreal-ng's frame as the
   trace stores it, not the time from the INT: the INT is at frame T 1812 on the 48K, 1846 on the 128K and -44 on
   the Pentagon, so the paper starts at frame T 16 152, 16 212 and 17 944. The machine follows the trace's frame
   length; `--machine`, `--int-t`, `--int-to-paper` or `--paper-t` override it. A case's own beam figure takes the
   same numbers and labels its axis "frame T" (or converts to "T from the INT" and says so).
5. **Stage animations, heatmaps, screenshots**: `kit/memanim.py`, `kit/heatmap.py`, `kit/screen_shot.py`.
6. Put each figure in the document where its routine is described, a caption first: what it shows, the
   recording, frames and T-states. Link the hot routines' animations from doc 12 (`refdocs.py` links
   `docs/img/routines/<Label>.gif` when it exists); `kit/check_docs.py` lists a figure no document links.

**Done when:** the checklist of the guide's 4.2 is met; every figure is rebuilt by a command in the WALKTHROUGH.
