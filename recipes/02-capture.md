# 02. Capture

**Answers:** what runs, from the loader's first instruction to play, and later every part of the game.

**Files:** `work/<run>/` with `session.ttd`, `session.json`, `l1.json` and `start.szx`
([case-files.md](../docs/case-files.md#71-a-re_sessionpy-work-folder)).

Set these once:

```bash
export UNREAL_NG=/path/to/unreal-ng                      # the shared checkout (recipe 11: one binary for all)
RS=$UNREAL_NG/tools/verification/analysis/re_session.py
BIN=$UNREAL_NG/cmake-build-agent-release/bin/unreal-qt.app/Contents/MacOS/unreal-qt
```

1. **Record from power-on, with the load.** The stages before the game are evidence too.

   ```bash
   # a tape
   python3 $RS capture --work work/c1 --media orig/GAME.TAP --model 48K --record-load --frames 30000 \
       --port-base <yours> --binary $BIN
   # a disk (nether-earth-zs-edition: an input script boots it and starts the game)
   python3 $RS capture --work work/r98 --media work/scl/NEZSED98.SCL --disk --model PENTAGON \
       --inputs inputs/r98.txt --ranges 4000-FFFF --port-base 13710 --binary $BIN --record-load
   ```

   - The machine starts with zeroed RAM and muted audio. The recording starts before `LOAD ""`.
   - Save the recording once (`work/c1/session.ttd`). For every later question, open it again:
     `python3 $RS open --work work/c1x --ttd work/c1/session.ttd --model 48K --port-base <yours> --binary $BIN`.
   - Use `--ranges 4000-FFFF` when there is code below `$5B00` or in the screen.

2. **Note how the tape loaded.** Every frame number of a recording depends on it. In every document, write the
   recording's name and how it loaded next to each frame number.
   - The LD-BYTES trap is on by default, so the load is fast. H.A.T.E. loaded in 2540 frames instead of about 13200.
   - A loader that calls LD-BYTES past `$0562` / `$0802` runs at signal speed. Zynaps' Hewson loader does this,
     and the game starts at frame 12323.
   - Disks have no fast load. On a disk, `--record-load` first runs 1500 idle frames at the 128 menu, and the
     recording starts at frame 102. So a recording frame is the script frame + 1602. No tool prints this offset.

3. **Find the start image**: the memory at the game's entry, at the frame and T-state where the last loader stage
   jumps in. Find it by a binary search over frames with `time_travel memory_at` (recipe 03), or with the case's
   `tools/first_change.py` (zynaps-128).

4. **Reach the game.** Random play and the demo reach only the first screens. To go further:
   - Write **input scripts** for each part of the game (mm_session format). End a long script with an explicit
     `N END` line, or it stops early.
   - Write **a bot** that reads the game's own records (position, objects, level) from memory each frame and
     steers from them. Patterns: `games/hate/tools/autopilot.py`, `games/nether-earth/tools/bot.py`,
     `games/zynaps-128/tools/play_bot.py`.

   ```bash
   python3 tools/autopilot.py --unreal $UNREAL_NG --binary $BIN --start work/c2/start.szx --work work/p2 \
       --wait 0 --frames 60000 --give-up 4 --save-rounds --record                      # hate
   python3 tools/bot.py play --record --frames 36000 --work work/deep                   # nether-earth
   python3 $RS capture --work work/r1 --snapshot work/run/play.szx --inputs work/run/all.txt \
       --model 48K --ranges 5B00-FFFF --port-base <yours> --binary $BIN                 # zynaps: a bot's keys replayed
   ```

   Keep each bot's log (frame, level, lives, score) and chart it, as `games/hate/tools/gamechart.py` does.

5. **List what the recordings reached:** levels, modes, endings, high-score entry, every menu option. Write what
   none of them reached in the WALKTHROUGH as "known only from the code". Reach it later if you can: more bot runs,
   a POKE on a clone (`PUT /api/v1/emulator/{id}/memory/ram/0/16343 {"hex":"01"}`), or a snapshot taken at the
   right place.

**Pitfalls**

| Pitfall | Do |
| --- | --- |
| Two instances on one port base, or base + 200 colliding with another instance's server | one base per agent, 100 or more apart, written in the brief (recipe 11) |
| `type_input` silently rejects `SS` / `CS` | write `ss` / `cs` (or `symbol`, `symbol+p`) |
| A snapshot holds no disk, so TR-DOS hangs at `$3FE7` | insert the disk (`POST /disk/A/insert`); remember that the frame counter restarts when a snapshot loads |
| A bot run and its capture drift apart after about frame 3000, because `run_frames` is not frame-aligned | each recording is consistent in itself; quote the frames of the recording, never those of the bot's log |
| General Sound runs | `--card gs --card-ram 512k\|128k` (the case's `gs_session.py`); capture `zxbus.1.ports`, not `zxbus.1` (1.7 GB for 2600 frames); NeoGS state is not saved in an SZX |
| Running on a machine the version does not target | run only on the models the version was made for (recipe 10) |

**MCP:**
- Take the control session first.
- `time_travel memory_at` reads memory at any frame and T-state, with no seek.
- `time_travel explain_frame` shows what a frame did.
- `time_travel find_last` with the write journal tells who wrote a byte.
- `find_event` finds a moment by its event. Give it a narrow from/to window: over a wide one it misses hits.

**Done when:** a power-on recording and recordings that reach each part of the game are saved. The WALKTHROUGH
has a table of their frames of interest (the entry, each level start, each mode), with how each recording loaded.
