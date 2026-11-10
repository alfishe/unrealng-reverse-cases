# Chuckie Egg: two emulator faults for the unreal-ng owner

Both come from one cause: the game's state after K frames depends on how the K frames are split into
`control_execution run_frames` calls. The same split always gives the same state (the run is deterministic per
split); different splits drift apart. Stage 2 only reproduces and records them; the emulator was not changed.

- Binary: `$BIN` of `work/env.sh` (`scratch/wt-nezs-stage1/cmake-build-agent-release`, unreal-qt).
- Machine: a fresh 48K through `tools/lab.py` (`Lab(36220)`: RAM zeroed at power-on, Kempston on `edge.1`, paused,
  muted, `take_control`), a snapshot loaded with `POST /snapshot/load`, keys held with `tools/bot.py`'s `keys`.
- Each probe below was run from the case folder after `. work/env.sh`; outputs are next to the scripts in
  `work/stage2/`.

## Fault 1: one long run_frames call differs from many short ones

```bash
python3 work/stage2/faults.py 31000 1000        # -> work/stage2/faults.out
```

From `work/stage1/rec/levels-1-3/end.szx` (level 4, lives 5, PC `$987E`, frame T 2119), no keys held:

| Variant | Calls | Lives | Harry (x, y) | PC | SHA-1 of `$4000-$FFFF` (first 12) |
| --- | --- | ---: | --- | --- | --- |
| A: `run_frames 31000` | 1 | 4 | 100, 23 | `$9AE2` | `4e1b74b0ba16` |
| B: 31 x `run_frames 1000` | 31 | 1 | 100, 23 | `$9A75` | `311c8b3ef5b4` |
| A2: A again | 1 | 4 | 100, 23 | `$9AE2` | `4e1b74b0ba16` |

A against B: 408 RAM bytes differ (the first `$4092`, `$4093`, `$40CC` ...: the screen, then the game's
variables). A against A2: 0. Stage 1 noted lives 3 for A (the binary may have been rebuilt since; not checked); B (lives 1) is what
the 50-frame steps of `bot.py record` give.

Where the drift starts (`work/stage2/faults_bisect.py` -> `faults_bisect.out`): after each call the frame T-state
(`GET /registers`, `special.t`) is a few T past where it started, and with short calls the overshoot accumulates:

| Run | One call: PC, T at the end | Split: PC, T after each call | RAM bytes that differ |
| --- | --- | --- | ---: |
| 2 frames vs 2 x 1 | `$9AE2`, 2124 | `$9AE0`; 2132, 2137 | 0 |
| 10 frames vs 10 x 1 | `$9AD1`, 2125 | `$9AD1`; 2132, 2137, 2144, 2147, 2152, 2158 ... | 0 |
| 100 frames vs 2 x 50 | `$9AE2`, 2128 | `$9AE0`; 2137, 2141 | 0 |
| 1000 frames vs 2 x 500 | `$9AB7`, 2121 | `$9AB7`; 2121, 2121 | 0 |
| 1000 frames vs 10 x 100 | `$9AB7`, 2121 | `$9AC3`; 2128, 2130, 2141, 2155, 2157, 2160 | 2 (`$FF2E-$FF2F`, the stack) |

So a split call does not end on the same instruction as the unsplit run at the same frame count: the CPU's position
in the frame (and so the instruction the next frame interrupt lands on) shifts by a few T a call. The game's main loop
is not frame-locked (a slow tick every 130 passes, MainLoop `$98B7`), so a few T moved across hundreds of calls
change which pass a key read or a hen move falls into, and the game diverges.

The likely place to look: how `run_frames` decides where frame N ends (relative to the call's start T rather than the
absolute frame boundary, or an instruction's overshoot past the boundary counted again in the next call). Not
investigated further (no unreal-ng code read or changed). A second line, reading the frame counter, did not pay
after two tries: `GET /cpu/state` and the guessed routes `/status`, `/info`, `/cpu`, `/frame` answer 404;
`GET /video/beam` (used by `tools/heavypass.py`) gives the frame and T and is the route for the next probe.

## Fault 2: the 50-frame chunks of bot.py record diverge from the one-call-a-segment run

```bash
python3 work/stage2/faults_chunks.py tests/inputs/levels-1-9.txt work/stage1/rec/levels-1-9/states.json 14500
# -> work/stage2/faults_chunks.out
```

`tests/inputs/levels-1-9.txt` replayed from `work/stage1/lab/x0/loaded.szx` in `run_frames` calls of at most 50
frames that end on multiples of 50 or at a segment end (as `bot.py record` without `--exact`), compared at every
segment end with `work/stage1/rec/levels-1-9/states.json` (recorded with `--exact`: one call a segment, the
recording that reaches level 10):

- the same at every segment end up to frame 8534;
- frame 8574 (level 4, eggs 4, lives 6): chunks x 169, exact x 170 (one pixel), y 87 both.

The one-pixel drift on level 4 is the first visible effect; stage 1 noticed the run only when it went wrong on level 6
at frame 13 250. Stage 1's `work/stage1/lab/chunkcmp.py` (50-frame replay
without recording against the 50-frame recording's states) gave "same up to 14000", so the recording itself does not
cause the drift: the chunk boundaries do. `bot.py record --exact` (one call a segment) is the workaround, and the
search replays use it.

## What the owner may want to check

1. Is `run_frames N` from a mid-frame position meant to stop at the same instruction as N calls of 1? Today it is
   not (table above).
2. Does any per-call work (pausing, the WebAPI's `take_control`, a snapshot of the beam) add or drop T-states?
